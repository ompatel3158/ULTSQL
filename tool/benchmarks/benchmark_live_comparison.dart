import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:ultsql/src/engine/executor/interpreter.dart' as hybrid;
import 'package:ultsql/src/engine/executor/value.dart' as hybrid;

const int totalRows = 10000000;
const String mongoPort = '27017';
const String mongoUrl = 'mongodb://localhost:$mongoPort/benchmark';

Future<void> main() async {
  print('=== STEP 1: ENSURING MONGODB IS AVAILABLE ===');
  final mongoDir = Directory('mongodb-win32-x86_64-windows-7.0.12');
  final mongodExe = File('${mongoDir.path}/bin/mongod.exe');

  if (!mongodExe.existsSync()) {
    print('MongoDB not found. Downloading MongoDB Community Server 7.0.12...');
    final zipUrl = 'https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-7.0.12.zip';
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(zipUrl));
    final response = await request.close();
    
    final zipFile = File('mongodb.zip');
    final sink = zipFile.openWrite();
    int downloadedBytes = 0;
    final totalBytes = response.contentLength;

    await response.map((chunk) {
      downloadedBytes += chunk.length;
      if (totalBytes != -1 && downloadedBytes % (5 * 1024 * 1024) < chunk.length) {
        final progress = (downloadedBytes / totalBytes) * 100;
        print('  Downloaded ${progress.toStringAsFixed(1)}% (${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB)...');
      }
      return chunk;
    }).pipe(sink);

    print('Download complete. Extracting ZIP archive...');
    // Use powershell to extract since Windows has built-in zip support in powershell
    final result = await Process.run('powershell', [
      '-Command',
      'Expand-Archive -Path mongodb.zip -DestinationPath . -Force'
    ]);

    if (result.exitCode != 0) {
      print('PowerShell extraction failed: ${result.stderr}');
      print('Trying native tar...');
      final tarRes = await Process.run('tar', ['-xf', 'mongodb.zip']);
      if (tarRes.exitCode != 0) {
        throw Exception('Failed to extract MongoDB zip: ${tarRes.stderr}');
      }
    }

    print('Extraction complete. Cleaning up zip file...');
    try { zipFile.deleteSync(); } catch (_) {}
  } else {
    print('MongoDB installation found.');
  }

  print('\n=== STEP 2: STARTING MONGODB SERVICE ===');
  final mongoDbDir = Directory('test_mongo_data');
  if (mongoDbDir.existsSync()) {
    try { mongoDbDir.deleteSync(recursive: true); } catch (_) {}
  }
  mongoDbDir.createSync(recursive: true);

  print('Launching mongod on port $mongoPort...');
  final mongodProcess = await Process.start(
    mongodExe.path,
    ['--dbpath', mongoDbDir.path, '--port', mongoPort]
  );

  // Monitor stderr/stdout to check if it started successfully
  bool mongoStarted = false;
  final startupSub = mongodProcess.stdout.transform(utf8.decoder).listen((line) {
    if (line.contains('Waiting for connections')) {
      mongoStarted = true;
    }
  });

  // Wait up to 10 seconds for MongoDB to start
  for (int i = 0; i < 10; i++) {
    if (mongoStarted) break;
    await Future.delayed(Duration(seconds: 1));
  }
  await startupSub.cancel();

  if (!mongoStarted) {
    print('Warning: "Waiting for connections" not detected in log, proceeding anyway.');
  } else {
    print('MongoDB started successfully.');
  }

  // Define metric maps
  final ultsqlMetrics = <String, String>{};
  final mongoMetrics = <String, String>{};

  // Run the benchmarks
  try {
    await runUltsqlBenchmark(ultsqlMetrics);
    await runMongoBenchmark(mongoMetrics);
  } finally {
    print('\n=== SHUTTING DOWN MONGODB ===');
    mongodProcess.kill();
    await mongodProcess.exitCode;
    print('MongoDB terminated.');

    print('Cleaning up data directories...');
    try {
      if (mongoDbDir.existsSync()) {
        mongoDbDir.deleteSync(recursive: true);
      }
    } catch (e) {
      print('Failed to delete mongo db directory: $e');
    }
  }

  // Print Comparison Table
  print('\n======================================================');
  print('          LIVE BENCHMARK RESULTS (10M WORKLOAD)       ');
  print('======================================================');
  print('${'Test'.padRight(25)} | ${'Ultsql'.padRight(12)} | ${'MongoDB'.padRight(12)}');
  print('-' * 55);

  final testKeys = [
    '10M Inserts',
    '10M Reads',
    'Indexed Lookup',
    'Range Query',
    'Nested JSON Query',
    'Update Nested Field',
    'Delete 1M Docs',
    'Aggregation',
    'Peak Memory Usage',
    'Database Size'
  ];

  for (final key in testKeys) {
    final ultsqlVal = ultsqlMetrics[key] ?? 'N/A';
    final mongoVal = mongoMetrics[key] ?? 'N/A';
    print('${key.padRight(25)} | ${ultsqlVal.padRight(12)} | ${mongoVal.padRight(12)}');
  }
  print('======================================================');
}

Future<void> runUltsqlBenchmark(Map<String, String> metrics) async {
  print('\n========================================');
  print('       RUNNING ULTSQL BENCHMARK         ');
  print('========================================');

  const dbDir = 'test_nosql_workload_db';
  final dir = Directory(dbDir);
  if (dir.existsSync()) {
    try { dir.deleteSync(recursive: true); } catch (_) {}
  }
  dir.createSync(recursive: true);

  final db = hybrid.Database(dbDir, useWal: false, maxCapacity: 10000);
  await db.init();
  final interpreter = hybrid.Interpreter(db);

  await interpreter.executeScript('CREATE TABLE nosql (id INT PRIMARY KEY, info JSON);');
  final initialMemory = ProcessInfo.currentRss;

  print('1. Running 10M Inserts...');
  final swInsert = Stopwatch()..start();
  await interpreter.executeScript('BEGIN TRANSACTION;');
  final insertStmt = db.prepare('INSERT INTO nosql VALUES (?, ?);');
  
  const int chunkSize = 500000;
  const int numChunks = totalRows ~/ chunkSize;

  for (int c = 0; c < numChunks; c++) {
    final batch = List<List<hybrid.DbValue>>.generate(chunkSize, (i) {
      final id = c * chunkSize + i;
      return [
        hybrid.DbInt(id),
        hybrid.DbJson({"age": (id % 100), "score": id * 1.5, "nested": {"level2": {"level3": "value_$id"}}})
      ];
    });
    insertStmt.executeBatchSync(batch);
    if ((c + 1) % 4 == 0) {
      print('  Inserted ${(c + 1) * chunkSize} / 10,000,000 rows...');
    }
    // Yield to GC
    await Future.delayed(Duration.zero);
  }
  await interpreter.executeScript('COMMIT;');
  swInsert.stop();
  final double insertSecs = swInsert.elapsedMilliseconds / 1000.0;
  metrics['10M Inserts'] = '${insertSecs.toStringAsFixed(2)}s';
  print('  10M Inserts completed in ${insertSecs.toStringAsFixed(2)}s');

  print('2. Running 10M Reads (Full Scan)...');
  final swRead = Stopwatch()..start();
  final readRes = await interpreter.executeScript('SELECT COUNT(*) FROM nosql;');
  swRead.stop();
  final double readSecs = swRead.elapsedMilliseconds / 1000.0;
  metrics['10M Reads'] = '${readSecs.toStringAsFixed(2)}s';
  print('  Count result: ${readRes.rows[0][0]} in ${readSecs.toStringAsFixed(2)}s');

  print('3. Running Indexed Lookup...');
  final swLookup = Stopwatch()..start();
  const int lookupCount = 1000;
  for (int i = 0; i < lookupCount; i++) {
    final targetId = (i * 9997) % totalRows;
    final res = await interpreter.executeScript('SELECT id FROM nosql WHERE id = $targetId;');
    if (res.rows.isEmpty) throw Exception('PK Lookup failed');
  }
  swLookup.stop();
  final double lookupTime = swLookup.elapsedMilliseconds / lookupCount.toDouble();
  metrics['Indexed Lookup'] = '${lookupTime.toStringAsFixed(3)}ms';
  print('  Indexed lookup time: ${lookupTime.toStringAsFixed(3)} ms/query');

  print('4. Running Range Query (5000 rows)...');
  final swRange = Stopwatch()..start();
  final rangeRes = await interpreter.executeScript('SELECT id FROM nosql WHERE id BETWEEN 5000000 AND 5005000;');
  swRange.stop();
  metrics['Range Query'] = '${swRange.elapsedMilliseconds}ms';
  print('  Range query returned ${rangeRes.rows.length} rows in ${swRange.elapsedMilliseconds}ms');

  print('5. Running Nested JSON Query...');
  final swJson = Stopwatch()..start();
  final jsonRes = await interpreter.executeScript('SELECT COUNT(*) FROM nosql WHERE info.age = 25;');
  swJson.stop();
  metrics['Nested JSON Query'] = '${swJson.elapsedMilliseconds}ms';
  print('  Nested JSON query returned ${jsonRes.rows[0][0]} in ${swJson.elapsedMilliseconds}ms');

  print('6. Running Update Nested Field (10,000 updates)...');
  final swUpdate = Stopwatch()..start();
  final selectStmt = db.prepare('SELECT info FROM nosql WHERE id = ?;');
  final updateStmt = db.prepare('UPDATE nosql SET info = ? WHERE id = ?;');

  await interpreter.executeScript('BEGIN TRANSACTION;');
  for (int i = 0; i < 10000; i++) {
    final targetId = i;
    final readRes = selectStmt.executeSync([hybrid.DbInt(targetId)]);
    if (readRes.rows.isNotEmpty) {
      final hybrid.DbJson infoJson = readRes.rows[0][0] as hybrid.DbJson;
      final map = Map<String, dynamic>.from(infoJson.value);
      map['age'] = 99;
      updateStmt.executeSync([hybrid.DbJson(map), hybrid.DbInt(targetId)]);
    }
  }
  await interpreter.executeScript('COMMIT;');
  swUpdate.stop();
  metrics['Update Nested Field'] = '${swUpdate.elapsedMilliseconds}ms';
  print('  10k updates completed in ${swUpdate.elapsedMilliseconds}ms');

  print('7. Running Delete 1M Docs...');
  final swDelete = Stopwatch()..start();
  await interpreter.executeScript('BEGIN TRANSACTION;');
  await interpreter.executeScript('DELETE FROM nosql WHERE id < 1000000;');
  await interpreter.executeScript('COMMIT;');
  swDelete.stop();
  metrics['Delete 1M Docs'] = '${swDelete.elapsedMilliseconds}ms';
  print('  Delete 1M completed in ${swDelete.elapsedMilliseconds}ms');

  print('8. Running Aggregation...');
  final swAgg = Stopwatch()..start();
  final aggRes = await interpreter.executeScript('SELECT info.age, COUNT(*), AVG(info.score) FROM nosql GROUP BY info.age LIMIT 100;');
  swAgg.stop();
  metrics['Aggregation'] = '${swAgg.elapsedMilliseconds}ms';
  print('  Aggregation group count: ${aggRes.rows.length} in ${swAgg.elapsedMilliseconds}ms');

  final finalMemory = ProcessInfo.currentRss;
  final double memoryUsedMb = (finalMemory - initialMemory) / (1024.0 * 1024.0);
  metrics['Peak Memory Usage'] = '${memoryUsedMb.toStringAsFixed(1)} MB';

  final dbFile = File('$dbDir/nosql.db');
  final double dbSizeMb = dbFile.lengthSync() / (1024.0 * 1024.0);
  metrics['Database Size'] = '${dbSizeMb.toStringAsFixed(1)} MB';

  await db.close();
  try { dir.deleteSync(recursive: true); } catch (_) {}
}

Future<void> runMongoBenchmark(Map<String, String> metrics) async {
  print('\n========================================');
  print('       RUNNING MONGO BENCHMARK          ');
  print('========================================');

  final db = mongo.Db(mongoUrl);
  await db.open();

  final collection = db.collection('nosql');
  await collection.drop();

  final initialMemory = ProcessInfo.currentRss;

  print('1. Running 10M Inserts...');
  final swInsert = Stopwatch()..start();
  
  const int chunkSize = 50000; // Smaller chunks for mongo BSON packets
  const int numChunks = totalRows ~/ chunkSize;

  for (int c = 0; c < numChunks; c++) {
    final batch = List<Map<String, dynamic>>.generate(chunkSize, (i) {
      final id = c * chunkSize + i;
      return {
        '_id': id,
        'age': (id % 100),
        'score': id * 1.5,
        'nested': {
          'level2': {
            'level3': 'value_$id'
          }
        }
      };
    });
    await collection.insertMany(batch, writeConcern: mongo.WriteConcern.acknowledged);
    if ((c + 1) % 40 == 0) {
      print('  Inserted ${(c + 1) * chunkSize} / 10,000,000 rows...');
    }
    // Yield to GC
    await Future.delayed(Duration.zero);
  }
  swInsert.stop();
  final double insertSecs = swInsert.elapsedMilliseconds / 1000.0;
  metrics['10M Inserts'] = '${insertSecs.toStringAsFixed(2)}s';
  print('  10M Inserts completed in ${insertSecs.toStringAsFixed(2)}s');

  print('2. Running 10M Reads (Full Scan via Aggregation)...');
  final swRead = Stopwatch()..start();
  final pipe = [
    {
      '\$group': {
        '_id': null,
        'count': {'\$sum': 1}
      }
    }
  ];
  final aggRes = await collection.aggregate(pipe).toList();
  swRead.stop();
  final double readSecs = swRead.elapsedMilliseconds / 1000.0;
  metrics['10M Reads'] = '${readSecs.toStringAsFixed(2)}s';
  final countVal = aggRes.isNotEmpty ? aggRes.first['count'] : 0;
  print('  Count result: $countVal in ${readSecs.toStringAsFixed(2)}s');

  print('3. Running Indexed Lookup...');
  final swLookup = Stopwatch()..start();
  const int lookupCount = 1000;
  for (int i = 0; i < lookupCount; i++) {
    final targetId = (i * 9997) % totalRows;
    final doc = await collection.findOne(mongo.where.id(targetId));
    if (doc == null) throw Exception('PK Lookup failed');
  }
  swLookup.stop();
  final double lookupTime = swLookup.elapsedMilliseconds / lookupCount.toDouble();
  metrics['Indexed Lookup'] = '${lookupTime.toStringAsFixed(3)}ms';
  print('  Indexed lookup time: ${lookupTime.toStringAsFixed(3)} ms/query');

  print('4. Running Range Query (5000 rows)...');
  final swRange = Stopwatch()..start();
  final rangeRes = await collection.find(mongo.where.gte('_id', 5000000).lte('_id', 5005000)).toList();
  swRange.stop();
  metrics['Range Query'] = '${swRange.elapsedMilliseconds}ms';
  print('  Range query returned ${rangeRes.length} rows in ${swRange.elapsedMilliseconds}ms');

  print('5. Running Nested JSON Query...');
  final swJson = Stopwatch()..start();
  // We query age=25 which is unindexed
  final jsonCount = await collection.count(mongo.where.eq('age', 25));
  swJson.stop();
  metrics['Nested JSON Query'] = '${swJson.elapsedMilliseconds}ms';
  print('  Nested JSON query returned $jsonCount in ${swJson.elapsedMilliseconds}ms');

  print('6. Running Update Nested Field (10,000 updates)...');
  final swUpdate = Stopwatch()..start();
  for (int i = 0; i < 10000; i++) {
    final targetId = i;
    await collection.updateOne(mongo.where.id(targetId), mongo.modify.set('age', 99));
  }
  swUpdate.stop();
  metrics['Update Nested Field'] = '${swUpdate.elapsedMilliseconds}ms';
  print('  10k updates completed in ${swUpdate.elapsedMilliseconds}ms');

  print('7. Running Delete 1M Docs...');
  final swDelete = Stopwatch()..start();
  await collection.deleteMany(mongo.where.lt('_id', 1000000));
  swDelete.stop();
  metrics['Delete 1M Docs'] = '${swDelete.elapsedMilliseconds}ms';
  print('  Delete 1M completed in ${swDelete.elapsedMilliseconds}ms');

  print('8. Running Aggregation...');
  final swAgg = Stopwatch()..start();
  final aggPipe = [
    {
      '\$group': {
        '_id': '\$age',
        'count': {'\$sum': 1},
        'avgScore': {'\$avg': '\$score'}
      }
    },
    {'\$limit': 100}
  ];
  final finalAgg = await collection.aggregate(aggPipe).toList();
  swAgg.stop();
  metrics['Aggregation'] = '${swAgg.elapsedMilliseconds}ms';
  print('  Aggregation group count: ${finalAgg.length} in ${swAgg.elapsedMilliseconds}ms');

  final finalMemory = ProcessInfo.currentRss;
  final double memoryUsedMb = (finalMemory - initialMemory) / (1024.0 * 1024.0);
  metrics['Peak Memory Usage'] = '${memoryUsedMb.toStringAsFixed(1)} MB';

  // Get MongoDB database size on disk
  final stats = await db.executeDbCommand({'dbStats': 1});
  final num sizeBytes = stats['dataSize'] ?? 0;
  metrics['Database Size'] = '${(sizeBytes / (1024.0 * 1024.0)).toStringAsFixed(1)} MB';

  await db.close();
}
