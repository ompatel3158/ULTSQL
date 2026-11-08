import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';

void main() {
  late Directory tempDir;
  late Database db;
  late Interpreter interp;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('sqllogictest_conformance_');
    db = Database(tempDir.path);
    await db.init();
    interp = Interpreter(db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('SQL Logic & Relational Conformance Tests', () {
    test('1. Basic Expressions, Precedence & Math', () async {
      final r1 = await interp.executeScript('SELECT 1 + 2 * 3 AS res;');
      expect(r1.rows.first.first.value, equals(7));

      final r2 = await interp.executeScript('SELECT (1 + 2) * 3 AS res;');
      expect(r2.rows.first.first.value, equals(9));

      final r3 = await interp.executeScript('SELECT 100 / 4 - 5 * 2 AS res;');
      expect(r3.rows.first.first.value, equals(15));
    });

    test('2. Three-Valued Logic & NULL Comparisons', () async {
      await interp.executeScript('''
        CREATE TABLE t_null (id INT PRIMARY KEY, val INT, note TEXT);
        INSERT INTO t_null VALUES (1, 10, 'A');
        INSERT INTO t_null VALUES (2, NULL, 'B');
        INSERT INTO t_null VALUES (3, 30, NULL);
      ''');

      final rNull = await interp.executeScript('SELECT id FROM t_null WHERE val IS NULL;');
      expect(rNull.rows.length, equals(1));
      expect(rNull.rows.first.first.value, equals(2));

      final rNotNull = await interp.executeScript('SELECT id FROM t_null WHERE note IS NOT NULL ORDER BY id;');
      expect(rNotNull.rows.map((r) => r.first.value).toList(), equals([1, 2]));

      // NULL comparison: val = NULL should yield no rows (three-valued logic)
      final rEqNull = await interp.executeScript('SELECT id FROM t_null WHERE val = NULL;');
      expect(rEqNull.rows.isEmpty, isTrue);

      // COALESCE logic
      final rCoalesce = await interp.executeScript('SELECT COALESCE(val, 999) AS cv FROM t_null WHERE id = 2;');
      expect(rCoalesce.rows.first.first.value, equals(999));
    });

    test('3. CASE WHEN Conditional Expressions', () async {
      await interp.executeScript('''
        CREATE TABLE t_case (id INT PRIMARY KEY, score INT);
        INSERT INTO t_case VALUES (1, 95);
        INSERT INTO t_case VALUES (2, 75);
        INSERT INTO t_case VALUES (3, 50);
      ''');

      final r = await interp.executeScript('''
        SELECT id,
               CASE
                 WHEN score >= 90 THEN 'A'
                 WHEN score >= 70 THEN 'B'
                 ELSE 'C'
               END AS grade
        FROM t_case ORDER BY id;
      ''');
      expect(r.rows[0][1].value, equals('A'));
      expect(r.rows[1][1].value, equals('B'));
      expect(r.rows[2][1].value, equals('C'));
    });

    test('4. Aggregations, GROUP BY and HAVING Conformance', () async {
      await interp.executeScript('''
        CREATE TABLE sales (id INT PRIMARY KEY, category TEXT, amount INT);
        INSERT INTO sales VALUES (1, 'Electronics', 100);
        INSERT INTO sales VALUES (2, 'Electronics', 200);
        INSERT INTO sales VALUES (3, 'Books', 30);
        INSERT INTO sales VALUES (4, 'Books', 20);
        INSERT INTO sales VALUES (5, 'Electronics', 300);
      ''');

      final rTotal = await interp.executeScript('SELECT COUNT(*), SUM(amount), AVG(amount), MIN(amount), MAX(amount) FROM sales;');
      expect(rTotal.rows.first[0].value, equals(5));
      expect(rTotal.rows.first[1].value, equals(650));
      expect(rTotal.rows.first[2].value, equals(130.0));
      expect(rTotal.rows.first[3].value, equals(20));
      expect(rTotal.rows.first[4].value, equals(300));

      final rGroup = await interp.executeScript('''
        SELECT category, SUM(amount) AS total
        FROM sales
        GROUP BY category
        HAVING total > 100
        ORDER BY category;
      ''');
      expect(rGroup.rows.length, equals(1));
      expect(rGroup.rows.first[0].value, equals('Electronics'));
      expect(rGroup.rows.first[1].value, equals(600));
    });

    test('5. Joins: INNER JOIN & LEFT JOIN Semantics', () async {
      await interp.executeScript('''
        CREATE TABLE users (id INT PRIMARY KEY, name TEXT);
        CREATE TABLE orders (id INT PRIMARY KEY, user_id INT, total INT);
        INSERT INTO users VALUES (1, 'Alice');
        INSERT INTO users VALUES (2, 'Bob');
        INSERT INTO users VALUES (3, 'Charlie');
        INSERT INTO orders VALUES (101, 1, 50);
        INSERT INTO orders VALUES (102, 1, 70);
        INSERT INTO orders VALUES (103, 2, 90);
      ''');

      final rInner = await interp.executeScript('''
        SELECT u.name, o.total
        FROM users u
        INNER JOIN orders o ON u.id = o.user_id
        ORDER BY o.id;
      ''');
      expect(rInner.rows.length, equals(3));
      expect(rInner.rows[0][0].value, equals('Alice'));
      expect(rInner.rows[0][1].value, equals(50));

      final rLeft = await interp.executeScript('''
        SELECT u.name, o.total
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
        ORDER BY u.id, o.id;
      ''');
      // Charlie has no orders, so total should be NULL
      expect(rLeft.rows.length, equals(4));
      final charlieRow = rLeft.rows.firstWhere((r) => r[0].value == 'Charlie');
      expect(charlieRow[1].value, isNull);
    });

    test('6. Subqueries and Nested In Expressions', () async {
      await interp.executeScript('''
        CREATE TABLE employees (id INT PRIMARY KEY, dept TEXT, salary INT);
        INSERT INTO employees VALUES (1, 'Engineering', 120000);
        INSERT INTO employees VALUES (2, 'Engineering', 90000);
        INSERT INTO employees VALUES (3, 'Marketing', 80000);
        INSERT INTO employees VALUES (4, 'Sales', 70000);
      ''');

      final rIn = await interp.executeScript('''
        SELECT id FROM employees
        WHERE dept IN (SELECT DISTINCT dept FROM employees WHERE salary >= 90000)
        ORDER BY id;
      ''');
      expect(rIn.rows.map((r) => r.first.value).toList(), equals([1, 2]));
    });

    test('7. Set Operations: UNION & UNION ALL', () async {
      await interp.executeScript('''
        CREATE TABLE a (val INT);
        CREATE TABLE b (val INT);
        INSERT INTO a VALUES (1);
        INSERT INTO a VALUES (2);
        INSERT INTO b VALUES (2);
        INSERT INTO b VALUES (3);
      ''');

      final rUnionAll = await interp.executeScript('SELECT val FROM a UNION ALL SELECT val FROM b;');
      expect(rUnionAll.rows.length, equals(4));

      final rUnion = await interp.executeScript('SELECT val FROM a UNION SELECT val FROM b ORDER BY val;');
      expect(rUnion.rows.length, equals(3));
      expect(rUnion.rows.map((r) => r.first.value).toList(), equals([1, 2, 3]));
    });
  });
}
