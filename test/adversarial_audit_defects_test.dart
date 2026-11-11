import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/storage/hnsw_index.dart';

void main() {
  group('Adversarial Chaos & Architectural Defect Regression Suite', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ultsql_defect_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    // ========================================================================
    // PILLAR 1: Storage, WAL & Encryption Defects
    // ========================================================================
    group('Storage, WAL & Encryption Defects', () {
      test('Defect 1: Audit logger redacts string literals to prevent sensitive canary leaks', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          await engine.query("CREATE TABLE users (username TEXT, secret_token TEXT);");
          await engine.query("INSERT INTO users VALUES ('alice', 'super_secret_canary_98765');");
          await engine.db.close();

          final auditFile = File('${tempDir.path}/audit.log');
          expect(auditFile.existsSync(), isTrue);
          final auditContent = await auditFile.readAsString();
          expect(auditContent.contains('super_secret_canary_98765'), isFalse,
              reason: 'Cleartext query literal canary leaked into audit.log!');
          expect(auditContent.contains('***'), isTrue,
              reason: 'Audit logger must mask string literals with ***');
        } finally {
          try {
            await engine.db.close();
          } catch (_) {}
        }
      });

      test('Defect 2: Non-ASCII UTF-8 serialization prevents silent truncation and dropped rows', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          await engine.query("CREATE TABLE i18n_test (id INT, text_cyrillic TEXT, text_greek TEXT, text_emoji TEXT);");
          await engine.query(
            "INSERT INTO i18n_test VALUES (1, 'Привет, мир!', 'Γειά σου κόσμε', '🚀🔥🎉🐱');",
          );

          // Query immediately
          var res = await engine.query("SELECT * FROM i18n_test WHERE id = 1;");
          expect(res.rows.length, equals(1));
          expect(res.rows[0][1].toString(), equals('Привет, мир!'));
          expect(res.rows[0][2].toString(), equals('Γειά σου κόσμε'));
          expect(res.rows[0][3].toString(), equals('🚀🔥🎉🐱'));

          // Close and reopen to verify physical disk binary deserialization
          await engine.db.close();
          final engine2 = await UltSqlEngine.openFile(tempDir.path);
          try {
            res = await engine2.query("SELECT * FROM i18n_test WHERE id = 1;");
            expect(res.rows.length, equals(1));
            expect(res.rows[0][1].toString(), equals('Привет, мир!'));
            expect(res.rows[0][2].toString(), equals('Γειά σου κόσμε'));
            expect(res.rows[0][3].toString(), equals('🚀🔥🎉🐱'));
          } finally {
            await engine2.db.close();
          }
        } finally {
          try {
            await engine.db.close();
          } catch (_) {}
        }
      });

      test('Defect 10 & 11: WAL writes CRC32 checksums and survives torn frames without corrupting engine', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          await engine.query("CREATE TABLE wal_test (id INT, val TEXT);");
          await engine.query("INSERT INTO wal_test VALUES (1, 'persisted');");
          await engine.db.close();

          // Append torn/garbage bytes to wal.log
          final walFile = File('${tempDir.path}/wal.log');
          if (!walFile.existsSync()) {
            await walFile.create();
          }
          final sink = walFile.openWrite(mode: FileMode.append);
          sink.add(Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]));
          await sink.flush();
          await sink.close();

          // Engine reopen should not crash or throw unhandled exceptions
          final engine2 = await UltSqlEngine.openFile(tempDir.path);
          try {
            final res = await engine2.query("SELECT * FROM wal_test WHERE id = 1;");
            expect(res.rows.length, equals(1));
            expect(res.rows[0][1].toString(), equals('persisted'));
          } finally {
            await engine2.db.close();
          }
        } finally {
          try {
            await engine.db.close();
          } catch (_) {}
        }
      });

      test('Defect 16: Encrypted database encrypts catalog.db metadata', () async {
        const passphrase = 'MasterUltraSecretKeyPass2026!';
        final engine = await UltSqlEngine.openFile(tempDir.path, passphrase: passphrase);
        try {
          await engine.query("CREATE TABLE secret_table_metadata (id INT, confidential_col TEXT);");
          await engine.query("INSERT INTO secret_table_metadata VALUES (1, 'classified_vault');");
          await engine.db.close();

          final catalogFile = File('${tempDir.path}/catalog.db');
          expect(catalogFile.existsSync(), isTrue);
          final rawBytes = await catalogFile.readAsBytes();
          final rawText = utf8.decode(rawBytes, allowMalformed: true);
          expect(rawText.contains('secret_table_metadata'), isFalse,
              reason: 'catalog.db must be encrypted with AES-CTR when database passphrase is set');
          expect(rawText.contains('confidential_col'), isFalse,
              reason: 'catalog.db schema column names must be encrypted');

          // Reopening with correct passphrase must succeed and find table
          final engine2 = await UltSqlEngine.openFile(tempDir.path, passphrase: passphrase);
          try {
            final res = await engine2.query("SELECT * FROM secret_table_metadata;");
            expect(res.columns, contains('confidential_col'));
          } finally {
            await engine2.db.close();
          }
        } finally {
          try {
            await engine.db.close();
          } catch (_) {}
        }
      });
    });

    // ========================================================================
    // PILLAR 2: Parser & Syntax Defects
    // ========================================================================
    group('Parser & Syntax Defects', () {
      test('Defect 12: SQL-standard escaped quotes (\'O\'\'Reilly\') and backslash quotes (\'O\\\'Reilly\')', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          var res = await engine.query("SELECT 'O''Reilly' AS author;");
          expect(res.rows.length, equals(1));
          expect(res.rows[0][0].toString(), equals("O'Reilly"));

          res = await engine.query("SELECT '''' AS single_quote;");
          expect(res.rows.length, equals(1));
          expect(res.rows[0][0].toString(), equals("'"));

          res = await engine.query("SELECT 'O\\'Reilly' AS author2;");
          expect(res.rows.length, equals(1));
          expect(res.rows[0][0].toString(), equals("O'Reilly"));
        } finally {
          await engine.db.close();
        }
      });

      test('Defect 19: Block comments (/* ... */, multi-line, inline)', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          var res = await engine.query("/* Block comment at start */ SELECT 42 AS num;");
          expect(res.rows.first[0].value, equals(42));

          res = await engine.query("""
            /* Multi-line
               block comment
               test */
            SELECT 100 AS num;
          """);
          expect(res.rows.first[0].value, equals(100));

          res = await engine.query("SELECT 10 /* inline comment */ + 20 AS res;");
          expect(res.rows.first[0].value, equals(30));
        } finally {
          await engine.db.close();
        }
      });

      test('Defect 20: Scientific notation numbers (1e10, 1e-5, 2.5e3)', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          var res = await engine.query("SELECT 1e10 AS big_val;");
          expect((res.rows.first[0].value as num).toDouble(), equals(1e10));

          res = await engine.query("SELECT 1e-5 AS small_val;");
          expect((res.rows.first[0].value as num).toDouble(), closeTo(1e-5, 1e-9));

          res = await engine.query("SELECT 2.5e3 AS mixed_exp;");
          expect((res.rows.first[0].value as num).toDouble(), equals(2500.0));
        } finally {
          await engine.db.close();
        }
      });

      test('Defect 21: Recursive CTE parameter list mapping (cnt(n))', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          final res = await engine.query("""
            WITH RECURSIVE cnt(n) AS (
              SELECT 1
              UNION ALL
              SELECT n + 1 FROM cnt WHERE n < 5
            )
            SELECT n FROM cnt;
          """);
          expect(res.rows.length, equals(5));
          expect(res.rows.map((r) => r[0].value).toList(), equals([1, 2, 3, 4, 5]));
        } finally {
          await engine.db.close();
        }
      });

      test('Defect 22: Duplicate column names in CREATE TABLE rejected with FormatException', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          expect(
            () => engine.query("CREATE TABLE dup_cols (id INT, id TEXT);"),
            throwsA(isA<FormatException>()),
          );
        } finally {
          await engine.db.close();
        }
      });

      test('Defect 23: Oracle cursor declaration parses without eating cursor name', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          await engine.query("CREATE TABLE emp (id INT, sal INT);");
          await engine.query("INSERT INTO emp VALUES (1, 5000);");
          final res = await engine.query("""
            DECLARE
              CURSOR c_emp IS SELECT id, sal FROM emp;
              v_id INT;
              v_sal INT;
            BEGIN
              OPEN c_emp;
              FETCH c_emp INTO v_id, v_sal;
              CLOSE c_emp;
            END;
          """);
          expect(res, isNotNull);
        } finally {
          await engine.db.close();
        }
      });

      test('Defect 24: SQL type keywords allowed as column names', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          await engine.query("CREATE TABLE kw_cols (id INT, text TEXT, count INT);");
          await engine.query("INSERT INTO kw_cols VALUES (1, 'sample', 42);");
          final res = await engine.query("SELECT id, text, count FROM kw_cols;");
          expect(res.rows.length, equals(1));
          expect(res.rows[0][1].toString(), equals('sample'));
          expect(res.rows[0][2].value, equals(42));
        } finally {
          await engine.db.close();
        }
      });
    });

    // ========================================================================
    // PILLAR 3: Runtime Execution & Mathematics
    // ========================================================================
    group('Runtime Execution & Mathematics', () {
      test('Defect 3: Modulo by zero (10 % 0) returns DbNull instead of uncaught crash', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          var res = await engine.query("SELECT 10 % 0 AS mod_zero;");
          expect(res.rows.first[0].value, isNull);

          res = await engine.query("SELECT mod(10, 0) AS mod_func_zero;");
          expect(res.rows.first[0].value, isNull);
        } finally {
          await engine.db.close();
        }
      });
    });

    // ========================================================================
    // PILLAR 4: Multi-Model: NoSQL Document Store
    // ========================================================================
    group('NoSQL Document Store Defects', () {
      test('Defect 4: NoSQL TOAST retrieval via _fetchDocAtPointer preserves >1024 byte documents', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          final coll = engine.collection('large_docs');
          final largeString = 'A' * 4096;
          final doc = await coll.insertOne({
            'title': 'Huge Document',
            'payload': largeString,
          });

          // Point fetch by _id
          final foundDoc = await coll.findOne({'_id': doc.id});
          expect(foundDoc, isNotNull);
          expect(foundDoc!.getByPath('title'), equals('Huge Document'));
          expect(foundDoc.getByPath('payload'), equals(largeString));

          // Close and reopen database to verify disk TOAST restoration
          await engine.db.close();
          final engine2 = await UltSqlEngine.openFile(tempDir.path);
          try {
            final coll2 = engine2.collection('large_docs');
            final docReloaded = await coll2.findOne({'_id': doc.id});
            expect(docReloaded, isNotNull);
            expect(docReloaded!.getByPath('payload'), equals(largeString));
          } finally {
            await engine2.db.close();
          }
        } finally {
          try {
            await engine.db.close();
          } catch (_) {}
        }
      });

      test('Defect 5: Array navigation in NoSQL \$set updates element in-place without Map conversion', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          final coll = engine.collection('articles');
          final doc = await coll.insertOne({
            'title': 'Dart 3.12',
            'tags': ['programming', 'mobile', 'frontend'],
          });

          // Update tags[1] to 'flutter'
          await coll.updateOne(
            filter: {'_id': doc.id},
            update: {r'$set': {'tags.1': 'flutter'}},
          );

          final updated = await coll.findOne({'_id': doc.id});
          expect(updated, isNotNull);
          final tags = updated!.getByPath('tags');
          expect(tags, isA<List>());
          final tagList = tags as List;
          expect(tagList.length, equals(3));
          expect(tagList[0], equals('programming'));
          expect(tagList[1], equals('flutter'));
          expect(tagList[2], equals('frontend'));
        } finally {
          await engine.db.close();
        }
      });

      test('Defect 6: ReDoS query filter rejection rejects adversarial patterns safely', () async {
        final doc = Document(id: 'doc1', data: {'text': 'aaaaaaaaaaaaaaaaaaaaa!'});

        final filter1 = QueryFilter.compile({
          'text': {r'$regex': r'^(a+)+$'}
        });
        expect(filter1.matches(doc), isFalse);

        final filter2 = QueryFilter.compile({
          'text': {r'$regex': r'^(a|aa)+$'}
        });
        expect(filter2.matches(doc), isFalse);
      });
    });

    // ========================================================================
    // PILLAR 5: Multi-Model: Vector RAG & HNSW
    // ========================================================================
    group('Vector RAG & HNSW Defects', () {
      test('Defect 7: HNSW validates finite components against NaN / Infinity', () {
        final hnsw = HnswIndex(indexPath: ':memory:', autoSave: false);
        hnsw.initSync();

        expect(
          () => hnsw.insertSync(DbVector([1.0, double.nan, 3.0]), 0, 1),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => hnsw.insertSync(DbVector([1.0, double.infinity, 3.0]), 0, 2),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => hnsw.search(DbVector([double.nan, 2.0, 3.0]), 5),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Defect 8: Vector dimension mismatch throws ArgumentError instead of returning 0.0', () {
        final v3 = DbVector([1.0, 2.0, 3.0]);
        final v4 = DbVector([1.0, 2.0, 3.0, 4.0]);

        expect(() => v3.distanceTo(v4), throwsA(isA<ArgumentError>()));
        expect(() => v3.cosineDistanceTo(v4), throwsA(isA<ArgumentError>()));
        expect(() => v3.dotProductTo(v4), throwsA(isA<ArgumentError>()));
      });

      test('Defect 14: Cosine distance metric normalizes vectors to unit length', () {
        final hnsw = HnswIndex(indexPath: ':memory:', autoSave: false, metric: 'cosine');
        hnsw.initSync();
        hnsw.insertSync(DbVector([10.0, 0.0]), 0, 1); // Norm 10
        hnsw.insertSync(DbVector([0.0, 5.0]), 0, 2);  // Norm 5

        // Query along x axis: [1.0, 0.0]
        final results = hnsw.search(DbVector([1.0, 0.0]), 2);
        expect(results.first.id, equals(0));
        final dist = results.first.vector.cosineDistanceTo(DbVector([1.0, 0.0]).normalized());
        expect(dist, closeTo(0.0, 1e-4));
      });
    });

    // ========================================================================
    // PILLAR 6: Multi-Model: Redis-Style Key-Value Store
    // ========================================================================
    group('Redis-Style KV Store Defects', () {
      test('Defect 9: KV Store concurrent incr() preserves all updates without lost increments', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          final kv = engine.kv;
          await kv.set('counter', 0);

          // Launch 50 concurrent async increments
          final futures = <Future<int>>[];
          for (int i = 0; i < 50; i++) {
            futures.add(kv.incr('counter'));
          }
          await Future.wait(futures);

          final finalVal = await kv.get('counter');
          expect(finalVal, equals(50));
        } finally {
          await engine.db.close();
        }
      });

      test('Defect 13: KV JSON maps and lists stored without double string encoding', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          final kv = engine.kv;
          final complexMap = {'server': 'primary', 'ports': [80, 443], 'active': true};
          await kv.set('cluster_config', complexMap);

          final retrieved = await kv.get('cluster_config');
          expect(retrieved, isA<Map>());
          expect((retrieved as Map)['server'], equals('primary'));
          expect(retrieved['ports'], equals([80, 443]));
        } finally {
          await engine.db.close();
        }
      });

      test('Defect 15: KV negative or zero TTL expires key immediately', () async {
        final engine = await UltSqlEngine.openFile(tempDir.path);
        try {
          final kv = engine.kv;
          await kv.set('temp_key', 'will_die', ttl: const Duration(seconds: -1));

          final val = await kv.get('temp_key');
          expect(val, isNull);
        } finally {
          await engine.db.close();
        }
      });
    });
  });
}
