import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'dart:io';

void main() {
  late Database db;
  late Interpreter interpreter;
  final dbPath = 'test_hnsw_sql_db';

  setUp(() async {
    final dir = Directory(dbPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    db = Database(dbPath);
    await db.init();
    interpreter = Interpreter(db);
  });

  tearDown(() async {
    await interpreter.db.close();
    await db.close();
    final dir = Directory(dbPath);
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  test('CREATE INDEX USING HNSW and optimized select query', () async {
    // 1. Create table with vector column
    await interpreter.executeScript('CREATE TABLE items(id INT, emb VECTOR);');

    // 2. Insert records
    await interpreter.executeScript("INSERT INTO items VALUES (1, '[0.1, 0.9]');");
    await interpreter.executeScript("INSERT INTO items VALUES (2, '[0.5, 0.5]');");
    await interpreter.executeScript("INSERT INTO items VALUES (3, '[-0.2, 0.8]');");

    // 3. Create HNSW index via SQL!
    final resIndex = await interpreter.executeScript('CREATE INDEX idx_emb ON items(emb) USING HNSW;');
    print('CREATE INDEX message: ${resIndex.message}');
    expect(resIndex.message.contains('created successfully'), true);

    // 4. Verify index file is created on disk!
    final indexFile = File('$dbPath/idx_emb.hnsw');
    expect(indexFile.existsSync(), true);

    // 5. Run EXPLAIN to check if the planner selects HnswScanNode!
    final resExplain = await interpreter.executeScript("EXPLAIN SELECT id, vector_distance(emb, '[0.0, 1.0]') AS dist FROM items ORDER BY dist ASC LIMIT 2;");
    print('EXPLAIN Plan:\n${resExplain.toString()}');
    expect(resExplain.toString().contains('HnswScanNode'), true);

    // 6. Run SELECT and check nearest neighbors!
    final resSelect = await interpreter.executeScript("SELECT id, vector_distance(emb, '[0.0, 1.0]') AS dist FROM items ORDER BY dist ASC LIMIT 2;");
    expect(resSelect.rows.length, 2);
    expect(resSelect.rows[0][0].toString(), '1');
    expect(resSelect.rows[1][0].toString(), '3');
  });
}
