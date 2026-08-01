import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/ult_sql_engine.dart';

void main() {
  test('UltSqlEngine executes in File-Persisted Disk Mode', () async {
    final engine = await UltSqlEngine.openFile('test_every_way_file_db');
    await engine.query("CREATE TABLE users (id INT, name TEXT);");
    await engine.query("INSERT INTO users VALUES (1, 'Alice');");
    
    final res = await engine.query("SELECT * FROM users;");
    expect(res.length, equals(1));
    expect(res.toList()[0]['name'], equals('Alice'));
    
    await engine.close();
    
    final dir = Directory('test_every_way_file_db');
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('UltSqlEngine executes in In-Memory Ephemeral Mode', () async {
    final engine = await UltSqlEngine.openMemory();
    await engine.query("CREATE TABLE mem_cache (item_key TEXT, val TEXT);");
    await engine.query("INSERT INTO mem_cache VALUES ('token', 'xyz123');");
    
    final res = await engine.query("SELECT * FROM mem_cache;");
    expect(res.length, equals(1));
    expect(res.toList()[0]['val'], equals('xyz123'));
    
    await engine.close();
  });

  test('UltSqlEngine executes in Server PGWire Mode over TCP Port 5436', () async {
    final engine = await UltSqlEngine.openMemory();
    await engine.query("CREATE TABLE products (id INT, price DOUBLE);");
    await engine.query("INSERT INTO products VALUES (1, 99.99);");
    
    final port = await engine.startServer(port: 5436);
    expect(port, equals(5436));

    // Socket client connection
    final socket = await Socket.connect('127.0.0.1', 5436);
    final startupBuf = BytesBuilder();
    startupBuf.add([0, 0, 0, 0]);
    startupBuf.add([0, 3, 0, 0]);
    startupBuf.add('user\x00test\x00database\x00testdb\x00\x00'.codeUnits);
    
    final startupBytes = startupBuf.takeBytes();
    final bd = ByteData.view(startupBytes.buffer);
    bd.setInt32(0, startupBytes.length, Endian.big);
    socket.add(startupBytes);

    final completer = Completer<bool>();
    socket.listen((data) {
      if (!completer.isCompleted) completer.complete(true);
    });

    final success = await completer.future.timeout(Duration(seconds: 5), onTimeout: () => false);
    expect(success, isTrue);

    socket.destroy();
    await engine.close();
  });
}
