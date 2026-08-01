import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'package:ultsql/engine/executor/value.dart';

void main() {
  const dbDir = 'test_stored_procedures_dir';

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

  test('Stored Procedures and CALL execution', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // 1. Create table
    await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT);');

    // 2. Create Stored Procedure
    final createProcRes = await interpreter.executeScript('''
CREATE PROCEDURE add_user (user_id INT, user_name TEXT) AS
BEGIN
  INSERT INTO users VALUES (user_id, user_name);
END;
''');
    expect(createProcRes.message, contains("created successfully"));

    // 3. CALL Stored Procedure
    final callRes1 = await interpreter.executeScript('CALL add_user(42, \'Alice\');');
    expect(callRes1.message, contains("executed successfully"));

    // 4. Verify insertion
    final selectRes1 = await interpreter.executeScript('SELECT id, name FROM users;');
    expect(selectRes1.rows.length, 1);
    expect((selectRes1.rows[0][0] as DbInt).value, 42);
    expect((selectRes1.rows[0][1] as DbText).value, 'Alice');

    // 5. CALL Stored Procedure again
    final callRes2 = await interpreter.executeScript('CALL add_user(43, \'Bob\');');
    expect(callRes2.message, contains("executed successfully"));

    // 6. Verify second insertion
    final selectRes2 = await interpreter.executeScript('SELECT id, name FROM users ORDER BY id ASC;');
    expect(selectRes2.rows.length, 2);
    expect((selectRes2.rows[1][0] as DbInt).value, 43);
    expect((selectRes2.rows[1][1] as DbText).value, 'Bob');

    await db.close();
  });

  test('Custom Functions and SELECT dynamic invocation', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // 1. Create custom function
    final createFuncRes = await interpreter.executeScript('''
CREATE FUNCTION calculate_total (price DOUBLE, tax_rate DOUBLE) RETURNS DOUBLE AS
BEGIN
  RETURN price * (1.0 + tax_rate);
END;
''');
    expect(createFuncRes.message, contains("created successfully"));

    // 2. Create table and insert rows
    await interpreter.executeScript('CREATE TABLE items (name TEXT, price DOUBLE);');
    await interpreter.executeScript('INSERT INTO items VALUES (\'Laptop\', 1000.0);');
    await interpreter.executeScript('INSERT INTO items VALUES (\'Phone\', 500.0);');

    // 3. Query function directly with literal args using items table
    final literalRes = await interpreter.executeScript('SELECT calculate_total(100.0, 0.15) AS total FROM items LIMIT 1;');
    expect(literalRes.rows.length, 1);
    expect((literalRes.rows[0][0] as DbDouble).value, closeTo(115.0, 0.001));

    // 4. Query table utilizing custom function dynamically
    final tableRes = await interpreter.executeScript('SELECT name, calculate_total(price, 0.10) AS final_price FROM items ORDER BY price DESC;');
    expect(tableRes.rows.length, 2);
    
    expect((tableRes.rows[0][0] as DbText).value, 'Laptop');
    expect((tableRes.rows[0][1] as DbDouble).value, closeTo(1100.0, 0.001));

    expect((tableRes.rows[1][0] as DbText).value, 'Phone');
    expect((tableRes.rows[1][1] as DbDouble).value, closeTo(550.0, 0.001));

    await db.close();
  });

  test('Stored Procedures and Functions PL/SQL nested logic', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // Create a dummy table for SELECT function evaluations
    await interpreter.executeScript('CREATE TABLE dummy (id INT);');
    await interpreter.executeScript('INSERT INTO dummy VALUES (1);');

    // Create function that performs logic inside
    final createClampRes = await interpreter.executeScript('''
CREATE FUNCTION clamp_val (val INT, min_val INT, max_val INT) RETURNS INT AS
BEGIN
  IF val < min_val THEN
    RETURN min_val;
  END IF;
  IF val > max_val THEN
    RETURN max_val;
  END IF;
  RETURN val;
END;
''');
    expect(createClampRes.message, contains("created successfully"));

    final testMin = await interpreter.executeScript('SELECT clamp_val(5, 10, 20) AS res FROM dummy;');
    expect((testMin.rows[0][0] as DbInt).value, 10);

    final testMax = await interpreter.executeScript('SELECT clamp_val(25, 10, 20) AS res FROM dummy;');
    expect((testMax.rows[0][0] as DbInt).value, 20);

    final testMid = await interpreter.executeScript('SELECT clamp_val(15, 10, 20) AS res FROM dummy;');
    expect((testMid.rows[0][0] as DbInt).value, 15);

    // Create procedure that prints message
    await interpreter.executeScript('''
CREATE PROCEDURE log_message (msg TEXT) AS
BEGIN
  DBMS_OUTPUT.PUT_LINE('LOG: ' || msg);
END;
''');

    await interpreter.executeScript('CALL log_message(\'Stored procedure test logging\');');
    expect(interpreter.dbmsOutputLog.last, 'LOG: Stored procedure test logging');

    await db.close();
  });
}
