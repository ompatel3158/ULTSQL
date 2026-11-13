import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/executor/jit_compiler.dart';
import 'package:ultsql/src/engine/parser/lexer.dart';
import 'package:ultsql/src/engine/parser/parser.dart';

void main() {
  group('Critical Defects Verification Suite', () {
    const dbDir = 'test_specialist_defects_db';

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

    test('Defect 1: No stale B+ Tree primary key index pointer after updateOne in reopened DB', () async {
      final engine1 = await UltSqlEngine.openFile(dbDir);
      final users1 = engine1.collection('users');

      final doc = await users1.insertOne({
        'name': 'Original Name',
        'role': 'Junior',
        'score': 100,
      });
      final docId = doc.id;
      expect(docId, isNotEmpty);

      // Perform updateOne (invokes REPLACE INTO)
      final updateRes = await users1.updateOne(
        filter: {'_id': docId},
        update: {
          r'$set': {'name': 'Updated Name', 'role': 'Senior'},
          r'$inc': {'score': 50},
        },
      );
      expect(updateRes.matchedCount, 1);
      expect(updateRes.modifiedCount, 1);

      // Verify immediately in same session
      final foundInSame = await users1.findOne({'_id': docId});
      expect(foundInSame, isNotNull);
      expect(foundInSame!.getByPath('name'), 'Updated Name');
      expect(foundInSame.getByPath('score'), 150);

      await engine1.close();

      // Open a fresh engine / database (simulating subsequent isolate session with clean hot cache)
      final engine2 = await UltSqlEngine.openFile(dbDir);
      final users2 = engine2.collection('users');

      // pointLookupById via B+ Tree index idx__coll_users__id
      final foundInFresh = users2.findOneSync({'_id': docId});
      expect(foundInFresh, isNotNull, reason: 'Point lookup by _id in subsequent session must not retrieve dead slot');
      expect(foundInFresh!.getByPath('name'), 'Updated Name');
      expect(foundInFresh.getByPath('role'), 'Senior');
      expect(foundInFresh.getByPath('score'), 150);

      // Perform a second update in engine2
      await users2.updateOne(
        filter: {'_id': docId},
        update: {
          r'$set': {'role': 'Staff'},
        },
      );

      await engine2.close();

      // Open a third session to verify repeated replacements
      final engine3 = await UltSqlEngine.openFile(dbDir);
      final users3 = engine3.collection('users');
      final foundInThird = users3.findOneSync({'_id': docId});
      expect(foundInThird, isNotNull);
      expect(foundInThird!.getByPath('role'), 'Staff');

      await engine3.close();
    });

    test('Defect 2: Heterogeneous cursor sorting (num vs String vs bool vs List) does not crash', () async {
      final engine = await UltSqlEngine.openFile(dbDir);
      final coll = engine.collection('hetero');

      await coll.insertMany([
        {'field': 'zebra'},
        {'field': 42.5},
        {'field': 'apple'},
        {'field': 10},
        {'field': true},
        {'field': false},
        {'field': [1, 2, 3]},
      ]);

      // Sort ascending - previously threw TypeError: type 'String' is not a subtype of type 'num' of 'other'
      final sortedAsc = await coll.find().sort({'field': 1}).toList();
      expect(sortedAsc.length, 7);

      // Sort descending
      final sortedDesc = await coll.find().sort({'field': -1}).toList();
      expect(sortedDesc.length, 7);

      // Check deterministic ordering in ascending: bool (false, true) < num (10, 42.5) < String ('apple', 'zebra') < List
      expect(sortedAsc[0].getByPath('field'), false);
      expect(sortedAsc[1].getByPath('field'), true);
      expect(sortedAsc[2].getByPath('field'), 10);
      expect(sortedAsc[3].getByPath('field'), 42.5);
      expect(sortedAsc[4].getByPath('field'), 'apple');
      expect(sortedAsc[5].getByPath('field'), 'zebra');

      await engine.close();
    });

    test('Defect 3: Malformed scientific notation (1e+, 1e-) returns syntax error without crashing', () async {
      final engine = await UltSqlEngine.openFile(dbDir);

      // Malformed scientific notation: must throw syntax/format error, not crash with unhandled exception
      expect(
        () async => await engine.query("SELECT 1e+;"),
        throwsA(isA<Exception>()),
      );
      expect(
        () async => await engine.query("SELECT 1e-;"),
        throwsA(isA<Exception>()),
      );

      // Valid scientific notation must continue to work properly
      final res1 = await engine.query("SELECT 1e10 AS val;");
      expect((res1.rows.first[0].value as num).toDouble(), 1e10);

      final res2 = await engine.query("SELECT 1e-5 AS val;");
      expect((res2.rows.first[0].value as num).toDouble(), closeTo(1e-5, 1e-9));

      final res3 = await engine.query("SELECT 2.5e+3 AS val;");
      expect((res3.rows.first[0].value as num).toDouble(), 2500.0);

      final res4 = await engine.query("SELECT 2.5e-3 AS val;");
      expect((res4.rows.first[0].value as num).toDouble(), closeTo(0.0025, 1e-9));

      // Direct Lexer/Parser checks
      final lexerPlus = Lexer("1e+");
      final tokensPlus = lexerPlus.tokenize();
      // Should not include exponent in number literal: token 1 is number, token 2 is e, token 3 is +
      expect(tokensPlus[0].lexeme, '1');

      final lexerMinus = Lexer("1e-");
      final tokensMinus = lexerMinus.tokenize();
      expect(tokensMinus[0].lexeme, '1');

      await engine.close();
    });

    test('Defect 4: ReDoS LIKE matching collapses adjacent wildcards and runs in microseconds', () {
      const redosPattern = '%_%_%_%_%_%_%_%_%_%_x';
      const nonMatchingInput = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

      final stopwatch = Stopwatch()..start();
      final match = matchLike(nonMatchingInput, redosPattern);
      stopwatch.stop();

      expect(match, isFalse);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Collapsing adjacent wildcards prevents exponential backtracking',
      );

      // Verify that positive matches still work (10 underscores = at least 10 chars before x)
      expect(matchLike('1234567890x', redosPattern), isTrue);
      expect(matchLike('123456789x', redosPattern), isFalse); // only 9 chars before x, needs 10
      expect(matchLike('foo___bar', 'foo___bar'), isTrue);
      expect(matchLike('foobar', 'foo%bar'), isTrue);
      expect(matchLike('fooXXbar', 'foo%_%bar'), isTrue);
    });
  });
}
