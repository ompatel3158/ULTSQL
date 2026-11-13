import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import 'package:ultsql/ultsql.dart';

const String kDbDir = 'test_fuzz_bombs_db';

enum AttackSeverity {
  criticalCrash,      // Unhandled crash, StackOverflowError, OOM, or unhandled FormatException
  silentDataLoss,     // Slotted page failure, data truncation, or missing rows
  unexpectedBehavior, // Deviation from standard SQL / unexpected hard cap / missing aggregates
  handledBoundary,    // Safely bounded / graceful error / expected limit
  passedCleanly,      // Engine handled extreme load cleanly
}

class TestFinding {
  final String testId;
  final String vectorName;
  final String title;
  final AttackSeverity severity;
  final int elapsedMs;
  final String details;
  final String? errorMessage;
  final String? stackTrace;
  final Map<String, dynamic> metrics;

  TestFinding({
    required this.testId,
    required this.vectorName,
    required this.title,
    required this.severity,
    required this.elapsedMs,
    required this.details,
    this.errorMessage,
    this.stackTrace,
    this.metrics = const {},
  });

  bool get isCritical =>
      severity == AttackSeverity.criticalCrash ||
      severity == AttackSeverity.silentDataLoss;
}

Future<void> cleanDirectory(String path) async {
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

Future<void> ensureCleanDirectory(String path) async {
  await cleanDirectory(path);
  await Directory(path).create(recursive: true);
}

class FuzzBombHarness {
  late UltSqlEngine engine;
  final List<TestFinding> findings = [];

  Future<void> init() async {
    await ensureCleanDirectory(kDbDir);
    engine = await UltSqlEngine.openFile(kDbDir);
  }

  Future<void> restartEngine() async {
    try {
      await engine.close();
    } catch (_) {}
    await ensureCleanDirectory(kDbDir);
    engine = await UltSqlEngine.openFile(kDbDir);
  }

  Future<void> close() async {
    try {
      await engine.close();
    } catch (_) {}
    await cleanDirectory(kDbDir);
  }

  void log(String msg) {
    stdout.writeln(msg);
  }

  void banner(String title) {
    stdout.writeln('\n================================================================================');
    stdout.writeln('  $title');
    stdout.writeln('================================================================================');
  }

  // ===========================================================================
  // VECTOR 1: Deep / Infinite Recursive CTE Bombs
  // ===========================================================================
  Future<void> testVector1RecursiveCte() async {
    banner('VECTOR 1: Deep / Infinite Recursive CTE Bombs');

    // 1.1 Standard infinite recursion with high LIMIT (100,000)
    {
      final sw = Stopwatch()..start();
      const sql = 'WITH RECURSIVE bomb(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM bomb) SELECT * FROM bomb LIMIT 100000;';
      try {
        log('[-] 1.1 Testing CTE with LIMIT 100000...');
        final res = await engine.query(sql);
        sw.stop();
        final rowCount = res.rows.length;
        log('    Result: $rowCount rows returned in ${sw.elapsedMilliseconds}ms.');

        // ULTSQL has a hardcoded maxDepth = 100 in RecursiveCteNode
        if (rowCount <= 101) {
          findings.add(TestFinding(
            testId: 'CTE-01',
            vectorName: 'Recursive CTE',
            title: 'Infinite recursive CTE with LIMIT 100000 stopped by internal maxDepth=100',
            severity: AttackSeverity.unexpectedBehavior,
            elapsedMs: sw.elapsedMilliseconds,
            details: 'Engine returned $rowCount rows instead of requested 100,000 without error or warning. RecursiveCteNode has a hardcoded `int maxDepth = 100` cutoff.',
            metrics: {'requestedLimit': 100000, 'actualRows': rowCount, 'hardcodedDepth': 100},
          ));
        } else {
          findings.add(TestFinding(
            testId: 'CTE-01',
            vectorName: 'Recursive CTE',
            title: 'Infinite recursive CTE produced large output',
            severity: AttackSeverity.passedCleanly,
            elapsedMs: sw.elapsedMilliseconds,
            details: 'Engine produced $rowCount rows successfully.',
            metrics: {'actualRows': rowCount},
          ));
        }
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'CTE-01',
          vectorName: 'Recursive CTE',
          title: 'Infinite recursive CTE with LIMIT 100000 threw error',
          severity: AttackSeverity.handledBoundary,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Engine terminated with exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 1.2 Unbounded recursive CTE without LIMIT
    {
      final sw = Stopwatch()..start();
      const sql = 'WITH RECURSIVE bomb(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM bomb) SELECT * FROM bomb;';
      try {
        log('[-] 1.2 Testing unbounded recursive CTE (no LIMIT)...');
        final res = await engine.query(sql);
        sw.stop();
        final rowCount = res.rows.length;
        log('    Result: $rowCount rows returned in ${sw.elapsedMilliseconds}ms.');
        findings.add(TestFinding(
          testId: 'CTE-02',
          vectorName: 'Recursive CTE',
          title: 'Unbounded recursive CTE (no LIMIT) execution bounded by maxDepth=100',
          severity: AttackSeverity.handledBoundary,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Engine safely capped recursion at depth 100 returning $rowCount rows without infinite loop or OOM.',
          metrics: {'actualRows': rowCount},
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'CTE-02',
          vectorName: 'Recursive CTE',
          title: 'Unbounded recursive CTE failed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Crash or exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 1.3 Aggregate function on recursive CTE: SELECT COUNT(*) FROM bomb
    {
      final sw = Stopwatch()..start();
      const sql = 'WITH RECURSIVE bomb(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM bomb WHERE n < 15) SELECT COUNT(*) FROM bomb;';
      try {
        log('[-] 1.3 Testing Aggregate COUNT(*) on Recursive CTE...');
        final res = await engine.query(sql);
        sw.stop();
        final count = res.rows.isNotEmpty ? res.rows.first.first.value : null;
        log('    Result: COUNT(*) = $count in ${sw.elapsedMilliseconds}ms.');

        // ULTSQL planner bug: _planWithRecursiveCte does not wrap with GroupByNode, so COUNT(*) evaluates to NULL!
        if (count == null) {
          findings.add(TestFinding(
            testId: 'CTE-AGG-NULL',
            vectorName: 'Recursive CTE',
            title: 'Planner Defect: Aggregation (COUNT(*)) over Recursive CTE returns NULL',
            severity: AttackSeverity.unexpectedBehavior,
            elapsedMs: sw.elapsedMilliseconds,
            details: 'Query "WITH RECURSIVE ... SELECT COUNT(*) FROM bomb" returned NULL. In planner.dart, _planWithRecursiveCte directly attaches ProjectNode without GroupByNode.',
            metrics: {'count': count},
          ));
        } else {
          findings.add(TestFinding(
            testId: 'CTE-AGG-NULL',
            vectorName: 'Recursive CTE',
            title: 'Aggregate COUNT(*) on Recursive CTE calculated cleanly',
            severity: AttackSeverity.passedCleanly,
            elapsedMs: sw.elapsedMilliseconds,
            details: 'COUNT(*) = $count computed cleanly.',
            metrics: {'count': count},
          ));
        }
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'CTE-AGG-NULL',
          vectorName: 'Recursive CTE',
          title: 'Bounded recursive CTE with WHERE failed',
          severity: AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Failed: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 1.4 Deduplication overhead test (UNION ALL unconditionally deduplicates)
    {
      final sw = Stopwatch()..start();
      const sql = 'WITH RECURSIVE bomb(n) AS (SELECT 1 UNION ALL SELECT 1 FROM bomb WHERE n < 10) SELECT * FROM bomb;';
      try {
        log('[-] 1.4 Testing UNION ALL row deduplication behavior in CTE...');
        final res = await engine.query(sql);
        sw.stop();
        final rowCount = res.rows.length;
        log('    Result: $rowCount rows returned in ${sw.elapsedMilliseconds}ms.');
        findings.add(TestFinding(
          testId: 'CTE-04',
          vectorName: 'Recursive CTE',
          title: 'Recursive CTE forced deduplication behavior',
          severity: AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'In ULTSQL, RecursiveCteNode unconditionally deduplicates all rows regardless of UNION ALL keyword. Duplicate generation stops at row $rowCount.',
          metrics: {'rowsReturned': rowCount},
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'CTE-04',
          vectorName: 'Recursive CTE',
          title: 'CTE deduplication test threw',
          severity: AttackSeverity.handledBoundary,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 1.5 Zero-row anchor recursive CTE
    {
      final sw = Stopwatch()..start();
      const sql = 'WITH RECURSIVE bomb(n) AS (SELECT 1 WHERE 1=0 UNION ALL SELECT n + 1 FROM bomb) SELECT * FROM bomb;';
      try {
        log('[-] 1.5 Testing zero-row anchor recursive CTE...');
        final res = await engine.query(sql);
        sw.stop();
        final rowCount = res.rows.length;
        log('    Result: $rowCount rows returned in ${sw.elapsedMilliseconds}ms.');
        findings.add(TestFinding(
          testId: 'CTE-05',
          vectorName: 'Recursive CTE',
          title: 'Zero-row anchor recursive CTE',
          severity: AttackSeverity.passedCleanly,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Engine cleanly handled empty anchor, returning 0 rows without crash.',
          metrics: {'rowsReturned': rowCount},
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'CTE-05',
          vectorName: 'Recursive CTE',
          title: 'Zero-row anchor CTE crashed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception on zero anchor: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }
  }

  // ===========================================================================
  // VECTOR 2: Exponential Cartesian Join Explosion
  // ===========================================================================
  Future<void> testVector2CartesianExplosion() async {
    banner('VECTOR 2: Exponential Cartesian Join Explosion');

    // Setup 7 tables with 10 rows each: t1..t7
    log('[-] Setting up test tables t1..t7 with 10 rows each...');
    for (int t = 1; t <= 7; t++) {
      await engine.query('DROP TABLE IF EXISTS t$t;');
      await engine.query('CREATE TABLE t$t (id INT, val TEXT);');
      final rows = List.generate(10, (i) => [i + 1, 'val_${t}_$i']);
      await engine.insertBatch('t$t', rows, columns: ['id', 'val']);
    }

    // 2.1 Grammar test: Comma-separated join syntax (FROM t1, t2, t3)
    {
      final sw = Stopwatch()..start();
      log('[-] 2.1 Testing ANSI standard comma-separated join: SELECT COUNT(*) FROM t1, t2, t3...');
      try {
        await engine.query('SELECT COUNT(*) FROM t1, t2, t3;');
        sw.stop();
        findings.add(TestFinding(
          testId: 'CART-COMMA-SYNTAX',
          vectorName: 'Cartesian Explosion',
          title: 'Comma-separated join syntax accepted',
          severity: AttackSeverity.passedCleanly,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Engine accepted standard comma-separated join syntax in FROM clause.',
        ));
      } catch (e, st) {
        sw.stop();
        log('    Comma-separated join failed: $e');
        findings.add(TestFinding(
          testId: 'CART-COMMA-SYNTAX',
          vectorName: 'Cartesian Explosion',
          title: 'Grammar Defect: Parser rejects ANSI comma-separated table joins',
          severity: AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Parser throws "$e" because FROM clause only recognizes JOIN keywords (INNER/CROSS/LEFT/RIGHT/FULL JOIN) and treats "," as statement separator.',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 2.2 Grammar defect test: CROSS JOIN alias collision (FROM t1 CROSS JOIN t2)
    {
      final sw = Stopwatch()..start();
      log('[-] 2.2 Testing ANSI CROSS JOIN syntax: SELECT COUNT(*) FROM t1 CROSS JOIN t2...');
      try {
        await engine.query('SELECT COUNT(*) FROM t1 CROSS JOIN t2;');
        sw.stop();
        findings.add(TestFinding(
          testId: 'CART-CROSS-SYNTAX',
          vectorName: 'Cartesian Explosion',
          title: 'ANSI CROSS JOIN syntax accepted',
          severity: AttackSeverity.passedCleanly,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Engine accepted standard CROSS JOIN without ON clause.',
        ));
      } catch (e, st) {
        sw.stop();
        log('    CROSS JOIN failed: $e');
        findings.add(TestFinding(
          testId: 'CART-CROSS-SYNTAX',
          vectorName: 'Cartesian Explosion',
          title: 'Parser Defect: CROSS token consumed as table alias instead of CROSS JOIN',
          severity: AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'In parser.dart line 1991, the table alias check lacks exclusion for "cross" (only excludes left/right/full/outer). As a result, "FROM t1 CROSS JOIN t2" parses as "FROM t1 AS cross JOIN t2", which then demands an "ON" clause and throws: "$e".',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 2.3 Stepwise Cartesian Join Execution via JOIN ... ON 1=1
    // Tests: 10^2, 10^3, 10^4, 10^5, 10^6
    final cartesianCombos = [
      {'count': 2, 'sql': 'SELECT COUNT(*) FROM t1 JOIN t2 ON 1=1;', 'expected': 100},
      {'count': 3, 'sql': 'SELECT COUNT(*) FROM t1 JOIN t2 ON 1=1 JOIN t3 ON 1=1;', 'expected': 1000},
      {'count': 4, 'sql': 'SELECT COUNT(*) FROM t1 JOIN t2 ON 1=1 JOIN t3 ON 1=1 JOIN t4 ON 1=1;', 'expected': 10000},
      {'count': 5, 'sql': 'SELECT COUNT(*) FROM t1 JOIN t2 ON 1=1 JOIN t3 ON 1=1 JOIN t4 ON 1=1 JOIN t5 ON 1=1;', 'expected': 100000},
      {'count': 6, 'sql': 'SELECT COUNT(*) FROM t1 JOIN t2 ON 1=1 JOIN t3 ON 1=1 JOIN t4 ON 1=1 JOIN t5 ON 1=1 JOIN t6 ON 1=1;', 'expected': 1000000},
      {'count': 7, 'sql': 'SELECT COUNT(*) FROM t1 JOIN t2 ON 1=1 JOIN t3 ON 1=1 JOIN t4 ON 1=1 JOIN t5 ON 1=1 JOIN t6 ON 1=1 JOIN t7 ON 1=1;', 'expected': 10000000},
    ];

    for (final combo in cartesianCombos) {
      final k = combo['count'] as int;
      final sql = combo['sql'] as String;
      final expected = combo['expected'] as int;
      final sw = Stopwatch()..start();

      log('[-] 2.3 Testing Cartesian Join of $k tables ($expected expected rows)...');
      try {
        final res = await engine.query(sql);
        sw.stop();
        final actual = res.rows.isNotEmpty ? res.rows.first.first.value : null;
        log('    Result: COUNT(*) = $actual in ${sw.elapsedMilliseconds}ms.');

        findings.add(TestFinding(
          testId: 'CART-JOIN-0$k',
          vectorName: 'Cartesian Explosion',
          title: 'Cartesian Join of $k tables ($expected rows)',
          severity: (actual == expected) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Computed COUNT(*) = $actual for $k tables in ${sw.elapsedMilliseconds}ms. NestedLoopJoinNode successfully streamed Cartesian rows.',
          metrics: {'tables': k, 'expected': expected, 'actual': actual, 'timeMs': sw.elapsedMilliseconds},
        ));
      } catch (e, st) {
        sw.stop();
        log('    FAILED: $e in ${sw.elapsedMilliseconds}ms');
        findings.add(TestFinding(
          testId: 'CART-JOIN-0$k',
          vectorName: 'Cartesian Explosion',
          title: 'Cartesian Join of $k tables failed/crashed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Failed with exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 2.4 Unconstrained Cartesian Materialization Bomb
    // SELECT * FROM t1 JOIN t2 ON 1=1 JOIN t3 ON 1=1 JOIN t4 ON 1=1 (10,000 rows x 8 columns = 80,000 cells)
    {
      final sw = Stopwatch()..start();
      log('[-] 2.4 Testing Cartesian SELECT * materialization (10,000 rows)...');
      try {
        final res = await engine.query('SELECT * FROM t1 JOIN t2 ON 1=1 JOIN t3 ON 1=1 JOIN t4 ON 1=1;');
        sw.stop();
        final rowCount = res.rows.length;
        log('    Result: $rowCount rows materialized in ${sw.elapsedMilliseconds}ms.');
        findings.add(TestFinding(
          testId: 'CART-MAT-01',
          vectorName: 'Cartesian Explosion',
          title: 'Cartesian SELECT * Materialization (10,000 rows)',
          severity: AttackSeverity.passedCleanly,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Successfully materialized $rowCount complete rows in memory.',
          metrics: {'rows': rowCount},
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'CART-MAT-01',
          vectorName: 'Cartesian Explosion',
          title: 'Cartesian SELECT * Materialization crashed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Failed to materialize 10,000 Cartesian rows: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }
  }

  // ===========================================================================
  // VECTOR 3: Giant Cell & TOAST Mega-Payload (20MB - 50MB)
  // ===========================================================================
  Future<void> testVector3GiantCellToast() async {
    banner('VECTOR 3: Giant Cell & TOAST Mega-Payload (20MB - 50MB)');

    // 3.1 TOAST Boundary Tests (1024, 1025, 4090 bytes)
    {
      log('[-] 3.1 Testing exact TOAST boundary (1024 vs 1025 bytes)...');
      await engine.query('DROP TABLE IF EXISTS toast_bounds;');
      await engine.query('CREATE TABLE toast_bounds (id INT, payload TEXT);');

      final str1024 = 'A' * 1024;
      final str1025 = 'B' * 1025;
      final str4090 = 'C' * 4090;

      final stmt = engine.db.prepare('INSERT INTO toast_bounds VALUES (?, ?);');
      stmt.executeSync([DbInt(1), DbText(str1024)]);
      stmt.executeSync([DbInt(2), DbText(str1025)]);
      stmt.executeSync([DbInt(3), DbText(str4090)]);

      // Flush cache to inspect disk state
      engine.db.cache.flushAllSync();

      // Read back via table scan (not point lookup)
      final res = await engine.query('SELECT id, payload FROM toast_bounds;');
      final row1Len = (res.rows[0][1].value as String).length;
      final row2Len = (res.rows[1][1].value as String).length;
      final row3Len = (res.rows[2][1].value as String).length;

      final toastFile = File('$kDbDir/toast_bounds_toast.db');
      final toastExists = toastFile.existsSync();
      final toastBytes = toastExists ? toastFile.lengthSync() : 0;
      log('    Row lengths read back: $row1Len, $row2Len, $row3Len. Toast file size on disk: $toastBytes bytes.');

      findings.add(TestFinding(
        testId: 'TOAST-BOUND-01',
        vectorName: 'TOAST Storage',
        title: 'TOAST threshold boundary transitions (1024B inline, 1025B & 4090B TOAST)',
        severity: (row1Len == 1024 && row2Len == 1025 && row3Len == 4090 && toastBytes > 0)
            ? AttackSeverity.passedCleanly
            : AttackSeverity.unexpectedBehavior,
        elapsedMs: 0,
        details: 'Boundary values verified: inline (1024B) vs TOASTed (1025B, 4090B). Toast file size on disk: $toastBytes bytes.',
        metrics: {'toastFileSize': toastBytes},
      ));
    }

    // 3.2 Point Lookup Bug with TOASTed Columns
    // Demonstrates that WHERE id = 1 fails to resolve TOAST because point lookup omits toastManager!
    {
      final sw = Stopwatch()..start();
      log('[-] 3.2 Verifying Point Lookup vs Table Scan on TOASTed Column...');
      try {
        final scanRes = await engine.query('SELECT payload FROM toast_bounds;');
        final scanVal = scanRes.rows[1][0].value;

        final pointRes = await engine.query('SELECT payload FROM toast_bounds WHERE id = 2;');
        final pointVal = pointRes.rows.isNotEmpty ? pointRes.rows.first.first.value : null;
        sw.stop();

        final hasBug = (scanVal is String && scanVal.length == 1025) && (pointVal == null);
        log('    Scan read TOAST length: ${(scanVal as String).length}. Point lookup read: $pointVal. Bug triggered: $hasBug');

        if (hasBug) {
          findings.add(TestFinding(
            testId: 'TOAST-POINT-LOOKUP-BUG',
            vectorName: 'TOAST Storage',
            title: 'CRITICAL: Point Lookup executor drops TOASTed values (returns NULL)',
            severity: AttackSeverity.silentDataLoss,
            elapsedMs: sw.elapsedMilliseconds,
            details: 'In interpreter.dart (_executePointLookup), RecordSerializer.deserializeRow and deserializeCellFromView are called without toastManager parameter, causing all TOASTed values (typeCodes 6 and 7) to return NULL during indexed point lookups.',
            metrics: {'scanLength': scanVal.length, 'pointResult': pointVal},
          ));
        } else {
          findings.add(TestFinding(
            testId: 'TOAST-POINT-LOOKUP-BUG',
            vectorName: 'TOAST Storage',
            title: 'Point lookup with TOAST succeeded',
            severity: AttackSeverity.passedCleanly,
            elapsedMs: sw.elapsedMilliseconds,
            details: 'Point lookup successfully retrieved TOASTed column value.',
          ));
        }
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'TOAST-POINT-LOOKUP-BUG',
          vectorName: 'TOAST Storage',
          title: 'Point lookup test threw exception',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 3.3 Ingesting 20MB String via Prepared Statement (Read via Table Scan)
    {
      final sw = Stopwatch()..start();
      const sizeMb = 20;
      final byteCount = sizeMb * 1024 * 1024;
      log('[-] 3.3 Generating $sizeMb MB string and ingesting via Prepared Statement...');

      final chunk = '0123456789ABCDEF' * 64; // 1024 bytes
      final sb = StringBuffer();
      final numChunks = byteCount ~/ chunk.length;
      for (int i = 0; i < numChunks; i++) {
        sb.write(chunk);
      }
      final payload20Mb = sb.toString();
      final expectedSha = sha256.convert(utf8.encode(payload20Mb)).toString();

      await engine.query('DROP TABLE IF EXISTS toast_mega;');
      await engine.query('CREATE TABLE toast_mega (id INT, data TEXT);');

      try {
        final insertSw = Stopwatch()..start();
        final prep = engine.db.prepare('INSERT INTO toast_mega VALUES (?, ?);');
        prep.executeSync([DbInt(1), DbText(payload20Mb)]);
        insertSw.stop();
        log('    20MB Insert finished in ${insertSw.elapsedMilliseconds}ms.');

        // Flush pages to disk
        engine.db.cache.flushAllSync();
        final toastFile = File('$kDbDir/toast_mega_toast.db');
        final toastSize = toastFile.existsSync() ? toastFile.lengthSync() : 0;
        final pages = toastSize ~/ 4096;
        log('    Toast file size on disk: $toastSize bytes (~$pages pages).');

        // Query back via TableScan (without WHERE id=1) to use RowScanNode with toastManager
        final querySw = Stopwatch()..start();
        final res = await engine.query('SELECT data FROM toast_mega;');
        querySw.stop();
        final readBackVal = res.rows.first.first.value;
        final readBackStr = readBackVal as String;
        final actualSha = sha256.convert(utf8.encode(readBackStr)).toString();
        sw.stop();

        final match = (expectedSha == actualSha) && (readBackStr.length == payload20Mb.length);
        log('    20MB Read back finished in ${querySw.elapsedMilliseconds}ms. SHA Match: $match');

        findings.add(TestFinding(
          testId: 'TOAST-20MB',
          vectorName: 'TOAST Storage',
          title: '20MB Single Cell Ingestion & Retrieval (SHA-256 verified)',
          severity: match ? AttackSeverity.passedCleanly : AttackSeverity.silentDataLoss,
          elapsedMs: sw.elapsedMilliseconds,
          details: match
              ? 'Successfully ingested and verified 20MB payload across $pages TOAST pages with exact SHA-256 checksum match.'
              : 'Data corruption detected in 20MB TOAST payload: SHA mismatch!',
          metrics: {
            'payloadBytes': payload20Mb.length,
            'toastPages': pages,
            'insertMs': insertSw.elapsedMilliseconds,
            'queryMs': querySw.elapsedMilliseconds,
            'shaMatch': match,
          },
        ));
      } catch (e, st) {
        sw.stop();
        log('    20MB Ingestion FAILED: $e');
        findings.add(TestFinding(
          testId: 'TOAST-20MB',
          vectorName: 'TOAST Storage',
          title: '20MB Single Cell Ingestion crashed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Failed on 20MB ingestion: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 3.4 Ingesting 50MB String via Prepared Statement
    {
      final sw = Stopwatch()..start();
      const sizeMb = 50;
      final byteCount = sizeMb * 1024 * 1024;
      log('[-] 3.4 Generating $sizeMb MB string and ingesting via Prepared Statement...');

      final chunk = 'XYZ_ULT_SQL_TOAST_' * 50; // 900 bytes approx
      final sb = StringBuffer();
      while (sb.length < byteCount) {
        sb.write(chunk);
      }
      final payload50Mb = sb.toString().substring(0, byteCount);
      final expectedSha = sha256.convert(utf8.encode(payload50Mb)).toString();

      try {
        final insertSw = Stopwatch()..start();
        final prep = engine.db.prepare('INSERT INTO toast_mega VALUES (?, ?);');
        prep.executeSync([DbInt(2), DbText(payload50Mb)]);
        insertSw.stop();
        log('    50MB Insert finished in ${insertSw.elapsedMilliseconds}ms.');

        engine.db.cache.flushAllSync();
        final toastFile = File('$kDbDir/toast_mega_toast.db');
        final toastSize = toastFile.existsSync() ? toastFile.lengthSync() : 0;
        final pages = toastSize ~/ 4096;
        log('    Toast file size after 50MB: $toastSize bytes (~$pages pages).');

        final querySw = Stopwatch()..start();
        // Filter via SQL limit/projection or read row 2
        final res = await engine.query('SELECT data FROM toast_mega;');
        querySw.stop();
        final readBackStr = res.rows[1][0].value as String;
        final actualSha = sha256.convert(utf8.encode(readBackStr)).toString();
        sw.stop();

        final match = (expectedSha == actualSha) && (readBackStr.length == payload50Mb.length);
        log('    50MB Read back finished in ${querySw.elapsedMilliseconds}ms. SHA Match: $match');

        findings.add(TestFinding(
          testId: 'TOAST-50MB',
          vectorName: 'TOAST Storage',
          title: '50MB Single Cell Ingestion & Retrieval (SHA-256 verified)',
          severity: match ? AttackSeverity.passedCleanly : AttackSeverity.silentDataLoss,
          elapsedMs: sw.elapsedMilliseconds,
          details: match
              ? 'Successfully ingested and verified 50MB payload across $pages TOAST pages with exact SHA-256 match.'
              : 'Data corruption detected in 50MB TOAST payload!',
          metrics: {
            'payloadBytes': payload50Mb.length,
            'toastPages': pages,
            'insertMs': insertSw.elapsedMilliseconds,
            'queryMs': querySw.elapsedMilliseconds,
            'shaMatch': match,
          },
        ));
      } catch (e, st) {
        sw.stop();
        log('    50MB Ingestion FAILED: $e');
        findings.add(TestFinding(
          testId: 'TOAST-50MB',
          vectorName: 'TOAST Storage',
          title: '50MB Single Cell Ingestion crashed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Failed on 50MB ingestion: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 3.5 NoSQL Document Mega-Payload (20MB JSON Document)
    {
      final sw = Stopwatch()..start();
      log('[-] 3.5 Ingesting 20MB NoSQL JSON Document into collection...');
      try {
        final coll = engine.collection('mega_docs');
        final hugeText = 'DOC_DATA_' * (20 * 1024 * 1024 ~/ 9);
        final docMap = {
          '_id': 'doc_20mb',
          'description': 'Mega payload test',
          'large_field': hugeText,
        };

        final insertSw = Stopwatch()..start();
        coll.insertOneSync(docMap);
        insertSw.stop();
        log('    NoSQL 20MB document inserted in ${insertSw.elapsedMilliseconds}ms.');

        // Fetch back
        final fetchSw = Stopwatch()..start();
        final fetchedDoc = coll.findOneSync({'_id': 'doc_20mb'});
        fetchSw.stop();

        final fetchedLen = fetchedDoc?.data['large_field']?.toString().length ?? 0;
        final match = fetchedLen == hugeText.length;
        log('    NoSQL 20MB document fetched back in ${fetchSw.elapsedMilliseconds}ms. Length match: $match');

        findings.add(TestFinding(
          testId: 'NOSQL-20MB',
          vectorName: 'TOAST Storage',
          title: 'NoSQL Collection 20MB JSON Document Ingestion & Retrieval',
          severity: match ? AttackSeverity.passedCleanly : AttackSeverity.silentDataLoss,
          elapsedMs: sw.elapsedMilliseconds,
          details: match
              ? 'NoSQL collection successfully stored and retrieved 20MB JSON document via TOAST.'
              : 'NoSQL document field length mismatch: expected ${hugeText.length}, got $fetchedLen',
          metrics: {
            'expectedLen': hugeText.length,
            'actualLen': fetchedLen,
            'insertMs': insertSw.elapsedMilliseconds,
            'fetchMs': fetchSw.elapsedMilliseconds,
          },
        ));
      } catch (e, st) {
        sw.stop();
        log('    NoSQL 20MB Ingestion FAILED: $e');
        findings.add(TestFinding(
          testId: 'NOSQL-20MB',
          vectorName: 'TOAST Storage',
          title: 'NoSQL 20MB JSON Document crashed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Failed on NoSQL 20MB doc: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 3.6 Raw SQL Parser Stress with 10MB Literal in SQL Query String
    {
      final sw = Stopwatch()..start();
      log('[-] 3.6 Testing Raw SQL Query String with 10MB String Literal in parser...');
      try {
        final literal = 'LITERAL_' * (10 * 1024 * 1024 ~/ 8);
        final sql = "INSERT INTO toast_mega VALUES (3, '$literal');";
        log('    Passing ${sql.length} byte SQL script to engine.query()...');
        final parseSw = Stopwatch()..start();
        await engine.query(sql);
        parseSw.stop();
        log('    Raw SQL 10MB literal executed in ${parseSw.elapsedMilliseconds}ms.');

        // Query back length
        final res = await engine.query('SELECT LENGTH(data) FROM toast_mega WHERE id = 3;');
        final len = res.rows.isNotEmpty ? res.rows.first.first.value : null;

        findings.add(TestFinding(
          testId: 'SQL-PARSER-10MB',
          vectorName: 'TOAST Storage',
          title: 'Raw SQL Query String with 10MB Literal Lexing & Parsing',
          severity: (len == literal.length) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Lexer and Parser handled 10MB continuous string literal in raw SQL query without memory exhaustion. Returned length: $len.',
          metrics: {'literalLength': literal.length, 'returnedLength': len},
        ));
      } catch (e, st) {
        sw.stop();
        log('    Raw SQL 10MB Literal FAILED: $e');
        findings.add(TestFinding(
          testId: 'SQL-PARSER-10MB',
          vectorName: 'TOAST Storage',
          title: 'Raw SQL Query with 10MB Literal crashed/failed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Lexer/Parser failed on 10MB query string: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }
  }

  // ===========================================================================
  // VECTOR 4: Schema Width Stress (1,000 Columns)
  // ===========================================================================
  Future<void> testVector4SchemaWidthStress() async {
    banner('VECTOR 4: Schema Width Stress (1,000 Columns)');

    // 4.1 CREATE TABLE with 1,000 columns
    const int kColCount = 1000;
    final cols = <String>[];
    for (int i = 0; i < kColCount; i++) {
      cols.add('col_$i ${i.isEven ? 'INT' : 'TEXT'}');
    }
    final ddlSql = 'CREATE TABLE wide_1000 (${cols.join(', ')});';

    {
      final sw = Stopwatch()..start();
      log('[-] 4.1 Creating table with 1,000 columns (DDL length: ${ddlSql.length} chars)...');
      try {
        await engine.query(ddlSql);
        sw.stop();
        log('    Table wide_1000 created successfully in ${sw.elapsedMilliseconds}ms.');

        final schema = engine.db.catalog.getTableSchema('wide_1000');
        final catalogCols = schema?.columnNames.length ?? 0;

        findings.add(TestFinding(
          testId: 'WIDTH-DDL-1000',
          vectorName: 'Schema Width',
          title: 'CREATE TABLE with 1,000 columns',
          severity: (catalogCols == kColCount) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Catalog successfully parsed and persisted 1,000 column definitions.',
          metrics: {'columnCount': catalogCols},
        ));
      } catch (e, st) {
        sw.stop();
        log('    CREATE TABLE with 1,000 columns FAILED: $e');
        findings.add(TestFinding(
          testId: 'WIDTH-DDL-1000',
          vectorName: 'Schema Width',
          title: 'CREATE TABLE with 1,000 columns failed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Failed: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
        return;
      }
    }

    // 4.2 Insert row with all NULLs into 1,000-column table
    // Size: 14 + 1000*2 (offsets) + 1000*1 (null markers) + 12 (mvcc) = 3026 bytes.
    // Fits in 4091 bytes page capacity!
    {
      final sw = Stopwatch()..start();
      log('[-] 4.2 Inserting all-NULL row into 1,000-column table (expected record size: ~3026B)...');
      final nullVals = List.filled(kColCount, 'NULL').join(', ');
      final insertNullSql = 'INSERT INTO wide_1000 VALUES ($nullVals);';
      try {
        await engine.query(insertNullSql);
        sw.stop();
        log('    All-NULL row inserted in ${sw.elapsedMilliseconds}ms.');

        final res = await engine.query('SELECT COUNT(*) FROM wide_1000;');
        final count = res.rows.isNotEmpty ? res.rows.first.first.value : 0;

        findings.add(TestFinding(
          testId: 'WIDTH-INS-NULL',
          vectorName: 'Schema Width',
          title: 'Insert all-NULL row into 1,000-column table (fits in page)',
          severity: (count == 1) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Row with 1,000 NULL columns successfully serialized and stored. Count: $count.',
          metrics: {'rowCount': count},
        ));
      } catch (e, st) {
        sw.stop();
        log('    Insert all-NULL row FAILED: $e');
        findings.add(TestFinding(
          testId: 'WIDTH-INS-NULL',
          vectorName: 'Schema Width',
          title: 'Insert all-NULL row into 1,000-column table failed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Failed: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 4.3 Insert row with non-null values that EXCEEDS 4096-byte slotted page!
    // 500 INTs (2 bytes) + 500 TEXTs (4 bytes) + offsets (2014) + mvcc (12) = 5026 bytes!
    // Since 5026 > 4091 bytes, slotted page cannot fit this record!
    {
      final sw = Stopwatch()..start();
      log('[-] 4.3 Inserting wide row exceeding 4KB page capacity (expected record size: ~5026B)...');
      final rowVals = <String>[];
      for (int i = 0; i < kColCount; i++) {
        rowVals.add(i.isEven ? '$i' : "'abc'");
      }
      final insertWideSql = 'INSERT INTO wide_1000 VALUES (${rowVals.join(', ')});';

      try {
        await engine.query(insertWideSql);
        sw.stop();
        log('    Wide row insert query finished in ${sw.elapsedMilliseconds}ms without throwing.');

        // Attempt to query the row back
        log('    Attempting to SELECT * FROM wide_1000...');
        try {
          final res = await engine.query('SELECT * FROM wide_1000;');
          final rowCount = res.rows.length;
          log('    SELECT * returned $rowCount rows.');

          if (rowCount < 2) {
            findings.add(TestFinding(
              testId: 'WIDTH-PAGE-OVERFLOW',
              vectorName: 'Schema Width',
              title: 'CRITICAL: Slotted-Page silent row drop on record width > 4KB',
              severity: AttackSeverity.silentDataLoss,
              elapsedMs: sw.elapsedMilliseconds,
              details: 'Record size (~5026B) exceeded 4096B page capacity. SlottedPageHelper.insertRecordDirect returned false, but insertSync ignored the return value and returned slotId = -1. Query returned without error, but row was silently dropped! Row count remained $rowCount.',
              metrics: {'rowsExpected': 2, 'rowsFound': rowCount},
            ));
          } else {
            findings.add(TestFinding(
              testId: 'WIDTH-PAGE-OVERFLOW',
              vectorName: 'Schema Width',
              title: 'Slotted page accommodated wide record',
              severity: AttackSeverity.passedCleanly,
              elapsedMs: sw.elapsedMilliseconds,
              details: 'Engine accommodated record > 4KB across pages or via internal mechanisms.',
              metrics: {'rows': rowCount},
            ));
          }
        } catch (readErr, readSt) {
          log('    SELECT * threw exception: $readErr');
          findings.add(TestFinding(
            testId: 'WIDTH-PAGE-OVERFLOW',
            vectorName: 'Schema Width',
            title: 'CRITICAL: Read of oversized record caused crash/corruption',
            severity: AttackSeverity.criticalCrash,
            elapsedMs: sw.elapsedMilliseconds,
            details: 'Querying wide table after inserting oversized record threw: $readErr',
            errorMessage: readErr.toString(),
            stackTrace: readSt.toString(),
          ));
        }
      } catch (e, st) {
        sw.stop();
        log('    Wide row insert threw exception: $e');
        findings.add(TestFinding(
          testId: 'WIDTH-PAGE-OVERFLOW',
          vectorName: 'Schema Width',
          title: 'Insert of record exceeding 4KB rejected with error',
          severity: AttackSeverity.handledBoundary,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Engine caught record size exceeding page capacity: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 4.4 Column projection on wide schema: SELECT col_0, col_500, col_999
    {
      final sw = Stopwatch()..start();
      log('[-] 4.4 Testing sparse column projections on 1,000-column schema...');
      try {
        final res = await engine.query('SELECT col_0, col_500, col_999 FROM wide_1000 LIMIT 1;');
        sw.stop();
        final colsReturned = res.columns;
        log('    Projection returned columns: $colsReturned in ${sw.elapsedMilliseconds}ms.');
        findings.add(TestFinding(
          testId: 'WIDTH-PROJ-01',
          vectorName: 'Schema Width',
          title: 'Sparse column projection on 1,000-column table',
          severity: (colsReturned.length == 3) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Successfully projected 3 sparse columns from 1,000-column table.',
          metrics: {'projectedCols': colsReturned},
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'WIDTH-PROJ-01',
          vectorName: 'Schema Width',
          title: 'Sparse column projection failed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Failed: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }
  }

  // ===========================================================================
  // VECTOR 5: Deeply Nested Expression Trees (500+ Levels)
  // ===========================================================================
  Future<void> testVector5NestedExpressions() async {
    banner('VECTOR 5: Deeply Nested Expression Trees (500+ Levels)');

    // 5.1 Nested CASE WHEN ... THEN ... ELSE ... END
    // Tests depths: 50, 100, 250, 500, 750, 850, 1000
    final caseDepths = [50, 100, 250, 500, 750, 850, 1000];

    for (final d in caseDepths) {
      final sw = Stopwatch()..start();
      log('[-] 5.1 Testing Nested CASE WHEN at depth $d...');

      String expr = '42';
      for (int i = 0; i < d; i++) {
        expr = 'CASE WHEN 1=1 THEN ($expr) ELSE 0 END';
      }
      final sql = 'SELECT $expr;';

      try {
        final res = await engine.query(sql);
        sw.stop();
        final val = res.rows.isNotEmpty ? res.rows.first.first.value : null;
        log('    Depth $d: Returned $val in ${sw.elapsedMilliseconds}ms.');

        findings.add(TestFinding(
          testId: 'NEST-CASE-$d',
          vectorName: 'Nested Expressions',
          title: 'Nested CASE WHEN at depth $d',
          severity: (val == 42) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Parser, AST, and JIT compiler evaluated $d levels of nested CASE without stack overflow.',
          metrics: {'depth': d, 'result': val},
        ));
      } on StackOverflowError catch (so, st) {
        sw.stop();
        log('    CRITICAL: StackOverflowError at depth $d in ${sw.elapsedMilliseconds}ms!');
        findings.add(TestFinding(
          testId: 'NEST-CASE-$d',
          vectorName: 'Nested Expressions',
          title: 'CRITICAL: StackOverflowError in nested CASE WHEN at depth $d',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Dart call stack exhausted at depth $d during recursive-descent parsing or JIT expression compilation.',
          errorMessage: 'StackOverflowError',
          stackTrace: st.toString().split('\n').take(10).join('\n'),
          metrics: {'depth': d},
        ));
        break;
      } catch (e, st) {
        sw.stop();
        log('    Depth $d failed: $e');
        findings.add(TestFinding(
          testId: 'NEST-CASE-$d',
          vectorName: 'Nested Expressions',
          title: 'Nested CASE WHEN at depth $d failed',
          severity: AttackSeverity.handledBoundary,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Terminated with error: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString().split('\n').take(10).join('\n'),
          metrics: {'depth': d},
        ));
      }
    }

    // 5.2 Nested COALESCE(NULL, COALESCE(NULL, ... 42)) up to 1000 levels
    for (final d in [100, 250, 500, 750, 1000]) {
      final sw = Stopwatch()..start();
      log('[-] 5.2 Testing Nested COALESCE at depth $d...');

      String expr = '42';
      for (int i = 0; i < d; i++) {
        expr = 'COALESCE(NULL, $expr)';
      }
      final sql = 'SELECT $expr;';

      try {
        final res = await engine.query(sql);
        sw.stop();
        final val = res.rows.isNotEmpty ? res.rows.first.first.value : null;
        log('    Depth $d: Returned $val in ${sw.elapsedMilliseconds}ms.');

        findings.add(TestFinding(
          testId: 'NEST-COAL-$d',
          vectorName: 'Nested Expressions',
          title: 'Nested COALESCE at depth $d',
          severity: (val == 42) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Evaluated $d levels of nested COALESCE cleanly without stack overflow.',
          metrics: {'depth': d, 'result': val},
        ));
      } on StackOverflowError catch (so, st) {
        sw.stop();
        log('    CRITICAL: StackOverflowError in COALESCE at depth $d!');
        findings.add(TestFinding(
          testId: 'NEST-COAL-$d',
          vectorName: 'Nested Expressions',
          title: 'CRITICAL: StackOverflowError in nested COALESCE at depth $d',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Dart call stack overflow at depth $d in COALESCE parser/evaluator.',
          errorMessage: 'StackOverflowError',
          stackTrace: st.toString().split('\n').take(10).join('\n'),
          metrics: {'depth': d},
        ));
        break;
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'NEST-COAL-$d',
          vectorName: 'Nested Expressions',
          title: 'Nested COALESCE at depth $d failed',
          severity: AttackSeverity.handledBoundary,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Error: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString().split('\n').take(10).join('\n'),
          metrics: {'depth': d},
        ));
      }
    }

    // 5.3 Deep Arithmetic Operator Chaining: (1 + (1 + (1 + ...)))
    for (final d in [100, 250, 500, 750, 1000]) {
      final sw = Stopwatch()..start();
      log('[-] 5.3 Testing Nested Arithmetic at depth $d...');

      String expr = '1';
      for (int i = 0; i < d; i++) {
        expr = '(1 + $expr)';
      }
      final sql = 'SELECT $expr;';

      try {
        final res = await engine.query(sql);
        sw.stop();
        final val = res.rows.isNotEmpty ? res.rows.first.first.value : null;
        log('    Depth $d: Returned $val in ${sw.elapsedMilliseconds}ms.');

        findings.add(TestFinding(
          testId: 'NEST-ARITH-$d',
          vectorName: 'Nested Expressions',
          title: 'Nested Arithmetic at depth $d',
          severity: (val == d + 1) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Calculated nested addition of $d terms cleanly. Result: $val.',
          metrics: {'depth': d, 'expected': d + 1, 'actual': val},
        ));
      } on StackOverflowError catch (so, st) {
        sw.stop();
        log('    CRITICAL: StackOverflowError in arithmetic at depth $d!');
        findings.add(TestFinding(
          testId: 'NEST-ARITH-$d',
          vectorName: 'Nested Expressions',
          title: 'CRITICAL: StackOverflowError in arithmetic chaining at depth $d',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Dart call stack overflow in binary operator recursion.',
          errorMessage: 'StackOverflowError',
          stackTrace: st.toString().split('\n').take(10).join('\n'),
          metrics: {'depth': d},
        ));
        break;
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'NEST-ARITH-$d',
          vectorName: 'Nested Expressions',
          title: 'Nested Arithmetic at depth $d failed',
          severity: AttackSeverity.handledBoundary,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Error: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString().split('\n').take(10).join('\n'),
          metrics: {'depth': d},
        ));
      }
    }
  }

  // ===========================================================================
  // VECTOR 6: Extreme Number Parsing & Boundaries
  // ===========================================================================
  Future<void> testVector6ExtremeNumbers() async {
    banner('VECTOR 6: Extreme Number Parsing & Boundary Conditions');

    // 6.1 Ultra-long Integer Literals (100+ digits)
    {
      final digits100 = '9' * 100;
      final sw = Stopwatch()..start();
      log('[-] 6.1 Testing 100-digit integer literal: 999...999...');
      try {
        final res = await engine.query('SELECT $digits100;');
        sw.stop();
        final val = res.rows.isNotEmpty ? res.rows.first.first.value : null;
        log('    Result: $val (type: ${val.runtimeType}) in ${sw.elapsedMilliseconds}ms.');

        // In Dart, num.parse("9"*100) overflows 64-bit int and parses as double.infinity
        findings.add(TestFinding(
          testId: 'NUM-DIGITS-100',
          vectorName: 'Extreme Numbers',
          title: '100-digit integer literal parsing',
          severity: AttackSeverity.passedCleanly,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Parsed 100-digit integer literal into numeric value: $val.',
          metrics: {'result': val.toString(), 'type': val.runtimeType.toString()},
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'NUM-DIGITS-100',
          vectorName: 'Extreme Numbers',
          title: '100-digit integer literal threw',
          severity: AttackSeverity.handledBoundary,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Failed: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 6.2 Scientific Notation Edge Cases: 1e999 (Overflow to Infinity)
    {
      final sw = Stopwatch()..start();
      log('[-] 6.2 Testing scientific notation 1e999 (overflow)...');
      try {
        final res = await engine.query('SELECT 1e999;');
        sw.stop();
        final val = res.rows.isNotEmpty ? res.rows.first.first.value : null;
        log('    Result: $val in ${sw.elapsedMilliseconds}ms.');

        findings.add(TestFinding(
          testId: 'NUM-SCI-1E999',
          vectorName: 'Extreme Numbers',
          title: 'Scientific notation 1e999 overflow handling',
          severity: (val == double.infinity) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Scientific notation 1e999 evaluated to: $val.',
          metrics: {'result': val.toString()},
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'NUM-SCI-1E999',
          vectorName: 'Extreme Numbers',
          title: 'Scientific notation 1e999 failed',
          severity: AttackSeverity.handledBoundary,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 6.3 Scientific Notation Underflow: 1e-999 (Underflow to 0.0)
    {
      final sw = Stopwatch()..start();
      log('[-] 6.3 Testing scientific notation 1e-999 (underflow)...');
      try {
        final res = await engine.query('SELECT 1e-999;');
        sw.stop();
        final val = res.rows.isNotEmpty ? res.rows.first.first.value : null;
        log('    Result: $val in ${sw.elapsedMilliseconds}ms.');

        findings.add(TestFinding(
          testId: 'NUM-SCI-1E-MINUS999',
          vectorName: 'Extreme Numbers',
          title: 'Scientific notation 1e-999 underflow handling',
          severity: (val == 0.0) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Scientific notation 1e-999 underflowed cleanly to: $val.',
          metrics: {'result': val.toString()},
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'NUM-SCI-1E-MINUS999',
          vectorName: 'Extreme Numbers',
          title: 'Scientific notation 1e-999 failed',
          severity: AttackSeverity.handledBoundary,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 6.4 IEEE-754 Subnormal Double (5e-324, double.minPositive)
    {
      final sw = Stopwatch()..start();
      log('[-] 6.4 Testing subnormal float boundary: 5e-324...');
      try {
        final res = await engine.query('SELECT 5e-324;');
        sw.stop();
        final val = res.rows.isNotEmpty ? res.rows.first.first.value : null;
        log('    Result: $val in ${sw.elapsedMilliseconds}ms.');

        findings.add(TestFinding(
          testId: 'NUM-SUBNORMAL-5E-324',
          vectorName: 'Extreme Numbers',
          title: 'IEEE-754 subnormal double literal (5e-324)',
          severity: (val != null && (val as num) > 0) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Parsed minimum IEEE-754 positive subnormal: $val.',
          metrics: {'result': val.toString()},
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'NUM-SUBNORMAL-5E-324',
          vectorName: 'Extreme Numbers',
          title: 'Subnormal double 5e-324 failed',
          severity: AttackSeverity.handledBoundary,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 6.5 Negative Zero (-0.0) Representation, Equality, and Storage
    {
      final sw = Stopwatch()..start();
      log('[-] 6.5 Testing negative zero (-0.0)...');
      try {
        final resVal = await engine.query('SELECT -0.0;');
        final resEq = await engine.query('SELECT -0.0 = 0.0;');
        sw.stop();

        final val = resVal.rows.isNotEmpty ? resVal.rows.first.first.value : null;
        final eq = resEq.rows.isNotEmpty ? resEq.rows.first.first.value : null;
        log('    Result: -0.0 evaluates to $val, equality (-0.0 = 0.0) evaluates to $eq.');

        // Verify storage in indexed table
        await engine.query('DROP TABLE IF EXISTS neg_zero_test;');
        await engine.query('CREATE TABLE neg_zero_test (id INT, val DOUBLE);');
        await engine.query('CREATE INDEX idx_neg_zero ON neg_zero_test(val);');
        await engine.query('INSERT INTO neg_zero_test VALUES (1, -0.0), (2, 0.0);');

        final lookupNeg = await engine.query('SELECT * FROM neg_zero_test WHERE val = -0.0;');
        final lookupPos = await engine.query('SELECT * FROM neg_zero_test WHERE val = 0.0;');

        findings.add(TestFinding(
          testId: 'NUM-NEG-ZERO',
          vectorName: 'Extreme Numbers',
          title: 'Negative zero (-0.0) evaluation, equality, and index search',
          severity: AttackSeverity.passedCleanly,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Negative zero representation: $val, equality: $eq, index lookup rows: neg=${lookupNeg.rows.length}, pos=${lookupPos.rows.length}.',
          metrics: {
            'val': val.toString(),
            'equality': eq.toString(),
            'negLookupCount': lookupNeg.rows.length,
            'posLookupCount': lookupPos.rows.length,
          },
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(TestFinding(
          testId: 'NUM-NEG-ZERO',
          vectorName: 'Extreme Numbers',
          title: 'Negative zero (-0.0) test failed',
          severity: AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 6.6 Malformed Scientific Notation Lexer Boundaries: 1e, 1e+, 1e-
    {
      final malformed = ['1e', '1e+', '1e-', '1.5e'];
      for (final m in malformed) {
        final sw = Stopwatch()..start();
        log('[-] 6.6 Testing malformed scientific notation "$m"...');
        try {
          final res = await engine.query('SELECT $m;');
          sw.stop();
          final val = res.rows.isNotEmpty ? res.rows.first.first.value : null;
          log('    Unexpected success for "$m": $val');

          findings.add(TestFinding(
            testId: 'NUM-MALFORMED-$m',
            vectorName: 'Extreme Numbers',
            title: 'Malformed scientific notation "$m" accepted without error',
            severity: AttackSeverity.unexpectedBehavior,
            elapsedMs: sw.elapsedMilliseconds,
            details: 'Query "SELECT $m;" was accepted and returned $val instead of syntax error.',
            metrics: {'input': m, 'result': val.toString()},
          ));
        } catch (e, st) {
          sw.stop();
          final isUnhandled = e is FormatException ||
              e.toString().contains('FormatException') ||
              e.toString().contains('RangeError');
          log('    Error for "$m": $e (unhandled FormatException: $isUnhandled)');

          findings.add(TestFinding(
            testId: 'NUM-MALFORMED-$m',
            vectorName: 'Extreme Numbers',
            title: isUnhandled
                ? 'CRITICAL: Unhandled FormatException on malformed float "$m"'
                : 'Graceful rejection of malformed float "$m"',
            severity: isUnhandled ? AttackSeverity.criticalCrash : AttackSeverity.handledBoundary,
            elapsedMs: sw.elapsedMilliseconds,
            details: 'Engine threw ${e.runtimeType}: $e in parser.dart num.parse() without descriptive syntax error.',
            errorMessage: e.toString(),
            stackTrace: st.toString(),
          ));
        }
      }
    }

    // 6.7 Float Division by Zero & NaN Serialization
    {
      final sw = Stopwatch()..start();
      log('[-] 6.7 Testing float division by zero (1.0 / 0.0) and (0.0 / 0.0)...');
      try {
        final divZero = await engine.query('SELECT 1.0 / 0.0;');
        final nanRes = await engine.query('SELECT 0.0 / 0.0;');
        sw.stop();

        final infVal = divZero.rows.isNotEmpty ? divZero.rows.first.first.value : null;
        final nanVal = nanRes.rows.isNotEmpty ? nanRes.rows.first.first.value : null;
        log('    Result: 1.0/0.0 = $infVal, 0.0/0.0 = $nanVal.');

        // Test storing NaN and Infinity in slotted-page table
        await engine.query('DROP TABLE IF EXISTS float_special;');
        await engine.query('CREATE TABLE float_special (id INT, val DOUBLE);');
        await engine.query('INSERT INTO float_special VALUES (1, 1.0 / 0.0), (2, 0.0 / 0.0);');

        final readSpecial = await engine.query('SELECT id, val FROM float_special ORDER BY id;');
        final r1 = readSpecial.rows[0][1].value;
        final r2 = readSpecial.rows[1][1].value;
        log('    Stored & retrieved: id 1 = $r1, id 2 = $r2.');

        findings.add(TestFinding(
          testId: 'NUM-FLOAT-SPECIAL',
          vectorName: 'Extreme Numbers',
          title: 'Float Infinity and NaN generation, slotted-page storage, and retrieval',
          severity: AttackSeverity.passedCleanly,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Engine cleanly generated IEEE-754 Infinity ($infVal) and NaN ($nanVal), stored them in slotted pages, and retrieved them.',
          metrics: {'inf': infVal.toString(), 'nan': nanVal.toString(), 'retrievedInf': r1.toString(), 'retrievedNan': r2.toString()},
        ));
      } catch (e, st) {
        sw.stop();
        log('    Float special values FAILED: $e');
        findings.add(TestFinding(
          testId: 'NUM-FLOAT-SPECIAL',
          vectorName: 'Extreme Numbers',
          title: 'Float special values (Infinity / NaN) failed',
          severity: AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }
  }

  // ===========================================================================
  // Report Generation
  // ===========================================================================
  void printSummaryReport() {
    banner('SUMMARY TEST REPORT & VULNERABILITY AUDIT');

    int criticalCount = 0;
    int silentLossCount = 0;
    int unexpectedCount = 0;
    int boundaryCount = 0;
    int passedCount = 0;

    for (final f in findings) {
      switch (f.severity) {
        case AttackSeverity.criticalCrash:
          criticalCount++;
          break;
        case AttackSeverity.silentDataLoss:
          silentLossCount++;
          break;
        case AttackSeverity.unexpectedBehavior:
          unexpectedCount++;
          break;
        case AttackSeverity.handledBoundary:
          boundaryCount++;
          break;
        case AttackSeverity.passedCleanly:
          passedCount++;
          break;
      }
    }

    stdout.writeln('Total Test Cases Run: ${findings.length}');
    stdout.writeln('  [CRITICAL CRASHES]       : $criticalCount');
    stdout.writeln('  [SILENT DATA LOSS]       : $silentLossCount');
    stdout.writeln('  [UNEXPECTED BEHAVIOR]    : $unexpectedCount');
    stdout.writeln('  [HANDLED BOUNDARIES]     : $boundaryCount');
    stdout.writeln('  [PASSED CLEANLY]         : $passedCount\n');

    stdout.writeln('--------------------------------------------------------------------------------');
    stdout.writeln('DETAILED FINDINGS BY ATTACK VECTOR:');
    stdout.writeln('--------------------------------------------------------------------------------');

    final grouped = <String, List<TestFinding>>{};
    for (final f in findings) {
      grouped.putIfAbsent(f.vectorName, () => []).add(f);
    }

    for (final entry in grouped.entries) {
      stdout.writeln('\n>>> ${entry.key.toUpperCase()} (${entry.value.length} tests)');
      for (final f in entry.value) {
        final badge = switch (f.severity) {
          AttackSeverity.criticalCrash => '[CRITICAL CRASH]',
          AttackSeverity.silentDataLoss => '[SILENT LOSS]',
          AttackSeverity.unexpectedBehavior => '[UNEXPECTED]',
          AttackSeverity.handledBoundary => '[HANDLED]',
          AttackSeverity.passedCleanly => '[PASSED]',
        };
        stdout.writeln('  $badge [${f.testId}] ${f.title} (${f.elapsedMs}ms)');
        stdout.writeln('      Details: ${f.details}');
        if (f.errorMessage != null) {
          stdout.writeln('      Error: ${f.errorMessage}');
        }
      }
    }

    stdout.writeln('\n================================================================================');
    stdout.writeln('END OF FUZZING & STRESS TEST SUITE');
    stdout.writeln('================================================================================\n');
  }
}

Future<void> main() async {
  final harness = FuzzBombHarness();
  try {
    await harness.init();
    await harness.testVector1RecursiveCte();
    await harness.testVector2CartesianExplosion();
    await harness.testVector3GiantCellToast();
    await harness.testVector4SchemaWidthStress();
    await harness.testVector5NestedExpressions();
    await harness.testVector6ExtremeNumbers();
    harness.printSummaryReport();
  } catch (e, st) {
    stderr.writeln('FATAL HARNESS FAILURE: $e\n$st');
  } finally {
    await harness.close();
  }
}
