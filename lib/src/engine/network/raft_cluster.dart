import 'dart:async';
import 'dart:math';

enum RaftNodeRole { follower, candidate, leader }

class RaftLogEntry {
  final int term;
  final int index;
  final String command;

  const RaftLogEntry({
    required this.term,
    required this.index,
    required this.command,
  });

  Map<String, dynamic> toJson() => {
    'term': term,
    'index': index,
    'command': command,
  };

  factory RaftLogEntry.fromJson(Map<String, dynamic> json) => RaftLogEntry(
    term: (json['term'] as num).toInt(),
    index: (json['index'] as num).toInt(),
    command: json['command'] as String,
  );
}

class RequestVoteArgs {
  final int term;
  final String candidateId;
  final int lastLogIndex;
  final int lastLogTerm;

  RequestVoteArgs({
    required this.term,
    required this.candidateId,
    required this.lastLogIndex,
    required this.lastLogTerm,
  });

  Map<String, dynamic> toJson() => {
    'term': term,
    'candidateId': candidateId,
    'lastLogIndex': lastLogIndex,
    'lastLogTerm': lastLogTerm,
  };

  factory RequestVoteArgs.fromJson(Map<String, dynamic> json) =>
      RequestVoteArgs(
        term: (json['term'] as num).toInt(),
        candidateId: json['candidateId'] as String,
        lastLogIndex: (json['lastLogIndex'] as num).toInt(),
        lastLogTerm: (json['lastLogTerm'] as num).toInt(),
      );
}

class RequestVoteReply {
  final int term;
  final bool voteGranted;

  RequestVoteReply({required this.term, required this.voteGranted});

  Map<String, dynamic> toJson() => {
    'term': term,
    'voteGranted': voteGranted,
  };

  factory RequestVoteReply.fromJson(Map<String, dynamic> json) =>
      RequestVoteReply(
        term: (json['term'] as num).toInt(),
        voteGranted: json['voteGranted'] as bool,
      );
}

class AppendEntriesArgs {
  final int term;
  final String leaderId;
  final int prevLogIndex;
  final int prevLogTerm;
  final List<RaftLogEntry> entries;
  final int leaderCommit;

  AppendEntriesArgs({
    required this.term,
    required this.leaderId,
    required this.prevLogIndex,
    required this.prevLogTerm,
    required this.entries,
    required this.leaderCommit,
  });

  Map<String, dynamic> toJson() => {
    'term': term,
    'leaderId': leaderId,
    'prevLogIndex': prevLogIndex,
    'prevLogTerm': prevLogTerm,
    'entries': entries.map((e) => e.toJson()).toList(),
    'leaderCommit': leaderCommit,
  };

  factory AppendEntriesArgs.fromJson(Map<String, dynamic> json) =>
      AppendEntriesArgs(
        term: (json['term'] as num).toInt(),
        leaderId: json['leaderId'] as String,
        prevLogIndex: (json['prevLogIndex'] as num).toInt(),
        prevLogTerm: (json['prevLogTerm'] as num).toInt(),
        entries: (json['entries'] as List)
            .map((e) => RaftLogEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        leaderCommit: (json['leaderCommit'] as num).toInt(),
      );
}

class AppendEntriesReply {
  final int term;
  final bool success;
  final int matchIndex;

  AppendEntriesReply({
    required this.term,
    required this.success,
    required this.matchIndex,
  });

  Map<String, dynamic> toJson() => {
    'term': term,
    'success': success,
    'matchIndex': matchIndex,
  };

  factory AppendEntriesReply.fromJson(Map<String, dynamic> json) =>
      AppendEntriesReply(
        term: (json['term'] as num).toInt(),
        success: json['success'] as bool,
        matchIndex: (json['matchIndex'] as num).toInt(),
      );
}

/// Abstract network transport interface for Raft peer communication
abstract class RaftTransport {
  Future<RequestVoteReply> sendRequestVote(
    String peerId,
    RequestVoteArgs args,
  );
  Future<AppendEntriesReply> sendAppendEntries(
    String peerId,
    AppendEntriesArgs args,
  );
}

/// In-Memory cluster transport for testing and local multi-node coordination
class InMemoryRaftTransport implements RaftTransport {
  final Map<String, RaftClusterNode> nodes = {};

  void registerNode(RaftClusterNode node) {
    nodes[node.nodeId] = node;
  }

  @override
  Future<RequestVoteReply> sendRequestVote(
    String peerId,
    RequestVoteArgs args,
  ) async {
    final target = nodes[peerId];
    if (target == null) {
      return RequestVoteReply(term: args.term, voteGranted: false);
    }
    return target.handleRequestVote(args);
  }

  @override
  Future<AppendEntriesReply> sendAppendEntries(
    String peerId,
    AppendEntriesArgs args,
  ) async {
    final target = nodes[peerId];
    if (target == null) {
      return AppendEntriesReply(term: args.term, success: false, matchIndex: 0);
    }
    return target.handleAppendEntries(args);
  }
}

/// Lightweight Raft Node state machine for local simulations and tests.
class RaftNode {
  final String nodeId;
  RaftNodeRole role;
  int currentTerm;
  String? votedFor;

  RaftNode({
    required this.nodeId,
    this.role = RaftNodeRole.follower,
    this.currentTerm = 0,
    this.votedFor,
  });

  void becomeCandidate() {
    role = RaftNodeRole.candidate;
    currentTerm++;
    votedFor = nodeId;
  }

  void becomeLeader() {
    role = RaftNodeRole.leader;
  }

  void becomeFollower(int term) {
    role = RaftNodeRole.follower;
    currentTerm = term;
    votedFor = null;
  }

  bool requestVote(int term, String candidateId, int lastLogIndex, int lastLogTerm) {
    if (term > currentTerm) {
      becomeFollower(term);
    }
    if (term == currentTerm && (votedFor == null || votedFor == candidateId)) {
      votedFor = candidateId;
      return true;
    }
    return false;
  }
}

/// Distributed Raft Consensus Engine Node
class RaftClusterNode {
  final String nodeId;
  final List<String> peers;
  final RaftTransport transport;
  final void Function(RaftLogEntry entry)? onStateCommitted;

  RaftNodeRole role = RaftNodeRole.follower;
  int currentTerm = 0;
  String? votedFor;
  final List<RaftLogEntry> log = [];

  int commitIndex = 0;
  int lastApplied = 0;

  final Map<String, int> nextIndex = {};
  final Map<String, int> matchIndex = {};

  Timer? _electionTimer;
  Timer? _heartbeatTimer;
  final Random _rng = Random();

  RaftClusterNode({
    required this.nodeId,
    required this.peers,
    required this.transport,
    this.onStateCommitted,
  });

  void start() {
    _resetElectionTimer();
  }

  void stop() {
    _electionTimer?.cancel();
    _heartbeatTimer?.cancel();
  }

  int get lastLogIndex => log.isEmpty ? 0 : log.last.index;
  int get lastLogTerm => log.isEmpty ? 0 : log.last.term;

  void _resetElectionTimer() {
    _electionTimer?.cancel();
    // Randomized election timeout between 150ms and 300ms
    final timeoutMs = 150 + _rng.nextInt(150);
    _electionTimer = Timer(Duration(milliseconds: timeoutMs), _startElection);
  }

  Future<void> _startElection() async {
    role = RaftNodeRole.candidate;
    currentTerm++;
    votedFor = nodeId;
    int votesGranted = 1; // Vote for self
    _resetElectionTimer();

    final args = RequestVoteArgs(
      term: currentTerm,
      candidateId: nodeId,
      lastLogIndex: lastLogIndex,
      lastLogTerm: lastLogTerm,
    );

    final futures = peers.map((p) => transport.sendRequestVote(p, args));
    final replies = await Future.wait(futures);

    if (role != RaftNodeRole.candidate) return;

    for (final reply in replies) {
      if (reply.term > currentTerm) {
        _becomeFollower(reply.term);
        return;
      }
      if (reply.voteGranted) {
        votesGranted++;
      }
    }

    final totalNodes = peers.length + 1;
    final quorum = (totalNodes ~/ 2) + 1;
    if (votesGranted >= quorum) {
      _becomeLeader();
    }
  }

  void _becomeLeader() {
    role = RaftNodeRole.leader;
    _electionTimer?.cancel();

    for (final peer in peers) {
      nextIndex[peer] = lastLogIndex + 1;
      matchIndex[peer] = 0;
    }

    _sendHeartbeats();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _sendHeartbeats(),
    );
  }

  void _becomeFollower(int term) {
    role = RaftNodeRole.follower;
    currentTerm = term;
    votedFor = null;
    _heartbeatTimer?.cancel();
    _resetElectionTimer();
  }

  Future<void> _sendHeartbeats() async {
    if (role != RaftNodeRole.leader) return;

    for (final peer in peers) {
      final pNext = nextIndex[peer] ?? (lastLogIndex + 1);
      final prevIndex = pNext - 1;
      int prevTerm = 0;
      if (prevIndex > 0 && prevIndex <= log.length) {
        prevTerm = log[prevIndex - 1].term;
      }

      final entriesToSend =
          pNext <= log.length ? log.sublist(pNext - 1) : <RaftLogEntry>[];

      final args = AppendEntriesArgs(
        term: currentTerm,
        leaderId: nodeId,
        prevLogIndex: prevIndex,
        prevLogTerm: prevTerm,
        entries: entriesToSend,
        leaderCommit: commitIndex,
      );

      transport.sendAppendEntries(peer, args).then((reply) {
        if (reply.term > currentTerm) {
          _becomeFollower(reply.term);
          return;
        }
        if (role == RaftNodeRole.leader) {
          if (reply.success) {
            nextIndex[peer] = reply.matchIndex + 1;
            matchIndex[peer] = reply.matchIndex;
            _checkAndUpdateCommitIndex();
          } else {
            nextIndex[peer] = max(1, (nextIndex[peer] ?? 1) - 1);
          }
        }
      });
    }
  }

  void _checkAndUpdateCommitIndex() {
    if (role != RaftNodeRole.leader) return;

    final totalNodes = peers.length + 1;
    final quorum = (totalNodes ~/ 2) + 1;

    for (int n = commitIndex + 1; n <= log.length; n++) {
      if (log[n - 1].term == currentTerm) {
        int matchCount = 1; // self
        for (final peer in peers) {
          if ((matchIndex[peer] ?? 0) >= n) {
            matchCount++;
          }
        }
        if (matchCount >= quorum) {
          commitIndex = n;
          _applyLogEntries();
        }
      }
    }
  }

  void _applyLogEntries() {
    while (commitIndex > lastApplied) {
      lastApplied++;
      final entry = log[lastApplied - 1];
      if (onStateCommitted != null) {
        onStateCommitted!(entry);
      }
    }
  }

  RequestVoteReply handleRequestVote(RequestVoteArgs args) {
    if (args.term > currentTerm) {
      _becomeFollower(args.term);
    }

    if (args.term < currentTerm) {
      return RequestVoteReply(term: currentTerm, voteGranted: false);
    }

    final canVote = (votedFor == null || votedFor == args.candidateId);
    final isUpToDate = args.lastLogTerm > lastLogTerm ||
        (args.lastLogTerm == lastLogTerm && args.lastLogIndex >= lastLogIndex);

    if (canVote && isUpToDate) {
      votedFor = args.candidateId;
      _resetElectionTimer();
      return RequestVoteReply(term: currentTerm, voteGranted: true);
    }

    return RequestVoteReply(term: currentTerm, voteGranted: false);
  }

  AppendEntriesReply handleAppendEntries(AppendEntriesArgs args) {
    if (args.term < currentTerm) {
      return AppendEntriesReply(
        term: currentTerm,
        success: false,
        matchIndex: lastLogIndex,
      );
    }

    if (args.term > currentTerm || role == RaftNodeRole.candidate) {
      _becomeFollower(args.term);
    }

    _resetElectionTimer();

    // Check log consistency at prevLogIndex
    if (args.prevLogIndex > 0) {
      if (log.length < args.prevLogIndex) {
        return AppendEntriesReply(
          term: currentTerm,
          success: false,
          matchIndex: log.length,
        );
      }
      if (log[args.prevLogIndex - 1].term != args.prevLogTerm) {
        return AppendEntriesReply(
          term: currentTerm,
          success: false,
          matchIndex: args.prevLogIndex - 1,
        );
      }
    }

    // Append entries not already in the log
    int insertIndex = args.prevLogIndex;
    for (final entry in args.entries) {
      insertIndex++;
      if (insertIndex <= log.length) {
        if (log[insertIndex - 1].term != entry.term) {
          log.removeRange(insertIndex - 1, log.length);
          log.add(entry);
        }
      } else {
        log.add(entry);
      }
    }

    if (args.leaderCommit > commitIndex) {
      commitIndex = min(args.leaderCommit, log.length);
      _applyLogEntries();
    }

    return AppendEntriesReply(
      term: currentTerm,
      success: true,
      matchIndex: log.length,
    );
  }

  /// Submits a write command to the cluster leader for replicated consensus commit
  Future<bool> executeReplicatedCommand(
    String command, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (role != RaftNodeRole.leader) {
      return false;
    }

    final entryIndex = log.length + 1;
    final entry = RaftLogEntry(
      term: currentTerm,
      index: entryIndex,
      command: command,
    );
    log.add(entry);

    // Broadcast immediately to followers
    _sendHeartbeats();

    final sw = Stopwatch()..start();
    while (sw.elapsed < timeout) {
      if (commitIndex >= entryIndex) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }
    return false;
  }
}

class TwoPhaseCommitCoordinator {
  final Map<String, List<String>> _activeTransactions = {};
  final Map<String, String> _transactionStates = {};

  bool prepareTransaction(String txId, List<String> participants) {
    if (participants.isEmpty) return false;
    _activeTransactions[txId] = participants;
    _transactionStates[txId] = 'PREPARED';
    return true;
  }

  bool commitTransaction(String txId) {
    if (!_transactionStates.containsKey(txId) ||
        _transactionStates[txId] != 'PREPARED') {
      return false;
    }
    _transactionStates[txId] = 'COMMITTED';
    return true;
  }

  bool abortTransaction(String txId) {
    if (!_transactionStates.containsKey(txId)) return false;
    _transactionStates[txId] = 'ABORTED';
    return true;
  }

  String? getTransactionState(String txId) => _transactionStates[txId];
}
