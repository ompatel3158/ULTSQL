import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'page.dart';
import '../storage/catalog.dart';
import 'aes_crypt.dart';

final Uint8List _sharedFlushBuffer = Uint8List(256 * 4096);

class PageKey {
  final String filePath;
  final int pageId;

  PageKey(this.filePath, this.pageId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageKey &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          pageId == other.pageId;

  @override
  int get hashCode => filePath.hashCode ^ pageId.hashCode;

  @override
  String toString() => 'PageKey($filePath, $pageId)';
}

class Pager {
  final String filePath;
  RandomAccessFile? _file;
  final int _pageSize;
  int _virtualPageCount = -1;
  Uint8List? encryptionKey;

  Pager(this.filePath, {this._pageSize = 4096});

  void _cryptPage(int pageId, Uint8List buffer) {
    if (encryptionKey == null) return;
    final aesCtr = AesCtr(encryptionKey!);
    aesCtr.cryptPage(pageId, buffer);
  }

  void openSync() {
    if (_file != null) return;
    final file = File(filePath);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    _file = file.openSync(mode: FileMode.append);
  }

  void _ensureOpenSync() {
    if (_file == null) {
      final file = File(filePath);
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      _file = file.openSync(mode: FileMode.append);
    }
  }

  int getPageCountSync() {
    if (_virtualPageCount != -1) return _virtualPageCount;
    _ensureOpenSync();
    final len = _file!.lengthSync();
    _virtualPageCount = len ~/ _pageSize;
    return _virtualPageCount;
  }

  void readPageSync(int pageId, Uint8List buffer) {
    _ensureOpenSync();
    if (_virtualPageCount == -1) {
      _virtualPageCount = _file!.lengthSync() ~/ _pageSize;
    }
    if (pageId >= _virtualPageCount) {
      _virtualPageCount = pageId + 1;
      buffer.fillRange(0, buffer.length, 0);
      return;
    }
    final offset = pageId * _pageSize;
    _file!.setPositionSync(offset);
    _file!.readIntoSync(buffer);
    
    // Decrypt in-place
    _cryptPage(pageId, buffer);
  }

  void writePageSync(int pageId, Uint8List buffer) {
    if (pageId >= _virtualPageCount) {
      _virtualPageCount = pageId + 1;
    }
    _ensureOpenSync();
    final offset = pageId * _pageSize;
    _file!.setPositionSync(offset);
    
    // Encrypt a copy of buffer so cache remains clear text
    if (encryptionKey != null) {
      final encryptedBuffer = Uint8List.fromList(buffer);
      _cryptPage(pageId, encryptedBuffer);
      _file!.writeFromSync(encryptedBuffer);
    } else {
      _file!.writeFromSync(buffer);
    }
  }

  void writePagesContiguousSync(int startPageId, Uint8List combinedBuffer) {
    final pageCount = combinedBuffer.length ~/ _pageSize;
    final endPageId = startPageId + pageCount;
    if (endPageId >= _virtualPageCount) {
      _virtualPageCount = endPageId;
    }
    _ensureOpenSync();
    final offset = startPageId * _pageSize;
    _file!.setPositionSync(offset);
    
    if (encryptionKey != null) {
      final encryptedBuffer = Uint8List.fromList(combinedBuffer);
      for (int i = 0; i < pageCount; i++) {
        final view = Uint8List.view(encryptedBuffer.buffer, encryptedBuffer.offsetInBytes + i * _pageSize, _pageSize);
        _cryptPage(startPageId + i, view);
      }
      _file!.writeFromSync(encryptedBuffer);
    } else {
      _file!.writeFromSync(combinedBuffer);
    }
  }

  void flushSync() {
    _file?.flushSync();
  }

  void closeSync() {
    if (_file != null) {
      _file!.closeSync();
      _file = null;
    }
    _virtualPageCount = -1;
  }

  void truncateToPagesSync(int pageCount) {
    _ensureOpenSync();
    final length = pageCount * _pageSize;
    _file!.truncateSync(length);
    _virtualPageCount = pageCount;
  }
}

class PageUndoInfo {
  final Uint8List originalData;
  PageUndoInfo(Uint8List data) : originalData = Uint8List.fromList(data);
}

class TransactionState {
  final Map<String, int> originalPageCounts = {};
  final Map<PageKey, PageUndoInfo> originalPages = {};
  final Set<PageKey> loggedPages = {};
  Map<String, dynamic>? catalogBackup;
}

class SessionTxContext {
  MvccTransaction? currentMvccTx;
  TransactionState? txState;
  RandomAccessFile? walFile;
}

class PageCache {
  final int maxCapacity;
  final int pageSize;
  final String? dbDirectory;
  final Map<PageKey, Page> _cache = {};
  final Set<PageKey> _unpinnedKeys = {};
  Uint8List? encryptionKey;
  
  // Track active pagers to write pages back on eviction/flush
  final Map<String, Pager> _pagers = {};
  final Map<String, Uint8List> _encodedPathsCache = {};

  int _timeCounter = 0;

  // Track last pinned page to detect sequential scans for pre-fetching
  final Map<String, int> _lastPinnedPage = {};

  bool _isClosed = false;

  final List<SessionTxContext> _allContexts = [];
  final SessionTxContext _globalContext = SessionTxContext();

  // Cached active transaction state to bypass Zone lookups in hot paths
  TransactionState? _directTxState;

  SessionTxContext createSessionContext() {
    final ctx = SessionTxContext();
    _allContexts.add(ctx);
    return ctx;
  }

  SessionTxContext get _activeContext {
    final ctx = Zone.current[#sessionTxContext] as SessionTxContext?;
    return ctx ?? _globalContext;
  }

  TransactionState? get _txState {
    if (_directTxState != null) return _directTxState;
    final zoneCtx = Zone.current[#sessionTxContext] as SessionTxContext?;
    if (zoneCtx != null) return zoneCtx.txState;
    for (final ctx in _allContexts) {
      if (ctx.txState != null) return ctx.txState;
    }
    return _globalContext.txState;
  }

  set _txState(TransactionState? val) {
    _directTxState = val;
    final zoneCtx = Zone.current[#sessionTxContext] as SessionTxContext?;
    if (zoneCtx != null) {
      zoneCtx.txState = val;
    } else {
      for (final ctx in _allContexts) {
        if (ctx.txState != null) {
          ctx.txState = val;
          return;
        }
      }
      _globalContext.txState = val;
    }
  }

  RandomAccessFile? get _walFile {
    final zoneCtx = Zone.current[#sessionTxContext] as SessionTxContext?;
    if (zoneCtx != null) return zoneCtx.walFile;
    for (final ctx in _allContexts) {
      if (ctx.walFile != null) return ctx.walFile;
    }
    return _globalContext.walFile;
  }

  set _walFile(RandomAccessFile? val) {
    final zoneCtx = Zone.current[#sessionTxContext] as SessionTxContext?;
    if (zoneCtx != null) {
      zoneCtx.walFile = val;
    } else {
      for (final ctx in _allContexts) {
        if (ctx.walFile != null) {
          ctx.walFile = val;
          return;
        }
      }
      _globalContext.walFile = val;
    }
  }

  MvccTransaction? get currentMvccTx {
    final zoneCtx = Zone.current[#sessionTxContext] as SessionTxContext?;
    if (zoneCtx != null) return zoneCtx.currentMvccTx;
    return _globalContext.currentMvccTx;
  }

  set currentMvccTx(MvccTransaction? val) {
    final zoneCtx = Zone.current[#sessionTxContext] as SessionTxContext?;
    if (zoneCtx != null) {
      zoneCtx.currentMvccTx = val;
    } else {
      _globalContext.currentMvccTx = val;
    }
  }

  final MvccTransactionManager mvccTxManager = MvccTransactionManager();

  bool get isTransactionActive => _txState != null;

  bool useWal;
  PageCache({this.maxCapacity = 4000, this.pageSize = 4096, this.dbDirectory, this.useWal = true}); // Default 4000 pages (~16MB)

  void _cryptPageData(int pageId, Uint8List data) {
    if (encryptionKey == null) return;
    final aesCtr = AesCtr(encryptionKey!);
    aesCtr.cryptPage(pageId, data);
  }

  void _ensureWalOpenSync() {
    if (_walFile != null) return;
    if (dbDirectory == null) return;
    final file = File('$dbDirectory/wal.log');
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    _walFile = file.openSync(mode: FileMode.writeOnlyAppend);
  }

  void _appendWalRecordSync(int type, {String filePath = '', int pageId = 0, dynamic before, Uint8List? after}) {
    _ensureWalOpenSync();
    if (_walFile == null) return;

    final builder = BytesBuilder();
    builder.addByte(type);

    if (type == 1) { // START_TX (catalog backup)
      final catalogJson = before as Map<String, dynamic>;
      final jsonBytes = utf8.encode(json.encode(catalogJson));
      final header = ByteData(4)..setUint32(0, jsonBytes.length, Endian.big);
      builder.add(header.buffer.asUint8List());
      builder.add(jsonBytes);
    } else if (type == 2) { // PAGE_RECORD
      final pathBytes = _encodedPathsCache.putIfAbsent(filePath, () => Uint8List.fromList(utf8.encode(filePath)));
      final header = ByteData(8)
        ..setUint32(0, pathBytes.length, Endian.big)
        ..setUint32(4, pageId, Endian.big);
      builder.add(header.buffer.asUint8List());
      builder.add(pathBytes);
      builder.add(before as Uint8List);
      builder.add(after!);
    } else if (type == 3) { // COMMIT_TX
      // No extra payload
    }

    _walFile!.writeFromSync(builder.takeBytes());
  }

  void _writePageToWalBeforeWriteSync(PageKey key, Uint8List afterData) {
    if (!useWal) return;
    final state = _txState;
    if (state == null || dbDirectory == null) return;
    if (state.loggedPages.contains(key)) return;

    final beforeData = state.originalPages[key]?.originalData ?? Uint8List(pageSize);
    
    final Uint8List encBefore;
    final Uint8List encAfter;
    if (encryptionKey != null) {
      encBefore = Uint8List.fromList(beforeData);
      encAfter = Uint8List.fromList(afterData);
      _cryptPageData(key.pageId, encBefore);
      _cryptPageData(key.pageId, encAfter);
    } else {
      encBefore = beforeData;
      encAfter = afterData;
    }

    _appendWalRecordSync(2, filePath: key.filePath, pageId: key.pageId, before: encBefore, after: encAfter);
    state.loggedPages.add(key);
  }

  void recoverSync(Catalog catalog) {
    if (dbDirectory == null) return;
    final walFile = File('$dbDirectory/wal.log');
    if (!walFile.existsSync() || walFile.lengthSync() == 0) return;

    print('WAL file found. Starting recovery...');
    final bytes = walFile.readAsBytesSync();
    int offset = 0;

    String? catalogBackupJson;
    final List<_WalPageRecord> pageRecords = [];
    bool isCommitted = false;

    try {
      while (offset < bytes.length) {
        final type = bytes[offset];
        offset += 1;

        if (type == 1) { // START_TX
          final jsonLen = ByteData.sublistView(bytes, offset, offset + 4).getUint32(0, Endian.big);
          offset += 4;
          final jsonBytes = bytes.sublist(offset, offset + jsonLen);
          offset += jsonLen;
          catalogBackupJson = utf8.decode(jsonBytes);
        } else if (type == 2) { // PAGE_RECORD
          final pathLen = ByteData.sublistView(bytes, offset, offset + 4).getUint32(0, Endian.big);
          offset += 4;
          final pageId = ByteData.sublistView(bytes, offset, offset + 4).getUint32(0, Endian.big);
          offset += 4;
          final pathBytes = bytes.sublist(offset, offset + pathLen);
          offset += pathLen;
          final filePath = utf8.decode(pathBytes);

          final beforeBytes = bytes.sublist(offset, offset + pageSize);
          offset += pageSize;

          final afterBytes = bytes.sublist(offset, offset + pageSize);
          offset += pageSize;

          // Decrypt if encryption key is present
          if (encryptionKey != null) {
            _cryptPageData(pageId, beforeBytes);
            _cryptPageData(pageId, afterBytes);
          }

          pageRecords.add(_WalPageRecord(filePath, pageId, beforeBytes, afterBytes));
        } else if (type == 3) { // COMMIT_TX
          isCommitted = true;
        }
      }
    } catch (e) {
      print('WAL parsing ended or failed: $e');
    }

    if (isCommitted) {
      print('Transaction committed. Replaying modifications...');
      for (final rec in pageRecords) {
        final pager = getOrCreatePager(rec.filePath);
        pager.writePageSync(rec.pageId, rec.afterBytes);
      }
    } else {
      print('Transaction was not committed. Reverting modifications...');
      for (final rec in pageRecords) {
        final pager = getOrCreatePager(rec.filePath);
        pager.writePageSync(rec.pageId, rec.beforeBytes);
      }
      if (catalogBackupJson != null) {
        try {
          final Map<String, dynamic> jsonMap = json.decode(catalogBackupJson);
          catalog.restoreBackupState(jsonMap);
          catalog.save();
        } catch (_) {}
      }
    }

    for (final pager in _pagers.values) {
      pager.flushSync();
    }

    try {
      walFile.deleteSync();
      print('WAL recovery completed successfully. WAL file deleted.');
    } catch (e) {
      print('Failed to delete WAL file: $e');
    }
  }

  void startTransaction(Catalog catalog) {
    currentMvccTx = mvccTxManager.startTransaction();
    final catalogBackup = catalog.getBackupState();
    _txState = TransactionState()
      ..catalogBackup = catalogBackup;
    
    if (useWal && dbDirectory != null) {
      final file = File('$dbDirectory/wal.log');
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
      _walFile = null;
      _ensureWalOpenSync();
      _appendWalRecordSync(1, before: catalogBackup);
      _walFile?.flushSync();
    }
  }

  void commitTransaction() {
    if (currentMvccTx != null) {
      mvccTxManager.commitTransaction(currentMvccTx!.txId);
      currentMvccTx = null;
    }
    if (_txState != null) {
      if (useWal) {
        // Write remaining dirty pages to WAL
        for (final entry in _cache.entries) {
          final key = entry.key;
          final page = entry.value;
          if (page.isDirty) {
            _writePageToWalBeforeWriteSync(key, page.data);
          }
        }
        _appendWalRecordSync(3);
        if (_walFile != null) {
          try {
            _walFile!.flushSync();
            _walFile!.closeSync();
          } catch (_) {}
           _walFile = null;
        }
      }
    }
    _txState = null;

    flushAllSync();

    if (useWal && dbDirectory != null) {
      final walFile = File('$dbDirectory/wal.log');
      if (walFile.existsSync()) {
        try {
          walFile.deleteSync();
        } catch (_) {}
      }
    }
  }

  void rollbackTransactionSync(Catalog catalog) {
    if (currentMvccTx != null) {
      mvccTxManager.rollbackTransaction(currentMvccTx!.txId);
      currentMvccTx = null;
    }
    final state = _txState;
    if (state == null) return;

    if (_walFile != null) {
      try {
        _walFile!.closeSync();
      } catch (_) {}
      _walFile = null;
    }

    if (dbDirectory != null) {
      final walFile = File('$dbDirectory/wal.log');
      if (walFile.existsSync()) {
        try {
          walFile.deleteSync();
        } catch (_) {}
      }
    }

    // 1. Restore original page data for modified pages
    for (final entry in state.originalPages.entries) {
      final key = entry.key;
      final undoInfo = entry.value;
      if (_cache.containsKey(key)) {
        final page = _cache[key]!;
        page.data.setAll(0, undoInfo.originalData);
        page.isDirty = true;
      } else {
        final pager = getOrCreatePager(key.filePath);
        pager.writePageSync(key.pageId, undoInfo.originalData);
      }
    }

    // 2. Truncate files that grew
    for (final entry in state.originalPageCounts.entries) {
      final filePath = entry.key;
      final originalCount = entry.value;
      final pager = getOrCreatePager(filePath);
      final currentCount = pager.getPageCountSync();
      if (currentCount > originalCount) {
        final keysToRemove = <PageKey>[];
        for (final k in _cache.keys) {
          if (k.filePath == filePath && k.pageId >= originalCount) {
            keysToRemove.add(k);
          }
        }
        for (final k in keysToRemove) {
          _cache.remove(k);
        }
        pager.truncateToPagesSync(originalCount);
      }
    }

    // 3. Restore catalog schemas
    if (state.catalogBackup != null) {
      catalog.restoreBackupState(state.catalogBackup!);
      catalog.save();
    }

    flushAllSync();
    _txState = null;
  }

  void _ensureFileTrackedSync(String filePath) {
    final state = _txState;
    if (state == null) return;
    if (!state.originalPageCounts.containsKey(filePath)) {
      final pager = getOrCreatePager(filePath);
      final count = pager.getPageCountSync();
      state.originalPageCounts[filePath] = count;
    }
  }

  void _logPageOriginalData(PageKey key, Page page) {
    final state = _txState;
    if (state == null) return;
    final txId = currentMvccTx?.txId ?? 0;
    if (page.lastLoggedTxId == txId) return;

    _ensureFileTrackedSync(key.filePath);

    if (!state.originalPages.containsKey(key)) {
      final originalCount = state.originalPageCounts[key.filePath] ?? 0;
      if (key.pageId < originalCount) {
        state.originalPages[key] = PageUndoInfo(page.data);
      }
    }
    page.lastLoggedTxId = txId;
  }

  Pager getOrCreatePager(String filePath) {
    final pager = _pagers.putIfAbsent(filePath, () => Pager(filePath, pageSize: pageSize));
    pager.encryptionKey = encryptionKey;
    return pager;
  }

  Page pinPageSync(String filePath, int pageId) {
    final key = PageKey(filePath, pageId);
    _timeCounter++;

    final lastPageId = _lastPinnedPage[filePath];
    _lastPinnedPage[filePath] = pageId;

    if (_txState == null && lastPageId != null && pageId == lastPageId + 1) {
      _schedulePrefetch(filePath, pageId + 1);
    }

    if (_cache.containsKey(key)) {
      final page = _cache[key]!;
      if (_txState != null) {
        _logPageOriginalData(key, page);
      }
      page.pinCount++;
      page.lastAccessTime = _timeCounter;
      _unpinnedKeys.remove(key);
      return page;
    }

    // Cache miss, read from disk
    final pager = getOrCreatePager(filePath);
    final page = Page(pageId, pageSize: pageSize);
    pager.readPageSync(pageId, page.data);
    
    if (_txState != null) {
      _logPageOriginalData(key, page);
    }

    // Evict if cache is full
    if (_cache.length >= maxCapacity) {
      _evictOnePageSync();
    }

    page.pinCount = 1;
    page.lastAccessTime = _timeCounter;
    _cache[key] = page;
    return page;
  }

  void _schedulePrefetch(String filePath, int pageId) {
    Future.microtask(() {
      try {
        if (_isClosed) return;
        final key = PageKey(filePath, pageId);
        if (_cache.containsKey(key)) return;

        final pager = getOrCreatePager(filePath);
        final pageCount = pager.getPageCountSync();
        if (pageId >= pageCount) return;

        final page = Page(pageId, pageSize: pageSize);
        pager.readPageSync(pageId, page.data);

        if (_isClosed) {
          pager.closeSync();
          return;
        }

        if (!_cache.containsKey(key)) {
          if (_cache.length >= maxCapacity) {
            _evictOnePageSync();
          }
          page.pinCount = 0;
          page.lastAccessTime = _timeCounter;
          _cache[key] = page;
          _unpinnedKeys.add(key);
        }
      } catch (_) {
        // Suppress background errors
      }
    });
  }

  void unpinPageSync(String filePath, int pageId, {required bool isDirty}) {
    final key = PageKey(filePath, pageId);
    final page = _cache[key];
    if (page == null) return;

    if (isDirty) {
      page.isDirty = true;
    }

    if (page.pinCount > 0) {
      page.pinCount--;
      if (page.pinCount == 0) {
        _unpinnedKeys.add(key);
      }
    }
  }

  void logPageToWalSync(String filePath, int pageId) {
    if (!useWal) return;
    final key = PageKey(filePath, pageId);
    final page = _cache[key];
    if (page != null && page.isDirty) {
      _writePageToWalBeforeWriteSync(key, page.data);
    }
  }

  void flushWalSync() {
    _walFile?.flushSync();
  }

  void logAllDirtyPagesToWalSync() {
    if (!useWal) return;
    for (final entry in _cache.entries) {
      final key = entry.key;
      final page = entry.value;
      if (page.isDirty) {
        _writePageToWalBeforeWriteSync(key, page.data);
      }
    }
    _walFile?.flushSync();
  }

  void _evictOnePageSync() {
    if (_unpinnedKeys.isEmpty) return;
    final lruKey = _unpinnedKeys.first;
    _unpinnedKeys.remove(lruKey);
    final lruPage = _cache.remove(lruKey);
    if (lruPage != null && lruPage.isDirty) {
      final pager = _pagers[lruKey.filePath];
      if (pager != null) {
        _writePageToWalBeforeWriteSync(lruKey, lruPage.data);
        pager.writePageSync(lruPage.pageId, lruPage.data);
      }
    }
  }

  void flushAllSync() {
    final dirtyPages = <PageKey, Page>{};
    for (final entry in _cache.entries) {
      if (entry.value.isDirty) {
        dirtyPages[entry.key] = entry.value;
      }
    }
    if (dirtyPages.isEmpty) return;

    final sortedKeys = dirtyPages.keys.toList()
      ..sort((a, b) {
        final cmp = a.filePath.compareTo(b.filePath);
        if (cmp != 0) return cmp;
        return a.pageId.compareTo(b.pageId);
      });

    final flushedPagers = <Pager>{};
    
    // Group sorted keys by filePath
    final pagesByFile = <String, List<PageKey>>{};
    for (final key in sortedKeys) {
      pagesByFile.putIfAbsent(key.filePath, () => []).add(key);
    }

    for (final entry in pagesByFile.entries) {
      final filePath = entry.key;
      final keys = entry.value;
      final pager = _pagers[filePath];
      if (pager == null) continue;
      flushedPagers.add(pager);

      int idx = 0;
      while (idx < keys.length) {
        int runStart = idx;
        int runEnd = idx;
        
        while (runEnd + 1 < keys.length && 
               keys[runEnd + 1].pageId == keys[runEnd].pageId + 1) {
          runEnd++;
        }

        final runLength = runEnd - runStart + 1;
        if (runLength > 1) {
          int chunkStart = runStart;
          while (chunkStart <= runEnd) {
            final chunkEnd = (chunkStart + 255 < runEnd) ? chunkStart + 255 : runEnd;
            final chunkLen = chunkEnd - chunkStart + 1;
            final combined = (chunkLen == 256)
                ? _sharedFlushBuffer
                : Uint8List.view(_sharedFlushBuffer.buffer, 0, chunkLen * pageSize);
            for (int r = 0; r < chunkLen; r++) {
              final key = keys[chunkStart + r];
              final page = dirtyPages[key]!;
              _writePageToWalBeforeWriteSync(key, page.data);
              combined.setAll(r * pageSize, page.data);
              page.isDirty = false;
            }
            pager.writePagesContiguousSync(keys[chunkStart].pageId, combined);
            chunkStart = chunkEnd + 1;
          }
        } else {
          final key = keys[runStart];
          final page = dirtyPages[key]!;
          _writePageToWalBeforeWriteSync(key, page.data);
          pager.writePageSync(key.pageId, page.data);
          page.isDirty = false;
        }

        idx = runEnd + 1;
      }
    }

    for (final pager in flushedPagers) {
      pager.flushSync();
    }
  }

  void evictTableSync(String filePath) {
    flushAllSync();
    final keysToRemove = _cache.keys.where((k) => k.filePath == filePath).toList();
    for (final k in keysToRemove) {
      _cache.remove(k);
      _unpinnedKeys.remove(k);
    }
    final pager = _pagers.remove(filePath);
    if (pager != null) {
      pager.closeSync();
    }
  }

  void closeAllSync() {
    _isClosed = true;
    flushAllSync();
    _cache.clear();
    _unpinnedKeys.clear();
    for (final pager in _pagers.values) {
      pager.closeSync();
    }
    _pagers.clear();
    for (final ctx in _allContexts) {
      if (ctx.walFile != null) {
        try {
          ctx.walFile!.closeSync();
        } catch (_) {}
        ctx.walFile = null;
      }
    }
    _allContexts.clear();
    if (_globalContext.walFile != null) {
      try {
        _globalContext.walFile!.closeSync();
      } catch (_) {}
      _globalContext.walFile = null;
    }
  }
}

class _WalPageRecord {
  final String filePath;
  final int pageId;
  final Uint8List beforeBytes;
  final Uint8List afterBytes;
  _WalPageRecord(this.filePath, this.pageId, this.beforeBytes, this.afterBytes);
}

enum TxStatus { active, committed, aborted }

class MvccTransaction {
  final int txId;
  final Set<int> activeTxIds;
  MvccTransaction(this.txId, this.activeTxIds);
}

class MvccTransactionManager {
  int _nextTxId = 1;
  final Map<int, TxStatus> txStatusMap = {
    0: TxStatus.committed,
  };
  final Set<int> _activeTxIds = {};

  MvccTransaction startTransaction() {
    final txId = _nextTxId++;
    txStatusMap[txId] = TxStatus.active;
    final activeSnapshot = Set<int>.from(_activeTxIds);
    _activeTxIds.add(txId);
    return MvccTransaction(txId, activeSnapshot);
  }

  void commitTransaction(int txId) {
    txStatusMap[txId] = TxStatus.committed;
    _activeTxIds.remove(txId);
  }

  void rollbackTransaction(int txId) {
    txStatusMap[txId] = TxStatus.aborted;
    _activeTxIds.remove(txId);
  }

  bool isVisible(int xmin, int xmax, int currentTxId, Set<int> activeTxIds) {
    if (xmin != 0) {
      final xminStatus = txStatusMap[xmin] ?? TxStatus.committed;
      if (xminStatus == TxStatus.aborted) {
        return false;
      }
      if (xminStatus == TxStatus.active) {
        if (xmin == currentTxId) {
          // Visible to our own transaction
        } else {
          return false;
        }
      }
      if (xminStatus == TxStatus.committed) {
        if (activeTxIds.contains(xmin)) {
          return false;
        }
      }
    }

    if (xmax == 0) {
      return true;
    }

    final xmaxStatus = txStatusMap[xmax] ?? TxStatus.committed;
    if (xmaxStatus == TxStatus.aborted) {
      return true;
    }
    if (xmaxStatus == TxStatus.active) {
      if (xmax == currentTxId) {
        return false;
      } else {
        return true;
      }
    }
    if (xmaxStatus == TxStatus.committed) {
      if (activeTxIds.contains(xmax)) {
        return true;
      }
      return false;
    }

    return true;
  }
}

class MvccRecord {
  final int xmin;
  final int xmax;
  final int rollPtr;
  final Uint8List rowData;

  MvccRecord({
    required this.xmin,
    required this.xmax,
    required this.rollPtr,
    required this.rowData,
  });

  Uint8List toBytes() {
    final bytes = Uint8List(12 + rowData.length);
    final bd = ByteData.sublistView(bytes);
    bd.setUint32(0, xmin);
    bd.setUint32(4, xmax);
    bd.setUint32(8, rollPtr);
    bytes.setAll(12, rowData);
    return bytes;
  }

  static MvccRecord fromBytes(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    final xmin = bd.getUint32(0);
    final xmax = bd.getUint32(4);
    final rollPtr = bd.getUint32(8);
    final rowData = Uint8List.view(bytes.buffer, bytes.offsetInBytes + 12, bytes.length - 12);
    return MvccRecord(xmin: xmin, xmax: xmax, rollPtr: rollPtr, rowData: rowData);
  }
}
