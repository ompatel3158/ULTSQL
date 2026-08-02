import 'dart:io';
import 'dart:typed_data';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/storage/table_file.dart';

void main() async {
  const dbDir = 'test_profile_db';
  final dir = Directory(dbDir);
  if (dir.existsSync()) {
    try { dir.deleteSync(recursive: true); } catch (_) {}
  }
  dir.createSync(recursive: true);

  final db = Database(dbDir);
  await db.init();
  final interpreter = Interpreter(db);

  await interpreter.executeScript('CREATE TABLE t1(a INT, b INT, c TEXT);');

  await interpreter.executeScript('BEGIN TRANSACTION;');
  final stmt = db.prepare('INSERT INTO t1 VALUES (?, ?, ?);');

  final rowTable = RowTableFile(
    cache: db.cache,
    tableName: 't1',
    dbDirectory: dbDir,
  );

  // Warmup
  for (int i = 1; i <= 1000; i++) {
    stmt.executeSync([DbInt(i), DbInt(i * 2), DbText('Row $i')]);
  }

  // Profile parameter preparation + executeSync
  final swFull = Stopwatch()..start();
  final iterations = 50000;
  for (int i = 1; i <= iterations; i++) {
    stmt.executeSync([DbInt(i), DbInt(i * 2), DbText('Row $i')]);
  }
  swFull.stop();

  // Profile direct rowTable insertSync
  final swInsertOnly = Stopwatch()..start();
  final currentTxId = db.cache.currentMvccTx?.txId ?? 0;
  for (int i = 1; i <= iterations; i++) {
    final row = [DbInt(i), DbInt(i * 2), DbText('Row $i')];
    rowTable.insertSync(row, xmin: currentTxId);
  }
  swInsertOnly.stop();

  // Profile insertRecordDirect sub-steps
  final page = db.cache.pinPageSync(rowTable.filePath, 0);
  final src = Uint8List(128);
  final swSetRange = Stopwatch()..start();
  for (int i = 1; i <= iterations; i++) {
    page.data.setRange(0, 100, src, 0);
  }
  swSetRange.stop();

  final swByteData = Stopwatch()..start();
  final data = page.byteData;
  for (int i = 1; i <= iterations; i++) {
    data.getUint16(1);
    data.getUint16(3);
    data.setUint16(10, 100);
    data.setUint16(12, 100);
    data.setUint16(1, 100);
    data.setUint16(3, 100);
  }
  swByteData.stop();

  // Profile serialization only
  final swSerializeOnly = Stopwatch()..start();
  final dest = Uint8List(4096);
  for (int i = 1; i <= iterations; i++) {
    final row = [DbInt(i), DbInt(i * 2), DbText('Row $i')];
    RecordSerializer.serializeMvccRowDirect(dest, row, currentTxId, 0, 0);
  }
  swSerializeOnly.stop();

  print('Iterations: $iterations');
  print('Total time (stmt.executeSync): ${swFull.elapsedMilliseconds} ms (${(iterations / (swFull.elapsedMilliseconds / 1000.0)).toStringAsFixed(0)} rows/sec)');
  print('Time for RowTable.insertSync only: ${swInsertOnly.elapsedMilliseconds} ms (${(iterations / (swInsertOnly.elapsedMilliseconds / 1000.0)).toStringAsFixed(0)} rows/sec)');
  print('Time for setRange only: ${swSetRange.elapsedMilliseconds} ms (${(iterations / (swSetRange.elapsedMilliseconds / 1000.0)).toStringAsFixed(0)} operations/sec)');
  print('Time for ByteData reads/writes only: ${swByteData.elapsedMilliseconds} ms (${(iterations / (swByteData.elapsedMilliseconds / 1000.0)).toStringAsFixed(0)} operations/sec)');
  print('Time for RecordSerializer.serializeMvccRowDirect only: ${swSerializeOnly.elapsedMilliseconds} ms (${(iterations / (swSerializeOnly.elapsedMilliseconds / 1000.0)).toStringAsFixed(0)} rows/sec)');

  await db.close();
  try { dir.deleteSync(recursive: true); } catch (_) {}
}
