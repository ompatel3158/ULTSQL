import 'ast.dart';
import 'token.dart';

class Parser {
  final List<Token> tokens;
  int _current = 0;
  int _placeholderCount = 0;

  Parser(this.tokens);

  bool get _isAtEnd => _peek().type == TokenType.eof;

  Token _peek() => tokens[_current];

  Token _peekNext() =>
      _current + 1 < tokens.length ? tokens[_current + 1] : tokens.last;

  Token _previous() => tokens[_current - 1];

  Token _advance() {
    if (!_isAtEnd) _current++;
    return _previous();
  }

  bool _check(TokenType type) {
    if (_isAtEnd) return false;
    return _peek().type == type;
  }

  bool _match(List<TokenType> types) {
    for (var type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw Exception('[${_peek()}] $message');
  }

  bool _matchWord(String word) {
    if (_check(TokenType.identifier) && _peek().lexeme.toLowerCase() == word) {
      _advance();
      return true;
    }
    return false;
  }

  bool _checkNextIsTransaction() {
    if (_current + 1 >= tokens.length) return false;
    final nextType = tokens[_current + 1].type;
    final nextLexeme = tokens[_current + 1].lexeme.toLowerCase();
    return nextType == TokenType.semicolon || nextLexeme == 'transaction';
  }

  bool _checkNextIsDataType() {
    if (_current + 1 >= tokens.length) return false;
    final nextType = tokens[_current + 1].type;
    final lexeme = tokens[_current + 1].lexeme.toLowerCase();
    return nextType == TokenType.typeInt ||
        nextType == TokenType.typeDouble ||
        nextType == TokenType.typeText ||
        nextType == TokenType.typeVector ||
        nextType == TokenType.typeJson ||
        const {
          'int',
          'integer',
          'bigint',
          'smallint',
          'double',
          'real',
          'float',
          'decimal',
          'numeric',
          'text',
          'varchar',
          'char',
          'string',
          'vector',
          'json',
        }.contains(lexeme);
  }

  List<Stmt> parseScript() {
    final list = <Stmt>[];
    while (!_isAtEnd) {
      if (_check(TokenType.declare) ||
          (_check(TokenType.begin) && _checkNextIsTransaction())) {
        if (_check(TokenType.declare)) {
          list.add(_parsePlSqlBlock());
        } else {
          list.add(_parseStatement());
        }
      } else if (_check(TokenType.begin)) {
        list.add(_parsePlSqlBlock());
      } else {
        list.add(_parsePlSqlStatement());
      }
      // Consume optional trailing semicolons
      while (_match([TokenType.semicolon])) {}
    }
    return list;
  }

  Stmt parse() {
    final list = parseScript();
    if (list.isEmpty) {
      throw Exception("No statements found in script.");
    }
    return list.first;
  }

  Expression parseExpression() {
    return _parseExpression();
  }

  // PL/SQL Parsing
  Stmt _parsePlSqlBlock() {
    List<VarDeclare> declarations = [];
    List<CursorDeclare> cursors = [];
    if (_match([TokenType.declare])) {
      while (!_check(TokenType.begin) && !_isAtEnd) {
        if (_check(TokenType.identifier)) {
          if (_peekNext().type == TokenType.cursorKeyword) {
            cursors.add(_parseCursorDeclaration());
          } else if (_checkNextIsDataType()) {
            declarations.add(_parseDeclaration());
          } else {
            break;
          }
        } else {
          break;
        }
      }
    }

    if (_check(TokenType.begin)) {
      _consume(TokenType.begin, "Expected 'BEGIN' to start executable block.");
      List<Stmt> body = [];
      while (!_check(TokenType.end) &&
          !_check(TokenType.exceptionKeyword) &&
          !_isAtEnd) {
        body.add(_parsePlSqlStatement());
      }

      List<ExceptionHandler>? exceptionHandlers;
      if (_match([TokenType.exceptionKeyword])) {
        exceptionHandlers = [];
        while (!_check(TokenType.end) && !_isAtEnd) {
          _consume(
            TokenType.whenKeyword,
            "Expected 'WHEN' in EXCEPTION block.",
          );
          final excNameToken = _consume(
            TokenType.identifier,
            "Expected exception name.",
          );
          final excName = excNameToken.lexeme;
          _consume(
            TokenType.then,
            "Expected 'THEN' after exception condition.",
          );

          final handlerBody = <Stmt>[];
          while (!_check(TokenType.whenKeyword) &&
              !_check(TokenType.end) &&
              !_isAtEnd) {
            handlerBody.add(_parsePlSqlStatement());
          }
          exceptionHandlers.add(ExceptionHandler(excName, handlerBody));
        }
      }

      _consume(TokenType.end, "Expected 'END' to close block.");
      _consume(TokenType.semicolon, "Expected ';' after 'END'.");
      return PlSqlBlock(
        declarations,
        body,
        cursors: cursors,
        exceptionHandlers: exceptionHandlers,
      );
    } else {
      // T-SQL style top-level declarations
      return PlSqlBlock(declarations, [], cursors: cursors);
    }
  }

  CursorDeclare _parseCursorDeclaration() {
    final nameToken = _consume(TokenType.identifier, "Expected cursor name.");
    final name = nameToken.lexeme;

    _consume(TokenType.cursorKeyword, "Expected 'CURSOR' keyword.");
    _consume(TokenType.forKeyword, "Expected 'FOR' after 'CURSOR'.");

    _consume(TokenType.select, "Expected 'SELECT' for cursor query.");
    final selectStmt = _parseSelectStatement() as SelectStmt;

    if (_check(TokenType.semicolon)) {
      _advance();
    }
    return CursorDeclare(name, selectStmt);
  }

  VarDeclare _parseDeclaration() {
    final nameToken = _consume(TokenType.identifier, "Expected variable name.");
    final name = nameToken.lexeme;

    final dataType = _parseDataType();

    Expression? initialValue;
    if (_match([TokenType.assign, TokenType.equals])) {
      initialValue = _parseExpression();
    }

    _consume(TokenType.semicolon, "Expected ';' after variable declaration.");
    return VarDeclare(name, dataType, initialValue);
  }

  DataType _parseDataType() {
    Token token;
    if (_match([
      TokenType.typeInt,
      TokenType.typeDouble,
      TokenType.typeText,
      TokenType.typeVector,
      TokenType.typeJson,
      TokenType.typeBool,
      TokenType.typeUuid,
      TokenType.typeDateTime,
      TokenType.typeBlob,
      TokenType.typeDecimal,
    ])) {
      token = _previous();
    } else if (_check(TokenType.identifier)) {
      token = _advance();
    } else {
      throw Exception(
        "Unsupported or missing variable type at '${_peek().lexeme}'.",
      );
    }

    if (_match([TokenType.lParen])) {
      _parseExpression();
      while (_match([TokenType.comma])) {
        _parseExpression();
      }
      _consume(TokenType.rParen, "Expected ')' after type modifier.");
    }

    final typeStr = token.lexeme.toLowerCase();
    if (typeStr == 'int' ||
        typeStr == 'integer' ||
        typeStr == 'bigint' ||
        typeStr == 'smallint') {
      return DataType.integer;
    } else if (typeStr == 'double' || typeStr == 'real' || typeStr == 'float') {
      return DataType.double;
    } else if (typeStr == 'decimal' || typeStr == 'numeric') {
      return DataType.decimal;
    } else if (typeStr == 'text' ||
        typeStr == 'varchar' ||
        typeStr == 'char' ||
        typeStr == 'string') {
      return DataType.text;
    } else if (typeStr == 'vector') {
      return DataType.vector;
    } else if (typeStr == 'json') {
      return DataType.json;
    } else if (typeStr == 'bool' || typeStr == 'boolean') {
      return DataType.boolean;
    } else if (typeStr == 'uuid' || typeStr == 'guid') {
      return DataType.uuid;
    } else if (typeStr == 'datetime' ||
        typeStr == 'timestamp' ||
        typeStr == 'date') {
      return DataType.datetime;
    } else if (typeStr == 'blob' || typeStr == 'bytea' || typeStr == 'bytes') {
      return DataType.blob;
    }
    throw Exception("Unsupported data type '$typeStr'.");
  }

  Stmt _parsePlSqlStatement() {
    if (_check(TokenType.declare) ||
        (_check(TokenType.begin) && !_checkNextIsTransaction())) {
      return _parsePlSqlBlock();
    }
    if (_match([TokenType.openKeyword])) {
      final cursorName = _consume(
        TokenType.identifier,
        "Expected cursor name after OPEN.",
      ).lexeme;
      if (_check(TokenType.semicolon)) _advance();
      return OpenCursorStmt(cursorName);
    }
    if (_match([TokenType.fetchKeyword])) {
      final cursorName = _consume(
        TokenType.identifier,
        "Expected cursor name after FETCH.",
      ).lexeme;
      _consume(TokenType.into, "Expected 'INTO' after cursor name in FETCH.");
      final targetVars = <String>[];
      do {
        targetVars.add(
          _consume(
            TokenType.identifier,
            "Expected variable name in FETCH INTO.",
          ).lexeme,
        );
      } while (_match([TokenType.comma]));
      if (_check(TokenType.semicolon)) _advance();
      return FetchCursorStmt(cursorName, targetVars);
    }
    if (_match([TokenType.closeKeyword])) {
      final cursorName = _consume(
        TokenType.identifier,
        "Expected cursor name after CLOSE.",
      ).lexeme;
      if (_check(TokenType.semicolon)) _advance();
      return CloseCursorStmt(cursorName);
    }
    if (_check(TokenType.ifKeyword)) {
      return _parseIfStatement();
    }
    if (_check(TokenType.forKeyword) ||
        (_check(TokenType.identifier) &&
            _peek().lexeme.toLowerCase() == 'for')) {
      return _parseForStatement();
    }
    if (_check(TokenType.whileKeyword)) {
      return _parseWhileStatement();
    }
    if (_check(TokenType.returnKeyword)) {
      return _parseReturnStatement();
    }
    if (_check(TokenType.identifier)) {
      final id = _peek().lexeme.toLowerCase();
      if (const {
        'update',
        'select',
        'insert',
        'delete',
        'create',
        'show',
        'grant',
        'revoke',
        'explain',
        'analyze',
        'use',
      }.contains(id)) {
        // Fall through to standard SQL statement
      } else {
        if (id == 'dbms_output') {
          return _parseDbmsOutputStatement();
        }
        if (id == 'set') {
          final nextLexeme = _peekNext().lexeme.toLowerCase();
          if (nextLexeme == 'user' ||
              nextLexeme == 'current_user' ||
              nextLexeme == 'engine_option') {
            // Fall through to standard SQL statement for DCL / Engine Option SetStmt
          } else {
            _advance(); // Consume 'set'
            return _parseAssignmentStatement();
          }
        } else {
          return _parseAssignmentStatement();
        }
      }
    }
    // Standard SQL can also run in block
    final stmt = _parseStatement();
    // Consume optional semicolon for embedded SQL statements inside PL/SQL
    if (_check(TokenType.semicolon)) {
      _advance();
    }
    return stmt;
  }

  Stmt _parseIfStatement() {
    _consume(TokenType.ifKeyword, "Expected 'IF'.");
    final condition = _parseExpression();
    _consume(TokenType.then, "Expected 'THEN' after condition.");

    List<Stmt> thenBranch = [];
    while (!_check(TokenType.elsif) &&
        !_check(TokenType.elseKeyword) &&
        !_check(TokenType.end) &&
        !_isAtEnd) {
      thenBranch.add(_parsePlSqlStatement());
    }

    List<ElsifBranch> elsifBranches = [];
    while (_match([TokenType.elsif])) {
      final elsifCondition = _parseExpression();
      _consume(TokenType.then, "Expected 'THEN' after ELSIF condition.");
      List<Stmt> elsifBody = [];
      while (!_check(TokenType.elsif) &&
          !_check(TokenType.elseKeyword) &&
          !_check(TokenType.end) &&
          !_isAtEnd) {
        elsifBody.add(_parsePlSqlStatement());
      }
      elsifBranches.add(ElsifBranch(elsifCondition, elsifBody));
    }

    List<Stmt>? elseBranch;
    if (_match([TokenType.elseKeyword])) {
      elseBranch = [];
      while (!_check(TokenType.end) && !_isAtEnd) {
        elseBranch.add(_parsePlSqlStatement());
      }
    }

    _consume(TokenType.end, "Expected 'END' for IF statement.");
    _consume(TokenType.ifKeyword, "Expected 'IF' after 'END'.");
    _consume(TokenType.semicolon, "Expected ';' after 'END IF'.");

    return IfStmt(condition, thenBranch, elsifBranches, elseBranch);
  }

  Stmt _parseWhileStatement() {
    _consume(TokenType.whileKeyword, "Expected 'WHILE'.");
    final condition = _parseExpression();

    final isTsql = _check(TokenType.begin);
    if (isTsql) {
      _consume(TokenType.begin, "Expected 'BEGIN' after WHILE condition.");
    } else {
      _consume(
        TokenType.loop,
        "Expected 'LOOP' or 'BEGIN' after WHILE condition.",
      );
    }

    List<Stmt> body = [];
    while (!_check(TokenType.end) && !_isAtEnd) {
      body.add(_parsePlSqlStatement());
    }

    _consume(TokenType.end, "Expected 'END' to close block.");

    if (isTsql) {
      if (_check(TokenType.semicolon)) {
        _advance();
      }
    } else {
      _consume(TokenType.loop, "Expected 'LOOP' after 'END'.");
      _consume(TokenType.semicolon, "Expected ';' after 'END LOOP'.");
    }

    return WhileStmt(condition, body);
  }

  Stmt _parseForStatement() {
    _advance(); // consume 'FOR'
    final varName = _consume(
      TokenType.identifier,
      "Expected loop variable name.",
    ).lexeme;
    if (_check(TokenType.inKeyword) ||
        (_check(TokenType.identifier) &&
            _peek().lexeme.toLowerCase() == 'in')) {
      _advance();
    }
    final startExpr = _parseExpression();
    if (_match([TokenType.dot])) {
      if (_check(TokenType.dot)) _advance();
    }
    final endExpr = _parseExpression();
    if (_check(TokenType.loop) ||
        (_check(TokenType.identifier) &&
            _peek().lexeme.toLowerCase() == 'loop')) {
      _advance();
    }
    final body = <Stmt>[];
    while (!_check(TokenType.end) && !_isAtEnd) {
      body.add(_parsePlSqlStatement());
    }
    _consume(TokenType.end, "Expected 'END' to close FOR loop.");
    if (_check(TokenType.loop) ||
        (_check(TokenType.identifier) &&
            _peek().lexeme.toLowerCase() == 'loop')) {
      _advance();
    }
    if (_check(TokenType.semicolon)) _advance();
    return ForLoopStmt(varName, startExpr, endExpr, body);
  }

  Stmt _parseAssignmentStatement() {
    final varNameToken = _consume(
      TokenType.identifier,
      "Expected variable name.",
    );
    var varName = varNameToken.lexeme;
    while (_match([TokenType.dot])) {
      final segment = _consume(
        TokenType.identifier,
        "Expected segment after dot.",
      );
      varName += '.${segment.lexeme}';
    }
    if (!_match([TokenType.assign, TokenType.equals])) {
      throw Exception("Expected ':=' or '=' for assignment.");
    }
    final expr = _parseExpression();
    _consume(TokenType.semicolon, "Expected ';' after assignment.");
    return AssignStmt(varName, expr);
  }

  Stmt _parseDbmsOutputStatement() {
    _consume(TokenType.identifier, "Expected 'DBMS_OUTPUT'.");
    _consume(TokenType.dot, "Expected '.' after 'DBMS_OUTPUT'.");
    final putLineToken = _consume(TokenType.identifier, "Expected 'PUT_LINE'.");
    if (putLineToken.lexeme.toLowerCase() != 'put_line') {
      throw Exception(
        "Expected 'PUT_LINE' call, found '${putLineToken.lexeme}'.",
      );
    }
    _consume(TokenType.lParen, "Expected '(' for function call.");
    final expr = _parseExpression();
    _consume(TokenType.rParen, "Expected ')' to close function call.");
    _consume(TokenType.semicolon, "Expected ';' after PUT_LINE.");
    return DbmsOutputStmt(expr);
  }

  // SQL Parsing
  Stmt _parseStatement() {
    _placeholderCount = 0;
    if (_match([TokenType.emitKeyword]) || _matchWord('emit')) {
      if (_match([TokenType.to]) || _matchWord('to')) {}
      final streamName = _consume(
        TokenType.identifier,
        "Expected stream name after EMIT TO.",
      ).lexeme;
      _consume(TokenType.valuesKeyword, "Expected 'VALUES' after stream name.");
      _consume(TokenType.lParen, "Expected '(' for stream emit values.");
      List<Expression> values = [];
      do {
        values.add(_parseExpression());
      } while (_match([TokenType.comma]));
      _consume(TokenType.rParen, "Expected ')' after stream emit values.");
      if (_check(TokenType.semicolon)) _advance();
      return EmitStreamStmt(streamName: streamName, values: values);
    }
    if (_match([TokenType.vacuumKeyword])) {
      bool full = false;
      if (_match([TokenType.fullKeyword])) {
        full = true;
      }
      final tableNameToken = _consume(
        TokenType.identifier,
        "Expected table name after VACUUM.",
      );
      if (_check(TokenType.semicolon)) _advance();
      return VacuumStmt(tableNameToken.lexeme, full: full);
    }
    if (_match([TokenType.dropKeyword])) {
      if (_match([TokenType.table])) {
        bool ifExists = false;
        if (_match([TokenType.ifKeyword])) {
          if (_match([TokenType.existsKeyword])) {
            ifExists = true;
          }
        } else if (_check(TokenType.identifier) &&
            _peek().lexeme.toLowerCase() == 'if') {
          _advance();
          if (_check(TokenType.identifier) &&
              _peek().lexeme.toLowerCase() == 'exists') {
            _advance();
            ifExists = true;
          }
        }
        final tableName = _consume(
          TokenType.identifier,
          "Expected table name after 'DROP TABLE'.",
        ).lexeme;
        if (_check(TokenType.semicolon)) _advance();
        return DropTableStmt(tableName, ifExists: ifExists);
      } else if (_match([TokenType.indexKeyword])) {
        final indexName = _consume(
          TokenType.identifier,
          "Expected index name after 'DROP INDEX'.",
        ).lexeme;
        if (_check(TokenType.semicolon)) _advance();
        return DropIndexStmt(indexName);
      }
    }
    if (_match([TokenType.describeKeyword])) {
      final tableNameToken = _consume(
        TokenType.identifier,
        "Expected table name after DESCRIBE.",
      );
      if (_check(TokenType.semicolon)) _advance();
      return DescribeTableStmt(tableNameToken.lexeme);
    }
    if (_check(TokenType.identifier) &&
        _peek().lexeme.toLowerCase() == 'desc') {
      _advance();
      final tableNameToken = _consume(
        TokenType.identifier,
        "Expected table name after DESC.",
      );
      if (_check(TokenType.semicolon)) _advance();
      return DescribeTableStmt(tableNameToken.lexeme);
    }
    if (_match([TokenType.pragmaKeyword])) {
      final pragmaNameToken = _consume(
        TokenType.identifier,
        "Expected pragma name.",
      );
      if (pragmaNameToken.lexeme.toLowerCase() == 'table_info') {
        _consume(TokenType.lParen, "Expected '(' after table_info.");
        String tableName = '';
        if (_match([TokenType.stringLiteral])) {
          tableName = _previous().lexeme;
          if (tableName.startsWith("'") || tableName.startsWith('"')) {
            tableName = tableName.substring(1, tableName.length - 1);
          }
        } else {
          tableName = _consume(
            TokenType.identifier,
            "Expected table name in PRAGMA table_info.",
          ).lexeme;
        }
        _consume(
          TokenType.rParen,
          "Expected ')' after table name in PRAGMA table_info.",
        );
        if (_check(TokenType.semicolon)) _advance();
        return PragmaTableInfoStmt(tableName);
      }
    }
    if (_match([TokenType.truncateKeyword])) {
      if (_match([TokenType.table])) {}
      final tableNameToken = _consume(
        TokenType.identifier,
        "Expected table name after TRUNCATE.",
      );
      if (_check(TokenType.semicolon)) _advance();
      return TruncateTableStmt(tableNameToken.lexeme);
    }
    if (_match([TokenType.alterKeyword])) {
      return _parseAlterTableStatement();
    }
    if (_match([TokenType.explain])) {
      _consume(TokenType.select, "Expected 'SELECT' after 'EXPLAIN'.");
      final selectStmt = _parseSelectStatement() as SelectStmt;
      return ExplainStmt(selectStmt);
    }
    if (_match([TokenType.generate])) {
      if (!_isAtEnd && _peek().lexeme.toLowerCase() == 'data') {
        _advance();
      }
      if (_check(TokenType.semicolon)) _advance();
      return GenerateStmt();
    }
    if (_match([TokenType.analyze])) {
      final tableName = _consume(
        TokenType.identifier,
        "Expected table name to analyze.",
      ).lexeme;
      if (_check(TokenType.semicolon)) _advance();
      return AnalyzeStmt(tableName);
    }
    if (_match([TokenType.callKeyword])) {
      return _parseCallStatement();
    }
    if (_match([TokenType.generate])) {
      if (!_isAtEnd && _peek().lexeme.toLowerCase() == 'data') {
        _advance();
      }
      if (_check(TokenType.semicolon)) _advance();
      return GenerateStmt();
    }
    if (_match([TokenType.analyze])) {
      final tableName = _consume(
        TokenType.identifier,
        "Expected table name to analyze.",
      ).lexeme;
      if (_check(TokenType.semicolon)) _advance();
      return AnalyzeStmt(tableName);
    }
    if (_match([TokenType.callKeyword])) {
      return _parseCallStatement();
    }
    if (_match([TokenType.create])) {
      return _parseCreateStatement();
    }
    if (_match([TokenType.insert])) {
      return _parseInsertStatement();
    }
    if (_match([TokenType.replaceKeyword])) {
      return _parseInsertStatement(isReplace: true);
    }
    if (_match([TokenType.withKeyword])) {
      return _parseCteStatement();
    }
    if (_match([TokenType.select])) {
      return _parseSelectOrUnionStatement();
    }
    if (_match([TokenType.deleteKeyword])) {
      _consume(TokenType.from, "Expected 'FROM' after 'DELETE'.");
      final tableName = _consume(
        TokenType.identifier,
        "Expected table name.",
      ).lexeme;
      Expression? whereCondition;
      if (_match([TokenType.where])) {
        whereCondition = _parseExpression();
      }
      if (_check(TokenType.semicolon)) _advance();
      return DeleteStmt(tableName, whereCondition);
    }
    if (_match([TokenType.deleteKeyword])) {
      _consume(TokenType.from, "Expected 'FROM' after 'DELETE'.");
      final tableName = _consume(
        TokenType.identifier,
        "Expected table name.",
      ).lexeme;
      Expression? whereCondition;
      if (_match([TokenType.where])) {
        whereCondition = _parseExpression();
      }
      if (_check(TokenType.semicolon)) _advance();
      return DeleteStmt(tableName, whereCondition);
    }
    if (_check(TokenType.identifier) &&
        _peek().lexeme.toLowerCase() == 'update') {
      _advance(); // Consume 'update'
      final tableName = _consume(
        TokenType.identifier,
        "Expected table name.",
      ).lexeme;

      final setToken = _consume(
        TokenType.identifier,
        "Expected 'SET' keyword.",
      );
      if (setToken.lexeme.toLowerCase() != 'set') {
        throw Exception(
          "Expected 'SET' keyword after table name in UPDATE statement.",
        );
      }

      final colName = _consume(
        TokenType.identifier,
        "Expected column name to update.",
      ).lexeme;
      _consume(TokenType.equals, "Expected '=' after column name.");
      final valueExpr = _parseExpression();

      Expression? whereCondition;
      if (_match([TokenType.where])) {
        whereCondition = _parseExpression();
      }

      if (_check(TokenType.semicolon)) _advance();
      return UpdateStmt(tableName, colName, valueExpr, whereCondition);
    }
    if (_match([TokenType.begin])) {
      if (!_isAtEnd && _peek().lexeme.toLowerCase() == 'transaction') {
        _advance();
      }
      if (_check(TokenType.semicolon)) _advance();
      return BeginTxStmt();
    }
    if (_match([TokenType.commit])) {
      if (!_isAtEnd &&
          (_peek().lexeme.toLowerCase() == 'transaction' ||
              _peek().lexeme.toLowerCase() == 'work')) {
        _advance();
      }
      if (_check(TokenType.semicolon)) _advance();
      return CommitTxStmt();
    }
    if (_match([TokenType.savepointKeyword])) {
      final nameToken = _consume(
        TokenType.identifier,
        "Expected savepoint name.",
      );
      if (_check(TokenType.semicolon)) _advance();
      return SavepointStmt(nameToken.lexeme);
    }
    if (_match([TokenType.releaseKeyword])) {
      if (!_isAtEnd && _peek().lexeme.toLowerCase() == 'savepoint') {
        _advance();
      }
      final nameToken = _consume(
        TokenType.identifier,
        "Expected savepoint name.",
      );
      if (_check(TokenType.semicolon)) _advance();
      return ReleaseSavepointStmt(nameToken.lexeme);
    }
    if (_match([TokenType.rollback])) {
      if (!_isAtEnd && _peek().lexeme.toLowerCase() == 'to') {
        _advance();
        if (!_isAtEnd && _peek().lexeme.toLowerCase() == 'savepoint') {
          _advance();
        }
        final nameToken = _consume(
          TokenType.identifier,
          "Expected savepoint name.",
        );
        if (_check(TokenType.semicolon)) _advance();
        return RollbackToSavepointStmt(nameToken.lexeme);
      }
      if (!_isAtEnd &&
          (_peek().lexeme.toLowerCase() == 'transaction' ||
              _peek().lexeme.toLowerCase() == 'work')) {
        _advance();
      }
      if (_check(TokenType.semicolon)) _advance();
      return RollbackTxStmt();
    }
    if (_match([TokenType.showKeyword])) {
      return _parseShowStatement();
    }
    final nextLexeme = _peek().lexeme.toLowerCase();
    if (nextLexeme == 'grant') {
      _advance(); // Consume 'grant'
      return _parseGrantStatement();
    }
    if (nextLexeme == 'revoke') {
      _advance(); // Consume 'revoke'
      return _parseRevokeStatement();
    }
    if (nextLexeme == 'set') {
      _advance(); // Consume 'set'
      return _parseSetStatement();
    }
    if (nextLexeme == 'use') {
      _advance(); // Consume 'use'
      final dbNameToken = _consume(
        TokenType.identifier,
        "Expected database name.",
      );
      if (_check(TokenType.semicolon)) _advance();
      return UseDatabaseStmt(dbNameToken.lexeme);
    }
    throw Exception(
      "Unsupported statement beginning with '${_peek().lexeme}'.",
    );
  }

  Stmt _parseGrantStatement() {
    String privilege = '';
    final nextLex = _peek().lexeme.toLowerCase();
    if (nextLex == 'all') {
      _advance();
      privilege = 'all';
      if (_peek().lexeme.toLowerCase() == 'privileges') {
        _advance();
      }
    } else {
      privilege = _advance().lexeme.toLowerCase();
    }

    _consume(TokenType.on, "Expected 'ON' after privilege in GRANT statement.");
    final tableName = _consume(
      TokenType.identifier,
      "Expected table name in GRANT statement.",
    ).lexeme;
    _consume(TokenType.to, "Expected 'TO' in GRANT statement.");

    String user = '';
    if (_check(TokenType.stringLiteral)) {
      user = _consume(TokenType.stringLiteral, "").lexeme;
    } else {
      user = _consume(
        TokenType.identifier,
        "Expected username in GRANT statement.",
      ).lexeme;
    }

    if (_check(TokenType.semicolon)) _advance();
    return GrantStmt(privilege, tableName, user);
  }

  Stmt _parseRevokeStatement() {
    String privilege = '';
    final nextLex = _peek().lexeme.toLowerCase();
    if (nextLex == 'all') {
      _advance();
      privilege = 'all';
      if (_peek().lexeme.toLowerCase() == 'privileges') {
        _advance();
      }
    } else {
      privilege = _advance().lexeme.toLowerCase();
    }

    _consume(
      TokenType.on,
      "Expected 'ON' after privilege in REVOKE statement.",
    );
    final tableName = _consume(
      TokenType.identifier,
      "Expected table name in REVOKE statement.",
    ).lexeme;
    _consume(TokenType.from, "Expected 'FROM' in REVOKE statement.");

    String user = '';
    if (_check(TokenType.stringLiteral)) {
      user = _consume(TokenType.stringLiteral, "").lexeme;
    } else {
      user = _consume(
        TokenType.identifier,
        "Expected username in REVOKE statement.",
      ).lexeme;
    }

    if (_check(TokenType.semicolon)) _advance();
    return RevokeStmt(privilege, tableName, user);
  }

  Stmt _parseSetStatement() {
    final nextLexeme = _peek().lexeme.toLowerCase();
    if (nextLexeme == 'user' || nextLexeme == 'current_user') {
      _advance(); // Consume user token

      if (_check(TokenType.equals)) {
        _advance();
      }

      String username = '';
      if (_check(TokenType.stringLiteral)) {
        username = _consume(TokenType.stringLiteral, "").lexeme;
      } else {
        username = _consume(
          TokenType.identifier,
          "Expected username in SET USER statement.",
        ).lexeme;
      }

      if (_check(TokenType.semicolon)) _advance();
      return SetUserStmt(username);
    } else if (nextLexeme == 'engine_option') {
      _advance(); // Consume engine_option token
      final optionName = _consume(
        TokenType.stringLiteral,
        "Expected string literal for option name.",
      ).lexeme;
      _consume(TokenType.equals, "Expected '=' after option name.");
      final valueToken = _advance();
      bool optionValue;
      final valClean = valueToken.lexeme
          .toLowerCase()
          .replaceAll("'", "")
          .replaceAll('"', '')
          .trim();
      if (valClean == 'on' || valClean == 'true' || valClean == '1') {
        optionValue = true;
      } else if (valClean == 'off' || valClean == 'false' || valClean == '0') {
        optionValue = false;
      } else {
        throw Exception("Expected 'ON' or 'OFF' for engine option value.");
      }
      if (_check(TokenType.semicolon)) _advance();
      return SetEngineOptionStmt(optionName, optionValue);
    }
    throw Exception("Unsupported SET statement: ${_peek().lexeme}");
  }

  Stmt _parseShowStatement() {
    if (_match([TokenType.tablesKeyword])) {
      if (_check(TokenType.semicolon)) _advance();
      return ShowTablesStmt();
    } else if (_match([TokenType.indexesKeyword])) {
      String? tableName;
      if (_match([TokenType.from])) {
        final tableNameToken = _consume(
          TokenType.identifier,
          "Expected table name.",
        );
        tableName = tableNameToken.lexeme;
      }
      if (_check(TokenType.semicolon)) _advance();
      return ShowIndexesStmt(tableName: tableName);
    } else if (_match([TokenType.columnsKeyword])) {
      if (_match([TokenType.from]) || _match([TokenType.inKeyword])) {}
      final tableNameToken = _consume(
        TokenType.identifier,
        "Expected table name after SHOW COLUMNS.",
      );
      if (_check(TokenType.semicolon)) _advance();
      return ShowColumnsStmt(tableNameToken.lexeme);
    } else if (_match([TokenType.schemasKeyword]) ||
        (_check(TokenType.identifier) &&
            _peek().lexeme.toLowerCase() == 'databases')) {
      if (_check(TokenType.identifier)) _advance();
      if (_check(TokenType.semicolon)) _advance();
      return ShowSchemasStmt();
    }
    throw Exception(
      "Expected 'TABLES', 'INDEXES', 'COLUMNS', or 'SCHEMAS' after 'SHOW'.",
    );
  }

  Stmt _parseCreateStatement() {
    if (_match([TokenType.triggerKeyword])) {
      final startIdx = _current - 2; // Since 'create' and 'trigger' are matched
      final nameToken = _consume(
        TokenType.identifier,
        "Expected trigger name.",
      );
      final name = nameToken.lexeme;

      String timing;
      if (_match([TokenType.beforeKeyword])) {
        timing = 'BEFORE';
      } else if (_match([TokenType.afterKeyword])) {
        timing = 'AFTER';
      } else {
        throw Exception("Expected 'BEFORE' or 'AFTER' trigger timing.");
      }

      String event;
      if (_match([TokenType.insert])) {
        event = 'INSERT';
      } else if (_check(TokenType.identifier) &&
          _peek().lexeme.toLowerCase() == 'update') {
        _advance();
        event = 'UPDATE';
      } else if (_match([TokenType.deleteKeyword])) {
        event = 'DELETE';
      } else {
        throw Exception(
          "Expected 'INSERT', 'UPDATE', or 'DELETE' trigger event.",
        );
      }

      _consume(TokenType.on, "Expected 'ON' in trigger declaration.");
      final tableNameToken = _consume(
        TokenType.identifier,
        "Expected table name.",
      );
      final tableName = tableNameToken.lexeme;

      bool forEachRow = false;
      if (_match([TokenType.forKeyword])) {
        _consume(TokenType.eachKeyword, "Expected 'EACH' after 'FOR'.");
        _consume(TokenType.rowKeyword, "Expected 'ROW' after 'FOR EACH'.");
        forEachRow = true;
      }

      if (_match([TokenType.as])) {} // Consume optional AS

      List<VarDeclare> declarations = [];
      if (_match([TokenType.declare])) {
        while (_check(TokenType.identifier) &&
            _checkNextIsDataType() &&
            !_isAtEnd) {
          declarations.add(_parseDeclaration());
        }
      }

      _consume(TokenType.begin, "Expected 'BEGIN' to start trigger body.");
      final body = <Stmt>[];
      while (!_check(TokenType.end) && !_isAtEnd) {
        body.add(_parsePlSqlStatement());
      }
      _consume(TokenType.end, "Expected 'END' to close trigger body.");
      if (_check(TokenType.semicolon)) _advance();

      final endIdx = _current;
      final sql = tokens
          .sublist(startIdx, endIdx)
          .map((t) {
            if (t.type == TokenType.stringLiteral) {
              final escaped = t.lexeme.replaceAll("'", "''");
              return "'$escaped'";
            }
            return t.lexeme;
          })
          .join(' ');

      return CreateTriggerStmt(
        name: name,
        timing: timing,
        event: event,
        tableName: tableName,
        forEachRow: forEachRow,
        declarations: declarations,
        body: body,
        sql: sql,
      );
    }

    if (_match([TokenType.procedureKeyword])) {
      final startIdx =
          _current - 2; // Since 'create' and 'procedure' are matched
      final nameToken = _consume(
        TokenType.identifier,
        "Expected procedure name.",
      );
      final name = nameToken.lexeme;

      final params = _parseParameters();

      _consume(TokenType.as, "Expected 'AS' after procedure parameters.");
      _consume(TokenType.begin, "Expected 'BEGIN' to start procedure body.");

      final body = <Stmt>[];
      while (!_check(TokenType.end) && !_isAtEnd) {
        body.add(_parsePlSqlStatement());
      }
      _consume(TokenType.end, "Expected 'END' to close procedure body.");
      if (_check(TokenType.semicolon)) _advance();

      final endIdx = _current;
      final sql = tokens
          .sublist(startIdx, endIdx)
          .map((t) {
            if (t.type == TokenType.stringLiteral) {
              final escaped = t.lexeme.replaceAll("'", "''");
              return "'$escaped'";
            }
            return t.lexeme;
          })
          .join(' ');

      return CreateProcedureStmt(name, params, body, sql);
    }

    if (_match([TokenType.functionKeyword])) {
      final startIdx =
          _current - 2; // Since 'create' and 'function' are matched
      final nameToken = _consume(
        TokenType.identifier,
        "Expected function name.",
      );
      final name = nameToken.lexeme;

      final params = _parseParameters();

      _consume(TokenType.returnsKeyword, "Expected 'RETURNS' keyword.");
      final returnType = _parseDataType();

      _consume(TokenType.as, "Expected 'AS' after function return type.");
      _consume(TokenType.begin, "Expected 'BEGIN' to start function body.");

      final body = <Stmt>[];
      while (!_check(TokenType.end) && !_isAtEnd) {
        body.add(_parsePlSqlStatement());
      }
      _consume(TokenType.end, "Expected 'END' to close function body.");
      if (_check(TokenType.semicolon)) _advance();

      final endIdx = _current;
      final sql = tokens
          .sublist(startIdx, endIdx)
          .map((t) {
            if (t.type == TokenType.stringLiteral) {
              final escaped = t.lexeme.replaceAll("'", "''");
              return "'$escaped'";
            }
            return t.lexeme;
          })
          .join(' ');

      return CreateFunctionStmt(name, params, returnType, body, sql);
    }

    if (_match([TokenType.macroKeyword]) || _matchWord('macro')) {
      final name = _consume(
        TokenType.identifier,
        "Expected macro name.",
      ).lexeme;
      List<String> params = [];
      if (_match([TokenType.lParen])) {
        if (!_check(TokenType.rParen)) {
          do {
            params.add(
              _consume(
                TokenType.identifier,
                "Expected parameter name in macro.",
              ).lexeme,
            );
          } while (_match([TokenType.comma]));
        }
        _consume(TokenType.rParen, "Expected ')' after macro parameters.");
      }
      _consume(TokenType.as, "Expected 'AS' after macro declaration.");
      final bodyExpr = _parseExpression();
      if (_check(TokenType.semicolon)) _advance();
      return CreateMacroStmt(name: name, params: params, bodyExpr: bodyExpr);
    }

    if (_match([TokenType.streamKeyword]) || _matchWord('stream')) {
      final streamName = _consume(
        TokenType.identifier,
        "Expected stream name.",
      ).lexeme;
      if (_check(TokenType.semicolon)) _advance();
      return CreateStreamStmt(streamName: streamName);
    }

    if (_peek().lexeme.toLowerCase() == 'database') {
      _advance(); // Consume 'database'
      final dbNameToken = _consume(
        TokenType.identifier,
        "Expected database name.",
      );
      if (_check(TokenType.semicolon)) _advance();
      return CreateDatabaseStmt(dbNameToken.lexeme);
    }

    if (_match([TokenType.foreignKeyword])) {
      _consume(TokenType.table, "Expected 'TABLE' after 'FOREIGN'.");
      final tableNameToken = _consume(
        TokenType.identifier,
        "Expected table name.",
      );
      final tableName = tableNameToken.lexeme;

      _consume(TokenType.lParen, "Expected '(' to list columns.");

      List<ColumnDef> columns = [];
      do {
        columns.add(_parseColumnDef());
      } while (_match([TokenType.comma]));

      _consume(TokenType.rParen, "Expected ')' to close column list.");

      _consume(TokenType.serverKeyword, "Expected 'SERVER'.");
      final serverToken = _consume(
        TokenType.identifier,
        "Expected server name.",
      );
      final serverName = serverToken.lexeme;

      _consume(TokenType.optionsKeyword, "Expected 'OPTIONS'.");
      _consume(TokenType.lParen, "Expected '(' after 'OPTIONS'.");
      Map<String, String> options = {};
      do {
        final optKey = _consume(
          TokenType.identifier,
          "Expected option key.",
        ).lexeme;
        final optVal = _consume(
          TokenType.stringLiteral,
          "Expected string literal for option value.",
        ).lexeme;
        options[optKey] = optVal;
      } while (_match([TokenType.comma]));
      _consume(TokenType.rParen, "Expected ')' after options.");

      if (_check(TokenType.semicolon)) _advance();
      return CreateForeignTableStmt(tableName, columns, serverName, options);
    } else if (_match([TokenType.table])) {
      bool ifNotExists = false;
      if (_match([TokenType.ifKeyword])) {
        if (_match([TokenType.notKeyword])) {
          _match([TokenType.existsKeyword]);
          ifNotExists = true;
        }
      } else if (_check(TokenType.identifier) &&
          _peek().lexeme.toLowerCase() == 'if') {
        _advance();
        if (_check(TokenType.identifier) &&
            _peek().lexeme.toLowerCase() == 'not') {
          _advance();
          if (_check(TokenType.identifier) &&
              _peek().lexeme.toLowerCase() == 'exists') {
            _advance();
            ifNotExists = true;
          }
        }
      }
      final tableNameToken = _consume(
        TokenType.identifier,
        "Expected table name.",
      );
      final tableName = tableNameToken.lexeme;

      PartitionOfClause? partitionOf;
      List<ColumnDef> columns = [];

      if (_match([TokenType.partition])) {
        _consume(TokenType.ofKeyword, "Expected 'OF' after 'PARTITION'.");
        final parentName = _consume(
          TokenType.identifier,
          "Expected parent table name.",
        ).lexeme;
        _consume(TokenType.forKeyword, "Expected 'FOR'.");
        _consume(TokenType.valuesKeyword, "Expected 'VALUES'.");
        _consume(TokenType.from, "Expected 'FROM'.");
        _consume(TokenType.lParen, "Expected '('.");
        final fromVal = _consume(
          TokenType.stringLiteral,
          "Expected string literal.",
        ).lexeme;
        _consume(TokenType.rParen, "Expected ')'.");
        _consume(TokenType.to, "Expected 'TO'.");
        _consume(TokenType.lParen, "Expected '('.");
        final toVal = _consume(
          TokenType.stringLiteral,
          "Expected string literal.",
        ).lexeme;
        _consume(TokenType.rParen, "Expected ')'.");
        partitionOf = PartitionOfClause(parentName, fromVal, toVal);
      } else {
        _consume(TokenType.lParen, "Expected '(' to list columns.");
        do {
          columns.add(_parseColumnDef());
        } while (_match([TokenType.comma]));
        _consume(TokenType.rParen, "Expected ')' to close column list.");
      }

      PartitionByClause? partitionBy;
      if (partitionOf == null && _match([TokenType.partition])) {
        _consume(TokenType.by, "Expected 'BY' after 'PARTITION'.");
        String strategy;
        if (_match([TokenType.rangeKeyword])) {
          strategy = 'RANGE';
        } else {
          throw Exception("Unsupported partitioning strategy.");
        }
        _consume(TokenType.lParen, "Expected '('.");
        final colName = _consume(
          TokenType.identifier,
          "Expected column name.",
        ).lexeme;
        _consume(TokenType.rParen, "Expected ')'.");
        partitionBy = PartitionByClause(strategy, colName);
      }

      if (_check(TokenType.semicolon)) _advance();
      return CreateTableStmt(
        tableName,
        columns,
        partitionBy: partitionBy,
        partitionOf: partitionOf,
        ifNotExists: ifNotExists,
      );
    } else if (_match([TokenType.relationship])) {
      final relNameToken = _consume(
        TokenType.identifier,
        "Expected relationship name.",
      );
      final relName = relNameToken.lexeme;

      _consume(TokenType.from, "Expected 'FROM' keyword.");
      final fromTableToken = _consume(
        TokenType.identifier,
        "Expected source table name.",
      );
      final fromTable = fromTableToken.lexeme;

      _consume(TokenType.to, "Expected 'TO' keyword.");
      final toTableToken = _consume(
        TokenType.identifier,
        "Expected destination table name.",
      );
      final toTable = toTableToken.lexeme;

      _consume(TokenType.on, "Expected 'ON' keyword.");
      final fromKeyToken = _consume(
        TokenType.identifier,
        "Expected source key column.",
      );
      final fromKey = fromKeyToken.lexeme;

      _consume(TokenType.equals, "Expected '='.");
      final toKeyToken = _consume(
        TokenType.identifier,
        "Expected destination key column.",
      );
      final toKey = toKeyToken.lexeme;

      if (_check(TokenType.semicolon)) _advance();

      return CreateRelationshipStmt(
        name: relName,
        fromTable: fromTable,
        toTable: toTable,
        fromKey: fromKey,
        toKey: toKey,
      );
    } else if (_match([TokenType.indexKeyword])) {
      if (_peek().lexeme.toLowerCase() == 'if') {
        _advance();
        if (_peek().lexeme.toLowerCase() == 'not') _advance();
        if (_peek().lexeme.toLowerCase() == 'exists') _advance();
      }
      final indexNameToken = _consume(
        TokenType.identifier,
        "Expected index name.",
      );
      final indexName = indexNameToken.lexeme;

      _consume(TokenType.on, "Expected 'ON' keyword.");

      final tableNameToken = _consume(
        TokenType.identifier,
        "Expected table name.",
      );
      final tableName = tableNameToken.lexeme;

      _consume(TokenType.lParen, "Expected '(' before column names.");
      final colNames = <String>[];
      do {
        final expr = _parseExpression();
        colNames.add(exprToSqlString(expr));
      } while (_match([TokenType.comma]));
      _consume(TokenType.rParen, "Expected ')' after column names.");
      final columnName = colNames.join(',');

      String? usingMethod;
      if (_match([TokenType.usingKeyword])) {
        usingMethod = _peek().lexeme.toLowerCase();
        _advance();
      }

      if (_check(TokenType.semicolon)) _advance();

      return CreateIndexStmt(
        indexName,
        tableName,
        columnName,
        usingMethod: usingMethod,
      );
    } else if (_match([TokenType.policyKeyword])) {
      final name = _consume(
        TokenType.identifier,
        "Expected policy name.",
      ).lexeme;
      _consume(TokenType.on, "Expected 'ON' keyword.");
      final tableName = _consume(
        TokenType.identifier,
        "Expected table name.",
      ).lexeme;
      _consume(TokenType.usingKeyword, "Expected 'USING' keyword.");
      _consume(TokenType.lParen, "Expected '(' before policy condition.");
      final condition = _parseExpression();
      _consume(TokenType.rParen, "Expected ')' after policy condition.");
      if (_check(TokenType.semicolon)) _advance();
      return CreatePolicyStmt(name, tableName, condition);
    }
    throw Exception(
      "Expected 'TABLE', 'RELATIONSHIP', 'INDEX', or 'POLICY' after 'CREATE'.",
    );
  }

  ColumnDef _parseColumnDef() {
    final colNameToken = _consume(
      TokenType.identifier,
      "Expected column name.",
    );
    final colType = _parseDataType();

    bool isPrimaryKey = false;
    bool isUnique = false;
    String? referencesTable;
    String? referencesColumn;
    bool onDeleteCascade = false;
    Expression? defaultValue;
    Expression? checkExpression;
    String? maskedWith;

    while (true) {
      if (_match([TokenType.primaryKeyword])) {
        _consume(TokenType.keyKeyword, "Expected 'KEY' after 'PRIMARY'.");
        isPrimaryKey = true;
      } else if (_match([TokenType.notKeyword])) {
        if (_match([TokenType.nullKeyword]) ||
            (_check(TokenType.identifier) &&
                _peek().lexeme.toLowerCase() == 'null')) {
          if (_check(TokenType.identifier)) _advance();
        }
      } else if (_match([TokenType.nullKeyword])) {
        // Optional NULL constraint
      } else if (_match([TokenType.uniqueKeyword])) {
        isUnique = true;
      } else if (_match([TokenType.referencesKeyword])) {
        final refTableToken = _consume(
          TokenType.identifier,
          "Expected referenced table name.",
        );
        referencesTable = refTableToken.lexeme;
        _consume(
          TokenType.lParen,
          "Expected '(' before referenced column name.",
        );
        final refColToken = _consume(
          TokenType.identifier,
          "Expected referenced column name.",
        );
        referencesColumn = refColToken.lexeme;
        _consume(
          TokenType.rParen,
          "Expected ')' after referenced column name.",
        );

        if (_match([TokenType.on])) {
          _consume(TokenType.deleteKeyword, "Expected 'DELETE' after 'ON'.");
          _consume(
            TokenType.cascadeKeyword,
            "Expected 'CASCADE' after 'ON DELETE'.",
          );
          onDeleteCascade = true;
        }
      } else if (_match([TokenType.defaultKeyword])) {
        defaultValue = _parseExpression();
      } else if (_match([TokenType.checkKeyword])) {
        _consume(TokenType.lParen, "Expected '(' after 'CHECK'.");
        checkExpression = _parseExpression();
        _consume(TokenType.rParen, "Expected ')' after CHECK expression.");
      } else if (_match([TokenType.maskedKeyword])) {
        _consume(TokenType.withKeyword, "Expected 'WITH' after 'MASKED'.");
        _consume(TokenType.lParen, "Expected '(' after 'MASKED WITH'.");
        _consume(
          TokenType.functionKeyword,
          "Expected 'FUNCTION' in MASKED WITH clause.",
        );
        _consume(TokenType.equals, "Expected '=' after 'FUNCTION'.");
        final funcNameToken = _consume(
          TokenType.stringLiteral,
          "Expected function name string.",
        );
        maskedWith = funcNameToken.lexeme;
        _consume(TokenType.rParen, "Expected ')' after MASKED WITH clause.");
      } else {
        break;
      }
    }

    return ColumnDef(
      colNameToken.lexeme,
      colType,
      isPrimaryKey: isPrimaryKey,
      isUnique: isUnique,
      referencesTable: referencesTable,
      referencesColumn: referencesColumn,
      onDeleteCascade: onDeleteCascade,
      defaultValue: defaultValue,
      checkExpression: checkExpression,
      maskedWith: maskedWith,
    );
  }

  Stmt _parseAlterTableStatement() {
    _consume(TokenType.table, "Expected 'TABLE' after 'ALTER'.");
    final tableNameToken = _consume(
      TokenType.identifier,
      "Expected table name.",
    );
    final tableName = tableNameToken.lexeme;

    if (_match([TokenType.addKeyword])) {
      final colDef = _parseColumnDef();
      if (_check(TokenType.semicolon)) _advance();
      return AlterTableStmt.add(tableName, colDef);
    } else if (_match([TokenType.dropKeyword])) {
      _consume(TokenType.columnKeyword, "Expected 'COLUMN' after 'DROP'.");
      final colNameToken = _consume(
        TokenType.identifier,
        "Expected column name to drop.",
      );
      if (_check(TokenType.semicolon)) _advance();
      return AlterTableStmt.drop(tableName, colNameToken.lexeme);
    } else if (_peek().lexeme.toLowerCase() == 'rename') {
      _advance(); // Consume 'rename'
      if (_check(TokenType.columnKeyword)) _advance();
      final oldCol = _consume(
        TokenType.identifier,
        "Expected old column name.",
      ).lexeme;
      _consume(TokenType.to, "Expected 'TO' after old column name.");
      final newCol = _consume(
        TokenType.identifier,
        "Expected new column name.",
      ).lexeme;
      if (_check(TokenType.semicolon)) _advance();
      return AlterTableStmt.renameColumn(tableName, oldCol, newCol);
    } else if (_peek().lexeme.toLowerCase() == 'alter') {
      _advance(); // Consume 'alter'
      if (_check(TokenType.columnKeyword)) _advance();
      final targetCol = _consume(
        TokenType.identifier,
        "Expected target column name.",
      ).lexeme;
      if (_peek().lexeme.toLowerCase() == 'type') _advance();
      final newType = _parseDataType();
      if (_check(TokenType.semicolon)) _advance();
      return AlterTableStmt.alterColumnType(tableName, targetCol, newType);
    } else {
      throw Exception(
        "Expected 'ADD', 'DROP', 'RENAME', or 'ALTER' in ALTER TABLE statement.",
      );
    }
  }

  Stmt _parseInsertStatement({bool isReplace = false}) {
    _consume(TokenType.into, "Expected 'INTO' keyword.");
    final tableNameToken = _consume(
      TokenType.identifier,
      "Expected table name.",
    );
    final tableName = tableNameToken.lexeme;

    List<String>? targetColumns;
    if (_match([TokenType.lParen])) {
      targetColumns = [];
      do {
        final colToken = _consume(
          TokenType.identifier,
          "Expected column name.",
        );
        targetColumns.add(colToken.lexeme);
      } while (_match([TokenType.comma]));
      _consume(TokenType.rParen, "Expected ')' after column list.");
    }

    _consume(TokenType.valuesKeyword, "Expected 'VALUES' keyword.");

    List<List<Expression>> multiValues = [];
    do {
      _consume(TokenType.lParen, "Expected '(' to list values.");
      List<Expression> row = [];
      do {
        row.add(_parseExpression());
      } while (_match([TokenType.comma]));
      _consume(TokenType.rParen, "Expected ')' to close values list.");
      multiValues.add(row);
    } while (_match([TokenType.comma]));

    List<Expression> values = multiValues.first;

    bool onConflictDoNothing = false;
    String? conflictTargetColumn;
    Map<String, Expression>? updateAssignments;

    if (_match([TokenType.on])) {
      _consume(TokenType.conflictKeyword, "Expected 'CONFLICT' after ON.");
      if (_match([TokenType.lParen])) {
        final targetColToken = _consume(
          TokenType.identifier,
          "Expected conflict target column name.",
        );
        conflictTargetColumn = targetColToken.lexeme;
        _consume(
          TokenType.rParen,
          "Expected ')' after conflict target column.",
        );
      }
      _consume(TokenType.doKeyword, "Expected 'DO' after ON CONFLICT.");
      if (_match([TokenType.nothingKeyword])) {
        onConflictDoNothing = true;
      } else if (_check(TokenType.identifier) &&
          _peek().lexeme.toLowerCase() == 'update') {
        _advance();
        _consume(TokenType.setKeyword, "Expected 'SET' after DO UPDATE.");
        updateAssignments = {};
        do {
          final colToken = _consume(
            TokenType.identifier,
            "Expected column name in SET clause.",
          );
          _consume(TokenType.assign, "Expected '=' in SET clause.");
          final expr = _parseExpression();
          updateAssignments[colToken.lexeme] = expr;
        } while (_match([TokenType.comma]));
      }
    }

    // Optional trailing semicolon
    if (_check(TokenType.semicolon)) _advance();

    return InsertStmt(
      tableName,
      values,
      targetColumns,
      isReplace,
      onConflictDoNothing,
      conflictTargetColumn,
      updateAssignments,
      multiValues.length > 1 ? multiValues : null,
    );
  }

  Stmt _parseSelectStatement() {
    bool isDistinct = false;
    if (_match([TokenType.distinct])) {
      isDistinct = true;
    } else if (_check(TokenType.identifier) &&
        _peek().lexeme.toLowerCase() == 'distinct') {
      _advance();
      isDistinct = true;
    }

    List<Projection> projections = [];

    if (_match([TokenType.asterisk])) {
      projections.add(Projection(VariableExpr(['*']), null));
    } else {
      do {
        final expr = _parseExpression();
        String? alias;
        if (_match([TokenType.as])) {
          alias = _consume(
            TokenType.identifier,
            "Expected alias identifier.",
          ).lexeme;
        } else if (_check(TokenType.identifier)) {
          // Implicit AS alias
          alias = _advance().lexeme;
        }
        projections.add(Projection(expr, alias));
      } while (_match([TokenType.comma]));
    }

    String tableName = '';
    SelectStmt? fromSubquery;
    FunctionCallExpr? fromFunction;
    if (_match([TokenType.from])) {
      if (_check(TokenType.lParen) &&
          (_peekNext().type == TokenType.select ||
              _peekNext().type == TokenType.withKeyword)) {
        _consume(TokenType.lParen, "Expected '(' before FROM subquery.");
        final stmt = _parsePlSqlStatement();
        _consume(TokenType.rParen, "Expected ')' after FROM subquery.");
        if (stmt is SelectStmt) {
          fromSubquery = stmt;
        } else {
          throw Exception("Expected SelectStmt inside FROM subquery.");
        }
      } else if ((_check(TokenType.identifier) || _check(TokenType.generate)) &&
          _peekNext().type == TokenType.lParen) {
        final funcNameToken = _advance();
        final funcName = funcNameToken.lexeme;
        _consume(TokenType.lParen, "Expected '(' after function name.");
        final args = <Expression>[];
        if (!_check(TokenType.rParen)) {
          do {
            args.add(_parseExpression());
          } while (_match([TokenType.comma]));
        }
        _consume(TokenType.rParen, "Expected ')' after function arguments.");
        fromFunction = FunctionCallExpr(funcName, args);
        tableName = funcName;
      } else {
        final parts = <String>[];
        do {
          if (_match([
            TokenType.identifier,
            TokenType.tablesKeyword,
            TokenType.columnsKeyword,
            TokenType.schemasKeyword,
            TokenType.systemKeyword,
            TokenType.generate,
          ])) {
            parts.add(_previous().lexeme);
          } else if (_check(TokenType.identifier)) {
            parts.add(_advance().lexeme);
          } else {
            throw Exception("Expected source table name.");
          }
        } while (_match([TokenType.dot]));
        tableName = parts.join('.');
      }
    }

    String? tableAlias;
    if (_check(TokenType.as) && _peekNext().type != TokenType.ofKeyword) {
      _advance();
      tableAlias = _consume(
        TokenType.identifier,
        "Expected table alias.",
      ).lexeme;
    } else if (_peek().type == TokenType.identifier &&
        _peek().lexeme.toLowerCase() != 'left' &&
        _peek().lexeme.toLowerCase() != 'right' &&
        _peek().lexeme.toLowerCase() != 'full' &&
        _peek().lexeme.toLowerCase() != 'outer' &&
        ![
          TokenType.join,
          TokenType.where,
          TokenType.groupKeyword,
          TokenType.orderBy,
          TokenType.limit,
          TokenType.withKeyword,
          TokenType.semicolon,
          TokenType.eof,
        ].contains(_peek().type)) {
      tableAlias = _advance().lexeme;
    }

    AsOfClause? asOfClause;
    if (_match([TokenType.as])) {
      _consume(TokenType.ofKeyword, "Expected 'OF' after 'AS'.");
      if (_match([TokenType.systemKeyword])) {
        _consume(
          TokenType.timeKeyword,
          "Expected TIME after SYSTEM in AS OF SYSTEM TIME.",
        );
        final expr = _parseExpression();
        asOfClause = AsOfClause(true, expr);
      } else if (_match([TokenType.transactionKeyword])) {
        final expr = _parseExpression();
        asOfClause = AsOfClause(false, expr);
      } else {
        throw Exception("Expected SYSTEM TIME or TRANSACTION after AS OF.");
      }
    }

    if (fromSubquery != null && tableName.isEmpty) {
      tableName = tableAlias ?? 'subquery';
    }

    final joins = <Join>[];
    while (true) {
      bool isLeftJoin = false;
      bool isRightJoin = false;
      bool isFullJoin = false;
      bool hasJoin = false;

      bool isCrossJoin = false;
      if (_check(TokenType.identifier) &&
          _peek().lexeme.toLowerCase() == 'inner') {
        _advance();
        _consume(TokenType.join, "Expected 'JOIN' after 'INNER'.");
        hasJoin = true;
      } else if (_check(TokenType.identifier) &&
          _peek().lexeme.toLowerCase() == 'cross') {
        _advance();
        _consume(TokenType.join, "Expected 'JOIN' after 'CROSS'.");
        hasJoin = true;
        isCrossJoin = true;
      } else if (_check(TokenType.identifier) &&
          _peek().lexeme.toLowerCase() == 'left') {
        _advance();
        isLeftJoin = true;
        if (_check(TokenType.identifier) &&
            _peek().lexeme.toLowerCase() == 'outer') {
          _advance();
        }
        _consume(TokenType.join, "Expected 'JOIN' after 'LEFT [OUTER]'.");
        hasJoin = true;
      } else if (_check(TokenType.identifier) &&
          _peek().lexeme.toLowerCase() == 'right') {
        _advance();
        isRightJoin = true;
        if (_check(TokenType.identifier) &&
            _peek().lexeme.toLowerCase() == 'outer') {
          _advance();
        }
        _consume(TokenType.join, "Expected 'JOIN' after 'RIGHT [OUTER]'.");
        hasJoin = true;
      } else if (_check(TokenType.identifier) &&
          _peek().lexeme.toLowerCase() == 'full') {
        _advance();
        isFullJoin = true;
        if (_check(TokenType.identifier) &&
            _peek().lexeme.toLowerCase() == 'outer') {
          _advance();
        }
        _consume(TokenType.join, "Expected 'JOIN' after 'FULL [OUTER]'.");
        hasJoin = true;
      } else if (_match([TokenType.join])) {
        hasJoin = true;
      }

      if (!hasJoin) {
        break;
      }

      String joinTable = '';
      SelectStmt? joinSubquery;
      if (_check(TokenType.lParen) &&
          (_peekNext().type == TokenType.select ||
              _peekNext().type == TokenType.withKeyword)) {
        _consume(TokenType.lParen, "Expected '(' before JOIN subquery.");
        final stmt = _parsePlSqlStatement();
        _consume(TokenType.rParen, "Expected ')' after JOIN subquery.");
        if (stmt is SelectStmt) {
          joinSubquery = stmt;
        } else {
          throw Exception("Expected SelectStmt inside JOIN subquery.");
        }
      } else {
        final joinTableToken = _consume(
          TokenType.identifier,
          "Expected table to join.",
        );
        joinTable = joinTableToken.lexeme;
      }

      String? joinAlias;
      if (_match([TokenType.as])) {
        joinAlias = _consume(
          TokenType.identifier,
          "Expected table alias.",
        ).lexeme;
      } else if (_peek().type == TokenType.identifier &&
          _peek().lexeme.toLowerCase() != 'left' &&
          _peek().lexeme.toLowerCase() != 'right' &&
          _peek().lexeme.toLowerCase() != 'full' &&
          _peek().lexeme.toLowerCase() != 'outer' &&
          _peek().lexeme.toLowerCase() != 'inner' &&
          _peek().lexeme.toLowerCase() != 'cross' &&
          ![
            TokenType.on,
            TokenType.join,
            TokenType.where,
            TokenType.groupKeyword,
            TokenType.orderBy,
            TokenType.limit,
            TokenType.withKeyword,
            TokenType.semicolon,
            TokenType.eof,
          ].contains(_peek().type)) {
        joinAlias = _advance().lexeme;
      }

      if (joinSubquery != null && joinTable.isEmpty) {
        joinTable = joinAlias ?? 'join_subquery';
      }

      Expression onCond;
      if (isCrossJoin && !_match([TokenType.on])) {
        onCond = LiteralExpr(1);
      } else {
        _consume(TokenType.on, "Expected 'ON' condition for JOIN.");
        onCond = _parseExpression();
      }

      joins.add(
        Join(
          joinTable,
          onCond,
          fromSubquery: joinSubquery,
          alias: joinAlias,
          isLeftJoin: isLeftJoin,
          isRightJoin: isRightJoin,
          isFullJoin: isFullJoin,
        ),
      );
    }

    Expression? whereCondition;
    if (_match([TokenType.where])) {
      whereCondition = _parseExpression();
    }

    Expression? groupBy;
    if (_match([TokenType.groupKeyword])) {
      _consume(TokenType.by, "Expected 'BY' after 'GROUP'.");

      if (_match([TokenType.rollupKeyword])) {
        _consume(TokenType.lParen, "Expected '(' after ROLLUP.");
        List<Expression> args = [];
        do {
          args.add(_parseExpression());
        } while (_match([TokenType.comma]));
        _consume(TokenType.rParen, "Expected ')' after ROLLUP.");
        groupBy = RollupExpr(args);
      } else if (_match([TokenType.cubeKeyword])) {
        _consume(TokenType.lParen, "Expected '(' after CUBE.");
        List<Expression> args = [];
        do {
          args.add(_parseExpression());
        } while (_match([TokenType.comma]));
        _consume(TokenType.rParen, "Expected ')' after CUBE.");
        groupBy = CubeExpr(args);
      } else if (_match([TokenType.groupingKeyword])) {
        _consume(TokenType.setsKeyword, "Expected 'SETS' after 'GROUPING'.");
        _consume(TokenType.lParen, "Expected '(' after GROUPING SETS.");
        List<List<Expression>> sets = [];
        do {
          _consume(TokenType.lParen, "Expected '(' for a grouping set.");
          List<Expression> args = [];
          if (!_check(TokenType.rParen)) {
            do {
              args.add(_parseExpression());
            } while (_match([TokenType.comma]));
          }
          _consume(TokenType.rParen, "Expected ')' to close a grouping set.");
          sets.add(args);
        } while (_match([TokenType.comma]));
        _consume(TokenType.rParen, "Expected ')' after GROUPING SETS.");
        groupBy = GroupingSetsExpr(sets);
      } else {
        // Normal GROUP BY
        List<Expression> args = [];
        do {
          args.add(_parseExpression());
        } while (_match([TokenType.comma]));
        if (args.length == 1) {
          groupBy = args[0];
        } else {
          groupBy = GroupingSetsExpr([args]);
        }
      }
    }

    Expression? havingCondition;
    if (_match([TokenType.havingKeyword])) {
      havingCondition = _parseExpression();
    }

    OrderBy? orderBy;
    if (_match([TokenType.orderBy])) {
      _consume(TokenType.by, "Expected 'BY' after 'ORDER'.");
      final expr = _parseExpression();
      bool ascending = true;
      if (_match([TokenType.asc])) {
        ascending = true;
      } else if (_match([TokenType.desc])) {
        ascending = false;
      }
      orderBy = OrderBy(expr, ascending);
    }

    int? limit;
    int? offset;
    if (_match([TokenType.limit])) {
      final limitToken = _consume(
        TokenType.numberLiteral,
        "Expected numeric limit.",
      );
      limit = int.tryParse(limitToken.lexeme);

      if (_match([TokenType.offset]) ||
          (_check(TokenType.identifier) &&
              _peek().lexeme.toLowerCase() == 'offset')) {
        if (_peek().lexeme.toLowerCase() == 'offset') {
          _advance();
        }
        final offsetToken = _consume(
          TokenType.numberLiteral,
          "Expected numeric offset.",
        );
        offset = int.tryParse(offsetToken.lexeme);
      }
    }

    String? withRelationship;
    if (_match([TokenType.withKeyword])) {
      _consume(TokenType.relationship, "Expected 'RELATIONSHIP' after 'WITH'.");
      final relNameToken = _consume(
        TokenType.identifier,
        "Expected relationship name.",
      );
      withRelationship = relNameToken.lexeme;
    }

    if (_check(TokenType.semicolon)) _advance();

    return SelectStmt(
      projections: projections,
      tableName: tableName,
      fromSubquery: fromSubquery,
      fromFunction: fromFunction,
      tableAlias: tableAlias,
      joins: joins,
      whereCondition: whereCondition,
      groupBy: groupBy,
      havingCondition: havingCondition,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
      withRelationship: withRelationship,
      isDistinct: isDistinct,
      asOfClause: asOfClause,
    );
  }

  // Expression Parsing (Operator Precedence)
  Expression _parseExpression() {
    return _parseOr();
  }

  Expression _parseOr() {
    var expr = _parseAnd();
    while (_match([TokenType.orKeyword])) {
      final operatorToken = _previous();
      final right = _parseAnd();
      expr = BinaryExpr(operatorToken.lexeme, expr, right);
    }
    return expr;
  }

  Expression _parseAnd() {
    var expr = _parseComparison();
    while (_match([TokenType.andKeyword])) {
      final operatorToken = _previous();
      final right = _parseComparison();
      expr = BinaryExpr(operatorToken.lexeme, expr, right);
    }
    return expr;
  }

  Expression _parseComparison() {
    var expr = _parseAdditive();

    if (_match([TokenType.betweenKeyword])) {
      final low = _parseAdditive();
      _consume(
        TokenType.andKeyword,
        "Expected 'AND' after BETWEEN lower bound.",
      );
      final high = _parseAdditive();
      return BinaryExpr(
        'AND',
        BinaryExpr('>=', expr, low),
        BinaryExpr('<=', expr, high),
      );
    }

    if (_match([TokenType.inKeyword])) {
      _consume(TokenType.lParen, "Expected '(' after IN");
      Expression right;
      if (_check(TokenType.select) || _check(TokenType.withKeyword)) {
        final stmt = _parsePlSqlStatement();
        _consume(TokenType.rParen, "Expected ')' after subquery.");
        if (stmt is SelectStmt) {
          right = SubqueryExpr(stmt);
        } else {
          throw Exception("Expected SelectStmt inside subquery.");
        }
      } else {
        final exprs = <Expression>[];
        do {
          exprs.add(_parseExpression());
        } while (_match([TokenType.comma]));
        _consume(TokenType.rParen, "Expected ')' after IN list.");
        right = FunctionCallExpr('in_list', exprs);
      }
      return BinaryExpr('IN', expr, right);
    }

    while (_match([
      TokenType.equals,
      TokenType.notEquals,
      TokenType.lessThan,
      TokenType.lessThanOrEquals,
      TokenType.greaterThan,
      TokenType.greaterThanOrEquals,
      TokenType.likeKeyword,
      TokenType.ilikeKeyword,
      TokenType.tilde,
    ])) {
      final operatorToken = _previous();
      final right = _parseAdditive();
      expr = BinaryExpr(operatorToken.lexeme, expr, right);
    }

    return expr;
  }

  Expression _parseAdditive() {
    var expr = _parseMultiplicative();

    while (_match([TokenType.plus, TokenType.minus, TokenType.concat])) {
      final operatorToken = _previous();
      final right = _parseMultiplicative();
      expr = BinaryExpr(operatorToken.lexeme, expr, right);
    }

    return expr;
  }

  Expression _parseMultiplicative() {
    var expr = _parsePrimary();

    while (_match([TokenType.asterisk, TokenType.slash, TokenType.modulo])) {
      final operatorToken = _previous();
      final right = _parsePrimary();
      expr = BinaryExpr(operatorToken.lexeme, expr, right);
    }

    return expr;
  }

  Expression _parsePrimary() {
    Expression expr;
    if (_match([TokenType.placeholder])) {
      final lex = _previous().lexeme;
      if (lex == '?') {
        final idx = _placeholderCount++;
        expr = PlaceholderExpr(lex, idx);
      } else if (lex.startsWith('\$')) {
        final idx = int.parse(lex.substring(1)) - 1;
        expr = PlaceholderExpr(lex, idx);
      } else {
        throw Exception("Unknown placeholder format: $lex");
      }
    } else if (_match([TokenType.minus])) {
      final right = _parsePrimary();
      if (right is LiteralExpr && right.value is num) {
        expr = LiteralExpr(-(right.value as num));
      } else {
        expr = BinaryExpr('-', LiteralExpr(0), right);
      }
    } else if (_match([TokenType.trueKeyword])) {
      expr = LiteralExpr(true);
    } else if (_match([TokenType.falseKeyword])) {
      expr = LiteralExpr(false);
    } else if (_match([TokenType.nullKeyword])) {
      expr = LiteralExpr(null);
    } else if (_match([TokenType.numberLiteral])) {
      final lex = _previous().lexeme;
      final val = num.parse(lex);
      expr = LiteralExpr(val);
    } else if (_match([TokenType.stringLiteral])) {
      var lex = _previous().lexeme;
      if (lex.length >= 2 &&
          ((lex.startsWith("'") && lex.endsWith("'")) ||
              (lex.startsWith('"') && lex.endsWith('"')))) {
        lex = lex.substring(1, lex.length - 1);
      }
      expr = LiteralExpr(lex);
    } else if (_match([TokenType.lBracket])) {
      final elements = <double>[];
      if (!_check(TokenType.rBracket)) {
        do {
          final sign = _match([TokenType.minus]) ? -1.0 : 1.0;
          final numToken = _consume(
            TokenType.numberLiteral,
            "Expected vector element double.",
          );
          elements.add(sign * double.parse(numToken.lexeme));
        } while (_match([TokenType.comma]));
      }
      _consume(TokenType.rBracket, "Expected ']' to close vector literal.");
      expr = VectorLiteralExpr(elements);
    } else if (_match([TokenType.castKeyword])) {
      _consume(TokenType.lParen, "Expected '(' after CAST.");
      final innerExpr = _parseExpression();
      _consume(TokenType.as, "Expected 'AS' inside CAST.");
      final targetType = _parseDataType();
      _consume(TokenType.rParen, "Expected ')' to close CAST.");
      expr = CastExpr(innerExpr, targetType);
    } else if (_match([
      TokenType.identifier,
      TokenType.matchKeyword,
      TokenType.timeKeyword,
      TokenType.generate,
      TokenType.typeInt,
      TokenType.typeDouble,
      TokenType.typeText,
      TokenType.typeVector,
      TokenType.typeJson,
      TokenType.typeBool,
      TokenType.typeUuid,
      TokenType.typeDateTime,
      TokenType.typeBlob,
      TokenType.typeDecimal,
      TokenType.replaceKeyword,
    ])) {
      final firstId = _previous().lexeme;
      if (firstId.toLowerCase() == 'match' ||
          firstId.toLowerCase() == 'contains') {
        _consume(TokenType.lParen, "Expected '(' after MATCH.");
        final colExpr = _parseExpression();
        _consume(TokenType.comma, "Expected ',' after column name in MATCH.");
        final queryExpr = _parseExpression();
        _consume(TokenType.rParen, "Expected ')' after search query in MATCH.");
        final colName = exprToSqlString(colExpr);
        final searchQuery = (queryExpr is LiteralExpr)
            ? queryExpr.value.toString()
            : exprToSqlString(queryExpr);
        expr = MatchExpr(colName, searchQuery);
      } else if (firstId.toLowerCase() == 'case') {
        final whenBranches = <WhenBranch>[];
        Expression? elseBranch;
        while (_check(TokenType.whenKeyword) ||
            (_check(TokenType.identifier) &&
                _peek().lexeme.toLowerCase() == 'when')) {
          _advance();
          final cond = _parseExpression();
          _consume(TokenType.then, "Expected 'THEN' after WHEN condition.");
          final thenExpr = _parseExpression();
          whenBranches.add(WhenBranch(cond, thenExpr));
        }
        if (_match([TokenType.elseKeyword])) {
          elseBranch = _parseExpression();
        } else if (_check(TokenType.identifier) &&
            _peek().lexeme.toLowerCase() == 'else') {
          _advance();
          elseBranch = _parseExpression();
        }
        _consume(TokenType.end, "Expected 'END' to close CASE expression.");
        expr = CaseExpr(whenBranches, elseBranch);
      } else if (firstId.toLowerCase() == 'cast') {
        _consume(TokenType.lParen, "Expected '(' after CAST.");
        final innerExpr = _parseExpression();
        _consume(TokenType.as, "Expected 'AS' inside CAST.");
        final targetType = _parseDataType();
        _consume(TokenType.rParen, "Expected ')' to close CAST.");
        expr = CastExpr(innerExpr, targetType);
      } else if (_check(TokenType.lParen)) {
        _advance(); // consume '('
        List<Expression> arguments = [];
        if (_check(TokenType.asterisk)) {
          _advance(); // consume '*'
          arguments.add(VariableExpr(['*']));
        } else if (!_check(TokenType.rParen)) {
          do {
            arguments.add(_parseExpression());
          } while (_match([TokenType.comma]));
        }
        _consume(TokenType.rParen, "Expected ')' after function arguments.");
        if (_match([TokenType.over])) {
          _consume(TokenType.lParen, "Expected '(' after OVER.");
          List<Expression> partitionBy = [];
          if (_match([TokenType.partition])) {
            _consume(TokenType.by, "Expected 'BY' after PARTITION.");
            do {
              partitionBy.add(_parseExpression());
            } while (_match([TokenType.comma]));
          }
          OrderBy? orderBy;
          if (_match([TokenType.orderBy])) {
            _consume(TokenType.by, "Expected 'BY' after ORDER.");
            final orderExpr = _parseExpression();
            bool ascending = true;
            if (_match([TokenType.asc])) {
              ascending = true;
            } else if (_match([TokenType.desc])) {
              ascending = false;
            }
            orderBy = OrderBy(orderExpr, ascending);
          }
          _consume(TokenType.rParen, "Expected ')' to close OVER clause.");
          expr = WindowFunctionExpr(
            functionName: firstId,
            arguments: arguments,
            partitionBy: partitionBy,
            orderBy: orderBy,
          );
        } else {
          expr = FunctionCallExpr(firstId, arguments);
        }
      } else {
        // Check for dotted path notation: table.column or column.json_path
        final path = [firstId];
        while (_match([TokenType.dot])) {
          final segmentToken = _consume(
            TokenType.identifier,
            "Expected identifier after dot.",
          );
          path.add(segmentToken.lexeme);
        }
        expr = VariableExpr(path);
      }
    } else if (_check(TokenType.lParen) &&
        (_peekNext().type == TokenType.select ||
            _peekNext().type == TokenType.withKeyword)) {
      _consume(TokenType.lParen, "Expected '(' before subquery.");
      final stmt = _parsePlSqlStatement();
      _consume(TokenType.rParen, "Expected ')' after subquery.");
      if (stmt is SelectStmt) {
        expr = SubqueryExpr(stmt);
      } else {
        throw Exception("Expected SelectStmt inside subquery.");
      }
    } else if (_match([TokenType.lParen])) {
      final innerExpr = _parseExpression();
      _consume(TokenType.rParen, "Expected ')' after expression.");
      expr = innerExpr;
    } else {
      throw Exception("Unexpected token '${_peek().lexeme}' in expression.");
    }

    // Parse postfix operators (arrow, arrowText, doubleColon)
    while (true) {
      if (_check(TokenType.arrow)) {
        _advance();
        final pathToken = _consume(
          TokenType.stringLiteral,
          "Expected string literal path after JSON operator '->'.",
        );
        expr = JsonExtractExpr(expr, pathToken.lexeme, false);
      } else if (_check(TokenType.arrowText)) {
        _advance();
        final pathToken = _consume(
          TokenType.stringLiteral,
          "Expected string literal path after JSON operator '->>'.",
        );
        expr = JsonExtractExpr(expr, pathToken.lexeme, true);
      } else if (_match([TokenType.doubleColon])) {
        final targetType = _parseDataType();
        expr = CastExpr(expr, targetType);
      } else {
        break;
      }
    }

    return expr;
  }

  List<Parameter> _parseParameters() {
    final params = <Parameter>[];
    if (_match([TokenType.lParen])) {
      if (!_check(TokenType.rParen)) {
        do {
          final nameToken = _consume(
            TokenType.identifier,
            "Expected parameter name.",
          );
          final dataType = _parseDataType();
          params.add(Parameter(nameToken.lexeme, dataType));
        } while (_match([TokenType.comma]));
      }
      _consume(TokenType.rParen, "Expected ')' after parameter list.");
    }
    return params;
  }

  Stmt _parseReturnStatement() {
    _consume(TokenType.returnKeyword, "Expected 'RETURN'.");
    final expr = _parseExpression();
    _consume(TokenType.semicolon, "Expected ';' after return statement.");
    return ReturnStmt(expr);
  }

  Stmt _parseCallStatement() {
    final nameToken = _consume(
      TokenType.identifier,
      "Expected procedure name in CALL statement.",
    );
    final name = nameToken.lexeme;

    _consume(TokenType.lParen, "Expected '(' for CALL argument list.");
    final args = <Expression>[];
    if (!_check(TokenType.rParen)) {
      do {
        args.add(_parseExpression());
      } while (_match([TokenType.comma]));
    }
    _consume(TokenType.rParen, "Expected ')' after CALL argument list.");
    if (_check(TokenType.semicolon)) _advance();
    return CallStmt(name, args);
  }

  Stmt _parseCteStatement() {
    bool isRecursive = false;
    if (_match([TokenType.recursiveKeyword])) {
      isRecursive = true;
    }
    final ctes = <String, dynamic>{};
    do {
      final cteNameToken = _consume(TokenType.identifier, "Expected CTE name.");
      final cteName = cteNameToken.lexeme.toLowerCase();
      if (_match([TokenType.lParen])) {
        do {
          _consume(
            TokenType.identifier,
            "Expected column name in CTE parameter list.",
          );
        } while (_match([TokenType.comma]));
        _consume(TokenType.rParen, "Expected ')' after CTE column names.");
      }
      _consume(TokenType.as, "Expected 'AS' after CTE name.");
      _consume(TokenType.lParen, "Expected '(' before CTE query.");
      _consume(TokenType.select, "Expected 'SELECT' inside CTE query.");
      final cteQuery = _parseSelectOrUnionStatement();
      _consume(TokenType.rParen, "Expected ')' after CTE query.");
      ctes[cteName] = cteQuery;
    } while (_match([TokenType.comma]));

    _consume(TokenType.select, "Expected 'SELECT' after CTE definition.");
    final mainSelect = _parseSelectStatement() as SelectStmt;

    return CteSelectStmt(
      ctes: ctes,
      mainSelect: mainSelect,
      isRecursive: isRecursive,
    );
  }

  Stmt _parseSelectOrUnionStatement() {
    final firstSelect = _parseSelectStatement() as SelectStmt;
    if (_peek().type == TokenType.union) {
      final selectStmts = <SelectStmt>[firstSelect];
      final isAllFlags = <bool>[];
      while (_match([TokenType.union])) {
        bool isAll = false;
        if (_match([TokenType.all])) {
          isAll = true;
        }
        _consume(TokenType.select, "Expected 'SELECT' after 'UNION'.");
        final nextSelect = _parseSelectStatement() as SelectStmt;
        selectStmts.add(nextSelect);
        isAllFlags.add(isAll);
      }
      return UnionStmt(selectStmts, isAllFlags);
    }
    if (_peek().type == TokenType.intersect) {
      final selectStmts = <SelectStmt>[firstSelect];
      while (_match([TokenType.intersect])) {
        _consume(TokenType.select, "Expected 'SELECT' after 'INTERSECT'.");
        final nextSelect = _parseSelectStatement() as SelectStmt;
        selectStmts.add(nextSelect);
      }
      return IntersectStmt(selectStmts);
    }
    if (_peek().type == TokenType.except) {
      final selectStmts = <SelectStmt>[firstSelect];
      while (_match([TokenType.except])) {
        _consume(TokenType.select, "Expected 'SELECT' after 'EXCEPT'.");
        final nextSelect = _parseSelectStatement() as SelectStmt;
        selectStmts.add(nextSelect);
      }
      return ExceptStmt(selectStmts);
    }
    return firstSelect;
  }
}
