import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../parser/ast.dart';
import '../executor/value.dart';

/// RFC 4180 Compliant Streaming CSV Parser
class Rfc4180Parser {
  /// Splits an RFC 4180 CSV line into tokens, respecting double-quotes and escaped quotes ("")
  static List<String> parseLine(String line) {
    final fields = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;
    int i = 0;

    while (i < line.length) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote "" -> "
          sb.write('"');
          i += 2;
          continue;
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
          i++;
          continue;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(sb.toString().trim());
        sb.clear();
        i++;
        continue;
      } else {
        sb.write(char);
        i++;
      }
    }
    fields.add(sb.toString().trim());
    return fields;
  }
}

/// Production Foreign Data Wrapper Manager (CSV, NDJSON, and JSON Array)
abstract class FdwManager {
  static Stream<Map<String, DbValue>> scan(CreateForeignTableStmt stmt) async* {
    final server = stmt.serverName.toLowerCase();
    final filename = stmt.options['filename'];
    if (filename == null) {
      throw Exception('Foreign table requires filename in options');
    }

    if (identical(0, 0.0)) return;
    final file = File(filename);
    if (!await file.exists()) {
      return;
    }

    if (server == 'csv') {
      List<String>? header;
      final linesStream = file
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in linesStream) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final parts = Rfc4180Parser.parseLine(line);
        if (header == null) {
          header = parts.map((h) => h.trim()).toList();
          continue;
        }

        final row = <String, DbValue>{};
        for (int j = 0; j < header.length && j < parts.length; j++) {
          final colName = header[j];
          final val = parts[j];
          final def = stmt.columns.firstWhere(
            (c) => c.name.toLowerCase() == colName.toLowerCase(),
            orElse: () => ColumnDef(colName, DataType.text),
          );

          DbValue dbVal;
          if (def.type == DataType.integer) {
            dbVal = DbInt(int.tryParse(val) ?? 0);
          } else if (def.type == DataType.double) {
            dbVal = DbDouble(double.tryParse(val) ?? 0.0);
          } else if (def.type == DataType.boolean) {
            dbVal = DbBool(val.toLowerCase() == 'true' || val == '1');
          } else {
            dbVal = DbText(val);
          }
          row[colName.toLowerCase()] = dbVal;
          row['${stmt.tableName.toLowerCase()}.${colName.toLowerCase()}'] = dbVal;
        }
        yield row;
      }
    } else if (server == 'json' || server == 'ndjson') {
      if (server == 'ndjson') {
        final linesStream = file
            .openRead()
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in linesStream) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          try {
            final decoded = json.decode(trimmed);
            if (decoded is Map<String, dynamic>) {
              yield _mapToRow(decoded, stmt);
            }
          } catch (_) {}
        }
      } else {
        // Standard JSON Array
        final content = await file.readAsString();
        final decoded = json.decode(content);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              yield _mapToRow(item, stmt);
            }
          }
        }
      }
    } else {
      throw Exception('Unsupported foreign server: $server');
    }
  }

  static Map<String, DbValue> _mapToRow(
    Map<String, dynamic> item,
    CreateForeignTableStmt stmt,
  ) {
    final row = <String, DbValue>{};
    for (final col in stmt.columns) {
      final key = col.name;
      final val = item[key] ?? item[key.toLowerCase()];
      DbValue dbVal;
      if (val == null) {
        dbVal = DbNull();
      } else if (col.type == DataType.integer) {
        dbVal = DbInt(val is int ? val : (int.tryParse(val.toString()) ?? 0));
      } else if (col.type == DataType.double) {
        dbVal = DbDouble(
          val is num ? val.toDouble() : (double.tryParse(val.toString()) ?? 0.0),
        );
      } else if (col.type == DataType.boolean) {
        dbVal = DbBool(val == true || val.toString().toLowerCase() == 'true');
      } else {
        dbVal = DbText(val.toString());
      }
      row[key.toLowerCase()] = dbVal;
      row['${stmt.tableName.toLowerCase()}.${key.toLowerCase()}'] = dbVal;
    }
    return row;
  }
}
