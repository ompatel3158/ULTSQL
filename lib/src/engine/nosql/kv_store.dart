import 'dart:convert';
import '../executor/interpreter.dart';

class _KVEntry {
  final dynamic value;
  final int expiresAt; // Epoch milliseconds, 0 = never expires

  _KVEntry({required this.value, this.expiresAt = 0});

  bool get isExpired =>
      expiresAt > 0 && DateTime.now().millisecondsSinceEpoch >= expiresAt;
}

/// High-performance Key-Value engine with in-memory caching and persistent WAL durability.
class KVStore {
  final Database db;
  static const String tableName = '_kv_store';

  final Map<String, _KVEntry> _hotCache = {};
  bool _initialized = false;

  KVStore(this.db);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (!db.catalog.hasTable(tableName)) {
      final interpreter = Interpreter(db);
      await interpreter.executeScript(
        'CREATE TABLE IF NOT EXISTS $tableName (kv_key TEXT PRIMARY KEY, val TEXT, expires_at INT, val_type INT);',
      );
    } else {
      // Warm up cache from persistent disk table
      final interpreter = Interpreter(db);
      final res = await interpreter.executeScript(
        'SELECT kv_key, val, expires_at, val_type FROM $tableName;',
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final row in res.rows) {
        final k = row[0].toString();
        final rawVal = row[1].toString();
        final exp = int.tryParse(row[2].toString()) ?? 0;
        final typeCode = int.tryParse(row[3].toString()) ?? 0;

        if (exp == 0 || exp > now) {
          final decoded = _deserialize(rawVal, typeCode);
          _hotCache[k] = _KVEntry(value: decoded, expiresAt: exp);
        }
      }
    }
    _initialized = true;
  }

  /// Sets a [key]-[value] pair with optional Time-To-Live [ttl].
  Future<void> set(String key, dynamic value, {Duration? ttl}) async {
    await _ensureInitialized();
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = (ttl != null) ? (now + ttl.inMilliseconds) : 0;

    _hotCache[key] = _KVEntry(value: value, expiresAt: expiresAt);

    final (rawVal, typeCode) = _serialize(value);
    final interpreter = Interpreter(db);

    await interpreter.executeScript(
      "REPLACE INTO $tableName VALUES ('${_escapeSql(key)}', '${_escapeSql(rawVal)}', $expiresAt, $typeCode);",
    );
  }

  /// Retrieves the value for [key], or `null` if not found or expired.
  Future<dynamic> get(String key) async {
    await _ensureInitialized();
    final entry = _hotCache[key];
    if (entry != null) {
      if (entry.isExpired) {
        await delete(key);
        return null;
      }
      return entry.value;
    }
    return null;
  }

  /// Checks if [key] exists and is unexpired.
  Future<bool> has(String key) async {
    final val = await get(key);
    return val != null;
  }

  /// Deletes [key] from the store. Returns `true` if key was present.
  Future<bool> delete(String key) async {
    await _ensureInitialized();
    final removed = _hotCache.remove(key) != null;
    final interpreter = Interpreter(db);
    await interpreter.executeScript(
      "DELETE FROM $tableName WHERE kv_key = '${_escapeSql(key)}';",
    );
    return removed;
  }

  /// Atomically increments a numeric value by [amount] (default 1).
  Future<int> incr(String key, [int amount = 1]) async {
    await _ensureInitialized();
    final current = await get(key);
    final int currentVal = (current is num) ? current.toInt() : 0;
    final newVal = currentVal + amount;
    await set(key, newVal);
    return newVal;
  }

  /// Atomically decrements a numeric value by [amount] (default 1).
  Future<int> decr(String key, [int amount = 1]) async {
    return incr(key, -amount);
  }

  /// Retrieves multiple keys in a single operation.
  Future<Map<String, dynamic>> mget(List<String> keys) async {
    final result = <String, dynamic>{};
    for (final k in keys) {
      final val = await get(k);
      if (val != null) {
        result[k] = val;
      }
    }
    return result;
  }

  /// Sets multiple key-value pairs in a single high-throughput batch transaction.
  Future<void> mset(Map<String, dynamic> entries, {Duration? ttl}) async {
    await _ensureInitialized();
    if (entries.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = (ttl != null) ? (now + ttl.inMilliseconds) : 0;

    final batchRecords = <Map<String, dynamic>>[];
    for (final e in entries.entries) {
      _hotCache[e.key] = _KVEntry(value: e.value, expiresAt: expiresAt);
      final (rawVal, typeCode) = _serialize(e.value);
      batchRecords.add({
        'kv_key': e.key,
        'kv_value': rawVal,
        'expires_at': expiresAt,
        'type_code': typeCode,
      });
    }
    db.insertBatchRecordsSync(tableName, batchRecords);
  }

  /// Returns all active keys, optionally filtered by a glob wildcard [pattern].
  Future<List<String>> keys({String? pattern}) async {
    await _ensureInitialized();
    await pruneExpired();

    if (pattern == null || pattern == '*') {
      return _hotCache.keys.toList();
    }

    final regexPattern = '^${pattern.replaceAll('*', '.*')}\$';
    final regex = RegExp(regexPattern);
    return _hotCache.keys.where((k) => regex.hasMatch(k)).toList();
  }

  /// Clears all key-value entries.
  Future<void> clear() async {
    await _ensureInitialized();
    _hotCache.clear();
    final interpreter = Interpreter(db);
    await interpreter.executeScript('DELETE FROM $tableName;');
  }

  /// Cleans up any expired entries from memory and disk.
  Future<void> pruneExpired() async {
    final expiredKeys = <String>[];
    for (final entry in _hotCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    for (final k in expiredKeys) {
      _hotCache.remove(k);
    }
    if (expiredKeys.isNotEmpty) {
      final interpreter = Interpreter(db);
      final now = DateTime.now().millisecondsSinceEpoch;
      await interpreter.executeScript(
        'DELETE FROM $tableName WHERE expires_at > 0 AND expires_at <= $now;',
      );
    }
  }

  (String, int) _serialize(dynamic value) {
    if (value == null) return ('', 0);
    if (value is int) return (value.toString(), 1);
    if (value is double) return (value.toString(), 2);
    if (value is bool) return (value ? 'true' : 'false', 3);
    if (value is String) return (value, 4);
    // Maps & Lists
    return (jsonEncode(value), 5);
  }

  dynamic _deserialize(String raw, int typeCode) {
    switch (typeCode) {
      case 0:
        return null;
      case 1:
        return int.tryParse(raw) ?? 0;
      case 2:
        return double.tryParse(raw) ?? 0.0;
      case 3:
        return raw == 'true';
      case 4:
        return raw;
      case 5:
        try {
          return jsonDecode(raw);
        } catch (_) {
          return raw;
        }
      default:
        return raw;
    }
  }

  String _escapeSql(String s) => s.replaceAll("'", "''");
}
