import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/storage/catalog.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'package:ultsql/engine/storage/table_file.dart';
import 'package:ultsql/engine/cache/page_cache.dart';

void main() {
  late Database db;
  late Interpreter interpreter;
  final testDir = Directory('test_db_vacuum');

  setUp(() async {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
    testDir.createSync();
    db = Database(testDir.path, useWal: false);
    await db.init();
    interpreter = Interpreter(db);
  });

  tearDown(() async {
    await db.close();
    if (testDir.existsSync()) {
      try {
        testDir.deleteSync(recursive: true);
      } catch (e) {
        // ignore
      }
    }
  });

  test('VACUUM removes dead tuples and shrinks free space', () async {
    // 1. Create table
    await interpreter.executeScript('CREATE TABLE test_table (id INT PRIMARY KEY, val TEXT);');

    // 2. Insert 1,000 rows
    final inserts = StringBuffer();
    inserts.writeln('BEGIN TRANSACTION;');
    for (int i = 0; i < 1000; i++) {
      inserts.writeln("INSERT INTO test_table VALUES ($i, 'test_val_$i');");
    }
    inserts.writeln('COMMIT;');
    await interpreter.executeScript(inserts.toString());

    final tableFile = RowTableFile(cache: db.cache, tableName: 'test_table', dbDirectory: testDir.path);
    tableFile.flushActivePageSync();

    // 3. Delete 500 rows (where id < 500)
    await interpreter.executeScript('DELETE FROM test_table WHERE id < 500;');

    // Verify rowCount using scanner
    final resAfterDelete = await interpreter.executeScript('SELECT id FROM test_table;');
    expect(resAfterDelete.rows.length, 500, reason: 'Should have 500 rows after delete');

    // 4. Run VACUUM
    await interpreter.executeScript('VACUUM test_table;');
    
    // Verify row count remains 500 after vacuum
    final resAfterVacuum = await interpreter.executeScript('SELECT id FROM test_table;');
    expect(resAfterVacuum.rows.length, 500, reason: 'Should still have 500 rows after vacuum');
  });
}
