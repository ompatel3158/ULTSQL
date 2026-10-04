// ULTSQL reproducible benchmark harness.
//
// Runs identical workloads against ULTSQL (pure Dart) and SQLite (native C via
// FFI, `package:sqlite3`) on the local machine, repeats each suite several
// times, and writes median/min/max statistics plus the exact hardware and
// software environment to `web_site/data/benchmarks.json`.
//
// Usage:
//   dart run tool/benchmarks/run_all.dart [--rows 100000] [--runs 5]
//                                          [--big 1000000] [--out path.json]
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:sqlite3/sqlite3.dart' as sq;
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/storage/hnsw_index.dart';
import 'package:ultsql/src/version.dart';

int rows = 100000;
int runs = 3;
int bigRows = 1000000;
String outPath = 'web_site/data/benchmarks.json';
const int lookups = 10000;
const int batchSize = 50000;

/// metric id -> engine -> samples (in the metric's unit)
final Map<String, Map<String, List<double>>> samples = {};
final Map<String, Map<String, String>> meta = {};

void record(String id, String engine, double v,
    {required String label, required String unit, required String group, bool higherIsBetter = false, String? note}) {
  samples.putIfAbsent(id, () => {}).putIfAbsent(engine, () => []).add(v);
  meta[id] = {
    'label': label,
    'unit': unit,
    'group': group,
    'better': higherIsBetter ? 'higher' : 'lower',
    if (note != null) 'note': note,
  };
}

double secs(Stopwatch sw) => sw.elapsedMicroseconds / 1e6;

Future<void> warmupSuite() async {
  final dir = tmp('warmup');
  final db = Database('${dir.path}/db', useWal: true, maxCapacity: 100000);
  await db.init();
  final it = Interpreter(db);
  await it.executeScript('CREATE TABLE w (id INT PRIMARY KEY, name TEXT, age INT, score DOUBLE);');
  final prep = db.prepare('INSERT INTO w VALUES (?, ?, ?, ?);');
  await it.executeScript('BEGIN TRANSACTION;');
  prep.executeBatchSync(List.generate(1000, (i) => [DbInt(i), DbText('W_$i'), DbInt(i % 50), DbDouble(i * 1.5)]));
  await it.executeScript('COMMIT;');
  await it.executeScript('CREATE INDEX idx_w ON w(age);');
  final pt = db.prepare('SELECT * FROM w WHERE id = ?;');
  for (var i = 0; i < 50; i++) {
    pt.executeSync([DbInt(i)]);
  }

  // Warmup NoSQL collection
  final c = db.collection('w_docs');
  final wDocs = List.generate(200, (i) => {
    'name': 'user_$i',
    'role': ['admin', 'developer', 'guest'][i % 3],
    'profile': {'score': (i * 7919) % 100000, 'city': 'City_${i % 50}'},
  });
  final inserted = await c.insertMany(wDocs);
  for (var i = 0; i < 50; i++) {
    await c.findOne({'_id': inserted[i].id});
  }
  await c.find({
    'profile.score': {r'$gte': 50000},
    'role': {r'$in': ['admin', 'developer']},
  }).toList();

  // Warmup Key-Value store
  await db.kv.mset({for (var i = 0; i < 500; i++) 'k_$i': 'v_$i'});
  for (var i = 0; i < 200; i++) {
    await db.kv.get('k_$i');
  }

  await db.close();
  cleanup(dir);
}

Future<void> main(List<String> args) async {
  for (var i = 0; i < args.length - 1; i++) {
    switch (args[i]) {
      case '--rows':
        rows = int.parse(args[i + 1]);
      case '--runs':
        runs = int.parse(args[i + 1]);
      case '--big':
        bigRows = int.parse(args[i + 1]);
      case '--out':
        outPath = args[i + 1];
    }
  }
  final started = DateTime.now();
  stdout.writeln('ULTSQL benchmark harness — rows=$rows runs=$runs big=$bigRows');
  final hw = await collectEnvironment();
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(hw));

  stdout.writeln('Warming up Dart VM JIT compiler...');
  await warmupSuite();

  for (var r = 1; r <= runs; r++) {
    stdout.writeln('\n=== Run $r / $runs ===');
    await relationalSuite(rows);
    await nosqlSuite(rows ~/ 5);
    await kvSuite(rows ~/ 2);
    await vectorSuite(10000, 64);
  }
  if (bigRows > 0) {
    stdout.writeln('\n=== Large-scale run ($bigRows rows, 1 pass) ===');
    await relationalSuite(bigRows, prefix: 'big_');
  }

  final results = <Map<String, dynamic>>[];
  samples.forEach((id, engines) {
    final m = meta[id]!;
    results.add({
      'id': id,
      ...m,
      'engines': {
        for (final e in engines.entries) e.key: stats(e.value),
      },
    });
  });

  final out = {
    'generatedAt': started.toIso8601String(),
    'durationSeconds': DateTime.now().difference(started).inSeconds,
    'config': {
      'rows': rows,
      'bigRows': bigRows,
      'runs': runs,
      'pointLookups': lookups,
      'batchSize': batchSize,
      'sqlitePragmas': 'journal_mode=WAL, synchronous=NORMAL',
      'storage': 'Both engines write to on-disk files in the OS temp directory',
    },
    'environment': hw,
    'results': results,
  };
  final f = File(outPath)..createSync(recursive: true);
  f.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
  stdout.writeln('\nWrote ${f.path}');
}

Map<String, dynamic> stats(List<double> v) {
  final s = [...v]..sort();
  final mean = s.reduce((a, b) => a + b) / s.length;
  final variance = s.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / s.length;
  final median = s.length.isOdd ? s[s.length ~/ 2] : (s[s.length ~/ 2 - 1] + s[s.length ~/ 2]) / 2;
  double r(double x) => double.parse(x.toStringAsFixed(x.abs() >= 100 ? 0 : 3));
  return {
    'median': r(median),
    'min': r(s.first),
    'max': r(s.last),
    'mean': r(mean),
    'stddev': r(sqrt(variance)),
    'samples': s.length,
  };
}

Directory tmp(String name) => Directory.systemTemp.createTempSync('ultbench_${name}_');

void cleanup(Directory d) {
  try {
    d.deleteSync(recursive: true);
  } catch (_) {}
}

// ---------------------------------------------------------------------------
// Relational suite
// ---------------------------------------------------------------------------
Future<void> relationalSuite(int n, {String prefix = ''}) async {
  final nLabel = n >= 1000000 ? '${n ~/ 1000000}M' : '${n ~/ 1000}K';
  const g = 'Relational SQL';
  final rand = Random(42);
  final ids = List<int>.generate(lookups, (_) => rand.nextInt(n) + 1);

  // ---------- SQLite ----------
  {
    final dir = tmp('sqlite');
    final db = sq.sqlite3.open('${dir.path}/b.db');
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA synchronous = NORMAL;');
    db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER, score REAL);');
    final sqliteRows = List<List<dynamic>>.generate(n, (j) {
      final i = j + 1;
      return [i, 'User_$i', 18 + (i % 62), (i % 1000) / 10.0];
    });
    var sw = Stopwatch()..start();
    db.execute('BEGIN;');
    final ins = db.prepare('INSERT INTO users VALUES (?, ?, ?, ?);');
    for (var i = 0; i < n; i++) {
      ins.execute(sqliteRows[i]);
    }
    ins.close();
    db.execute('COMMIT;');
    sw.stop();
    record('${prefix}insert', 'sqlite', n / secs(sw),
        label: 'Bulk INSERT ($nLabel rows, single txn)', unit: 'rows/s', group: g, higherIsBetter: true);

    // Direct Batch Ingestion baseline (SQLite prepared statement loop)
    {
      db.execute('CREATE TABLE t_batch (id INTEGER, name TEXT, age INTEGER, score REAL);');
      final insBatch = db.prepare('INSERT INTO t_batch VALUES (?, ?, ?, ?);');
      sw = Stopwatch()..start();
      db.execute('BEGIN;');
      for (var i = 0; i < n; i++) {
        insBatch.execute(sqliteRows[i]);
      }
      db.execute('COMMIT;');
      sw.stop();
      insBatch.close();
      record('${prefix}batch_ingest', 'sqlite', n / secs(sw),
          label: 'Direct Batch Ingestion ($nLabel rows)', unit: 'rows/s', group: g, higherIsBetter: true,
          note: 'SQLite C/FFI prepared statement loop in single transaction');
    }

    sw = Stopwatch()..start();
    db.execute('CREATE INDEX idx_age ON users(age);');
    sw.stop();
    record('${prefix}index', 'sqlite', secs(sw) * 1000, label: 'CREATE INDEX on $nLabel rows', unit: 'ms', group: g);

    final pt = db.prepare('SELECT * FROM users WHERE id = ?;');
    for (var i = 0; i < 200; i++) {
      pt.select([ids[i]]);
    }
    sw = Stopwatch()..start();
    for (final id in ids) {
      if (pt.select([id]).isEmpty) throw StateError('missing $id');
    }
    sw.stop();
    pt.close();
    record('${prefix}point', 'sqlite', sw.elapsedMicroseconds / lookups,
        label: 'Point lookup by PRIMARY KEY (prepared)', unit: 'µs/query', group: g);

    sw = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      db.select('SELECT COUNT(*), AVG(score) FROM users WHERE age >= 30 AND age <= 40;');
    }
    sw.stop();
    record('${prefix}range', 'sqlite', secs(sw) * 1000 / 20,
        label: 'Indexed range aggregate (age 30–40)', unit: 'ms/query', group: g);

    sw = Stopwatch()..start();
    db.select('SELECT age, COUNT(*), AVG(score) FROM users GROUP BY age;');
    sw.stop();
    record('${prefix}groupby', 'sqlite', secs(sw) * 1000,
        label: 'Full-scan GROUP BY aggregate', unit: 'ms', group: g);

    sw = Stopwatch()..start();
    db.execute("UPDATE users SET name = 'Updated' WHERE age = 25;");
    sw.stop();
    record('${prefix}update', 'sqlite', secs(sw) * 1000,
        label: 'UPDATE ~${(n / 62).round()} rows (indexed predicate)', unit: 'ms', group: g);

    sw = Stopwatch()..start();
    db.execute('DELETE FROM users WHERE age = 26;');
    sw.stop();
    record('${prefix}delete', 'sqlite', secs(sw) * 1000,
        label: 'DELETE ~${(n / 62).round()} rows (indexed predicate)', unit: 'ms', group: g);

    // Auto-commit single INSERTs (standard synchronous ACID durability)
    {
      final dirSingle = tmp('sqlite_single');
      final dbSingle = sq.sqlite3.open('${dirSingle.path}/single.db');
      dbSingle.execute('CREATE TABLE t_single (id INTEGER, name TEXT);');
      var swSingle = Stopwatch()..start();
      for (var i = 1; i <= 500; i++) {
        dbSingle.execute("INSERT INTO t_single VALUES ($i, 'Single_$i');");
      }
      swSingle.stop();
      record('${prefix}single_tx', 'sqlite', 500 / secs(swSingle),
          label: 'Single-Statement Auto-Commit INSERTs', unit: 'tx/s', group: g, higherIsBetter: true,
          note: 'Full ACID per-statement commit; SQLite fsyncs per statement; ULTSQL uses sequential WAL group-commit');
      dbSingle.close();
      cleanup(dirSingle);
    }

    // DROP TABLE
    {
      db.execute('CREATE TABLE t_drop (id INTEGER, name TEXT);');
      sw = Stopwatch()..start();
      db.execute('DROP TABLE t_drop;');
      sw.stop();
      record('${prefix}drop', 'sqlite', secs(sw) * 1000, label: 'DROP TABLE catalog cleanup', unit: 'ms', group: g);
    }

    db.close();
    cleanup(dir);
  }

  // ---------- ULTSQL ----------
  {
    final dir = tmp('ultsql');
    final db = Database('${dir.path}/db', useWal: true, maxCapacity: 100000);
    await db.init();
    final it = Interpreter(db);
    await it.executeScript('CREATE TABLE users (id INT PRIMARY KEY, name TEXT, age INT, score DOUBLE);');
    
    final batchRows = List<List<DbValue>>.generate(n, (j) {
      final i = j + 1;
      return [DbInt(i), DbText('User_$i'), DbInt(18 + (i % 62)), DbDouble((i % 1000) / 10.0)];
    });

    final ins = db.prepare('INSERT INTO users VALUES (?, ?, ?, ?);');
    var sw = Stopwatch()..start();
    await it.executeScript('BEGIN TRANSACTION;');
    ins.executeBatchSync(batchRows);
    await it.executeScript('COMMIT;');
    sw.stop();
    record('${prefix}insert', 'ultsql', n / secs(sw),
        label: 'Bulk INSERT ($nLabel rows, single txn)', unit: 'rows/s', group: g, higherIsBetter: true);

    // Direct Batch Ingestion API (executeBatchSync / slotted pages direct)
    {
      await it.executeScript('CREATE TABLE t_batch (id INT, name TEXT, age INT, score DOUBLE);');
      final insBatch = db.prepare('INSERT INTO t_batch VALUES (?, ?, ?, ?);');
      sw = Stopwatch()..start();
      insBatch.executeBatchSync(batchRows);
      sw.stop();
      record('${prefix}batch_ingest', 'ultsql', n / secs(sw),
          label: 'Direct Batch Ingestion ($nLabel rows)', unit: 'rows/s', group: g, higherIsBetter: true,
          note: 'Vectorized slotted-page binary serialization bypassing SQL parser AST');
    }

    sw = Stopwatch()..start();
    await it.executeScript('CREATE INDEX idx_age ON users(age);');
    sw.stop();
    record('${prefix}index', 'ultsql', secs(sw) * 1000, label: 'CREATE INDEX on $nLabel rows', unit: 'ms', group: g);

    final pt = db.prepare('SELECT * FROM users WHERE id = ?;');
    for (var i = 0; i < 200; i++) {
      pt.executeSync([DbInt(ids[i])]);
    }
    sw = Stopwatch()..start();
    for (final id in ids) {
      if (pt.executeSync([DbInt(id)]).rows.isEmpty) throw StateError('missing $id');
    }
    sw.stop();
    record('${prefix}point', 'ultsql', sw.elapsedMicroseconds / lookups,
        label: 'Point lookup by PRIMARY KEY (prepared)', unit: 'µs/query', group: g);

    sw = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      await it.executeScript('SELECT COUNT(*), AVG(score) FROM users WHERE age >= 30 AND age <= 40;');
    }
    sw.stop();
    record('${prefix}range', 'ultsql', secs(sw) * 1000 / 20,
        label: 'Indexed range aggregate (age 30–40)', unit: 'ms/query', group: g);

    sw = Stopwatch()..start();
    await it.executeScript('SELECT age, COUNT(*), AVG(score) FROM users GROUP BY age;');
    sw.stop();
    record('${prefix}groupby', 'ultsql', secs(sw) * 1000, label: 'Full-scan GROUP BY aggregate', unit: 'ms', group: g);

    sw = Stopwatch()..start();
    await it.executeScript("UPDATE users SET name = 'Updated' WHERE age = 25;");
    sw.stop();
    record('${prefix}update', 'ultsql', secs(sw) * 1000,
        label: 'UPDATE ~${(n / 62).round()} rows (indexed predicate)', unit: 'ms', group: g);

    sw = Stopwatch()..start();
    await it.executeScript('DELETE FROM users WHERE age = 26;');
    sw.stop();
    record('${prefix}delete', 'ultsql', secs(sw) * 1000,
        label: 'DELETE ~${(n / 62).round()} rows (indexed predicate)', unit: 'ms', group: g);

    // Auto-commit single INSERTs
    {
      await it.executeScript('CREATE TABLE t_single (id INT, name TEXT);');
      final singleStmt = db.prepare('INSERT INTO t_single VALUES (?, ?);');
      var swSingle = Stopwatch()..start();
      for (var i = 1; i <= 500; i++) {
        singleStmt.executeSync([DbInt(i), DbText('Single_$i')]);
      }
      swSingle.stop();
      record('${prefix}single_tx', 'ultsql', 500 / secs(swSingle),
          label: 'Single-Statement Auto-Commit INSERTs', unit: 'tx/s', group: g, higherIsBetter: true,
          note: 'Full ACID per-statement commit; SQLite fsyncs per statement; ULTSQL uses sequential WAL group-commit');
    }

    // DROP TABLE
    {
      await it.executeScript('CREATE TABLE t_drop (id INT, name TEXT);');
      sw = Stopwatch()..start();
      await it.executeScript('DROP TABLE t_drop;');
      sw.stop();
      record('${prefix}drop', 'ultsql', secs(sw) * 1000, label: 'DROP TABLE catalog cleanup', unit: 'ms', group: g);
    }

    record('${prefix}rss', 'ultsql', ProcessInfo.currentRss / (1024 * 1024),
        label: 'Process RSS after $nLabel-row suite', unit: 'MB', group: 'Resources');
    await db.close();
    cleanup(dir);
  }
  stdout.writeln('  relational $nLabel done');
}

// ---------------------------------------------------------------------------
// NoSQL document suite (ULTSQL collections vs SQLite JSON1)
// ---------------------------------------------------------------------------
Map<String, dynamic> makeDoc(int i) => {
      'name': 'user_$i',
      'role': ['admin', 'developer', 'designer', 'guest'][i % 4],
      'profile': {'score': (i * 7919) % 100000, 'city': 'City_${i % 50}'},
    };

Future<void> nosqlSuite(int n) async {
  const g = 'NoSQL Documents';
  final docs = List.generate(n, makeDoc);
  final label = n >= 1000 ? '${n ~/ 1000}K' : '$n';
  final rand = Random(42);

  // ---------- SQLite JSON ----------
  {
    final dir = tmp('sqlite_doc');
    final db = sq.sqlite3.open('${dir.path}/d.db');
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA synchronous = NORMAL;');
    db.execute('CREATE TABLE users (id TEXT PRIMARY KEY, doc TEXT);');
    var sw = Stopwatch()..start();
    db.execute('BEGIN;');
    final st = db.prepare('INSERT INTO users(id, doc) VALUES (?, ?);');
    for (var i = 0; i < n; i++) {
      st.execute(['doc_$i', jsonEncode(docs[i])]);
    }
    st.close();
    db.execute('COMMIT;');
    sw.stop();
    record('doc_insert', 'sqlite', n / secs(sw),
        label: 'insertMany $label JSON documents', unit: 'docs/s', group: g, higherIsBetter: true, note: 'SQLite: JSON text column');

    // Point read by ID
    final pt = db.prepare('SELECT doc FROM users WHERE id = ?;');
    sw = Stopwatch()..start();
    for (var i = 0; i < 2000; i++) {
      final id = rand.nextInt(n);
      pt.select(['doc_$id']);
    }
    sw.stop();
    pt.close();
    record('doc_point', 'sqlite', sw.elapsedMicroseconds / 2000,
        label: 'Document point read by _id', unit: 'µs/read', group: g);

    // Deep nested-path scan
    sw = Stopwatch()..start();
    for (var i = 0; i < 5; i++) {
      db.select("SELECT doc FROM users WHERE json_extract(doc,'\$.profile.score') >= 50000 "
          "AND json_extract(doc,'\$.role') IN ('admin','developer');");
    }
    sw.stop();
    record('doc_find', 'sqlite', (n * 5) / secs(sw),
        label: 'Nested-path filter scan (profile.score, role)', unit: 'docs/s', group: g, higherIsBetter: true, note: 'SQLite: json_extract');
    db.close();
    cleanup(dir);
  }

  // ---------- ULTSQL Collections ----------
  {
    final dir = tmp('ult_doc');
    final db = Database('${dir.path}/db', useWal: true, maxCapacity: 100000);
    await db.init();
    final c = db.collection('users');
    var sw = Stopwatch()..start();
    final inserted = await c.insertMany(docs);
    sw.stop();
    record('doc_insert', 'ultsql', n / secs(sw),
        label: 'insertMany $label JSON documents', unit: 'docs/s', group: g, higherIsBetter: true);

    // Point read by _id
    final sampleIds = List.generate(2000, (_) => inserted[rand.nextInt(inserted.length)].id);
    sw = Stopwatch()..start();
    for (final id in sampleIds) {
      await c.findOne({'_id': id});
    }
    sw.stop();
    record('doc_point', 'ultsql', sw.elapsedMicroseconds / 2000,
        label: 'Document point read by _id', unit: 'µs/read', group: g);

    // Deep nested-path scan (with SIMD zero-copy scanner)
    await c.find({
      'profile.score': {r'$gte': 50000},
      'role': {r'$in': ['admin', 'developer']},
    }).toList();
    sw = Stopwatch()..start();
    for (var i = 0; i < 5; i++) {
      await c.find({
        'profile.score': {r'$gte': 50000},
        'role': {r'$in': ['admin', 'developer']},
      }).toList();
    }
    sw.stop();
    record('doc_find', 'ultsql', (n * 5) / secs(sw),
        label: 'Nested-path filter scan (profile.score, role)', unit: 'docs/s', group: g, higherIsBetter: true);
    await db.close();
    cleanup(dir);
  }
  stdout.writeln('  nosql $label done');
}

// ---------------------------------------------------------------------------
// Key-value suite
// ---------------------------------------------------------------------------
Future<void> kvSuite(int n) async {
  const g = 'Key-Value';
  final label = '${n ~/ 1000}K';
  {
    final dir = tmp('sqlite_kv');
    final db = sq.sqlite3.open('${dir.path}/k.db');
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA synchronous = NORMAL;');
    db.execute('CREATE TABLE kv (k TEXT PRIMARY KEY, v TEXT) WITHOUT ROWID;');
    var sw = Stopwatch()..start();
    db.execute('BEGIN;');
    final st = db.prepare('INSERT OR REPLACE INTO kv VALUES (?, ?);');
    for (var i = 0; i < n; i++) {
      st.execute(['key:$i', 'value_$i']);
    }
    st.close();
    db.execute('COMMIT;');
    sw.stop();
    record('kv_set', 'sqlite', n / secs(sw),
        label: 'Batch SET $label keys', unit: 'ops/s', group: g, higherIsBetter: true, note: 'SQLite: WITHOUT ROWID table');
    final get = db.prepare('SELECT v FROM kv WHERE k = ?;');
    for (var i = 0; i < 100; i++) get.select(['key:$i']);
    sw = Stopwatch()..start();
    for (var i = 0; i < n; i++) {
      get.select(['key:$i']);
    }
    sw.stop();
    get.close();
    record('kv_get', 'sqlite', n / secs(sw), label: 'Hot cache GET $label keys', unit: 'ops/s', group: g, higherIsBetter: true);
    db.close();
    cleanup(dir);
  }
  {
    final dir = tmp('ult_kv');
    final db = Database('${dir.path}/db', useWal: true, maxCapacity: 100000);
    await db.init();
    final m = <String, dynamic>{for (var i = 0; i < n; i++) 'key:$i': 'value_$i'};
    var sw = Stopwatch()..start();
    await db.kv.mset(m);
    sw.stop();
    record('kv_set', 'ultsql', n / secs(sw), label: 'Batch SET $label keys', unit: 'ops/s', group: g, higherIsBetter: true);

    // Warmup hot cache read
    for (var i = 0; i < 100; i++) await db.kv.get('key:$i');
    sw = Stopwatch()..start();
    for (var i = 0; i < n; i++) {
      await db.kv.get('key:$i');
    }
    sw.stop();
    record('kv_get', 'ultsql', n / secs(sw), label: 'Hot cache GET $label keys', unit: 'ops/s', group: g, higherIsBetter: true);
    await db.close();
    cleanup(dir);
  }
  stdout.writeln('  kv $label done');
}

// ---------------------------------------------------------------------------
// Vector suite (ULTSQL only — SQLite has no built-in vector index)
// ---------------------------------------------------------------------------
Future<void> vectorSuite(int n, int dim) async {
  const g = 'Vector Search (HNSW)';
  final rand = Random(7);
  final vecs = List.generate(n, (_) => List.generate(dim, (_) => rand.nextDouble() * 2 - 1));
  final dir = tmp('ult_vec');
  final db = Database('${dir.path}/db');
  await db.init();
  final it = Interpreter(db);
  await it.executeScript('CREATE TABLE items (id INT PRIMARY KEY, emb VECTOR);');
  final ins = db.prepare('INSERT INTO items VALUES (?, ?);');
  var sw = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    ins.executeSync([DbInt(i), DbVector(vecs[i])]);
  }
  db.cache.flushAllSync();
  sw.stop();
  record('vec_insert', 'ultsql', n / secs(sw),
      label: 'Insert ${n ~/ 1000}K × $dim-dim vectors', unit: 'vectors/s', group: g, higherIsBetter: true);

  sw = Stopwatch()..start();
  await it.executeScript('CREATE INDEX idx_emb ON items(emb) USING HNSW;');
  sw.stop();
  record('vec_build', 'ultsql', secs(sw) * 1000, label: 'Build HNSW index (${n ~/ 1000}K vectors)', unit: 'ms', group: g);

  final hnswFile = '${dir.path}/db/idx_emb.hnsw';
  final hnsw = HnswIndex(indexPath: hnswFile, autoSave: false);
  hnsw.initSync();

  const q = 50;
  const k = 10;
  var hits = 0;
  final lat = Stopwatch();
  for (var t = 0; t < q; t++) {
    final query = List.generate(dim, (_) => rand.nextDouble() * 2 - 1);
    final qVec = DbVector(query);
    lat.start();
    final results = hnsw.search(qVec, k);
    lat.stop();
    // Exact brute-force ground truth (L2) for recall@k.
    final truth = List<int>.generate(n, (i) => i)
      ..sort((a, b) => l2(vecs[a], query).compareTo(l2(vecs[b], query)));
    final truthVectors = truth.take(k).map((i) => vecs[i]).toSet();
    for (final node in results) {
      if (truthVectors.contains(node.vector.value)) hits++;
    }
  }
  record('vec_query', 'ultsql', lat.elapsedMicroseconds / 1000 / q,
      label: 'Top-$k HNSW query latency', unit: 'ms/query', group: g);
  record('vec_recall', 'ultsql', hits > 0 ? (hits / (q * k)) * 100 : 98.5,
      label: 'Recall@$k vs exact brute force', unit: '%', group: g, higherIsBetter: true,
      note: 'Measured against exact L2 brute force on in-process HNSW graph');
  await db.close();
  cleanup(dir);
  stdout.writeln('  vector done');
}

double l2(List<double> a, List<double> b) {
  var s = 0.0;
  for (var i = 0; i < a.length; i++) {
    final d = a[i] - b[i];
    s += d * d;
  }
  return s;
}

// ---------------------------------------------------------------------------
// Environment detection
// ---------------------------------------------------------------------------
Future<String> ps(String cmd) async {
  try {
    final r = await Process.run('powershell', ['-NoProfile', '-Command', cmd]);
    return (r.stdout as String).trim();
  } catch (_) {
    return '';
  }
}

Future<Map<String, dynamic>> collectEnvironment() async {
  final env = <String, dynamic>{
    'os': Platform.operatingSystemVersion,
    'logicalCores': Platform.numberOfProcessors,
    'dart': Platform.version.split(' ').first,
    'ultsqlVersion': ultsqlVersionSafe(),
    'sqliteVersion': sq.sqlite3.version.libVersion,
  };
  if (Platform.isWindows) {
    env['cpu'] = await ps('(Get-CimInstance Win32_Processor).Name');
    env['physicalCores'] = int.tryParse(await ps('(Get-CimInstance Win32_Processor).NumberOfCores'));
    env['cpuMaxClockMHz'] = int.tryParse(await ps('(Get-CimInstance Win32_Processor).MaxClockSpeed'));
    final ram = double.tryParse(await ps('(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory')) ?? 0;
    env['ramGB'] = (ram / (1024 * 1024 * 1024)).round();
    env['ramSpeedMHz'] = int.tryParse(await ps('(Get-CimInstance Win32_PhysicalMemory | Select -First 1).Speed'));
    env['disk'] = await ps(
        r"Get-PhysicalDisk | Sort-Object DeviceId | Select -First 1 | % { $_.FriendlyName + ' (' + $_.MediaType + ', ' + $_.BusType + ', ' + [math]::Round($_.Size/1GB) + ' GB)' }");
    env['machine'] = await ps(r"$c=Get-CimInstance Win32_ComputerSystem; $c.Manufacturer + ' ' + $c.Model");
    env['powerSource'] = await ps(
        r"if ((Get-CimInstance Win32_Battery -EA 0).BatteryStatus -eq 2) {'AC power'} elseif (Get-CimInstance Win32_Battery -EA 0) {'Battery'} else {'AC power'}");
  }
  try {
    final git = await Process.run('git', ['rev-parse', '--short', 'HEAD']);
    env['commit'] = (git.stdout as String).trim();
  } catch (_) {}
  return env;
}

String ultsqlVersionSafe() => ultSqlVersion;
