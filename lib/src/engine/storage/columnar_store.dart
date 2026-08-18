import 'dart:typed_data';
import '../cache/page_cache.dart';
import '../executor/value.dart';
import 'block_compression.dart';

class CompressedColumnStore {
  final PageCache cache;
  final String tableName;
  final String dbDirectory;

  CompressedColumnStore({
    required this.cache,
    required this.tableName,
    required this.dbDirectory,
  });

  String getColumnFilePath(int colIndex) =>
      '$dbDirectory/$tableName.comp_col_$colIndex';

  // We can write a batch of DbValues into a single compressed page/block.
  void writeBatchSync(
    int colIndex,
    List<DbValue> values, {
    bool useRle = false,
    bool useDict = false,
    bool useBlockCompression = false,
  }) {
    final colFilePath = getColumnFilePath(colIndex);

    // First, let's try to compress the batch
    Uint8List compressedData;
    int encodingType =
        0; // 0 = plain, 1 = RLE, 2 = Dictionary, 3 = BlockCompression

    if (values.isEmpty) return;

    if (useBlockCompression) {
      encodingType = 3;
      final plainData = _encodePlain(values);
      compressedData = BlockCompressor.compressBlock(plainData);
    } else if (useRle) {
      encodingType = 1;
      compressedData = _encodeRle(values);
    } else if (useDict) {
      encodingType = 2;
      compressedData = _encodeDictionary(values);
    } else {
      encodingType = 0;
      compressedData = _encodePlain(values);
    }

    // Write compressed block to pager
    final pager = cache.getOrCreatePager(colFilePath);
    final pageCount = pager.getPageCountSync();

    final page = cache.pinPageSync(colFilePath, pageCount);
    final data = page.byteData;

    // Header: encodingType (1 byte), valuesCount (4 bytes), byteLength (4 bytes)
    data.setUint8(0, encodingType);
    data.setUint32(1, values.length);
    data.setUint32(5, compressedData.length);

    // Payload
    page.data.setRange(9, 9 + compressedData.length, compressedData);

    cache.unpinPageSync(colFilePath, pageCount, isDirty: true);
  }

  List<DbValue> readBatchSync(int colIndex, int pageId) {
    final colFilePath = getColumnFilePath(colIndex);
    final page = cache.pinPageSync(colFilePath, pageId);
    final data = page.byteData;

    final encodingType = data.getUint8(0);
    final valuesCount = data.getUint32(1);
    final byteLength = data.getUint32(5);

    final payload = page.data.sublist(9, 9 + byteLength);
    cache.unpinPageSync(colFilePath, pageId, isDirty: false);

    if (encodingType == 3) {
      final uncompressed = BlockCompressor.decompressBlock(payload);
      return _decodePlain(uncompressed, valuesCount);
    } else if (encodingType == 1) {
      return _decodeRle(payload, valuesCount);
    } else if (encodingType == 2) {
      return _decodeDictionary(payload, valuesCount);
    } else {
      return _decodePlain(payload, valuesCount);
    }
  }

  Uint8List _encodePlain(List<DbValue> values) {
    // Simply serialize them sequentially
    List<int> bytes = [];
    for (final v in values) {
      final b = v.toBytes();
      bytes.add(b.length);
      bytes.addAll(b);
    }
    return Uint8List.fromList(bytes);
  }

  List<DbValue> _decodePlain(Uint8List payload, int count) {
    List<DbValue> res = [];
    int offset = 0;
    final bd = ByteData.sublistView(payload);
    for (int i = 0; i < count; i++) {
      int len = payload[offset];
      offset += 1;
      res.add(DbValue.fromBytes(bd, offset, len));
      offset += len;
    }
    return res;
  }

  Uint8List _encodeRle(List<DbValue> values) {
    List<int> bytes = [];
    if (values.isEmpty) return Uint8List(0);

    DbValue current = values.first;
    int runLength = 1;

    void flush() {
      final b = current.toBytes();
      bytes.add(b.length);
      bytes.addAll(b);
      // add runLength as 4 bytes
      bytes.add((runLength >> 24) & 0xFF);
      bytes.add((runLength >> 16) & 0xFF);
      bytes.add((runLength >> 8) & 0xFF);
      bytes.add(runLength & 0xFF);
    }

    for (int i = 1; i < values.length; i++) {
      if (values[i] == current) {
        runLength++;
      } else {
        flush();
        current = values[i];
        runLength = 1;
      }
    }
    flush();

    return Uint8List.fromList(bytes);
  }

  List<DbValue> _decodeRle(Uint8List payload, int expectedCount) {
    List<DbValue> res = [];
    int offset = 0;
    final bd = ByteData.sublistView(payload);

    while (offset < payload.length && res.length < expectedCount) {
      int len = payload[offset];
      offset += 1;
      final val = DbValue.fromBytes(bd, offset, len);
      offset += len;

      int runLength = bd.getUint32(offset);
      offset += 4;

      for (int i = 0; i < runLength; i++) {
        res.add(val);
      }
    }
    return res;
  }

  Uint8List _encodeDictionary(List<DbValue> values) {
    Map<DbValue, int> dict = {};
    List<DbValue> keys = [];
    List<int> encoded = [];

    for (final v in values) {
      if (!dict.containsKey(v)) {
        dict[v] = keys.length;
        keys.add(v);
      }
      encoded.add(dict[v]!);
    }

    List<int> bytes = [];
    // Write dict size
    bytes.add((keys.length >> 8) & 0xFF);
    bytes.add(keys.length & 0xFF);

    // Write dict entries
    for (final k in keys) {
      final b = k.toBytes();
      bytes.add(b.length);
      bytes.addAll(b);
    }

    // Write encoded values (4 bytes each)
    for (final e in encoded) {
      bytes.add((e >> 24) & 0xFF);
      bytes.add((e >> 16) & 0xFF);
      bytes.add((e >> 8) & 0xFF);
      bytes.add(e & 0xFF);
    }

    return Uint8List.fromList(bytes);
  }

  List<DbValue> _decodeDictionary(Uint8List payload, int expectedCount) {
    List<DbValue> res = [];
    final bd = ByteData.sublistView(payload);

    int numKeys = bd.getUint16(0);
    int offset = 2;

    List<DbValue> dict = [];
    for (int i = 0; i < numKeys; i++) {
      int len = payload[offset];
      offset += 1;
      dict.add(DbValue.fromBytes(bd, offset, len));
      offset += len;
    }

    for (int i = 0; i < expectedCount; i++) {
      int idx = bd.getUint32(offset);
      offset += 4;
      res.add(dict[idx]);
    }

    return res;
  }
}
