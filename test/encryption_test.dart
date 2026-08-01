import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';

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

    // 4. Open with INCORRECT passphrase and verify data is garbage (or fails to read/decrypt properly)
    final dbIncorrect = Database(dbDir, passphrase: 'wrong-passphrase');
    await dbIncorrect.init();
    final interpreterIncorrect = Interpreter(dbIncorrect);

    final resIncorrect = await interpreterIncorrect.executeScript('SELECT id, note FROM confidential;');
    // Since the encryption/decryption key is wrong, deserializing slotted page records should fail or yield null/corrupted fields
    expect(resIncorrect.rows.isEmpty, isTrue, reason: "Decryption with wrong passphrase should result in failed row deserialization.");
    await dbIncorrect.close();
  });
}
