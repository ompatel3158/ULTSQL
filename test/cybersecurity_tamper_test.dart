import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/cache/crypto_security.dart';
import 'package:ultsql/src/engine/cache/page_cache.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';

void main() {
  const testDir = 'test_cybersecurity_sandbox';

  void cleanDir() {
    final d = Directory(testDir);
    if (d.existsSync()) {
      d.deleteSync(recursive: true);
    }
    d.createSync(recursive: true);
  }

  setUp(cleanDir);
  tearDown(cleanDir);

  group('Cryptographic Primitives & Key Zeroization', () {
    test('PBKDF2-HMAC-SHA256 derivation and memory wipe', () {
      final salt = CryptoSecurity.generateSalt(16);
      expect(salt.length, 16);

      final keys1 = CryptoSecurity.pbkdf2DeriveKeys('SuperSecretPassphrase123!', salt, iterations: 1000);
      final keys2 = CryptoSecurity.pbkdf2DeriveKeys('SuperSecretPassphrase123!', salt, iterations: 1000);

      expect(keys1.encKey.length, 32);
      expect(keys1.authKey.length, 32);
      expect(keys1.encKey, equals(keys2.encKey));
      expect(keys1.authKey, equals(keys2.authKey));

      // Constant time equality
      expect(CryptoSecurity.constantTimeEquals(keys1.encKey, keys2.encKey), isTrue);

      // Memory zeroization wipe
      keys1.wipe();
      expect(keys1.encKey.every((b) => b == 0), isTrue);
      expect(keys1.authKey.every((b) => b == 0), isTrue);
    });

    test('HMAC incorporates pageId to prevent cross-page swap attacks', () {
      final authKey = Uint8List(32)..fillRange(0, 32, 0xAA);
      final ciphertext = Uint8List(4064)..fillRange(0, 4064, 0x55);

      final tagPage0 = CryptoSecurity.computePageHmac(authKey, 0, ciphertext);
      final tagPage1 = CryptoSecurity.computePageHmac(authKey, 1, ciphertext);

      expect(tagPage0.length, 32);
      expect(tagPage1.length, 32);
      expect(tagPage0, isNot(equals(tagPage1)),
          reason: 'HMAC tags for different page IDs must differ to prevent page swapping.');
      expect(CryptoSecurity.verifyPageHmac(authKey, 0, ciphertext, tagPage0), isTrue);
      expect(CryptoSecurity.verifyPageHmac(authKey, 1, ciphertext, tagPage0), isFalse);
    });
  });

  group('Envelope Mode: inPage (Self-Contained 4064-byte payload + 32-byte tag)', () {
    test('Roundtrip write/read transparently on disk', () async {
      final db = Database(testDir, passphrase: 'master-inpage-secret', authEnvelopeMode: AuthEnvelopeMode.inPage);
      await db.init();
      final interp = Interpreter(db);
      await interp.executeScript('CREATE TABLE accounts (id INT, holder TEXT, balance INT);');
      for (int i = 1; i <= 20; i++) {
        await interp.executeScript("INSERT INTO accounts VALUES ($i, 'Holder-$i', ${i * 100});");
      }
      await db.close();

      // Verify security.meta exists and specifies inPage
      final metaFile = File('$testDir/security.meta');
      expect(metaFile.existsSync(), isTrue);
      final metaJson = jsonDecode(metaFile.readAsStringSync());
      expect(metaJson['envelopeMode'], 'inPage');

      // Reopen with correct key
      final reopenDb = Database(testDir, passphrase: 'master-inpage-secret');
      await reopenDb.init();
      final reopenInterp = Interpreter(reopenDb);
      final res = await reopenInterp.executeScript('SELECT count(*) FROM accounts;');
      expect(res.rows[0][0].toString(), '20');
      await reopenDb.close();
    });

    test('Active tamper detection: bit-flip in page throws DatabaseIntegrityException', () async {
      final db = Database(testDir, passphrase: 'tamper-secret', authEnvelopeMode: AuthEnvelopeMode.inPage);
      await db.init();
      final interp = Interpreter(db);
      await interp.executeScript('CREATE TABLE records (id INT, data TEXT);');
      for (int i = 1; i <= 10; i++) {
        await interp.executeScript("INSERT INTO records VALUES ($i, 'CriticalPayload-$i');");
      }
      await db.close();

      // Tamper on disk: flip a byte in the table file
      final tableFile = File('$testDir/records.db');
      expect(tableFile.existsSync(), isTrue);
      final rawBytes = tableFile.readAsBytesSync();
      expect(rawBytes.length, greaterThanOrEqualTo(4096));

      // Flip a bit in the encrypted payload of page 0
      rawBytes[200] ^= 0xFF;
      tableFile.writeAsBytesSync(rawBytes, flush: true);

      // Reopen with valid passphrase
      final reopenDb = Database(testDir, passphrase: 'tamper-secret');
      await reopenDb.init();
      final reopenInterp = Interpreter(reopenDb);

      expect(
        () async => await reopenInterp.executeScript('SELECT * FROM records;'),
        throwsA(isA<DatabaseIntegrityException>()),
        reason: 'Tampered page must fail HMAC verification and throw DatabaseIntegrityException.',
      );

      await reopenDb.close();
    });
  });

  group(r'Envelope Mode: companion ($table.auth companion file)', () {
    test('Writes tags to companion file and verifies integrity', () async {
      final db = Database(testDir, passphrase: 'companion-secret', authEnvelopeMode: AuthEnvelopeMode.companion);
      await db.init();
      final interp = Interpreter(db);
      await interp.executeScript('CREATE TABLE ledger (txid INT, amount INT);');
      for (int i = 1; i <= 25; i++) {
        await interp.executeScript("INSERT INTO ledger VALUES ($i, ${i * 50});");
      }
      await db.close();

      // Companion .auth file must exist
      final authFile = File('$testDir/ledger.auth');
      expect(authFile.existsSync(), isTrue, reason: 'Companion .auth file must be created on disk.');
      expect(authFile.lengthSync() % 32, 0, reason: 'Companion file size must be a multiple of 32 bytes.');

      // Reopen and query
      final reopenDb = Database(testDir, passphrase: 'companion-secret');
      await reopenDb.init();
      final reopenInterp = Interpreter(reopenDb);
      final res = await reopenInterp.executeScript('SELECT count(*) FROM ledger;');
      expect(res.rows[0][0].toString(), '25');
      await reopenDb.close();

      // Tamper companion file: flip a byte in the HMAC tag
      final tagBytes = authFile.readAsBytesSync();
      tagBytes[10] ^= 0x01;
      authFile.writeAsBytesSync(tagBytes, flush: true);

      // Reopen and verify tamper detection
      final tamperDb = Database(testDir, passphrase: 'companion-secret');
      await tamperDb.init();
      final tamperInterp = Interpreter(tamperDb);

      expect(
        () async => await tamperInterp.executeScript('SELECT * FROM ledger;'),
        throwsA(isA<DatabaseIntegrityException>()),
        reason: 'Corrupted HMAC tag in companion file must trigger DatabaseIntegrityException.',
      );

      await tamperDb.close();
    });
  });

  group('Metadata & Zeroization Enforcement', () {
    test('Unauthenticated access to encrypted database is rejected', () async {
      final db = Database(testDir, passphrase: 'lock-me-up');
      await db.init();
      final interp = Interpreter(db);
      await interp.executeScript('CREATE TABLE secrets (k TEXT, v TEXT);');
      await interp.executeScript("INSERT INTO secrets VALUES ('api_key', 'sk-test-1234');");
      await db.close();

      // Open without passphrase
      expect(
        () => Database(testDir),
        throwsA(isA<DatabaseIntegrityException>()),
        reason: 'Opening encrypted database without passphrase must throw DatabaseIntegrityException.',
      );

      // Open with wrong passphrase
      expect(
        () => Database(testDir, passphrase: 'incorrect-passphrase'),
        throwsA(isA<DatabaseIntegrityException>()),
        reason: 'Opening encrypted database with wrong passphrase must throw DatabaseIntegrityException.',
      );
    });

    test('Tampering with security.meta is rejected', () async {
      final db = Database(testDir, passphrase: 'meta-secret');
      await db.init();
      await db.close();

      final metaFile = File('$testDir/security.meta');
      final metaJson = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      // Corrupt the verification marker
      metaJson['verificationMarker'] = base64Encode(Uint8List(16)..fillRange(0, 16, 0xFF));
      metaFile.writeAsStringSync(jsonEncode(metaJson));

      expect(
        () => Database(testDir, passphrase: 'meta-secret'),
        throwsA(isA<DatabaseIntegrityException>()),
        reason: 'Corrupted security.meta must immediately throw DatabaseIntegrityException.',
      );
    });

    test('Database.close() wipes cryptographic keys from memory', () async {
      final db = Database(testDir, passphrase: 'wipe-test');
      await db.init();
      expect(db.cache.encryptionKey, isNotNull);
      expect(db.cache.authKey, isNotNull);

      await db.close();

      expect(db.cache.encryptionKey, isNull);
      expect(db.cache.authKey, isNull);
    });
  });
}
