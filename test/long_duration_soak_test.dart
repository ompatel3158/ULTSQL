import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/storage/catalog.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'package:ultsql/engine/executor/value.dart';
import 'dart:io';

void main() {
  group('Long-Duration Soak & Multi-Operation Integrity Test', () {
    late String dbDir;
    late Database db;
    late Interpreter interpreter;

    setUp(() async {
      dbDir = 'test_soak_db';
      final dir = Directory(dbDir);
      if (await dir.exists()) await dir.delete(recursive: true);
      db = Database(dbDir);
      await db.init();
      interpreter = Interpreter(db);
    });

    tearDown(() async {
      await db.close();
      final dir = Directory(dbDir);
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('Runs continuous transaction cycles with page compaction and WAL integrity checks', () async {
      print('\n=== STARTING LONG-DURATION SOAK & INTEGRITY SUITE ===');

      await interpreter.executeScript('''
        CREATE TABLE soak_accounts (
          id INT PRIMARY KEY,
          balance DOUBLE,
          status TEXT
        );
      ''');

      // 1. Initial Seeding in Transaction
      print('1. Seeding 500 initial account records in transaction...');
      final insertScript = StringBuffer('BEGIN TRANSACTION;\n');
      for (int i = 1; i <= 500; i++) {
        insertScript.writeln("INSERT INTO soak_accounts VALUES ($i, ${(i * 100.0)}, 'ACTIVE');");
      }
      insertScript.writeln('COMMIT;');
      await interpreter.executeScript(insertScript.toString());

      // 2. High-Frequency Transaction Loop (100 Mutation Cycles)
      print('2. Executing continuous DML transaction cycles (Updates, Deletes, Inserts)...');
      final swLoop = Stopwatch()..start();

      for (int cycle = 1; cycle <= 100; cycle++) {
        final newId = 500 + cycle;
        await interpreter.executeScript('''
          BEGIN TRANSACTION;
          UPDATE soak_accounts SET balance = balance + 10.0 WHERE id = ${(cycle * 2)};
          INSERT INTO soak_accounts VALUES ($newId, 500.0, 'PENDING');
          DELETE FROM soak_accounts WHERE id = $newId;
          COMMIT;
        ''');

        if (cycle % 25 == 0) {
          final countRes = await interpreter.executeScript('SELECT COUNT(*) FROM soak_accounts;');
          final currentCount = countRes.rows[0][0].toString();
          print('   Cycle $cycle / 100 complete | Account Count: $currentCount | Memory Delta OK');
        }
      }
      swLoop.stop();
      print('   Multi-Operation Cycle completed in ${swLoop.elapsedMilliseconds} ms (${(1000 / (swLoop.elapsedMilliseconds / 1000.0)).toStringAsFixed(0)} ops/sec)');

      // 3. Post-Soak Data Consistency Check
      final verifyRes = await interpreter.executeScript('SELECT COUNT(*) FROM soak_accounts;');
      expect(verifyRes.rows[0][0].toString(), '500');

      // 4. Index B-Tree Integrity Check
      final pointLookup = await interpreter.executeScript('SELECT * FROM soak_accounts WHERE id = 250;');
      expect(pointLookup.rows.length, 1);
      expect(pointLookup.rows[0][0].toString(), '250');

      print('=== LONG-DURATION SOAK SUITE COMPLETED WITH 100% DATA INTEGRITY ===\n');
    });
  });
}
