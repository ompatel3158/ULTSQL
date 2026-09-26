import 'dart:convert';
import 'dart:io';
import 'package:ultsql/ultsql.dart';

enum OutputMode { box, table, json, csv, markdown, line }

void main(List<String> args) async {
  String dbTarget = ':memory:';
  String? passphrase;
  AuthEnvelopeMode authEnvelopeMode = AuthEnvelopeMode.inPage;
  OutputMode outputMode = OutputMode.box;
  bool showTimer = false;
  String? oneShotSql;

  // Process subcommands
  if (args.isNotEmpty) {
    final subCmd = args[0].toLowerCase();

    // 1. BENCHMARK SUBCOMMAND
    if (subCmd == 'bench' || subCmd == 'benchmark') {
      int rowCount = 1000000;
      String benchDb = 'bench_temp_db';
      bool useWal = true;
      for (int i = 1; i < args.length; i++) {
        final a = args[i];
        if (int.tryParse(a) != null) {
          rowCount = int.parse(a);
        } else if (a.startsWith('--rows=')) {
          rowCount = int.tryParse(a.substring(7)) ?? rowCount;
        } else if (a == '--rows' && i + 1 < args.length) {
          rowCount = int.tryParse(args[++i]) ?? rowCount;
        } else if (a.startsWith('--db=')) {
          benchDb = a.substring(5);
        } else if (a == '--db' && i + 1 < args.length) {
          benchDb = args[++i];
        } else if (a == '--no-wal') {
          useWal = false;
        }
      }
      await _runBenchmark(rowCount, benchDb, useWal);
      return;
    }

    // 2. EXPORT SUBCOMMAND
    if (subCmd == 'export') {
      if (args.length < 3) {
        print('Usage: ultsql export <table_name> <file.csv|file.json> [--db <db_path>] [--password <passphrase>]');
        exit(1);
      }
      final tableName = args[1];
      final filePath = args[2];
      String dbPath = './ultsql_data';
      for (int i = 3; i < args.length; i++) {
        final a = args[i];
        if (a == '--db' && i + 1 < args.length) {
          dbPath = args[++i];
        } else if (a.startsWith('--db=')) {
          dbPath = a.substring(5);
        } else if ((a == '--password' || a == '--passphrase' || a == '--key') && i + 1 < args.length) {
          passphrase = args[++i];
        } else if (a.startsWith('--password=')) {
          passphrase = a.substring(11);
        } else if (a.startsWith('--passphrase=')) {
          passphrase = a.substring(13);
        } else if (a.startsWith('--key=')) {
          passphrase = a.substring(6);
        }
      }
      passphrase = _resolvePassphrase(dbPath, passphrase);
      final db = Database(dbPath, passphrase: passphrase);
      try {
        await db.init();
      } on DatabaseLockException catch (e) {
        stderr.writeln('❌ Error: ${e.message}');
        exit(1);
      }
      await _handleExport(db, tableName, filePath);
      await db.close();
      return;
    }

    // 3. IMPORT SUBCOMMAND
    if (subCmd == 'import') {
      if (args.length < 3) {
        print('Usage: ultsql import <file.csv|file.json> <table_name> [--db <db_path>] [--password <passphrase>]');
        exit(1);
      }
      final filePath = args[1];
      final tableName = args[2];
      String dbPath = './ultsql_data';
      for (int i = 3; i < args.length; i++) {
        final a = args[i];
        if (a == '--db' && i + 1 < args.length) {
          dbPath = args[++i];
        } else if (a.startsWith('--db=')) {
          dbPath = a.substring(5);
        } else if ((a == '--password' || a == '--passphrase' || a == '--key') && i + 1 < args.length) {
          passphrase = args[++i];
        } else if (a.startsWith('--password=')) {
          passphrase = a.substring(11);
        } else if (a.startsWith('--passphrase=')) {
          passphrase = a.substring(13);
        } else if (a.startsWith('--key=')) {
          passphrase = a.substring(6);
        }
      }
      passphrase = _resolvePassphrase(dbPath, passphrase);
      final db = Database(dbPath, passphrase: passphrase);
      try {
        await db.init();
      } on DatabaseLockException catch (e) {
        stderr.writeln('❌ Error: ${e.message}');
        exit(1);
      }
      await _handleImport(db, filePath, tableName);
      await db.close();
      return;
    }

    // 4. SERVE SUBCOMMAND
    if (subCmd == 'serve') {
      int port = 8080;
      int? pgwirePort;
      String dbPath = './ultsql_data';
      for (int i = 1; i < args.length; i++) {
        final a = args[i];
        if (a == '--port' && i + 1 < args.length) {
          port = int.tryParse(args[++i]) ?? 8080;
        } else if (a.startsWith('--port=')) {
          port = int.tryParse(a.substring(7)) ?? 8080;
        } else if (a == '--pgwire' && i + 1 < args.length) {
          pgwirePort = int.tryParse(args[++i]) ?? 5432;
        } else if (a.startsWith('--pgwire=')) {
          pgwirePort = int.tryParse(a.substring(9)) ?? 5432;
        } else if (a == '--db' && i + 1 < args.length) {
          dbPath = args[++i];
        } else if (a.startsWith('--db=')) {
          dbPath = a.substring(5);
        } else if ((a == '--password' || a == '--passphrase' || a == '--key') && i + 1 < args.length) {
          passphrase = args[++i];
        } else if (a.startsWith('--password=')) {
          passphrase = a.substring(11);
        } else if (a.startsWith('--passphrase=')) {
          passphrase = a.substring(13);
        } else if (a.startsWith('--key=')) {
          passphrase = a.substring(6);
        }
      }
      passphrase = _resolvePassphrase(dbPath, passphrase);
      final db = Database(dbPath, passphrase: passphrase);
      try {
        await db.init();
      } on DatabaseLockException catch (e) {
        stderr.writeln('❌ Error: ${e.message}');
        exit(1);
      }
      final restServer = RestServer(db, port: port);
      final boundPort = await restServer.start(autoPort: true);

      PgWireServer? pgServer;
      if (pgwirePort != null) {
        pgServer = PgWireServer(db, port: pgwirePort);
        await pgServer.start();
      }

      print('===============================================================');
      print('🚀 UltSQL Server Daemon Active & Ready! (v1.0.23)');
      print('===============================================================');
      print('📁 Database Path       : $dbPath');
      if (passphrase != null) {
        print('🔒 Encryption          : AES-256-CTR Enabled');
      }
      print('🌐 REST & OpenAPI API  : http://localhost:$boundPort');
      print('📖 OpenAPI Specs       : http://localhost:$boundPort/openapi.json');
      if (pgServer != null) {
        print('🔌 PostgreSQL Wire API : localhost:$pgwirePort (v3 protocol)');
      }
      print('===============================================================');
      print('Press Ctrl+C to stop the server daemon.\n');

      ProcessSignal.sigint.watch().listen((_) async {
        print('\n🛑 Stopping UltSQL servers...');
        await restServer.stop();
        await pgServer?.stop();
        await db.close();
        exit(0);
      });
      return;
    }

    // 5. PGWIRE SUBCOMMAND
    if (subCmd == 'pgwire') {
      int port = 5432;
      String dbPath = './ultsql_data';
      for (int i = 1; i < args.length; i++) {
        final a = args[i];
        if ((a == '--port' || a == '-p') && i + 1 < args.length) {
          port = int.tryParse(args[++i]) ?? 5432;
        } else if (a.startsWith('--port=')) {
          port = int.tryParse(a.substring(7)) ?? 5432;
        } else if (a == '--db' && i + 1 < args.length) {
          dbPath = args[++i];
        } else if (a.startsWith('--db=')) {
          dbPath = a.substring(5);
        } else if ((a == '--password' || a == '--passphrase' || a == '--key') && i + 1 < args.length) {
          passphrase = args[++i];
        }
      }
      passphrase = _resolvePassphrase(dbPath, passphrase);
      final db = Database(dbPath, passphrase: passphrase);
      try {
        await db.init();
      } on DatabaseLockException catch (e) {
        stderr.writeln('❌ Error: ${e.message}');
        exit(1);
      }
      final pgServer = PgWireServer(db, port: port);
      await pgServer.start();
      print('===============================================================');
      print('🚀 PostgreSQL Wire Protocol daemon active on port $port');
      print('📁 Database Path : $dbPath');
      print('👉 Connect with any Postgres client (psql, node-pg, JDBC).');
      print('===============================================================');
      print('Press Ctrl+C to stop.\n');
      ProcessSignal.sigint.watch().listen((_) async {
        await pgServer.stop();
        await db.close();
        exit(0);
      });
      return;
    }
  }

  // Parse general arguments
  for (int i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--help' || arg == '-h') {
      _printHelp();
      exit(0);
    } else if (arg == '--version' || arg == '-v') {
      print('UltSQL CLI v1.0.23 (Converged Database Engine)');
      exit(0);
    } else if ((arg == '-c' || arg == '--execute') && i + 1 < args.length) {
      oneShotSql = args[++i];
    } else if (arg.startsWith('-c=')) {
      oneShotSql = arg.substring(3);
    } else if (arg.startsWith('--execute=')) {
      oneShotSql = arg.substring(10);
    } else if ((arg == '-m' || arg == '--mode') && i + 1 < args.length) {
      outputMode = _parseOutputMode(args[++i]);
    } else if (arg.startsWith('--mode=')) {
      outputMode = _parseOutputMode(arg.substring(7));
    } else if (arg == '-t' || arg == '--timer') {
      showTimer = true;
    } else if (arg.startsWith('--envelope=')) {
      final env = arg.substring(11).toLowerCase();
      if (env == 'companion') authEnvelopeMode = AuthEnvelopeMode.companion;
    } else if ((arg == '--envelope') && i + 1 < args.length) {
      final env = args[++i].toLowerCase();
      if (env == 'companion') authEnvelopeMode = AuthEnvelopeMode.companion;
    } else if ((arg == '--password' || arg == '--passphrase' || arg == '--key') && i + 1 < args.length) {
      passphrase = args[++i];
    } else if (arg.startsWith('--password=')) {
      passphrase = arg.substring(11);
    } else if (arg.startsWith('--passphrase=')) {
      passphrase = arg.substring(13);
    } else if (arg.startsWith('--key=')) {
      passphrase = arg.substring(6);
    } else if (!arg.startsWith('-')) {
      dbTarget = arg;
    }
  }

  passphrase = _resolvePassphrase(dbTarget, passphrase);

  final db = Database(
    dbTarget,
    passphrase: passphrase,
    authEnvelopeMode: authEnvelopeMode,
  );

  try {
    await db.init();
  } on DatabaseLockException catch (e) {
    stderr.writeln('❌ Error: ${e.message}');
    exit(1);
  } on DatabaseIntegrityException catch (e) {
    stderr.writeln('🔒 Security Error: ${e.message}');
    exit(1);
  }

  final interpreter = Interpreter(db);

  // HEADLESS ONE-SHOT EXECUTION (-c / --execute)
  if (oneShotSql != null) {
    if (oneShotSql.trim().startsWith('.')) {
      await _handleMetaCommand(db, interpreter, oneShotSql.trim(), (newMode) {
        outputMode = newMode;
      }, (timerToggle) {
        showTimer = timerToggle;
      }, outputMode, showTimer);
      await db.close();
      exit(0);
    }
    if (oneShotSql.trim().startsWith('db.')) {
      final handled = await _handleMongoCommand(db, oneShotSql.trim(), outputMode, showTimer);
      if (handled) {
        await db.close();
        exit(0);
      }
    }
    final sw = Stopwatch()..start();
    try {
      final result = await interpreter.executeScript(oneShotSql);
      sw.stop();
      if (result.rows.isNotEmpty) {
        _renderOutput(result.columns, result.rows, outputMode);
      } else if (result.message.isNotEmpty) {
        print(result.message);
      }
      if (showTimer) {
        final elapsedMs = (sw.elapsedMicroseconds / 1000.0).toStringAsFixed(3);
        print('Time: ${elapsedMs} ms');
      }
      await db.close();
      exit(0);
    } catch (e) {
      sw.stop();
      stderr.writeln('⚡ Error: $e');
      await db.close();
      exit(1);
    }
  }

  // INTERACTIVE REPL
  print('===============================================================');
  print('🚀 UltSQL Interactive Console (v1.0.23)');
  print('   Converged Multimodal Database Engine');
  print('===============================================================');
  print('📁 Database Target : $dbTarget');
  if (passphrase != null) {
    final envDesc = authEnvelopeMode == AuthEnvelopeMode.companion
        ? 'Companion ($dbTarget.auth)'
        : 'In-Page Envelope (4064 + 32 tag)';
    print('🔒 Encryption      : AES-256-CTR + HMAC-SHA256 [$envDesc]');
  }
  print('🌿 Active Branch   : ${db.currentBranch}');
  print('🎨 Output Mode     : ${outputMode.name}');
  print('Type ".help" for meta commands, ".exit" to quit.');
  print('Enter SQL, NoSQL (db.users.find()), or PL/SQL statements ending with ";".\n');

  _loadHistory();

  StringBuffer scriptBuffer = StringBuffer();
  final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());

  String prompt() => scriptBuffer.isEmpty ? 'ultsql [${db.currentBranch}]> ' : '   ...  ';
  stdout.write(prompt());

  await for (final line in lines) {
    final trimmed = line.trim();

    // Handle Meta Commands (starts with '.')
    if (scriptBuffer.isEmpty && trimmed.startsWith('.')) {
      _appendHistory(trimmed);
      final handled = await _handleMetaCommand(db, interpreter, trimmed, (newMode) {
        outputMode = newMode;
      }, (timerToggle) {
        showTimer = timerToggle;
      }, outputMode, showTimer);

      if (handled == 'EXIT') {
        print('👋 Goodbye!');
        await db.close();
        exit(0);
      }
      stdout.write(prompt());
      continue;
    }

    // Handle MongoDB-style NoSQL commands (db.<collection>.<method> or db.kv.<method>)
    if (scriptBuffer.isEmpty && trimmed.startsWith('db.')) {
      _appendHistory(trimmed);
      final handled = await _handleMongoCommand(db, trimmed, outputMode, showTimer);
      if (handled) {
        stdout.write(prompt());
        continue;
      }
    }

    if (scriptBuffer.isEmpty && (trimmed == 'exit' || trimmed == 'quit')) {
      print('👋 Goodbye!');
      await db.close();
      exit(0);
    }

    scriptBuffer.writeln(line);

    // Multi-line script execution trigger (ends with semicolon or END;)
    final accumulated = scriptBuffer.toString().trim();
    if (accumulated.endsWith(';') || accumulated.toUpperCase().endsWith('END;')) {
      final scriptToRun = accumulated;
      scriptBuffer.clear();
      _appendHistory(scriptToRun.replaceAll('\n', ' '));

      final sw = Stopwatch()..start();
      try {
        final result = await interpreter.executeScript(scriptToRun);
        sw.stop();
        final elapsedMs = (sw.elapsedMicroseconds / 1000.0).toStringAsFixed(3);

        if (result.dbmsOutputLog.isNotEmpty) {
          for (final msg in result.dbmsOutputLog) {
            print(msg);
          }
        }

        if (result.rows.isNotEmpty) {
          _renderOutput(result.columns, result.rows, outputMode);
          if (showTimer) {
            print('(${result.rows.length} row(s) returned in ${elapsedMs} ms)\n');
          } else {
            print('(${result.rows.length} row(s) returned)\n');
          }
        } else if (result.message.isNotEmpty) {
          if (showTimer) {
            print('${result.message} (${elapsedMs} ms)\n');
          } else {
            print('${result.message}\n');
          }
        } else {
          if (showTimer) {
            print('Statement executed successfully (${elapsedMs} ms)\n');
          } else {
            print('Statement executed successfully.\n');
          }
        }
      } catch (e) {
        sw.stop();
        print('⚡ Error: $e\n');
      }
    }

    stdout.write(prompt());
  }

  await db.close();
}

String? _resolvePassphrase(String dbPath, String? currentPassphrase) {
  if (currentPassphrase != null) return currentPassphrase;
  if (dbPath != ':memory:') {
    final metaFile = File('$dbPath/security.meta');
    if (metaFile.existsSync()) {
      stdout.write('🔒 Database is encrypted. Enter passphrase: ');
      try {
        stdin.echoMode = false;
        final pass = stdin.readLineSync()?.trim();
        stdin.echoMode = true;
        print('');
        return (pass != null && pass.isNotEmpty) ? pass : null;
      } catch (_) {
        stdin.echoMode = true;
      }
    }
  }
  return null;
}

OutputMode _parseOutputMode(String mode) {
  switch (mode.toLowerCase()) {
    case 'table':
      return OutputMode.table;
    case 'json':
      return OutputMode.json;
    case 'csv':
      return OutputMode.csv;
    case 'markdown':
    case 'md':
      return OutputMode.markdown;
    case 'line':
    case 'vertical':
      return OutputMode.line;
    case 'box':
    default:
      return OutputMode.box;
  }
}

// -------------------------------------------------------------
// BENCHMARK RUNNER SUBCOMMAND
// -------------------------------------------------------------
Future<void> _runBenchmark(int rowCount, String dbDir, bool useWal) async {
  final dir = Directory(dbDir);
  if (dir.existsSync()) {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  }
  dir.createSync(recursive: true);

  print('===============================================================');
  print('   ⚡ ULTSQL HIGH-THROUGHPUT DISK INGESTION BENCHMARK ⚡   ');
  print('===============================================================');
  print('📁 Database Directory : $dbDir');
  print('💾 Storage Mode       : Physical Disk with WAL Durability ($useWal)');
  print('📊 Target Ingestion   : ${rowCount.toString()} Rows');
  print('⏳ Initializing test schema and memory page caches...');

  final db = Database(dbDir, useWal: useWal, maxCapacity: 100000);
  await db.init();
  final interp = Interpreter(db);

  await interp.executeScript('CREATE TABLE logs (ts INT, val INT, message TEXT);');

  print('⏳ Generating structured parameter rows in memory...');
  final batchParams = List<List<DbValue>>.generate(rowCount, (i) {
    return [DbInt(i), DbInt(i * 3), DbText('log_$i')];
  });

  print('🚀 Ingesting $rowCount rows via batch prepared statement with WAL...');
  final stmt = db.prepare('INSERT INTO logs VALUES (?, ?, ?);');

  final swTotal = Stopwatch()..start();
  final swBegin = Stopwatch()..start();
  await interp.executeScript('BEGIN TRANSACTION;');
  swBegin.stop();

  final swInsert = Stopwatch()..start();
  stmt.executeBatchSync(batchParams);
  swInsert.stop();

  final swCommit = Stopwatch()..start();
  await interp.executeScript('COMMIT;');
  swCommit.stop();
  swTotal.stop();

  final durationMs = swTotal.elapsedMilliseconds;
  final durationSec = durationMs / 1000.0;
  final rowsPerSec = durationSec > 0 ? (rowCount / durationSec).round() : 0;

  print('');
  print('┌─────────────────────────────────────────────────────────────┐');
  print('│                  BENCHMARK EXECUTION RESULTS                │');
  print('├─────────────────────────────────────────────────────────────┤');
  print('│  Total Elapsed Time : ${durationMs.toString().padRight(8)} ms (${durationSec.toStringAsFixed(3)} s)           │');
  print('│  BEGIN Latency      : ${swBegin.elapsedMilliseconds.toString().padRight(8)} ms                            │');
  print('│  Batch Insertion    : ${swInsert.elapsedMilliseconds.toString().padRight(8)} ms                            │');
  print('│  WAL Commit Flush   : ${swCommit.elapsedMilliseconds.toString().padRight(8)} ms                            │');
  print('│  Throughput         : ${rowsPerSec.toString().padRight(10)} rows/sec                    │');
  print('│  Target (>1.4M/sec) : ${(rowsPerSec >= 1400000 ? "PASSED (SUCCESS)" : "COMPLETED").padRight(28)}│');
  print('└─────────────────────────────────────────────────────────────┘');
  print('');

  print('🔒 Closing database to flush all buffers to disk...');
  await db.close();

  print('🔍 Reopening database to verify physical zero-loss persistence...');
  final verifyDb = Database(dbDir, useWal: useWal);
  await verifyDb.init();
  final countRes = await Interpreter(verifyDb).executeScript('SELECT count(*) FROM logs;');
  final persistedRows = countRes.rows[0][0].toString();
  print('✔ Physical Disk Row Count Verified : $persistedRows');

  if (persistedRows == rowCount.toString()) {
    print('✔ Verification: 100% DURABLE ON DISK. ZERO DATA LOSS!\n');
  } else {
    print('❌ Warning: Expected $rowCount rows but found $persistedRows!\n');
  }

  await verifyDb.close();
  try {
    dir.deleteSync(recursive: true);
  } catch (_) {}
}

// -------------------------------------------------------------
// META COMMAND HANDLER
// -------------------------------------------------------------
Future<String?> _handleMetaCommand(
  Database db,
  Interpreter interpreter,
  String cmd,
  void Function(OutputMode) setMode,
  void Function(bool) setTimer,
  OutputMode currentMode,
  bool currentTimer,
) async {
  final parts = cmd.split(' ').where((s) => s.isNotEmpty).toList();
  final action = parts[0].toLowerCase();

  switch (action) {
    case '.exit':
    case '.quit':
      return 'EXIT';

    case '.help':
      _printMetaHelp();
      return null;

    case '.version':
      print('UltSQL CLI v1.0.23 (Converged Database Engine)\n');
      return null;

    case '.tables':
      _listTables(db);
      return null;

    case '.schema':
      _showSchema(db, parts.length > 1 ? parts[1] : null);
      return null;

    case '.indexes':
      _showIndexes(db, parts.length > 1 ? parts[1] : null);
      return null;

    case '.databases':
      print('Main database target: ${db.directory}');
      print('Active branch       : ${db.currentBranch}\n');
      return null;

    case '.mode':
      if (parts.length < 2) {
        print('Current output mode: ${currentMode.name}');
        print('Available modes: box, table, json, csv, markdown, line\n');
      } else {
        final m = _parseOutputMode(parts[1]);
        setMode(m);
        print('Output mode set to: ${m.name}\n');
      }
      return null;

    case '.timer':
      if (parts.length < 2) {
        print('Timer is currently ${currentTimer ? "ON" : "OFF"}\n');
      } else {
        final val = parts[1].toLowerCase();
        final enable = (val == 'on' || val == '1' || val == 'true');
        setTimer(enable);
        print('Timer turned ${enable ? "ON" : "OFF"}\n');
      }
      return null;

    case '.explain':
      if (parts.length < 2) {
        print('Usage: .explain <sql_query>\n');
        return null;
      }
      final query = cmd.substring('.explain'.length).trim();
      final explainSql = query.toUpperCase().startsWith('EXPLAIN') ? query : 'EXPLAIN $query';
      try {
        final res = await interpreter.executeScript(explainSql);
        if (res.rows.isNotEmpty) {
          print(res.rows[0][0].toString() + '\n');
        } else {
          print(res.message + '\n');
        }
      } catch (e) {
        print('⚡ Explain error: $e\n');
      }
      return null;

    case '.branch':
      _handleBranch(db, parts);
      return null;

    case '.export':
      if (parts.length < 3) {
        print('Usage: .export <table_name> <file.csv|file.json>\n');
      } else {
        await _handleExport(db, parts[1], parts[2]);
      }
      return null;

    case '.import':
      if (parts.length < 3) {
        print('Usage: .import <file.csv|file.json> <table_name>\n');
      } else {
        await _handleImport(db, parts[1], parts[2]);
      }
      return null;

    case '.vacuum':
      print('Executing vacuum compaction and checkpointing...');
      final sw = Stopwatch()..start();
      db.cache.flushAllSync();
      if (db.cache.useWal) {
        db.cache.flushWalSync();
      }
      sw.stop();
      print('✔ Vacuum and checkpoint completed in ${sw.elapsedMilliseconds} ms.\n');
      return null;

    case '.stats':
      _showStats(db, parts.length > 1 ? parts[1] : null);
      return null;

    case '.collections':
      await _listCollections(db);
      return null;

    case '.kv':
      await _handleKvCommand(db, parts);
      return null;

    case '.pgwire':
      final port = parts.length > 1 ? (int.tryParse(parts[1]) ?? 5432) : 5432;
      final server = PgWireServer(db, port: port);
      await server.start();
      print('🚀 PostgreSQL Wire Protocol daemon listening on port $port');
      print('Connect with any Postgres client (psql, psycopg2, JDBC, DBeaver)!\n');
      return null;

    default:
      print('Unrecognized meta command: $action. Type ".help" for available commands.\n');
      return null;
  }
}

void _handleBranch(Database db, List<String> parts) {
  if (parts.length == 1 || (parts.length == 2 && parts[1] == 'list')) {
    final branches = db.listBranches();
    print('Database branches:');
    for (final b in branches) {
      if (b == db.currentBranch) {
        print(' * $b (active)');
      } else {
        print('   $b');
      }
    }
    print('');
    return;
  }

  final sub = parts[1].toLowerCase();
  if (sub == 'create' && parts.length > 2) {
    final name = parts[2];
    try {
      db.createBranch(name);
      print('✔ Created branch "$name".\n');
    } catch (e) {
      print('❌ $e\n');
    }
  } else if (sub == 'switch' && parts.length > 2) {
    final name = parts[2];
    try {
      db.switchBranch(name);
      print('✔ Switched to branch "$name".\n');
    } catch (e) {
      print('❌ $e\n');
    }
  } else if (sub == 'merge' && parts.length > 2) {
    final name = parts[2];
    try {
      db.mergeBranch(name);
      print('✔ Merged branch "$name" into "${db.currentBranch}".\n');
    } catch (e) {
      print('❌ $e\n');
    }
  } else if (sub == 'delete' && parts.length > 2) {
    final name = parts[2];
    try {
      db.deleteBranch(name);
      print('✔ Deleted branch "$name".\n');
    } catch (e) {
      print('❌ $e\n');
    }
  } else {
    print('Usage: .branch [list | create <name> | switch <name> | merge <source> | delete <name>]\n');
  }
}

void _showIndexes(Database db, String? tableName) {
  final indexes = db.catalog.indexes.values.toList();
  final filtered = (tableName != null)
      ? indexes.where((idx) => idx.tableName.toLowerCase() == tableName.toLowerCase()).toList()
      : indexes;

  if (filtered.isEmpty) {
    print(tableName != null
        ? 'No indexes found for table "$tableName".\n'
        : 'No indexes found in catalog.\n');
    return;
  }

  print('Indexes:');
  for (final idx in filtered) {
    print(' - ${idx.name} ON ${idx.tableName} (${idx.columnName})');
  }
  print('');
}

void _showStats(Database db, String? tableName) {
  print('=== ULTSQL DATABASE STATISTICS ===');
  print('Target Directory : ${db.directory}');
  print('Active Branch    : ${db.currentBranch}');
  print('Cache Capacity   : ${db.cache.maxCapacity} pages');
  print('Total Tables     : ${db.catalog.tables.length}');
  print('Total Indexes    : ${db.catalog.indexes.length}');

  if (tableName != null) {
    final schema = db.catalog.getTableSchema(tableName);
    if (schema != null) {
      final stats = db.catalog.getOrCreateStats(schema.name);
      print('--- Table: ${schema.name} ---');
      print('Store Layout     : ${schema.isColumnar ? "Columnar (Parquet)" : "Row Store (Slotted Page)"}');
      print('Registered Rows  : ${stats.rowCount}');
      print('Columns Count    : ${schema.columnNames.length}');
    }
  }
  print('');
}

void _listTables(Database db) {
  final tables = db.catalog.tables.keys.where((t) => !t.startsWith('_coll_') && t != '_kv_store').toList();
  if (tables.isEmpty) {
    print('No relational tables found in catalog.\n');
  } else {
    print('Tables:');
    for (final t in tables) {
      final schema = db.catalog.getTableSchema(t);
      final kind = (schema != null && schema.isColumnar) ? 'Columnar' : 'Row store';
      final stats = db.catalog.getOrCreateStats(t);
      print(' - $t ($kind, ~${stats.rowCount} rows)');
    }
    print('');
  }
}

Future<void> _listCollections(Database db) async {
  final colls = db.listCollections();
  if (colls.isEmpty) {
    print('No NoSQL document collections found.\n');
    return;
  }
  print('NoSQL Collections:');
  for (final name in colls) {
    final count = await db.collection(name).countDocuments();
    print(' - $name ($count document(s))');
  }
  print('');
}

Future<void> _handleKvCommand(Database db, List<String> parts) async {
  if (parts.length == 1 || (parts.length == 2 && (parts[1] == 'list' || parts[1] == 'keys'))) {
    final keys = await db.kv.keys();
    if (keys.isEmpty) {
      print('Key-Value store is empty.\n');
    } else {
      print('Key-Value Store (${keys.length} keys):');
      for (final k in keys) {
        final val = await db.kv.get(k);
        final type = val?.runtimeType.toString() ?? 'null';
        final preview = jsonEncode(val);
        final truncated = preview.length > 50 ? '${preview.substring(0, 47)}...' : preview;
        print(' - $k [$type]: $truncated');
      }
      print('');
    }
    return;
  }

  final sub = parts[1].toLowerCase();
  if (sub == 'get' && parts.length > 2) {
    final key = parts[2];
    final val = await db.kv.get(key);
    if (val == null) {
      print('(nil)\n');
    } else {
      print(val is Map || val is List ? JsonEncoder.withIndent('  ').convert(val) : '$val\n');
    }
  } else if (sub == 'set' && parts.length > 3) {
    final key = parts[2];
    final rawRest = parts.sublist(3);
    dynamic val;
    int? ttl;
    if (rawRest.length > 1 && int.tryParse(rawRest.last) != null) {
      ttl = int.parse(rawRest.last);
      val = _parseKvValue(rawRest.sublist(0, rawRest.length - 1).join(' '));
    } else {
      val = _parseKvValue(rawRest.join(' '));
    }
    await db.kv.set(key, val, ttl: ttl != null ? Duration(seconds: ttl) : null);
    print('OK${ttl != null ? " (TTL: ${ttl}s)" : ""}\n');
  } else if (sub == 'del' && parts.length > 2) {
    final key = parts[2];
    final deleted = await db.kv.delete(key);
    print(deleted ? 'OK (deleted)\n' : '(not found)\n');
  } else if (sub == 'clear') {
    await db.kv.clear();
    print('OK (cleared)\n');
  } else {
    print('Usage: .kv [list | get <key> | set <key> <val> [ttlSec] | del <key> | clear]\n');
  }
}

dynamic _parseKvValue(String raw) {
  final trimmed = raw.trim();
  try {
    return jsonDecode(trimmed);
  } catch (_) {}
  final intVal = int.tryParse(trimmed);
  if (intVal != null) return intVal;
  final dVal = double.tryParse(trimmed);
  if (dVal != null) return dVal;
  if (trimmed.toLowerCase() == 'true') return true;
  if (trimmed.toLowerCase() == 'false') return false;
  return trimmed;
}

Map<String, dynamic> _parseJsonMap(String raw) {
  var trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '{}') return {};
  trimmed = trimmed.replaceAll(r'\$', r'$');
  try {
    return Map<String, dynamic>.from(jsonDecode(trimmed) as Map);
  } catch (_) {
    try {
      var relaxed = trimmed.replaceAllMapped(
        RegExp(r'([a-zA-Z0-9_$]+)\s*:'),
        (m) => '"${m.group(1)}":',
      );
      relaxed = relaxed.replaceAllMapped(
        RegExp(r':\s*([a-zA-Z_][a-zA-Z0-9_-]*)([\s,}])'),
        (m) {
          final word = m.group(1)!;
          if (word == 'true' || word == 'false' || word == 'null') {
            return ': $word${m.group(2)}';
          }
          return ': "$word"${m.group(2)}';
        },
      );
      return Map<String, dynamic>.from(jsonDecode(relaxed) as Map);
    } catch (_) {
      return Map<String, dynamic>.from(jsonDecode(trimmed) as Map);
    }
  }
}

List<dynamic> _parseCommaArguments(String argsStr) {
  var trimmed = argsStr.trim();
  if (trimmed.isEmpty) return [];
  trimmed = trimmed.replaceAll(r'\$', r'$');
  try {
    return jsonDecode('[$trimmed]') as List;
  } catch (_) {
    var relaxed = trimmed.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9_$]+)\s*:'),
      (m) => '"${m.group(1)}":',
    );
    relaxed = relaxed.replaceAllMapped(
      RegExp(r':\s*([a-zA-Z_][a-zA-Z0-9_-]*)([\s,}])'),
      (m) {
        final word = m.group(1)!;
        if (word == 'true' || word == 'false' || word == 'null') {
          return ': $word${m.group(2)}';
        }
        return ': "$word"${m.group(2)}';
      },
    );
    try {
      return jsonDecode('[$relaxed]') as List;
    } catch (_) {}

    if (trimmed.startsWith('{') && trimmed.contains('},')) {
      final idx = trimmed.indexOf('},');
      final firstPart = trimmed.substring(0, idx + 1).trim();
      final secondPart = trimmed.substring(idx + 2).trim();
      return [_parseJsonMap(firstPart), _parseJsonMap(secondPart)];
    }

    return trimmed.split(',').map((s) => s.trim().replaceAll('"', '').replaceAll("'", '')).toList();
  }
}

Future<bool> _handleMongoCommand(
  Database db,
  String rawInput,
  OutputMode outputMode,
  bool showTimer,
) async {
  var input = rawInput.trim();
  if (input.endsWith(';')) input = input.substring(0, input.length - 1).trim();

  final sw = Stopwatch()..start();

  try {
    // 1. db.collections() / db.getCollections()
    if (input == 'db.collections()' || input == 'db.getCollections()') {
      await _listCollections(db);
      return true;
    }

    // 2. db.kv.<subcommand>
    if (input.startsWith('db.kv.')) {
      final rest = input.substring('db.kv.'.length).trim();
      final callMatch = RegExp(r'^([a-zA-Z0-9_]+)\s*\((.*)\)$', dotAll: true).firstMatch(rest);
      if (callMatch != null) {
        final kvMethod = callMatch.group(1)!;
        final kvArgs = callMatch.group(2)!.trim();
        if (kvMethod == 'get') {
          final key = kvArgs.replaceAll('"', '').replaceAll("'", '').trim();
          final val = await db.kv.get(key);
          if (val == null) {
            print('(nil)\n');
          } else {
            print(val is Map || val is List ? JsonEncoder.withIndent('  ').convert(val) : '$val\n');
          }
          return true;
        } else if (kvMethod == 'set') {
          final parsedArgs = _parseCommaArguments(kvArgs);
          if (parsedArgs.length >= 2) {
            final key = parsedArgs[0].toString();
            final val = parsedArgs[1];
            int? ttlSec;
            if (parsedArgs.length >= 3 && parsedArgs[2] is num) {
              ttlSec = (parsedArgs[2] as num).toInt();
            }
            await db.kv.set(key, val, ttl: ttlSec != null ? Duration(seconds: ttlSec) : null);
            print('OK${ttlSec != null ? " (TTL: ${ttlSec}s)" : ""}\n');
            return true;
          }
        } else if (kvMethod == 'del' || kvMethod == 'delete') {
          final key = kvArgs.replaceAll('"', '').replaceAll("'", '').trim();
          final deleted = await db.kv.delete(key);
          print(deleted ? 'OK (deleted)\n' : '(not found)\n');
          return true;
        } else if (kvMethod == 'keys') {
          final keys = await db.kv.keys();
          print(JsonEncoder.withIndent('  ').convert(keys) + '\n');
          return true;
        }
      }
    }

    // 3. db.<collection>.<method>(<args>)[.chain()]
    final match = RegExp(r'^db\.([a-zA-Z0-9_]+)\.(.+)$', dotAll: true).firstMatch(input);
    if (match == null) return false;

    final collName = match.group(1)!;
    final callPart = match.group(2)!.trim();

    final mCall = RegExp(r'^([a-zA-Z0-9_]+)\s*\((.*?)\)(.*)$', dotAll: true).firstMatch(callPart);
    if (mCall == null) return false;

    final method = mCall.group(1)!;
    final argsStr = mCall.group(2)!.trim();
    final chain = mCall.group(3)!.trim();

    final coll = db.collection(collName);

    if (method == 'find') {
      final filter = _parseJsonMap(argsStr);
      var cursor = coll.find(filter);

      final limitMatch = RegExp(r'\.limit\s*\(\s*(\d+)\s*\)').firstMatch(chain);
      if (limitMatch != null) {
        cursor = cursor.limit(int.parse(limitMatch.group(1)!));
      }
      final skipMatch = RegExp(r'\.skip\s*\(\s*(\d+)\s*\)').firstMatch(chain);
      if (skipMatch != null) {
        cursor = cursor.skip(int.parse(skipMatch.group(1)!));
      }
      final sortMatch = RegExp(r'\.sort\s*\(\s*(\{.*?\})\s*\)').firstMatch(chain);
      if (sortMatch != null) {
        cursor = cursor.sort(
          _parseJsonMap(sortMatch.group(1)!).map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ),
        );
      }

      final docs = await cursor.toList();
      sw.stop();
      final elapsedMs = (sw.elapsedMicroseconds / 1000.0).toStringAsFixed(3);

      if (docs.isEmpty) {
        print('Empty result set (0 documents)\n');
      } else {
        if (outputMode == OutputMode.json) {
          print(JsonEncoder.withIndent('  ').convert(docs.map((d) => d.toMap()).toList()) + '\n');
        } else {
          for (final d in docs) {
            print(JsonEncoder.withIndent('  ').convert(d.toMap()));
          }
          if (showTimer) {
            print('(${docs.length} document(s) returned in ${elapsedMs} ms)\n');
          } else {
            print('(${docs.length} document(s) returned)\n');
          }
        }
      }
      return true;
    } else if (method == 'findOne') {
      final filter = _parseJsonMap(argsStr);
      final doc = await coll.findOne(filter);
      sw.stop();
      if (doc == null) {
        print('null\n');
      } else {
        print(JsonEncoder.withIndent('  ').convert(doc.toMap()) + '\n');
      }
      return true;
    } else if (method == 'count' || method == 'countDocuments') {
      final filter = _parseJsonMap(argsStr);
      final count = await coll.countDocuments(filter);
      sw.stop();
      print('$count\n');
      return true;
    } else if (method == 'insertOne' || method == 'insert') {
      final data = _parseJsonMap(argsStr);
      final doc = await coll.insertOne(data);
      sw.stop();
      print('{\n  "acknowledged": true,\n  "insertedId": "${doc.id}"\n}\n');
      return true;
    } else if (method == 'insertMany') {
      final list = jsonDecode(argsStr) as List;
      final docs = await coll.insertMany(list.map((m) => Map<String, dynamic>.from(m as Map)).toList());
      sw.stop();
      print('{\n  "acknowledged": true,\n  "insertedCount": ${docs.length}\n}\n');
      return true;
    } else if (method == 'updateOne' || method == 'updateMany') {
      final argsList = _parseCommaArguments(argsStr);
      if (argsList.length < 2) {
        print('❌ Error: update requires (filter, update) arguments.\n');
        return true;
      }
      final filter = Map<String, dynamic>.from(argsList[0] as Map);
      final update = Map<String, dynamic>.from(argsList[1] as Map);
      final count = method == 'updateOne'
          ? (await coll.updateOne(filter: filter, update: update)).modifiedCount
          : (await coll.updateMany(filter: filter, update: update)).modifiedCount;
      sw.stop();
      print('{\n  "acknowledged": true,\n  "modifiedCount": $count\n}\n');
      return true;
    } else if (method == 'deleteOne' || method == 'deleteMany') {
      final filter = _parseJsonMap(argsStr);
      final count = method == 'deleteOne'
          ? await coll.deleteOne(filter)
          : await coll.deleteMany(filter);
      sw.stop();
      print('{\n  "acknowledged": true,\n  "deletedCount": $count\n}\n');
      return true;
    } else if (method == 'drop') {
      await coll.drop();
      sw.stop();
      print('true\n');
      return true;
    } else if (method == 'createIndex') {
      final field = argsStr.replaceAll('"', '').replaceAll("'", '').trim();
      await coll.createIndex(field);
      sw.stop();
      print('{\n  "createdIndex": "$field"\n}\n');
      return true;
    }
  } catch (e) {
    sw.stop();
    print('⚡ NoSQL Error: $e\n');
    return true;
  }

  return false;
}

void _showSchema(Database db, String? tableName) {
  if (tableName == null) {
    print('Usage: .schema <table_name>\n');
    return;
  }
  final schema = db.catalog.getTableSchema(tableName);
  if (schema == null) {
    print('Table "$tableName" does not exist.\n');
    return;
  }
  print('Schema for ${schema.name} (${schema.isColumnar ? "Columnar" : "Row store"}):');
  for (int i = 0; i < schema.columnNames.length; i++) {
    final col = schema.columnNames[i];
    final type = schema.columnTypes[i];
    final isPk = (i < schema.columnPrimaryKey.length && schema.columnPrimaryKey[i]) ? ' [PRIMARY KEY]' : '';
    final isUniq = (i < schema.columnUnique.length && schema.columnUnique[i]) ? ' [UNIQUE]' : '';
    print('  - $col : $type$isPk$isUniq');
  }
  print('');
}

// -------------------------------------------------------------
// OUTPUT FORMATTERS
// -------------------------------------------------------------
void _renderOutput(List<String> columns, List<List<DbValue>> rows, OutputMode mode) {
  switch (mode) {
    case OutputMode.box:
      _printBoxTable(columns, rows);
      break;
    case OutputMode.table:
      _printAsciiTable(columns, rows);
      break;
    case OutputMode.json:
      _printJson(columns, rows);
      break;
    case OutputMode.csv:
      _printCsv(columns, rows);
      break;
    case OutputMode.markdown:
      _printMarkdown(columns, rows);
      break;
    case OutputMode.line:
      _printLine(columns, rows);
      break;
  }
}

void _printBoxTable(List<String> columns, List<List<DbValue>> rows) {
  if (rows.isEmpty) return;
  final colWidths = List<int>.generate(columns.length, (i) => columns[i].length);
  for (final row in rows) {
    for (int i = 0; i < row.length && i < colWidths.length; i++) {
      final s = row[i].value.toString();
      if (s.length > colWidths[i]) colWidths[i] = s.length;
    }
  }

  final topBorder = '┌' + colWidths.map((w) => '─' * (w + 2)).join('┬') + '┐';
  final midBorder = '├' + colWidths.map((w) => '─' * (w + 2)).join('┼') + '┤';
  final botBorder = '└' + colWidths.map((w) => '─' * (w + 2)).join('┴') + '┘';

  final header = '│' + columns.asMap().entries.map((e) => ' ' + e.value.padRight(colWidths[e.key]) + ' ').join('│') + '│';

  print(topBorder);
  print(header);
  print(midBorder);

  for (final row in rows) {
    final line = '│' + row.asMap().entries.map((e) {
      final str = e.key < colWidths.length ? e.value.value.toString().padRight(colWidths[e.key]) : e.value.value.toString();
      return ' ' + str + ' ';
    }).join('│') + '│';
    print(line);
  }
  print(botBorder);
}

void _printAsciiTable(List<String> columns, List<List<DbValue>> rows) {
  if (rows.isEmpty) return;
  final colWidths = List<int>.generate(columns.length, (i) => columns[i].length);
  for (final row in rows) {
    for (int i = 0; i < row.length && i < colWidths.length; i++) {
      final s = row[i].value.toString();
      if (s.length > colWidths[i]) colWidths[i] = s.length;
    }
  }

  final border = '+' + colWidths.map((w) => '-' * (w + 2)).join('+') + '+';
  final header = '|' + columns.asMap().entries.map((e) => ' ' + e.value.padRight(colWidths[e.key]) + ' ').join('|') + '|';

  print(border);
  print(header);
  print(border);

  for (final row in rows) {
    final line = '|' + row.asMap().entries.map((e) {
      final str = e.key < colWidths.length ? e.value.value.toString().padRight(colWidths[e.key]) : e.value.value.toString();
      return ' ' + str + ' ';
    }).join('|') + '|';
    print(line);
  }
  print(border);
}

void _printJson(List<String> columns, List<List<DbValue>> rows) {
  final list = <Map<String, dynamic>>[];
  for (final row in rows) {
    final map = <String, dynamic>{};
    for (int i = 0; i < columns.length && i < row.length; i++) {
      map[columns[i]] = row[i].value;
    }
    list.add(map);
  }
  final encoder = const JsonEncoder.withIndent('  ');
  print(encoder.convert(list));
}

void _printCsv(List<String> columns, List<List<DbValue>> rows) {
  print(columns.map(_escapeCsv).join(','));
  for (final row in rows) {
    print(row.map((v) => _escapeCsv(v.value.toString())).join(','));
  }
}

String _escapeCsv(String val) {
  if (val.contains(',') || val.contains('"') || val.contains('\n')) {
    return '"' + val.replaceAll('"', '""') + '"';
  }
  return val;
}

void _printMarkdown(List<String> columns, List<List<DbValue>> rows) {
  print('| ' + columns.join(' | ') + ' |');
  print('| ' + columns.map((_) => ':---').join(' | ') + ' |');
  for (final row in rows) {
    print('| ' + row.map((v) => v.value.toString()).join(' | ') + ' |');
  }
}

void _printLine(List<String> columns, List<List<DbValue>> rows) {
  for (int r = 0; r < rows.length; r++) {
    print('---[ Record ${r + 1} ]---');
    final row = rows[r];
    for (int i = 0; i < columns.length && i < row.length; i++) {
      print('  ${columns[i].padRight(16)}: ${row[i].value}');
    }
  }
}

// -------------------------------------------------------------
// EXPORT & IMPORT
// -------------------------------------------------------------
Future<void> _handleExport(Database db, String tableName, String filePath) async {
  final schema = db.catalog.getTableSchema(tableName);
  if (schema == null) {
    print('❌ Error: Table "$tableName" does not exist in catalog.\n');
    return;
  }

  print('⚡ Exporting table "$tableName" to "$filePath"...');
  final sw = Stopwatch()..start();
  final interp = Interpreter(db);
  final res = await interp.executeScript('SELECT * FROM $tableName;');

  final file = File(filePath);
  if (file.existsSync()) {
    try {
      file.deleteSync();
    } catch (_) {}
  }
  file.parent.createSync(recursive: true);

  if (filePath.toLowerCase().endsWith('.json')) {
    final list = <Map<String, dynamic>>[];
    for (final row in res.rows) {
      final map = <String, dynamic>{};
      for (int i = 0; i < res.columns.length && i < row.length; i++) {
        map[res.columns[i]] = row[i].value;
      }
      list.add(map);
    }
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(list));
  } else {
    // CSV
    final sink = file.openWrite();
    sink.writeln(res.columns.map(_escapeCsv).join(','));
    for (final row in res.rows) {
      sink.writeln(row.map((v) => _escapeCsv(v.value.toString())).join(','));
    }
    await sink.flush();
    await sink.close();
  }
  sw.stop();
  print('✔ Successfully exported ${res.rows.length} rows to "$filePath" in ${sw.elapsedMilliseconds} ms.\n');
}

Future<void> _handleImport(Database db, String filePath, String tableName) async {
  final file = File(filePath);
  if (!await file.exists()) {
    print('❌ Error: File "$filePath" does not exist.\n');
    return;
  }

  print('⚡ Ingesting "$filePath" into table "$tableName" via high-speed batch path...');
  final sw = Stopwatch()..start();

  try {
    int count = 0;
    if (filePath.toLowerCase().endsWith('.json')) {
      final content = await file.readAsString();
      final dynamic decoded = jsonDecode(content);
      if (decoded is List) {
        final records = decoded
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        db.insertBatchRecordsSync(tableName, records);
        count = records.length;
      } else {
        print('❌ Error: JSON file must contain an array of objects.\n');
        return;
      }
    } else {
      final lines = await file.readAsLines();
      if (lines.isEmpty) {
        print('❌ Error: CSV file is empty.\n');
        return;
      }
      final headers = lines[0].split(',').map((h) => h.trim()).toList();
      final records = <Map<String, dynamic>>[];
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');
        final map = <String, dynamic>{};
        for (int c = 0; c < headers.length && c < parts.length; c++) {
          final raw = parts[c].trim();
          final intVal = int.tryParse(raw);
          if (intVal != null) {
            map[headers[c]] = intVal;
          } else {
            final doubleVal = double.tryParse(raw);
            if (doubleVal != null) {
              map[headers[c]] = doubleVal;
            } else if (raw.toLowerCase() == 'true') {
              map[headers[c]] = true;
            } else if (raw.toLowerCase() == 'false') {
              map[headers[c]] = false;
            } else {
              if (raw.startsWith('"') && raw.endsWith('"') && raw.length >= 2) {
                map[headers[c]] = raw.substring(1, raw.length - 1);
              } else {
                map[headers[c]] = raw;
              }
            }
          }
        }
        records.add(map);
      }
      db.insertBatchRecordsSync(tableName, records);
      count = records.length;
    }
    sw.stop();
    final elapsedMs = sw.elapsedMicroseconds / 1000.0;
    final rate = count > 0 && elapsedMs > 0
        ? (count / (elapsedMs / 1000.0)).toStringAsFixed(0)
        : '0';
    print(
      '✔ Successfully imported $count rows into "$tableName" in ${elapsedMs.toStringAsFixed(2)} ms ($rate rows/sec).',
    );

    final stats = db.catalog.getOrCreateStats(tableName);
    print(
      '✔ Verified table "$tableName": ${stats.rowCount} total rows registered and indexed.\n',
    );
  } catch (e) {
    sw.stop();
    print('❌ Import failed: $e\n');
  }
}

// -------------------------------------------------------------
// HISTORY PERSISTENCE
// -------------------------------------------------------------
File _getHistoryFile() {
  final home = Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '.';
  return File('$home/.ultsql_history');
}

void _loadHistory() {
  try {
    final f = _getHistoryFile();
    if (!f.existsSync()) {
      f.createSync(recursive: true);
    }
  } catch (_) {}
}

void _appendHistory(String line) {
  try {
    final f = _getHistoryFile();
    f.writeAsStringSync('${line.trim()}\n', mode: FileMode.append);
  } catch (_) {}
}

// -------------------------------------------------------------
// HELP MENUS
// -------------------------------------------------------------
void _printHelp() {
  print('''
UltSQL CLI Usage:
  ultsql [database_file] [options]
  ultsql bench [rows] [--db <path>] [--wal]
  ultsql import <file.csv|file.json> <table_name> [--db <db_path>]
  ultsql export <table_name> <file.csv|file.json> [--db <db_path>]
  ultsql serve [--port=8080] [--pgwire=5432] [--db=./ultsql_data]
  ultsql pgwire [--port=5432] [--db=./ultsql_data]

Options:
  -c, --execute <sql|nosql> Execute SQL or NoSQL query headlessly and exit
  -m, --mode <format>       Output format: box, table, json, csv, markdown, line
  -t, --timer               Display microsecond-precision execution timer
  --envelope <mode>         Encryption envelope mode: inPage (default) or companion
  --password, --key <pass>  Passphrase for AES-256-CTR authenticated encryption
  --port <number>           Port for REST API daemon (default: 8080)
  --db <path>               Database storage directory (default: ./ultsql_data)
  -v, --version             Show CLI version
  -h, --help                Show this help message

Examples:
  ultsql                                      # Launch in-memory SQL terminal
  ultsql app.db                               # Open local database file
  ultsql app.db -c "SELECT * FROM t1;"        # Run headless SQL query
  ultsql app.db -c "db.users.find()"          # Run headless NoSQL query
  ultsql bench 1000000                        # Run 1M-row disk throughput benchmark
  ultsql export users users.csv               # Dump table to CSV file
  ultsql import data.json users               # High-speed batch import from JSON
''');
}

void _printMetaHelp() {
  print(r'''
Meta Commands:
  .tables              List all tables with row count and store layout
  .collections         List all NoSQL document collections and document counts
  .kv [cmd]            Manage Key-Value store: list, get <k>, set <k> <v> [ttl], del <k>, clear
  .schema [table]      Display column schema, types, and primary keys
  .indexes [table]     Display all B+Tree, Vector HNSW, and FTS indexes
  .databases           Show active database file path and branch
  .mode <format>       Switch output display: box, table, json, csv, markdown, line
  .timer <on|off>      Toggle microsecond query execution timer
  .explain <sql>       Display query planner physical execution tree
  .branch [cmd]        Git-like database branching: list, create, switch, merge, delete
  .import <file> <tab> High-speed batch import from CSV or JSON file
  .export <tab> <file> Direct streaming export of table to CSV or JSON
  .vacuum              Flush WAL and compact active page buffers
  .stats [table]       Display storage, row count, and page cache statistics
  .pgwire [port]       Start background PostgreSQL Wire Protocol server (5432)
  .version             Display CLI and database engine version
  .help                Show this help menu
  .exit                Exit UltSQL CLI

NoSQL Mongo-Style Syntax:
  db.<coll>.insertOne({ ... })                Insert single JSON document
  db.<coll>.insertMany([ { ... } ])           Insert batch of JSON documents
  db.<coll>.find([filter])[.limit(N)][.skip(N)] Query documents with rich filters
  db.<coll>.findOne([filter])                 Retrieve single matching document
  db.<coll>.count([filter])                   Count documents matching filter
  db.<coll>.updateOne(filter, update)         Update single document ($set, $inc, etc.)
  db.<coll>.updateMany(filter, update)        Update multiple documents
  db.<coll>.deleteOne(filter)                 Delete single matching document
  db.<coll>.deleteMany(filter)                Delete multiple matching documents
  db.<coll>.createIndex("field")              Create secondary index on document field
  db.<coll>.drop()                            Drop entire document collection
  db.collections()                            List all document collections
  db.kv.get("key")                            Get key from Key-Value store
  db.kv.set("key", value, [ttlSec])           Set key with optional TTL in seconds
  db.kv.del("key")                            Delete key from Key-Value store
  db.kv.keys()                                List all active keys in Key-Value store
''');
}
