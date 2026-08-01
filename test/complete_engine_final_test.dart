import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/storage/catalog.dart';
import 'package:ultsql/engine/parser/ast.dart';
import 'package:ultsql/engine/executor/value.dart';
import 'package:ultsql/engine/storage/parquet_engine.dart';
import 'package:ultsql/engine/network/raft_cluster.dart';
import 'package:ultsql/engine/spatial/h3_indexer.dart';
import 'package:ultsql/engine/storage/direct_io.dart';

void main() {
  test('Apache Parquet Columnar export and import roundtrip', () {
    final schema = TableSchema(
      name: 'metrics',
      columnNames: ['id', 'metric_name', 'val'],
      columnTypes: [DataType.integer, DataType.text, DataType.double],
    );

    final rows = [
      [DbInt(1), DbText('cpu_usage'), DbDouble(75.5)],
      [DbInt(2), DbText('mem_usage'), DbDouble(42.0)],
    ];

    final parquetBytes = ParquetEngine.exportToParquet(schema, rows);
    expect(parquetBytes.length, greaterThan(8));

    final importedRows = ParquetEngine.importFromParquet(parquetBytes, schema);
    expect(importedRows.length, equals(2));
    expect(importedRows[0][1].value, equals('cpu_usage'));
    expect(importedRows[1][2].value, equals(42.0));
  });

  test('Raft Multi-Master Consensus and 2PC Transaction Coordination', () {
    final node1 = RaftNode(nodeId: 'node-1');
    final node2 = RaftNode(nodeId: 'node-2');

    expect(node1.role, equals(RaftNodeRole.follower));

    node1.becomeCandidate();
    expect(node1.role, equals(RaftNodeRole.candidate));
    expect(node1.currentTerm, equals(1));

    final granted = node2.requestVote(1, 'node-1', 0, 0);
    expect(granted, isTrue);
    expect(node2.votedFor, equals('node-1'));

    node1.becomeLeader();
    expect(node1.role, equals(RaftNodeRole.leader));

    final coordinator = TwoPhaseCommitCoordinator();
    final prepared = coordinator.prepareTransaction('tx-101', ['node-1', 'node-2']);
    expect(prepared, isTrue);

    final committed = coordinator.commitTransaction('tx-101');
    expect(committed, isTrue);
    expect(coordinator.getTransactionState('tx-101'), equals('COMMITTED'));
  });

  test('H3 Hexagonal Hierarchical Spatial Indexing and k-ring search', () {
    final lat = 37.7749;
    final lng = -122.4194;
    final h3Index = H3Indexer.latLngToH3(lat, lng, 9);

    expect(h3Index, greaterThan(0));

    final coords = H3Indexer.h3ToLatLng(h3Index);
    expect(coords['lat'], closeTo(lat, 0.1));
    expect(coords['lng'], closeTo(lng, 0.1));

    final neighbors = H3Indexer.kRing(h3Index, 1);
    expect(neighbors.length, greaterThan(1));
  });

  test('Direct 4KB Aligned Memory I/O Buffer read and write', () {
    final directBuffer = DirectIoBuffer(4096);
    final data = Uint8List.fromList([10, 20, 30, 40, 50]);

    directBuffer.write(0, data);
    final slice = directBuffer.read(0, 5);

    expect(slice, equals(data));
  });
}
