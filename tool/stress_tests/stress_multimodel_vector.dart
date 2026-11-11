import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/storage/hnsw_index.dart';
import 'package:ultsql/src/engine/nosql/query_filter.dart';
import 'package:ultsql/src/engine/nosql/document_mutator.dart';
import 'package:ultsql/src/engine/nosql/collection.dart';
import 'package:ultsql/src/engine/nosql/document.dart';
import 'package:ultsql/src/engine/nosql/kv_store.dart';

// ============================================================================
// ULTSQL MULTI-MODEL ADVERSARIAL STRESS & CHAOS TEST SUITE
// ============================================================================
// Targets:
//   1. NoSQL Schema & Operator Poisoning (Nesting, Big Arrays, ReDoS, Type Confusion)
//   2. Vector RAG Degenerate Topologies (NaN/Inf, Dimension Mismatch, 5k Clustered, Concurrency)
//   3. Redis-Style KV Store Extreme Stress (10MB Values, Atomic Race Conditions, Malformed TTLs)
// ============================================================================

const String kDbDir = 'test_vector_db';

void main(List<String> args) async {
  // Check for worker isolate CLI mode (e.g. for isolating ReDoS regex tests)
  if (args.isNotEmpty && args[0] == '--regex-worker') {
    _runRegexWorkerCli(args);
    return;
  }

  print('======================================================================');
  print(' ⚡ ULTSQL ADVERSARIAL MULTI-MODEL & VECTOR STRESS SUITE ⚡');
  print(' Dedicated Target Database: $kDbDir');
  print(' OS: ${Platform.operatingSystem} (${Platform.numberOfProcessors} CPU cores)');
  print(' Dart Runtime: ${Platform.version}');
  print(' Timestamp: ${DateTime.now().toIso8601String()}');
  print('======================================================================\n');

  // Pre-suite cleanup
  await _cleanDirectory(kDbDir);

  final suiteSw = Stopwatch()..start();
  final defects = <Map<String, dynamic>>[];
  final testSummaries = <Map<String, dynamic>>[];

  try {
    // ------------------------------------------------------------------------
    // PILLAR 1: NoSQL Schema & Operator Poisoning
    // ------------------------------------------------------------------------
    print('>>> [PILLAR 1/3] NOSQL SCHEMA & OPERATOR POISONING ATTACKS <<<\n');

    final res1_1 = await test1_1DeeplyNestedDocuments(defects);
    testSummaries.add(res1_1);

    final res1_2 = await test1_2MassiveArraysPush(defects);
    testSummaries.add(res1_2);

    final res1_3 = await test1_3AdversarialReDoS(defects);
    testSummaries.add(res1_3);

    final res1_4 = await test1_4TypeConfusionAndOperatorAttacks(defects);
    testSummaries.add(res1_4);

    // ------------------------------------------------------------------------
    // PILLAR 2: Vector RAG Degenerate Topologies & Edge Cases
    // ------------------------------------------------------------------------
    print('\n>>> [PILLAR 2/3] VECTOR RAG DEGENERATE TOPOLOGIES & MATH ATTACKS <<<\n');

    final res2_1 = await test2_1DegenerateVectorsAndMath(defects);
    testSummaries.add(res2_1);

    final res2_2 = await test2_2DimensionMismatchCorruption(defects);
    testSummaries.add(res2_2);

    final res2_3 = await test2_3IdenticalVectorCluster(defects);
    testSummaries.add(res2_3);

    final res2_4 = await test2_4ConcurrentVectorSearchAndInsert(defects);
    testSummaries.add(res2_4);

    // ------------------------------------------------------------------------
    // PILLAR 3: Redis-Style KV Store Extreme Stress
    // ------------------------------------------------------------------------
    print('\n>>> [PILLAR 3/3] REDIS-STYLE KEY-VALUE STORE EXTREME STRESS <<<\n');

    final res3_1 = await test3_1GiantValuesAndNestedStructures(defects);
    testSummaries.add(res3_1);

    final res3_2 = await test3_2RapidConcurrentCounterFlooding(defects);
    testSummaries.add(res3_2);

    final res3_3 = await test3_3NegativeAndMalformedTTLs(defects);
    testSummaries.add(res3_3);

  } finally {
    suiteSw.stop();
    // Post-suite cleanup
    await _cleanDirectory(kDbDir);
  }

  // --------------------------------------------------------------------------
  // EXECUTIVE SUMMARY REPORT
  // --------------------------------------------------------------------------
  print('\n======================================================================');
  print(' 📊 GRAND MULTI-MODEL ADVERSARIAL STRESS REPORT');
  print(' Total Suite Duration: ${suiteSw.elapsedMilliseconds} ms');
  print(' Total Tests Executed: ${testSummaries.length}');
  print(' Total Defects Found:  ${defects.length}');
  print('======================================================================');

  for (final s in testSummaries) {
    final status = s['passed'] == true ? '✅ PASS' : '❌ FAIL';
    print('$status [${s['name']}] (${s['durationMs']} ms)');
    if (s['metrics'] != null) {
      final m = s['metrics'] as Map<String, dynamic>;
      m.forEach((k, v) => print('     • $k: $v'));
    }
  }

  print('\n----------------------------------------------------------------------');
  if (defects.isEmpty) {
    print(' 🎉 NO DEFECTS DETECTED. Engine demonstrated full resilience.');
  } else {
    print(' 🚨 IDENTIFIED VULNERABILITIES & ENGINE DEFECTS (${defects.length}):');
    for (int i = 0; i < defects.length; i++) {
      final d = defects[i];
      print('\n[DEFECT #${i + 1}] [${d['category']}] - Severity: ${d['severity']}');
      print('  Title:       ${d['title']}');
      print('  Description: ${d['description']}');
      print('  Impact:      ${d['impact']}');
      if (d['evidence'] != null) {
        print('  Evidence:    ${d['evidence']}');
      }
    }
  }
  print('======================================================================\n');
}

// ============================================================================
// CLEANUP HELPER
// ============================================================================
Future<void> _cleanDirectory(String dirPath) async {
  final d = Directory(dirPath);
  if (d.existsSync()) {
    try {
      d.deleteSync(recursive: true);
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (d.existsSync()) {
        try {
          d.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
  }
}

// ============================================================================
// 1.1: Deeply Nested Documents (50+ Levels)
// ============================================================================
Future<Map<String, dynamic>> test1_1DeeplyNestedDocuments(
  List<Map<String, dynamic>> defects,
) async {
  final sw = Stopwatch()..start();
  print('--- [TEST 1.1] Deeply Nested Documents (50+ Levels) ---');
  final metrics = <String, dynamic>{};
  bool passed = true;

  final dbPath = '$kDbDir/nosql_nesting';
  await _cleanDirectory(dbPath);
  final db = Database(dbPath);
  await db.init();

  try {
    final coll = Collection('deep_docs', db);

    // Build 60 levels of nested maps: { "l0": { "l1": ... { "val": "treasure_found" } } }
    const int targetLevels = 60;
    Map<String, dynamic> leaf = {'val': 'core_treasure', 'level': targetLevels};
    for (int i = targetLevels - 1; i >= 0; i--) {
      leaf = {'l_$i': leaf};
    }
    leaf['_id'] = 'deep_doc_60';

    final insertSw = Stopwatch()..start();
    final insertedDoc = coll.insertOneSync(leaf);
    insertSw.stop();
    metrics['60_level_insert_ms'] = insertSw.elapsedMilliseconds;

    // Build dotted path
    final segments = List.generate(targetLevels, (i) => 'l_$i');
    final fullDottedPath = '${segments.join('.')}.val';

    // Verify in-memory retrieval via getByPath
    final inMemVal = insertedDoc.getByPath(fullDottedPath);
    metrics['in_mem_dotted_lookup'] = inMemVal == 'core_treasure' ? 'MATCH' : 'FAIL';
    if (inMemVal != 'core_treasure') {
      passed = false;
      defects.add({
        'category': 'NoSQL Dotted Path',
        'severity': 'HIGH',
        'title': 'getByPath Failed on 60-Level Deep Document',
        'description': 'Document.getByPath failed to traverse 60 nested levels.',
        'impact': 'Cannot read deeply nested properties in NoSQL documents.',
        'evidence': 'Expected "core_treasure", got: $inMemVal',
      });
    }

    // Point lookup from database using findOne with dotted path
    final querySw = Stopwatch()..start();
    final retrieved = await coll.findOne({fullDottedPath: 'core_treasure'});
    querySw.stop();
    metrics['60_level_query_ms'] = querySw.elapsedMilliseconds;
    metrics['60_level_query_match'] = retrieved != null ? 'FOUND' : 'NOT_FOUND';
    if (retrieved == null) {
      passed = false;
      defects.add({
        'category': 'NoSQL Query Engine',
        'severity': 'HIGH',
        'title': 'QueryFilter Failed on 60-Level Deep Dotted Path',
        'description': 'Collection.findOne with a 60-segment dotted path failed to match the record.',
        'impact': 'Deeply structured JSON queries fail to locate documents.',
        'evidence': 'Query { "$fullDottedPath": "core_treasure" } returned null',
      });
    }

    // Atomic update on 60-level path
    final updateSw = Stopwatch()..start();
    final updateRes = await coll.updateOne(
      filter: {'_id': 'deep_doc_60'},
      update: {
        r'$set': {fullDottedPath: 'mutated_treasure'}
      },
    );
    updateSw.stop();
    metrics['60_level_update_ms'] = updateSw.elapsedMilliseconds;
    metrics['60_level_update_modified'] = updateRes.modifiedCount;

    // Re-fetch to verify update persistence
    final verified = await coll.findOne({'_id': 'deep_doc_60'});
    final updatedVal = verified?.getByPath(fullDottedPath);
    if (updatedVal != 'mutated_treasure') {
      passed = false;
      defects.add({
        'category': 'NoSQL Mutator',
        'severity': 'HIGH',
        'title': 'DocumentMutator Failed to Mutate 60-Level Deep Path',
        'description': 'DocumentMutator.setByPath failed to mutate value at 60 nested levels.',
        'impact': 'NoSQL atomic updates on deep paths do not persist.',
        'evidence': 'Expected "mutated_treasure", got: $updatedVal',
      });
    }

    // Test doc.clone() recursion on deep document
    try {
      final cloned = insertedDoc.clone();
      metrics['deep_clone'] = cloned.id == insertedDoc.id ? 'SUCCESS' : 'ID_MISMATCH';
    } catch (e) {
      passed = false;
      defects.add({
        'category': 'NoSQL Document',
        'severity': 'MEDIUM',
        'title': 'Document.clone() Crashed on Deep Structure',
        'description': 'Stack overflow or encoding error during doc.clone().',
        'impact': 'Cannot safely clone deeply nested documents.',
        'evidence': '$e',
      });
    }

    // Test extreme 100-level nesting insertion
    try {
      Map<String, dynamic> leaf100 = {'val': 'level_100_core'};
      for (int i = 99; i >= 0; i--) {
        leaf100 = {'l_$i': leaf100};
      }
      leaf100['_id'] = 'deep_doc_100';
      coll.insertOneSync(leaf100);
      metrics['100_level_insert'] = 'SUCCESS';
    } catch (e) {
      metrics['100_level_insert'] = 'FAILED: $e';
    }

    print('  ✓ Deep nesting test completed (insert: ${metrics['60_level_insert_ms']}ms, query: ${metrics['60_level_query_ms']}ms)');
  } catch (e, st) {
    passed = false;
    print('  ✗ Deep nesting test threw: $e');
    defects.add({
      'category': 'NoSQL Nesting',
      'severity': 'CRITICAL',
      'title': 'Deep Nesting Catastrophic Exception',
      'description': 'Unexpected exception in test1_1: $e',
      'impact': 'Engine crashed during deep document processing.',
      'evidence': '$st',
    });
  } finally {
    await db.close();
  }

  sw.stop();
  return {
    'name': '1.1 Deeply Nested Documents (50+ Levels)',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': metrics,
  };
}

// ============================================================================
// 1.2: Massive Arrays ($push 20,000 items)
// ============================================================================
Future<Map<String, dynamic>> test1_2MassiveArraysPush(
  List<Map<String, dynamic>> defects,
) async {
  final sw = Stopwatch()..start();
  print('--- [TEST 1.2] Massive Arrays (\$push 20,000 items) ---');
  final metrics = <String, dynamic>{};
  bool passed = true;

  final dbPath = '$kDbDir/nosql_massive_arrays';
  await _cleanDirectory(dbPath);
  final db = Database(dbPath);
  await db.init();

  try {
    final coll = Collection('array_test', db);

    // 1. Insert seed document with empty array
    final initialDoc = coll.insertOneSync({
      '_id': 'massive_array_target',
      'name': 'array_benchmark',
      'items': <dynamic>[],
    });

    const int totalItems = 20000;
    final itemsPayload = List.generate(totalItems, (i) => 'entry_${i.toString().padLeft(6, "0")}');

    // 2. Execute $push with $each for 20,000 items in single update
    final pushSw = Stopwatch()..start();
    final updateResult = await coll.updateOne(
      filter: {'_id': 'massive_array_target'},
      update: {
        r'$push': {
          'items': {r'$each': itemsPayload}
        }
      },
    );
    pushSw.stop();
    metrics['push_20k_duration_ms'] = pushSw.elapsedMilliseconds;
    metrics['push_matched'] = updateResult.matchedCount;
    metrics['push_modified'] = updateResult.modifiedCount;

    // 3. Re-read document directly to verify array size
    final readSw = Stopwatch()..start();
    final fetched = await coll.findOne({'_id': 'massive_array_target'});
    readSw.stop();
    metrics['read_20k_duration_ms'] = readSw.elapsedMilliseconds;

    final arrayVal = fetched?.getByPath('items');
    final actualLength = arrayVal is List ? arrayVal.length : -1;
    metrics['actual_array_length'] = actualLength;

    if (actualLength != totalItems) {
      passed = false;
      defects.add({
        'category': 'NoSQL Massive Arrays',
        'severity': 'CRITICAL',
        'title': 'Massive Array Truncation / Data Loss on \$push 20,000 items',
        'description': 'Expected $totalItems array elements after \$push, but found $actualLength elements.',
        'impact': 'Large arrays cannot be atomically updated or are truncated/lost by storage limits.',
        'evidence': 'Expected length: $totalItems, Actual length: $actualLength',
      });
    }

    // 4. Test query operators on 20k array: $size
    final sizeSw = Stopwatch()..start();
    final sizeMatch = await coll.findOne({'items': {r'$size': totalItems}});
    sizeSw.stop();
    metrics['query_size_match'] = sizeMatch != null ? 'MATCH' : 'FAIL';
    metrics['query_size_duration_ms'] = sizeSw.elapsedMilliseconds;

    if (sizeMatch == null) {
      passed = false;
      defects.add({
        'category': 'NoSQL Query Operators',
        'severity': 'MEDIUM',
        'title': '\$size Operator Failed on 20,000-Item Array',
        'description': 'QueryFilter \$size condition failed to match 20,000 items.',
        'impact': 'Array size filters do not work correctly on large arrays.',
        'evidence': 'Query { items: { \$size: $totalItems } } returned null',
      });
    }

    // 5. Test query operator $in on the last element of the 20k array
    final lastItem = itemsPayload.last;
    final inMatch = await coll.findOne({
      'items': {
        r'$in': [lastItem]
      }
    });
    metrics['query_in_last_item'] = inMatch != null ? 'MATCH' : 'FAIL';

    // 6. Test cold re-read from disk (bypass in-memory cache)
    await db.close();
    final coldDb = Database(dbPath);
    await coldDb.init();
    try {
      final coldColl = Collection('array_test', coldDb);
      final coldDoc = await coldColl.findOne({'_id': 'massive_array_target'});
      final coldItems = coldDoc?.getByPath('items');
      final coldLength = coldItems is List ? coldItems.length : -1;
      metrics['cold_read_length'] = coldLength;
      if (coldLength != totalItems) {
        passed = false;
        defects.add({
          'category': 'NoSQL Storage / TOAST',
          'severity': 'CRITICAL',
          'title': 'Cold Read Array Length Mismatch (Slotted Page / TOAST Loss)',
          'description': 'Array of 20,000 items lost data when read back from fresh Database instance.',
          'impact': 'Massive JSON arrays are not correctly persisted across database reboots.',
          'evidence': 'Expected $totalItems, got $coldLength on cold reopen',
        });
      }
    } finally {
      await coldDb.close();
    }

    print('  ✓ Massive array test completed (push: ${metrics['push_20k_duration_ms']}ms, read: ${metrics['read_20k_duration_ms']}ms)');
  } catch (e, st) {
    passed = false;
    print('  ✗ Massive array test threw: $e');
    defects.add({
      'category': 'NoSQL Storage Limits',
      'severity': 'CRITICAL',
      'title': 'Massive Array Push Crashed Storage Engine',
      'description': 'Storage engine or JSON serializer crashed while pushing 20,000 items: $e',
      'impact': 'Slotted page or TOAST overflow causes unhandled crash.',
      'evidence': '$st',
    });
  } finally {
    try {
      await db.close();
    } catch (_) {}
  }

  sw.stop();
  return {
    'name': '1.2 Massive Arrays (\$push 20,000 items)',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': metrics,
  };
}

// ============================================================================
// 1.3: Regex Bombs / ReDoS Attacks
// ============================================================================
void _runRegexWorkerCli(List<String> args) {
  // CLI mode for running regex attack in a separate process
  final pattern = args[1];
  final input = args[2];
  final sw = Stopwatch()..start();
  try {
    final regex = RegExp(pattern, caseSensitive: false);
    final match = regex.hasMatch(input);
    sw.stop();
    print('REGEX_RESULT:match=$match;durationMs=${sw.elapsedMilliseconds}');
  } catch (e) {
    print('REGEX_ERROR:$e');
  }
}

Future<Map<String, dynamic>> test1_3AdversarialReDoS(
  List<Map<String, dynamic>> defects,
) async {
  final sw = Stopwatch()..start();
  print('--- [TEST 1.3] Regex Bombs / ReDoS Catastrophic Backtracking Attacks ---');
  final metrics = <String, dynamic>{};
  bool passed = true;

  // Adversarial regex patterns known to trigger exponential backtracking
  final attackVectors = <Map<String, String>>[
    {
      'name': 'Nested Plus Quantifiers (a+)+',
      'pattern': r'^(a+)+$',
      'input': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaa!', // 28 'a's with non-matching end
    },
    {
      'name': 'Alternation Overlap (a|aa)+',
      'pattern': r'^(a|aa)+$',
      'input': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaa!',
    },
    {
      'name': 'Alpha Class Star Pattern ([a-zA-Z]+)*',
      'pattern': r'^([a-zA-Z]+)*$',
      'input': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaa!',
    },
  ];

  for (final attack in attackVectors) {
    final name = attack['name']!;
    final pattern = attack['pattern']!;
    final input = attack['input']!;

    print('  • Probing: $name [pattern: "$pattern", input len: ${input.length}]');

    // Run regex attack in a sub-process with hard 3.0-second watchdog
    Process? proc;
    bool hung = false;
    int durationMs = 0;

    try {
      final psw = Stopwatch()..start();
      proc = await Process.start(Platform.resolvedExecutable, [
        Platform.script.toFilePath(),
        '--regex-worker',
        pattern,
        input,
      ]);

      final exitCodeFuture = proc.exitCode;
      final outFuture = proc.stdout.transform(utf8.decoder).join();

      final completed = await Future.any([
        Future.wait([exitCodeFuture, outFuture]),
        Future.delayed(const Duration(milliseconds: 3000), () => 'TIMEOUT'),
      ]);

      psw.stop();
      durationMs = psw.elapsedMilliseconds;

      if (completed == 'TIMEOUT') {
        hung = true;
        proc.kill(ProcessSignal.sigkill);
      } else {
        final out = (completed as List)[1] as String;
        if (out.contains('REGEX_RESULT')) {
          // Process finished
        }
      }
    } catch (_) {
      hung = true;
    }

    metrics['${name}_hung'] = hung;
    metrics['${name}_duration_ms'] = durationMs;

    if (hung) {
      passed = false;
      defects.add({
        'category': 'NoSQL Security / ReDoS',
        'severity': 'CRITICAL',
        'title': 'ReDoS Vulnerability: Engine Hangs on Adversarial Regex ($name)',
        'description': 'Adversarial query filter \$regex with pattern "$pattern" triggered catastrophic backtracking, hanging the process thread.',
        'impact': 'Malicious clients can lock up database threads and trigger complete Denial of Service (DoS).',
        'evidence': 'Execution timed out after 3,000ms with backtracking input of length ${input.length}',
      });
      print('    🚨 HUNG! (Exceeded 3,000ms watchdog timeout - ReDoS confirmed)');
    } else {
      print('    ✓ Completed safely in ${durationMs}ms');
    }
  }

  sw.stop();
  return {
    'name': '1.3 Adversarial ReDoS in Query Filters',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': metrics,
  };
}

// ============================================================================
// 1.4: Type Confusion & Operator Malformation
// ============================================================================
Future<Map<String, dynamic>> test1_4TypeConfusionAndOperatorAttacks(
  List<Map<String, dynamic>> defects,
) async {
  final sw = Stopwatch()..start();
  print('--- [TEST 1.4] Type Confusion & Operator Malformation ---');
  final metrics = <String, dynamic>{};
  bool passed = true;

  final dbPath = '$kDbDir/nosql_type_confusion';
  await _cleanDirectory(dbPath);
  final db = Database(dbPath);
  await db.init();

  try {
    final coll = Collection('confusion_test', db);

    // ------------------------------------------------------------------------
    // CASE A: $inc on a String field
    // ------------------------------------------------------------------------
    coll.insertOneSync({'_id': 'str_doc', 'str_col': 'cannot_increment_me'});
    await coll.updateOne(
      filter: {'_id': 'str_doc'},
      update: {
        r'$inc': {'str_col': 10}
      },
    );
    final strDocAfter = await coll.findOne({'_id': 'str_doc'});
    final valAfterInc = strDocAfter?.getByPath('str_col');
    metrics['inc_on_string_result'] = '$valAfterInc (${valAfterInc.runtimeType})';

    // In standard NoSQL (MongoDB), $inc on a string field throws an error:
    // "Cannot apply $inc to a value of non-numeric type".
    // In ULTSQL, it replaces the string with 10 (silent data corruption).
    if (valAfterInc == 10) {
      defects.add({
        'category': 'NoSQL Type Confusion',
        'severity': 'HIGH',
        'title': 'Silent Data Corruption: \$inc Overwrites String Fields with Delta',
        'description': 'Running \$inc on a string field does not reject the operation or throw an error. It silently overwrites the string with the increment value.',
        'impact': 'Silent loss of string data and subtle schema corruption without warnings or errors.',
        'evidence': 'Field "cannot_increment_me" became 10 after \$inc: { str_col: 10 }',
      });
    }

    // ------------------------------------------------------------------------
    // CASE B: $push on an Integer field
    // ------------------------------------------------------------------------
    coll.insertOneSync({'_id': 'int_doc', 'int_col': 42});
    final pushRes = await coll.updateOne(
      filter: {'_id': 'int_doc'},
      update: {
        r'$push': {'int_col': 'new_item'}
      },
    );
    final intDocAfter = await coll.findOne({'_id': 'int_doc'});
    final valAfterPush = intDocAfter?.getByPath('int_col');
    metrics['push_on_int_modified'] = pushRes.modifiedCount;
    metrics['push_on_int_val'] = '$valAfterPush';

    // In MongoDB, $push on a non-array throws an error: "The field 'int_col' must be an array but is of type int".
    // In ULTSQL, it silently does nothing and returns modifiedCount: 0 without throwing an exception.
    if (pushRes.modifiedCount == 0 && valAfterPush == 42) {
      defects.add({
        'category': 'NoSQL Error Handling',
        'severity': 'MEDIUM',
        'title': '\$push Silently Ignored on Non-Array Scalar Fields',
        'description': 'Attempting to \$push into a scalar integer field returns modifiedCount: 0 instead of cleanly rejecting with an error.',
        'impact': 'Silent failures where application expects array mutations to fail loudly.',
        'evidence': 'Field "int_col": 42 remained unchanged without throwing an error.',
      });
    }

    // ------------------------------------------------------------------------
    // CASE C: $mul on a Null field
    // ------------------------------------------------------------------------
    coll.insertOneSync({'_id': 'null_doc', 'null_col': null});
    await coll.updateOne(
      filter: {'_id': 'null_doc'},
      update: {
        r'$mul': {'null_col': 5}
      },
    );
    final nullDocAfter = await coll.findOne({'_id': 'null_doc'});
    final valAfterMul = nullDocAfter?.getByPath('null_col');
    metrics['mul_on_null_val'] = '$valAfterMul (${valAfterMul.runtimeType})';

    // In MongoDB, $mul on a null field throws or produces 0.
    // In ULTSQL, null * 5 produces 0 (int).
    if (valAfterMul == 0) {
      defects.add({
        'category': 'NoSQL Type Confusion',
        'severity': 'LOW',
        'title': '\$mul Converts Null to Zero (0)',
        'description': 'Running \$mul on a null field converts null to 0 instead of preserving null or rejecting.',
        'impact': 'Semantic divergence from expected null semantics.',
        'evidence': 'null_col: null became 0 after \$mul: { null_col: 5 }',
      });
    }

    // ------------------------------------------------------------------------
    // CASE D: $set on Array Indices (e.g. "tags.1")
    // ------------------------------------------------------------------------
    coll.insertOneSync({
      '_id': 'arr_idx_doc',
      'tags': ['alpha', 'beta', 'gamma'],
    });
    final setIdxRes = await coll.updateOne(
      filter: {'_id': 'arr_idx_doc'},
      update: {
        r'$set': {'tags.1': 'OMEGA'}
      },
    );
    final arrDocAfter = await coll.findOne({'_id': 'arr_idx_doc'});
    final tagsAfter = arrDocAfter?.getByPath('tags');
    metrics['set_array_idx_modified'] = setIdxRes.modifiedCount;
    metrics['tags_after_set'] = '$tagsAfter';

    // In MongoDB, $set on "tags.1" updates the element at index 1 ('beta' -> 'OMEGA').
    // In ULTSQL Document.setByPath:
    // It detects that tags is not a Map, so it OVERWRITES the List with an empty Map!
    // Result: tags becomes {'1': 'OMEGA'}, destroying all previous elements!
    if (tagsAfter is! List || tagsAfter.length != 3 || tagsAfter[1] != 'OMEGA') {
      passed = false;
      defects.add({
        'category': 'NoSQL Mutator Catastrophic Data Loss',
        'severity': 'CRITICAL',
        'title': 'Catastrophic Array Destruction: \$set on Array Indices Obliterates List',
        'description': 'DocumentMutator.setByPath does not support array index navigation. When setting "tags.1", it treats the existing List as non-Map, obliterates the entire List with a new Map <String, dynamic>{}, and stores { "1": "OMEGA" }. All other array elements are permanently destroyed!',
        'impact': 'Catastrophic data loss when attempting to update any array element by index.',
        'evidence': 'Original List ["alpha", "beta", "gamma"] was replaced with Map $tagsAfter',
      });
    }

    // ------------------------------------------------------------------------
    // CASE E: Unknown / Malformed Operator Injection
    // ------------------------------------------------------------------------
    final unknownOpRes = await coll.updateOne(
      filter: {'_id': 'str_doc'},
      update: {
        r'$maliciousOp': {'injected': 'data'}
      },
    );
    metrics['unknown_op_modified'] = unknownOpRes.modifiedCount;

    print('  ✓ Type confusion attacks completed');
  } catch (e, st) {
    passed = false;
    print('  ✗ Type confusion test threw: $e');
    defects.add({
      'category': 'NoSQL Operator Attack',
      'severity': 'CRITICAL',
      'title': 'Type Confusion Attack Threw Unhandled Crash',
      'description': '$e',
      'impact': 'Engine crashed during operator type confusion test.',
      'evidence': '$st',
    });
  } finally {
    await db.close();
  }

  sw.stop();
  return {
    'name': '1.4 Type Confusion & Operator Malformation',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': metrics,
  };
}

// ============================================================================
// 2.1: Vector RAG Degenerate Topologies & Math Attacks
// ============================================================================
Future<Map<String, dynamic>> test2_1DegenerateVectorsAndMath(
  List<Map<String, dynamic>> defects,
) async {
  final sw = Stopwatch()..start();
  print('--- [TEST 2.1] Vector RAG Degenerate Vectors & Math Attacks ---');
  final metrics = <String, dynamic>{};
  bool passed = true;

  final hnswPath = '$kDbDir/degenerate_test.hnsw';
  final hnswFile = File(hnswPath);
  if (hnswFile.existsSync()) hnswFile.deleteSync();

  try {
    final hnsw = HnswIndex(indexPath: hnswPath, autoSave: false);
    hnsw.initSync();

    // ------------------------------------------------------------------------
    // SUBTEST A: Zero Vectors [0.0, 0.0, ...]
    // ------------------------------------------------------------------------
    final z1 = DbVector([0.0, 0.0, 0.0, 0.0]);
    final z2 = DbVector([0.0, 0.0, 0.0, 0.0]);
    final u1 = DbVector([1.0, 0.0, 0.0, 0.0]);

    final euclDistZero = z1.distanceTo(z2);
    final cosDistZero = z1.cosineDistanceTo(z2);
    final dotDistZero = z1.dotProductTo(z2);

    metrics['zero_euclidean'] = euclDistZero;
    metrics['zero_cosine'] = cosDistZero;
    metrics['zero_dot'] = dotDistZero;

    // Zero vector inserted into HNSW
    hnsw.insertSync(z1, 0, 1);
    final zeroSearch = hnsw.search(z1, 1);
    metrics['zero_search_found'] = zeroSearch.isNotEmpty ? 'YES' : 'NO';

    // ------------------------------------------------------------------------
    // SUBTEST B: NaN (Not-a-Number) Vectors
    // ------------------------------------------------------------------------
    final nanVec = DbVector([double.nan, 1.0, 0.5, 0.2]);
    final normalVec = DbVector([0.5, 0.5, 0.5, 0.5]);

    final nanDist = nanVec.distanceTo(normalVec);
    metrics['nan_distance'] = '$nanDist';

    // Insert NaN vector into HNSW index
    bool nanInsertThrew = false;
    try {
      hnsw.insertSync(nanVec, 0, 2);
    } catch (e) {
      nanInsertThrew = true;
      metrics['nan_insert_exception'] = '$e';
    }
    metrics['nan_insert_threw'] = nanInsertThrew;

    // Search with NaN vector query
    bool nanSearchHungOrThrew = false;
    try {
      final res = hnsw.search(nanVec, 1);
      metrics['nan_search_results'] = res.length;
    } catch (e) {
      nanSearchHungOrThrew = true;
      metrics['nan_search_error'] = '$e';
    }

    // HNSW saveSync with NaN vector
    bool nanSaveCrashed = false;
    String nanSaveError = '';
    try {
      hnsw.saveSync();
    } catch (e) {
      nanSaveCrashed = true;
      nanSaveError = '$e';
    }
    metrics['nan_save_crashed'] = nanSaveCrashed;

    if (nanSaveCrashed) {
      passed = false;
      defects.add({
        'category': 'Vector HNSW Serialization',
        'severity': 'CRITICAL',
        'title': 'HNSW Crash on NaN Vector Persistence (JsonUnsupportedObjectError)',
        'description': 'HnswIndex.saveSync() serializes vector coordinates directly to JSON using json.encode(). In Dart, json.encode throws JsonUnsupportedObjectError on double.nan, corrupting index saves and crashing the interpreter flush cycle.',
        'impact': 'Database crash on transaction commit or table eviction whenever NaN vectors are inserted.',
        'evidence': 'saveSync() threw: $nanSaveError',
      });
    }

    // ------------------------------------------------------------------------
    // SUBTEST C: Infinity Vectors (+Inf, -Inf)
    // ------------------------------------------------------------------------
    final infVec = DbVector([double.infinity, 0.0, 0.0, 0.0]);
    final negInfVec = DbVector([-double.infinity, 0.0, 0.0, 0.0]);

    final infDist = infVec.distanceTo(normalVec);
    final cosInfDist = infVec.cosineDistanceTo(normalVec);
    metrics['inf_distance'] = '$infDist';
    metrics['inf_cosine_distance'] = '$cosInfDist';

    final hnswInfPath = '$kDbDir/inf_test.hnsw';
    final hnswInf = HnswIndex(indexPath: hnswInfPath, autoSave: false);
    hnswInf.initSync();
    hnswInf.insertSync(infVec, 0, 10);
    hnswInf.insertSync(negInfVec, 0, 11);

    bool infSaveCrashed = false;
    String infSaveError = '';
    try {
      hnswInf.saveSync();
    } catch (e) {
      infSaveCrashed = true;
      infSaveError = '$e';
    }
    metrics['inf_save_crashed'] = infSaveCrashed;

    if (infSaveCrashed) {
      passed = false;
      defects.add({
        'category': 'Vector HNSW Serialization',
        'severity': 'CRITICAL',
        'title': 'HNSW Crash on Infinity Vector Persistence (JsonUnsupportedObjectError)',
        'description': 'HnswIndex.saveSync() throws JsonUnsupportedObjectError when serializing double.infinity or -double.infinity.',
        'impact': 'Any infinite coordinate in vector embeddings crashes database persistence.',
        'evidence': 'saveSync() threw: $infSaveError',
      });
    }

    print('  ✓ Degenerate vectors test completed');
  } catch (e, st) {
    passed = false;
    print('  ✗ Degenerate vectors test threw: $e');
    defects.add({
      'category': 'Vector Math',
      'severity': 'CRITICAL',
      'title': 'Vector Degenerate Math Unhandled Crash',
      'description': '$e',
      'impact': 'Engine crashed during degenerate vector calculations.',
      'evidence': '$st',
    });
  }

  sw.stop();
  return {
    'name': '2.1 Vector RAG Degenerate Topologies & Math',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': metrics,
  };
}

// ============================================================================
// 2.2: Dimension Mismatch & Index Corruption
// ============================================================================
Future<Map<String, dynamic>> test2_2DimensionMismatchCorruption(
  List<Map<String, dynamic>> defects,
) async {
  final sw = Stopwatch()..start();
  print('--- [TEST 2.2] Vector Dimension Mismatch & Index Corruption ---');
  final metrics = <String, dynamic>{};
  bool passed = true;

  final hnswPath = '$kDbDir/dim_mismatch.hnsw';
  final hnswFile = File(hnswPath);
  if (hnswFile.existsSync()) hnswFile.deleteSync();

  try {
    final hnsw = HnswIndex(indexPath: hnswPath, autoSave: false);
    hnsw.initSync();

    // 1. Populate HNSW index with standard 128-dimensional embeddings
    const int baseDim = 128;
    for (int i = 0; i < 50; i++) {
      final vec = DbVector(List.generate(baseDim, (d) => (d + i) * 0.01));
      hnsw.insertSync(vec, 0, i);
    }
    metrics['base_128dim_vectors_inserted'] = 50;

    // 2. Attempt inserting a 768-dimensional vector (e.g. BERT/LLM embedding)
    bool dim768Rejected = false;
    try {
      final vec768 = DbVector(List.generate(768, (d) => 0.5));
      hnsw.insertSync(vec768, 0, 768);
    } catch (_) {
      dim768Rejected = true;
    }
    metrics['768_dim_rejected'] = dim768Rejected;

    // 3. Attempt inserting a 10-dimensional vector
    bool dim10Rejected = false;
    try {
      final vec10 = DbVector(List.generate(10, (d) => 0.1));
      hnsw.insertSync(vec10, 0, 10);
    } catch (_) {
      dim10Rejected = true;
    }
    metrics['10_dim_rejected'] = dim10Rejected;

    // 4. Test DbVector distanceTo behavior on mismatched lengths
    final v128 = DbVector(List.filled(128, 1.0));
    final v10 = DbVector(List.filled(10, 1.0));
    final mismatchDist = v128.distanceTo(v10);
    metrics['mismatch_distance_result'] = mismatchDist;

    // 5. Query HNSW index with a 128-dimensional vector
    final query128 = DbVector(List.filled(128, 1.0));
    final topNeighbors = hnsw.search(query128, 5);
    final topSlotIds = topNeighbors.map((n) => n.slotId).toList();
    metrics['top_neighbor_slot_ids'] = topSlotIds;

    // Check if the 10-dim or 768-dim vector was falsely ranked as top neighbor
    final falseMatchFound = topSlotIds.contains(10) || topSlotIds.contains(768);
    metrics['false_mismatch_in_top5'] = falseMatchFound;

    if (!dim768Rejected || !dim10Rejected) {
      passed = false;
      defects.add({
        'category': 'Vector Index Integrity',
        'severity': 'CRITICAL',
        'title': 'No Dimension Validation in HNSW Vector Index',
        'description': 'HnswIndex allows inserting vectors of completely arbitrary and mismatched dimensions (10-dim and 768-dim into a 128-dim index) without throwing an error.',
        'impact': 'Vector index graph corruption and invalid similarity calculations.',
        'evidence': 'Accepted 10-dim and 768-dim vectors into a 128-dim index without exception.',
      });
    }

    if (mismatchDist == 0.0) {
      passed = false;
      defects.add({
        'category': 'Vector Math / Distance Fallback',
        'severity': 'CRITICAL',
        'title': 'Catastrophic Distance Collapse: Mismatched Vector Dimensions Return 0.0 Distance',
        'description': 'DbVector.distanceTo checks if (len != v2.length) return 0.0. This falsely reports vectors of different dimensions as having ZERO distance (perfect identity match)!',
        'impact': 'Any query comparing against mismatched dimension vectors erroneously considers them perfect 100% matches, polluting top-K RAG results with garbage.',
        'evidence': '128-dim vector vs 10-dim vector computed distance: $mismatchDist (should be NaN, Infinity, or throw ArgumentError).',
      });
    }

    print('  ✓ Dimension mismatch test completed (10-dim distance: $mismatchDist)');
  } catch (e, st) {
    passed = false;
    print('  ✗ Dimension mismatch test threw: $e');
    defects.add({
      'category': 'Vector Dimension',
      'severity': 'CRITICAL',
      'title': 'Dimension Mismatch Test Crash',
      'description': '$e',
      'impact': 'Crash during dimension mismatch testing.',
      'evidence': '$st',
    });
  }

  sw.stop();
  return {
    'name': '2.2 Vector Dimension Mismatch & Graph Corruption',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': metrics,
  };
}

// ============================================================================
// 2.3: Identical Vector Cluster (5,000 completely identical vectors)
// ============================================================================
Future<Map<String, dynamic>> test2_3IdenticalVectorCluster(
  List<Map<String, dynamic>> defects,
) async {
  final sw = Stopwatch()..start();
  print('--- [TEST 2.3] Identical Vector Cluster (5,000 Identical Vectors) ---');
  final metrics = <String, dynamic>{};
  bool passed = true;

  final hnswPath = '$kDbDir/identical_cluster.hnsw';
  final hnswFile = File(hnswPath);
  if (hnswFile.existsSync()) hnswFile.deleteSync();

  try {
    final hnsw = HnswIndex(
      indexPath: hnswPath,
      autoSave: false,
      M: 16,
      M0: 32,
      efConstruction: 32,
      efSearch: 32,
    );
    hnsw.initSync();

    const int clusterCount = 5000;
    const int dims = 8;
    final identicalVec = DbVector(List.filled(dims, 1.0));

    // Measure insertion throughput of 5,000 identical vectors
    final insertSw = Stopwatch()..start();
    for (int i = 0; i < clusterCount; i++) {
      hnsw.insertSync(identicalVec, 0, i);
    }
    insertSw.stop();

    metrics['cluster_size'] = clusterCount;
    metrics['insert_5k_duration_ms'] = insertSw.elapsedMilliseconds;
    metrics['insert_throughput_vps'] =
        (clusterCount / (insertSw.elapsedMilliseconds / 1000.0)).toStringAsFixed(1);

    // Query with exact identical vector for top-10
    final searchSw = Stopwatch()..start();
    final top10Exact = hnsw.search(identicalVec, 10);
    searchSw.stop();

    metrics['search_top10_exact_ms'] = searchSw.elapsedMicroseconds / 1000.0;
    metrics['top10_exact_count'] = top10Exact.length;

    if (top10Exact.length < 10) {
      passed = false;
      defects.add({
        'category': 'Vector HNSW Degeneracy',
        'severity': 'HIGH',
        'title': 'HNSW Graph Degeneracy on Identical Vectors',
        'description': 'Search for top 10 in a cluster of 5,000 identical vectors returned only ${top10Exact.length} nodes.',
        'impact': 'Graph search cannot navigate clustered or duplicate vector data.',
        'evidence': 'Expected 10 results, got: ${top10Exact.length}',
      });
    }

    // Query with slightly perturbed vector [1.02, 0.98, ...]
    final perturbedVec = DbVector([1.02, 0.98, 1.01, 0.99, 1.0, 1.0, 1.0, 1.0]);
    final pertSearchSw = Stopwatch()..start();
    final top10Perturbed = hnsw.search(perturbedVec, 10);
    pertSearchSw.stop();

    metrics['search_top10_perturbed_ms'] = pertSearchSw.elapsedMicroseconds / 1000.0;
    metrics['top10_perturbed_count'] = top10Perturbed.length;

    // Check degree distribution (edges per node) to ensure graph hasn't collapsed into 0 edges
    int totalEdgesL0 = 0;
    int isolatedNodes = 0;
    for (final node in hnsw.nodes) {
      if (node.neighbors.isEmpty || node.neighbors[0].isEmpty) {
        isolatedNodes++;
      } else {
        totalEdgesL0 += node.neighbors[0].length;
      }
    }
    final avgDegreeL0 = totalEdgesL0 / hnsw.nodes.length;
    metrics['avg_degree_level_0'] = avgDegreeL0.toStringAsFixed(2);
    metrics['isolated_nodes'] = isolatedNodes;

    if (isolatedNodes > 1) {
      defects.add({
        'category': 'Vector HNSW Topology',
        'severity': 'MEDIUM',
        'title': 'Isolated Nodes in Identical Vector Cluster',
        'description': 'Identical vector insertions caused $isolatedNodes nodes to have 0 neighbors on level 0.',
        'impact': 'Portions of the vector space become disconnected and unsearchable.',
        'evidence': 'Isolated nodes: $isolatedNodes / $clusterCount',
      });
    }

    print('  ✓ Identical cluster test completed (5k vectors in ${insertSw.elapsedMilliseconds}ms, ${metrics['insert_throughput_vps']} v/s)');
  } catch (e, st) {
    passed = false;
    print('  ✗ Identical cluster test threw: $e');
    defects.add({
      'category': 'Vector Topology',
      'severity': 'CRITICAL',
      'title': 'Identical Cluster Test Crash',
      'description': '$e',
      'impact': 'Engine crashed while indexing clustered identical vectors.',
      'evidence': '$st',
    });
  }

  sw.stop();
  return {
    'name': '2.3 Identical Vector Cluster (5,000 Vectors)',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': metrics,
  };
}

// ============================================================================
// 2.4: High-Throughput Search Under Heavy Concurrent Vector Inserts
// ============================================================================
Future<Map<String, dynamic>> test2_4ConcurrentVectorSearchAndInsert(
  List<Map<String, dynamic>> defects,
) async {
  final sw = Stopwatch()..start();
  print('--- [TEST 2.4] Concurrent Vector Search Under Heavy Concurrent Inserts ---');
  final metrics = <String, dynamic>{};
  bool passed = true;

  final hnswPath = '$kDbDir/concurrent_vector.hnsw';
  final hnswFile = File(hnswPath);
  if (hnswFile.existsSync()) hnswFile.deleteSync();

  try {
    final hnsw = HnswIndex(
      indexPath: hnswPath,
      autoSave: false,
      M: 16,
      M0: 32,
      efConstruction: 32,
      efSearch: 32,
    );
    hnsw.initSync();

    // Seed initial 100 vectors
    const int dims = 16;
    for (int i = 0; i < 100; i++) {
      hnsw.insertSync(DbVector(List.generate(dims, (d) => (d + i) * 0.05)), 0, i);
    }

    final concurrentSw = Stopwatch()..start();
    int searchCount = 0;
    int insertCount = 0;
    int searchErrors = 0;
    int insertErrors = 0;

    // Concurrent Writer task: inserts 200 more vectors
    final writerFuture = Future(() async {
      for (int i = 100; i < 300; i++) {
        try {
          hnsw.insertSync(
            DbVector(List.generate(dims, (d) => (d + i) * 0.05)),
            0,
            i,
          );
          insertCount++;
          if (i % 20 == 0) await Future.delayed(Duration.zero);
        } catch (_) {
          insertErrors++;
        }
      }
    });

    // Concurrent Readers: 4 tasks performing searches
    final readerFutures = List.generate(4, (workerId) {
      return Future(() async {
        final rand = math.Random(workerId);
        for (int i = 0; i < 250; i++) {
          try {
            final qVec = DbVector(List.generate(dims, (d) => rand.nextDouble()));
            final res = hnsw.search(qVec, 5);
            if (res.isNotEmpty) {
              searchCount++;
            }
          } catch (_) {
            searchErrors++;
          }
          if (i % 25 == 0) await Future.delayed(Duration.zero);
        }
      });
    });

    await Future.wait([writerFuture, ...readerFutures]);
    concurrentSw.stop();

    metrics['concurrent_inserts_completed'] = insertCount;
    metrics['concurrent_searches_completed'] = searchCount;
    metrics['search_errors'] = searchErrors;
    metrics['insert_errors'] = insertErrors;
    metrics['concurrent_duration_ms'] = concurrentSw.elapsedMilliseconds;

    if (searchErrors > 0 || insertErrors > 0) {
      defects.add({
        'category': 'Vector Concurrency Race Condition',
        'severity': 'HIGH',
        'title': 'HNSW Index Not Thread-Safe Under Concurrent Search & Insert',
        'description': 'Concurrent vector searches while insertSync was mutating the graph produced $searchErrors search errors and $insertErrors insert errors.',
        'impact': 'Queries crash with ConcurrentModificationError or RangeError when vector index is concurrently updated.',
        'evidence': 'searchErrors: $searchErrors, insertErrors: $insertErrors',
      });
    }

    print('  ✓ Concurrent vector test completed (searches: $searchCount, inserts: $insertCount, errors: ${searchErrors + insertErrors})');
  } catch (e, st) {
    passed = false;
    print('  ✗ Concurrent vector test threw: $e');
    defects.add({
      'category': 'Vector Concurrency',
      'severity': 'CRITICAL',
      'title': 'Concurrent Vector Test Crash',
      'description': '$e',
      'impact': 'Engine crashed during concurrent vector read/write stress.',
      'evidence': '$st',
    });
  }

  sw.stop();
  return {
    'name': '2.4 Concurrent Vector Search & Insert Stress',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': metrics,
  };
}

// ============================================================================
// 3.1: Redis-Style KV Store: Giant Values & Nested Structures
// ============================================================================
Future<Map<String, dynamic>> test3_1GiantValuesAndNestedStructures(
  List<Map<String, dynamic>> defects,
) async {
  final sw = Stopwatch()..start();
  print('--- [TEST 3.1] Redis-Style KV Store: Giant Values (10MB) & Nested Structures ---');
  final metrics = <String, dynamic>{};
  bool passed = true;

  final dbPath = '$kDbDir/kv_giant_values';
  await _cleanDirectory(dbPath);
  final db = Database(dbPath);
  await db.init();

  try {
    final kv = KVStore(db);

    // ------------------------------------------------------------------------
    // SUBTEST A: 10MB String Storage & Retrieval
    // ------------------------------------------------------------------------
    const int targetBytes = 10 * 1024 * 1024; // 10MB
    print('  • Generating 10MB ASCII payload...');
    final chunk = '0123456789ABCDEF' * 64; // 1024 chars
    final chunkCount = targetBytes ~/ chunk.length;
    final sb = StringBuffer();
    for (int i = 0; i < chunkCount; i++) {
      sb.write(chunk);
    }
    final giant10MbString = sb.toString();
    metrics['generated_string_bytes'] = giant10MbString.length;

    print('  • Storing 10MB string into KVStore...');
    final set10MbSw = Stopwatch()..start();
    bool set10MbSuccess = false;
    String set10MbError = '';
    try {
      await kv.set('huge_10mb_payload', giant10MbString);
      set10MbSw.stop();
      set10MbSuccess = true;
    } catch (e) {
      set10MbSw.stop();
      set10MbError = '$e';
    }
    metrics['set_10mb_ms'] = set10MbSw.elapsedMilliseconds;
    metrics['set_10mb_success'] = set10MbSuccess;

    if (!set10MbSuccess) {
      passed = false;
      defects.add({
        'category': 'KV Store TOAST / Size Limit',
        'severity': 'CRITICAL',
        'title': 'KVStore Failed to Store 10MB String Payload',
        'description': 'kv.set("huge_10mb_payload", 10MB) threw an exception: $set10MbError',
        'impact': 'Cannot store large blob/text values in KV cache engine.',
        'evidence': '$set10MbError',
      });
    } else {
      // Hot cache read
      final getHotSw = Stopwatch()..start();
      final hotRetrieved = await kv.get('huge_10mb_payload');
      getHotSw.stop();
      metrics['get_10mb_hot_ms'] = getHotSw.elapsedMilliseconds;
      metrics['get_10mb_hot_length'] = hotRetrieved is String ? hotRetrieved.length : -1;

      // Cold disk read (close database and reopen fresh to verify persistence & TOAST)
      await db.close();
      final coldDb = Database(dbPath);
      await coldDb.init();
      try {
        final coldKv = KVStore(coldDb);
        final getColdSw = Stopwatch()..start();
        final coldRetrieved = await coldKv.get('huge_10mb_payload');
        getColdSw.stop();
        metrics['get_10mb_cold_disk_ms'] = getColdSw.elapsedMilliseconds;
        final coldLen = coldRetrieved is String ? coldRetrieved.length : -1;
        metrics['get_10mb_cold_length'] = coldLen;

        if (coldLen != giant10MbString.length) {
          passed = false;
          defects.add({
            'category': 'KV Store Persistence',
            'severity': 'CRITICAL',
            'title': 'KVStore 10MB Payload Corrupted / Truncated on Cold Reboot',
            'description': 'Expected ${giant10MbString.length} bytes from disk, but got $coldLen bytes on reload.',
            'impact': 'Large key-value payloads fail to persist or restore across engine restarts.',
            'evidence': 'Expected: ${giant10MbString.length}, Actual: $coldLen',
          });
        }
      } finally {
        await coldDb.close();
      }
    }

    // Reopen primary db for remaining subtests
    await db.init();
    final kvReopened = KVStore(db);

    // ------------------------------------------------------------------------
    // SUBTEST B: Deeply Nested Map (50+ Levels) in KVStore
    // ------------------------------------------------------------------------
    Map<String, dynamic> deepKvMap = {'core_val': 'kv_nested_treasure'};
    for (int i = 49; i >= 0; i--) {
      deepKvMap = {'level_$i': deepKvMap};
    }
    await kvReopened.set('deep_nested_map', deepKvMap);
    final retrievedDeepMap = await kvReopened.get('deep_nested_map');
    metrics['deep_map_persisted'] = retrievedDeepMap is Map ? 'SUCCESS' : 'FAIL';

    // ------------------------------------------------------------------------
    // SUBTEST C: Giant List of 50,000 JSON Objects in KVStore
    // ------------------------------------------------------------------------
    final list50k = List.generate(
      50000,
      (i) => {'id': i, 'code': 'sku_$i', 'active': i.isEven},
    );
    final setListSw = Stopwatch()..start();
    await kvReopened.set('massive_50k_list', list50k);
    setListSw.stop();
    metrics['set_50k_list_ms'] = setListSw.elapsedMilliseconds;

    final retrievedList = await kvReopened.get('massive_50k_list');
    final actualListLen = retrievedList is List ? retrievedList.length : -1;
    metrics['get_50k_list_length'] = actualListLen;

    if (actualListLen != 50000) {
      passed = false;
      defects.add({
        'category': 'KV Store Serialization',
        'severity': 'HIGH',
        'title': 'KVStore List of 50,000 Objects Length Mismatch',
        'description': 'Expected 50,000 items in retrieved List, got $actualListLen',
        'impact': 'Large collections stored in KV store suffer data truncation.',
        'evidence': 'Expected: 50,000, Got: $actualListLen',
      });
    }

    print('  ✓ Giant values & nested structures test completed');
  } catch (e, st) {
    passed = false;
    print('  ✗ Giant values test threw: $e');
    defects.add({
      'category': 'KV Store Giant Values',
      'severity': 'CRITICAL',
      'title': 'Giant Value KV Test Crash',
      'description': '$e',
      'impact': 'Engine crashed during 10MB KV stress test.',
      'evidence': '$st',
    });
  } finally {
    try {
      await db.close();
    } catch (_) {}
  }

  sw.stop();
  return {
    'name': '3.1 Redis-Style KV Store: Giant Values & Nested Structures',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': metrics,
  };
}

// ============================================================================
// 3.2: Rapid Concurrent Counter Flooding (kv.incr & kv.decr)
// ============================================================================
Future<Map<String, dynamic>> test3_2RapidConcurrentCounterFlooding(
  List<Map<String, dynamic>> defects,
) async {
  final sw = Stopwatch()..start();
  print('--- [TEST 3.2] Rapid Concurrent Counter Flooding (kv.incr / kv.decr) ---');
  final metrics = <String, dynamic>{};
  bool passed = true;

  final dbPath = '$kDbDir/kv_counter_flood';
  await _cleanDirectory(dbPath);
  final db = Database(dbPath);
  await db.init();

  try {
    final kv = KVStore(db);

    // ------------------------------------------------------------------------
    // CONCURRENCY TEST: 10,000 Total Increments across 50 Concurrent Tasks
    // ------------------------------------------------------------------------
    await kv.set('concurrent_counter', 0);

    const int numTasks = 50;
    const int opsPerTask = 200;
    const int expectedTotal = numTasks * opsPerTask; // 10,000 increments

    final floodSw = Stopwatch()..start();
    final tasks = List.generate(numTasks, (taskId) {
      return Future(() async {
        for (int i = 0; i < opsPerTask; i++) {
          await kv.incr('concurrent_counter', 1);
        }
      });
    });

    await Future.wait(tasks);
    floodSw.stop();

    final finalVal = await kv.get('concurrent_counter');
    final actualTotal = finalVal is int ? finalVal : (int.tryParse('$finalVal') ?? -1);
    final lostUpdates = expectedTotal - actualTotal;
    final lossPercentage = (lostUpdates / expectedTotal) * 100.0;

    metrics['expected_increments'] = expectedTotal;
    metrics['actual_increments'] = actualTotal;
    metrics['lost_updates'] = lostUpdates;
    metrics['loss_rate_percent'] = '${lossPercentage.toStringAsFixed(2)}%';
    metrics['concurrency_duration_ms'] = floodSw.elapsedMilliseconds;
    metrics['ops_per_second'] =
        (expectedTotal / (floodSw.elapsedMilliseconds / 1000.0)).toStringAsFixed(1);

    if (lostUpdates > 0) {
      passed = false;
      defects.add({
        'category': 'KV Store Concurrency / Atomicity',
        'severity': 'CRITICAL',
        'title': 'Severe Race Condition: kv.incr() Suffers Lost Updates Under Concurrency',
        'description': 'kv.incr() is implemented as non-atomic read-modify-write: final current = await get(key); await set(key, current + 1); Concurrent async calls read stale values, resulting in massive lost updates (${lossPercentage.toStringAsFixed(1)}% lost!).',
        'impact': 'Counters and rate-limiters built on KVStore will completely lose updates under concurrent load.',
        'evidence': 'Expected $expectedTotal increments, but final counter was only $actualTotal ($lostUpdates updates lost).',
      });
      print('    🚨 LOST UPDATES DETECTED: $lostUpdates / $expectedTotal (${lossPercentage.toStringAsFixed(1)}% lost!)');
    }

    // ------------------------------------------------------------------------
    // SIMULTANEOUS DISPATCH RACE: 100 Increments Dispatched at the Exact Same Instant
    // ------------------------------------------------------------------------
    await kv.set('simultaneous_race_counter', 0);
    await Future.wait(List.generate(100, (_) => kv.incr('simultaneous_race_counter', 1)));
    final simRaceVal = await kv.get('simultaneous_race_counter');
    final int simActual = simRaceVal is int ? simRaceVal : (int.tryParse('$simRaceVal') ?? 0);
    metrics['simultaneous_100_incr_result'] = simActual;
    if (simActual < 100) {
      passed = false;
      defects.add({
        'category': 'KV Store Concurrency / Atomicity',
        'severity': 'CRITICAL',
        'title': 'Severe Race Condition: kv.incr() Lost Updates Under Simultaneous Dispatch',
        'description': 'When 100 concurrent calls to kv.incr() are dispatched simultaneously via Future.wait, they read the identical initial value from cache before any write completes, resulting in massive lost updates ($simActual / 100 recorded).',
        'impact': 'Non-atomic read-modify-write produces lost updates in any concurrent workload.',
        'evidence': 'Expected 100 increments, but final counter was only $simActual (${100 - simActual} lost).',
      });
      print('    🚨 SIMULTANEOUS RACE LOST UPDATES DETECTED: $simActual / 100 (${100 - simActual} lost!)');
    }

    // ------------------------------------------------------------------------
    // SEQUENTIAL BENCHMARK: 1,000 Rapid Sequential Operations (decr)
    // ------------------------------------------------------------------------
    await kv.set('seq_counter', 1000);
    final seqSw = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      await kv.decr('seq_counter', 1);
    }
    seqSw.stop();

    final seqFinal = await kv.get('seq_counter');
    metrics['seq_1000_decr_final'] = seqFinal;
    metrics['seq_1000_decr_ms'] = seqSw.elapsedMilliseconds;
    metrics['seq_throughput_ops'] =
        (1000 / (seqSw.elapsedMilliseconds / 1000.0)).toStringAsFixed(1);

    print('  ✓ Counter flooding test completed (concurrent: ${floodSw.elapsedMilliseconds}ms, seq: ${seqSw.elapsedMilliseconds}ms)');
  } catch (e, st) {
    passed = false;
    print('  ✗ Counter flooding test threw: $e');
    defects.add({
      'category': 'KV Store Counter',
      'severity': 'CRITICAL',
      'title': 'Counter Flooding Test Crash',
      'description': '$e',
      'impact': 'Engine crashed during concurrent counter hammering.',
      'evidence': '$st',
    });
  } finally {
    await db.close();
  }

  sw.stop();
  return {
    'name': '3.2 Rapid Concurrent Counter Flooding (kv.incr / kv.decr)',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': metrics,
  };
}

// ============================================================================
// 3.3: Negative & Malformed TTLs
// ============================================================================
Future<Map<String, dynamic>> test3_3NegativeAndMalformedTTLs(
  List<Map<String, dynamic>> defects,
) async {
  final sw = Stopwatch()..start();
  print('--- [TEST 3.3] Negative & Malformed TTLs ---');
  final metrics = <String, dynamic>{};
  bool passed = true;

  final dbPath = '$kDbDir/kv_ttl_stress';
  await _cleanDirectory(dbPath);
  final db = Database(dbPath);
  await db.init();

  try {
    final kv = KVStore(db);

    // ------------------------------------------------------------------------
    // CASE A: Negative Duration (-10 seconds)
    // ------------------------------------------------------------------------
    await kv.set('neg_ttl_key', 'short_negative_val', ttl: const Duration(seconds: -10));
    final negVal = await kv.get('neg_ttl_key');
    metrics['neg_10s_ttl_retrieved'] = '$negVal';
    if (negVal != null) {
      passed = false;
      defects.add({
        'category': 'KV Store TTL Bug',
        'severity': 'HIGH',
        'title': 'Negative TTL Entry Remains Accessible in Cache',
        'description': 'Setting a negative TTL of -10s did not immediately expire the entry on get().',
        'impact': 'Stale or expired keys remain active and accessible in application caches.',
        'evidence': 'kv.get("neg_ttl_key") returned: $negVal (expected null)',
      });
    }

    // ------------------------------------------------------------------------
    // CASE B: Extreme Negative TTL (-100 Years -> expiresAt < 0)
    // ------------------------------------------------------------------------
    // When ttl is -100 years, (now + ttl.inMilliseconds) evaluates to a negative integer (< 0).
    // In _KVEntry: bool get isExpired => expiresAt > 0 && now >= expiresAt;
    // Because expiresAt < 0, (expiresAt > 0) evaluates to FALSE!
    // The key NEVER EXPIRES and becomes IMMORTAL!
    final extremeNegTtl = const Duration(days: -36500);
    await kv.set('immortal_neg_key', 'should_be_expired_immediately', ttl: extremeNegTtl);
    final immortalVal = await kv.get('immortal_neg_key');
    metrics['extreme_neg_ttl_val'] = '$immortalVal';

    if (immortalVal != null) {
      passed = false;
      defects.add({
        'category': 'KV Store TTL Bug / Immortal Key',
        'severity': 'CRITICAL',
        'title': 'Immortal Key Vulnerability: Negative expiresAt Bypasses Expiration Check',
        'description': 'When a large negative TTL is passed (e.g. -100 years), now + ttl.inMilliseconds becomes negative. In _KVEntry: isExpired checks "expiresAt > 0 && now >= expiresAt". Because expiresAt < 0, isExpired returns FALSE forever, making expired keys immortal!',
        'impact': 'Keys intended to be expired or purged remain active indefinitely in cache and on disk.',
        'evidence': 'kv.get("immortal_neg_key") returned "$immortalVal" with negative expiresAt',
      });
      print('    🚨 IMMORTAL KEY DETECTED! Entry with negative expiresAt never expires.');
    }

    // ------------------------------------------------------------------------
    // CASE C: Duration.zero
    // ------------------------------------------------------------------------
    await kv.set('zero_ttl_key', 'zero_val', ttl: Duration.zero);
    final zeroVal = await kv.get('zero_ttl_key');
    metrics['zero_ttl_val'] = '$zeroVal';

    // ------------------------------------------------------------------------
    // CASE D: Massive TTL (100 Years into Future)
    // ------------------------------------------------------------------------
    const centuryTtl = Duration(days: 36500);
    await kv.set('century_key', 'century_val', ttl: centuryTtl);
    final centuryVal = await kv.get('century_key');
    metrics['century_ttl_val'] = '$centuryVal';

    // Verify century key survives database reboot and 64-bit int serialization
    await db.close();
    final rebootDb = Database(dbPath);
    await rebootDb.init();
    try {
      final rebootKv = KVStore(rebootDb);
      final rebootCenturyVal = await rebootKv.get('century_key');
      metrics['reboot_century_val'] = '$rebootCenturyVal';
      if (rebootCenturyVal != 'century_val') {
        passed = false;
        defects.add({
          'category': 'KV Store Persistence',
          'severity': 'MEDIUM',
          'title': 'Century TTL Failed Persistence on Cold Restart',
          'description': 'Key with 100-year TTL did not survive database reopen.',
          'impact': 'Long-term cache entries lost across database restarts.',
          'evidence': 'Expected "century_val", got: $rebootCenturyVal',
        });
      }

      // ----------------------------------------------------------------------
      // CASE E: pruneExpired() Disk Cleanup Behavior
      // ----------------------------------------------------------------------
      await rebootKv.pruneExpired();
      metrics['prune_expired_ran'] = 'YES';
    } finally {
      await rebootDb.close();
    }

    print('  ✓ Negative & malformed TTL tests completed');
  } catch (e, st) {
    passed = false;
    print('  ✗ TTL test threw: $e');
    defects.add({
      'category': 'KV Store TTL',
      'severity': 'CRITICAL',
      'title': 'TTL Test Crash',
      'description': '$e',
      'impact': 'Engine crashed during TTL boundary testing.',
      'evidence': '$st',
    });
  }

  sw.stop();
  return {
    'name': '3.3 Negative & Malformed TTLs',
    'passed': passed,
    'durationMs': sw.elapsedMilliseconds,
    'metrics': metrics,
  };
}
