import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/storage/parquet_engine.dart';

void main() {
  group('v1.0.27 Release Features Comprehensive Test Suite', () {
    // -------------------------------------------------------------
    // FEATURE 1: SIMD Hardware-Accelerated Vector Distance
    // -------------------------------------------------------------
    test('1. SIMD Float32x4 Vector Acceleration: Euclidean, Cosine, and Dot Product', () {
      // Test aligned (multiples of 4) and non-aligned vectors (with remainder lanes)
      final v1 = DbVector([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]);
      final v2 = DbVector([7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0]);

      // Dot product: 1*7 + 2*6 + 3*5 + 4*4 + 5*3 + 6*2 + 7*1 = 7 + 12 + 15 + 16 + 15 + 12 + 7 = 84.0
      expect(v1.dotProductTo(v2), closeTo(84.0, 1e-5));

      // L2 Euclidean distance: sqrt((1-7)^2 + (2-6)^2 + (3-5)^2 + 0 + (5-3)^2 + (6-2)^2 + (7-1)^2)
      // = sqrt(36 + 16 + 4 + 0 + 4 + 16 + 36) = sqrt(112) = 10.5830052
      expect(v1.distanceTo(v2), closeTo(10.5830052, 1e-4));

      // Cosine distance
      expect(v1.cosineDistanceTo(v1), closeTo(0.0, 1e-5));
      final cosDist = v1.cosineDistanceTo(v2);
      expect(cosDist, greaterThan(0.0));
      expect(cosDist, lessThanOrEqualTo(1.0));

      // 64-dimensional vectors (typical embedding size)
      final dim64A = DbVector(List.generate(64, (i) => (i + 1) * 0.1));
      final dim64B = DbVector(List.generate(64, (i) => (64 - i) * 0.1));
      expect(dim64A.distanceTo(dim64B), greaterThan(0.0));
      expect(dim64A.dotProductTo(dim64B), greaterThan(0.0));
      expect(dim64A.cosineDistanceTo(dim64A), closeTo(0.0, 1e-5));
    });

    // -------------------------------------------------------------
    // FEATURE 2: Turbo Bulk Ingest Mode
    // -------------------------------------------------------------
    test('2. Turbo Bulk Ingest Mode: Zero-Allocation Ingestion & Persistence', () async {
      final tempDir = Directory.systemTemp.createTempSync('ultsql_turbo_test_');
      try {
        final dbPath = '${tempDir.path}/turbo.db';
        var engine = await UltSqlEngine.openFile(dbPath);
        await engine.query('CREATE TABLE t_turbo (id INT PRIMARY KEY, name TEXT, age INT, score DOUBLE, active BOOLEAN);');

        const rowCount = 20000;
        final rawRows = List.generate(
          rowCount,
          (i) => [i, 'TurboUser_$i', 20 + (i % 50), i * 1.25, i % 2 == 0],
        );

        final sw = Stopwatch()..start();
        final res = engine.turboInsertBatchSync('t_turbo', rawRows);
        sw.stop();

        expect(res.message, contains('$rowCount rows inserted'));
        print('⚡ Turbo Bulk Ingested $rowCount rows in ${sw.elapsedMilliseconds} ms (${(rowCount / (sw.elapsedMilliseconds / 1000)).toStringAsFixed(0)} rows/s)');

        // Verify count and point lookups
        final countRes = await engine.query('SELECT COUNT(*) FROM t_turbo;');
        expect(countRes.rows.first.first.value, rowCount);

        final lookup = await engine.query('SELECT * FROM t_turbo WHERE id = 12345;');
        expect(lookup.rows.length, 1);
        final map = lookup.toList().first;
        expect(map['name'], 'TurboUser_12345');
        expect(map['score'], 12345 * 1.25);

        // Close and re-open to guarantee slotted-page durability
        await engine.close();
        engine = await UltSqlEngine.openFile(dbPath);

        final reopenCount = await engine.query('SELECT COUNT(*) FROM t_turbo;');
        expect(reopenCount.rows.first.first.value, rowCount);

        final reopenLookup = await engine.query('SELECT name FROM t_turbo WHERE id = 9999;');
        expect(reopenLookup.rows.first.first.value, 'TurboUser_9999');

        await engine.close();
      } finally {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      }
    });

    // -------------------------------------------------------------
    // FEATURE 3: B+Tree Index Acceleration for NoSQL JSON
    // -------------------------------------------------------------
    test('3. B+Tree Index Acceleration for NoSQL Document Collections', () async {
      final engine = await UltSqlEngine.openMemory();
      final users = engine.collection('users');

      // Insert documents
      final docs = List.generate(1000, (i) => {
        'username': 'user_$i',
        'email': 'user_$i@company.com',
        'profile': {'tier': i % 3 == 0 ? 'pro' : 'free', 'score': i * 10},
      });
      await users.insertMany(docs);

      // Create secondary index on nested path
      await users.createIndex('email');
      await users.createIndex('profile.score');

      expect(users.getIndexes(), contains('email'));
      expect(users.getIndexes(), contains('profile.score'));

      // Direct indexed seek on email
      final findByEmail = users.find({'email': 'user_42@company.com'}).toListSync();
      expect(findByEmail.length, 1);
      expect(findByEmail.first.getByPath('username'), 'user_42');

      // Direct indexed seek on nested path
      final findByScore = users.find({'profile.score': 770}).toListSync();
      expect(findByScore.length, 1);
      expect(findByScore.first.getByPath('username'), 'user_77');

      // Subsequent insertion updates index
      await users.insertOne({
        'username': 'vip_user',
        'email': 'vip@company.com',
        'profile': {'tier': 'vip', 'score': 99999},
      });

      final vipLookup = users.find({'email': 'vip@company.com'}).toListSync();
      expect(vipLookup.length, 1);
      expect(vipLookup.first.getByPath('username'), 'vip_user');

      await engine.close();
    });

    // -------------------------------------------------------------
    // FEATURE 4: Zero-Copy Streaming CSV & Parquet Importers
    // -------------------------------------------------------------
    test('4. Streaming CSV & Parquet Importers via Dart API and SQL COPY FROM', () async {
      final tempDir = Directory.systemTemp.createTempSync('ultsql_stream_test_');
      try {
        final engine = await UltSqlEngine.openMemory();

        // 1. Generate CSV file
        final csvPath = '${tempDir.path}/data.csv';
        final csvFile = File(csvPath);
        final sink = csvFile.openWrite();
        sink.writeln('id,name,amount,active');
        for (int i = 1; i <= 5000; i++) {
          sink.writeln('$i,"Customer $i",${i * 10.5},${i % 2 == 0}');
        }
        await sink.close();

        // 2. Import CSV via Dart Engine API
        final importedCsvCount = await engine.importCsv(csvPath, 'customers');
        expect(importedCsvCount, 5000);

        final csvQuery = await engine.query('SELECT COUNT(*) FROM customers;');
        expect(csvQuery.rows.first.first.value, 5000);

        final pointCsv = await engine.query('SELECT * FROM customers WHERE id = 2500;');
        expect(pointCsv.rows.length, 1);
        expect(pointCsv.toList().first['name'], 'Customer 2500');

        // 3. Import CSV via SQL COPY FROM statement
        final copyRes = await engine.query("COPY copy_cust FROM '$csvPath' WITH (FORMAT CSV, HEADER);");
        expect(copyRes.message, contains('5000 rows successfully imported'));

        final copyCount = await engine.query('SELECT COUNT(*) FROM copy_cust;');
        expect(copyCount.rows.first.first.value, 5000);

        // 4. Parquet Export & Import
        final schema = engine.db.catalog.getTableSchema('customers')!;
        final rowsToExport = (await engine.query('SELECT * FROM customers;')).rows;
        final parquetBytes = ParquetEngine.exportToParquet(schema, rowsToExport);

        final parquetPath = '${tempDir.path}/data.parquet';
        await File(parquetPath).writeAsBytes(parquetBytes);

        final importedParquetCount = await engine.importParquet(parquetPath, 'parquet_cust');
        expect(importedParquetCount, 5000);

        final parquetCount = await engine.query('SELECT COUNT(*) FROM parquet_cust;');
        expect(parquetCount.rows.first.first.value, 5000);

        // 5. Parquet via SQL COPY FROM statement
        final copyParquetRes = await engine.query("COPY copy_pq FROM '$parquetPath' WITH (FORMAT PARQUET);");
        expect(copyParquetRes.message, contains('5000 rows successfully imported'));

        final copyPqCount = await engine.query('SELECT COUNT(*) FROM copy_pq;');
        expect(copyPqCount.rows.first.first.value, 5000);

        await engine.close();
      } finally {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      }
    });
  });
}
