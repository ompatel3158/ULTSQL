import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  group('Distributed Raft Consensus & Cluster Replication', () {
    test('3-Node Raft cluster conducts leader election and replicates state', () async {
      final transport = InMemoryRaftTransport();
      final committedCommandsNode1 = <String>[];
      final committedCommandsNode2 = <String>[];
      final committedCommandsNode3 = <String>[];

      final node1 = RaftClusterNode(
        nodeId: 'node_1',
        peers: ['node_2', 'node_3'],
        transport: transport,
        onStateCommitted: (e) => committedCommandsNode1.add(e.command),
      );

      final node2 = RaftClusterNode(
        nodeId: 'node_2',
        peers: ['node_1', 'node_3'],
        transport: transport,
        onStateCommitted: (e) => committedCommandsNode2.add(e.command),
      );

      final node3 = RaftClusterNode(
        nodeId: 'node_3',
        peers: ['node_1', 'node_2'],
        transport: transport,
        onStateCommitted: (e) => committedCommandsNode3.add(e.command),
      );

      transport.registerNode(node1);
      transport.registerNode(node2);
      transport.registerNode(node3);

      // Start follower nodes
      node2.start();
      node3.start();

      // Node 1 starts and initiates election
      node1.start();

      // Wait for leader election to stabilize
      int attempts = 0;
      RaftClusterNode? leader;
      while (attempts < 20 && leader == null) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (node1.role == RaftNodeRole.leader) leader = node1;
        if (node2.role == RaftNodeRole.leader) leader = node2;
        if (node3.role == RaftNodeRole.leader) leader = node3;
        attempts++;
      }

      expect(leader, isNotNull);
      expect(leader!.role, RaftNodeRole.leader);

      // Submit replicated write command to the leader
      final success = await leader.executeReplicatedCommand(
        "INSERT INTO cluster_log VALUES ('tx_101', 500);",
      );
      expect(success, isTrue);
      expect(leader.commitIndex, 1);

      // Give followers a brief moment to receive the commit index heartbeat
      await Future.delayed(const Duration(milliseconds: 100));

      final allCommitted = [
        committedCommandsNode1,
        committedCommandsNode2,
        committedCommandsNode3,
      ];
      final committingNodes = allCommitted.where((l) => l.isNotEmpty).length;
      // At least quorum (2 of 3 nodes) must have applied the state
      expect(committingNodes >= 2, isTrue);

      node1.stop();
      node2.stop();
      node3.stop();
    });
  });
}
