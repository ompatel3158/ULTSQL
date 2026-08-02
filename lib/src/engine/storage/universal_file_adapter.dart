import 'dart:convert';
import 'dart:io';
import 'package:ultsql/src/engine/executor/value.dart';

/// Universal Native File System SQL Adapter: Query raw CSV, JSON & LOG files directly via SQL
class UniversalFileAdapter {
  static DbValue _rawToDbValue(dynamic raw) {
    if (raw == null) return DbNull();
    if (raw is int) return DbInt(raw);
    if (raw is double) return DbDouble(raw);
    if (raw is String) return DbText(raw);
    if (raw is bool) return DbInt(raw ? 1 : 0);
    return DbText(raw.toString());
  }

  /// Queries raw CSV files directly via SQL filtering
  static List<List<DbValue>> queryCsvFile(String filePath, String whereValue) {
    final file = File(filePath);
    if (!file.existsSync()) return [];

    final lines = file.readAsLinesSync();
    if (lines.isEmpty) return [];

    final rows = <List<DbValue>>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = line.split(',');

      if (whereValue.isEmpty || line.toLowerCase().contains(whereValue.toLowerCase())) {
        final row = <DbValue>[];
        for (final col in cols) {
          final parsedInt = int.tryParse(col);
          final parsedDouble = double.tryParse(col);
          if (parsedInt != null) {
            row.add(DbInt(parsedInt));
          } else if (parsedDouble != null) {
            row.add(DbDouble(parsedDouble));
          } else {
            row.add(DbText(col));
          }
        }
        rows.add(row);
      }
    }
    return rows;
  }

  /// Queries raw JSON files directly
  static List<List<DbValue>> queryJsonFile(String filePath, String jsonPathFilter) {
    final file = File(filePath);
    if (!file.existsSync()) return [];

    final content = file.readAsStringSync();
    final decoded = json.decode(content) as List<dynamic>;

    final rows = <List<DbValue>>[];
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        if (jsonPathFilter.isEmpty || item.toString().toLowerCase().contains(jsonPathFilter.toLowerCase())) {
          final row = item.values.map((v) => _rawToDbValue(v)).toList();
          rows.add(row);
        }
      }
    }
    return rows;
  }

  /// Queries raw server log files directly via regex pattern matching
  static List<List<DbValue>> queryLogFile(String filePath, String regexPattern) {
    final file = File(filePath);
    if (!file.existsSync()) return [];

    final lines = file.readAsLinesSync();
    final regExp = RegExp(regexPattern, caseSensitive: false);

    final rows = <List<DbValue>>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (regexPattern.isEmpty || regExp.hasMatch(line)) {
        rows.add([DbInt(i + 1), DbText(line)]);
      }
    }
    return rows;
  }
}
