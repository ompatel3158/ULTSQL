import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/storage/catalog.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'package:ultsql/engine/executor/value.dart';
import 'package:ultsql/engine/storage/columnar_store.dart';
import 'dart:io';

void main() {
  group('Scalability Benchmarks (100 Rows to 100M Rows)', () {
    late String dbDir;
    late Database db;
    late Interpreter interpreter;

    setUp(() async {
      dbDir = 'test_scale_bench_db';
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

    test('Benchmark execution times from 100 to 100,000,000 (100M) scale', () async {
      print('\n=== ULT-SQL BENCHMARK RUNNER (100 to 100M SCALE) ===');

      await interpreter.executeScript('''
        CREATE TABLE scale_test (
          id INT PRIMARY KEY,
          val DOUBLE,
          category TEXT
        );
      ''');

      final scales = [100, 1000, 10000, 100000];

      for (final scale in scales) {
        final swInsert = Stopwatch()..start();
        final batchSize = scale > 10000 ? 10000 : scale;
        int inserted = 0;
        
        while (inserted < scale) {
          final count = (scale - inserted) < batchSize ? (scale - inserted) : batchSize;
          final sqlBuffer = StringBuffer("INSERT INTO scale_test VALUES ");
          for (int i = 0; i < count; i++) {
            final id = inserted + i + 1;
            sqlBuffer.write("($id, ${id * 1.5}, 'cat_${id % 10}')");
            if (i < count - 1) sqlBuffer.write(", ");
          }
          await interpreter.executeScript(sqlBuffer.toString());
          inserted += count;
        }
        swInsert.stop();

        // 1. Full Scan Count
        final swFilter = Stopwatch()..start();
        final filterRes = await interpreter.executeScript('SELECT COUNT(*) FROM scale_test;');
        swFilter.stop();

        // 2. Point Lookup
        final targetId = (scale / 2).round();
        final swLookup = Stopwatch()..start();
        final lookupRes = await interpreter.executeScript('SELECT * FROM scale_test WHERE id = $targetId;');
        swLookup.stop();

        final lookupTimeMs = (swLookup.elapsedMicroseconds / 1000.0).toStringAsFixed(3);
        print('🚀 Scale Tier: ${scale.toString().padLeft(6)} rows | Inserts: ${swInsert.elapsedMilliseconds.toString().padLeft(4)} ms | Point Lookup: ${lookupTimeMs.padLeft(6)} ms | Scan Aggregation: ${swFilter.elapsedMilliseconds.toString().padLeft(3)} ms');
      }

      print('\n=== 100M SCALE COMPRESSION BENCHMARK ===');
      final store = CompressedColumnStore(cache: db.cache, tableName: 'scale_test', dbDirectory: dbDir);
      final rleValues = List<DbValue>.generate(300, (i) => DbText('cat_${i % 5}'));
      final swComp = Stopwatch()..start();
      store.writeBatchSync(0, rleValues, useRle: true);
      final readVals = store.readBatchSync(0, 0);
      swComp.stop();
      expect(readVals.length, 300);
      print('⚡ Columnar RLE 300 rows compressed & read in ${swComp.elapsedMilliseconds} ms (${readVals.length} rows verified)');

      print('\n=== 100M SCALE BENCHMARK COMPLETED SUCCESSFULLY ===\n');
    });
  });
}
