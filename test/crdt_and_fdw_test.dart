import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  group('Delta-CRDT with Hybrid Logical Clocks & Tombstones', () {
    test('HlcTimestamp maintains strict ordering with counters', () {
      final t1 = HlcTimestamp(1000, 0, 'nodeA');
      final t2 = HlcTimestamp(1000, 1, 'nodeA');
      final t3 = HlcTimestamp(1001, 0, 'nodeB');

      expect(t1.compareTo(t2) < 0, isTrue);
      expect(t2.compareTo(t3) < 0, isTrue);
    });

    test('P2pSyncNode handles offline updates and tombstone deletions', () {
      final nodeA = P2pSyncNode('device_A');
      final nodeB = P2pSyncNode('device_B');

      // 1. Device A sets a record
      nodeA.set('user:101', {'name': 'Alice', 'role': 'admin'});
      expect(nodeA.localState.contains('user:101'), isTrue);

      // 2. Sync A -> B
      nodeB.mergePeerState(nodeA.localState);
      expect(nodeB.localState.contains('user:101'), isTrue);
      expect(
        (nodeB.localState.get('user:101') as Map)['name'],
        'Alice',
      );

      // 3. Device B deletes the record
      nodeB.delete('user:101');
      expect(nodeB.localState.contains('user:101'), isFalse);

      // 4. Device A attempts an older update before sync
      // Sync B -> A (tombstone propagation)
      nodeA.mergePeerState(nodeB.localState);
      expect(nodeA.localState.contains('user:101'), isFalse);
    });

    test('Delta generation only transmits changed keys', () {
      final node = P2pSyncNode('device_A');
      final baseTime = DateTime.now().millisecondsSinceEpoch - 5000;

      node.set('item:old', 'value1');
      final deltaOld = node.localState.getDeltaSince(baseTime);
      expect(deltaOld.contains('item:old'), isTrue);

      final futureTime = DateTime.now().millisecondsSinceEpoch + 10000;
      final emptyDelta = node.localState.getDeltaSince(futureTime);
      expect(emptyDelta.contains('item:old'), isFalse);
    });
  });

  group('RFC 4180 CSV & Foreign Data Wrapper', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ultsql_fdw_test_');
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('Rfc4180Parser correctly handles quoted commas and escaped quotes', () {
      final line = '101,"Smith, John","He said ""Hello"" to all",99.5';
      final tokens = Rfc4180Parser.parseLine(line);

      expect(tokens.length, 4);
      expect(tokens[0], '101');
      expect(tokens[1], 'Smith, John');
      expect(tokens[2], 'He said "Hello" to all');
      expect(tokens[3], '99.5');
    });

    test('UniversalFileAdapter.queryCsvFile queries RFC 4180 CSV files', () {
      final csvFile = File('${tempDir.path}/users.csv');
      csvFile.writeAsStringSync('''id,name,city,active
1,"Alice Smith","New York, NY",1
2,"Bob Jones","Los Angeles, CA",1
3,"Charlie Brown","Chicago, IL",0
''');

      final results = UniversalFileAdapter.queryCsvFile(csvFile.path, 'New York');
      expect(results.length, 1);
      expect(results[0][0].toString(), '1');
      expect(results[0][1].toString(), 'Alice Smith');
      expect(results[0][2].toString(), 'New York, NY');
    });
  });
}
