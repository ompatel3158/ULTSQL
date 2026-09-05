import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/network/p2p_sync.dart';

void main() {
  test('CRDT State and P2pSyncNode LWW merging and JSON serialization', () {
    final nodeA = P2pSyncNode('node_a');
    nodeA.localState.update('user:1', {'name': 'Alice'}, 100);

    final nodeB = P2pSyncNode('node_b');
    nodeB.localState.update('user:1', {'name': 'Alice Updated'}, 200);
    nodeB.localState.update('user:2', {'name': 'Bob'}, 150);

    // Serialize nodeB state to JSON and restore into new CrdtState
    final jsonMap = nodeB.localState.toJson();
    final restoredBState = CrdtState.fromJson(jsonMap);

    // Merge remote state into nodeA
    final changed = nodeA.mergePeerState(restoredBState);
    expect(changed, isTrue);

    expect(nodeA.localState.addSet['user:1']['name'], 'Alice Updated');
    expect(nodeA.localState.addSet['user:2']['name'], 'Bob');
  });
}
