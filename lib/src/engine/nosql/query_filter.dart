import 'document.dart';

/// Evaluates MongoDB-style query filters against [Document] instances.
class QueryFilter {
  /// Evaluates whether [doc] satisfies the filter specification [filter].
  static bool matches(Document doc, Map<String, dynamic>? filter) {
    if (filter == null || filter.isEmpty) return true;

    for (final entry in filter.entries) {
      final key = entry.key;
      final expected = entry.value;

      // Handle top-level logical operators
      if (key == r'$and') {
        if (expected is! List) return false;
        for (final subFilter in expected) {
          if (subFilter is Map<String, dynamic>) {
            if (!matches(doc, subFilter)) return false;
          }
        }
        continue;
      }

      if (key == r'$or') {
        if (expected is! List || expected.isEmpty) return false;
        bool anyMatched = false;
        for (final subFilter in expected) {
          if (subFilter is Map<String, dynamic>) {
            if (matches(doc, subFilter)) {
              anyMatched = true;
              break;
            }
          }
        }
        if (!anyMatched) return false;
        continue;
      }

      if (key == r'$nor') {
        if (expected is! List) return false;
        for (final subFilter in expected) {
          if (subFilter is Map<String, dynamic>) {
            if (matches(doc, subFilter)) return false;
          }
        }
        continue;
      }

      // Field condition evaluation (can be dotted path)
      final actual = doc.getByPath(key);

      if (!_evaluateFieldCondition(actual, expected)) {
        return false;
      }
    }

    return true;
  }

  static bool _evaluateFieldCondition(dynamic actual, dynamic expected) {
    if (expected is Map<String, dynamic>) {
      // Check if this map contains operator expressions
      final isOperatorMap = expected.keys.any((k) => k.startsWith(r'$'));
      if (isOperatorMap) {
        for (final opEntry in expected.entries) {
          final op = opEntry.key;
          final opVal = opEntry.value;

          if (!_evaluateOperator(op, actual, opVal)) {
            return false;
          }
        }
        return true;
      }
    }

    // Direct equality match
    return _compareEqual(actual, expected);
  }

  static bool _evaluateOperator(String op, dynamic actual, dynamic target) {
    switch (op) {
      case r'$eq':
        return _compareEqual(actual, target);
      case r'$ne':
        return !_compareEqual(actual, target);
      case r'$gt':
        final cmp = _compareValues(actual, target);
        return cmp != null && cmp > 0;
      case r'$gte':
        final cmp = _compareValues(actual, target);
        return cmp != null && cmp >= 0;
      case r'$lt':
        final cmp = _compareValues(actual, target);
        return cmp != null && cmp < 0;
      case r'$lte':
        final cmp = _compareValues(actual, target);
        return cmp != null && cmp <= 0;
      case r'$in':
        if (target is! List) return false;
        if (actual is List) {
          return actual.any((item) => target.any((t) => _compareEqual(item, t)));
        }
        return target.any((t) => _compareEqual(actual, t));
      case r'$nin':
        if (target is! List) return true;
        if (actual is List) {
          return !actual.any((item) => target.any((t) => _compareEqual(item, t)));
        }
        return !target.any((t) => _compareEqual(actual, t));
      case r'$exists':
        final exists = actual != null;
        return (target == true) ? exists : !exists;
      case r'$regex':
        if (actual == null) return false;
        final pattern = target.toString();
        try {
          final regex = RegExp(pattern, caseSensitive: false);
          return regex.hasMatch(actual.toString());
        } catch (_) {
          return false;
        }
      case r'$size':
        if (actual is! List) return false;
        return actual.length == (target is num ? target.toInt() : int.tryParse(target.toString()));
      case r'$all':
        if (actual is! List || target is! List) return false;
        return target.every((t) => actual.any((item) => _compareEqual(item, t)));
      case r'$elemMatch':
        if (actual is! List) return false;
        if (target is! Map<String, dynamic>) return false;
        return actual.any((item) {
          if (item is Map<String, dynamic>) {
            final subDoc = Document.fromJson(item);
            return matches(subDoc, target);
          }
          return _evaluateFieldCondition(item, target);
        });
      case r'$not':
        if (target is Map<String, dynamic>) {
          return !_evaluateFieldCondition(actual, target);
        }
        return !_compareEqual(actual, target);
      default:
        return false;
    }
  }

  static bool _compareEqual(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;

    if (a is num && b is num) {
      return a == b;
    }

    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_compareEqual(a[i], b[i])) return false;
      }
      return true;
    }

    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_compareEqual(a[key], b[key])) {
          return false;
        }
      }
      return true;
    }

    return a.toString() == b.toString();
  }

  static int? _compareValues(dynamic a, dynamic b) {
    if (a == null || b == null) return null;

    if (a is num && b is num) {
      return a.compareTo(b);
    }

    if (a is String && b is String) {
      return a.compareTo(b);
    }

    if (a is DateTime && b is DateTime) {
      return a.compareTo(b);
    }

    // Try parsing string dates
    if (a is String && b is String) {
      final da = DateTime.tryParse(a);
      final db = DateTime.tryParse(b);
      if (da != null && db != null) {
        return da.compareTo(db);
      }
    }

    return a.toString().compareTo(b.toString());
  }
}
