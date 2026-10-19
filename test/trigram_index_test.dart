import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';

void main() {
  group('Trigram Index Core Structure', () {
    test('extractTrigrams generates valid 3-gram sets', () {
      final trigrams = TrigramIndex.extractTrigrams('test');
      // '  test ' -> '  t', ' te', 'tes', 'est', 'st '
      expect(trigrams.contains('tes'), isTrue);
      expect(trigrams.contains('est'), isTrue);
      expect(trigrams.length, 5);
    });

    test('extractQueryTrigrams extracts substring n-grams from wildcards', () {
      final queryTrigrams = TrigramIndex.extractQueryTrigrams('%ultsql%');
      expect(queryTrigrams.contains('ult'), isTrue);
      expect(queryTrigrams.contains('lts'), isTrue);
      expect(queryTrigrams.contains('tsq'), isTrue);
      expect(queryTrigrams.contains('sql'), isTrue);
    });

    test('standalone TrigramIndex inserts and retrieves posting lists', () {
      final index = TrigramIndex(indexPath: ':memory:');
      index.addDocumentSync('alice@example.com', 0, 1);
      index.addDocumentSync('support@ultsql.tech', 0, 2);
      index.addDocumentSync('developer@ultsql.tech', 0, 3);

      final ultsqlMatches = index.searchSync('%ultsql%');
      expect(ultsqlMatches, isNotNull);
      expect(ultsqlMatches!.length, 2);
      expect(ultsqlMatches.any((p) => p.slotId == 2), isTrue);
      expect(ultsqlMatches.any((p) => p.slotId == 3), isTrue);
      expect(ultsqlMatches.any((p) => p.slotId == 1), isFalse);

      final exampleMatches = index.searchSync('%example%');
      expect(exampleMatches, isNotNull);
      expect(exampleMatches!.length, 1);
      expect(exampleMatches.first.slotId, 1);
    });
  });

  group('Trigram Index SQL Integration', () {
    test('CREATE INDEX USING TRIGRAM accelerates LIKE queries', () async {
      final db = Database(':memory:');
      await db.init();
      final interp = Interpreter(db);

      await interp.executeScript('''
        CREATE TABLE contacts (id INT, name TEXT, email TEXT);
        INSERT INTO contacts VALUES (1, 'Alice Smith', 'alice@company.org');
        INSERT INTO contacts VALUES (2, 'Bob Jones', 'bob@ultsql.tech');
        INSERT INTO contacts VALUES (3, 'Charlie Brown', 'charlie@gmail.com');
        CREATE INDEX idx_contacts_email ON contacts(email) USING TRIGRAM;
      ''');

      // 1. Verify EXPLAIN displays TrigramScanNode
      final explainRes = await interp.executeScript(
        "EXPLAIN SELECT * FROM contacts WHERE email LIKE '%ultsql%';",
      );
      final planStr = explainRes.rows.map((r) => r.join(' ')).join('\n');
      expect(planStr.contains('TrigramScanNode'), isTrue);

      // 2. Verify query output matches correct row
      final res1 = await interp.executeScript(
        "SELECT id, name FROM contacts WHERE email LIKE '%ultsql%';",
      );
      expect(res1.rows.length, 1);
      expect(res1.rows[0][0].toString(), '2');
      expect(res1.rows[0][1].toString(), 'Bob Jones');

      // 3. Verify inserting new row updates the trigram index
      await interp.executeScript(
        "INSERT INTO contacts VALUES (4, 'Dave Developer', 'dave@ultsql.tech');",
      );
      final res2 = await interp.executeScript(
        "SELECT id, name FROM contacts WHERE email LIKE '%ultsql%';",
      );
      expect(res2.rows.length, 2);
      final ids = res2.rows.map((r) => r[0].toString()).toList();
      expect(ids, containsAll(['2', '4']));

      await db.close();
    });
  });
}
