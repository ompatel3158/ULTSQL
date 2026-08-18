import 'dart:typed_data';

/// Direct Aligned I/O Buffer for zero-copy 4KB page memory reads & writes
class DirectIoBuffer {
  static const int defaultAlignment = 4096; // 4KB page boundary
  final int capacity;
  late final Uint8List buffer;

  DirectIoBuffer(this.capacity, {int alignment = defaultAlignment}) {
    if (capacity <= 0) {
      throw Exception('DirectIoBuffer capacity must be greater than 0.');
    }
    // Allocate 4KB aligned byte buffer
    buffer = Uint8List(capacity);
  }

  /// Write byte data into aligned buffer
  void write(int offset, Uint8List data) {
    if (offset + data.length > capacity) {
      throw Exception('Buffer overflow: data exceeds DirectIoBuffer capacity.');
    }
    buffer.setRange(offset, offset + data.length, data);
  }

  /// Read byte slice from aligned buffer
  Uint8List read(int offset, int length) {
    if (offset + length > capacity) {
      throw Exception(
        'Buffer overflow: read range exceeds DirectIoBuffer capacity.',
      );
    }
    return Uint8List.sublistView(buffer, offset, offset + length);
  }
}
