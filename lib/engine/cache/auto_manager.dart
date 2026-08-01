import 'package:ultsql/engine/storage/catalog.dart';
import 'package:ultsql/engine/executor/interpreter.dart';

/// Autonomous Auto-Managing Engine: Monitors telemetry and auto-indexes slow query columns
class AutoManager {
  static final Map<String, int> _scanTelemetry = {};

  /// Clear telemetry map
  static void clearTelemetry() {
    _scanTelemetry.clear();
  }

  /// Records sequential table scan telemetry
  static void recordTableScan(String tableName, List<String> scannedColumns) {
    for (final col in scannedColumns) {
      final key = "$tableName:$col";
      _scanTelemetry[key] = (_scanTelemetry[key] ?? 0) + 1;
    }
  }

  /// Automatically generates missing B+ Tree indexes when sequential scan count exceeds threshold
  static Future<int> suggestAndBuildIndexes(Catalog catalog, Database db) async {
    int indexCreatedCount = 0;
    final entries = List<MapEntry<String, int>>.from(_scanTelemetry.entries);

    for (final entry in entries) {
      if (entry.value >= 3) {
        final parts = entry.key.split(':');
        final tableName = parts[0];
        final columnName = parts[1];
        final indexName = "idx_auto_${tableName}_$columnName";

        if (!catalog.hasIndex(indexName)) {
          final interpreter = Interpreter(db);
          await interpreter.executeScript(
            "CREATE INDEX IF NOT EXISTS $indexName ON $tableName ($columnName);",
          );
          indexCreatedCount++;
        }
      }
    }
    return indexCreatedCount;
  }
}
