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

  final List<List<double>> centroids = List.generate(5, (_) => List.generate(768, (_) => random.nextDouble()));

  for (int i = 0; i < 10000; i++) { // Let's use 10000 vectors for quick test
    final centroid = centroids[i % 5];
    final elements = List<double>.generate(768, (j) => centroid[j] + 0.1 * random.nextDouble());
    databaseVectors.add(DbVector(elements));
  }

  print('Inserting 1000 vectors...');
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

  final queryCentroid = centroids[random.nextInt(5)];
  final queryVector = DbVector(List<double>.generate(768, (j) => queryCentroid[j] + 0.1 * random.nextDouble()));

  final hnswResults = hnsw.search(queryVector, 10);
  print('HNSW Search TOP 10 Results:');
  for (final node in hnswResults) {
    print('  Node ID: ${node.id}, Slot ID: ${node.slotId}, Dist: ${node.vector.distanceTo(queryVector)}');
  }

  final flatResults = databaseVectors
      .asMap()
      .entries
      .map((entry) => MapEntry(entry.key, entry.value.distanceTo(queryVector)))
      .toList();
  flatResults.sort((a, b) => a.value.compareTo(b.value));

  print('Flat Search TOP 10 Results:');
  for (final entry in flatResults.take(10)) {
    print('  Index: ${entry.key}, Dist: ${entry.value}');
  }

  final flatTop10Ids = flatResults.take(10).map((x) => x.key).toSet();
  final hnswTop10Ids = hnswResults.map((node) => node.slotId).toSet();

  int matchCount = 0;
  for (final id in hnswTop10Ids) {
    if (flatTop10Ids.contains(id)) {
      matchCount++;
    }
  }
  print('Recall: ${matchCount / 10.0 * 100}%');
}
