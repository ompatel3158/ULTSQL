import 'dart:io';
import 'package:ultsql/ultsql.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run tool/test_out_of_process_persistence.dart <write|read> <db_dir>');
    exit(1);
  }

  final mode = args[0];
  final dbPath = args[1];

  if (mode == 'write') {
    final dir = Directory(dbPath);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);

    print('[Process 1 - Writer] Starting write process on PID ${pid}...');
    final engine = await UltSqlEngine.openFile(dbPath);
    final interp = Interpreter(engine.db);

    await interp.executeScript('CREATE TABLE sensor_data (id INT PRIMARY KEY, sensor TEXT, reading DOUBLE);');
    await interp.executeScript('BEGIN TRANSACTION;');
    for (int i = 1; i <= 500; i++) {
      await interp.executeScript("INSERT INTO sensor_data VALUES ($i, 'sensor_${i % 10}', ${(i * 1.5).toStringAsFixed(2)});");
    }
    await interp.executeScript('COMMIT;');

    // Also write a NoSQL document
    final coll = engine.collection('metrics');
    await coll.insertOne({'_id': 'm1', 'host': 'node-us-east-1', 'cpu': 92.4, 'tags': ['prod', 'web']});

    // Also write a KV entry
    await engine.kv.set('active_cluster', 'alpha-primary');

    await engine.close();
    print('[Process 1 - Writer] Write complete, database closed. Exiting process.');
    exit(0);
  } else if (mode == 'read') {
    print('[Process 2 - Reader] Starting reader process on PID ${pid}...');
    final engine = await UltSqlEngine.openFile(dbPath);
    final interp = Interpreter(engine.db);

    final countRes = await interp.executeScript('SELECT COUNT(*) AS total FROM sensor_data;');
    final total = countRes.rows.first.first.value;
    print('  - SQL Row Count: $total (Expected: 500)');

    final sampleRes = await interp.executeScript('SELECT sensor, reading FROM sensor_data WHERE id = 250;');
    print('  - Sample Row 250: ${sampleRes.rows.first.map((v) => v.value).toList()} (Expected: [sensor_0, 375.0])');

    final coll = engine.collection('metrics');
    final doc = await coll.findOne({'_id': 'm1'});
    print('  - NoSQL Document: ${doc?.data}');

    final cluster = await engine.kv.get('active_cluster');
    print('  - KV active_cluster: $cluster (Expected: "alpha-primary")');

    await engine.close();

    if (total == 500 && sampleRes.rows.isNotEmpty && doc != null && cluster == 'alpha-primary') {
      print('🎉 [Process 2 - Reader] OUT-OF-PROCESS PERSISTENCE VERIFIED 100%!');
      exit(0);
    } else {
      print('❌ [Process 2 - Reader] PERSISTENCE CHECK FAILED!');
      exit(1);
    }
  }
}
