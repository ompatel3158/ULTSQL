import '../executor/plan_nodes.dart';

/// LRU Prepared Query Plan Cache to accelerate query execution speed
/// by reusing parsed and optimized [PlanNode] execution trees.
class PlanCache {
  final int capacity;
  final Map<String, PlanNode> _cache = {};
  int _hits = 0;
  int _misses = 0;

  PlanCache({this.capacity = 500});

  int get hits => _hits;
  int get misses => _misses;
  int get size => _cache.length;
  double get hitRate =>
      (_hits + _misses) == 0 ? 0.0 : _hits / (_hits + _misses);

  /// Retrieves a cached query plan if present.
  PlanNode? get(String sql) {
    final key = _normalizeSql(sql);
    if (_cache.containsKey(key)) {
      _hits++;
      final plan = _cache.remove(key)!;
      _cache[key] = plan; // Move to back (most recently used)
      return plan;
    }
    _misses++;
    return null;
  }

  /// Caches a compiled query plan.
  void put(String sql, PlanNode plan) {
    final key = _normalizeSql(sql);
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= capacity) {
      _cache.remove(_cache.keys.first); // Evict oldest
    }
    _cache[key] = plan;
  }

  /// Clears the plan cache (e.g. when schema changes occur).
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  String _normalizeSql(String sql) {
    return sql.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Map<String, dynamic> getStats() {
    return {
      'capacity': capacity,
      'cached_plans': _cache.length,
      'hits': _hits,
      'misses': _misses,
      'hit_rate_pct': (hitRate * 100).toStringAsFixed(2),
    };
  }
}
