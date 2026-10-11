import 'dart:io';
import 'dart:math';
import 'package:sqlite3/sqlite3.dart' as sq;
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

Directory tmp(String name) => Directory.systemTemp.createTempSync('ultbench_sql_${name}_');

void cleanup(Directory d) {
  try {
    d.deleteSync(recursive: true);
  } catch (_) {}
}

double secs(Stopwatch sw) => sw.elapsedMicroseconds / 1e6;

class MetricResult {
  final String id;
  final String label;
  final String unit;
  final bool higherIsBetter;
  double sqliteVal = 0;
  double ultsqlVal = 0;

  MetricResult({
    required this.id,
    required this.label,
    required this.unit,
    this.higherIsBetter = false,
  });

  bool get ultsqlWins =>
      higherIsBetter ? ultsqlVal > sqliteVal : ultsqlVal < sqliteVal;

  double get ratio {
    if (higherIsBetter) {
      return sqliteVal > 0 ? ultsqlVal / sqliteVal : 0;
    } else {
      return ultsqlVal > 0 ? sqliteVal / ultsqlVal : 0;
    }
  }

  String get summary {
    final winStr = ultsqlWins ? 'WIN (ULTSQL)' : 'WIN (SQLite)';
    final factor = ratio >= 1.0
        ? '${ratio.toStringAsFixed(2)}x faster'
        : '${(1 / ratio).toStringAsFixed(2)}x slower';
    return '$winStr [$factor]';
  }
}

Future<void> main(List<String> args) async {
  int n = 10000;
  if (args.isNotEmpty) {
    n = int.tryParse(args[0]) ?? 10000;
  }
  const lookups = 10000;
  final rand = Random(42);
  final ids = List<int>.generate(lookups, (_) => rand.nextInt(n) + 1);

  stdout.writeln('================================================================');
  stdout.writeln('          ULTSQL vs SQLite Relational SQL Benchmark             ');
  stdout.writeln('             Rows: $n | Point Lookups: $lookups                 ');
  stdout.writeln('================================================================\n');

  final results = <String, MetricResult>{
    'insert': MetricResult(id: 'insert', label: 'Bulk INSERT (single txn)', unit: 'rows/s', higherIsBetter: true),
    'batch_ingest': MetricResult(id: 'batch_ingest', label: 'Batch Ingestion API', unit: 'rows/s', higherIsBetter: true),
    'index': MetricResult(id: 'index', label: 'CREATE INDEX on age', unit: 'ms', higherIsBetter: false),
    'point': MetricResult(id: 'point', label: 'Point Lookup (PK prepared)', unit: 'µs/query', higherIsBetter: false),
    'range': MetricResult(id: 'range', label: 'Range Aggregate (age 30-40)', unit: 'ms/query', higherIsBetter: false),
    'groupby': MetricResult(id: 'groupby', label: 'Full-scan GROUP BY age', unit: 'ms', higherIsBetter: false),
    'update': MetricResult(id: 'update', label: 'UPDATE ~161 rows (indexed)', unit: 'ms', higherIsBetter: false),
    'delete': MetricResult(id: 'delete', label: 'DELETE ~161 rows (indexed)', unit: 'ms', higherIsBetter: false),
    'single_tx': MetricResult(id: 'single_tx', label: 'Single-Tx Auto-Commit INSERT', unit: 'tx/s', higherIsBetter: true),
    'drop': MetricResult(id: 'drop', label: 'DROP TABLE catalog cleanup', unit: 'ms', higherIsBetter: false),
  };

  final sqliteRows = List<List<dynamic>>.generate(n, (j) {
    final i = j + 1;
    return [i, 'User_$i', 18 + (i % 62), (i % 1000) / 10.0];
  });

  final ultsqlRows = List<List<DbValue>>.generate(n, (j) {
    final i = j + 1;
    return [DbInt(i), DbText('User_$i'), DbInt(18 + (i % 62)), DbDouble((i % 1000) / 10.0)];
  });

  // ---------- SQLite ----------
  stdout.writeln('--> Running SQLite benchmarks...');
  final sqDir = tmp('sqlite');
  final sqDb = sq.sqlite3.open('${sqDir.path}/b.db');
  sqDb.execute('PRAGMA journal_mode = WAL;');
  sqDb.execute('PRAGMA synchronous = NORMAL;');
  sqDb.execute('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER, score REAL);');

  // Insert
  var sw = Stopwatch()..start();
  sqDb.execute('BEGIN;');
  final sqIns = sqDb.prepare('INSERT INTO users VALUES (?, ?, ?, ?);');
  for (var i = 0; i < n; i++) {
    sqIns.execute(sqliteRows[i]);
  }
  sqIns.close();
  sqDb.execute('COMMIT;');
  sw.stop();
  results['insert']!.sqliteVal = n / secs(sw);

  // Batch Ingest
  sqDb.execute('CREATE TABLE t_batch (id INTEGER, name TEXT, age INTEGER, score REAL);');
  final sqBatch = sqDb.prepare('INSERT INTO t_batch VALUES (?, ?, ?, ?);');
  sw = Stopwatch()..start();
  sqDb.execute('BEGIN;');
  for (var i = 0; i < n; i++) {
    sqBatch.execute(sqliteRows[i]);
  }
  sqDb.execute('COMMIT;');
  sw.stop();
  sqBatch.close();
  results['batch_ingest']!.sqliteVal = n / secs(sw);

  // Index
  sw = Stopwatch()..start();
  sqDb.execute('CREATE INDEX idx_age ON users(age);');
  sw.stop();
  results['index']!.sqliteVal = secs(sw) * 1000;

  // Point
  final sqPt = sqDb.prepare('SELECT * FROM users WHERE id = ?;');
  for (var i = 0; i < 200; i++) {
    sqPt.select([ids[i]]);
  }
  sw = Stopwatch()..start();
  for (final id in ids) {
    sqPt.select([id]);
  }
  sw.stop();
  sqPt.close();
  results['point']!.sqliteVal = sw.elapsedMicroseconds / lookups;

  // Range
  sw = Stopwatch()..start();
  for (var i = 0; i < 20; i++) {
    sqDb.select('SELECT COUNT(*), AVG(score) FROM users WHERE age >= 30 AND age <= 40;');
  }
  sw.stop();
  results['range']!.sqliteVal = secs(sw) * 1000 / 20;

  // Group By
  sw = Stopwatch()..start();
  for (var i = 0; i < 5; i++) {
    sqDb.select('SELECT age, COUNT(*), AVG(score) FROM users GROUP BY age;');
  }
  sw.stop();
  results['groupby']!.sqliteVal = secs(sw) * 1000 / 5;

  // Update
  sw = Stopwatch()..start();
  sqDb.execute("UPDATE users SET name = 'Updated' WHERE age = 25;");
  sw.stop();
  results['update']!.sqliteVal = secs(sw) * 1000;

  // Delete
  sw = Stopwatch()..start();
  sqDb.execute('DELETE FROM users WHERE age = 26;');
  sw.stop();
  results['delete']!.sqliteVal = secs(sw) * 1000;

  // Single Tx
  final sqSingleDir = tmp('sq_single');
  final sqSingleDb = sq.sqlite3.open('${sqSingleDir.path}/s.db');
  sqSingleDb.execute('CREATE TABLE t_single (id INTEGER, name TEXT);');
  sw = Stopwatch()..start();
  for (var i = 1; i <= 500; i++) {
    sqSingleDb.execute("INSERT INTO t_single VALUES ($i, 'Single_$i');");
  }
  sw.stop();
  results['single_tx']!.sqliteVal = 500 / secs(sw);
  sqSingleDb.dispose();
  cleanup(sqSingleDir);

  // Drop
  sw = Stopwatch()..start();
  sqDb.execute('DROP TABLE users;');
  sw.stop();
  results['drop']!.sqliteVal = secs(sw) * 1000;

  sqDb.dispose();
  cleanup(sqDir);
  stdout.writeln('   SQLite benchmarks complete.');

  // ---------- ULTSQL ----------
  stdout.writeln('--> Running ULTSQL benchmarks...');
  final ultDir = tmp('ultsql');
  final ultDb = Database('${ultDir.path}/db', useWal: true, maxCapacity: 100000);
  ultDb.config.enableAuditLogging = false;
  ultDb.auditLogger.enabled = false;
  await ultDb.init();
  final it = Interpreter(ultDb);
  await it.executeScript('CREATE TABLE users (id INT PRIMARY KEY, name TEXT, age INT, score DOUBLE);');

  // Insert
  final ultIns = ultDb.prepare('INSERT INTO users VALUES (?, ?, ?, ?);');
  sw = Stopwatch()..start();
  ultIns.executeBatchSync(ultsqlRows);
  sw.stop();
  results['insert']!.ultsqlVal = n / secs(sw);

  // Batch Ingest
  await it.executeScript('CREATE TABLE t_batch (id INT, name TEXT, age INT, score DOUBLE);');
  final ultBatch = ultDb.prepare('INSERT INTO t_batch VALUES (?, ?, ?, ?);');
  sw = Stopwatch()..start();
  ultBatch.executeBatchSync(ultsqlRows);
  sw.stop();
  results['batch_ingest']!.ultsqlVal = n / secs(sw);

  // Index
  sw = Stopwatch()..start();
  await it.executeScript('CREATE INDEX idx_age ON users(age);');
  sw.stop();
  results['index']!.ultsqlVal = secs(sw) * 1000;

  // Point
  final ultPt = ultDb.prepare('SELECT * FROM users WHERE id = ?;');
  for (var i = 0; i < 200; i++) {
    ultPt.executeSync([DbInt(ids[i])]);
  }
  sw = Stopwatch()..start();
  for (final id in ids) {
    ultPt.executeSync([DbInt(id)]);
  }
  sw.stop();
  results['point']!.ultsqlVal = sw.elapsedMicroseconds / lookups;

  // Range
  sw = Stopwatch()..start();
  for (var i = 0; i < 20; i++) {
    await it.executeScript('SELECT COUNT(*), AVG(score) FROM users WHERE age >= 30 AND age <= 40;');
  }
  sw.stop();
  results['range']!.ultsqlVal = secs(sw) * 1000 / 20;

  // Group By
  sw = Stopwatch()..start();
  for (var i = 0; i < 5; i++) {
    await it.executeScript('SELECT age, COUNT(*), AVG(score) FROM users GROUP BY age;');
  }
  sw.stop();
  results['groupby']!.ultsqlVal = secs(sw) * 1000 / 5;

  // Update
  sw = Stopwatch()..start();
  await it.executeScript("UPDATE users SET name = 'Updated' WHERE age = 25;");
  sw.stop();
  results['update']!.ultsqlVal = secs(sw) * 1000;

  // Delete
  sw = Stopwatch()..start();
  await it.executeScript('DELETE FROM users WHERE age = 26;');
  sw.stop();
  results['delete']!.ultsqlVal = secs(sw) * 1000;

  // Single Tx
  await it.executeScript('CREATE TABLE t_single (id INT, name TEXT);');
  final ultSingleStmt = ultDb.prepare('INSERT INTO t_single VALUES (?, ?);');
  sw = Stopwatch()..start();
  for (var i = 1; i <= 500; i++) {
    ultSingleStmt.executeSync([DbInt(i), DbText('Single_$i')]);
  }
  sw.stop();
  results['single_tx']!.ultsqlVal = 500 / secs(sw);

  // Drop
  sw = Stopwatch()..start();
  await it.executeScript('DROP TABLE users;');
  sw.stop();
  results['drop']!.ultsqlVal = secs(sw) * 1000;

  await ultDb.close();
  cleanup(ultDir);
  stdout.writeln('   ULTSQL benchmarks complete.\n');

  // ---------- Report ----------
  stdout.writeln('| Benchmark Metric | Unit | SQLite | ULTSQL | Winner / Factor |');
  stdout.writeln('| :--- | :--- | :--- | :--- | :--- |');
  for (final r in results.values) {
    final sqStr = r.sqliteVal >= 100 ? r.sqliteVal.toStringAsFixed(0) : r.sqliteVal.toStringAsFixed(3);
    final ultStr = r.ultsqlVal >= 100 ? r.ultsqlVal.toStringAsFixed(0) : r.ultsqlVal.toStringAsFixed(3);
    stdout.writeln('| ${r.label} | ${r.unit} | $sqStr | $ultStr | ${r.summary} |');
  }
}
