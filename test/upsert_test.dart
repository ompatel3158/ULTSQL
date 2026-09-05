import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  test('UPSERT: ON CONFLICT DO UPDATE SET, ON CONFLICT DO NOTHING, REPLACE INTO', () async {
    final db = Database(':memory:');
    await db.init();
    final interpreter = Interpreter(db);

    // 1. Setup table
    await interpreter.executeScript(
      'CREATE TABLE users (id INT PRIMARY KEY, name TEXT, balance DOUBLE);',
    );
    await interpreter.executeScript(
      "INSERT INTO users (id, name, balance) VALUES (1, 'Alice', 1000.00);",
    );

    // 2. ON CONFLICT DO UPDATE SET
    final updateRes = await interpreter.executeScript(
      "INSERT INTO users (id, name, balance) VALUES (1, 'Alice', 2000.00) ON CONFLICT (id) DO UPDATE SET balance = 2000.00;",
    );
    expect(updateRes.message, contains('updated (on conflict)'));

    var res = await interpreter.executeScript('SELECT id, name, balance FROM users WHERE id = 1;');
    expect(res.rows.length, 1);
    expect(res.rows[0][2].toString(), '2000.0');

    // 3. EXCLUDED pseudo-table evaluation
    await interpreter.executeScript(
      "INSERT INTO users (id, name, balance) VALUES (1, 'Alice Updated', 2500.00) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, balance = EXCLUDED.balance;",
    );
    res = await interpreter.executeScript('SELECT id, name, balance FROM users WHERE id = 1;');
    expect(res.rows.length, 1);
    expect(res.rows[0][1].toString(), 'Alice Updated');
    expect(res.rows[0][2].toString(), '2500.0');

    // 4. ON CONFLICT DO NOTHING
    final nothingRes = await interpreter.executeScript(
      "INSERT INTO users (id, name, balance) VALUES (1, 'Ignored', 9999.00) ON CONFLICT (id) DO NOTHING;",
    );
    expect(nothingRes.message, contains('conflict ignored'));
    res = await interpreter.executeScript('SELECT id, name, balance FROM users WHERE id = 1;');
    expect(res.rows[0][1].toString(), 'Alice Updated');
    expect(res.rows[0][2].toString(), '2500.0');

    // 5. REPLACE INTO
    final replaceRes = await interpreter.executeScript(
      "REPLACE INTO users (id, name, balance) VALUES (1, 'Bob', 4000.00);",
    );
    expect(replaceRes.message, contains('replaced'));
    res = await interpreter.executeScript('SELECT id, name, balance FROM users WHERE id = 1;');
    expect(res.rows[0][1].toString(), 'Bob');
    expect(res.rows[0][2].toString(), '4000.0');

    await db.close();
  });
}
