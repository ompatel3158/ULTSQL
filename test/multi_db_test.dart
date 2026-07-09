import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'dart:io';

void main() {
  late Database db;
  late Interpreter interpreter;
  final dbPath = 'test_primary_db';

  setUp(() async {
    final dir = Directory(dbPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    final otherDir = Directory('test_other_db');
    if (otherDir.existsSync()) {
      otherDir.deleteSync(recursive: true);
    }
    
    db = Database(dbPath);
    await db.init();
    interpreter = Interpreter(db);
  });

  tearDown(() async {
    await interpreter.db.close();
    await db.close();
    
    final dir = Directory(dbPath);
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
    
    final otherDir = Directory('test_other_db');
    if (otherDir.existsSync()) {
      try {
        otherDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  test('CREATE DATABASE and USE switching workflow', () async {
    // 1. Create table and insert in primary database
    await interpreter.executeScript('CREATE TABLE t_main(a INT);');
    await interpreter.executeScript('INSERT INTO t_main VALUES (42);');
    
    final sel1 = await interpreter.executeScript('SELECT * FROM t_main;');
    expect(sel1.rows.length, 1);
    expect(sel1.rows.first.first.toString(), '42');

    // 2. Create the second database
    final resCreate = await interpreter.executeScript('CREATE DATABASE test_other;');
    expect(resCreate.message.contains('created successfully'), true);
    
    // 3. Switch to the second database
    final resUse = await interpreter.executeScript('USE test_other;');
    expect(resUse.message.contains('Switched to'), true);
    expect(interpreter.db.directory, 'test_other_db');

    // 4. Verify primary table does not exist in the new database
    final selMainFail = await interpreter.executeScript('SELECT * FROM t_main;');
    expect(selMainFail.message.contains('Error'), true); // Should fail because t_main is in primary_db

    // 5. Create table and insert in the second database
    await interpreter.executeScript('CREATE TABLE t_secondary(b TEXT);');
    await interpreter.executeScript("INSERT INTO t_secondary VALUES ('Hello Secondary');");
    
    final sel2 = await interpreter.executeScript('SELECT * FROM t_secondary;');
    expect(sel2.rows.length, 1);
    expect(sel2.rows.first.first.toString(), 'Hello Secondary');

    // 6. Switch back to the primary database
    final resUseBack = await interpreter.executeScript('USE test_primary;');
    expect(resUseBack.message.contains('Switched to'), true);
    expect(interpreter.db.directory, 'test_primary_db');

    // 7. Verify t_main exists and has its row, but t_secondary does not exist here
    final selMainSuccess = await interpreter.executeScript('SELECT * FROM t_main;');
    expect(selMainSuccess.rows.length, 1);
    expect(selMainSuccess.rows.first.first.toString(), '42');

    final selSecondaryFail = await interpreter.executeScript('SELECT * FROM t_secondary;');
    expect(selSecondaryFail.message.contains('Error'), true);
  });
}
