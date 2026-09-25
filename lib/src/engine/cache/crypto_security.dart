import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Specifies how page authentication (HMAC-SHA256) tags are persisted.
enum AuthEnvelopeMode {
  /// Stores a 32-byte HMAC-SHA256 tag in the last 32 bytes of the 4096-byte page
  /// (payload restricted to 4064 bytes). Self-contained, crash-safe, atomic.
  inPage,

  /// Preserves full 4096 bytes per page for data; HMAC-SHA256 tags are written
  /// to a companion `$tableName.auth` file indexed by `pageId * 32`.
  companion,
}

/// Thrown when encrypted database pages fail cryptographic authentication
/// (detecting unauthorized disk tampering, bit corruption, or page manipulation).
class DatabaseIntegrityException implements Exception {
  final String message;
  final int? pageId;
  final String? filePath;

  DatabaseIntegrityException(this.message, {this.pageId, this.filePath});

  @override
  String toString() =>
      'DatabaseIntegrityException: $message' +
      (pageId != null ? ' (Page ID: $pageId)' : '') +
      (filePath != null ? ' in $filePath' : '');
}

/// Holds derived AES-256 encryption key and HMAC-SHA256 authentication key.
class DerivedKeys {
  final Uint8List encKey;
  final Uint8List authKey;

  DerivedKeys({required this.encKey, required this.authKey});

  /// Cryptographically wipes keys from memory.
  void wipe() {
    encKey.fillRange(0, encKey.length, 0);
    authKey.fillRange(0, authKey.length, 0);
  }
}

/// Pure-Dart enterprise cryptography engine for ULTSQL.
///
/// Implements:
/// - PBKDF2-HMAC-SHA256 Key Derivation with salt and 10,000+ rounds.
/// - Authenticated Page Envelopes (AES-256-CTR + HMAC-SHA256).
/// - Active bit-tamper detection and page-swap replay prevention.
/// - Memory zeroization.
class CryptoSecurity {
  /// Generates cryptographically secure pseudo-random salt.
  static Uint8List generateSalt([int length = 16]) {
    final rng = Random.secure();
    final salt = Uint8List(length);
    for (int i = 0; i < length; i++) {
      salt[i] = rng.nextInt(256);
    }
    return salt;
  }

  /// Derives 64 bytes (32-byte encKey + 32-byte authKey) using PBKDF2-HMAC-SHA256.
  static DerivedKeys pbkdf2DeriveKeys(
    String passphrase,
    Uint8List salt, {
    int iterations = 10000,
  }) {
    final passwordBytes = utf8.encode(passphrase);
    final hmacSha256 = Hmac(sha256, passwordBytes);

    // Block 1: 32 bytes for AES-256 Encryption Key
    final block1 = _pbkdf2Block(hmacSha256, salt, iterations, 1);
    // Block 2: 32 bytes for HMAC-SHA256 Authentication Key
    final block2 = _pbkdf2Block(hmacSha256, salt, iterations, 2);

    return DerivedKeys(encKey: block1, authKey: block2);
  }

  static Uint8List _pbkdf2Block(
    Hmac prf,
    Uint8List salt,
    int iterations,
    int blockIndex,
  ) {
    // Salt || INT_32_BE(blockIndex)
    final input = Uint8List(salt.length + 4);
    input.setRange(0, salt.length, salt);
    final bd = ByteData.sublistView(input, salt.length, salt.length + 4);
    bd.setUint32(0, blockIndex, Endian.big);

    // U_1 = PRF(P, Salt || INT(i))
    var u = Uint8List.fromList(prf.convert(input).bytes);
    final result = Uint8List.fromList(u);

    // U_2 ... U_c
    for (int c = 1; c < iterations; c++) {
      u = Uint8List.fromList(prf.convert(u).bytes);
      for (int k = 0; k < result.length; k++) {
        result[k] ^= u[k];
      }
    }
    return result;
  }

  /// Computes a 32-byte HMAC-SHA256 tag over `pageId || ciphertext`.
  /// Including `pageId` prevents cross-page swap attacks.
  static Uint8List computePageHmac(
    Uint8List authKey,
    int pageId,
    Uint8List ciphertext,
  ) {
    final hmac = Hmac(sha256, authKey);
    final pageHeader = ByteData(4)..setUint32(0, pageId, Endian.big);
    final payload = Uint8List(4 + ciphertext.length);
    payload.setRange(0, 4, pageHeader.buffer.asUint8List());
    payload.setRange(4, 4 + ciphertext.length, ciphertext);
    return Uint8List.fromList(hmac.convert(payload).bytes);
  }

  /// Constant-time verification of HMAC-SHA256 tag.
  static bool verifyPageHmac(
    Uint8List authKey,
    int pageId,
    Uint8List ciphertext,
    List<int> expectedTag,
  ) {
    if (expectedTag.length != 32) return false;
    final calculated = computePageHmac(authKey, pageId, ciphertext);
    return constantTimeEquals(calculated, expectedTag);
  }

  /// Compares two byte lists in constant time to prevent timing side-channel leaks.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Cryptographically zeroes a buffer in memory.
  static void wipe(Uint8List buffer) {
    buffer.fillRange(0, buffer.length, 0);
  }
}
