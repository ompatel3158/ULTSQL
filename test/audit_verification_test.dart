import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/storage/hnsw_index.dart';

void main() {
  group('ULTSQL Technical Audit Verification Suite', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ultsql_audit_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    dynamic cell(QueryResult res, String colName, [int row = 0]) {
      final idx = res.columns.indexWhere(
        (c) => c.toLowerCase() == colName.toLowerCase() ||
               c.toLowerCase().endsWith('.${colName.toLowerCase()}'),
      );
      if (idx == -1) throw Exception("Column $colName not found in ${res.columns}");
      return res.rows[row][idx].value;
    }

    test('Deficiency 1: MVCC Snapshot Isolation & Time-Travel on UPDATE', () async {
      final db = Database(tempDir.path);
      await db.init();
      final interp = Interpreter(db);
      await interp.executeScript('CREATE TABLE accounts (id INT PRIMARY KEY, balance INT);');
      
      // Tx 1: Insert initial balance
      await interp.executeScript('''
        BEGIN TRANSACTION;
        INSERT INTO accounts VALUES (1, 100);
        COMMIT;
      ''');

      final tx1Id = db.cache.mvccTxManager.nextTxId - 1;

      // Tx 2: Update balance from 100 to 250
      await interp.executeScript('''
        BEGIN TRANSACTION;
        UPDATE accounts SET balance = 250 WHERE id = 1;
        COMMIT;
      ''');

      final tx2Id = db.cache.mvccTxManager.nextTxId - 1;

      // Query current state
      final currentRes = await interp.executeScript('SELECT balance FROM accounts WHERE id = 1;');
      expect(cell(currentRes, 'balance'), equals(250));

      // Time travel query AS OF TRANSACTION tx1Id must return 100!
      final historicalRes = await interp.executeScript('SELECT balance FROM accounts AS OF TRANSACTION $tx1Id WHERE id = 1;');
      expect(cell(historicalRes, 'balance'), equals(100));

      // Time travel query AS OF TRANSACTION tx2Id must return 250!
      final historicalRes2 = await interp.executeScript('SELECT balance FROM accounts AS OF TRANSACTION $tx2Id WHERE id = 1;');
      expect(cell(historicalRes2, 'balance'), equals(250));

      await db.close();
    });

    test('Deficiency 2: TRUNCATE TABLE evicts cache and disk files', () async {
      final db = Database(tempDir.path);
      await db.init();
      final interp = Interpreter(db);
      await interp.executeScript('CREATE TABLE items (id INT PRIMARY KEY, name TEXT);');
      await interp.executeScript('CREATE INDEX idx_items_name ON items (name);');

      for (int i = 1; i <= 50; i++) {
        await interp.executeScript("INSERT INTO items VALUES ($i, 'Item_$i');");
      }

      var res = await interp.executeScript('SELECT COUNT(*) AS total FROM items;');
      expect(cell(res, 'total'), equals(50));

      // Truncate table
      await interp.executeScript('TRUNCATE TABLE items;');

      res = await interp.executeScript('SELECT COUNT(*) AS total FROM items;');
      expect(cell(res, 'total'), equals(0));

      // Insert new records after truncate
      await interp.executeScript("INSERT INTO items VALUES (101, 'FreshItem');");
      res = await interp.executeScript('SELECT * FROM items WHERE id = 101;');
      expect(res.rows.length, equals(1));
      expect(cell(res, 'name'), equals('FreshItem'));

      await db.close();

      // Memory DB test for TRUNCATE
      final memDb = Database(':memory:');
      await memDb.init();
      final memInterp = Interpreter(memDb);
      await memInterp.executeScript('CREATE TABLE mem_items (id INT, val TEXT);');
      await memInterp.executeScript("INSERT INTO mem_items VALUES (1, 'A');");
      await memInterp.executeScript("INSERT INTO mem_items VALUES (2, 'B');");
      var memRes = await memInterp.executeScript('SELECT COUNT(*) AS total FROM mem_items;');
      expect(cell(memRes, 'total'), equals(2));

      await memInterp.executeScript('TRUNCATE TABLE mem_items;');
      memRes = await memInterp.executeScript('SELECT COUNT(*) AS total FROM mem_items;');
      expect(cell(memRes, 'total'), equals(0));
      await memDb.close();
    });

    test('Deficiency 3: Joins & DDL Grammar (CROSS JOIN, ALTER TABLE ADD COLUMN, Table Constraints, Oracle CURSOR)', () async {
      final db = Database(':memory:');
      await db.init();
      final interp = Interpreter(db);

      // 1. Table-level Constraints: FOREIGN KEY, PRIMARY KEY, UNIQUE, CHECK
      await interp.executeScript('''
        CREATE TABLE depts (
          id INT PRIMARY KEY,
          dept_name TEXT UNIQUE
        );
      ''');
      await interp.executeScript('''
        CREATE TABLE emps (
          emp_id INT,
          name TEXT,
          dept_id INT,
          age INT,
          CONSTRAINT pk_emps PRIMARY KEY (emp_id),
          CONSTRAINT uq_name UNIQUE (name),
          CONSTRAINT fk_dept FOREIGN KEY (dept_id) REFERENCES depts(id) ON DELETE CASCADE,
          CONSTRAINT chk_age CHECK (age >= 18)
        );
      ''');

      await interp.executeScript("INSERT INTO depts VALUES (10, 'Engineering');");
      await interp.executeScript("INSERT INTO emps VALUES (1, 'Alice', 10, 30);");

      // 2. ALTER TABLE ADD [COLUMN]
      await interp.executeScript("ALTER TABLE emps ADD COLUMN salary DOUBLE DEFAULT 50000.0;");
      await interp.executeScript("ALTER TABLE emps ADD notes TEXT;");

      var empRes = await interp.executeScript('SELECT * FROM emps WHERE emp_id = 1;');
      expect(cell(empRes, 'salary'), equals(50000.0));

      // 3. CROSS JOIN with and without ON
      await interp.executeScript("CREATE TABLE colors (color TEXT);");
      await interp.executeScript("INSERT INTO colors VALUES ('Red');");
      await interp.executeScript("INSERT INTO colors VALUES ('Blue');");

      await interp.executeScript("CREATE TABLE sizes (size TEXT);");
      await interp.executeScript("INSERT INTO sizes VALUES ('S');");
      await interp.executeScript("INSERT INTO sizes VALUES ('M');");

      // CROSS JOIN without ON
      final crossRes = await interp.executeScript("SELECT c.color, s.size FROM colors c CROSS JOIN sizes s;");
      expect(crossRes.rows.length, equals(4));

      // CROSS JOIN with ON condition
      final crossOnRes = await interp.executeScript("SELECT c.color, s.size FROM colors c CROSS JOIN sizes s ON c.color = 'Red';");
      expect(crossOnRes.rows.length, equals(2));

      // 4. Oracle PL/SQL CURSOR c IS SELECT ...;
      final plsqlRes = await interp.executeScript('''
        DECLARE
          CURSOR c_emps IS SELECT emp_id, name FROM emps;
        BEGIN
          NULL;
        END;
      ''');
      expect(plsqlRes.message, contains('success'));

      await db.close();
    });

    test('Deficiency 4: Direct file SQL queries (SELECT * FROM "file.csv")', () async {
      final csvFile = File('${tempDir.path}/users_export.csv');
      csvFile.writeAsStringSync('id,username,score\n1,Alice,95.5\n2,Bob,88.0\n3,Charlie,72.3\n');

      final db = Database(':memory:');
      await db.init();
      final interp = Interpreter(db);

      // Query CSV directly using file path literal
      final csvPathEscaped = csvFile.path.replaceAll('\\', '/');
      final res = await interp.executeScript("SELECT * FROM '$csvPathEscaped';");
      expect(res.rows.length, equals(3));
      expect(cell(res, 'id', 0), equals(1));
      expect(cell(res, 'username', 0), equals('Alice'));
      expect(cell(res, 'score', 0), equals(95.5));

      // Query with WHERE clause on CSV
      final filteredRes = await interp.executeScript("SELECT username, score FROM '$csvPathEscaped' WHERE score > 80.0;");
      expect(filteredRes.rows.length, equals(2));

      await db.close();
    });

    test('Deficiency 5: Vector Dot Product Math & Distance Minimization', () async {
      final v1 = DbVector([1.0, 2.0, 3.0]);
      final v2 = DbVector([4.0, 5.0, 6.0]);

      // 1. In pure Dart value math: dot product = 1*4 + 2*5 + 3*6 = 32.0 (positive!)
      expect(v1.dotProductTo(v2), equals(32.0));

      final db = Database(':memory:');
      await db.init();
      final interp = Interpreter(db);
      
      // 2. SQL dot_product function
      final dotRes = await interp.executeScript("SELECT dot_product('[1, 2, 3]', '[4, 5, 6]') AS dp;");
      expect(cell(dotRes, 'dp'), equals(32.0));

      // 3. vector_distance(v1, v2, 'dot') returns -32.0 for distance minimization in top-K
      final distRes = await interp.executeScript("SELECT vector_distance('[1, 2, 3]', '[4, 5, 6]', 'dot') AS dist;");
      expect(cell(distRes, 'dist'), equals(-32.0));

      await db.close();
    });

    test('Deficiency 6: HNSW O(N^2) Write Amplification Prevention via In-Memory Buffering', () async {
      final indexFile = '${tempDir.path}/hnsw_buffered.idx';
      final hnsw = HnswIndex(
        indexPath: indexFile,
        autoSave: false, // In-memory buffering enabled
        M: 16,
        M0: 32,
        efConstruction: 64,
        efSearch: 32,
      );
      hnsw.initSync();

      // Insert vectors without per-insert disk serialization
      for (int i = 0; i < 200; i++) {
        final vec = DbVector([i.toDouble(), (i * 2).toDouble(), (i * 3).toDouble()]);
        hnsw.insertSync(vec, 0, i);
      }
      expect(hnsw.nodes.length, equals(200));

      // Persist to disk in single batch
      hnsw.saveSync();
      expect(File(indexFile).existsSync(), isTrue);

      // Verify that another instance can load and query
      final loadedHnsw = HnswIndex(
        indexPath: indexFile,
        autoSave: false,
      );
      loadedHnsw.initSync();
      expect(loadedHnsw.nodes.length, equals(200));

      final queryVec = DbVector([10.0, 20.0, 30.0]);
      final nearest = loadedHnsw.search(queryVec, 1);
      expect(nearest.isNotEmpty, isTrue);
      expect(nearest.first.id, equals(10));
    });

    test('Deficiency 7: Savepoint & Transaction Rollback Page Truncation', () async {
      final db = Database(tempDir.path);
      await db.init();
      final interp = Interpreter(db);
      await interp.executeScript('CREATE TABLE logs (id INT, message TEXT);');

      await interp.executeScript('BEGIN TRANSACTION;');
      for (int i = 1; i <= 100; i++) {
        await interp.executeScript("INSERT INTO logs VALUES ($i, 'Msg_$i');");
      }
      await interp.executeScript('SAVEPOINT sp1;');

      for (int i = 101; i <= 200; i++) {
        await interp.executeScript("INSERT INTO logs VALUES ($i, 'ExtraMsg_$i');");
      }

      // Rollback to savepoint: pages that grew must be truncated without leaving dangling pinned pages
      await interp.executeScript('ROLLBACK TO SAVEPOINT sp1;');
      var res = await interp.executeScript('SELECT COUNT(*) AS total FROM logs;');
      expect(cell(res, 'total'), equals(100));

      // Rollback whole transaction
      await interp.executeScript('ROLLBACK;');
      res = await interp.executeScript('SELECT COUNT(*) AS total FROM logs;');
      expect(cell(res, 'total'), equals(0));

      await db.close();
    });
  });
}
