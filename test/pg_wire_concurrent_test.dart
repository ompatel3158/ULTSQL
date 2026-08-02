import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/network/pg_wire_server.dart';
import 'package:ultsql/src/engine/storage/catalog.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';

void main() {
  const dbDir = 'test_data_pg_wire_concurrent';

  Future<void> cleanDir(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  }

  setUp(() async {
    await cleanDir(dbDir);
  });

  tearDown(() async {
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('PgWireServer handles concurrent client sockets', () async {
    final db = Database(dbDir);
    await db.init();
    
    final server = PgWireServer(db, port: 5435);
    await server.start();

    const int numClients = 10;
    final List<Future<void>> clients = [];

    for (int i = 0; i < numClients; i++) {
      clients.add(() async {
        final socket = await Socket.connect('127.0.0.1', 5435);

        // Send StartupMessage
        final startupBuf = BytesBuilder();
        startupBuf.add([0, 0, 0, 0]); // Length placeholder
        startupBuf.add([0, 3, 0, 0]); // Protocol 3.0 (196608)
        startupBuf.add('user\x00test\x00database\x00testdb\x00\x00'.codeUnits);
        
        final startupBytes = startupBuf.takeBytes();
        final bd = ByteData.view(startupBytes.buffer);
        bd.setInt32(0, startupBytes.length, Endian.big);
        
        socket.add(startupBytes);

        // Read responses
        bool authOk = false;
        bool ready = false;
        final completer = Completer<bool>();
        int zCount = 0;
        
        socket.listen((data) {
          int offset = 0;
          while (offset < data.length) {
            final type = String.fromCharCode(data[offset]);
            if (offset + 5 > data.length) break;
            final bd = ByteData.sublistView(Uint8List.fromList(data), offset + 1, offset + 5);
            final len = bd.getInt32(0);

            if (type == 'R') authOk = true;
            if (type == 'E') {
              if (!completer.isCompleted) completer.complete(false);
              break;
            }
            if (type == 'Z') {
              zCount++;
              if (zCount == 1) {
                ready = true;
                final queryBuf = BytesBuilder();
                queryBuf.addByte(81); // 'Q'
                queryBuf.add([0, 0, 0, 0]); // Length
                queryBuf.add('SELECT $i;\x00'.codeUnits);
                
                final qBytes = queryBuf.takeBytes();
                final qBd = ByteData.view(qBytes.buffer);
                qBd.setInt32(1, qBytes.length - 1, Endian.big);
                socket.add(qBytes);
              } else if (zCount == 2) {
                if (!completer.isCompleted) completer.complete(true);
              }
            }
            offset += 1 + len;
          }
        });

        final success = await completer.future.timeout(Duration(seconds: 5), onTimeout: () => false);

        expect(authOk, isTrue);
        expect(ready, isTrue);
        expect(success, isTrue);
        
        final termBuf = BytesBuilder();
        termBuf.addByte(88); // 'X'
        termBuf.add([0, 0, 0, 4]); // Length
        socket.add(termBuf.takeBytes());
        
        await Future.delayed(Duration(milliseconds: 50));
        socket.destroy();
      }());
    }

    await Future.wait(clients);
    await server.stop();
  });
}
