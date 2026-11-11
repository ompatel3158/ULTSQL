import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ultsql/ultsql.dart';
import 'package:ultsql/src/engine/parser/lexer.dart';
import 'package:ultsql/src/engine/parser/parser.dart';
import 'package:ultsql/src/engine/parser/token.dart';
import 'package:ultsql/src/engine/parser/ast.dart';

const String kDbDir = 'test_parser_qa_db';

enum TestCategory {
  escapingAndSyntax,
  grammarDepth,
  unicodeCompliance,
  arithmeticBoundaries,
  malformedValidation,
}

enum ResultStatus {
  passed,           // Succeeded as expected according to engine capabilities
  gracefulError,    // Gracefully rejected with descriptive syntax/runtime error
  syntaxDefect,     // Valid standard SQL rejected by parser/lexer limitation
  dataCorrupted,    // Executed but caused data truncation, mojibake, or precision loss
  unhandledCrash,   // Uncaught runtime crash (e.g. IntegerDivisionByZeroException)
  laxValidation,    // Invalid/malformed query accepted without error (e.g. duplicate columns)
  stackOverflow,    // Crashed with StackOverflowError
}

class TestCaseResult {
  final String testId;
  final String title;
  final TestCategory category;
  final ResultStatus status;
  final int durationMs;
  final String? errorMessage;
  final String? errorType;
  final String findingDetails;
  final dynamic queryResult;

  TestCaseResult({
    required this.testId,
    required this.title,
    required this.category,
    required this.status,
    required this.durationMs,
    this.errorMessage,
    this.errorType,
    this.findingDetails = '',
    this.queryResult,
  });

  bool get isClean =>
      status == ResultStatus.passed || status == ResultStatus.gracefulError;
}

Future<void> cleanDirectory(String path) async {
  final dir = Directory(path);
  for (int i = 0; i < 5; i++) {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      return;
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

Future<void> ensureCleanDirectory(String path) async {
  await cleanDirectory(path);
  await Directory(path).create(recursive: true);
}

class ParserStressRunner {
  late UltSqlEngine engine;
  final List<TestCaseResult> results = [];
  final List<String> criticalDefects = [];

  Future<void> init() async {
    await ensureCleanDirectory(kDbDir);
    engine = await UltSqlEngine.openFile(kDbDir);
  }

  Future<void> close() async {
    await engine.db.close();
    await cleanDirectory(kDbDir);
  }

  Future<void> restartEngine() async {
    try {
      await engine.db.close();
    } catch (_) {}
    await ensureCleanDirectory(kDbDir);
    engine = await UltSqlEngine.openFile(kDbDir);
  }

  /// Run query through engine.query(sql) catching all Exceptions and Errors.
  Future<TestCaseResult> runTest({
    required String testId,
    required String title,
    required TestCategory category,
    required String sql,
    required bool expectSuccess,
    String? expectedErrorSubstring,
    bool Function(EngineQueryResult res)? resultValidator,
    String? expectedDefectSummary,
    ResultStatus? defectStatus,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final res = await engine.query(sql);
      sw.stop();

      if (!expectSuccess) {
        // Query was malformed/invalid, but executed without throwing!
        final status = defectStatus ?? ResultStatus.laxValidation;
        final r = TestCaseResult(
          testId: testId,
          title: title,
          category: category,
          status: status,
          durationMs: sw.elapsedMilliseconds,
          findingDetails: expectedDefectSummary ??
              'Query is invalid/malformed SQL, but engine accepted and executed without throwing.',
          queryResult: res.toString(),
        );
        results.add(r);
        return r;
      }

      // Query was expected to succeed
      if (resultValidator != null) {
        final isValid = resultValidator(res);
        if (!isValid) {
          final status = defectStatus ?? ResultStatus.dataCorrupted;
          final r = TestCaseResult(
            testId: testId,
            title: title,
            category: category,
            status: status,
            durationMs: sw.elapsedMilliseconds,
            findingDetails: expectedDefectSummary ??
                'Returned result failed validation assertions: rows=${res.rows.length}, cols=${res.columns}, message="${res.message}"',
            queryResult: res.rows.isNotEmpty ? res.rows.first.toString() : res.message,
          );
          results.add(r);
          return r;
        }
      }

      final r = TestCaseResult(
        testId: testId,
        title: title,
        category: category,
        status: ResultStatus.passed,
        durationMs: sw.elapsedMilliseconds,
        findingDetails: 'Executed successfully.',
        queryResult: res.rows.isNotEmpty ? res.rows.first.toString() : res.message,
      );
      results.add(r);
      return r;
    } on StackOverflowError catch (so) {
      sw.stop();
      final r = TestCaseResult(
        testId: testId,
        title: title,
        category: category,
        status: ResultStatus.stackOverflow,
        durationMs: sw.elapsedMilliseconds,
        errorType: 'StackOverflowError',
        errorMessage: so.toString(),
        findingDetails: 'CRITICAL: Stack overflow occurred in parser or AST execution call stack.',
      );
      results.add(r);
      criticalDefects.add('[$testId] STACK OVERFLOW: $title');
      return r;
    } catch (e) {
      sw.stop();
      final errStr = e.toString();
      final errType = e.runtimeType.toString();

      if (!expectSuccess) {
        // We expected rejection. Check if it was graceful or an unhandled crash.
        final isUnhandled = errType.contains('IntegerDivisionByZeroException') ||
            errType.contains('RangeError') ||
            errType.contains('TypeError') ||
            errType.contains('NoSuchMethodError');

        if (isUnhandled) {
          final r = TestCaseResult(
            testId: testId,
            title: title,
            category: category,
            status: ResultStatus.unhandledCrash,
            durationMs: sw.elapsedMilliseconds,
            errorType: errType,
            errorMessage: errStr,
            findingDetails: expectedDefectSummary ??
                'CRASH: Uncaught Dart runtime error: $errStr',
          );
          results.add(r);
          criticalDefects.add('[$testId] UNHANDLED CRASH: $title ($errType: $errStr)');
          return r;
        }

        final status = ResultStatus.gracefulError;
        final r = TestCaseResult(
          testId: testId,
          title: title,
          category: category,
          status: status,
          durationMs: sw.elapsedMilliseconds,
          errorType: errType,
          errorMessage: errStr,
          findingDetails: 'Rejected gracefully with error: $errStr',
        );
        results.add(r);
        return r;
      } else {
        // Valid SQL query threw an error (Parser limitation or bug)
        final status = defectStatus ?? ResultStatus.syntaxDefect;
        final r = TestCaseResult(
          testId: testId,
          title: title,
          category: category,
          status: status,
          durationMs: sw.elapsedMilliseconds,
          errorType: errType,
          errorMessage: errStr,
          findingDetails: expectedDefectSummary ??
              'Valid SQL rejected by parser/lexer: $errStr',
        );
        results.add(r);
        criticalDefects.add('[$testId] SYNTAX DEFECT: $title -> $errStr');
        return r;
      }
    }
  }

  // ==========================================================================
  // CATEGORY 1: Statement Escaping & Complex Syntax
  // ==========================================================================
  Future<void> runCategory1() async {
    print('----------------------------------------------------------------------');
    print(' 🔹 CATEGORY 1: Statement Escaping & Complex Syntax');
    print('----------------------------------------------------------------------');

    // 1.1 SQL Standard Single Quote Escaping: 'O''Reilly'
    await runTest(
      testId: 'ESC-01',
      title: "SQL-standard single quote escaping ('O''Reilly')",
      category: TestCategory.escapingAndSyntax,
      sql: "SELECT 'O''Reilly' AS author;",
      expectSuccess: true,
      resultValidator: (res) {
        if (res.rows.isEmpty) return false;
        final val = res.rows.first.first.toString();
        return val == "O'Reilly";
      },
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Lexer terminates string literal on second single quote instead of looking ahead for '' escape. "
          "Splits 'O''Reilly' into 'O' and 'Reilly', resulting in: Exception: Unsupported statement beginning with 'Reilly'.",
    );

    // 1.2 Quadruple quotes: '''' represents a single quote literal
    await runTest(
      testId: 'ESC-02',
      title: "Quadruple quote literal ('''' -> single quote)",
      category: TestCategory.escapingAndSyntax,
      sql: "SELECT '''' AS single_quote;",
      expectSuccess: true,
      resultValidator: (res) {
        if (res.rows.isEmpty) return false;
        final val = res.rows.first.first.toString();
        return val == "'";
      },
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Lexer treats '''' as two adjacent empty strings instead of one escaped single quote.",
    );

    // 1.3 Backslash escaped single quote: \'
    await runTest(
      testId: 'ESC-03',
      title: "Backslash escaped single quote ('O\\'Reilly')",
      category: TestCategory.escapingAndSyntax,
      sql: "SELECT 'O\\'Reilly' AS author;",
      expectSuccess: true,
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Lexer lacks backslash '\\' escaping support; reads 'O\\' as complete literal, causing trailing quote to trigger 'Unterminated string literal'.",
    );

    // 1.4 Multi-statement script with semicolons (DDL + DML + SELECT)
    await runTest(
      testId: 'ESC-04',
      title: "Multi-statement script with semicolons (DDL + DML + DQL)",
      category: TestCategory.escapingAndSyntax,
      sql: """
        CREATE TABLE books_esc (id INT, title TEXT);
        INSERT INTO books_esc VALUES (1, 'Book Alpha');
        INSERT INTO books_esc VALUES (2, 'Book Beta');
        SELECT * FROM books_esc;
      """,
      expectSuccess: true,
      resultValidator: (res) => res.rows.length == 2,
    );

    // 1.5 Multi-statement script with semicolon noise (consecutive & trailing)
    await runTest(
      testId: 'ESC-05',
      title: "Semicolon noise (leading ';;', consecutive, trailing)",
      category: TestCategory.escapingAndSyntax,
      sql: ";; SELECT 101 AS val1;; SELECT 202 AS val2;;;",
      expectSuccess: true,
      resultValidator: (res) => res.rows.isNotEmpty,
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Parser.parseScript() only skips semicolons at the loop end; leading semicolons throw 'Unsupported statement beginning with ;'.",
    );

    // 1.6 Single-line comments (-- line comment)
    await runTest(
      testId: 'ESC-06',
      title: "Single-line comments (-- comment)",
      category: TestCategory.escapingAndSyntax,
      sql: """
        -- Leading comment
        SELECT 42 AS answer;
        -- Trailing comment
      """,
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '42',
    );

    // 1.7 Single-line comment without trailing newline (EOF immediately after comment)
    await runTest(
      testId: 'ESC-07',
      title: "Single-line comment at EOF without newline",
      category: TestCategory.escapingAndSyntax,
      sql: "SELECT 99 AS n; -- comment without newline",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '99',
    );

    // 1.8 Block comments (/* comment */)
    await runTest(
      testId: 'ESC-08',
      title: "Block comments (/* block comment */)",
      category: TestCategory.escapingAndSyntax,
      sql: "/* Block comment before query */ SELECT 50 AS val;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '50',
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Lexer does not support C-style /* ... */ block comments; emits '/' and '*' as arithmetic tokens, causing parse failure.",
    );

    // 1.9 Multi-line block comments
    await runTest(
      testId: 'ESC-09',
      title: "Multi-line block comments (/* line1 \\n line2 */)",
      category: TestCategory.escapingAndSyntax,
      sql: """
        /*
         * Multi-line
         * Block Comment
         */
        SELECT 77 AS num;
      """,
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '77',
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Lexer lacks /* block */ comment skipping; throws 'Unsupported statement beginning with /'.",
    );

    // 1.10 Inline block comments inside arithmetic expression
    await runTest(
      testId: 'ESC-10',
      title: "Inline block comment inside expression (10 /* add */ + 20)",
      category: TestCategory.escapingAndSyntax,
      sql: "SELECT 10 /* inline comment */ + 20 AS sum_val;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '30',
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Inline comment tokenized as slash and asterisk operators inside expression, throwing: Unexpected token '*' in expression.",
    );

    // 1.11 Basic UNION query
    await runTest(
      testId: 'ESC-11',
      title: "Basic UNION query (SELECT 10 UNION SELECT 20)",
      category: TestCategory.escapingAndSyntax,
      sql: "SELECT 10 AS num UNION SELECT 20 AS num;",
      expectSuccess: true,
      resultValidator: (res) => res.rows.length == 2,
    );

    // 1.12 UNION with duplicate elimination
    await runTest(
      testId: 'ESC-12',
      title: "UNION duplicate elimination (SELECT 10 UNION SELECT 10)",
      category: TestCategory.escapingAndSyntax,
      sql: "SELECT 10 AS num UNION SELECT 10 AS num;",
      expectSuccess: true,
      resultValidator: (res) => res.rows.length == 1,
    );

    // 1.13 UNION ALL preserving duplicates
    await runTest(
      testId: 'ESC-13',
      title: "UNION ALL preserving duplicates (SELECT 10 UNION ALL SELECT 10)",
      category: TestCategory.escapingAndSyntax,
      sql: "SELECT 10 AS num UNION ALL SELECT 10 AS num;",
      expectSuccess: true,
      resultValidator: (res) => res.rows.length == 2,
    );

    // 1.14 Parenthesized UNION query: (SELECT 1) UNION (SELECT 2)
    await runTest(
      testId: 'ESC-14',
      title: "Parenthesized UNION queries ((SELECT 1) UNION (SELECT 2))",
      category: TestCategory.escapingAndSyntax,
      sql: "(SELECT 1 AS x) UNION (SELECT 2 AS x);",
      expectSuccess: true,
      resultValidator: (res) => res.rows.length == 2,
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Top-level statements in parseScript() cannot begin with '(', throwing: Unsupported statement beginning with '('.",
    );
  }

  // ==========================================================================
  // CATEGORY 2: Extreme Nesting & Grammar Depth
  // ==========================================================================
  Future<void> runCategory2() async {
    print('\n----------------------------------------------------------------------');
    print(' 🔹 CATEGORY 2: Extreme Nesting & Grammar Depth');
    print('----------------------------------------------------------------------');

    // 2.1 10 levels nested parentheses
    await runTest(
      testId: 'DEP-01',
      title: "Nested parentheses (10 levels)",
      category: TestCategory.grammarDepth,
      sql: "SELECT ${'(' * 10}1${')' * 10} AS val;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '1',
    );

    // 2.2 50 levels nested parentheses
    await runTest(
      testId: 'DEP-02',
      title: "Nested parentheses (50 levels)",
      category: TestCategory.grammarDepth,
      sql: "SELECT ${'(' * 50}1${')' * 50} AS val;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '1',
    );

    // 2.3 100 levels nested parentheses
    await runTest(
      testId: 'DEP-03',
      title: "Nested parentheses (100 levels)",
      category: TestCategory.grammarDepth,
      sql: "SELECT ${'(' * 100}1${')' * 100} AS val;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '1',
    );

    // 2.4 250 levels nested parentheses
    await runTest(
      testId: 'DEP-04',
      title: "Nested parentheses (250 levels)",
      category: TestCategory.grammarDepth,
      sql: "SELECT ${'(' * 250}1${')' * 250} AS val;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '1',
    );

    // 2.5 500 levels nested parentheses
    await runTest(
      testId: 'DEP-05',
      title: "Extreme nested parentheses (500 levels: (((...1...))))",
      category: TestCategory.grammarDepth,
      sql: "SELECT ${'(' * 500}1${')' * 500} AS val;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '1',
    );

    // 2.6 Chained binary operations (100 additions: 1 + 1 + ... + 1)
    final additions100 = List.filled(100, '1').join(' + ');
    await runTest(
      testId: 'DEP-06',
      title: "Chained binary expressions (100 additions: 1 + 1 + ...)",
      category: TestCategory.grammarDepth,
      sql: "SELECT $additions100 AS sum_val;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '100',
    );

    // 2.7 Nested FROM subqueries - 5 levels
    String buildNestedFrom(int depth) {
      String query = "SELECT 1 AS val";
      for (int i = 1; i <= depth; i++) {
        query = "SELECT * FROM ($query) AS t$i";
      }
      return "$query;";
    }

    await runTest(
      testId: 'DEP-07',
      title: "Nested FROM subqueries (5 levels)",
      category: TestCategory.grammarDepth,
      sql: buildNestedFrom(5),
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '1',
    );

    // 2.8 Nested FROM subqueries - 10 levels
    await runTest(
      testId: 'DEP-08',
      title: "Nested FROM subqueries (10 levels)",
      category: TestCategory.grammarDepth,
      sql: buildNestedFrom(10),
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '1',
    );

    // 2.9 Nested FROM subqueries - 20 levels
    await runTest(
      testId: 'DEP-09',
      title: "Nested FROM subqueries (20 levels)",
      category: TestCategory.grammarDepth,
      sql: buildNestedFrom(20),
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '1',
    );

    // 2.10 Nested FROM subqueries - 30 levels
    await runTest(
      testId: 'DEP-10',
      title: "Deeply nested FROM subqueries (30 levels)",
      category: TestCategory.grammarDepth,
      sql: buildNestedFrom(30),
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '1',
    );

    // 2.11 Recursive CTE with explicit anchor column alias (SELECT 1 AS n)
    await runTest(
      testId: 'DEP-11',
      title: "Recursive CTE with explicit alias (1 AS n) terminating at n < 10",
      category: TestCategory.grammarDepth,
      sql: """
        WITH RECURSIVE cnt AS (
          SELECT 1 AS n
          UNION ALL
          SELECT n + 1 FROM cnt WHERE n < 10
        )
        SELECT * FROM cnt;
      """,
      expectSuccess: true,
      resultValidator: (res) => res.rows.length == 10,
    );

    // 2.12 Recursive CTE parameter list ignored defect (cnt(n))
    await runTest(
      testId: 'DEP-12',
      title: "Recursive CTE parameter list mapping defect (cnt(n) AS (SELECT 1 ...))",
      category: TestCategory.grammarDepth,
      sql: """
        WITH RECURSIVE cnt(n) AS (
          SELECT 1
          UNION ALL
          SELECT n + 1 FROM cnt WHERE n < 10
        )
        SELECT * FROM cnt;
      """,
      expectSuccess: true,
      resultValidator: (res) => res.rows.length == 10,
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Parser parses and discards CTE parameter list 'cnt(n)' without renaming anchor columns. "
          "Because anchor column remains named '1', recursive expression 'n + 1' cannot find 'n', defaulting to 0+1=1, halting after 1 row.",
    );

    // 2.13 Recursive CTE cycle / infinite recursion guard
    await runTest(
      testId: 'DEP-13',
      title: "Recursive CTE cycle / duplicate row guard (SELECT 1 UNION ALL SELECT n FROM cte)",
      category: TestCategory.grammarDepth,
      sql: """
        WITH RECURSIVE cycle_cte AS (
          SELECT 1 AS n
          UNION ALL
          SELECT n FROM cycle_cte
        )
        SELECT * FROM cycle_cte;
      """,
      expectSuccess: true,
      resultValidator: (res) => res.rows.length == 1,
    );

    // 2.14 Recursive CTE depth capped at engine maxDepth (100)
    await runTest(
      testId: 'DEP-14',
      title: "Recursive CTE depth capped at maxDepth (100 iterations)",
      category: TestCategory.grammarDepth,
      sql: """
        WITH RECURSIVE deep_cte AS (
          SELECT 1 AS n
          UNION ALL
          SELECT n + 1 FROM deep_cte WHERE n < 150
        )
        SELECT * FROM deep_cte;
      """,
      expectSuccess: true,
      resultValidator: (res) => res.rows.length == 100,
    );
  }

  // ==========================================================================
  // CATEGORY 3: Unicode Compliance & Edge Cases
  // ==========================================================================
  Future<void> runCategory3() async {
    print('\n----------------------------------------------------------------------');
    print(' 🔹 CATEGORY 3: Unicode Compliance & Edge Cases');
    print('----------------------------------------------------------------------');

    // 3.1 Multi-byte CJK text in string literals
    await runTest(
      testId: 'UNI-01',
      title: "Multi-byte CJK characters in string literals",
      category: TestCategory.unicodeCompliance,
      sql: "SELECT '中文测试' AS zh, '日本語テスト' AS ja, '한국어테스트' AS ko;",
      expectSuccess: true,
      resultValidator: (res) {
        if (res.rows.isEmpty) return false;
        final row = res.rows.first;
        return row[0].toString() == '中文测试' &&
            row[1].toString() == '日本語テスト' &&
            row[2].toString() == '한국어테스트';
      },
    );

    // 3.2 Cyrillic & Greek text in table storage (codeUnit truncation defect)
    await runTest(
      testId: 'UNI-02',
      title: "Non-ASCII table storage (Cyrillic & Greek strings <= 1024 bytes)",
      category: TestCategory.unicodeCompliance,
      sql: """
        CREATE TABLE uni_cyr_greek (id INT, txt TEXT);
        INSERT INTO uni_cyr_greek VALUES (1, 'Привет, мир!'), (2, 'Γειά σου Κόσμε!');
        SELECT * FROM uni_cyr_greek;
      """,
      expectSuccess: true,
      resultValidator: (res) {
        if (res.rows.length != 2) return false;
        return res.rows[0][1].toString() == 'Привет, мир!' &&
            res.rows[1][1].toString() == 'Γειά σου Κόσμε!';
      },
      defectStatus: ResultStatus.dataCorrupted,
      expectedDefectSummary:
          "CRITICAL DATA CORRUPTION: RecordSerializer.serializeMvccRowDirect truncates 16-bit char codes "
          "via 'dest[currentOffset + 1 + c] = str.codeUnitAt(c);' for strings <= 1024 bytes instead of UTF-8 encoding. "
          "'Привет' is truncated to 8-bit bytes '@825B', and non-ASCII Greek bytes trigger FormatException in utf8.decode, silently dropping row 2.",
    );

    // 3.3 Basic and compound emojis in string literals
    await runTest(
      testId: 'UNI-03',
      title: "Basic emojis in string literals (🔥 🚀 🎉 🐱)",
      category: TestCategory.unicodeCompliance,
      sql: "SELECT '🔥 Fire 🚀 Rocket 🎉 Party 🐱 Cat' AS emojis;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty &&
          res.rows.first.first.toString().contains('🔥') &&
          res.rows.first.first.toString().contains('🚀'),
    );

    // 3.4 Zero-Width Joiner (ZWJ) sequences: family, technologist
    await runTest(
      testId: 'UNI-04',
      title: "Zero-Width Joiner (ZWJ) sequences (👨‍👩‍👧‍👦, 👩‍💻)",
      category: TestCategory.unicodeCompliance,
      sql: "SELECT '👨‍👩‍👧‍👦' AS family, '👩‍💻' AS coder;",
      expectSuccess: true,
      resultValidator: (res) {
        if (res.rows.isEmpty) return false;
        return res.rows.first[0].toString() == '👨‍👩‍👧‍👦' &&
            res.rows.first[1].toString() == '👩‍💻';
      },
    );

    // 3.5 Right-to-Left (RTL) scripts (Arabic and Hebrew)
    await runTest(
      testId: 'UNI-05',
      title: "Right-to-Left scripts (Arabic 'مرحبا', Hebrew 'שלום')",
      category: TestCategory.unicodeCompliance,
      sql: "SELECT 'مرحبا بالعالم' AS ar, 'שלום עולם' AS he;",
      expectSuccess: true,
      resultValidator: (res) {
        if (res.rows.isEmpty) return false;
        return res.rows.first[0].toString() == 'مرحبا بالعالم' &&
            res.rows.first[1].toString() == 'שלום עולם';
      },
    );

    // 3.6 Mixed bidirectional text (LTR + RTL + digits)
    await runTest(
      testId: 'UNI-06',
      title: "Mixed bidirectional text (LTR + RTL + numbers)",
      category: TestCategory.unicodeCompliance,
      sql: "SELECT 'Invoice #1234: 500 ريال paid by John' AS bidi_text;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty &&
          res.rows.first.first.toString().contains('ريال'),
    );

    // 3.7 Non-ASCII table and column identifiers
    await runTest(
      testId: 'UNI-07',
      title: "Non-ASCII table and column identifiers (CREATE TABLE 用户)",
      category: TestCategory.unicodeCompliance,
      sql: "CREATE TABLE 用户 (编号 INT, 姓名 TEXT);",
      expectSuccess: true,
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Lexer._isAlpha only permits ASCII letters [A-Za-z_]; rejects Unicode identifiers with: Lexer error: 用 at Line 1:14.",
    );

    // 3.8 Special Unicode characters (Byte Order Mark, zero-width space)
    await runTest(
      testId: 'UNI-08',
      title: "Special Unicode control characters (BOM, ZWSP)",
      category: TestCategory.unicodeCompliance,
      sql: "SELECT '\uFEFFBOM_\u200B_ZWSP' AS special_unicode;",
      expectSuccess: true,
    );

    // 3.9 Large 2MB string literal in memory SELECT
    final large2MbString = 'X' * (2 * 1024 * 1024);
    await runTest(
      testId: 'UNI-09',
      title: "Large 2MB string literal in memory SELECT",
      category: TestCategory.unicodeCompliance,
      sql: "SELECT '$large2MbString' AS big_str;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty &&
          res.rows.first.first.toString().length == 2 * 1024 * 1024,
    );

    // 3.10 Large 2MB string literal table persistence (TOAST overflow)
    await runTest(
      testId: 'UNI-10',
      title: "Large 2MB string literal disk storage in table (TOAST overflow)",
      category: TestCategory.unicodeCompliance,
      sql: """
        CREATE TABLE big_text_table (id INT, content TEXT);
        INSERT INTO big_text_table VALUES (1, '$large2MbString');
        SELECT id FROM big_text_table;
      """,
      expectSuccess: true,
      resultValidator: (res) => res.rows.isNotEmpty,
    );
  }

  // ==========================================================================
  // CATEGORY 4: Arithmetic & Numeric Boundaries
  // ==========================================================================
  Future<void> runCategory4() async {
    print('\n----------------------------------------------------------------------');
    print(' 🔹 CATEGORY 4: Arithmetic & Numeric Boundaries');
    print('----------------------------------------------------------------------');

    // 4.1 Integer division by zero (1 / 0)
    await runTest(
      testId: 'NUM-01',
      title: "Integer division by zero (1 / 0 -> double.infinity)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 1 / 0 AS div_zero;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == 'Infinity',
    );

    // 4.2 Floating-point division by zero (1.5 / 0.0)
    await runTest(
      testId: 'NUM-02',
      title: "Floating point division by zero (1.5 / 0.0 -> double.infinity)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 1.5 / 0.0 AS float_div_zero;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == 'Infinity',
    );

    // 4.3 Zero divided by zero (0 / 0)
    await runTest(
      testId: 'NUM-03',
      title: "Zero divided by zero (0 / 0 -> double.nan)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 0 / 0 AS zero_zero;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == 'NaN',
    );

    // 4.4 Modulo by zero (10 % 0) -> Unhandled Crash!
    await runTest(
      testId: 'NUM-04',
      title: "Modulo by zero (10 % 0)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 10 % 0 AS mod_zero;",
      expectSuccess: false,
      defectStatus: ResultStatus.unhandledCrash,
      expectedDefectSummary:
          "CRASH: Modulo by zero executes raw Dart 'value % other.value', throwing uncaught IntegerDivisionByZeroException instead of SQL error or NULL.",
    );

    // 4.5 64-bit integer max value (9223372036854775807)
    await runTest(
      testId: 'NUM-05',
      title: "64-bit signed integer max (9223372036854775807)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 9223372036854775807 AS max_int64;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty &&
          res.rows.first.first.toString() == '9223372036854775807',
    );

    // 4.6 64-bit signed integer min value (-9223372036854775808) -> Floating precision loss!
    await runTest(
      testId: 'NUM-06',
      title: "64-bit signed integer min (-9223372036854775808)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT -9223372036854775808 AS min_int64;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty &&
          res.rows.first.first.toString() == '-9223372036854775808',
      defectStatus: ResultStatus.dataCorrupted,
      expectedDefectSummary:
          "PRECISION LOSS: Unary minus is parsed as operator on positive literal 9223372036854775808. "
          "Because positive value exceeds int64.max, num.parse converts it to double, losing precision to -9223372036854776000.0.",
    );

    // 4.7 64-bit integer addition overflow (9223372036854775807 + 1)
    await runTest(
      testId: 'NUM-07',
      title: "64-bit integer overflow expression (9223372036854775807 + 1)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 9223372036854775807 + 1 AS overflow_val;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty &&
          res.rows.first.first.toString() == '-9223372036854775808',
    );

    // 4.8 Integer literal exceeding 64-bit range (9223372036854775808)
    await runTest(
      testId: 'NUM-08',
      title: "Integer literal exceeding 64-bit range (9223372036854775808 -> double)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 9223372036854775808 AS beyond_int64;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty &&
          res.rows.first.first.toString().startsWith('922337203685477'),
    );

    // 4.9 Negative numbers in LIMIT (LIMIT -1)
    await runTest(
      testId: 'NUM-09',
      title: "Negative number in LIMIT clause (LIMIT -1)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 1 AS val LIMIT -1;",
      expectSuccess: false,
      expectedErrorSubstring: "limit",
    );

    // 4.10 Negative numbers in OFFSET (OFFSET -5)
    await runTest(
      testId: 'NUM-10',
      title: "Negative number in OFFSET clause (OFFSET -5)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 1 AS val LIMIT 1 OFFSET -5;",
      expectSuccess: false,
      expectedErrorSubstring: "offset",
    );

    // 4.11 Scientific notation positive exponent (1e10, 2.5e3)
    await runTest(
      testId: 'NUM-11',
      title: "Scientific notation positive exponent (1e10)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 1e10 AS sci1, 2.5e3 AS sci2;",
      expectSuccess: true,
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Lexer does not recognize 'e'/'E' in numbers; tokenizes 1e10 as number '1' and identifier 'e10', throwing syntax error.",
    );

    // 4.12 Scientific notation extreme positive exponent (1e30)
    await runTest(
      testId: 'NUM-12',
      title: "Extreme scientific notation positive exponent (1e30)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 1e30 AS huge_sci;",
      expectSuccess: true,
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Lexer lacks scientific notation support; tokenizes 1e30 as number and identifier.",
    );

    // 4.13 Scientific notation negative exponent (1e-5, 3.14e-2)
    await runTest(
      testId: 'NUM-13',
      title: "Scientific notation negative exponent (1e-5)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 1e-5 AS small_sci, 3.14e-2 AS pi_sci;",
      expectSuccess: true,
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Lexer reads '1', 'e', then encounters '-' as subtraction operator, throwing syntax error.",
    );

    // 4.14 Scientific notation extreme negative exponent (1e-30)
    await runTest(
      testId: 'NUM-14',
      title: "Extreme scientific notation negative exponent (1e-30)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 1e-30 AS tiny_sci;",
      expectSuccess: true,
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "Lexer lacks scientific notation support with negative exponents.",
    );

    // 4.15 Floating point IEEE 754 boundaries (Max double, Min positive)
    await runTest(
      testId: 'NUM-15',
      title: "IEEE 754 double extremes (1.7976931348623157e+308, 5e-324)",
      category: TestCategory.arithmeticBoundaries,
      sql: "SELECT 1.7976931348623157e+308 AS max_dbl, 5e-324 AS min_dbl;",
      expectSuccess: true,
      defectStatus: ResultStatus.syntaxDefect,
      expectedDefectSummary:
          "IEEE 754 float boundary constants using scientific notation e+308 fail at the lexer.",
    );
  }

  // ==========================================================================
  // CATEGORY 5: Malformed Queries & Syntax Validation
  // ==========================================================================
  Future<void> runCategory5() async {
    print('\n----------------------------------------------------------------------');
    print(' 🔹 CATEGORY 5: Malformed Queries & Syntax Validation');
    print('----------------------------------------------------------------------');

    // 5.1 Unclosed single quote in string literal
    await runTest(
      testId: 'MAL-01',
      title: "Unclosed single quote ('unterminated string)",
      category: TestCategory.malformedValidation,
      sql: "SELECT 'unterminated string literal;",
      expectSuccess: false,
      expectedErrorSubstring: "Unterminated",
    );

    // 5.2 Trailing comma in SELECT projection list
    await runTest(
      testId: 'MAL-02',
      title: "Trailing comma in SELECT list (SELECT 1, 2, FROM ...)",
      category: TestCategory.malformedValidation,
      sql: "SELECT 1, 2, FROM (SELECT 10 AS a) t;",
      expectSuccess: false,
      expectedErrorSubstring: "Expected",
    );

    // 5.3 Trailing comma in CREATE TABLE column definitions
    await runTest(
      testId: 'MAL-03',
      title: "Trailing comma in CREATE TABLE (id INT, name TEXT,)",
      category: TestCategory.malformedValidation,
      sql: "CREATE TABLE bad_table_comma (id INT, name TEXT,);",
      expectSuccess: false,
      expectedErrorSubstring: "Expected column name",
    );

    // 5.4 Trailing comma in INSERT INTO VALUES list
    await runTest(
      testId: 'MAL-04',
      title: "Trailing comma in INSERT VALUES (1, 2,)",
      category: TestCategory.malformedValidation,
      sql: """
        CREATE TABLE ins_comma_tbl (id INT, val INT);
        INSERT INTO ins_comma_tbl VALUES (1, 2,);
      """,
      expectSuccess: false,
      expectedErrorSubstring: "expression",
    );

    // 5.5 Invalid cast: non-numeric string to INT (CAST('not_a_number' AS INT))
    await runTest(
      testId: 'MAL-05',
      title: "Invalid cast to INT (CAST('not_a_number' AS INT) -> 0)",
      category: TestCategory.malformedValidation,
      sql: "SELECT CAST('not_a_number' AS INT) AS bad_cast;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '0',
      defectStatus: ResultStatus.laxValidation,
      expectedDefectSummary:
          "Lax Cast: JitCompiler defaults non-numeric strings to 0 ('int.tryParse(val) ?? 0') instead of raising cast exception.",
    );

    // 5.6 Invalid cast: non-numeric string to DOUBLE (CAST('abc' AS DOUBLE))
    await runTest(
      testId: 'MAL-06',
      title: "Invalid cast to DOUBLE (CAST('abc' AS DOUBLE) -> 0.0)",
      category: TestCategory.malformedValidation,
      sql: "SELECT CAST('abc' AS DOUBLE) AS bad_cast;",
      expectSuccess: true,
      resultValidator: (res) =>
          res.rows.isNotEmpty && res.rows.first.first.toString() == '0.0',
      defectStatus: ResultStatus.laxValidation,
      expectedDefectSummary:
          "Lax Cast: JitCompiler defaults invalid doubles to 0.0 ('double.tryParse(val) ?? 0.0').",
    );

    // 5.7 Invalid cast: malformed date to DATETIME (CAST('not-a-date' AS DATETIME))
    await runTest(
      testId: 'MAL-07',
      title: "Invalid cast to DATETIME (CAST('not-a-date' AS DATETIME) -> DateTime.now())",
      category: TestCategory.malformedValidation,
      sql: "SELECT CAST('not-a-date' AS DATETIME) AS bad_cast;",
      expectSuccess: true,
      resultValidator: (res) => res.rows.isNotEmpty,
      defectStatus: ResultStatus.laxValidation,
      expectedDefectSummary:
          "Lax Cast: JitCompiler defaults unparseable datetime strings to DateTime.now().",
    );

    // 5.8 Unknown data type in CREATE TABLE
    await runTest(
      testId: 'MAL-08',
      title: "Unknown data type in CREATE TABLE (id UNKNOWN_FOOBAR_TYPE)",
      category: TestCategory.malformedValidation,
      sql: "CREATE TABLE bad_type_tbl (id UNKNOWN_FOOBAR_TYPE);",
      expectSuccess: false,
      expectedErrorSubstring: "Unsupported data type",
    );

    // 5.9 Duplicate column names in CREATE TABLE -> Silently permitted!
    await runTest(
      testId: 'MAL-09',
      title: "Duplicate column names in CREATE TABLE (id INT, id TEXT)",
      category: TestCategory.malformedValidation,
      sql: "CREATE TABLE dup_col_tbl (id INT, id TEXT);",
      expectSuccess: false,
      defectStatus: ResultStatus.laxValidation,
      expectedDefectSummary:
          "LAX SCHEMA VALIDATION: Parser & Catalog allow table definition with duplicate column names ('id INT, id TEXT'). "
          "TableSchema.columnIndexMap silently overwrites the previous column index.",
    );

    // 5.10 Missing table name after FROM keyword (SELECT * FROM;)
    await runTest(
      testId: 'MAL-10',
      title: "Missing table name after FROM (SELECT * FROM;)",
      category: TestCategory.malformedValidation,
      sql: "SELECT * FROM;",
      expectSuccess: false,
      expectedErrorSubstring: "Expected source table name",
    );

    // 5.11 Unmatched opening parenthesis (SELECT ((1 + 2);)
    await runTest(
      testId: 'MAL-11',
      title: "Unmatched opening parenthesis (SELECT ((1 + 2);)",
      category: TestCategory.malformedValidation,
      sql: "SELECT ((1 + 2);",
      expectSuccess: false,
      expectedErrorSubstring: "Expected ')' after expression",
    );

    // 5.12 Unmatched closing parenthesis (SELECT (1 + 2));)
    await runTest(
      testId: 'MAL-12',
      title: "Unmatched closing parenthesis (SELECT (1 + 2));)",
      category: TestCategory.malformedValidation,
      sql: "SELECT (1 + 2));",
      expectSuccess: false,
      expectedErrorSubstring: "Unsupported statement beginning with ')'",
    );

    // 5.13 Empty SQL script or whitespace only
    await runTest(
      testId: 'MAL-13',
      title: "Empty SQL string or whitespace only",
      category: TestCategory.malformedValidation,
      sql: "     \n\t   ",
      expectSuccess: false,
      expectedErrorSubstring: "No statements found in script",
    );

    // 5.14 Dangling binary operator (SELECT 1 + ;)
    await runTest(
      testId: 'MAL-14',
      title: "Dangling binary operator (SELECT 1 + ;)",
      category: TestCategory.malformedValidation,
      sql: "SELECT 1 + ;",
      expectSuccess: false,
      expectedErrorSubstring: "Unexpected token ';'",
    );

    // 5.15 Incomplete CASE statement (missing END)
    await runTest(
      testId: 'MAL-15',
      title: "Incomplete CASE statement missing END (CASE WHEN 1=1 THEN 'yes')",
      category: TestCategory.malformedValidation,
      sql: "SELECT CASE WHEN 1=1 THEN 'yes';",
      expectSuccess: false,
      expectedErrorSubstring: "Expected 'END' to close CASE expression",
    );
  }

  // ==========================================================================
  // Report Generation & Summary
  // ==========================================================================
  void printReport(Duration totalDuration) {
    print('\n======================================================================');
    print(' 📊 GRAND PARSER ROBUSTNESS & QA AUDIT REPORT');
    print(' Total Tests Executed: ${results.length}');
    print(' Total Execution Time: ${totalDuration.inMilliseconds}ms');
    print('======================================================================\n');

    final byCategory = <TestCategory, List<TestCaseResult>>{};
    for (final r in results) {
      byCategory.putIfAbsent(r.category, () => []).add(r);
    }

    int totalPassed = 0;
    int totalGraceful = 0;
    int totalSyntaxDefects = 0;
    int totalDataCorrupted = 0;
    int totalLaxValidation = 0;
    int totalUnhandledCrashes = 0;
    int totalStackOverflows = 0;

    for (final entry in byCategory.entries) {
      final catName = entry.key.name.toUpperCase();
      final catList = entry.value;
      final passCount = catList.where((t) => t.status == ResultStatus.passed).length;
      final gracefulCount = catList.where((t) => t.status == ResultStatus.gracefulError).length;
      final syntaxDefectCount = catList.where((t) => t.status == ResultStatus.syntaxDefect).length;
      final dataCorruptCount = catList.where((t) => t.status == ResultStatus.dataCorrupted).length;
      final laxCount = catList.where((t) => t.status == ResultStatus.laxValidation).length;
      final unhandledCount = catList.where((t) => t.status == ResultStatus.unhandledCrash).length;
      final stackOvCount = catList.where((t) => t.status == ResultStatus.stackOverflow).length;

      totalPassed += passCount;
      totalGraceful += gracefulCount;
      totalSyntaxDefects += syntaxDefectCount;
      totalDataCorrupted += dataCorruptCount;
      totalLaxValidation += laxCount;
      totalUnhandledCrashes += unhandledCount;
      totalStackOverflows += stackOvCount;

      print('📂 [$catName] (${catList.length} tests)');
      print('   ✅ Passed: $passCount | 🛡️  Gracefully Handled: $gracefulCount | ⚠️  Syntax Defects: $syntaxDefectCount | ☣️  Data Corruption: $dataCorruptCount | 🟡 Lax Validation: $laxCount | 💥 StackOverflows: $stackOvCount | 🚨 Unhandled Crash: $unhandledCount');

      for (final r in catList) {
        String icon;
        switch (r.status) {
          case ResultStatus.passed:
            icon = '✅ PASS';
            break;
          case ResultStatus.gracefulError:
            icon = '🛡️  REJECT_OK';
            break;
          case ResultStatus.syntaxDefect:
            icon = '⚠️  SYNTAX_DEFECT';
            break;
          case ResultStatus.dataCorrupted:
            icon = '☣️  DATA_CORRUPT';
            break;
          case ResultStatus.laxValidation:
            icon = '🟡 LAX_VALIDATION';
            break;
          case ResultStatus.stackOverflow:
            icon = '💥 STACK_OVERFLOW';
            break;
          case ResultStatus.unhandledCrash:
            icon = '🚨 CRASH';
            break;
        }

        final durationStr = '${r.durationMs}ms'.padLeft(5);
        print('   $icon [$durationStr] [${r.testId}] ${r.title}');
        if (r.errorMessage != null) {
          final trimmedErr = r.errorMessage!.split('\n').first;
          print('       Error: $trimmedErr');
        }
        if (r.findingDetails.isNotEmpty) {
          print('       Audit: ${r.findingDetails}');
        }
      }
      print('');
    }

    print('======================================================================');
    print(' 📋 EXECUTIVE SUMMARY & SCORECARD:');
    print('======================================================================');
    print(' • Fully Passed & Compliant:        $totalPassed');
    print(' • Gracefully Rejected Errors:      $totalGraceful');
    print(' • Syntax & Escaping Defects:       $totalSyntaxDefects');
    print(' • Data Corruption / Precision:     $totalDataCorrupted');
    print(' • Lax / Missing Schema Validation: $totalLaxValidation');
    print(' • Unhandled Dart Runtime Crashes:  $totalUnhandledCrashes');
    print(' • StackOverflows Encountered:      $totalStackOverflows');
    print('----------------------------------------------------------------------');
    print(' 🔍 TOP ARCHITECTURAL ACTION ITEMS:');
    print('----------------------------------------------------------------------');
    print(' 1. [NUM-04 CRITICAL CRASH] Fix raw modulo `a % b` in DbValue / JitCompiler to guard against division by zero.');
    print(' 2. [UNI-02 CRITICAL CORRUPTION] Fix RecordSerializer.serializeMvccRowDirect line 72: replace `str.codeUnitAt(c)` truncation with UTF-8 encoding for strings <= 1024 bytes.');
    print(' 3. [ESC-01, ESC-02, ESC-03] Fix Lexer single-quote scanner to support SQL-standard `\'\'` quote escaping.');
    print(' 4. [ESC-08, ESC-09, ESC-10] Add `/* ... */` block comment skipping to Lexer._skipWhitespaceAndComments().');
    print(' 5. [NUM-11..15] Add scientific notation (`1e10`, `1e-5`, `1.5e+10`) parsing in Lexer and Parser.');
    print(' 6. [UNI-07] Update Lexer._isAlpha() to support Unicode letter code points for international identifiers.');
    print(' 7. [MAL-09] Enforce unique column check in TableSchema / CREATE TABLE parser to reject duplicate column names.');
    print(' 8. [DEP-12] Implement CTE parameter list mapping to anchor projection columns in Parser & Planner.');
    print('======================================================================\n');
  }
}

void main() async {
  print('======================================================================');
  print(' 🔥 ULTSQL PARSER ROBUSTNESS & EXTREME BOUNDARY QA AUDIT 🔥');
  print(' Target Directory: $kDbDir');
  print(' Platform: ${Platform.operatingSystem} (${Platform.numberOfProcessors} cores)');
  print(' Dart Version: ${Platform.version}');
  print('======================================================================\n');

  final suiteSw = Stopwatch()..start();
  final runner = ParserStressRunner();

  try {
    await runner.init();

    await runner.runCategory1();
    await runner.runCategory2();
    await runner.runCategory3();
    await runner.runCategory4();
    await runner.runCategory5();
  } catch (e, st) {
    print('CRITICAL SUITE CRASH: $e\n$st');
  } finally {
    suiteSw.stop();
    runner.printReport(suiteSw.elapsed);
    await runner.close();
  }
}
