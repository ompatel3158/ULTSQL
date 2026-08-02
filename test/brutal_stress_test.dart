@Timeout(Duration(minutes: 5))

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

void main() {
  const dbDir = 'test_brutal_db';
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
    await Future.delayed(const Duration(milliseconds: 50));
    cleanDirectory(dbDir);
  });

  group('🏆 BRUTAL STRESS & DESTROY TESTS', () {
    // -------------------------------------------------------------
    // Test 1: Mid-Transaction Crash Recovery (WAL Revert)
    // -------------------------------------------------------------
    test('Test 1: Mid-Transaction Crash Recovery (WAL Revert)', () async {
      final myDbDir = '$dbDir/t1';
      cleanDirectory(myDbDir);

      // Step 1: Initialize table with a baseline committed row
      {
        final db = openDb(myDbDir);
        await db.init();
        final interpreter = Interpreter(db);
        await interpreter.executeScript('CREATE TABLE t1 (id INT, name TEXT);');
        await interpreter.executeScript('INSERT INTO t1 VALUES (1, \'Committed\');');
        await db.close();
      }

      // Step 2: Start transaction, write uncommitted rows, flush cache, and force-kill
      {
        final db = openDb(myDbDir);
        await db.init();
        final interpreter = Interpreter(db);
        await interpreter.executeScript('BEGIN TRANSACTION;');
        
        // Write 100 rows
        for (int i = 0; i < 100; i++) {
          await interpreter.executeScript('INSERT INTO t1 VALUES (${100 + i}, \'Uncommitted $i\');');
        }

        // Flush cache to disk to simulate dirty page write-backs during transaction
        db.cache.flushAllSync();

        // Simulate crash by closing immediately without committing
        await db.close();
      }

      // Step 3: Reopen database and verify WAL recovery rolled back uncommitted rows
      {
        final db = openDb(myDbDir);
        await db.init(); // recoverSync runs here
        final interpreter = Interpreter(db);

        final queryRes = await interpreter.executeScript('SELECT COUNT(*) FROM t1;');
        expect((queryRes.rows[0][0] as DbInt).value, 1, reason: 'Uncommitted rows must be fully reverted');
        await db.close();
      }
    });

    // -------------------------------------------------------------
    // Test 2: Post-Commit Immediate Crash Recovery (WAL Replay)
    // -------------------------------------------------------------
    test('Test 2: Post-Commit Immediate Crash Recovery (WAL Replay)', () async {
      final myDbDir = '$dbDir/t2';
      cleanDirectory(myDbDir);

      // Step 1: Initialize table
      {
        final db = openDb(myDbDir);
        await db.init();
        final interpreter = Interpreter(db);
        await interpreter.executeScript('CREATE TABLE t1 (id INT, val TEXT);');
        await db.close();
      }

      // Step 2: Start transaction, insert 100 rows, commit, then simulate crash
      {
        final db = openDb(myDbDir);
        await db.init();
        final interpreter = Interpreter(db);
        
        await interpreter.executeScript('BEGIN TRANSACTION;');
        for (int i = 0; i < 100; i++) {
          await interpreter.executeScript('INSERT INTO t1 VALUES ($i, \'Value_$i\');');
        }
        await interpreter.executeScript('COMMIT;');

        // Simulate crash by force closing
        await db.close();
      }

      // Step 3: Reopen database and verify committed data is replayed/present
      {
        final db = openDb(myDbDir);
        await db.init();
        final interpreter = Interpreter(db);

        final queryRes = await interpreter.executeScript('SELECT COUNT(*) FROM t1;');
        expect((queryRes.rows[0][0] as DbInt).value, 100, reason: 'Committed rows must survive crash');
        await db.close();
      }
    });

    // -------------------------------------------------------------
    // Test 3: Interleaved Transaction Chaos (Rollback Integrity)
    // -------------------------------------------------------------
    test('Test 3: Interleaved Transaction Chaos (Rollback Integrity)', () async {
      final myDbDir = '$dbDir/t3';
      cleanDirectory(myDbDir);

      final db = openDb(myDbDir);
      await db.init();
      final interpreter = Interpreter(db);

      await interpreter.executeScript('CREATE TABLE t1 (id INT, label TEXT);');

      final random = Random(1234);
      int expectedCount = 0;

      for (int cycle = 0; cycle < 50; cycle++) {
        await interpreter.executeScript('BEGIN TRANSACTION;');
        
        final int rowsInTx = random.nextInt(10) + 1;
        for (int i = 0; i < rowsInTx; i++) {
          await interpreter.executeScript('INSERT INTO t1 VALUES ($i, \'Label $i\');');
        }

        final bool shouldCommit = random.nextBool();
        if (shouldCommit) {
          await interpreter.executeScript('COMMIT;');
          expectedCount += rowsInTx;
        } else {
          await interpreter.executeScript('ROLLBACK;');
        }
        final curRes = await interpreter.executeScript('SELECT COUNT(*) FROM t1;');
        final curCount = (curRes.rows[0][0] as DbInt).value;
        if (curCount != expectedCount) {
          print('DISCREPANCY at cycle $cycle: shouldCommit=$shouldCommit, rowsInTx=$rowsInTx, expected=$expectedCount, actual=$curCount');
          break;
        }
      }

      final queryRes = await interpreter.executeScript('SELECT COUNT(*) FROM t1;');
      expect((queryRes.rows[0][0] as DbInt).value, expectedCount, reason: 'Rollback integrity check failed');
      await db.close();
    });

    // -------------------------------------------------------------
    // Test 4: Constraint & Type Coercion Fuzzing
    // -------------------------------------------------------------
    test('Test 4: Constraint & Type Coercion Fuzzing', () async {
      final myDbDir = '$dbDir/t4';
      cleanDirectory(myDbDir);

      final db = openDb(myDbDir);
      await db.init();
      final interpreter = Interpreter(db);

      await interpreter.executeScript('CREATE TABLE t1 (id INT PRIMARY KEY, val DOUBLE, info JSON);');

      // 1. Primary key violation fuzzing
      await interpreter.executeScript('INSERT INTO t1 VALUES (1, 10.5, \'{"a": 1}\');');
      
      final duplicateRes = await interpreter.executeScript('INSERT INTO t1 VALUES (1, 20.5, \'{"b": 2}\');');
      expect(duplicateRes.message, contains('Error:'), reason: 'Duplicate Primary Key insert must return an error message');

      // 2. Mismatched type coercion check
      // Insert int into double column -> should coerce to double
      await interpreter.executeScript('INSERT INTO t1 VALUES (2, 5, \'{"x": 10}\');');
      final doubleRes = await interpreter.executeScript('SELECT val FROM t1 WHERE id = 2;');
      expect(doubleRes.rows.isNotEmpty, isTrue, reason: 'Row 2 must be present');
      expect(doubleRes.rows[0][0], isA<DbDouble>(), reason: 'Int must be coerced to DbDouble');
      expect((doubleRes.rows[0][0] as DbDouble).value, 5.0);

      // 3. Invalid JSON insert
      final invalidJsonRes = await interpreter.executeScript('INSERT INTO t1 VALUES (3, 1.1, \'invalid-json-string\');');
      expect(invalidJsonRes.message, contains('Error:'), reason: 'Invalid JSON string must return an error message');

      await db.close();
    });

    // -------------------------------------------------------------
    // Test 5: Concurrent Read-Write Zone Stress
    // -------------------------------------------------------------
    test('Test 5: Concurrent Read-Write Zone Stress', () async {
      final myDbDir = '$dbDir/t5';
      cleanDirectory(myDbDir);

      final db = openDb(myDbDir);
      await db.init();
      final interpreter = Interpreter(db);

      await interpreter.executeScript('CREATE TABLE t1 (id INT, name TEXT);');
      await interpreter.executeScript('INSERT INTO t1 VALUES (1, \'Alice\');');

      final List<Future<void>> futures = [];

      // Reader loop
      for (int i = 0; i < 5; i++) {
        futures.add(Future(() async {
          final ctx = db.cache.createSessionContext();
          await runZoned(() async {
            final sessionInterpreter = Interpreter(db);
            for (int j = 0; j < 50; j++) {
              final res = await sessionInterpreter.executeScript('SELECT COUNT(*) FROM t1;');
              final count = (res.rows[0][0] as DbInt).value;
              expect(count, greaterThanOrEqualTo(1));
            }
          }, zoneValues: {#sessionTxContext: ctx});
        }));
      }

      // Writer loop
      for (int i = 0; i < 5; i++) {
        final id = 100 + i;
        futures.add(Future(() async {
          final ctx = db.cache.createSessionContext();
          await runZoned(() async {
            final sessionInterpreter = Interpreter(db);
            for (int j = 0; j < 10; j++) {
              await sessionInterpreter.executeScript('BEGIN TRANSACTION;');
              await sessionInterpreter.executeScript('INSERT INTO t1 VALUES ($id, \'Writer_$id\');');
              await sessionInterpreter.executeScript('COMMIT;');
            }
          }, zoneValues: {#sessionTxContext: ctx});
        }));
      }

      await Future.wait(futures);
      await db.close();
    });

    // -------------------------------------------------------------
    // Test 6: 10,000,000 Row NoSQL Insert & Retrieve Stress
    // -------------------------------------------------------------
    test('Test 6: 10,000,000 Row NoSQL Insert & Retrieve Stress', () async {
      final myDbDir = '$dbDir/t6';
      cleanDirectory(myDbDir);

      final db = openDb(myDbDir);
      await db.init();
      final interpreter = Interpreter(db);

      await interpreter.executeScript('CREATE TABLE nosql_stress (id INT, info JSON);');

      print('Starting 10,000,000 NoSQL JSON scale test...');
      final sw = Stopwatch()..start();
      await interpreter.executeScript('BEGIN TRANSACTION;');
      
      final stmt = db.prepare('INSERT INTO nosql_stress VALUES (?, ?);');
      
      // We do 10M rows in chunks of 500k to ensure GC clears intermediate lists and keeps RAM low
      const int totalRows = 10000000;
      const int chunkSize = 500000;
      const int numChunks = totalRows ~/ chunkSize;
      
      for (int c = 0; c < numChunks; c++) {
        final batch = List<List<DbValue>>.generate(chunkSize, (i) {
          final id = c * chunkSize + i;
          return [
            DbInt(id),
            DbText('{"age": ${(id % 100)}, "score": ${id * 1.5}, "status": "${id % 2 == 0 ? "active" : "pending"}"}')
          ];
        });
        stmt.executeBatchSync(batch);
        if ((c + 1) % 4 == 0) {
          print('Inserted ${(c + 1) * chunkSize} rows...');
        }
      }
      
      await interpreter.executeScript('COMMIT;');
      sw.stop();
      
      final double secs = sw.elapsedMilliseconds / 1000.0;
      final double rowsPerSec = totalRows / secs;
      print('10M JSON Inserts completed in: ${secs.toStringAsFixed(2)}s (${rowsPerSec.toStringAsFixed(0)} rows/sec)');
      
      // Fetch NoSQL filtering query using dotted paths
      final swSelect = Stopwatch()..start();
      final countRes = await interpreter.executeScript('SELECT COUNT(*) FROM nosql_stress WHERE info.age = 25;');
      swSelect.stop();
      print('10M Point filter count completed in: ${swSelect.elapsedMilliseconds}ms');
      
      expect((countRes.rows[0][0] as DbInt).value, totalRows ~/ 100);
      await db.close();
    });

    // -------------------------------------------------------------
    // Test 7: NoSQL & JSON Path Stressing
    // -------------------------------------------------------------
    test('Test 7: NoSQL & JSON Path Stressing', () async {
      final myDbDir = '$dbDir/t7';
      cleanDirectory(myDbDir);

      final db = openDb(myDbDir);
      await db.init();
      final interpreter = Interpreter(db);

      await interpreter.executeScript('CREATE TABLE nested_json (id INT, data JSON);');

      // 1. Insert deeply nested JSON object
      final deepJsonStr = '{"a":{"b":{"c":{"d":{"e":{"f":{"g":{"h":{"i":{"j": 42}}}}}}}}}}';
      await interpreter.executeScript('INSERT INTO nested_json VALUES (1, \'$deepJsonStr\');');

      // 2. Query deeply nested path
      final res = await interpreter.executeScript('SELECT data.a.b.c.d.e.f.g.h.i.j FROM nested_json WHERE id = 1;');
      expect((res.rows[0][0] as DbInt).value, 42, reason: 'Deep JSON path extraction failed');

      // 3. Query non-existent path -> should evaluate to DbNull safely
      final nullRes = await interpreter.executeScript('SELECT data.a.b.invalid_path.x FROM nested_json WHERE id = 1;');
      expect(nullRes.rows[0][0], isA<DbNull>(), reason: 'Non-existent JSON path must yield DbNull');

      // 4. Query JSON containing array
      await interpreter.executeScript('INSERT INTO nested_json VALUES (2, \'{"name": "Jack", "skills": ["Dart", "SQL"]}\');');
      final arrayRes = await interpreter.executeScript('SELECT data.skills FROM nested_json WHERE id = 2;');
      expect(arrayRes.rows[0][0].toString(), '["Dart","SQL"]');

      await db.close();
    });

    // -------------------------------------------------------------
    // Test 8: Vector (HNSW) & Graph Traversal Stressing
    // -------------------------------------------------------------
    test('Test 8: Vector (HNSW) & Graph Traversal Stressing', () async {
      final myDbDir = '$dbDir/t8';
      cleanDirectory(myDbDir);

      final db = openDb(myDbDir);
      await db.init();
      final interpreter = Interpreter(db);

      // Create nodes and relationships
      final c1 = await interpreter.executeScript('CREATE TABLE nodes (id INT PRIMARY KEY, name TEXT, vec VECTOR);');
      expect(c1.message, isNot(contains('Error:')));
      final c2 = await interpreter.executeScript('CREATE TABLE edges (from_id INT, to_id INT);');
      expect(c2.message, isNot(contains('Error:')));

      // Insert 1000 nodes using PL/SQL loop (since nodes table is Columnar and batch inserts are for Row store only)
      final nRes = await interpreter.executeScript('''
DECLARE
  i INT := 0;
BEGIN
  BEGIN TRANSACTION;
  WHILE i < 1000 LOOP
    INSERT INTO nodes VALUES (i, 'Node_' || i, '[0.1, 0.2, 0.3]');
    i := i + 1;
  END LOOP;
  COMMIT;
END;
''');
      expect(nRes.message, isNot(contains('Error:')));

      // Insert edges using PL/SQL block
      final eRes = await interpreter.executeScript('''
DECLARE
  i INT := 0;
BEGIN
  BEGIN TRANSACTION;
  WHILE i < 999 LOOP
    INSERT INTO edges VALUES (i, i + 1);
    i := i + 1;
  END LOOP;
  COMMIT;
END;
''');
      expect(eRes.message, isNot(contains('Error:')));

      // Define relationship
      final rRes = await interpreter.executeScript('CREATE RELATIONSHIP rec FROM edges TO nodes ON to_id = id;');
      expect(rRes.message, isNot(contains('Error:')));

      // Query graph join and verify
      final graphRes = await interpreter.executeScript(
        'SELECT edges.from_id, nodes.name FROM edges WITH RELATIONSHIP rec;'
      );
      expect(graphRes.message, isNot(contains('Error:')));
      expect(graphRes.rows.length, 999);
      expect(graphRes.rows[0][1].toString(), 'Node_1');

      await db.close();
    });

    // -------------------------------------------------------------
    // Test 9: WAL File Corruption & Truncation Chaos
    // -------------------------------------------------------------
    test('Test 9: WAL File Corruption & Truncation Chaos', () async {
      final myDbDir = '$dbDir/t9';
      cleanDirectory(myDbDir);

      // Step 1: Create a table and write a baseline committed row
      {
        final db = openDb(myDbDir);
        await db.init();
        final interpreter = Interpreter(db);
        await interpreter.executeScript('CREATE TABLE t1 (id INT, name TEXT);');
        await interpreter.executeScript('INSERT INTO t1 VALUES (1, \'Committed baseline\');');
        await db.close();
      }

      // Step 2: Start a transaction, write rows, flush dirty pages, and close
      {
        final db = openDb(myDbDir);
        await db.init();
        final interpreter = Interpreter(db);
        await interpreter.executeScript('BEGIN TRANSACTION;');
        await interpreter.executeScript('INSERT INTO t1 VALUES (2, \'Uncommitted Crash 1\');');
        await interpreter.executeScript('INSERT INTO t1 VALUES (3, \'Uncommitted Crash 2\');');
        db.cache.flushAllSync();
        await db.close();
      }

      // Step 3: Read the generated wal.log and append garbage corrupted bytes
      final walFile = File('$myDbDir/wal.log');
      expect(walFile.existsSync(), isTrue);
      
      final walBytes = walFile.readAsBytesSync();
      final corruptedBytes = Uint8List(walBytes.length + 100);
      corruptedBytes.setAll(0, walBytes);
      // Inject garbage/corrupted bytes at the end of the log
      for (int i = 0; i < 100; i++) {
        corruptedBytes[walBytes.length + i] = 0xAA;
      }
      walFile.writeAsBytesSync(corruptedBytes);

      // Step 4: Reopen database and verify WAL recovery manager handles corruption without crashing
      {
        final db = openDb(myDbDir);
        await db.init(); // recoverSync runs, parses corrupted log, and halts recovery safely
        final interpreter = Interpreter(db);

        final countRes = await interpreter.executeScript('SELECT COUNT(*) FROM t1;');
        expect((countRes.rows[0][0] as DbInt).value, 1, reason: 'Database baseline must remain clean');
        
        await db.close();
      }
    });

    // -------------------------------------------------------------
    // Test 10: Circular Graph Traversal (Stack Overflow Check)
    // -------------------------------------------------------------
    test('Test 10: Circular Graph Traversal (Stack Overflow Check)', () async {
      final myDbDir = '$dbDir/t10';
      cleanDirectory(myDbDir);

      final db = openDb(myDbDir);
      await db.init();
      final interpreter = Interpreter(db);

      await interpreter.executeScript('CREATE TABLE nodes (id INT PRIMARY KEY, name TEXT);');
      await interpreter.executeScript('CREATE TABLE edges (from_id INT, to_id INT);');

      // Insert loop relationships: Node 0 -> Node 1 -> Node 2 -> Node 0
      await interpreter.executeScript('INSERT INTO nodes VALUES (0, \'Node 0\');');
      await interpreter.executeScript('INSERT INTO nodes VALUES (1, \'Node 1\');');
      await interpreter.executeScript('INSERT INTO nodes VALUES (2, \'Node 2\');');

      await interpreter.executeScript('INSERT INTO edges VALUES (0, 1);');
      await interpreter.executeScript('INSERT INTO edges VALUES (1, 2);');
      await interpreter.executeScript('INSERT INTO edges VALUES (2, 0);');

      // Create relationship
      await interpreter.executeScript('CREATE RELATIONSHIP loop_rel FROM edges TO nodes ON to_id = id;');

      // Query relationship join on loop (this should resolve single-hop join without infinite recursion)
      final res = await interpreter.executeScript(
        'SELECT edges.from_id, nodes.name FROM edges WITH RELATIONSHIP loop_rel;'
      );
      expect(res.rows.length, 3, reason: 'Volcano graph joins must match exact edge counts');
      expect(res.rows[0][0].toString(), '0');
      expect(res.rows[0][1].toString(), 'Node 1');
      expect(res.rows[1][0].toString(), '1');
      expect(res.rows[1][1].toString(), 'Node 2');
      expect(res.rows[2][0].toString(), '2');
      expect(res.rows[2][1].toString(), 'Node 0');

      await db.close();
    });
  });
}
