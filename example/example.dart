import 'package:ultsql/ultsql.dart';

void main() async {
  print('====================================================');
  print('🚀 UltSQL Quick Start Example');
  print('====================================================');

  // 1. Initialize UltSQL in memory mode (1.2M+ rows/sec)
  final interpreter = await LocalDatabaseService.instance.init(defaultDbName: ':memory:');

  // 2. Create Table & Insert Multimodal Vector / Document Data
  await interpreter.executeScript('''
    CREATE TABLE products (
      id INT PRIMARY KEY,
      name TEXT,
      price DOUBLE,
      embedding VECTOR
    );

    INSERT INTO products VALUES (1, 'Gaming Laptop', 1499.99, '[0.15, 0.82, -0.34]');
    INSERT INTO products VALUES (2, 'Wireless Headphones', 199.99, '[0.12, 0.79, -0.31]');
  ''');

  // 3. Perform SQL Query with Vector Distance Search
  final result = await LocalDatabaseService.instance.executeQuery('''
    SELECT name, price, vector_distance(embedding, '[0.14, 0.81, -0.33]') AS dist
    FROM products
    ORDER BY dist ASC;
  ''');

  print('Execution Time: ${result['execution_time_ms']} ms');
  print('Columns       : ${result['columns']}');
  print('Rows          : ${result['rows']}');
}
