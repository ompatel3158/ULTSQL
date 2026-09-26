import 'dart:convert';
import 'dart:typed_data';

/// Searchable Ciphertext (Repeating-Key XOR Equality Search) Engine (Zero External Dependencies)
class ZkCryptoEnclave {
  /// Encrypts plaintext field using deterministic repeating-key XOR cipher
  static Uint8List encryptField(String plaintext, String secretKey) {
    final keyBytes = utf8.encode(secretKey);
    final dataBytes = utf8.encode(plaintext);
    final result = Uint8List(dataBytes.length);
    for (int i = 0; i < dataBytes.length; i++) {
      result[i] = dataBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return result;
  }

  /// Encrypts plaintext field to hex-encoded string
  static String encryptFieldToHex(String plaintext, String secretKey) {
    final bytes = encryptField(plaintext, secretKey);
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Decrypts hex-encoded string back to plaintext
  static String decryptHexField(String hexStr, String secretKey) {
    final clean = hexStr.replaceAll(' ', '');
    final bytes = Uint8List(clean.length ~/ 2);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    final keyBytes = utf8.encode(secretKey);
    final result = Uint8List(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      result[i] = bytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return utf8.decode(result, allowMalformed: true);
  }

  /// Queries encrypted ciphertext using deterministic repeating-key XOR equality comparison
  static bool queryEncryptedField(
    Uint8List ciphertext,
    String searchPrompt,
    String secretKey,
  ) {
    final expectedCipher = encryptField(searchPrompt, secretKey);
    if (ciphertext.length != expectedCipher.length) return false;
    for (int i = 0; i < ciphertext.length; i++) {
      if (ciphertext[i] != expectedCipher[i]) return false;
    }
    return true;
  }

  /// Queries ciphertext (either hex-encoded string or raw text) against a search prompt
  static bool queryField(
    String ciphertext,
    String searchPrompt,
    String secretKey,
  ) {
    final clean = ciphertext.replaceAll(' ', '');
    if (clean.length % 2 == 0 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(clean)) {
      final bytes = Uint8List(clean.length ~/ 2);
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
      }
      return queryEncryptedField(bytes, searchPrompt, secretKey);
    }
    final rawBytes = Uint8List.fromList(utf8.encode(ciphertext));
    return queryEncryptedField(rawBytes, searchPrompt, secretKey);
  }
}
