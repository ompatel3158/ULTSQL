import 'dart:typed_data';

class BlockCompressor {
  static const int _minMatch = 4;
  static const int _maxOffset = 65535;

  /// Compresses a block of data (e.g. 4KB slotted page) using an LZ4-style algorithm.
  static Uint8List compressBlock(Uint8List rawBytes) {
    final int inputSize = rawBytes.length;
    if (inputSize == 0) {
      final out = BytesBuilder();
      out.add([0, 0, 0, 0]);
      return out.toBytes();
    }

    final out = BytesBuilder();
    // Write uncompressed size (4 bytes, little endian)
    out.add([
      inputSize & 0xff,
      (inputSize >> 8) & 0xff,
      (inputSize >> 16) & 0xff,
      (inputSize >> 24) & 0xff,
    ]);

    final int hashBits = 12; // 4096 entries in hash table
    final Int32List hashTable = Int32List(1 << hashBits)
      ..fillRange(0, 1 << hashBits, -65536);

    int ip = 0;
    int anchor = 0;

    int hashPointers(int v) {
      return ((v * 2654435761) & 0xFFFFFFFF) >> (32 - hashBits);
    }

    int read32(int idx) {
      if (idx + 3 < inputSize) {
        return rawBytes[idx] |
            (rawBytes[idx + 1] << 8) |
            (rawBytes[idx + 2] << 16) |
            (rawBytes[idx + 3] << 24);
      }
      return 0;
    }

    while (ip < inputSize - _minMatch) {
      int sequence = read32(ip);
      int hash = hashPointers(sequence);
      int ref = hashTable[hash];
      hashTable[hash] = ip;

      if (ip - ref <= _maxOffset && ref >= 0 && read32(ref) == sequence) {
        // Match found
        int matchLen = _minMatch;
        while (ip + matchLen < inputSize &&
            ref + matchLen < inputSize &&
            rawBytes[ip + matchLen] == rawBytes[ref + matchLen]) {
          matchLen++;
        }

        // Output literals
        int litLen = ip - anchor;
        int tokenLit = litLen >= 15 ? 15 : litLen;
        int tokenMatch = (matchLen - _minMatch) >= 15
            ? 15
            : (matchLen - _minMatch);

        out.addByte((tokenLit << 4) | tokenMatch);

        if (tokenLit == 15) {
          int l = litLen - 15;
          while (l >= 255) {
            out.addByte(255);
            l -= 255;
          }
          out.addByte(l);
        }

        out.add(rawBytes.sublist(anchor, ip));

        // Output match offset (2 bytes, little endian)
        int offset = ip - ref;
        out.addByte(offset & 0xff);
        out.addByte((offset >> 8) & 0xff);

        if (tokenMatch == 15) {
          int m = (matchLen - _minMatch) - 15;
          while (m >= 255) {
            out.addByte(255);
            m -= 255;
          }
          out.addByte(m);
        }

        ip += matchLen;
        anchor = ip;
      } else {
        ip++;
      }
    }

    // Output remaining literals as the last sequence
    int litLen = inputSize - anchor;
    int tokenLit = litLen >= 15 ? 15 : litLen;
    out.addByte((tokenLit << 4) | 0);
    if (tokenLit == 15) {
      int l = litLen - 15;
      while (l >= 255) {
        out.addByte(255);
        l -= 255;
      }
      out.addByte(l);
    }
    out.add(rawBytes.sublist(anchor, inputSize));

    return out.toBytes();
  }

  /// Decompresses a block previously compressed by compressBlock.
  static Uint8List decompressBlock(Uint8List compressedBytes) {
    if (compressedBytes.length < 4) {
      return Uint8List(0);
    }

    int expectedSize =
        compressedBytes[0] |
        (compressedBytes[1] << 8) |
        (compressedBytes[2] << 16) |
        (compressedBytes[3] << 24);

    if (expectedSize == 0) return Uint8List(0);

    Uint8List out = Uint8List(expectedSize);
    int op = 0;
    int ip = 4;

    while (ip < compressedBytes.length) {
      int token = compressedBytes[ip++];
      int litLen = token >> 4;

      if (litLen == 15) {
        int l;
        do {
          if (ip >= compressedBytes.length)
            throw Exception("Corrupt data: unexpected end reading litLen");
          l = compressedBytes[ip++];
          litLen += l;
        } while (l == 255);
      }

      if (op + litLen > expectedSize || ip + litLen > compressedBytes.length) {
        throw Exception("Corrupt data: litLen overflow");
      }

      for (int i = 0; i < litLen; i++) {
        out[op++] = compressedBytes[ip++];
      }

      if (ip >= compressedBytes.length) break; // Last sequence has no match

      if (ip + 1 >= compressedBytes.length)
        throw Exception("Corrupt data: missing match offset");
      int offset = compressedBytes[ip] | (compressedBytes[ip + 1] << 8);
      ip += 2;

      if (offset == 0 || offset > op) {
        throw Exception("Corrupt data: invalid offset $offset at op=$op");
      }

      int matchLen = (token & 0xf);
      if (matchLen == 15) {
        int m;
        do {
          if (ip >= compressedBytes.length)
            throw Exception("Corrupt data: unexpected end reading matchLen");
          m = compressedBytes[ip++];
          matchLen += m;
        } while (m == 255);
      }
      matchLen += _minMatch;

      if (op + matchLen > expectedSize) {
        throw Exception(
          "Corrupt data: match overflow, op=$op, matchLen=$matchLen, expected=$expectedSize",
        );
      }

      int ref = op - offset;
      for (int i = 0; i < matchLen; i++) {
        out[op++] = out[ref++];
      }
    }

    if (op != expectedSize) {
      throw Exception(
        "Size mismatch after decompression: expected $expectedSize, got $op",
      );
    }

    return out;
  }
}
