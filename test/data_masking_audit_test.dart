import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'package:ultsql/engine/executor/value.dart';

void main() {
  group('Dynamic Data Masking and Security Audit Logging', () {
    late Database db;
    late Interpreter interpreter;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hybrid_sql_test_');
      db = Database(tempDir.path);
      await db.init();
      interpreter = Interpreter(db);
    });

    tearDown(() async {
      db.cache.closeAllSync();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Masking applied for non-admin user and Audit logs recorded', () async {
      // 1. Create table with masked columns
      final createRes = await interpreter.executeScript('''
        CREATE TABLE users (
          id INT PRIMARY KEY,
          name TEXT,
          email TEXT MASKED WITH (FUNCTION = 'email'),
          card TEXT MASKED WITH (FUNCTION = 'credit_card'),
          secret_info TEXT MASKED WITH (FUNCTION = 'default')
        );
      ''');
      print('CREATE: ' + createRes.message);

      // 2. Insert test data
      final insertRes = await interpreter.executeScript('''
        INSERT INTO users (id, name, email, card, secret_info) VALUES 
        (1, 'Alice', 'alice@example.com', '1234-5678-9012-3456', 'supersecret');
      ''');
      print('INSERT: ' + insertRes.message);

      // Grant SELECT to guest
      await interpreter.executeScript("GRANT SELECT ON users TO guest;");

      // 3. Query as admin user
      interpreter.currentUser = 'admin';
      final adminRes = await interpreter.executeScript('SELECT email, card, secret_info FROM users;');
      
      print(adminRes.message);
      expect(adminRes.rows.length, 1);
      final adminRow = adminRes.rows[0];
      expect(adminRow[0].toString(), 'alice@example.com');
      expect(adminRow[1].toString(), '1234-5678-9012-3456');
      expect(adminRow[2].toString(), 'supersecret');

      // 4. Query as non-admin user
      interpreter.currentUser = 'guest';
      final guestRes = await interpreter.executeScript('SELECT email, card, secret_info FROM users;');
      print('GUEST: ' + guestRes.message);
      expect(guestRes.rows.length, 1);
      final guestRow = guestRes.rows[0];
      expect(guestRow[0].toString(), 'a***@example.com');
      expect(guestRow[1].toString(), 'XXXX-XXXX-XXXX-3456');
      expect(guestRow[2].toString(), 'XXXX');

      // 5. Verify audit log
      final auditFile = File('${tempDir.path}/audit.log');
      expect(auditFile.existsSync(), isTrue);

      final logContent = auditFile.readAsStringSync();
      
      expect(logContent, contains('CREATE TABLE users'));
      expect(logContent, contains('INSERT INTO users'));
      
      // Select statements are not DDL/DML, but if they were logged we'd check here. 
      // Our logic specifically logs insert, update, delete, create, alter, drop.
      expect(logContent, isNot(contains('SELECT email')));
    });
  });
}
