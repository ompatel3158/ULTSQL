import 'dart:typed_data';
import 'dart:convert';
import '../cache/page.dart';
import '../cache/page_cache.dart';
import '../executor/value.dart';
import 'catalog.dart';
import 'btree_index.dart';
import 'toast_manager.dart';
final Uint8List _sharedTempBuffer = Uint8List(65536);
final ByteData _sharedTempByteData = ByteData.sublistView(_sharedTempBuffer);

class RecordSerializer {
  static int serializeMvccRowDirect(Uint8List dest, List<DbValue> values, int xmin, int xmax, int rollPtr, [ToastManager? toastManager]) {
    final bd = identical(dest, _sharedTempBuffer) ? _sharedTempByteData : ByteData.sublistView(dest);
    // Write MVCC header
    bd.setUint32(0, xmin);
    bd.setUint32(4, xmax);
    bd.setUint32(8, rollPtr);

    // RowData starts at byte 12
    final count = values.length;
    bd.setUint16(12, count);

    int currentOffset = 14 + count * 2;
    for (int i = 0; i < count; i++) {
      // Write offset relative to rowData start (which is at byte 12)
      bd.setUint16(14 + i * 2, currentOffset - 12);

      final val = values[i];
      if (val is DbNull) {
        dest[currentOffset] = 0;
        currentOffset += 1;
      } else if (val is DbInt) {
        dest[currentOffset] = 1;
        final v = val.value;
        if (v >= -128 && v <= 127) {
          bd.setInt8(currentOffset + 1, v);
          currentOffset += 2;
        } else if (v >= -32768 && v <= 32767) {
          bd.setInt16(currentOffset + 1, v);
          currentOffset += 3;
        } else if (v >= -2147483648 && v <= 2147483647) {
          bd.setInt32(currentOffset + 1, v);
          currentOffset += 5;
        } else {
          bd.setInt64(currentOffset + 1, v);
          currentOffset += 9;
        }
      } else if (val is DbDouble) {
        dest[currentOffset] = 2;
        bd.setFloat64(currentOffset + 1, val.value);
        currentOffset += 9;
      } else if (val is DbText) {
        dest[currentOffset] = 3;
        final str = val.value;
        final strLen = str.length;
        if (strLen <= 1024) {
          dest.setRange(currentOffset + 1, currentOffset + 1 + strLen, str.codeUnits);
          currentOffset += 1 + strLen;
        } else {
          final bytes = utf8.encoder.convert(str);
          if (toastManager != null) {
            int startPage = toastManager.writeDataSync(bytes);
            dest[currentOffset] = 6;
            bd.setUint32(currentOffset + 1, startPage);
            bd.setUint32(currentOffset + 5, bytes.length);
            currentOffset += 9;
          } else {
            dest.setRange(currentOffset + 1, currentOffset + 1 + bytes.length, bytes);
            currentOffset += 1 + bytes.length;
          }
        }
      } else if (val is DbVector) {
        dest[currentOffset] = 4;
        final vLen = val.value.length;
        for (int j = 0; j < vLen; j++) {
          bd.setFloat64(currentOffset + 1 + j * 8, val.value[j]);
        }
        currentOffset += 1 + vLen * 8;
      } else if (val is DbJson) {
        dest[currentOffset] = 5;
        final jsonStr = json.encode(val.value);
        final strLen = jsonStr.length;
        bool isAscii = true;
        for (int j = 0; j < strLen; j++) {
          if (jsonStr.codeUnitAt(j) > 127) {
            isAscii = false;
            break;
          }
        }
        if (isAscii) {
          if (toastManager != null && strLen > 1024) {
            final bytes = Uint8List.fromList(jsonStr.codeUnits);
            int startPage = toastManager.writeDataSync(bytes);
            dest[currentOffset] = 7; // TOAST Json
            bd.setUint32(currentOffset + 1, startPage);
            bd.setUint32(currentOffset + 5, bytes.length);
            currentOffset += 9;
          } else {
            dest.setRange(currentOffset + 1, currentOffset + 1 + strLen, jsonStr.codeUnits);
            currentOffset += 1 + strLen;
          }
        } else {
          final bytes = utf8.encoder.convert(jsonStr);
          if (toastManager != null && bytes.length > 1024) {
            int startPage = toastManager.writeDataSync(bytes);
            dest[currentOffset] = 7; // TOAST Json
            bd.setUint32(currentOffset + 1, startPage);
            bd.setUint32(currentOffset + 5, bytes.length);
            currentOffset += 9;
          } else {
            dest.setRange(currentOffset + 1, currentOffset + 1 + bytes.length, bytes);
            currentOffset += 1 + bytes.length;
          }
        }
      }
    }
    return currentOffset;
  }

  static Uint8List serializeRow(List<DbValue> values) {
    final count = values.length;
    final headerSize = 2 + count * 2;

    final valueBytesList = values.map((v) => v.toBytes()).toList();
    final valuesSize = valueBytesList.fold<int>(0, (sum, bytes) => sum + bytes.length);

    final buffer = Uint8List(headerSize + valuesSize);
    final data = ByteData.sublistView(buffer);

    data.setUint16(0, count);
    int currentOffset = headerSize;
    for (int i = 0; i < count; i++) {
      data.setUint16(2 + i * 2, currentOffset);
      buffer.setAll(currentOffset, valueBytesList[i]);
      currentOffset += valueBytesList[i].length;
    }
    return buffer;
  }

  static List<DbValue> deserializeRow(Uint8List recordBytes, [int? expectedColumnCount, ToastManager? toastManager]) {
    final data = ByteData.sublistView(recordBytes);
    final count = data.getUint16(0);
    final list = <DbValue>[];
    for (int i = 0; i < count; i++) {
      final startOffset = data.getUint16(2 + i * 2);
      final endOffset = (i + 1 < count)
          ? data.getUint16(2 + (i + 1) * 2)
          : recordBytes.length;
      final len = endOffset - startOffset;
      if (len > 0) {
        final typeCode = data.getUint8(startOffset);
        if (typeCode == 6) {
          if (toastManager != null) {
            final startPage = data.getUint32(startOffset + 1);
            final totalSize = data.getUint32(startOffset + 5);
            final bytes = toastManager.readDataSync(startPage, totalSize);
            list.add(DbText(utf8.decode(bytes)));
          } else {
            list.add(DbNull());
          }
        } else if (typeCode == 7) {
          if (toastManager != null) {
            final startPage = data.getUint32(startOffset + 1);
            final totalSize = data.getUint32(startOffset + 5);
            final bytes = toastManager.readDataSync(startPage, totalSize);
            list.add(DbJson.fromBytes(bytes));
          } else {
            list.add(DbNull());
          }
        } else if (typeCode == 8) {
          list.add(DbNull());
        } else {
          list.add(DbValue.fromBytes(data, startOffset, len));
        }
      } else {
        list.add(DbNull());
      }
    }
    if (expectedColumnCount != null && list.length < expectedColumnCount) {
      while (list.length < expectedColumnCount) {
        list.add(DbNull());
      }
    }
    return list;
  }

  static DbValue deserializeCell(Uint8List recordBytes, int colIndex) {
    final data = ByteData.sublistView(recordBytes);
    final count = data.getUint16(0);
    if (colIndex >= count) return DbNull();

    final startOffset = data.getUint16(2 + colIndex * 2);
    final endOffset = (colIndex + 1 < count)
        ? data.getUint16(2 + (colIndex + 1) * 2)
        : recordBytes.length;

    final len = endOffset - startOffset;
    return DbValue.fromBytes(data, startOffset, len);
  }

  static DbValue deserializeCellFromView(ByteData data, int startOffsetInBytes, int recordLengthInBytes, int colIndex) {
    final count = data.getUint16(startOffsetInBytes);
    if (colIndex >= count) return DbNull();

    final startOffset = data.getUint16(startOffsetInBytes + 2 + colIndex * 2);
    final endOffset = (colIndex + 1 < count)
        ? data.getUint16(startOffsetInBytes + 2 + (colIndex + 1) * 2)
        : recordLengthInBytes;

    final len = endOffset - startOffset;
    return DbValue.fromBytes(data, startOffsetInBytes + startOffset, len);
  }
}

class SlottedPageHelper {
  // Page Layout:
  // Offset 0: pageType (1 byte, 1 = Row Data Page)
  // Offset 1: rowCount (2 bytes)
  // Offset 3: freeSpaceOffset (2 bytes, starts at 4096)
  // Slot array starts at 5: list of 4-byte slots (2 bytes offset, 2 bytes length)
  
  static const int headerSize = 5;

  static void initPage(Page page) {
    final data = page.byteData;
    data.setUint8(0, 1); // Page Type = 1
    data.setUint16(1, 0); // rowCount = 0
    data.setUint16(3, page.data.length); // freeSpaceOffset = pageSize (4096)
    page.rowCount = 0;
    page.freeSpaceOffset = page.data.length;
    page.markDirty();
  }

  static int getRowCount(Page page) {
    return page.rowCount ??= page.byteData.getUint16(1);
  }

  static int getFreeSpaceOffset(Page page) {
    return page.freeSpaceOffset ??= page.byteData.getUint16(3);
  }

  static bool insertRecord(Page page, Uint8List recordBytes) {
    final data = page.byteData;
    final rowCount = getRowCount(page);
    final freeSpaceOffset = getFreeSpaceOffset(page);
    final recordLen = recordBytes.length;

    final requiredSpace = recordLen + 4; // record + slot size (4 bytes)
    final currentSlotEnd = headerSize + rowCount * 4;

    if (freeSpaceOffset - currentSlotEnd < requiredSpace) {
      return false; // Page full
    }

    final newFreeSpaceOffset = freeSpaceOffset - recordLen;
    page.data.setAll(newFreeSpaceOffset, recordBytes);

    // Write slot info
    data.setUint16(currentSlotEnd, newFreeSpaceOffset);
    data.setUint16(currentSlotEnd + 2, recordLen);

    // Update headers
    final newRowCount = rowCount + 1;
    page.rowCount = newRowCount;
    page.freeSpaceOffset = newFreeSpaceOffset;
    data.setUint16(1, newRowCount);
    data.setUint16(3, newFreeSpaceOffset);
    page.markDirty();
    return true;
  }

  static bool insertRecordDirect(Page page, Uint8List src, int recordLen) {
    final data = page.byteData;
    final rowCount = getRowCount(page);
    final freeSpaceOffset = getFreeSpaceOffset(page);

    final requiredSpace = recordLen + 4; // record + slot size (4 bytes)
    final currentSlotEnd = headerSize + rowCount * 4;

    if (freeSpaceOffset - currentSlotEnd < requiredSpace) {
      return false; // Page full
    }

    final newFreeSpaceOffset = freeSpaceOffset - recordLen;
    page.data.setRange(newFreeSpaceOffset, newFreeSpaceOffset + recordLen, src, 0);

    // Write slot info
    data.setUint16(currentSlotEnd, newFreeSpaceOffset);
    data.setUint16(currentSlotEnd + 2, recordLen);

    // Update headers
    final newRowCount = rowCount + 1;
    page.rowCount = newRowCount;
    page.freeSpaceOffset = newFreeSpaceOffset;
    data.setUint16(1, newRowCount);
    data.setUint16(3, newFreeSpaceOffset);
    page.markDirty();
    return true;
  }

  static Uint8List? getRecord(Page page, int slotIndex) {
    final data = page.byteData;
    final rowCount = getRowCount(page);
    if (slotIndex >= rowCount) return null;

    final slotOffset = headerSize + slotIndex * 4;
    final offset = data.getUint16(slotOffset);
    final len = data.getUint16(slotOffset + 2);

    if (len == 0 || offset >= page.data.length) return null;
    return Uint8List.view(page.data.buffer, page.data.offsetInBytes + offset, len);
  }
}

class RowTableFile {
  final PageCache cache;
  final String tableName;
  final String dbDirectory;
  late final ToastManager toastManager;

  RowTableFile({
    required this.cache,
    required this.tableName,
    required this.dbDirectory,
  }) {
    toastManager = ToastManager(cache: cache, dbDirectory: dbDirectory, tableName: tableName);
  }

  String get filePath => '$dbDirectory/$tableName.db';

  Pager? _cachedPager;
  Pager get pager => _cachedPager ??= cache.getOrCreatePager(filePath);

  int? _cachedPageCount;
  int getPageCount() {
    if (_cachedPageCount == null) {
      _cachedPageCount = pager.getPageCountSync();
    }
    return _cachedPageCount!;
  }

  Page? _activeInsertPage;
  int _activeInsertPageId = -1;

  void flushActivePageSync() {
    if (_activeInsertPage != null) {
      cache.logPageToWalSync(filePath, _activeInsertPageId);
      cache.unpinPageSync(filePath, _activeInsertPageId, isDirty: true);
      _activeInsertPage = null;
      _activeInsertPageId = -1;
      if (!cache.isTransactionActive) {
        cache.flushWalSync();
      }
    }
    _cachedPageCount = null;
  }

  void resetActivePageSync() {
    if (_activeInsertPage != null) {
      cache.unpinPageSync(filePath, _activeInsertPageId, isDirty: false);
      _activeInsertPage = null;
      _activeInsertPageId = -1;
    }
    _cachedPageCount = null;
  }

  void insertRawRecordSync(Uint8List recordBytes) {
    if (_activeInsertPage != null) {
      cache.logPageBeforeModifySync(filePath, _activeInsertPageId);
      final success = SlottedPageHelper.insertRecordDirect(_activeInsertPage!, recordBytes, recordBytes.length);
      if (success) {
        _activeInsertPage!.isDirty = true;
        return;
      }
      flushActivePageSync();
    }

    final pgr = pager;
    int pageCount = getPageCount();

    if (pageCount == 0) {
      final page = cache.pinPageSync(filePath, 0);
      cache.logPageBeforeModifySync(filePath, 0);
      SlottedPageHelper.initPage(page);
      SlottedPageHelper.insertRecordDirect(page, recordBytes, recordBytes.length);
      page.isDirty = true;
      _activeInsertPage = page;
      _activeInsertPageId = 0;
      _cachedPageCount = 1;
      return;
    }

    final lastPageId = pageCount - 1;
    final lastPage = cache.pinPageSync(filePath, lastPageId);
    cache.logPageBeforeModifySync(filePath, lastPageId);
    final success = SlottedPageHelper.insertRecordDirect(lastPage, recordBytes, recordBytes.length);
    
    if (success) {
      lastPage.isDirty = true;
      _activeInsertPage = lastPage;
      _activeInsertPageId = lastPageId;
    } else {
      cache.unpinPageSync(filePath, lastPageId, isDirty: false);
      final newPageId = pageCount;
      final newPage = cache.pinPageSync(filePath, newPageId);
      cache.logPageBeforeModifySync(filePath, newPageId);
      SlottedPageHelper.initPage(newPage);
      SlottedPageHelper.insertRecordDirect(newPage, recordBytes, recordBytes.length);
      newPage.isDirty = true;
      _activeInsertPage = newPage;
      _activeInsertPageId = newPageId;
      _cachedPageCount = newPageId + 1;
    }
  }

  BTreePointer insertSync(List<DbValue> row, {int xmin = 0, int rollPtr = 0}) {
    final recordLen = RecordSerializer.serializeMvccRowDirect(_sharedTempBuffer, row, xmin, 0, rollPtr, toastManager);
    
    if (_activeInsertPage != null) {
      cache.logPageBeforeModifySync(filePath, _activeInsertPageId);
      final success = SlottedPageHelper.insertRecordDirect(_activeInsertPage!, _sharedTempBuffer, recordLen);
      if (success) {
        _activeInsertPage!.isDirty = true;
        final slotId = SlottedPageHelper.getRowCount(_activeInsertPage!) - 1;
        return BTreePointer(_activeInsertPageId, slotId);
      }
      flushActivePageSync();
    }

    final pgr = pager;
    int pageCount = getPageCount();

    if (pageCount == 0) {
      final page = cache.pinPageSync(filePath, 0);
      cache.logPageBeforeModifySync(filePath, 0);
      SlottedPageHelper.initPage(page);
      SlottedPageHelper.insertRecordDirect(page, _sharedTempBuffer, recordLen);
      page.isDirty = true;
      _activeInsertPage = page;
      _activeInsertPageId = 0;
      _cachedPageCount = 1;
      return BTreePointer(0, 0);
    }

    final lastPageId = pageCount - 1;
    final page = cache.pinPageSync(filePath, lastPageId);
    cache.logPageBeforeModifySync(filePath, lastPageId);
    final success = SlottedPageHelper.insertRecordDirect(page, _sharedTempBuffer, recordLen);
    
    if (success) {
      page.isDirty = true;
      final slotId = SlottedPageHelper.getRowCount(page) - 1;
      _activeInsertPage = page;
      _activeInsertPageId = lastPageId;
      return BTreePointer(lastPageId, slotId);
    } else {
      cache.unpinPageSync(filePath, lastPageId, isDirty: false);
      final newPageId = pageCount;
      final newPage = cache.pinPageSync(filePath, newPageId);
      SlottedPageHelper.initPage(newPage);
      SlottedPageHelper.insertRecordDirect(newPage, _sharedTempBuffer, recordLen);
      newPage.isDirty = true;
      final newSlotId = SlottedPageHelper.getRowCount(newPage) - 1;
      _activeInsertPage = newPage;
      _activeInsertPageId = newPageId;
      _cachedPageCount = newPageId + 1;
      return BTreePointer(newPageId, newSlotId);
    }
  }

  List<BTreePointer>? insertBatchSync(List<List<DbValue>> rows, {int xmin = 0, int rollPtr = 0, bool generatePointers = true}) {
    flushActivePageSync();
    final pager = cache.getOrCreatePager(filePath);
    int pageCount = pager.getPageCountSync();

    final pointers = generatePointers ? <BTreePointer>[] : null;
    if (rows.isEmpty) return pointers;

    int currentPageId = pageCount > 0 ? pageCount - 1 : 0;
    Page page = cache.pinPageSync(filePath, currentPageId);
    if (pageCount == 0) {
      SlottedPageHelper.initPage(page);
    }

    ByteData data = page.byteData;
    int rowCount = data.getUint16(1);
    int freeSpaceOffset = data.getUint16(3);
    bool pageDirty = pageCount == 0;

    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];
      final recordLen = RecordSerializer.serializeMvccRowDirect(_sharedTempBuffer, row, xmin, 0, rollPtr, toastManager);

      final requiredSpace = recordLen + 4;
      final currentSlotEnd = 5 + rowCount * 4;

      if (freeSpaceOffset - currentSlotEnd < requiredSpace) {
        data.setUint16(1, rowCount);
        data.setUint16(3, freeSpaceOffset);
        cache.unpinPageSync(filePath, currentPageId, isDirty: pageDirty);

        currentPageId++;
        page = cache.pinPageSync(filePath, currentPageId);
        SlottedPageHelper.initPage(page);
        data = page.byteData;
        rowCount = 0;
        freeSpaceOffset = 4096;
        pageDirty = true;
      }

      final newFreeSpaceOffset = freeSpaceOffset - recordLen;
      final pageBytes = page.data;
      pageBytes.setRange(newFreeSpaceOffset, newFreeSpaceOffset + recordLen, _sharedTempBuffer, 0);

      final slotOffset = 5 + rowCount * 4;
      data.setUint16(slotOffset, newFreeSpaceOffset);
      data.setUint16(slotOffset + 2, recordLen);

      if (generatePointers) {
        pointers!.add(BTreePointer(currentPageId, rowCount));
      }

      rowCount++;
      freeSpaceOffset = newFreeSpaceOffset;
      pageDirty = true;
    }

    // Save final page headers
    data.setUint16(1, rowCount);
    data.setUint16(3, freeSpaceOffset);
    cache.unpinPageSync(filePath, currentPageId, isDirty: pageDirty);
    return pointers;
  }


  void deleteRecordSync(int pageId, int slotId, int currentTxId) {
    final page = cache.pinPageSync(filePath, pageId);
    final recBytes = SlottedPageHelper.getRecord(page, slotId);
    if (recBytes != null) {
      try {
        final mvccRecord = MvccRecord.fromBytes(recBytes);
        final updatedRecord = MvccRecord(
          xmin: mvccRecord.xmin,
          xmax: currentTxId,
          rollPtr: mvccRecord.rollPtr,
          rowData: mvccRecord.rowData,
        );
        final slotOffset = SlottedPageHelper.headerSize + slotId * 4;
        final offset = page.byteData.getUint16(slotOffset);
        page.data.setAll(offset, updatedRecord.toBytes());
        cache.unpinPageSync(filePath, pageId, isDirty: true);
      } catch (_) {
        cache.unpinPageSync(filePath, pageId, isDirty: false);
      }
    } else {
      cache.unpinPageSync(filePath, pageId, isDirty: false);
    }
  }

  RowCursor scanSync({
    int currentTxId = 0,
    Set<int>? activeTxIds,
    MvccTransactionManager? txManager,
    List<int>? projectedColIndexes,
    int? expectedColumnCount,
    int? asOfTxId,
  }) {
    final pager = cache.getOrCreatePager(filePath);
    final pageCount = pager.getPageCountSync();
    final mgr = txManager ?? cache.mvccTxManager;
    final actIds = activeTxIds ?? const <int>{};
    return RowCursor(
      cache: cache,
      filePath: filePath,
      pageCount: pageCount,
      mgr: mgr,
      currentTxId: currentTxId,
      activeTxIds: actIds,
      projectedColIndexes: projectedColIndexes,
      tableFile: this,
      expectedColumnCount: expectedColumnCount,
      asOfTxId: asOfTxId,
    );
  }

  List<DbValue> _deserializePartialRow(Uint8List recordBytes, List<int> colIndexes, List<DbValue>? reuseList, [int? expectedColumnCount]) {
    if (colIndexes.isEmpty) return const <DbValue>[];
    final data = ByteData.sublistView(recordBytes);
    final count = data.getUint16(0);
    final targetCount = expectedColumnCount ?? count;
    List<DbValue> list;
    if (reuseList != null && reuseList.length == targetCount) {
      list = reuseList;
      list.fillRange(0, targetCount, DbNull());
    } else {
      list = List<DbValue>.filled(targetCount, DbNull());
    }
    for (final colIdx in colIndexes) {
      if (colIdx < count) {
        final startOffset = data.getUint16(2 + colIdx * 2);
        final endOffset = (colIdx + 1 < count)
            ? data.getUint16(2 + (colIdx + 1) * 2)
            : recordBytes.length;
        final len = endOffset - startOffset;
        if (len > 0) {
          final typeCode = data.getUint8(startOffset);
          if (typeCode == 6) {
            final startPage = data.getUint32(startOffset + 1);
            final totalSize = data.getUint32(startOffset + 5);
            final bytes = toastManager.readDataSync(startPage, totalSize);
            list[colIdx] = DbText(utf8.decode(bytes));
          } else if (typeCode == 7) {
            final startPage = data.getUint32(startOffset + 1);
            final totalSize = data.getUint32(startOffset + 5);
            final bytes = toastManager.readDataSync(startPage, totalSize);
            list[colIdx] = DbJson.fromBytes(bytes);
          } else if (typeCode == 8) {
            list[colIdx] = DbNull();
          } else {
            list[colIdx] = DbValue.fromBytes(data, startOffset, len);
          }
        }
      } else if (colIdx < targetCount) {
        list[colIdx] = DbNull();
      }
    }
    return list;
  }
}

class RowCursor extends Iterable<List<DbValue>> implements Iterator<List<DbValue>> {
  final PageCache cache;
  final String filePath;
  final int pageCount;
  final MvccTransactionManager mgr;
  final int currentTxId;
  final Set<int> activeTxIds;
  final List<int>? projectedColIndexes;
  final RowTableFile tableFile;
  final int? expectedColumnCount;

  final int? asOfTxId;

  int _currentPageId = 0;
  Page? _currentPage;
  int _currentRowCount = 0;
  int _currentSlot = 0;
  List<DbValue>? _current;
  List<DbValue>? _reusedRowList;

  RowCursor({
    required this.cache,
    required this.filePath,
    required this.pageCount,
    required this.mgr,
    required this.currentTxId,
    required this.activeTxIds,
    this.projectedColIndexes,
    required this.tableFile,
    this.expectedColumnCount,
    this.asOfTxId,
  });

  @override
  Iterator<List<DbValue>> get iterator => this;

  @override
  List<DbValue> get current => _current!;

  @override
  bool moveNext() {
    while (_currentPageId < pageCount) {
      if (_currentPage == null) {
        _currentPage = cache.pinPageSync(filePath, _currentPageId);
        _currentRowCount = SlottedPageHelper.getRowCount(_currentPage!);
        _currentSlot = 0;
      }

      while (_currentSlot < _currentRowCount) {
        final recBytes = SlottedPageHelper.getRecord(_currentPage!, _currentSlot++);
        if (recBytes != null) {
          if (recBytes.length >= 12) {
            final bd = ByteData.sublistView(recBytes);
            final xmin = bd.getUint32(0);
            final xmax = bd.getUint32(4);
            bool isVisible = false;
            if (asOfTxId != null) {
              isVisible = xmin <= asOfTxId! && (xmax == 0 || xmax > asOfTxId!);
            } else {
              isVisible = mgr.isVisible(xmin, xmax, currentTxId, activeTxIds);
            }
            // Clean production scan (no debug print per row)
            if (isVisible) {
              final rowData = Uint8List.view(recBytes.buffer, recBytes.offsetInBytes + 12, recBytes.length - 12);
              if (projectedColIndexes != null) {
                _reusedRowList = tableFile._deserializePartialRow(rowData, projectedColIndexes!, _reusedRowList, expectedColumnCount);
                _current = _reusedRowList;
              } else {
                _current = RecordSerializer.deserializeRow(rowData, expectedColumnCount, tableFile.toastManager);
              }
              return true;
            }
          } else {
            if (projectedColIndexes != null) {
              _reusedRowList = tableFile._deserializePartialRow(recBytes, projectedColIndexes!, _reusedRowList, expectedColumnCount);
              _current = _reusedRowList;
            } else {
              _current = RecordSerializer.deserializeRow(recBytes, expectedColumnCount, tableFile.toastManager);
            }
            return true;
          }
        }
      }

      cache.unpinPageSync(filePath, _currentPageId, isDirty: false);
      _currentPage = null;
      _currentPageId++;
    }
    _current = null;
    return false;
  }
}

class ColumnTableFile {
  final PageCache cache;
  final String tableName;
  final String dbDirectory;
  final TableSchema schema;

  ColumnTableFile({
    required this.cache,
    required this.tableName,
    required this.dbDirectory,
    required this.schema,
  });

  String getColumnFilePath(int colIndex) =>
      '$dbDirectory/$tableName.col_$colIndex';

  void insertSync(List<DbValue> row) {
    for (int i = 0; i < row.length; i++) {
      final val = row[i];
      final colFilePath = getColumnFilePath(i);
      final valBytes = val.toBytes();
      
      final pager = cache.getOrCreatePager(colFilePath);
      final pageCount = pager.getPageCountSync();

      if (pageCount == 0) {
        final page = cache.pinPageSync(colFilePath, 0);
        SlottedPageHelper.initPage(page);
        SlottedPageHelper.insertRecord(page, valBytes);
        cache.unpinPageSync(colFilePath, 0, isDirty: true);
        continue;
      }

      // Try inserting into last page first
      final lastPageId = pageCount - 1;
      final page = cache.pinPageSync(colFilePath, lastPageId);
      final success = SlottedPageHelper.insertRecord(page, valBytes);
      cache.unpinPageSync(colFilePath, lastPageId, isDirty: success);

      if (!success) {
        // Create new page
        final newPage = cache.pinPageSync(colFilePath, pageCount);
        SlottedPageHelper.initPage(newPage);
        SlottedPageHelper.insertRecord(newPage, valBytes);
        cache.unpinPageSync(colFilePath, pageCount, isDirty: true);
      }
    }
  }

  Iterable<DbValue> scanColumnSync(int colIndex) sync* {
    final colFilePath = getColumnFilePath(colIndex);
    final pager = cache.getOrCreatePager(colFilePath);
    final pageCount = pager.getPageCountSync();

    for (int i = 0; i < pageCount; i++) {
      final page = cache.pinPageSync(colFilePath, i);
      final rowCount = SlottedPageHelper.getRowCount(page);

      for (int slot = 0; slot < rowCount; slot++) {
        final valBytes = SlottedPageHelper.getRecord(page, slot);
        if (valBytes != null) {
          final data = ByteData.sublistView(valBytes);
          yield DbValue.fromBytes(data, 0, valBytes.length);
        }
      }
      cache.unpinPageSync(colFilePath, i, isDirty: false);
    }
  }
}
