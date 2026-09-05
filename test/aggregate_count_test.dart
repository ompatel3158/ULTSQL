import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  test('SELECT COUNT(*) returns single non-duplicated column', () async {
    final db = Database(':memory:');
    await db.init();
    final interpreter = Interpreter(db);

    await interpreter.executeScript('CREATE TABLE items (id INT);');
    await interpreter.executeScript('INSERT INTO items VALUES (1), (2), (3), (4), (5);');

    final res = await interpreter.executeScript('SELECT COUNT(*) FROM items;');
    expect(res.columns, ['COUNT(*)']);
    expect(res.rows.length, 1);
    expect(res.rows[0].length, 1);
    expect(res.rows[0][0].toString(), '5');

    final resLower = await interpreter.executeScript('SELECT count(*) FROM items;');
    expect(resLower.columns.length, 1);
    expect(resLower.rows.length, 1);
    expect(resLower.rows[0].length, 1);
    expect(resLower.rows[0][0].toString(), '5');

    await db.close();
  });
}
