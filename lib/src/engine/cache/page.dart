import 'dart:typed_data';

class Page {
  final int pageId;
  final Uint8List data;
  late final ByteData byteData;
  bool isDirty = false;
  int pinCount = 0;

  // Last access timestamp for LRU eviction
  int lastAccessTime = 0;

  // Track if this page was already logged in the current transaction
  int lastLoggedTxId = -1;

  // Cached header values for SlottedPageHelper performance
  int? rowCount;
  int? freeSpaceOffset;

  Page(this.pageId, {int pageSize = 4096}) : data = Uint8List(pageSize) {
    byteData = ByteData.sublistView(data);
  }

  void markDirty() {
    isDirty = true;
  }
}
