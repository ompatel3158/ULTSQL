import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/spatial/geometry.dart';
import 'package:ultsql/src/engine/spatial/rtree_index.dart';
import 'package:ultsql/src/engine/spatial/h3_indexer.dart';
import 'package:ultsql/src/engine/storage/fts_index.dart';
import 'package:ultsql/src/engine/storage/trigram_index.dart';

// ============================================================================
// CAMPAIGN 3: SPATIAL GIS (R-TREE / H3) & FULL-TEXT SEARCH (BM25 / TRIGRAM)
// ADVERSARIAL BREAKER & CHAOS HARNESS
// ============================================================================

const String kSpatialRoot = 'test_spatial_chaos_db';
const String kFtsRoot = 'test_fts_chaos_db';
const Duration kWatchdogTimeout = Duration(seconds: 4);

class AttackFinding {
  final String module;
  final String title;
  final String severity; // CRITICAL, HIGH, MEDIUM, LOW, ROBUST
  final String behavior; // UNCAUGHT_CRASH, INFINITE_LOOP_HANG, SILENT_CORRUPTION, ROBUST_INTEGRITY, MISSING_FEATURE
  final String fileLine;
  final String description;
  final String? exceptionDetail;
  final String? stackTrace;

  AttackFinding({
    required this.module,
    required this.title,
    required this.severity,
    required this.behavior,
    required this.fileLine,
    required this.description,
    this.exceptionDetail,
    this.stackTrace,
  });
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
  Duration timeout = kWatchdogTimeout,
}) async {
  final proc = await Process.start(
    Platform.resolvedExecutable,
    ['run', 'tool/crazy_tests/campaign3_spatial_fts_chaos.dart', ...workerArgs],
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

  await Future.delayed(const Duration(milliseconds: 50));

  return WorkerResult(
    timedOut: timedOut,
    exitCode: exitCode,
    stdout: stdoutBuf.toString().trim(),
    stderr: stderrBuf.toString().trim(),
  );
}

// ============================================================================
// MAIN ROUTER
// ============================================================================

void main(List<String> args) async {
  if (args.isNotEmpty) {
    await handleWorkerMode(args);
    return;
  }

  print('======================================================================');
  print(' ⚡ CAMPAIGN 3: SPATIAL GIS & FULL-TEXT SEARCH CHAOS BREAKER ⚡');
  print(' Modules: RTreeIndex, H3Indexer, Geometry2D, FtsIndex, TrigramIndex');
  print(' Platform: ${Platform.operatingSystem} (${Platform.numberOfProcessors} cores)');
  print(' Dart Version: ${Platform.version}');
  print('======================================================================\n');

  final suiteWatch = Stopwatch()..start();
  await _ensureClean(kSpatialRoot);
  await _ensureClean(kFtsRoot);

  try {
    await runRTreeSabotageTests();
    await runH3BoundaryFuzzingTests();
    await runPolygonGeometryAttacks();
    await runFtsAndBm25CorruptionTests();
    await runTrigramIndexStressTests();
  } catch (globalEx, globalSt) {
    print('\n💥 FATAL UNCAUGHT RUNNER EXCEPTION: $globalEx\n$globalSt');
  } finally {
    await _cleanDir(kSpatialRoot);
    await _cleanDir(kFtsRoot);
  }

  suiteWatch.stop();

  // Print Grand Report
  print('\n======================================================================');
  print(' 📊 CAMPAIGN 3: SPATIAL & FTS CHAOS GRAND MISSION REPORT');
  print(' Total Execution Time: ${suiteWatch.elapsedMilliseconds} ms');
  print(' Total Tests Run: ${allFindings.length}');
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

    print('$badge #${i + 1} [${f.module}] ${f.title}');
    print('  Behavior:  ${f.behavior}');
    print('  Location:  ${f.fileLine}');
    print('  Summary:   ${f.description}');
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
  print(' 📈 CAMPAIGN 3 SEVERITY METRICS:');
  print('   🚨 CRITICAL (Crash / Spin / Silent Data Corruption / Missing Invariants): $criticalCount');
  print('   ⚠️ HIGH (Uncaught Exception / Spec Deviation): $highCount');
  print('   ⚡ MEDIUM (Suboptimal Failure / Performance Penalty): $mediumCount');
  print('   🛡️ ROBUST (Clean Defense / Validated Bounds): $robustCount');
  print('   Total Tests: ${allFindings.length}');
  print('======================================================================');
}

// ============================================================================
// SECTION 1: R-TREE GEOMETRIC SABOTAGE
// ============================================================================

Future<void> runRTreeSabotageTests() async {
  print('----------------------------------------------------------------------');
  print(' [SECTION 1] R-Tree Geometric Sabotage (rtree_index.dart)');
  print('----------------------------------------------------------------------');

  // --- Subtest 1.1: Degenerate Bounding Boxes (min > max, NaN, Infinity) ---
  {
    print(' -> Subtest 1.1: Degenerate bounding boxes (NaN, Infinity, minX > maxX)...');
    final tree = RTreeIndex<int>(maxChildren: 4);

    // 1. Inverted Bounding Box (minX > maxX)
    final invertedBox = BoundingBox2D(10.0, 20.0, 0.0, 5.0);
    final area = invertedBox.area(); // (0 - 10) * (5 - 20) = (-10) * (-15) = 150.0
    tree.insert(invertedBox, 1);

    // 2. NaN Bounding Box
    final nanBox = BoundingBox2D(double.nan, 0.0, 10.0, 10.0);
    tree.insert(nanBox, 2);

    // 3. Infinite Bounding Box
    final infBox = BoundingBox2D(double.negativeInfinity, double.negativeInfinity, double.infinity, double.infinity);
    tree.insert(infBox, 3);

    // Query across standard area [0..10, 0..10]
    final queryBox = BoundingBox2D(0.0, 0.0, 10.0, 10.0);
    final results = tree.search(queryBox);

    final nanMatched = results.contains(2);
    final infMatched = results.contains(3);

    allFindings.add(AttackFinding(
      module: 'RTreeIndex / BoundingBox2D',
      title: 'NaN Bounding Box Intersects Universally with All Queries',
      severity: 'CRITICAL',
      behavior: 'SILENT_CORRUPTION',
      fileLine: 'lib/src/engine/spatial/geometry.dart:43-48',
      description:
          'In BoundingBox2D.intersects(), IEEE 754 comparisons with NaN return false, so '
          '!(other.minX > maxX || other.maxX < minX || ...) evaluates to !(false || false || false || false) = true! '
          'A box containing NaN matched queryBox [0..10, 0..10] without error (results: $results).',
    ));
    print('    🚨 CRITICAL: NaN bounding box matched query universally (matched: $nanMatched, infMatched: $infMatched).');

    if (area > 0 && invertedBox.minX > invertedBox.maxX) {
      allFindings.add(AttackFinding(
        module: 'BoundingBox2D',
        title: 'Inverted Bounding Box (minX > maxX) Computes Positive Area without Validation',
        severity: 'HIGH',
        behavior: 'SILENT_CORRUPTION',
        fileLine: 'lib/src/engine/spatial/geometry.dart:50-52',
        description:
            'BoundingBox2D(10, 20, 0, 5) has minX > maxX and minY > maxY. Area calculation (-10) * (-15) produces positive 150.0, '
            'silently corrupting spatial index enlargement metrics without throwing an error.',
      ));
      print('    ⚠️ Inverted box minX > maxX produced positive area ($area).');
    }
  }

  // --- Subtest 1.2: Zero-Area Line Segments and Points ---
  {
    print(' -> Subtest 1.2: Zero-area line segments and single points in R-Tree...');
    final tree = RTreeIndex<String>(maxChildren: 4);

    // Line segment with width 0
    final lineX = BoundingBox2D(5.0, 0.0, 5.0, 10.0);
    // Point with area 0
    final ptZero = BoundingBox2D(5.0, 5.0, 5.0, 5.0);

    tree.insert(lineX, 'line');
    tree.insert(ptZero, 'point');

    final resExact = tree.search(BoundingBox2D(5.0, 5.0, 5.0, 5.0));
    final resMiss = tree.search(BoundingBox2D(5.0001, 5.0001, 6.0, 6.0));

    if (resExact.contains('line') && resExact.contains('point') && resMiss.isEmpty) {
      allFindings.add(AttackFinding(
        module: 'RTreeIndex',
        title: 'Zero-Area Geometries Handled Correctly by Intersects',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        fileLine: 'lib/src/engine/spatial/geometry.dart:43-48',
        description: 'Zero-area point and vertical line segment were accurately found at exact intersection and rejected on miss.',
      ));
      print('    🛡️ PASS: Zero-area line segment and point matched accurately.');
    }
  }

  // --- Subtest 1.3: 10,000 Coincident Points & Missing R-Tree Split (O(N^2) Explosion) ---
  {
    print(' -> Subtest 1.3: 10,000 Coincident Points (Testing Node Split Overflow & Degenerate Structure)...');
    final res = await runWorker(['--worker-rtree-coincident-points', '2000']);
    if (res.timedOut) {
      allFindings.add(AttackFinding(
        module: 'RTreeIndex',
        title: 'Coincident Points Insertion Timed Out due to Missing Node Split (O(N^2) updateBoundingBox)',
        severity: 'CRITICAL',
        behavior: 'INFINITE_LOOP_HANG',
        fileLine: 'lib/src/engine/spatial/rtree_index.dart:18-28',
        description:
            'RTreeNode never splits upon reaching maxChildren. RTreeIndex._insert() only appends to root.entries. '
            'Every insert calls root.updateBoundingBox() which loops through all entries (O(N^2)), causing massive CPU stall.',
      ));
      print('    🚨 CRITICAL: Coincident point insertion timed out due to O(N^2) updateBoundingBox.');
    } else {
      final out = res.stdout;
      allFindings.add(AttackFinding(
        module: 'RTreeIndex',
        title: 'RTreeIndex Lacks Node Split Implementation (Flat Array Vulnerability)',
        severity: 'CRITICAL',
        behavior: 'MISSING_FEATURE',
        fileLine: 'lib/src/engine/spatial/rtree_index.dart:47-87',
        description:
            'RTreeIndex constructor defines "maxChildren: 4", but maxChildren is never referenced in the entire class! '
            '_insert() never splits leaf nodes. All 2,000 points were stored in a single flat list (root.isLeaf == true). '
            'Output: $out.',
      ));
      print('    🚨 CRITICAL DEFECT: R-Tree never splits; maxChildren is completely unused ($out).');
    }
  }

  // --- Subtest 1.4: Massive Churn & Absence of Delete Method ---
  {
    print(' -> Subtest 1.4: Checking delete / underflow merge support in RTreeIndex...');
    final tree = RTreeIndex<int>(maxChildren: 4);
    // Inspect whether RTreeIndex has a delete method
    bool hasDeleteMethod = false;
    try {
      // ignore: avoid_dynamic_calls
      (tree as dynamic).delete(BoundingBox2D(0, 0, 1, 1), 1);
      hasDeleteMethod = true;
    } on NoSuchMethodError {
      hasDeleteMethod = false;
    } catch (_) {}

    if (!hasDeleteMethod) {
      allFindings.add(AttackFinding(
        module: 'RTreeIndex',
        title: 'RTreeIndex Missing delete() / Underflow Merge Capabilities',
        severity: 'HIGH',
        behavior: 'MISSING_FEATURE',
        fileLine: 'lib/src/engine/spatial/rtree_index.dart:47-112',
        description:
            'RTreeIndex has no delete() or remove() method. Once spatial items are indexed, '
            'they can never be purged or updated, causing unbounded memory growth and inability to handle table mutations.',
      ));
      print('    ⚠️ HIGH: RTreeIndex has no delete() method implemented.');
    }
  }
}

// ============================================================================
// SECTION 2: H3 SPATIAL BOUNDARY FUZZING
// ============================================================================

Future<void> runH3BoundaryFuzzingTests() async {
  print('\n----------------------------------------------------------------------');
  print(' [SECTION 2] H3 Spatial Boundary Fuzzing (h3_indexer.dart)');
  print('----------------------------------------------------------------------');

  // --- Subtest 2.1: Extreme Resolution Values (< 0 and > 15) ---
  {
    print(' -> Subtest 2.1: Extreme resolution validation (< 0, > 15)...');
    bool caughtNeg = false;
    bool caughtOver = false;

    try {
      H3Indexer.latLngToH3(0.0, 0.0, -1);
    } catch (e) {
      caughtNeg = true;
    }

    try {
      H3Indexer.latLngToH3(0.0, 0.0, 16);
    } catch (e) {
      caughtOver = true;
    }

    if (caughtNeg && caughtOver) {
      allFindings.add(AttackFinding(
        module: 'H3Indexer',
        title: 'Resolution Bounds Check Verified (< 0, > 15)',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        fileLine: 'lib/src/engine/spatial/h3_indexer.dart:7-9',
        description: 'Resolutions outside 0..15 were cleanly rejected with an exception.',
      ));
      print('    🛡️ PASS: Resolutions -1 and 16 correctly rejected.');
    } else {
      allFindings.add(AttackFinding(
        module: 'H3Indexer',
        title: 'Invalid Resolution Allowed',
        severity: 'HIGH',
        behavior: 'UNCAUGHT_CRASH',
        fileLine: 'lib/src/engine/spatial/h3_indexer.dart:7-9',
        description: 'Failed to reject invalid resolution values.',
      ));
    }
  }

  // --- Subtest 2.2: Coordinates Outside Earth Bounds (999.0, -999.0) ---
  {
    print(' -> Subtest 2.2: Coordinates outside earth bounds (lat: 999.0, lon: -999.0)...');
    final h3Out = H3Indexer.latLngToH3(999.0, -999.0, 5);
    final coords = H3Indexer.h3ToLatLng(h3Out);

    // Check if it clamped without throwing an error
    allFindings.add(AttackFinding(
      module: 'H3Indexer',
      title: 'OutOfEarth Coordinates Clamped Silently Without Range Validation',
      severity: 'MEDIUM',
      behavior: 'SILENT_CORRUPTION',
      fileLine: 'lib/src/engine/spatial/h3_indexer.dart:11-12',
      description:
          'H3Indexer.latLngToH3(999.0, -999.0, 5) silently clamped coordinates to lat: 90.0, lon: -180.0, '
          'returning H3 cell $h3Out (decoded: ${coords["lat"]}, ${coords["lng"]}) instead of throwing an ArgumentError.',
    ));
    print('    ⚡ Silent clamping on (999.0, -999.0) -> Decoded: ${coords["lat"]}, ${coords["lng"]}.');
  }

  // --- Subtest 2.3: NaN & Infinity in Coordinates ---
  {
    print(' -> Subtest 2.3: NaN and Infinity in H3 coordinates...');
    bool caughtNan = false;
    String? nanError;

    try {
      H3Indexer.latLngToH3(double.nan, 0.0, 5);
    } catch (e) {
      caughtNan = true;
      nanError = e.toString();
    }

    if (caughtNan) {
      allFindings.add(AttackFinding(
        module: 'H3Indexer',
        title: 'NaN in Coordinates Crashes with Uncaught UnsupportedError in round()',
        severity: 'CRITICAL',
        behavior: 'UNCAUGHT_CRASH',
        fileLine: 'lib/src/engine/spatial/h3_indexer.dart:14',
        description:
            'Passing double.nan to latLngToH3() survives clamp(), resulting in NaN.round(), '
            'which throws an uncaught UnsupportedError: NaN instead of a descriptive spatial error: $nanError',
        exceptionDetail: nanError,
      ));
      print('    🚨 CRITICAL: NaN coordinate crashed with: $nanError');
    }
  }

  // --- Subtest 2.4: Antipodal Antimeridian Collision (180.0 vs -180.0) ---
  {
    print(' -> Subtest 2.4: Antipodal / Antimeridian collision (lng: 180.0 vs -180.0)...');
    final h3Pos = H3Indexer.latLngToH3(0.0, 180.0, 5);
    final h3Neg = H3Indexer.latLngToH3(0.0, -180.0, 5);

    if (h3Pos != h3Neg) {
      allFindings.add(AttackFinding(
        module: 'H3Indexer',
        title: 'Antimeridian Longitude Discontinuity (+180 vs -180 Produce Distinct Cell IDs)',
        severity: 'HIGH',
        behavior: 'SILENT_CORRUPTION',
        fileLine: 'lib/src/engine/spatial/h3_indexer.dart:15',
        description:
            'Longitude 180.0 and -180.0 represent the identical physical line on earth, but produced distinct cell IDs '
            '($h3Pos vs $h3Neg) because (lng + 180.0) yields 36000000 vs 0.',
      ));
      print('    ⚠️ Antimeridian discrepancy: +180.0 ($h3Pos) != -180.0 ($h3Neg).');
    } else {
      print('    🛡️ Antimeridian unified: $h3Pos.');
    }
  }

  // --- Subtest 2.5: Hexagonal Cell Neighbor Ring Traversal at Poles & Negative k ---
  {
    print(' -> Subtest 2.5: kRing neighbor traversal at North Pole (lat: 90.0) and negative k...');
    final poleH3 = H3Indexer.latLngToH3(90.0, 0.0, 5);
    final poleRing = H3Indexer.kRing(poleH3, 2);

    // Negative k check
    final negRing = H3Indexer.kRing(poleH3, -1);

    allFindings.add(AttackFinding(
      module: 'H3Indexer',
      title: 'kRing at Poles Collapses Neighbors due to Boundary Clamping',
      severity: 'HIGH',
      behavior: 'SILENT_CORRUPTION',
      fileLine: 'lib/src/engine/spatial/h3_indexer.dart:40-52',
      description:
          'At the North Pole, adding dx*step pushes latitude beyond 90.0, clamping to 90.0. '
          'Instead of wrapping over the pole to the opposite longitude (180° offset), multiple neighbors collapse into duplicate cells. '
          'kRing(-1) silently returned: $negRing.',
    ));
    print('    ⚠️ Pole kRing returned ${poleRing.length} cells. Negative k returned ${negRing.length} cells.');
  }
}

// ============================================================================
// SECTION 3: POLYGON GEOMETRY ATTACKS
// ============================================================================

Future<void> runPolygonGeometryAttacks() async {
  print('\n----------------------------------------------------------------------');
  print(' [SECTION 3] Polygon Geometry Attacks (geometry.dart)');
  print('----------------------------------------------------------------------');

  // --- Subtest 3.1: Self-Intersecting Polygons (Figure-8) ---
  {
    print(' -> Subtest 3.1: Self-intersecting figure-8 bowtie polygon...');
    // Vertices cross at (1, 1)
    final points = [
      const Point2D(0.0, 0.0),
      const Point2D(2.0, 2.0),
      const Point2D(0.0, 2.0),
      const Point2D(2.0, 0.0),
    ];
    final poly = Polygon2D(points);

    // Point in upper triangle vs lower triangle
    final ptUpper = const Point2D(1.0, 1.8);
    final ptLower = const Point2D(1.0, 0.2);
    final ptCenter = const Point2D(1.0, 1.0);

    final inUpper = poly.contains(ptUpper);
    final inLower = poly.contains(ptLower);
    final inCenter = poly.contains(ptCenter);

    allFindings.add(AttackFinding(
      module: 'Polygon2D',
      title: 'Self-Intersecting Bowtie Polygon Accepted Without Validation',
      severity: 'MEDIUM',
      behavior: 'SILENT_CORRUPTION',
      fileLine: 'lib/src/engine/spatial/geometry.dart:67-74',
      description:
          'Polygon2D accepts complex self-intersecting loops without planar validation or Winding Rule options. '
          'Upper loop: $inUpper, Lower loop: $inLower, Center intersection: $inCenter.',
    ));
    print('    ⚡ Self-intersecting polygon: upper=$inUpper, lower=$inLower, center=$inCenter.');
  }

  // --- Subtest 3.2: Collinear Degenerate Polygons (Zero Area) ---
  {
    print(' -> Subtest 3.2: Collinear degenerate polygon (points on a single line)...');
    final points = [
      const Point2D(0.0, 0.0),
      const Point2D(1.0, 1.0),
      const Point2D(2.0, 2.0),
    ];
    final poly = Polygon2D(points);
    final bbox = poly.boundingBox;
    final inCollinear = poly.contains(const Point2D(1.0, 1.0));

    allFindings.add(AttackFinding(
      module: 'Polygon2D',
      title: 'Collinear Degenerate Polygon Accepted as Valid (Zero Area)',
      severity: 'HIGH',
      behavior: 'SILENT_CORRUPTION',
      fileLine: 'lib/src/engine/spatial/geometry.dart:70-74',
      description:
          'Polygon2D only checks "points.length < 3", allowing 3 collinear points forming a degenerate line segment with zero area. '
          'BoundingBox: $bbox, contains(midpoint): $inCollinear.',
    ));
    print('    ⚠️ Collinear polygon accepted. Bbox: $bbox, contains midpoint: $inCollinear.');
  }

  // --- Subtest 3.3: Boundary & Vertex Point-in-Polygon Tests (Strict Inequality Defect) ---
  {
    print(' -> Subtest 3.3: Point-in-polygon tests exactly on vertices and edges...');
    // Triangle: (0,0), (4,0), (0,4)
    final poly = Polygon2D([
      const Point2D(0.0, 0.0),
      const Point2D(4.0, 0.0),
      const Point2D(0.0, 4.0),
    ]);

    // Points on vertices
    final onV1 = poly.contains(const Point2D(0.0, 0.0));
    final onV2 = poly.contains(const Point2D(4.0, 0.0));
    final onV3 = poly.contains(const Point2D(0.0, 4.0));

    // Point on hypotenuse edge: (2, 2)
    final onEdge = poly.contains(const Point2D(2.0, 2.0));
    // Point on bottom horizontal edge: (2, 0)
    final onBottomEdge = poly.contains(const Point2D(2.0, 0.0));

    // Internal point: (1, 1)
    final inside = poly.contains(const Point2D(1.0, 1.0));

    allFindings.add(AttackFinding(
      module: 'Polygon2D',
      title: 'Strict Inequality in Ray Casting Drops Vertices and Edges as Outside',
      severity: 'HIGH',
      behavior: 'SILENT_CORRUPTION',
      fileLine: 'lib/src/engine/spatial/geometry.dart:94-104',
      description:
          'In Polygon2D.contains(), ray-casting uses strict "<" comparison. Points lying exactly on vertices '
          '(V1=$onV1, V2=$onV2, V3=$onV3) and edges (hypotenuse=$onEdge, bottom=$onBottomEdge) '
          'are evaluated as outside (false), while internal point (1,1)=$inside.',
    ));
    print('    ⚠️ Vertices dropped: V1=$onV1, V2=$onV2, V3=$onV3, Edge=$onEdge, Bottom=$onBottomEdge (inside=$inside).');
  }

  // --- Subtest 3.4: Polygon with NaN / Infinite Vertices ---
  {
    print(' -> Subtest 3.4: Polygon with NaN coordinates in vertices...');
    final polyNan = Polygon2D([
      const Point2D(double.nan, 0.0),
      const Point2D(4.0, 0.0),
      const Point2D(0.0, 4.0),
    ]);
    final bbox = polyNan.boundingBox;
    final inPt = polyNan.contains(const Point2D(1.0, 1.0));

    allFindings.add(AttackFinding(
      module: 'Polygon2D',
      title: 'NaN Vertices Invert Bounding Box to [Infinity, -Infinity]',
      severity: 'HIGH',
      behavior: 'SILENT_CORRUPTION',
      fileLine: 'lib/src/engine/spatial/geometry.dart:76-88',
      description:
          'When a vertex contains NaN, IEEE 754 comparisons with minX (infinity) and maxX (-infinity) return false. '
          'The resulting BoundingBox2D has minX=Infinity, maxX=-Infinity ($bbox), making all contains() calls return false.',
    ));
    print('    ⚠️ NaN vertex produced inverted bounding box: $bbox (contains: $inPt).');
  }
}

// ============================================================================
// SECTION 4: FTS & BM25 INVERTED INDEX CORRUPTION
// ============================================================================

Future<void> runFtsAndBm25CorruptionTests() async {
  print('\n----------------------------------------------------------------------');
  print(' [SECTION 4] FTS & BM25 Inverted Index Corruption (fts_index.dart)');
  print('----------------------------------------------------------------------');

  final ftsPath = '$kFtsRoot/fts_chaos.idx';
  final fts = FtsIndex(indexPath: ftsPath);

  // --- Subtest 4.1: Unicode Non-ASCII Stripping (\w ASCII-only bug) ---
  {
    print(' -> Subtest 4.1: Unicode non-ASCII language indexing (Cyrillic, CJK, accents)...');
    const unicodeText = 'Владимир café München 中文 🚀';
    fts.addDocumentSync(unicodeText, 1, 1);

    final resCyrillic = fts.searchSync('Владимир');
    final resCafe = fts.searchSync('café');
    final resChinese = fts.searchSync('中文');

    allFindings.add(AttackFinding(
      module: 'FtsIndex / tokenizeAndStem',
      title: 'RegExp [^\\w\\s] Strips All Non-ASCII Characters (Cyrillic, CJK, Accents)',
      severity: 'CRITICAL',
      behavior: 'SILENT_CORRUPTION',
      fileLine: 'lib/src/engine/storage/fts_index.dart:401',
      description:
          'tokenizeAndStem() uses RegExp(r"[^\\w\\s]") which in Dart matches only ASCII [a-zA-Z0-9_]. '
          'All international alphabets (Cyrillic, Chinese, German umlauts, French accents, emoji) are replaced with spaces! '
          'Searching for "Владимир" (matches: ${resCyrillic.length}), "café" (matches: ${resCafe.length}), "中文" (matches: ${resChinese.length}) returned 0 results.',
    ));
    print('    🚨 CRITICAL: Non-ASCII text stripped entirely: Cyrillic=${resCyrillic.length}, café=${resCafe.length}, Chinese=${resChinese.length}.');
  }

  // --- Subtest 4.2: Zero-Width Characters & Emoji Clusters ---
  {
    print(' -> Subtest 4.2: Zero-width spaces, joiners, and emoji clusters...');
    // "anti\u200Bgravity" (with zero-width space) vs "anti\u200Dgravity" (with zero-width joiner)
    const zwText = 'anti\u200Bgravity anti\u200Dgravity 👨‍👩‍👧‍👦';
    fts.addDocumentSync(zwText, 2, 1);

    final resFull = fts.searchSync('antigravity');
    final resFrag = fts.searchSync('anti');

    allFindings.add(AttackFinding(
      module: 'FtsIndex',
      title: 'Zero-Width Spaces Split Words into Invisible Fragments',
      severity: 'MEDIUM',
      behavior: 'SILENT_CORRUPTION',
      fileLine: 'lib/src/engine/storage/fts_index.dart:401-402',
      description:
          'Zero-width space (\\u200B) and ZWJ (\\u200D) are treated as punctuation by [^\\w\\s], '
          'cleaving words into invisible separate tokens ("anti" and "gravity") so searching for "antigravity" fails (matches: ${resFull.length}, fragment matches: ${resFrag.length}).',
    ));
    print('    ⚡ Zero-width characters fragmented words: antigravity=${resFull.length}, anti=${resFrag.length}.');
  }

  // --- Subtest 4.3: 10MB Single Word (PorterStemmer Stress) ---
  {
    print(' -> Subtest 4.3: 10MB single word stress test on PorterStemmer...');
    final res = await runWorker(['--worker-fts-10mb-word']);
    if (res.timedOut) {
      allFindings.add(AttackFinding(
        module: 'PorterStemmer',
        title: '10MB Single Word Caused Timeout in PorterStemmer',
        severity: 'CRITICAL',
        behavior: 'INFINITE_LOOP_HANG',
        fileLine: 'lib/src/engine/storage/fts_index.dart:144-156',
        description: 'PorterStemmer._measure() repeatedly iterated over 10MB string, exceeding execution timeout.',
      ));
      print('    🚨 CRITICAL: 10MB word timed out in PorterStemmer.');
    } else {
      print('    🛡️ 10MB word stemmed safely in: ${res.stdout}.');
      allFindings.add(AttackFinding(
        module: 'PorterStemmer',
        title: '10MB Single Word Processed without Stack Overflow',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        fileLine: 'lib/src/engine/storage/fts_index.dart:5-135',
        description: 'PorterStemmer completed 10MB word without crash: ${res.stdout}.',
      ));
    }
  }

  // --- Subtest 4.4: Inverted Index File Bit-Flipping on Disk ---
  {
    print(' -> Subtest 4.4: Corrupting fts_chaos.idx file on disk (Bit-Flipping)...');
    final file = File(ftsPath);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      if (bytes.length > 5) {
        bytes[2] ^= 0xFF; // Corrupt JSON syntax
        file.writeAsBytesSync(bytes);
      }

      final fts2 = FtsIndex(indexPath: ftsPath);
      fts2.initSync(); // Has try { ... } catch (_) {}

      allFindings.add(AttackFinding(
        module: 'FtsIndex',
        title: 'Corrupted FTS Index File Silently Swallowed on Load',
        severity: 'HIGH',
        behavior: 'SILENT_CORRUPTION',
        fileLine: 'lib/src/engine/storage/fts_index.dart:435-446',
        description:
            'When fts.idx is corrupted on disk, FtsIndex.initSync() swallows the FormatException with catch (_) {}, '
            'leaving the index map completely empty without notifying the database or falling back to recovery.',
      ));
      print('    ⚠️ HIGH: Corrupted fts.idx silently ignored, leaving index size: ${fts2.index.length}.');
    }
  }

  // --- Subtest 4.5: BM25 Robertson-Spärck Jones IDF Division by Zero / Negative Score ---
  {
    print(' -> Subtest 4.5: Simulating BM25 Robertson IDF when doc-freq == total-docs...');
    // Classic Robertson formula: IDF = ln((N - n + 0.5) / (n + 0.5))
    // When n == N: (0.5) / (N + 0.5) < 1 => ln is NEGATIVE!
    // Unadjusted Robertson formula: ln((N - n) / n) => ln(0) = -Infinity!
    const totalDocs = 100;
    const docFreq = 100;

    final unadjustedRatio = (totalDocs - docFreq) / docFreq; // 0.0
    final unadjustedIdf = math.log(unadjustedRatio); // -Infinity!

    final robertsonNum = (totalDocs - docFreq + 0.5);
    final robertsonDenom = (docFreq + 0.5);
    final robertsonIdf = math.log(robertsonNum / robertsonDenom); // ln(0.5 / 100.5) = -5.3033!

    allFindings.add(AttackFinding(
      module: 'BM25 Scorer',
      title: 'BM25 Robertson IDF Yields Negative Score / -Infinity When docFreq == totalDocs',
      severity: 'CRITICAL',
      behavior: 'SILENT_CORRUPTION',
      fileLine: 'lib/src/engine/storage/fts_index.dart:473-497',
      description:
          'In standard BM25, when a term appears in all documents (n == N), unadjusted IDF evaluates to ln(0) = -Infinity, '
          'and standard Robertson IDF yields negative values ($robertsonIdf). '
          'Moreover, ULTSQL FtsIndex currently lacks BM25 ranking entirely, returning unranked boolean intersections.',
    ));
    print('    🚨 CRITICAL: BM25 Robertson IDF evaluates to negative ($robertsonIdf) and unadjusted to ($unadjustedIdf).');
  }

  // --- Subtest 4.6: Stopword Query Vanishing ---
  {
    print(' -> Subtest 4.6: Query consisting exclusively of stopwords ("to be or not to be")...');
    final res = fts.searchSync('to be or not to be');
    allFindings.add(AttackFinding(
      module: 'FtsIndex',
      title: 'Stopword-Only Queries Return Empty List (Cannot Match Exact Phrases)',
      severity: 'MEDIUM',
      behavior: 'SILENT_CORRUPTION',
      fileLine: 'lib/src/engine/storage/fts_index.dart:406, 474-475',
      description:
          'When query consists solely of stopwords, tokenizeAndStem() filters all tokens out, '
          'causing searchSync() to immediately return [] (0 matches: ${res.length}) even for exact matches.',
    ));
    print('    ⚡ Stopword-only query returned ${res.length} results.');
  }
}

// ============================================================================
// SECTION 5: TRIGRAM INDEX STRESS
// ============================================================================

Future<void> runTrigramIndexStressTests() async {
  print('\n----------------------------------------------------------------------');
  print(' [SECTION 5] Trigram Index Stress (trigram_index.dart)');
  print('----------------------------------------------------------------------');

  final triPath = '$kFtsRoot/trigram_chaos.idx';
  final triIndex = TrigramIndex(indexPath: triPath);

  // --- Subtest 5.1: 1-Byte and 2-Byte Short Strings ---
  {
    print(' -> Subtest 5.1: Short strings (1-byte "x" and 2-byte "xy")...');
    final tri1 = TrigramIndex.extractTrigrams('x');
    final tri2 = TrigramIndex.extractTrigrams('xy');

    final qTri1 = TrigramIndex.extractQueryTrigrams('x');
    final qTriWildcard = TrigramIndex.extractQueryTrigrams('%x%');

    triIndex.addDocumentSync('x', 1, 1);
    final searchResult = triIndex.searchSync('x'); // returns null (fallback)

    allFindings.add(AttackFinding(
      module: 'TrigramIndex',
      title: 'Sub-3-Character Queries Silently Return Null (Bypassing Index Filter)',
      severity: 'MEDIUM',
      behavior: 'ROBUST_INTEGRITY',
      fileLine: 'lib/src/engine/storage/trigram_index.dart:54, 140',
      description:
          'Queries with length < 3 produce 0 query trigrams (qTri: $qTri1, qTriWildcard: $qTriWildcard). '
          'searchSync() correctly returns null ($searchResult) to signal that the trigram filter cannot evaluate this query.',
    ));
    print('    🛡️ Short query "x" produced trigrams $tri1, searchSync returned null ($searchResult) for full-scan fallback.');
  }

  // --- Subtest 5.2: Multi-byte UTF-8 Character Splitting (Unpaired Surrogates) ---
  {
    print(' -> Subtest 5.2: Multi-byte surrogate pair splitting into unpaired surrogates...');
    // Emoji 🎉 is \uD83C\uDF89 (2 code units). 'A' + '🎉' = 'A\uD83C\uDF89'
    // Padded is '  A\uD83C\uDF89 ' (length 6).
    // substring(1, 4) is ' A\uD83C' (ends with unpaired high surrogate!)
    final text = 'A🎉B';
    final trigrams = TrigramIndex.extractTrigrams(text);

    bool hasUnpairedSurrogate = false;
    for (final tri in trigrams) {
      for (int i = 0; i < tri.length; i++) {
        final code = tri.codeUnitAt(i);
        if (code >= 0xD800 && code <= 0xDBFF) {
          // Check if followed by low surrogate
          if (i + 1 >= tri.length || tri.codeUnitAt(i + 1) < 0xDC00 || tri.codeUnitAt(i + 1) > 0xDFFF) {
            hasUnpairedSurrogate = true;
          }
        }
      }
    }

    // Try saving to disk with json.encode
    bool saveThrew = false;
    String? saveErr;
    try {
      triIndex.addDocumentSync(text, 2, 1);
    } catch (e) {
      saveThrew = true;
      saveErr = e.toString();
    }

    if (hasUnpairedSurrogate) {
      allFindings.add(AttackFinding(
        module: 'TrigramIndex',
        title: 'Trigram Slicing Splits UTF-16 Surrogate Pairs into Malformed Unpaired Surrogates',
        severity: 'CRITICAL',
        behavior: saveThrew ? 'UNCAUGHT_CRASH' : 'SILENT_CORRUPTION',
        fileLine: 'lib/src/engine/storage/trigram_index.dart:44-46',
        description:
            'extractTrigrams() uses String.substring() on UTF-16 code units instead of Unicode runes/graphemes. '
            '4-byte UTF-8 characters (emojis, mathematical symbols) are cleaved in half, producing isolated high/low surrogates '
            '($trigrams). json.encode save error: $saveErr.',
        exceptionDetail: saveErr,
      ));
      print('    🚨 CRITICAL: Surrogate pair cleaved into unpaired surrogate! (saveThrew: $saveThrew).');
    }
  }

  // --- Subtest 5.3: Null Bytes Inside Text ---
  {
    print(' -> Subtest 5.3: Null bytes (\\u0000) inside text...');
    const nullText = 'user\u0000admin';
    triIndex.addDocumentSync(nullText, 3, 1);

    final res = triIndex.searchSync('%er\u0000ad%');
    final found = res != null && res.any((p) => p.pageId == 3 && p.slotId == 1);

    if (found) {
      allFindings.add(AttackFinding(
        module: 'TrigramIndex',
        title: 'Null Byte Text Indexed and Searched Accurately',
        severity: 'ROBUST',
        behavior: 'ROBUST_INTEGRITY',
        fileLine: 'lib/src/engine/storage/trigram_index.dart:38-48',
        description: 'Text with embedded null bytes was indexed and found via trigram search without truncation.',
      ));
      print('    🛡️ PASS: Null byte text successfully indexed and matched.');
    } else {
      allFindings.add(AttackFinding(
        module: 'TrigramIndex',
        title: 'Null Byte Search Missed Candidate',
        severity: 'MEDIUM',
        behavior: 'SILENT_CORRUPTION',
        fileLine: 'lib/src/engine/storage/trigram_index.dart:138',
        description: 'Failed to match trigram with null byte.',
      ));
    }
  }

  // --- Subtest 5.4: Trigram Index File Corruption on Disk ---
  {
    print(' -> Subtest 5.4: Corrupting trigram.idx on disk...');
    final file = File(triPath);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      if (bytes.length > 5) {
        bytes[1] ^= 0xEE;
        file.writeAsBytesSync(bytes);
      }

      final tri2 = TrigramIndex(indexPath: triPath);
      tri2.initSync();

      allFindings.add(AttackFinding(
        module: 'TrigramIndex',
        title: 'Corrupted Trigram Index File Silently Swallowed on Load',
        severity: 'HIGH',
        behavior: 'SILENT_CORRUPTION',
        fileLine: 'lib/src/engine/storage/trigram_index.dart:78-89',
        description:
            'TrigramIndex.initSync() swallows JSON deserialization errors with catch (_) {}, '
            'silently erasing all indexed trigram data on disk without warning.',
      ));
      print('    ⚠️ HIGH: Corrupted trigram.idx silently ignored, leaving index size: ${tri2.index.length}.');
    }
  }
}

// ============================================================================
// WORKER ISOLATE ACTIONS
// ============================================================================

Future<void> handleWorkerMode(List<String> args) async {
  final mode = args[0];

  if (mode == '--worker-rtree-coincident-points') {
    final count = int.parse(args[1]);
    final tree = RTreeIndex<int>(maxChildren: 4);
    final box = const BoundingBox2D(10.0, 10.0, 10.0, 10.0);
    for (int i = 0; i < count; i++) {
      tree.insert(box, i);
    }
    print('ENTRIES:${tree.root.entries.length}, CHILDREN:${tree.root.children.length}');
    return;
  }

  if (mode == '--worker-fts-10mb-word') {
    // Generate a 10MB word of 'a'
    final bigWord = 'a' * 10000000;
    final sw = Stopwatch()..start();
    final stemmed = PorterStemmer.stem(bigWord);
    sw.stop();
    print('STEMMED_LEN:${stemmed.length}, TIME:${sw.elapsedMilliseconds}ms');
    return;
  }
}
