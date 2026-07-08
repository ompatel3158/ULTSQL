import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';

void main() {
  const dbDir = 'test_data_engine';

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

  test('Relational SQL, NoSQL Dotted Paths, Vector Search, and PL/SQL Loops', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // 1. DDL: Create tables
    final createRes = await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, dept_id INT);');
    expect(createRes.message, contains("created successfully"));

    final createDeptRes = await interpreter.executeScript('CREATE TABLE depts (id INT, name TEXT);');
    expect(createDeptRes.message, contains("created successfully"));

    // 2. DML: Inserts
    await interpreter.executeScript('INSERT INTO depts VALUES (1, \'Engineering\');');
    await interpreter.executeScript('INSERT INTO depts VALUES (2, \'Sales\');');
    
    await interpreter.executeScript('INSERT INTO users VALUES (10, \'Alice\', 1);');
    await interpreter.executeScript('INSERT INTO users VALUES (20, \'Bob\', 1);');
    await interpreter.executeScript('INSERT INTO users VALUES (30, \'Charlie\', 2);');

    // 3. Relational Query: JOIN and WHERE
    final selectRes = await interpreter.executeScript(
        'SELECT users.name, depts.name FROM users JOIN depts ON users.dept_id = depts.id WHERE depts.id = 1;'
    );
    expect(selectRes.rows.length, 2);
    // Columns should be user name and dept name
    expect(selectRes.columns, contains('users.name'));
    expect(selectRes.columns, contains('depts.name'));

    // 4. NoSQL: Dotted JSON Extraction
    await interpreter.executeScript('CREATE TABLE customers (id INT, info JSON);');
    await interpreter.executeScript('INSERT INTO customers VALUES (1, \'{"name": "Jack", "age": 30, "address": {"city": "Paris"}}\');');
    await interpreter.executeScript('INSERT INTO customers VALUES (2, \'{"name": "Jill", "age": 20, "address": {"city": "London"}}\');');

    final jsonRes = await interpreter.executeScript(
        'SELECT info.name, info.address.city FROM customers WHERE info.age >= 25;'
    );
    expect(jsonRes.rows.length, 1);
    expect(jsonRes.rows[0][0].toString(), 'Jack');
    expect(jsonRes.rows[0][1].toString(), 'Paris');

    // 5. AI Vector Similarity Search
    await interpreter.executeScript('CREATE TABLE items (id INT, label TEXT, embedding VECTOR);');
    await interpreter.executeScript('INSERT INTO items VALUES (1, \'Shoes\', \'[0.1, 0.9, -0.1]\');');
    await interpreter.executeScript('INSERT INTO items VALUES (2, \'Shirt\', \'[0.9, 0.1, 0.2]\');');

    // Query closest item to target vector [0.12, 0.88, -0.08] (should match Shoes)
    final vectorRes = await interpreter.executeScript(
        'SELECT label, vector_distance(embedding, \'[0.12, 0.88, -0.08]\') AS dist FROM items ORDER BY dist ASC LIMIT 1;'
    );
    expect(vectorRes.rows.length, 1);
    // First column is label
    expect(vectorRes.rows[0][0].toString(), 'Shoes');
    // Distance should be very small
    final dist = (vectorRes.rows[0][1] as DbDouble).value;
    expect(dist, lessThan(0.05));

    // 6. PL/SQL: Loops, Conditionals, Variables
    final plsqlRes = await interpreter.executeScript('''
DECLARE
  x INT := 0;
  y INT := 1;
BEGIN
  WHILE x < 5 LOOP
    x := x + 1;
    y := y * 2;
    DBMS_OUTPUT.PUT_LINE('x=' || x || ', y=' || y);
  END LOOP;
END;
''');
    expect(plsqlRes.message, contains("executed successfully"));
    expect(interpreter.dbmsOutputLog.length, 5);
    expect(interpreter.dbmsOutputLog.last, 'x=5, y=32');

    // Test PL/SQL Modulo (%) and IF statement
    final plsqlModRes = await interpreter.executeScript('''
DECLARE
  counter INT := 0;
  total INT := 0;
BEGIN
  WHILE counter < 10 LOOP
    counter := counter + 1;
    total := total + counter;
    IF counter % 2 = 0 THEN
      DBMS_OUTPUT.PUT_LINE('Iteration ' || counter || ': EVEN');
    ELSE
      DBMS_OUTPUT.PUT_LINE('Iteration ' || counter || ': ODD');
    END IF;
  END LOOP;
END;
''');
    expect(plsqlModRes.message, contains("executed successfully"));
    expect(interpreter.dbmsOutputLog.length, 10);
    expect(interpreter.dbmsOutputLog[0], 'Iteration 1: ODD');
    expect(interpreter.dbmsOutputLog[1], 'Iteration 2: EVEN');
    expect(interpreter.dbmsOutputLog.last, 'Iteration 10: EVEN');

    // 7. GENERATE command test
    final generateRes = await interpreter.executeScript('GENERATE DATA;');
    expect(generateRes.message, contains("=== GENERATION SUCCESSFUL ==="));
    expect(generateRes.rows[0][0].toString(), 'SUCCESS');

    // Verify tables exist after generate
    final verifyRes = await interpreter.executeScript('SELECT name FROM depts;');
    expect(verifyRes.rows.length, 2);

    // 8. LIKE string matching test
    await interpreter.executeScript('CREATE TABLE strings (id INT, txt TEXT);');
    await interpreter.executeScript('INSERT INTO strings VALUES (1, \'User123\');');
    await interpreter.executeScript('INSERT INTO strings VALUES (2, \'Admin456\');');
    await interpreter.executeScript('INSERT INTO strings VALUES (3, \'User789\');');
    final likeRes = await interpreter.executeScript('SELECT txt FROM strings WHERE txt LIKE \'User%\';');
    expect(likeRes.rows.length, 2);
    expect(likeRes.rows[0][0].toString(), 'User123');
    expect(likeRes.rows[1][0].toString(), 'User789');

    // 9. GROUP BY and COUNT(*) test
    await interpreter.executeScript('CREATE TABLE ages (name TEXT, age INT);');
    await interpreter.executeScript('INSERT INTO ages VALUES (\'A\', 20);');
    await interpreter.executeScript('INSERT INTO ages VALUES (\'B\', 20);');
    await interpreter.executeScript('INSERT INTO ages VALUES (\'C\', 30);');
    await interpreter.executeScript('INSERT INTO ages VALUES (\'D\', 20);');
    await interpreter.executeScript('INSERT INTO ages VALUES (\'E\', 30);');
    await interpreter.executeScript('INSERT INTO ages VALUES (\'F\', 40);');

    final groupRes = await interpreter.executeScript('''
      SELECT age, COUNT(*) AS total
      FROM ages
      GROUP BY age
      ORDER BY total DESC;
    ''');
    expect(groupRes.rows.length, 3);
    expect(groupRes.rows[0][0].toString(), '20');
    expect(groupRes.rows[0][1].toString(), '3'); // total count
    expect(groupRes.rows[1][0].toString(), '30');
    expect(groupRes.rows[1][1].toString(), '2');
    expect(groupRes.rows[2][0].toString(), '40');
    expect(groupRes.rows[2][1].toString(), '1');

    // 10. T-SQL style block & CAST test
    final tsqlRes = await interpreter.executeScript('''
      DECLARE idx INT = 1;
      DECLARE val TEXT = 'User';
      WHILE idx <= 3
      BEGIN
        SET val = val + CAST(idx AS TEXT);
        SET idx = idx + 1;
      END;
    ''');
    expect(tsqlRes.message, contains("executed successfully"));

    // 11. CREATE INDEX test
    await interpreter.executeScript('CREATE TABLE indexed_users (id INT, name TEXT, age INT);');
    await interpreter.executeScript('INSERT INTO indexed_users VALUES (1, \'Alice\', 25);');
    await interpreter.executeScript('INSERT INTO indexed_users VALUES (2, \'Bob\', 30);');
    await interpreter.executeScript('INSERT INTO indexed_users VALUES (3, \'Charlie\', 25);');

    final createIdxRes = await interpreter.executeScript('CREATE INDEX idx_users_age ON indexed_users(age);');
    expect(createIdxRes.message, contains("created successfully"));

    // Check if query uses index scan
    final selectIdxRes = await interpreter.executeScript('SELECT name FROM indexed_users WHERE age = 30;');
    expect(selectIdxRes.rows.length, 1);
    expect(selectIdxRes.rows[0][0].toString(), 'Bob');
    expect(selectIdxRes.message, contains("Index scan completed successfully"));

    // 12. SHOW TABLES and SHOW INDEXES test
    final showTablesRes = await interpreter.executeScript('SHOW TABLES;');
    expect(showTablesRes.rows.length, greaterThanOrEqualTo(5));
    expect(showTablesRes.columns, contains('table_name'));

    final showIndexesRes = await interpreter.executeScript('SHOW INDEXES;');
    expect(showIndexesRes.rows.length, greaterThanOrEqualTo(2));
    expect(showIndexesRes.columns, contains('index_name'));

    // 13. BETWEEN, Logical AND/OR, and Empty Aggregate COUNT(*) test
    final betweenRes = await interpreter.executeScript('SELECT name FROM indexed_users WHERE age BETWEEN 25 AND 35;');
    expect(betweenRes.rows.length, 3);

    final andRes = await interpreter.executeScript('SELECT name FROM indexed_users WHERE age > 20 AND age < 30;');
    expect(andRes.rows.length, 2);

    final orRes = await interpreter.executeScript('SELECT name FROM indexed_users WHERE age = 30 OR age = 100;');
    expect(orRes.rows.length, 1);
    expect(orRes.rows[0][0].toString(), 'Bob');

    final countEmptyRes = await interpreter.executeScript('SELECT COUNT(*) FROM indexed_users WHERE age > 100;');
    expect(countEmptyRes.rows.length, 1);
    expect(countEmptyRes.rows[0][0].toString(), '0');

    // Test count aggregate with index point-lookup scan bypass check
    final countIndexedRes = await interpreter.executeScript('SELECT COUNT(*) FROM indexed_users WHERE age = 25;');
    expect(countIndexedRes.rows.length, 1);
    expect(countIndexedRes.rows[0][0].toString(), '2');

    // Verify index persistence across database reopens
    await db.close();
    
    final db2 = Database(dbDir);
    await db2.init();
    final interpreter2 = Interpreter(db2);

    final showIndexesRes2 = await interpreter2.executeScript('SHOW INDEXES;');
    final idxNames = showIndexesRes2.rows.map((r) => r[0].toString().toLowerCase()).toList();
    expect(idxNames, contains('idx_users_age'));

    await db2.close();
  });

  test('EXPLAIN, SQL Aggregates, Cost-Based Planner, and Delayed Indexing', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // 1. Create table and insert rows
    await interpreter.executeScript('CREATE TABLE test_stats (id INT, val DOUBLE);');
    
    // Check delayed indexing/inserts
    await interpreter.executeScript('INSERT INTO test_stats VALUES (1, 10.0);');
    await interpreter.executeScript('INSERT INTO test_stats VALUES (2, 20.0);');
    await interpreter.executeScript('INSERT INTO test_stats VALUES (3, 30.0);');
    await interpreter.executeScript('INSERT INTO test_stats VALUES (4, 40.0);');
    await interpreter.executeScript('INSERT INTO test_stats VALUES (5, 50.0);');

    // 2. Test Aggregates: SUM, AVG, MIN, MAX, COUNT
    final aggRes = await interpreter.executeScript(
      'SELECT SUM(val), AVG(val), MIN(val), MAX(val), COUNT(val) FROM test_stats;'
    );
    expect(aggRes.rows.length, 1);
    expect(aggRes.rows[0][0].toString(), '150.0'); // SUM
    expect(aggRes.rows[0][1].toString(), '30.0'); // AVG
    expect(aggRes.rows[0][2].toString(), '10.0'); // MIN
    expect(aggRes.rows[0][3].toString(), '50.0'); // MAX
    expect(aggRes.rows[0][4].toString(), '5'); // COUNT

    // 3. Create index and verify stats
    await interpreter.executeScript('CREATE INDEX idx_test_stats_val ON test_stats(val);');

    // Stats should be populated
    final stats = db.catalog.getTableStats('test_stats');
    expect(stats, isNotNull);
    expect(stats!.rowCount, 5);
    expect(stats.columnStats['val']?.min, 10.0);
    expect(stats.columnStats['val']?.max, 50.0);

    // 4. Test EXPLAIN
    final explainRes = await interpreter.executeScript(
      'EXPLAIN SELECT * FROM test_stats WHERE val BETWEEN 20 AND 25;'
    );
    expect(explainRes.columns[0], 'QUERY PLAN');
    expect(explainRes.rows[0][0].toString(), contains('IndexScanNode'));

    // Check selectivity cost-based choosing:
    // If we select a very wide range, planner should choose RowScanNode instead of IndexScanNode
    final explainResWide = await interpreter.executeScript(
      'EXPLAIN SELECT * FROM test_stats WHERE val BETWEEN 0 AND 100;'
    );
    expect(explainResWide.rows[0][0].toString(), contains('RowScanNode'));

    await db.close();
  });
}
