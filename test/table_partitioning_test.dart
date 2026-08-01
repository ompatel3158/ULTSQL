import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'package:ultsql/engine/executor/value.dart';

void main() {
  const dbDir = 'test_db_partitions';

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

  test('Physical table partitioning by RANGE routes inserts and aggregates selects', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);

    // 1. Create parent table
    await interpreter.executeScript("CREATE TABLE orders (id INT, order_date TEXT, amount DOUBLE) PARTITION BY RANGE (order_date);");
    
    // 2. Create partitions
    await interpreter.executeScript("CREATE TABLE orders_2025 PARTITION OF orders FOR VALUES FROM ('2025-01-01') TO ('2025-12-31');");
    await interpreter.executeScript("CREATE TABLE orders_2026 PARTITION OF orders FOR VALUES FROM ('2026-01-01') TO ('2026-12-31');");
    
    // 3. Insert rows into parent
    await interpreter.executeScript("INSERT INTO orders VALUES (1, '2025-05-15', 100.50);");
    await interpreter.executeScript("INSERT INTO orders VALUES (2, '2026-03-10', 200.75);");
    await interpreter.executeScript("INSERT INTO orders VALUES (3, '2025-11-20', 50.00);");
    await interpreter.executeScript("INSERT INTO orders VALUES (4, '2026-08-05', 300.00);");

    // 4. Verify orders_2025
    final res2025 = await interpreter.executeScript("SELECT * FROM orders_2025;");
    expect(res2025.rows.length, equals(2));
    final ids2025 = res2025.rows.map((r) => r[0].value).toList();
    expect(ids2025, containsAll([1, 3]));

    // 5. Verify orders_2026
    final res2026 = await interpreter.executeScript("SELECT * FROM orders_2026;");
    expect(res2026.rows.length, equals(2));
    final ids2026 = res2026.rows.map((r) => r[0].value).toList();
    expect(ids2026, containsAll([2, 4]));

    // 6. Verify orders (parent) has all rows
    final resAll = await interpreter.executeScript("SELECT * FROM orders;");
    print("resAll rows: ${resAll.rows.map((r) => r.map((c) => c.value).toList()).toList()}");
    expect(resAll.rows.length, equals(4));
    final idsAll = resAll.rows.map((r) => r[0].value).toList();
    expect(idsAll, containsAll([1, 2, 3, 4]));
    
    await db.close();
  });
}
