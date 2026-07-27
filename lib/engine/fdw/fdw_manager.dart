import 'dart:io';
import '../parser/ast.dart';
import '../executor/value.dart';

abstract class FdwManager {
  static Stream<Map<String, DbValue>> scan(CreateForeignTableStmt stmt) async* {
    final server = stmt.serverName.toLowerCase();
    final filename = stmt.options['filename'];
    if (filename == null) {
      throw Exception('Foreign table requires filename in options');
    }

    final file = File(filename);
    if (!await file.exists()) {
      return;
    }

    if (server == 'csv') {
      final lines = await file.readAsLines();
      if (lines.isEmpty) return;
      
      final header = lines[0].split(',');
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        final parts = lines[i].split(',');
        final row = <String, DbValue>{};
        for (int j = 0; j < header.length && j < parts.length; j++) {
          final colName = header[j].trim();
          final val = parts[j].trim();
          final def = stmt.columns.firstWhere((c) => c.name == colName, orElse: () => ColumnDef(colName, DataType.text));
          
          DbValue dbVal;
          if (def.type == DataType.integer) {
            dbVal = DbInt(int.tryParse(val) ?? 0);
          } else if (def.type == DataType.double) {
            dbVal = DbDouble(double.tryParse(val) ?? 0.0);
          } else {
            dbVal = DbText(val);
          }
          row[colName] = dbVal;
        }
        yield row;
      }
    } else {
      throw Exception('Unsupported foreign server: \$server');
    }
  }
}
