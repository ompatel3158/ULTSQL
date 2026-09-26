import 'document.dart';

/// Applies MongoDB-style atomic update operations to a [Document].
class DocumentMutator {
  /// Modifies [doc] in-place according to [updateSpec].
  /// Returns `true` if any field was changed.
  static bool applyUpdate(Document doc, Map<String, dynamic> updateSpec) {
    if (updateSpec.isEmpty) return false;

    // Check if the update is a replacement document (no top-level $ operators)
    final hasDollar = updateSpec.keys.any((k) => k.startsWith(r'$'));
    if (!hasDollar) {
      final oldId = doc.id;
      doc.data.clear();
      doc.data.addAll(updateSpec);
      doc.data['_id'] = oldId;
      return true;
    }

    bool mutated = false;

    for (final entry in updateSpec.entries) {
      final op = entry.key;
      final payload = entry.value;

      if (payload is! Map<String, dynamic>) continue;

      switch (op) {
        case r'$set':
          for (final f in payload.entries) {
            if (f.key == '_id') continue;
            doc.setByPath(f.key, f.value);
            mutated = true;
          }
          break;

        case r'$unset':
          for (final f in payload.entries) {
            if (f.key == '_id') continue;
            if (doc.removeByPath(f.key)) {
              mutated = true;
            }
          }
          break;

        case r'$inc':
          for (final f in payload.entries) {
            if (f.key == '_id') continue;
            final current = doc.getByPath(f.key);
            final delta = f.value;
            if (delta is num) {
              final newVal = (current is num) ? (current + delta) : delta;
              doc.setByPath(f.key, newVal);
              mutated = true;
            }
          }
          break;

        case r'$mul':
          for (final f in payload.entries) {
            if (f.key == '_id') continue;
            final current = doc.getByPath(f.key);
            final factor = f.value;
            if (factor is num) {
              final newVal = (current is num) ? (current * factor) : 0;
              doc.setByPath(f.key, newVal);
              mutated = true;
            }
          }
          break;

        case r'$push':
          for (final f in payload.entries) {
            if (f.key == '_id') continue;
            var list = doc.getByPath(f.key);
            if (list == null) {
              list = <dynamic>[];
              doc.setByPath(f.key, list);
            }
            if (list is List) {
              final val = f.value;
              if (val is Map<String, dynamic> && val.containsKey(r'$each')) {
                final eachItems = val[r'$each'];
                if (eachItems is Iterable) {
                  list.addAll(eachItems);
                  mutated = true;
                }
              } else {
                list.add(val);
                mutated = true;
              }
            }
          }
          break;

        case r'$pull':
          for (final f in payload.entries) {
            if (f.key == '_id') continue;
            final list = doc.getByPath(f.key);
            if (list is List) {
              final target = f.value;
              final beforeLen = list.length;
              list.removeWhere((item) => item.toString() == target.toString());
              if (list.length != beforeLen) {
                mutated = true;
              }
            }
          }
          break;

        case r'$addToSet':
          for (final f in payload.entries) {
            if (f.key == '_id') continue;
            var list = doc.getByPath(f.key);
            if (list == null) {
              list = <dynamic>[];
              doc.setByPath(f.key, list);
            }
            if (list is List) {
              final val = f.value;
              if (val is Map<String, dynamic> && val.containsKey(r'$each')) {
                final eachItems = val[r'$each'];
                if (eachItems is Iterable) {
                  for (final item in eachItems) {
                    if (!list.any((x) => x.toString() == item.toString())) {
                      list.add(item);
                      mutated = true;
                    }
                  }
                }
              } else {
                if (!list.any((x) => x.toString() == val.toString())) {
                  list.add(val);
                  mutated = true;
                }
              }
            }
          }
          break;

        case r'$min':
          for (final f in payload.entries) {
            if (f.key == '_id') continue;
            final current = doc.getByPath(f.key);
            final target = f.value;
            if (current == null || (target is Comparable && (target.compareTo(current) < 0))) {
              doc.setByPath(f.key, target);
              mutated = true;
            }
          }
          break;

        case r'$max':
          for (final f in payload.entries) {
            if (f.key == '_id') continue;
            final current = doc.getByPath(f.key);
            final target = f.value;
            if (current == null || (target is Comparable && (target.compareTo(current) > 0))) {
              doc.setByPath(f.key, target);
              mutated = true;
            }
          }
          break;
      }
    }

    return mutated;
  }
}
