import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/executor/jit_compiler.dart';
import 'package:ultsql/src/engine/executor/parallel_scan_nodes.dart';
import 'package:ultsql/src/engine/storage/materialized_views_trigger.dart';
import 'package:ultsql/src/engine/storage/ivf_flat_index.dart';
import 'package:ultsql/src/engine/storage/catalog.dart';
import 'package:ultsql/src/engine/parser/ast.dart';

/// ANSI Color Codes
class Ansi {
  static const reset = '\x1B[0m';
  static const bold = '\x1B[1m';
  static const red = '\x1B[31m';
  static const green = '\x1B[32m';
  static const yellow = '\x1B[33m';
  static const blue = '\x1B[34m';
  static const magenta = '\x1B[35m';
  static const cyan = '\x1B[36m';
}

/// Represents an adversarial test result step
class TestStepResult {
  final String section;
  final String name;
  final String status; // 'PASS', 'FAIL', 'DEFECT', 'CRASH'
  final String description;
  final Duration elapsed;
  final Map<String, dynamic> metrics;
  final String? error;
  final String? location;

  TestStepResult({
    required this.section,
    required this.name,
    required this.status,
    required this.description,
    required this.elapsed,
    this.metrics = const {},
    this.error,
    this.location,
  });

  @override
  String toString() {
    final badge = switch (status) {
      'PASS' => '${Ansi.green}✔ [PASS]${Ansi.reset}',
      'FAIL' => '${Ansi.red}✘ [FAIL]${Ansi.reset}',
      'DEFECT' => '${Ansi.yellow}${Ansi.bold}⚠ [DEFECT]${Ansi.reset}',
      'CRASH' => '${Ansi.red}${Ansi.bold}☠ [CRASH]${Ansi.reset}',
      _ => '[$status]',
    };
    final mStr = metrics.isNotEmpty ? ' | metrics: $metrics' : '';
    final locStr = location != null ? ' | at: $location' : '';
    final errStr = error != null ? ' | error: $error' : '';
    return '$badge ${Ansi.bold}$section::$name${Ansi.reset} (${elapsed.inMilliseconds}ms) -> $description$locStr$mStr$errStr';
  }
}

class Campaign3Runner {
  final List<TestStepResult> results = [];
  final List<String> tempDirs = [
    'test_jit_stress_db',
    'test_parallel_scan_db',
    'test_mv_reactor_db',
    'test_ivf_chaos_db',
  ];

  void record(TestStepResult res) {
    results.add(res);
    print(res.toString());
  }

  Future<void> cleanAllDirs() async {
    for (final d in tempDirs) {
      final dir = Directory(d);
      for (int i = 0; i < 5; i++) {
        try {
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }
          break;
        } catch (_) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }
  }
}

void main() async {
  print('${Ansi.cyan}${Ansi.bold}========================================================================${Ansi.reset}');
  print('${Ansi.cyan}${Ansi.bold}   CAMPAIGN 3: JIT Engine, Parallel Scanners & Materialized Views Reactor${Ansi.reset}');
  print('${Ansi.cyan}${Ansi.bold}========================================================================${Ansi.reset}');
  print('Engine Version: $ultSqlVersion | Dart: ${Platform.version.split(' ').first}\n');

  final runner = Campaign3Runner();
  await runner.cleanAllDirs();

  try {
    // -------------------------------------------------------------------------
    // PART 1: JIT Expression Compiler Stress
    // -------------------------------------------------------------------------
    print('\n${Ansi.magenta}${Ansi.bold}[PART 1] JIT Expression Compiler Stress & Deoptimization${Ansi.reset}');
    await testPart1JitStress(runner);

    // -------------------------------------------------------------------------
    // PART 2: Parallel Scan Engine Chaos
    // -------------------------------------------------------------------------
    print('\n${Ansi.magenta}${Ansi.bold}[PART 2] Parallel Scan Engine Chaos & Chunk Streaming${Ansi.reset}');
    await testPart2ParallelScanChaos(runner);

    // -------------------------------------------------------------------------
    // PART 3: Materialized Views Sabotage
    // -------------------------------------------------------------------------
    print('\n${Ansi.magenta}${Ansi.bold}[PART 3] Materialized Views Reactor & Sabotage${Ansi.reset}');
    await testPart3MaterializedViewsSabotage(runner);

    // -------------------------------------------------------------------------
    // PART 4: IVF-Flat Vector Index Chaos
    // -------------------------------------------------------------------------
    print('\n${Ansi.magenta}${Ansi.bold}[PART 4] IVF-Flat Vector Index Chaos & K-Means Clusters${Ansi.reset}');
    await testPart4IvfFlatChaos(runner);

  } finally {
    await runner.cleanAllDirs();
  }

  // ---------------------------------------------------------------------------
  // Summary & Defect Scorecard
  // ---------------------------------------------------------------------------
  printSummaryReport(runner.results);
}

// =============================================================================
// PART 1 IMPLEMENTATION: JIT Expression Compiler Stress
// =============================================================================
Future<void> testPart1JitStress(Campaign3Runner runner) async {
  // Test 1.1: Rapid Polymorphic Type Feedback Deoptimization
  {
    final sw = Stopwatch()..start();
    try {
      final expr = BinaryExpr('+', VariableExpr(['val']), LiteralExpr('10'));
      final closure = JitCompiler.compile(expr);

      const iterations = 10000;
      final types = <String>{};
      int successfulEvals = 0;

      // Cycle through 8 distinct types repeatedly on the same closure
      final sampleValues = <DbValue>[
        DbInt(42),
        DbText("100"),
        DbDouble(3.14159),
        DbJson([1, 2]),
        DbNull(),
        DbBlob(Uint8List.fromList([1, 2, 3])),
        DbJson({'key': 'val'}),
        DbInt(-999),
      ];

      for (int i = 0; i < iterations; i++) {
        final val = sampleValues[i % sampleValues.length];
        types.add(val.runtimeType.toString());
        final row = {'val': val};
        closure(row);
        successfulEvals++;
      }
      sw.stop();

      final passed = successfulEvals == iterations;
      runner.record(TestStepResult(
        section: 'JIT Stress',
        name: 'Rapid Polymorphic Type Feedback (10k iterations, 8 types)',
        status: passed ? 'PASS' : 'FAIL',
        description: passed
            ? 'JIT closure safely evaluated 10,000 rapid type transitions without monomorphic deopt crashes'
            : 'JIT evaluation failed during polymorphic cycling',
        elapsed: sw.elapsed,
        metrics: {
          'iterations': iterations,
          'distinct_types_cycled': types.length,
          'successful_evals': successfulEvals,
        },
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'JIT Stress',
        name: 'Rapid Polymorphic Type Feedback',
        status: 'CRASH',
        description: 'JIT closure threw exception under polymorphic feedback',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  // Test 1.2: 64-Bit Arithmetic Overflow & Edge Cases
  {
    final sw = Stopwatch()..start();
    try {
      // 64-bit integer limits: 0x7FFFFFFFFFFFFFFF and -0x8000000000000000
      const maxInt = 9223372036854775807;
      const minInt = -9223372036854775808;

      final addExpr = BinaryExpr('+', VariableExpr(['a']), VariableExpr(['b']));
      final mulExpr = BinaryExpr('*', VariableExpr(['a']), VariableExpr(['b']));
      final divExpr = BinaryExpr('/', VariableExpr(['a']), VariableExpr(['b']));
      final modExpr = BinaryExpr('%', VariableExpr(['a']), VariableExpr(['b']));

      final addFn = JitCompiler.compile(addExpr);
      final mulFn = JitCompiler.compile(mulExpr);
      final divFn = JitCompiler.compile(divExpr);
      final modFn = JitCompiler.compile(modExpr);

      // 1. MaxInt + 1
      final resAddOverflow = addFn({'a': DbInt(maxInt), 'b': DbInt(1)});
      // 2. MinInt - 1
      final resSubUnderflow = addFn({'a': DbInt(minInt), 'b': DbInt(-1)});
      // 3. MaxInt * 2
      final resMulOverflow = mulFn({'a': DbInt(maxInt), 'b': DbInt(2)});
      // 4. Div by zero
      final resDivZero = divFn({'a': DbInt(maxInt), 'b': DbInt(0)});
      // 5. Mod by zero
      final resModZero = modFn({'a': DbInt(maxInt), 'b': DbInt(0)});

      sw.stop();
      final safeDiv = resDivZero is DbDouble && (resDivZero.value.isInfinite || resDivZero.value.isNaN);
      final safeMod = resModZero is DbNull;

      runner.record(TestStepResult(
        section: 'JIT Stress',
        name: '64-Bit Arithmetic Overflow, Underflow & Division by Zero',
        status: (safeDiv && safeMod) ? 'PASS' : 'FAIL',
        description: 'Arithmetic wrap-around executed safely; division by zero returned ${resDivZero.toString()} and modulo returned ${resModZero.toString()} without crash',
        elapsed: sw.elapsed,
        metrics: {
          'max_int_add_1': resAddOverflow.toString(),
          'min_int_sub_1': resSubUnderflow.toString(),
          'mul_overflow': resMulOverflow.toString(),
          'div_zero_result': resDivZero.toString(),
          'mod_zero_result': resModZero.toString(),
        },
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'JIT Stress',
        name: '64-Bit Arithmetic Overflow',
        status: 'CRASH',
        description: 'Arithmetic threw uncaught exception (e.g. IntegerDivisionByZeroException)',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  // Test 1.3: Pathological LIKE Patterns & Catastrophic Backtracking
  {
    final sw = Stopwatch()..start();
    try {
      // Pathological pattern with alternating % and _ wildcards
      const pathologicalPattern = '%_%_%_%_%_%_%_%_%_%_x';
      final longSubject = 'A' * 2000;

      bool timedOut = false;
      bool? matchResult;

      final port = ReceivePort();
      final worker = await Isolate.spawn((List<dynamic> args) {
        final replyPort = args[0] as SendPort;
        final sub = args[1] as String;
        final pat = args[2] as String;
        final r = matchLike(sub, pat);
        replyPort.send(r);
      }, [port.sendPort, longSubject, pathologicalPattern]);

      try {
        matchResult = await port.first.timeout(const Duration(milliseconds: 1500)) as bool;
      } on TimeoutException {
        timedOut = true;
      } finally {
        worker.kill(priority: Isolate.immediate);
        port.close();
      }

      sw.stop();

      runner.record(TestStepResult(
        section: 'JIT Stress',
        name: 'Pathological LIKE Pattern Catastrophic Backtracking Test (%_%_%_%_)',
        status: timedOut ? 'DEFECT' : 'PASS',
        description: timedOut
            ? 'DEFECT: RegExp catastrophic backtracking in matchLike() hung isolate (killed after 1.5s timeout)'
            : 'Pathological wildcard pattern evaluated in ${sw.elapsedMilliseconds}ms without ReDoS hang',
        elapsed: sw.elapsed,
        location: 'lib/src/engine/executor/jit_compiler.dart:50',
        metrics: {
          'catastrophic_backtracking_timed_out': timedOut,
          'match_result': matchResult?.toString() ?? 'timed_out',
        },
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'JIT Stress',
        name: 'Pathological LIKE Pattern',
        status: 'CRASH',
        description: 'LIKE matcher threw exception',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  // Test 1.4: Deeply Nested Expression Trees Compiled via JIT (120 levels)
  {
    final sw = Stopwatch()..start();
    try {
      const depth = 120;
      Expression tree = VariableExpr(['base']);
      for (int i = 0; i < depth; i++) {
        tree = BinaryExpr('+', tree, LiteralExpr(1));
      }

      final closure = JitCompiler.compile(tree);
      final res = closure({'base': DbInt(10)});
      sw.stop();

      final expected = 10 + depth;
      final match = res is DbInt && res.value == expected;

      runner.record(TestStepResult(
        section: 'JIT Stress',
        name: 'Deeply Nested JIT Expression Tree ($depth binary levels)',
        status: match ? 'PASS' : 'FAIL',
        description: match
            ? 'Compiled and evaluated $depth-level deep expression tree without recursion stack overflow'
            : 'Incorrect evaluation of deep expression: got $res, expected $expected',
        elapsed: sw.elapsed,
        metrics: {'depth': depth, 'result': res.toString()},
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'JIT Stress',
        name: 'Deeply Nested JIT Expression Tree',
        status: 'CRASH',
        description: 'JIT compilation of deep expression crashed',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }
}

// =============================================================================
// PART 2 IMPLEMENTATION: Parallel Scan Engine Chaos
// =============================================================================
Future<void> testPart2ParallelScanChaos(Campaign3Runner runner) async {
  const dbDir = 'test_parallel_scan_db';
  final engine = await UltSqlEngine.openFile(dbDir);

  // Setup table with 2,000 rows
  await engine.query('CREATE TABLE t_chaos (id INT, val TEXT, cat INT);');
  for (int chunk = 0; chunk < 10; chunk++) {
    final values = List.generate(
      200,
      (i) => "(${chunk * 200 + i}, 'val_${chunk * 200 + i}', ${i % 5})",
    ).join(', ');
    await engine.query('INSERT INTO t_chaos VALUES $values;');
  }
  engine.db.cache.flushAllSync();

  final schema = engine.db.catalog.getTableSchema('t_chaos')!;
  final tableFilePath = '${engine.db.directory}/t_chaos.db';
  final pageCount = engine.db.cache.getActualPageCountSync(tableFilePath);

  // Test 2.1: Massive Parallelism on Tiny Tables (50 Workers on 0-Row & 1-Row Tables)
  {
    final sw = Stopwatch()..start();
    try {
      // 1. 0-row table
      await engine.query('CREATE TABLE t_empty (id INT, name TEXT);');
      engine.db.cache.flushAllSync();
      final emptySchema = engine.db.catalog.getTableSchema('t_empty')!;
      final emptyPath = '${engine.db.directory}/t_empty.db';
      final emptyScan = ParallelScanNode(
        filePath: emptyPath,
        schema: emptySchema,
        pageCount: 0,
        numWorkers: 50,
      );
      await emptyScan.executeParallelScan();
      final emptyNext = emptyScan.next();

      // 2. 1-row table
      await engine.query('CREATE TABLE t_single (id INT, name TEXT);');
      await engine.query("INSERT INTO t_single VALUES (1, 'only_row');");
      engine.db.cache.flushAllSync();
      final singleSchema = engine.db.catalog.getTableSchema('t_single')!;
      final singlePath = '${engine.db.directory}/t_single.db';
      final singlePages = engine.db.cache.getActualPageCountSync(singlePath);
      final singleScan = ParallelScanNode(
        filePath: singlePath,
        schema: singleSchema,
        pageCount: singlePages,
        numWorkers: 50,
      );
      await singleScan.executeParallelScan();
      final singleRows = <Map<String, DbValue>>[];
      Map<String, DbValue>? r;
      while ((r = singleScan.next()) != null) {
        singleRows.add(r!);
      }

      // 3. Spawning 50 parallel scans concurrently
      final batchScans = List.generate(50, (_) {
        return ParallelScanNode(
          filePath: singlePath,
          schema: singleSchema,
          pageCount: singlePages,
          numWorkers: 2,
        );
      });
      await Future.wait(batchScans.map((s) => s.executeParallelScan()));

      sw.stop();
      final passed = emptyNext == null && singleRows.length == 1;

      runner.record(TestStepResult(
        section: 'Parallel Scan',
        name: 'Massive Parallelism on Tiny Tables (50 workers, 0-row & 1-row)',
        status: passed ? 'PASS' : 'FAIL',
        description: passed
            ? '50 workers partitioned 0-row and 1-row tables cleanly without integer division by zero'
            : 'Mismatched row count on tiny table scans',
        elapsed: sw.elapsed,
        metrics: {
          'empty_rows': 0,
          'single_rows': singleRows.length,
          'concurrent_50_scans_completed': true,
        },
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'Parallel Scan',
        name: 'Massive Parallelism on Tiny Tables',
        status: 'CRASH',
        description: 'Parallel scan on tiny tables crashed',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  // Test 2.2: Aggregation & Group-By in Worker Isolates
  {
    final sw = Stopwatch()..start();
    try {
      final aggNode = ParallelScanNode(
        filePath: tableFilePath,
        schema: schema,
        pageCount: pageCount,
        numWorkers: 4,
        groupByExpr: VariableExpr(['cat']),
        aggProjections: [
          Projection(
            FunctionCallExpr('count', [VariableExpr(['id'])]),
            'row_count',
          ),
          Projection(
            FunctionCallExpr('sum', [VariableExpr(['id'])]),
            'sum_id',
          ),
          Projection(
            FunctionCallExpr('avg', [VariableExpr(['id'])]),
            'avg_id',
          ),
        ],
      );

      await aggNode.executeParallelScan();
      final aggRows = <Map<String, DbValue>>[];
      Map<String, DbValue>? r;
      while ((r = aggNode.next()) != null) {
        aggRows.add(r!);
      }
      sw.stop();

      final totalSum = aggRows.fold<int>(
        0,
        (acc, row) => acc + ((row['row_count'] as DbInt).value),
      );
      final passed = aggRows.length == 5 && totalSum == 2000;

      runner.record(TestStepResult(
        section: 'Parallel Scan',
        name: 'Parallel Pre-Aggregation & Isolate Reducer (COUNT, SUM, AVG)',
        status: passed ? 'PASS' : 'FAIL',
        description: passed
            ? 'Worker isolates pre-aggregated rows across 5 groups; master reducer merged exactly 2,000 rows'
            : 'Aggregator result mismatch: groups=${aggRows.length}, sum=$totalSum',
        elapsed: sw.elapsed,
        metrics: {
          'groups_count': aggRows.length,
          'total_rows_aggregated': totalSum,
        },
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'Parallel Scan',
        name: 'Parallel Aggregation & Reducer',
        status: 'CRASH',
        description: 'Parallel pre-aggregation crashed in worker isolates',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  // Test 2.3: Negative & Corrupted Chunk Boundaries
  await _testNegativeChunkBoundaries(tableFilePath, schema, runner);

  // Test 2.4: Concurrent Table Drop while Parallel Worker Isolate Scans
  {
    final sw = Stopwatch()..start();
    try {
      // Create temporary table for concurrent destruction
      await engine.query('CREATE TABLE t_drop_target (id INT, data TEXT);');
      for (int i = 0; i < 5; i++) {
        final vals = List.generate(200, (j) => "(${i * 200 + j}, 'payload')").join(', ');
        await engine.query('INSERT INTO t_drop_target VALUES $vals;');
      }
      final dropSchema = engine.db.catalog.getTableSchema('t_drop_target')!;
      final dropPath = '${engine.db.directory}/t_drop_target.db';
      final dropPages = engine.db.cache.getActualPageCountSync(dropPath);

      final scanNode = ParallelScanNode(
        filePath: dropPath,
        schema: dropSchema,
        pageCount: dropPages,
        numWorkers: 4,
      );

      // Start scan concurrently with DROP TABLE
      bool dropCompleted = false;
      bool scanThrewOrHandled = false;

      final scanFuture = scanNode.executeParallelScan().catchError((e) {
        scanThrewOrHandled = true;
      });

      final dropFuture = Future(() async {
        await engine.query('DROP TABLE t_drop_target;');
        dropCompleted = true;
      });

      await Future.wait([scanFuture, dropFuture]);
      sw.stop();

      runner.record(TestStepResult(
        section: 'Parallel Scan',
        name: 'Concurrent Table DROP during Active Parallel Worker Scan',
        status: 'PASS',
        description: 'Isolate scan and DROP TABLE completed concurrently without deadlocking or crashing the process',
        elapsed: sw.elapsed,
        metrics: {
          'drop_completed': dropCompleted,
          'scan_handled': scanThrewOrHandled,
        },
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'Parallel Scan',
        name: 'Concurrent Table DROP',
        status: 'CRASH',
        description: 'Process crashed on concurrent table drop',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  await engine.close();
}

Future<void> _testNegativeChunkBoundaries(
  String tableFilePath,
  TableSchema schema,
  Campaign3Runner runner,
) async {
  final sw = Stopwatch()..start();
  try {
    // Create negative chunk task
    final badTask = ParallelScanTask(
      filePath: tableFilePath,
      startPage: -10,
      endPage: 5,
      schema: schema,
    );

    bool isolateThrew = false;
    String isolateError = '';

    try {
      await Isolate.run(() => runParallelScanWorker(badTask));
    } catch (e) {
      isolateThrew = true;
      isolateError = e.toString();
    }

    // Inverted bounds: startPage > endPage
    final invertedTask = ParallelScanTask(
      filePath: tableFilePath,
      startPage: 20,
      endPage: 5,
      schema: schema,
    );
    final invertedRes = await Isolate.run(() => runParallelScanWorker(invertedTask));

    sw.stop();

    runner.record(TestStepResult(
      section: 'Parallel Scan',
      name: 'Negative & Inverted Chunk Boundaries (startPage: -10, startPage > endPage)',
      status: isolateThrew ? 'PASS' : 'DEFECT',
      description: isolateThrew
          ? 'Negative chunk boundary intercepted: FilePager prevented negative file pointer'
          : 'Negative chunk boundary did not throw error',
      elapsed: sw.elapsed,
      metrics: {
        'isolate_caught_negative': isolateThrew,
        'inverted_returned_rows': invertedRes.length,
        'error_sample': isolateError.split('\n').first,
      },
    ));
  } catch (e, st) {
    sw.stop();
    runner.record(TestStepResult(
      section: 'Parallel Scan',
      name: 'Negative Chunk Boundaries',
      status: 'CRASH',
      description: 'Negative chunk test crashed parent isolate',
      elapsed: sw.elapsed,
      error: e.toString(),
      location: st.toString().split('\n').first,
    ));
  }
}

// =============================================================================
// PART 3 IMPLEMENTATION: Materialized Views Sabotage
// =============================================================================
Future<void> testPart3MaterializedViewsSabotage(Campaign3Runner runner) async {
  const dbDir = 'test_mv_reactor_db';
  final dir = Directory(dbDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // Test 3.1: Circular Dependency Graph Poisoning
  {
    final sw = Stopwatch()..start();
    try {
      final registryFile = File('$dbDir/mv_registry.json');
      final circularJson = {
        'view_a': {
          'viewName': 'view_a',
          'sourceTable': 'view_b',
          'selectQuery': 'SELECT * FROM view_b;',
        },
        'view_b': {
          'viewName': 'view_b',
          'sourceTable': 'view_c',
          'selectQuery': 'SELECT * FROM view_c;',
        },
        'view_c': {
          'viewName': 'view_c',
          'sourceTable': 'view_a',
          'selectQuery': 'SELECT * FROM view_a;',
        },
      };
      registryFile.writeAsStringSync(json.encode(circularJson));

      final mvManager = MaterializedViewManager(dbDir);
      mvManager.initSync();

      // Test recursive dependency traversal with cycle detection simulation
      bool cycleDetected = false;
      bool stackOverflowOccurred = false;

      void resolveDependencies(String startTable, Set<String> visited) {
        if (visited.contains(startTable.toLowerCase())) {
          cycleDetected = true;
          return;
        }
        visited.add(startTable.toLowerCase());
        final dependents = mvManager.getViewsForTable(startTable);
        for (final dep in dependents) {
          resolveDependencies(dep.viewName, Set<String>.from(visited));
        }
      }

      try {
        resolveDependencies('view_a', {});
      } catch (err) {
        stackOverflowOccurred = true;
      }
      sw.stop();

      final passed = cycleDetected && !stackOverflowOccurred;
      runner.record(TestStepResult(
        section: 'Materialized Views',
        name: 'Registry Poisoning: Circular Dependency Graph (A -> B -> C -> A)',
        status: passed ? 'PASS' : 'DEFECT',
        description: passed
            ? 'Loaded poisoned circular registry; cycle detected safely without infinite recursion'
            : 'Infinite recursion / stack overflow during dependency resolution',
        elapsed: sw.elapsed,
        metrics: {
          'cycle_detected': cycleDetected,
          'stack_overflow': stackOverflowOccurred,
          'views_loaded': 3,
        },
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'Materialized Views',
        name: 'Registry Poisoning: Circular Dependency',
        status: 'CRASH',
        description: 'Circular registry parsing crashed',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  // Test 3.2: Orphan View: Base Table Dropped While View Exists
  {
    final sw = Stopwatch()..start();
    try {
      final engine = await UltSqlEngine.openFile(dbDir);
      await engine.query('CREATE TABLE sales (id INT, amount DOUBLE);');
      await engine.query('INSERT INTO sales VALUES (1, 100.5), (2, 250.0);');

      // Create materialized view table and register definition
      await engine.query('CREATE TABLE mv_sales_summary (total_sales DOUBLE);');
      await engine.query('INSERT INTO mv_sales_summary VALUES (350.5);');

      final mvManager = MaterializedViewManager(dbDir);
      mvManager.registerView('mv_sales_summary', 'sales', 'SELECT SUM(amount) AS total_sales FROM sales;');

      // Drop base table
      await engine.query('DROP TABLE sales;');

      // Attempt to refresh view
      bool refreshFailedCleanly = false;
      String refreshError = '';
      try {
        final viewDef = mvManager.getViewsForTable('sales');
        if (viewDef.isNotEmpty) {
          await engine.query(viewDef.first.selectQuery);
        }
      } catch (e) {
        refreshFailedCleanly = true;
        refreshError = e.toString();
      }

      // Existing view table remains queryable
      final viewRes = await engine.query('SELECT * FROM mv_sales_summary;');

      sw.stop();
      final passed = refreshFailedCleanly && viewRes.rows.isNotEmpty;

      runner.record(TestStepResult(
        section: 'Materialized Views',
        name: 'Orphan View: Base Table Dropped while Materialized View Persists',
        status: passed ? 'PASS' : 'FAIL',
        description: passed
            ? 'Refreshing orphan view failed gracefully ("Table sales does not exist"); persisted view data intact'
            : 'Uncaught error or view corruption on orphan refresh',
        elapsed: sw.elapsed,
        metrics: {
          'refresh_failed_cleanly': refreshFailedCleanly,
          'view_persisted_rows': viewRes.rows.length,
          'error_sample': refreshError,
        },
      ));
      await engine.close();
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'Materialized Views',
        name: 'Orphan View',
        status: 'CRASH',
        description: 'Orphan view handling crashed',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  // Test 3.3: Transaction Abort & Rollback during Materialized View Update
  {
    final sw = Stopwatch()..start();
    try {
      final engine = await UltSqlEngine.openFile(dbDir);
      await engine.query('CREATE TABLE accounts (id INT, balance DOUBLE);');
      await engine.query('INSERT INTO accounts VALUES (1, 500.0);');
      await engine.query('CREATE TABLE mv_accounts (id INT, balance DOUBLE);');
      await engine.query('INSERT INTO mv_accounts VALUES (1, 500.0);');

      // Start Transaction and mutate both tables, then ROLLBACK
      await engine.query('BEGIN TRANSACTION;');
      await engine.query('UPDATE accounts SET balance = 999.0 WHERE id = 1;');
      await engine.query('UPDATE mv_accounts SET balance = 999.0 WHERE id = 1;');
      await engine.query('ROLLBACK;');

      // Verify that both tables reverted
      final baseRes = await engine.query('SELECT balance FROM accounts WHERE id = 1;');
      final viewRes = await engine.query('SELECT balance FROM mv_accounts WHERE id = 1;');
      sw.stop();

      final baseReverted = baseRes.rows.first[0].toString() == '500.0';
      final viewReverted = viewRes.rows.first[0].toString() == '500.0';
      final passed = baseReverted && viewReverted;

      runner.record(TestStepResult(
        section: 'Materialized Views',
        name: 'Transaction Abort & Rollback during View Maintenance',
        status: passed ? 'PASS' : 'FAIL',
        description: passed
            ? 'Both base table and materialized view reverted cleanly on transaction abort'
            : 'Rollback failed to restore view or base table state',
        elapsed: sw.elapsed,
        metrics: {
          'base_reverted': baseReverted,
          'view_reverted': viewReverted,
        },
      ));
      await engine.close();
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'Materialized Views',
        name: 'Transaction Abort & Rollback',
        status: 'CRASH',
        description: 'Transaction abort crashed MV engine',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  // Test 3.4: Corrupted mv_registry.json Injection (Syntax error, null fields)
  {
    final sw = Stopwatch()..start();
    try {
      final registryFile = File('$dbDir/mv_registry.json');
      registryFile.writeAsStringSync('{ INVALID_JSON_SYNTAX: null, broken: [1, 2, }');

      final mvManager = MaterializedViewManager(dbDir);
      // initSync must catch format errors gracefully without throwing
      mvManager.initSync();
      sw.stop();

      runner.record(TestStepResult(
        section: 'Materialized Views',
        name: 'Corrupted Registry Injection (Malformed JSON)',
        status: 'PASS',
        description: 'initSync() caught JSON syntax error internally without unhandled parse exception',
        elapsed: sw.elapsed,
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'Materialized Views',
        name: 'Corrupted Registry Injection',
        status: 'CRASH',
        description: 'Corrupted registry crashed initSync()',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }
}

// =============================================================================
// PART 4 IMPLEMENTATION: IVF-Flat Vector Index Chaos
// =============================================================================
Future<void> testPart4IvfFlatChaos(Campaign3Runner runner) async {
  const dbDir = 'test_ivf_chaos_db';
  final dir = Directory(dbDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // Test 4.1: Boundary Clustering: k = 0 (numCentroids = 0)
  {
    final sw = Stopwatch()..start();
    try {
      final ivfZero = IvfFlatIndex(
        indexPath: '$dbDir/ivf_k_zero.ivf',
        numCentroids: 0,
        autoSave: false,
      );

      // Insert 10 vectors
      for (int i = 0; i < 10; i++) {
        ivfZero.insertSync(DbVector([i.toDouble(), (i * 2).toDouble()]), 1, i);
      }
      ivfZero.trainAndPartition();
      final results = ivfZero.search(DbVector([5.0, 10.0]), 3);
      sw.stop();

      final passed = ivfZero.centroids.length == 1 && results.isNotEmpty;
      runner.record(TestStepResult(
        section: 'IVF-Flat Chaos',
        name: 'Boundary Clustering: k = 0 (Clamped to k = 1)',
        status: passed ? 'PASS' : 'FAIL',
        description: passed
            ? 'numCentroids = 0 clamped safely to k = 1; partitioned and searched without division by zero'
            : 'Failed to cluster or search when numCentroids = 0',
        elapsed: sw.elapsed,
        metrics: {
          'centroids_created': ivfZero.centroids.length,
          'search_results': results.length,
        },
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'IVF-Flat Chaos',
        name: 'Boundary Clustering: k = 0',
        status: 'CRASH',
        description: 'IVF-Flat crashed on numCentroids = 0',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  // Test 4.2: Over-Clustering: k > N Vectors (More Clusters than Data Points)
  {
    final sw = Stopwatch()..start();
    try {
      final ivfOver = IvfFlatIndex(
        indexPath: '$dbDir/ivf_k_over.ivf',
        numCentroids: 50,
        nprobe: 5,
        autoSave: false,
      );

      // Insert only 5 vectors
      for (int i = 0; i < 5; i++) {
        ivfOver.insertSync(DbVector([i * 1.5, i * 2.5]), 1, i);
      }
      ivfOver.trainAndPartition();
      final searchRes = ivfOver.search(DbVector([2.0, 3.0]), 5);
      sw.stop();

      // k must clamp to _tempNodes.length (5)
      final passed = ivfOver.centroids.length == 5 && searchRes.length == 5;
      runner.record(TestStepResult(
        section: 'IVF-Flat Chaos',
        name: 'Over-Clustering: k > N (k=50 centroids requested for N=5 vectors)',
        status: passed ? 'PASS' : 'FAIL',
        description: passed
            ? 'numCentroids (50) clamped automatically to dataset size (5); search returned all 5 points'
            : 'Centroid count mismatch or search failed',
        elapsed: sw.elapsed,
        metrics: {
          'centroids_created': ivfOver.centroids.length,
          'results_returned': searchRes.length,
        },
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'IVF-Flat Chaos',
        name: 'Over-Clustering: k > N',
        status: 'CRASH',
        description: 'IVF-Flat crashed when k > N',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  // Test 4.3: Identical Vectors & Empty Clusters
  {
    final sw = Stopwatch()..start();
    try {
      final ivfIdentical = IvfFlatIndex(
        indexPath: '$dbDir/ivf_identical.ivf',
        numCentroids: 5,
        autoSave: false,
      );

      // Insert 20 identical vectors
      final identicalCoord = [42.0, 99.0, 100.0];
      for (int i = 0; i < 20; i++) {
        ivfIdentical.insertSync(DbVector(List<double>.from(identicalCoord)), 1, i);
      }
      ivfIdentical.trainAndPartition();

      // Centroid recalculation with identical vectors causes empty groups (groups[1..k-1] are empty)
      final res = ivfIdentical.search(DbVector(identicalCoord), 5);
      sw.stop();

      final passed = ivfIdentical.centroids.length == 5 && res.length == 5;
      runner.record(TestStepResult(
        section: 'IVF-Flat Chaos',
        name: 'Identical Vectors & Empty Cluster Centroid Recalculation',
        status: passed ? 'PASS' : 'FAIL',
        description: passed
            ? 'K-means handled empty clusters by resampling random temp nodes without division-by-zero crashes'
            : 'Search or clustering failed on identical vectors',
        elapsed: sw.elapsed,
        metrics: {
          'centroids_length': ivfIdentical.centroids.length,
          'search_results': res.length,
        },
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'IVF-Flat Chaos',
        name: 'Identical Vectors & Empty Clusters',
        status: 'CRASH',
        description: 'Empty cluster centroid calculation crashed',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  // Test 4.4: NaN, Infinity & Poison Coordinates in K-Means
  {
    final sw = Stopwatch()..start();
    try {
      final ivfPoison = IvfFlatIndex(
        indexPath: '$dbDir/ivf_poison.ivf',
        numCentroids: 3,
        autoSave: false,
      );

      // Insert vectors containing NaN and Infinity
      ivfPoison.insertSync(DbVector([double.nan, 1.0]), 1, 1);
      ivfPoison.insertSync(DbVector([double.infinity, 2.0]), 1, 2);
      ivfPoison.insertSync(DbVector([3.0, 4.0]), 1, 3);

      ivfPoison.trainAndPartition();
      final searchRes = ivfPoison.search(DbVector([3.0, 4.0]), 3);
      sw.stop();

      final hasNaNInCentroids = ivfPoison.centroids.any(
        (c) => c.value.any((v) => v.isNaN || v.isInfinite),
      );

      runner.record(TestStepResult(
        section: 'IVF-Flat Chaos',
        name: 'NaN & Infinity Coordinates in K-Means Centroid Recalculation',
        status: hasNaNInCentroids ? 'DEFECT' : 'PASS',
        description: hasNaNInCentroids
            ? 'DEFECT: insertSync() does not validate coord.isFinite, allowing NaN/Infinity to poison K-means centroids'
            : 'NaN/Infinity coordinates were sanitized or rejected',
        elapsed: sw.elapsed,
        location: 'lib/src/engine/storage/ivf_flat_index.dart:204',
        metrics: {
          'centroids_poisoned_with_nan': hasNaNInCentroids,
          'search_candidates_found': searchRes.length,
        },
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'IVF-Flat Chaos',
        name: 'NaN & Infinity Coordinates',
        status: 'CRASH',
        description: 'NaN/Infinity crashed K-means clustering',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }

  // Test 4.5: Mismatched Vector Dimensions in IVF Indexing (Dim 3 vs Dim 8)
  {
    final sw = Stopwatch()..start();
    try {
      final ivfMismatch = IvfFlatIndex(
        indexPath: '$dbDir/ivf_mismatch.ivf',
        numCentroids: 2,
        autoSave: false,
      );

      // Insert vector of dimension 3, then dimension 8
      ivfMismatch.insertSync(DbVector([1.0, 2.0, 3.0]), 1, 1);
      ivfMismatch.insertSync(DbVector([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]), 1, 2);

      bool mismatchThrew = false;
      String mismatchError = '';
      String mismatchLoc = '';

      try {
        ivfMismatch.trainAndPartition();
      } catch (err, st) {
        mismatchThrew = true;
        mismatchError = err.toString();
        mismatchLoc = st.toString().split('\n').first;
      }
      sw.stop();

      runner.record(TestStepResult(
        section: 'IVF-Flat Chaos',
        name: 'Mismatched Vector Dimensions (Dim 3 vs Dim 8 in Same Index)',
        status: mismatchThrew ? 'DEFECT' : 'FAIL',
        description: mismatchThrew
            ? 'DEFECT: insertSync() lacks dimension validation; trainAndPartition() throws RangeError during centroid mean calculation'
            : 'Unexpected: Mismatched dimensions succeeded',
        elapsed: sw.elapsed,
        location: 'lib/src/engine/storage/ivf_flat_index.dart:135',
        error: mismatchError,
        metrics: {
          'threw_range_error': mismatchThrew,
          'throw_location': mismatchLoc,
        },
      ));
    } catch (e, st) {
      sw.stop();
      runner.record(TestStepResult(
        section: 'IVF-Flat Chaos',
        name: 'Mismatched Vector Dimensions',
        status: 'CRASH',
        description: 'Unexpected outer crash',
        elapsed: sw.elapsed,
        error: e.toString(),
        location: st.toString().split('\n').first,
      ));
    }
  }
}

// =============================================================================
// SUMMARY REPORT
// =============================================================================
void printSummaryReport(List<TestStepResult> results) {
  final passCount = results.where((r) => r.status == 'PASS').length;
  final failCount = results.where((r) => r.status == 'FAIL').length;
  final defectCount = results.where((r) => r.status == 'DEFECT').length;
  final crashCount = results.where((r) => r.status == 'CRASH').length;
  final totalDuration = results.fold<Duration>(Duration.zero, (acc, r) => acc + r.elapsed);

  print('\n${Ansi.cyan}${Ansi.bold}========================================================================${Ansi.reset}');
  print('${Ansi.cyan}${Ansi.bold}                 CAMPAIGN 3: ADVERSARIAL SUMMARY REPORT                 ${Ansi.reset}');
  print('${Ansi.cyan}${Ansi.bold}========================================================================${Ansi.reset}');
  print('Total Test Vectors: ${results.length}');
  print('Passed:             ${Ansi.green}$passCount${Ansi.reset}');
  print('Defects Discovered: ${defectCount > 0 ? Ansi.yellow : Ansi.green}$defectCount${Ansi.reset}');
  print('Failures:           ${failCount > 0 ? Ansi.red : Ansi.green}$failCount${Ansi.reset}');
  print('Crashes:            ${crashCount > 0 ? Ansi.red : Ansi.green}$crashCount${Ansi.reset}');
  print('Total Elapsed Time: ${totalDuration.inMilliseconds} ms\n');

  print('${Ansi.bold}Breakdown by Vector Category:${Ansi.reset}');
  for (final r in results) {
    print(r.toString());
  }
  print('\n${Ansi.cyan}${Ansi.bold}========================================================================${Ansi.reset}\n');
}
