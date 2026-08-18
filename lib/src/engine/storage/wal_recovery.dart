import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import '../cache/page_cache.dart';
import '../cache/crc32.dart';
import '../storage/catalog.dart';

class WalRecord {
  final int
  type; // 1 = START_TX, 2 = PAGE_RECORD, 3 = COMMIT_TX, 4 = SAVEPOINT, 5 = CHECKPOINT
  final String filePath;
  final int pageId;
  final Uint8List? beforeData;
  final Uint8List? afterData;
  final String? extraJson;
  final int checksum;

  WalRecord({
    required this.type,
    this.filePath = '',
    this.pageId = 0,
    this.beforeData,
    this.afterData,
    this.extraJson,
    required this.checksum,
  });
}

/// Advanced WAL Crash Recovery & Checkpoint Manager.
class WalRecoveryEngine {
  static const int walMagic = 0x554c5457; // 'ULTW' (ULTSQL WAL)
  static const int walVersion = 2;

  /// Inspects and recovers database files from a WAL log.
  static Map<String, dynamic> recoverDatabase({
    required String dbDirectory,
    required PageCache pageCache,
    required Catalog catalog,
  }) {
    final walFile = File('$dbDirectory/wal.log');
    if (!walFile.existsSync() || walFile.lengthSync() == 0) {
      return {'status': 'no_wal_found', 'recovered_transactions': 0};
    }

    print(
      '🛡️ [ULTSQL Recovery Engine] Active WAL log detected ($dbDirectory/wal.log). Inspecting...',
    );
    final bytes = walFile.readAsBytesSync();
    int offset = 0;

    int totalRecords = 0;
    int committedTransactions = 0;
    int rolledBackTransactions = 0;

    String? lastCatalogBackup;
    final List<WalRecord> currentTxRecords = [];
    bool txCommitted = false;

    try {
      while (offset + 5 <= bytes.length) {
        final type = bytes[offset];
        offset += 1;

        if (type == 1) {
          // START_TX
          if (offset + 4 > bytes.length) break;
          final jsonLen = ByteData.sublistView(
            bytes,
            offset,
            offset + 4,
          ).getUint32(0, Endian.big);
          offset += 4;
          if (offset + jsonLen > bytes.length) break;
          final jsonBytes = bytes.sublist(offset, offset + jsonLen);
          offset += jsonLen;
          lastCatalogBackup = utf8.decode(jsonBytes);
          currentTxRecords.clear();
          txCommitted = false;
          totalRecords++;
        } else if (type == 2) {
          // PAGE_RECORD
          if (offset + 8 > bytes.length) break;
          final pathLen = ByteData.sublistView(
            bytes,
            offset,
            offset + 4,
          ).getUint32(0, Endian.big);
          final pageId = ByteData.sublistView(
            bytes,
            offset + 4,
            offset + 8,
          ).getUint32(0, Endian.big);
          offset += 8;

          if (offset + pathLen > bytes.length) break;
          final filePath = utf8.decode(bytes.sublist(offset, offset + pathLen));
          offset += pathLen;

          final pageSize = pageCache.pageSize;
          if (offset + (pageSize * 2) > bytes.length) break;

          final beforeData = Uint8List.fromList(
            bytes.sublist(offset, offset + pageSize),
          );
          offset += pageSize;
          final afterData = Uint8List.fromList(
            bytes.sublist(offset, offset + pageSize),
          );
          offset += pageSize;

          final checksum = Crc32.compute(afterData);
          currentTxRecords.add(
            WalRecord(
              type: type,
              filePath: filePath,
              pageId: pageId,
              beforeData: beforeData,
              afterData: afterData,
              checksum: checksum,
            ),
          );
          totalRecords++;
        } else if (type == 3) {
          // COMMIT_TX
          txCommitted = true;
          totalRecords++;
        } else if (type == 5) {
          // CHECKPOINT
          currentTxRecords.clear();
          txCommitted = true;
          totalRecords++;
        }
      }
    } catch (e) {
      print('⚠️ WAL file parse hit EOF or torn record: $e');
    }

    if (txCommitted) {
      print(
        '✅ Replaying ${currentTxRecords.length} committed page writes from WAL...',
      );
      for (final rec in currentTxRecords) {
        if (rec.afterData != null) {
          final pager = pageCache.getOrCreatePager(rec.filePath);
          pager.writePageSync(rec.pageId, rec.afterData!);
        }
      }
      if (lastCatalogBackup != null) {
        try {
          final Map<String, dynamic> jsonMap = json.decode(lastCatalogBackup);
          catalog.restoreBackupState(jsonMap);
          catalog.save();
        } catch (e) {
          print('Error restoring catalog state during WAL recovery: $e');
        }
      }
      committedTransactions++;
    } else {
      print(
        '⚠️ Transaction was not committed. Reverting ${currentTxRecords.length} page writes to before-image state...',
      );
      for (final rec in currentTxRecords.reversed) {
        if (rec.beforeData != null) {
          final pager = pageCache.getOrCreatePager(rec.filePath);
          pager.writePageSync(rec.pageId, rec.beforeData!);
        }
      }
      if (lastCatalogBackup != null) {
        try {
          final Map<String, dynamic> jsonMap = json.decode(lastCatalogBackup);
          catalog.restoreBackupState(jsonMap);
          catalog.save();
        } catch (e) {
          print('Error restoring catalog state during WAL recovery: $e');
        }
      }
      rolledBackTransactions++;
    }

    try {
      walFile.deleteSync();
    } catch (_) {}

    pageCache.flushAllSync();

    // Clear WAL file after clean recovery
    try {
      walFile.deleteSync();
      print('✅ Recovery finished successfully. WAL log truncated.');
    } catch (e) {
      print('Failed to truncate WAL log: $e');
    }

    return {
      'status': 'success',
      'total_records_processed': totalRecords,
      'committed_transactions': committedTransactions,
      'rolled_back_transactions': rolledBackTransactions,
    };
  }

  /// Forces a full checkpoint: flushes all dirty pages to disk, syncs file handles, and truncates WAL.
  static void checkpoint({
    required String dbDirectory,
    required PageCache pageCache,
  }) {
    print('🔄 [CHECKPOINT] Flushing dirty pages and truncating WAL...');
    pageCache.flushAllSync();

    final walFile = File('$dbDirectory/wal.log');
    if (walFile.existsSync()) {
      try {
        walFile.writeAsBytesSync([]);
        print('✅ Checkpoint complete. WAL log truncated.');
      } catch (e) {
        print('Checkpoint WAL truncation error: $e');
      }
    }
  }
}
