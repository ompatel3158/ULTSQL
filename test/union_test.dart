import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void main() {
  const dbDir = 'test_data_union';

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

  test('UNION and UNION ALL set operations', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // Create tables and insert data
    await interpreter.executeScript('CREATE TABLE t1 (id INT, name TEXT);');
    await interpreter.executeScript('CREATE TABLE t2 (id INT, name TEXT);');

    await interpreter.executeScript("INSERT INTO t1 VALUES (1, 'Alice');");
    await interpreter.executeScript("INSERT INTO t1 VALUES (2, 'Bob');");
    await interpreter.executeScript("INSERT INTO t1 VALUES (2, 'Bob');"); // Duplicate in t1

    await interpreter.executeScript("INSERT INTO t2 VALUES (2, 'Bob');"); // Duplicate across t1 and t2
    await interpreter.executeScript("INSERT INTO t2 VALUES (3, 'Charlie');");

    // 1. Verify UNION (eliminates duplicates within and across tables)
    {
      final res = await interpreter.executeScript(
        'SELECT id, name FROM t1 UNION SELECT id, name FROM t2 ORDER BY id ASC;'
      );
      expect(res.rows.length, 3);
      expect(res.columns, ['id', 'name']);
      expect(res.rows[0][0].toString(), '1');
      expect(res.rows[0][1].toString(), 'Alice');
      expect(res.rows[1][0].toString(), '2');
      expect(res.rows[1][1].toString(), 'Bob');
      expect(res.rows[2][0].toString(), '3');
      expect(res.rows[2][1].toString(), 'Charlie');
    }

    // 2. Verify UNION ALL (retains all duplicates)
    {
      final res = await interpreter.executeScript(
        'SELECT id, name FROM t1 UNION ALL SELECT id, name FROM t2 ORDER BY id ASC;'
      );
      // t1 has: (1, Alice), (2, Bob), (2, Bob) -> 3 rows
      // t2 has: (2, Bob), (3, Charlie) -> 2 rows
      // Total 5 rows
      expect(res.rows.length, 5);
      expect(res.columns, ['id', 'name']);
      
      // Count occurrences
      int countAlice = 0;
      int countBob = 0;
      int countCharlie = 0;
      for (final row in res.rows) {
        final id = row[0].toString();
        final name = row[1].toString();
        if (id == '1' && name == 'Alice') countAlice++;
        if (id == '2' && name == 'Bob') countBob++;
        if (id == '3' && name == 'Charlie') countCharlie++;
      }
      expect(countAlice, 1);
      expect(countBob, 3);
      expect(countCharlie, 1);
    }

    // 3. Verify mixed UNION and UNION ALL
    // (t1 UNION t2) UNION ALL t1
    // t1 UNION t2 is distinct: (1, Alice), (2, Bob), (3, Charlie)
    // UNION ALL t1 adds (1, Alice), (2, Bob), (2, Bob)
    // Total should be 3 + 3 = 6 rows
    {
      final res = await interpreter.executeScript(
        'SELECT id, name FROM t1 UNION SELECT id, name FROM t2 UNION ALL SELECT id, name FROM t1;'
      );
      expect(res.rows.length, 6);
    }

    // 4. Verify mixed UNION ALL and UNION
    // (t1 UNION ALL t2) UNION t1
    // The final UNION makes the entire query distinct, so it should be just the 3 distinct rows
    {
      final res = await interpreter.executeScript(
        'SELECT id, name FROM t1 UNION ALL SELECT id, name FROM t2 UNION SELECT id, name FROM t1;'
      );
      expect(res.rows.length, 3);
    }

    await db.close();
  });
}
