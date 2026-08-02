import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void main() {
  const dbDir = 'test_data_subquery_cte';

  Future<void> cleanDir(String path) async {
    final dir = Directory(path);
    for (int i = 0; i < 10; i++) {
      try {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
        await dir.create(recursive: true);
        return;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> deleteDir(String path) async {
    final dir = Directory(path);
    for (int i = 0; i < 10; i++) {
      try {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
        return;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  setUp(() async {
    await cleanDir(dbDir);
  });

  tearDown(() async {
    await deleteDir(dbDir);
  });

  test('Subqueries and CTEs support in UltSQL', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // Create tables
    await interpreter.executeScript('CREATE TABLE t1 (id INT, name TEXT);');
    await interpreter.executeScript('CREATE TABLE t2 (id INT, val TEXT);');
    await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, age INT);');
    await interpreter.executeScript('CREATE TABLE orders (id INT, user_id INT);');

    // Insert data
    await interpreter.executeScript("INSERT INTO t1 VALUES (1, 'Alice');");
    await interpreter.executeScript("INSERT INTO t1 VALUES (2, 'Bob');");
    await interpreter.executeScript("INSERT INTO t2 VALUES (1, 'X');");
    await interpreter.executeScript("INSERT INTO t2 VALUES (2, 'Y');");

    await interpreter.executeScript("INSERT INTO users VALUES (1, 'Alice', 25);");
    await interpreter.executeScript("INSERT INTO users VALUES (2, 'Bob', 35);");
    await interpreter.executeScript("INSERT INTO users VALUES (3, 'Charlie', 18);");

    await interpreter.executeScript("INSERT INTO orders VALUES (101, 1);");
    await interpreter.executeScript("INSERT INTO orders VALUES (102, 3);");

    // 1. Scalar subquery: SELECT id, (SELECT val FROM t2 WHERE t2.id = t1.id) FROM t1;
    {
      final res = await interpreter.executeScript(
        'SELECT id, (SELECT val FROM t2 WHERE t2.id = t1.id) FROM t1 ORDER BY id ASC;'
      );
      expect(res.rows.length, 2);
      expect(res.rows[0][0].toString(), '1');
      expect(res.rows[0][1].toString(), 'X');
      expect(res.rows[1][0].toString(), '2');
      expect(res.rows[1][1].toString(), 'Y');
    }

    // 2. Subquery in FROM: SELECT * FROM (SELECT id, age FROM users) WHERE age > 20;
    {
      final res = await interpreter.executeScript(
        'SELECT * FROM (SELECT id, age FROM users) WHERE age > 20 ORDER BY id ASC;'
      );
      expect(res.rows.length, 2);
      expect(res.rows[0][0].toString(), '1'); // id
      expect(res.rows[0][1].toString(), '25'); // age
      expect(res.rows[1][0].toString(), '2'); // id
      expect(res.rows[1][1].toString(), '35'); // age
    }

    // 3. Subquery in WHERE: SELECT * FROM users WHERE id IN (SELECT user_id FROM orders);
    {
      final res = await interpreter.executeScript(
        'SELECT * FROM users WHERE id IN (SELECT user_id FROM orders) ORDER BY id ASC;'
      );
      expect(res.rows.length, 2);
      expect(res.rows[0][0].toString(), '1'); // Alice (id 1)
      expect(res.rows[1][0].toString(), '3'); // Charlie (id 3)
    }

    // 4. CTE query: WITH young_users AS (SELECT id, name FROM users WHERE age < 30) SELECT name FROM young_users;
    {
      final res = await interpreter.executeScript(
        'WITH young_users AS (SELECT id, name FROM users WHERE age < 30) SELECT name FROM young_users ORDER BY name ASC;'
      );
      expect(res.rows.length, 2);
      expect(res.rows[0][0].toString(), 'Alice');
      expect(res.rows[1][0].toString(), 'Charlie');
    }

    await db.close();
  });
}
