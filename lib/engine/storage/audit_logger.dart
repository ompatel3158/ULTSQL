import 'dart:io';

class AuditLogger {
  final File _auditFile;

  AuditLogger(String dbPath) : _auditFile = File('$dbPath/audit.log');

  void logQuery(String username, String query) {
    try {
      if (!_auditFile.parent.existsSync()) {
        _auditFile.parent.createSync(recursive: true);
      }
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = '[$timestamp] USER: $username | QUERY: $query\n';
      _auditFile.writeAsStringSync(logEntry, mode: FileMode.append);
    } catch (_) {
      // Ignore background log write issues if directory is concurrently being recreated
    }
  }
}
