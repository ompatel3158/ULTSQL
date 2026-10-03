// Tests all code snippets showcased in the ULTSQL documentation website.
// Ensures that documentation snippets never drift from the actual engine implementation.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  late Directory tempDir;
  late Database db;
  late Interpreter it;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('docs_snippets_test_');
    db = Database(tempDir.path);
    await db.init();
    it = Interpreter(db);
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  test('Snippet 1: Quickstart Relational SQL', () async {
    // DDL
    final ddlRes = await it.executeScript('''
      CREATE TABLE users (
        id INT PRIMARY KEY,
        name TEXT,
        email TEXT,
        created_at TEXT
      );
    ''');
    expect(ddlRes.message.contains('created successfully'), isTrue);

    // INSERT
    final insRes = await it.executeScript('''
      INSERT INTO users VALUES (1, 'Alice Smith', 'alice@ultsql.io', '2026-10-01');
      INSERT INTO users VALUES (2, 'Bob Jones', 'bob@ultsql.io', '2026-10-02');
    ''');
    expect(insRes.rows.isEmpty, isTrue);

    // SELECT with filter
    final selRes = await it.executeScript("SELECT name, email FROM users WHERE id = 1;");
    expect(selRes.rows.length, 1);
    expect(selRes.rows[0][0].toString(), 'Alice Smith');
    expect(selRes.rows[0][1].toString(), 'alice@ultsql.io');
  });

  test('Snippet 2: Prepared Statements & Parameterized Binding', () async {
    await it.executeScript('CREATE TABLE metrics (id INT PRIMARY KEY, tag TEXT, val DOUBLE);');

    final stmt = db.prepare('INSERT INTO metrics VALUES (?, ?, ?);');
    stmt.executeSync([DbInt(101), DbText('cpu_load'), DbDouble(0.42)]);
    stmt.executeSync([DbInt(102), DbText('mem_free'), DbDouble(7.85)]);

    final queryStmt = db.prepare('SELECT val FROM metrics WHERE tag = ?;');
    final result = queryStmt.executeSync([DbText('cpu_load')]);
    expect(result.rows.length, 1);
    expect(double.parse(result.rows[0][0].toString()), closeTo(0.42, 0.001));
  });

  test('Snippet 3: Bottom-Up B+ Tree Indexing & EXPLAIN', () async {
    await it.executeScript('''
      CREATE TABLE products (sku INT PRIMARY KEY, category TEXT, price DOUBLE);
      INSERT INTO products VALUES (1, 'hardware', 19.99);
      INSERT INTO products VALUES (2, 'software', 49.99);
      INSERT INTO products VALUES (3, 'hardware', 89.99);
      CREATE INDEX idx_products_cat ON products(category);
    ''');

    final explainRes = await it.executeScript("EXPLAIN SELECT sku, price FROM products WHERE category = 'hardware';");
    expect(explainRes.toString().isNotEmpty, isTrue);

    final queryRes = await it.executeScript("SELECT sku, price FROM products WHERE category = 'hardware';");
    expect(queryRes.rows.length, 2);
  });

  test('Snippet 4: ACID Transactions & MVCC Rollback', () async {
    await it.executeScript('''
      CREATE TABLE accounts (id INT PRIMARY KEY, balance DOUBLE);
      INSERT INTO accounts VALUES (1, 1000.0);
    ''');

    // Rollback test
    await it.executeScript('''
      BEGIN;
      UPDATE accounts SET balance = balance - 500.0 WHERE id = 1;
      ROLLBACK;
    ''');
    var res = await it.executeScript('SELECT balance FROM accounts WHERE id = 1;');
    expect(double.parse(res.rows[0][0].toString()), 1000.0);

    // Commit test
    await it.executeScript('''
      BEGIN;
      UPDATE accounts SET balance = balance + 250.0 WHERE id = 1;
      COMMIT;
    ''');
    res = await it.executeScript('SELECT balance FROM accounts WHERE id = 1;');
    expect(double.parse(res.rows[0][0].toString()), 1250.0);
  });

  test('Snippet 5: Converged NoSQL Document Store (MongoDB API)', () async {
    final col = db.collection('customers');

    // insertOne
    final doc1 = await col.insertOne({
      'name': 'Sarah Connor',
      'email': 'sarah@resistance.org',
      'profile': {'score': 95000, 'tags': ['vip', 'verified']},
    });
    expect(doc1.id.isNotEmpty, isTrue);

    // insertMany
    await col.insertMany([
      {'name': 'John Connor', 'profile': {'score': 88000, 'tags': ['member']}},
      {'name': 'Kyle Reese', 'profile': {'score': 72000, 'tags': ['veteran']}},
    ]);

    // findOne
    final found = await col.findOne({'_id': doc1.id});
    expect(found?.getByPath('name'), 'Sarah Connor');

    // find with deep dotted path filter
    final vipList = await col.find({
      'profile.score': {r'$gte': 80000},
    }).toList();
    expect(vipList.length, 2);

    // atomic update ($set, $inc)
    final updateRes = await col.updateOne(
      filter: {'_id': doc1.id},
      update: {
        r'$set': {'status': 'active'},
        r'$inc': {'profile.score': 500},
      },
    );
    expect(updateRes.modifiedCount, 1);

    final updatedDoc = await col.findOne({'_id': doc1.id});
    expect(updatedDoc?.getByPath('status'), 'active');
    expect(updatedDoc?.getByPath('profile.score'), 95500);

    // delete
    final deletedCount = await col.deleteOne({'name': 'Kyle Reese'});
    expect(deletedCount, 1);
  });

  test('Snippet 6: Redis-Style Key-Value Engine', () async {
    // set with ttl
    await db.kv.set('auth:session:99', 'token_xyz123', ttl: const Duration(hours: 2));
    final token = await db.kv.get('auth:session:99');
    expect(token, 'token_xyz123');

    // mset & mget
    await db.kv.mset({
      'config:timeout': 30,
      'config:max_conns': 100,
    });
    final configs = await db.kv.mget(['config:timeout', 'config:max_conns']);
    expect(configs['config:timeout'], 30);
    expect(configs['config:max_conns'], 100);

    // atomic incr / decr
    final hits = await db.kv.incr('stats:page_views');
    expect(hits, 1);
    final hits5 = await db.kv.incr('stats:page_views', 5);
    expect(hits5, 6);
    final decr = await db.kv.decr('stats:page_views', 2);
    expect(decr, 4);

    // keys wildcard
    final keys = await db.kv.keys(pattern: 'config:*');
    expect(keys.contains('config:timeout'), isTrue);
  });

  test('Snippet 7: Cross-Model SQL <-> NoSQL Bridge', () async {
    final col = db.collection('devices');
    await col.insertOne({
      'serial': 'DEV-001',
      'firmware': 'v2.4.1',
      'telemetry': {'battery': 94, 'temp': 36.5},
    });

    final sqlRes = await it.executeScript('''
      SELECT 
        _id,
        doc->>'serial' AS dev_serial,
        (doc->'telemetry'->>'battery')::INT AS battery
      FROM collection('devices')
      WHERE (doc->'telemetry'->>'battery')::INT > 80;
    ''');
    expect(sqlRes.rows.length, 1);
    expect(sqlRes.rows[0][1].toString(), 'DEV-001');
    expect(sqlRes.rows[0][2].toString(), '94');
  });

  test('Snippet 8: AI Vector Search & RAG (HNSW Index)', () async {
    await it.executeScript('CREATE TABLE knowledge_base (id INT PRIMARY KEY, content TEXT, emb VECTOR);');
    
    // Insert vectors via SQL
    await it.executeScript("INSERT INTO knowledge_base VALUES (1, 'Paris is the capital of France', '[0.12, 0.88, 0.45]');");
    await it.executeScript("INSERT INTO knowledge_base VALUES (2, 'Berlin is the capital of Germany', '[0.15, 0.82, 0.40]');");
    await it.executeScript("INSERT INTO knowledge_base VALUES (3, 'Tokyo is the capital of Japan', '[-0.85, 0.12, -0.35]');");

    // Build HNSW index
    final indexRes = await it.executeScript('CREATE INDEX idx_kb_emb ON knowledge_base(emb) USING HNSW;');
    expect(indexRes.message.contains('created successfully'), isTrue);

    // Query nearest neighbors using vector_distance
    final searchRes = await it.executeScript('''
      SELECT id, content, vector_distance(emb, '[0.14, 0.85, 0.42]') AS dist
      FROM knowledge_base
      ORDER BY dist ASC
      LIMIT 2;
    ''');
    expect(searchRes.rows.length, 2);
    expect(searchRes.rows[0][0].toString(), '2'); // Berlin is closest to [0.14, 0.85, 0.42]
    expect(searchRes.rows[1][0].toString(), '1'); // Paris is second closest
  });
}
