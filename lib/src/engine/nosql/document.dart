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

  /// Creates a document from a raw JSON map, generating a unique ID if omitted.
  factory Document.fromJson(Map<String, dynamic> json, [String? fallbackId]) {
    final rawId = json['_id'] ?? fallbackId ?? _generateUniqueId();
    final id = rawId.toString();
    final map = Map<String, dynamic>.from(json);
    map['_id'] = id;
    return Document(id: id, data: map);
  }

  /// Generates a fast 24-character hex ID (similar to MongoDB ObjectId).
  static String _generateUniqueId() {
    final rand = Random.secure();
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final tsHex = ts.toRadixString(16).padLeft(8, '0');
    final randomHex = List.generate(
      16,
      (_) => rand.nextInt(16).toRadixString(16),
    ).join();
    return '$tsHex$randomHex';
  }

  /// Retrieves a value at the specified dotted path (e.g. `'profile.address.city'`, `'tags.0'`).
  dynamic getByPath(String path) {
    if (path == '_id' || path == 'id') return id;
    if (!path.contains('.')) return data[path];

    final parts = path.split('.');
    dynamic current = data;

    for (final part in parts) {
      if (current == null) return null;
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
