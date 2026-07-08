import 'ast.dart';
import 'token.dart';

class Parser {
  final List<Token> tokens;
  int _current = 0;
  int _placeholderCount = 0;

  Parser(this.tokens);

  bool get _isAtEnd => _peek().type == TokenType.eof;

  Token _peek() => tokens[_current];

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

  bool _checkNextIsTransaction() {
    if (_current + 1 >= tokens.length) return false;
    final nextType = tokens[_current + 1].type;
    final nextLexeme = tokens[_current + 1].lexeme.toLowerCase();
    return nextType == TokenType.semicolon || nextLexeme == 'transaction';
  }

  bool _checkNextIsDataType() {
    if (_current + 1 >= tokens.length) return false;
    final nextType = tokens[_current + 1].type;
    return nextType == TokenType.typeInt ||
        nextType == TokenType.typeDouble ||
        nextType == TokenType.typeText ||
        nextType == TokenType.typeVector ||
        nextType == TokenType.typeJson;
  }

  List<Stmt> parseScript() {
    final list = <Stmt>[];
    while (!_isAtEnd) {
      if (_check(TokenType.declare) || (_check(TokenType.begin) && _checkNextIsTransaction())) {
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
    if (_match([TokenType.declare])) {
      while (_check(TokenType.identifier) && _checkNextIsDataType() && !_isAtEnd) {
        declarations.add(_parseDeclaration());
      }
    }

    if (_check(TokenType.begin)) {
      _consume(TokenType.begin, "Expected 'BEGIN' to start executable block.");
      List<Stmt> body = [];
      while (!_check(TokenType.end) && !_isAtEnd) {
        body.add(_parsePlSqlStatement());
      }
      _consume(TokenType.end, "Expected 'END' to close block.");
      _consume(TokenType.semicolon, "Expected ';' after 'END'.");
      return PlSqlBlock(declarations, body);
    } else {
      // T-SQL style top-level declarations
      return PlSqlBlock(declarations, []);
    }
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
    if (_match([TokenType.typeInt])) return DataType.integer;
    if (_match([TokenType.typeDouble])) return DataType.double;
    if (_match([TokenType.typeText])) return DataType.text;
    if (_match([TokenType.typeVector])) return DataType.vector;
    if (_match([TokenType.typeJson])) return DataType.json;
    throw Exception("Unsupported or missing variable type at '${_peek().lexeme}'.");
  }

  Stmt _parsePlSqlStatement() {
    if (_check(TokenType.ifKeyword)) {
      return _parseIfStatement();
    }
    if (_check(TokenType.whileKeyword)) {
      return _parseWhileStatement();
    }
    if (_check(TokenType.identifier)) {
      final id = _peek().lexeme.toLowerCase();
      if (id == 'update') {
        // Fall through to standard SQL statement
      } else {
        if (id == 'dbms_output') {
          return _parseDbmsOutputStatement();
        }
        if (id == 'set') {
          _advance(); // Consume 'set'
        }
        return _parseAssignmentStatement();
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
    while (!_check(TokenType.elsif) && !_check(TokenType.elseKeyword) && !_check(TokenType.end) && !_isAtEnd) {
      thenBranch.add(_parsePlSqlStatement());
    }

    List<ElsifBranch> elsifBranches = [];
    while (_match([TokenType.elsif])) {
      final elsifCondition = _parseExpression();
      _consume(TokenType.then, "Expected 'THEN' after ELSIF condition.");
      List<Stmt> elsifBody = [];
      while (!_check(TokenType.elsif) && !_check(TokenType.elseKeyword) && !_check(TokenType.end) && !_isAtEnd) {
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
      _consume(TokenType.loop, "Expected 'LOOP' or 'BEGIN' after WHILE condition.");
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

  Stmt _parseAssignmentStatement() {
    final varNameToken = _consume(TokenType.identifier, "Expected variable name.");
    final varName = varNameToken.lexeme;
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
      throw Exception("Expected 'PUT_LINE' call, found '${putLineToken.lexeme}'.");
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
      final tableName = _consume(TokenType.identifier, "Expected table name to analyze.").lexeme;
      if (_check(TokenType.semicolon)) _advance();
      return AnalyzeStmt(tableName);
    }
    if (_match([TokenType.create])) {
      return _parseCreateStatement();
    }
    if (_match([TokenType.insert])) {
      return _parseInsertStatement();
    }
    if (_match([TokenType.select])) {
      return _parseSelectStatement();
    }
    if (_match([TokenType.deleteKeyword])) {
      _consume(TokenType.from, "Expected 'FROM' after 'DELETE'.");
      final tableName = _consume(TokenType.identifier, "Expected table name.").lexeme;
      Expression? whereCondition;
      if (_match([TokenType.where])) {
        whereCondition = _parseExpression();
      }
      if (_check(TokenType.semicolon)) _advance();
      return DeleteStmt(tableName, whereCondition);
    }
    if (_check(TokenType.identifier) && _peek().lexeme.toLowerCase() == 'update') {
      _advance(); // Consume 'update'
      final tableName = _consume(TokenType.identifier, "Expected table name.").lexeme;
      
      final setToken = _consume(TokenType.identifier, "Expected 'SET' keyword.");
      if (setToken.lexeme.toLowerCase() != 'set') {
        throw Exception("Expected 'SET' keyword after table name in UPDATE statement.");
      }
      
      final colName = _consume(TokenType.identifier, "Expected column name to update.").lexeme;
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
      if (_check(TokenType.semicolon)) _advance();
      return CommitTxStmt();
    }
    if (_match([TokenType.rollback])) {
      if (_check(TokenType.semicolon)) _advance();
      return RollbackTxStmt();
    }
    if (_match([TokenType.showKeyword])) {
      return _parseShowStatement();
    }
    throw Exception("Unsupported statement beginning with '${_peek().lexeme}'.");
  }

  Stmt _parseShowStatement() {
    if (_match([TokenType.tablesKeyword])) {
      if (_check(TokenType.semicolon)) _advance();
      return ShowTablesStmt();
    } else if (_match([TokenType.indexesKeyword])) {
      String? tableName;
      if (_match([TokenType.from])) {
        final tableNameToken = _consume(TokenType.identifier, "Expected table name.");
        tableName = tableNameToken.lexeme;
      }
      if (_check(TokenType.semicolon)) _advance();
      return ShowIndexesStmt(tableName: tableName);
    }
    throw Exception("Expected 'TABLES' or 'INDEXES' after 'SHOW'.");
  }

  Stmt _parseCreateStatement() {
    if (_match([TokenType.table])) {
      final tableNameToken = _consume(TokenType.identifier, "Expected table name.");
      final tableName = tableNameToken.lexeme;
      
      _consume(TokenType.lParen, "Expected '(' to list columns.");
      
      List<ColumnDef> columns = [];
      do {
        final colNameToken = _consume(TokenType.identifier, "Expected column name.");
        final colType = _parseDataType();
        
        bool isPrimaryKey = false;
        bool isUnique = false;
        String? referencesTable;
        String? referencesColumn;
        bool onDeleteCascade = false;

        while (true) {
          if (_match([TokenType.primaryKeyword])) {
            _consume(TokenType.keyKeyword, "Expected 'KEY' after 'PRIMARY'.");
            isPrimaryKey = true;
          } else if (_match([TokenType.uniqueKeyword])) {
            isUnique = true;
          } else if (_match([TokenType.referencesKeyword])) {
            final refTableToken = _consume(TokenType.identifier, "Expected referenced table name.");
            referencesTable = refTableToken.lexeme;
            _consume(TokenType.lParen, "Expected '(' before referenced column name.");
            final refColToken = _consume(TokenType.identifier, "Expected referenced column name.");
            referencesColumn = refColToken.lexeme;
            _consume(TokenType.rParen, "Expected ')' after referenced column name.");

            if (_match([TokenType.on])) {
              _consume(TokenType.deleteKeyword, "Expected 'DELETE' after 'ON'.");
              _consume(TokenType.cascadeKeyword, "Expected 'CASCADE' after 'ON DELETE'.");
              onDeleteCascade = true;
            }
          } else {
            break;
          }
        }

        columns.add(ColumnDef(
          colNameToken.lexeme,
          colType,
          isPrimaryKey: isPrimaryKey,
          isUnique: isUnique,
          referencesTable: referencesTable,
          referencesColumn: referencesColumn,
          onDeleteCascade: onDeleteCascade,
        ));
      } while (_match([TokenType.comma]));

      _consume(TokenType.rParen, "Expected ')' to close column list.");
      if (_check(TokenType.semicolon)) _advance();
      return CreateTableStmt(tableName, columns);
    } else if (_match([TokenType.relationship])) {
      final relNameToken = _consume(TokenType.identifier, "Expected relationship name.");
      final relName = relNameToken.lexeme;

      _consume(TokenType.from, "Expected 'FROM' keyword.");
      final fromTableToken = _consume(TokenType.identifier, "Expected source table name.");
      final fromTable = fromTableToken.lexeme;

      _consume(TokenType.to, "Expected 'TO' keyword.");
      final toTableToken = _consume(TokenType.identifier, "Expected destination table name.");
      final toTable = toTableToken.lexeme;

      _consume(TokenType.on, "Expected 'ON' keyword.");
      final fromKeyToken = _consume(TokenType.identifier, "Expected source key column.");
      final fromKey = fromKeyToken.lexeme;

      _consume(TokenType.equals, "Expected '='.");
      final toKeyToken = _consume(TokenType.identifier, "Expected destination key column.");
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
      final indexNameToken = _consume(TokenType.identifier, "Expected index name.");
      final indexName = indexNameToken.lexeme;

      _consume(TokenType.on, "Expected 'ON' keyword.");

      final tableNameToken = _consume(TokenType.identifier, "Expected table name.");
      final tableName = tableNameToken.lexeme;

      _consume(TokenType.lParen, "Expected '(' before column names.");
      final colNames = <String>[];
      do {
        final colNameToken = _consume(TokenType.identifier, "Expected column name.");
        colNames.add(colNameToken.lexeme);
      } while (_match([TokenType.comma]));
      _consume(TokenType.rParen, "Expected ')' after column names.");
      final columnName = colNames.join(',');

      if (_check(TokenType.semicolon)) _advance();

      return CreateIndexStmt(indexName, tableName, columnName);
    } else if (_match([TokenType.policyKeyword])) {
      final name = _consume(TokenType.identifier, "Expected policy name.").lexeme;
      _consume(TokenType.on, "Expected 'ON' keyword.");
      final tableName = _consume(TokenType.identifier, "Expected table name.").lexeme;
      _consume(TokenType.usingKeyword, "Expected 'USING' keyword.");
      _consume(TokenType.lParen, "Expected '(' before policy condition.");
      final condition = _parseExpression();
      _consume(TokenType.rParen, "Expected ')' after policy condition.");
      if (_check(TokenType.semicolon)) _advance();
      return CreatePolicyStmt(name, tableName, condition);
    }
    throw Exception("Expected 'TABLE', 'RELATIONSHIP', 'INDEX', or 'POLICY' after 'CREATE'.");
  }

  Stmt _parseInsertStatement() {
    _consume(TokenType.into, "Expected 'INTO' keyword.");
    final tableNameToken = _consume(TokenType.identifier, "Expected table name.");
    final tableName = tableNameToken.lexeme;

    _consume(TokenType.valuesKeyword, "Expected 'VALUES' keyword.");
    _consume(TokenType.lParen, "Expected '(' to list values.");

    List<Expression> values = [];
    do {
      values.add(_parseExpression());
    } while (_match([TokenType.comma]));

    _consume(TokenType.rParen, "Expected ')' to close values list.");
    
    // Optional trailing semicolon
    if (_check(TokenType.semicolon)) _advance();

    return InsertStmt(tableName, values);
  }

  Stmt _parseSelectStatement() {
    List<Projection> projections = [];
    
    if (_match([TokenType.asterisk])) {
      projections.add(Projection(VariableExpr(['*']), null));
    } else {
      do {
        final expr = _parseExpression();
        String? alias;
        if (_match([TokenType.as])) {
          alias = _consume(TokenType.identifier, "Expected alias identifier.").lexeme;
        } else if (_check(TokenType.identifier)) {
          // Implicit AS alias
          alias = _advance().lexeme;
        }
        projections.add(Projection(expr, alias));
      } while (_match([TokenType.comma]));
    }

    _consume(TokenType.from, "Expected 'FROM' keyword.");
    final tableNameToken = _consume(TokenType.identifier, "Expected source table name.");
    final tableName = tableNameToken.lexeme;

    String? tableAlias;
    if (_match([TokenType.as])) {
      tableAlias = _consume(TokenType.identifier, "Expected table alias.").lexeme;
    } else if (_peek().type == TokenType.identifier && 
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

    Join? join;
    if (_match([TokenType.join])) {
      final joinTable = _consume(TokenType.identifier, "Expected table to join.").lexeme;
      String? joinAlias;
      if (_match([TokenType.as])) {
        joinAlias = _consume(TokenType.identifier, "Expected table alias.").lexeme;
      } else if (_peek().type == TokenType.identifier &&
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
      _consume(TokenType.on, "Expected 'ON' condition for JOIN.");
      final onCond = _parseExpression();
      join = Join(joinTable, onCond, alias: joinAlias);
    }

    Expression? whereCondition;
    if (_match([TokenType.where])) {
      whereCondition = _parseExpression();
    }

    Expression? groupBy;
    if (_match([TokenType.groupKeyword])) {
      _consume(TokenType.by, "Expected 'BY' after 'GROUP'.");
      groupBy = _parseExpression();
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
    if (_match([TokenType.limit])) {
      final limitToken = _consume(TokenType.numberLiteral, "Expected numeric limit.");
      limit = int.tryParse(limitToken.lexeme);
    }

    String? withRelationship;
    if (_match([TokenType.withKeyword])) {
      _consume(TokenType.relationship, "Expected 'RELATIONSHIP' after 'WITH'.");
      final relNameToken = _consume(TokenType.identifier, "Expected relationship name.");
      withRelationship = relNameToken.lexeme;
    }

    if (_check(TokenType.semicolon)) _advance();

    return SelectStmt(
      projections: projections,
      tableName: tableName,
      tableAlias: tableAlias,
      join: join,
      whereCondition: whereCondition,
      groupBy: groupBy,
      havingCondition: havingCondition,
      orderBy: orderBy,
      limit: limit,
      withRelationship: withRelationship,
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
      _consume(TokenType.andKeyword, "Expected 'AND' after BETWEEN lower bound.");
      final high = _parseAdditive();
      return BinaryExpr(
        'AND',
        BinaryExpr('>=', expr, low),
        BinaryExpr('<=', expr, high),
      );
    }

    while (_match([
      TokenType.equals,
      TokenType.notEquals,
      TokenType.lessThan,
      TokenType.lessThanOrEquals,
      TokenType.greaterThan,
      TokenType.greaterThanOrEquals,
      TokenType.likeKeyword
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
    if (_match([TokenType.placeholder])) {
      final lex = _previous().lexeme;
      if (lex == '?') {
        final idx = _placeholderCount++;
        return PlaceholderExpr(lex, idx);
      } else if (lex.startsWith('\$')) {
        final idx = int.parse(lex.substring(1)) - 1;
        return PlaceholderExpr(lex, idx);
      }
    }

    if (_match([TokenType.numberLiteral])) {
      final lex = _previous().lexeme;
      final val = num.parse(lex);
      return LiteralExpr(val);
    }

    if (_match([TokenType.stringLiteral])) {
      return LiteralExpr(_previous().lexeme);
    }

    // Vector Lit: e.g. '[0.1, 0.2, 0.3]' or parsed LBRACKET numbers RBRACKET
    if (_match([TokenType.lBracket])) {
      final elements = <double>[];
      if (!_check(TokenType.rBracket)) {
        do {
          final sign = _match([TokenType.minus]) ? -1.0 : 1.0;
          final numToken = _consume(TokenType.numberLiteral, "Expected vector element double.");
          elements.add(sign * double.parse(numToken.lexeme));
        } while (_match([TokenType.comma]));
      }
      _consume(TokenType.rBracket, "Expected ']' to close vector literal.");
      return VectorLiteralExpr(elements);
    }

    if (_match([TokenType.identifier])) {
      final firstId = _previous().lexeme;
      if (firstId.toLowerCase() == 'cast') {
        _consume(TokenType.lParen, "Expected '(' after CAST.");
        final expr = _parseExpression();
        _consume(TokenType.as, "Expected 'AS' inside CAST.");
        final targetType = _parseDataType();
        _consume(TokenType.rParen, "Expected ')' to close CAST.");
        return FunctionCallExpr('cast', [expr, LiteralExpr(targetType.toString())]);
      }

      // Check if it's a function call (e.g. vector_distance(embedding, '[1, 2, 3]'))
      if (_check(TokenType.lParen)) {
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
        return FunctionCallExpr(firstId, arguments);
      }

      // Check for dotted path notation: table.column or column.json_path
      final path = [firstId];
      while (_match([TokenType.dot])) {
        final segmentToken = _consume(TokenType.identifier, "Expected identifier after dot.");
        path.add(segmentToken.lexeme);
      }
      return VariableExpr(path);
    }

    if (_match([TokenType.lParen])) {
      final expr = _parseExpression();
      _consume(TokenType.rParen, "Expected ')' after expression.");
      return expr;
    }

    throw Exception("Unexpected token '${_peek().lexeme}' in expression.");
  }
}
