import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';

void main() {
  const dbDir = 'test_data_window_functions';

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

  test('ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...) Support', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    await interpreter.executeScript(
      'CREATE TABLE employees (name TEXT, department TEXT, salary INT);'
    );

    await interpreter.executeScript("INSERT INTO employees VALUES ('Alice', 'HR', 5000);");
    await interpreter.executeScript("INSERT INTO employees VALUES ('Bob', 'HR', 6000);");
    await interpreter.executeScript("INSERT INTO employees VALUES ('Charlie', 'Engineering', 7000);");
    await interpreter.executeScript("INSERT INTO employees VALUES ('David', 'Engineering', 9000);");
    await interpreter.executeScript("INSERT INTO employees VALUES ('Eve', 'Engineering', 8000);");

    final selectRes = await interpreter.executeScript(
      'SELECT name, department, salary, ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as rank FROM employees;'
    );

    expect(selectRes.rows.length, 5);

    final bob = selectRes.rows.firstWhere((r) => r[0].toString() == 'Bob');
    expect(bob[1].toString(), 'HR');
    expect(bob[2].toString(), '6000');
    expect(bob[3].toString(), '1');

    final alice = selectRes.rows.firstWhere((r) => r[0].toString() == 'Alice');
    expect(alice[1].toString(), 'HR');
    expect(alice[2].toString(), '5000');
    expect(alice[3].toString(), '2');

    final david = selectRes.rows.firstWhere((r) => r[0].toString() == 'David');
    expect(david[1].toString(), 'Engineering');
    expect(david[2].toString(), '9000');
    expect(david[3].toString(), '1');

    await db.close();
  });

  test('RANK() and DENSE_RANK() OVER (ORDER BY ...) Support', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    await interpreter.executeScript('CREATE TABLE scores (name TEXT, score INT);');
    await interpreter.executeScript("INSERT INTO scores VALUES ('A', 100);");
    await interpreter.executeScript("INSERT INTO scores VALUES ('B', 100);");
    await interpreter.executeScript("INSERT INTO scores VALUES ('C', 90);");
    await interpreter.executeScript("INSERT INTO scores VALUES ('D', 80);");

    final rankRes = await interpreter.executeScript(
      'SELECT name, score, RANK() OVER (ORDER BY score DESC) as r, DENSE_RANK() OVER (ORDER BY score DESC) as dr FROM scores;'
    );

    expect(rankRes.rows.length, 4);

    final itemA = rankRes.rows.firstWhere((r) => r[0].toString() == 'A');
    expect(itemA[2].toString(), '1'); // RANK
    expect(itemA[3].toString(), '1'); // DENSE_RANK

    final itemC = rankRes.rows.firstWhere((r) => r[0].toString() == 'C');
    expect(itemC[2].toString(), '3'); // RANK skips to 3
    expect(itemC[3].toString(), '2'); // DENSE_RANK goes to 2

    await db.close();
  });

  test('LAG() and LEAD() OVER (ORDER BY ...) Support', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    await interpreter.executeScript('CREATE TABLE timeline (year INT, val INT);');
    await interpreter.executeScript("INSERT INTO timeline VALUES (2020, 10);");
    await interpreter.executeScript("INSERT INTO timeline VALUES (2021, 20);");
    await interpreter.executeScript("INSERT INTO timeline VALUES (2022, 30);");

    final lagRes = await interpreter.executeScript(
      'SELECT year, val, LAG(val) OVER (ORDER BY year ASC) as prev_val, LEAD(val) OVER (ORDER BY year ASC) as next_val FROM timeline;'
    );

    expect(lagRes.rows.length, 3);
    final row2021 = lagRes.rows.firstWhere((r) => r[0].toString() == '2021');
    expect(row2021[2].toString(), '10'); // prev_val
    expect(row2021[3].toString(), '30'); // next_val

    await db.close();
  });
}
