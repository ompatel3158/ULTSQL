import 'dart:convert';
import 'dart:io';
import 'package:ultsql/ultsql.dart';

void main() async {
  print('===============================================================');
  print('   ULTSQL DISK PERSISTENCE VERIFICATION: WRITE -> CLOSE -> REOPEN');
  print('===============================================================');

  final testDir = Directory('test_persistence_run_db');
  if (testDir.existsSync()) {
    try {
      testDir.deleteSync(recursive: true);
    } catch (_) {}
  }
  testDir.createSync(recursive: true);

  final dbPath = testDir.path;
  print('Testing database directory: $dbPath\n');

  bool allTestsPassed = true;

  // =========================================================================
  // PHASE 1: RELATIONAL SQL - AUTOCOMMIT, EXPLICIT COMMIT, UPDATE, DELETE
  // =========================================================================
  print('--- TEST 1: Relational SQL Persistence ---');
  {
    print('[Step 1.1] Opening Database to write initial data...');
    final db1 = Database(dbPath, useWal: true);
    await db1.init();
    final interp1 = Interpreter(db1);

    // DDL
    await interp1.executeScript('''
      CREATE TABLE users (
        id INT PRIMARY KEY,
        name TEXT,
        balance DOUBLE,
        bio TEXT
      );
    ''');
    await interp1.executeScript('CREATE INDEX idx_users_name ON users(name);');

    // Insert 100 rows in explicit transaction
    await interp1.executeScript('BEGIN TRANSACTION;');
    for (int i = 1; i <= 100; i++) {
      await interp1.executeScript(
        "INSERT INTO users VALUES ($i, 'User_$i', ${(i * 10.5).toStringAsFixed(2)}, 'Bio for $i');",
      );
    }
    await interp1.executeScript('COMMIT;');

    // Insert 10 rows via autocommit
    for (int i = 101; i <= 110; i++) {
      await interp1.executeScript(
        "INSERT INTO users VALUES ($i, 'Autocommit_$i', ${(i * 1.0).toStringAsFixed(2)}, 'Autocommit Bio');",
      );
    }

    // Update row 1
    await interp1.executeScript("UPDATE users SET balance = 9999.99 WHERE id = 1;");
    await interp1.executeScript("UPDATE users SET bio = 'Updated Bio' WHERE id = 1;");

    // Delete rows 105 through 110
    await interp1.executeScript("DELETE FROM users WHERE id >= 105;");

    print('[Step 1.2] Data written. Closing database connection completely...');
    await db1.close();

    print('[Step 1.3] Physical files on disk:');
    for (final entity in Directory(dbPath).listSync()) {
      if (entity is File) {
        print('  - ${entity.path.split(Platform.pathSeparator).last} (${entity.lengthSync()} bytes)');
      }
    }

    print('[Step 1.4] Reopening database from physical disk in fresh instance...');
    final db2 = Database(dbPath, useWal: true);
    await db2.init();
    final interp2 = Interpreter(db2);

    final countRes = await interp2.executeScript('SELECT COUNT(*) AS total FROM users;');
    final total = countRes.rows.first.first.value;
    print('  - Persisted total row count: $total (Expected: 104)');
    if (total != 104) {
      print('  ❌ FAIL: Expected 104 rows after update/delete, got $total');
      allTestsPassed = false;
    } else {
      print('  ✅ PASS: Row count is exactly 104!');
    }

    final row1Res = await interp2.executeScript('SELECT name, balance, bio FROM users WHERE id = 1;');
    final row1 = row1Res.rows.first;
    print('  - Row 1 check: name=${row1[0].value}, balance=${row1[1].value}, bio=${row1[2].value}');
    if (row1[0].value != 'User_1' || row1[1].value != 9999.99 || row1[2].value != 'Updated Bio') {
      print('  ❌ FAIL: Row 1 updated values did not persist correctly!');
      allTestsPassed = false;
    } else {
      print('  ✅ PASS: Row 1 update correctly persisted!');
    }

    final deletedRowsCheck = await interp2.executeScript('SELECT id FROM users WHERE id >= 105;');
    if (deletedRowsCheck.rows.isNotEmpty) {
      print('  ❌ FAIL: Deleted rows (105-110) reappeared: ${deletedRowsCheck.rows}');
      allTestsPassed = false;
    } else {
      print('  ✅ PASS: Deleted rows (105-110) are permanently gone from physical disk (0 rows returned)!');
    }

    await db2.close();
  }

  // =========================================================================
  // PHASE 2: WAL CRASH DURABILITY - COMMITTED SURVIVES, UNCOMMITTED DROPPED
  // =========================================================================
  print('\n--- TEST 2: WAL Crash Persistence (Uncommitted vs Committed) ---');
  {
    print('[Step 2.1] Opening Database to test transaction durability...');
    final db1 = Database(dbPath, useWal: true);
    await db1.init();
    final interp1 = Interpreter(db1);

    await interp1.executeScript('CREATE TABLE accounts (id INT PRIMARY KEY, amount INT);');
    await interp1.executeScript('INSERT INTO accounts VALUES (1, 100);');
    await interp1.executeScript('INSERT INTO accounts VALUES (2, 200);');

    // Now start a transaction, insert row 3, and deliberately DO NOT commit
    await interp1.executeScript('BEGIN TRANSACTION;');
    await interp1.executeScript('INSERT INTO accounts VALUES (3, 300);');

    // Simulate crash: close directly without COMMIT (or process crash)
    print('[Step 2.2] Simulating uncommitted crash by closing without COMMIT...');
    await db1.close();

    print('[Step 2.3] Re-opening Database to verify WAL recovery...');
    final db2 = Database(dbPath, useWal: true);
    await db2.init();
    final interp2 = Interpreter(db2);

    final rowsRes = await interp2.executeScript('SELECT id, amount FROM accounts ORDER BY id ASC;');
    print('  - Rows recovered: ${rowsRes.rows.map((r) => '${r[0].value}:${r[1].value}').toList()}');
    if (rowsRes.rows.length != 2) {
      print('  ❌ FAIL: Expected 2 committed rows, got ${rowsRes.rows.length}');
      allTestsPassed = false;
    } else if (rowsRes.rows.any((r) => r[0].value == 3)) {
      print('  ❌ FAIL: Uncommitted row 3 survived!');
      allTestsPassed = false;
    } else {
      print('  ✅ PASS: Committed rows (1, 2) persisted; uncommitted row 3 safely reverted by WAL!');
    }

    await db2.close();
  }

  // =========================================================================
  // PHASE 3: NoSQL DOCUMENT STORE PERSISTENCE
  // =========================================================================
  print('\n--- TEST 3: NoSQL Document Store Persistence ---');
  {
    print('[Step 3.1] Opening Engine to insert NoSQL documents...');
    final engine1 = await UltSqlEngine.openFile(dbPath);
    final coll1 = engine1.collection('customers');

    await coll1.insertOne({'_id': 'cust_1', 'name': 'Alice', 'tier': 'gold', 'orders': 5});
    await coll1.insertOne({'_id': 'cust_2', 'name': 'Bob', 'tier': 'silver', 'orders': 2});
    await coll1.insertOne({'_id': 'cust_3', 'name': 'Charlie', 'tier': 'bronze', 'orders': 0});

    // Mutate cust_1
    await coll1.updateOne(
      filter: {'_id': 'cust_1'},
      update: {'\$inc': {'orders': 3}, '\$set': {'location': 'Tokyo'}},
    );

    print('[Step 3.2] Closing Engine...');
    await engine1.close();

    print('[Step 3.3] Re-opening Engine from disk to check NoSQL persistence...');
    final engine2 = await UltSqlEngine.openFile(dbPath);
    final coll2 = engine2.collection('customers');

    final allDocs = await coll2.find().toList();
    final count = allDocs.length;
    print('  - NoSQL collection count: $count (Expected: 3)');
    if (count != 3) {
      print('  ❌ FAIL: Expected 3 documents, got $count');
      allTestsPassed = false;
    } else {
      print('  ✅ PASS: Document count is 3!');
    }

    final cust1 = await coll2.findOne({'_id': 'cust_1'});
    print('  - Customer 1 fetched: ${cust1?.data}');
    if (cust1 == null || cust1.data['orders'] != 8 || cust1.data['location'] != 'Tokyo') {
      print('  ❌ FAIL: cust_1 mutations did not persist properly: ${cust1?.data}');
      allTestsPassed = false;
    } else {
      print('  ✅ PASS: cust_1 mutated fields (orders: 8, location: Tokyo) persisted!');
    }

    await engine2.close();
  }

  // =========================================================================
  // PHASE 4: REDIS KEY-VALUE STORE PERSISTENCE
  // =========================================================================
  print('\n--- TEST 4: Key-Value Store Persistence & TTL Pruning ---');
  {
    print('[Step 4.1] Opening Engine to set KV pairs...');
    final engine1 = await UltSqlEngine.openFile(dbPath);
    final kv1 = engine1.kv;

    await kv1.set('site_name', 'ULTSQL Portal');
    await kv1.set('counter', 42);
    await kv1.set('config', {'theme': 'dark', 'version': 1.0});

    // Ephemeral key with 100ms TTL
    await kv1.set('ephemeral_token', 'temp123', ttl: Duration(milliseconds: 100));

    print('[Step 4.2] Waiting 150ms for ephemeral key to expire...');
    await Future.delayed(Duration(milliseconds: 150));

    print('[Step 4.3] Closing Engine...');
    await engine1.close();

    print('[Step 4.4] Re-opening Engine to verify KV persistence across restart...');
    final engine2 = await UltSqlEngine.openFile(dbPath);
    final kv2 = engine2.kv;

    final siteName = await kv2.get('site_name');
    final counter = await kv2.get('counter');
    final config = await kv2.get('config');
    final ephemeral = await kv2.get('ephemeral_token');

    print('  - site_name: $siteName (Expected: "ULTSQL Portal")');
    print('  - counter: $counter (Expected: 42)');
    print('  - config: $config');
    print('  - ephemeral_token: $ephemeral (Expected: null)');

    if (siteName != 'ULTSQL Portal' || counter != 42 || config == null || config['theme'] != 'dark') {
      print('  ❌ FAIL: Persistent KV pairs failed to persist correctly!');
      allTestsPassed = false;
    } else if (ephemeral != null) {
      print('  ❌ FAIL: Expired ephemeral token survived persistence!');
      allTestsPassed = false;
    } else {
      print('  ✅ PASS: Persistent KV pairs preserved and expired token properly excluded!');
    }

    await engine2.close();
  }

  // Clean up
  try {
    testDir.deleteSync(recursive: true);
  } catch (_) {}

  print('\n===============================================================');
  if (allTestsPassed) {
    print('🎉 ALL PERSISTENCE TESTS PASSED: DATA IS 100% SAVED AND RESTORED!');
  } else {
    print('⚠️ SOME PERSISTENCE TESTS FAILED. SEE DETAILS ABOVE.');
  }
  print('===============================================================');
}
