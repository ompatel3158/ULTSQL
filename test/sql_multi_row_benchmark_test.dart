import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/parser/parser.dart';
import 'package:ultsql/src/engine/storage/table_file.dart';

void main() {
  test('SQL multi-row insert benchmark', () async {
    final db = Database(':memory:');
    await db.init();
    final interpreter = Interpreter(db);
    await interpreter.executeScript('CREATE TABLE bench (id INT, val DOUBLE);');

    final sb = StringBuffer('INSERT INTO bench VALUES ');
    for (int i = 1; i <= 100000; i++) {
      if (i > 1) sb.write(',');
      sb.write('($i, ${i * 1.5})');
    }
    sb.write(';');

    final sql = sb.toString();
    print('Starting 100K SQL multi-row insert...');
    final sw = Stopwatch()..start();
    final insertRes = await interpreter.executeScript(sql);
    sw.stop();
    print('Insert Result Message: ${insertRes.message}');
    print('Total executeScript Elapsed: ${sw.elapsedMilliseconds} ms (${(100000 / (sw.elapsedMilliseconds / 1000)).toStringAsFixed(0)} rows/sec)');

    final countRes = await interpreter.executeScript('SELECT COUNT(*) FROM bench;');
    print('COUNT: ${countRes.rows.first[0].value}');
    expect(countRes.rows.first[0].value, 100000);

    final btree = interpreter.db.getOrInitIndexSync('idx_bench_id');
    print('btree rootPageId=${btree.rootPageId}, rightmost=${btree.rightmostLeafPageId}');
    final ptr1 = btree.searchSync([1.0]);
    print('btree searchSync 1.0: $ptr1');
    final ptr50k = btree.searchSync([50000.0]);
    print('btree searchSync 50000.0: $ptr50k');
    final ptr100k = btree.searchSync([100000.0]);
    print('btree searchSync 100000.0: $ptr100k');

    final pointRes = await interpreter.executeScript('SELECT * FROM bench WHERE id = 50000;');
    print('Point lookup id=50000 rows len: ${pointRes.rows.length}');
    expect(pointRes.rows.first[0].value, 50000);
    expect(pointRes.rows.first[1].value, 75000.0);
    await db.close();
  });
}
