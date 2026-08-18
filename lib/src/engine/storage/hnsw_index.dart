import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:ultsql/src/engine/executor/value.dart';

class HnswNode {
  final int id;
  final DbVector vector;
  final int pageId;
  final int slotId;
  // neighbors[level] contains lists of neighbor node IDs at that level
  final List<List<int>> neighbors;

  HnswNode({
    required this.id,
    required this.vector,
    required this.pageId,
    required this.slotId,
    required this.neighbors,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'vector': vector.value,
    'pageId': pageId,
    'slotId': slotId,
    'neighbors': neighbors,
  };

  factory HnswNode.fromJson(Map<String, dynamic> json) {
    final list = (json['neighbors'] as List)
        .map((l) => List<int>.from(l as List))
        .toList();
    final vecList = List<double>.from(json['vector'] as List);
    return HnswNode(
      id: json['id'],
      vector: DbVector(vecList),
      pageId: json['pageId'],
      slotId: json['slotId'],
      neighbors: list,
    );
  }
}

class HnswIndex {
  final String indexPath;
  final int M;
  final int M0;
  final int efConstruction;
  final int efSearch;
  final double mL;
  bool autoSave;
  String metric;

  final List<HnswNode> nodes = [];
  int? enterNodeId;
  int enterLevel = -1;
  final Random _random = Random(42); // Seeded for deterministic testing

  HnswIndex({
    required this.indexPath,
    this.M = 16,
    this.M0 = 32,
    this.efConstruction = 64,
    this.efSearch = 32,
    this.autoSave = true,
    this.metric = 'euclidean',
  }) : mL = 1.0 / log(16); // M is 16

  void initSync() {
    final file = File(indexPath);
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        final data = json.decode(content);
        nodes.clear();
        for (final item in data['nodes']) {
          nodes.add(HnswNode.fromJson(item));
        }
        enterNodeId = data['enterNodeId'];
        enterLevel = data['enterLevel'];
        if (metric == 'euclidean' && data['metric'] != null) {
          metric = data['metric'];
        }
      } catch (_) {
        // Fallback if file is empty/corrupt
      }
    }
  }

  void saveSync() {
    final file = File(indexPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    final data = {
      'enterNodeId': enterNodeId,
      'enterLevel': enterLevel,
      'metric': metric,
      'nodes': nodes.map((n) => n.toJson()).toList(),
    };
    file.writeAsStringSync(json.encode(data));
  }

  double _calculateDistance(DbVector a, DbVector b) {
    switch (metric.toLowerCase()) {
      case 'cosine':
        return a.cosineDistanceTo(b);
      case 'dot':
        return a.dotProductTo(b);
      case 'euclidean':
      default:
        return a.distanceTo(b);
    }
  }

  void insertSync(DbVector vector, int pageId, int slotId) {
    final newNodeId = nodes.length;
    final int level = _getRandomLevel();

    final neighbors = List<List<int>>.generate(level + 1, (_) => []);
    final newNode = HnswNode(
      id: newNodeId,
      vector: vector,
      pageId: pageId,
      slotId: slotId,
      neighbors: neighbors,
    );
    nodes.add(newNode);

    if (enterNodeId == null) {
      enterNodeId = newNodeId;
      enterLevel = level;
      if (autoSave) {
        saveSync();
      }
      return;
    }

    int currEnterNode = enterNodeId!;
    int currEnterLevel = enterLevel;

    // Phase 1: Search top-down to find closest node at the new node's level
    for (int l = currEnterLevel; l > level; l--) {
      currEnterNode = _searchLayerGreedy(vector, currEnterNode, l);
    }

    // Phase 2: Insert into levels from min(level, enterLevel) down to 0
    int startLevel = level < currEnterLevel ? level : currEnterLevel;
    List<int> enterNodes = [currEnterNode];

    for (int l = startLevel; l >= 0; l--) {
      final candidates = _searchLayer(vector, enterNodes, efConstruction, l);
      final selectedNeighbors = _selectNeighbors(
        vector,
        candidates,
        l == 0 ? M0 : M,
      );
      for (final neighborId in selectedNeighbors) {
        final neighborNode = nodes[neighborId];
        newNode.neighbors[l].add(neighborId);
        neighborNode.neighbors[l].add(newNodeId);
      }
      enterNodes = candidates;
    }

    if (level > enterLevel) {
      enterNodeId = newNodeId;
      enterLevel = level;
    }

    if (autoSave) {
      saveSync();
    }
  }

  int _getRandomLevel() {
    double r = _random.nextDouble();
    if (r == 0) r = 0.0000001;
    return (-log(r) * mL).floor();
  }

  int _searchLayerGreedy(DbVector query, int enterNodeId, int level) {
    int currNodeId = enterNodeId;
    double currDist = _calculateDistance(nodes[currNodeId].vector, query);
    bool changed = true;

    while (changed) {
      changed = false;
      final node = nodes[currNodeId];
      if (level < node.neighbors.length) {
        for (final neighborId in node.neighbors[level]) {
          final dist = _calculateDistance(nodes[neighborId].vector, query);
          if (dist < currDist) {
            currDist = dist;
            currNodeId = neighborId;
            changed = true;
          }
        }
      }
    }
    return currNodeId;
  }

  List<int> _searchLayer(
    DbVector query,
    List<int> enterNodes,
    int ef,
    int level, {
    bool Function(int pageId, int slotId)? filter,
  }) {
    final visited = <int>{...enterNodes};
    final candidates = <_HnswDistance>[];
    for (final id in enterNodes) {
      candidates.add(
        _HnswDistance(id, _calculateDistance(nodes[id].vector, query)),
      );
    }
    candidates.sort((a, b) => a.distance.compareTo(b.distance));

    final results = <_HnswDistance>[];
    for (final c in candidates) {
      final node = nodes[c.id];
      if (filter == null || filter(node.pageId, node.slotId)) {
        results.add(c);
      }
    }

    while (candidates.isNotEmpty) {
      final curr = candidates.removeAt(0);

      if (results.isNotEmpty) {
        final furthestResult = results.last;
        if (results.length >= ef && curr.distance > furthestResult.distance) {
          break;
        }
      }

      final node = nodes[curr.id];
      if (level < node.neighbors.length) {
        for (final neighborId in node.neighbors[level]) {
          if (!visited.contains(neighborId)) {
            visited.add(neighborId);
            final dist = _calculateDistance(nodes[neighborId].vector, query);

            if (results.isEmpty ||
                dist < results.last.distance ||
                results.length < ef) {
              final newDist = _HnswDistance(neighborId, dist);

              int insertPos = candidates.indexWhere((c) => c.distance > dist);
              if (insertPos == -1) {
                candidates.add(newDist);
              } else {
                candidates.insert(insertPos, newDist);
              }

              final neighborNode = nodes[neighborId];
              if (filter == null ||
                  filter(neighborNode.pageId, neighborNode.slotId)) {
                int resPos = results.indexWhere((r) => r.distance > dist);
                if (resPos == -1) {
                  results.add(newDist);
                } else {
                  results.insert(resPos, newDist);
                }

                if (results.length > ef) {
                  results.removeLast();
                }
              }
            }
          }
        }
      }
    }

    return results.map((r) => r.id).toList();
  }

  List<int> _selectNeighbors(DbVector query, List<int> candidates, int count) {
    if (candidates.length <= count) return candidates;
    final list = candidates
        .map(
          (id) =>
              _HnswDistance(id, _calculateDistance(nodes[id].vector, query)),
        )
        .toList();
    list.sort((a, b) => a.distance.compareTo(b.distance));
    return list.take(count).map((x) => x.id).toList();
  }

  List<HnswNode> search(
    DbVector query,
    int k, {
    bool Function(int pageId, int slotId)? filter,
  }) {
    if (nodes.isEmpty || enterNodeId == null) return [];

    int currEnterNode = enterNodeId!;
    int currEnterLevel = enterLevel;

    for (int l = currEnterLevel; l > 0; l--) {
      currEnterNode = _searchLayerGreedy(query, currEnterNode, l);
    }

    final candidates = _searchLayer(
      query,
      [currEnterNode],
      efSearch > k ? efSearch : k,
      0,
      filter: filter,
    );

    final results = candidates
        .map(
          (id) =>
              _HnswDistance(id, _calculateDistance(nodes[id].vector, query)),
        )
        .toList();
    results.sort((a, b) => a.distance.compareTo(b.distance));

    return results.take(k).map((r) => nodes[r.id]).toList();
  }
}

class _HnswDistance {
  final int id;
  final double distance;
  _HnswDistance(this.id, this.distance);
}
