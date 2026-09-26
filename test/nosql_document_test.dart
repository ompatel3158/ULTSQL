import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  const dbDir = 'test_nosql_doc_db';

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

  test('NoSQL Document Store: CRUD & Dotted-Path Operations', () async {
    final engine = await UltSqlEngine.openFile(dbDir);
    final users = engine.collection('users');

    // 1. insertOne with nested fields
    final doc1 = await users.insertOne({
      'name': 'Alice Smith',
      'email': 'alice@google.com',
      'age': 28,
      'profile': {
        'tier': 'pro',
        'karma': 1200,
        'city': 'San Francisco',
      },
      'tags': ['flutter', 'dart', 'systems'],
    });

    expect(doc1.id, isNotEmpty);
    expect(doc1.getByPath('profile.city'), 'San Francisco');
    expect(doc1.getByPath('tags.0'), 'flutter');

    // 2. findOne by _id
    final found = await users.findOne({'_id': doc1.id});
    expect(found, isNotNull);
    expect(found!.getByPath('name'), 'Alice Smith');
    expect(found.getByPath('profile.tier'), 'pro');

    // 3. insertMany
    final docs = await users.insertMany([
      {
        'name': 'Bob Jones',
        'email': 'bob@acme.com',
        'age': 35,
        'profile': {'tier': 'starter', 'karma': 450, 'city': 'Austin'},
        'tags': ['dart', 'web'],
      },
      {
        'name': 'Charlie Day',
        'email': 'charlie@google.com',
        'age': 42,
        'profile': {'tier': 'pro', 'karma': 2500, 'city': 'Seattle'},
        'tags': ['flutter', 'ai', 'cloud'],
      },
      {
        'name': 'Diana Prince',
        'email': 'diana@amazon.com',
        'age': 31,
        'profile': {'tier': 'enterprise', 'karma': 5000, 'city': 'New York'},
        'tags': ['security', 'db', 'cloud'],
      },
    ]);
    expect(docs.length, 3);

    // 4. countDocuments
    final totalCount = await users.countDocuments();
    expect(totalCount, 4);

    // 5. Query Filter with $gt and dotted path
    final proUsers = await users.find({
      'profile.tier': 'pro',
      'profile.karma': {r'$gte': 1000},
    }).toList();
    expect(proUsers.length, 2); // Alice & Charlie

    // 6. Query Filter with $in, $or, $regex
    final cloudOrSystems = await users.find({
      r'$or': [
        {'tags': {r'$in': ['cloud']}},
        {'tags': {r'$in': ['systems']}},
      ],
    }).toList();
    expect(cloudOrSystems.length, 3); // Alice, Charlie, Diana

    final googleUsers = await users.find({
      'email': {r'$regex': r'@google\.com$'},
    }).toList();
    expect(googleUsers.length, 2); // Alice & Charlie

    // 7. Cursor Sorting, Skip, Limit, Projection
    final sorted = await users.find()
        .sort({'profile.karma': -1}) // Highest karma first
        .skip(1)
        .limit(2)
        .project({'name': 1, 'profile.karma': 1})
        .toList();

    expect(sorted.length, 2);
    // Highest is Diana (5000), skipped. Next is Charlie (2500), then Alice (1200)
    expect(sorted[0].getByPath('name'), 'Charlie Day');
    expect(sorted[1].getByPath('name'), 'Alice Smith');
    // Projection excluded email
    expect(sorted[0].getByPath('email'), isNull);

    // 8. Atomic updateOne ($inc, $set, $push)
    final updateRes = await users.updateOne(
      filter: {'email': 'alice@google.com'},
      update: {
        r'$inc': {'profile.karma': 300},
        r'$set': {'profile.title': 'Principal Engineer'},
        r'$push': {'tags': 'rust'},
      },
    );
    expect(updateRes.matchedCount, 1);
    expect(updateRes.modifiedCount, 1);

    final updatedAlice = await users.findOne({'email': 'alice@google.com'});
    expect(updatedAlice!.getByPath('profile.karma'), 1500);
    expect(updatedAlice.getByPath('profile.title'), 'Principal Engineer');
    expect((updatedAlice.getByPath('tags') as List).contains('rust'), true);

    // 9. Upsert behavior
    final upsertRes = await users.updateOne(
      filter: {'email': 'eve@test.com'},
      update: {
        r'$set': {'name': 'Eve Evans', 'age': 22},
      },
      upsert: true,
    );
    expect(upsertRes.upsertedId, isNotNull);
    final eve = await users.findOne({'email': 'eve@test.com'});
    expect(eve, isNotNull);
    expect(eve!.getByPath('name'), 'Eve Evans');

    // 10. deleteOne & deleteMany
    final delOne = await users.deleteOne({'email': 'eve@test.com'});
    expect(delOne, 1);
    final afterDelOne = await users.countDocuments();
    expect(afterDelOne, 4);

    final delMany = await users.deleteMany({'profile.tier': 'starter'});
    expect(delMany, 1); // Bob
    expect(await users.countDocuments(), 3);

    // 11. Cross-Model SQL Bridge
    final sqlRes = await engine.query(
      "SELECT _id, doc->>'name' as name, doc->'profile'->>'tier' as tier FROM collection('users') ORDER BY name ASC;",
    );
    expect(sqlRes.rows.length, 3);
    expect(sqlRes.columns.contains('name'), true);

    await engine.close();

    // 12. Verification of Disk Durability (reopening fresh database)
    final reopenedEngine = await UltSqlEngine.openFile(dbDir);
    final reopenedUsers = reopenedEngine.collection('users');
    final persistedCount = await reopenedUsers.countDocuments();
    expect(persistedCount, 3);

    final verifiedAlice = await reopenedUsers.findOne({'email': 'alice@google.com'});
    expect(verifiedAlice, isNotNull);
    expect(verifiedAlice!.getByPath('profile.karma'), 1500);

    await reopenedEngine.close();
  });
}
