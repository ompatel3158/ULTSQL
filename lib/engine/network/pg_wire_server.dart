import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../executor/interpreter.dart';
import '../executor/value.dart';

class PgWireServer {
  final Database db;
  final int port;
  final String address;
  ServerSocket? _server;

  PgWireServer(this.db, {this.port = 5432, this.address = '127.0.0.1'});

  Future<void> start() async {
    _server = await ServerSocket.bind(address, port);
    print('PgWireServer listening on $address:$port');
    _server!.listen(_handleConnection);
  }

  Future<void> stop() async {
    await _server?.close();
  }

  void _handleConnection(Socket socket) {
    final sessionCtx = db.cache.createSessionContext();
    runZoned(() {
      _PgConnectionHandler(socket, db).handle();
    }, zoneValues: {#sessionTxContext: sessionCtx});
  }
}

class _PgConnectionHandler {
  final Socket socket;
  final Database db;
  late Interpreter interpreter;
  bool _startupComplete = false;
  String _lastQuery = '';
  final List<int> _buffer = [];

  _PgConnectionHandler(this.socket, this.db) {
    interpreter = Interpreter(db);
  }

  void handle() {
    socket.listen(
      (data) {
        _buffer.addAll(data);
        _processBuffer();
      },
      onError: (e) {
        print('PgWireServer connection error: $e');
        socket.close();
      },
      onDone: () {
        socket.close();
      },
    );
  }

  Future<void> _processBuffer() async {
    while (true) {
      if (!_startupComplete) {
        if (_buffer.length < 8) return;
        final length = _readInt32(0);
        if (_buffer.length < length) return;

        final protocol = _readInt32(4);
        if (protocol == 80877103) { // SSLRequest
          _safeAdd([78]); // 'N'
          _buffer.removeRange(0, length);
          continue;
        }

        // Complete startup
        _startupComplete = true;
        _buffer.removeRange(0, length);
        
        _sendAuthenticationOk();
        _sendReadyForQuery();
      } else {
        if (_buffer.length < 5) return;
        final msgType = String.fromCharCode(_buffer[0]);
        final length = _readInt32(1);
        if (_buffer.length < length + 1) return;

        final payload = _buffer.sublist(5, length + 1);
        _buffer.removeRange(0, length + 1);

        if (msgType == 'Q') { // Simple Query
          final query = utf8.decode(payload).replaceAll('\x00', '');
          await _handleQuery(query, sendReady: true);
        } else if (msgType == 'P') { // Parse
          int zeroIdx = payload.indexOf(0);
          int nextZeroIdx = payload.indexOf(0, zeroIdx + 1);
          final query = utf8.decode(payload.sublist(zeroIdx + 1, nextZeroIdx));
          if (query.isNotEmpty) {
            _lastQuery = query;
          }
          final buf = BytesBuilder();
          buf.addByte(49); // '1' ParseComplete
          buf.add(_encodeInt32(4));
          _safeAdd(buf.takeBytes());
        } else if (msgType == 'B') { // Bind
          final buf = BytesBuilder();
          buf.addByte(50); // '2' BindComplete
          buf.add(_encodeInt32(4));
          _safeAdd(buf.takeBytes());
        } else if (msgType == 'D') { // Describe
          final paramDesc = BytesBuilder();
          paramDesc.addByte(116); // 't'
          paramDesc.add(_encodeInt32(6));
          paramDesc.add(_encodeInt16(0));
          _safeAdd(paramDesc.takeBytes());
          
          final noData = BytesBuilder();
          noData.addByte(110); // 'n'
          noData.add(_encodeInt32(4));
          _safeAdd(noData.takeBytes());
        } else if (msgType == 'E') { // Execute
          await _handleQuery(_lastQuery, sendReady: false);
        } else if (msgType == 'S') { // Sync
          _sendReadyForQuery();
        } else if (msgType == 'X') { // Terminate
          socket.close();
          return;
        }
      }
    }
  }

  Future<void> _handleQuery(String query, {bool sendReady = true}) async {
    try {
      final result = await interpreter.executeScript(query);
      
      // RowDescription 'T'
      if (result.columns.isNotEmpty) {
        final buf = BytesBuilder();
        buf.addByte(84); // 'T'
        
        final msgBuf = BytesBuilder();
        msgBuf.add(_encodeInt16(result.columns.length));
        
        for (final col in result.columns) {
          msgBuf.add(utf8.encode(col));
          msgBuf.addByte(0);
          msgBuf.add(_encodeInt32(0)); // tableOid
          msgBuf.add(_encodeInt16(0)); // colOid
          msgBuf.add(_encodeInt32(25)); // typeOid (25 = text)
          msgBuf.add(_encodeInt16(-1)); // typeSize
          msgBuf.add(_encodeInt32(-1)); // typeModifier
          msgBuf.add(_encodeInt16(0)); // formatCode
        }
        
        buf.add(_encodeInt32(msgBuf.length + 4));
        buf.add(msgBuf.takeBytes());
        _safeAdd(buf.takeBytes());
      }
      
      // DataRow 'D'
      for (final row in result.rows) {
        final buf = BytesBuilder();
        buf.addByte(68); // 'D'
        
        final msgBuf = BytesBuilder();
        msgBuf.add(_encodeInt16(row.length));
        
        for (final val in row) {
          if (val is DbNull) {
            msgBuf.add(_encodeInt32(-1));
          } else {
            final str = val.toString();
            final bytes = utf8.encode(str);
            msgBuf.add(_encodeInt32(bytes.length));
            msgBuf.add(bytes);
          }
        }
        
        buf.add(_encodeInt32(msgBuf.length + 4));
        buf.add(msgBuf.takeBytes());
        _safeAdd(buf.takeBytes());
      }
      
      // CommandComplete 'C'
      _sendCommandComplete('SELECT ${result.rows.length}');
      if (sendReady) _sendReadyForQuery();
      
    } catch (e) {
      // ErrorResponse 'E'
      final buf = BytesBuilder();
      buf.addByte(69); // 'E'
      
      final msgBuf = BytesBuilder();
      msgBuf.addByte(83); // Severity
      msgBuf.add(utf8.encode('ERROR'));
      msgBuf.addByte(0);
      
      msgBuf.addByte(77); // Message
      msgBuf.add(utf8.encode(e.toString()));
      msgBuf.addByte(0);
      
      msgBuf.addByte(0); // null terminator
      
      buf.add(_encodeInt32(msgBuf.length + 4));
      buf.add(msgBuf.takeBytes());
      _safeAdd(buf.takeBytes());
      
      if (sendReady) _sendReadyForQuery();
    }
  }

  void _sendAuthenticationOk() {
    final buf = BytesBuilder();
    buf.addByte(82); // 'R'
    buf.add(_encodeInt32(8)); // length
    buf.add(_encodeInt32(0)); // AuthOk
    _safeAdd(buf.takeBytes());
  }

  void _sendReadyForQuery() {
    final buf = BytesBuilder();
    buf.addByte(90); // 'Z'
    buf.add(_encodeInt32(5)); // length
    buf.addByte(73); // 'I' for idle
    _safeAdd(buf.takeBytes());
  }

  void _sendCommandComplete(String tag) {
    final buf = BytesBuilder();
    buf.addByte(67); // 'C'
    
    final msgBuf = BytesBuilder();
    msgBuf.add(utf8.encode(tag));
    msgBuf.addByte(0);
    
    buf.add(_encodeInt32(msgBuf.length + 4));
    buf.add(msgBuf.takeBytes());
    _safeAdd(buf.takeBytes());
  }

  void _safeAdd(List<int> bytes) {
    try {
      socket.add(bytes);
    } catch (_) {}
  }

  int _readInt32(int offset) {
    final bd = ByteData.view(Uint8List.fromList(_buffer.sublist(offset, offset + 4)).buffer);
    return bd.getInt32(0, Endian.big);
  }

  List<int> _encodeInt32(int value) {
    final bd = ByteData(4);
    bd.setInt32(0, value, Endian.big);
    return bd.buffer.asUint8List();
  }

  List<int> _encodeInt16(int value) {
    final bd = ByteData(2);
    bd.setInt16(0, value, Endian.big);
    return bd.buffer.asUint8List();
  }
}
