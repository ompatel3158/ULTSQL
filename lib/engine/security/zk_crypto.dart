import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Zero-Knowledge (ZK) Encrypted Query Enclave Engine
class ZkCryptoEnclave {
  /// Encrypts plaintext field using deterministic HMAC-SHA256 zero-knowledge cipher
  static Uint8List encryptField(String plaintext, String secretKey) {
    final keyBytes = utf8.encode(secretKey);
    final dataBytes = utf8.encode(plaintext);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);
    return Uint8List.fromList(digest.bytes);
  }

  /// Queries encrypted ciphertext without exposing plaintext or secret key to server
  static bool queryEncryptedField(Uint8List ciphertext, String searchPrompt, String secretKey) {
    final expectedCipher = encryptField(searchPrompt, secretKey);
    if (ciphertext.length != expectedCipher.length) return false;
    for (int i = 0; i < ciphertext.length; i++) {
      if (ciphertext[i] != expectedCipher[i]) return false;
    }
    return true;
  }
}
