import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'dart:io';

void main() {
  late Database db;
  late Interpreter interpreter;
  final dbPath = 'test_vector_metrics_db';

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

  test('Vector metrics integration test - Euclidean, Cosine, and Dot Product', () async {
    // 1. Create table
    await interpreter.executeScript('CREATE TABLE items(id INT, emb VECTOR);');

    // 2. Insert records
    // A: id 1, [0.9, 0.1]
    // B: id 2, [2.0, 2.0]
    await interpreter.executeScript("INSERT INTO items VALUES (1, '[0.9, 0.1]');");
    await interpreter.executeScript("INSERT INTO items VALUES (2, '[2.0, 2.0]');");

    // 3. Test functional distance calculations (non-indexed)
    // Euclidean (default)
    final resEucl = await interpreter.executeScript(
      "SELECT id, vector_distance(emb, '[1.0, 0.0]') AS dist FROM items ORDER BY dist ASC;"
    );
    expect(resEucl.rows.length, 2);
    expect(resEucl.rows[0][0].toString(), '1'); // A is closer in Euclidean (0.1414 vs 2.236)
    expect(resEucl.rows[1][0].toString(), '2');

    // Cosine
    final resCos = await interpreter.executeScript(
      "SELECT id, vector_distance(emb, '[1.0, 0.0]', 'cosine') AS dist FROM items ORDER BY dist ASC;"
    );
    expect(resCos.rows.length, 2);
    expect(resCos.rows[0][0].toString(), '1'); // A is closer in Cosine (0.0061 vs 0.2929)
    expect(resCos.rows[1][0].toString(), '2');

    // Dot Product (negative dot product)
    final resDot = await interpreter.executeScript(
      "SELECT id, vector_distance(emb, '[1.0, 0.0]', 'dot') AS dist FROM items ORDER BY dist ASC;"
    );
    expect(resDot.rows.length, 2);
    expect(resDot.rows[0][0].toString(), '2'); // B is closer/has lower negative dot product (-2.0 vs -0.9)
    expect(resDot.rows[1][0].toString(), '1');

    // 4. Create HNSW index
    final resIndex = await interpreter.executeScript('CREATE INDEX idx_emb ON items(emb) USING HNSW;');
    expect(resIndex.message.contains('created successfully'), true);

    // 5. Test indexed scan with Euclidean (default)
    final explainEucl = await interpreter.executeScript(
      "EXPLAIN SELECT id, vector_distance(emb, '[1.0, 0.0]') AS dist FROM items ORDER BY dist ASC;"
    );
    expect(explainEucl.toString().contains('HnswScanNode'), true);

    final scanEucl = await interpreter.executeScript(
      "SELECT id, vector_distance(emb, '[1.0, 0.0]') AS dist FROM items ORDER BY dist ASC;"
    );
    expect(scanEucl.rows.length, 2);
    expect(scanEucl.rows[0][0].toString(), '1');
    expect(scanEucl.rows[1][0].toString(), '2');

    // 6. Test indexed scan with Cosine metric
    final explainCos = await interpreter.executeScript(
      "EXPLAIN SELECT id, vector_distance(emb, '[1.0, 0.0]', 'cosine') AS dist FROM items ORDER BY dist ASC;"
    );
    expect(explainCos.toString().contains('HnswScanNode'), true);

    final scanCos = await interpreter.executeScript(
      "SELECT id, vector_distance(emb, '[1.0, 0.0]', 'cosine') AS dist FROM items ORDER BY dist ASC;"
    );
    expect(scanCos.rows.length, 2);
    expect(scanCos.rows[0][0].toString(), '1');
    expect(scanCos.rows[1][0].toString(), '2');

    // 7. Test indexed scan with Dot Product metric
    final explainDot = await interpreter.executeScript(
      "EXPLAIN SELECT id, vector_distance(emb, '[1.0, 0.0]', 'dot') AS dist FROM items ORDER BY dist ASC;"
    );
    expect(explainDot.toString().contains('HnswScanNode'), true);

    final scanDot = await interpreter.executeScript(
      "SELECT id, vector_distance(emb, '[1.0, 0.0]', 'dot') AS dist FROM items ORDER BY dist ASC;"
    );
    expect(scanDot.rows.length, 2);
    expect(scanDot.rows[0][0].toString(), '2');
    expect(scanDot.rows[1][0].toString(), '1');
  });
}
