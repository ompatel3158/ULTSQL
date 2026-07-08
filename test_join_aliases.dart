import 'dart:io';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';

void main() async {
  const dbDir = 'test_debug_join_aliases';
  final dir = Directory(dbDir);
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
  dir.createSync(recursive: true);

  final db = Database(dbDir);
  await db.init();
  final interpreter = Interpreter(db);

  await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT);');
  await interpreter.executeScript('CREATE TABLE orders (id INT, user_id INT, amount DOUBLE);');

  await interpreter.executeScript('INSERT INTO users VALUES (1, \'Alice\');');
  await interpreter.executeScript('INSERT INTO users VALUES (2, \'Bob\');');

  await interpreter.executeScript('INSERT INTO orders VALUES (100, 1, 15.5);');
  await interpreter.executeScript('INSERT INTO orders VALUES (101, 1, 20.0);');
  await interpreter.executeScript('INSERT INTO orders VALUES (102, 2, 50.5);');

  // Explain with aliases
  print('--- EXPLAIN ---');
  final explainRes = await interpreter.executeScript('''
    EXPLAIN SELECT u.name, COUNT(o.id) AS ord_cnt, SUM(o.amount) AS tot_amt
    FROM orders o
    JOIN users u ON o.user_id = u.id
    GROUP BY u.name
    ORDER BY tot_amt DESC
    LIMIT 100;
  ''');
  if (explainRes.rows.isNotEmpty) {
    print('QUERY PLAN:\n${explainRes.rows[0][0]}');
  } else {
    print('EXPLAIN failed: ${explainRes.message}');
  }

  // Select with aliases
  print('--- SELECT ---');
  final selectRes = await interpreter.executeScript('''
    SELECT u.name, COUNT(o.id) AS ord_cnt, SUM(o.amount) AS tot_amt
    FROM orders o
    JOIN users u ON o.user_id = u.id
    GROUP BY u.name
    ORDER BY tot_amt DESC
    LIMIT 100;
  ''');
  if (selectRes.rows.isNotEmpty) {
    print('Rows returned: ${selectRes.rows.length}');
    for (final r in selectRes.rows) {
      print('Row: $r');
    }
  } else {
    print('SELECT failed: ${selectRes.message}');
  }

  await db.close();
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
}
