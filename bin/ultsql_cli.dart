import 'dart:io';
import 'package:ultsql/ultsql.dart';

void main(List<String> args) async {
  String dbTarget = ':memory:';

  if (args.isNotEmpty) {
    if (args[0] == 'serve') {
      int port = 8080;
      String dbPath = './ultsql_data';
      for (int i = 1; i < args.length; i++) {
        if (args[i] == '--port' && i + 1 < args.length) {
          port = int.tryParse(args[i + 1]) ?? 8080;
        } else if (args[i] == '--db' && i + 1 < args.length) {
          dbPath = args[i + 1];
        }
      }
      final db = Database(dbPath);
      await db.init();
      final restServer = RestServer(db, port: port);
      await restServer.start();
      print('🚀 UltSQL REST & OpenAPI daemon listening on http://localhost:$port');
      print('📖 OpenAPI Documentation: http://localhost:$port/openapi.json');
      return;
    }
    if (args[0] == '--help' || args[0] == '-h') {
      _printHelp();
      exit(0);
    }
    dbTarget = args[0];
  }

  print('===============================================================');
  print('🚀 UltSQL Interactive Command Line Terminal (v1.0.0)');
  print('===============================================================');
  print('📁 Database Target : $dbTarget');
  print('Type ".help" for meta commands or ".exit" to quit.');
  print('Type SQL or PL/SQL scripts and press Enter to execute.\n');

  final db = Database(dbTarget);
  await db.init();
  final interpreter = Interpreter(db);

  StringBuffer scriptBuffer = StringBuffer();

  while (true) {
    final prompt = scriptBuffer.isEmpty ? 'ultsql> ' : '   ...  ';
    stdout.write(prompt);
    final line = stdin.readLineSync();

    if (line == null) break;

    final trimmed = line.trim();

    if (scriptBuffer.isEmpty) {
      if (trimmed == '.exit' || trimmed == 'exit' || trimmed == 'quit') {
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
      } else if (trimmed == '.databases') {
        print('Main database: $dbTarget');
        continue;
      }
    }

    scriptBuffer.writeln(line);

    // Multi-line script execution trigger (ends with semicolon or END;)
    final accumulated = scriptBuffer.toString().trim();
    if (accumulated.endsWith(';') || accumulated.toUpperCase().endsWith('END;')) {
      final scriptToRun = accumulated;
      scriptBuffer.clear();

      final sw = Stopwatch()..start();
      try {
        final result = await interpreter.executeScript(scriptToRun);
        sw.stop();
        final elapsedMs = (sw.elapsedMicroseconds / 1000.0).toStringAsFixed(3);

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
    final isPk = (i < schema.columnPrimaryKey.length && schema.columnPrimaryKey[i]) ? ' [PRIMARY KEY]' : '';
    print('  - $col : $type$isPk');
  }
  print('');
}

void _printResultTable(List<String> columns, List<List<DbValue>> rows) {
  if (rows.isEmpty) return;

  final colWidths = List<int>.generate(columns.length, (i) => columns[i].length);
  for (final row in rows) {
    for (int i = 0; i < row.length; i++) {
      final s = row[i].value.toString();
      if (s.length > colWidths[i]) {
        colWidths[i] = s.length;
      }
    }
  }

  String border = '+' + colWidths.map((w) => '-' * (w + 2)).join('+') + '+';
  String header = '|' + columns.asMap().entries.map((e) => ' ' + e.value.padRight(colWidths[e.key]) + ' ').join('|') + '|';

  print(border);
  print(header);
  print(border);

  for (final row in rows) {
    String line = '|' + row.asMap().entries.map((e) => ' ' + e.value.value.toString().padRight(colWidths[e.key]) + ' ').join('|') + '|';
    print(line);
  }

  print(border);
}

void _printHelp() {
  print('''
UltSQL CLI Usage:
  dart run bin/ultsql_cli.dart [database_file]

Examples:
  dart run bin/ultsql_cli.dart               # In-Memory database
  dart run bin/ultsql_cli.dart my_data.db    # Physical disk database
''');
}

void _printMetaHelp() {
  print('''
Meta Commands:
  .tables              List all tables in active database
  .schema <table_name> Display columns & types for a table
  .databases           Show active database file path
  .help                Show this help menu
  .exit                Exit UltSQL CLI
''');
}
