import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void main() {
  test('⚡ Non-fsync & Relaxed Durability Benchmark: UltSQL vs SQLite (synchronous=OFF)', () async {
    final tempDir = Directory.systemTemp.createTempSync('non_fsync_bench_');
    final sqliteDbPath = '${tempDir.path}/sqlite_non_fsync.db';
    final ultDbPath = '${tempDir.path}/ult_non_fsync_db';
    const numRows = 50000;

    print('\n======================================================');
    print('⚡ RELAXED DURABILITY BENCHMARK (NON-FSYNC / SYNCHRONOUS = OFF) ⚡');
    print('======================================================\n');

    // -------------------------------------------------------------
    // 1. SQLite 3 Disk with synchronous = OFF and WAL mode (no fsync disk waits)
    // -------------------------------------------------------------
    final sqliteDb = sqlite.sqlite3.open(sqliteDbPath);
    sqliteDb.execute("PRAGMA journal_mode = WAL;");
    sqliteDb.execute("PRAGMA synchronous = OFF;");
    sqliteDb.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER);");

    final swSqliteInsert = Stopwatch()..start();
    sqliteDb.execute("BEGIN TRANSACTION;");
    final stmtSqlite = sqliteDb.prepare("INSERT INTO users (id, name, age) VALUES (?, ?, ?);");
    for (int i = 1; i <= numRows; i++) {
      stmtSqlite.execute([i, 'User_$i', 20 + (i % 50)]);
    }
    stmtSqlite.dispose();
    sqliteDb.execute("COMMIT;");
    swSqliteInsert.stop();

    // SQLite point lookup (10,000 queries)
    final swSqlitePoint = Stopwatch()..start();
    final pointStmt = sqliteDb.prepare("SELECT * FROM users WHERE id = ?;");
    for (int i = 1; i <= 10000; i++) {
      pointStmt.select([i * 5]);
    }
    pointStmt.dispose();
    swSqlitePoint.stop();

    sqliteDb.dispose();

    // -------------------------------------------------------------
    // 2. SQLite 3 Pure In-Memory (:memory:)
    // -------------------------------------------------------------
    final memSqlite = sqlite.sqlite3.openInMemory();
    memSqlite.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER);");
    final swMemSqliteInsert = Stopwatch()..start();
    memSqlite.execute("BEGIN TRANSACTION;");
    final memStmt = memSqlite.prepare("INSERT INTO users (id, name, age) VALUES (?, ?, ?);");
    for (int i = 1; i <= numRows; i++) {
      memStmt.execute([i, 'User_$i', 20 + (i % 50)]);
    }
    memStmt.dispose();
    memSqlite.execute("COMMIT;");
    swMemSqliteInsert.stop();

    final swMemSqlitePoint = Stopwatch()..start();
    final memPointStmt = memSqlite.prepare("SELECT * FROM users WHERE id = ?;");
    for (int i = 1; i <= 10000; i++) {
      memPointStmt.select([i * 5]);
    }
    memPointStmt.dispose();
    swMemSqlitePoint.stop();
    memSqlite.dispose();

    // -------------------------------------------------------------
    // 3. UltSQL Disk with Batch Group-Commit (Relaxed WAL)
    // -------------------------------------------------------------
    final ultDb = Database(ultDbPath);
    await ultDb.init();
    final interp = Interpreter(ultDb);
    await interp.executeScript("CREATE TABLE users (id INT PRIMARY KEY, name TEXT, age INT);");

    final prepInsert = ultDb.prepare("INSERT INTO users VALUES (?, ?, ?);");
    final batchParams = List<List<DbValue>>.generate(
      numRows,
      (i) => [DbInt(i + 1), DbText('User_${i + 1}'), DbInt(20 + ((i + 1) % 50))],
    );

    final swUltInsert = Stopwatch()..start();
    prepInsert.executeBatchSync(batchParams);
    swUltInsert.stop();

    // UltSQL point lookup (10,000 queries)
    final prepPoint = ultDb.prepare("SELECT * FROM users WHERE id = ?;");
    final swUltPoint = Stopwatch()..start();
    for (int i = 1; i <= 10000; i++) {
      prepPoint.executeSync([DbInt(i * 5)]);
    }
    swUltPoint.stop();

    await ultDb.close();

    // -------------------------------------------------------------
    // Results
    // -------------------------------------------------------------
    final sqliteOffRps = (numRows / (swSqliteInsert.elapsedMilliseconds / 1000)).toStringAsFixed(0);
    final sqliteMemRps = (numRows / (swMemSqliteInsert.elapsedMilliseconds / 1000)).toStringAsFixed(0);
    final ultInsertRps = (numRows / (swUltInsert.elapsedMilliseconds / 1000)).toStringAsFixed(0);
    final sqliteOffPointOps = (10000 / (swSqlitePoint.elapsedMilliseconds / 1000)).toStringAsFixed(0);
    final sqliteMemPointOps = (10000 / (swMemSqlitePoint.elapsedMilliseconds / 1000)).toStringAsFixed(0);
    final ultPointOps = (10000 / (swUltPoint.elapsedMilliseconds / 1000)).toStringAsFixed(0);

    print('\n------------------------------------------------------');
    print('📊 BENCHMARK COMPARISON ($numRows ROWS):');
    print('------------------------------------------------------');
    print('1. Bulk Ingest:');
    print('   - SQLite3 Disk (synchronous=OFF): ${swSqliteInsert.elapsedMilliseconds} ms ($sqliteOffRps rows/s)');
    print('   - SQLite3 In-Memory (:memory:):   ${swMemSqliteInsert.elapsedMilliseconds} ms ($sqliteMemRps rows/s)');
    print('   - UltSQL Disk (Batch Group-Commit):${swUltInsert.elapsedMilliseconds} ms ($ultInsertRps rows/s)');
    print('\n2. Point Lookup (10,000 queries):');
    print('   - SQLite3 Disk (synchronous=OFF): ${swSqlitePoint.elapsedMilliseconds} ms ($sqliteOffPointOps queries/s)');
    print('   - SQLite3 In-Memory (:memory:):   ${swMemSqlitePoint.elapsedMilliseconds} ms ($sqliteMemPointOps queries/s)');
    print('   - UltSQL Disk (B+Tree Page Cache):${swUltPoint.elapsedMilliseconds} ms ($ultPointOps queries/s)');
    print('------------------------------------------------------\n');

    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });
}
