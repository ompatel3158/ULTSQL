import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  const testDbDir = 'test_multi_process_lock_db';

  setUp(() async {
    final dir = Directory(testDbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  tearDown(() async {
    final dir = Directory(testDbDir);
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    }
  });

  test('Multi-process file locking prevents concurrent database directory access', () async {
    final db1 = Database(testDbDir);
    await db1.init();

    final db2 = Database(testDbDir);
    expect(
      () => db2.init(),
      throwsA(isA<DatabaseLockException>().having(
        (e) => e.message,
        'message',
        contains('is locked by another process'),
      )),
    );

    await db1.close();

    // After db1 closes, db2 should now successfully acquire the lock
    await db2.init();
    await db2.close();
  });
}
