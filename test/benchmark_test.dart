import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/executor/interpreter.dart';

void main() {
  test('Benchmark query execution breakdown (1,000 rows)', () async {
    final dbDir = 'test_benchmark_db_small';
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // Initial table setup
    await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, dept_id INT);');
    await interpreter.executeScript('INSERT INTO users VALUES (1, \'Alice\', 10);');
    await interpreter.executeScript('INSERT INTO users VALUES (2, \'Bob\', 20);');

    // Run SELECT query 1000 times
    final sw = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      await interpreter.executeScript('SELECT name FROM users WHERE id = 1;');
    }
    sw.stop();
    print('Total time for 1000 SELECT queries: ${sw.elapsedMilliseconds}ms (${sw.elapsedMilliseconds / 1000}ms per query)');

    // Run INSERT query 1000 times
    final swInsert = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    for (int i = 0; i < 1000; i++) {
      await interpreter.executeScript('INSERT INTO users VALUES (${3 + i}, \'User_${i}\', 10);');
    }
    await interpreter.executeScript('COMMIT;');
    swInsert.stop();
    print('Total time for 1000 INSERT queries: ${swInsert.elapsedMilliseconds}ms (${swInsert.elapsedMilliseconds / 1000}ms per query)');

    await db.close();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('Benchmark scale testing (100,000 insertions and reads)', () async {
    final dbDir = 'test_benchmark_db_large';
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // 1. DDL Setup
    await interpreter.executeScript('CREATE TABLE large_table (id INT, name TEXT, value INT);');

    // 2. Benchmark 100,000 inserts using PL/SQL Transaction loop
    print('\nStarting 100,000 inserts benchmark...');
    final swInsert = Stopwatch()..start();
    final plsqlInsert = '''
DECLARE
  c INT := 0;
BEGIN
  BEGIN TRANSACTION;
  WHILE c < 100000 LOOP
    c := c + 1;
    INSERT INTO large_table VALUES (c, 'User_Label', 100);
  END LOOP;
  COMMIT;
END;
''';
    final insertRes = await interpreter.executeScript(plsqlInsert);
    swInsert.stop();
    expect(insertRes.message, contains('committed'));
    print('100,000 Inserts completed in: ${swInsert.elapsedMilliseconds}ms (${swInsert.elapsedMilliseconds / 100000}ms per insert)');
    print('Throughput: ${(100000 / (swInsert.elapsedMilliseconds / 1000)).toStringAsFixed(0)} inserts/second');

    // 3. Benchmark Point Lookups (utilizing B+ Tree index)
    print('\nStarting 1000 Point Lookups (B+ Tree index scan)...');
    final swIndex = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      // Lookup middle keys
      final searchKey = 50000 + (i % 100);
      final selectRes = await interpreter.executeScript('SELECT name FROM large_table WHERE id = $searchKey;');
      expect(selectRes.rows.length, 1);
    }
    swIndex.stop();
    print('1,000 Index Lookups completed in: ${swIndex.elapsedMilliseconds}ms (${swIndex.elapsedMilliseconds / 1000}ms per lookup)');

    // 4. Benchmark Full Table Scan (100k rows scan & JIT execution)
    print('\nStarting Full Table Scan & Filter (100,000 rows)...');
    final swScan = Stopwatch()..start();
    final scanRes = await interpreter.executeScript('SELECT id FROM large_table WHERE value = 200;'); // Matches 0 rows
    swScan.stop();
    expect(scanRes.rows.length, 0);
    print('Full Table Scan (100,000 rows scan + JIT filter) completed in: ${swScan.elapsedMilliseconds}ms');

    await db.close();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });
}
