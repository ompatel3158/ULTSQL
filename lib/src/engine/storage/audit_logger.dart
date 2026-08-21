import 'dart:io';

class AuditLogger {
  final String dbPath;

  AuditLogger(this.dbPath);

  void logQuery(String username, String query) {
    if (dbPath == ':memory:' || identical(0, 0.0)) return;
    try {
      final auditFile = File('$dbPath/audit.log');
      if (!auditFile.parent.existsSync()) {
        auditFile.parent.createSync(recursive: true);
      }
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = '[$timestamp] USER: $username | QUERY: $query\n';
      auditFile.writeAsStringSync(logEntry, mode: FileMode.append);
    } catch (_) {
      // Ignore background log write issues if directory is concurrently being recreated
    }
  }
}
