import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:ultsql/src/engine/executor/value.dart';

class IvfFlatNode {
  final DbVector vector;
  final int pageId;
  final int slotId;

  IvfFlatNode({
    required this.vector,
    required this.pageId,
    required this.slotId,
  });

  Map<String, dynamic> toJson() => {
        'vector': vector.value,
        'pageId': pageId,
        'slotId': slotId,
      };

  factory IvfFlatNode.fromJson(Map<String, dynamic> json) {
    final vecList = List<double>.from(json['vector'] as List);
    return IvfFlatNode(
      vector: DbVector(vecList),
      pageId: json['pageId'],
      slotId: json['slotId'],
    );
  }
}

class IvfFlatIndex {
  final String indexPath;
  bool autoSave;
  String metric;
  int numCentroids;
  int nprobe;

  final List<DbVector> centroids = [];
  final Map<int, List<IvfFlatNode>> buckets = {};
  final List<IvfFlatNode> _tempNodes = [];

  IvfFlatIndex({
    required this.indexPath,
    this.numCentroids = 10,
    this.nprobe = 3,
    this.autoSave = true,
    this.metric = 'euclidean',
  });

  void initSync() {
    final file = File(indexPath);
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        final data = json.decode(content);
        
        if (data['metric'] != null) metric = data['metric'];
        if (data['numCentroids'] != null) numCentroids = data['numCentroids'];
        if (data['nprobe'] != null) nprobe = data['nprobe'];

        centroids.clear();
        if (data['centroids'] != null) {
          for (final c in data['centroids']) {
            centroids.add(DbVector(List<double>.from(c)));
          }
        }

        buckets.clear();
        if (data['buckets'] != null) {
          final bMap = data['buckets'] as Map<String, dynamic>;
          bMap.forEach((key, val) {
            final idx = int.parse(key);
            final nodeList = (val as List).map((n) => IvfFlatNode.fromJson(n)).toList();
            buckets[idx] = nodeList;
          });
        }
        
        _tempNodes.clear();
        if (data['tempNodes'] != null) {
          for (final n in data['tempNodes']) {
            _tempNodes.add(IvfFlatNode.fromJson(n));
          }
        }
      } catch (_) {
        // Fallback if file is empty/corrupt
      }
    }
  }

  void trainAndPartition() {
    if (_tempNodes.isEmpty) return;
    
    int k = numCentroids;
    if (k > _tempNodes.length) {
      k = _tempNodes.length;
    }
    if (k < 1) k = 1;

    final random = Random(42);
    final tempNodesCopy = List<IvfFlatNode>.from(_tempNodes);
    tempNodesCopy.shuffle(random);
    
    centroids.clear();
    for (int i = 0; i < k; i++) {
      centroids.add(tempNodesCopy[i].vector);
    }

    // K-Means clustering (10 iterations)
    for (int iter = 0; iter < 10; iter++) {
      final groups = List<List<DbVector>>.generate(k, (_) => []);
      for (final node in _tempNodes) {
        int bestIdx = 0;
        double bestDist = double.infinity;
        for (int i = 0; i < k; i++) {
          final dist = _calculateDistance(node.vector, centroids[i]);
          if (dist < bestDist) {
            bestDist = dist;
            bestIdx = i;
          }
        }
        groups[bestIdx].add(node.vector);
      }

      for (int i = 0; i < k; i++) {
        if (groups[i].isNotEmpty) {
          final dim = groups[i].first.value.length;
          final meanVals = List<double>.filled(dim, 0.0);
          for (final vec in groups[i]) {
            for (int d = 0; d < dim; d++) {
              meanVals[d] += vec.value[d];
            }
          }
          for (int d = 0; d < dim; d++) {
            meanVals[d] /= groups[i].length;
          }
          centroids[i] = DbVector(meanVals);
        } else {
          centroids[i] = _tempNodes[random.nextInt(_tempNodes.length)].vector;
        }
      }
    }

    buckets.clear();
    for (int i = 0; i < k; i++) {
      buckets[i] = [];
    }
    for (final node in _tempNodes) {
      int bestIdx = 0;
      double bestDist = double.infinity;
      for (int i = 0; i < k; i++) {
        final dist = _calculateDistance(node.vector, centroids[i]);
        if (dist < bestDist) {
          bestDist = dist;
          bestIdx = i;
        }
      }
      buckets[bestIdx]!.add(node);
    }

    _tempNodes.clear();
  }

  void saveSync() {
    if (_tempNodes.isNotEmpty) {
      trainAndPartition();
    }
    
    final file = File(indexPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    
    final data = {
      'metric': metric,
      'numCentroids': numCentroids,
      'nprobe': nprobe,
      'centroids': centroids.map((c) => c.value).toList(),
      'buckets': buckets.map((key, val) => MapEntry(key.toString(), val.map((n) => n.toJson()).toList())),
      'tempNodes': _tempNodes.map((n) => n.toJson()).toList(),
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
    final node = IvfFlatNode(vector: vector, pageId: pageId, slotId: slotId);
    if (centroids.isEmpty) {
      _tempNodes.add(node);
    } else {
      int bestIdx = 0;
      double bestDist = double.infinity;
      for (int i = 0; i < centroids.length; i++) {
        final dist = _calculateDistance(vector, centroids[i]);
        if (dist < bestDist) {
          bestDist = dist;
          bestIdx = i;
        }
      }
      buckets.putIfAbsent(bestIdx, () => []).add(node);
    }
    if (autoSave) {
      saveSync();
    }
  }

  List<IvfFlatNode> search(DbVector query, int limit, {bool Function(int pageId, int slotId)? filter}) {
    if (centroids.isEmpty) {
      final list = <_IvfFlatDistance>[];
      for (final node in _tempNodes) {
        if (filter == null || filter(node.pageId, node.slotId)) {
          list.add(_IvfFlatDistance(node, _calculateDistance(node.vector, query)));
        }
      }
      list.sort((a, b) => a.distance.compareTo(b.distance));
      return list.take(limit).map((x) => x.node).toList();
    }

    final centroidDists = <_CentroidDistance>[];
    for (int i = 0; i < centroids.length; i++) {
      centroidDists.add(_CentroidDistance(i, _calculateDistance(centroids[i], query)));
    }
    centroidDists.sort((a, b) => a.distance.compareTo(b.distance));

    final probeCentroids = centroidDists.take(nprobe).map((x) => x.index).toList();

    final candidates = <_IvfFlatDistance>[];
    for (final cIdx in probeCentroids) {
      final bucketNodes = buckets[cIdx];
      if (bucketNodes != null) {
        for (final node in bucketNodes) {
          if (filter == null || filter(node.pageId, node.slotId)) {
            candidates.add(_IvfFlatDistance(node, _calculateDistance(node.vector, query)));
          }
        }
      }
    }

    candidates.sort((a, b) => a.distance.compareTo(b.distance));
    return candidates.take(limit).map((x) => x.node).toList();
  }
}

class _IvfFlatDistance {
  final IvfFlatNode node;
  final double distance;
  _IvfFlatDistance(this.node, this.distance);
}

class _CentroidDistance {
  final int index;
  final double distance;
  _CentroidDistance(this.index, this.distance);
}
