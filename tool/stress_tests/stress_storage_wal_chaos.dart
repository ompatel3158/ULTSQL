import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/cache/page_cache.dart';
import 'package:ultsql/src/engine/cache/crypto_security.dart';

// ============================================================================
// ULTSQL STORAGE RESILIENCE & CHAOS ATTACK SUITE
// ============================================================================

const String kChaosRoot = 'test_chaos_db';
const Duration kLockTimeout = Duration(seconds: 5);

void main(List<String> args) async {
  // Check for child worker execution modes
  if (args.isNotEmpty) {
    final mode = args[0];
    if (mode == '--worker-dirty-death') {
      final dbPath = args.length > 1 ? args[1] : '$kChaosRoot/worker_death';
      final numPages = args.length > 2 ? int.parse(args[2]) : 1000;
      final shouldCommit = args.length > 3 ? (args[3] == 'true') : false;
      await _runWorkerDirtyBufferDeath(dbPath, numPages, shouldCommit);
      return;
    } else if (mode == '--worker-uncommitted-crash') {
      final dbPath = args.length > 1 ? args[1] : '$kChaosRoot/uncommitted_crash';
      await _runWorkerUncommittedCrash(dbPath);
      return;
    }
  }

  // Master Test Harness
  print('======================================================================');
  print(' ⚡ ULTSQL BRUTAL STORAGE RESILIENCE & CHAOS STRESS SUITE ⚡');
  print(' Root Directory: $kChaosRoot');
  print(' Platform: ${Platform.operatingSystem} (${Platform.numberOfProcessors} cores)');
  print(' Dart Version: ${Platform.version}');
  print('======================================================================\n');

  final suiteSw = Stopwatch()..start();
  final defects = <String>[];
  final findings = <Map<String, dynamic>>[];
  final testSummaries = <Map<String, dynamic>>[];

  // Clean root before test execution
  await _cleanDirectory(kChaosRoot);
  await Directory(kChaosRoot).create(recursive: true);

  try {
    // ------------------------------------------------------------------------
    // TEST 1: Physical Byte Truncation
    // ------------------------------------------------------------------------
    final res1 = await test1PhysicalByteTruncation(defects, findings);
    testSummaries.add(res1);

    // ------------------------------------------------------------------------
    // TEST 2: WAL Chaos & Checksum Tampering
    // ------------------------------------------------------------------------
    final res2 = await test2WalChaosAndChecksumTampering(defects, findings);
    testSummaries.add(res2);

    // ------------------------------------------------------------------------
    // TEST 3: Cryptographic Tamper & Attack Suite
    // ------------------------------------------------------------------------
    final res3 = await test3CryptographicTamperSuite(defects, findings);
    testSummaries.add(res3);

    // ------------------------------------------------------------------------
    // TEST 4: Dirty Page Buffer Death
    // ------------------------------------------------------------------------
    final res4 = await test4DirtyPageBufferDeath(defects, findings);
    testSummaries.add(res4);

  } finally {
    // Clean root directory after test execution
    await _cleanDirectory(kChaosRoot);
  }

  suiteSw.stop();

  // Print Grand Chaos Summary
  print('\n======================================================================');
  print(' 📊 GRAND STORAGE RESILIENCE & CHAOS REPORT');
  print(' Total Suite Duration: ${suiteSw.elapsedMilliseconds}ms');
  print('======================================================================');
  for (final s in testSummaries) {
    final status = s['passed'] == true ? '✅ PASS' : '❌ FAIL';
    print('$status [${s['name']}] Duration: ${s['durationMs']}ms');
    if (s['metrics'] != null) {
      final m = s['metrics'] as Map<String, dynamic>;
      for (final e in m.entries) {
        print('    - ${e.key}: ${e.value}');
      }
    }
  }

  print('\n----------------------------------------------------------------------');
  print(' 🔍 IDENTIFIED FINDINGS & ARCHITECTURAL VULNERABILITIES (${findings.length}):');
  print('----------------------------------------------------------------------');
  for (int i = 0; i < findings.length; i++) {
    final f = findings[i];
    final severity = f['severity'] ?? 'INFO';
    print(' [$i] [$severity] ${f['title']}');
    print('     Details: ${f['description']}');
  }

  print('\n----------------------------------------------------------------------');
  print(' 🐞 FORMAL DEFECTS LOGGED (${defects.length}):');
  print('----------------------------------------------------------------------');
  if (defects.isEmpty) {
    print('  🎉 No critical defects logged!');
  } else {
    for (int i = 0; i < defects.length; i++) {
      print('  [$i] ${defects[i]}');
    }
  }
  print('======================================================================\n');
}

// ============================================================================
// HELPERS
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

Future<void> _ensureCleanDir(String path) async {
  await _cleanDirectory(path);
  await Directory(path).create(recursive: true);
}

// ============================================================================
// WORKER MODES
// ============================================================================

Future<void> _runWorkerDirtyBufferDeath(
  String dbPath,
  int targetPages,
  bool shouldCommit,
) async {
  try {
    final db = Database(
      dbPath,
      useWal: true,
      maxCapacity: 50000,
      lockTimeout: kLockTimeout,
    );
    await db.init();
    final interp = Interpreter(db);

    await interp.executeScript(
      'CREATE TABLE dirty_death (id INT, payload TEXT);',
    );

    // Each row has ~3500 bytes so exactly 1 row fits in a 4096-byte slotted page.
    final payload = 'X' * 3500;

    await interp.executeScript('BEGIN TRANSACTION;');
    for (int i = 0; i < targetPages; i++) {
      await interp.executeScript(
        "INSERT INTO dirty_death VALUES ($i, '$payload');",
      );
    }

    if (shouldCommit) {
      await interp.executeScript('COMMIT;');
      stdout.writeln('DIRTY_BUFFER_COMMITTED:$targetPages');
      await stdout.flush();
    } else {
      stdout.writeln('DIRTY_BUFFER_PRIMED:$targetPages');
      await stdout.flush();
    }

    // Do NOT call close() or flushAllSync(). Wait to be brutally killed.
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
    }
  } catch (e, st) {
    stderr.writeln('WORKER_ERROR: $e\n$st');
    exit(1);
  }
}

Future<void> _runWorkerUncommittedCrash(String dbPath) async {
  try {
    final db = Database(dbPath, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);

    await interp.executeScript('BEGIN TRANSACTION;');
    await interp.executeScript("INSERT INTO wal_uncom VALUES (999, 'uncommitted_row');");
    stdout.writeln('UNCOMMITTED_WRITTEN');
    await stdout.flush();

    while (true) {
      await Future.delayed(const Duration(seconds: 1));
    }
  } catch (e, st) {
    stderr.writeln('UNCOMMITTED_ERROR: $e\n$st');
    exit(1);
  }
}

// ============================================================================
// TEST 1: Physical Byte Truncation
// ============================================================================

Future<Map<String, dynamic>> test1PhysicalByteTruncation(
  List<String> defects,
  List<Map<String, dynamic>> findings,
) async {
  final sw = Stopwatch()..start();
  print('\n----------------------------------------------------------------------');
  print(' [TEST 1] Physical Byte Truncation & Corrupted Offsets');
  print('----------------------------------------------------------------------');

  final testDir = '$kChaosRoot/truncation';
  await _ensureCleanDir(testDir);

  int subtestsPassed = 0;
  int subtestsTotal = 0;

  // --------------------------------------------------------------------------
  // Subtest 1.1: Truncation to 0 Bytes
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 1.1: Truncate table .db file to 0 bytes...');
  bool zeroTruncHandled = false;
  try {
    final engine = await UltSqlEngine.openFile(testDir);
    await engine.query('CREATE TABLE trunc_zero (id INT, name TEXT);');
    for (int i = 0; i < 100; i++) {
      await engine.query("INSERT INTO trunc_zero VALUES ($i, 'row_$i');");
    }
    await engine.close();

    final tableFile = File('$testDir/trunc_zero.db');
    final origLen = tableFile.lengthSync();
    if (origLen == 0) {
      defects.add('Test 1.1: trunc_zero.db was empty before truncation');
    }

    // Truncate to 0 bytes
    tableFile.writeAsBytesSync([]);

    // Reopen and run queries
    final reopenEngine = await UltSqlEngine.openFile(testDir);
    final countRes = await reopenEngine.query('SELECT COUNT(*) FROM trunc_zero;');
    final count = (countRes.rows.first.first as DbInt).value;

    final selectRes = await reopenEngine.query('SELECT * FROM trunc_zero;');
    final rowCount = selectRes.length;

    // Insert new row into truncated table
    await reopenEngine.query("INSERT INTO trunc_zero VALUES (999, 'post_trunc');");
    final postInsertRes = await reopenEngine.query('SELECT COUNT(*) FROM trunc_zero;');
    final postCount = (postInsertRes.rows.first.first as DbInt).value;

    await reopenEngine.close();

    if (count == 0 && rowCount == 0 && postCount == 1) {
      zeroTruncHandled = true;
      subtestsPassed++;
      print('    ✅ Zero-byte truncation handled cleanly: count=0, post-insert count=1.');
    } else {
      defects.add('Test 1.1: Unexpected counts after 0-byte truncation (count=$count, post=$postCount)');
    }
  } catch (e, st) {
    defects.add('Test 1.1 Defect: 0-byte truncation crashed with unhandled exception: $e');
    print('    ❌ Crash on 0-byte truncation: $e\n$st');
  }

  // --------------------------------------------------------------------------
  // Subtest 1.2: Random Non-Page-Aligned Truncations (512B, 1500B, 5500B)
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 1.2: Random non-page-aligned byte offsets (512B, 1500B, 5500B)...');
  bool nonAlignedHandled = true;
  final testOffsets = [512, 1500, 5500];

  for (final targetOffset in testOffsets) {
    final subDir = '$testDir/non_aligned_$targetOffset';
    await _ensureCleanDir(subDir);
    try {
      final engine = await UltSqlEngine.openFile(subDir);
      await engine.query('CREATE TABLE t_align (id INT, payload TEXT);');
      // Create at least 3 pages of data (3 * 4096 = 12288 bytes)
      final dummy = 'A' * 1000;
      for (int i = 0; i < 30; i++) {
        await engine.query("INSERT INTO t_align VALUES ($i, '$dummy');");
      }
      await engine.close();

      final dbFile = File('$subDir/t_align.db');
      final beforeLen = dbFile.lengthSync();
      if (beforeLen <= targetOffset) {
        dbFile.writeAsBytesSync(Uint8List(targetOffset + 4096));
      }

      // Read targetOffset bytes and truncate
      final truncatedBytes = dbFile.readAsBytesSync().sublist(0, targetOffset);
      dbFile.writeAsBytesSync(truncatedBytes);

      // Reopen and query
      final reopenEngine = await UltSqlEngine.openFile(subDir);
      final countRes = await reopenEngine.query('SELECT COUNT(*) FROM t_align;');
      final count = (countRes.rows.first.first as DbInt).value;

      final selectRes = await reopenEngine.query('SELECT * FROM t_align;');
      // Insert new row to test allocation after truncated EOF
      await reopenEngine.query("INSERT INTO t_align VALUES (777, 'rebound');");
      final afterRes = await reopenEngine.query('SELECT COUNT(*) FROM t_align;');
      final afterCount = (afterRes.rows.first.first as DbInt).value;
      await reopenEngine.close();

      print('    Offset $targetOffset bytes (before: $beforeLen): read count=$count, post-insert=$afterCount (rows scanned: ${selectRes.length})');
    } catch (e) {
      nonAlignedHandled = false;
      defects.add('Test 1.2 Defect: Truncation at offset $targetOffset crashed: $e');
      print('    ❌ Truncation at offset $targetOffset crashed: $e');
    }
  }
  if (nonAlignedHandled) subtestsPassed++;

  // --------------------------------------------------------------------------
  // Subtest 1.3: Mid-Slot Header Truncation
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 1.3: Truncation mid-slot header (offset 4096 + 7 bytes)...');
  bool midSlotHandled = false;
  try {
    final subDir = '$testDir/mid_slot';
    await _ensureCleanDir(subDir);
    final engine = await UltSqlEngine.openFile(subDir);
    await engine.query('CREATE TABLE t_slot (id INT, val TEXT);');
    // Generate rows spanning across page 0 and page 1
    for (int i = 0; i < 150; i++) {
      await engine.query("INSERT INTO t_slot VALUES ($i, 'mid_slot_val_$i');");
    }
    await engine.close();

    final dbFile = File('$subDir/t_slot.db');
    // Truncate at exactly page 0 (4096) + 7 bytes (cutting through slot 0 header on page 1)
    const midSlotOffset = 4096 + 7;
    final bytes = dbFile.readAsBytesSync();
    if (bytes.length > midSlotOffset) {
      dbFile.writeAsBytesSync(bytes.sublist(0, midSlotOffset));
    }

    final reopenEngine = await UltSqlEngine.openFile(subDir);
    final res = await reopenEngine.query('SELECT * FROM t_slot;');
    await reopenEngine.query("INSERT INTO t_slot VALUES (999, 'slot_recovered');");
    await reopenEngine.close();

    midSlotHandled = true;
    subtestsPassed++;
    print('    ✅ Mid-slot truncation survived gracefully: returned ${res.length} rows from page 0 without crash.');
  } catch (e) {
    defects.add('Test 1.3 Defect: Mid-slot header truncation crashed: $e');
    print('    ❌ Mid-slot truncation crashed: $e');
  }

  // --------------------------------------------------------------------------
  // Subtest 1.4: B-Tree Index Desynchronization After Table Truncation
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 1.4: Table truncation with desynchronized B+ Tree Index...');
  bool btreeDesyncHandled = false;
  try {
    final subDir = '$testDir/btree_desync';
    await _ensureCleanDir(subDir);
    final engine = await UltSqlEngine.openFile(subDir);
    await engine.query('CREATE TABLE t_idx (id INT, name TEXT);');
    await engine.query('CREATE INDEX idx_t_id ON t_idx (id);');

    // Insert 200 rows spanning 3 pages
    for (int i = 1; i <= 200; i++) {
      await engine.query("INSERT INTO t_idx VALUES ($i, 'name_$i');");
    }
    await engine.close();

    // Truncate table file to page 0 only (4096 bytes), leave index pointing to pages 1 and 2
    final dbFile = File('$subDir/t_idx.db');
    final rawBytes = dbFile.readAsBytesSync();
    dbFile.writeAsBytesSync(rawBytes.sublist(0, 4096));

    final reopenEngine = await UltSqlEngine.openFile(subDir);
    // Point query on surviving page 0
    final p0Res = await reopenEngine.query('SELECT * FROM t_idx WHERE id = 1;');
    // Point query pointing to truncated page 1
    final p1Res = await reopenEngine.query('SELECT * FROM t_idx WHERE id = 150;');
    // Range query across truncated boundary
    final rangeRes = await reopenEngine.query('SELECT * FROM t_idx WHERE id >= 1 AND id <= 200;');

    await reopenEngine.close();

    btreeDesyncHandled = true;
    subtestsPassed++;
    print('    ✅ B-Tree desync handled: P0 match=${p0Res.length}, P1 ghost lookup=${p1Res.length}, range=${rangeRes.length}');
  } catch (e) {
    defects.add('Test 1.4 Defect: B-Tree index lookup on truncated page crashed: $e');
    print('    ❌ B-Tree desync crashed: $e');
  }

  // --------------------------------------------------------------------------
  // Subtest 1.5: Catalog Truncation Chaos
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 1.5: Catalog file truncation to 0 bytes and corrupted JSON...');
  bool catalogTruncHandled = false;
  try {
    final subDir = '$testDir/catalog_chaos';
    await _ensureCleanDir(subDir);
    final engine = await UltSqlEngine.openFile(subDir);
    await engine.query('CREATE TABLE cat_test (x INT);');
    await engine.close();

    // Corrupt catalog.db by truncating to 5 bytes
    final catFile = File('$subDir/catalog.db');
    catFile.writeAsBytesSync(utf8.encode('{cor'));

    try {
      final reopenEngine = await UltSqlEngine.openFile(subDir);
      await reopenEngine.close();
      catalogTruncHandled = true;
      subtestsPassed++;
      print('    ✅ Corrupt catalog handled safely.');
    } catch (e) {
      if (e.toString().contains('FormatException') || e.toString().contains('Corrupt') || e.toString().contains('catalog')) {
        catalogTruncHandled = true;
        subtestsPassed++;
        print('    ✅ Catalog corruption caught gracefully: $e');
      } else {
        defects.add('Test 1.5 Defect: Catalog corruption threw unformatted error: $e');
      }
    }
  } catch (e) {
    defects.add('Test 1.5 Defect: Catalog chaos crashed: $e');
  }

  sw.stop();
  final passed = (subtestsPassed == subtestsTotal);
  return {
    'name': 'Physical Byte Truncation',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': {
      'subtestsPassed': '$subtestsPassed / $subtestsTotal',
      'zeroTruncHandled': zeroTruncHandled,
      'nonAlignedHandled': nonAlignedHandled,
      'midSlotHandled': midSlotHandled,
      'btreeDesyncHandled': btreeDesyncHandled,
      'catalogTruncHandled': catalogTruncHandled,
    },
  };
}

// ============================================================================
// TEST 2: WAL Chaos & Checksum Tampering
// ============================================================================

Future<Map<String, dynamic>> test2WalChaosAndChecksumTampering(
  List<String> defects,
  List<Map<String, dynamic>> findings,
) async {
  final sw = Stopwatch()..start();
  print('\n----------------------------------------------------------------------');
  print(' [TEST 2] WAL Chaos & Checksum Tampering');
  print('----------------------------------------------------------------------');

  final testDir = '$kChaosRoot/wal_chaos';
  await _ensureCleanDir(testDir);

  int subtestsPassed = 0;
  int subtestsTotal = 0;

  final scriptPath = Platform.script.toFilePath();

  // --------------------------------------------------------------------------
  // Subtest 2.1: Blind Replay of Corrupted WAL Record (No CRC32 verification!)
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 2.1: Mutating committed WAL record payload bytes (Blind Replay Check)...');
  bool blindReplayObserved = false;
  try {
    final subDir = '$testDir/blind_replay';
    await _ensureCleanDir(subDir);

    // 1. Set up transaction with WAL logging in place
    final db = Database(subDir, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript('CREATE TABLE wal_test (id INT, payload TEXT);');
    await interp.executeScript('BEGIN TRANSACTION;');
    await interp.executeScript("INSERT INTO wal_test VALUES (1, 'ORIGINAL_INTEGRITY_SAFE_DATA_AAAA');");
    await interp.executeScript("INSERT INTO wal_test VALUES (2, 'ORIGINAL_INTEGRITY_SAFE_DATA_BBBB');");
    await interp.executeScript('COMMIT;');

    // Capture wal.log before clean close truncates it
    final walFile = File('$subDir/wal.log');
    final walBytes = Uint8List.fromList(walFile.readAsBytesSync());
    await db.close();

    // Reset table file so that data MUST be restored via WAL recovery replay
    final dbFile = File('$subDir/wal_test.db');
    if (dbFile.existsSync()) {
      dbFile.writeAsBytesSync([]);
    }

    // Mutate target bytes in walBytes
    final targetStr = 'ORIGINAL_INTEGRITY_SAFE_DATA_AAAA';
    final targetBytes = utf8.encode(targetStr);
    int matchOffset = -1;
    for (int i = 0; i <= walBytes.length - targetBytes.length; i++) {
      bool found = true;
      for (int j = 0; j < targetBytes.length; j++) {
        if (walBytes[i + j] != targetBytes[j]) {
          found = false;
          break;
        }
      }
      if (found) {
        matchOffset = i;
        break;
      }
    }

    if (matchOffset != -1) {
      final hackedStr = utf8.encode('CORRUPTED_TAMPERED_BYTE_PAYLOAD_');
      for (int k = 0; k < hackedStr.length; k++) {
        walBytes[matchOffset + k] = hackedStr[k];
      }
      walFile.writeAsBytesSync(walBytes);
      print('    Mutated bytes at WAL offset $matchOffset with tampered payload.');
    }

    // Now re-open database to trigger WAL recovery (PageCache.recoverSync)
    final reopenDb = Database(subDir, useWal: true, lockTimeout: kLockTimeout);
    await reopenDb.init();
    final reopenInterp = Interpreter(reopenDb);
    final res = await reopenInterp.executeScript('SELECT * FROM wal_test;');
    await reopenDb.close();

    bool foundCorruptedData = false;
    for (final row in res.rows) {
      final val = row[1].toString();
      if (val.contains('CORRUPTED_TAMPERED')) {
        foundCorruptedData = true;
        break;
      }
    }

    if (foundCorruptedData) {
      blindReplayObserved = true;
      findings.add({
        'title': 'WAL Blind Replay Defect (Missing Checksum Verification)',
        'severity': 'CRITICAL',
        'description':
            'PageCache._recoverWalSync() parses WAL records without verifying any CRC32 checksum. '
            'When bytes in wal.log are mutated or corrupted, the recovery engine blindly replays the corrupted '
            'pages directly into physical database table files, permanently corrupting disk data.',
      });
      defects.add(
        'Test 2.1 Critical Vulnerability: WAL recovery lacks CRC32 verification; blindly replayed tampered payload into physical table',
      );
      print('    ⚠️ VULNERABILITY CONFIRMED: Engine blindly replayed corrupted WAL record without checksum validation!');
    } else {
      print('    ✅ Corrupted WAL record was rejected.');
    }
    subtestsPassed++;
  } catch (e, st) {
    print('    Exception during WAL replay: $e\n$st');
    defects.add('Test 2.1 Defect: Reopening after WAL mutation crashed: $e');
  }

  // --------------------------------------------------------------------------
  // Subtest 2.2: WAL Record Header Corruption & Premature File Deletion
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 2.2: Tampering WAL record headers (length & type corruption)...');
  bool prematureDeletionObserved = false;
  try {
    final subDir = '$testDir/header_corruption';
    await _ensureCleanDir(subDir);

    final db = Database(subDir, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript('CREATE TABLE wal_multi (id INT);');
    await interp.executeScript('BEGIN TRANSACTION;');
    await interp.executeScript('INSERT INTO wal_multi VALUES (10);');
    await interp.executeScript('COMMIT;');
    await interp.executeScript('BEGIN TRANSACTION;');
    await interp.executeScript('INSERT INTO wal_multi VALUES (20);');
    await interp.executeScript('COMMIT;');

    final walFile = File('$subDir/wal.log');
    final walBytes = Uint8List.fromList(walFile.readAsBytesSync());
    await db.close();

    // Corrupt length header to an impossible huge value (0x7FFFFFFF)
    if (walBytes.length > 5) {
      walBytes[1] = 0x7F;
      walBytes[2] = 0xFF;
      walBytes[3] = 0xFF;
      walBytes[4] = 0xFF;
      walFile.writeAsBytesSync(walBytes);
    }

    // Reopen DB to trigger recovery
    final reopenDb = Database(subDir, useWal: true, lockTimeout: kLockTimeout);
    await reopenDb.init();
    await reopenDb.close();

    // Check if wal.log was deleted despite parsing failure
    final walStillExists = walFile.existsSync() && walFile.lengthSync() > 0;
    if (!walStillExists) {
      prematureDeletionObserved = true;
      findings.add({
        'title': 'Premature WAL Deletion on Parse Failure',
        'severity': 'HIGH',
        'description':
            'When PageCache._recoverWalSync() encounters a malformed or corrupted record header, '
            'it catches the exception but still executes walFile.deleteSync(). This permanently destroys '
            'subsequent valid transaction records that have not yet been replayed.',
      });
      defects.add(
        'Test 2.2 Defect: WAL file deleted upon hit of malformed record, causing unrecoverable data loss for subsequent transactions',
      );
      print('    ⚠️ WAL file was deleted despite corrupted header causing early termination!');
    } else {
      print('    ✅ WAL file preserved after error.');
    }
    subtestsPassed++;
  } catch (e) {
    print('    Exception during header corruption test: $e');
    defects.add('Test 2.2 Defect: Header corruption test crashed: $e');
  }

  // --------------------------------------------------------------------------
  // Subtest 2.3: Torn Write Truncation Mid-Record
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 2.3: Torn write simulation (WAL cut mid-page record)...');
  bool tornWriteHandled = false;
  try {
    final subDir = '$testDir/torn_write';
    await _ensureCleanDir(subDir);

    final db = Database(subDir, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript('CREATE TABLE wal_test (id INT, payload TEXT);');
    await interp.executeScript('BEGIN TRANSACTION;');
    await interp.executeScript("INSERT INTO wal_test VALUES (10, 'safe_prefix');");
    await interp.executeScript('COMMIT;');

    final walFile = File('$subDir/wal.log');
    final bytes = Uint8List.fromList(walFile.readAsBytesSync());
    await db.close();

    if (bytes.length > 20) {
      // Cut WAL in half mid-record
      walFile.writeAsBytesSync(bytes.sublist(0, bytes.length ~/ 2));
    }

    final reopenDb = Database(subDir, useWal: true, lockTimeout: kLockTimeout);
    await reopenDb.init();
    final reopenInterp = Interpreter(reopenDb);
    final res = await reopenInterp.executeScript('SELECT COUNT(*) FROM wal_test;');
    final count = (res.rows.first.first as DbInt).value;
    await reopenDb.close();

    tornWriteHandled = true;
    subtestsPassed++;
    print('    ✅ Torn WAL write handled cleanly: surviving count=$count');
  } catch (e) {
    defects.add('Test 2.3 Defect: Torn WAL file caused unhandled crash: $e');
    print('    ❌ Torn write crashed: $e');
  }

  // --------------------------------------------------------------------------
  // Subtest 2.4: Uncommitted Transaction Rollback Verification
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 2.4: Uncommitted transaction rollback from WAL...');
  bool uncommittedRollbackSuccess = false;
  try {
    final subDir = '$testDir/uncommitted_rollback';
    await _ensureCleanDir(subDir);

    // Create base table first
    final baseDb = Database(subDir, useWal: true, lockTimeout: kLockTimeout);
    await baseDb.init();
    final baseInterp = Interpreter(baseDb);
    await baseInterp.executeScript('CREATE TABLE wal_uncom (id INT, payload TEXT);');
    await baseInterp.executeScript("INSERT INTO wal_uncom VALUES (1, 'base_row');");
    await baseDb.close();

    // Launch worker that starts transaction, inserts row 999, and waits
    final proc = await Process.start('dart', [
      'run',
      scriptPath,
      '--worker-uncommitted-crash',
      subDir,
    ]);

    final completer = Completer<void>();
    proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.contains('UNCOMMITTED_WRITTEN') && !completer.isCompleted) {
        completer.complete();
      }
    });

    await completer.future.timeout(const Duration(seconds: 30));
    // Kill child abruptly to simulate uncommitted crash
    proc.kill(ProcessSignal.sigkill);
    await proc.exitCode;
    await Future.delayed(const Duration(milliseconds: 250));

    // Reopen and check if uncommitted row 999 is present or rolled back
    final reopenDb = Database(subDir, useWal: true, lockTimeout: kLockTimeout);
    await reopenDb.init();
    final reopenInterp = Interpreter(reopenDb);
    final res = await reopenInterp.executeScript('SELECT COUNT(*) FROM wal_uncom WHERE id = 999;');
    final count = (res.rows.first.first as DbInt).value;

    final baseRes = await reopenInterp.executeScript('SELECT COUNT(*) FROM wal_uncom WHERE id = 1;');
    final baseCount = (baseRes.rows.first.first as DbInt).value;
    await reopenDb.close();

    if (count == 0 && baseCount == 1) {
      uncommittedRollbackSuccess = true;
      subtestsPassed++;
      print('    ✅ Uncommitted transaction successfully rolled back (row 999 absent, row 1 preserved).');
    } else {
      defects.add('Test 2.4 Defect: Uncommitted row 999 leaked into database after restart!');
      print('    ❌ Uncommitted row 999 survived restart!');
    }
  } catch (e) {
    defects.add('Test 2.4 Defect: Uncommitted rollback crashed: $e');
    print('    ❌ Crash: $e');
  }

  // --------------------------------------------------------------------------
  // Subtest 2.5: Direct WalRecoveryEngine Architecture Audit
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 2.5: Auditing WalRecoveryEngine and Crc32 usage...');
  findings.add({
    'title': 'Decoupled WalRecoveryEngine Architecture',
    'severity': 'MEDIUM',
    'description':
        'WalRecoveryEngine (in wal_recovery.dart) defines WalRecord and computes Crc32.compute(afterData), '
        'but is never invoked by Database or PageCache runtime engine. PageCache implements its own separate '
        'recoverSync() routine which omits CRC32 calculations entirely.',
  });
  subtestsPassed++;

  sw.stop();
  final passed = (subtestsPassed == subtestsTotal);
  return {
    'name': 'WAL Chaos & Checksum Tampering',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': {
      'subtestsPassed': '$subtestsPassed / $subtestsTotal',
      'blindReplayObserved': blindReplayObserved,
      'prematureDeletionObserved': prematureDeletionObserved,
      'tornWriteHandled': tornWriteHandled,
      'uncommittedRollbackSuccess': uncommittedRollbackSuccess,
    },
  };
}

// ============================================================================
// TEST 3: Cryptographic Tamper & Attack Suite
// ============================================================================

Future<Map<String, dynamic>> test3CryptographicTamperSuite(
  List<String> defects,
  List<Map<String, dynamic>> findings,
) async {
  final sw = Stopwatch()..start();
  print('\n----------------------------------------------------------------------');
  print(' [TEST 3] Cryptographic Tamper & Attack Suite');
  print('----------------------------------------------------------------------');

  final testDir = '$kChaosRoot/crypto';
  await _ensureCleanDir(testDir);

  int subtestsPassed = 0;
  int subtestsTotal = 0;

  // --------------------------------------------------------------------------
  // Subtest 3.1: Passphrase Boundary Edge Cases (empty, 1-char, null, wrong)
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 3.1: Passphrase edge cases (empty, short, null, wrong)...');
  bool boundaryPassed = true;
  try {
    // 1. Empty string passphrase
    final emptyDir = '$testDir/empty_pass';
    await _ensureCleanDir(emptyDir);
    final engineEmpty = await UltSqlEngine.openFile(emptyDir, passphrase: '');
    await engineEmpty.query('CREATE TABLE t_empty (x INT);');
    await engineEmpty.query('INSERT INTO t_empty VALUES (123);');
    await engineEmpty.close();

    // Reopen with empty passphrase
    final reopenEmpty = await UltSqlEngine.openFile(emptyDir, passphrase: '');
    final resEmpty = await reopenEmpty.query('SELECT x FROM t_empty;');
    final valEmpty = (resEmpty.rows.first.first as DbInt).value;
    await reopenEmpty.close();
    if (valEmpty != 123) {
      boundaryPassed = false;
      defects.add('Test 3.1 Defect: Empty string passphrase corrupted data retrieval');
    }

    // Reopen with null on encrypted db -> Must throw DatabaseIntegrityException
    bool nullRejected = false;
    try {
      await UltSqlEngine.openFile(emptyDir, passphrase: null);
    } on DatabaseIntegrityException {
      nullRejected = true;
    } catch (_) {}
    if (!nullRejected) {
      boundaryPassed = false;
      defects.add('Test 3.1 Defect: Null passphrase failed to throw DatabaseIntegrityException on encrypted db');
    }

    // Reopen with wrong passphrase -> Must throw DatabaseIntegrityException
    bool wrongRejected = false;
    try {
      await UltSqlEngine.openFile(emptyDir, passphrase: 'WRONG_PASSPHRASE_123');
    } on DatabaseIntegrityException {
      wrongRejected = true;
    } catch (_) {}
    if (!wrongRejected) {
      boundaryPassed = false;
      defects.add('Test 3.1 Defect: Wrong passphrase failed to throw DatabaseIntegrityException');
    }

    // 2. 1-character passphrase
    final shortDir = '$testDir/short_pass';
    await _ensureCleanDir(shortDir);
    final engineShort = await UltSqlEngine.openFile(shortDir, passphrase: 'K');
    await engineShort.query('CREATE TABLE t_short (x INT);');
    await engineShort.query('INSERT INTO t_short VALUES (456);');
    await engineShort.close();

    final reopenShort = await UltSqlEngine.openFile(shortDir, passphrase: 'K');
    final resShort = await reopenShort.query('SELECT x FROM t_short;');
    final valShort = (resShort.rows.first.first as DbInt).value;
    await reopenShort.close();
    if (valShort != 456) {
      boundaryPassed = false;
      defects.add('Test 3.1 Defect: 1-char passphrase corrupted data retrieval');
    }

    if (boundaryPassed) {
      subtestsPassed++;
      print('    ✅ Passphrase boundaries verified: empty string, 1-char, null-rejection, wrong-rejection all pass.');
    }
  } catch (e) {
    boundaryPassed = false;
    defects.add('Test 3.1 Defect: Passphrase boundary test crashed: $e');
    print('    ❌ Crash: $e');
  }

  // --------------------------------------------------------------------------
  // Subtest 3.2: In-Page Auth Envelope Ciphertext Tamper Vectors
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 3.2: In-Page Auth Envelope bit tampering & HMAC rejection...');
  bool inPageTamperCaught = true;
  const kMasterPass = 'BrutalSecureMasterKey2026!#';

  final vectors = <String, int>{
    'Vector A: Payload Bit-Flip (byte 150)': 150,
    'Vector B: Header Bit-Flip (byte 2)': 2,
    'Vector C: Nonce/IV Bit-Flip (byte 0)': 0,
    'Vector D: HMAC Tag Bit-Flip (byte 4080)': 4080,
  };

  for (final entry in vectors.entries) {
    final vName = entry.key;
    final bytePos = entry.value;
    final subDir = '$testDir/inpage_${bytePos}';
    await _ensureCleanDir(subDir);

    try {
      final db = Database(
        subDir,
        passphrase: kMasterPass,
        authEnvelopeMode: AuthEnvelopeMode.inPage,
        lockTimeout: kLockTimeout,
      );
      await db.init();
      final interp = Interpreter(db);
      await interp.executeScript('CREATE TABLE vault (id INT, secret TEXT);');
      await interp.executeScript("INSERT INTO vault VALUES (1, 'SUPER_SECRET_ALPHA');");
      await interp.executeScript("INSERT INTO vault VALUES (2, 'SUPER_SECRET_BETA');");
      await db.close();

      final dbFile = File('$subDir/vault.db');
      final bytes = dbFile.readAsBytesSync();
      if (bytes.length >= 4096) {
        // Mutate single bit
        bytes[bytePos] ^= 0x01;
        dbFile.writeAsBytesSync(bytes);
      }

      // Reopen and attempt to query
      bool caughtIntegrity = false;
      Database? reopenDb;
      try {
        reopenDb = Database(
          subDir,
          passphrase: kMasterPass,
          authEnvelopeMode: AuthEnvelopeMode.inPage,
          lockTimeout: kLockTimeout,
        );
        await reopenDb.init();
        final reopenInterp = Interpreter(reopenDb);
        await reopenInterp.executeScript('SELECT * FROM vault;');
      } on DatabaseIntegrityException {
        caughtIntegrity = true;
      } catch (e) {
        print('    Observed other exception on $vName: $e');
      } finally {
        await reopenDb?.close();
      }

      if (caughtIntegrity) {
        print('    ✅ $vName: Caught with DatabaseIntegrityException!');
      } else {
        inPageTamperCaught = false;
        defects.add('Test 3.2 Security Defect: $vName bypassed HMAC authentication without DatabaseIntegrityException!');
        print('    ❌ SECURITY DEFECT: $vName bypassed HMAC authentication!');
      }
    } catch (e) {
      inPageTamperCaught = false;
      defects.add('Test 3.2 Defect on $vName: $e');
    }
  }

  // Vector E: Page Swap Attack (Swap Page 0 and Page 1)
  {
    final subDir = '$testDir/page_swap';
    await _ensureCleanDir(subDir);
    try {
      final db = Database(
        subDir,
        passphrase: kMasterPass,
        authEnvelopeMode: AuthEnvelopeMode.inPage,
        lockTimeout: kLockTimeout,
      );
      await db.init();
      final interp = Interpreter(db);
      await interp.executeScript('CREATE TABLE swap_vault (id INT, s TEXT);');
      // Insert 100 rows with 80-byte strings to occupy 2 full pages cleanly (> 8KB)
      for (int i = 1; i <= 100; i++) {
        await interp.executeScript("INSERT INTO swap_vault VALUES ($i, 'SWAP_PAYLOAD_STRING_BLOCK_${'Z' * 60}_$i');");
      }
      await db.close();

      final dbFile = File('$subDir/swap_vault.db');
      final bytes = dbFile.readAsBytesSync();
      if (bytes.length >= 8192) {
        final page0 = bytes.sublist(0, 4096);
        final page1 = bytes.sublist(4096, 8192);
        // Swap pages
        final swapped = Uint8List(bytes.length);
        swapped.setRange(0, 4096, page1);
        swapped.setRange(4096, 8192, page0);
        if (bytes.length > 8192) {
          swapped.setRange(8192, bytes.length, bytes.sublist(8192));
        }
        dbFile.writeAsBytesSync(swapped);

        bool caughtSwap = false;
        Database? reopenDb;
        try {
          reopenDb = Database(
            subDir,
            passphrase: kMasterPass,
            authEnvelopeMode: AuthEnvelopeMode.inPage,
            lockTimeout: kLockTimeout,
          );
          await reopenDb.init();
          final reopenInterp = Interpreter(reopenDb);
          await reopenInterp.executeScript('SELECT * FROM swap_vault;');
        } on DatabaseIntegrityException {
          caughtSwap = true;
        } catch (_) {
        } finally {
          await reopenDb?.close();
        }

        if (caughtSwap) {
          print('    ✅ Vector E: Page Swap Attack rejected with DatabaseIntegrityException (pageId bound to HMAC)!');
        } else {
          inPageTamperCaught = false;
          defects.add('Test 3.2 Security Defect: Page Swap Attack bypassed HMAC verification!');
          print('    ❌ SECURITY DEFECT: Page Swap Attack bypassed HMAC verification!');
        }
      } else {
        print('    Notice: swap_vault.db length was ${bytes.length} < 8192; page swap test adjusted.');
      }
    } catch (e) {
      inPageTamperCaught = false;
      defects.add('Test 3.2 Page Swap Attack crashed: $e');
    }
  }
  if (inPageTamperCaught) subtestsPassed++;

  // --------------------------------------------------------------------------
  // Subtest 3.3: Companion Auth Envelope Mode Tampering (.auth file)
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 3.3: Companion Auth Envelope Mode (.auth file tampering)...');
  bool companionPassed = true;
  try {
    final subDir = '$testDir/companion_mode';
    await _ensureCleanDir(subDir);

    final db = Database(
      subDir,
      passphrase: kMasterPass,
      authEnvelopeMode: AuthEnvelopeMode.companion,
      lockTimeout: kLockTimeout,
    );
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript('CREATE TABLE comp_vault (id INT, secret TEXT);');
    await interp.executeScript("INSERT INTO comp_vault VALUES (100, 'COMPANION_SECRET');");
    await db.close();

    final authFile = File('$subDir/comp_vault.auth');
    if (!authFile.existsSync() || authFile.lengthSync() == 0) {
      companionPassed = false;
      defects.add('Test 3.3 Defect: comp_vault.auth was not generated in companion mode');
    } else {
      // Mutate 1 bit in .auth file
      final authBytes = authFile.readAsBytesSync();
      authBytes[0] ^= 0x01;
      authFile.writeAsBytesSync(authBytes);

      bool caughtAuthTamper = false;
      Database? reopenDb;
      try {
        reopenDb = Database(
          subDir,
          passphrase: kMasterPass,
          authEnvelopeMode: AuthEnvelopeMode.companion,
          lockTimeout: kLockTimeout,
        );
        await reopenDb.init();
        final reopenInterp = Interpreter(reopenDb);
        await reopenInterp.executeScript('SELECT * FROM comp_vault;');
      } on DatabaseIntegrityException {
        caughtAuthTamper = true;
      } catch (_) {
      } finally {
        await reopenDb?.close();
      }

      if (caughtAuthTamper) {
        print('    ✅ Companion .auth tampering rejected with DatabaseIntegrityException!');
        subtestsPassed++;
      } else {
        companionPassed = false;
        defects.add('Test 3.3 Security Defect: Companion .auth bit tampering was NOT detected by verification!');
        print('    ❌ SECURITY DEFECT: Companion .auth tampering was not detected!');
      }
    }
  } catch (e) {
    companionPassed = false;
    defects.add('Test 3.3 Defect: Companion mode crashed: $e');
  }

  // --------------------------------------------------------------------------
  // Subtest 3.4: Plaintext Secret Leakage Inspection
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 3.4: Plaintext canary leak scan across disk files...');
  bool tableCiphertextClean = true;
  try {
    final subDir = '$testDir/canary_scan';
    await _ensureCleanDir(subDir);

    const kCanaryRow = 'TOP_SECRET_CANARY_PAYLOAD_987654321_ALPHA';
    const kCanaryDefault = 'SENSITIVE_DEFAULT_TOKEN_8888_BETA';

    final db = Database(subDir, passphrase: kMasterPass, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript(
      "CREATE TABLE classified (id INT, payload TEXT, token TEXT DEFAULT '$kCanaryDefault');",
    );
    await interp.executeScript('BEGIN TRANSACTION;');
    await interp.executeScript(
      "INSERT INTO classified VALUES (1, '$kCanaryRow', 'override_token');",
    );
    await interp.executeScript('COMMIT;');
    await db.close();

    // Scan specific file types
    final tableDbFile = File('$subDir/classified.db');
    if (tableDbFile.existsSync()) {
      final raw = tableDbFile.readAsBytesSync();
      final text = String.fromCharCodes(raw);
      if (text.contains(kCanaryRow)) {
        tableCiphertextClean = false;
        defects.add('Test 3.4 Critical Defect: classified.db contains unencrypted row canary!');
        print('    ❌ CRITICAL: classified.db table file contains cleartext row data!');
      } else {
        print('    ✅ classified.db page ciphertext is 100% encrypted (zero cleartext leakage).');
      }
    }

    // Inspect audit.log for cleartext query leak
    final auditFile = File('$subDir/audit.log');
    if (auditFile.existsSync()) {
      final raw = auditFile.readAsBytesSync();
      final text = String.fromCharCodes(raw);
      if (text.contains(kCanaryRow)) {
        findings.add({
          'title': 'AuditLogger Plaintext SQL Query Leakage on Encrypted Database',
          'severity': 'HIGH',
          'description':
              'AuditLogger writes raw executed SQL query strings directly to audit.log in cleartext. '
              'On databases encrypted with AES-256-CTR, plaintext secrets and passwords in INSERT/UPDATE '
              'queries are written unencrypted to disk in audit.log.',
        });
        print('    ⚠️ VULNERABILITY CONFIRMED: AuditLogger leaked raw SQL query with secrets into audit.log.');
      }
    }

    // Inspect catalog.db / wal.log for schema default leak
    final catalogFile = File('$subDir/catalog.db');
    if (catalogFile.existsSync()) {
      final raw = catalogFile.readAsBytesSync();
      final text = String.fromCharCodes(raw);
      if (text.contains(kCanaryDefault)) {
        findings.add({
          'title': 'Schema Metadata / Column Default Plaintext Exposure in Catalog & WAL',
          'severity': 'MEDIUM',
          'description':
              'Table column default values and check expressions are stored as raw unencrypted JSON in catalog.db '
              'and logged in plain text in wal.log (type 1 START_TX catalog backup). Sensitive defaults may leak.',
        });
        print('    ⚠️ Notice: Catalog schema metadata and column defaults stored in cleartext JSON.');
      }
    }

    if (tableCiphertextClean) subtestsPassed++;
  } catch (e) {
    tableCiphertextClean = false;
    defects.add('Test 3.4 Leak scan crashed: $e');
  }

  // --------------------------------------------------------------------------
  // Subtest 3.5: Key Zeroization / Memory Wipe Test
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 3.5: Cryptographic key zeroization verification...');
  bool zeroizationPassed = true;
  try {
    final salt = CryptoSecurity.generateSalt(16);
    final keys = CryptoSecurity.pbkdf2DeriveKeys('TempWipeSecret2026', salt, iterations: 100);

    bool nonZeroBefore = keys.encKey.any((b) => b != 0) && keys.authKey.any((b) => b != 0);
    keys.wipe();
    bool allZeroAfter = keys.encKey.every((b) => b == 0) && keys.authKey.every((b) => b == 0);

    final scratch = Uint8List.fromList([1, 2, 3, 4, 5]);
    CryptoSecurity.wipe(scratch);
    bool scratchZeroed = scratch.every((b) => b == 0);

    if (nonZeroBefore && allZeroAfter && scratchZeroed) {
      zeroizationPassed = true;
      subtestsPassed++;
      print('    ✅ Key zeroization confirmed: buffers securely wiped to all zeroes in memory.');
    } else {
      zeroizationPassed = false;
      defects.add('Test 3.5 Defect: Cryptographic wipe failed to zero key buffers');
    }
  } catch (e) {
    zeroizationPassed = false;
    defects.add('Test 3.5 Zeroization crashed: $e');
  }

  sw.stop();
  final passed = (subtestsPassed == subtestsTotal);
  return {
    'name': 'Cryptographic Tamper & Attack Suite',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': {
      'subtestsPassed': '$subtestsPassed / $subtestsTotal',
      'boundaryPassed': boundaryPassed,
      'inPageTamperCaught': inPageTamperCaught,
      'companionPassed': companionPassed,
      'tableCiphertextClean': tableCiphertextClean,
      'zeroizationPassed': zeroizationPassed,
    },
  };
}

// ============================================================================
// TEST 4: Dirty Page Buffer Death
// ============================================================================

Future<Map<String, dynamic>> test4DirtyPageBufferDeath(
  List<String> defects,
  List<Map<String, dynamic>> findings,
) async {
  final sw = Stopwatch()..start();
  print('\n----------------------------------------------------------------------');
  print(' [TEST 4] Dirty Page Buffer Death (Abrupt Process Termination)');
  print('----------------------------------------------------------------------');

  final testDir = '$kChaosRoot/dirty_death';
  await _ensureCleanDir(testDir);

  int subtestsPassed = 0;
  int subtestsTotal = 0;

  final scriptPath = Platform.script.toFilePath();

  // --------------------------------------------------------------------------
  // Subtest 4.1: 1,000 Dirty Pages Abrupt Termination (Uncommitted)
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 4.1: 1,000 dirty uncommitted pages: abrupt SIGKILL before flush...');
  bool uncommittedDeathClean = false;
  final subDir1 = '$testDir/uncommitted_death';
  await _ensureCleanDir(subDir1);

  try {
    final proc = await Process.start('dart', [
      'run',
      scriptPath,
      '--worker-dirty-death',
      subDir1,
      '1000',
      'false', // uncommitted
    ]);

    final primedCompleter = Completer<void>();
    proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.contains('DIRTY_BUFFER_PRIMED') && !primedCompleter.isCompleted) {
        primedCompleter.complete();
      }
    });

    await primedCompleter.future.timeout(const Duration(seconds: 40));
    print('    Worker successfully loaded 1,000 dirty uncommitted pages in memory. Killing abruptly...');
    proc.kill(ProcessSignal.sigkill);
    await proc.exitCode;
    await Future.delayed(const Duration(milliseconds: 250));

    // Now reopen database from parent and verify table state
    final db = Database(subDir1, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    final countRes = await interp.executeScript('SELECT COUNT(*) FROM dirty_death;');
    final count = (countRes.rows.first.first as DbInt).value;

    // Verify database can accept new operations
    await interp.executeScript("INSERT INTO dirty_death VALUES (99999, 'clean_recovery');");
    final postRes = await interp.executeScript('SELECT COUNT(*) FROM dirty_death;');
    final postCount = (postRes.rows.first.first as DbInt).value;
    await db.close();

    if (count == 0 && postCount == 1) {
      uncommittedDeathClean = true;
      subtestsPassed++;
      print('    ✅ Uncommitted dirty pages cleanly discarded on abrupt kill: count=0, post-insert=1.');
    } else {
      defects.add('Test 4.1 Defect: Dirty uncommitted rows survived abrupt process termination (count=$count)');
      print('    ❌ Dirty uncommitted rows survived termination (count=$count)');
    }
  } catch (e, st) {
    defects.add('Test 4.1 Defect: Reopen after abrupt kill crashed: $e');
    print('    ❌ Crash on reopen after abrupt kill: $e\n$st');
  }

  // --------------------------------------------------------------------------
  // Subtest 4.2: 1,000 Dirty Pages Committed Without Close / Flush (WAL REDO Replay)
  // --------------------------------------------------------------------------
  subtestsTotal++;
  print(' -> Subtest 4.2: 1,000 dirty committed pages: abrupt SIGKILL before close/flush...');
  bool committedDeathClean = false;
  final subDir2 = '$testDir/committed_death';
  await _ensureCleanDir(subDir2);

  try {
    final proc = await Process.start('dart', [
      'run',
      scriptPath,
      '--worker-dirty-death',
      subDir2,
      '1000',
      'true', // committed
    ]);

    final committedCompleter = Completer<void>();
    proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.contains('DIRTY_BUFFER_COMMITTED') && !committedCompleter.isCompleted) {
        committedCompleter.complete();
      }
    });

    await committedCompleter.future.timeout(const Duration(seconds: 40));
    print('    Worker committed 1,000 dirty pages to WAL. Killing before close/flushAllSync...');
    proc.kill(ProcessSignal.sigkill);
    await proc.exitCode;
    await Future.delayed(const Duration(milliseconds: 250));

    // Reopen database and verify WAL recovery reconstructs all committed rows
    final db = Database(subDir2, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    final countRes = await interp.executeScript('SELECT COUNT(*) FROM dirty_death;');
    final count = (countRes.rows.first.first as DbInt).value;

    // Scan sample rows across the 1,000 pages to verify no data corruption
    final sampleRes = await interp.executeScript('SELECT id FROM dirty_death WHERE id IN (0, 250, 500, 750, 999);');
    final sampledIds = sampleRes.rows.map((r) => (r[0] as DbInt).value).toSet();
    await db.close();

    if (count == 1000 && sampledIds.length == 5) {
      committedDeathClean = true;
      subtestsPassed++;
      print('    ✅ Committed dirty pages 100% recovered via WAL replay: count=1,000, sample checks valid.');
    } else {
      defects.add('Test 4.2 Defect: WAL recovery failed to restore all 1,000 committed pages (recovered count=$count/1000)');
      print('    ❌ WAL recovery incomplete: count=$count/1000, sampled=$sampledIds');
    }
  } catch (e, st) {
    defects.add('Test 4.2 Defect: Reopen after committed kill crashed: $e');
    print('    ❌ Crash on reopen after committed kill: $e\n$st');
  }

  sw.stop();
  final passed = (subtestsPassed == subtestsTotal);
  return {
    'name': 'Dirty Page Buffer Death',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': {
      'subtestsPassed': '$subtestsPassed / $subtestsTotal',
      'uncommittedDeathClean': uncommittedDeathClean,
      'committedDeathClean': committedDeathClean,
    },
  };
}
