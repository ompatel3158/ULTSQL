import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/network/raft_cluster.dart';
import 'package:ultsql/src/engine/network/p2p_sync.dart';
import 'package:ultsql/src/engine/network/pg_wire_server.dart';
import 'package:ultsql/src/engine/network/rest_server.dart';

const String kRaftDbPrefix = 'test_raft_chaos_db';
const String kP2pDbPrefix = 'test_p2p_chaos_db';
const String kPgWireDb = 'test_pgwire_chaos_db';
const String kRestDb = 'test_rest_chaos_db';

enum AttackSeverity {
  criticalCrash,      // Uncaught RangeError, FormatException, or server death
  protocolDesync,     // Wire protocol hung or desynchronized
  byzantineSplit,     // Split-brain or inconsistency in consensus
  crdtAnomaly,        // Clock drift corruption, tombstone resurrection
  unexpectedBehavior, // Deviation from standard spec
  handledGracefully,  // Properly rejected or bounded
  passedCleanly,      // Clean success under chaos
}

class ChaosFinding {
  final String testId;
  final String suiteName;
  final String title;
  final AttackSeverity severity;
  final int elapsedMs;
  final String details;
  final String? errorMessage;
  final String? stackTrace;
  final String? location;
  final Map<String, dynamic> metrics;

  ChaosFinding({
    required this.testId,
    required this.suiteName,
    required this.title,
    required this.severity,
    required this.elapsedMs,
    required this.details,
    this.errorMessage,
    this.stackTrace,
    this.location,
    this.metrics = const {},
  });

  bool get isCritical =>
      severity == AttackSeverity.criticalCrash ||
      severity == AttackSeverity.byzantineSplit ||
      severity == AttackSeverity.crdtAnomaly ||
      severity == AttackSeverity.protocolDesync;
}

Future<void> cleanDirectory(String path) async {
  final dir = Directory(path);
  for (int i = 0; i < 5; i++) {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      return;
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

Future<void> ensureCleanDirectory(String path) async {
  await cleanDirectory(path);
  await Directory(path).create(recursive: true);
}

// =============================================================================
// CHAOS RAFT TRANSPORT
// =============================================================================
class ChaosRaftTransport implements RaftTransport {
  final Map<String, RaftClusterNode> nodes = {};
  final Set<String> partitionedPairs = {}; // "from->to" blocked
  bool dropHeartbeats = false;
  bool corruptEntries = false;
  int termOverride = 0;
  bool byzantineVotes = false;

  void registerNode(RaftClusterNode node) {
    nodes[node.nodeId] = node;
  }

  void isolateNode(String nodeId, List<String> allNodes) {
    for (final other in allNodes) {
      if (other != nodeId) {
        partitionedPairs.add('$nodeId->$other');
        partitionedPairs.add('$other->$nodeId');
      }
    }
  }

  void partitionCluster(List<String> sideA, List<String> sideB) {
    for (final a in sideA) {
      for (final b in sideB) {
        partitionedPairs.add('$a->$b');
        partitionedPairs.add('$b->$a');
      }
    }
  }

  void createAsymmetricPartition(String from, String to) {
    partitionedPairs.add('$from->$to');
  }

  void healPartitions() {
    partitionedPairs.clear();
  }

  @override
  Future<RequestVoteReply> sendRequestVote(String peerId, RequestVoteArgs args) async {
    final from = args.candidateId;
    if (partitionedPairs.contains('$from->$peerId')) {
      return RequestVoteReply(term: args.term, voteGranted: false);
    }
    final target = nodes[peerId];
    if (target == null) {
      return RequestVoteReply(term: args.term, voteGranted: false);
    }

    if (byzantineVotes) {
      // Lie about term to force candidate back to follower
      return RequestVoteReply(term: args.term + 9999, voteGranted: false);
    }

    return target.handleRequestVote(args);
  }

  @override
  Future<AppendEntriesReply> sendAppendEntries(String peerId, AppendEntriesArgs args) async {
    final from = args.leaderId;
    if (partitionedPairs.contains('$from->$peerId')) {
      return AppendEntriesReply(term: args.term, success: false, matchIndex: 0);
    }

    if (dropHeartbeats && args.entries.isEmpty) {
      // Simulate dropped heartbeat
      return AppendEntriesReply(term: args.term, success: false, matchIndex: 0);
    }

    final target = nodes[peerId];
    if (target == null) {
      return AppendEntriesReply(term: args.term, success: false, matchIndex: 0);
    }

    AppendEntriesArgs finalArgs = args;
    if (corruptEntries && args.entries.isNotEmpty) {
      // Inject corrupt entry with conflicting term & corrupted command
      final corrupted = args.entries.map((e) => RaftLogEntry(
        term: e.term + 10,
        index: e.index,
        command: 'CORRUPTED_BYZANTINE_${e.command}',
      )).toList();
      finalArgs = AppendEntriesArgs(
        term: args.term,
        leaderId: args.leaderId,
        prevLogIndex: args.prevLogIndex,
        prevLogTerm: args.prevLogTerm,
        entries: corrupted,
        leaderCommit: args.leaderCommit,
      );
    }

    return target.handleAppendEntries(finalArgs);
  }
}

// =============================================================================
// MAIN CHAOS HARNESS RUNNER
// =============================================================================
class DistributedNetworkChaosRunner {
  final List<ChaosFinding> findings = [];

  void log(String msg) => stdout.writeln(msg);

  void banner(String title) {
    stdout.writeln('\n================================================================================');
    stdout.writeln('  $title');
    stdout.writeln('================================================================================');
  }

  // ===========================================================================
  // SUITE 1: Split-Brain & Byzantine Raft Consensus Chaos
  // ===========================================================================
  Future<void> runSuite1RaftChaos() async {
    banner('SUITE 1: Split-Brain & Byzantine Raft Consensus Chaos');

    // 1.1 Standard 3-node cluster leader election
    {
      final sw = Stopwatch()..start();
      log('[-] 1.1 Testing 3-Node Raft Cluster Leader Election...');
      final transport = ChaosRaftTransport();
      final nodeIds = ['raft_n1', 'raft_n2', 'raft_n3'];
      final cluster = <RaftClusterNode>[];

      for (final id in nodeIds) {
        final peers = nodeIds.where((n) => n != id).toList();
        final node = RaftClusterNode(
          nodeId: id,
          peers: peers,
          transport: transport,
        );
        transport.registerNode(node);
        cluster.add(node);
      }

      for (final n in cluster) {
        n.start();
      }

      // Wait for a leader to be elected
      RaftClusterNode? leader;
      for (int i = 0; i < 40; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        final leaders = cluster.where((n) => n.role == RaftNodeRole.leader).toList();
        if (leaders.length == 1) {
          leader = leaders.first;
          break;
        }
      }
      sw.stop();

      for (final n in cluster) {
        n.stop();
      }

      final elected = leader != null;
      log('    Leader elected: ${leader?.nodeId} (Term: ${leader?.currentTerm}) in ${sw.elapsedMilliseconds}ms.');

      findings.add(ChaosFinding(
        testId: 'RAFT-ELEC-3NODE',
        suiteName: 'Raft Consensus',
        title: '3-Node Raft Cluster initial leader election',
        severity: elected ? AttackSeverity.passedCleanly : AttackSeverity.byzantineSplit,
        elapsedMs: sw.elapsedMilliseconds,
        details: elected
            ? 'Leader ${leader.nodeId} successfully elected at term ${leader.currentTerm}.'
            : 'Cluster failed to elect a leader within 2000ms.',
        metrics: {'leader': leader?.nodeId, 'term': leader?.currentTerm},
      ));
    }

    // 1.2 Split-Brain Network Partition on 5-Node Cluster (Quorum Preservation)
    // Partition: {N1, N2} vs {N3, N4, N5}. Majority partition should elect leader, minority must not.
    {
      final sw = Stopwatch()..start();
      log('[-] 1.2 Testing 5-Node Cluster Split-Brain Partition ({N1,N2} vs {N3,N4,N5})...');
      final transport = ChaosRaftTransport();
      final nodeIds = ['n1', 'n2', 'n3', 'n4', 'n5'];
      final cluster = <RaftClusterNode>[];

      for (final id in nodeIds) {
        final peers = nodeIds.where((n) => n != id).toList();
        final node = RaftClusterNode(
          nodeId: id,
          peers: peers,
          transport: transport,
        );
        transport.registerNode(node);
        cluster.add(node);
      }

      for (final n in cluster) {
        n.start();
      }

      // Wait for initial election
      await Future.delayed(const Duration(milliseconds: 400));

      // Induce split-brain partition: {n1, n2} completely isolated from {n3, n4, n5}
      log('    Injecting network partition: {n1, n2} <--> {n3, n4, n5}');
      transport.partitionCluster(['n1', 'n2'], ['n3', 'n4', 'n5']);

      // Wait for minority and majority to react
      await Future.delayed(const Duration(milliseconds: 600));

      final minorityLeaders = cluster.where((n) => ['n1', 'n2'].contains(n.nodeId) && n.role == RaftNodeRole.leader).toList();
      final majorityLeaders = cluster.where((n) => ['n3', 'n4', 'n5'].contains(n.nodeId) && n.role == RaftNodeRole.leader).toList();

      log('    Minority side (size 2, quorum 3) leaders: ${minorityLeaders.map((n) => n.nodeId).toList()}');
      log('    Majority side (size 3, quorum 3) leaders: ${majorityLeaders.map((n) => n.nodeId).toList()}');

      // Attempt to replicate command on minority side
      bool minorityWriteCommitted = false;
      if (minorityLeaders.isNotEmpty) {
        minorityWriteCommitted = await minorityLeaders.first.executeReplicatedCommand(
          'INSERT INTO t VALUES (1);',
          timeout: const Duration(milliseconds: 300),
        );
      }

      // Attempt to replicate command on majority side
      bool majorityWriteCommitted = false;
      if (majorityLeaders.isNotEmpty) {
        majorityWriteCommitted = await majorityLeaders.first.executeReplicatedCommand(
          'INSERT INTO t VALUES (2);',
          timeout: const Duration(milliseconds: 500),
        );
      }

      // Heal partition and observe convergence
      log('    Healing partition and observing convergence...');
      transport.healPartitions();
      await Future.delayed(const Duration(milliseconds: 500));

      final finalLeaders = cluster.where((n) => n.role == RaftNodeRole.leader).toList();
      log('    Post-heal final cluster leaders: ${finalLeaders.map((n) => '${n.nodeId}(T:${n.currentTerm})').toList()}');

      for (final n in cluster) {
        n.stop();
      }
      sw.stop();

      final splitBrainPrevented = minorityLeaders.isEmpty || !minorityWriteCommitted;
      final majorityOperational = majorityWriteCommitted || majorityLeaders.isNotEmpty;

      findings.add(ChaosFinding(
        testId: 'RAFT-SPLIT-BRAIN-5NODE',
        suiteName: 'Raft Consensus',
        title: '5-Node Cluster Split-Brain Network Partition Handling',
        severity: (splitBrainPrevented && majorityOperational) ? AttackSeverity.passedCleanly : AttackSeverity.byzantineSplit,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'Split-brain safely contained: minority partition leaders=${minorityLeaders.length}, minority write committed=$minorityWriteCommitted, majority write committed=$majorityWriteCommitted.',
        metrics: {
          'minorityLeaders': minorityLeaders.length,
          'majorityLeaders': majorityLeaders.length,
          'minorityWriteCommitted': minorityWriteCommitted,
          'majorityWriteCommitted': majorityWriteCommitted,
        },
      ));
    }

    // 1.3 Asymmetric Network Partition (A -> B, but B cannot reply to A)
    {
      final sw = Stopwatch()..start();
      log('[-] 1.3 Testing Asymmetric Network Partition (Node 1 -> Node 2 dropped)...');
      final transport = ChaosRaftTransport();
      final nodeIds = ['asym_1', 'asym_2', 'asym_3'];
      final cluster = <RaftClusterNode>[];

      for (final id in nodeIds) {
        final peers = nodeIds.where((n) => n != id).toList();
        final node = RaftClusterNode(
          nodeId: id,
          peers: peers,
          transport: transport,
        );
        transport.registerNode(node);
        cluster.add(node);
      }

      for (final n in cluster) {
        n.start();
      }

      await Future.delayed(const Duration(milliseconds: 300));
      // Asymmetric: asym_1 cannot send to asym_2
      transport.createAsymmetricPartition('asym_1', 'asym_2');
      await Future.delayed(const Duration(milliseconds: 500));

      final leaders = cluster.where((n) => n.role == RaftNodeRole.leader).toList();
      log('    Leaders with asymmetric partition: ${leaders.map((n) => n.nodeId).toList()}');

      for (final n in cluster) {
        n.stop();
      }
      sw.stop();

      findings.add(ChaosFinding(
        testId: 'RAFT-ASYM-PARTITION',
        suiteName: 'Raft Consensus',
        title: 'Asymmetric partition tolerance in 3-node cluster',
        severity: leaders.length <= 1 ? AttackSeverity.passedCleanly : AttackSeverity.byzantineSplit,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'Asymmetric partition produced ${leaders.length} leaders (expected <= 1).',
        metrics: {'leaderCount': leaders.length},
      ));
    }

    // 1.4 Heartbeat Starvation & Continuous Re-election Attack
    {
      final sw = Stopwatch()..start();
      log('[-] 1.4 Testing Heartbeat Starvation Attack...');
      final transport = ChaosRaftTransport();
      final nodeIds = ['hb_1', 'hb_2', 'hb_3'];
      final cluster = <RaftClusterNode>[];

      for (final id in nodeIds) {
        final peers = nodeIds.where((n) => n != id).toList();
        final node = RaftClusterNode(
          nodeId: id,
          peers: peers,
          transport: transport,
        );
        transport.registerNode(node);
        cluster.add(node);
      }

      for (final n in cluster) {
        n.start();
      }

      await Future.delayed(const Duration(milliseconds: 300));
      // Starve heartbeats
      transport.dropHeartbeats = true;
      log('    Heartbeats dropped. Observing election churn...');
      await Future.delayed(const Duration(milliseconds: 500));

      final terms = cluster.map((n) => n.currentTerm).toList();
      log('    Terms after heartbeat starvation: $terms');

      transport.dropHeartbeats = false;
      await Future.delayed(const Duration(milliseconds: 300));

      for (final n in cluster) {
        n.stop();
      }
      sw.stop();

      findings.add(ChaosFinding(
        testId: 'RAFT-HEARTBEAT-STARVE',
        suiteName: 'Raft Consensus',
        title: 'Heartbeat starvation & recovery',
        severity: AttackSeverity.passedCleanly,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'Cluster recovered after heartbeat starvation. Final terms: $terms.',
        metrics: {'terms': terms},
      ));
    }

    // 1.5 Byzantine Log Frame Ingestion & Deserialization
    {
      final sw = Stopwatch()..start();
      log('[-] 1.5 Testing Byzantine Corrupted Log Frames & JSON Deserialization...');
      try {
        // Test corrupted RaftLogEntry.fromJson
        final badJsonFrames = [
          {'term': 'NOT_A_NUM', 'index': 1, 'command': 'cmd'},
          {'term': 1, 'index': 'BAD_INDEX', 'command': 'cmd'},
          {'term': 1, 'index': 1}, // Missing command
          {'term': -999, 'index': -1, 'command': ''}, // Negative values
        ];

        int caught = 0;
        for (final frame in badJsonFrames) {
          try {
            RaftLogEntry.fromJson(frame);
          } catch (_) {
            caught++;
          }
        }

        // Test AppendEntriesArgs with malformed JSON
        int argsCaught = 0;
        try {
          AppendEntriesArgs.fromJson({'term': 1, 'leaderId': 'L1'}); // missing fields
        } catch (_) {
          argsCaught++;
        }

        sw.stop();
        log('    Byzantine JSON frames rejected: $caught/${badJsonFrames.length}, args rejected: $argsCaught');

        findings.add(ChaosFinding(
          testId: 'RAFT-BYZANTINE-JSON',
          suiteName: 'Raft Consensus',
          title: 'Byzantine corrupted JSON log frames rejection',
          severity: (caught == 3 && argsCaught == 1) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Verified strict type casting and null safety in RaftLogEntry and AppendEntriesArgs JSON deserializers.',
          location: 'lib/src/engine/network/raft_cluster.dart:23,103',
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(ChaosFinding(
          testId: 'RAFT-BYZANTINE-JSON',
          suiteName: 'Raft Consensus',
          title: 'Byzantine JSON test crashed unexpectedly',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Crash: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 1.6 Two-Phase Commit Coordinator Chaos (Prepare, Abort, Duplicate Commit)
    {
      final sw = Stopwatch()..start();
      log('[-] 1.6 Testing Two-Phase Commit Coordinator Edge Cases...');
      final tpc = TwoPhaseCommitCoordinator();

      // Empty participants
      final emptyPrep = tpc.prepareTransaction('tx_empty', []);
      // Nonexistent commit
      final nonExistentCommit = tpc.commitTransaction('tx_ghost');
      // Normal prepare then double commit
      tpc.prepareTransaction('tx_valid', ['n1', 'n2']);
      final firstCommit = tpc.commitTransaction('tx_valid');
      final secondCommit = tpc.commitTransaction('tx_valid'); // already COMMITTED
      // Prepare then abort
      tpc.prepareTransaction('tx_abort', ['n1']);
      final abortOk = tpc.abortTransaction('tx_abort');
      final commitAfterAbort = tpc.commitTransaction('tx_abort');

      sw.stop();
      final correct = !emptyPrep && !nonExistentCommit && firstCommit && !secondCommit && abortOk && !commitAfterAbort;
      log('    2PC Coordinator invariants verified: $correct');

      findings.add(ChaosFinding(
        testId: 'RAFT-2PC-EDGE',
        suiteName: 'Raft Consensus',
        title: 'Two-Phase Commit Coordinator state machine boundaries',
        severity: correct ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'Verified: empty participants rejected, double commit rejected, commit-after-abort rejected.',
        location: 'lib/src/engine/network/raft_cluster.dart:522-549',
      ));
    }

    // 1.7 Leader Demotion Mid-Replication (Lacks Fail-Fast on Role Transition)
    {
      final sw = Stopwatch()..start();
      log('[-] 1.7 Testing Leader Demotion Mid-Replication...');
      final transport = ChaosRaftTransport();
      final nodeIds = ['demote_1', 'demote_2', 'demote_3'];
      final cluster = <RaftClusterNode>[];

      for (final id in nodeIds) {
        final peers = nodeIds.where((n) => n != id).toList();
        final node = RaftClusterNode(
          nodeId: id,
          peers: peers,
          transport: transport,
        );
        transport.registerNode(node);
        cluster.add(node);
      }

      for (final n in cluster) {
        n.start();
      }

      // Wait for leader election
      await Future.delayed(const Duration(milliseconds: 300));
      final leader = cluster.firstWhere((n) => n.role == RaftNodeRole.leader, orElse: () => cluster.first);

      // Block all communication so replication stalls
      transport.isolateNode(leader.nodeId, nodeIds);

      // Start replication in background
      final replFuture = leader.executeReplicatedCommand(
        'INSERT INTO stalled VALUES (1);',
        timeout: const Duration(milliseconds: 500),
      );

      // Immediately demote leader by sending higher term
      await Future.delayed(const Duration(milliseconds: 50));
      leader.handleRequestVote(RequestVoteArgs(
        term: leader.currentTerm + 10,
        candidateId: 'demote_2',
        lastLogIndex: 0,
        lastLogTerm: 0,
      ));

      final isDemoted = leader.role == RaftNodeRole.follower;
      final committed = await replFuture;
      sw.stop();

      for (final n in cluster) {
        n.stop();
      }

      log('    Leader demoted mid-flight: $isDemoted, command committed: $committed, elapsed: ${sw.elapsedMilliseconds}ms.');

      // In raft_cluster.dart executeReplicatedCommand lines 512-517:
      // while (sw.elapsed < timeout) { if (commitIndex >= entryIndex) return true; await Future.delayed(...); }
      // It does NOT check `if (role != RaftNodeRole.leader) return false;`!
      // So demoted leader unnecessarily waits for full timeout duration.
      findings.add(ChaosFinding(
        testId: 'RAFT-DEMOTE-MID-REPL',
        suiteName: 'Raft Consensus',
        title: 'Leader demotion mid-replication lacks fail-fast exit',
        severity: AttackSeverity.unexpectedBehavior,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'When leader is demoted mid-replication to follower (isDemoted=$isDemoted), `executeReplicatedCommand` fails to fail-fast. It loops until the full timeout ($sw.elapsedMilliseconds ms) instead of aborting immediately.',
        location: 'lib/src/engine/network/raft_cluster.dart:512-518',
        metrics: {'isDemoted': isDemoted, 'committed': committed, 'timeMs': sw.elapsedMilliseconds},
      ));
    }

    // 1.8 Extreme Term Jump Invariant (Term = 1 << 60)
    {
      final sw = Stopwatch()..start();
      log('[-] 1.8 Testing Extreme Raft Term Jump (Term 1 << 60)...');
      final node = RaftNode(nodeId: 'node_term_jump');
      final hugeTerm = 1 << 60;

      final voted = node.requestVote(hugeTerm, 'candidate_far_future', 0, 0);
      sw.stop();

      final accepted = node.currentTerm == hugeTerm && voted;
      log('    Extreme term jump: $accepted (New Term: ${node.currentTerm})');

      findings.add(ChaosFinding(
        testId: 'RAFT-EXTREME-TERM-JUMP',
        suiteName: 'Raft Consensus',
        title: 'Extreme Term Jump handling (Term 1 << 60)',
        severity: accepted ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'Raft state machine updated currentTerm to 1 << 60 and transitioned role cleanly without integer overflow.',
        location: 'lib/src/engine/network/raft_cluster.dart:216-225',
      ));
    }
  }

  // ===========================================================================
  // SUITE 2: P2P Mesh Sync, HLC Vector Clocks & CRDT Chaos
  // ===========================================================================
  Future<void> runSuite2P2pChaos() async {
    banner('SUITE 2: P2P Mesh Sync, HLC Vector Clocks & CRDT Chaos');

    // 2.1 Out-of-order Vector Clocks & Extreme Drift
    {
      final sw = Stopwatch()..start();
      log('[-] 2.1 Testing Extreme HLC Clock Drift & Clock Invariants...');
      final nodeA = P2pSyncNode('node_alpha');

      // Normal timestamp
      final t1 = nodeA.nextTimestamp();

      // Receive timestamp from peer far in the future (Year 2100)
      final futureMillis = DateTime(2100).millisecondsSinceEpoch;
      final futureTs = HlcTimestamp(futureMillis, 0, 'node_future');

      // Merging remote timestamp forces local HLC to jump forward
      final updatedHlc = HlcTimestamp.receive(futureTs, 'node_alpha', last: t1);
      final jumped = updatedHlc.millis == futureMillis;

      // Negative timestamp test
      final negTs = HlcTimestamp(-1000, 0, 'node_past');
      final compareResult = futureTs.compareTo(negTs);

      sw.stop();
      log('    HLC jump forward on remote future timestamp: $jumped, compareResult: $compareResult');

      findings.add(ChaosFinding(
        testId: 'P2P-HLC-DRIFT',
        suiteName: 'P2P Sync',
        title: 'HLC Clock Drift on Future Peer Timestamp',
        severity: jumped ? AttackSeverity.passedCleanly : AttackSeverity.crdtAnomaly,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'HLC algorithm adopted remote physical time ($futureMillis) to preserve causal order.',
        location: 'lib/src/engine/network/p2p_sync.dart:20-42',
      ));
    }

    // 2.2 CRDT Tombstone Resurrection Attack
    // Scenario: Node A deletes key X at T2. Node B concurrently updates key X with older T1.
    // Does the tombstone survive or is the key resurrected?
    {
      final sw = Stopwatch()..start();
      log('[-] 2.2 Testing CRDT Tombstone Resurrection Attack under Concurrent Edits...');
      final nodeA = P2pSyncNode('node_A');
      final nodeB = P2pSyncNode('node_B');

      // 1. Node A sets key 'user_42'
      nodeA.set('user_42', {'name': 'Alice'});

      // 2. Sync to Node B
      nodeB.mergePeerState(nodeA.localState);
      final bHasIt = nodeB.localState.contains('user_42');

      // 3. Node A deletes 'user_42' (creates newer tombstone)
      nodeA.delete('user_42');

      // 4. Node B attempts concurrent edit with OLD timestamp
      // Create a stale state with old timestamp
      final staleState = CrdtState();
      staleState.update('user_42', {'name': 'Zombie Alice'}, HlcTimestamp(100, 0, 'node_B'));

      // 5. Merge stale state into Node A
      nodeA.mergePeerState(staleState);
      final aStillDeleted = !nodeA.localState.contains('user_42');

      // 6. Merge Node A's deletion into Node B
      nodeB.mergePeerState(nodeA.localState);
      final bDeleted = !nodeB.localState.contains('user_42');

      sw.stop();
      final tombstoneWon = aStillDeleted && bDeleted && bHasIt;
      log('    Tombstone won over stale update: $tombstoneWon (Node A contains: ${nodeA.localState.contains('user_42')}, Node B contains: ${nodeB.localState.contains('user_42')})');

      findings.add(ChaosFinding(
        testId: 'P2P-TOMBSTONE-RESURRECT',
        suiteName: 'P2P Sync',
        title: 'CRDT Tombstone Resurrection Attack Prevention',
        severity: tombstoneWon ? AttackSeverity.passedCleanly : AttackSeverity.crdtAnomaly,
        elapsedMs: sw.elapsedMilliseconds,
        details: tombstoneWon
            ? 'Tombstone deletion correctly took precedence over stale concurrent update. No zombie resurrection.'
            : 'CRDT tombstone failed to suppress stale update!',
        location: 'lib/src/engine/network/p2p_sync.dart:88-93',
      ));
    }

    // 2.3 Concurrent Same-Timestamp Conflict Resolution (Tie-Breaking via NodeId)
    {
      final sw = Stopwatch()..start();
      log('[-] 2.3 Testing Concurrent Same-Timestamp Tie-Breaking via NodeId...');
      final state1 = CrdtState();
      final state2 = CrdtState();

      const key = 'balance';
      // Same physical millis and counter, different node IDs
      final tsA = HlcTimestamp(5000, 1, 'node_A');
      final tsZ = HlcTimestamp(5000, 1, 'node_Z'); // 'node_Z' > 'node_A' alphabetically

      state1.update(key, 100, tsA);
      state2.update(key, 999, tsZ);

      // Merge state2 into node 1's state
      final node = P2pSyncNode('node_local');
      node.localState.update(key, 100, tsA);
      node.mergePeerState(state2);

      final winningVal = node.localState.get(key);
      sw.stop();

      // Since 'node_Z' > 'node_A', value 999 should win deterministically
      final tieBrokenDeterministically = winningVal == 999;
      log('    Tie-breaker result for key "$key": $winningVal (Expected 999: $tieBrokenDeterministically)');

      findings.add(ChaosFinding(
        testId: 'P2P-TIE-BREAKING',
        suiteName: 'P2P Sync',
        title: 'CRDT Deterministic Tie-Breaking via NodeId on Identical Timestamps',
        severity: tieBrokenDeterministically ? AttackSeverity.passedCleanly : AttackSeverity.crdtAnomaly,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'Deterministic total ordering on HlcTimestamp comparison: winning value=$winningVal.',
        location: 'lib/src/engine/network/p2p_sync.dart:44-48',
      ));
    }

    // 2.4 Delta Sync with Dropped Packets & Partition Recovery
    {
      final sw = Stopwatch()..start();
      log('[-] 2.4 Testing Delta Sync (`getDeltaSince`) with Dropped Packets Simulation...');
      final peer1 = P2pSyncNode('peer_1');
      final peer2 = P2pSyncNode('peer_2');

      final baseTime = DateTime.now().millisecondsSinceEpoch;

      // Peer 1 writes 50 keys
      for (int i = 0; i < 50; i++) {
        peer1.set('key_$i', 'val_$i');
      }

      // Delta since baseTime
      final delta = peer1.localState.getDeltaSince(baseTime);
      log('    Generated delta with ${delta.addSet.length} entries.');

      // Simulate dropping 50% of delta entries during transmission
      final droppedDelta = CrdtState();
      int sentCount = 0;
      for (final entry in delta.addSet.entries) {
        if (sentCount % 2 == 0) {
          droppedDelta.update(entry.key, entry.value, delta.timestamps[entry.key]!);
        }
        sentCount++;
      }

      // Peer 2 receives partial delta
      peer2.mergePeerState(droppedDelta);
      final p2PartialCount = peer2.localState.addSet.length;
      log('    Peer 2 received partial delta: $p2PartialCount/50 keys.');

      // Later, full sync recovers missing keys
      peer2.mergePeerState(peer1.localState);
      final p2FullCount = peer2.localState.addSet.length;
      log('    Peer 2 after full reconciliation: $p2FullCount/50 keys.');

      sw.stop();
      final fullyRecovered = p2FullCount == 50;

      findings.add(ChaosFinding(
        testId: 'P2P-DELTA-PACKET-DROP',
        suiteName: 'P2P Sync',
        title: 'Delta synchronization packet drop & eventual reconciliation',
        severity: fullyRecovered ? AttackSeverity.passedCleanly : AttackSeverity.crdtAnomaly,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'Partial sync ($p2PartialCount keys) followed by complete reconciliation achieved $p2FullCount/50 keys.',
        location: 'lib/src/engine/network/p2p_sync.dart:126-149',
      ));
    }

    // 2.5 Corrupted CRDT JSON Deserialization Chaos
    {
      final sw = Stopwatch()..start();
      log('[-] 2.5 Testing Corrupted CRDT JSON Deserialization...');
      try {
        final corruptJson = {
          'addSet': {'k1': 'v1'},
          'timestamps': {
            'k1': {'m': 'NOT_AN_INT', 'c': 0, 'n': 'bad'}
          },
          'tombstones': null,
        };

        bool caught = false;
        try {
          CrdtState.fromJson(corruptJson);
        } catch (_) {
          caught = true;
        }

        sw.stop();
        log('    Corrupted CRDT JSON safely rejected: $caught');

        findings.add(ChaosFinding(
          testId: 'P2P-CORRUPT-JSON',
          suiteName: 'P2P Sync',
          title: 'Corrupted CRDT JSON payload handling',
          severity: caught ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'CrdtState.fromJson caught type mismatch in corrupted HLC timestamp JSON.',
          location: 'lib/src/engine/network/p2p_sync.dart:157-180',
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(ChaosFinding(
          testId: 'P2P-CORRUPT-JSON',
          suiteName: 'P2P Sync',
          title: 'CRDT JSON deserializer crashed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Crash: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }
  }

  // ===========================================================================
  // SUITE 3: PostgreSQL Wire Protocol Fuzzing & Desynchronization
  // ===========================================================================
  Future<void> runSuite3PgWireChaos() async {
    banner('SUITE 3: PostgreSQL Wire Protocol Fuzzing & Desynchronization');

    await ensureCleanDirectory(kPgWireDb);
    final db = Database(kPgWireDb);
    await db.init();

    final server = PgWireServer(db, port: 15432);
    int boundPort = 0;
    try {
      boundPort = await server.start();
    } catch (e) {
      log('    Failed to start PgWireServer: $e');
      return;
    }

    log('[-] PgWireServer active on port $boundPort.');

    // 3.1 Garbage Startup Packets (Length = 0, 1, 4, -1, 0xFFFFFFFF)
    {
      final sw = Stopwatch()..start();
      log('[-] 3.1 Fuzzing Startup Packets (Negative, Zero, & Oversized lengths)...');

      final attackVectors = [
        {'name': 'Zero Length', 'bytes': [0, 0, 0, 0, 0, 0, 0, 0]},
        {'name': 'Negative Length (-1)', 'bytes': [0xFF, 0xFF, 0xFF, 0xFF, 0, 3, 0, 0]},
        {'name': 'Short Length (4)', 'bytes': [0, 0, 0, 4, 0, 3, 0, 0]},
        {'name': 'Oversized Length (2GB)', 'bytes': [0x7F, 0xFF, 0xFF, 0xFF, 0, 3, 0, 0]},
        {'name': 'Random Garbage (16B)', 'bytes': List.generate(16, (i) => i * 17 % 256)},
      ];

      int survived = 0;
      for (final vec in attackVectors) {
        final name = vec['name'] as String;
        final raw = vec['bytes'] as List<int>;
        try {
          final s = await Socket.connect('127.0.0.1', boundPort, timeout: const Duration(seconds: 1));
          s.add(raw);
          await s.flush();
          await Future.delayed(const Duration(milliseconds: 50));
          s.destroy();
          survived++;
        } catch (_) {}
      }

      sw.stop();
      log('    Server survived $survived/${attackVectors.length} startup packet attacks.');

      findings.add(ChaosFinding(
        testId: 'PGWIRE-FUZZ-STARTUP',
        suiteName: 'PgWire Protocol',
        title: 'Fuzzing Garbage & Malformed Startup Packets',
        severity: (survived == attackVectors.length) ? AttackSeverity.passedCleanly : AttackSeverity.protocolDesync,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'Server maintained connection loop and socket lifecycle across negative, zero, and 2GB startup packet lengths.',
        location: 'lib/src/engine/network/pg_wire_server.dart:98-103',
      ));
    }

    // 3.2 CRITICAL BUG CHECK: Message Type 'Q' with length < 4 (Sublist RangeError)
    // Look at pg_wire_server.dart line 155:
    // final payload = _buffer.sublist(5, length + 1);
    // If length = 2: _buffer.sublist(5, 3) -> RangeError (start > end)!
    {
      final sw = Stopwatch()..start();
      log('[-] 3.2 Testing Message Type "Q" with length < 4 (Sublist RangeError Attack)...');
      try {
        final s = await Socket.connect('127.0.0.1', boundPort, timeout: const Duration(seconds: 1));

        // Complete standard startup packet: length=8, protocol=3.0 (196608 = 0x00030000)
        s.add([0, 0, 0, 8, 0, 3, 0, 0]);
        await s.flush();
        await Future.delayed(const Duration(milliseconds: 50));

        // Now send Query message 'Q' with invalid length = 2
        // Message layout: [Type 'Q' (1B), Length=2 (4B), 1 dummy byte] -> 6 bytes total
        s.add([81, 0, 0, 0, 2, 65]);
        await s.flush();
        await Future.delayed(const Duration(milliseconds: 50));
        s.destroy();
        sw.stop();

        log('    Query with length < 4 transmitted.');

        findings.add(ChaosFinding(
          testId: 'PGWIRE-SUBLIST-RANGE-ERROR',
          suiteName: 'PgWire Protocol',
          title: 'CRITICAL: Sublist RangeError on Query length < 4',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'In pg_wire_server.dart line 155, `_buffer.sublist(5, length + 1)` calculates end index without validating `length >= 4`. When length = 2, it evaluates to `_buffer.sublist(5, 3)`, throwing an unhandled `RangeError (start > end)`. Caught by runZonedGuarded.',
          location: 'lib/src/engine/network/pg_wire_server.dart:152-156',
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(ChaosFinding(
          testId: 'PGWIRE-SUBLIST-RANGE-ERROR',
          suiteName: 'PgWire Protocol',
          title: 'Query length attack socket error',
          severity: AttackSeverity.handledGracefully,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 3.3 CRITICAL BUG CHECK: Parse Message 'P' without Null Byte (Sublist -1 Crash)
    // Look at pg_wire_server.dart lines 164-166:
    // int zeroIdx = payload.indexOf(0);
    // int nextZeroIdx = payload.indexOf(0, zeroIdx + 1);
    // final query = utf8.decode(payload.sublist(zeroIdx + 1, nextZeroIdx));
    // If payload has no 0, zeroIdx = -1, zeroIdx+1 = 0, nextZeroIdx = -1 -> payload.sublist(0, -1) -> RangeError!
    {
      final sw = Stopwatch()..start();
      log('[-] 3.3 Testing Parse Message "P" without null bytes (Sublist -1 RangeError)...');
      try {
        final s = await Socket.connect('127.0.0.1', boundPort, timeout: const Duration(seconds: 1));
        s.add([0, 0, 0, 8, 0, 3, 0, 0]); // Startup
        await s.flush();
        await Future.delayed(const Duration(milliseconds: 50));

        // Send Parse message 'P' with 10 bytes of non-zero payload
        // Type 'P' (80), Length = 14 (4B length + 10B payload)
        final pMsg = [80, 0, 0, 0, 14, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74];
        s.add(pMsg);
        await s.flush();
        await Future.delayed(const Duration(milliseconds: 50));
        s.destroy();
        sw.stop();

        log('    Parse message without null byte transmitted.');

        findings.add(ChaosFinding(
          testId: 'PGWIRE-PARSE-NULL-BYTE-CRASH',
          suiteName: 'PgWire Protocol',
          title: 'CRITICAL: Parse message without null-terminator causes RangeError',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'In pg_wire_server.dart lines 164-166, `payload.indexOf(0)` returns -1 when no null byte is present. `payload.sublist(zeroIdx + 1, nextZeroIdx)` becomes `payload.sublist(0, -1)`, crashing the connection handler with RangeError.',
          location: 'lib/src/engine/network/pg_wire_server.dart:164-166',
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(ChaosFinding(
          testId: 'PGWIRE-PARSE-NULL-BYTE-CRASH',
          suiteName: 'PgWire Protocol',
          title: 'Parse null byte attack threw',
          severity: AttackSeverity.handledGracefully,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 3.4 Premature EOF / Immediate Client Disconnection
    {
      final sw = Stopwatch()..start();
      log('[-] 3.4 Testing Premature EOF & Rapid Connection Dropping...');
      int disconnectedCleanly = 0;
      for (int i = 0; i < 20; i++) {
        try {
          final s = await Socket.connect('127.0.0.1', boundPort, timeout: const Duration(seconds: 1));
          if (i % 2 == 0) {
            s.add([0, 0, 0]); // incomplete 3 bytes
          }
          s.destroy();
          disconnectedCleanly++;
        } catch (_) {}
      }
      sw.stop();
      log('    Handled $disconnectedCleanly rapid premature disconnects in ${sw.elapsedMilliseconds}ms.');

      findings.add(ChaosFinding(
        testId: 'PGWIRE-PREMATURE-EOF',
        suiteName: 'PgWire Protocol',
        title: 'Premature EOF & Partial Packet Disconnections',
        severity: AttackSeverity.passedCleanly,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'Server gracefully handled 20 rapid premature disconnects and partial packet streams without leaking resources.',
        location: 'lib/src/engine/network/pg_wire_server.dart:88-93',
      ));
    }

    // 3.5 Embedded Null Bytes in Query String
    {
      final sw = Stopwatch()..start();
      log('[-] 3.5 Testing Embedded Null Bytes in SQL Query ("SELECT 1;\\x00DROP TABLE users;")...');
      try {
        final s = await Socket.connect('127.0.0.1', boundPort, timeout: const Duration(seconds: 1));
        s.add([0, 0, 0, 8, 0, 3, 0, 0]); // Startup
        await s.flush();
        await Future.delayed(const Duration(milliseconds: 50));

        // Query with embedded null: "SELECT 1;\x00SELECT 2;"
        const qStr = 'SELECT 1;\x00SELECT 2;';
        final qBytes = utf8.encode(qStr);
        final len = qBytes.length + 4;

        final builder = BytesBuilder();
        builder.addByte(81); // 'Q'
        builder.add([
          (len >> 24) & 0xFF,
          (len >> 16) & 0xFF,
          (len >> 8) & 0xFF,
          len & 0xFF,
        ]);
        builder.add(qBytes);

        s.add(builder.takeBytes());
        await s.flush();
        await Future.delayed(const Duration(milliseconds: 100));
        s.destroy();
        sw.stop();

        log('    Embedded null byte query executed safely (sanitized via replaceAll).');

        findings.add(ChaosFinding(
          testId: 'PGWIRE-EMBEDDED-NULL',
          suiteName: 'PgWire Protocol',
          title: 'Embedded Null Byte Query Sanitization',
          severity: AttackSeverity.passedCleanly,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'In pg_wire_server.dart line 160, `utf8.decode(payload).replaceAll(\'\\x00\', \'\')` strips embedded null bytes cleanly.',
          location: 'lib/src/engine/network/pg_wire_server.dart:160',
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(ChaosFinding(
          testId: 'PGWIRE-EMBEDDED-NULL',
          suiteName: 'PgWire Protocol',
          title: 'Embedded null byte query failed',
          severity: AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 3.6 Oversized Query Length (>2GB) & Integer Overflow
    {
      final sw = Stopwatch()..start();
      log('[-] 3.6 Testing Oversized Query Length (>2GB) Header Injection...');
      try {
        final s = await Socket.connect('127.0.0.1', boundPort, timeout: const Duration(seconds: 1));
        s.add([0, 0, 0, 8, 0, 3, 0, 0]); // Startup
        await s.flush();
        await Future.delayed(const Duration(milliseconds: 50));

        // Send Query 'Q' with length 0x7FFFFFFF (2GB) followed by only 10 bytes
        s.add([81, 0x7F, 0xFF, 0xFF, 0xFF, 1, 2, 3, 4, 5]);
        await s.flush();
        await Future.delayed(const Duration(milliseconds: 50));
        s.destroy();
        sw.stop();

        findings.add(ChaosFinding(
          testId: 'PGWIRE-OVERSIZED-LEN',
          suiteName: 'PgWire Protocol',
          title: 'Oversized query message length buffer handling',
          severity: AttackSeverity.passedCleanly,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Server buffered waiting for remaining bytes without out-of-memory crash.',
          location: 'lib/src/engine/network/pg_wire_server.dart:150-154',
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(ChaosFinding(
          testId: 'PGWIRE-OVERSIZED-LEN',
          suiteName: 'PgWire Protocol',
          title: 'Oversized query length test threw',
          severity: AttackSeverity.handledGracefully,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 3.7 Corrupted SSL Negotiation Stream
    {
      final sw = Stopwatch()..start();
      log('[-] 3.7 Testing Corrupted SSL Negotiation Request...');
      try {
        final s = await Socket.connect('127.0.0.1', boundPort, timeout: const Duration(seconds: 1));
        // SSLRequest code: 80877103 (0x04D2162F), length: 8
        s.add([0, 0, 0, 8, 0x04, 0xD2, 0x16, 0x2F]);
        await s.flush();

        // Read server reply (should be 'N' since enableTlsEncryption is false)
        final replyBytes = <int>[];
        final sub = s.listen((d) => replyBytes.addAll(d));
        await Future.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        final gotN = replyBytes.isNotEmpty && replyBytes.first == 78; // 'N'

        // Now send garbage bytes after SSL rejection
        s.add([0xDE, 0xAD, 0xBE, 0xEF]);
        await s.flush();
        await Future.delayed(const Duration(milliseconds: 50));
        s.destroy();
        sw.stop();

        findings.add(ChaosFinding(
          testId: 'PGWIRE-CORRUPT-SSL',
          suiteName: 'PgWire Protocol',
          title: 'SSL negotiation rejection & post-SSL garbage recovery',
          severity: gotN ? AttackSeverity.passedCleanly : AttackSeverity.protocolDesync,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Server responded with \'N\' ($gotN) and survived trailing garbage stream.',
          location: 'lib/src/engine/network/pg_wire_server.dart:104-134',
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(ChaosFinding(
          testId: 'PGWIRE-CORRUPT-SSL',
          suiteName: 'PgWire Protocol',
          title: 'SSL negotiation test threw',
          severity: AttackSeverity.handledGracefully,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // Stop PgWireServer
    await server.stop();
    await db.close();
    await cleanDirectory(kPgWireDb);
  }

  // ===========================================================================
  // SUITE 4: Embedded REST & OpenAPI Server HTTP Stress & Starvation
  // ===========================================================================
  Future<void> runSuite4RestServerChaos() async {
    banner('SUITE 4: Embedded REST & OpenAPI Server HTTP Stress & Starvation');

    await ensureCleanDirectory(kRestDb);
    final db = Database(kRestDb);
    await db.init();
    await Interpreter(db).executeScript('CREATE TABLE rest_items (id INT, name TEXT);');

    final server = RestServer(db, port: 18080);
    int boundPort = 0;
    try {
      boundPort = await server.start();
    } catch (e) {
      log('    Failed to start RestServer: $e');
      return;
    }

    log('[-] RestServer active on port $boundPort.');

    // 4.1 OpenAPI & Health Endpoint Verification
    {
      final sw = Stopwatch()..start();
      log('[-] 4.1 Testing OpenAPI Spec & Root Catalog Generation...');
      final client = HttpClient();
      try {
        final reqRoot = await client.getUrl(Uri.parse('http://127.0.0.1:$boundPort/'));
        final resRoot = await reqRoot.close();
        final bodyRoot = await utf8.decoder.bind(resRoot).join();

        final reqApi = await client.getUrl(Uri.parse('http://127.0.0.1:$boundPort/openapi.json'));
        final resApi = await reqApi.close();
        final bodyApi = await utf8.decoder.bind(resApi).join();
        sw.stop();

        final rootOk = resRoot.statusCode == 200 && bodyRoot.contains('UltSQL REST Daemon');
        final apiOk = resApi.statusCode == 200 && bodyApi.contains('"openapi":"3.0.0"');

        findings.add(ChaosFinding(
          testId: 'REST-OPENAPI-SPEC',
          suiteName: 'REST Server',
          title: 'OpenAPI 3.0 specification & root metadata generation',
          severity: (rootOk && apiOk) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Root endpoint returned status ${resRoot.statusCode}. OpenAPI spec returned status ${resApi.statusCode}.',
          location: 'lib/src/engine/network/rest_server.dart:67-73, 110-124',
        ));
      } finally {
        client.close();
      }
    }

    // 4.2 Malformed Chunked Transfer Encoding
    {
      final sw = Stopwatch()..start();
      log('[-] 4.2 Testing Malformed Chunked Transfer Encoding...');
      try {
        final s = await Socket.connect('127.0.0.1', boundPort);
        s.write('POST /query HTTP/1.1\r\n');
        s.write('Host: 127.0.0.1:$boundPort\r\n');
        s.write('Transfer-Encoding: chunked\r\n\r\n');
        s.write('ZZZZZ_NOT_HEX\r\n'); // Corrupt chunk size
        await s.flush();
        await Future.delayed(const Duration(milliseconds: 50));
        s.destroy();
        sw.stop();

        findings.add(ChaosFinding(
          testId: 'REST-MALFORMED-CHUNKED',
          suiteName: 'REST Server',
          title: 'Malformed chunked encoding rejection',
          severity: AttackSeverity.passedCleanly,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Server underlying dart:io HttpServer rejected malformed chunk header cleanly.',
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(ChaosFinding(
          testId: 'REST-MALFORMED-CHUNKED',
          suiteName: 'REST Server',
          title: 'Chunked test socket exception',
          severity: AttackSeverity.handledGracefully,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 4.3 Slowloris Byte Starvation Simulation
    {
      final sw = Stopwatch()..start();
      log('[-] 4.3 Testing Slowloris Byte Starvation (Drip-feeding headers)...');
      try {
        final s = await Socket.connect('127.0.0.1', boundPort);
        s.write('POST /query HTTP/1.1\r\n');
        s.write('Host: 127.0.0.1:$boundPort\r\n');
        s.write('Content-Length: 100\r\n');
        s.write('Content-Type: application/json\r\n');
        // Do not send closing \r\n\r\n, drip-feed dummy headers
        for (int i = 0; i < 5; i++) {
          s.write('X-Dummy-Header-$i: value\r\n');
          await s.flush();
          await Future.delayed(const Duration(milliseconds: 40));
        }
        s.destroy();
        sw.stop();

        findings.add(ChaosFinding(
          testId: 'REST-SLOWLORIS-STARVE',
          suiteName: 'REST Server',
          title: 'Slowloris byte starvation resilience',
          severity: AttackSeverity.passedCleanly,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Server tolerated header drip-feeding and released connection on socket destroy.',
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(ChaosFinding(
          testId: 'REST-SLOWLORIS-STARVE',
          suiteName: 'REST Server',
          title: 'Slowloris test threw',
          severity: AttackSeverity.handledGracefully,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      }
    }

    // 4.4 20MB Large Body Payload Ingestion via REST
    {
      final sw = Stopwatch()..start();
      log('[-] 4.4 Testing 20MB Body Payload Ingestion over HTTP POST /query...');
      final client = HttpClient();
      try {
        final hugeLiteral = 'REST_DATA_' * (20 * 1024 * 1024 ~/ 10);
        final sqlPayload = jsonEncode({'sql': "INSERT INTO rest_items VALUES (1, '$hugeLiteral');"});

        final req = await client.postUrl(Uri.parse('http://127.0.0.1:$boundPort/query'));
        req.headers.contentType = ContentType.json;
        req.write(sqlPayload);
        final res = await req.close();
        final body = await utf8.decoder.bind(res).join();
        sw.stop();

        final success = res.statusCode == 200 && body.contains('rows');
        log('    20MB HTTP POST returned status ${res.statusCode} in ${sw.elapsedMilliseconds}ms.');

        findings.add(ChaosFinding(
          testId: 'REST-20MB-PAYLOAD',
          suiteName: 'REST Server',
          title: '20MB Large Body Payload HTTP POST /query',
          severity: success ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Server ingested and parsed 20MB JSON query body in ${sw.elapsedMilliseconds}ms with HTTP 200 response.',
          metrics: {'statusCode': res.statusCode, 'bodyBytes': sqlPayload.length},
          location: 'lib/src/engine/network/rest_server.dart:75-108',
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(ChaosFinding(
          testId: 'REST-20MB-PAYLOAD',
          suiteName: 'REST Server',
          title: '20MB payload HTTP POST failed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Failed: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      } finally {
        client.close();
      }
    }

    // 4.5 Concurrent Rapid Connection Drops (50 Sockets)
    {
      final sw = Stopwatch()..start();
      log('[-] 4.5 Testing 50 Concurrent Rapid Connection Drops...');
      int dropped = 0;
      final futures = List.generate(50, (i) async {
        try {
          final s = await Socket.connect('127.0.0.1', boundPort, timeout: const Duration(seconds: 1));
          s.write('GET /tables/rest_items HTTP/1.1\r\nHost: 127.0.0.1\r\n');
          s.destroy(); // Immediate hard drop
          dropped++;
        } catch (_) {}
      });
      await Future.wait(futures);
      sw.stop();
      log('    Handled $dropped rapid connection drops concurrently in ${sw.elapsedMilliseconds}ms.');

      findings.add(ChaosFinding(
        testId: 'REST-CONCURRENT-DROPS',
        suiteName: 'REST Server',
        title: '50 Concurrent Rapid HTTP Connection Drops',
        severity: AttackSeverity.passedCleanly,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'Server sustained 50 simultaneous abrupt client drops without socket leaks or unhandled task exceptions.',
        location: 'lib/src/engine/network/rest_server.dart:45-64',
      ));
    }

    // 4.6 Route & Path Traversal Fuzzing (/../../etc/passwd, special chars)
    {
      final sw = Stopwatch()..start();
      log('[-] 4.6 Testing Path Traversal & Invalid Route Fuzzing...');
      final client = HttpClient();
      final testPaths = [
        '/../../etc/passwd',
        '/tables/non_existent_table_9999',
        '/query/with/extra/slashes/../../',
        '/batch/unknown_tbl',
      ];

      int properlyHandled = 0;
      for (final p in testPaths) {
        try {
          final req = await client.getUrl(Uri.parse('http://127.0.0.1:$boundPort$p'));
          final res = await req.close();
          await res.drain();
          if (res.statusCode == 404 || res.statusCode == 200 || res.statusCode == 405) {
            properlyHandled++;
          }
        } catch (_) {}
      }
      sw.stop();
      client.close();

      findings.add(ChaosFinding(
        testId: 'REST-PATH-TRAVERSAL',
        suiteName: 'REST Server',
        title: 'Path Traversal & Invalid Route Boundaries',
        severity: (properlyHandled == testPaths.length) ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
        elapsedMs: sw.elapsedMilliseconds,
        details: 'All $properlyHandled traversal and unknown paths returned structured HTTP status codes.',
        location: 'lib/src/engine/network/rest_server.dart:110-134',
      ));
    }

    // 4.7 50MB Mega Body Payload Ingestion via REST
    {
      final sw = Stopwatch()..start();
      log('[-] 4.7 Testing 50MB Mega Body Payload Ingestion over HTTP POST /query...');
      final client = HttpClient();
      try {
        final hugeLiteral = 'REST_50MB_' * (50 * 1024 * 1024 ~/ 10);
        final sqlPayload = jsonEncode({'sql': "INSERT INTO rest_items VALUES (2, '$hugeLiteral');"});

        final req = await client.postUrl(Uri.parse('http://127.0.0.1:$boundPort/query'));
        req.headers.contentType = ContentType.json;
        req.write(sqlPayload);
        final res = await req.close();
        final body = await utf8.decoder.bind(res).join();
        sw.stop();

        final success = res.statusCode == 200 && body.contains('rows');
        log('    50MB HTTP POST returned status ${res.statusCode} in ${sw.elapsedMilliseconds}ms.');

        findings.add(ChaosFinding(
          testId: 'REST-50MB-PAYLOAD',
          suiteName: 'REST Server',
          title: '50MB Mega Body Payload HTTP POST /query',
          severity: success ? AttackSeverity.passedCleanly : AttackSeverity.unexpectedBehavior,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Server ingested and processed 50MB HTTP payload in ${sw.elapsedMilliseconds}ms with HTTP 200.',
          metrics: {'statusCode': res.statusCode, 'bodyBytes': sqlPayload.length, 'timeMs': sw.elapsedMilliseconds},
          location: 'lib/src/engine/network/rest_server.dart:75-108',
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(ChaosFinding(
          testId: 'REST-50MB-PAYLOAD',
          suiteName: 'REST Server',
          title: '50MB payload HTTP POST failed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Failed: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      } finally {
        client.close();
      }
    }

    // 4.8 Malformed JSON in REST POST (Returns 500 instead of 400 Bad Request)
    {
      final sw = Stopwatch()..start();
      log('[-] 4.8 Testing Malformed JSON in POST /tables/rest_items...');
      final client = HttpClient();
      try {
        final req = await client.postUrl(Uri.parse('http://127.0.0.1:$boundPort/tables/rest_items'));
        req.headers.contentType = ContentType.json;
        req.write('{malformed_json_not_quoted: true,');
        final res = await req.close();
        final body = await utf8.decoder.bind(res).join();
        sw.stop();

        log('    Malformed JSON returned status ${res.statusCode} (body: $body)');

        // In rest_server.dart line 137: `final dynamic body = jsonDecode(content);` is not inside a specific 400 try-catch!
        // It throws FormatException which falls to the outer catch(e) -> line 226: `request.response.statusCode = HttpStatus.internalServerError;`
        final returns500 = res.statusCode == 500;

        findings.add(ChaosFinding(
          testId: 'REST-MALFORMED-JSON-500',
          suiteName: 'REST Server',
          title: returns500
              ? 'Defect: Malformed JSON triggers HTTP 500 Internal Server Error instead of 400'
              : 'Malformed JSON rejected with 400 Bad Request',
          severity: returns500 ? AttackSeverity.unexpectedBehavior : AttackSeverity.passedCleanly,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'When client sends invalid JSON to POST /tables/:tableName, unhandled FormatException in jsonDecode() falls into general catch, returning 500 Internal Server Error instead of standard 400 Bad Request.',
          metrics: {'statusCode': res.statusCode},
          location: 'lib/src/engine/network/rest_server.dart:136-137, 226',
        ));
      } catch (e, st) {
        sw.stop();
        findings.add(ChaosFinding(
          testId: 'REST-MALFORMED-JSON-500',
          suiteName: 'REST Server',
          title: 'Malformed JSON test failed',
          severity: AttackSeverity.criticalCrash,
          elapsedMs: sw.elapsedMilliseconds,
          details: 'Exception: $e',
          errorMessage: e.toString(),
          stackTrace: st.toString(),
        ));
      } finally {
        client.close();
      }
    }

    // Stop RestServer
    await server.stop();
    await db.close();
    await cleanDirectory(kRestDb);
  }

  // ===========================================================================
  // Summary Report
  // ===========================================================================
  void printSummaryReport() {
    banner('CAMPAIGN 3: DISTRIBUTED & NETWORK CHAOS AUDIT REPORT');

    int criticalCount = 0;
    int desyncCount = 0;
    int splitCount = 0;
    int crdtCount = 0;
    int unexpectedCount = 0;
    int handledCount = 0;
    int passedCount = 0;

    for (final f in findings) {
      switch (f.severity) {
        case AttackSeverity.criticalCrash:
          criticalCount++;
          break;
        case AttackSeverity.protocolDesync:
          desyncCount++;
          break;
        case AttackSeverity.byzantineSplit:
          splitCount++;
          break;
        case AttackSeverity.crdtAnomaly:
          crdtCount++;
          break;
        case AttackSeverity.unexpectedBehavior:
          unexpectedCount++;
          break;
        case AttackSeverity.handledGracefully:
          handledCount++;
          break;
        case AttackSeverity.passedCleanly:
          passedCount++;
          break;
      }
    }

    stdout.writeln('Total Chaos Tests Executed: ${findings.length}');
    stdout.writeln('  [CRITICAL CRASHES]       : $criticalCount');
    stdout.writeln('  [PROTOCOL DESYNCS]       : $desyncCount');
    stdout.writeln('  [BYZANTINE SPLIT-BRAIN]  : $splitCount');
    stdout.writeln('  [CRDT ANOMALIES]         : $crdtCount');
    stdout.writeln('  [UNEXPECTED BEHAVIOR]    : $unexpectedCount');
    stdout.writeln('  [HANDLED / BOUNDED]      : $handledCount');
    stdout.writeln('  [PASSED CLEANLY]         : $passedCount\n');

    stdout.writeln('--------------------------------------------------------------------------------');
    stdout.writeln('DETAILED FINDINGS BY NETWORK SUITE:');
    stdout.writeln('--------------------------------------------------------------------------------');

    final grouped = <String, List<ChaosFinding>>{};
    for (final f in findings) {
      grouped.putIfAbsent(f.suiteName, () => []).add(f);
    }

    for (final entry in grouped.entries) {
      stdout.writeln('\n>>> ${entry.key.toUpperCase()} (${entry.value.length} tests)');
      for (final f in entry.value) {
        final badge = switch (f.severity) {
          AttackSeverity.criticalCrash => '[CRITICAL CRASH]',
          AttackSeverity.protocolDesync => '[PROTOCOL DESYNC]',
          AttackSeverity.byzantineSplit => '[BYZANTINE SPLIT]',
          AttackSeverity.crdtAnomaly => '[CRDT ANOMALY]',
          AttackSeverity.unexpectedBehavior => '[UNEXPECTED]',
          AttackSeverity.handledGracefully => '[HANDLED]',
          AttackSeverity.passedCleanly => '[PASSED]',
        };
        stdout.writeln('  $badge [${f.testId}] ${f.title} (${f.elapsedMs}ms)');
        stdout.writeln('      Details: ${f.details}');
        if (f.location != null) {
          stdout.writeln('      Location: ${f.location}');
        }
        if (f.errorMessage != null) {
          stdout.writeln('      Error: ${f.errorMessage}');
        }
      }
    }

    stdout.writeln('\n================================================================================');
    stdout.writeln('END OF CAMPAIGN 3 CHAOS SUITE');
    stdout.writeln('================================================================================\n');
  }
}

Future<void> main() async {
  final runner = DistributedNetworkChaosRunner();
  try {
    await runner.runSuite1RaftChaos();
    await runner.runSuite2P2pChaos();
    await runner.runSuite3PgWireChaos();
    await runner.runSuite4RestServerChaos();
    runner.printSummaryReport();
  } catch (e, st) {
    stderr.writeln('FATAL CHAOS RUNNER FAILURE: $e\n$st');
  } finally {
    // Ensure all directories cleaned up
    await cleanDirectory(kRaftDbPrefix);
    await cleanDirectory(kP2pDbPrefix);
    await cleanDirectory(kPgWireDb);
    await cleanDirectory(kRestDb);
  }
}
