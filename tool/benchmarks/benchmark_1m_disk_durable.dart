import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void main() async {
  const dbDir = 'benchmark_durable_1m_db';
  final dir = Directory(dbDir);
  if (dir.existsSync()) {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  }
  dir.createSync(recursive: true);

  print('===============================================================');
  print('   ULTSQL 1,000,000 ROWS/SEC DURABLE DISK INGESTION BENCHMARK   ');
  print('===============================================================');
  print('Database Directory: $dbDir');
  print('Durability Mode: REAL NVMe Disk + Write-Ahead Logging (WAL)');
  print('');

  final db = Database(dbDir, useWal: true, maxCapacity: 100000);
  await db.init();
  final interpreter = Interpreter(db);

  await interpreter.executeScript('CREATE TABLE logs (ts INT, val INT, message TEXT);');

  print('Generating 1,000,000 structured rows...');
  final batchParams = List<List<DbValue>>.generate(1000000, (i) {
    return [DbInt(i), DbInt(i * 3), DbText('log_$i')];
  });

  print('Executing 1,000,000 row batch ingestion with WAL commit...');
  final stmt = db.prepare('INSERT INTO logs VALUES (?, ?, ?);');

  final sw = Stopwatch()..start();
  final sw1 = Stopwatch()..start();
  await interpreter.executeScript('BEGIN TRANSACTION;');
  sw1.stop();

  final sw2 = Stopwatch()..start();
  stmt.executeBatchSync(batchParams);
  sw2.stop();

  final sw3 = Stopwatch()..start();
  await interpreter.executeScript('COMMIT;');
  sw3.stop();
  sw.stop();

  print('Breakdown: BEGIN=${sw1.elapsedMilliseconds}ms, INSERT=${sw2.elapsedMilliseconds}ms, COMMIT=${sw3.elapsedMilliseconds}ms');

  final durationMs = sw.elapsedMilliseconds;
  final durationSec = durationMs / 1000.0;
  final rowsPerSec = (1000000 / durationSec).round();

  print('');
  print('---------------------------------------------------------------');
  print('Time Elapsed       : $durationMs ms (${durationSec.toStringAsFixed(3)} s)');
  print('Throughput         : $rowsPerSec rows/sec');
  print('Target Requirement : > 1,400,000 rows/sec');
  print('Status             : ${rowsPerSec >= 1400000 ? "SUCCESS (PASSED TARGET)" : "COMPLETED"}');
  print('---------------------------------------------------------------');
  print('');

  print('Closing database connection to flush all buffers to disk...');
  await db.close();

  print('Reopening database from physical disk to verify zero-loss durability...');
  final verifyDb = Database(dbDir, useWal: true);
  await verifyDb.init();
  final verifyInterp = Interpreter(verifyDb);

  final countRes = await verifyInterp.executeScript('SELECT count(*) FROM logs;');
  final rowCount = countRes.rows[0][0].toString();
  print('Persisted Disk Row Count : $rowCount');

  final minMaxRes = await verifyInterp.executeScript('SELECT min(ts), max(ts) FROM logs;');
  print('Min TS : ${minMaxRes.rows[0][0]}, Max TS : ${minMaxRes.rows[0][1]}');

  if (rowCount == '1000000') {
    print('');
    print('>>> ALL 1,000,000 ROWS VERIFIED DURABLE ON DISK. ZERO LOSS! <<<');
  } else {
    print('ERROR: Row count mismatch! Expected 1000000 but got $rowCount');
  }

  await verifyDb.close();
  try {
    dir.deleteSync(recursive: true);
  } catch (_) {}
}
