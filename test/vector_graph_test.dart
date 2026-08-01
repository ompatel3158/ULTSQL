import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';

void main() {
  const dbDir = 'test_data_vector_graph';

  setUp(() async {
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  });

  tearDown(() async {
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('Vector-Graph Hybrid Queries execute successfully', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // 1. Create schemas
    await interpreter.executeScript('CREATE TABLE products (id INT, name TEXT, embedding VECTOR);');
    await interpreter.executeScript('CREATE TABLE product_relations (from_id INT, to_id INT);');

    // 2. Insert records
    // Product 1: Shoes, Product 2: Socks, Product 3: Laptop
    await interpreter.executeScript('INSERT INTO products VALUES (1, \'Shoes\', \'[0.1, 0.9, 0.0]\');');
    await interpreter.executeScript('INSERT INTO products VALUES (2, \'Socks\', \'[0.11, 0.88, 0.02]\');');
    await interpreter.executeScript('INSERT INTO products VALUES (3, \'Laptop\', \'[0.9, 0.1, 0.1]\');');

    // Relations: Shoes (1) -> Socks (2)
    await interpreter.executeScript('INSERT INTO product_relations VALUES (1, 2);');
    // Relations: Socks (2) -> Laptop (3)
    await interpreter.executeScript('INSERT INTO product_relations VALUES (2, 3);');

    // 3. Define relationship
    final relRes = await interpreter.executeScript(
      'CREATE RELATIONSHIP recommendation FROM product_relations TO products ON to_id = id;'
    );
    expect(relRes.message, contains("created successfully"));

    // 4. Run Vector-Graph hybrid query:
    // Query relationships and traverse to related products.
    final queryRes = await interpreter.executeScript(
      'SELECT product_relations.from_id, products.name FROM product_relations WITH RELATIONSHIP recommendation;'
    );
    expect(queryRes.rows.length, 2);

    // First relation: 1 -> 2 (Socks)
    expect(queryRes.rows[0][0].toString(), '1');
    expect(queryRes.rows[0][1].toString(), 'Socks');

    // Second relation: 2 -> 3 (Laptop)
    expect(queryRes.rows[1][0].toString(), '2');
    expect(queryRes.rows[1][1].toString(), 'Laptop');

    // 5. Test semantic vector search combined with relationship traversal
    final hybridRes = await interpreter.executeScript('''
      SELECT product_relations.from_id, products.name 
      FROM product_relations 
      WHERE vector_distance(products.embedding, '[0.91, 0.09, 0.09]') < 0.2
      WITH RELATIONSHIP recommendation;
    ''');
    
    expect(hybridRes.rows.length, 1);
    expect(hybridRes.rows[0][0].toString(), '2'); // from_id: Socks (2)
    expect(hybridRes.rows[0][1].toString(), 'Laptop'); // products.name: Laptop

    await db.close();
  });
}
