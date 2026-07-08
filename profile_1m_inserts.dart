import 'dart:io';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';

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

  print('Inserting 1,000,000 rows in a single transaction...');
  final sw = Stopwatch()..start();
  await interpreter.executeScript('BEGIN TRANSACTION;');
  final stmt = db.prepare('INSERT INTO t1 VALUES (?, ?, ?);');
  stmt.executeBatchSync(batchParams);
  await interpreter.executeScript('COMMIT;');
  sw.stop();

  final double durationInSecs = sw.elapsedMilliseconds / 1000.0;
  final double rowsPerSec = 1000000 / durationInSecs;
  print('=== BATCH INSERT BENCHMARK RESULTS ===');
  print('Inserted 1,000,000 rows in ${sw.elapsedMilliseconds} ms (${rowsPerSec.toStringAsFixed(0)} rows/sec)');

  await db.close();
  try { dir.deleteSync(recursive: true); } catch (_) {}
}
