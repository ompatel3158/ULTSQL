import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';

void main() {
  const dbDir = 'test_data_recursive_cte';

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

  test('WITH RECURSIVE CTE Execution', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    final res = await interpreter.executeScript(
      'WITH RECURSIVE cnt(x) AS (SELECT 1 as x UNION ALL SELECT x + 1 FROM cnt WHERE x < 5) SELECT x FROM cnt;'
    );

    expect(res.rows.length, 5);
    expect(res.rows[0][0].toString(), '1');
    expect(res.rows[4][0].toString(), '5');

    await db.close();
  });
}
