import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'dart:io';

void main() {
  late Database db;
  late Interpreter interpreter;
  final dbPath = 'test_hnsw_prefilter_db';

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

  test('HNSW Index Search Pre-filtering Correctness', () async {
    // 1. Create table with metadata columns and a vector column
    await interpreter.executeScript(
      'CREATE TABLE products(id INT, category TEXT, price INT, embedding VECTOR);',
    );

    // 2. Insert records:
    // Query vector is '[0.1, 0.9]'. We want 'cosine' metric.
    // product 1: shoes, price 100, vector [0.1, 0.9] (dist = 0)
    // product 2: electronics, price 500, vector [0.11, 0.89] (dist = very small, fails category shoes)
    // product 3: shoes, price 150, vector [0.2, 0.8] (dist = small, matches category shoes)
    // product 4: clothes, price 50, vector [0.15, 0.85] (dist = small, fails category shoes)
    // product 5: shoes, price 120, vector [0.5, 0.5] (dist = larger, matches category shoes)
    // product 6: shoes, price 80, vector [0.9, 0.1] (dist = very large, matches category shoes)
    
    await interpreter.executeScript("INSERT INTO products VALUES (1, 'shoes', 100, '[0.1, 0.9]');");
    await interpreter.executeScript("INSERT INTO products VALUES (2, 'electronics', 500, '[0.11, 0.89]');");
    await interpreter.executeScript("INSERT INTO products VALUES (3, 'shoes', 150, '[0.2, 0.8]');");
    await interpreter.executeScript("INSERT INTO products VALUES (4, 'clothes', 50, '[0.15, 0.85]');");
    await interpreter.executeScript("INSERT INTO products VALUES (5, 'shoes', 120, '[0.5, 0.5]');");
    await interpreter.executeScript("INSERT INTO products VALUES (6, 'shoes', 80, '[0.9, 0.1]');");

    // 3. Create HNSW index on embedding column
    final resIndex = await interpreter.executeScript(
      'CREATE INDEX idx_emb ON products(embedding) USING HNSW;',
    );
    expect(resIndex.message.contains('created successfully'), true);

    // 4. Verify index file is created on disk
    final indexFile = File('$dbPath/idx_emb.hnsw');
    expect(indexFile.existsSync(), true);

    // 5. Run EXPLAIN to check if the planner selects HnswScanNode and shows filter
    final resExplain = await interpreter.executeScript(
      "EXPLAIN SELECT id, category FROM products WHERE category = 'shoes' ORDER BY vector_distance(embedding, '[0.1, 0.9]', 'cosine') ASC LIMIT 5;",
    );
    print('EXPLAIN Plan:\n${resExplain.toString()}');
    expect(resExplain.toString().contains('HnswScanNode'), true);
    expect(resExplain.toString().contains('filter:'), true);

    // 6. Run SELECT query with category = 'shoes' filter
    final resSelectShoes = await interpreter.executeScript(
      "SELECT id, category FROM products WHERE category = 'shoes' ORDER BY vector_distance(embedding, '[0.1, 0.9]', 'cosine') ASC LIMIT 5;",
    );
    
    // We expect 4 matching products: ids 1, 3, 5, 6
    expect(resSelectShoes.rows.length, 4);
    
    // In cosine distance order from '[0.1, 0.9]':
    // id 1: [0.1, 0.9] -> cosine distance is 0
    // id 3: [0.2, 0.8] -> cosine distance is small
    // id 5: [0.5, 0.5] -> cosine distance is larger
    // id 6: [0.9, 0.1] -> cosine distance is very large
    // None of the electronics (id 2) or clothes (id 4) should be returned even though they are closer than ids 5 and 6.
    expect(resSelectShoes.rows[0][0].toString(), '1');
    expect(resSelectShoes.rows[1][0].toString(), '3');
    expect(resSelectShoes.rows[2][0].toString(), '5');
    expect(resSelectShoes.rows[3][0].toString(), '6');

    // 7. Run another SELECT query with price < 130 filter
    // Matching products:
    // id 1: shoes, price 100, [0.1, 0.9]
    // id 4: clothes, price 50, [0.15, 0.85]
    // id 5: shoes, price 120, [0.5, 0.5]
    // id 6: shoes, price 80, [0.9, 0.1]
    // electronics (id 2, price 500) and shoes (id 3, price 150) should be filtered out.
    final resSelectPrice = await interpreter.executeScript(
      "SELECT id, category, price FROM products WHERE price < 130 ORDER BY vector_distance(embedding, '[0.1, 0.9]', 'cosine') ASC LIMIT 5;",
    );
    expect(resSelectPrice.rows.length, 4);
    expect(resSelectPrice.rows[0][0].toString(), '1'); // dist 0
    expect(resSelectPrice.rows[1][0].toString(), '4'); // dist small
    expect(resSelectPrice.rows[2][0].toString(), '5'); // dist larger
    expect(resSelectPrice.rows[3][0].toString(), '6'); // dist very large
  });
}
