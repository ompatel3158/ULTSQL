import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/parser/lexer.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void main() {
  const dbDir = 'test_data_json_operators';

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

  test('JSON path operators -> and ->> integration test', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // Create table
    final createRes = await interpreter.executeScript(
      'CREATE TABLE users (id INT, name TEXT, info JSON);'
    );
    expect(createRes.message, contains("created successfully"));

    // Insert user with JSON info
    final insertRes = await interpreter.executeScript(
      "INSERT INTO users VALUES (1, 'Alice', '{\"name\": \"Alice Smith\", \"age\": 30, \"active\": true}');"
    );
    expect(insertRes.message, contains("inserted successfully"));

    // Select with json path operators
    final selectRes = await interpreter.executeScript(
      "SELECT info->'age', info->>'name' FROM users;"
    );
    expect(selectRes.rows.length, 1);
    
    // The first column is info->'age' which is DbInt(30)
    final ageVal = selectRes.rows[0][0];
    expect(ageVal, isA<DbInt>());
    expect((ageVal as DbInt).value, 30);

    // The second column is info->>'name' which is DbText('Alice Smith')
    final nameVal = selectRes.rows[0][1];
    expect(nameVal, isA<DbText>());
    expect((nameVal as DbText).value, 'Alice Smith');

    // Check query filtering using JSON operators
    final selectRes2 = await interpreter.executeScript(
      "SELECT id FROM users WHERE info->>'name' = 'Alice Smith' AND info->'age' = 30;"
    );
    expect(selectRes2.rows.length, 1);
    expect((selectRes2.rows[0][0] as DbInt).value, 1);

    await db.close();
  });
}
