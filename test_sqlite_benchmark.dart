import 'dart:io';
import 'dart:math';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';

String numberToWords(int n) {
  if (n == 0) return 'zero';
  final units = ['', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
                 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'];
  final tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];
  
  String convert(int num) {
    if (num < 20) return units[num];
    if (num < 100) return tens[num ~/ 10] + (num % 10 != 0 ? ' ' + units[num % 10] : '');
    if (num < 1000) return units[num ~/ 100] + ' hundred' + (num % 100 != 0 ? ' ' + convert(num % 100) : '');
    if (num < 1000000) return convert(num ~/ 1000) + ' thousand' + (num % 1000 != 0 ? ' ' + convert(num % 1000) : '');
    return num.toString();
  }
  return convert(n);
}

void main() async {
  const dbDir = 'test_sqlite_benchmark_db';
  final dir = Directory(dbDir);
  if (dir.existsSync()) {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  }
  dir.createSync(recursive: true);

  final db = Database(dbDir);
  await db.init();
  final interpreter = Interpreter(db);

  final results = <String, double>{};
  final rand = Random(42);

  print('=== STARTING SQLITE COMPARATIVE BENCHMARK ===');

  // Test 1: 1000 INSERTs (separate auto-commit transactions)
  {
    print('Running Test 1: 1000 INSERTs (individual transactions)...');
    await interpreter.executeScript('CREATE TABLE t1(a INT, b INT, c TEXT);');
    
    final sw = Stopwatch()..start();
    for (int i = 1; i <= 1000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      await interpreter.executeScript('INSERT INTO t1 VALUES ($i, $b, \'$c\');');
    }
    sw.stop();
    results['Test 1: 1000 INSERTs (sync)'] = sw.elapsedMilliseconds / 1000.0;
  }

  // Test 2: 25000 INSERTs in a transaction
  {
    print('Running Test 2: 25000 INSERTs in a transaction...');
    await interpreter.executeScript('CREATE TABLE t2(a INT, b INT, c TEXT);');
    
    final sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    for (int i = 1; i <= 25000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      await interpreter.executeScript('INSERT INTO t2 VALUES ($i, $b, \'$c\');');
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    results['Test 2: 25000 INSERTs in tx'] = sw.elapsedMilliseconds / 1000.0;
  }

  // Test 3: 25000 INSERTs into an indexed table
  {
    print('Running Test 3: 25000 INSERTs into an indexed table...');
    await interpreter.executeScript('CREATE TABLE t3(a INT, b INT, c TEXT);');
    await interpreter.executeScript('CREATE INDEX i3 ON t3(c);');
    
    final sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    for (int i = 1; i <= 25000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      await interpreter.executeScript('INSERT INTO t3 VALUES ($i, $b, \'$c\');');
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    results['Test 3: 25000 INSERTs into indexed table'] = sw.elapsedMilliseconds / 1000.0;
  }

  // Test 4: 100 SELECTs without an index (requires full table scan)
  {
    print('Running Test 4: 100 SELECTs without an index...');
    final sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    for (int i = 0; i < 100; i++) {
      final low = i * 100;
      final high = low + 1000;
      await interpreter.executeScript('SELECT COUNT(*), AVG(b) FROM t2 WHERE b >= $low AND b < $high;');
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    results['Test 4: 100 SELECTs without index'] = sw.elapsedMilliseconds / 1000.0;
  }

  // Test 5: 100 SELECTs on a string comparison
  {
    print('Running Test 5: 100 SELECTs on a string comparison...');
    final sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    final words = ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'];
    for (int i = 0; i < 100; i++) {
      final word = words[i % words.length];
      await interpreter.executeScript('SELECT COUNT(*), AVG(b) FROM t2 WHERE c LIKE \'%$word%\';');
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    results['Test 5: 100 SELECTs on string LIKE'] = sw.elapsedMilliseconds / 1000.0;
  }

  // Test 6: Creating an index
  {
    print('Running Test 6: Creating an index...');
    final sw = Stopwatch()..start();
    await interpreter.executeScript('CREATE INDEX i2a ON t2(a);');
    await interpreter.executeScript('CREATE INDEX i2b ON t2(b);');
    sw.stop();
    results['Test 6: Creating indices'] = sw.elapsedMilliseconds / 1000.0;
  }

  // Test 7: 5000 SELECTs with an index
  {
    print('Running Test 7: 5000 SELECTs with an index...');
    final sw = Stopwatch()..start();
    for (int i = 0; i < 5000; i++) {
      final low = (i * 100) % 50000;
      final high = low + 100;
      await interpreter.executeScript('SELECT COUNT(*), AVG(b) FROM t2 WHERE b >= $low AND b < $high;');
    }
    sw.stop();
    results['Test 7: 5000 SELECTs with index'] = sw.elapsedMilliseconds / 1000.0;
  }

  // Test 11: INSERTs from a SELECT
  {
    print('Running Test 11: INSERTs from SELECT...');
    final sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    final selectT2 = await interpreter.executeScript('SELECT b, a, c FROM t2;');
    for (final row in selectT2.rows) {
      await interpreter.executeScript('INSERT INTO t1 VALUES (${row[1]}, ${row[0]}, \'${row[2].toString().replaceAll("'", "''")}\');');
    }
    final selectT1 = await interpreter.executeScript('SELECT b, a, c FROM t1 LIMIT 25000;');
    for (final row in selectT1.rows) {
      await interpreter.executeScript('INSERT INTO t2 VALUES (${row[1]}, ${row[0]}, \'${row[2].toString().replaceAll("'", "''")}\');');
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    results['Test 11: INSERTs from SELECT'] = sw.elapsedMilliseconds / 1000.0;
  }

  // Test 12: DELETE without an index
  {
    print('Running Test 12: DELETE without an index...');
    final sw = Stopwatch()..start();
    await interpreter.executeScript('DELETE FROM t2 WHERE c LIKE \'%fifty%\';');
    sw.stop();
    results['Test 12: DELETE without index'] = sw.elapsedMilliseconds / 1000.0;
  }

  // Test 13: DELETE with an index
  {
    print('Running Test 13: DELETE with an index...');
    final sw = Stopwatch()..start();
    await interpreter.executeScript('DELETE FROM t2 WHERE a > 10 AND a < 20000;');
    sw.stop();
    results['Test 13: DELETE with index'] = sw.elapsedMilliseconds / 1000.0;
  }

  // Test 14: A big INSERT after a big DELETE
  {
    print('Running Test 14: Big INSERT after big DELETE...');
    final sw = Stopwatch()..start();
    final selectT1 = await interpreter.executeScript('SELECT * FROM t1 LIMIT 25000;');
    await interpreter.executeScript('BEGIN TRANSACTION;');
    for (final row in selectT1.rows) {
      await interpreter.executeScript('INSERT INTO t2 VALUES (${row[0]}, ${row[1]}, \'${row[2].toString().replaceAll("'", "''")}\');');
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    results['Test 14: Big INSERT after big DELETE'] = sw.elapsedMilliseconds / 1000.0;
  }

  // Test 15: A big DELETE followed by many small INSERTs
  {
    print('Running Test 15: Big DELETE followed by small INSERTs...');
    final sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    await interpreter.executeScript('DELETE FROM t1;');
    for (int i = 1; i <= 12000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      await interpreter.executeScript('INSERT INTO t1 VALUES ($i, $b, \'$c\');');
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    results['Test 15: Big DELETE + small INSERTs'] = sw.elapsedMilliseconds / 1000.0;
  }

  // Test 16: DROP TABLE
  {
    print('Running Test 16: DROP TABLE...');
    final sw = Stopwatch()..start();
    await db.close();
    for (final name in ['t1', 't2', 't3']) {
      final dbFile = File('$dbDir/$name.db');
      if (dbFile.existsSync()) dbFile.deleteSync();
      final idxFile = File('$dbDir/idx_${name}_age.idx');
      if (idxFile.existsSync()) idxFile.deleteSync();
    }
    sw.stop();
    results['Test 16: DROP TABLE'] = sw.elapsedMilliseconds / 1000.0;
  }

  await db.close();

  print('\n=== RESULTS SUMMARY ===');
  results.forEach((test, time) {
    print('$test: ${time.toStringAsFixed(3)} seconds');
  });
}
