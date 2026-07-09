import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';

void main() {
  const dbDir = 'test_data_alter_table';

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

  test('ALTER TABLE ADD and DROP Column Support', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // 1. Create a table
    final createRes = await interpreter.executeScript('CREATE TABLE t (id INT, name TEXT);');
    expect(createRes.message, contains("created successfully"));

    // 2. Insert initial records
    await interpreter.executeScript("INSERT INTO t VALUES (1, 'Alice');");
    await interpreter.executeScript("INSERT INTO t VALUES (2, 'Bob');");

    // Verify initial state
    var selectRes = await interpreter.executeScript('SELECT id, name FROM t;');
    expect(selectRes.rows.length, 2);
    expect(selectRes.rows[0][0].toString(), '1');
    expect(selectRes.rows[0][1].toString(), 'Alice');

    // 3. ALTER TABLE ADD COLUMN
    final addRes = await interpreter.executeScript('ALTER TABLE t ADD age INT;');
    expect(addRes.message, contains("successfully"));

    // Verify that the table schema has been updated in Catalog
    final schema = db.catalog.getTableSchema('t');
    expect(schema, isNotNull);
    expect(schema!.columnNames, contains('age'));

    // 4. Select from table containing older records, verifying new column is padded with NULL
    selectRes = await interpreter.executeScript('SELECT id, name, age FROM t;');
    expect(selectRes.rows.length, 2);
    expect(selectRes.rows[0][2], isA<DbNull>());
    expect(selectRes.rows[1][2], isA<DbNull>());

    // 5. Insert new records including the new column (using INSERT which now maps to 3 columns)
    await interpreter.executeScript("INSERT INTO t VALUES (3, 'Charlie', 25);");

    // 6. Select again, verifying Charlie has age 25
    selectRes = await interpreter.executeScript('SELECT id, name, age FROM t ORDER BY id ASC;');
    expect(selectRes.rows.length, 3);
    expect(selectRes.rows[0][0].toString(), '1');
    expect(selectRes.rows[0][2], isA<DbNull>());
    expect(selectRes.rows[2][0].toString(), '3');
    expect(selectRes.rows[2][2].toString(), '25');

    // 7. ALTER TABLE DROP COLUMN
    final dropRes = await interpreter.executeScript('ALTER TABLE t DROP COLUMN age;');
    expect(dropRes.message, contains("successfully"));

    // Verify Catalog schema does not contain age
    final schemaAfterDrop = db.catalog.getTableSchema('t');
    expect(schemaAfterDrop, isNotNull);
    expect(schemaAfterDrop!.columnNames, isNot(contains('age')));

    // 8. Select from table, verifying correctness and that column is completely removed
    selectRes = await interpreter.executeScript('SELECT * FROM t ORDER BY id ASC;');
    expect(selectRes.columns, isNot(contains('age')));
    expect(selectRes.rows.length, 3);
    expect(selectRes.rows[0].length, 2);
    expect(selectRes.rows[0][0].toString(), '1');
    expect(selectRes.rows[0][1].toString(), 'Alice');
    expect(selectRes.rows[2][0].toString(), '3');
    expect(selectRes.rows[2][1].toString(), 'Charlie');

    await db.close();
  });
}
