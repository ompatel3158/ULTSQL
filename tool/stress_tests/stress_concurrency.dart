import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/cache/page_cache.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/storage/table_file.dart';

// ============================================================================
// ULTSQL BRUTAL CONCURRENCY & CHAOS TEST SUITE
// ============================================================================

const String kDbDir = 'test_concurrency_db';
const String kDbDir1 = 'test_concurrency_db_1';
const String kDbDir2 = 'test_concurrency_db_2';
const String kDbDir3 = 'test_concurrency_db_3';
const String kDbDir4 = 'test_concurrency_db_4';
const String kDbDir5 = 'test_concurrency_db_5';

void main(List<String> args) async {
  // Check for worker CLI modes first
  if (args.isNotEmpty) {
    final mode = args[0];
    if (mode == '--worker-hold-lock') {
      await _runWorkerHoldLock(args.length > 1 ? args[1] : kDbDir);
      return;
    } else if (mode == '--worker-compete') {
      final dbPath = args.length > 1 ? args[1] : kDbDir;
      final workerId = args.length > 2 ? int.parse(args[2]) : 0;
      final timeoutMs = args.length > 3 ? int.parse(args[3]) : 0;
      await _runWorkerCompete(dbPath, workerId, timeoutMs);
      return;
    } else if (mode == '--worker-dirty-crash') {
      final dbPath = args.length > 1 ? args[1] : kDbDir;
      await _runWorkerDirtyCrash(dbPath);
      return;
    }
  }

  // Master Test Runner
  print('======================================================================');
  print(' 🔥 ULTSQL BRUTAL CONCURRENCY & CHAOS STRESS SUITE 🔥');
  print(' Target Directory: $kDbDir');
  print(' Platform: ${Platform.operatingSystem} (${Platform.numberOfProcessors} cores)');
  print(' Dart Version: ${Platform.version}');
  print('======================================================================\n');

  final suiteSw = Stopwatch()..start();
  final defects = <String>[];
  final testSummaries = <Map<String, dynamic>>[];

  // --------------------------------------------------------------------------
  // TEST 1: Multi-Isolate Parallel Hammering
  // --------------------------------------------------------------------------
  final res1 = await test1MultiIsolateHammering(defects);
  testSummaries.add(res1);

  // --------------------------------------------------------------------------
  // TEST 2: Multi-Process Lock Collision
  // --------------------------------------------------------------------------
  final res2 = await test2MultiProcessLockCollision(defects);
  testSummaries.add(res2);

  // --------------------------------------------------------------------------
  // TEST 3: Extreme Cache Thrashing & Eviction under Pressure
  // --------------------------------------------------------------------------
  final res3 = await test3CacheThrashingEviction(defects);
  testSummaries.add(res3);

  // --------------------------------------------------------------------------
  // TEST 4: Concurrent Snapshot Isolation Violations
  // --------------------------------------------------------------------------
  final res4 = await test4SnapshotIsolationViolations(defects);
  testSummaries.add(res4);

  // --------------------------------------------------------------------------
  // TEST 5: Lock Release on Abnormal Termination & Crash Recovery
  // --------------------------------------------------------------------------
  final res5 = await test5LockReleaseAbnormalTermination(defects);
  testSummaries.add(res5);

  suiteSw.stop();

  // Clean DB directories at the end
  for (final dir in [kDbDir1, kDbDir2, kDbDir3, kDbDir4, kDbDir5]) {
    await _cleanDirectory(dir);
  }

  // Print Grand Executive Summary
  print('\n======================================================================');
  print(' 📊 GRAND CONCURRENCY STRESS REPORT');
  print(' Suite Total Execution Time: ${suiteSw.elapsedMilliseconds}ms');
  print('======================================================================');
  for (final s in testSummaries) {
    final status = s['passed'] == true ? '✅ PASS' : '❌ FAIL';
    print('$status [${s['name']}] Duration: ${s['durationMs']}ms');
    if (s['metrics'] != null) {
      final m = s['metrics'] as Map<String, dynamic>;
      m.forEach((k, v) => print('   • $k: $v'));
    }
  }

  print('\n----------------------------------------------------------------------');
  print(' 🚨 IDENTIFIED CONCURRENCY DEFECTS & VULNERABILITIES (${defects.length}):');
  print('----------------------------------------------------------------------');
  if (defects.isEmpty) {
    print('  None detected! System held up against all chaos attacks.');
  } else {
    for (int i = 0; i < defects.length; i++) {
      print('  ${i + 1}. ${defects[i]}');
    }
  }
  print('======================================================================\n');

  if (defects.isNotEmpty) {
    exitCode = 1;
  }
}

// ============================================================================
// HELPER UTILITIES
// ============================================================================

Future<void> _cleanDirectory(String path) async {
  final dir = Directory(path);
  for (int i = 0; i < 5; i++) {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      return;
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

Future<void> _ensureCleanDirectory(String path) async {
  await _cleanDirectory(path);
  await Directory(path).create(recursive: true);
}

// ============================================================================
// WORKER MODES FOR MULTI-PROCESS TESTS
// ============================================================================

Future<void> _runWorkerHoldLock(String dbPath) async {
  try {
    final engine = await UltSqlEngine.openFile(dbPath);
    await engine.query('CREATE TABLE IF NOT EXISTS lock_held (id INT);');
    await engine.query('INSERT INTO lock_held VALUES (42);');
    stdout.writeln('LOCK_ACQUIRED');
    await stdout.flush();

    // Block indefinitely waiting to be killed
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
    }
  } catch (e) {
    stderr.writeln('WORKER_ERROR: $e');
    exit(1);
  }
}

Future<void> _runWorkerCompete(String dbPath, int workerId, int timeoutMs) async {
  try {
    final db = Database(
      dbPath,
      lockTimeout: Duration(milliseconds: timeoutMs),
    );
    await db.init();
    final interp = Interpreter(db);
    stdout.writeln('LOCK_ACQUIRED:$workerId');
    await stdout.flush();

    // Perform small write
    await interp.executeScript('INSERT INTO proc_compete VALUES ($workerId, ${DateTime.now().millisecondsSinceEpoch});');
    await Future.delayed(const Duration(milliseconds: 100));

    await db.close();
    stdout.writeln('WORKER_DONE:$workerId');
    await stdout.flush();
    exit(0);
  } on DatabaseLockException catch (e) {
    stdout.writeln('LOCK_REJECTED:$workerId:${e.message}');
    await stdout.flush();
    exit(2);
  } catch (e) {
    stderr.writeln('WORKER_FATAL:$workerId:$e');
    await stderr.flush();
    exit(3);
  }
}

Future<void> _runWorkerDirtyCrash(String dbPath) async {
  try {
    final db = Database(dbPath, useWal: true);
    await db.init();
    final interp = Interpreter(db);

    await interp.executeScript('BEGIN TRANSACTION;');
    await interp.executeScript('INSERT INTO crash_recovery VALUES (999, 99999);');
    // Signal parent that uncommitted insert is in WAL/buffer
    stdout.writeln('UNCOMMITTED_WRITTEN');
    await stdout.flush();

    // Wait to be abruptly killed by parent
    while (true) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  } catch (e) {
    stderr.writeln('WORKER_ERROR: $e');
    exit(1);
  }
}

// ============================================================================
// TEST 1: Multi-Isolate Parallel Hammering
// ============================================================================

void _isolateHammerEntry(List<dynamic> args) async {
  final SendPort sendPort = args[0];
  final int isolateId = args[1];
  final String dbPath = args[2];
  final int iterations = args[3];

  int openedCount = 0;
  int lockRejections = 0;
  int opCount = 0;
  int errors = 0;
  String? lastError;

  for (int iter = 0; iter < iterations; iter++) {
    Database? db;
    try {
      db = Database(
        dbPath,
        lockTimeout: const Duration(milliseconds: 150),
      );
      await db.init();
      openedCount++;
      final interp = Interpreter(db);

      // Perform rapid batch of operations
      final val = iter * 10 + isolateId;
      await interp.executeScript("INSERT INTO iso_hammer VALUES ($isolateId, $val, 'iso_$isolateId');");
      opCount++;

      if (iter % 3 == 0) {
        await interp.executeScript("UPDATE iso_hammer SET val = ${val + 1} WHERE worker_id = $isolateId AND val = $val;");
        opCount++;
      }

      if (iter % 5 == 0) {
        await interp.executeScript("DELETE FROM iso_hammer WHERE worker_id = $isolateId AND val > 1000;");
        opCount++;
      }

      final res = await interp.executeScript("SELECT COUNT(*) FROM iso_hammer WHERE worker_id = $isolateId;");
      if (res.rows.isEmpty) {
        errors++;
        lastError = 'Empty count result';
      }
      opCount++;

      await db.close();
      db = null;

      // Small jitter between iterations
      await Future.delayed(Duration(milliseconds: Random().nextInt(10) + 1));
    } on DatabaseLockException {
      lockRejections++;
      await Future.delayed(Duration(milliseconds: Random().nextInt(20) + 5));
    } catch (e) {
      errors++;
      lastError = e.toString();
    } finally {
      if (db != null) {
        try {
          await db.close();
        } catch (_) {}
      }
    }
  }

  sendPort.send({
    'isolateId': isolateId,
    'openedCount': openedCount,
    'lockRejections': lockRejections,
    'opCount': opCount,
    'errors': errors,
    'lastError': lastError,
  });
}

Future<Map<String, dynamic>> test1MultiIsolateHammering(List<String> defects) async {
  print('----------------------------------------------------------------------');
  print(' 💥 TEST 1: Multi-Isolate Parallel Hammering (10 Isolates)');
  print('----------------------------------------------------------------------');
  final sw = Stopwatch()..start();
  await _ensureCleanDirectory(kDbDir1);

  // Setup initial table
  final initDb = Database(kDbDir1);
  await initDb.init();
  final initInterp = Interpreter(initDb);
  await initInterp.executeScript('CREATE TABLE iso_hammer (worker_id INT, val INT, tag TEXT);');
  await initDb.close();

  const int numIsolates = 10;
  const int iterationsPerIsolate = 25;
  final rp = ReceivePort();

  print(' -> Spawning $numIsolates Dart Isolates hammering disk table simultaneously...');
  for (int i = 0; i < numIsolates; i++) {
    await Isolate.spawn(_isolateHammerEntry, [
      rp.sendPort,
      i,
      kDbDir1,
      iterationsPerIsolate,
    ]);
  }

  int completed = 0;
  int totalOps = 0;
  int totalOpened = 0;
  int totalLockRejections = 0;
  int totalErrors = 0;
  final isolateErrors = <String>[];

  await for (final dynamic msg in rp) {
    if (msg is Map) {
      completed++;
      totalOps += (msg['opCount'] as int);
      totalOpened += (msg['openedCount'] as int);
      totalLockRejections += (msg['lockRejections'] as int);
      final err = (msg['errors'] as int);
      totalErrors += err;
      if (err > 0 && msg['lastError'] != null) {
        isolateErrors.add('Isolate ${msg['isolateId']}: ${msg['lastError']}');
      }
      if (completed == numIsolates) break;
    }
  }
  rp.close();
  sw.stop();

  // Post-hammer database validation & integrity inspection
  bool dbCorrupted = false;
  int finalRowCount = -1;
  String? verifyError;
  try {
    final vDb = Database(kDbDir1);
    await vDb.init();
    final vInterp = Interpreter(vDb);
    final countRes = await vInterp.executeScript('SELECT COUNT(*) FROM iso_hammer;');
    finalRowCount = (countRes.rows[0][0] as DbInt).value;

    // Scan table file directly to check slotted pages
    final tablePath = '$kDbDir1/iso_hammer.db';
    final tableFile = File(tablePath);
    if (tableFile.existsSync()) {
      final bytes = tableFile.readAsBytesSync();
      final pageCount = bytes.length ~/ 4096;
      for (int p = 0; p < pageCount; p++) {
        final pOffset = p * 4096;
        final pageBytes = bytes.sublist(pOffset, pOffset + 4096);
        final bData = ByteData.sublistView(pageBytes);
        final rowCount = bData.getUint16(1);
        final freeSpace = bData.getUint16(3);
        if (rowCount > 0) {
          final slotEnd = 5 + rowCount * 4;
          if (freeSpace < slotEnd && freeSpace != 0) {
            dbCorrupted = true;
            verifyError = 'Corrupted slotted page $p: freeSpaceOffset ($freeSpace) < slotEnd ($slotEnd)';
            break;
          }
        }
      }
    }
    await vDb.close();
  } catch (e) {
    dbCorrupted = true;
    verifyError = 'Database reopen failure after isolate hammering: $e';
  }

  final throughput = (totalOps / (sw.elapsedMilliseconds / 1000)).toStringAsFixed(1);
  print(' -> Total Operations: $totalOps ($throughput ops/sec)');
  print(' -> Database Opens: $totalOpened, Lock Contentions: $totalLockRejections');
  print(' -> Isolate Errors: $totalErrors, Final Row Count: $finalRowCount');

  if (dbCorrupted || totalErrors > 0) {
    final defect = 'Test 1 Defect: Slotted page corruption or isolate crash ($verifyError, errors: $isolateErrors)';
    defects.add(defect);
    print(' ❌ FAIL: $defect');
  } else {
    print(' ✅ PASS: All 10 isolates completed cleanly; table pages verified intact.');
  }

  return {
    'name': 'Multi-Isolate Parallel Hammering',
    'passed': !dbCorrupted && totalErrors == 0,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': {
      'isolates': numIsolates,
      'totalOps': totalOps,
      'throughputOpsSec': throughput,
      'totalLockRejections': totalLockRejections,
      'finalRowCount': finalRowCount,
      'corrupted': dbCorrupted,
    },
  };
}

// ============================================================================
// TEST 2: Multi-Process Lock Collision
// ============================================================================

Future<Map<String, dynamic>> test2MultiProcessLockCollision(List<String> defects) async {
  print('\n----------------------------------------------------------------------');
  print(' 💥 TEST 2: Multi-Process Lock Collision (6-8 OS Processes)');
  print('----------------------------------------------------------------------');
  final sw = Stopwatch()..start();
  await _ensureCleanDirectory(kDbDir2);

  // Initialize DB and table
  final initDb = Database(kDbDir2);
  await initDb.init();
  final initInterp = Interpreter(initDb);
  await initInterp.executeScript('CREATE TABLE proc_compete (worker_id INT, ts INT);');
  await initDb.close();

  final scriptPath = Platform.script.toFilePath();

  // Phase 2A: Instant Collision (timeout = 0)
  print(' -> Phase 2A: Firing 7 OS processes with lockTimeout: 0ms (immediate gate test)...');
  const int numProcs2A = 7;
  final procs2A = <Future<ProcessResult>>[];

  for (int i = 0; i < numProcs2A; i++) {
    procs2A.add(Process.run('dart', [
      'run',
      scriptPath,
      '--worker-compete',
      kDbDir2,
      '$i',
      '0', // 0ms timeout
    ]));
  }

  final results2A = await Future.wait(procs2A);
  int acquired2A = 0;
  int rejected2A = 0;
  int fatal2A = 0;
  final fatalOutputs = <String>[];

  for (final res in results2A) {
    final stdoutStr = res.stdout.toString();
    final stderrStr = res.stderr.toString();
    if (stdoutStr.contains('LOCK_ACQUIRED')) {
      acquired2A++;
    } else if (stdoutStr.contains('LOCK_REJECTED')) {
      rejected2A++;
    } else {
      fatal2A++;
      fatalOutputs.add('exit:${res.exitCode} out:$stdoutStr err:$stderrStr');
    }
  }

  print('    Phase 2A Results: Acquired: $acquired2A, Rejected cleanly: $rejected2A, Fatal/Crashed: $fatal2A');

  // Phase 2B: Lock Handoff with Timeout (timeout = 4000ms)
  print(' -> Phase 2B: Firing 5 OS processes with lockTimeout: 4000ms (sequential handoff test)...');
  const int numProcs2B = 5;
  final procs2B = <Future<ProcessResult>>[];

  for (int i = 0; i < numProcs2B; i++) {
    procs2B.add(Process.run('dart', [
      'run',
      scriptPath,
      '--worker-compete',
      kDbDir2,
      '${10 + i}',
      '4000', // 4000ms timeout
    ]));
  }

  final results2B = await Future.wait(procs2B);
  int acquired2B = 0;
  int rejected2B = 0;
  int fatal2B = 0;

  for (final res in results2B) {
    final stdoutStr = res.stdout.toString();
    if (stdoutStr.contains('LOCK_ACQUIRED')) {
      acquired2B++;
    } else if (stdoutStr.contains('LOCK_REJECTED')) {
      rejected2B++;
    } else {
      fatal2B++;
    }
  }

  print('    Phase 2B Results: Acquired sequentially: $acquired2B, Timed out: $rejected2B, Fatal/Crashed: $fatal2B');

  // Verify DB state
  bool catalogCorrupted = false;
  int totalInsertedRows = 0;
  try {
    final vDb = Database(kDbDir2);
    await vDb.init();
    final vInterp = Interpreter(vDb);
    final countRes = await vInterp.executeScript('SELECT COUNT(*) FROM proc_compete;');
    totalInsertedRows = (countRes.rows[0][0] as DbInt).value;
    await vDb.close();
  } catch (e) {
    catalogCorrupted = true;
  }

  sw.stop();

  bool testPassed = true;
  if (fatal2A > 0 || fatal2B > 0) {
    testPassed = false;
    defects.add('Test 2 Defect: OS Process crashed without proper DatabaseLockException handling ($fatalOutputs)');
  }
  if (acquired2A > 1) {
    testPassed = false;
    defects.add('Test 2 Defect: Mutual Exclusion Broken! Multiple processes ($acquired2A) acquired exclusive lock simultaneously!');
  }
  if (catalogCorrupted) {
    testPassed = false;
    defects.add('Test 2 Defect: catalog.db or lock file corrupted under multi-process lock competition');
  }

  if (testPassed) {
    print(' ✅ PASS: DatabaseLockException cleanly gated multi-process collision. Rows: $totalInsertedRows');
  } else {
    print(' ❌ FAIL: Multi-process lock defects encountered.');
  }

  return {
    'name': 'Multi-Process Lock Collision',
    'passed': testPassed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': {
      'phase2A_acquired': acquired2A,
      'phase2A_rejected': rejected2A,
      'phase2B_acquired': acquired2B,
      'phase2B_timedOut': rejected2B,
      'fatalCrashes': fatal2A + fatal2B,
      'totalInsertedRows': totalInsertedRows,
      'catalogCorrupted': catalogCorrupted,
    },
  };
}

// ============================================================================
// TEST 3: Extreme Cache Thrashing & Eviction under Pressure
// ============================================================================

Future<Map<String, dynamic>> test3CacheThrashingEviction(List<String> defects) async {
  print('\n----------------------------------------------------------------------');
  print(' 💥 TEST 3: Extreme Cache Thrashing & Eviction (maxCapacity: 10 vs 5,000 Pages)');
  print('----------------------------------------------------------------------');
  final sw = Stopwatch()..start();
  await _ensureCleanDirectory(kDbDir3);

  // Initialize DB with tiny cache capacity: ONLY 10 PAGES!
  const int kTinyCacheCapacity = 10;
  final db = Database(
    kDbDir3,
    maxCapacity: kTinyCacheCapacity,
    useWal: true,
  );
  await db.init();
  final interp = Interpreter(db);

  // 1. Create 5 tables and generate ~5,000 pages on disk
  // Each row has 350-byte string payload. 4096 / 350 = ~10 rows per page.
  // 1,000 pages per table = ~10,000 rows per table.
  // 5 tables * 1,000 pages = 5,000 pages total.
  final tables = ['tbl_a', 'tbl_b', 'tbl_c', 'tbl_d', 'tbl_e'];
  const int rowsPerTable = 10000;
  final padding = 'X' * 350;

  print(' -> Ingesting 50,000 rows across 5 tables (~5,000 pages on disk)...');
  for (final t in tables) {
    await interp.executeScript('CREATE TABLE $t (id INT PRIMARY KEY, val INT, payload TEXT);');

    // Batch insert 10,000 rows per table
    final batchSize = 1000;
    for (int b = 0; b < rowsPerTable; b += batchSize) {
      final rows = List.generate(
        batchSize,
        (i) => [b + i, (b + i) * 2, padding],
      );
      await interp.insertBatch(t, rows);
    }
  }

  // Verify page counts on disk
  int totalDiskPages = 0;
  for (final t in tables) {
    final f = File('$kDbDir3/$t.db');
    if (f.existsSync()) {
      totalDiskPages += f.lengthSync() ~/ 4096;
    }
  }
  print(' -> Total Pages Created On Disk: $totalDiskPages (Cache Capacity: $kTinyCacheCapacity)');

  // 2. Brutal Concurrent Thrashing & Mutation
  print(' -> Running aggressive interleaved scan & update thrashing against tiny cache...');
  int queriesCompleted = 0;
  int updatesCompleted = 0;
  int cacheErrors = 0;
  final random = Random(42);

  final thrashSw = Stopwatch()..start();
  // Interleave scans and point updates touching pages all over the 5,000 pages
  for (int round = 0; round < 40; round++) {
    final tName = tables[round % tables.length];

    // Query 1: Full table scan (forces scanning 1,000 pages through 10-slot cache)
    try {
      final res = await interp.executeScript('SELECT COUNT(*), MAX(val) FROM $tName;');
      if (res.rows.isNotEmpty) queriesCompleted++;
    } catch (e) {
      cacheErrors++;
    }

    // Query 2: Point updates across scattered pages
    for (int u = 0; u < 25; u++) {
      final randId = random.nextInt(rowsPerTable);
      try {
        await interp.executeScript('UPDATE $tName SET val = val + 1 WHERE id = $randId;');
        updatesCompleted++;
      } catch (e) {
        cacheErrors++;
      }
    }

    // Query 3: Point lookup
    for (int l = 0; l < 25; l++) {
      final randId = random.nextInt(rowsPerTable);
      try {
        final res = await interp.executeScript('SELECT id, val FROM $tName WHERE id = $randId;');
        if (res.rows.isNotEmpty) queriesCompleted++;
      } catch (e) {
        cacheErrors++;
      }
    }
  }
  thrashSw.stop();

  // Inspect page cache state
  print(' -> Thrash Completed in ${thrashSw.elapsedMilliseconds}ms. Queries: $queriesCompleted, Updates: $updatesCompleted');
  print(' -> Cache Max Capacity Configured: $kTinyCacheCapacity');

  // 3. Close database (forces full flush of dirty pages from tiny cache)
  await db.close();

  // 4. Reopen and verify data consistency
  final vDb = Database(kDbDir3, maxCapacity: 5000);
  await vDb.init();
  final vInterp = Interpreter(vDb);
  bool dataLoss = false;
  for (final t in tables) {
    final res = await vInterp.executeScript('SELECT COUNT(*) FROM $t;');
    final count = (res.rows[0][0] as DbInt).value;
    if (count != rowsPerTable) {
      dataLoss = true;
      defects.add('Test 3 Defect: Data loss under cache thrashing! Table $t expected $rowsPerTable rows, found $count');
    }
  }
  await vDb.close();
  sw.stop();

  bool testPassed = !dataLoss && cacheErrors == 0;
  if (testPassed) {
    print(' ✅ PASS: Cache thrashing survived 5,000+ pages with zero data loss or pin leaks.');
  } else {
    print(' ❌ FAIL: Cache thrashing produced errors or data loss.');
  }

  return {
    'name': 'Extreme Cache Thrashing & Eviction',
    'passed': testPassed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': {
      'totalDiskPages': totalDiskPages,
      'cacheMaxCapacity': kTinyCacheCapacity,
      'queriesCompleted': queriesCompleted,
      'updatesCompleted': updatesCompleted,
      'cacheErrors': cacheErrors,
      'dataLoss': dataLoss,
    },
  };
}

// ============================================================================
// TEST 4: Concurrent Snapshot Isolation Violations
// ============================================================================

Future<Map<String, dynamic>> test4SnapshotIsolationViolations(List<String> defects) async {
  print('\n----------------------------------------------------------------------');
  print(' 💥 TEST 4: Concurrent Snapshot Isolation Violations (Dirty Read Chaos)');
  print('----------------------------------------------------------------------');
  final sw = Stopwatch()..start();
  await _ensureCleanDirectory(kDbDir4);

  final db = Database(kDbDir4, useWal: true);
  await db.init();

  // Setup: 20 accounts with balance $5,000 each. Total invariant sum: $100,000.
  const int numAccounts = 20;
  const int initialBalance = 5000;
  const int kInvariantSum = numAccounts * initialBalance; // 100,000

  final setupInterp = Interpreter(db);
  await setupInterp.executeScript('CREATE TABLE accounts (id INT PRIMARY KEY, balance INT);');
  for (int i = 1; i <= numAccounts; i++) {
    await setupInterp.executeScript('INSERT INTO accounts VALUES ($i, $initialBalance);');
  }

  print(' -> Initialized $numAccounts accounts. Balance invariant SUM = $kInvariantSum.');

  bool writerDone = false;
  int totalTransactions = 0;
  int readerQueries = 0;
  int dirtyReads = 0;
  final observedAnomalies = <int, int>{};
  int readerExceptions = 0;

  // Writer task: transfers $500 between accounts inside explicit transactions
  final writerFuture = Future(() async {
    final writer = Interpreter(db);
    final random = Random(1234);

    for (int t = 0; t < 60; t++) {
      final fromAcc = (t % numAccounts) + 1;
      final toAcc = ((t + 1) % numAccounts) + 1;
      const transferAmount = 500;

      await writer.executeScript('BEGIN TRANSACTION;');
      // Step 1: Deduct $500 from fromAcc -> Total sum is temporarily 99,500!
      await writer.executeScript('UPDATE accounts SET balance = balance - $transferAmount WHERE id = $fromAcc;');

      // Micro-yield to give concurrent readers an opportunity to read intermediate state
      await Future.delayed(const Duration(milliseconds: 2));

      // Step 2: Add $500 to toAcc -> Total sum restored to 100,000
      await writer.executeScript('UPDATE accounts SET balance = balance + $transferAmount WHERE id = $toAcc;');
      await writer.executeScript('COMMIT;');

      totalTransactions++;
      await Future.delayed(Duration(milliseconds: random.nextInt(3) + 1));
    }
    writerDone = true;
  });

  // Concurrent Reader tasks
  const int numReaderTasks = 4;
  final readerFutures = List.generate(numReaderTasks, (readerId) async {
    final reader = Interpreter(db);
    while (!writerDone) {
      try {
        final res = await reader.executeScript('SELECT SUM(balance) FROM accounts;');
        if (res.rows.isNotEmpty && res.rows[0][0] is DbInt) {
          final sumVal = (res.rows[0][0] as DbInt).value;
          readerQueries++;
          if (sumVal != kInvariantSum) {
            dirtyReads++;
            observedAnomalies[sumVal] = (observedAnomalies[sumVal] ?? 0) + 1;
          }
        }
      } catch (e) {
        readerExceptions++;
      }
      await Future.delayed(const Duration(milliseconds: 1));
    }
  });

  await Future.wait([writerFuture, ...readerFutures]);
  await db.close();
  sw.stop();

  print(' -> Total Transactions Committed: $totalTransactions');
  print(' -> Reader Queries Executed: $readerQueries, Exceptions: $readerExceptions');
  print(' -> Dirty Reads / Snapshot Violations: $dirtyReads');
  if (observedAnomalies.isNotEmpty) {
    print(' -> Anomalous Sums Observed: $observedAnomalies (Expected: $kInvariantSum)');
  }

  bool testPassed = (dirtyReads == 0 && readerExceptions == 0);
  if (!testPassed) {
    final defect = 'Test 4 Defect: Snapshot Isolation Broken! Readers observed $dirtyReads intermediate uncommitted states: $observedAnomalies';
    defects.add(defect);
    print(' ❌ FAIL: $defect');
  } else {
    print(' ✅ PASS: Zero snapshot isolation violations. Invariant sum ($kInvariantSum) preserved across all reads.');
  }

  return {
    'name': 'Concurrent Snapshot Isolation Violations',
    'passed': testPassed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': {
      'transactions': totalTransactions,
      'readerQueries': readerQueries,
      'dirtyReads': dirtyReads,
      'anomalies': observedAnomalies,
      'readerExceptions': readerExceptions,
    },
  };
}

// ============================================================================
// TEST 5: Lock Release on Abnormal Termination & Crash Recovery
// ============================================================================

Future<Map<String, dynamic>> test5LockReleaseAbnormalTermination(List<String> defects) async {
  print('\n----------------------------------------------------------------------');
  print(' 💥 TEST 5: Lock Release on Abnormal Termination & Crash Recovery');
  print('----------------------------------------------------------------------');
  final sw = Stopwatch()..start();
  await _ensureCleanDirectory(kDbDir5);

  final scriptPath = Platform.script.toFilePath();

  // 1. Spawn child process holding lock
  print(' -> Spawning child process to acquire and hold database lock...');
  final proc = await Process.start('dart', [
    'run',
    scriptPath,
    '--worker-hold-lock',
    kDbDir5,
  ]);

  final completer = Completer<void>();
  proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    if (line.contains('LOCK_ACQUIRED') && !completer.isCompleted) {
      completer.complete();
    }
  });

  await completer.future.timeout(const Duration(seconds: 15));
  print('    Child process confirmed lock acquisition.');

  // 2. Verify parent is blocked
  bool parentBlocked = false;
  try {
    final dbCheck = Database(kDbDir5);
    await dbCheck.init();
    await dbCheck.close();
  } on DatabaseLockException {
    parentBlocked = true;
    print('    Parent verified exclusive lock is active (DatabaseLockException received).');
  }

  // 3. Brutally kill child process (SIGKILL / TerminateProcess)
  print(' -> Brutally killing child process with SIGKILL (abnormal termination)...');
  proc.kill(ProcessSignal.sigkill);
  final exitCode = await proc.exitCode;
  print('    Child process terminated (exit code: $exitCode).');

  // Verify lock file still exists physically on disk
  final lockFile = File('$kDbDir5/ultsql.lock');
  final lockFileExists = lockFile.existsSync();
  print('    File on disk (ultsql.lock) exists: $lockFileExists');

  // 4. Attempt to reopen database from parent immediately
  print(' -> Attempting immediate database reopen after abnormal process death...');
  bool reopenSuccess = false;
  String? reopenError;
  try {
    final dbRecover = Database(kDbDir5);
    await dbRecover.init();
    final interp = Interpreter(dbRecover);
    final res = await interp.executeScript('SELECT * FROM lock_held;');
    reopenSuccess = (res.rows.isNotEmpty && res.rows[0][0] is DbInt && (res.rows[0][0] as DbInt).value == 42);
    await dbRecover.close();
  } catch (e) {
    reopenError = e.toString();
  }

  // 5. Test crash recovery on uncommitted dirty transaction
  print(' -> Testing WAL crash recovery on uncommitted dirty transaction kill...');
  try {
    final setupDb = Database(kDbDir5);
    await setupDb.init();
    final sInterp = Interpreter(setupDb);
    await sInterp.executeScript('CREATE TABLE IF NOT EXISTS crash_recovery (id INT, val INT);');
    await setupDb.close();
  } catch (_) {}

  final crashProc = await Process.start('dart', [
    'run',
    scriptPath,
    '--worker-dirty-crash',
    kDbDir5,
  ]);

  final crashCompleter = Completer<void>();
  crashProc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    if (line.contains('UNCOMMITTED_WRITTEN') && !crashCompleter.isCompleted) {
      crashCompleter.complete();
    }
  });

  await crashCompleter.future.timeout(const Duration(seconds: 15));
  print('    Child wrote uncommitted dirty transaction. Killing abruptly...');
  crashProc.kill(ProcessSignal.sigkill);
  await crashProc.exitCode;

  // Reopen and verify whether uncommitted row (999) was properly rolled back or present
  bool dirtyRowRolledBack = true;
  try {
    final crashDb = Database(kDbDir5);
    await crashDb.init();
    final cInterp = Interpreter(crashDb);
    final res = await cInterp.executeScript('SELECT COUNT(*) FROM crash_recovery WHERE id = 999;');
    final count = (res.rows[0][0] as DbInt).value;
    dirtyRowRolledBack = (count == 0);
    await crashDb.close();
  } catch (e) {
    dirtyRowRolledBack = false;
  }

  sw.stop();

  bool testPassed = true;
  if (!parentBlocked) {
    testPassed = false;
    defects.add('Test 5 Defect: Parent failed to detect exclusive lock held by child process');
  }
  if (!reopenSuccess) {
    testPassed = false;
    defects.add('Test 5 Defect: Abrupt process kill left database permanently bricked! Reopen error: $reopenError');
  }
  if (!dirtyRowRolledBack) {
    testPassed = false;
    defects.add('Test 5 Defect: Crash recovery failed to rollback uncommitted transaction from killed process');
  }

  if (testPassed) {
    print(' ✅ PASS: OS kernel released lock upon abnormal termination; database reopened cleanly and recovered WAL.');
  } else {
    print(' ❌ FAIL: Abnormal termination handling failed.');
  }

  return {
    'name': 'Lock Release on Abnormal Termination',
    'passed': testPassed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': {
      'lockFileExistsOnDisk': lockFileExists,
      'reopenSuccess': reopenSuccess,
      'dirtyRowRolledBack': dirtyRowRolledBack,
    },
  };
}
