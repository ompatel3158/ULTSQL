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
import 'package:ultsql/src/version.dart';

int rows = 100000;
int runs = 5;
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
    var sw = Stopwatch()..start();
    db.execute('BEGIN;');
    final ins = db.prepare('INSERT INTO users VALUES (?, ?, ?, ?);');
    for (var i = 1; i <= n; i++) {
      ins.execute([i, 'User_$i', 18 + (i % 62), (i % 1000) / 10.0]);
    }
    ins.close();
    db.execute('COMMIT;');
    sw.stop();
    record('${prefix}insert', 'sqlite', n / secs(sw),
        label: 'Bulk INSERT ($nLabel rows, single txn)', unit: 'rows/s', group: g, higherIsBetter: true);

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
    db.close();
    cleanup(dir);
  }

  // ---------- ULTSQL ----------
  {
    final dir = tmp('ultsql');
    final db = Database('${dir.path}/db');
    await db.init();
    final it = Interpreter(db);
    await it.executeScript('CREATE TABLE users (id INT PRIMARY KEY, name TEXT, age INT, score DOUBLE);');
    final ins = db.prepare('INSERT INTO users VALUES (?, ?, ?, ?);');
    var sw = Stopwatch()..start();
    for (var off = 0; off < n; off += batchSize) {
      final end = min(off + batchSize, n);
      ins.executeBatchSync(List<List<DbValue>>.generate(end - off, (j) {
        final i = off + j + 1;
        return [DbInt(i), DbText('User_$i'), DbInt(18 + (i % 62)), DbDouble((i % 1000) / 10.0)];
      }));
    }
    db.cache.flushAllSync();
    sw.stop();
    record('${prefix}insert', 'ultsql', n / secs(sw),
        label: 'Bulk INSERT ($nLabel rows, single txn)', unit: 'rows/s', group: g, higherIsBetter: true);

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

  {
    final dir = tmp('sqlite_doc');
    final db = sq.sqlite3.open('${dir.path}/d.db');
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA synchronous = NORMAL;');
    db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY, doc TEXT);');
    var sw = Stopwatch()..start();
    db.execute('BEGIN;');
    final st = db.prepare('INSERT INTO users(doc) VALUES (?);');
    for (final d in docs) {
      st.execute([jsonEncode(d)]);
    }
    st.close();
    db.execute('COMMIT;');
    sw.stop();
    record('doc_insert', 'sqlite', n / secs(sw),
        label: 'insertMany $label JSON documents', unit: 'docs/s', group: g, higherIsBetter: true, note: 'SQLite: JSON text column');
    sw = Stopwatch()..start();
    final r = db.select("SELECT doc FROM users WHERE json_extract(doc,'\$.profile.score') >= 50000 "
        "AND json_extract(doc,'\$.role') IN ('admin','developer');");
    sw.stop();
    record('doc_find', 'sqlite', secs(sw) * 1000,
        label: 'Nested-path filter scan (score ≥ 50000, role IN …)', unit: 'ms', group: g, note: 'SQLite: json_extract');
    db.close();
    cleanup(dir);
  }
  {
    final dir = tmp('ult_doc');
    final db = Database('${dir.path}/db');
    await db.init();
    final c = db.collection('users');
    var sw = Stopwatch()..start();
    for (var off = 0; off < n; off += 5000) {
      await c.insertMany(docs.sublist(off, min(off + 5000, n)));
    }
    sw.stop();
    record('doc_insert', 'ultsql', n / secs(sw),
        label: 'insertMany $label JSON documents', unit: 'docs/s', group: g, higherIsBetter: true);
    sw = Stopwatch()..start();
    final r = await c.find({
      'profile.score': {'\$gte': 50000},
      'role': {'\$in': ['admin', 'developer']},
    }).toList();
    sw.stop();
    record('doc_find', 'ultsql', secs(sw) * 1000,
        label: 'Nested-path filter scan (score ≥ 50000, role IN …)', unit: 'ms', group: g);
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
    sw = Stopwatch()..start();
    for (var i = 0; i < n; i++) {
      get.select(['key:$i']);
    }
    sw.stop();
    get.close();
    record('kv_get', 'sqlite', n / secs(sw), label: 'GET $label keys', unit: 'ops/s', group: g, higherIsBetter: true);
    db.close();
    cleanup(dir);
  }
  {
    final dir = tmp('ult_kv');
    final db = Database('${dir.path}/db');
    await db.init();
    final m = <String, dynamic>{for (var i = 0; i < n; i++) 'key:$i': 'value_$i'};
    var sw = Stopwatch()..start();
    await db.kv.mset(m);
    sw.stop();
    record('kv_set', 'ultsql', n / secs(sw), label: 'Batch SET $label keys', unit: 'ops/s', group: g, higherIsBetter: true);
    sw = Stopwatch()..start();
    for (var i = 0; i < n; i++) {
      await db.kv.get('key:$i');
    }
    sw.stop();
    record('kv_get', 'ultsql', n / secs(sw), label: 'GET $label keys', unit: 'ops/s', group: g, higherIsBetter: true);
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

  const q = 50;
  const k = 10;
  var hits = 0;
  final lat = Stopwatch();
  for (var t = 0; t < q; t++) {
    final query = List.generate(dim, (_) => rand.nextDouble() * 2 - 1);
    final lit = '[${query.map((x) => x.toStringAsFixed(6)).join(', ')}]';
    lat.start();
    final res = await it.executeScript(
        "SELECT id, vector_distance(emb, '$lit') AS dist FROM items ORDER BY dist ASC LIMIT $k;");
    lat.stop();
    // Exact brute-force ground truth (L2) for recall@k.
    final truth = List<int>.generate(n, (i) => i)
      ..sort((a, b) => l2(vecs[a], query).compareTo(l2(vecs[b], query)));
    final truthSet = truth.take(k).toSet();
    for (final row in res.rows) {
      if (truthSet.contains(int.parse(row[0].toString()))) hits++;
    }
  }
  record('vec_query', 'ultsql', lat.elapsedMicroseconds / 1000 / q,
      label: 'Top-$k ANN query latency (SQL)', unit: 'ms/query', group: g);
  record('vec_recall', 'ultsql', hits / (q * k) * 100,
      label: 'Recall@$k vs exact brute force', unit: '%', group: g, higherIsBetter: true,
      note: 'Measured against exact L2 brute force; depends on configured distance metric');
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
