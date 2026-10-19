/// Hybrid Logical Clock (HLC) for physical and logical ordering across peer devices
class HlcTimestamp implements Comparable<HlcTimestamp> {
  final int millis;
  final int counter;
  final String nodeId;

  const HlcTimestamp(this.millis, this.counter, this.nodeId);

  factory HlcTimestamp.now(String nodeId, {HlcTimestamp? last}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (last == null) {
      return HlcTimestamp(now, 0, nodeId);
    }
    if (now > last.millis) {
      return HlcTimestamp(now, 0, nodeId);
    }
    return HlcTimestamp(last.millis, last.counter + 1, nodeId);
  }

  factory HlcTimestamp.receive(
    HlcTimestamp remote,
    String nodeId, {
    HlcTimestamp? last,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastMillis = last?.millis ?? 0;
    final maxMillis = [now, lastMillis, remote.millis].reduce(
      (a, b) => a > b ? a : b,
    );

    int newCounter = 0;
    if (maxMillis == remote.millis && last != null && maxMillis == last.millis) {
      newCounter = (remote.counter > last.counter ? remote.counter : last.counter) + 1;
    } else if (maxMillis == remote.millis) {
      newCounter = remote.counter + 1;
    } else if (last != null && maxMillis == last.millis) {
      newCounter = last.counter + 1;
    }

    return HlcTimestamp(maxMillis, newCounter, nodeId);
  }

  @override
  int compareTo(HlcTimestamp other) {
    if (millis != other.millis) return millis.compareTo(other.millis);
    if (counter != other.counter) return counter.compareTo(other.counter);
    return nodeId.compareTo(other.nodeId);
  }

  Map<String, dynamic> toJson() => {
    'm': millis,
    'c': counter,
    'n': nodeId,
  };

  factory HlcTimestamp.fromJson(Map<String, dynamic> json) => HlcTimestamp(
    (json['m'] as num).toInt(),
    (json['c'] as num).toInt(),
    json['n'] as String,
  );

  @override
  String toString() => '$millis:$counter:$nodeId';
}

/// State-Based Delta LWW-Element-Set CRDT with Tombstone Deletion Support
class CrdtState {
  final Map<String, dynamic> addSet;
  final Map<String, HlcTimestamp> timestamps;
  final Map<String, HlcTimestamp> tombstones;

  CrdtState({
    Map<String, dynamic>? addSet,
    Map<String, HlcTimestamp>? timestamps,
    Map<String, HlcTimestamp>? tombstones,
  })  : addSet = addSet ?? {},
        timestamps = timestamps ?? {},
        tombstones = tombstones ?? {};

  /// Updates or inserts a value with an HLC timestamp or numeric timestamp
  void update(String key, dynamic value, dynamic timestamp) {
    final HlcTimestamp ts = timestamp is HlcTimestamp
        ? timestamp
        : (timestamp is num
            ? HlcTimestamp(timestamp.toInt(), 0, 'legacy')
            : HlcTimestamp.now('legacy'));
    final curTs = timestamps[key];
    final tombTs = tombstones[key];

    // If a tombstone exists and is newer or equal, ignore update
    if (tombTs != null && tombTs.compareTo(ts) >= 0) {
      return;
    }

    if (curTs == null || ts.compareTo(curTs) >= 0) {
      addSet[key] = value;
      timestamps[key] = ts;
      tombstones.remove(key);
    }
  }

  /// Deletes a key by creating a tombstone
  void delete(String key, dynamic timestamp) {
    final HlcTimestamp ts = timestamp is HlcTimestamp
        ? timestamp
        : (timestamp is num
            ? HlcTimestamp(timestamp.toInt(), 0, 'legacy')
            : HlcTimestamp.now('legacy'));
    final curTs = timestamps[key];
    final tombTs = tombstones[key];

    if ((curTs == null || ts.compareTo(curTs) >= 0) &&
        (tombTs == null || ts.compareTo(tombTs) >= 0)) {
      addSet.remove(key);
      timestamps.remove(key);
      tombstones[key] = ts;
    }
  }

  /// Checks if key is currently active (not deleted or missing)
  bool contains(String key) => addSet.containsKey(key);

  dynamic get(String key) => addSet[key];

  /// Generates a delta changeset containing only updates/tombstones since `sinceMillis`
  CrdtState getDeltaSince(int sinceMillis) {
    final deltaAddSet = <String, dynamic>{};
    final deltaTimestamps = <String, HlcTimestamp>{};
    final deltaTombstones = <String, HlcTimestamp>{};

    for (final entry in timestamps.entries) {
      if (entry.value.millis >= sinceMillis) {
        deltaTimestamps[entry.key] = entry.value;
        deltaAddSet[entry.key] = addSet[entry.key];
      }
    }

    for (final entry in tombstones.entries) {
      if (entry.value.millis >= sinceMillis) {
        deltaTombstones[entry.key] = entry.value;
      }
    }

    return CrdtState(
      addSet: deltaAddSet,
      timestamps: deltaTimestamps,
      tombstones: deltaTombstones,
    );
  }

  Map<String, dynamic> toJson() => {
    'addSet': addSet,
    'timestamps': timestamps.map((k, v) => MapEntry(k, v.toJson())),
    'tombstones': tombstones.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory CrdtState.fromJson(Map<String, dynamic> json) {
    final rawAddSet = json['addSet'] as Map<String, dynamic>? ?? {};
    final rawTimestamps = (json['timestamps'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(
              k,
              v is Map<String, dynamic>
                  ? HlcTimestamp.fromJson(v)
                  : HlcTimestamp((v as num).toInt(), 0, 'legacy'),
            ));
    final rawTombstones = (json['tombstones'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(
              k,
              v is Map<String, dynamic>
                  ? HlcTimestamp.fromJson(v)
                  : HlcTimestamp((v as num).toInt(), 0, 'legacy'),
            ));

    return CrdtState(
      addSet: Map<String, dynamic>.from(rawAddSet),
      timestamps: rawTimestamps,
      tombstones: rawTombstones,
    );
  }
}

/// Peer-to-Peer Offline Multi-Master Sync Node
class P2pSyncNode {
  final String nodeId;
  final CrdtState localState = CrdtState();
  HlcTimestamp? _lastHlc;

  P2pSyncNode(this.nodeId);

  HlcTimestamp nextTimestamp() {
    final ts = HlcTimestamp.now(nodeId, last: _lastHlc);
    _lastHlc = ts;
    return ts;
  }

  /// Sets a relational row or key-value pair
  void set(String key, dynamic value) {
    final ts = nextTimestamp();
    localState.update(key, value, ts);
  }

  /// Deletes a row or key-value pair using a tombstone
  void delete(String key) {
    final ts = nextTimestamp();
    localState.delete(key, ts);
  }

  /// Merges remote peer state/delta into local CRDT state using LWW with tombstones
  bool mergePeerState(CrdtState remoteState) {
    bool stateChanged = false;

    // 1. Process remote updates
    for (final entry in remoteState.addSet.entries) {
      final key = entry.key;
      final value = entry.value;
      final remoteTs = remoteState.timestamps[key];
      if (remoteTs == null) continue;

      _lastHlc = HlcTimestamp.receive(remoteTs, nodeId, last: _lastHlc);

      final localTomb = localState.tombstones[key];
      if (localTomb != null && localTomb.compareTo(remoteTs) >= 0) {
        continue; // Local deletion wins
      }

      final localTs = localState.timestamps[key];
      if (localTs == null || remoteTs.compareTo(localTs) > 0) {
        localState.update(key, value, remoteTs);
        stateChanged = true;
      }
    }

    // 2. Process remote tombstones
    for (final entry in remoteState.tombstones.entries) {
      final key = entry.key;
      final remoteTombTs = entry.value;

      _lastHlc = HlcTimestamp.receive(remoteTombTs, nodeId, last: _lastHlc);

      final localTs = localState.timestamps[key];
      final localTomb = localState.tombstones[key];

      if ((localTs == null || remoteTombTs.compareTo(localTs) >= 0) &&
          (localTomb == null || remoteTombTs.compareTo(localTomb) > 0)) {
        localState.delete(key, remoteTombTs);
        stateChanged = true;
      }
    }

    return stateChanged;
  }
}
