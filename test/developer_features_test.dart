import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/storage/catalog.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void expectVal(dynamic actual, dynamic expected, String message) {
  final actualStr = actual.toString();
  final expectedStr = expected.toString();
  if (actualStr != expectedStr) {
    throw Exception("FAIL [$message]: Expected '$expectedStr', but got '$actualStr'");
  }
}

void main() {
  test('Developer Features Test Suite', () async {
    print("Running Developer Features Suite...");
    final tempDir = await Directory.systemTemp.createTemp('ultsql_dev_features_test_');
    final db = Database(tempDir.path);
    final interpreter = Interpreter(db);

    try {
    // 1. GENERATE_SERIES
    print("Testing 1: GENERATE_SERIES...");
    final res1 = await interpreter.executeScript("SELECT * FROM generate_series(1, 5)");
    expect(res1.rows.length, 5, "generate_series length");
    expect(res1.rows[0][0], DbInt(1), "generate_series first");
    expect(res1.rows[4][0], DbInt(5), "generate_series last");

    final res2 = await interpreter.executeScript("SELECT * FROM generate_series(10, 2, -2)");
    expect(res2.rows.length, 5, "generate_series step length");
    expect(res2.rows[0][0], DbInt(10), "generate_series step first");
    expect(res2.rows[4][0], DbInt(2), "generate_series step last");

    // 2. Data Types: BOOLEAN, UUID, DATETIME, BLOB, DECIMAL
    print("Testing 2: Expanded Data Types...");
    await interpreter.executeScript("CREATE TABLE dev_types (id INT PRIMARY KEY, is_active BOOLEAN, user_uuid UUID, created_at DATETIME, data_payload BLOB, balance DECIMAL)");

    await interpreter.executeScript("INSERT INTO dev_types VALUES (1, true, 'f47ac10b-58cc-4372-a567-0e02b2c3d479', '2026-08-05T15:00:00.000Z', 'hello', 99.95)");

    final resTypes = await interpreter.executeScript("SELECT * FROM dev_types WHERE id = 1");
    expect(resTypes.rows.length, 1, "dev_types row count");
    expect(resTypes.rows[0][1], DbBool(true), "BOOLEAN value");
    expect(resTypes.rows[0][2], DbUuid('f47ac10b-58cc-4372-a567-0e02b2c3d479'), "UUID value");
    expect(resTypes.rows[0][5], DbDecimal(99.95), "DECIMAL value");

    // 3. CAST & ::
    print("Testing 3: CAST and :: operators...");
    final resCast1 = await interpreter.executeScript("SELECT CAST(123 AS TEXT), CAST('456' AS INT), CAST(1 AS BOOLEAN)");
    expect(resCast1.rows[0][0], DbText('123'), "CAST to TEXT");
    expect(resCast1.rows[0][1], DbInt(456), "CAST to INT");
    expect(resCast1.rows[0][2], DbBool(true), "CAST to BOOLEAN");

    final resCast2 = await interpreter.executeScript("SELECT 789::TEXT, '99.99'::DOUBLE");
    expect(resCast2.rows[0][0], DbText('789'), "::TEXT operator");
    expect(resCast2.rows[0][1], DbDouble(99.99), "::DOUBLE operator");

    // 4. information_schema & catalog views
    print("Testing 4: information_schema views...");
    await interpreter.executeScript("CREATE TABLE products (id INT, title TEXT, price DECIMAL)");

    final tablesRes = await interpreter.executeScript("SELECT * FROM information_schema.tables");
    expect(tablesRes.rows.isNotEmpty, true, "information_schema.tables not empty");
    final tableNames = tablesRes.rows.map((r) => r[2].toString()).toList();
    if (!tableNames.contains('products')) {
      throw Exception("Expected information_schema.tables to contain 'products'");
    }

    final shorthandRes = await interpreter.executeScript("SELECT * FROM information.tables");
    expect(shorthandRes.rows.length, tablesRes.rows.length, "information.tables shorthand");

    final colsRes = await interpreter.executeScript("SELECT * FROM information_schema.columns");
    expect(colsRes.rows.isNotEmpty, true, "information_schema.columns not empty");

    final schemasRes = await interpreter.executeScript("SELECT * FROM information_schema.schemata");
    expect(schemasRes.rows.length, 1, "information_schema.schemata count");

    // 5. Metadata inspection: DESCRIBE, SHOW COLUMNS, PRAGMA table_info, SHOW SCHEMAS
    print("Testing 5: Metadata inspection...");
    await interpreter.executeScript("CREATE TABLE items (id INT, name TEXT, qty INT)");

    final descRes = await interpreter.executeScript("DESCRIBE items");
    expect(descRes.rows.length, 3, "DESCRIBE items row count");
    expect(descRes.rows[0][0], DbText('id'), "DESCRIBE first column name");

    final showColRes = await interpreter.executeScript("SHOW COLUMNS FROM items");
    expect(showColRes.rows.length, 3, "SHOW COLUMNS items count");

    final pragmaRes = await interpreter.executeScript("PRAGMA table_info('items')");
    expect(pragmaRes.rows.length, 3, "PRAGMA table_info count");

    final showSchemasRes = await interpreter.executeScript("SHOW SCHEMAS");
    expect(showSchemasRes.rows.length, 2, "SHOW SCHEMAS count");

    // 6. DDL: CREATE TABLE IF NOT EXISTS, DROP TABLE IF EXISTS, TRUNCATE TABLE
    print("Testing 6: Enhanced DDL...");
    await interpreter.executeScript("CREATE TABLE IF NOT EXISTS test_ddl (id INT)");
    final resIfNotExists = await interpreter.executeScript("CREATE TABLE IF NOT EXISTS test_ddl (id INT)");
    if (!resIfNotExists.message.contains('already exists')) {
      throw Exception("Expected IF NOT EXISTS message");
    }

    await interpreter.executeScript("INSERT INTO test_ddl VALUES (1)");
    await interpreter.executeScript("TRUNCATE TABLE test_ddl");

    final resDropIfExists1 = await interpreter.executeScript("DROP TABLE IF EXISTS test_ddl");
    print("DROP TABLE 1 MESSAGE: '${resDropIfExists1.message}'");
    if (!resDropIfExists1.message.contains('dropped')) {
      throw Exception("Expected dropped message, got '${resDropIfExists1.message}'");
    }

    final resDropIfExists2 = await interpreter.executeScript("DROP TABLE IF EXISTS non_existent_table");
    if (!resDropIfExists2.message.contains('does not exist')) {
      throw Exception("Expected does not exist message");
    }

    // 7. Developer habit scalar functions
    print("Testing 7: Developer habit scalar functions...");
    final resFuncs = await interpreter.executeScript("""
      SELECT 
        COALESCE(NULL, 'default_val'),
        NULLIF(10, 10),
        GREATEST(10, 50, 20),
        LEAST(10, 50, 20),
        CONCAT_WS('-', '2026', '08', '05'),
        TYPEOF(100),
        GEN_RANDOM_UUID()
    """);

    expect(resFuncs.rows[0][0], DbText('default_val'), "COALESCE result");
    expect(resFuncs.rows[0][1], DbNull(), "NULLIF result");
    expect(resFuncs.rows[0][2], DbInt(50), "GREATEST result");
    expect(resFuncs.rows[0][3], DbInt(10), "LEAST result");
    expect(resFuncs.rows[0][4], DbText('2026-08-05'), "CONCAT_WS result");
    expect(resFuncs.rows[0][5], DbText('INTEGER'), "TYPEOF result");
    // 8. ILIKE & Extended Math/String functions
    print("Testing 8: ILIKE and Extended Math/String functions...");
    final resMath = await interpreter.executeScript("""
      SELECT 
        ABS(-42),
        ROUND(3.14159, 2),
        CEIL(4.2),
        FLOOR(4.8),
        POW(2, 3),
        SQRT(16),
        REPLACE('hello world', 'world', 'ultsql'),
        REVERSE('dart')
    """);

    print("RESMATH MSG: ${resMath.message}, ROWS: ${resMath.rows}");
    expect(resMath.rows[0][0], DbInt(42), "ABS result");
    expect(resMath.rows[0][1], DbDouble(3.14), "ROUND result");
    expect(resMath.rows[0][2], DbInt(5), "CEIL result");
    expect(resMath.rows[0][3], DbInt(4), "FLOOR result");
    expect(resMath.rows[0][4], DbDouble(8.0), "POW result");
    expect(resMath.rows[0][5], DbDouble(4.0), "SQRT result");
    expect(resMath.rows[0][6], DbText('hello ultsql'), "REPLACE result");
    expect(resMath.rows[0][7], DbText('trad'), "REVERSE result");

    await interpreter.executeScript("CREATE TABLE ilike_test (name TEXT)");
    await interpreter.executeScript("INSERT INTO ilike_test VALUES ('Antigravity')");
    await interpreter.executeScript("INSERT INTO ilike_test VALUES ('Gemini')");
    final resIlike = await interpreter.executeScript("SELECT * FROM ilike_test WHERE name ILIKE 'anti%'");
    print("ILIKE ROWS: ${resIlike.rows}, MESSAGE: ${resIlike.message}");
    expect(resIlike.rows.length, 1, "ILIKE match count");

    // 9. Final Boss DB Extensions (Regex, Date Math, String Part, Version)
    print("Testing 9: Final Boss DB Extensions (Regex, Date Math, String Part, Version)...");
    final resBoss = await interpreter.executeScript("""
      SELECT 
        REGEXP_LIKE('ompatel@google.com', '^[a-z]+@[a-z]+\\.[a-z]+\$'),
        SPLIT_PART('a.b.c', '.', 2),
        INITCAP('hello world database'),
        DATE_ADD('2026-08-05', 10),
        DATE_SUB('2026-08-05', 5),
        EXTRACT('year', '2026-08-05'),
        VERSION()
    """);

    expectVal(resBoss.rows[0][0], DbBool(true), "REGEXP_LIKE result");
    expectVal(resBoss.rows[0][1], DbText('b'), "SPLIT_PART result");
    expectVal(resBoss.rows[0][2], DbText('Hello World Database'), "INITCAP result");
    expectVal(resBoss.rows[0][3], DbText('2026-08-15'), "DATE_ADD result");
    expectVal(resBoss.rows[0][4], DbText('2026-07-31'), "DATE_SUB result");
    expectVal(resBoss.rows[0][5], DbInt(2026), "EXTRACT result");
    expectVal(resBoss.rows[0][6].toString().contains('ULTSQL'), true, "VERSION result");

    final resRegexOp = await interpreter.executeScript("SELECT * FROM ilike_test WHERE name ~ '^Anti'");
    expectVal(resRegexOp.rows.length, 1, "Regex ~ operator match count");

    print("\nALL DEVELOPER FEATURES TESTS PASSED SUCCESSFULLY!");
  } finally {
    db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
  });
}
