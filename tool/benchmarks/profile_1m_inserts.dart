import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void main() async {
  const dbDir = 'test_profile_1m_db';
  final dir = Directory(dbDir);
  if (dir.existsSync()) {
    try { dir.deleteSync(recursive: true); } catch (_) {}
  }
  dir.createSync(recursive: true);

  final db = Database(dbDir, maxCapacity: 100000);
  await db.init();
  final interpreter = Interpreter(db);

  await interpreter.executeScript('CREATE TABLE t1(a INT, b INT, c TEXT);');

  print('Generating 1,000,000 parameter rows...');
  final batchParams = List<List<DbValue>>.generate(1000000, (i) {
    return [DbInt(i), DbInt(i * 2), DbText('Row $i')];
  });

  final sw = Stopwatch()..start();
  final sw1 = Stopwatch()..start();
  await interpreter.executeScript('BEGIN TRANSACTION;');
  sw1.stop();

  final sw2 = Stopwatch()..start();
  final stmt = db.prepare('INSERT INTO t1 VALUES (?, ?, ?);');
  stmt.executeBatchSync(batchParams);
  sw2.stop();

  final sw3 = Stopwatch()..start();
  await interpreter.executeScript('COMMIT;');
  sw3.stop();
  sw.stop();

  print('Breakdown: BEGIN=${sw1.elapsedMilliseconds}ms, INSERT=${sw2.elapsedMilliseconds}ms, COMMIT=${sw3.elapsedMilliseconds}ms');

  final double durationInSecs = sw.elapsedMilliseconds / 1000.0;
  final double rowsPerSec = 1000000 / durationInSecs;
  print('=== BATCH INSERT BENCHMARK RESULTS ===');
  print('Inserted 1,000,000 rows in ${sw.elapsedMilliseconds} ms (${rowsPerSec.toStringAsFixed(0)} rows/sec)');

  await db.close();

  print('Reopening from disk to verify...');
  final verifyDb = Database(dbDir);
  await verifyDb.init();
  final verifyInterp = Interpreter(verifyDb);
  final countRes = await verifyInterp.executeScript('SELECT count(*) FROM t1;');
  print('Persisted Row Count: ${countRes.rows[0][0]}');
  await verifyDb.close();

  try { dir.deleteSync(recursive: true); } catch (_) {}
}
