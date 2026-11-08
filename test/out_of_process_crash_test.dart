import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';

Future<void> _hardKill(Process process) async {
  if (Platform.isWindows) {
    try {
      await Process.run('taskkill', ['/F', '/T', '/PID', process.pid.toString()]);
    } catch (_) {
      process.kill(ProcessSignal.sigkill);
    }
  } else {
    Process.killPid(process.pid, ProcessSignal.sigkill);
  }
  await process.exitCode.timeout(const Duration(seconds: 4), onTimeout: () => -1);
}

void main() {
  test('💥 Out-of-Process Crash Safety: Hard kill -9 mid-transaction recovery', () async {
    final tempDir = Directory.systemTemp.createTempSync('ultsql_crash_test_');
    final dbPath = '${tempDir.path}/crash_db';
    final ackPath = '${tempDir.path}/ack.txt';
    final ackFile = File(ackPath);

    final scriptPath = File('test/fixtures/crash_writer.dart').absolute.path;

    // 1. Spawn worker in separate OS process
    final dartExec = Platform.isWindows ? 'dart.bat' : 'dart';
    final process = await Process.start(
      dartExec,
      [scriptPath, dbPath, ackPath],
      runInShell: true,
    );

    // Stream worker output to stderr for debugging if needed
    process.stderr.listen((bytes) => stderr.add(bytes));

    // 2. Wait until at least 2 batches are committed and acknowledged
    int batchesDone = 0;
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsedMilliseconds < 5000) {
      if (ackFile.existsSync()) {
        final lines = ackFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
        if (lines.length >= 2) {
          batchesDone = lines.length;
          break;
        }
      }
      await Future.delayed(const Duration(milliseconds: 30));
    }

    expect(batchesDone, greaterThanOrEqualTo(2), reason: 'Worker should have committed at least 2 batches');

    // 3. Abrupt hard kill midway through writing (kill -9 / taskkill /F)
    await _hardKill(process);

    // Small delay to ensure OS releases all file handles
    await Future.delayed(const Duration(milliseconds: 150));

    // Read exact number of acknowledged batches before the kill
    final acknowledgedBatches = ackFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).length;
    final expectedMinRows = acknowledgedBatches * 20;

    // 4. Recover database directly in a fresh process instance
    final recoveredDb = Database(dbPath);
    await recoveredDb.init();
    final interp = Interpreter(recoveredDb);

    // 5. Query table and verify integrity
    final result = await interp.executeScript('SELECT COUNT(*) FROM accounts;');
    expect(result.rows.isNotEmpty, isTrue);
    final count = result.rows.first.first.value as int;

    // The database must contain at least all acknowledged committed rows
    expect(count, greaterThanOrEqualTo(expectedMinRows),
        reason: 'All acknowledged committed rows must survive crash recovery');

    // Verify rows are intact and queryable by primary key
    final sampleResult = await interp.executeScript('SELECT balance, note FROM accounts WHERE id = 1;');
    expect(sampleResult.rows.isNotEmpty, isTrue);
    expect(sampleResult.rows.first[0].value, equals(1010));

    // Verify new writes succeed post-crash recovery
    await interp.executeScript("INSERT INTO accounts VALUES (999999, 5000, 'Post-recovery insert');");
    final verifyPost = await interp.executeScript('SELECT balance FROM accounts WHERE id = 999999;');
    expect(verifyPost.rows.first[0].value, equals(5000));

    await recoveredDb.close();

    // Cleanup
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  test('💥 Multi-Cycle Crash Safety: 3 consecutive hard kills & recoveries', () async {
    final tempDir = Directory.systemTemp.createTempSync('ultsql_multi_crash_test_');
    final dbPath = '${tempDir.path}/multi_crash_db';
    final ackPath = '${tempDir.path}/ack.txt';
    final ackFile = File(ackPath);
    final scriptPath = File('test/fixtures/crash_writer.dart').absolute.path;
    final dartExec = Platform.isWindows ? 'dart.bat' : 'dart';

    int totalAckBatches = 0;

    for (int cycle = 1; cycle <= 3; cycle++) {
      final prevAcks = ackFile.existsSync()
          ? ackFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).length
          : 0;

      final process = await Process.start(
        dartExec,
        [scriptPath, dbPath, ackPath],
        runInShell: true,
      );

      final stopwatch = Stopwatch()..start();
      while (stopwatch.elapsedMilliseconds < 6000) {
        if (ackFile.existsSync()) {
          final count = ackFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).length;
          if (count >= prevAcks + 2) {
            break;
          }
        }
        await Future.delayed(const Duration(milliseconds: 30));
      }

      await _hardKill(process);
      await Future.delayed(const Duration(milliseconds: 200));

      final currentAcks = ackFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).length;
      totalAckBatches = currentAcks;

      // Verify recovery after this cycle
      final recoveredDb = Database(dbPath);
      await recoveredDb.init();
      final interp = Interpreter(recoveredDb);

      final result = await interp.executeScript('SELECT COUNT(*) FROM accounts;');
      final count = result.rows.first.first.value as int;
      expect(count, greaterThanOrEqualTo(totalAckBatches * 20),
          reason: 'Cycle $cycle: All committed rows must survive repeated crashes');

      await recoveredDb.close();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });
}
