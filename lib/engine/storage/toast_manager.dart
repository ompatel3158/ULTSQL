import 'dart:typed_data';
import '../cache/page_cache.dart';

class ToastManager {
  final PageCache cache;
  final String dbDirectory;
  final String tableName;

  ToastManager({
    required this.cache,
    required this.dbDirectory,
    required this.tableName,
  });

  String get filePath => '$dbDirectory/${tableName}_toast.db';

  int writeDataSync(Uint8List data) {
    final pager = cache.getOrCreatePager(filePath);
    int pageCount = pager.getPageCountSync();
    
    int startPageId = pageCount;
    int remaining = data.length;
    int offset = 0;
    
    while (remaining > 0) {
      final page = cache.pinPageSync(filePath, pageCount);
      final bd = page.byteData;
      
      // Calculate how much we can fit in this page (4096 - 6 header bytes)
      int capacity = 4096 - 6;
      int chunkLen = remaining > capacity ? capacity : remaining;
      
      // Next page ID (4 bytes). 0xFFFFFFFF if last page.
      int nextPageId = (remaining > capacity) ? (pageCount + 1) : 0xFFFFFFFF;
      bd.setUint32(0, nextPageId);
      
      // Chunk length (2 bytes)
      bd.setUint16(4, chunkLen);
      
      // Payload
      page.data.setRange(6, 6 + chunkLen, data, offset);
      
      cache.unpinPageSync(filePath, pageCount, isDirty: true);
      
      offset += chunkLen;
      remaining -= chunkLen;
      pageCount++;
    }
    
    return startPageId;
  }

  Uint8List readDataSync(int startPageId, int totalSize) {
    final result = Uint8List(totalSize);
    int currentPageId = startPageId;
    int offset = 0;
    
    while (currentPageId != 0xFFFFFFFF && offset < totalSize) {
      final page = cache.pinPageSync(filePath, currentPageId);
      final bd = page.byteData;
      
      int nextPageId = bd.getUint32(0);
      int chunkLen = bd.getUint16(4);
      
      result.setRange(offset, offset + chunkLen, page.data.sublist(6, 6 + chunkLen));
      
      cache.unpinPageSync(filePath, currentPageId, isDirty: false);
      
      offset += chunkLen;
      currentPageId = nextPageId;
    }
    
    return result;
  }
}
