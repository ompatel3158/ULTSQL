import 'dart:convert';
import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void main() async {
  const dbDir = 'test_nosql_workload_db';
  final dir = Directory(dbDir);
  if (dir.existsSync()) {
    try { dir.deleteSync(recursive: true); } catch (_) {}
  }
  dir.createSync(recursive: true);

  final db = Database(dbDir, useWal: false, maxCapacity: 100000);
  await db.init();
  final interpreter = Interpreter(db);

  print('=== STEP 1: CREATE TABLE AND INDEXES ===');
  await interpreter.executeScript('CREATE TABLE nosql (id INT PRIMARY KEY, info JSON);');

  final initialMemory = ProcessInfo.currentRss;

  print('\n=== STEP 2: BENCHMARK 10M INSERTS ===');
  final swInsert = Stopwatch()..start();
  await interpreter.executeScript('BEGIN TRANSACTION;');
  final insertStmt = db.prepare('INSERT INTO nosql VALUES (?, ?);');
  
  const int totalRows = 10000000;
  const int chunkSize = 500000;
  const int numChunks = totalRows ~/ chunkSize;

  for (int c = 0; c < numChunks; c++) {
    final batch = List<List<DbValue>>.generate(chunkSize, (i) {
      final id = c * chunkSize + i;
      return [
        DbInt(id),
        DbJson({"age": (id % 100), "score": id * 1.5, "nested": {"level2": {"level3": "value_$id"}}})
      ];
    });
    insertStmt.executeBatchSync(batch);
    if ((c + 1) % 4 == 0) {
      print('  Inserted ${(c + 1) * chunkSize} / 10,000,000 rows...');
    }
  }
  await interpreter.executeScript('COMMIT;');
  swInsert.stop();
  final double insertSecs = swInsert.elapsedMilliseconds / 1000.0;
  final double insertsPerSec = totalRows / insertSecs;
  print('10M Inserts Time: ${insertSecs.toStringAsFixed(2)}s (${insertsPerSec.toStringAsFixed(0)} rows/sec)');

  print('\n=== STEP 3: BENCHMARK 10M READS (FULL SEQUENTIAL SCAN) ===');
  final swRead = Stopwatch()..start();
  // Count query causes sequential scan of all 10M rows
  final readRes = await interpreter.executeScript('SELECT COUNT(*) FROM nosql;');
  swRead.stop();
  final double readSecs = swRead.elapsedMilliseconds / 1000.0;
  final double readsPerSec = totalRows / readSecs;
  print('10M Reads (Full Scan) Time: ${readSecs.toStringAsFixed(2)}s (${readsPerSec.toStringAsFixed(0)} rows/sec)');
  print('Total Rows: ${readRes.rows[0][0]}');

  print('\n=== STEP 4: INDEXED LOOKUP ===');
  final swLookup = Stopwatch()..start();
  // Perform 1000 point lookups on PRIMARY KEY index
  const int lookupCount = 1000;
  for (int i = 0; i < lookupCount; i++) {
    final targetId = (i * 9997) % totalRows;
    final res = await interpreter.executeScript('SELECT id FROM nosql WHERE id = $targetId;');
    if (res.rows.isEmpty) {
      print('Error: Row not found for id $targetId');
    }
  }
  swLookup.stop();
  final double lookupTime = swLookup.elapsedMilliseconds / lookupCount.toDouble();
  print('$lookupCount Indexed Lookups Time: ${swLookup.elapsedMilliseconds}ms (${lookupTime.toStringAsFixed(3)} ms per query)');

  print('\n=== STEP 5: RANGE QUERY ===');
  final swRange = Stopwatch()..start();
  // Fetch 5000 rows in range
  final rangeRes = await interpreter.executeScript('SELECT id FROM nosql WHERE id BETWEEN 5000000 AND 5005000;');
  swRange.stop();
  print('Range Query (5000 rows) Time: ${swRange.elapsedMilliseconds}ms');
  print('Rows retrieved: ${rangeRes.rows.length}');

  print('\n=== STEP 6: NESTED JSON QUERY (FILTER BY JSON FIELD) ===');
  final swJson = Stopwatch()..start();
  // Filter by nested JSON path age = 25 (expected 100,000 matches)
  final jsonRes = await interpreter.executeScript('SELECT COUNT(*) FROM nosql WHERE info.age = 25;');
  swJson.stop();
  print('Nested JSON Query (10M filter) Time: ${swJson.elapsedMilliseconds}ms');
  print('Matching Rows: ${jsonRes.rows[0][0]}');

  print('\n=== STEP 7: UPDATE NESTED FIELD (10,000 UPDATES) ===');
  final swUpdate = Stopwatch()..start();
  final selectStmt = db.prepare('SELECT info FROM nosql WHERE id = ?;');
  final updateStmt = db.prepare('UPDATE nosql SET info = ? WHERE id = ?;');

  await interpreter.executeScript('BEGIN TRANSACTION;');
  for (int i = 0; i < 10000; i++) {
    final targetId = i;
    // 1. Read row
    final readRes = selectStmt.executeSync([DbInt(targetId)]);
    if (readRes.rows.isNotEmpty) {
      final DbJson infoJson = readRes.rows[0][0] as DbJson;
      final map = Map<String, dynamic>.from(infoJson.value);
      // 2. Modify field
      map['age'] = 99;
      final updatedJsonStr = json.encode(map);
      // 3. In-place UPDATE
      updateStmt.executeSync([DbText(updatedJsonStr), DbInt(targetId)]);
    }
  }
  await interpreter.executeScript('COMMIT;');
  swUpdate.stop();
  final double updateSecs = swUpdate.elapsedMilliseconds / 1000.0;
  final double updatesPerSec = 10000 / updateSecs;
  print('10,000 Updates Time: ${updateSecs.toStringAsFixed(2)}s (${updatesPerSec.toStringAsFixed(0)} updates/sec)');

  print('\n=== STEP 8: DELETE 1,000,000 DOCUMENTS ===');
  final swDelete = Stopwatch()..start();
  await interpreter.executeScript('BEGIN TRANSACTION;');
  final deleteRes = await interpreter.executeScript('DELETE FROM nosql WHERE id < 1000000;');
  await interpreter.executeScript('COMMIT;');
  swDelete.stop();
  print('Delete 1M Docs Time: ${swDelete.elapsedMilliseconds}ms');
  print('Delete query status: ${deleteRes.message}');

  print('\n=== STEP 9: AGGREGATION ===');
  final swAgg = Stopwatch()..start();
  // Aggregate score by age for 100 groups
  final aggRes = await interpreter.executeScript('SELECT info.age, COUNT(*), AVG(info.score) FROM nosql GROUP BY info.age LIMIT 100;');
  swAgg.stop();
  print('Aggregation (9M rows -> 100 groups) Time: ${swAgg.elapsedMilliseconds}ms');
  print('Groups returned: ${aggRes.rows.length}');

  print('\n=== STEP 10: METRIC CAPTURE ===');
  final finalMemory = ProcessInfo.currentRss;
  final double memoryUsedMb = (finalMemory - initialMemory) / (1024.0 * 1024.0);

  final dbFile = File('$dbDir/nosql.db');
  final double dbSizeMb = dbFile.lengthSync() / (1024.0 * 1024.0);

  print('Peak Memory Delta (RSS): ${memoryUsedMb.toStringAsFixed(2)} MB');
  print('Database Size on Disk: ${dbSizeMb.toStringAsFixed(2)} MB');

  await db.close();
}
