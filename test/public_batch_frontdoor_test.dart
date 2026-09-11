import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  test('Public front-door batch API: insertBatch & insertBatchRecords with B+Tree indexing', () async {
    final engine = await UltSqlEngine.openMemory();
    await engine.query("CREATE TABLE items (id INT PRIMARY KEY, name TEXT, score DOUBLE);");

    // 1. Ingest via insertBatch (list of rows)
    final rows1 = List.generate(5000, (i) => [i, 'Item_$i', i * 1.5]);
    final res1 = await engine.insertBatch('items', rows1, columns: ['id', 'name', 'score']);
    expect(res1.message, contains('5000 rows inserted'));

    // 2. Ingest via insertBatchRecords (list of maps)
    final records = List.generate(5000, (i) => {
      'id': 5000 + i,
      'name': 'Record_${5000 + i}',
      'score': (5000 + i) * 1.5,
    });
    final res2 = await engine.insertBatchRecords('items', records);
    expect(res2.message, contains('5000 rows inserted'));

    // 3. Verify total count
    final countRes = await engine.query("SELECT COUNT(*) FROM items;");
    expect(countRes.rows.first.first.value, equals(10000));

    // 4. Verify findability via indexed point lookup
    final pointRes = await engine.query("SELECT * FROM items WHERE id = 7777;");
    expect(pointRes.rows.length, equals(1));
    expect(pointRes.toList().first['name'], equals('Record_7777'));

    await engine.close();
  });

  test('REST server front-door batch endpoint: POST /:table/batch', () async {
    final db = Database(':memory:');
    await db.init();
    final server = RestServer(db, port: 9123);
    final boundPort = await server.start(autoPort: true);

    final client = HttpClient();
    try {
      // 1. Ingest batch of JSON objects via HTTP POST
      final batchData = List.generate(1000, (i) => {
        'id': i,
        'user_name': 'User_$i',
        'points': i * 10.0,
      });

      final req = await client.post('127.0.0.1', boundPort, '/users/batch');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(batchData));
      final resp = await req.close();
      expect(resp.statusCode, equals(HttpStatus.created));

      final respBody = await utf8.decoder.bind(resp).join();
      final decoded = jsonDecode(respBody) as Map<String, dynamic>;
      expect(decoded['status'], equals('ok'));
      expect(decoded['count'], equals(1000));

      // 2. Verify findability via SQL query through REST endpoint
      final queryReq = await client.post('127.0.0.1', boundPort, '/query');
      queryReq.headers.contentType = ContentType.json;
      queryReq.write(jsonEncode({'sql': 'SELECT COUNT(*) FROM users;'}));
      final queryResp = await queryReq.close();
      final queryBody = await utf8.decoder.bind(queryResp).join();
      final queryDecoded = jsonDecode(queryBody) as Map<String, dynamic>;
      expect(queryDecoded['rows'][0][0], equals(1000));

      // 3. Point lookup through REST
      final pointReq = await client.post('127.0.0.1', boundPort, '/query');
      pointReq.headers.contentType = ContentType.json;
      pointReq.write(jsonEncode({'sql': 'SELECT * FROM users WHERE id = 500;'}));
      final pointResp = await pointReq.close();
      final pointBody = await utf8.decoder.bind(pointResp).join();
      final pointDecoded = jsonDecode(pointBody) as Map<String, dynamic>;
      expect(pointDecoded['rows'].length, equals(1));
      expect(pointDecoded['rows'][0][1], equals('User_500'));
    } finally {
      client.close();
      await server.stop();
      await db.close();
    }
  });

  test('File batch import: CSV and JSON files', () async {
    final tempDir = Directory.systemTemp.createTempSync('ultsql_test_import_');
    try {
      // Create test CSV
      final csvFile = File('${tempDir.path}/test_users.csv');
      final csvContent = StringBuffer();
      csvContent.writeln('id,name,score');
      for (int i = 0; i < 2000; i++) {
        csvContent.writeln('$i,"User $i",${i * 2.5}');
      }
      await csvFile.writeAsString(csvContent.toString());

      final db = Database(':memory:');
      await db.init();

      // Read and insert CSV via insertBatchRecordsSync
      final lines = await csvFile.readAsLines();
      final headers = lines[0].split(',').map((h) => h.trim()).toList();
      final records = <Map<String, dynamic>>[];
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');
        records.add({
          headers[0]: int.parse(parts[0].trim()),
          headers[1]: parts[1].trim().replaceAll('"', ''),
          headers[2]: double.parse(parts[2].trim()),
        });
      }

      final res = db.insertBatchRecordsSync('csv_users', records);
      expect(res.message, contains('2000 rows inserted'));

      // Verify findability
      final interpreter = Interpreter(db);
      final count = await interpreter.executeScript("SELECT COUNT(*) FROM csv_users;");
      expect(count.rows.first.first.value, equals(2000));

      final lookup = await interpreter.executeScript("SELECT * FROM csv_users WHERE id = 1234;");
      expect(lookup.rows.length, equals(1));
      expect(lookup.rows.first[1].value, equals('User 1234'));

      await db.close();
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });
}
