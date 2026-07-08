# Hybrid Query Engine: Features & Testing Guide

This guide describes the core features of the Hybrid SQL/PL-SQL/NoSQL query engine and provides step-by-step instructions on how to test them using the automated test suite or by running scripts directly in the UI editor.

---

## 1. Automated Test Suite

To verify all core components and features automatically, run the test suite from the root of the project:

```bash
flutter test
```

This runs the following test suites:
* **`test/btree_test.dart`**: Verifies B+ Tree key insertions, point search lookups, and recursive splits.
* **`test/page_cache_test.dart`**: Validates the 16MB LRU eviction and page pinning policies.
* **`test/jit_test.dart`**: Benchmarks the JIT compiler, showing a **4x - 5x speedup** compared to standard AST evaluations.
* **`test/encryption_test.dart`**: Assures database files are obfuscated on disk, but readable with the correct passphrase.
* **`test/rollback_test.dart`**: Verifies manual transaction rollbacks and automated rollbacks on script failures.
* **`test/vector_graph_test.dart`**: Validates `CREATE RELATIONSHIP` definition and graph query traversal.
* **`test/engine_test.dart`**: Checks nested SQL joins, NoSQL JSON path extraction, vector search, and PL/SQL loop execution.

---

## 2. Interactive Testing via UI Editor Dashboard

Launch the application on the Android emulator or target device, and copy-paste the following presets into the query editor to test each feature interactively.

### Feature A: Relational SQL, Joins & NoSQL JSON Paths
This script creates relational tables, joins them, and extracts dotted JSON subpaths from schema-less columns.

```sql
-- 1. Create relational tables
CREATE TABLE depts (id INT, name TEXT);
INSERT INTO depts VALUES (1, 'Engineering');
INSERT INTO depts VALUES (2, 'Sales');

CREATE TABLE users (id INT, name TEXT, dept_id INT);
INSERT INTO users VALUES (10, 'Alice', 1);
INSERT INTO users VALUES (20, 'Bob', 1);
INSERT INTO users VALUES (30, 'Charlie', 2);

-- 2. Query relational join
SELECT users.name, depts.name 
FROM users 
JOIN depts ON users.dept_id = depts.id 
WHERE depts.id = 1;

-- 3. NoSQL Json path extraction
CREATE TABLE customers (id INT, info JSON);
INSERT INTO customers VALUES (1, '{"name": "Jack", "age": 30, "address": {"city": "Paris"}}');
INSERT INTO customers VALUES (2, '{"name": "Jill", "age": 20, "address": {"city": "London"}}');

SELECT info.name, info.address.city 
FROM customers 
WHERE info.age >= 25;
```

---

### Feature B: PL/SQL Scripts (Loops & Variables)
This tests the procedural engine block, handling declared variables, loops, conditional branches, and console logging.

```sql
DECLARE
  x INT := 0;
  y INT := 1;
BEGIN
  WHILE x < 5 LOOP
    x := x + 1;
    y := y * 2;
    DBMS_OUTPUT.PUT_LINE('Iteration x=' || x || ', y=' || y);
  END LOOP;
END;
```

---

### Feature C: AI Semantic Vector Search
This creates a table with vector-type columns, inserts semantic embeddings, and runs a vector distance search to find the nearest match.

```sql
CREATE TABLE items (id INT, label TEXT, embedding VECTOR);
INSERT INTO items VALUES (1, 'Shoes', '[0.1, 0.9, -0.1]');
INSERT INTO items VALUES (2, 'Shirt', '[0.9, 0.1, 0.2]');

-- Find closest item to target vector [0.12, 0.88, -0.08]
SELECT label, vector_distance(embedding, '[0.12, 0.88, -0.08]') AS dist 
FROM items 
ORDER BY dist ASC 
LIMIT 1;
```

---

### Feature D: Transactional Rollbacks (`ROLLBACK`)
This script demonstrates the Undo Log. It inserts records inside a transaction, performs a manual rollback, and proves that data is reverted back to the pre-transaction state.

```sql
CREATE TABLE inventory (id INT, item TEXT);
INSERT INTO inventory VALUES (1, 'Tablet');

-- Start transaction
BEGIN TRANSACTION;
INSERT INTO inventory VALUES (2, 'Smart Watch');

-- Query to verify the watch is temporarily present
SELECT id, item FROM inventory;

-- Rollback the changes
ROLLBACK;

-- Verify the watch is gone and only the tablet remains
SELECT id, item FROM inventory;
```

---

### Feature E: Vector-Graph Hybrid Queries
This DDL defines graph relationships (`CREATE RELATIONSHIP`) and traverses them (`WITH RELATIONSHIP`) to query linked nodes in a single physical Volcano pipeline.

```sql
CREATE TABLE nodes (id INT, label TEXT, embedding VECTOR);
CREATE TABLE edges (from_id INT, to_id INT);

INSERT INTO nodes VALUES (1, 'Sneakers', '[0.1, 0.9, 0.0]');
INSERT INTO nodes VALUES (2, 'Socks', '[0.11, 0.88, 0.02]');
INSERT INTO nodes VALUES (3, 'Laptop', '[0.9, 0.1, 0.1]');

INSERT INTO edges VALUES (1, 2);
INSERT INTO edges VALUES (2, 3);

-- Define graph relationship
CREATE RELATIONSHIP recommendation FROM edges TO nodes ON to_id = id;

-- Traverse and merge relationship nodes (Sneakers -> Socks, Socks -> Laptop)
SELECT edges.from_id, nodes.label 
FROM edges 
WITH RELATIONSHIP recommendation;

-- Combined Vector-Graph query: find recommendations to target vector [0.91, 0.09, 0.09] (matches Laptop)
SELECT edges.from_id, nodes.label 
FROM edges 
WHERE vector_distance(nodes.embedding, '[0.91, 0.09, 0.09]') < 0.2
WITH RELATIONSHIP recommendation;
```

---

## 3. Page-Level Encryption Verification

To test that data is encrypted on disk:
1. Run a script to insert data (e.g., Feature A).
2. Look at the database file on disk: `test_data_encryption/confidential.db`.
3. You will observe that the contents are obfuscated binary bytes, and the plain-text columns cannot be extracted using a raw text reader.
4. Correct decrypts only succeed when querying through a `Database` instance initialized with the matching passphrase.

---

## 4. Query Category Auto-detection UI Verification

When using the interactive dashboard:
1. Open the dropdown preset menu and choose **`Other / Custom Query`**.
2. Type different types of SQL or PL/SQL scripts into the text field.
3. Observe the dynamic **`QUERY EDITOR`** header badge:
   - Type `DECLARE` or `BEGIN ... END;` -> Badge switches to **`PL/SQL`**.
   - Type `CREATE RELATIONSHIP` or `WITH RELATIONSHIP` -> Badge switches to **`Vector-Graph Hybrid`**.
   - Type `vector_distance(...)` -> Badge switches to **`AI Vector Search`**.
   - Type `info.address` or `JSON` -> Badge switches to **`NoSQL Dotted JSON`**.
   - Type `JOIN` -> Badge switches to **`Relational JOIN`**.
   - Otherwise -> Badge displays **`Standard SQL`**.
4. The classification uses optimized, cached lexical scanners for near-instant (sub-microsecond) updates to ensure UI responsiveness.

