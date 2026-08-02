import 'dart:io';
import 'dart:math';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:ultsql/src/engine/executor/interpreter.dart' as hybrid;
import 'package:ultsql/src/engine/executor/value.dart';

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

Future<void> main() async {
  const sqliteDbFile = 'test_sqlite.db';
  const hybridDbDir = 'test_hybrid_hardware_db';

  // Cleanup
  for (final f in [sqliteDbFile, sqliteDbFile + '-journal', sqliteDbFile + '-wal']) {
    final file = File(f);
    if (file.existsSync()) {
      try { file.deleteSync(); } catch (_) {}
    }
  }
  final dir = Directory(hybridDbDir);
  if (dir.existsSync()) {
    try { dir.deleteSync(recursive: true); } catch (_) {}
  }
  dir.createSync(recursive: true);

  final rand = Random(42);
  final sqliteTimes = <String, double>{};
  final sqliteNosyncTimes = <String, double>{};
  final hybridTimes = <String, double>{};

  // ==========================================
  // RUN SQLITE BENCHMARK
  // ==========================================
  print('=== STARTING SQLITE BENCHMARK ===');
  {
    final db = sqlite.sqlite3.open(sqliteDbFile);
    
    // Test 1: 1000 INSERTs (separate auto-commit transactions)
    db.execute('CREATE TABLE t1(a INTEGER, b INTEGER, c TEXT);');
    var sw = Stopwatch()..start();
    for (int i = 1; i <= 1000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      db.execute('INSERT INTO t1 VALUES (?, ?, ?);', [i, b, c]);
    }
    sw.stop();
    sqliteTimes['Test 1: 1000 INSERTs (sync)'] = sw.elapsedMilliseconds / 1000.0;

    // Test 2: 25000 INSERTs in a transaction
    db.execute('CREATE TABLE t2(a INTEGER, b INTEGER, c TEXT);');
    sw = Stopwatch()..start();
    db.execute('BEGIN;');
    final stmt = db.prepare('INSERT INTO t2 VALUES (?, ?, ?);');
    for (int i = 1; i <= 25000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      stmt.execute([i, b, c]);
    }
    stmt.dispose();
    db.execute('COMMIT;');
    sw.stop();
    sqliteTimes['Test 2: 25000 INSERTs in tx'] = sw.elapsedMilliseconds / 1000.0;

    // Test 3: 25000 INSERTs into indexed table
    db.execute('CREATE TABLE t3(a INTEGER, b INTEGER, c TEXT);');
    db.execute('CREATE INDEX i3 ON t3(c);');
    sw = Stopwatch()..start();
    db.execute('BEGIN;');
    final stmt3 = db.prepare('INSERT INTO t3 VALUES (?, ?, ?);');
    for (int i = 1; i <= 25000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      stmt3.execute([i, b, c]);
    }
    stmt3.dispose();
    db.execute('COMMIT;');
    sw.stop();
    sqliteTimes['Test 3: 25000 INSERTs (indexed)'] = sw.elapsedMilliseconds / 1000.0;

    // Test 4: 100 SELECTs without index (requires full table scan)
    sw = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      final low = i * 100;
      final high = low + 1000;
      final row = db.select('SELECT COUNT(*), AVG(b) FROM t2 WHERE b >= ? AND b < ?;', [low, high]).first;
    }
    sw.stop();
    sqliteTimes['Test 4: 100 SELECTs (no index)'] = sw.elapsedMilliseconds / 1000.0;

    // Test 5: 100 SELECTs on string comparison
    sw = Stopwatch()..start();
    final words = ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'];
    for (int i = 0; i < 100; i++) {
      final word = words[i % words.length];
      db.select('SELECT COUNT(*), AVG(b) FROM t2 WHERE c LIKE ?;', ['%$word%']);
    }
    sw.stop();
    sqliteTimes['Test 5: 100 SELECTs (string LIKE)'] = sw.elapsedMilliseconds / 1000.0;

    // Test 6: Creating indices
    sw = Stopwatch()..start();
    db.execute('CREATE INDEX i2a ON t2(a);');
    db.execute('CREATE INDEX i2b ON t2(b);');
    sw.stop();
    sqliteTimes['Test 6: Creating indices'] = sw.elapsedMilliseconds / 1000.0;

    // Test 7: 5000 SELECTs with index
    sw = Stopwatch()..start();
    for (int i = 0; i < 5000; i++) {
      final low = (i * 100) % 50000;
      final high = low + 100;
      db.select('SELECT COUNT(*), AVG(b) FROM t2 WHERE b >= ? AND b < ?;', [low, high]);
    }
    sw.stop();
    sqliteTimes['Test 7: 5000 SELECTs with index'] = sw.elapsedMilliseconds / 1000.0;

    // Test 11: INSERTs from SELECT
    sw = Stopwatch()..start();
    db.execute('BEGIN;');
    db.execute('INSERT INTO t1 SELECT b, a, c FROM t2;');
    db.execute('INSERT INTO t2 SELECT b, a, c FROM t1 LIMIT 25000;');
    db.execute('COMMIT;');
    sw.stop();
    sqliteTimes['Test 11: INSERTs from SELECT'] = sw.elapsedMilliseconds / 1000.0;

    // Test 12: DELETE without index
    sw = Stopwatch()..start();
    db.execute('DELETE FROM t2 WHERE c LIKE \'%fifty%\';');
    sw.stop();
    sqliteTimes['Test 12: DELETE without index'] = sw.elapsedMilliseconds / 1000.0;

    // Test 13: DELETE with index
    sw = Stopwatch()..start();
    db.execute('DELETE FROM t2 WHERE a > 10 AND a < 20000;');
    sw.stop();
    sqliteTimes['Test 13: DELETE with index'] = sw.elapsedMilliseconds / 1000.0;

    // Test 14: Big INSERT after big DELETE
    sw = Stopwatch()..start();
    db.execute('BEGIN;');
    db.execute('INSERT INTO t2 SELECT * FROM t1 LIMIT 25000;');
    db.execute('COMMIT;');
    sw.stop();
    sqliteTimes['Test 14: Big INSERT after DELETE'] = sw.elapsedMilliseconds / 1000.0;

    // Test 15: Big DELETE followed by small INSERTs
    sw = Stopwatch()..start();
    db.execute('BEGIN;');
    db.execute('DELETE FROM t1;');
    final stmt15 = db.prepare('INSERT INTO t1 VALUES (?, ?, ?);');
    for (int i = 1; i <= 12000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      stmt15.execute([i, b, c]);
    }
    stmt15.dispose();
    db.execute('COMMIT;');
    sw.stop();
    sqliteTimes['Test 15: Big DELETE + small INSERTs'] = sw.elapsedMilliseconds / 1000.0;

    // Test 16: DROP TABLE
    sw = Stopwatch()..start();
    db.execute('DROP TABLE t1;');
    db.execute('DROP TABLE t2;');
    db.execute('DROP TABLE t3;');
    sw.stop();
    sqliteTimes['Test 16: DROP TABLE'] = sw.elapsedMilliseconds / 1000.0;

    db.dispose();
  }

  // ==========================================
  // RUN SQLITE BENCHMARK (NOSYNC)
  // ==========================================
  print('=== STARTING SQLITE BENCHMARK (NOSYNC) ===');
  {
    for (final f in [sqliteDbFile, sqliteDbFile + '-journal', sqliteDbFile + '-wal']) {
      final file = File(f);
      if (file.existsSync()) {
        try { file.deleteSync(); } catch (_) {}
      }
    }

    final db = sqlite.sqlite3.open(sqliteDbFile);
    db.execute('PRAGMA synchronous = OFF;');
    db.execute('PRAGMA journal_mode = MEMORY;');

    // Test 1: 1000 INSERTs (nosync)
    db.execute('CREATE TABLE t1(a INTEGER, b INTEGER, c TEXT);');
    var sw = Stopwatch()..start();
    for (int i = 1; i <= 1000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      db.execute('INSERT INTO t1 VALUES (?, ?, ?);', [i, b, c]);
    }
    sw.stop();
    sqliteNosyncTimes['Test 1: 1000 INSERTs (sync)'] = sw.elapsedMilliseconds / 1000.0;

    // Test 2: 25000 INSERTs in a transaction
    db.execute('CREATE TABLE t2(a INTEGER, b INTEGER, c TEXT);');
    sw = Stopwatch()..start();
    db.execute('BEGIN;');
    final stmt = db.prepare('INSERT INTO t2 VALUES (?, ?, ?);');
    for (int i = 1; i <= 25000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      stmt.execute([i, b, c]);
    }
    stmt.dispose();
    db.execute('COMMIT;');
    sw.stop();
    sqliteNosyncTimes['Test 2: 25000 INSERTs in tx'] = sw.elapsedMilliseconds / 1000.0;

    // Test 3: 25000 INSERTs into indexed table
    db.execute('CREATE TABLE t3(a INTEGER, b INTEGER, c TEXT);');
    db.execute('CREATE INDEX i3 ON t3(c);');
    sw = Stopwatch()..start();
    db.execute('BEGIN;');
    final stmt3 = db.prepare('INSERT INTO t3 VALUES (?, ?, ?);');
    for (int i = 1; i <= 25000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      stmt3.execute([i, b, c]);
    }
    stmt3.dispose();
    db.execute('COMMIT;');
    sw.stop();
    sqliteNosyncTimes['Test 3: 25000 INSERTs (indexed)'] = sw.elapsedMilliseconds / 1000.0;

    // Test 4: 100 SELECTs without index (requires full table scan)
    sw = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      final low = i * 100;
      final high = low + 1000;
      db.select('SELECT COUNT(*), AVG(b) FROM t2 WHERE b >= ? AND b < ?;', [low, high]).first;
    }
    sw.stop();
    sqliteNosyncTimes['Test 4: 100 SELECTs (no index)'] = sw.elapsedMilliseconds / 1000.0;

    // Test 5: 100 SELECTs on string comparison
    sw = Stopwatch()..start();
    final words = ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'];
    for (int i = 0; i < 100; i++) {
      final word = words[i % words.length];
      db.select('SELECT COUNT(*), AVG(b) FROM t2 WHERE c LIKE ?;', ['%$word%']);
    }
    sw.stop();
    sqliteNosyncTimes['Test 5: 100 SELECTs (string LIKE)'] = sw.elapsedMilliseconds / 1000.0;

    // Test 6: Creating indices
    sw = Stopwatch()..start();
    db.execute('CREATE INDEX i2a ON t2(a);');
    db.execute('CREATE INDEX i2b ON t2(b);');
    sw.stop();
    sqliteNosyncTimes['Test 6: Creating indices'] = sw.elapsedMilliseconds / 1000.0;

    // Test 7: 5000 SELECTs with index
    sw = Stopwatch()..start();
    for (int i = 0; i < 5000; i++) {
      final low = (i * 100) % 50000;
      final high = low + 100;
      db.select('SELECT COUNT(*), AVG(b) FROM t2 WHERE b >= ? AND b < ?;', [low, high]);
    }
    sw.stop();
    sqliteNosyncTimes['Test 7: 5000 SELECTs with index'] = sw.elapsedMilliseconds / 1000.0;

    // Test 11: INSERTs from SELECT
    sw = Stopwatch()..start();
    db.execute('BEGIN;');
    db.execute('INSERT INTO t1 SELECT b, a, c FROM t2;');
    db.execute('INSERT INTO t2 SELECT b, a, c FROM t1 LIMIT 25000;');
    db.execute('COMMIT;');
    sw.stop();
    sqliteNosyncTimes['Test 11: INSERTs from SELECT'] = sw.elapsedMilliseconds / 1000.0;

    // Test 12: DELETE without index
    sw = Stopwatch()..start();
    db.execute('DELETE FROM t2 WHERE c LIKE \'%fifty%\';');
    sw.stop();
    sqliteNosyncTimes['Test 12: DELETE without index'] = sw.elapsedMilliseconds / 1000.0;

    // Test 13: DELETE with index
    sw = Stopwatch()..start();
    db.execute('DELETE FROM t2 WHERE a > 10 AND a < 20000;');
    sw.stop();
    sqliteNosyncTimes['Test 13: DELETE with index'] = sw.elapsedMilliseconds / 1000.0;

    // Test 14: Big INSERT after big DELETE
    sw = Stopwatch()..start();
    db.execute('BEGIN;');
    db.execute('INSERT INTO t2 SELECT * FROM t1 LIMIT 25000;');
    db.execute('COMMIT;');
    sw.stop();
    sqliteNosyncTimes['Test 14: Big INSERT after DELETE'] = sw.elapsedMilliseconds / 1000.0;

    // Test 15: Big DELETE followed by small INSERTs
    sw = Stopwatch()..start();
    db.execute('BEGIN;');
    db.execute('DELETE FROM t1;');
    final stmt15 = db.prepare('INSERT INTO t1 VALUES (?, ?, ?);');
    for (int i = 1; i <= 12000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      stmt15.execute([i, b, c]);
    }
    stmt15.dispose();
    db.execute('COMMIT;');
    sw.stop();
    sqliteNosyncTimes['Test 15: Big DELETE + small INSERTs'] = sw.elapsedMilliseconds / 1000.0;

    // Test 16: DROP TABLE
    sw = Stopwatch()..start();
    db.execute('DROP TABLE t1;');
    db.execute('DROP TABLE t2;');
    db.execute('DROP TABLE t3;');
    sw.stop();
    sqliteNosyncTimes['Test 16: DROP TABLE'] = sw.elapsedMilliseconds / 1000.0;

    db.dispose();
  }

  // ==========================================
  // RUN HYBRID SQL ENGINE BENCHMARK
  // ==========================================
  print('=== STARTING HYBRID SQL ENGINE BENCHMARK ===');
  {
    final db = hybrid.Database(hybridDbDir);
    await db.init();
    final interpreter = hybrid.Interpreter(db);

    // Warmup the Dart VM JIT compiler
    {
      await interpreter.executeScript('CREATE TABLE t_warmup(a INT, b INT, c TEXT);');
      await interpreter.executeScript('BEGIN TRANSACTION;');
      final stmt = db.prepare('INSERT INTO t_warmup VALUES (?, ?, ?);');
      for (int i = 1; i <= 5000; i++) {
        stmt.executeSync([DbInt(i), DbInt(i), DbText('Warmup $i')]);
      }
      await interpreter.executeScript('COMMIT;');
      await interpreter.executeScript('CREATE INDEX i_warmup ON t_warmup(c);');
      await interpreter.executeScript('SELECT COUNT(*), AVG(b) FROM t_warmup WHERE b >= 1000 AND b < 2000;');
      await interpreter.executeScript('DROP TABLE t_warmup;');
    }

    // Test 1: 1000 INSERTs (separate auto-commit transactions)
    await interpreter.executeScript('CREATE TABLE t1(a INT, b INT, c TEXT);');
    var sw = Stopwatch()..start();
    final stmt1 = db.prepare('INSERT INTO t1 VALUES (?, ?, ?);');
    for (int i = 1; i <= 1000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      stmt1.executeSync([DbInt(i), DbInt(b), DbText(c)]);
    }
    sw.stop();
    hybridTimes['Test 1: 1000 INSERTs (sync)'] = sw.elapsedMilliseconds / 1000.0;

    // Test 2: 25000 INSERTs in a transaction
    await interpreter.executeScript('CREATE TABLE t2(a INT, b INT, c TEXT);');
    sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    final stmt2 = db.prepare('INSERT INTO t2 VALUES (?, ?, ?);');
    for (int i = 1; i <= 25000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      stmt2.executeSync([DbInt(i), DbInt(b), DbText(c)]);
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    hybridTimes['Test 2: 25000 INSERTs in tx'] = sw.elapsedMilliseconds / 1000.0;

    // Test 3: 25000 INSERTs into indexed table
    await interpreter.executeScript('CREATE TABLE t3(a INT, b INT, c TEXT);');
    await interpreter.executeScript('CREATE INDEX i3 ON t3(c);');
    sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    final stmt3 = db.prepare('INSERT INTO t3 VALUES (?, ?, ?);');
    for (int i = 1; i <= 25000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      stmt3.executeSync([DbInt(i), DbInt(b), DbText(c)]);
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    hybridTimes['Test 3: 25000 INSERTs (indexed)'] = sw.elapsedMilliseconds / 1000.0;

    // Test 4: 100 SELECTs without index (requires full table scan)
    sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    final stmt4 = db.prepare('SELECT COUNT(*), AVG(b) FROM t2 WHERE b >= ? AND b < ?;');
    for (int i = 0; i < 100; i++) {
      final low = i * 100;
      final high = low + 1000;
      stmt4.executeSync([DbInt(low), DbInt(high)]);
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    hybridTimes['Test 4: 100 SELECTs (no index)'] = sw.elapsedMilliseconds / 1000.0;

    // Test 5: 100 SELECTs on string comparison
    sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    final stmt5 = db.prepare('SELECT COUNT(*), AVG(b) FROM t2 WHERE c LIKE ?;');
    final words = ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'];
    for (int i = 0; i < 100; i++) {
      final word = words[i % words.length];
      stmt5.executeSync([DbText('%$word%')]);
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    hybridTimes['Test 5: 100 SELECTs (string LIKE)'] = sw.elapsedMilliseconds / 1000.0;

    // Test 6: Creating indices
    sw = Stopwatch()..start();
    await interpreter.executeScript('CREATE INDEX i2a ON t2(a);');
    await interpreter.executeScript('CREATE INDEX i2b ON t2(b);');
    sw.stop();
    hybridTimes['Test 6: Creating indices'] = sw.elapsedMilliseconds / 1000.0;

    // Test 7: 5000 SELECTs with index
    sw = Stopwatch()..start();
    final stmt7 = db.prepare('SELECT COUNT(*), AVG(b) FROM t2 WHERE b >= ? AND b < ?;');
    for (int i = 0; i < 5000; i++) {
      final low = (i * 100) % 50000;
      final high = low + 100;
      stmt7.executeSync([DbInt(low), DbInt(high)]);
    }
    sw.stop();
    hybridTimes['Test 7: 5000 SELECTs with index'] = sw.elapsedMilliseconds / 1000.0;

    // Test 11: INSERTs from SELECT
    sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    final selectT2 = await interpreter.executeScript('SELECT b, a, c FROM t2;');
    final stmt11_1 = db.prepare('INSERT INTO t1 VALUES (?, ?, ?);');
    for (final row in selectT2.rows) {
      stmt11_1.executeSync([row[1], row[0], row[2]]);
    }
    final selectT1 = await interpreter.executeScript('SELECT b, a, c FROM t1 LIMIT 25000;');
    final stmt11_2 = db.prepare('INSERT INTO t2 VALUES (?, ?, ?);');
    for (final row in selectT1.rows) {
      stmt11_2.executeSync([row[1], row[0], row[2]]);
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    hybridTimes['Test 11: INSERTs from SELECT'] = sw.elapsedMilliseconds / 1000.0;

    // Test 12: DELETE without index
    sw = Stopwatch()..start();
    final stmt12 = db.prepare('DELETE FROM t2 WHERE c LIKE ?;');
    stmt12.executeSync([DbText('%fifty%')]);
    sw.stop();
    hybridTimes['Test 12: DELETE without index'] = sw.elapsedMilliseconds / 1000.0;

    // Test 13: DELETE with index
    sw = Stopwatch()..start();
    final stmt13 = db.prepare('DELETE FROM t2 WHERE a > ? AND a < ?;');
    stmt13.executeSync([DbInt(10), DbInt(20000)]);
    sw.stop();
    hybridTimes['Test 13: DELETE with index'] = sw.elapsedMilliseconds / 1000.0;

    // Test 14: Big INSERT after big DELETE
    sw = Stopwatch()..start();
    final selectT1_14 = await interpreter.executeScript('SELECT * FROM t1 LIMIT 25000;');
    await interpreter.executeScript('BEGIN TRANSACTION;');
    final stmt14 = db.prepare('INSERT INTO t2 VALUES (?, ?, ?);');
    for (final row in selectT1_14.rows) {
      stmt14.executeSync([row[0], row[1], row[2]]);
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    hybridTimes['Test 14: Big INSERT after DELETE'] = sw.elapsedMilliseconds / 1000.0;

    // Test 15: Big DELETE followed by small INSERTs
    sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    await interpreter.executeScript('DELETE FROM t1;');
    final stmt15 = db.prepare('INSERT INTO t1 VALUES (?, ?, ?);');
    for (int i = 1; i <= 12000; i++) {
      final b = rand.nextInt(100000);
      final c = numberToWords(b);
      stmt15.executeSync([DbInt(i), DbInt(b), DbText(c)]);
    }
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    hybridTimes['Test 15: Big DELETE + small INSERTs'] = sw.elapsedMilliseconds / 1000.0;

    // Test 16: DROP TABLE
    sw = Stopwatch()..start();
    await db.close();
    for (final name in ['t1', 't2', 't3']) {
      final dbFile = File('$hybridDbDir/$name.db');
      if (dbFile.existsSync()) dbFile.deleteSync();
      final idxFile = File('$hybridDbDir/idx_${name}_age.idx');
      if (idxFile.existsSync()) idxFile.deleteSync();
    }
    sw.stop();
    hybridTimes['Test 16: DROP TABLE'] = sw.elapsedMilliseconds / 1000.0;

    await db.close();
  }

  // Clean up database files
  for (final f in [sqliteDbFile, sqliteDbFile + '-journal', sqliteDbFile + '-wal']) {
    final file = File(f);
    if (file.existsSync()) {
      try { file.deleteSync(); } catch (_) {}
    }
  }
  if (dir.existsSync()) {
    try { dir.deleteSync(recursive: true); } catch (_) {}
  }

  print('\n=== SIDE-BY-SIDE HARDWARE BENCHMARK COMPARISON ===');
  print('-----------------------------------------------------------------------------------------------------');
  print('| Benchmark Category                     | SQLite (Sync) | SQLite (NoSync) | Hybrid SQL Engine (Ours) |');
  print('-----------------------------------------------------------------------------------------------------');
  final keys = sqliteTimes.keys.toList();
  for (final key in keys) {
    final sqVal = sqliteTimes[key]!.toStringAsFixed(3) + 's';
    final sqNoVal = sqliteNosyncTimes[key]!.toStringAsFixed(3) + 's';
    final hyVal = hybridTimes[key]!.toStringAsFixed(3) + 's';
    print('| ${key.padRight(38)} | ${sqVal.padLeft(13)} | ${sqNoVal.padLeft(15)} | ${hyVal.padLeft(24)} |');
  }
  print('-----------------------------------------------------------------------------------------------------');
}
