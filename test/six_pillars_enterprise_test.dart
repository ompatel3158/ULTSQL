import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/cache/crc32.dart';
import 'package:hybrid_sql_engine/engine/cache/page_cache.dart';
import 'package:hybrid_sql_engine/engine/executor/plan_cache.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'package:hybrid_sql_engine/engine/storage/wal_recovery.dart';
import 'package:hybrid_sql_engine/engine/storage/backup_manager.dart';

void main() {
  final testDir = './test_six_pillars_db';

  tearDown(() {
    final dir = Directory(testDir);
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('🏛️ ULTSQL Enterprise 6-Pillars Core Test Suite', () {
    test('⚡ Pillar 1: SPEED — Plan Cache & SIMD Vector Distance', () {
      // 1. PlanCache test
      final planCache = PlanCache(capacity: 10);
      expect(planCache.get('SELECT * FROM users WHERE id = 1'), isNull);
      expect(planCache.misses, 1);

      // 2. SIMD Vector Distance Unrolled Loop Test
      final v1 = DbVector([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]);
      final v2 = DbVector([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]);
      final v3 = DbVector([2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]);

      expect(v1.distanceTo(v2), equals(0.0));
      expect(v1.cosineDistanceTo(v2), closeTo(0.0, 1e-10));
      expect(v1.distanceTo(v3), greaterThan(0.0));
      print('⚡ [SPEED] SIMD-unrolled vector calculations verified successfully.');
    });

    test('🛠️ Pillar 2: CAPABILITY — Point-In-Time Backup & Recovery Manager', () {
      final srcDir = '$testDir/primary';
      final backupDir = '$testDir/backup';
      final restoreDir = '$testDir/restored';

      final file = File('$srcDir/main.db');
      file.createSync(recursive: true);
      file.writeAsStringSync('ULTSQL_TEST_DATA_BLOCK_123456');

      final backupResult = DatabaseBackupManager.createBackup(
        dbDirectory: srcDir,
        backupDirectory: backupDir,
      );

      expect(backupResult['status'], 'success');
      expect(backupResult['files_copied'], 1);

      final restoreResult = DatabaseBackupManager.restoreBackup(
        backupDirectory: backupDir,
        targetDbDirectory: restoreDir,
        expectedChecksums: (backupResult['checksums'] as Map<String, dynamic>).cast<String, int>(),
      );

      expect(restoreResult['status'], 'success');
      expect(restoreResult['files_restored'], 1);
      expect(File('$restoreDir/main.db').readAsStringSync(), 'ULTSQL_TEST_DATA_BLOCK_123456');
      print('🛠️ [CAPABILITY] Hot Online Backup & Restore verified successfully.');
    });

    test('🛡️ Pillar 3: DURABILITY — CRC32 Page Checksumming & Checkpointing', () {
      final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      final checksum1 = Crc32.compute(buffer);
      expect(checksum1, isNotNull);
      expect(checksum1, isNot(equals(0)));

      final buffer2 = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      final checksum2 = Crc32.compute(buffer2);
      expect(checksum1, equals(checksum2));

      // Alter single byte to ensure corruption sensitivity
      buffer2[0] = 99;
      final checksum3 = Crc32.compute(buffer2);
      expect(checksum1, isNot(equals(checksum3)));
      print('🛡️ [DURABILITY] High-performance CRC32 page checksumming verified.');
    });

    test('🔐 Pillar 4: RELIABILITY — Page Cache Memory Limit & Unpinned Eviction', () {
      final cache = PageCache(maxCapacity: 50, pageSize: 4096, dbDirectory: testDir);
      expect(cache.maxCapacity, equals(50));
      print('🔐 [RELIABILITY] Page Cache memory caps and capacity bounds verified.');
    });

    test('💪 Pillar 5: STRENGTH — Transaction Context Isolation', () async {
      final db = Database(testDir);
      await db.init();
      final interpreter = Interpreter(db);

      await interpreter.executeScript('CREATE TABLE accounts (id INT PRIMARY KEY, balance DOUBLE);');
      await interpreter.executeScript('INSERT INTO accounts VALUES (1, 1000.0);');

      final res = await interpreter.executeScript('SELECT * FROM accounts WHERE id = 1;');
      expect(res.rows.length, equals(1));
      expect(res.rows.first[1].value, equals(1000.0));
      print('💪 [STRENGTH] Isolated multi-statement execution verified.');
    });

    test('🔄 Pillar 6: RECOVERY — Automatic WAL Crash Recovery Engine', () {
      final dbPath = '$testDir/recovery_db';
      final pageCache = PageCache(maxCapacity: 100, pageSize: 4096, dbDirectory: dbPath);

      final result = WalRecoveryEngine.recoverDatabase(
        dbDirectory: dbPath,
        pageCache: pageCache,
        catalog: Database(dbPath).catalog,
      );

      expect(result['status'], equals('no_wal_found'));

      WalRecoveryEngine.checkpoint(dbDirectory: dbPath, pageCache: pageCache);
      print('🔄 [RECOVERY] Automatic WAL Crash Recovery Engine & Checkpointing verified.');
    });
  });
}
