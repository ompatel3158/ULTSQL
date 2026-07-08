import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';

void main() {
  const dbDir = 'test_data_rollback';
  Database? db;

  setUp(() async {
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    }
    await dir.create(recursive: true);
  });

  tearDown(() async {
    if (db != null) {
      await db!.close();
      db = null;
    }
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    }
  });

  test('Transactional Rollback reverts inserts and B+ Tree indices', () async {
    db = Database(dbDir);
    await db!.init();
    final interpreter = Interpreter(db!);

    // Create table with B+ Tree index (first column is id)
    await interpreter.executeScript('CREATE TABLE test_table (id INT, value TEXT);');
    await interpreter.executeScript('INSERT INTO test_table VALUES (10, \'First row\');');

    // 1. Transaction insert and manual rollback
    await interpreter.executeScript('BEGIN TRANSACTION;');
    await interpreter.executeScript('INSERT INTO test_table VALUES (20, \'Rollback this row\');');

    // Verify row is temporarily present inside the transaction
    var selectRes = await interpreter.executeScript('SELECT id, value FROM test_table;');
    expect(selectRes.rows.length, 2);

    // Rollback
    final rollbackRes = await interpreter.executeScript('ROLLBACK;');
    expect(rollbackRes.message, contains("Transaction rolled back"));

    // Verify row was removed
    selectRes = await interpreter.executeScript('SELECT id, value FROM test_table;');
    expect(selectRes.rows.length, 1);
    expect(selectRes.rows[0][0].toString(), '10');

    // Verify index lookup also reverted
    final btree = db!.getOrInitIndexSync('test_table');
    final ptrVal = btree.searchSync([20.0]);
    expect(ptrVal, isNull, reason: "B+ Tree index pointer must be reverted/deleted.");

    // 2. Transaction insert and commit
    await interpreter.executeScript('BEGIN;');
    await interpreter.executeScript('INSERT INTO test_table VALUES (30, \'Commit this row\');');
    await interpreter.executeScript('COMMIT;');

    selectRes = await interpreter.executeScript('SELECT id, value FROM test_table;');
    expect(selectRes.rows.length, 2);
    expect(selectRes.rows[1][0].toString(), '30');

    final ptrValCommitted = btree.searchSync([30.0]);
    expect(ptrValCommitted, isNotNull, reason: "B+ Tree index pointer must be preserved on commit.");

    await db!.close();
    db = null;
  });

  test('Automatic rollback on script execution failure cleans up DDL and DML', () async {
    db = Database(dbDir);
    await db!.init();
    final interpreter = Interpreter(db!);

    await interpreter.executeScript('CREATE TABLE base_table (id INT, val TEXT);');
    await interpreter.executeScript('INSERT INTO base_table VALUES (1, \'Clean record\');');

    // Run a script where DDL + DML occurs, but a later statement fails
    final scriptRes = await interpreter.executeScript('''
BEGIN TRANSACTION;
CREATE TABLE temp_table (id INT, category TEXT);
INSERT INTO temp_table VALUES (100, 'Sneakers');
INSERT INTO base_table VALUES (2, 'Modified record');
-- This statement will crash (division by zero or schema mismatch or table not found)
SELECT * FROM non_existent_table;
COMMIT;
''');

    expect(scriptRes.message, contains('Error'));

    // Verify catalog cleaned up 'temp_table'
    expect(db!.catalog.hasTable('temp_table'), isFalse, reason: "temp_table must be removed from catalog on rollback.");

    // Verify base_table insert was reverted
    final selectRes = await interpreter.executeScript('SELECT id, val FROM base_table;');
    expect(selectRes.rows.length, 1);
    expect(selectRes.rows[0][0].toString(), '1');

    await db!.close();
    db = null;
  });
}
