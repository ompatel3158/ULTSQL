import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/cache/crypto_security.dart';

void main() {
  const dbDir = 'test_data_encryption';

  setUp(() async {
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  });

  tearDown(() async {
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('Page-Level Encryption obfuscates disk data but reads transparently', () async {
    // 1. Create database with a passphrase
    final dbEncrypted = Database(dbDir, passphrase: 'my-secret-passphrase');
    await dbEncrypted.init();
    final interpreterEncrypted = Interpreter(dbEncrypted);

    await interpreterEncrypted.executeScript('CREATE TABLE confidential (id INT, note TEXT);');
    await interpreterEncrypted.executeScript('INSERT INTO confidential VALUES (42, \'Secure Data Here!\');');
    await dbEncrypted.close();

    // 2. Read the raw database file bytes from disk directly
    final dbFile = File('$dbDir/confidential.db');
    expect(await dbFile.exists(), isTrue);
    final rawBytes = await dbFile.readAsBytes();

    // Ensure the text 'Secure Data Here!' is NOT present as plain-text in raw bytes (obfuscated on disk)
    final plainTextString = 'Secure Data Here!';
    bool containsPlain = false;
    for (int i = 0; i <= rawBytes.length - plainTextString.length; i++) {
      bool match = true;
      for (int j = 0; j < plainTextString.length; j++) {
        if (rawBytes[i + j] != plainTextString.codeUnitAt(j)) {
          match = false;
          break;
        }
      }
      if (match) {
        containsPlain = true;
        break;
      }
    }
    expect(containsPlain, isFalse, reason: "The plaintext data must not be visible on disk.");

    // 3. Open with CORRECT passphrase and verify data is readable
    final dbCorrect = Database(dbDir, passphrase: 'my-secret-passphrase');
    await dbCorrect.init();
    final interpreterCorrect = Interpreter(dbCorrect);

    final resCorrect = await interpreterCorrect.executeScript('SELECT id, note FROM confidential;');
    expect(resCorrect.rows.length, 1);
    expect(resCorrect.rows[0][0].toString(), '42');
    expect(resCorrect.rows[0][1].toString(), 'Secure Data Here!');
    await dbCorrect.close();

    // 4. Open with INCORRECT passphrase and verify DatabaseIntegrityException is thrown
    expect(
      () => Database(dbDir, passphrase: 'wrong-passphrase'),
      throwsA(isA<DatabaseIntegrityException>()),
      reason: "Decryption with wrong passphrase must immediately throw DatabaseIntegrityException.",
    );
  });

  test('Deterministic Obfuscation (XOR Fast Matching) via SQL functions', () async {
    final db = Database(':memory:');
    await db.init();
    final interpreter = Interpreter(db);

    // Test version() SQL function
    final verRes = await interpreter.executeScript('SELECT version();');
    expect(verRes.rows[0][0].toString(), contains('1.0.23'));

    // Create table with obfuscated tokens
    await interpreter.executeScript('CREATE TABLE tokens (id INT, cipher TEXT);');
    await interpreter.executeScript(
      "INSERT INTO tokens VALUES (1, zk_encrypt('credit_card_4111', 'my_key_123'));",
    );
    await interpreter.executeScript(
      "INSERT INTO tokens VALUES (2, zk_encrypt('social_security_99', 'my_key_123'));",
    );

    // Exact deterministic query matching without decrypting raw data
    final matchRes = await interpreter.executeScript(
      "SELECT id, zk_decrypt(cipher, 'my_key_123') as plain FROM tokens WHERE zk_match(cipher, 'credit_card_4111', 'my_key_123') = true;",
    );
    expect(matchRes.rows.length, 1);
    expect(matchRes.rows[0][0].toString(), '1');
    expect(matchRes.rows[0][1].toString(), 'credit_card_4111');

    // Mismatched search prompt yields 0 rows
    final noMatchRes = await interpreter.executeScript(
      "SELECT id FROM tokens WHERE zk_match(cipher, 'non_existent_token', 'my_key_123') = true;",
    );
    expect(noMatchRes.rows.length, 0);

    await db.close();
  });
}
