import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  group('Multi-Process Concurrency & File Lock Escalation', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ultsql_concurrency_test_');
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('Exclusive writer blocks second exclusive writer with timeout', () async {
      final db1 = Database(tempDir.path, lockTimeout: const Duration(seconds: 1));
      await db1.init();

      final db2 = Database(
        tempDir.path,
        lockTimeout: const Duration(milliseconds: 200),
      );

      await expectLater(db2.init(), throwsA(isA<DatabaseLockException>()));

      await db1.close();

      // After db1 closes, db2 can acquire the lock
      final db3 = Database(tempDir.path, lockTimeout: const Duration(seconds: 1));
      await db3.init();
      await db3.close();
    });

    test('Concurrent shared read-only databases can co-exist', () async {
      // Create initial database and write table
      final writer = Database(tempDir.path);
      await writer.init();
      final interp = Interpreter(writer);
      await interp.executeScript(
        "CREATE TABLE config (k TEXT, v TEXT); INSERT INTO config VALUES ('theme', 'dark');",
      );
      await writer.close();

      // Open reader 1 in readOnly mode
      final reader1 = Database(tempDir.path, readOnly: true);
      await reader1.init();

      // Open reader 2 concurrently in readOnly mode
      final reader2 = Database(tempDir.path, readOnly: true);
      await reader2.init();

      // Both can query concurrently
      final r1Interp = Interpreter(reader1);
      final r2Interp = Interpreter(reader2);
      final res1 = await r1Interp.executeScript('SELECT * FROM config;');
      final res2 = await r2Interp.executeScript('SELECT * FROM config;');

      expect(res1.rows.length, 1);
      expect(res1.rows[0][0].toString(), 'theme');
      expect(res2.rows.length, 1);
      expect(res2.rows[0][0].toString(), 'theme');

      await reader1.close();
      await reader2.close();
    });
  });
}
