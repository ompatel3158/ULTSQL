import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  late String dbDir;
  late Database db;
  late Interpreter interpreter;

  setUp(() async {
    dbDir = Directory.systemTemp.createTempSync('ultsql_guide_test_').path;
    db = Database(dbDir);
    await db.init();
    interpreter = Interpreter(db);
  });

  tearDown(() async {
    await db.close();
    final d = Directory(dbDir);
    if (d.existsSync()) {
      d.deleteSync(recursive: true);
    }
  });

  test('Guide Section 1: DDL (CREATE, ALTER, DROP, INDEX)', () async {
    // 1. CREATE TABLE
    await interpreter.executeScript('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        salary REAL
      );
    ''');
    expect(db.catalog.tables.containsKey('employees'), isTrue);

    // 2. ALTER TABLE
    await interpreter.executeScript('''
      ALTER TABLE employees ADD email TEXT;
    ''');
    expect(db.catalog.tables['employees']!.columnNames, contains('email'));

    // 3. CREATE INDEX
    await interpreter.executeScript('''
      CREATE INDEX idx_emp_name ON employees (name);
    ''');

    // 4. DROP TABLE
    await interpreter.executeScript('DROP TABLE employees;');
    expect(db.catalog.tables.containsKey('employees'), isFalse);
  });

  test('Guide Section 2 & 3: DML (INSERT, SELECT, UPDATE, DELETE) & Joins', () async {
    await interpreter.executeScript('''
      CREATE TABLE employees (
        id INT PRIMARY KEY,
        name TEXT,
        dept_id INT,
        salary DOUBLE
      );

      CREATE TABLE departments (
        id INT PRIMARY KEY,
        dept_name TEXT
      );

      INSERT INTO departments VALUES (1, 'Engineering');
      INSERT INTO departments VALUES (2, 'HR');

      INSERT INTO employees VALUES (1, 'John', 1, 60000.0);
      INSERT INTO employees VALUES (2, 'Jane', 1, 55000.0);
      INSERT INTO employees VALUES (3, 'Bob', 2, 25000.0);
    ''');

    // UPDATE
    await interpreter.executeScript("UPDATE employees SET salary = 65000 WHERE id = 1;");

    // SELECT
    var sel = await interpreter.executeScript("SELECT name, salary FROM employees WHERE salary > 50000;");
    expect(sel.rows.length, equals(2));

    // INNER JOIN
    var inner = await interpreter.executeScript('''
      SELECT e.name, d.dept_name
      FROM employees e
      INNER JOIN departments d
      ON e.dept_id = d.id;
    ''');
    expect(inner.rows.length, equals(3));

    // LEFT JOIN
    var left = await interpreter.executeScript('''
      SELECT e.name, d.dept_name
      FROM employees e
      LEFT JOIN departments d
      ON e.dept_id = d.id;
    ''');
    expect(left.rows.length, equals(3));

    // CROSS JOIN
    var cross = await interpreter.executeScript('''
      SELECT e.name, d.dept_name
      FROM employees e
      CROSS JOIN departments d;
    ''');
    expect(cross.rows.length, equals(6));

    // DELETE
    await interpreter.executeScript("DELETE FROM employees WHERE salary < 30000;");
    var postDelete = await interpreter.executeScript("SELECT COUNT(*) AS c FROM employees;");
    expect(postDelete.rows.first[0].value, equals(2));
  });

  test('Guide Section 4: Aggregates & Grouping (COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING)', () async {
    await interpreter.executeScript('''
      CREATE TABLE emp (
        id INT PRIMARY KEY,
        dept TEXT,
        salary DOUBLE
      );

      INSERT INTO emp VALUES (1, 'ENG', 70000.0);
      INSERT INTO emp VALUES (2, 'ENG', 80000.0);
      INSERT INTO emp VALUES (3, 'HR', 40000.0);
    ''');

    var countRes = await interpreter.executeScript("SELECT COUNT(*) FROM emp WHERE salary > 50000;");
    expect(countRes.rows.first[0].value, equals(2));

    var sumRes = await interpreter.executeScript("SELECT SUM(salary) FROM emp;");
    expect((sumRes.rows.first[0].value as num).toDouble(), equals(190000.0));

    var avgRes = await interpreter.executeScript("SELECT AVG(salary) FROM emp;");
    expect((avgRes.rows.first[0].value as num).toDouble(), closeTo(63333.33, 0.1));

    var minMax = await interpreter.executeScript("SELECT MIN(salary), MAX(salary) FROM emp;");
    expect((minMax.rows.first[0].value as num).toDouble(), equals(40000.0));
    expect((minMax.rows.first[1].value as num).toDouble(), equals(80000.0));

    var groupBy = await interpreter.executeScript("SELECT dept, AVG(salary) FROM emp GROUP BY dept HAVING AVG(salary) > 60000;");
    expect(groupBy.rows.length, equals(1));
    expect(groupBy.rows.first[0].value, equals('ENG'));
  });

  test('Guide Section 5, 6 & 7: String, Date/Time & Conditional Functions', () async {
    await interpreter.executeScript('''
      CREATE TABLE test_fn (
        id INT PRIMARY KEY,
        first_name TEXT,
        last_name TEXT,
        hire_date TEXT,
        phone TEXT,
        email TEXT,
        salary DOUBLE
      );

      INSERT INTO test_fn VALUES (1, 'Alice', 'Smith', '2026-05-15 10:30:00', NULL, 'alice@test.com', 85000.0);
    ''');

    // String functions
    var concatRes = await interpreter.executeScript("SELECT CONCAT(first_name, ' ', last_name) AS full_name FROM test_fn;");
    expect(concatRes.rows.first[0].value, equals('Alice Smith'));

    var lenRes = await interpreter.executeScript("SELECT LENGTH(first_name) FROM test_fn;");
    expect(lenRes.rows.first[0].value, equals(5));

    var caseStrRes = await interpreter.executeScript("SELECT UPPER(first_name), LOWER(email) FROM test_fn;");
    expect(caseStrRes.rows.first[0].value, equals('ALICE'));
    expect(caseStrRes.rows.first[1].value, equals('alice@test.com'));

    var substrRes = await interpreter.executeScript("SELECT SUBSTRING(first_name, 1, 3) FROM test_fn;");
    expect(substrRes.rows.first[0].value, equals('Ali'));

    var trimRes = await interpreter.executeScript("SELECT TRIM('  hello  ');");
    expect(trimRes.rows.first[0].value, equals('hello'));

    // Date/Time functions
    var dateRes = await interpreter.executeScript("SELECT DATE(hire_date) FROM test_fn;");
    expect(dateRes.rows.first[0].value, equals('2026-05-15'));

    var timeRes = await interpreter.executeScript("SELECT TIME(hire_date) FROM test_fn;");
    expect(timeRes.rows.first[0].value, equals('10:30:00'));

    var dtRes = await interpreter.executeScript("SELECT DATETIME('2026-01-01 12:00:00');");
    expect(dtRes.rows.first[0].value, equals('2026-01-01 12:00:00'));

    var strftimeRes = await interpreter.executeScript("SELECT STRFTIME('%Y-%m-%d', hire_date) FROM test_fn;");
    expect(strftimeRes.rows.first[0].value, equals('2026-05-15'));

    // Conditionals
    var caseExprRes = await interpreter.executeScript('''
      SELECT first_name,
        CASE
          WHEN salary > 80000 THEN 'High'
          ELSE 'Low'
        END AS level
      FROM test_fn;
    ''');
    expect(caseExprRes.rows.first[1].value, equals('High'));

    var coalesceRes = await interpreter.executeScript("SELECT COALESCE(phone, email, 'No contact') FROM test_fn;");
    expect(coalesceRes.rows.first[0].value, equals('alice@test.com'));

    var ifnullRes = await interpreter.executeScript("SELECT IFNULL(phone, 'N/A') FROM test_fn;");
    expect(ifnullRes.rows.first[0].value, equals('N/A'));
  });

  test('Guide Section 8 & 9: PL/SQL Loops/Variables & Transactions', () async {
    await interpreter.executeScript('''
      CREATE TABLE num_table (val INT);
    ''');

    // BEGIN / END block & WHILE loop
    await interpreter.executeScript('''
      DECLARE
        counter INT := 0;
      BEGIN
        WHILE counter < 5 LOOP
          counter := counter + 1;
          INSERT INTO num_table VALUES (counter);
        END LOOP;
      END;
    ''');

    var whileRes = await interpreter.executeScript("SELECT COUNT(*) FROM num_table;");
    expect(whileRes.rows.first[0].value, equals(5));

    // FOR loop
    await interpreter.executeScript('''
      BEGIN
        FOR i IN 6..10 LOOP
          INSERT INTO num_table VALUES (i);
        END LOOP;
      END;
    ''');

    var forRes = await interpreter.executeScript("SELECT COUNT(*) FROM num_table;");
    expect(forRes.rows.first[0].value, equals(10));

    // Transactions: BEGIN TRANSACTION, COMMIT, ROLLBACK
    await interpreter.executeScript("BEGIN TRANSACTION;");
    await interpreter.executeScript("INSERT INTO num_table VALUES (99);");
    await interpreter.executeScript("ROLLBACK;");

    var rbRes = await interpreter.executeScript("SELECT COUNT(*) FROM num_table;");
    expect(rbRes.rows.first[0].value, equals(10));
  });
}
