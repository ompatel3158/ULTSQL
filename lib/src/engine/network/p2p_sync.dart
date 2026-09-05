/// State-Based LWW-Element-Set CRDT for Offline P2P Synchronization
class CrdtState {
  final Map<String, dynamic> addSet;
  final Map<String, int> timestamps;

  CrdtState({Map<String, dynamic>? addSet, Map<String, int>? timestamps})
    : addSet = addSet ?? {},
      timestamps = timestamps ?? {};

  void update(String key, dynamic value, int timestamp) {
    if (!timestamps.containsKey(key) || timestamp >= timestamps[key]!) {
      addSet[key] = value;
      timestamps[key] = timestamp;
    }
  }

  Map<String, dynamic> toJson() => {
    'addSet': addSet,
    'timestamps': timestamps,
  };

  factory CrdtState.fromJson(Map<String, dynamic> json) {
    final rawAddSet = json['addSet'] as Map<String, dynamic>? ?? {};
    final rawTimestamps = (json['timestamps'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    return CrdtState(
      addSet: Map<String, dynamic>.from(rawAddSet),
      timestamps: rawTimestamps,
    );
  }
}

/// Peer-to-Peer Offline Multi-Master Sync Node
class P2pSyncNode {
  final String nodeId;
  final CrdtState localState = CrdtState();

  P2pSyncNode(this.nodeId);

  /// Merges remote peer state into local CRDT state using Last-Write-Wins (LWW) resolution
  bool mergePeerState(CrdtState remoteState) {
    bool stateChanged = false;
    for (final entry in remoteState.addSet.entries) {
      final key = entry.key;
      final value = entry.value;
      final remoteTs = remoteState.timestamps[key] ?? 0;

      if (!localState.timestamps.containsKey(key) ||
          remoteTs > localState.timestamps[key]!) {
        localState.update(key, value, remoteTs);
        stateChanged = true;
      }
    }
    return stateChanged;
  }
}
