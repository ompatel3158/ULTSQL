import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/storage/catalog.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'dart:io';

void main() {
  group('Time-Travel Querying', () {
    late Database db;
    late Interpreter interpreter;
    final dbDir = 'test_time_travel_db';

    setUp(() async {
      final dir = Directory(dbDir);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
      db = Database(dbDir);
      await db.init();
      interpreter = Interpreter(db);

      await interpreter.executeScript('CREATE TABLE users (id INT PRIMARY KEY, name TEXT);');
    });

    tearDown(() async {
      await db.close();
      final dir = Directory(dbDir);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

    test('querying historical state using AS OF TRANSACTION', () async {
      // 1. Insert row at T1
      await interpreter.executeScript('''
        BEGIN TRANSACTION;
        INSERT INTO users (id, name) VALUES (1, 'Alice');
        COMMIT;
      ''');
      
      // Verify row exists at current time
      var res = await interpreter.executeScript('SELECT * FROM users;');
      expect(res.rows.length, 1);
      
      // 2. Delete row at T2
      await interpreter.executeScript('''
        BEGIN TRANSACTION;
        DELETE FROM users WHERE id = 1;
        COMMIT;
      ''');
      
      // 3. SELECT * FROM table -> returns 0 rows (current state)
      res = await interpreter.executeScript('SELECT * FROM users;');
      expect(res.rows.length, 0);
      
      // 4. SELECT * FROM table AS OF TRANSACTION 1 -> returns 1 row (historical state)
      res = await interpreter.executeScript('SELECT * FROM users AS OF TRANSACTION 1;');
      expect(res.rows.length, 1);
      expect(res.rows[0][0].toString(), '1');
      expect(res.rows[0][1].toString(), 'Alice');
    });
  });
}
