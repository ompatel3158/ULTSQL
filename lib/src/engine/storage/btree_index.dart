import 'dart:typed_data';
import '../cache/page.dart';
import '../cache/page_cache.dart';
import '../executor/jit_compiler.dart';

class BTreePointer {
  final int pageId;
  final int slotId;
  BTreePointer(this.pageId, this.slotId);

  @override
  String toString() => 'Ptr($pageId, $slotId)';
}

class BTreeIndex {
  final PageCache cache;
  final String indexPath;
  final int keyColumns;
  int _rootPageId = 0;
  int _rightmostLeafPageId = 0;
  bool _lastInsertHadKey = false;
  Page? _cachedRootPage;
  final Map<int, Page> _cachedInteriorPages = {};

  int _cachedLeafPageId = -1;
  double _cachedLeafMinKey = 0.0;
  double _cachedLeafMaxKey = -1.0;

  int get rootPageId => _rootPageId;
  int get rightmostLeafPageId => _rightmostLeafPageId;

  /// Converts a string into a 53-bit integer hash represented as a double for B+ Tree indexing.
  /// Uses a djb2 variant with exact 64-bit integer bit shifts, ensuring 0 precision loss in IEEE 754 float64.
  static double stringToKey(String str) {
    if (str.isNotEmpty) {
      final c0 = str.codeUnitAt(0);
      if ((c0 >= 48 && c0 <= 57) || c0 == 45 || c0 == 43 || c0 == 46) {
        final parsed = double.tryParse(str);
        if (parsed != null) return parsed;
      }
    }
    int hash = 5381;
    for (int j = 0; j < str.length; j++) {
      hash = ((hash << 5) + hash + str.codeUnitAt(j)) & 0x1FFFFFFFFFFFFF;
    }
    return hash.toDouble();
  }

  bool isSafeForBatch(double minNewKey) {
    if (_rightmostLeafPageId == 0) {
      final page = cache.pinPageSync(indexPath, 0);
      final count = page.byteData.getUint16(2);
      cache.unpinPageSync(indexPath, 0, isDirty: false);
      if (count == 0) return true;
    }
    final page = cache.pinPageSync(indexPath, _rightmostLeafPageId);
    final count = page.byteData.getUint16(2);
    if (count == 0) {
      cache.unpinPageSync(indexPath, _rightmostLeafPageId, isDirty: false);
      return true;
    }
    final lastKey = page.byteData.getFloat64(4 + (count - 1) * keySize);
    cache.unpinPageSync(indexPath, _rightmostLeafPageId, isDirty: false);
    return minNewKey >= lastKey;
  }

  late final int maxKeys;
  late final int keySize;
  late final int pageIdOffset;
  late final int slotIdOffset;
  late final int siblingOffset;
  late final int rootOffset;
  Pager get pager => cache.getOrCreatePager(indexPath);

  BTreeIndex({
    required this.cache,
    required this.indexPath,
    this.keyColumns = 1,
  }) {
    keySize = keyColumns * 8;
    final calculatedMax = (4080) ~/ (keySize + 6);
    maxKeys = calculatedMax > 250 ? 250 : (calculatedMax < 2 ? 2 : calculatedMax);
    pageIdOffset = 4 + maxKeys * keySize;
    slotIdOffset = pageIdOffset + (maxKeys + 1) * 4;
    siblingOffset = slotIdOffset + maxKeys * 2;
    rootOffset = siblingOffset + 4;
  }

  void initSync() {
    if (_cachedRootPage != null) {
      cache.unpinPage(_cachedRootPage!, isDirty: false);
      _cachedRootPage = null;
    }
    for (final p in _cachedInteriorPages.values) {
      cache.unpinPage(p, isDirty: false);
    }
    _cachedInteriorPages.clear();
    final count = cache.getActualPageCountSync(indexPath);
    if (count == 0) {
      // Initialize root leaf page
      final page = cache.pinPageSync(indexPath, 0);
      final data = page.byteData;
      data.setUint8(0, 2); // pageType = 2
      data.setUint8(1, 1); // isLeaf = 1 (true)
      data.setUint16(2, 0); // keyCount = 0
      data.setInt32(siblingOffset, -1); // rightSiblingPageId = -1
      cache.unpinPage(page, isDirty: true);
      _rootPageId = 0;
      _rightmostLeafPageId = 0;
    } else {
      final page0 = cache.pinPageSync(indexPath, 0);
      final storedRoot = page0.byteData.getInt32(rootOffset);
      _rootPageId = storedRoot == 0 ? 0 : (storedRoot == -1 ? 0 : storedRoot);
      cache.unpinPage(page0, isDirty: false);
      _rightmostLeafPageId = _findRightmostLeafPageId();
    }
  }

  int _findRightmostLeafPageId() {
    int curr = _rootPageId;
    while (curr != -1) {
      final page = cache.pinPageSync(indexPath, curr);
      final isLeaf = page.byteData.getUint8(1) == 1;
      if (isLeaf) {
        cache.unpinPage(page, isDirty: false);
        return curr;
      }
      final keyCount = page.byteData.getUint16(2);
      if (keyCount == 0) {
        cache.unpinPage(page, isDirty: false);
        return curr;
      }
      final childPageId = page.byteData.getInt32(
        pageIdOffset + keyCount * 4,
      ); // rightmost child
      cache.unpinPage(page, isDirty: false);
      curr = childPageId;
    }
    return 0;
  }

  void _updateRootPageIdSync(int newRoot) {
    if (_cachedRootPage != null) {
      cache.unpinPage(_cachedRootPage!, isDirty: false);
      _cachedRootPage = null;
    }
    for (final p in _cachedInteriorPages.values) {
      cache.unpinPage(p, isDirty: false);
    }
    _cachedInteriorPages.clear();
    _rootPageId = newRoot;
    final p = pager;
    final page0 = p.getCachedPage(0) ?? cache.pinPagerPageSync(p, 0);
    page0.byteData.setInt32(rootOffset, newRoot);
    cache.unpinPage(page0, isDirty: true);
    _cachedRootPage = p.getCachedPage(newRoot);
  }

  int _compareKeys(dynamic a, dynamic b) {
    if (a is double) {
      final double bVal = b is double ? b : (b as List<double>)[0];
      return a.compareTo(bVal);
    }
    if (b is double) {
      final double aVal = a is double ? a : (a as List<double>)[0];
      return aVal.compareTo(b);
    }
    final List<double> aList = a as List<double>;
    final List<double> bList = b as List<double>;
    if (keyColumns == 1) {
      return aList[0].compareTo(bList[0]);
    }
    final len = aList.length < bList.length ? aList.length : bList.length;
    for (int i = 0; i < len; i++) {
      final cmp = aList[i].compareTo(bList[i]);
      if (cmp != 0) return cmp;
    }
    return aList.length.compareTo(bList.length);
  }

  int searchKey1PackedSync(double searchVal) {
    final p = pager;
    if (_cachedLeafPageId >= 0) {
      if (searchVal >= _cachedLeafMinKey && searchVal <= _cachedLeafMaxKey) {
        final leafId = _cachedLeafPageId;
        final page = p.getCachedPage(leafId) ?? cache.pinPagerPageSync(p, leafId);
        final bd = page.byteData;
        final keyCount = bd.getUint16(2);
        final idx = _binarySearchVal1Exact(bd, searchVal, keyCount);
        if (idx != -1) {
          final pageId = bd.getInt32(pageIdOffset + idx * 4);
          final slotId = bd.getUint16(slotIdOffset + idx * 2);
          return (pageId << 16) | slotId;
        }
      }
    }

    final rootPage = _cachedRootPage ??= (p.getCachedPage(_rootPageId) ?? cache.pinPagerPageSync(p, _rootPageId));
    Page currentPage = rootPage;
    int currentPageId = _rootPageId;

    while (true) {
      final bd = currentPage.byteData;
      final isLeaf = bd.getUint8(1) == 1;
      final keyCount = bd.getUint16(2);

      if (isLeaf) {
        final idx = _binarySearchVal1Exact(bd, searchVal, keyCount);
        if (idx != -1) {
          if (keyCount > 0) {
            _cachedLeafPageId = currentPageId;
            _cachedLeafMinKey = bd.getFloat64(4);
            _cachedLeafMaxKey = bd.getFloat64(4 + (keyCount - 1) * 8);
          }
          final pageId = bd.getInt32(pageIdOffset + idx * 4);
          final slotId = bd.getUint16(slotIdOffset + idx * 2);
          return (pageId << 16) | slotId;
        }

        final siblingId = bd.getInt32(siblingOffset);
        if (siblingId != -1) {
          final sibPage = p.getCachedPage(siblingId) ?? cache.pinPagerPageSync(p, siblingId);
          final sibBd = sibPage.byteData;
          final sibKeyCount = sibBd.getUint16(2);
          final sibIdx = _binarySearchVal1Exact(sibBd, searchVal, sibKeyCount);
          if (sibIdx != -1) {
            if (sibKeyCount > 0) {
              _cachedLeafPageId = siblingId;
              _cachedLeafMinKey = sibBd.getFloat64(4);
              _cachedLeafMaxKey = sibBd.getFloat64(4 + (sibKeyCount - 1) * 8);
            }
            final pageId = sibBd.getInt32(pageIdOffset + sibIdx * 4);
            final slotId = sibBd.getUint16(slotIdOffset + sibIdx * 2);
            return (pageId << 16) | slotId;
          }
        }

        return -1;
      } else {
        if (keyCount == 0) return -1;
        final idx = _binarySearchInternalVal1(bd, searchVal, keyCount);
        final childPageId = bd.getInt32(pageIdOffset + idx * 4);
        if (childPageId == currentPageId) return -1;

        currentPage = p.getCachedPage(childPageId) ?? cache.pinPagerPageSync(p, childPageId);
        currentPageId = childPageId;
      }
    }
  }

  BTreePointer? searchKey1Sync(double searchVal) {
    final packed = searchKey1PackedSync(searchVal);
    if (packed == -1) return null;
    return BTreePointer(packed >> 16, packed & 0xFFFF);
  }

  int _binarySearchVal1Exact(ByteData bd, double val, int count) {
    int low = 0;
    int high = count - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midVal = bd.getFloat64(4 + mid * 8);
      if (midVal == val) {
        return mid;
      } else if (midVal > val) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    return -1;
  }


  int _binarySearchInternalVal1(ByteData bd, double val, int count) {
    int low = 0;
    int high = count - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midVal = bd.getFloat64(4 + mid * 8);
      if (val >= midVal) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  BTreePointer? searchSync(dynamic key) {
    if (keyColumns == 1) {
      final double searchVal = key is double ? key : (key as List<double>)[0];
      return searchKey1Sync(searchVal);
    }

    int currentPageId = _rootPageId;
    while (true) {
      final page = cache.pinPageSync(indexPath, currentPageId);
      final isLeaf = page.byteData.getUint8(1) == 1;
      final keyCount = page.byteData.getUint16(2);

      if (isLeaf) {
        // Search inside leaf
        int idx = _binarySearch(page, key, keyCount);
        bool isMatch = false;
        if (idx < keyCount) {
          if (keyColumns == 1) {
            final double searchVal = key is double
                ? key
                : (key as List<double>)[0];
            isMatch = page.byteData.getFloat64(4 + idx * 8) == searchVal;
          } else {
            isMatch = _compareKeys(_getKey(page, idx), key) == 0;
          }
        }
        if (isMatch) {
          if (keyColumns == 1 && keyCount > 0) {
            _cachedLeafPageId = currentPageId;
            _cachedLeafMinKey = page.byteData.getFloat64(4);
            _cachedLeafMaxKey = page.byteData.getFloat64(
              4 + (keyCount - 1) * 8,
            );
          }
          final pageId = page.byteData.getInt32(pageIdOffset + idx * 4);
          final slotId = page.byteData.getUint16(slotIdOffset + idx * 2);
          cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
          return BTreePointer(pageId, slotId);
        }

        // If not found, check the immediate right sibling (needed for boundary keys)
        final siblingId = page.byteData.getInt32(siblingOffset);
        cache.unpinPageSync(indexPath, currentPageId, isDirty: false);

        if (siblingId != -1) {
          final sibPage = cache.pinPageSync(indexPath, siblingId);
          final sibKeyCount = sibPage.byteData.getUint16(2);
          int sibIdx = _binarySearch(sibPage, key, sibKeyCount);
          bool sibMatch = false;
          if (sibIdx < sibKeyCount) {
            if (keyColumns == 1) {
              final double searchVal = key is double
                  ? key
                  : (key as List<double>)[0];
              sibMatch =
                  sibPage.byteData.getFloat64(4 + sibIdx * 8) == searchVal;
            } else {
              sibMatch = _compareKeys(_getKey(sibPage, sibIdx), key) == 0;
            }
          }
          if (sibMatch) {
            if (keyColumns == 1 && sibKeyCount > 0) {
              _cachedLeafPageId = siblingId;
              _cachedLeafMinKey = sibPage.byteData.getFloat64(4);
              _cachedLeafMaxKey = sibPage.byteData.getFloat64(
                4 + (sibKeyCount - 1) * 8,
              );
            }
            final pageId = sibPage.byteData.getInt32(pageIdOffset + sibIdx * 4);
            final slotId = sibPage.byteData.getUint16(
              slotIdOffset + sibIdx * 2,
            );
            cache.unpinPageSync(indexPath, siblingId, isDirty: false);
            return BTreePointer(pageId, slotId);
          }
          cache.unpinPageSync(indexPath, siblingId, isDirty: false);
        }

        return null;
      } else {
        // Find child node to traverse
        int idx = _binarySearchInternal(page, key, keyCount);
        final childPageId = page.byteData.getInt32(pageIdOffset + idx * 4);
        cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
        currentPageId = childPageId;
      }
    }
  }

  int findLeafPageId(dynamic key) {
    final p = pager;
    if (key is List<double> && key.isEmpty) {
      int curr = _rootPageId;
      while (true) {
        final page = p.getCachedPage(curr) ?? cache.pinPagerPageSync(p, curr);
        final isLeaf = page.byteData.getUint8(1) == 1;
        if (isLeaf) {
          return curr;
        }
        final childPageId = page.byteData.getInt32(pageIdOffset);
        curr = childPageId;
      }
    }
    int currentPageId = _rootPageId;
    while (true) {
      final page = p.getCachedPage(currentPageId) ?? cache.pinPagerPageSync(p, currentPageId);
      final isLeaf = page.byteData.getUint8(1) == 1;
      if (isLeaf) {
        return currentPageId;
      }
      final keyCount = page.byteData.getUint16(2);
      int idx = _binarySearchInternal(page, key, keyCount);
      final childPageId = page.byteData.getInt32(pageIdOffset + idx * 4);
      currentPageId = childPageId;
    }
  }

  List<BTreePointer> searchRangeSync(List<double>? low, List<double>? high) {
    final results = <BTreePointer>[];
    int currentPageId = 0;
    final bool hasLow = low != null && low.isNotEmpty;
    final bool hasHigh = high != null && high.isNotEmpty;

    if (!hasLow) {
      // Find leftmost leaf page
      int curr = _rootPageId;
      while (true) {
        final page = cache.pinPageSync(indexPath, curr);
        final isLeaf = page.byteData.getUint8(1) == 1;
        if (isLeaf) {
          cache.unpinPageSync(indexPath, curr, isDirty: false);
          currentPageId = curr;
          break;
        }
        final childPageId = page.byteData.getInt32(
          pageIdOffset,
        ); // leftmost child
        cache.unpinPageSync(indexPath, curr, isDirty: false);
        curr = childPageId;
      }
    } else {
      currentPageId = findLeafPageId(low);
    }

    while (currentPageId != -1) {
      final page = cache.pinPageSync(indexPath, currentPageId);
      final keyCount = page.byteData.getUint16(2);

      for (int i = 0; i < keyCount; i++) {
        if (keyColumns == 1) {
          final val = page.byteData.getFloat64(4 + i * 8);
          if (hasLow && val < low[0]) continue;
          if (hasHigh && val > high[0]) {
            cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
            return results;
          }
        } else {
          final k = _getKey(page, i);
          if (hasLow && _compareKeys(k, low) < 0) continue;
          if (hasHigh && _compareKeys(k, high) > 0) {
            cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
            return results;
          }
        }
        final pageId = page.byteData.getInt32(pageIdOffset + i * 4);
        final slotId = page.byteData.getUint16(slotIdOffset + i * 2);
        results.add(BTreePointer(pageId, slotId));
      }

      final nextPageId = page.byteData.getInt32(
        siblingOffset,
      ); // rightSiblingPageId
      cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
      currentPageId = nextPageId;
    }

    return results;
  }

  static Uint64List _sharedRangeBuffer = Uint64List(32768);

  Uint64List searchRangePackedSync(List<double>? low, List<double>? high) {
    Uint64List buffer = _sharedRangeBuffer;
    int bufferLen = 0;
    int currentPageId = 0;
    final bool hasLow = low != null && low.isNotEmpty;
    final bool hasHigh = high != null && high.isNotEmpty;
    final p = pager;

    if (!hasLow) {
      int curr = _rootPageId;
      while (true) {
        final page = p.getCachedPage(curr) ?? cache.pinPagerPageSync(p, curr);
        final isLeaf = page.byteData.getUint8(1) == 1;
        if (isLeaf) {
          currentPageId = curr;
          break;
        }
        final childPageId = page.byteData.getInt32(pageIdOffset);
        curr = childPageId;
      }
    } else {
      currentPageId = findLeafPageId(low);
    }

    bool isFirstPage = true;
    final double? lowVal = hasLow && keyColumns == 1 ? low[0] : null;
    final double? highVal = hasHigh && keyColumns == 1 ? high[0] : null;
    final pIdOffset = pageIdOffset;
    final sIdOffset = slotIdOffset;

    while (currentPageId != -1) {
      final page = p.getCachedPage(currentPageId) ?? cache.pinPagerPageSync(p, currentPageId);
      final bd = page.byteData;
      final keyCount = bd.getUint16(2);

      int startIdx = 0;
      if (isFirstPage) {
        isFirstPage = false;
        if (lowVal != null) {
          int l = 0, r = keyCount - 1;
          while (l <= r) {
            final mid = (l + r) >> 1;
            final midVal = bd.getFloat64(4 + mid * 8);
            if (midVal >= lowVal) {
              startIdx = mid;
              r = mid - 1;
            } else {
              l = mid + 1;
            }
          }
          if (l > keyCount - 1 && startIdx == 0 && keyCount > 0 && bd.getFloat64(4 + (keyCount - 1) * 8) < lowVal) {
            startIdx = keyCount;
          }
        }
      }

      if (keyColumns == 1) {
        if (startIdx < keyCount) {
          int endIdx = keyCount;
          bool reachedEnd = false;
          if (highVal != null) {
            if (bd.getFloat64(4 + startIdx * 8) > highVal) {
              return Uint64List.sublistView(buffer, 0, bufferLen);
            }
            if (bd.getFloat64(4 + (keyCount - 1) * 8) > highVal) {
              reachedEnd = true;
              int l = startIdx, r = keyCount - 1;
              while (l <= r) {
                final mid = (l + r) >> 1;
                if (bd.getFloat64(4 + mid * 8) <= highVal) {
                  l = mid + 1;
                } else {
                  endIdx = mid;
                  r = mid - 1;
                }
              }
            }
          }
          final countToCopy = endIdx - startIdx;
          if (bufferLen + countToCopy > buffer.length) {
            int nextSize = buffer.length * 2;
            while (nextSize < bufferLen + countToCopy) nextSize *= 2;
            final next = Uint64List(nextSize);
            next.setRange(0, bufferLen, buffer);
            _sharedRangeBuffer = next;
            buffer = next;
          }
          for (int i = startIdx; i < endIdx; i++) {
            final pageId = bd.getInt32(pIdOffset + i * 4);
            final slotId = bd.getUint16(sIdOffset + i * 2);
            buffer[bufferLen++] = (pageId << 32) | slotId;
          }
          if (reachedEnd) {
            return Uint64List.sublistView(buffer, 0, bufferLen);
          }
        }
      } else {
        for (int i = startIdx; i < keyCount; i++) {
          final k = _getKey(page, i);
          if (hasLow && _compareKeys(k, low) < 0) continue;
          if (hasHigh && _compareKeys(k, high) > 0) {
            return Uint64List.sublistView(buffer, 0, bufferLen);
          }
          final pageId = bd.getInt32(pIdOffset + i * 4);
          final slotId = bd.getUint16(sIdOffset + i * 2);
          if (bufferLen == buffer.length) {
            final next = Uint64List(buffer.length * 2);
            next.setRange(0, bufferLen, buffer);
            buffer = next;
          }
          buffer[bufferLen++] = (pageId << 32) | slotId;
        }
      }

      final nextPageId = bd.getInt32(siblingOffset);
      currentPageId = nextPageId;
    }

    return Uint64List.sublistView(buffer, 0, bufferLen);
  }

  List<double> _getKeyFromByteData(ByteData bd, int index) {
    final offset = 4 + index * keySize;
    final list = <double>[];
    for (int i = 0; i < keyColumns; i++) {
      list.add(bd.getFloat64(offset + i * 8));
    }
    return list;
  }

  int countRangeSync(List<double>? low, List<double>? high) {
    final activeInterpreter = JitCompiler.activeInterpreter;
    if (activeInterpreter != null) {
      final fileName = indexPath
          .split('/')
          .last
          .split('\\')
          .last
          .replaceAll('.idx', '');
      String tableName = fileName;
      if (fileName.startsWith('idx_')) {
        final parts = fileName.split('_');
        if (parts.length >= 2) {
          tableName = parts[1];
        }
      }
      final tableStats = activeInterpreter.db.catalog.getOrCreateStats(
        tableName,
      );
      if (tableStats.rowCount > 0 && low == null && high == null) {
        return tableStats.rowCount;
      }
      if (tableStats.rowCount > 0 &&
          low != null &&
          high != null &&
          low.length == 1 &&
          high.length == 1 &&
          low[0] == high[0]) {
        for (final entry in tableStats.columnStats.entries) {
          final cs = entry.value;
          if (cs.min != null &&
              cs.max != null &&
              cs.min == low[0] &&
              cs.max == low[0]) {
            return tableStats.rowCount;
          }
        }
      }
    }

    final bool hasLow = low != null && low.isNotEmpty;
    final bool hasHigh = high != null && high.isNotEmpty;

    int count = 0;
    int currentPageId = 0;
    if (!hasLow) {
      // Find leftmost leaf page
      int curr = _rootPageId;
      while (true) {
        final page = cache.pinPageSync(indexPath, curr);
        final isLeaf = page.byteData.getUint8(1) == 1;
        if (isLeaf) {
          cache.unpinPageSync(indexPath, curr, isDirty: false);
          currentPageId = curr;
          break;
        }
        final childPageId = page.byteData.getInt32(
          pageIdOffset,
        ); // leftmost child
        cache.unpinPageSync(indexPath, curr, isDirty: false);
        curr = childPageId;
      }
    } else {
      currentPageId = findLeafPageId(low);
    }

    final pager = cache.getOrCreatePager(indexPath);
    final Uint8List tempBuf = Uint8List(4096);
    final ByteData tempBd = ByteData.sublistView(tempBuf);

    while (currentPageId != -1) {
      final pageInCache = cache.peekPageSync(indexPath, currentPageId);
      final ByteData bd;
      if (pageInCache != null) {
        bd = pageInCache.byteData;
      } else {
        pager.readPageSync(currentPageId, tempBuf);
        bd = tempBd;
      }

      final keyCount = bd.getUint16(2);

      if (keyCount > 0 && !hasLow && !hasHigh) {
        count += keyCount;
        currentPageId = bd.getInt32(siblingOffset);
        continue;
      }

      if (keyCount > 0 &&
          keyColumns == 1 &&
          hasLow &&
          hasHigh &&
          low[0] == high[0]) {
        final targetVal = low[0];
        final firstVal = bd.getFloat64(4);
        final lastVal = bd.getFloat64(4 + (keyCount - 1) * 8);
        if (firstVal == targetVal && lastVal == targetVal) {
          count += keyCount;
          currentPageId = bd.getInt32(siblingOffset);
          continue;
        }
      }

      for (int i = 0; i < keyCount; i++) {
        if (keyColumns == 1) {
          final val = bd.getFloat64(4 + i * 8);
          if (hasLow && val < low[0]) continue;
          if (hasHigh && val > high[0]) {
            return count;
          }
        } else {
          final k = _getKeyFromByteData(bd, i);
          if (hasLow && _compareKeys(k, low) < 0) continue;
          if (hasHigh && _compareKeys(k, high) > 0) {
            return count;
          }
        }
        count++;
      }

      currentPageId = bd.getInt32(siblingOffset);
    }

    return count;
  }

  bool insertSync(List<double> key, int recordPageId, int recordSlotId) {
    _cachedLeafPageId = -1;
    if (_rightmostLeafPageId != -1) {
      final rightmostPage = cache.pinPageSync(indexPath, _rightmostLeafPageId);
      final count = rightmostPage.byteData.getUint16(2);
      if (count > 0 && count < maxKeys) {
        final lastKey = _getKey(rightmostPage, count - 1);
        if (_compareKeys(key, lastKey) > 0) {
          // Fast Path: Sequential append
          _insertIntoLeaf(rightmostPage, key, recordPageId, recordSlotId);
          cache.unpinPageSync(indexPath, _rightmostLeafPageId, isDirty: true);
          return true; // Key did not exist
        }
      }
      cache.unpinPageSync(indexPath, _rightmostLeafPageId, isDirty: false);
    }

    _lastInsertHadKey = false;
    final rootPage = cache.pinPageSync(indexPath, _rootPageId);
    final isRootLeaf = rootPage.byteData.getUint8(1) == 1;

    if (isRootLeaf) {
      final count = rootPage.byteData.getUint16(2);
      final idx = _binarySearch(rootPage, key, count);
      if (idx < count && _compareKeys(_getKey(rootPage, idx), key) == 0) {
        _lastInsertHadKey = true;
      }

      final success = _insertIntoLeaf(
        rootPage,
        key,
        recordPageId,
        recordSlotId,
      );
      if (!success) {
        // Split root leaf
        final newPageId = cache.getActualPageCountSync(indexPath);
        final newPage = cache.pinPageSync(indexPath, newPageId);

        // Initialize new leaf
        newPage.byteData.setUint8(0, 2);
        newPage.byteData.setUint8(1, 1);
        newPage.byteData.setUint16(2, 0);
        newPage.byteData.setInt32(
          siblingOffset,
          rootPage.byteData.getInt32(siblingOffset),
        ); // Sibling pointer

        // Link sibling
        rootPage.byteData.setInt32(siblingOffset, newPageId);

        // Split keys
        final count = rootPage.byteData.getUint16(2);
        final mid = count ~/ 2;

        // Copy right half to new page
        int newIdx = 0;
        for (int i = mid; i < count; i++) {
          final k = _getKey(rootPage, i);
          final pId = rootPage.byteData.getInt32(pageIdOffset + i * 4);
          final sId = rootPage.byteData.getUint16(slotIdOffset + i * 2);
          _setKey(newPage, newIdx, k);
          newPage.byteData.setInt32(pageIdOffset + newIdx * 4, pId);
          newPage.byteData.setUint16(slotIdOffset + newIdx * 2, sId);
          newIdx++;
        }
        newPage.byteData.setUint16(2, newIdx);
        rootPage.byteData.setUint16(2, mid);

        // Insert key in correct leaf
        final splitKey = _getKey(newPage, 0);
        if (_compareKeys(key, splitKey) >= 0) {
          _insertIntoLeaf(newPage, key, recordPageId, recordSlotId);
        } else {
          _insertIntoLeaf(rootPage, key, recordPageId, recordSlotId);
        }

        // Create new root internal node
        final newRootPageId = cache.getActualPageCountSync(indexPath);
        final newRootPage = cache.pinPageSync(indexPath, newRootPageId);
        newRootPage.byteData.setUint8(0, 2);
        newRootPage.byteData.setUint8(1, 0); // isLeaf = 0
        newRootPage.byteData.setUint16(2, 1); // 1 key, 2 children
        _setKey(newRootPage, 0, splitKey);
        newRootPage.byteData.setInt32(pageIdOffset, _rootPageId);
        newRootPage.byteData.setInt32(pageIdOffset + 4, newPageId);

        cache.unpinPageSync(indexPath, _rootPageId, isDirty: true);
        cache.unpinPageSync(indexPath, newPageId, isDirty: true);
        cache.unpinPageSync(indexPath, newRootPageId, isDirty: true);

        _updateRootPageIdSync(newRootPageId);
        _rightmostLeafPageId = newPageId;
      } else {
        cache.unpinPageSync(indexPath, _rootPageId, isDirty: true);
      }
    } else {
      cache.unpinPageSync(indexPath, _rootPageId, isDirty: false);
      // Traverse down to insert
      _insertRecursiveSync(_rootPageId, key, recordPageId, recordSlotId);
    }

    return !_lastInsertHadKey;
  }

  BTreeSplitResult? _insertRecursiveSync(
    int pageId,
    List<double> key,
    int rPageId,
    int rSlotId,
  ) {
    final page = cache.pinPageSync(indexPath, pageId);
    final isLeaf = page.byteData.getUint8(1) == 1;
    final keyCount = page.byteData.getUint16(2);

    if (isLeaf) {
      final idx = _binarySearch(page, key, keyCount);
      if (idx < keyCount && _compareKeys(_getKey(page, idx), key) == 0) {
        _lastInsertHadKey = true;
      }
      final success = _insertIntoLeaf(page, key, rPageId, rSlotId);
      if (success) {
        cache.unpinPageSync(indexPath, pageId, isDirty: true);
        return null;
      }

      // Split leaf
      final newPageId = cache.getActualPageCountSync(indexPath);
      final newPage = cache.pinPageSync(indexPath, newPageId);

      newPage.byteData.setUint8(0, 2);
      newPage.byteData.setUint8(1, 1);
      newPage.byteData.setUint16(2, 0);
      newPage.byteData.setInt32(
        siblingOffset,
        page.byteData.getInt32(siblingOffset),
      );

      page.byteData.setInt32(siblingOffset, newPageId);

      final mid = keyCount ~/ 2;
      int newIdx = 0;
      for (int i = mid; i < keyCount; i++) {
        final k = _getKey(page, i);
        final pId = page.byteData.getInt32(pageIdOffset + i * 4);
        final sId = page.byteData.getUint16(slotIdOffset + i * 2);
        _setKey(newPage, newIdx, k);
        newPage.byteData.setInt32(pageIdOffset + newIdx * 4, pId);
        newPage.byteData.setUint16(slotIdOffset + newIdx * 2, sId);
        newIdx++;
      }
      newPage.byteData.setUint16(2, newIdx);
      page.byteData.setUint16(2, mid);

      final splitKey = _getKey(newPage, 0);
      if (_compareKeys(key, splitKey) >= 0) {
        _insertIntoLeaf(newPage, key, rPageId, rSlotId);
      } else {
        _insertIntoLeaf(page, key, rPageId, rSlotId);
      }

      cache.unpinPageSync(indexPath, pageId, isDirty: true);
      cache.unpinPageSync(indexPath, newPageId, isDirty: true);

      _rightmostLeafPageId = newPageId;
      return BTreeSplitResult(splitKey, newPageId);
    } else {
      int idx = _binarySearchInternal(page, key, keyCount);
      final childPageId = page.byteData.getInt32(pageIdOffset + idx * 4);
      cache.unpinPageSync(indexPath, pageId, isDirty: false);

      final splitResult = _insertRecursiveSync(
        childPageId,
        key,
        rPageId,
        rSlotId,
      );
      if (splitResult == null) return null;

      // Insert split result into this internal node
      final parentPage = cache.pinPageSync(indexPath, pageId);
      final success = _insertIntoInternal(
        parentPage,
        splitResult.key,
        splitResult.newPageId,
      );
      if (success) {
        cache.unpinPageSync(indexPath, pageId, isDirty: true);
        return null;
      }

      // Split internal node
      final newPageId = cache.getActualPageCountSync(indexPath);
      final newPage = cache.pinPageSync(indexPath, newPageId);

      newPage.byteData.setUint8(0, 2);
      newPage.byteData.setUint8(1, 0); // Internal
      newPage.byteData.setUint16(2, 0);

      final count = parentPage.byteData.getUint16(2);
      final mid = count ~/ 2;

      // Copy keys and child pointers to new internal node
      final promoteKey = _getKey(parentPage, mid);

      int newIdx = 0;
      // Copy child pointer after mid
      newPage.byteData.setInt32(
        pageIdOffset,
        parentPage.byteData.getInt32(pageIdOffset + (mid + 1) * 4),
      );

      for (int i = mid + 1; i < count; i++) {
        final k = _getKey(parentPage, i);
        final childId = parentPage.byteData.getInt32(
          pageIdOffset + (i + 1) * 4,
        );
        _setKey(newPage, newIdx, k);
        newPage.byteData.setInt32(pageIdOffset + (newIdx + 1) * 4, childId);
        newIdx++;
      }
      newPage.byteData.setUint16(2, newIdx);
      parentPage.byteData.setUint16(2, mid);

      if (_compareKeys(splitResult.key, promoteKey) >= 0) {
        _insertIntoInternal(newPage, splitResult.key, splitResult.newPageId);
      } else {
        _insertIntoInternal(parentPage, splitResult.key, splitResult.newPageId);
      }

      cache.unpinPageSync(indexPath, pageId, isDirty: true);
      cache.unpinPageSync(indexPath, newPageId, isDirty: true);

      // If we are splitting the root, create a new root
      if (pageId == _rootPageId) {
        final newRootPageId = cache.getActualPageCountSync(indexPath);
        final newRootPage = cache.pinPageSync(indexPath, newRootPageId);
        newRootPage.byteData.setUint8(0, 2);
        newRootPage.byteData.setUint8(1, 0);
        newRootPage.byteData.setUint16(2, 1);
        _setKey(newRootPage, 0, promoteKey);
        newRootPage.byteData.setInt32(pageIdOffset, pageId);
        newRootPage.byteData.setInt32(pageIdOffset + 4, newPageId);
        cache.unpinPageSync(indexPath, newRootPageId, isDirty: true);
        _updateRootPageIdSync(newRootPageId);
        return null;
      }

      return BTreeSplitResult(promoteKey, newPageId);
    }
  }

  bool _insertIntoLeaf(Page page, List<double> key, int rPageId, int rSlotId) {
    final count = page.byteData.getUint16(2);
    if (count >= maxKeys) return false; // Force split

    int idx = _binarySearch(page, key, count);

    // Shift keys and pointers right
    for (int i = count; i > idx; i--) {
      _setKey(page, i, _getKey(page, i - 1));
      page.byteData.setInt32(
        pageIdOffset + i * 4,
        page.byteData.getInt32(pageIdOffset + (i - 1) * 4),
      );
      page.byteData.setUint16(
        slotIdOffset + i * 2,
        page.byteData.getUint16(slotIdOffset + (i - 1) * 2),
      );
    }

    _setKey(page, idx, key);
    page.byteData.setInt32(pageIdOffset + idx * 4, rPageId);
    page.byteData.setUint16(slotIdOffset + idx * 2, rSlotId);

    page.byteData.setUint16(2, count + 1);
    page.markDirty();
    return true;
  }

  bool _insertIntoInternal(Page page, List<double> key, int childPageId) {
    final count = page.byteData.getUint16(2);
    if (count >= maxKeys) return false;

    int idx = _binarySearch(page, key, count);

    // Shift keys and pointers right
    for (int i = count; i > idx; i--) {
      _setKey(page, i, _getKey(page, i - 1));
      page.byteData.setInt32(
        pageIdOffset + (i + 1) * 4,
        page.byteData.getInt32(pageIdOffset + i * 4),
      );
    }

    _setKey(page, idx, key);
    page.byteData.setInt32(pageIdOffset + (idx + 1) * 4, childPageId);

    page.byteData.setUint16(2, count + 1);
    page.markDirty();
    return true;
  }

  int _binarySearch(Page page, List<double> key, int count) {
    if (keyColumns == 1) {
      final searchVal = key[0];
      int low = 0;
      int high = count - 1;
      while (low <= high) {
        int mid = (low + high) ~/ 2;
        final midVal = page.byteData.getFloat64(4 + mid * 8);
        if (midVal < searchVal) {
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }
      return low;
    }

    int low = 0;
    int high = count - 1;
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      List<double> midKey = _getKey(page, mid);
      if (_compareKeys(midKey, key) < 0) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  int _binarySearchInternal(Page page, dynamic key, int count) {
    if (key is List<double> && key.isEmpty) return 0;
    if (keyColumns == 1) {
      final double searchVal = key is double ? key : (key as List<double>)[0];
      int low = 0;
      int high = count - 1;
      while (low <= high) {
        int mid = (low + high) ~/ 2;
        final midVal = page.byteData.getFloat64(4 + mid * 8);
        if (midVal >= searchVal) {
          high = mid - 1;
        } else {
          low = mid + 1;
        }
      }
      return low;
    }

    int low = 0;
    int high = count - 1;
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      List<double> midKey = _getKey(page, mid);
      if (_compareKeys(midKey, key) >= 0) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    return low;
  }

  List<double> _getKey(Page page, int idx) {
    final list = <double>[];
    final start = 4 + idx * keySize;
    for (int i = 0; i < keyColumns; i++) {
      list.add(page.byteData.getFloat64(start + i * 8));
    }
    return list;
  }

  void _setKey(Page page, int idx, List<double> key) {
    final start = 4 + idx * keySize;
    for (int i = 0; i < keyColumns; i++) {
      final val = i < key.length ? key[i] : 0.0;
      page.byteData.setFloat64(start + i * 8, val);
    }
  }

  /// Builds a complete B+ Tree bottom-up in a single sequential sweep from sorted arrays.
  /// Eliminates 50/50 page splits, node rebalancing, and root-down traversals.
  void buildBottomUpSync(
    Float64List keys,
    Int32List pageIds,
    Int32List slotIds,
    int total, {
    Int32List? indices,
    int K = 1,
  }) {
    if (total <= 0) return;
    _cachedLeafPageId = -1;
    _cachedRootPage = null;
    _cachedInteriorPages.clear();

    // Evict any existing cached pages for this index to guarantee clean state
    cache.clearCachedPagesForFile(indexPath);
    final p = pager;

    final estimatedPages = (total ~/ maxKeys) + 64;
    if (estimatedPages <= cache.maxCapacity) {
      int nextPageId = 0;
      final leafPageIds = <int>[];
      final promotedKeys = <List<double>>[];
      final pIdOff = pageIdOffset;
      final sIdOff = slotIdOffset;
      final sibOff = siblingOffset;

      int idx = 0;
      while (idx < total) {
        final pageId = nextPageId++;
        leafPageIds.add(pageId);
        final page = cache.getOrCreateBlankPageSync(p, pageId);
        final bd = page.byteData;

        bd.setUint8(0, 2); // pageType = 2
        bd.setUint8(1, 1); // isLeaf = 1

        final count = (total - idx) < maxKeys ? (total - idx) : maxKeys;
        bd.setUint16(2, count);

        if (K == 1 && indices == null) {
          for (int i = 0; i < count; i++) {
            final realIdx = idx + i;
            bd.setFloat64(4 + i * 8, keys[realIdx]);
            bd.setInt32(pIdOff + i * 4, pageIds[realIdx]);
            bd.setUint16(sIdOff + i * 2, slotIds[realIdx]);
          }
        } else {
          for (int i = 0; i < count; i++) {
            final realIdx = indices != null ? indices[idx + i] : (idx + i);
            if (K == 1) {
              bd.setFloat64(4 + i * 8, keys[realIdx]);
            } else {
              for (int c = 0; c < K; c++) {
                bd.setFloat64(4 + i * keySize + c * 8, keys[realIdx * K + c]);
              }
            }
            bd.setInt32(pIdOff + i * 4, pageIds[realIdx]);
            bd.setUint16(sIdOff + i * 2, slotIds[realIdx]);
          }
        }

        idx += count;
        final nextSibling = idx < total ? nextPageId : -1;
        bd.setInt32(sibOff, nextSibling);

        if (leafPageIds.length > 1) {
          final firstItemIdx = indices != null ? indices[idx - count] : (idx - count);
          if (K == 1) {
            promotedKeys.add([keys[firstItemIdx]]);
          } else {
            promotedKeys.add(List<double>.generate(K, (c) => keys[firstItemIdx * K + c]));
          }
        }
      }

      _rightmostLeafPageId = leafPageIds.last;
      if (leafPageIds.length == 1) {
        p.updatePageCountAfterBulkBuildSync(nextPageId);
        _updateRootPageIdSync(leafPageIds[0]);
        return;
      }

      List<int> currentChildren = leafPageIds;
      List<List<double>> currentKeys = promotedKeys;

      while (currentChildren.length > 1) {
        final nextLevelChildren = <int>[];
        final nextLevelPromotedKeys = <List<double>>[];

        int keyIdx = 0;
        int childIdx = 0;
        final numKeys = currentKeys.length;

        while (childIdx < currentChildren.length) {
          final interiorPageId = nextPageId++;
          nextLevelChildren.add(interiorPageId);
          final page = cache.getOrCreateBlankPageSync(p, interiorPageId);
          final bd = page.byteData;

          bd.setUint8(0, 2); // pageType = 2
          bd.setUint8(1, 0); // isLeaf = 0 (interior)
          bd.setInt32(pIdOff, currentChildren[childIdx++]);

          int keysInPage = 0;
          while (keysInPage < maxKeys && keyIdx < numKeys && childIdx < currentChildren.length) {
            final k = currentKeys[keyIdx++];
            for (int c = 0; c < keySize ~/ 8 && c < k.length; c++) {
              bd.setFloat64(4 + keysInPage * keySize + c * 8, k[c]);
            }
            final nextChild = currentChildren[childIdx++];
            bd.setInt32(pIdOff + (keysInPage + 1) * 4, nextChild);
            keysInPage++;
          }

          bd.setUint16(2, keysInPage);
          if (childIdx < currentChildren.length && keyIdx < numKeys) {
            nextLevelPromotedKeys.add(currentKeys[keyIdx++]);
          }
        }

        currentChildren = nextLevelChildren;
        currentKeys = nextLevelPromotedKeys;
      }

      p.updatePageCountAfterBulkBuildSync(nextPageId);
      _rightmostLeafPageId = leafPageIds.isNotEmpty ? leafPageIds.last : 0;
      _updateRootPageIdSync(currentChildren[0]);
      return;
    }

    const int kPagesPerChunk = 256;
    final chunkBuffer = Uint8List(kPagesPerChunk * 4096);
    final chunkBd = ByteData.sublistView(chunkBuffer);
    int chunkStartPageId = 0;

    void flushChunkIfFull(int curPageId) {
      if (curPageId - chunkStartPageId == kPagesPerChunk - 1) {
        if (chunkStartPageId + kPagesPerChunk <= cache.maxCapacity) {
          for (int pg = 0; pg < kPagesPerChunk; pg++) {
            cache.populateCachedPageSync(
              indexPath,
              chunkStartPageId + pg,
              chunkBuffer,
              pg * 4096,
              true,
            );
          }
        } else {
          p.writePagesContiguousSync(chunkStartPageId, chunkBuffer);
        }
        chunkStartPageId += kPagesPerChunk;
        chunkBuffer.fillRange(0, chunkBuffer.length, 0);
      }
    }

    int nextPageId = 0;
    final leafPageIds = <int>[];
    final promotedKeys = <List<double>>[];

    int idx = 0;
    while (idx < total) {
      final pageId = nextPageId++;
      leafPageIds.add(pageId);
      final pageOffset = (pageId - chunkStartPageId) * 4096;

      chunkBd.setUint8(pageOffset, 2); // pageType = 2
      chunkBd.setUint8(pageOffset + 1, 1); // isLeaf = 1

      final count = (total - idx) < maxKeys ? (total - idx) : maxKeys;
      chunkBd.setUint16(pageOffset + 2, count);

      for (int i = 0; i < count; i++) {
        final realIdx = indices != null ? indices[idx + i] : (idx + i);
        if (K == 1) {
          final kVal = keys[realIdx];
          chunkBd.setFloat64(pageOffset + 4 + i * 8, kVal);
        } else {
          for (int c = 0; c < K; c++) {
            chunkBd.setFloat64(pageOffset + 4 + i * keySize + c * 8, keys[realIdx * K + c]);
          }
        }
        chunkBd.setInt32(pageOffset + pageIdOffset + i * 4, pageIds[realIdx]);
        chunkBd.setUint16(pageOffset + slotIdOffset + i * 2, slotIds[realIdx]);
      }

      idx += count;

      final nextSibling = idx < total ? nextPageId : -1;
      chunkBd.setInt32(pageOffset + siblingOffset, nextSibling);

      if (leafPageIds.length > 1) {
        final firstItemIdx = indices != null ? indices[idx - count] : (idx - count);
        if (K == 1) {
          promotedKeys.add([keys[firstItemIdx]]);
        } else {
          promotedKeys.add(List<double>.generate(K, (c) => keys[firstItemIdx * K + c]));
        }
      }

      flushChunkIfFull(pageId);
    }

    _rightmostLeafPageId = leafPageIds.last;

    if (leafPageIds.length == 1) {
      if (nextPageId > chunkStartPageId) {
        final remaining = nextPageId - chunkStartPageId;
        if (chunkStartPageId + remaining <= cache.maxCapacity) {
          for (int pg = 0; pg < remaining; pg++) {
            cache.populateCachedPageSync(
              indexPath,
              chunkStartPageId + pg,
              chunkBuffer,
              pg * 4096,
              true,
            );
          }
        } else {
          p.writePagesContiguousSync(
            chunkStartPageId,
            Uint8List.sublistView(chunkBuffer, 0, remaining * 4096),
          );
        }
      }
      p.updatePageCountAfterBulkBuildSync(nextPageId);
      _updateRootPageIdSync(leafPageIds[0]);
      return;
    }

    List<int> currentChildren = leafPageIds;
    List<List<double>> currentKeys = promotedKeys;

    while (currentChildren.length > 1) {
      final nextLevelChildren = <int>[];
      final nextLevelPromotedKeys = <List<double>>[];

      int keyIdx = 0;
      int childIdx = 0;
      final numKeys = currentKeys.length;

      while (childIdx < currentChildren.length) {
        final interiorPageId = nextPageId++;
        nextLevelChildren.add(interiorPageId);
        final pageOffset = (interiorPageId - chunkStartPageId) * 4096;

        chunkBd.setUint8(pageOffset, 2); // pageType = 2
        chunkBd.setUint8(pageOffset + 1, 0); // isLeaf = 0 (interior)

        chunkBd.setInt32(pageOffset + pageIdOffset, currentChildren[childIdx++]);

        int keysInPage = 0;
        while (keysInPage < maxKeys && keyIdx < numKeys && childIdx < currentChildren.length) {
          final k = currentKeys[keyIdx++];
          for (int c = 0; c < keySize ~/ 8 && c < k.length; c++) {
            chunkBd.setFloat64(pageOffset + 4 + keysInPage * keySize + c * 8, k[c]);
          }
          final nextChild = currentChildren[childIdx++];
          chunkBd.setInt32(pageOffset + pageIdOffset + (keysInPage + 1) * 4, nextChild);
          keysInPage++;
        }

        chunkBd.setUint16(pageOffset + 2, keysInPage);
        flushChunkIfFull(interiorPageId);

        if (childIdx < currentChildren.length && keyIdx < numKeys) {
          nextLevelPromotedKeys.add(currentKeys[keyIdx++]);
        }
      }

      currentChildren = nextLevelChildren;
      currentKeys = nextLevelPromotedKeys;
    }

    if (nextPageId > chunkStartPageId) {
      final remaining = nextPageId - chunkStartPageId;
      if (chunkStartPageId + remaining <= cache.maxCapacity) {
        for (int pg = 0; pg < remaining; pg++) {
          cache.populateCachedPageSync(
            indexPath,
            chunkStartPageId + pg,
            chunkBuffer,
            pg * 4096,
            true,
          );
        }
      } else {
        p.writePagesContiguousSync(
          chunkStartPageId,
          Uint8List.sublistView(chunkBuffer, 0, remaining * 4096),
        );
      }
    }
    p.updatePageCountAfterBulkBuildSync(nextPageId);
    _rightmostLeafPageId = leafPageIds.isNotEmpty ? leafPageIds.last : 0;
    _updateRootPageIdSync(currentChildren[0]);
  }

  void insertSortedBatchSync(
    Float64List keys,
    Int32List pageIds,
    Int32List slotIds,
    int K, {
    Int32List? indices,
  }) {
    if (pageIds.isEmpty) return;
    final total = pageIds.length;
    if (total >= 100) {
      final pageCount = cache.getActualPageCountSync(indexPath);
      if (pageCount <= 1) {
        bool isBrandNew = true;
        if (pageCount == 1) {
          final p0 = cache.pinPageSync(indexPath, 0);
          if (p0.byteData.getUint16(2) > 0) {
            isBrandNew = false;
          }
          cache.unpinPageSync(indexPath, 0, isDirty: false);
        }
        if (isBrandNew) {
          buildBottomUpSync(keys, pageIds, slotIds, total, indices: indices, K: K);
          return;
        }
      }
    }
    _cachedLeafPageId = -1;

    // Establish the rightmost path of page IDs from root to rightmost leaf.
    final path = <int>[];
    int curr = _rootPageId;
    while (curr != -1) {
      path.add(curr);
      final page = cache.pinPageSync(indexPath, curr);
      final isLeaf = page.byteData.getUint8(1) == 1;
      if (isLeaf) {
        cache.unpinPageSync(indexPath, curr, isDirty: false);
        break;
      }
      final keyCount = page.byteData.getUint16(2);
      final rightmostChild = page.byteData.getInt32(
        pageIdOffset + keyCount * 4,
      );
      cache.unpinPageSync(indexPath, curr, isDirty: false);
      curr = rightmostChild;
    }

    if (K == 1) {
      int leafPageId = path.last;
      Page page = cache.pinPageSync(indexPath, leafPageId);
      ByteData byteData = page.byteData;
      bool pageDirty = false;
      int count = byteData.getUint16(2);
      double lastKeyVal = count > 0
          ? byteData.getFloat64(4 + (count - 1) * 8)
          : -double.infinity;

      for (int i = 0; i < total; i++) {
        final idx = indices != null ? indices[i] : i;
        final keyVal = keys[idx];
        final rPageId = pageIds[idx];
        final rSlotId = slotIds[idx];

        if (count < maxKeys && keyVal >= lastKeyVal) {
          final slotOffset = count;
          byteData.setFloat64(4 + slotOffset * 8, keyVal);
          byteData.setInt32(pageIdOffset + slotOffset * 4, rPageId);
          byteData.setUint16(slotIdOffset + slotOffset * 2, rSlotId);
          count++;
          lastKeyVal = keyVal;
          pageDirty = true;
          continue;
        }

        // Before split/insert, write back count
        byteData.setUint16(2, count);
        cache.unpinPageSync(indexPath, leafPageId, isDirty: pageDirty);

        _bulkSplitInsert(path, keyVal, rPageId, rSlotId);

        leafPageId = path.last;
        page = cache.pinPageSync(indexPath, leafPageId);
        byteData = page.byteData;
        pageDirty = false;
        count = byteData.getUint16(2);
        lastKeyVal = count > 0
            ? byteData.getFloat64(4 + (count - 1) * 8)
            : -double.infinity;
      }

      byteData.setUint16(2, count);
      cache.unpinPageSync(indexPath, leafPageId, isDirty: pageDirty);
    } else {
      // Fallback for composite keys
      int leafPageId = path.last;
      Page page = cache.pinPageSync(indexPath, leafPageId);
      bool pageDirty = false;

      for (int i = 0; i < total; i++) {
        final idx = indices != null ? indices[i] : i;
        final key = List<double>.generate(K, (k) => keys[idx * K + k]);
        final rPageId = pageIds[idx];
        final rSlotId = slotIds[idx];

        int count = page.byteData.getUint16(2);

        if (count < maxKeys) {
          bool canAppend = true;
          if (count > 0) {
            final lastKey = _getKey(page, count - 1);
            if (_compareKeys(key, lastKey) < 0) {
              canAppend = false;
            }
          }
          if (canAppend) {
            _insertIntoLeaf(page, key, rPageId, rSlotId);
            pageDirty = true;
            continue;
          }
        }

        cache.unpinPageSync(indexPath, leafPageId, isDirty: pageDirty);
        insertSync(key, rPageId, rSlotId);

        // Rebuild path since insertSync might split dynamically
        path.clear();
        int traverseCurr = _rootPageId;
        while (traverseCurr != -1) {
          path.add(traverseCurr);
          final pageT = cache.pinPageSync(indexPath, traverseCurr);
          final isLeafT = pageT.byteData.getUint8(1) == 1;
          if (isLeafT) {
            cache.unpinPageSync(indexPath, traverseCurr, isDirty: false);
            break;
          }
          final keyCountT = pageT.byteData.getUint16(2);
          final rightmostChildT = pageT.byteData.getInt32(
            pageIdOffset + keyCountT * 4,
          );
          cache.unpinPageSync(indexPath, traverseCurr, isDirty: false);
          traverseCurr = rightmostChildT;
        }

        leafPageId = path.last;
        page = cache.pinPageSync(indexPath, leafPageId);
        pageDirty = false;
      }

      cache.unpinPageSync(indexPath, leafPageId, isDirty: pageDirty);
    }

    if (path.isNotEmpty) {
      _rightmostLeafPageId = path.last;
    }
  }

  void _bulkSplitInsert(
    List<int> path,
    double keyVal,
    int rPageId,
    int rSlotId,
  ) {
    final leafPageId = path.last;
    final leafPage = cache.pinPageSync(indexPath, leafPageId);

    final newLeafPageId = cache.getActualPageCountSync(indexPath);
    final newLeafPage = cache.pinPageSync(indexPath, newLeafPageId);

    newLeafPage.byteData.setUint8(0, 2);
    newLeafPage.byteData.setUint8(1, 1);
    newLeafPage.byteData.setUint16(2, 0);
    newLeafPage.byteData.setInt32(
      siblingOffset,
      leafPage.byteData.getInt32(siblingOffset),
    );

    leafPage.byteData.setInt32(siblingOffset, newLeafPageId);

    final count = leafPage.byteData.getUint16(2);
    final mid = count ~/ 2;
    int newIdx = 0;
    for (int i = mid; i < count; i++) {
      final k = leafPage.byteData.getFloat64(4 + i * 8);
      final pId = leafPage.byteData.getInt32(pageIdOffset + i * 4);
      final sId = leafPage.byteData.getUint16(slotIdOffset + i * 2);

      newLeafPage.byteData.setFloat64(4 + newIdx * 8, k);
      newLeafPage.byteData.setInt32(pageIdOffset + newIdx * 4, pId);
      newLeafPage.byteData.setUint16(slotIdOffset + newIdx * 2, sId);
      newIdx++;
    }
    newLeafPage.byteData.setUint16(2, newIdx);
    leafPage.byteData.setUint16(2, mid);

    final splitKey = newLeafPage.byteData.getFloat64(4);
    if (keyVal >= splitKey) {
      _insertIntoLeafDouble(newLeafPage, keyVal, rPageId, rSlotId);
    } else {
      _insertIntoLeafDouble(leafPage, keyVal, rPageId, rSlotId);
    }

    cache.unpinPageSync(indexPath, leafPageId, isDirty: true);
    cache.unpinPageSync(indexPath, newLeafPageId, isDirty: true);

    _rightmostLeafPageId = newLeafPageId;
    _propagateSplitUp(path, path.length - 1, splitKey, newLeafPageId);
  }

  void _insertIntoLeafDouble(
    Page page,
    double keyVal,
    int rPageId,
    int rSlotId,
  ) {
    final count = page.byteData.getUint16(2);
    int idx = 0;
    int low = 0;
    int high = count - 1;
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      final midVal = page.byteData.getFloat64(4 + mid * 8);
      if (midVal < keyVal) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    idx = low;

    for (int i = count; i > idx; i--) {
      page.byteData.setFloat64(
        4 + i * 8,
        page.byteData.getFloat64(4 + (i - 1) * 8),
      );
      page.byteData.setInt32(
        pageIdOffset + i * 4,
        page.byteData.getInt32(pageIdOffset + (i - 1) * 4),
      );
      page.byteData.setUint16(
        slotIdOffset + i * 2,
        page.byteData.getUint16(slotIdOffset + (i - 1) * 2),
      );
    }

    page.byteData.setFloat64(4 + idx * 8, keyVal);
    page.byteData.setInt32(pageIdOffset + idx * 4, rPageId);
    page.byteData.setUint16(slotIdOffset + idx * 2, rSlotId);
    page.byteData.setUint16(2, count + 1);
    page.markDirty();
  }

  void _propagateSplitUp(
    List<int> path,
    int pathIndex,
    double splitKey,
    int newPageId,
  ) {
    if (pathIndex == 0) {
      final rootPageId = path[0];
      final newRootPageId = cache.getActualPageCountSync(indexPath);
      final newRootPage = cache.pinPageSync(indexPath, newRootPageId);

      newRootPage.byteData.setUint8(0, 2);
      newRootPage.byteData.setUint8(1, 0);
      newRootPage.byteData.setUint16(2, 1);

      newRootPage.byteData.setFloat64(4, splitKey);
      newRootPage.byteData.setInt32(pageIdOffset, rootPageId);
      newRootPage.byteData.setInt32(pageIdOffset + 4, newPageId);

      cache.unpinPageSync(indexPath, newRootPageId, isDirty: true);

      _updateRootPageIdSync(newRootPageId);

      path.insert(0, newRootPageId);
      path[1] = newPageId;
      return;
    }

    final parentPageId = path[pathIndex - 1];
    final parentPage = cache.pinPageSync(indexPath, parentPageId);
    final count = parentPage.byteData.getUint16(2);

    if (count < maxKeys) {
      _insertIntoInternalDouble(parentPage, splitKey, newPageId);
      cache.unpinPageSync(indexPath, parentPageId, isDirty: true);
      path[pathIndex] = newPageId;
    } else {
      final newParentPageId = cache.getActualPageCountSync(indexPath);
      final newParentPage = cache.pinPageSync(indexPath, newParentPageId);

      newParentPage.byteData.setUint8(0, 2);
      newParentPage.byteData.setUint8(1, 0);
      newParentPage.byteData.setUint16(2, 0);

      final mid = count ~/ 2;
      final promoteKey = parentPage.byteData.getFloat64(4 + mid * 8);

      newParentPage.byteData.setInt32(
        pageIdOffset,
        parentPage.byteData.getInt32(pageIdOffset + (mid + 1) * 4),
      );

      int newIdx = 0;
      for (int i = mid + 1; i < count; i++) {
        final k = parentPage.byteData.getFloat64(4 + i * 8);
        final childId = parentPage.byteData.getInt32(
          pageIdOffset + (i + 1) * 4,
        );
        newParentPage.byteData.setFloat64(4 + newIdx * 8, k);
        newParentPage.byteData.setInt32(
          pageIdOffset + (newIdx + 1) * 4,
          childId,
        );
        newIdx++;
      }
      newParentPage.byteData.setUint16(2, newIdx);
      parentPage.byteData.setUint16(2, mid);

      if (splitKey >= promoteKey) {
        _insertIntoInternalDouble(newParentPage, splitKey, newPageId);
      } else {
        _insertIntoInternalDouble(parentPage, splitKey, newPageId);
      }

      cache.unpinPageSync(indexPath, parentPageId, isDirty: true);
      cache.unpinPageSync(indexPath, newParentPageId, isDirty: true);

      path[pathIndex] = newPageId;

      _propagateSplitUp(path, pathIndex - 1, promoteKey, newParentPageId);
    }
  }

  void _insertIntoInternalDouble(Page page, double keyVal, int childPageId) {
    final count = page.byteData.getUint16(2);
    int idx = 0;
    int low = 0;
    int high = count - 1;
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      final midVal = page.byteData.getFloat64(4 + mid * 8);
      if (midVal < keyVal) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    idx = low;

    for (int i = count; i > idx; i--) {
      page.byteData.setFloat64(
        4 + i * 8,
        page.byteData.getFloat64(4 + (i - 1) * 8),
      );
      page.byteData.setInt32(
        pageIdOffset + (i + 1) * 4,
        page.byteData.getInt32(pageIdOffset + i * 4),
      );
    }

    page.byteData.setFloat64(4 + idx * 8, keyVal);
    page.byteData.setInt32(pageIdOffset + (idx + 1) * 4, childPageId);
    page.byteData.setUint16(2, count + 1);
    page.markDirty();
  }
}

class BTreeSplitResult {
  final List<double> key;
  final int newPageId;
  BTreeSplitResult(this.key, this.newPageId);
}
