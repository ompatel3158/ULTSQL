import 'dart:typed_data';

/// High-Performance CRC32 checksum calculation for database page validation and WAL integrity.
class Crc32 {
  static final List<int> _table = _generateTable();

  static List<int> _generateTable() {
    final table = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      int c = i;
      for (int k = 0; k < 8; k++) {
        if ((c & 1) != 0) {
          c = 0xedb88320 ^ (c >>> 1);
        } else {
          c = c >>> 1;
        }
      }
      table[i] = c;
    }
    return table;
  }

  /// Calculates the 32-bit IEEE 802.3 CRC checksum of a byte buffer.
  static int compute(Uint8List buffer, [int offset = 0, int? length]) {
    final end = offset + (length ?? (buffer.length - offset));
    int crc = 0xffffffff;
    for (int i = offset; i < end; i++) {
      final index = (crc ^ buffer[i]) & 0xff;
      crc = (crc >>> 8) ^ _table[index];
    }
    return (crc ^ 0xffffffff) >>> 0;
  }
}
