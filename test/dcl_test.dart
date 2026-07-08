import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'dart:io';

void main() {
  late Database db;
  late Interpreter interpreter;
  final dbPath = 'test_dcl_db';

  setUp(() async {
    final dir = Directory(dbPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    db = Database(dbPath);
    await db.init();
    interpreter = Interpreter(db);
  });

  tearDown(() async {
    await db.close();
    final dir = Directory(dbPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('GRANT, REVOKE, and SET USER privilege control flow', () async {
    // 1. Create table
    await interpreter.executeScript('CREATE TABLE t_perm(a INT, b TEXT);');
    
    // 2. Default user is admin (who can insert/select freely)
    await interpreter.executeScript("INSERT INTO t_perm VALUES (1, 'Admin Row');");
    final selectAdmin = await interpreter.executeScript('SELECT * FROM t_perm;');
    expect(selectAdmin.rows.length, 1);

    // 3. Switch to non-admin user 'guest'
    await interpreter.executeScript("SET USER 'guest';");
    expect(interpreter.currentUser, 'guest');

    // 4. Try select (should fail with permission denied)
    final selectGuestFail = await interpreter.executeScript('SELECT * FROM t_perm;');
    expect(selectGuestFail.message.contains('Permission denied'), true);

    // 5. Try insert (should fail with permission denied)
    final insertGuestFail = await interpreter.executeScript("INSERT INTO t_perm VALUES (2, 'Guest Row');");
    expect(insertGuestFail.message.contains('Permission denied'), true);

    // 6. Switch back to admin and GRANT select privilege to guest
    await interpreter.executeScript("SET USER 'admin';");
    await interpreter.executeScript("GRANT SELECT ON t_perm TO 'guest';");

    // 7. Switch back to guest and verify SELECT works but INSERT still fails
    await interpreter.executeScript("SET USER 'guest';");
    final selectGuestSuccess = await interpreter.executeScript('SELECT * FROM t_perm;');
    expect(selectGuestSuccess.rows.length, 1);
    expect(selectGuestSuccess.rows.first[1].toString(), 'Admin Row');

    final insertGuestFail2 = await interpreter.executeScript("INSERT INTO t_perm VALUES (2, 'Guest Row 2');");
    expect(insertGuestFail2.message.contains('Permission denied'), true);

    // 8. Switch back to admin, GRANT INSERT, and verify guest can insert
    await interpreter.executeScript("SET USER 'admin';");
    await interpreter.executeScript("GRANT INSERT ON t_perm TO 'guest';");

    await interpreter.executeScript("SET USER 'guest';");
    final insertGuestSuccess = await interpreter.executeScript("INSERT INTO t_perm VALUES (2, 'Guest Row Success');");
    expect(insertGuestSuccess.message.contains('Error'), false);

    // 9. Verify the row was inserted
    final selectGuestSuccess2 = await interpreter.executeScript('SELECT * FROM t_perm;');
    expect(selectGuestSuccess2.rows.length, 2);

    // 10. Switch back to admin, REVOKE insert, and verify guest is blocked again
    await interpreter.executeScript("SET USER 'admin';");
    await interpreter.executeScript("REVOKE INSERT ON t_perm FROM 'guest';");

    await interpreter.executeScript("SET USER 'guest';");
    final insertGuestFail3 = await interpreter.executeScript("INSERT INTO t_perm VALUES (3, 'Guest Row Blocked');");
    expect(insertGuestFail3.message.contains('Permission denied'), true);
  });
}
