import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/storage/block_compression.dart';

void main() {
  group('BlockCompressor', () {
    test('compresses and decompresses correctly with high compression ratio', () {
      // Generate a 4KB array with repetitive data
      final original = Uint8List(4096);
      int offset = 0;
      final pattern = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      
      while (offset < 4096) {
        for (int i = 0; i < pattern.length && offset < 4096; i++) {
          original[offset++] = pattern[i];
        }
      }

      // Compress
      final compressed = BlockCompressor.compressBlock(original);
      
      // Calculate compression ratio
      double ratio = original.length / compressed.length;
      print('Original size: ${original.length}');
      print('Compressed size: ${compressed.length}');
      print('Compression ratio: ${ratio.toStringAsFixed(2)}x');

      // Verify compression ratio > 2.5x
      expect(ratio > 2.5, isTrue, reason: 'Compression ratio should be > 2.5x');

      // Decompress
      final decompressed = BlockCompressor.decompressBlock(compressed);

      // Verify decompressed matches original exactly
      expect(decompressed.length, equals(original.length));
      for (int i = 0; i < original.length; i++) {
        expect(decompressed[i], equals(original[i]));
      }
    });

    test('compresses and decompresses empty block', () {
      final original = Uint8List(0);
      final compressed = BlockCompressor.compressBlock(original);
      final decompressed = BlockCompressor.decompressBlock(compressed);
      
      expect(decompressed.length, equals(0));
    });

    test('compresses and decompresses non-repetitive data correctly', () {
      final original = Uint8List(100);
      for (int i = 0; i < 100; i++) {
        original[i] = i;
      }
      final compressed = BlockCompressor.compressBlock(original);
      final decompressed = BlockCompressor.decompressBlock(compressed);
      
      expect(decompressed.length, equals(original.length));
      for (int i = 0; i < original.length; i++) {
        expect(decompressed[i], equals(original[i]));
      }
    });
  });
}
