import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/parser/ast.dart';

void main() {
  const dbDir = 'test_data_alter_table_adv';

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

  test('ALTER TABLE RENAME COLUMN and ALTER COLUMN TYPE', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, score INT);');
    await interpreter.executeScript("INSERT INTO users VALUES (1, 'Alice', 100);");

    // 1. Rename column
    final renameRes = await interpreter.executeScript('ALTER TABLE users RENAME COLUMN name TO full_name;');
    expect(renameRes.message, contains('renamed'));

    final query1 = await interpreter.executeScript('SELECT full_name FROM users WHERE id = 1;');
    expect(query1.rows.length, 1);
    expect(query1.rows[0][0].toString(), 'Alice');

    // 2. Alter column type
    final typeRes = await interpreter.executeScript('ALTER TABLE users ALTER COLUMN score TYPE DOUBLE;');
    expect(typeRes.message, contains('altered'));

    final schema = db.catalog.getTableSchema('users')!;
    final scoreIdx = schema.columnNamesLower.indexOf('score');
    expect(schema.columnTypes[scoreIdx], DataType.double);

    await db.close();
  });
}
