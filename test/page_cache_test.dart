import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/cache/page_cache.dart';

void main() {
  const dbDir = 'test_data_cache';

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

  test('Page Cache LRU Eviction & Pinning Limit', () async {
    // 1. Create a cache with max capacity of 2 pages
    final cache = PageCache(maxCapacity: 2, pageSize: 4096);
    final filePath = '$dbDir/test_cache.db';

    // 2. Pin page 0 and page 1
    final p0 = cache.pinPageSync(filePath, 0);
    final p1 = cache.pinPageSync(filePath, 1);

    expect(p0.pageId, 0);
    expect(p1.pageId, 1);

    // Modify page 0 and mark dirty
    p0.byteData.setInt32(0, 999);
    cache.unpinPageSync(filePath, 0, isDirty: true);

    // Unpin page 1 (not dirty)
    cache.unpinPageSync(filePath, 1, isDirty: false);

    // 3. Pin page 2 (forces eviction of page 1 since page 0 is pinned or page 1 is oldest unpinned)
    // Currently, page 0 pinCount was decremented to 0 by unpinPage! Page 1 pinCount is also 0.
    // Page 0 was accessed at time 1. Page 1 was accessed at time 2.
    // So Page 0 is the oldest unpinned page and should be evicted!
    // But page 0 is dirty! Eviction must write it to disk.
    final p2 = cache.pinPageSync(filePath, 2);
    expect(p2.pageId, 2);

    // Page 0 should have been evicted and written to disk
    // Let's verify by checking if page 0's data is persisted on disk
    final pager = Pager(filePath, pageSize: 4096);
    pager.openSync();
    
    final pageCount = pager.getPageCountSync();
    expect(pageCount, greaterThanOrEqualTo(1)); // Page 0 written

    final diskBuffer = Uint8List(4096);
    pager.readPageSync(0, diskBuffer);
    final diskData = ByteData.sublistView(diskBuffer);
    expect(diskData.getInt32(0), 999); // Verified write on eviction!

    pager.closeSync();
    cache.closeAllSync();
  });
}
