import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'package:ultsql/engine/executor/value.dart';
import 'dart:io';

void main() {
  late Database db;
  late Interpreter interpreter;
  final dbPath = 'test_procedural_savepoint_db';

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
    await db.close();
    final dir = Directory(dbPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('Savepoints and nested rollbacks', () async {
    // Start transaction
    await interpreter.executeScript('BEGIN TRANSACTION;');
    await interpreter.executeScript('CREATE TABLE test_sp(id INT, name TEXT);');
    await interpreter.executeScript("INSERT INTO test_sp VALUES (1, 'A');");

    // Savepoint SP1
    await interpreter.executeScript('SAVEPOINT SP1;');
    await interpreter.executeScript("INSERT INTO test_sp VALUES (2, 'B');");

    // Savepoint SP2
    await interpreter.executeScript('SAVEPOINT SP2;');
    await interpreter.executeScript("INSERT INTO test_sp VALUES (3, 'C');");

    // Rollback to SP2
    await interpreter.executeScript('ROLLBACK TO SAVEPOINT SP2;');
    var res = await interpreter.executeScript('SELECT * FROM test_sp;');
    expect(res.rows.length, 2); // 1 and 2 should exist

    // Rollback to SP1
    await interpreter.executeScript('ROLLBACK TO SAVEPOINT SP1;');
    res = await interpreter.executeScript('SELECT * FROM test_sp;');
    expect(res.rows.length, 1); // Only 1 should exist

    // Release savepoint
    await interpreter.executeScript('RELEASE SAVEPOINT SP1;');
    
    // Commit transaction
    await interpreter.executeScript('COMMIT TRANSACTION;');

    res = await interpreter.executeScript('SELECT * FROM test_sp;');
    expect(res.rows.length, 1);
  });

  test('PL/SQL Exception Handling and Auto-Savepoints', () async {
    // 1. Setup table
    await interpreter.executeScript('CREATE TABLE test_exc(id INT PRIMARY KEY, name TEXT);');

    // 2. Execute block with exception
    final script = '''
DECLARE
  v_count INT := 10;
BEGIN
  BEGIN TRANSACTION;
  INSERT INTO test_exc VALUES (1, 'First');
  
  -- Nested block that will fail
  DECLARE
    v_val INT := 1;
  BEGIN
    INSERT INTO test_exc VALUES (2, 'Second');
    -- Unique key violation to raise exception
    INSERT INTO test_exc VALUES (1, 'Duplicate'); 
  EXCEPTION
    WHEN OTHERS THEN
      v_count := 20;
      DBMS_OUTPUT.PUT_LINE('Caught error');
  END;

  COMMIT TRANSACTION;
END;
''';
    final res = await interpreter.executeScript(script);
    expect(res.message.contains('Error'), false); // Exception handled successfully

    // Verify duplicate insert inside nested block was rolled back, but first insert remains
    final selectRes = await interpreter.executeScript('SELECT * FROM test_exc;');
    expect(selectRes.rows.length, 1); 
    expect(selectRes.rows.first[0].value, 1);

    // Verify DBMS OUTPUT was printed
    expect(res.dbmsOutputLog.contains('Caught error'), true);
  });

  test('Cursors execution flow', () async {
    await interpreter.executeScript('CREATE TABLE test_cursor(id INT, val INT);');
    await interpreter.executeScript('INSERT INTO test_cursor VALUES (1, 100);');
    await interpreter.executeScript('INSERT INTO test_cursor VALUES (2, 200);');

    final script = '''
DECLARE
  c1 CURSOR FOR SELECT id, val FROM test_cursor;
  v_id INT;
  v_val INT;
  v_sum INT := 0;
BEGIN
  OPEN c1;
  
  FETCH c1 INTO v_id, v_val;
  WHILE c1%found LOOP
    v_sum := v_sum + v_val;
    FETCH c1 INTO v_id, v_val;
  END LOOP;
  
  CLOSE c1;
  DBMS_OUTPUT.PUT_LINE('Sum = ' || v_sum);
END;
''';
    final res = await interpreter.executeScript(script);
    expect(res.message.contains('Error'), false);
    expect(res.dbmsOutputLog.contains('Sum = 300'), true);
  });

  test('Triggers verification', () async {
    // Create tables
    await interpreter.executeScript('CREATE TABLE items(id INT PRIMARY KEY, price INT, status TEXT);');
    await interpreter.executeScript('CREATE TABLE audit_log(event_name TEXT, item_id INT);');

    // BEFORE INSERT trigger to modify status
    await interpreter.executeScript('''
CREATE TRIGGER before_ins_items BEFORE INSERT ON items FOR EACH ROW
BEGIN
  new.status := 'PENDING';
END;
''');

    // AFTER INSERT trigger to write to audit log
    await interpreter.executeScript('''
CREATE TRIGGER after_ins_items AFTER INSERT ON items FOR EACH ROW
BEGIN
  INSERT INTO audit_log VALUES ('INSERT', new.id);
END;
''');

    // BEFORE UPDATE trigger to increment price
    await interpreter.executeScript('''
CREATE TRIGGER before_upd_items BEFORE UPDATE ON items FOR EACH ROW
BEGIN
  new.price := new.price + 10;
END;
''');

    // Test Insert triggers
    await interpreter.executeScript("INSERT INTO items VALUES (1, 100, 'ACTIVE');");
    
    // Status should be set to 'PENDING' by BEFORE INSERT trigger
    var res = await interpreter.executeScript('SELECT * FROM items WHERE id = 1;');
    expect(res.rows.first[2].toString(), 'PENDING');

    // Audit log should contain entry
    res = await interpreter.executeScript('SELECT * FROM audit_log;');
    expect(res.rows.length, 1);
    expect(res.rows.first[1].value, 1);

    // Test Update triggers
    await interpreter.executeScript('UPDATE items SET price = 200 WHERE id = 1;');
    res = await interpreter.executeScript('SELECT * FROM items WHERE id = 1;');
    // Price should be 210 (200 + 10 by BEFORE UPDATE trigger)
    expect(res.rows.first[1].value, 210);
  });

  test('Trigger constraint validation', () async {
    // Create tables with FOREIGN KEY constraint
    await interpreter.executeScript('CREATE TABLE categories(id INT PRIMARY KEY, name TEXT);');
    await interpreter.executeScript('CREATE TABLE products(id INT PRIMARY KEY, cat_id INT REFERENCES categories(id), name TEXT);');

    // BEFORE INSERT trigger on products to change cat_id
    await interpreter.executeScript('''
CREATE TRIGGER before_ins_products BEFORE INSERT ON products FOR EACH ROW
BEGIN
  new.cat_id := 10; -- change to non-existent cat_id to trigger constraint error
END;
''');

    // Verify it fails constraint validation after BEFORE trigger modified cat_id
    final insertRes = await interpreter.executeScript("INSERT INTO products VALUES (1, 1, 'Gadget');");
    expect(insertRes.message.contains('Foreign key constraint violation'), true);
  });
}
