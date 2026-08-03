import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  late String dbDir;
  late Database db;
  late Interpreter interpreter;

  setUp(() async {
    dbDir = Directory.systemTemp.createTempSync('ultsql_user_issues_test_').path;
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

  test('User Query 1: CREATE TABLE with INTEGER, REAL, NOT NULL', () async {
    const sql = '''
      CREATE TABLE benchmark_users (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          age INTEGER,
          salary REAL,
          city TEXT,
          created_at TEXT
      );
    ''';

    final res = await interpreter.executeScript(sql);
    expect(res.message, contains('Table \'benchmark_users\' created successfully'));

    final schema = db.catalog.tables['benchmark_users'];
    expect(schema, isNotNull);
    expect(schema!.columnNames, equals(['id', 'name', 'email', 'age', 'salary', 'city', 'created_at']));
  });

  test('User Query 2: High-Speed PL/SQL Loop Execution', () async {
    const sql = '''
      CREATE TABLE benchmark_users_2 (
        id INT PRIMARY KEY,
        name TEXT,
        email TEXT,
        age INT,
        salary DOUBLE,
        city TEXT
      );

      DECLARE
        i INT := 1;
      BEGIN
        WHILE i <= 1000 LOOP
          INSERT INTO benchmark_users_2 VALUES (
            i,
            'User ' || i,
            'user' || i || '@example.com',
            18 + (i % 50),
            30000.0 + (i % 70000),
            'City ' || (i % 100)
          );

          i := i + 1;
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('Inserted ' || (i - 1) || ' rows.');
      END;
    ''';

    final sw = Stopwatch()..start();
    final res = await interpreter.executeScript(sql);
    sw.stop();

    print('1,000 PL/SQL inserts completed in: ${sw.elapsedMilliseconds} ms (${res.message})');

    final countRes = await interpreter.executeScript('SELECT COUNT(*) AS total FROM benchmark_users_2;');
    expect(countRes.rows.first[0].value, equals(1000));
  });
}
