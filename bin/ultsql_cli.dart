import 'dart:convert';
import 'dart:io';
import 'package:ultsql/ultsql.dart';

void main(List<String> args) async {
  String dbTarget = ':memory:';
  String? passphrase;

  if (args.isNotEmpty) {
    if (args[0] == 'import') {
      if (args.length < 3) {
        print(
          'Usage: ultsql import <file.csv|file.json> <table_name> [--db <db_path>] [--password <passphrase>]',
        );
        exit(1);
      }
      final filePath = args[1];
      final tableName = args[2];
      String dbPath = './ultsql_data';
      for (int i = 3; i < args.length; i++) {
        if (args[i] == '--db' && i + 1 < args.length) {
          dbPath = args[i + 1];
        } else if (args[i].startsWith('--db=')) {
          dbPath = args[i].substring(5);
        } else if ((args[i] == '--password' ||
                args[i] == '--passphrase' ||
                args[i] == '--key') &&
            i + 1 < args.length) {
          passphrase = args[i + 1];
          i++;
        } else if (args[i].startsWith('--password=')) {
          passphrase = args[i].substring(11);
        } else if (args[i].startsWith('--passphrase=')) {
          passphrase = args[i].substring(13);
        } else if (args[i].startsWith('--key=')) {
          passphrase = args[i].substring(6);
        }
      }
      final db = Database(dbPath, passphrase: passphrase);
      await db.init();
      await _handleImport(db, filePath, tableName);
      await db.close();
      return;
    }
    if (args[0] == 'serve') {
      int port = 8080;
      String dbPath = './ultsql_data';
      for (int i = 1; i < args.length; i++) {
        if (args[i] == '--port' && i + 1 < args.length) {
          port = int.tryParse(args[i + 1]) ?? 8080;
        } else if (args[i].startsWith('--port=')) {
          port = int.tryParse(args[i].substring(7)) ?? 8080;
        } else if (args[i] == '--db' && i + 1 < args.length) {
          dbPath = args[i + 1];
        } else if (args[i].startsWith('--db=')) {
          dbPath = args[i].substring(5);
        } else if ((args[i] == '--password' ||
            args[i] == '--passphrase' ||
            args[i] == '--key') &&
            i + 1 < args.length) {
          passphrase = args[i + 1];
          i++;
        } else if (args[i].startsWith('--password=')) {
          passphrase = args[i].substring(11);
        } else if (args[i].startsWith('--passphrase=')) {
          passphrase = args[i].substring(13);
        } else if (args[i].startsWith('--key=')) {
          passphrase = args[i].substring(6);
        }
      }
      final db = Database(dbPath, passphrase: passphrase);
      await db.init();
      final restServer = RestServer(db, port: port);
      final boundPort = await restServer.start(autoPort: true);

      print('===============================================================');
      print('🚀 UltSQL Server Daemon Active & Ready! (v1.0.21)');
      print('===============================================================');
      print('📁 Database Path       : $dbPath');
      if (passphrase != null) {
        print('🔒 Encryption          : AES-256-CTR Enabled');
      }
      if (boundPort != port) {
        print(
          '🌐 REST & OpenAPI API  : http://localhost:$boundPort (Port $port was occupied, auto-selected $boundPort)',
        );
      } else {
        print('🌐 REST & OpenAPI API  : http://localhost:$boundPort');
      }
      print(
        '📖 OpenAPI Specs       : http://localhost:$boundPort/openapi.json',
      );
      print('===============================================================');
      print('Press Ctrl+C to stop the server daemon.\n');
      return;
    }
    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--help' || arg == '-h') {
        _printHelp();
        exit(0);
      } else if (arg == '--version' || arg == '-v') {
        print('UltSQL CLI v1.0.21');
        exit(0);
      } else if ((arg == '--password' ||
          arg == '--passphrase' ||
          arg == '--key') &&
          i + 1 < args.length) {
        passphrase = args[i + 1];
        i++;
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
  }

  print('===============================================================');
  print('🚀 UltSQL Interactive Command Line Terminal (v1.0.21)');
  print('===============================================================');
  print('📁 Database Target : $dbTarget');
  if (passphrase != null) {
    print('🔒 Encryption      : AES-256-CTR Enabled');
  }
  print('Type ".help" for meta commands or ".exit" to quit.');
  print(
    'Type SQL, NoSQL JSON, or PL/SQL scripts and press Enter to execute.\n',
  );

  final db = Database(dbTarget, passphrase: passphrase);
  await db.init();
  final interpreter = Interpreter(db);

  StringBuffer scriptBuffer = StringBuffer();

  while (true) {
    final prompt = scriptBuffer.isEmpty ? 'ultsql> ' : '   ...  ';
    stdout.write(prompt);
    final line = stdin.readLineSync();

    if (line == null) break;

    final trimmed = line.trim();

    if (scriptBuffer.isEmpty && trimmed.startsWith('.')) {
      if (trimmed == '.exit' || trimmed == '.quit') {
        print('Bye!');
        await db.close();
        exit(0);
      } else if (trimmed == '.help') {
        _printMetaHelp();
        continue;
      } else if (trimmed == '.tables') {
        _listTables(db);
        continue;
      } else if (trimmed.startsWith('.schema')) {
        _showSchema(db, trimmed);
        continue;
      } else if (trimmed.startsWith('.pgwire')) {
        final parts = trimmed.split(' ');
        final port = parts.length > 1 ? (int.tryParse(parts[1]) ?? 5432) : 5432;
        final server = PgWireServer(db, port: port);
        await server.start();
        print('🚀 PostgreSQL Wire Protocol daemon listening on port $port');
        print(
          'Connect with any Postgres client (psycopg2, node-postgres, JDBC, psql)!',
        );
        continue;
      } else if (trimmed == '.databases') {
        print('Main database: $dbTarget\n');
        continue;
      } else if (trimmed.startsWith('.import')) {
        await _handleCliImportCommand(db, trimmed);
        continue;
      } else {
        print(
          'Unrecognized meta command: $trimmed. Type .help for available commands.\n',
        );
        continue;
      }
    }

    if (scriptBuffer.isEmpty && (trimmed == 'exit' || trimmed == 'quit')) {
      print('Bye!');
      await db.close();
      exit(0);
    }

    scriptBuffer.writeln(line);

    // Multi-line script execution trigger (ends with semicolon or END;)
    final accumulated = scriptBuffer.toString().trim();
    if (accumulated.endsWith(';') ||
        accumulated.toUpperCase().endsWith('END;')) {
      final scriptToRun = accumulated;
      scriptBuffer.clear();

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
          _printResultTable(result.columns, result.rows);
          print('(${result.rows.length} row(s) returned in ${elapsedMs} ms)\n');
        } else if (result.message.isNotEmpty) {
          print('${result.message} (${elapsedMs} ms)\n');
        } else {
          print('Statement executed successfully (${elapsedMs} ms)\n');
        }
      } catch (e) {
        sw.stop();
        print('⚡ Error (${sw.elapsedMicroseconds / 1000.0} ms): $e\n');
      }
    }
  }
}

void _listTables(Database db) {
  final tables = db.catalog.tables.keys.toList();
  if (tables.isEmpty) {
    print('No tables found in catalog.\n');
  } else {
    print('Tables:');
    for (final t in tables) {
      print(' - $t');
    }
    print('');
  }
}

void _showSchema(Database db, String cmd) {
  final parts = cmd.split(' ');
  if (parts.length < 2) {
    print('Usage: .schema <table_name>\n');
    return;
  }
  final tableName = parts[1].trim();
  final schema = db.catalog.getTableSchema(tableName);
  if (schema == null) {
    print('Table "$tableName" does not exist.\n');
    return;
  }
  print('Schema for $tableName:');
  for (int i = 0; i < schema.columnNames.length; i++) {
    final col = schema.columnNames[i];
    final type = schema.columnTypes[i];
    final isPk =
        (i < schema.columnPrimaryKey.length && schema.columnPrimaryKey[i])
        ? ' [PRIMARY KEY]'
        : '';
    print('  - $col : $type$isPk');
  }
  print('');
}

void _printResultTable(List<String> columns, List<List<DbValue>> rows) {
  if (rows.isEmpty) return;

  final colWidths = List<int>.generate(
    columns.length,
    (i) => columns[i].length,
  );
  for (final row in rows) {
    for (int i = 0; i < row.length; i++) {
      final s = row[i].value.toString();
      if (s.length > colWidths[i]) {
        colWidths[i] = s.length;
      }
    }
  }

  String border = '+' + colWidths.map((w) => '-' * (w + 2)).join('+') + '+';
  String header =
      '|' +
      columns
          .asMap()
          .entries
          .map((e) => ' ' + e.value.padRight(colWidths[e.key]) + ' ')
          .join('|') +
      '|';

  print(border);
  print(header);
  print(border);

  for (final row in rows) {
    String line =
        '|' +
        row
            .asMap()
            .entries
            .map(
              (e) =>
                  ' ' +
                  e.value.value.toString().padRight(colWidths[e.key]) +
                  ' ',
            )
            .join('|') +
        '|';
    print(line);
  }

  print(border);
}

Future<void> _handleCliImportCommand(Database db, String cmd) async {
  final parts = cmd.split(' ').where((s) => s.isNotEmpty).toList();
  if (parts.length < 3) {
    print('Usage: .import <file.csv|file.json> <table_name>\n');
    return;
  }
  final filePath = parts[1];
  final tableName = parts[2];
  await _handleImport(db, filePath, tableName);
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
      // Default to CSV
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

    // Verify findability
    final stats = db.catalog.getOrCreateStats(tableName);
    print(
      '✔ Verified table "$tableName": ${stats.rowCount} total rows registered and indexed.\n',
    );
  } catch (e) {
    sw.stop();
    print('❌ Import failed: $e\n');
  }
}

void _printHelp() {
  print('''
UltSQL CLI Usage:
  ultsql [database_file] [--password <passphrase>]
  ultsql serve [--port=8080] [--db=./ultsql_data] [--password <passphrase>]
  ultsql import <file.csv|file.json> <table_name> [--db <db_path>]

Options:
  --password, --key <pass>  Passphrase for AES-256-CTR database encryption
  --port <number>           Port for REST server (default: 8080)
  --db <path>               Database storage directory (default: ./ultsql_data)
  -v, --version             Show CLI engine version
  -h, --help                Show this help message

Examples:
  ultsql                                # Launch in-memory SQL terminal
  ultsql my_data.db                     # Open disk database
  ultsql my_data.db --password secret   # Open encrypted database
  ultsql serve --port=8081              # Start REST daemon
  ultsql import data.csv users          # Batch import CSV into users table
''');
}

void _printMetaHelp() {
  print('''
Meta Commands:
  .tables              List all tables in active database
  .schema <table_name> Display columns & types for a table
  .databases           Show active database file path
  .import <file> <tab> High-speed batch import from CSV or JSON file
  .pgwire [port]       Start PostgreSQL Wire Protocol daemon (default: 5432)
  .help                Show this help menu
  .exit                Exit UltSQL CLI
''');
}
