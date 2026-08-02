import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/storage/table_file.dart';
import 'package:ultsql/src/engine/ult_sql_engine.dart';

void main() {
  test('Achieve 1.2M+ rows/sec in In-Memory Ephemeral Mode', () async {
    final engine = await UltSqlEngine.openMemory();
    await engine.query('CREATE TABLE bench (id INT, val DOUBLE);');

    final db = engine.db;
    final rowTable = RowTableFile(
      cache: db.cache,
      tableName: 'bench',
      dbDirectory: db.directory,
    );

    const totalRows = 1200000;
    final batch = List.generate(totalRows, (i) => <DbValue>[DbInt(i), DbDouble(i * 1.5)]);

    print('Starting 1.2M row in-memory batch insert test...');
    final sw = Stopwatch()..start();
    rowTable.insertBatchSync(batch, xmin: 0, generatePointers: false);
    sw.stop();

    final elapsedSec = sw.elapsedMicroseconds / 1000000.0;
    final rowsPerSec = totalRows / elapsedSec;

    print('\n=== IN-MEMORY / EPHEMERAL MODE BENCHMARK ===');
    print('Total Rows Inserted: $totalRows');
    print('Execution Time: ${sw.elapsedMilliseconds} ms (${elapsedSec.toStringAsFixed(3)} s)');
    print('Throughput: ${(rowsPerSec / 1000000.0).toStringAsFixed(2)}M rows/sec (${rowsPerSec.toStringAsFixed(0)} rows/sec)');
    print('============================================\n');

    expect(rowsPerSec, greaterThanOrEqualTo(1000000.0), reason: 'Engine must achieve at least 1.0M - 1.2M+ rows/sec in memory mode');
  });
}
