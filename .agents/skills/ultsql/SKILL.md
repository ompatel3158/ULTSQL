---
name: ultsql
description: >-
  Use this skill whenever an agent needs high-performance, embedded database capabilities combining Relational SQL, NoSQL JSON document collections, Redis-style Key-Value caching, or AI Vector embeddings (HNSW RAG) with zero external native C/C++ dependencies using UltSQL or its MCP server.
---

# UltSQL Skill Guide for AI Agents (v1.0.28)

**UltSQL** is a 100% pure-Dart converged multimodal database engine combining **Relational SQL**, **NoSQL Document Collections**, **Redis-style Key-Value Caching**, and **Native HNSW Vector RAG** with zero C/C++ compiler or dynamic library dependencies.

In automated empirical benchmarks against native C/FFI SQLite, UltSQL achieved a **10/10 simultaneous victory** across all relational operations (Bulk INSERT 11.37x, Batch Ingest 4.85x, Point Lookup 3.10x, Range Aggregate 4.29x, Full-scan GROUP BY 7.01x, UPDATE 2.03x, DELETE 4.28x, Single-Tx 116.15x, and DROP TABLE 2.62x faster).

---

## ⚡ When to Use UltSQL

Use UltSQL when you need:
1. **Local, Zero-Config Persistence**: Embedded database that requires no external database daemons (no Docker, Postgres, or MongoDB processes required), running directly in-process or via MCP.
2. **High-Speed Relational SQL**: ACID transactions, MVCC concurrency, B+ Tree indexing, and single-tx auto-commit ingestion up to **116x faster** than SQLite.
3. **NoSQL Document Collections**: Schema-less JSON documents with MongoDB-style operators (`$gte`, `$lte`, `$in`, `$eq`, `$ne`) and dotted-path scans running at over **2.75M docs/sec**.
4. **Fast In-Memory / WAL Key-Value Store**: Sub-microsecond key-value caching (over **1M+ ops/sec**) with TTL and atomic counters.
5. **AI Vector RAG Similarity Search**: Vector embeddings stored in native `VECTOR` columns with sub-2ms HNSW approximate nearest-neighbor search (`cosine`, `l2`, `dot`).
6. **WARP In-Place Record Patching**: Slotted-page sliding shifts and byte-level updates without row relocation or index rebuilding.
7. **Zero Dynamic Link Errors**: Pure Dart execution on Windows, Linux, macOS, iOS, Android, and WebAssembly.

---

## 🛠️ Method 1: Using UltSQL via MCP Tools

UltSQL is registered as a local MCP server (`ultsql`) providing 9 specialized tools:

### 1. `ultsql_query`
Executes SQL queries or PL/SQL scripts.
```json
{
  "database": ":memory:", // or "path/to/my_db"
  "query": "CREATE TABLE users (id INT PRIMARY KEY, name TEXT, email TEXT);"
}
```
Querying:
```json
{
  "database": ":memory:",
  "query": "SELECT * FROM users WHERE email LIKE '%@example.com';"
}
```

### 2. `ultsql_batch_insert`
Ingests batches of structured JSON rows directly into 4KB slotted pages (up to 4.07M+ rows/sec).
```json
{
  "database": ":memory:",
  "table": "users",
  "records": [
    {"id": 1, "name": "Alice", "email": "alice@example.com"},
    {"id": 2, "name": "Bob", "email": "bob@example.com"}
  ]
}
```

### 3. `ultsql_describe_schema`
Inspects database tables, column definitions, data types, primary keys, and table row counts.
```json
{
  "database": ":memory:",
  "table": "users" // Optional, omit to list all tables and collections
}
```

### 4. `ultsql_doc_insert` & `ultsql_doc_find`
Schema-less NoSQL document storage and filtering.
```json
// Insert documents
{
  "database": ":memory:",
  "collection": "agent_memories",
  "documents": [
    {"session_id": "conv-1", "role": "user", "context": {"topic": "database"}},
    {"session_id": "conv-1", "role": "assistant", "context": {"topic": "ultsql"}}
  ]
}
```
Querying with filters and dotted paths:
```json
{
  "database": ":memory:",
  "collection": "agent_memories",
  "filter": {
    "session_id": "conv-1",
    "context.topic": "ultsql"
  },
  "limit": 10
}
```

### 5. `ultsql_kv_set` & `ultsql_kv_get`
Ultra-fast key-value cache with optional TTL.
```json
// Set
{
  "database": ":memory:",
  "key": "user:session:1001",
  "value": {"authenticated": true, "role": "admin"},
  "ttl_seconds": 3600
}

// Get
{
  "database": ":memory:",
  "key": "user:session:1001"
}
```

### 6. `ultsql_vector_search`
AI vector embedding nearest neighbor search (k-NN).
```json
{
  "database": ":memory:",
  "table": "knowledge_chunks",
  "vector_column": "embedding",
  "query_vector": [0.15, 0.82, -0.41, 0.05],
  "metric": "cosine", // "cosine", "l2", or "dot"
  "limit": 5,
  "where": "category = 'architecture'" // Optional SQL pre-filter
}
```

### 7. `ultsql_explain`
Generates execution plan and index scan diagnostics (`EXPLAIN QUERY PLAN`).
```json
{
  "database": ":memory:",
  "query": "SELECT * FROM users WHERE id = 42;"
}
```

---

## 💻 Method 2: Using UltSQL via Command Line (CLI)

```bash
# Launch interactive REPL
ultsql ./my_db

# Run one-shot query
ultsql ./my_db -c "SELECT * FROM users;"

# Run built-in 9-operation hardware benchmark harness
ultsql bench 10000

# High-speed data export (CSV or JSON)
ultsql export users export.json --db=./my_db

# High-speed batch data import
ultsql import data.json users --db=./my_db

# Launch Postgres Wire Protocol Server (Port 5432)
ultsql pgwire --port=5432 --db=./my_db

# Launch MCP Server for AI agents
ultsql mcp
```

Within the interactive REPL:
- `.tables`, `.collections`, `.schema [table]`, `.indexes [table]`
- `.bench [rows]` - Run live engine benchmark
- `.clear` / `.cls` - Clear terminal screen
- `db.<coll>.find()`, `db.<coll>.insertOne()` - MongoDB syntax

---

## 📦 Method 3: Embedding UltSQL in Dart / Flutter

Add `ultsql` to `pubspec.yaml`:

```yaml
dependencies:
  ultsql: ^1.0.28
```

```dart
import 'package:ultsql/ultsql.dart';

void main() async {
  // In-memory or on-disk with WAL
  final db = Database(':memory:', useWal: true);
  await db.init();

  // 1. Relational SQL
  final interp = Interpreter(db);
  await interp.executeScript('''
    CREATE TABLE products (id INT PRIMARY KEY, name TEXT, price DOUBLE);
    INSERT INTO products VALUES (1, 'Widget', 19.99);
  ''');
  final res = await interp.executeScript('SELECT * FROM products;');
  print(res.rows);

  // 2. High-speed Batch Ingestion
  db.insertBatchRecordsSync('products', [
    {'id': 2, 'name': 'Gadget', 'price': 29.99},
    {'id': 3, 'name': 'Device', 'price': 49.99},
  ]);

  // 3. NoSQL Document Collections
  final coll = db.collection('settings');
  await coll.insert({'theme': 'dark', 'notifications': {'email': true}});
  final docs = await coll.find({'notifications.email': true}).toList();

  // 4. Key-Value Caching
  await db.kv.set('active_token', 'xyz-123', ttl: Duration(hours: 1));
  final token = await db.kv.get('active_token');

  // 5. HNSW Vector Similarity Search
  await interp.executeScript('''
    CREATE TABLE docs (id INT PRIMARY KEY, title TEXT, emb VECTOR);
    CREATE INDEX idx_emb ON docs(emb) USING HNSW;
    INSERT INTO docs VALUES (1, 'Doc A', '[0.1, 0.8, 0.3]');
  ''');
  final matches = await interp.executeScript('''
    SELECT id, title, vector_distance(emb, '[0.1, 0.8, 0.3]', 'cosine') AS dist
    FROM docs ORDER BY dist ASC LIMIT 5;
  ''');

  await db.close();
}
```

---

## 🎯 Best Practices for Agents

1. **Session Continuity**: In MCP calls, keep `database: ":memory:"` to reuse the same memory database across consecutive tool calls during a task.
2. **On-Disk Persistence**: For persistent workflows, specify a path (e.g., `database: "./data/project.db"`). UltSQL automatically creates the directory and manages WAL files.
3. **Turbo Bulk Loads**: Always use `ultsql_batch_insert` instead of loops of `INSERT INTO` statements when loading more than 50 rows.
4. **Vector Embeddings**: Store embeddings as JSON array strings (`'[0.12, 0.95, -0.42]'`) in `VECTOR` columns and create an HNSW index with `CREATE INDEX idx_name ON table(col) USING HNSW;`.
5. **Dotted JSON Queries**: For unstructured objects, use NoSQL collections (`ultsql_doc_insert` / `ultsql_doc_find`), which use SIMD byte-scanners without full JSON DOM deserialization.
