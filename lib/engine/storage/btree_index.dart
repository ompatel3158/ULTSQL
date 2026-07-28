import 'dart:typed_data';
import '../cache/page.dart';
import '../cache/page_cache.dart';

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

  int? _cachedLeafPageId;
  double? _cachedLeafMinKey;
  double? _cachedLeafMaxKey;

  int get rootPageId => _rootPageId;
  int get rightmostLeafPageId => _rightmostLeafPageId;

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

  BTreeIndex({required this.cache, required this.indexPath, this.keyColumns = 1}) {
    keySize = keyColumns * 8;
    maxKeys = 50; // Cap at 50 to easily fit composite keys in 4KB page
    pageIdOffset = 4 + maxKeys * keySize;
    slotIdOffset = pageIdOffset + maxKeys * 4;
    siblingOffset = slotIdOffset + maxKeys * 2;
    rootOffset = siblingOffset + 4;
  }

  void initSync() {
    final pager = cache.getOrCreatePager(indexPath);
    final count = pager.getPageCountSync();
    if (count == 0) {
      // Initialize root leaf page
      final page = cache.pinPageSync(indexPath, 0);
      final data = page.byteData;
      data.setUint8(0, 2); // pageType = 2
      data.setUint8(1, 1); // isLeaf = 1 (true)
      data.setUint16(2, 0); // keyCount = 0
      data.setInt32(siblingOffset, -1); // rightSiblingPageId = -1
      cache.unpinPageSync(indexPath, 0, isDirty: true);
      _rootPageId = 0;
      _rightmostLeafPageId = 0;
    } else {
      final page0 = cache.pinPageSync(indexPath, 0);
      final storedRoot = page0.byteData.getInt32(rootOffset);
      _rootPageId = storedRoot == 0 ? 0 : (storedRoot == -1 ? 0 : storedRoot);
      cache.unpinPageSync(indexPath, 0, isDirty: false);
      _rightmostLeafPageId = _findRightmostLeafPageId();
    }
  }

  int _findRightmostLeafPageId() {
    int curr = _rootPageId;
    while (curr != -1) {
      final page = cache.pinPageSync(indexPath, curr);
      final isLeaf = page.byteData.getUint8(1) == 1;
      if (isLeaf) {
        // Follow sibling pointers to the end
        int sibling = page.byteData.getInt32(siblingOffset);
        int prev = curr;
        cache.unpinPageSync(indexPath, curr, isDirty: false);
        while (sibling != -1) {
          prev = sibling;
          final sibPage = cache.pinPageSync(indexPath, sibling);
          sibling = sibPage.byteData.getInt32(siblingOffset);
          cache.unpinPageSync(indexPath, prev, isDirty: false);
        }
        return prev;
      }
      final keyCount = page.byteData.getUint16(2);
      if (keyCount == 0) {
        cache.unpinPageSync(indexPath, curr, isDirty: false);
        return curr;
      }
      final childPageId = page.byteData.getInt32(pageIdOffset + keyCount * 4); // rightmost child
      cache.unpinPageSync(indexPath, curr, isDirty: false);
      curr = childPageId;
    }
    return 0;
  }

  void _updateRootPageIdSync(int newRoot) {
    _rootPageId = newRoot;
    final page0 = cache.pinPageSync(indexPath, 0);
    page0.byteData.setInt32(rootOffset, newRoot);
    cache.unpinPageSync(indexPath, 0, isDirty: true);
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

  BTreePointer? searchSync(dynamic key) {
    if (keyColumns == 1 && _cachedLeafPageId != null) {
      final double searchVal = key is double ? key : (key as List<double>)[0];
      if (searchVal >= _cachedLeafMinKey! && searchVal <= _cachedLeafMaxKey!) {
        final page = cache.pinPageSync(indexPath, _cachedLeafPageId!);
        final keyCount = page.byteData.getUint16(2);
        final List<double> keyList = key is List<double> ? key : [searchVal];
        int idx = _binarySearch(page, keyList, keyCount);
        bool isMatch = idx < keyCount && page.byteData.getFloat64(4 + idx * 8) == searchVal;
        if (isMatch) {
          final pageId = page.byteData.getInt32(pageIdOffset + idx * 4);
          final slotId = page.byteData.getUint16(slotIdOffset + idx * 2);
          cache.unpinPageSync(indexPath, _cachedLeafPageId!, isDirty: false);
          return BTreePointer(pageId, slotId);
        }
        cache.unpinPageSync(indexPath, _cachedLeafPageId!, isDirty: false);
      }
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
            final double searchVal = key is double ? key : (key as List<double>)[0];
            isMatch = page.byteData.getFloat64(4 + idx * 8) == searchVal;
          } else {
            isMatch = _compareKeys(_getKey(page, idx), key) == 0;
          }
        }
        if (isMatch) {
          if (keyColumns == 1 && keyCount > 0) {
            _cachedLeafPageId = currentPageId;
            _cachedLeafMinKey = page.byteData.getFloat64(4);
            _cachedLeafMaxKey = page.byteData.getFloat64(4 + (keyCount - 1) * 8);
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
              final double searchVal = key is double ? key : (key as List<double>)[0];
              sibMatch = sibPage.byteData.getFloat64(4 + sibIdx * 8) == searchVal;
            } else {
              sibMatch = _compareKeys(_getKey(sibPage, sibIdx), key) == 0;
            }
          }
          if (sibMatch) {
            if (keyColumns == 1 && sibKeyCount > 0) {
              _cachedLeafPageId = siblingId;
              _cachedLeafMinKey = sibPage.byteData.getFloat64(4);
              _cachedLeafMaxKey = sibPage.byteData.getFloat64(4 + (sibKeyCount - 1) * 8);
            }
            final pageId = sibPage.byteData.getInt32(pageIdOffset + sibIdx * 4);
            final slotId = sibPage.byteData.getUint16(slotIdOffset + sibIdx * 2);
            cache.unpinPageSync(indexPath, siblingId, isDirty: false);
            return BTreePointer(pageId, slotId);
          }
          cache.unpinPageSync(indexPath, siblingId, isDirty: false);
        }
        
        return null;
      } else {
        // Find child node to traverse
        int idx = _binarySearch(page, key, keyCount);
        bool isMatch = false;
        if (idx < keyCount) {
          if (keyColumns == 1) {
            final double searchVal = key is double ? key : (key as List<double>)[0];
            isMatch = page.byteData.getFloat64(4 + idx * 8) == searchVal;
          } else {
            isMatch = _compareKeys(_getKey(page, idx), key) == 0;
          }
        }
        final childPageId = page.byteData.getInt32(pageIdOffset + idx * 4);
        cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
        currentPageId = childPageId;
      }
    }
  }

  int findLeafPageId(dynamic key) {
    int currentPageId = _rootPageId;
    while (true) {
      final page = cache.pinPageSync(indexPath, currentPageId);
      final isLeaf = page.byteData.getUint8(1) == 1;
      if (isLeaf) {
        cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
        return currentPageId;
      }
      final keyCount = page.byteData.getUint16(2);
      int idx = _binarySearch(page, key, keyCount);
      final childPageId = page.byteData.getInt32(pageIdOffset + idx * 4);
      cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
      currentPageId = childPageId;
    }
  }

  List<BTreePointer> searchRangeSync(List<double>? low, List<double>? high) {
    final results = <BTreePointer>[];
    int currentPageId = 0;
    if (low == null) {
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
        final childPageId = page.byteData.getInt32(pageIdOffset); // leftmost child
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
          if (low != null && val < low[0]) continue;
          if (high != null && val > high[0]) {
            cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
            return results;
          }
        } else {
          final k = _getKey(page, i);
          if (low != null && _compareKeys(k, low) < 0) continue;
          if (high != null && _compareKeys(k, high) > 0) {
            cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
            return results;
          }
        }
        final pageId = page.byteData.getInt32(pageIdOffset + i * 4);
        final slotId = page.byteData.getUint16(slotIdOffset + i * 2);
        results.add(BTreePointer(pageId, slotId));
      }
      
      final nextPageId = page.byteData.getInt32(siblingOffset); // rightSiblingPageId
      cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
      currentPageId = nextPageId;
    }

    return results;
  }

  int countRangeSync(List<double>? low, List<double>? high) {
    int count = 0;
    int currentPageId = 0;
    if (low == null) {
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
        final childPageId = page.byteData.getInt32(pageIdOffset); // leftmost child
        cache.unpinPageSync(indexPath, curr, isDirty: false);
        curr = childPageId;
      }
    } else {
      currentPageId = findLeafPageId(low);
    }

    while (currentPageId != -1) {
      final page = cache.pinPageSync(indexPath, currentPageId);
      final keyCount = page.byteData.getUint16(2);
      
      if (keyCount > 0 && keyColumns == 1 && low != null && high != null && low[0] == high[0]) {
        final targetVal = low[0];
        final firstVal = page.byteData.getFloat64(4);
        final lastVal = page.byteData.getFloat64(4 + (keyCount - 1) * 8);
        if (firstVal == targetVal && lastVal == targetVal) {
          count += keyCount;
          final nextPageId = page.byteData.getInt32(siblingOffset);
          cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
          currentPageId = nextPageId;
          continue;
        }
      }

      for (int i = 0; i < keyCount; i++) {
        if (keyColumns == 1) {
          final val = page.byteData.getFloat64(4 + i * 8);
          if (low != null && val < low[0]) continue;
          if (high != null && val > high[0]) {
            cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
            return count;
          }
        } else {
          final k = _getKey(page, i);
          if (low != null && _compareKeys(k, low) < 0) continue;
          if (high != null && _compareKeys(k, high) > 0) {
            cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
            return count;
          }
        }
        count++;
      }
      
      final nextPageId = page.byteData.getInt32(siblingOffset); // rightSiblingPageId
      cache.unpinPageSync(indexPath, currentPageId, isDirty: false);
      currentPageId = nextPageId;
    }

    return count;
  }

  bool insertSync(List<double> key, int recordPageId, int recordSlotId) {
    _cachedLeafPageId = null;
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

      final success = _insertIntoLeaf(rootPage, key, recordPageId, recordSlotId);
      if (!success) {
        // Split root leaf
        final pager = cache.getOrCreatePager(indexPath);
        final newPageId = pager.getPageCountSync();
        final newPage = cache.pinPageSync(indexPath, newPageId);
        
        // Initialize new leaf
        newPage.byteData.setUint8(0, 2);
        newPage.byteData.setUint8(1, 1);
        newPage.byteData.setUint16(2, 0);
        newPage.byteData.setInt32(siblingOffset, rootPage.byteData.getInt32(siblingOffset)); // Sibling pointer
        
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
        final newRootPageId = newPageId + 1;
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

  BTreeSplitResult? _insertRecursiveSync(int pageId, List<double> key, int rPageId, int rSlotId) {
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
      final pager = cache.getOrCreatePager(indexPath);
      final newPageId = pager.getPageCountSync();
      final newPage = cache.pinPageSync(indexPath, newPageId);

      newPage.byteData.setUint8(0, 2);
      newPage.byteData.setUint8(1, 1);
      newPage.byteData.setUint16(2, 0);
      newPage.byteData.setInt32(siblingOffset, page.byteData.getInt32(siblingOffset));

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
      int idx = _binarySearch(page, key, keyCount);
      final childPageId = page.byteData.getInt32(pageIdOffset + idx * 4);
      cache.unpinPageSync(indexPath, pageId, isDirty: false);

      final splitResult = _insertRecursiveSync(childPageId, key, rPageId, rSlotId);
      if (splitResult == null) return null;

      // Insert split result into this internal node
      final parentPage = cache.pinPageSync(indexPath, pageId);
      final success = _insertIntoInternal(parentPage, splitResult.key, splitResult.newPageId);
      if (success) {
        cache.unpinPageSync(indexPath, pageId, isDirty: true);
        return null;
      }

      // Split internal node
      final pager = cache.getOrCreatePager(indexPath);
      final newPageId = pager.getPageCountSync();
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
      newPage.byteData.setInt32(pageIdOffset, parentPage.byteData.getInt32(pageIdOffset + (mid + 1) * 4));
      
      for (int i = mid + 1; i < count; i++) {
        final k = _getKey(parentPage, i);
        final childId = parentPage.byteData.getInt32(pageIdOffset + (i + 1) * 4);
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
        final newRootPageId = newPageId + 1;
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
      page.byteData.setInt32(pageIdOffset + i * 4, page.byteData.getInt32(pageIdOffset + (i - 1) * 4));
      page.byteData.setUint16(slotIdOffset + i * 2, page.byteData.getUint16(slotIdOffset + (i - 1) * 2));
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
      page.byteData.setInt32(pageIdOffset + (i + 1) * 4, page.byteData.getInt32(pageIdOffset + i * 4));
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

  void insertSortedBatchSync(Float64List keys, Int32List pageIds, Int32List slotIds, int K, {Int32List? indices}) {
    if (pageIds.isEmpty) return;
    _cachedLeafPageId = null;
    print('insertSortedBatchSync total = ${pageIds.length}, K = $K');

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
      final rightmostChild = page.byteData.getInt32(pageIdOffset + keyCount * 4);
      cache.unpinPageSync(indexPath, curr, isDirty: false);
      curr = rightmostChild;
    }

    final total = pageIds.length;

    if (K == 1) {
      int leafPageId = path.last;
      Page page = cache.pinPageSync(indexPath, leafPageId);
      ByteData byteData = page.byteData;
      bool pageDirty = false;
      int count = byteData.getUint16(2);
      double lastKeyVal = count > 0 ? byteData.getFloat64(4 + (count - 1) * 8) : -double.infinity;

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
        
        final oldLeaf = leafPageId;
        _bulkSplitInsert(path, keyVal, rPageId, rSlotId);

        leafPageId = path.last;
        if (total == 10000) {
          print('Split old leaf $oldLeaf, path.last is now $leafPageId');
        }
        page = cache.pinPageSync(indexPath, leafPageId);
        byteData = page.byteData;
        pageDirty = false;
        count = byteData.getUint16(2);
        lastKeyVal = count > 0 ? byteData.getFloat64(4 + (count - 1) * 8) : -double.infinity;
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
          final rightmostChildT = pageT.byteData.getInt32(pageIdOffset + keyCountT * 4);
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

  void _bulkSplitInsert(List<int> path, double keyVal, int rPageId, int rSlotId) {
    final leafPageId = path.last;
    final leafPage = cache.pinPageSync(indexPath, leafPageId);
    
    final pager = cache.getOrCreatePager(indexPath);
    final newLeafPageId = pager.getPageCountSync();
    final newLeafPage = cache.pinPageSync(indexPath, newLeafPageId);

    newLeafPage.byteData.setUint8(0, 2);
    newLeafPage.byteData.setUint8(1, 1);
    newLeafPage.byteData.setUint16(2, 0);
    newLeafPage.byteData.setInt32(siblingOffset, leafPage.byteData.getInt32(siblingOffset));

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

    _propagateSplitUp(path, path.length - 1, splitKey, newLeafPageId);
  }

  void _insertIntoLeafDouble(Page page, double keyVal, int rPageId, int rSlotId) {
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
      page.byteData.setFloat64(4 + i * 8, page.byteData.getFloat64(4 + (i - 1) * 8));
      page.byteData.setInt32(pageIdOffset + i * 4, page.byteData.getInt32(pageIdOffset + (i - 1) * 4));
      page.byteData.setUint16(slotIdOffset + i * 2, page.byteData.getUint16(slotIdOffset + (i - 1) * 2));
    }

    page.byteData.setFloat64(4 + idx * 8, keyVal);
    page.byteData.setInt32(pageIdOffset + idx * 4, rPageId);
    page.byteData.setUint16(slotIdOffset + idx * 2, rSlotId);
    page.byteData.setUint16(2, count + 1);
    page.markDirty();
  }

  void _propagateSplitUp(List<int> path, int pathIndex, double splitKey, int newPageId) {
    if (pathIndex == 0) {
      final rootPageId = path[0];
      final pager = cache.getOrCreatePager(indexPath);
      final newRootPageId = pager.getPageCountSync();
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
      final pager = cache.getOrCreatePager(indexPath);
      final newParentPageId = pager.getPageCountSync();
      final newParentPage = cache.pinPageSync(indexPath, newParentPageId);

      newParentPage.byteData.setUint8(0, 2);
      newParentPage.byteData.setUint8(1, 0);
      newParentPage.byteData.setUint16(2, 0);

      final mid = count ~/ 2;
      final promoteKey = parentPage.byteData.getFloat64(4 + mid * 8);

      newParentPage.byteData.setInt32(pageIdOffset, parentPage.byteData.getInt32(pageIdOffset + (mid + 1) * 4));

      int newIdx = 0;
      for (int i = mid + 1; i < count; i++) {
        final k = parentPage.byteData.getFloat64(4 + i * 8);
        final childId = parentPage.byteData.getInt32(pageIdOffset + (i + 1) * 4);
        newParentPage.byteData.setFloat64(4 + newIdx * 8, k);
        newParentPage.byteData.setInt32(pageIdOffset + (newIdx + 1) * 4, childId);
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
      page.byteData.setFloat64(4 + i * 8, page.byteData.getFloat64(4 + (i - 1) * 8));
      page.byteData.setInt32(pageIdOffset + (i + 1) * 4, page.byteData.getInt32(pageIdOffset + i * 4));
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
