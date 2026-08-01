import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'package:ultsql/engine/executor/value.dart';
import 'package:ultsql/engine/storage/catalog.dart';
import 'package:ultsql/engine/storage/btree_index.dart';
import 'package:ultsql/engine/storage/hnsw_index.dart';
import 'package:ultsql/engine/executor/replication.dart';

@Timeout(Duration(minutes: 5))
void main() {
  const dbDir = 'test_spec_db';
  final List<Database> activeDbs = [];

  Database openDb(String dir, {String? passphrase}) {
    final db = Database(dir, passphrase: passphrase);
    activeDbs.add(db);
    return db;
  }

  void cleanDirectory(String dirPath) {
    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
    dir.createSync(recursive: true);
  }

  setUp(() {
    activeDbs.clear();
    cleanDirectory(dbDir);
  });

  tearDown(() async {
    for (final db in List<Database>.from(activeDbs)) {
      try {
        await db.close();
      } catch (_) {}
    }
    activeDbs.clear();
    // Give OS a brief moment to release file descriptors
    await Future.delayed(const Duration(milliseconds: 50));
    cleanDirectory(dbDir);
  });

  group('Tier 1 — Correctness Tests', () {
    test('Test 1: WAL Recovery (Uncommitted transaction crashes and yields 0 rows)', () async {
      // 1. Initial setup: create table and write some committed rows
      {
        final db = openDb(dbDir);
        await db.init();
        final interpreter = Interpreter(db);
        await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, age INT);');
        await interpreter.executeScript('INSERT INTO users VALUES (1, \'OriginalUser\', 20);');
        await db.close();
      }

      // 2. Open DB, start a transaction, insert but do NOT commit, and flush pages to trigger WAL logging
      {
        final db = openDb(dbDir);
        await db.init();
        final interpreter = Interpreter(db);
        
        await interpreter.executeScript('BEGIN TRANSACTION;');
        await interpreter.executeScript('INSERT INTO users VALUES (9999999, \'CrashTest\', 25);');
        
        // Flush all pages to write them to WAL and disk before commit
        db.cache.flushAllSync();
        
        // Force close without committing to simulate kill/crash
        await db.close();
      }

      // Verify wal.log exists
      final walFile = File('$dbDir/wal.log');
      expect(walFile.existsSync(), isTrue, reason: 'wal.log must be written to disk on flush before commit');

      // 3. Re-open DB (recovers uncommitted transaction, replaying before bytes)
      {
        final db = openDb(dbDir);
        await db.init(); // Auto-runs recoverSync
        final interpreter = Interpreter(db);

        final queryRes = await interpreter.executeScript('SELECT * FROM users WHERE id = 9999999;');
        expect(queryRes.rows.length, 0, reason: 'The uncommitted insert must be rolled back by WAL recovery');
        
        await db.close();
      }
    });

    test('Test 2: Commit Recovery (Committed transaction survives crash/kill)', () async {
      // 1. Initial setup: create table
      {
        final db = openDb(dbDir);
        await db.init();
        final interpreter = Interpreter(db);
        await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, age INT);');
        await db.close();
      }

      // 2. Start tx, insert, commit, then simulate immediate crash/kill
      {
        final db = openDb(dbDir);
        await db.init();
        final interpreter = Interpreter(db);
        
        await interpreter.executeScript('BEGIN TRANSACTION;');
        await interpreter.executeScript('INSERT INTO users VALUES (9999999, \'CrashTest\', 25);');
        await interpreter.executeScript('COMMIT;');
        
        // Simulate immediate force close/kill
        await db.close();
      }

      // 3. Re-open DB and verify data is still there
      {
        final db = openDb(dbDir);
        await db.init();
        final interpreter = Interpreter(db);

        final queryRes = await interpreter.executeScript('SELECT * FROM users WHERE id = 9999999;');
        expect(queryRes.rows.length, 1);
        expect(queryRes.rows[0][1].toString(), 'CrashTest');
        
        await db.close();
      }
    });

    test('Test 3: MVCC Session Isolation (Readers see original values until commit)', () async {
      final db = openDb(dbDir);
      await db.init();
      
      final interpreterA = Interpreter(db);
      final interpreterB = Interpreter(db);

      await interpreterA.executeScript('CREATE TABLE users (id INT, name TEXT, age INT);');
      await interpreterA.executeScript('INSERT INTO users VALUES (1, \'User1\', 25);');

      // Session A starts a transaction and updates the record
      await interpreterA.executeScript('BEGIN TRANSACTION;');
      await interpreterA.executeScript('DELETE FROM users WHERE id = 1;');
      await interpreterA.executeScript('INSERT INTO users VALUES (1, \'User1\', 999);');

      // Session B queries the record (outside transaction or in a separate snapshot)
      final resBBefore = await interpreterB.executeScript('SELECT age FROM users WHERE id = 1;');
      expect(resBBefore.rows[0][0].toString(), '25', reason: 'Session B must see original value because Session A has not committed');

      // Session A commits
      await interpreterA.executeScript('COMMIT;');

      // Session B queries again
      final resBAfter = await interpreterB.executeScript('SELECT age FROM users WHERE id = 1;');
      expect(resBAfter.rows[0][0].toString(), '999', reason: 'Session B must see updated value after Session A commits');

      await db.close();
    });

    test('Test 4: Foreign Key Cascade (Deletes cascade to referencing rows)', () async {
      final db = openDb(dbDir);
      await db.init();
      final interpreter = Interpreter(db);

      await interpreter.executeScript('CREATE TABLE users (id INT PRIMARY KEY);');
      // In Test 4 DDL:
      await interpreter.executeScript('CREATE TABLE orders (id INT, user_id INT REFERENCES users(id));');

      await interpreter.executeScript('INSERT INTO users VALUES (1);');
      await interpreter.executeScript('INSERT INTO users VALUES (2);');

      await interpreter.executeScript('INSERT INTO orders VALUES (10, 1);');
      await interpreter.executeScript('INSERT INTO orders VALUES (20, 1);');
      await interpreter.executeScript('INSERT INTO orders VALUES (30, 2);');

      // Perform DELETE (cascades)
      final deleteRes = await interpreter.executeScript('DELETE FROM users WHERE id = 1;');
      expect(deleteRes.message, contains('deleted successfully'));

      // Verify orders referencing user 1 are gone
      final queryRes = await interpreter.executeScript('SELECT * FROM orders WHERE user_id = 1;');
      expect(queryRes.rows.length, 0, reason: 'Orders for user_id = 1 should be cascaded');

      // Verify orders referencing user 2 are intact
      final queryRes2 = await interpreter.executeScript('SELECT * FROM orders WHERE user_id = 2;');
      expect(queryRes2.rows.length, 1);

      await db.close();
    });
  });

  group('Tier 2 & 3 — Performance & Optimizer Tests', () {
    test('Test 5 to 11: Scale insertion, Point Lookup, Explain, Stats', () async {
      final db = openDb(dbDir);
      await db.init();
      final interpreter = Interpreter(db);

      // Create users table
      await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, age INT);');

      // 1. Scale insertion benchmark (insert 1M rows using PL/SQL loop)
      print('Inserting 1,000,000 users...');
      final sw = Stopwatch()..start();
      final plsqlInsert = '''
DECLARE
  i INT := 0;
BEGIN
  BEGIN TRANSACTION;
  WHILE i < 1000000 LOOP
    i := i + 1;
    INSERT INTO users VALUES (i, 'User_' || i, 25);
  END LOOP;
  COMMIT;
END;
''';
      final insertRes = await interpreter.executeScript(plsqlInsert);
      sw.stop();
      expect(insertRes.message, contains('committed'));
      
      final insertTimeSec = sw.elapsedMilliseconds / 1000.0;
      print('Test 5: 1M Inserts completed in ${insertTimeSec.toStringAsFixed(2)}s');
      expect(insertTimeSec, lessThan(35.0), reason: 'Insert benchmark must complete under 35s');

      // Create index to verify lookups
      print('Creating index idx_users_age...');
      await interpreter.executeScript('CREATE INDEX idx_users_age ON users(age);');

      // Test 6: Point Lookup Performance
      print('Running Point Lookups...');
      final swPoint = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        // Query age=25 point lookup
        final queryRes = await interpreter.executeScript('SELECT id FROM users WHERE age = 25 LIMIT 1;');
        expect(queryRes.rows.length, 1);
      }
      swPoint.stop();
      final pointLookupTimeMs = swPoint.elapsedMilliseconds / 1000.0;
      print('Test 6: Average point lookup query time: ${pointLookupTimeMs}ms');
      expect(pointLookupTimeMs, lessThan(10.0), reason: 'Point Lookup must complete in 1-10 ms');

      // Test 7: Indexed Count Performance
      final swCount = Stopwatch()..start();
      final countRes = await interpreter.executeScript('SELECT COUNT(*) FROM users WHERE age = 25;');
      swCount.stop();
      print('Test 7: Indexed COUNT(*) query time: ${swCount.elapsedMilliseconds}ms');
      expect(countRes.rows[0][0].toString(), '1000000');
      expect(swCount.elapsedMilliseconds, lessThan(50), reason: 'Indexed Count must complete in 1-50 ms');

      // Test 8: Composite Index
      print('Creating composite index idx_age_name...');
      await interpreter.executeScript('CREATE INDEX idx_age_name ON users(age, name);');
      final expRes = await interpreter.executeScript('EXPLAIN SELECT * FROM users WHERE age = 25 AND name = \'User_5000\';');
      print('EXPLAIN Composite:\n${expRes.rows[0][0]}');
      final swComp = Stopwatch()..start();
      final compRes = await interpreter.executeScript('SELECT * FROM users WHERE age = 25 AND name = \'User_5000\';');
      swComp.stop();
      print('Test 8: Composite Index query time: ${swComp.elapsedMilliseconds}ms');
      expect(compRes.rows.length, 1);
      expect(swComp.elapsedMilliseconds, lessThan(10), reason: 'Composite index scan must take <10 ms');

      // Test 9: Explain Plan
      final explainRes = await interpreter.executeScript('EXPLAIN SELECT * FROM users WHERE age = 25;');
      final planStr = explainRes.rows[0][0].toString();
      print('Test 9 Plan:\n$planStr');
      expect(planStr, contains('IndexScanNode'), reason: 'Optimizer must use Index Scan');
      expect(planStr, isNot(contains('RowScanNode')), reason: 'Optimizer must NOT use Sequential scan for point queries');

      // Test 10: Range Scan
      final swRange = Stopwatch()..start();
      final rangeRes = await interpreter.executeScript('SELECT id FROM users WHERE age BETWEEN 25 AND 35 LIMIT 10;');
      swRange.stop();
      print('Test 10: Range Scan query time: ${swRange.elapsedMilliseconds}ms');
      expect(rangeRes.rows.length, 10);

      // Test 11: Statistics Accuracy (ANALYZE users)
      final analyzeRes = await interpreter.executeScript('ANALYZE users;');
      expect(analyzeRes.message, contains('Analyzed table'));

      final stats = db.catalog.getOrCreateStats('users');
      expect(stats.rowCount, 1000000, reason: 'rowCount must match reality');
      
      final ageStats = stats.columnStats['age'];
      expect(ageStats, isNotNull);
      expect(ageStats!.distinctCount, 1, reason: 'distinctCount of age (all 25) must be 1');
      expect(ageStats.min, 25.0, reason: 'min age must be 25');
      expect(ageStats.max, 25.0, reason: 'max age must be 25');

      await db.close();
    });
  });

  group('Tier 4 — Join Tests', () {
    test('Test 12 to 14: Hash Join, Aggregation, and Heavy Query Showcase', () async {
      final db = openDb(dbDir);
      await db.init();
      final interpreter = Interpreter(db);

      await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT);');
      await interpreter.executeScript('CREATE TABLE orders (id INT, user_id INT, amount DOUBLE);');

      // Generate 1,000 users
      print('Generating 1,000 users...');
      await interpreter.executeScript('''
DECLARE
  i INT := 0;
BEGIN
  BEGIN TRANSACTION;
  WHILE i < 1000 LOOP
    i := i + 1;
    INSERT INTO users VALUES (i, 'User_' || i);
  END LOOP;
  COMMIT;
END;
''');

      // Generate 1,000,000 orders
      print('Generating 1,000,000 orders...');
      await interpreter.executeScript('''
DECLARE
  i INT := 0;
  uid INT := 1;
  amt DOUBLE := 10.0;
BEGIN
  BEGIN TRANSACTION;
  WHILE i < 1000000 LOOP
    i := i + 1;
    uid := (i % 1000) + 1;
    amt := CAST((i % 100) AS DOUBLE) + 5.5;
    INSERT INTO orders VALUES (i, uid, amt);
  END LOOP;
  COMMIT;
END;
''');

      // Create primary index for users
      await interpreter.executeScript('CREATE INDEX idx_users_id ON users(id);');

      // Test 12: Join execution (1M+ rows join)
      print('Running Hash Join test...');
      final swJoin = Stopwatch()..start();
      final joinRes = await interpreter.executeScript('SELECT users.name, orders.amount FROM orders JOIN users ON orders.user_id = users.id LIMIT 10;');
      swJoin.stop();
      print('Test 12: Hash/Index Join execution time: ${swJoin.elapsedMilliseconds}ms');
      expect(joinRes.rows.length, 10);

      // Test 13: Aggregation
      print('Running Aggregation...');
      final aggRes = await interpreter.executeScript('SELECT user_id, COUNT(*), AVG(amount) FROM orders GROUP BY user_id LIMIT 100;');
      expect(aggRes.rows.length, 100);
      for (final r in aggRes.rows) {
        expect(r[0], isNot(isA<DbNull>()), reason: 'No NULL grouping values');
        expect(r[1], isNot(isA<DbNull>()), reason: 'No NULL counts');
        expect((r[1] as DbInt).value, 1000, reason: 'Correct aggregation count (1M orders / 1k users = 1000 orders each)');
      }

      // Test 14: Heavy Query & The One Benchmark Showcased Publicly
      print('Running heavy query...');
      final initialMemory = ProcessInfo.currentRss;
      final explainHeavy = await interpreter.executeScript('''
        EXPLAIN SELECT u.name, COUNT(o.id) AS ord_cnt, SUM(o.amount) AS tot_amt
        FROM orders o
        JOIN users u ON o.user_id = u.id
        GROUP BY u.name
        ORDER BY tot_amt DESC
        LIMIT 100;
      ''');

      final swHeavy = Stopwatch()..start();
      final heavyRes = await interpreter.executeScript('''
        SELECT u.name, COUNT(o.id) AS ord_cnt, SUM(o.amount) AS tot_amt
        FROM orders o
        JOIN users u ON o.user_id = u.id
        GROUP BY u.name
        ORDER BY tot_amt DESC
        LIMIT 100;
      ''');
      swHeavy.stop();

      final finalMemory = ProcessInfo.currentRss;
      final elapsedSec = swHeavy.elapsedMilliseconds / 1000.0;
      final memoryUsedMb = (finalMemory - initialMemory) / (1024.0 * 1024.0);

      final dbFile = File('$dbDir/orders.db');
      final fileSizeMb = dbFile.lengthSync() / (1024.0 * 1024.0);

      print('\n=== THE ONE BENCHMARK I\'D SHOWCASE PUBLICLY ===');
      print('Query: SELECT u.name, COUNT(o.id), SUM(o.amount) FROM users u JOIN orders o ON u.id=o.user_id GROUP BY u.name ORDER BY SUM(o.amount) DESC LIMIT 100;');
      print('Database scale: 1,000,000 Orders Join 1,000 Users');
      print('Execution Time: ${elapsedSec.toStringAsFixed(3)} seconds');
      print('Query Plan:\n${explainHeavy.rows[0][0]}');
      print('Memory usage (delta RSS): ${memoryUsedMb.toStringAsFixed(2)} MB');
      print('Orders table file size: ${fileSizeMb.toStringAsFixed(2)} MB');
      print('===============================================\n');

      expect(elapsedSec, lessThan(10.0), reason: 'Heavy query must run in under 10 seconds');
      expect(heavyRes.rows.length, 100);

      await db.close();
    });
  });

  group('Tier 5 — Vector Engine Tests', () {
    test('Test 15 to 16: HNSW Performance and Search Accuracy', () async {
      final indexFile = '$dbDir/hnsw_test.idx';
      final hnsw = HnswIndex(
        indexPath: indexFile,
        autoSave: false,
        M: 32,
        M0: 64,
        efConstruction: 128,
        efSearch: 100,
      );
      hnsw.initSync();

      final List<DbVector> databaseVectors = [];
      final random = Random(42);

      // Generate 5 centroids
      final List<List<double>> centroids = List.generate(5, (_) => List.generate(768, (_) => random.nextDouble()));

      // Generate 10,000 random vectors of 768 dimensions grouped around centroids
      print('Generating 10,000 vectors of 768 dimensions...');
      for (int i = 0; i < 10000; i++) {
        final centroid = centroids[i % 5];
        final elements = List<double>.generate(768, (j) => centroid[j] + 0.1 * random.nextDouble());
        databaseVectors.add(DbVector(elements));
      }

      // Test 15: Insert Benchmark (Insert vectors to HNSW graph)
      print('Inserting vectors to HNSW index...');
      final swInsert = Stopwatch()..start();
      for (int i = 0; i < databaseVectors.length; i++) {
        hnsw.insertSync(databaseVectors[i], 0, i);
      }
      swInsert.stop();
      print('HNSW insertion completed in: ${swInsert.elapsedMilliseconds}ms (${swInsert.elapsedMilliseconds / databaseVectors.length}ms per insert)');

      // Verify index contains correct number of nodes
      expect(hnsw.nodes.length, databaseVectors.length);

      final queryCentroid = centroids[random.nextInt(5)];
      final queryVector = DbVector(List<double>.generate(768, (j) => queryCentroid[j] + 0.1 * random.nextDouble()));
      print('Running HNSW nearest neighbor searches...');
      final swSearch = Stopwatch()..start();
      final hnswResults = hnsw.search(queryVector, 10);
      swSearch.stop();
      print('Test 15: HNSW Search TOP 10 search time: ${swSearch.elapsedMilliseconds}ms');
      expect(swSearch.elapsedMilliseconds, lessThan(100), reason: 'HNSW Search TOP 10 must take <100ms');

      // Test 16: Search Accuracy / Recall (Compare against flat search)
      print('Running Flat linear search for comparison...');
      final swFlat = Stopwatch()..start();
      final flatResults = databaseVectors
          .asMap()
          .entries
          .map((entry) => MapEntry(entry.key, entry.value.distanceTo(queryVector)))
          .toList();
      flatResults.sort((a, b) => a.value.compareTo(b.value));
      swFlat.stop();
      print('Flat linear search completed in: ${swFlat.elapsedMilliseconds}ms');

      final flatTop10Ids = flatResults.take(10).map((x) => x.key).toSet();
      final hnswTop10Ids = hnswResults.map((node) => node.slotId).toSet();

      int matchCount = 0;
      for (final id in hnswTop10Ids) {
        if (flatTop10Ids.contains(id)) {
          matchCount++;
        }
      }

      final double recall = matchCount / 10.0;
      print('Test 16: HNSW Search Recall vs Flat Search: ${(recall * 100).toStringAsFixed(1)}%');
      expect(recall, greaterThanOrEqualTo(0.90), reason: 'HNSW accuracy recall should be 90%+ (usually 95%+)');
    });
  });

  group('Tier 6 — Enterprise Tests', () {
    test('Test 17: WAL Replication (Sync WAL record streams to replica DB)', () async {
      final primaryDir = '$dbDir/primary';
      final replicaDir = '$dbDir/replica';
      cleanDirectory(primaryDir);
      cleanDirectory(replicaDir);

      final dbPrimary = openDb(primaryDir);
      await dbPrimary.init();
      final interpreterPrimary = Interpreter(dbPrimary);

      final dbReplica = openDb(replicaDir);
      await dbReplica.init();
      final replica = ReplicationReplica(dbReplica);

      // Create schema on primary
      await interpreterPrimary.executeScript('CREATE TABLE users (id INT, name TEXT);');

      // Since WAL logging triggers during transaction, start transaction
      await interpreterPrimary.executeScript('BEGIN TRANSACTION;');

      // Insert 100,000 rows
      print('Inserting 100,000 rows on Primary...');
      await interpreterPrimary.executeScript('''
DECLARE
  i INT := 0;
BEGIN
  WHILE i < 100000 LOOP
    i := i + 1;
    INSERT INTO users VALUES (i, 'User_' || i);
  END LOOP;
END;
''');

      // Before committing on primary, copy the wal.log content
      final walFile = File('$primaryDir/wal.log');
      expect(walFile.existsSync(), isTrue);
      final walBytes = walFile.readAsBytesSync();

      // Commit primary transaction (which deletes wal.log)
      await interpreterPrimary.executeScript('COMMIT;');

      // Parse primary's wal.log bytes into WalReplicationRecord list
      final List<WalReplicationRecord> records = [];
      int offset = 0;
      final pageSize = 4096;

      while (offset < walBytes.length) {
        final type = walBytes[offset];
        offset += 1;

        if (type == 1) {
          final jsonLen = ByteData.sublistView(walBytes, offset, offset + 4).getUint32(0, Endian.big);
          offset += 4;
          final jsonBytes = walBytes.sublist(offset, offset + jsonLen);
          offset += jsonLen;
          final catalogJson = utf8.decode(jsonBytes);
          records.add(WalReplicationRecord(type: 1, catalogJson: catalogJson));
        } else if (type == 2) {
          final pathLen = ByteData.sublistView(walBytes, offset, offset + 4).getUint32(0, Endian.big);
          offset += 4;
          final pageId = ByteData.sublistView(walBytes, offset, offset + 4).getUint32(0, Endian.big);
          offset += 4;
          final pathBytes = walBytes.sublist(offset, offset + pathLen);
          offset += pathLen;
          final filePath = utf8.decode(pathBytes);

          final beforeBytes = walBytes.sublist(offset, offset + pageSize);
          offset += pageSize;

          final afterBytes = walBytes.sublist(offset, offset + pageSize);
          offset += pageSize;

          records.add(WalReplicationRecord(
            type: 2,
            filePath: filePath,
            pageId: pageId,
            beforeData: beforeBytes,
            afterData: afterBytes,
          ));
        } else if (type == 3) {
          records.add(WalReplicationRecord(type: 3));
        }
      }

      print('Replicating ${records.length} WAL records to Replica...');
      for (final record in records) {
        await replica.applyRecord(record);
      }

      // Check counts on replica database
      final interpreterReplica = Interpreter(dbReplica);
      final replicaRes = await interpreterReplica.executeScript('SELECT COUNT(*) FROM users;');
      expect(replicaRes.rows[0][0].toString(), '100000', reason: 'Replica count must match primary exactly (100,000)');

      await dbPrimary.close();
      await dbReplica.close();
    });

    test('Test 18: Page Encryption (Denied access on incorrect key)', () async {
      final encryptDir = '$dbDir/encrypt';
      cleanDirectory(encryptDir);

      // 1. Write confidential data to database using a key passphrase
      {
        final db = openDb(encryptDir, passphrase: 'top-secret-key-123');
        await db.init();
        final interpreter = Interpreter(db);
        await interpreter.executeScript('CREATE TABLE confidential (id INT, secret TEXT);');
        await interpreter.executeScript('INSERT INTO confidential VALUES (1337, \'Nuclear Launch Codes\');');
        await db.close();
      }

      // 2. Attempt to open database without a key (key is null)
      {
        final db = openDb(encryptDir);
        await db.init();
        final interpreter = Interpreter(db);
        
        final queryRes = await interpreter.executeScript('SELECT * FROM confidential;');
        // Since pages are encrypted, slotted page deserialization returns garbage or errors, resulting in empty rows
        expect(queryRes.rows.isEmpty, isTrue, reason: 'Access without key must deny reading correct records');
        await db.close();
      }

      // 3. Attempt to open database with INCORRECT key passphrase
      {
        final db = openDb(encryptDir, passphrase: 'wrong-passphrase-abc');
        await db.init();
        final interpreter = Interpreter(db);

        final queryRes = await interpreter.executeScript('SELECT * FROM confidential;');
        expect(queryRes.rows.isEmpty, isTrue, reason: 'Access with incorrect key must deny reading correct records');
        await db.close();
      }

      // 4. Verify access is allowed when CORRECT key passphrase is provided
      {
        final db = openDb(encryptDir, passphrase: 'top-secret-key-123');
        await db.init();
        final interpreter = Interpreter(db);

        final queryRes = await interpreter.executeScript('SELECT secret FROM confidential;');
        expect(queryRes.rows.length, 1);
        expect(queryRes.rows[0][0].toString(), 'Nuclear Launch Codes');
        await db.close();
      }
    });
  });
}
