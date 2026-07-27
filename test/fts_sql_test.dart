import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';

void main() {
  const dbDir = 'test_data_fts_sql';

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

  test('Full-Text Search Indexing and MATCH() Query Routing', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    await interpreter.executeScript('CREATE TABLE articles (id INT, title TEXT, body TEXT);');
    await interpreter.executeScript('CREATE INDEX idx_articles_body ON articles(body) USING fts;');

    await interpreter.executeScript("INSERT INTO articles VALUES (1, 'Engine Overview', 'UltSQL is a high performance hybrid database engine.');");
    await interpreter.executeScript("INSERT INTO articles VALUES (2, 'Cooking Recipe', 'Baking delicious chocolate cake in an oven.');");
    await interpreter.executeScript("INSERT INTO articles VALUES (3, 'Vector Search', 'Hierarchical Small World graph index for vector embeddings.');");

    final explainRes = await interpreter.executeScript("EXPLAIN SELECT * FROM articles WHERE MATCH(body, 'database engine');");
    expect(explainRes.rows[0][0].toString(), contains('FtsScanNode'));

    final queryRes = await interpreter.executeScript("SELECT id, title FROM articles WHERE MATCH(body, 'database engine');");
    expect(queryRes.rows.length, 1);
    expect(queryRes.rows[0][0].toString(), '1');
    expect(queryRes.rows[0][1].toString(), 'Engine Overview');

    await db.close();
  });
}
