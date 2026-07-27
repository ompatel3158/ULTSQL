import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'dart:io';

void main() {
  late Database db;
  late Interpreter interpreter;
  final dbPath = 'test_expression_index_db';

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

  test('CREATE INDEX on JSON expression and query with index scan', () async {
    // 1. Create table with JSON column
    await interpreter.executeScript('CREATE TABLE items(id INT, info JSON);');

    // 2. Insert records
    await interpreter.executeScript("INSERT INTO items VALUES (1, '{\"name\": \"Alice\", \"age\": 30}');");
    await interpreter.executeScript("INSERT INTO items VALUES (2, '{\"name\": \"Bob\", \"age\": 25}');");
    await interpreter.executeScript("INSERT INTO items VALUES (3, '{\"name\": \"Charlie\", \"age\": 35}');");

    // 3. Create JSON expression index
    final resIndex = await interpreter.executeScript("CREATE INDEX idx_name ON items((info ->> 'name'));");
    print('CREATE INDEX message: ${resIndex.message}');
    expect(resIndex.message.contains('created successfully'), true);

    // 4. Verify index file is created on disk
    final indexFile = File('$dbPath/idx_name.idx');
    expect(indexFile.existsSync(), true);

    // 5. Run EXPLAIN to check if the planner selects IndexScanNode
    final resExplain = await interpreter.executeScript("EXPLAIN SELECT id FROM items WHERE (info ->> 'name') = 'Bob';");
    print('EXPLAIN Plan:\n${resExplain.toString()}');
    expect(resExplain.toString().contains('IndexScanNode'), true);

    // 6. Run SELECT and check correct row is returned
    final resSelect = await interpreter.executeScript("SELECT id FROM items WHERE (info ->> 'name') = 'Bob';");
    expect(resSelect.rows.length, 1);
    expect(resSelect.rows[0][0].toString(), '2');
  });
}
