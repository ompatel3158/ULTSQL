import 'dart:typed_data';

/// Pure-Dart AES-256 Block Cipher and CTR Mode implementation.
class Aes256 {
  static final List<int> sBox = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
  ];

  final Uint32List _expandedKey;

  Aes256(Uint8List key) : _expandedKey = _expandKey(key);

  static Uint32List _expandKey(Uint8List key) {
    final keyBytes = Uint8List(32);
    if (key.length == 32) {
      keyBytes.setAll(0, key);
    } else {
      // Deterministically pad or derive a 32-byte key from key bytes
      for (int i = 0; i < 32; i++) {
        keyBytes[i] = key.isEmpty ? 0 : key[i % key.length] ^ (i * 17);
      }
    }

    final w = Uint32List(60);
    for (int i = 0; i < 8; i++) {
      w[i] = (keyBytes[i * 4] << 24) |
             (keyBytes[i * 4 + 1] << 16) |
             (keyBytes[i * 4 + 2] << 8) |
             keyBytes[i * 4 + 3];
    }

    final rcon = [0, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36];

    for (int i = 8; i < 60; i++) {
      int temp = w[i - 1];
      if (i % 8 == 0) {
        temp = ((temp << 8) & 0xFFFFFFFF) | (temp >>> 24);
        temp = (sBox[(temp >> 24) & 0xFF] << 24) |
               (sBox[(temp >> 16) & 0xFF] << 16) |
               (sBox[(temp >> 8) & 0xFF] << 8) |
               sBox[temp & 0xFF];
        temp ^= (rcon[i ~/ 8] << 24);
      } else if (i % 8 == 4) {
        temp = (sBox[(temp >> 24) & 0xFF] << 24) |
               (sBox[(temp >> 16) & 0xFF] << 16) |
               (sBox[(temp >> 8) & 0xFF] << 8) |
               sBox[temp & 0xFF];
      }
      w[i] = w[i - 8] ^ temp;
    }
    return w;
  }

  void encryptBlock(Uint8List src, int srcOff, Uint8List dest, int destOff) {
    int s0 = (src[srcOff] << 24) | (src[srcOff + 1] << 16) | (src[srcOff + 2] << 8) | src[srcOff + 3];
    int s1 = (src[srcOff + 4] << 24) | (src[srcOff + 5] << 16) | (src[srcOff + 6] << 8) | src[srcOff + 7];
    int s2 = (src[srcOff + 8] << 24) | (src[srcOff + 9] << 16) | (src[srcOff + 10] << 8) | src[srcOff + 11];
    int s3 = (src[srcOff + 12] << 24) | (src[srcOff + 13] << 16) | (src[srcOff + 14] << 8) | src[srcOff + 15];

    s0 ^= _expandedKey[0];
    s1 ^= _expandedKey[1];
    s2 ^= _expandedKey[2];
    s3 ^= _expandedKey[3];

    for (int r = 1; r < 14; r++) {
      final k = r * 4;
      
      final t0 = (sBox[(s0 >> 24) & 0xFF] << 24) |
                 (sBox[(s1 >> 16) & 0xFF] << 16) |
                 (sBox[(s2 >> 8) & 0xFF] << 8) |
                 sBox[s3 & 0xFF];
      final t1 = (sBox[(s1 >> 24) & 0xFF] << 24) |
                 (sBox[(s2 >> 16) & 0xFF] << 16) |
                 (sBox[(s3 >> 8) & 0xFF] << 8) |
                 sBox[s0 & 0xFF];
      final t2 = (sBox[(s2 >> 24) & 0xFF] << 24) |
                 (sBox[(s3 >> 16) & 0xFF] << 16) |
                 (sBox[(s0 >> 8) & 0xFF] << 8) |
                 sBox[s1 & 0xFF];
      final t3 = (sBox[(s3 >> 24) & 0xFF] << 24) |
                 (sBox[(s0 >> 16) & 0xFF] << 16) |
                 (sBox[(s1 >> 8) & 0xFF] << 8) |
                 sBox[s2 & 0xFF];

      s0 = _mix(t0) ^ _expandedKey[k];
      s1 = _mix(t1) ^ _expandedKey[k + 1];
      s2 = _mix(t2) ^ _expandedKey[k + 2];
      s3 = _mix(t3) ^ _expandedKey[k + 3];
    }

    final t0 = (sBox[(s0 >> 24) & 0xFF] << 24) |
               (sBox[(s1 >> 16) & 0xFF] << 16) |
               (sBox[(s2 >> 8) & 0xFF] << 8) |
               sBox[s3 & 0xFF];
    final t1 = (sBox[(s1 >> 24) & 0xFF] << 24) |
               (sBox[(s2 >> 16) & 0xFF] << 16) |
               (sBox[(s3 >> 8) & 0xFF] << 8) |
               sBox[s0 & 0xFF];
    final t2 = (sBox[(s2 >> 24) & 0xFF] << 24) |
               (sBox[(s3 >> 16) & 0xFF] << 16) |
               (sBox[(s0 >> 8) & 0xFF] << 8) |
               sBox[s1 & 0xFF];
    final t3 = (sBox[(s3 >> 24) & 0xFF] << 24) |
               (sBox[(s0 >> 16) & 0xFF] << 16) |
               (sBox[(s1 >> 8) & 0xFF] << 8) |
               sBox[s2 & 0xFF];

    s0 = t0 ^ _expandedKey[56];
    s1 = t1 ^ _expandedKey[57];
    s2 = t2 ^ _expandedKey[58];
    s3 = t3 ^ _expandedKey[59];

    dest[destOff] = (s0 >> 24) & 0xFF;
    dest[destOff + 1] = (s0 >> 16) & 0xFF;
    dest[destOff + 2] = (s0 >> 8) & 0xFF;
    dest[destOff + 3] = s0 & 0xFF;

    dest[destOff + 4] = (s1 >> 24) & 0xFF;
    dest[destOff + 5] = (s1 >> 16) & 0xFF;
    dest[destOff + 6] = (s1 >> 8) & 0xFF;
    dest[destOff + 7] = s1 & 0xFF;

    dest[destOff + 8] = (s2 >> 24) & 0xFF;
    dest[destOff + 9] = (s2 >> 16) & 0xFF;
    dest[destOff + 10] = (s2 >> 8) & 0xFF;
    dest[destOff + 11] = s2 & 0xFF;

    dest[destOff + 12] = (s3 >> 24) & 0xFF;
    dest[destOff + 13] = (s3 >> 16) & 0xFF;
    dest[destOff + 14] = (s3 >> 8) & 0xFF;
    dest[destOff + 15] = s3 & 0xFF;
  }

  static int _mul2(int b) {
    return ((b << 1) ^ (((b & 0x80) != 0) ? 0x1B : 0)) & 0xFF;
  }

  static int _mix(int w) {
    final b0 = (w >> 24) & 0xFF;
    final b1 = (w >> 16) & 0xFF;
    final b2 = (w >> 8) & 0xFF;
    final b3 = w & 0xFF;

    final d0 = _mul2(b0) ^ (_mul2(b1) ^ b1) ^ b2 ^ b3;
    final d1 = b0 ^ _mul2(b1) ^ (_mul2(b2) ^ b2) ^ b3;
    final d2 = b0 ^ b1 ^ _mul2(b2) ^ (_mul2(b3) ^ b3);
    final d3 = (_mul2(b0) ^ b0) ^ b1 ^ b2 ^ _mul2(b3);

    return (d0 << 24) | (d1 << 16) | (d2 << 8) | d3;
  }
}

/// AES-256 CTR Mode stream/page encryption
class AesCtr {
  final Aes256 aes;

  AesCtr(Uint8List key) : aes = Aes256(key);

  /// Performs CTR encrypt/decrypt in-place on data.
  void cryptPage(int pageId, Uint8List data) {
    final counterBlock = Uint8List(16);
    final keystream = Uint8List(16);
    final bd = ByteData.sublistView(counterBlock);
    bd.setUint64(0, pageId);

    final blocksCount = data.length ~/ 16;
    for (int blockIdx = 0; blockIdx < blocksCount; blockIdx++) {
      bd.setUint64(8, blockIdx);
      aes.encryptBlock(counterBlock, 0, keystream, 0);
      final offset = blockIdx * 16;
      for (int j = 0; j < 16; j++) {
        data[offset + j] ^= keystream[j];
      }
    }

    // Handle remaining bytes if size is not a multiple of 16
    final rem = data.length % 16;
    if (rem > 0) {
      bd.setUint64(8, blocksCount);
      aes.encryptBlock(counterBlock, 0, keystream, 0);
      final offset = blocksCount * 16;
      for (int j = 0; j < rem; j++) {
        data[offset + j] ^= keystream[j];
      }
    }
  }
}
