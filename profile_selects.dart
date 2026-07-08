import 'dart:io';
import 'dart:typed_data';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';
import 'package:hybrid_sql_engine/engine/storage/table_file.dart';

void main() async {
  const dbDir = 'test_profile_select_db';
  final dir = Directory(dbDir);
  if (dir.existsSync()) {
    try { dir.deleteSync(recursive: true); } catch (_) {}
  }
  dir.createSync(recursive: true);

  final db = Database(dbDir);
  await db.init();
  final interpreter = Interpreter(db);

  await interpreter.executeScript('CREATE TABLE t2(a INT, b INT, c TEXT);');

  await interpreter.executeScript('BEGIN TRANSACTION;');
  final stmtInsert = db.prepare('INSERT INTO t2 VALUES (?, ?, ?);');
  for (int i = 1; i <= 25000; i++) {
    stmtInsert.executeSync([DbInt(i), DbInt(i), DbText('Row $i')]);
  }
  await interpreter.executeScript('COMMIT;');

  // Profile Test 4: 100 SELECTs
  final swFull = Stopwatch()..start();
  await interpreter.executeScript('BEGIN TRANSACTION;');
  final stmtSelect = db.prepare('SELECT COUNT(*), AVG(b) FROM t2 WHERE b >= ? AND b < ?;');
  for (int i = 0; i < 100; i++) {
    final low = i * 100;
    final high = low + 1000;
    stmtSelect.executeSync([DbInt(low), DbInt(high)]);
  }
  await interpreter.executeScript('COMMIT;');
  swFull.stop();

  print('Total time for 100 SELECTs: ${swFull.elapsedMilliseconds} ms');

  // Let's profile the components:
  // 1. Raw RowCursor iteration + visibility checking only
  final rowTable = RowTableFile(cache: db.cache, tableName: 't2', dbDirectory: dbDir);
  final currentTxId = db.cache.currentMvccTx?.txId ?? 0;
  
  final swCursor = Stopwatch()..start();
  for (int i = 0; i < 100; i++) {
    final cursor = rowTable.scanSync(
      currentTxId: currentTxId,
      projectedColIndexes: [1],
    );
    final iterator = cursor.iterator;
    int count = 0;
    while (iterator.moveNext()) {
      iterator.current;
      count++;
    }
  }
  swCursor.stop();

  print('Time for Cursor iteration (2.5M rows): ${swCursor.elapsedMilliseconds} ms');

  await db.close();
  try { dir.deleteSync(recursive: true); } catch (_) {}
}
