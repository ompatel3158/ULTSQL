import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  const dbDir = 'test_nosql_kv_db';

  void cleanDb() {
    final dir = Directory(dbDir);
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  setUp(cleanDb);
  tearDown(cleanDb);

  test('NoSQL Key-Value Store: Caching, Counters, TTL, and Disk Durability', () async {
    final engine = await UltSqlEngine.openFile(dbDir);
    final kv = engine.kv;

    // 1. Basic Set & Get of primitive types
    await kv.set('app:version', '1.0.22');
    await kv.set('config:port', 8080);
    await kv.set('config:ssl', true);
    await kv.set('metric:latency', 12.45);

    expect(await kv.get('app:version'), '1.0.22');
    expect(await kv.get('config:port'), 8080);
    expect(await kv.get('config:ssl'), true);
    expect(await kv.get('metric:latency'), 12.45);
    expect(await kv.has('app:version'), true);
    expect(await kv.has('non_existent'), false);

    // 2. Structured JSON Map & List values
    final sessionData = {
      'user_id': 1001,
      'role': 'superadmin',
      'permissions': ['read', 'write', 'deploy'],
    };
    await kv.set('session:1001', sessionData);

    final retrievedSession = await kv.get('session:1001') as Map;
    expect(retrievedSession['user_id'], 1001);
    expect(retrievedSession['role'], 'superadmin');
    expect((retrievedSession['permissions'] as List).contains('deploy'), true);

    // 3. Atomic Increment & Decrement Counters
    await kv.set('stats:page_views', 100);
    final incrVal = await kv.incr('stats:page_views', 5);
    expect(incrVal, 105);
    expect(await kv.get('stats:page_views'), 105);

    final decrVal = await kv.decr('stats:page_views', 10);
    expect(decrVal, 95);

    // 4. Batch Operations (mset, mget)
    await kv.mset({
      'flag:feature_a': true,
      'flag:feature_b': false,
      'flag:feature_c': true,
    });

    final batch = await kv.mget(['flag:feature_a', 'flag:feature_b', 'not_found']);
    expect(batch['flag:feature_a'], true);
    expect(batch['flag:feature_b'], false);
    expect(batch.containsKey('not_found'), false);

    // 5. Pattern Matching Keys
    final flagKeys = await kv.keys(pattern: 'flag:*');
    expect(flagKeys.length, 3);
    expect(flagKeys.contains('flag:feature_a'), true);

    // 6. Time-To-Live (TTL) Expiration
    await kv.set('temp:otp', '984123', ttl: const Duration(milliseconds: 50));
    expect(await kv.get('temp:otp'), '984123');

    // Wait for TTL expiration
    await Future.delayed(const Duration(milliseconds: 70));
    expect(await kv.get('temp:otp'), isNull);
    expect(await kv.has('temp:otp'), false);

    // 7. Delete
    final delSuccess = await kv.delete('metric:latency');
    expect(delSuccess, true);
    expect(await kv.get('metric:latency'), isNull);

    await engine.close();

    // 8. Reopening Fresh Database to verify physical WAL Disk Durability
    final reopenedEngine = await UltSqlEngine.openFile(dbDir);
    final reopenedKv = reopenedEngine.kv;

    expect(await reopenedKv.get('app:version'), '1.0.22');
    expect(await reopenedKv.get('config:port'), 8080);
    expect(await reopenedKv.get('stats:page_views'), 95);

    final reloadedSession = await reopenedKv.get('session:1001') as Map;
    expect(reloadedSession['role'], 'superadmin');

    // Expired item should still be absent
    expect(await reopenedKv.get('temp:otp'), isNull);

    await reopenedEngine.close();
  });
}
