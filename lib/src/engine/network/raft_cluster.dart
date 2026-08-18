enum RaftNodeRole { follower, candidate, leader }

class RaftNode {
  final String nodeId;
  int currentTerm;
  String? votedFor;
  List<dynamic> logEntries;
  RaftNodeRole role;

  RaftNode({
    required this.nodeId,
    this.currentTerm = 0,
    this.votedFor,
    List<dynamic>? logEntries,
    this.role = RaftNodeRole.follower,
  }) : logEntries = logEntries ?? [];

  bool requestVote(
    int term,
    String candidateId,
    int lastLogIndex,
    int lastLogTerm,
  ) {
    if (term < currentTerm) {
      return false;
    }

    if (term > currentTerm) {
      currentTerm = term;
      role = RaftNodeRole.follower;
      votedFor = null;
    }

    if (votedFor == null || votedFor == candidateId) {
      votedFor = candidateId;
      return true;
    }

    return false;
  }

  bool appendEntries(
    int term,
    String leaderId,
    int prevLogIndex,
    int prevLogTerm,
    List<dynamic> entries,
    int leaderCommit,
  ) {
    if (term < currentTerm) {
      return false;
    }

    if (term > currentTerm) {
      currentTerm = term;
    }

    role = RaftNodeRole.follower;
    votedFor = leaderId;
    logEntries.addAll(entries);
    return true;
  }

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
