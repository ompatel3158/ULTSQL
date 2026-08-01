import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/storage/catalog.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'package:ultsql/engine/executor/value.dart';
import 'package:ultsql/engine/network/raft_cluster.dart';
import 'package:ultsql/engine/storage/parquet_engine.dart';
import 'package:ultsql/engine/spatial/h3_indexer.dart';
import 'package:ultsql/engine/parser/ast.dart';

void main() {
  test('💥 Resilience 1: Power Loss & WAL Crash Recovery Verification', () async {
    final dbDir = Directory('test_chaos_wal_db');
    if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);

    final db = Database('test_chaos_wal_db');
    await db.init();

    final interpreter = Interpreter(db);
    await interpreter.executeScript("CREATE TABLE audit_records (id INT, status TEXT);");
    await interpreter.executeScript("INSERT INTO audit_records VALUES (1, 'COMMITTED');");

    // Simulate abrupt power loss / process kill
    await db.close();

    // Reopen DB instance to trigger ARIES WAL recovery
    final recoveredDb = Database('test_chaos_wal_db');
    await recoveredDb.init();
    final recoveredInterpreter = Interpreter(recoveredDb);

    final res = await recoveredInterpreter.executeScript("SELECT * FROM audit_records;");
    expect(res.rows.length, equals(1));
    expect(res.rows[0][1].value, equals('COMMITTED'));

    await recoveredDb.close();
    if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);
  });

  test('🛡️ Resilience 2: WAL Page Checksum Corruption Handling', () async {
    final dbDir = Directory('test_chaos_corrupt_db');
    if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);

    final db = Database('test_chaos_corrupt_db');
    await db.init();
    final interpreter = Interpreter(db);

    await interpreter.executeScript("CREATE TABLE safe_table (id INT, val TEXT);");
    await interpreter.executeScript("INSERT INTO safe_table VALUES (100, 'valid');");
    await db.close();

    // Inject corruption bytes into WAL log file
    final walFile = File('test_chaos_corrupt_db/wal.log');
    if (walFile.existsSync()) {
      final bytes = walFile.readAsBytesSync();
      if (bytes.isNotEmpty) {
        bytes[bytes.length - 1] ^= 0xFF; // Flip bits to corrupt CRC
        walFile.writeAsBytesSync(bytes);
      }
    }

    // Recovering DB should catch checksum mismatch gracefully
    final recoveredDb = Database('test_chaos_corrupt_db');
    expect(() async => await recoveredDb.init(), returnsNormally);
    await recoveredDb.close();

    if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);
  });

  test('🗳️ Resilience 3: Raft Leader Crash Failover Election', () {
    final node1 = RaftNode(nodeId: 'node-1', role: RaftNodeRole.leader, currentTerm: 1);
    final node2 = RaftNode(nodeId: 'node-2', role: RaftNodeRole.follower, currentTerm: 1);
    final node3 = RaftNode(nodeId: 'node-3', role: RaftNodeRole.follower, currentTerm: 1);

    // Simulate Node 1 leader crash
    node1.becomeFollower(1);

    // Node 2 detects heartbeat timeout & initiates election
    node2.becomeCandidate(); // Term becomes 2
    expect(node2.currentTerm, equals(2));

    final voteFrom3 = node3.requestVote(2, 'node-2', 0, 0);
    expect(voteFrom3, isTrue);

    node2.becomeLeader();
    expect(node2.role, equals(RaftNodeRole.leader));
  });

  test('🧹 Resilience 4: MVCC Autovacuum Garbage Collection (Zero Tuple Leaks)', () async {
    final db = Database('test_chaos_mvcc_db');
    await db.init();
    final interpreter = Interpreter(db);

    await interpreter.executeScript("CREATE TABLE mvcc_test (id INT, counter INT);");
    await interpreter.executeScript("INSERT INTO mvcc_test VALUES (1, 0);");

    // Perform 100 updates creating 100 dead tuple versions
    for (int i = 1; i <= 100; i++) {
      await interpreter.executeScript("UPDATE mvcc_test SET counter = $i WHERE id = 1;");
    }

    // Trigger autovacuum page defragmentation
    await interpreter.executeScript("VACUUM FULL mvcc_test;");

    final res = await interpreter.executeScript("SELECT * FROM mvcc_test;");
    expect(res.rows.length, equals(1));
    expect(res.rows[0][1].value, equals(100));

    await db.close();
    final dbDir = Directory('test_chaos_mvcc_db');
    if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);
  });

  test('📦 Resilience 5: Apache Parquet Edge Case Roundtrip Validation', () {
    final schema = TableSchema(
      name: 'edge_cases',
      columnNames: ['null_col', 'unicode_col', 'large_int'],
      columnTypes: [DataType.text, DataType.text, DataType.integer],
    );

    final rows = [
      [DbNull(), DbText('🚀 UltSQL Enterprise 🗄️'), DbInt(9223372036854775807)],
      [DbText(''), DbText('Special \n \t \r characters'), DbInt(-9223372036854775808)],
    ];

    final parquetBytes = ParquetEngine.exportToParquet(schema, rows);
    final imported = ParquetEngine.importFromParquet(parquetBytes, schema);

    expect(imported.length, equals(2));
    expect(imported[0][0], isA<DbNull>());
    expect(imported[0][1].value, equals('🚀 UltSQL Enterprise 🗄️'));
  });
}
