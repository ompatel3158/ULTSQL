import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/cache/page_cache.dart';
import 'package:ultsql/src/engine/storage/btree_index.dart';

void main() {
  const dbDir = 'test_data_btree';

  setUp(() async {
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  });

  tearDown(() async {
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('On-Disk B+ Tree Page Split & Search', () async {
    final cache = PageCache(maxCapacity: 10, pageSize: 4096);
    final indexPath = '$dbDir/test_index.idx';

    final btree = BTreeIndex(cache: cache, indexPath: indexPath);
    btree.initSync();

    // 1. Insert keys to trigger splits.
    // maxKeys is set to 50 in our btree_index.dart.
    // Inserting 150 items guarantees at least one leaf node split.
    for (int i = 1; i <= 150; i++) {
      // Insert key = i, pageId = i * 2, slotId = i
      btree.insertSync([i.toDouble()], i * 2, i);
    }

    // Flush cache to write splits to disk
    cache.flushAllSync();

    // 2. Search for the keys and verify correct pointers returned
    for (int i = 1; i <= 150; i++) {
      final ptr = btree.searchSync([i.toDouble()]);
      expect(ptr, isNotNull, reason: 'Key $i not found in B+ Tree index.');
      expect(ptr!.pageId, i * 2);
      expect(ptr.slotId, i);
    }

    // Search for a non-existent key
    final missing = btree.searchSync([999.0]);
    expect(missing, isNull);

    cache.closeAllSync();
  });
}
