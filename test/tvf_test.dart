import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';

void main() {
  const dbDir = 'test_tvf_dir';

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

  test('Table-Valued Functions: simple list/json array of objects', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // Create a function returning a JSON array of JSON objects (sets of rows)
    await interpreter.executeScript('''
CREATE FUNCTION generate_users (base_id INT) RETURNS JSON AS
BEGIN
  RETURN JSON_ARRAY(
    JSON_OBJECT('id', base_id + 1, 'name', 'Alice', 'role', 'Admin'),
    JSON_OBJECT('id', base_id + 2, 'name', 'Bob', 'role', 'User'),
    JSON_OBJECT('id', base_id + 3, 'name', 'Charlie', 'role', 'User')
  );
END;
''');

    // 1. SELECT * FROM generate_users(10);
    final resAll = await interpreter.executeScript('SELECT * FROM generate_users(10);');
    expect(resAll.rows.length, 3);
    expect(resAll.columns, containsAll(['id', 'name', 'role']));
    
    // Check values
    expect((resAll.rows[0][resAll.columns.indexOf('id')] as DbInt).value, 11);
    expect((resAll.rows[0][resAll.columns.indexOf('name')] as DbText).value, 'Alice');
    expect((resAll.rows[0][resAll.columns.indexOf('role')] as DbText).value, 'Admin');

    expect((resAll.rows[1][resAll.columns.indexOf('id')] as DbInt).value, 12);
    expect((resAll.rows[1][resAll.columns.indexOf('name')] as DbText).value, 'Bob');
    expect((resAll.rows[1][resAll.columns.indexOf('role')] as DbText).value, 'User');

    // 2. Select specific columns, with filter and order by
    final resQuery = await interpreter.executeScript(
      'SELECT name, id FROM generate_users(100) WHERE role = \'User\' ORDER BY id DESC;'
    );
    expect(resQuery.rows.length, 2);
    expect(resQuery.columns, equals(['name', 'id']));
    
    // Bob should be second because of DESC order, so Charlie (id 103) is first
    expect((resQuery.rows[0][0] as DbText).value, 'Charlie');
    expect((resQuery.rows[0][1] as DbInt).value, 103);
    
    expect((resQuery.rows[1][0] as DbText).value, 'Bob');
    expect((resQuery.rows[1][1] as DbInt).value, 102);

    await db.close();
  });

  test('Table-Valued Functions: returning array of arrays', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // Create a function returning list of lists
    await interpreter.executeScript('''
CREATE FUNCTION generate_coordinates (scale DOUBLE) RETURNS JSON AS
BEGIN
  RETURN JSON_ARRAY(
    JSON_ARRAY(1.0 * scale, 2.0 * scale),
    JSON_ARRAY(3.0 * scale, 4.0 * scale)
  );
END;
''');

    final res = await interpreter.executeScript('SELECT * FROM generate_coordinates(2.0);');
    expect(res.rows.length, 2);
    expect(res.columns, equals(['col0', 'col1']));
    expect((res.rows[0][0] as DbDouble).value, closeTo(2.0, 0.001));
    expect((res.rows[0][1] as DbDouble).value, closeTo(4.0, 0.001));
    expect((res.rows[1][0] as DbDouble).value, closeTo(6.0, 0.001));
    expect((res.rows[1][1] as DbDouble).value, closeTo(8.0, 0.001));

    await db.close();
  });
}
