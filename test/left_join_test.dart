import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';

void main() {
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

  test('LEFT JOIN with HashJoinNode (no index)', () async {
    const dbDir = 'test_data_left_join_1';
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    try {
      // Create tables
      await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, dept_id INT);');
      await interpreter.executeScript('CREATE TABLE depts (id INT, name TEXT);');

      // Insert data
      await interpreter.executeScript('INSERT INTO depts VALUES (1, \'Engineering\');');
      await interpreter.executeScript('INSERT INTO depts VALUES (2, \'Sales\');');

      await interpreter.executeScript('INSERT INTO users VALUES (1, \'Alice\', 1);');
      await interpreter.executeScript('INSERT INTO users VALUES (2, \'Bob\', 3);'); // dept 3 doesn't exist
      await interpreter.executeScript('INSERT INTO users VALUES (3, \'Charlie\', 2);');
      await interpreter.executeScript('INSERT INTO users VALUES (4, \'David\', 99);'); // dept 99 doesn't exist

      // Run LEFT JOIN query
      final res = await interpreter.executeScript(
        'SELECT users.name, depts.name FROM users LEFT JOIN depts ON users.dept_id = depts.id ORDER BY users.id;'
      );

      expect(res.rows.length, 4);
      expect(res.columns, contains('users.name'));
      expect(res.columns, contains('depts.name'));

      // Alice matches Engineering (id: 1)
      expect(res.rows[0][0].toString(), 'Alice');
      expect(res.rows[0][1].toString(), 'Engineering');

      // Bob has dept_id 3 (no match)
      expect(res.rows[1][0].toString(), 'Bob');
      expect(res.rows[1][1], isA<DbNull>());

      // Charlie matches Sales (id: 2)
      expect(res.rows[2][0].toString(), 'Charlie');
      expect(res.rows[2][1].toString(), 'Sales');

      // David has dept_id 99 (no match)
      expect(res.rows[3][0].toString(), 'David');
      expect(res.rows[3][1], isA<DbNull>());
    } finally {
      await db.close();
      await deleteDir(dbDir);
    }
  });

  test('LEFT OUTER JOIN with HashJoinNode (no index)', () async {
    const dbDir = 'test_data_left_join_2';
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    try {
      // Create tables
      await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, dept_id INT);');
      await interpreter.executeScript('CREATE TABLE depts (id INT, name TEXT);');

      // Insert data
      await interpreter.executeScript('INSERT INTO depts VALUES (1, \'Engineering\');');
      await interpreter.executeScript('INSERT INTO users VALUES (1, \'Alice\', 1);');
      await interpreter.executeScript('INSERT INTO users VALUES (2, \'Bob\', 2);'); // no match

      // Run LEFT OUTER JOIN query
      final res = await interpreter.executeScript(
        'SELECT users.name, depts.name FROM users LEFT OUTER JOIN depts ON users.dept_id = depts.id ORDER BY users.id;'
      );

      expect(res.rows.length, 2);
      // Alice
      expect(res.rows[0][0].toString(), 'Alice');
      expect(res.rows[0][1].toString(), 'Engineering');
      // Bob
      expect(res.rows[1][0].toString(), 'Bob');
      expect(res.rows[1][1], isA<DbNull>());
    } finally {
      await db.close();
      await deleteDir(dbDir);
    }
  });

  test('LEFT JOIN with IndexJoinNode (index on depts.id)', () async {
    const dbDir = 'test_data_left_join_3';
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    try {
      // Create tables
      await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, dept_id INT);');
      await interpreter.executeScript('CREATE TABLE depts (id INT, name TEXT);');

      // Insert data
      await interpreter.executeScript('INSERT INTO depts VALUES (1, \'Engineering\');');
      await interpreter.executeScript('INSERT INTO depts VALUES (2, \'Sales\');');

      await interpreter.executeScript('INSERT INTO users VALUES (1, \'Alice\', 1);');
      await interpreter.executeScript('INSERT INTO users VALUES (2, \'Bob\', 3);'); // no match
      await interpreter.executeScript('INSERT INTO users VALUES (3, \'Charlie\', 2);');
      await interpreter.executeScript('INSERT INTO users VALUES (4, \'David\', 99);'); // no match

      // Create index on depts.id to trigger IndexJoinNode
      await interpreter.executeScript('CREATE INDEX idx_depts_id ON depts (id);');

      // Run LEFT JOIN query
      final res = await interpreter.executeScript(
        'SELECT users.name, depts.name FROM users LEFT JOIN depts ON users.dept_id = depts.id ORDER BY users.id;'
      );

      expect(res.rows.length, 4);

      // Alice matches Engineering (id: 1)
      expect(res.rows[0][0].toString(), 'Alice');
      expect(res.rows[0][1].toString(), 'Engineering');

      // Bob has dept_id 3 (no match)
      expect(res.rows[1][0].toString(), 'Bob');
      expect(res.rows[1][1], isA<DbNull>());

      // Charlie matches Sales (id: 2)
      expect(res.rows[2][0].toString(), 'Charlie');
      expect(res.rows[2][1].toString(), 'Sales');

      // David has dept_id 99 (no match)
      expect(res.rows[3][0].toString(), 'David');
      expect(res.rows[3][1], isA<DbNull>());
    } finally {
      await db.close();
      await deleteDir(dbDir);
    }
  });

  test('LEFT OUTER JOIN with IndexJoinNode (index on depts.id)', () async {
    const dbDir = 'test_data_left_join_4';
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    try {
      // Create tables
      await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, dept_id INT);');
      await interpreter.executeScript('CREATE TABLE depts (id INT, name TEXT);');

      // Insert data
      await interpreter.executeScript('INSERT INTO depts VALUES (1, \'Engineering\');');
      await interpreter.executeScript('INSERT INTO users VALUES (1, \'Alice\', 1);');
      await interpreter.executeScript('INSERT INTO users VALUES (2, \'Bob\', 2);'); // no match

      // Create index on depts.id to trigger IndexJoinNode
      await interpreter.executeScript('CREATE INDEX idx_depts_id ON depts (id);');

      // Run LEFT OUTER JOIN query
      final res = await interpreter.executeScript(
        'SELECT users.name, depts.name FROM users LEFT OUTER JOIN depts ON users.dept_id = depts.id ORDER BY users.id;'
      );

      expect(res.rows.length, 2);
      // Alice
      expect(res.rows[0][0].toString(), 'Alice');
      expect(res.rows[0][1].toString(), 'Engineering');
      // Bob
      expect(res.rows[1][0].toString(), 'Bob');
      expect(res.rows[1][1], isA<DbNull>());
    } finally {
      await db.close();
      await deleteDir(dbDir);
    }
  });
}
