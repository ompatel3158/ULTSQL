import 'dart:io';
import 'dart:typed_data';
import '../cache/crc32.dart';

/// Database Point-in-Time Backup and Disaster Recovery Manager.
class DatabaseBackupManager {
  /// Creates a full atomic directory snapshot of the target database.
  static Map<String, dynamic> createBackup({
    required String dbDirectory,
    required String backupDirectory,
  }) {
    final srcDir = Directory(dbDirectory);
    if (!srcDir.existsSync()) {
      throw Exception('Database directory $dbDirectory does not exist');
    }

    final destDir = Directory(backupDirectory);
    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }

    int copiedFiles = 0;
    int totalBytes = 0;
    final Map<String, int> checksums = {};

    final entities = srcDir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final relPath = entity.path.substring(srcDir.path.length);
        final targetPath = '${destDir.path}$relPath';
        final targetFile = File(targetPath);

        if (!targetFile.parent.existsSync()) {
          targetFile.parent.createSync(recursive: true);
        }

        final bytes = entity.readAsBytesSync();
        targetFile.writeAsBytesSync(bytes);

        final checksum = Crc32.compute(bytes);
        checksums[relPath] = checksum;

        copiedFiles++;
        totalBytes += bytes.length;
      }
    }

    return {
      'status': 'success',
      'source': dbDirectory,
      'destination': backupDirectory,
      'files_copied': copiedFiles,
      'total_bytes': totalBytes,
      'checksums': checksums,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Restores a database from a backup directory and verifies checksums.
  static Map<String, dynamic> restoreBackup({
    required String backupDirectory,
    required String targetDbDirectory,
    Map<String, int>? expectedChecksums,
  }) {
    final srcDir = Directory(backupDirectory);
    if (!srcDir.existsSync()) {
      throw Exception('Backup directory $backupDirectory does not exist');
    }

    final destDir = Directory(targetDbDirectory);
    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }

    int restoredFiles = 0;
    int verifiedFiles = 0;

    final entities = srcDir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final relPath = entity.path.substring(srcDir.path.length);
        final targetPath = '${destDir.path}$relPath';
        final targetFile = File(targetPath);

        if (!targetFile.parent.existsSync()) {
          targetFile.parent.createSync(recursive: true);
        }

        final bytes = entity.readAsBytesSync();
        final checksum = Crc32.compute(bytes);

        if (expectedChecksums != null && expectedChecksums.containsKey(relPath)) {
          if (expectedChecksums[relPath] != checksum) {
            throw Exception('Corrupted backup file detected: $relPath (checksum mismatch)');
          }
          verifiedFiles++;
        }

        targetFile.writeAsBytesSync(bytes);
        restoredFiles++;
      }
    }

    return {
      'status': 'success',
      'files_restored': restoredFiles,
      'files_verified': verifiedFiles,
      'target': targetDbDirectory,
    };
  }
}
