import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/executor/interpreter.dart';

void main() {
  test('1,000,000 Orders Join & Aggregate Benchmark', () async {
    final dbDir = 'test_complex_benchmark';
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // 1. Setup tables
    await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT);');
    await interpreter.executeScript('CREATE TABLE orders (id INT, user_id INT, amount DOUBLE);');

    // 2. Generate 1,000 users using PL/SQL Loop
    print('Generating 1,000 users...');
    final userPlSql = '''
DECLARE
  i INT := 0;
BEGIN
  BEGIN TRANSACTION;
  WHILE i < 1000 LOOP
    i := i + 1;
    INSERT INTO users VALUES (i, 'User_' || i);
  END LOOP;
  COMMIT;
END;
''';
    await interpreter.executeScript(userPlSql);

    // 3. Generate 1,000,000 orders using PL/SQL Loop
    print('Generating 1,000,000 orders...');
    final swInsert = Stopwatch()..start();
    final orderPlSql = '''
DECLARE
  i INT := 0;
  uid INT := 1;
  amt DOUBLE := 10.0;
BEGIN
  BEGIN TRANSACTION;
  WHILE i < 1000000 LOOP
    i := i + 1;
    uid := (i % 1000) + 1;
    amt := CAST((i % 100) AS DOUBLE) + 5.5;
    INSERT INTO orders VALUES (i, uid, amt);
  END LOOP;
  COMMIT;
END;
''';
    final insertRes = await interpreter.executeScript(orderPlSql);
    swInsert.stop();
    expect(insertRes.message, contains('committed'));
    print('1,000,000 Orders inserted in: ${swInsert.elapsedMilliseconds}ms (${swInsert.elapsedMilliseconds / 1000000}ms per insert)');
    print('Throughput: ${(1000000 / (swInsert.elapsedMilliseconds / 1000)).toStringAsFixed(0)} inserts/second');

    // 4. Print EXPLAIN
    final explainRes = await interpreter.executeScript('''
      EXPLAIN SELECT users.name,
             COUNT(orders.id) AS ord_count,
             SUM(orders.amount) AS total_amount
      FROM orders
      JOIN users
      ON orders.user_id = users.id
      GROUP BY users.name
      ORDER BY total_amount DESC
      LIMIT 100;
    ''');
    print('\nQUERY PLAN:\n${explainRes.rows[0][0]}');

    // 5. Execute query and measure performance
    print('\nExecuting Join and Aggregate query...');
    final swQuery = Stopwatch()..start();
    final queryRes = await interpreter.executeScript('''
      SELECT users.name,
             COUNT(orders.id) AS ord_count,
             SUM(orders.amount) AS total_amount
      FROM orders
      JOIN users
      ON orders.user_id = users.id
      GROUP BY users.name
      ORDER BY total_amount DESC
      LIMIT 100;
    ''');
    swQuery.stop();

    print('\nQuery completed in: ${swQuery.elapsedMilliseconds}ms');
    print('Rows returned: ${queryRes.rows.length}');

    // Print first 10 rows
    print('\nTop 10 Results:');
    print('name | ord_count | total_amount');
    for (int i = 0; i < 10 && i < queryRes.rows.length; i++) {
      final r = queryRes.rows[i];
      print('${r[0]} | ${r[1]} | ${r[2]}');
    }

    await db.close();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }, timeout: Timeout(Duration(minutes: 2)));
}
