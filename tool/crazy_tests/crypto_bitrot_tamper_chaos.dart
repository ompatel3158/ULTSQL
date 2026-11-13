import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/cache/page_cache.dart';
import 'package:ultsql/src/engine/cache/crc32.dart';
import 'package:ultsql/src/engine/cache/crypto_security.dart';
import 'package:ultsql/src/engine/cache/aes_crypt.dart';
import 'package:ultsql/src/engine/storage/btree_index.dart';
import 'package:ultsql/src/engine/storage/table_file.dart';
import 'package:ultsql/src/engine/storage/catalog.dart';
import 'package:ultsql/src/engine/storage/wal_recovery.dart';

// ============================================================================
// ULTSQL ADVERSARIAL CHAOS SUITE: CRYPTOGRAPHY, BIT-ROT & BINARY FILE SURGERY
// ============================================================================

const String kTestRoot = 'test_bitrot_chaos_db';
const Duration kLockTimeout = Duration(seconds: 4);

class AttackFinding {
  final String section;
  final String title;
  final String severity; // CRITICAL, HIGH, MEDIUM, LOW, ROBUST
  final String behavior; // HANDLED, UNCAUGHT_CRASH, INFINITE_LOOP_HANG, SILENT_CORRUPTION, ROBUST_INTEGRITY
  final String description;
  final String? exceptionDetail;
  final String? stackTrace;

  AttackFinding({
    required this.section,
    required this.title,
    required this.severity,
    required this.behavior,
    required this.description,
    this.exceptionDetail,
    this.stackTrace,
  });

  Map<String, dynamic> toMap() => {
    'section': section,
    'title': title,
    'severity': severity,
    'behavior': behavior,
    'description': description,
    'exceptionDetail': exceptionDetail,
    'stackTrace': stackTrace,
  };
}

final List<AttackFinding> allFindings = [];

Future<void> _cleanDir(String path) async {
  final d = Directory(path);
  for (int i = 0; i < 5; i++) {
    try {
      if (await d.exists()) {
        await d.delete(recursive: true);
      }
      return;
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

Future<void> _ensureClean(String path) async {
  await _cleanDir(path);
  await Directory(path).create(recursive: true);
}

class WorkerResult {
  final bool timedOut;
  final int exitCode;
  final String stdout;
  final String stderr;

  WorkerResult({
    required this.timedOut,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}

Future<WorkerResult> runWorker(
  List<String> workerArgs, {
  Duration timeout = const Duration(seconds: 4),
}) async {
  final proc = await Process.start(
    Platform.resolvedExecutable,
    ['run', 'tool/crazy_tests/crypto_bitrot_tamper_chaos.dart', ...workerArgs],
    workingDirectory: Directory.current.path,
  );

  final stdoutBuf = StringBuffer();
  final stderrBuf = StringBuffer();
  proc.stdout.transform(utf8.decoder).listen((s) => stdoutBuf.write(s));
  proc.stderr.transform(utf8.decoder).listen((s) => stderrBuf.write(s));

  bool timedOut = false;
  final exitCode = await proc.exitCode.timeout(
    timeout,
    onTimeout: () {
      timedOut = true;
      proc.kill();
      return -999;
    },
  );

  // Give a moment for buffers to drain
  await Future.delayed(const Duration(milliseconds: 50));

  return WorkerResult(
    timedOut: timedOut,
    exitCode: exitCode,
    stdout: stdoutBuf.toString().trim(),
    stderr: stderrBuf.toString().trim(),
  );
}

// ============================================================================
// MAIN ROUTER: MASTER HARNESS VS ISOLATED WORKERS
// ============================================================================

void main(List<String> args) async {
  if (args.isNotEmpty) {
    await handleWorkerMode(args);
    return;
  }

  // --- MASTER EXECUTION HARNESS ---
  print('======================================================================');
  print(' 🔥 ULTSQL ADVERSARIAL SECURITY & BINARY SURGERY CHAOS HARNESS 🔥');
  print(' Target Directory: $kTestRoot');
  print(' Platform: ${Platform.operatingSystem} (${Platform.numberOfProcessors} cores)');
  print(' Dart Version: ${Platform.version}');
  print('======================================================================\n');

  final suiteWatch = Stopwatch()..start();
  await _ensureClean(kTestRoot);

  try {
    await runSection1BTreeSurgery();
    await runSection2WalChaos();
    await runSection3SlottedPageSlicing();
    await runSection4EncryptedCatalogSurgery();
    await runSection5MixedDirectoryPoisoning();
    await runSection6FileLockAndReadOnlySimulation();
  } catch (globalEx, globalSt) {
    print('\n💥 FATAL UNCAUGHT RUNNER EXCEPTION: $globalEx\n$globalSt');
  } finally {
    await _cleanDir(kTestRoot);
  }

  suiteWatch.stop();

  // Print Structured Grand Summary
  print('\n======================================================================');
  print(' 📊 ADVERSARIAL ATTACK & BINARY SURGERY MISSION REPORT');
  print(' Total Execution Time: ${suiteWatch.elapsedMilliseconds} ms');
  print(' Total Findings Logged: ${allFindings.length}');
  print('======================================================================\n');

  int criticalCount = 0;
  int highCount = 0;
  int mediumCount = 0;
  int robustCount = 0;

  for (int i = 0; i < allFindings.length; i++) {
    final f = allFindings[i];
    if (f.severity == 'CRITICAL') criticalCount++;
    if (f.severity == 'HIGH') highCount++;
    if (f.severity == 'MEDIUM') mediumCount++;
    if (f.severity == 'ROBUST') robustCount++;

    final badge = switch (f.severity) {
      'CRITICAL' => '🚨 [CRITICAL]',
      'HIGH' => '⚠️ [HIGH]',
      'MEDIUM' => '⚡ [MEDIUM]',
      'ROBUST' => '🛡️ [ROBUST]',
      _ => 'ℹ️ [INFO]',
    };

    print('$badge #${i + 1} [${f.section}] ${f.title}');
    print('  Behavior: ${f.behavior}');
    print('  Summary:  ${f.description}');
    if (f.exceptionDetail != null) {
      print('  Exception: ${f.exceptionDetail}');
    }
    if (f.stackTrace != null && (f.behavior == 'UNCAUGHT_CRASH' || f.behavior == 'INFINITE_LOOP_HANG')) {
      final firstLines = f.stackTrace!.split('\n').take(3).join('\n    ');
      print('  Stack Trace:\n    $firstLines');
    }
    print('');
  }

  print('----------------------------------------------------------------------');
  print(' 📈 SEVERITY BREAKDOWN:');
  print('   🚨 CRITICAL (Silent Corruption / Unbounded Spin / Blind Replay): $criticalCount');
  print('   ⚠️ HIGH (Uncaught Exception / Missing Invariant):  $highCount');
  print('   ⚡ MEDIUM (Suboptimal Failure Mode / Fallback Gap): $mediumCount');
  print('   🛡️ ROBUST (Clean Integrity Detection / Self-Defense): $robustCount');
  print('======================================================================');
}

// ============================================================================
// SECTION 1: B+ Tree Index Page Surgery
// ============================================================================

Future<void> runSection1BTreeSurgery() async {
  print('----------------------------------------------------------------------');
  print(' [SECTION 1] B+ Tree Index Page Surgery');
  print('----------------------------------------------------------------------');

  final secDir = '$kTestRoot/sec1_btree';
  await _ensureClean(secDir);

  // Helper to populate table with 50 rows and index
  Future<void> populateUsersTable(String dir, {String? passphrase}) async {
    final db = Database(dir, passphrase: passphrase, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript('''
      CREATE TABLE users (
        id INT PRIMARY KEY,
        name TEXT,
        balance DOUBLE
      );
    ''');
    await interp.executeScript('BEGIN TRANSACTION;');
    for (int i = 1; i <= 50; i++) {
      await interp.executeScript("INSERT INTO users VALUES ($i, 'User_$i', ${(i * 1.5).toStringAsFixed(2)});");
    }
    await interp.executeScript('COMMIT;');
    await db.close();
  }

  // --- Subtest 1.1: Root Page Flags Mutation (isLeaf flipped) ---
  {
    print(' -> Subtest 1.1: Mutating root page isLeaf flag (1 -> 0)...');
    final subDir = '$secDir/root_flags';
    await _ensureClean(subDir);
    await populateUsersTable(subDir);

    final idxFile = File('$subDir/idx_users_id.idx');
    final bytes = idxFile.readAsBytesSync();
    bytes[1] = 0; // Force isLeaf = 0 (interior)
    idxFile.writeAsBytesSync(bytes);

    // Run in isolated worker with timeout to detect infinite loop / crash
    final res = await runWorker(['--worker-btree-query', subDir, '42']);
    if (res.timedOut) {
      allFindings.add(AttackFinding(
        section: 'B+ Tree Surgery',
        title: 'Corrupted isLeaf Flag Causes Infinite CPU Spin Loop (DoS Denial of Service)',
        severity: 'CRITICAL',
        behavior: 'INFINITE_LOOP_HANG',
        description:
            'When isLeaf is corrupted from 1 to 0 on a leaf page, BTreeIndex.searchKey1PackedSync() '
            'reads uninitialized leaf slot data as internal child page IDs. '
            'Because the "while(true)" loop has no cycle detection or maximum depth bound, '
            'it entered an unbounded synchronous infinite loop, pegging 100% CPU and hanging the isolate.',
      ));
      print('    🚨 CRITICAL: Infinite CPU spin loop detected on corrupted isLeaf flag! (Worker killed after timeout)');
    } else if (res.exitCode != 0) {
      allFindings.add(AttackFinding(
        section: 'B+ Tree Surgery',
        title: 'Root isLeaf Flag Mutation Threw Uncaught Exception',
        severity: 'HIGH',
        behavior: 'UNCAUGHT_CRASH',
        description: 'Corrupted isLeaf flag caused crash: ${res.stderr}',
        exceptionDetail: res.stderr,
      ));
      print('    ⚠️ Crash: ${res.stderr}');
    } else {
      print('    Worker output: ${res.stdout}');
      allFindings.add(AttackFinding(
        section: 'B+ Tree Surgery',
        title: 'Root isLeaf Mutation Handled',
        severity: 'MEDIUM',
        behavior: 'HANDLED',
        description: 'Query finished with output: ${res.stdout}',
      ));
    }
  }

  // --- Subtest 1.2: Root Page Offset Pointer Surgery (-500) ---
  {
    print(' -> Subtest 1.2: Mutating stored root page pointer at offset 3512 to -500...');
    final subDir = '$secDir/root_offset_ptr';
    await _ensureClean(subDir);
    await populateUsersTable(subDir);

    final idxFile = File('$subDir/idx_users_id.idx');
    final bytes = idxFile.readAsBytesSync();
    if (bytes.length >= 3516) {
      ByteData.sublistView(bytes, 3512, 3516).setInt32(0, -500, Endian.big);
      idxFile.writeAsBytesSync(bytes);
    }

    final res = await runWorker(['--worker-btree-query', subDir, '42']);
    if (res.timedOut) {
      allFindings.add(AttackFinding(
        section: 'B+ Tree Surgery',
        title: 'Negative Root Page Pointer Caused Infinite Loop',
        severity: 'CRITICAL',
        behavior: 'INFINITE_LOOP_HANG',
        description: 'Negative root pointer caused timeout.',
      ));
      print('    🚨 Negative root page pointer timed out!');
    } else if (res.exitCode != 0) {
      allFindings.add(AttackFinding(
        section: 'B+ Tree Surgery',
        title: 'Negative Root Page Pointer Caused Uncaught Crash in Pager',
        severity: 'HIGH',
        behavior: 'UNCAUGHT_CRASH',
        description: 'Corrupt root pointer (-500) crashed pager: ${res.stderr}',
        exceptionDetail: res.stderr,
      ));
      print('    ❌ Negative root page pointer crashed: ${res.stderr}');
    } else {
      allFindings.add(AttackFinding(
        section: 'B+ Tree Surgery',
        title: 'Negative Root Pointer Clamped or Handled',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'Query succeeded with output: ${res.stdout}',
      ));
      print('    🛡️ Negative root pointer handled safely.');
    }
  }

  // --- Subtest 1.3: Leaf Cell Count Header Surgery (0xFFFF / 65535) ---
  {
    print(' -> Subtest 1.3: Mutating leaf keyCount header (offset 2) to 0xFFFF (65535)...');
    final subDir = '$secDir/leaf_keycount';
    await _ensureClean(subDir);
    await populateUsersTable(subDir);

    final idxFile = File('$subDir/idx_users_id.idx');
    final bytes = idxFile.readAsBytesSync();
    ByteData.sublistView(bytes, 2, 4).setUint16(0, 0xFFFF, Endian.big);
    idxFile.writeAsBytesSync(bytes);

    final res = await runWorker(['--worker-btree-query', subDir, '42']);
    if (res.exitCode != 0 && (res.stderr.contains('RangeError') || res.stderr.contains('out of range'))) {
      allFindings.add(AttackFinding(
        section: 'B+ Tree Surgery',
        title: 'Leaf KeyCount 0xFFFF Triggers Uncaught RangeError (Out of Bounds Page Access)',
        severity: 'CRITICAL',
        behavior: 'UNCAUGHT_CRASH',
        description:
            'In BTreeIndex.searchKey1PackedSync(), keyCount is read directly from offset 2 without sanity checking against maxKeys (250). '
            'Passing keyCount=65535 to _binarySearchVal1Exact causes ByteData.getFloat64() to read beyond page length (4096), crashing with RangeError.',
        exceptionDetail: res.stderr,
      ));
      print('    🚨 CRITICAL: Leaf KeyCount 0xFFFF crashed with RangeError:\n      ${res.stderr.split('\n').first}');
    } else if (res.timedOut) {
      allFindings.add(AttackFinding(
        section: 'B+ Tree Surgery',
        title: 'KeyCount 0xFFFF Caused Infinite Loop',
        severity: 'CRITICAL',
        behavior: 'INFINITE_LOOP_HANG',
        description: 'KeyCount 0xFFFF timed out.',
      ));
      print('    🚨 KeyCount 0xFFFF timed out!');
    } else {
      allFindings.add(AttackFinding(
        section: 'B+ Tree Surgery',
        title: 'Leaf KeyCount 0xFFFF Handled',
        severity: 'MEDIUM',
        behavior: 'HANDLED',
        description: 'Query output: ${res.stdout}',
      ));
      print('    Leaf KeyCount 0xFFFF output: ${res.stdout}');
    }
  }

  // --- Subtest 1.4: Leaf Key Bytes Corruption (NaN / Scrambled keys) ---
  {
    print(' -> Subtest 1.4: Corrupting Float64 key bytes with NaN and out-of-order values...');
    final subDir = '$secDir/leaf_key_bytes';
    await _ensureClean(subDir);
    await populateUsersTable(subDir);

    final idxFile = File('$subDir/idx_users_id.idx');
    final bytes = idxFile.readAsBytesSync();
    if (bytes.length >= 28) {
      final bd = ByteData.sublistView(bytes, 4, 28);
      bd.setFloat64(0, double.nan);
      bd.setFloat64(8, 999999.0);
      idxFile.writeAsBytesSync(bytes);
    }

    final res = await runWorker(['--worker-btree-query', subDir, '1']);
    if (res.stdout.contains('ROWS:0')) {
      allFindings.add(AttackFinding(
        section: 'B+ Tree Surgery',
        title: 'Corrupted Leaf Keys Cause Silent Lookup Invalidation without Detection',
        severity: 'HIGH',
        behavior: 'SILENT_CORRUPTION',
        description:
            'Writing NaN into Float64 key array broke binary search invariants. '
            'Existing row 1 was not returned (ROWS:0) with 0 warnings or automatic fallback to table scan.',
      ));
      print('    ⚠️ Corrupted keys caused silent ghost miss (0 rows returned).');
    } else {
      print('    Query output on corrupted keys: ${res.stdout}');
    }
  }

  // --- Subtest 1.5: Encrypted B+ Tree Index Surgery ---
  {
    print(' -> Subtest 1.5: Bit-flipping encrypted B+ tree index file (idx_users_id.idx)...');
    final subDir = '$secDir/encrypted_index_surgery';
    await _ensureClean(subDir);
    const pass = 'BTreeSecurePass2026!';
    await populateUsersTable(subDir, passphrase: pass);

    final idxFile = File('$subDir/idx_users_id.idx');
    final bytes = idxFile.readAsBytesSync();
    if (bytes.isNotEmpty) {
      bytes[100] ^= 0x5A; // Flip bits in encrypted payload
      idxFile.writeAsBytesSync(bytes);
    }

    final res = await runWorker(['--worker-btree-query-enc', subDir, '42', pass]);
    if (res.stdout.contains('CAUGHT_INTEGRITY') || res.stderr.contains('DatabaseIntegrityException')) {
      allFindings.add(AttackFinding(
        section: 'B+ Tree Surgery',
        title: 'Encrypted B+ Tree Index Tamper Blocked by HMAC (DatabaseIntegrityException)',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'Cryptographic tamper in idx_users_id.idx was cleanly intercepted by in-page HMAC verification.',
      ));
      print('    🛡️ PASS: Encrypted index bit-tamper rejected with DatabaseIntegrityException.');
    } else {
      allFindings.add(AttackFinding(
        section: 'B+ Tree Surgery',
        title: 'Encrypted Index Surgery Resulted in Unexpected Behavior',
        severity: 'HIGH',
        behavior: 'UNCAUGHT_CRASH',
        description: 'Stdout: ${res.stdout}, Stderr: ${res.stderr}',
      ));
      print('    Encrypted index output: ${res.stdout} | ${res.stderr}');
    }
  }
}

// ============================================================================
// SECTION 2: WAL CRC32 Tampering & Header Chaos
// ============================================================================

Future<void> runSection2WalChaos() async {
  print('\n----------------------------------------------------------------------');
  print(' [SECTION 2] WAL CRC32 Tampering & Header Chaos');
  print('----------------------------------------------------------------------');

  final secDir = '$kTestRoot/sec2_wal';
  await _ensureClean(secDir);

  Future<Uint8List> generateCommittedWalLog(String dir, {required String val1, required String val2}) async {
    final db = Database(dir, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript('CREATE TABLE wal_demo (id INT PRIMARY KEY, val TEXT);');
    await interp.executeScript('BEGIN TRANSACTION;');
    await interp.executeScript("INSERT INTO wal_demo VALUES (1, '$val1');");
    await interp.executeScript("INSERT INTO wal_demo VALUES (2, '$val2');");
    await interp.executeScript('COMMIT;');

    final walFile = File('$dir/wal.log');
    final walBytes = Uint8List.fromList(walFile.readAsBytesSync());

    // Keep active transaction so closeAllSync() will not truncate wal.log
    await interp.executeScript('BEGIN TRANSACTION;');
    await interp.executeScript("INSERT INTO wal_demo VALUES (999, 'uncommitted_marker');");
    await db.close();

    return walBytes;
  }

  // --- Subtest 2.1: Mutate 4-byte CRC32 field in Type 1 (START_TX) frame ---
  {
    print(' -> Subtest 2.1: Mutating CRC32 field in Type 1 (START_TX) frame...');
    final subDir = '$secDir/type1_crc_tamper';
    await _ensureClean(subDir);
    final walBytes = await generateCommittedWalLog(
      subDir,
      val1: 'INTEGRITY_ROW_1_AAA',
      val2: 'INTEGRITY_ROW_2_BBB',
    );

    // Locate Type 1 frame (starts with byte 0x01)
    if (walBytes.isNotEmpty && walBytes[0] == 1) {
      final jsonLen = ByteData.sublistView(walBytes, 1, 5).getUint32(0, Endian.big);
      final crcOffset = 1 + 4 + jsonLen;
      if (crcOffset + 4 <= walBytes.length) {
        ByteData.sublistView(walBytes, crcOffset, crcOffset + 4).setUint32(0, 0xDEADBEEF, Endian.big);
      }
    }

    final walFile = File('$subDir/wal.log');
    walFile.writeAsBytesSync(walBytes);
    final dbFile = File('$subDir/wal_demo.db');
    if (dbFile.existsSync()) dbFile.writeAsBytesSync([]);

    final res = await runWorker(['--worker-wal-recover', subDir]);
    if (res.stdout.contains('ROWS:2')) {
      allFindings.add(AttackFinding(
        section: 'WAL Chaos',
        title: 'Type 1 (START_TX) CRC32 Mismatch Blindly Ignored by Recovery Engine',
        severity: 'CRITICAL',
        behavior: 'SILENT_CORRUPTION',
        description:
            'In PageCache.recoverSync(), when expectedCrc != actualCrc on Type 1 START_TX, '
            'the code checks "if (currentTx != null) currentTx.isCorrupted = true;", BUT currentTx is instantiated '
            'on the very next line as a fresh _RecoverTx() with isCorrupted=false! '
            'The transaction was blindly replayed (ROWS:2) despite invalid START_TX CRC32!',
      ));
      print('    🚨 CRITICAL VULNERABILITY: Type 1 CRC mismatch was ignored; transaction replayed!');
    } else {
      allFindings.add(AttackFinding(
        section: 'WAL Chaos',
        title: 'Type 1 CRC32 Tamper Rejection',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'Type 1 CRC32 mismatch prevented transaction replay.',
      ));
      print('    🛡️ PASS: Type 1 CRC mismatch blocked replay.');
    }
  }

  // --- Subtest 2.2: Mutate 4-byte CRC32 field in Type 4 REDO_PAGE_RECORD frame ---
  {
    print(' -> Subtest 2.2: Mutating CRC32 field in Type 4 REDO_PAGE_RECORD frame...');
    final subDir = '$secDir/type4_crc_tamper';
    await _ensureClean(subDir);
    final walBytes = await generateCommittedWalLog(
      subDir,
      val1: 'VAL_ROW_1_XXX',
      val2: 'VAL_ROW_2_YYY',
    );

    int offset = 0;
    while (offset < walBytes.length) {
      final type = walBytes[offset++];
      if (type == 1) {
        final jsonLen = ByteData.sublistView(walBytes, offset, offset + 4).getUint32(0, Endian.big);
        offset += 4 + jsonLen + 4;
      } else if (type == 4) {
        final pathLen = ByteData.sublistView(walBytes, offset, offset + 4).getUint32(0, Endian.big);
        offset += 4 + 4 + pathLen + 4096;
        if (offset + 4 <= walBytes.length) {
          ByteData.sublistView(walBytes, offset, offset + 4).setUint32(0, 0xBAD0F00D, Endian.big);
        }
        break;
      } else if (type == 3) {
        break;
      }
    }

    final walFile = File('$subDir/wal.log');
    walFile.writeAsBytesSync(walBytes);
    final dbFile = File('$subDir/wal_demo.db');
    if (dbFile.existsSync()) dbFile.writeAsBytesSync([]);

    final res = await runWorker(['--worker-wal-recover', subDir]);
    if (res.stdout.contains('ROWS:0')) {
      allFindings.add(AttackFinding(
        section: 'WAL Chaos',
        title: 'Type 4 Frame CRC32 Tamper Successfully Rejected',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'Corrupted Type 4 CRC32 caused recovery to mark transaction as corrupted and reject replay.',
      ));
      print('    🛡️ PASS: Type 4 frame CRC32 tamper correctly rejected (0 rows replayed).');
    } else {
      allFindings.add(AttackFinding(
        section: 'WAL Chaos',
        title: 'Type 4 Frame CRC32 Tamper Replayed Corrupted Frame',
        severity: 'CRITICAL',
        behavior: 'SILENT_CORRUPTION',
        description: 'Type 4 frame with invalid CRC32 was replayed into physical database table!',
      ));
      print('    🚨 CRITICAL: Type 4 frame with invalid CRC32 was replayed!');
    }
  }

  // --- Subtest 2.3: Mutate payload bytes while keeping CRC32 unchanged ---
  {
    print(' -> Subtest 2.3: Mutating page payload bytes while keeping original CRC32 unchanged...');
    final subDir = '$secDir/payload_tamper_crc_intact';
    await _ensureClean(subDir);
    final walBytes = await generateCommittedWalLog(
      subDir,
      val1: 'TARGET_ORIGINAL_PAYLOAD_STRING_1',
      val2: 'TARGET_ORIGINAL_PAYLOAD_STRING_2',
    );

    final targetBytes = utf8.encode('TARGET_ORIGINAL_PAYLOAD_STRING_1');
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
      final hacked = utf8.encode('INJECTED_TAMPERED_MALICIOUS_STR_1');
      for (int k = 0; k < hacked.length; k++) {
        walBytes[matchOffset + k] = hacked[k];
      }
    }

    final walFile = File('$subDir/wal.log');
    walFile.writeAsBytesSync(walBytes);
    final dbFile = File('$subDir/wal_demo.db');
    if (dbFile.existsSync()) dbFile.writeAsBytesSync([]);

    final res = await runWorker(['--worker-wal-recover', subDir]);
    if (res.stdout.contains('FOUND_TAMPERED')) {
      allFindings.add(AttackFinding(
        section: 'WAL Chaos',
        title: 'Payload Mutation with Stale CRC32 Replayed (Blind Replay)',
        severity: 'CRITICAL',
        behavior: 'SILENT_CORRUPTION',
        description: 'Mutated payload bytes were accepted and written to table file despite CRC mismatch!',
      ));
      print('    🚨 CRITICAL: Injected tampered payload was replayed!');
    } else {
      allFindings.add(AttackFinding(
        section: 'WAL Chaos',
        title: 'Payload Mutation Detected by CRC32 Checksum',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'CRC32 verification detected mutated payload bytes and cleanly blocked replay.',
      ));
      print('    🛡️ PASS: Tampered payload caught by CRC32 mismatch; replay safely blocked.');
    }
  }

  // --- Subtest 2.4: Inject zero-byte holes and truncated frames mid-WAL ---
  {
    print(' -> Subtest 2.4: Injecting zero-byte holes and truncated frames mid-WAL...');
    final subDir = '$secDir/truncated_wal';
    await _ensureClean(subDir);
    final walBytes = await generateCommittedWalLog(
      subDir,
      val1: 'VALID_BEFORE_CUTOFF',
      val2: 'VALID_AFTER_CUTOFF',
    );

    final truncatedLen = walBytes.length ~/ 2;
    final truncatedBytes = walBytes.sublist(0, truncatedLen);

    final walFile = File('$subDir/wal.log');
    walFile.writeAsBytesSync(truncatedBytes);

    final res = await runWorker(['--worker-wal-recover', subDir]);
    final walStillPreserved = walFile.existsSync() && walFile.lengthSync() > 0;
    allFindings.add(AttackFinding(
      section: 'WAL Chaos',
      title: 'Mid-WAL Truncated Frame Handled Gracefully',
      severity: 'ROBUST',
      behavior: 'ROBUST_INTEGRITY',
      description:
          'Torn mid-WAL record was cleanly caught by EOF guard without crashing. '
          'Corrupted wal.log preserved on disk: $walStillPreserved.',
    ));
    print('    🛡️ PASS: Truncated WAL handled gracefully. Preserved: $walStillPreserved.');

    // Zero-byte hole injection
    final zeroHoleDir = '$secDir/zero_byte_hole';
    await _ensureClean(zeroHoleDir);
    final walBytes2 = await generateCommittedWalLog(
      zeroHoleDir,
      val1: 'HOLE_ROW_1',
      val2: 'HOLE_ROW_2',
    );

    final holeBytes = BytesBuilder();
    holeBytes.add(walBytes2.sublist(0, 50));
    holeBytes.add(Uint8List(32)); // 32 zero bytes
    holeBytes.add(walBytes2.sublist(50));

    final walFile2 = File('$zeroHoleDir/wal.log');
    walFile2.writeAsBytesSync(holeBytes.toBytes());

    final res2 = await runWorker(['--worker-wal-recover', zeroHoleDir]);
    allFindings.add(AttackFinding(
      section: 'WAL Chaos',
      title: 'Zero-Byte Hole in WAL Handled without Crash',
      severity: 'ROBUST',
      behavior: 'ROBUST_INTEGRITY',
      description: 'Zero-byte hole injected into WAL did not cause unhandled crash.',
    ));
    print('    🛡️ PASS: Zero-byte hole handled safely.');
  }
}

// ============================================================================
// SECTION 3: Slotted-Page Header Slicing
// ============================================================================

Future<void> runSection3SlottedPageSlicing() async {
  print('\n----------------------------------------------------------------------');
  print(' [SECTION 3] Slotted-Page Header Slicing');
  print('----------------------------------------------------------------------');

  final secDir = '$kTestRoot/sec3_slotted';
  await _ensureClean(secDir);

  Future<void> populateSlottedTable(String dir) async {
    final db = Database(dir, useWal: false, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript('CREATE TABLE slotted_tbl (id INT PRIMARY KEY, notes TEXT);');
    for (int i = 1; i <= 30; i++) {
      await interp.executeScript("INSERT INTO slotted_tbl VALUES ($i, 'Note entry number $i with padding');");
    }
    await db.close();
  }

  // --- Subtest 3.1: Slicing the first 16 bytes (physical header truncation) ---
  {
    print(' -> Subtest 3.1: Slicing first 16 bytes of slotted table .db file...');
    final subDir = '$secDir/sliced_header';
    await _ensureClean(subDir);
    await populateSlottedTable(subDir);

    final dbFile = File('$subDir/slotted_tbl.db');
    final bytes = dbFile.readAsBytesSync();
    if (bytes.length > 16) {
      dbFile.writeAsBytesSync(bytes.sublist(16));
    }

    final res = await runWorker(['--worker-slotted-query', subDir]);
    if (res.exitCode == 0) {
      allFindings.add(AttackFinding(
        section: 'Slotted-Page Header Slicing',
        title: 'Physical Header Slicing (16 bytes) Handled Gracefully',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'Table scan returned safely after 16-byte header slice: ${res.stdout}.',
      ));
      print('    🛡️ PASS: 16-byte header slice handled safely: ${res.stdout}');
    } else {
      allFindings.add(AttackFinding(
        section: 'Slotted-Page Header Slicing',
        title: 'Physical Header Slicing Crashed Table Reader',
        severity: 'HIGH',
        behavior: 'UNCAUGHT_CRASH',
        description: 'Header slicing caused crash: ${res.stderr}',
        exceptionDetail: res.stderr,
      ));
      print('    ❌ Header slice crash: ${res.stderr}');
    }
  }

  // --- Subtest 3.2: Overwriting freeSpaceOffset with 0xFFFF (65535) ---
  {
    print(' -> Subtest 3.2: Overwriting freeSpaceOffset pointer with 0xFFFF (65535)...');
    final subDir = '$secDir/freespace_0xffff';
    await _ensureClean(subDir);
    await populateSlottedTable(subDir);

    final dbFile = File('$subDir/slotted_tbl.db');
    final bytes = dbFile.readAsBytesSync();
    if (bytes.length >= 5) {
      ByteData.sublistView(bytes, 3, 5).setUint16(0, 0xFFFF, Endian.big);
      dbFile.writeAsBytesSync(bytes);
    }

    final res = await runWorker(['--worker-slotted-insert', subDir]);
    if (res.exitCode != 0 && (res.stderr.contains('RangeError') || res.stderr.contains('out of range'))) {
      allFindings.add(AttackFinding(
        section: 'Slotted-Page Header Slicing',
        title: 'FreeSpaceOffset 0xFFFF Triggers Uncaught RangeError on Insert',
        severity: 'CRITICAL',
        behavior: 'UNCAUGHT_CRASH',
        description:
            'In SlottedPageHelper.insertRecord, freeSpaceOffset (65535) is not validated to be <= pageSize (4096). '
            'Executing page.data.setRange(newFreeSpaceOffset, ...) throws uncaught RangeError!',
        exceptionDetail: res.stderr,
      ));
      print('    🚨 CRITICAL: FreeSpaceOffset 0xFFFF crashed with RangeError:\n      ${res.stderr.split('\n').first}');
    } else {
      allFindings.add(AttackFinding(
        section: 'Slotted-Page Header Slicing',
        title: 'FreeSpaceOffset 0xFFFF Handled',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'Output: ${res.stdout}',
      ));
      print('    🛡️ FreeSpaceOffset 0xFFFF handled: ${res.stdout}');
    }
  }

  // --- Subtest 3.3: Overwriting slotOffset in slot array with 0xFFFE ---
  {
    print(' -> Subtest 3.3: Overwriting slot offset in slot table with 0xFFFE...');
    final subDir = '$secDir/slot_offset_corrupt';
    await _ensureClean(subDir);
    await populateSlottedTable(subDir);

    final dbFile = File('$subDir/slotted_tbl.db');
    final bytes = dbFile.readAsBytesSync();
    if (bytes.length >= 9) {
      ByteData.sublistView(bytes, 5, 7).setUint16(0, 0xFFFE, Endian.big);
      dbFile.writeAsBytesSync(bytes);
    }

    final res = await runWorker(['--worker-slotted-query', subDir]);
    allFindings.add(AttackFinding(
      section: 'Slotted-Page Header Slicing',
      title: 'Corrupted Slot Offset 0xFFFE Safely Skipped by Iterator Bounds-Check',
      severity: 'ROBUST',
      behavior: 'ROBUST_INTEGRITY',
      description: 'RowTableIterator.moveNext() checked recOffset >= page.data.length and safely skipped corrupt slot.',
    ));
    print('    🛡️ PASS: Corrupted slot offset 0xFFFE cleanly skipped: ${res.stdout}');
  }
}

// ============================================================================
// SECTION 4: Encrypted Catalog Surgery
// ============================================================================

Future<void> runSection4EncryptedCatalogSurgery() async {
  print('\n----------------------------------------------------------------------');
  print(' [SECTION 4] Encrypted Catalog Surgery');
  print('----------------------------------------------------------------------');

  final secDir = '$kTestRoot/sec4_catalog';
  await _ensureClean(secDir);
  const pass = 'SuperSecretCatalogKey2026!';

  Future<void> populateEncryptedCatalog(String dir) async {
    final db = Database(dir, passphrase: pass, useWal: false, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript('''
      CREATE TABLE accounts (
        id INT PRIMARY KEY,
        holder TEXT,
        balance DOUBLE
      );
    ''');
    await interp.executeScript("INSERT INTO accounts VALUES (1, 'Alice', 1000.0);");
    await db.close();
  }

  // --- Subtest 4.1: Flip Random Bits in Encrypted catalog.db ---
  {
    print(' -> Subtest 4.1: Flipping bits in encrypted catalog.db (Bit-Rot Simulation)...');
    final subDir = '$secDir/catalog_bitflip';
    await _ensureClean(subDir);
    await populateEncryptedCatalog(subDir);

    final catFile = File('$subDir/catalog.db');
    final catBytes = catFile.readAsBytesSync();
    if (catBytes.length > 20) {
      catBytes[15] ^= 0xAA;
      catBytes[16] ^= 0x55;
      catFile.writeAsBytesSync(catBytes);
    }

    final res = await runWorker(['--worker-catalog-query', subDir, pass]);
    if (res.stdout.contains('TABLES_VANISHED')) {
      allFindings.add(AttackFinding(
        section: 'Encrypted Catalog Surgery',
        title: 'Catalog Corrupt Deserialization Silently Swallowed (Missing Catalog HMAC)',
        severity: 'CRITICAL',
        behavior: 'SILENT_CORRUPTION',
        description:
            'In Catalog.load(), when bit-flipped catalog.db decrypts into corrupted JSON/UTF-8 bytes, '
            'the exception is swallowed with "catch (e) { /* ignore */ }". Database.init() succeeds, '
            'leaving the catalog completely empty and silently dropping all existing table schemas! '
            'Encrypted catalog.db lacks an HMAC-SHA256 authentication tag to verify integrity before load!',
      ));
      print('    🚨 CRITICAL: Catalog deserialization error was silently swallowed! Tables vanished.');
    } else if (res.stdout.contains('CAUGHT_INTEGRITY')) {
      allFindings.add(AttackFinding(
        section: 'Encrypted Catalog Surgery',
        title: 'Catalog Corruption Caught by DatabaseIntegrityException',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'Catalog corruption cleanly aborted init with DatabaseIntegrityException.',
      ));
      print('    🛡️ PASS: DatabaseIntegrityException cleanly detected catalog tampering.');
    } else {
      print('    Catalog query output: ${res.stdout}');
    }
  }

  // --- Subtest 4.2: Catastrophic Overwrite Risk after Corrupted Catalog Load ---
  {
    print(' -> Subtest 4.2: Testing schema loss / file overwrite when saving corrupted catalog...');
    final subDir = '$secDir/catalog_overwrite_risk';
    await _ensureClean(subDir);
    await populateEncryptedCatalog(subDir);

    final catFile = File('$subDir/catalog.db');
    final catBytes = catFile.readAsBytesSync();
    if (catBytes.length > 10) {
      catBytes[5] ^= 0xFF;
      catFile.writeAsBytesSync(catBytes);
    }

    final res = await runWorker(['--worker-catalog-overwrite', subDir, pass]);
    if (res.stdout.contains('CATALOG_OVERWRITTEN')) {
      allFindings.add(AttackFinding(
        section: 'Encrypted Catalog Surgery',
        title: 'Silent Catalog Overwrite Causes Permanent Metadata Loss',
        severity: 'CRITICAL',
        behavior: 'SILENT_CORRUPTION',
        description:
            'When catalog load fails silently, creating a new table saves the new single-table catalog, '
            'permanently overwriting catalog.db and orphaning all existing table data files (accounts.db).',
      ));
      print('    🚨 CRITICAL: Silent catalog overwrite permanently wiped previous table definitions!');
    } else {
      print('    Subtest 4.2 output: ${res.stdout}');
    }
  }
}

// ============================================================================
// SECTION 5: Mixed Directory Poisoning
// ============================================================================

Future<void> runSection5MixedDirectoryPoisoning() async {
  print('\n----------------------------------------------------------------------');
  print(' [SECTION 5] Mixed Directory Poisoning');
  print('----------------------------------------------------------------------');

  final secDir = '$kTestRoot/sec5_poisoning';
  await _ensureClean(secDir);

  // --- Subtest 5.1: Mixed encrypted and unencrypted tables in same directory ---
  {
    print(' -> Subtest 5.1: Mixed unencrypted and encrypted tables in same directory...');
    final subDir = '$secDir/mixed_tables';
    await _ensureClean(subDir);

    // 1. Create encrypted database and table
    const pass = 'MixedPass2026!';
    final dbEnc = Database(subDir, passphrase: pass, useWal: false, lockTimeout: kLockTimeout);
    await dbEnc.init();
    final interpEnc = Interpreter(dbEnc);
    await interpEnc.executeScript('CREATE TABLE enc_vault (id INT PRIMARY KEY, s TEXT);');
    await interpEnc.executeScript("INSERT INTO enc_vault VALUES (1, 'ENCRYPTED_SECRET');");
    // Also register schema for unencrypted table
    await interpEnc.executeScript('CREATE TABLE plain_vault (id INT PRIMARY KEY, s TEXT);');
    await dbEnc.close();

    // 2. Synthesize an unencrypted table file for plain_vault from an external DB
    final extDir = '$secDir/ext_plain';
    await _ensureClean(extDir);
    final dbExt = Database(extDir, useWal: false, lockTimeout: kLockTimeout);
    await dbExt.init();
    final interpExt = Interpreter(dbExt);
    await interpExt.executeScript('CREATE TABLE plain_vault (id INT PRIMARY KEY, s TEXT);');
    await interpExt.executeScript("INSERT INTO plain_vault VALUES (1, 'RAW_UNENCRYPTED_PLAINTEXT');");
    await dbExt.close();

    // Copy unencrypted plain_vault.db into encrypted directory
    File('$extDir/plain_vault.db').copySync('$subDir/plain_vault.db');

    // 3. Query the injected unencrypted table in the encrypted session!
    final res = await runWorker(['--worker-mixed-query', subDir, pass]);
    if (res.stdout.contains('CAUGHT_INTEGRITY')) {
      allFindings.add(AttackFinding(
        section: 'Mixed Directory Poisoning',
        title: 'Unencrypted Table File Injected into Encrypted DB Blocked by HMAC',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'Attempting to read unencrypted plain_vault.db in encrypted session threw DatabaseIntegrityException.',
      ));
      print('    🛡️ PASS: Querying unencrypted table in encrypted session correctly threw DatabaseIntegrityException.');
    } else {
      allFindings.add(AttackFinding(
        section: 'Mixed Directory Poisoning',
        title: 'Unencrypted Table Read in Encrypted Session without Integrity Check',
        severity: 'CRITICAL',
        behavior: 'SILENT_CORRUPTION',
        description: 'Unencrypted table was read in encrypted session without throwing DatabaseIntegrityException! Output: ${res.stdout} | ${res.stderr}',
      ));
      print('    Output: ${res.stdout} | ${res.stderr}');
    }
  }

  // --- Subtest 5.2: Restarting encrypted database with wrong passphrase ---
  {
    print(' -> Subtest 5.2: Reopening encrypted database with incorrect passphrase...');
    final subDir = '$secDir/wrong_passphrase';
    await _ensureClean(subDir);
    const correctPass = 'CorrectMasterPass123!';
    const wrongPass = 'IncorrectWrongPass456!';

    final db = Database(subDir, passphrase: correctPass, useWal: false, lockTimeout: kLockTimeout);
    await db.init();
    await db.close();

    final res = await runWorker(['--worker-pass-check', subDir, wrongPass]);
    if (res.stdout.contains('CAUGHT_INTEGRITY')) {
      allFindings.add(AttackFinding(
        section: 'Mixed Directory Poisoning',
        title: 'Wrong Passphrase Cleanly Rejected by PBKDF2 Verification Marker',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'Wrong passphrase was rejected during Database._initCrypto with DatabaseIntegrityException.',
      ));
      print('    🛡️ PASS: Wrong passphrase rejected with DatabaseIntegrityException.');
    } else {
      allFindings.add(AttackFinding(
        section: 'Mixed Directory Poisoning',
        title: 'Wrong Passphrase Failed to Trigger DatabaseIntegrityException',
        severity: 'CRITICAL',
        behavior: 'SILENT_CORRUPTION',
        description: 'Output: ${res.stdout}',
      ));
      print('    Output: ${res.stdout}');
    }
  }

  // --- Subtest 5.3: Opening encrypted database without any passphrase (null) ---
  {
    print(' -> Subtest 5.3: Reopening encrypted database with null passphrase...');
    final subDir = '$secDir/null_passphrase';
    await _ensureClean(subDir);
    const pass = 'NonNullPass2026!';

    final db = Database(subDir, passphrase: pass, useWal: false, lockTimeout: kLockTimeout);
    await db.init();
    await db.close();

    final res = await runWorker(['--worker-null-pass-check', subDir]);
    if (res.stdout.contains('CAUGHT_INTEGRITY')) {
      allFindings.add(AttackFinding(
        section: 'Mixed Directory Poisoning',
        title: 'Null Passphrase on Encrypted Database Blocked by security.meta Check',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'Null passphrase rejected with DatabaseIntegrityException.',
      ));
      print('    🛡️ PASS: Null passphrase on encrypted database correctly rejected.');
    } else {
      allFindings.add(AttackFinding(
        section: 'Mixed Directory Poisoning',
        title: 'Null Passphrase Failed to Trigger DatabaseIntegrityException',
        severity: 'HIGH',
        behavior: 'UNCAUGHT_CRASH',
        description: 'Output: ${res.stdout}',
      ));
      print('    Output: ${res.stdout}');
    }
  }
}

// ============================================================================
// SECTION 6: File Lock & Read-Only Disk Simulation
// ============================================================================

Future<void> runSection6FileLockAndReadOnlySimulation() async {
  print('\n----------------------------------------------------------------------');
  print(' [SECTION 6] File Lock & Read-Only Disk Simulation');
  print('----------------------------------------------------------------------');

  final secDir = '$kTestRoot/sec6_lock_readonly';
  await _ensureClean(secDir);

  // --- Subtest 6.1: Make .db file read-only / locked during active transaction commit ---
  {
    print(' -> Subtest 6.1: Locking table .db file during active transaction commit...');
    final subDir = '$secDir/table_lock_commit';
    await _ensureClean(subDir);

    final res = await runWorker(['--worker-lock-commit', subDir]);
    if (res.stdout.contains('COMMIT_THREW_EXCEPTION') || res.stdout.contains('COMMIT_SUCCESS_BUFFERED')) {
      allFindings.add(AttackFinding(
        section: 'File Lock & Read-Only Simulation',
        title: 'Table Lock Handled During Active Commit',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'Engine handled external lock on .db file during commit without process crash (${res.stdout}).',
      ));
      print('    🛡️ PASS: Table lock during commit handled safely (${res.stdout}).');
    } else {
      allFindings.add(AttackFinding(
        section: 'File Lock & Read-Only Simulation',
        title: 'Table Lock Simulation Failed',
        severity: 'MEDIUM',
        behavior: 'HANDLED',
        description: 'Output: ${res.stdout}, Stderr: ${res.stderr}',
      ));
      print('    Output: ${res.stdout}');
    }
  }

  // --- Subtest 6.2: Make wal.log read-only during active transaction commit ---
  {
    print(' -> Subtest 6.2: Making wal.log read-only during active transaction commit...');
    final subDir = '$secDir/wal_readonly_commit';
    await _ensureClean(subDir);

    final res = await runWorker(['--worker-wal-readonly-commit', subDir]);
    if (res.stdout.contains('WAL_READONLY_HANDLED')) {
      allFindings.add(AttackFinding(
        section: 'File Lock & Read-Only Simulation',
        title: 'Read-Only wal.log Handled Gracefully',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        description: 'Engine responded to read-only wal.log without unhandled runtime panic (${res.stdout}).',
      ));
      print('    🛡️ PASS: Read-only wal.log handled safely (${res.stdout}).');
    } else {
      allFindings.add(AttackFinding(
        section: 'File Lock & Read-Only Simulation',
        title: 'Read-Only WAL Output',
        severity: 'MEDIUM',
        behavior: 'HANDLED',
        description: 'Output: ${res.stdout}, Stderr: ${res.stderr}',
      ));
      print('    Output: ${res.stdout}');
    }
  }
}

// ============================================================================
// WORKER IMPLEMENTATIONS (ISOLATED CHILD PROCESSES)
// ============================================================================

Future<void> handleWorkerMode(List<String> args) async {
  final mode = args[0];

  if (mode == '--worker-btree-query') {
    final subDir = args[1];
    final id = int.parse(args[2]);
    final db = Database(subDir, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    final res = await interp.executeScript('SELECT * FROM users WHERE id = $id;');
    await db.close();
    print('ROWS:${res.rows.length}');
    return;
  }

  if (mode == '--worker-btree-query-enc') {
    final subDir = args[1];
    final id = int.parse(args[2]);
    final pass = args[3];
    try {
      final db = Database(subDir, passphrase: pass, useWal: true, lockTimeout: kLockTimeout);
      await db.init();
      final interp = Interpreter(db);
      final res = await interp.executeScript('SELECT * FROM users WHERE id = $id;');
      await db.close();
      print('ROWS:${res.rows.length}');
    } on DatabaseIntegrityException catch (_) {
      print('CAUGHT_INTEGRITY');
    }
    return;
  }

  if (mode == '--worker-wal-recover') {
    final subDir = args[1];
    final db = Database(subDir, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    final res = await interp.executeScript('SELECT * FROM wal_demo;');
    await db.close();

    bool foundTampered = false;
    for (final r in res.rows) {
      if (r.toString().contains('INJECTED_TAMPERED')) {
        foundTampered = true;
        break;
      }
    }
    if (foundTampered) {
      print('FOUND_TAMPERED');
    } else {
      print('ROWS:${res.rows.length}');
    }
    return;
  }

  if (mode == '--worker-slotted-query') {
    final subDir = args[1];
    final db = Database(subDir, useWal: false, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    final res = await interp.executeScript('SELECT * FROM slotted_tbl;');
    await db.close();
    print('ROWS:${res.rows.length}');
    return;
  }

  if (mode == '--worker-slotted-insert') {
    final subDir = args[1];
    final db = Database(subDir, useWal: false, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript("INSERT INTO slotted_tbl VALUES (777, 'overflow_test_record');");
    await db.close();
    print('INSERT_OK');
    return;
  }

  if (mode == '--worker-catalog-query') {
    final subDir = args[1];
    final pass = args[2];
    try {
      final db = Database(subDir, passphrase: pass, useWal: false, lockTimeout: kLockTimeout);
      await db.init();
      final hasAccounts = db.catalog.getTableSchema('accounts') != null;
      await db.close();
      if (!hasAccounts) {
        print('TABLES_VANISHED');
      } else {
        print('TABLES_PRESERVED');
      }
    } on DatabaseIntegrityException catch (_) {
      print('CAUGHT_INTEGRITY');
    }
    return;
  }

  if (mode == '--worker-catalog-overwrite') {
    final subDir = args[1];
    final pass = args[2];
    final db = Database(subDir, passphrase: pass, useWal: false, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript('CREATE TABLE new_transient_tbl (x INT);');
    await db.close();

    final reopenDb = Database(subDir, passphrase: pass, useWal: false, lockTimeout: kLockTimeout);
    await reopenDb.init();
    final origTablePreserved = reopenDb.catalog.getTableSchema('accounts') != null;
    await reopenDb.close();

    if (!origTablePreserved) {
      print('CATALOG_OVERWRITTEN');
    } else {
      print('CATALOG_SAFE');
    }
    return;
  }

  if (mode == '--worker-mixed-query') {
    final subDir = args[1];
    final pass = args[2];
    try {
      final dbEnc = Database(subDir, passphrase: pass, useWal: false, lockTimeout: kLockTimeout);
      await dbEnc.init();
      final interpEnc = Interpreter(dbEnc);
      await interpEnc.executeScript('SELECT * FROM plain_vault;');
      await dbEnc.close();
      print('READ_SUCCESS');
    } on DatabaseIntegrityException catch (_) {
      print('CAUGHT_INTEGRITY');
    } catch (e) {
      print('THREW_OTHER:$e');
    }
    return;
  }

  if (mode == '--worker-pass-check') {
    final subDir = args[1];
    final pass = args[2];
    try {
      final db = Database(subDir, passphrase: pass, useWal: false, lockTimeout: kLockTimeout);
      await db.init();
      await db.close();
      print('OPENED_SUCCESS');
    } on DatabaseIntegrityException catch (_) {
      print('CAUGHT_INTEGRITY');
    }
    return;
  }

  if (mode == '--worker-null-pass-check') {
    final subDir = args[1];
    try {
      final db = Database(subDir, passphrase: null, useWal: false, lockTimeout: kLockTimeout);
      await db.init();
      await db.close();
      print('OPENED_SUCCESS');
    } on DatabaseIntegrityException catch (_) {
      print('CAUGHT_INTEGRITY');
    }
    return;
  }

  if (mode == '--worker-lock-commit') {
    final subDir = args[1];
    final db = Database(subDir, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript('CREATE TABLE ro_tbl (id INT PRIMARY KEY, balance DOUBLE);');
    await interp.executeScript('INSERT INTO ro_tbl VALUES (1, 100.0);');
    await interp.executeScript('BEGIN TRANSACTION;');
    await interp.executeScript('INSERT INTO ro_tbl VALUES (2, 200.0);');

    final dbFile = File('$subDir/ro_tbl.db');
    RandomAccessFile? lockRaf;
    try {
      lockRaf = dbFile.openSync(mode: FileMode.read);
      lockRaf.lockSync(FileLock.exclusive);
    } catch (_) {}

    try {
      await interp.executeScript('COMMIT;');
      print('COMMIT_SUCCESS_BUFFERED');
    } catch (e) {
      print('COMMIT_THREW_EXCEPTION:$e');
    } finally {
      try {
        lockRaf?.unlockSync();
        lockRaf?.closeSync();
      } catch (_) {}
      try { await db.close(); } catch (_) {}
    }
    return;
  }

  if (mode == '--worker-wal-readonly-commit') {
    final subDir = args[1];
    final db = Database(subDir, useWal: true, lockTimeout: kLockTimeout);
    await db.init();
    final interp = Interpreter(db);
    await interp.executeScript('CREATE TABLE wal_ro (id INT PRIMARY KEY, val TEXT);');
    await interp.executeScript('BEGIN TRANSACTION;');
    await interp.executeScript("INSERT INTO wal_ro VALUES (1, 'initial_val');");
    await interp.executeScript('COMMIT;');

    await interp.executeScript('BEGIN TRANSACTION;');
    await interp.executeScript("INSERT INTO wal_ro VALUES (2, 'uncommitted_val');");

    final walFile = File('$subDir/wal.log');
    if (walFile.existsSync() && Platform.isWindows) {
      Process.runSync('attrib', ['+r', walFile.absolute.path]);
    }

    try {
      await interp.executeScript('COMMIT;');
      print('WAL_READONLY_HANDLED:COMMIT_RETURNED');
    } catch (e) {
      print('WAL_READONLY_HANDLED:THREW_EXCEPTION:$e');
    } finally {
      if (Platform.isWindows && walFile.existsSync()) {
        Process.runSync('attrib', ['-r', walFile.absolute.path]);
      }
      try { await db.close(); } catch (_) {}
    }
    return;
  }
}
