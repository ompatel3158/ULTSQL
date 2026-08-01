import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/network/pg_wire_server.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';

void main() {
  test('PgWireServer handles SSLRequest and extended protocol', () async {
    final db = Database(':memory:');
    final server = PgWireServer(db, port: 5434);
    await server.start();

    final socket = await Socket.connect('127.0.0.1', 5434);
    final buffer = <int>[];
    
    // Listen for responses
    socket.listen((data) {
      buffer.addAll(data);
    });

    // 1. Send SSLRequest (80877103)
    var bd = ByteData(8);
    bd.setInt32(0, 8, Endian.big);
    bd.setInt32(4, 80877103, Endian.big);
    socket.add(bd.buffer.asUint8List());

    await Future.delayed(Duration(milliseconds: 100));
    expect(buffer.length, 1);
    expect(buffer[0], 78); // 'N'
    buffer.clear();

    // 2. Send StartupMessage
    final startupPayload = BytesBuilder();
    startupPayload.add(utf8.encode('user\x00postgres\x00\x00'));
    
    bd = ByteData(8);
    bd.setInt32(0, 8 + startupPayload.length, Endian.big);
    bd.setInt32(4, 196608, Endian.big);
    
    socket.add(bd.buffer.asUint8List());
    socket.add(startupPayload.takeBytes());

    await Future.delayed(Duration(milliseconds: 100));
    // AuthOk 'R'
    expect(buffer.length, greaterThanOrEqualTo(14));
    expect(buffer[0], 82); 
    buffer.clear();

    // 3. Send Parse ('P')
    final queryStr = 'SELECT 1;\x00';
    final parsePayload = BytesBuilder();
    parsePayload.add(utf8.encode('\x00')); // stmt name empty
    parsePayload.add(utf8.encode(queryStr)); // query
    parsePayload.add([0, 0]); // 0 params
    
    var msgLength = parsePayload.length + 4;
    bd = ByteData(5);
    bd.setUint8(0, 80); // 'P'
    bd.setInt32(1, msgLength, Endian.big);
    socket.add(bd.buffer.asUint8List());
    socket.add(parsePayload.takeBytes());

    await Future.delayed(Duration(milliseconds: 100));
    expect(buffer[0], 49); // '1' ParseComplete
    buffer.clear();

    // 4. Send Bind ('B')
    final bindPayload = BytesBuilder();
    bindPayload.add(utf8.encode('\x00')); // portal empty
    bindPayload.add(utf8.encode('\x00')); // stmt empty
    bindPayload.add([0, 0]); // 0 format codes
    bindPayload.add([0, 0]); // 0 param values
    bindPayload.add([0, 0]); // 0 result format codes

    msgLength = bindPayload.length + 4;
    bd = ByteData(5);
    bd.setUint8(0, 66); // 'B'
    bd.setInt32(1, msgLength, Endian.big);
    socket.add(bd.buffer.asUint8List());
    socket.add(bindPayload.takeBytes());

    await Future.delayed(Duration(milliseconds: 100));
    expect(buffer[0], 50); // '2' BindComplete
    buffer.clear();

    // 5. Send Describe ('D')
    final describePayload = BytesBuilder();
    describePayload.addByte(83); // 'S' (Statement)
    describePayload.add(utf8.encode('\x00')); // stmt empty

    msgLength = describePayload.length + 4;
    bd = ByteData(5);
    bd.setUint8(0, 68); // 'D'
    bd.setInt32(1, msgLength, Endian.big);
    socket.add(bd.buffer.asUint8List());
    socket.add(describePayload.takeBytes());

    await Future.delayed(Duration(milliseconds: 100));
    expect(buffer[0], 116); // 't' ParameterDescription
    buffer.clear();
    
    // 6. Send Execute ('E')
    final executePayload = BytesBuilder();
    executePayload.add(utf8.encode('\x00')); // portal empty
    executePayload.add([0, 0, 0, 0]); // max rows 0
    
    msgLength = executePayload.length + 4;
    bd = ByteData(5);
    bd.setUint8(0, 69); // 'E'
    bd.setInt32(1, msgLength, Endian.big);
    socket.add(bd.buffer.asUint8List());
    socket.add(executePayload.takeBytes());

    await Future.delayed(Duration(milliseconds: 100));
    expect(buffer, isNotEmpty);
    buffer.clear();
    
    // 7. Send Sync ('S')
    bd = ByteData(5);
    bd.setUint8(0, 83); // 'S'
    bd.setInt32(1, 4, Endian.big);
    socket.add(bd.buffer.asUint8List());
    
    await Future.delayed(Duration(milliseconds: 100));
    expect(buffer[0], 90); // 'Z' ReadyForQuery

    socket.destroy();
    await server.stop();
  });
}
