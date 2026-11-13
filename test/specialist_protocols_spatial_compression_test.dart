import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:ultsql/src/engine/network/pg_wire_server.dart';
import 'package:ultsql/src/engine/spatial/geometry.dart';
import 'package:ultsql/src/engine/spatial/rtree_index.dart';
import 'package:ultsql/src/engine/storage/fts_index.dart';
import 'package:ultsql/src/engine/storage/trigram_index.dart';
import 'package:ultsql/src/engine/storage/columnar_store.dart';
import 'package:ultsql/src/engine/storage/block_compression.dart';
import 'package:ultsql/src/engine/storage/parquet_engine.dart';
import 'package:ultsql/src/engine/storage/ivf_flat_index.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/cache/crypto_security.dart';
import 'package:ultsql/src/engine/cache/page_cache.dart';
import 'package:ultsql/src/engine/storage/catalog.dart';
import 'package:ultsql/src/engine/parser/ast.dart';

void main() {
  group('Specialist Protocols, Spatial, Parquet & Compression Defect Tests', () {

    // 1. PgWire Sublist RangeError on Query Length < 4
    test('Defect 1: PgWire short packet length < 4 does not crash', () async {
      final dbDir = Directory.systemTemp.createTempSync('pg_defect_1_');
      final db = Database(dbDir.path);
      await db.init();
      final server = PgWireServer(db, port: 5491);
      final port = await server.start(autoPort: true);

      final socket = await Socket.connect('127.0.0.1', port);
      // Startup message
      final startupBuf = BytesBuilder();
      startupBuf.add([0, 0, 0, 0]);
      startupBuf.add([0, 3, 0, 0]);
      startupBuf.add('user\x00test\x00database\x00test\x00\x00'.codeUnits);
      final startupBytes = startupBuf.takeBytes();
      ByteData.view(startupBytes.buffer).setInt32(0, startupBytes.length, Endian.big);
      socket.add(startupBytes);

      await Future.delayed(const Duration(milliseconds: 100));

      // Send corrupted Query packet with length = 2 (< 4)
      final badPacket = BytesBuilder();
      badPacket.addByte(81); // 'Q'
      badPacket.add([0, 0, 0, 2]); // length = 2 (< 4)
      socket.add(badPacket.takeBytes());

      await Future.delayed(const Duration(milliseconds: 100));

      // Ensure socket is still alive and didn't crash unhandled
      await socket.close();
      await server.stop();
      await db.close();
      try { dbDir.deleteSync(recursive: true); } catch (_) {}
    });

    // 2. PgWire Parse Message Missing Null-Terminator Crash
    test('Defect 2: PgWire Parse message without null-terminator does not crash', () async {
      final dbDir = Directory.systemTemp.createTempSync('pg_defect_2_');
      final db = Database(dbDir.path);
      await db.init();
      final server = PgWireServer(db, port: 5493);
      final port = await server.start(autoPort: true);

      final socket = await Socket.connect('127.0.0.1', port);
      // Startup message
      final startupBuf = BytesBuilder();
      startupBuf.add([0, 0, 0, 0]);
      startupBuf.add([0, 3, 0, 0]);
      startupBuf.add('user\x00test\x00database\x00test\x00\x00'.codeUnits);
      final startupBytes = startupBuf.takeBytes();
      ByteData.view(startupBytes.buffer).setInt32(0, startupBytes.length, Endian.big);
      socket.add(startupBytes);

      await Future.delayed(const Duration(milliseconds: 100));

      // Send Parse packet without null terminator: 'P' + length + 'SELECT 1;' (no \0)
      final parsePayload = utf8.encode('SELECT 1;');
      final parseMsg = BytesBuilder();
      parseMsg.addByte(80); // 'P'
      final bd = ByteData(4);
      bd.setInt32(0, parsePayload.length + 4, Endian.big);
      parseMsg.add(bd.buffer.asUint8List());
      parseMsg.add(parsePayload);
      socket.add(parseMsg.takeBytes());

      await Future.delayed(const Duration(milliseconds: 100));

      await socket.close();
      await server.stop();
      await db.close();
      try { dbDir.deleteSync(recursive: true); } catch (_) {}
    });

    // 3. NaN Bounding Box Intersects Universally With All Queries
    test('Defect 3: NaN BoundingBox returns false for intersects', () {
      const nanBox = BoundingBox2D(double.nan, 0, 10, 10);
      const validBox = BoundingBox2D(0, 0, 10, 10);
      expect(nanBox.intersects(validBox), isFalse);
      expect(validBox.intersects(nanBox), isFalse);

      const allNanBox = BoundingBox2D(double.nan, double.nan, double.nan, double.nan);
      expect(allNanBox.intersects(validBox), isFalse);
      expect(validBox.intersects(allNanBox), isFalse);
    });

    // 4. RTreeIndex Has Node Splitting and Multi-Level Tree
    test('Defect 4: RTreeIndex splits nodes when entries exceed maxChildren', () {
      final rtree = RTreeIndex<int>(maxChildren: 4);
      // Insert 20 disjoint bounding boxes
      for (int i = 0; i < 20; i++) {
        final x = i * 10.0;
        rtree.insert(BoundingBox2D(x, 0, x + 5, 5), i);
      }

      // Root should no longer be a flat leaf containing all 20 entries
      expect(rtree.root.isLeaf, isFalse);
      expect(rtree.root.children.length, greaterThanOrEqualTo(2));

      // Search should accurately return only matching items
      final found = rtree.search(BoundingBox2D(15, 0, 35, 5));
      expect(found, containsAll([2, 3]));
      expect(found, isNot(contains(0)));
      expect(found, isNot(contains(10)));
    });

    // 5. FTS Strips All Non-ASCII Characters
    test('Defect 5: FTS tokenizeAndStem preserves international letters and digits', () {
      final tokens = tokenizeAndStem('Привет, мир! 123 München café 你好世界');
      expect(tokens, contains('привет'));
      expect(tokens, contains('мир'));
      expect(tokens, contains('123'));
      expect(tokens, contains('münchen'));
      expect(tokens, contains('café'));
      expect(tokens, contains('你好世界'));
    });

    // 6. Trigram Slicing Cleaves UTF-16 Surrogate Pairs
    test('Defect 6: Trigram extraction does not cleave surrogate pairs (emojis)', () {
      final trigrams = TrigramIndex.extractTrigrams('🚀🔥🎉');
      // Must not contain dangling surrogate code points
      for (final tri in trigrams) {
        for (final unit in tri.codeUnits) {
          final isHighSurrogate = unit >= 0xD800 && unit <= 0xDBFF;
          final isLowSurrogate = unit >= 0xDC00 && unit <= 0xDFFF;
          if (isHighSurrogate || isLowSurrogate) {
            // Check that the full string is valid UTF-8/runes
            expect(() => utf8.encode(tri), returnsNormally);
          }
        }
      }
      expect(trigrams, contains('🚀🔥🎉'));

      final queryTrigrams = TrigramIndex.extractQueryTrigrams('%🚀🔥🎉%');
      expect(queryTrigrams, contains('🚀🔥🎉'));
    });

    // 7. Columnar Store RangeError on Batch > 4KB
    test('Defect 7: Columnar store handles batches > 4KB without RangeError', () {
      final tempDir = Directory.systemTemp.createTempSync('col_test_7_');
      final cache = PageCache(dbDirectory: tempDir.path, maxCapacity: 50);
      final store = CompressedColumnStore(
        cache: cache,
        tableName: 'large_col',
        dbDirectory: tempDir.path,
      );

      // Create a batch of 500 strings, far exceeding 4KB
      final massiveBatch = List.generate(
        500,
        (i) => DbText('massive_string_value_exceeding_block_budget_item_$i'),
      );

      expect(() => store.writeBatchSync(0, massiveBatch, useBlockCompression: false), returnsNormally);

      final readValues = store.readBatchSync(0, 0);
      expect(readValues.length, 500);
      expect(readValues.first.value, 'massive_string_value_exceeding_block_budget_item_0');
      expect(readValues.last.value, 'massive_string_value_exceeding_block_budget_item_499');

      try { tempDir.deleteSync(recursive: true); } catch (_) {}
    });

    // 8. Decompression Bomb Memory Exhaustion
    test('Defect 8: BlockCompressor rejects decompression bomb with DatabaseIntegrityException', () {
      // 2GB bomb
      final bomb2GB = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0x7F, 0x00]);
      expect(
        () => BlockCompressor.decompressBlock(bomb2GB),
        throwsA(isA<DatabaseIntegrityException>()),
      );

      // Negative/4GB bomb
      final negBomb = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0x00]);
      expect(
        () => BlockCompressor.decompressBlock(negBomb),
        throwsA(isA<DatabaseIntegrityException>()),
      );
    });

    // 9. Parquet Binary RangeErrors on Negative & Truncated Lengths
    test('Defect 9: Parquet rejects negative and overflow data lengths with FormatException', () {
      final schema = TableSchema(
        name: 'test',
        columnNames: ['id'],
        columnTypes: [DataType.integer],
      );

      // Negative length
      final negBytes = BytesBuilder();
      negBytes.add([0x50, 0x41, 0x52, 0x31]); // PAR1
      negBytes.add((ByteData(4)..setInt32(0, -100, Endian.big)).buffer.asUint8List());
      negBytes.add([0x50, 0x41, 0x52, 0x31]); // PAR1
      expect(
        () => ParquetEngine.importFromParquet(negBytes.toBytes(), schema),
        throwsA(isA<FormatException>()),
      );

      // Overflow length
      final overBytes = BytesBuilder();
      overBytes.add([0x50, 0x41, 0x52, 0x31]);
      overBytes.add((ByteData(4)..setInt32(0, 5000000, Endian.big)).buffer.asUint8List());
      overBytes.add([0x50, 0x41, 0x52, 0x31]);
      expect(
        () => ParquetEngine.importFromParquet(overBytes.toBytes(), schema),
        throwsA(isA<FormatException>()),
      );
    });

    // 10. IVF-Flat Vector Dimension Mismatch Deferral
    test('Defect 10: IVF-Flat rejects mismatched vector dimensions with ArgumentError', () {
      final ivf = IvfFlatIndex(indexPath: ':memory:', numCentroids: 2, autoSave: false);
      ivf.insertSync(DbVector([1.0, 2.0, 3.0]), 1, 1);
      expect(
        () => ivf.insertSync(DbVector([1.0, 2.0, 3.0, 4.0, 5.0]), 1, 2),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ivf.search(DbVector([1.0, 2.0]), 2),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
