import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:ultsql/ultsql.dart';

@JS('executeUltSQL')
external set _executeUltSQL(JSFunction fn);

late UltSqlEngine engine;

void main() async {
  engine = await UltSqlEngine.openMemory();

  _executeUltSQL = ((JSString queryJS) {
    return _runQuery(queryJS.toDart).toJS;
  }).toJS;

  print('⚡ Real UltSQL 100% Pure Dart Engine Initialized in Browser!');
}

Future<JSString> _runQuery(String sql) async {
  final stopwatch = Stopwatch()..start();
  try {
    final result = await engine.query(sql);
    stopwatch.stop();

    final response = {
      'status': 'success',
      'elapsedMs': (stopwatch.elapsedMicroseconds / 1000).toStringAsFixed(2),
      'columns': result.columns,
      'rows': result.rows.map((row) => row.map((v) => v is DbNull ? 'NULL' : (v.value?.toString() ?? 'NULL')).toList()).toList(),
      'message': result.message,
    };
    return jsonEncode(response).toJS;
  } catch (e) {
    stopwatch.stop();
    final rawError = e.toString();
    final details = _parseErrorDetails(rawError);
    final response = {
      'status': 'error',
      'elapsedMs': (stopwatch.elapsedMicroseconds / 1000).toStringAsFixed(2),
      'errorTitle': details['title'],
      'error': details['error'],
      'errorHint': details['hint'],
      'rawError': rawError,
    };
    return jsonEncode(response).toJS;
  }
}

Map<String, String> _parseErrorDetails(String raw) {
  var clean = raw.trim();
  if (clean.startsWith('Exception: ')) {
    clean = clean.substring('Exception: '.length).trim();
  }
  if (clean.startsWith('Error: ')) {
    clean = clean.substring('Error: '.length).trim();
  }

  // 1. Table not found
  final tableNotFoundMatch = RegExp(r"Table '([^']+)' does not exist", caseSensitive: false).firstMatch(clean);
  if (tableNotFoundMatch != null) {
    final tbl = tableNotFoundMatch.group(1);
    return {
      'title': 'Table Not Found',
      'error': "Table '$tbl' does not exist in the database catalog.",
      'hint': "Make sure you create the table first using 'CREATE TABLE $tbl (...);' or check for spelling errors.",
    };
  }

  // 2. Table already exists
  final tableExistsMatch = RegExp(r"Table '([^']+)' already exists", caseSensitive: false).firstMatch(clean);
  if (tableExistsMatch != null) {
    final tbl = tableExistsMatch.group(1);
    return {
      'title': 'Table Already Exists',
      'error': "A table named '$tbl' already exists.",
      'hint': "Use 'DROP TABLE IF EXISTS $tbl;' before creating it, or choose a different table name.",
    };
  }

  // 3. Column not found
  final colNotFoundMatch = RegExp(r"Column '([^']+)' (?:does not exist|not found)", caseSensitive: false).firstMatch(clean);
  if (colNotFoundMatch != null) {
    final col = colNotFoundMatch.group(1);
    return {
      'title': 'Column Not Found',
      'error': "Column '$col' was not found in the referenced table schema.",
      'hint': "Check the column name spelling or run 'DESCRIBE <table>;' to see available columns.",
    };
  }

  // 4. Column count mismatch
  final colCountMatch = RegExp(r"Column count mismatch\. Expected (\d+) values, found (\d+)", caseSensitive: false).firstMatch(clean);
  if (colCountMatch != null) {
    final expected = colCountMatch.group(1);
    final found = colCountMatch.group(2);
    return {
      'title': 'Column Count Mismatch',
      'error': "The INSERT statement supplied $found values, but the target table schema expects $expected columns.",
      'hint': "Specify explicit columns: 'INSERT INTO table (col1, col2) VALUES (...)' or supply all $expected values.",
    };
  }

  // 5. Syntax / parser error
  if (clean.contains('Expected ') || clean.contains('Unexpected token') || clean.contains('Syntax error') || clean.contains('[Token')) {
    var desc = clean;
    if (desc.contains('] ')) {
      desc = desc.substring(desc.indexOf('] ') + 2);
    }
    return {
      'title': 'SQL Syntax Error',
      'error': desc,
      'hint': "Verify SQL keywords, commas between column names, quotes around text literals ('value'), and closing parentheses.",
    };
  }

  // 6. Type mismatch
  if (clean.toLowerCase().contains('type mismatch') || clean.toLowerCase().contains('cannot cast') || clean.toLowerCase().contains('incompatible')) {
    return {
      'title': 'Data Type Mismatch',
      'error': clean,
      'hint': "Ensure your values match the column data types (e.g. single quotes for VARCHAR/TEXT, numbers for INT/DOUBLE).",
    };
  }

  // 7. Duplicate Key / Unique Constraint
  if (clean.toLowerCase().contains('duplicate key') || clean.toLowerCase().contains('primary key constraint') || clean.toLowerCase().contains('unique constraint')) {
    return {
      'title': 'Unique Constraint Violation',
      'error': clean,
      'hint': "Primary key and UNIQUE columns must have distinct values. Consider using 'INSERT OR REPLACE' or distinct IDs.",
    };
  }

  // 8. Default fallback
  return {
    'title': 'Query Execution Error',
    'error': clean,
    'hint': 'Review the SQL statement structure and ensure referenced tables, columns, and data types are valid.',
  };
}
