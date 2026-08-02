import 'dart:io';
import 'dart:math';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:ultsql/src/engine/executor/interpreter.dart' as hybrid;
import 'package:ultsql/src/engine/executor/value.dart';

void main() async {
  const sqliteDbFile = 'test_sqlite_1m.db';
  const hybridDbDir = 'test_hybrid_1m_db';

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
  final hybridTimes = <String, double>{};

  // Generate 1M parameters
  print('Generating 1,000,000 test data rows...');
  final data = List.generate(1000000, (i) {
    final b = rand.nextInt(10000000);
    return [i, b, 'Row $i'];
  });

  // ==========================================
  // SQLITE BENCHMARK
  // ==========================================
  print('\n=== RUNNING SQLITE 1M SQL BENCHMARK ===');
  {
    final db = sqlite.sqlite3.open(sqliteDbFile);
    db.execute('CREATE TABLE t1(a INTEGER, b INTEGER, c TEXT);');

    // 1. 1M Inserts
    print('SQLite: Inserting 1M rows inside a transaction...');
    final sw = Stopwatch()..start();
    db.execute('BEGIN;');
    final stmt = db.prepare('INSERT INTO t1 VALUES (?, ?, ?);');
    for (final row in data) {
      stmt.execute(row);
    }
    stmt.dispose();
    db.execute('COMMIT;');
    sw.stop();
    sqliteTimes['1M Inserts in Tx'] = sw.elapsedMilliseconds / 1000.0;
    print('SQLite 1M Inserts completed in: ${sqliteTimes['1M Inserts in Tx']}s');

    // Create Index
    print('SQLite: Creating index on column b...');
    final swIdx = Stopwatch()..start();
    db.execute('CREATE INDEX idx_t1_b ON t1(b);');
    swIdx.stop();
    sqliteTimes['Create Index'] = swIdx.elapsedMilliseconds / 1000.0;
    print('SQLite Index Create completed in: ${sqliteTimes['Create Index']}s');

    // 2. 1M Reads (Full Scan with Aggregation)
    print('SQLite: Running 1M Full Scan Aggregation...');
    final swRead = Stopwatch()..start();
    final readRes = db.select('SELECT COUNT(*), AVG(b) FROM t1;').first;
    swRead.stop();
    sqliteTimes['1M Reads (Full Scan)'] = swRead.elapsedMilliseconds / 1000.0;
    print('SQLite 1M Reads completed in: ${sqliteTimes['1M Reads (Full Scan)']}s (Count: ${readRes[0]}, Avg: ${readRes[1]})');

    // 3. 5000 Point Lookups (Indexed)
    print('SQLite: Running 5,000 Indexed Point Lookups...');
    final swLookup = Stopwatch()..start();
    final stmtLookup = db.prepare('SELECT a FROM t1 WHERE b = ? LIMIT 1;');
    for (int i = 0; i < 5000; i++) {
      final targetB = data[(i * 199) % 1000000][1];
      stmtLookup.execute([targetB]);
    }
    stmtLookup.dispose();
    swLookup.stop();
    sqliteTimes['5,000 Point Lookups'] = swLookup.elapsedMilliseconds / 1000.0;
    print('SQLite 5k Point Lookups completed in: ${sqliteTimes['5,000 Point Lookups']}s');

    // 4. Delete 100,000 rows
    print('SQLite: Deleting 100,000 rows...');
    final swDelete = Stopwatch()..start();
    db.execute('DELETE FROM t1 WHERE a < 100000;');
    swDelete.stop();
    sqliteTimes['Delete 100k Rows'] = swDelete.elapsedMilliseconds / 1000.0;
    print('SQLite 100k Delete completed in: ${sqliteTimes['Delete 100k Rows']}s');

    db.dispose();
  }

  // ==========================================
  // HYBRID SQL ENGINE BENCHMARK
  // ==========================================
  print('\n=== RUNNING HYBRID SQL ENGINE 1M SQL BENCHMARK ===');
  {
    final db = hybrid.Database(hybridDbDir, useWal: false, maxCapacity: 100000);
    await db.init();
    final interpreter = hybrid.Interpreter(db);

    await interpreter.executeScript('CREATE TABLE t1(a INT, b INT, c TEXT);');

    // 1. 1M Inserts
    print('Hybrid: Inserting 1M rows inside a transaction...');
    final sw = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    final insertStmt = db.prepare('INSERT INTO t1 VALUES (?, ?, ?);');
    final batchParams = data.map((row) => [DbInt(row[0] as int), DbInt(row[1] as int), DbText(row[2] as String)]).toList();
    insertStmt.executeBatchSync(batchParams);
    await interpreter.executeScript('COMMIT;');
    sw.stop();
    hybridTimes['1M Inserts in Tx'] = sw.elapsedMilliseconds / 1000.0;
    print('Hybrid 1M Inserts completed in: ${hybridTimes['1M Inserts in Tx']}s');

    // Create Index
    print('Hybrid: Creating index on column b...');
    final swIdx = Stopwatch()..start();
    await interpreter.executeScript('CREATE INDEX idx_t1_b ON t1(b);');
    swIdx.stop();
    hybridTimes['Create Index'] = swIdx.elapsedMilliseconds / 1000.0;
    print('Hybrid Index Create completed in: ${hybridTimes['Create Index']}s');

    // 2. 1M Reads (Full Scan with Aggregation)
    print('Hybrid: Running 1M Full Scan Aggregation...');
    final swRead = Stopwatch()..start();
    final readRes = await interpreter.executeScript('SELECT COUNT(*), AVG(b) FROM t1;');
    swRead.stop();
    hybridTimes['1M Reads (Full Scan)'] = swRead.elapsedMilliseconds / 1000.0;
    print('Hybrid 1M Reads completed in: ${hybridTimes['1M Reads (Full Scan)']}s (Count: ${readRes.rows[0][0]}, Avg: ${readRes.rows[0][1]})');

    // 3. 5000 Point Lookups (Indexed)
    print('Hybrid: Running 5,000 Indexed Point Lookups...');
    final swLookup = Stopwatch()..start();
    final stmtLookup = db.prepare('SELECT a FROM t1 WHERE b = ? LIMIT 1;');
    for (int i = 0; i < 5000; i++) {
      final targetB = data[(i * 199) % 1000000][1];
      stmtLookup.executeSync([DbInt(targetB as int)]);
    }
    swLookup.stop();
    hybridTimes['5,000 Point Lookups'] = swLookup.elapsedMilliseconds / 1000.0;
    print('Hybrid 5k Point Lookups completed in: ${hybridTimes['5,000 Point Lookups']}s');

    // 4. Delete 100,000 rows
    print('Hybrid: Deleting 100,000 rows...');
    final swDelete = Stopwatch()..start();
    await interpreter.executeScript('BEGIN TRANSACTION;');
    await interpreter.executeScript('DELETE FROM t1 WHERE a < 100000;');
    await interpreter.executeScript('COMMIT;');
    swDelete.stop();
    hybridTimes['Delete 100k Rows'] = swDelete.elapsedMilliseconds / 1000.0;
    print('Hybrid 100k Delete completed in: ${hybridTimes['Delete 100k Rows']}s');

    await db.close();
  }

  // File size comparison
  final sqliteFile = File(sqliteDbFile);
  final sqliteSizeMb = sqliteFile.existsSync() ? sqliteFile.lengthSync() / (1024 * 1024) : 0.0;

  final hybridFile = File('$hybridDbDir/t1.db');
  final hybridSizeMb = hybridFile.existsSync() ? hybridFile.lengthSync() / (1024 * 1024) : 0.0;

  print('\n=== 1M SQL BENCHMARK COMPARISON SUMMARY ===');
  print('------------------------------------------------------------');
  print('| Metric                 | SQLite         | Hybrid SQL Engine |');
  print('------------------------------------------------------------');
  for (final k in sqliteTimes.keys) {
    print('| ${k.padRight(22)} | ${sqliteTimes[k]!.toStringAsFixed(3).padRight(14)}s | ${hybridTimes[k]!.toStringAsFixed(3).padRight(17)}s |');
  }
  print('| Database Size on Disk  | ${sqliteSizeMb.toStringAsFixed(2).padRight(14)}MB | ${hybridSizeMb.toStringAsFixed(2).padRight(17)}MB |');
  print('------------------------------------------------------------');

  // Cleanup files
  try {
    sqliteFile.deleteSync();
    Directory(hybridDbDir).deleteSync(recursive: true);
  } catch (_) {}
}
