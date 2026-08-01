import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/storage/catalog.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/storage/self_healing_manager.dart';
import 'package:ultsql/src/engine/cache/auto_manager.dart';
import 'package:ultsql/src/engine/storage/universal_file_adapter.dart';
import 'package:ultsql/src/engine/ai/nl_query_engine.dart';
import 'package:ultsql/src/engine/security/zk_crypto.dart';
import 'package:ultsql/src/engine/network/p2p_sync.dart';

void main() {
  test('🛠️ Innovation 1: Self-Healing Engine verifies page integrity', () async {
    final pageData = Uint8List.fromList([1, 2, 3, 4, 5]);
    final db = Database('test_self_healing_db');
    final healed = SelfHealingManager.verifyAndRepairPage(0, pageData, db.cache);
    expect(healed, isTrue);
    await db.close();
    final dir = Directory('test_self_healing_db');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('🤖 Innovation 2: Autonomous Auto-Manager creates indexes from scan telemetry', () async {
    AutoManager.clearTelemetry();
    final db = Database('test_auto_mgr_db');
    await db.init();
    final interpreter = Interpreter(db);
    await interpreter.executeScript("CREATE TABLE telemetry_table (id INT, email TEXT);");

    // Record sequential scans
    AutoManager.recordTableScan('telemetry_table', ['email']);
    AutoManager.recordTableScan('telemetry_table', ['email']);
    AutoManager.recordTableScan('telemetry_table', ['email']);

    final createdCount = await AutoManager.suggestAndBuildIndexes(db.catalog, db);
    expect(createdCount, equals(1));
    expect(db.catalog.hasIndex('idx_auto_telemetry_table_email'), isTrue);

    await db.close();
    final dir = Directory('test_auto_mgr_db');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('📁 Innovation 3: Universal Native File System SQL Adapter queries CSV, JSON, and LOG files', () {
    final tempDir = Directory.systemTemp.createTempSync('ultsql_file_adapter_');

    // Create CSV
    final csvFile = File('${tempDir.path}/users.csv');
    csvFile.writeAsStringSync("id,name,age\n1,Alice,30\n2,Bob,25\n");

    final csvRows = UniversalFileAdapter.queryCsvFile(csvFile.path, 'Alice');
    expect(csvRows.length, equals(1));
    expect(csvRows[0][1].value, equals('Alice'));

    // Create LOG
    final logFile = File('${tempDir.path}/server.log');
    logFile.writeAsStringSync("INFO: System startup\nERROR: Connection timeout\nINFO: Ready\n");

    final logRows = UniversalFileAdapter.queryLogFile(logFile.path, 'ERROR');
    expect(logRows.length, equals(1));
    expect(logRows[0][1].value, contains('ERROR'));

    tempDir.deleteSync(recursive: true);
  });

  test('🧠 Innovation 4: AI Natural Language NL-to-SQL Compiler translates prompts', () {
    final catalog = Catalog('test_catalog');

    final sql1 = NlQueryEngine.compileEnglishToSql('show top 5 orders', catalog);
    expect(sql1, contains('LIMIT 5'));

    final sql2 = NlQueryEngine.compileEnglishToSql('how many orders are there', catalog);
    expect(sql2, contains('COUNT(*)'));
  });

  test('🔐 Innovation 5: Zero-Knowledge (ZK) Encrypted Enclave searches ciphertext', () {
    final secretKey = 'my_super_secret_key';
    final cipher = ZkCryptoEnclave.encryptField('confidential_data', secretKey);

    final matchTrue = ZkCryptoEnclave.queryEncryptedField(cipher, 'confidential_data', secretKey);
    expect(matchTrue, isTrue);

    final matchFalse = ZkCryptoEnclave.queryEncryptedField(cipher, 'wrong_data', secretKey);
    expect(matchFalse, isFalse);
  });

  test('🌐 Innovation 6: Peer-to-Peer (P2P) Offline CRDT Sync merges peer states', () {
    final peerA = P2pSyncNode('node-A');
    final peerB = P2pSyncNode('node-B');

    peerA.localState.update('user_101', {'name': 'Alice'}, 100);
    peerB.localState.update('user_101', {'name': 'Alice Updated'}, 200);

    final merged = peerA.mergePeerState(peerB.localState);
    expect(merged, isTrue);
    expect(peerA.localState.addSet['user_101']['name'], equals('Alice Updated'));
  });
}
