import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/cache/page_cache.dart';
import 'package:ultsql/src/engine/cache/crypto_security.dart';
import 'package:ultsql/src/engine/storage/table_file.dart';
import 'package:ultsql/src/engine/storage/btree_index.dart';
import 'package:ultsql/src/engine/storage/catalog.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void main() {
  group('Storage & Slotted Page Specialist Defect Fixes', () {
    const testDir = 'test_storage_specialist_db';

    void cleanup() {
      final dir = Directory(testDir);
      if (dir.existsSync()) {
        try {
          dir.deleteSync(recursive: true);
        } catch (_) {}
      }
    }

    setUp(cleanup);
    tearDown(cleanup);

    test('Defect 1: Wide record exceeding slotted page capacity throws DatabaseIntegrityException instead of silent drop', () {
      final dir = Directory(testDir)..createSync(recursive: true);
      final cache = PageCache(dbDirectory: testDir, maxCapacity: 100);
      final table = RowTableFile(cache: cache, tableName: 'wide_test', dbDirectory: testDir);

      // Create a wide record using raw bytes that exceed the 4096-byte page capacity (4091B max payload)
      final hugeBlob = Uint8List(5000);
      hugeBlob.fillRange(0, hugeBlob.length, 42);

      expect(
        () => table.insertSync([DbInt(1), DbBlob(hugeBlob)]),
        throwsA(isA<DatabaseIntegrityException>()),
      );
    });

    test('Defect 2: Point lookups resolve TOASTed columns (> 1024B) instead of returning NULL', () async {
      final db = Database(testDir);
      await db.init();
      final interpreter = Interpreter(db);
      await interpreter.executeScript('CREATE TABLE toast_point (id INT PRIMARY KEY, bio TEXT, metadata JSON);');

      final longBio = 'B' * 3000;
      final largeData = <String, dynamic>{'numbers': List.generate(200, (i) => i * 10)};

      final insertStmt = db.prepare('INSERT INTO toast_point VALUES (?, ?, ?);');
      insertStmt.executeSync([DbInt(1), DbText(longBio), DbJson(largeData)]);

      // Point lookup using prepared statement (triggers _executePointLookup)
      final stmt = db.prepare('SELECT id, bio, metadata FROM toast_point WHERE id = ?;');
      final res = stmt.executeSync([DbInt(1)]);

      expect(res.rows.length, 1);
      expect(res.rows[0][0].value, 1);
      expect(res.rows[0][1].value, longBio);
      final jsonVal = res.rows[0][2] as DbJson;
      expect((jsonVal.value['numbers'] as List).length, 200);

      // Also verify projection point lookup (selecting only TOASTed columns)
      final stmtProj = db.prepare('SELECT bio, metadata FROM toast_point WHERE id = ?;');
      final resProj = stmtProj.executeSync([DbInt(1)]);
      expect(resProj.rows.length, 1);
      expect(resProj.rows[0][0].value, longBio);
      expect(((resProj.rows[0][1] as DbJson).value['numbers'] as List).length, 200);

      await db.close();
    });

    test('Defect 3: Cyclic internal node pointer in BTreeIndex._findRightmostLeafPageId throws DatabaseIntegrityException', () {
      final dir = Directory(testDir)..createSync(recursive: true);
      final cache = PageCache(dbDirectory: testDir, maxCapacity: 100);
      final indexPath = '$testDir/corrupt_idx.db';
      final btree = BTreeIndex(cache: cache, indexPath: indexPath);

      // Initialize root page 0 as internal node pointing to itself (cycle: page 0 -> page 0)
      final page0 = cache.pinPageSync(indexPath, 0);
      final bd0 = page0.byteData;
      bd0.setUint8(0, 2); // pageType = 2 (index)
      bd0.setUint8(1, 0); // isLeaf = 0 (internal node!)
      bd0.setUint16(2, 1); // keyCount = 1
      bd0.setInt32(btree.rootOffset, 0); // rootPageId = 0
      // Rightmost child pointer: points back to 0
      bd0.setInt32(btree.pageIdOffset + 1 * 4, 0);
      cache.unpinPageSync(indexPath, 0, isDirty: true);

      // Calling initSync invokes _findRightmostLeafPageId, which should detect the cycle and throw
      expect(
        () => btree.initSync(),
        throwsA(
          isA<DatabaseIntegrityException>().having(
            (e) => e.message,
            'message',
            contains('BTree cycle or corrupted internal node pointer detected'),
          ),
        ),
      );
    });

    test('Defect 4: Leaf keyCount 0xFFFF & freeSpaceOffset 0xFFFF throw DatabaseIntegrityException instead of RangeError', () {
      final dir = Directory(testDir)..createSync(recursive: true);
      final cache = PageCache(dbDirectory: testDir, maxCapacity: 100);

      // 4A: Table file freeSpaceOffset = 0xFFFF
      final table = RowTableFile(cache: cache, tableName: 'corrupt_slots', dbDirectory: testDir);
      final page = cache.pinPageSync(table.filePath, 0);
      page.byteData.setUint8(0, 1); // Row data page
      page.byteData.setUint16(1, 0); // rowCount = 0
      page.byteData.setUint16(3, 0xFFFF); // Corrupted freeSpaceOffset
      cache.unpinPageSync(table.filePath, 0, isDirty: true);

      expect(
        () => SlottedPageHelper.getFreeSpaceOffset(page),
        throwsA(isA<DatabaseIntegrityException>()),
      );
      expect(
        () => table.insertSync([DbInt(1)]),
        throwsA(isA<DatabaseIntegrityException>()),
      );

      // 4B: BTree index keyCount = 0xFFFF
      final indexPath = '$testDir/corrupt_keys.db';
      final btree = BTreeIndex(cache: cache, indexPath: indexPath);
      btree.initSync();
      final rootPage = cache.pinPageSync(indexPath, 0);
      rootPage.byteData.setUint8(1, 1); // isLeaf = 1
      rootPage.byteData.setUint16(2, 0xFFFF); // Corrupted keyCount
      cache.unpinPageSync(indexPath, 0, isDirty: true);

      expect(
        () => btree.searchSync(10.0),
        throwsA(isA<DatabaseIntegrityException>()),
      );
    });

    test('Defect 5: Bit-flipped / corrupted catalog.db throws DatabaseIntegrityException and prevents wiping metadata', () async {
      final dir = Directory(testDir)..createSync(recursive: true);
      final catFile = File('$testDir/catalog.db');

      // Write corrupted / bit-flipped non-JSON content
      catFile.writeAsBytesSync([0xFF, 0xFE, 0x00, 0x01, 0xDE, 0xAD, 0xBE, 0xEF]);

      final catalog = Catalog(testDir);

      expect(
        () => catalog.load(),
        throwsA(
          isA<DatabaseIntegrityException>().having(
            (e) => e.message,
            'message',
            contains('Corrupted catalog metadata'),
          ),
        ),
      );

      // Verify that catalog.db was NOT wiped or overwritten
      expect(catFile.existsSync(), true);
      expect(catFile.readAsBytesSync().length, 8);
    });
  });
}
