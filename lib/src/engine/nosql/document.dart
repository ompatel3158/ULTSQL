import 'dart:convert';
import 'dart:math';

/// Represents a schema-less JSON document with unique [_id] and deep dotted-path navigation.
class Document {
  /// The unique document identifier.
  final String id;

  /// The raw JSON data map for this document.
  final Map<String, dynamic> data;

  Document({required this.id, required Map<String, dynamic> data})
      : data = Map<String, dynamic>.from(data) {
    this.data['_id'] = id;
  }

  Document._(this.id, this.data);

  /// Creates a document from a raw JSON map, generating a unique ID if omitted.
  factory Document.fromJson(Map<String, dynamic> json, [String? fallbackId]) {
    final rawId = json['_id'] ?? fallbackId;
    final id = rawId != null ? rawId.toString() : _generateUniqueId();
    json['_id'] = id;
    return Document._(id, json);
  }

  static final Random _rand = Random();
  static final String _processHex = List.generate(
    10,
    (_) => _rand.nextInt(16).toRadixString(16),
  ).join();
  static int _counter = _rand.nextInt(0xFFFFFF);
  static int _lastSec = 0;
  static String _lastSecHex = '';

  /// Generates a fast 24-character hex ID (similar to MongoDB ObjectId).
  static String _generateUniqueId() {
    final c = (_counter = (_counter + 1) & 0xFFFFFF);
    if ((c & 0x3FF) == 0 || _lastSecHex.isEmpty) {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowSec != _lastSec) {
        _lastSec = nowSec;
        _lastSecHex = nowSec.toRadixString(16).padLeft(8, '0');
      }
    }
    final countHex = c.toRadixString(16).padLeft(6, '0');
    return '$_lastSecHex$_processHex$countHex';
  }

  /// Retrieves a value at the specified dotted path (e.g. `'profile.address.city'`, `'tags.0'`).
  dynamic getByPath(String path) {
    if (path == '_id' || path == 'id') return id;
    if (!path.contains('.')) return data[path];
    return getBySegments(path.split('.'));
  }

  /// Retrieves a value using pre-split path segments, avoiding repeated string splitting.
  dynamic getBySegments(List<String> parts) {
    if (parts.length == 1) {
      final p = parts[0];
      if (p == '_id' || p == 'id') return id;
      return data[p];
    }
    dynamic current = data;
    for (int i = 0; i < parts.length; i++) {
      if (current == null) return null;
      final part = parts[i];
      if (current is Map) {
        current = current[part];
      } else if (current is List) {
        final idx = int.tryParse(part);
        if (idx == null || idx < 0 || idx >= current.length) {
          return null;
        }
        current = current[idx];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Sets a value at the specified dotted path, creating nested maps if needed.
  void setByPath(String path, dynamic value) {
    if (path == '_id') return; // Cannot mutate _id
    if (!path.contains('.')) {
      data[path] = value;
      return;
    }

    final parts = path.split('.');
    dynamic current = data;

    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (current is Map) {
        if (!current.containsKey(part) || current[part] is! Map) {
          current[part] = <String, dynamic>{};
        }
        current = current[part];
      } else {
        return;
      }
    }

    if (current is Map) {
      current[parts.last] = value;
    }
  }

  /// Removes a field at the specified dotted path. Returns true if removed.
  bool removeByPath(String path) {
    if (path == '_id') return false;
    if (!path.contains('.')) {
      return data.remove(path) != null;
    }

    final parts = path.split('.');
    dynamic current = data;

    for (int i = 0; i < parts.length - 1; i++) {
      if (current is! Map) return false;
      current = current[parts[i]];
    }

    if (current is Map) {
      return current.remove(parts.last) != null;
    }
    return false;
  }

  /// Clones this document deeply.
  Document clone() {
    final clonedMap = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    return Document(id: id, data: clonedMap);
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
  Map<String, dynamic> toMap() => Map<String, dynamic>.from(data);

  @override
  String toString() => jsonEncode(data);
}
