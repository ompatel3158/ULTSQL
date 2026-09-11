import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/ult_sql_engine.dart';

void main() {
  test('Public Ingest API and Query Verification in Memory Mode', () async {
    final engine = await UltSqlEngine.openMemory();
    await engine.query('CREATE TABLE bench (id INT, val DOUBLE);');

    const totalRows = 500000;
    final batch = List.generate(totalRows, (i) => <dynamic>[i, i * 1.5]);

    print('Starting $totalRows row in-memory public batch insert test...');
    final sw = Stopwatch()..start();
    final insertRes = await engine.insertBatch('bench', batch);
    sw.stop();

    final elapsedSec = sw.elapsedMicroseconds / 1000000.0;
    final rowsPerSec = totalRows / elapsedSec;

    print('\n=== PUBLIC IN-MEMORY BATCH INGESTION BENCHMARK ===');
    print('Total Rows Inserted: $totalRows');
    print('Execution Time: ${sw.elapsedMilliseconds} ms (${elapsedSec.toStringAsFixed(3)} s)');
    print('Throughput: ${(rowsPerSec / 1000.0).toStringAsFixed(0)}K rows/sec (${rowsPerSec.toStringAsFixed(0)} rows/sec)');
    print('Result Message: ${insertRes.message}');
    print('==================================================\n');

    expect(insertRes.message, contains('$totalRows rows inserted'));

    // Verify the data is findable and readable:
    print('Verifying data queryability...');
    final countRes = await engine.query('SELECT COUNT(*) FROM bench;');
    expect(countRes.rows.length, 1);
    expect(countRes.rows[0][0].value, totalRows);

    final pointRes = await engine.query('SELECT * FROM bench WHERE id = 250000;');
    expect(pointRes.rows.length, 1);
    expect(pointRes.rows[0][0].value, 250000);
    expect(pointRes.rows[0][1].value, 250000 * 1.5);
    print('Verified COUNT(*) = $totalRows and point lookup id=250000 succeeded.\n');

    await engine.close();
  });

  test('Public Ingest API with Active B+Tree Index and Range Lookup Verification', () async {
    final engine = await UltSqlEngine.openMemory();
    await engine.query('CREATE TABLE items (id INT, price DOUBLE);');
    await engine.query('CREATE INDEX idx_items_id ON items(id);');

    const totalRows = 100000;
    final batch = List.generate(totalRows, (i) => <dynamic>[i, i * 2.5]);

    print('Starting $totalRows row indexed public batch insert test...');
    final sw = Stopwatch()..start();
    final insertRes = await engine.insertBatch('items', batch);
    sw.stop();

    final elapsedSec = sw.elapsedMicroseconds / 1000000.0;
    final rowsPerSec = totalRows / elapsedSec;

    print('\n=== PUBLIC INDEXED BATCH INGESTION BENCHMARK ===');
    print('Total Rows Inserted: $totalRows');
    print('Execution Time: ${sw.elapsedMilliseconds} ms (${elapsedSec.toStringAsFixed(3)} s)');
    print('Throughput: ${(rowsPerSec / 1000.0).toStringAsFixed(0)}K rows/sec (${rowsPerSec.toStringAsFixed(0)} rows/sec)');
    print('Result Message: ${insertRes.message}');
    print('================================================\n');

    expect(insertRes.message, contains('$totalRows rows inserted'));

    // Verify index lookups:
    final pointRes = await engine.query('SELECT * FROM items WHERE id = 42424;');
    expect(pointRes.rows.length, 1);
    expect(pointRes.rows[0][0].value, 42424);
    expect(pointRes.rows[0][1].value, 42424 * 2.5);

    final countRes = await engine.query('SELECT COUNT(*) FROM items;');
    expect(countRes.rows[0][0].value, totalRows);
    print('Verified indexed point lookup and COUNT(*) = $totalRows.\n');

    await engine.close();
  });
}
