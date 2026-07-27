import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';

void main() {
  const dbDir = 'test_data_json_mutations';

  Future<void> cleanDir(String path) async {
    final dir = Directory(path);
    for (int i = 0; i < 10; i++) {
      try {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
        await dir.create(recursive: true);
        return;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> deleteDir(String path) async {
    final dir = Directory(path);
    for (int i = 0; i < 10; i++) {
      try {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
        return;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  setUp(() async {
    await cleanDir(dbDir);
  });

  tearDown(() async {
    await deleteDir(dbDir);
  });

  test('JSON Mutations - JSON_SET, JSON_REMOVE, JSON_ARRAY, JSON_OBJECT and UPDATE', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // Setup: Create a users table and insert a dummy row.
    await interpreter.executeScript(
      'CREATE TABLE users (id INT, name TEXT, age INT, info JSON);'
    );
    await interpreter.executeScript(
      "INSERT INTO users VALUES (1, 'Alice', 30, '{\"active\": false}');"
    );

    // 1. SELECT JSON_SET('{"a": 1}', 'b', 2);
    {
      final res = await interpreter.executeScript(
        "SELECT JSON_SET('{\"a\": 1}', 'b', 2) FROM users;"
      );
      expect(res.rows.length, 1);
      final jsonVal = res.rows[0][0];
      expect(jsonVal, isA<DbJson>());
      expect(json.decode(jsonVal.toString()), {'a': 1, 'b': 2});
    }

    // 2. SELECT JSON_REMOVE('{"a": 1, "b": 2}', 'b');
    {
      final res = await interpreter.executeScript(
        "SELECT JSON_REMOVE('{\"a\": 1, \"b\": 2}', 'b') FROM users;"
      );
      expect(res.rows.length, 1);
      final jsonVal = res.rows[0][0];
      expect(jsonVal, isA<DbJson>());
      expect(json.decode(jsonVal.toString()), {'a': 1});
    }

    // 3. SELECT JSON_ARRAY(1, 'two', true);
    {
      final res = await interpreter.executeScript(
        "SELECT JSON_ARRAY(1, 'two', true) FROM users;"
      );
      expect(res.rows.length, 1);
      final jsonVal = res.rows[0][0];
      expect(jsonVal, isA<DbJson>());
      expect(json.decode(jsonVal.toString()), [1, 'two', true]);
    }

    // 4. SELECT JSON_OBJECT('name', 'Alice', 'age', 30);
    {
      final res = await interpreter.executeScript(
        "SELECT JSON_OBJECT('name', 'Alice', 'age', 30) FROM users;"
      );
      expect(res.rows.length, 1);
      final jsonVal = res.rows[0][0];
      expect(jsonVal, isA<DbJson>());
      expect(json.decode(jsonVal.toString()), {'name': 'Alice', 'age': 30});
    }

    // 5. UPDATE users SET info = JSON_SET(info, 'active', true);
    {
      // Prior value check:
      var queryRes = await interpreter.executeScript("SELECT info FROM users;");
      expect(json.decode(queryRes.rows[0][0].toString()), {'active': false});

      // Run update
      await interpreter.executeScript(
        "UPDATE users SET info = JSON_SET(info, 'active', true);"
      );

      // Verify updated value
      queryRes = await interpreter.executeScript("SELECT info FROM users;");
      expect(json.decode(queryRes.rows[0][0].toString()), {'active': true});
    }
  });
}
