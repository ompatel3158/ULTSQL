import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';

class WalReplicationRecord {
  final int type; // 1: START, 2: PAGE, 3: COMMIT
  final String filePath;
  final int pageId;
  final Uint8List? beforeData;
  final Uint8List? afterData;
  final String? catalogJson;

  WalReplicationRecord({
    required this.type,
    this.filePath = '',
    this.pageId = 0,
    this.beforeData,
    this.afterData,
    this.catalogJson,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'filePath': filePath,
        'pageId': pageId,
        'beforeData': beforeData != null ? base64.encode(beforeData!) : null,
        'afterData': afterData != null ? base64.encode(afterData!) : null,
        'catalogJson': catalogJson,
      };

  factory WalReplicationRecord.fromJson(Map<String, dynamic> json) => WalReplicationRecord(
        type: json['type'],
        filePath: json['filePath'] ?? '',
        pageId: json['pageId'] ?? 0,
        beforeData: json['beforeData'] != null ? base64.decode(json['beforeData']) : null,
        afterData: json['afterData'] != null ? base64.decode(json['afterData']) : null,
        catalogJson: json['catalogJson'],
      );
}

class ReplicationMaster {
  final Database db;
  final List<ReplicationReplica> _replicas = [];

  ReplicationMaster(this.db);

  void registerReplica(ReplicationReplica replica) {
    _replicas.add(replica);
  }

  Future<void> replicateSync(List<WalReplicationRecord> records) async {
    final futures = <Future>[];
    for (final r in records) {
      for (final replica in _replicas) {
        futures.add(replica.applyRecord(r));
      }
    }
    await Future.wait(futures);
  }
}

class ReplicationReplica {
  final Database db;

  ReplicationReplica(this.db);

  Future<void> applyRecord(WalReplicationRecord record) async {
    if (record.type == 1) {
      // START_TX: Apply catalog changes
      if (record.catalogJson != null) {
        final Map<String, dynamic> decoded = json.decode(record.catalogJson!);
        db.catalog.restoreBackupState(decoded);
        db.catalog.save();
      }
    } else if (record.type == 2) {
      // PAGE_RECORD: Write data page directly into page cache
      if (record.afterData != null) {
        final fileName = record.filePath.split('/').last.split('\\').last;
        final localPath = '${db.directory}/$fileName';
        final page = db.cache.pinPageSync(localPath, record.pageId);
        page.data.setAll(0, record.afterData!);
        db.cache.unpinPageSync(localPath, record.pageId, isDirty: true);
      }
    } else if (record.type == 3) {
      // COMMIT_TX: Flush page cache
      db.cache.flushAllSync();
    }
  }
}
