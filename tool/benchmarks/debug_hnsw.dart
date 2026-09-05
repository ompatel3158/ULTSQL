import 'dart:math';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/storage/hnsw_index.dart';

void main() {
  final hnsw = HnswIndex(
    indexPath: 'test_hnsw_debug.idx',
    autoSave: false,
    M: 32,
    M0: 64,
    efConstruction: 128,
    efSearch: 100,
  );
  hnsw.initSync();

  final List<DbVector> databaseVectors = [];
  final random = Random(42);

  const vectorCount = 1000;
  const numQueries = 50;

  print('Generating $vectorCount non-clustered vectors (768-dim)...');
  for (int i = 0; i < vectorCount; i++) {
    final elements = List<double>.generate(768, (j) => random.nextDouble());
    databaseVectors.add(DbVector(elements));
  }

  print('Inserting $vectorCount vectors into HNSW index...');
  for (int i = 0; i < databaseVectors.length; i++) {
    hnsw.insertSync(databaseVectors[i], 0, i);
  }

  print('Enter node: ${hnsw.enterNodeId}, Enter level: ${hnsw.enterLevel}');
  print('Nodes in index: ${hnsw.nodes.length}');

  // Average neighbors per node at level 0
  double avgN = 0.0;
  for (final node in hnsw.nodes) {
    avgN += node.neighbors[0].length;
  }
  print('Average neighbors at level 0: ${avgN / hnsw.nodes.length}');

  print('Running $numQueries non-clustered search queries to measure Recall@10...');
  double totalRecall = 0.0;
  for (int q = 0; q < numQueries; q++) {
    final queryVector = DbVector(List<double>.generate(768, (j) => random.nextDouble()));
    final hnswResults = hnsw.search(queryVector, 10);
    final flatResults = databaseVectors
        .asMap()
        .entries
        .map((entry) => MapEntry(entry.key, entry.value.distanceTo(queryVector)))
        .toList();
    flatResults.sort((a, b) => a.value.compareTo(b.value));

    final flatTop10Ids = flatResults.take(10).map((x) => x.key).toSet();
    final hnswTop10Ids = hnswResults.map((node) => node.slotId).toSet();

    int matchCount = 0;
    for (final id in hnswTop10Ids) {
      if (flatTop10Ids.contains(id)) {
        matchCount++;
      }
    }
    totalRecall += (matchCount / 10.0);
  }

  final avgRecall = (totalRecall / numQueries) * 100.0;
  print('Average Recall@10 over $numQueries queries (non-clustered data): ${avgRecall.toStringAsFixed(2)}%');
}
