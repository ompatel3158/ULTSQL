import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  test('Flight Recorder Telemetry Report test', () async {
    final tempDir = await Directory.systemTemp.createTemp('ultsql_telemetry_test_');
    final db = Database(tempDir.path);
    final interpreter = Interpreter(db);

    try {
      await interpreter.executeScript("CREATE TABLE telemetry_users (id INT PRIMARY KEY, name TEXT, score INT)");
      await interpreter.executeScript("INSERT INTO telemetry_users VALUES (1, 'Alice', 95)");
      await interpreter.executeScript("INSERT INTO telemetry_users VALUES (2, 'Bob', 80)");
      await interpreter.executeScript("INSERT INTO telemetry_users VALUES (3, 'Charlie', 90)");

      // Record telemetry for SELECT query
      FlightRecorder.start("SELECT name, score FROM telemetry_users WHERE score >= 90 ORDER BY score DESC");
      FlightRecorder.recordStep(
        nodeType: 'SeqScanNode',
        description: 'Scanned 3 rows from telemetry_users',
        rowsProcessed: 3,
        durationMicroseconds: 120,
      );
      FlightRecorder.recordStep(
        nodeType: 'FilterNode',
        description: 'Filtered rows where score >= 90',
        rowsProcessed: 2,
        durationMicroseconds: 45,
      );
      FlightRecorder.recordStep(
        nodeType: 'SortNode',
        description: 'Sorted 2 rows by score DESC',
        rowsProcessed: 2,
        durationMicroseconds: 30,
      );

      final res = await interpreter.executeScript("SELECT name, score FROM telemetry_users WHERE score >= 90 ORDER BY score DESC");
      final report = interpreter.lastTelemetryReport ?? FlightRecorder.stop(rowsReturned: res.rows.length);

      expect(report.sql.contains("SELECT"), true);
      expect(report.rowsReturned, 2);
      expect(report.steps.length >= 3, true);
      expect(report.steps[0].nodeType, 'SeqScanNode');

      final md = report.toMarkdown();
      expect(md.contains("Flight Recorder Diagnostics"), true);
      expect(md.contains("SeqScanNode"), true);
      expect(md.contains("FilterNode"), true);

      final jsonMap = report.toJson();
      expect(jsonMap['rowsReturned'], 2);

      print("FLIGHT RECORDER TELEMETRY REPORT TEST PASSED CLEANLY!");
      print("\nSample Markdown Report:\n$md");
    } finally {
      db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}
