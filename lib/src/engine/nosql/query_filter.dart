import 'document.dart';
import '../executor/value.dart';

/// Evaluates MongoDB-style query filters against [Document] instances.
class QueryFilter {
  /// Compiles a query filter for repeated high-throughput evaluation.
  static CompiledQueryFilter compile(Map<String, dynamic>? filter) {
    if (filter == null || filter.isEmpty) return CompiledQueryFilter.empty;
    return CompiledQueryFilter.compile(filter);
  }

  /// Evaluates whether raw [id] and [docVal] satisfy [filter] without decoding the full JSON document.
  static bool matchesRaw(String id, DbValue docVal, Map<String, dynamic>? filter) {
    if (filter == null || filter.isEmpty) return true;
    return compile(filter).matchesRaw(id, docVal);
  }

  /// Evaluates whether [doc] satisfies the filter specification [filter].
  static bool matches(Document doc, Map<String, dynamic>? filter) {
    if (filter == null || filter.isEmpty) return true;
    return compile(filter).matches(doc);
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

/// A pre-compiled, zero-allocation query filter representation for high-throughput scans.
class CompiledQueryFilter {
  static const CompiledQueryFilter empty = CompiledQueryFilter(
    rules: [],
    andFilters: null,
    orFilters: null,
    norFilters: null,
  );

  final List<CompiledFilterRule> rules;
  final List<CompiledQueryFilter>? andFilters;
  final List<CompiledQueryFilter>? orFilters;
  final List<CompiledQueryFilter>? norFilters;

  const CompiledQueryFilter({
    required this.rules,
    this.andFilters,
    this.orFilters,
    this.norFilters,
  });

  static CompiledQueryFilter compile(Map<String, dynamic> filter) {
    if (filter.isEmpty) return empty;

    List<CompiledQueryFilter>? andList;
    List<CompiledQueryFilter>? orList;
    List<CompiledQueryFilter>? norList;
    final rules = <CompiledFilterRule>[];

    for (final entry in filter.entries) {
      final key = entry.key;
      final expected = entry.value;

      if (key == r'$and' && expected is List) {
        andList ??= [];
        for (final sub in expected) {
          if (sub is Map<String, dynamic>) {
            andList.add(compile(sub));
          }
        }
        continue;
      }
      if (key == r'$or' && expected is List) {
        orList ??= [];
        for (final sub in expected) {
          if (sub is Map<String, dynamic>) {
            orList.add(compile(sub));
          }
        }
        continue;
      }
      if (key == r'$nor' && expected is List) {
        norList ??= [];
        for (final sub in expected) {
          if (sub is Map<String, dynamic>) {
            norList.add(compile(sub));
          }
        }
        continue;
      }

      final isId = key == '_id' || key == 'id';
      final segments = key.contains('.') ? key.split('.') : [key];
      bool isOperatorMap = false;
      List<MapEntry<String, dynamic>>? operators;

      if (expected is Map<String, dynamic>) {
        final hasOp = expected.keys.any((k) => k.startsWith(r'$'));
        if (hasOp) {
          isOperatorMap = true;
          operators = expected.entries.toList();
        }
      }

      rules.add(CompiledFilterRule(
        key: key,
        segments: segments,
        isId: isId,
        expected: expected,
        isOperatorMap: isOperatorMap,
        operators: operators,
      ));
    }

    return CompiledQueryFilter(
      rules: rules,
      andFilters: andList,
      orFilters: orList,
      norFilters: norList,
    );
  }

  bool matches(Document doc) {
    if (andFilters != null) {
      for (int i = 0; i < andFilters!.length; i++) {
        if (!andFilters![i].matches(doc)) return false;
      }
    }
    if (orFilters != null) {
      if (orFilters!.isEmpty) return false;
      bool any = false;
      for (int i = 0; i < orFilters!.length; i++) {
        if (orFilters![i].matches(doc)) {
          any = true;
          break;
        }
      }
      if (!any) return false;
    }
    if (norFilters != null) {
      for (int i = 0; i < norFilters!.length; i++) {
        if (norFilters![i].matches(doc)) return false;
      }
    }

    for (int i = 0; i < rules.length; i++) {
      final rule = rules[i];
      final actual = rule.isId ? doc.id : doc.getBySegments(rule.segments);
      if (!rule.eval(actual)) return false;
    }
    return true;
  }

  bool matchesRaw(String id, DbValue docVal) {
    if (andFilters != null) {
      for (int i = 0; i < andFilters!.length; i++) {
        if (!andFilters![i].matchesRaw(id, docVal)) return false;
      }
    }
    if (orFilters != null) {
      if (orFilters!.isEmpty) return false;
      bool any = false;
      for (int i = 0; i < orFilters!.length; i++) {
        if (orFilters![i].matchesRaw(id, docVal)) {
          any = true;
          break;
        }
      }
      if (!any) return false;
    }
    if (norFilters != null) {
      for (int i = 0; i < norFilters!.length; i++) {
        if (norFilters![i].matchesRaw(id, docVal)) return false;
      }
    }

    for (int i = 0; i < rules.length; i++) {
      final rule = rules[i];
      dynamic actual;
      if (rule.isId) {
        actual = id;
      } else if (docVal is DbJson) {
        actual = docVal.extractPath(rule.segments).value;
      } else {
        actual = extractJsonPathRaw(docVal.toString(), rule.segments).value;
      }
      if (!rule.eval(actual)) return false;
    }
    return true;
  }
}

class CompiledFilterRule {
  final String key;
  final List<String> segments;
  final bool isId;
  final dynamic expected;
  final bool isOperatorMap;
  final List<MapEntry<String, dynamic>>? operators;

  CompiledFilterRule({
    required this.key,
    required this.segments,
    required this.isId,
    required this.expected,
    required this.isOperatorMap,
    this.operators,
  });

  bool eval(dynamic actual) {
    if (isOperatorMap && operators != null) {
      for (int i = 0; i < operators!.length; i++) {
        final op = operators![i];
        if (!QueryFilter._evaluateOperator(op.key, actual, op.value)) {
          return false;
        }
      }
      return true;
    }
    return QueryFilter._compareEqual(actual, expected);
  }
}
