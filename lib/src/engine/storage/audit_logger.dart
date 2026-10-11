import 'dart:convert';
import 'dart:io';

class AuditLogger {
  final String dbPath;
  final StringBuffer _buffer = StringBuffer();
  RandomAccessFile? _raf;
  bool _pendingWrite = false;

  AuditLogger(this.dbPath);
  bool enabled = true;

  void logQuery(String username, String query) {
    if (!enabled || dbPath == ':memory:' || identical(0, 0.0)) return;
    final timestamp = DateTime.now().toIso8601String();
    _buffer.writeln('[$timestamp] USER: $username | QUERY: $query');
    if (!_pendingWrite) {
      _pendingWrite = true;
      Future.microtask(() {
        _pendingWrite = false;
        _writeBufferSync();
      });
    }
  }

  void _writeBufferSync() {
    if (_buffer.isEmpty) return;
    try {
      if (_raf == null) {
        final auditFile = File('$dbPath/audit.log');
        if (!auditFile.parent.existsSync()) {
          auditFile.parent.createSync(recursive: true);
        }
        _raf = auditFile.openSync(mode: FileMode.writeOnlyAppend);
      }
      final str = _buffer.toString();
      _buffer.clear();
      _raf!.writeFromSync(utf8.encode(str));
    } catch (_) {}
  }

  void flushSync() {
    _writeBufferSync();
    try {
      _raf?.flushSync();
    } catch (_) {}
  }

  void closeSync() {
    flushSync();
    try {
      _raf?.closeSync();
    } catch (_) {}
    _raf = null;
  }
}
