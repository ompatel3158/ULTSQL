import 'dart:io';
import 'dart:typed_data';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/storage/table_file.dart';
import 'package:ultsql/src/engine/storage/btree_index.dart';

void main() async {
  final tempDir = Directory.systemTemp.createTempSync('prof_idx_');
  final db = Database('${tempDir.path}/db', useWal: true, maxCapacity: 100000);
  await db.init();
  final it = Interpreter(db);
  await it.executeScript('CREATE TABLE users (id INT PRIMARY KEY, name TEXT, age INT, score DOUBLE);');

  final n = 10000;
  final batchRows = List<List<DbValue>>.generate(n, (j) {
    final i = j + 1;
    return [DbInt(i), DbText('User_$i'), DbInt(18 + (i % 62)), DbDouble((i % 1000) / 10.0)];
  });

  final ins = db.prepare('INSERT INTO users VALUES (?, ?, ?, ?);');
  ins.executeBatchSync(batchRows);

  final schema = db.catalog.getTableSchema('users')!;
  final rowTable = RowTableFile(
    cache: db.cache,
    tableName: schema.name,
    dbDirectory: db.directory,
  );
  final pageCount = db.cache.getActualPageCountSync(rowTable.filePath);
  final pager = rowTable.pager;

  void scan(int round) {
    final swScan = Stopwatch()..start();
    var intKeys = Int64List(n + 1024);
    var pageIds = Int32List(n + 1024);
    var slotIds = Int32List(n + 1024);
    int destIdx = 0;
    int minK = 0x7FFFFFFFFFFFFFFF;
    int maxK = -0x8000000000000000;

    for (int pageId = 0; pageId < pageCount; pageId++) {
      final cached = pager.getCachedPage(pageId)!;
      final byteData = cached.byteData;
      final pageData = cached.data;
      final rowCount = byteData.getUint16(1);

      for (int slotId = 0; slotId < rowCount; slotId++) {
        final slotOffset = 5 + slotId * 4;
        final recordOffset = byteData.getUint16(slotOffset);
        final recordLen = byteData.getUint16(slotOffset + 2);
        if (recordLen < 14 || recordOffset >= 4096) continue;

        final startOffset = byteData.getUint16(recordOffset + 18);
        final endOffset = byteData.getUint16(recordOffset + 20);
        final valLen = endOffset - startOffset - 1;
        if (valLen > 0) {
          final cellOffset = recordOffset + 12 + startOffset;
          if (pageData[cellOffset] == 1) {
            int k;
            if (valLen == 1) {
              final u = pageData[cellOffset + 1];
              k = u > 127 ? u - 256 : u;
            } else if (valLen == 2) {
              k = byteData.getInt16(cellOffset + 1);
            } else if (valLen == 4) {
              k = byteData.getInt32(cellOffset + 1);
            } else {
              k = byteData.getInt64(cellOffset + 1);
            }
            intKeys[destIdx] = k;
            pageIds[destIdx] = pageId;
            slotIds[destIdx] = slotId;
            destIdx++;
            if (k < minK) minK = k;
            if (k > maxK) maxK = k;
          }
        }
      }
    }
    swScan.stop();
    print('Round $round scan took: ${swScan.elapsedMicroseconds} us (${destIdx} rows)');
  }

  scan(1);
  scan(2);
  scan(3);

  await db.close();
  try { tempDir.deleteSync(recursive: true); } catch (_) {}
}
