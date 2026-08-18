import 'token.dart';

class Lexer {
  final String source;
  int _position = 0;
  int _line = 1;
  int _column = 1;

  Lexer(this.source);

  static const Map<String, TokenType> _keywords = {
    'analyze': TokenType.analyze,
    'explain': TokenType.explain,
    'select': TokenType.select,
    'from': TokenType.from,
    'where': TokenType.where,
    'join': TokenType.join,
    'on': TokenType.on,
    'limit': TokenType.limit,
    'order': TokenType.orderBy,
    'by': TokenType.by,
    'asc': TokenType.asc,
    'desc': TokenType.desc,
    'create': TokenType.create,
    'table': TokenType.table,
    'insert': TokenType.insert,
    'into': TokenType.into,
    'values': TokenType.valuesKeyword,
    'as': TokenType.as,
    'commit': TokenType.commit,
    'rollback': TokenType.rollback,
    'relationship': TokenType.relationship,
    'index': TokenType.indexKeyword,
    'show': TokenType.showKeyword,
    'tables': TokenType.tablesKeyword,
    'indexes': TokenType.indexesKeyword,
    'to': TokenType.to,
    'with': TokenType.withKeyword,
    'in': TokenType.inKeyword,
    'generate': TokenType.generate,
    'group': TokenType.groupKeyword,
    'like': TokenType.likeKeyword,
    'between': TokenType.betweenKeyword,
    'and': TokenType.andKeyword,
    'or': TokenType.orKeyword,
    'having': TokenType.havingKeyword,
    'primary': TokenType.primaryKeyword,
    'key': TokenType.keyKeyword,
    'unique': TokenType.uniqueKeyword,
    'references': TokenType.referencesKeyword,
    'delete': TokenType.deleteKeyword,
    'cascade': TokenType.cascadeKeyword,
    'alter': TokenType.alterKeyword,
    'add': TokenType.addKeyword,
    'drop': TokenType.dropKeyword,
    'column': TokenType.columnKeyword,
    'check': TokenType.checkKeyword,
    'default': TokenType.defaultKeyword,
    'declare': TokenType.declare,
    'begin': TokenType.begin,
    'end': TokenType.end,
    'if': TokenType.ifKeyword,
    'then': TokenType.then,
    'else': TokenType.elseKeyword,
    'elsif': TokenType.elsif,
    'while': TokenType.whileKeyword,
    'loop': TokenType.loop,
    'int': TokenType.typeInt,
    'integer': TokenType.typeInt,
    'bigint': TokenType.typeInt,
    'smallint': TokenType.typeInt,
    'double': TokenType.typeDouble,
    'real': TokenType.typeDouble,
    'float': TokenType.typeDouble,
    'decimal': TokenType.typeDecimal,
    'numeric': TokenType.typeDecimal,
    'text': TokenType.typeText,
    'varchar': TokenType.typeText,
    'char': TokenType.typeText,
    'string': TokenType.typeText,
    'vector': TokenType.typeVector,
    'json': TokenType.typeJson,
    'bool': TokenType.typeBool,
    'boolean': TokenType.typeBool,
    'uuid': TokenType.typeUuid,
    'guid': TokenType.typeUuid,
    'datetime': TokenType.typeDateTime,
    'timestamp': TokenType.typeDateTime,
    'date': TokenType.typeDateTime,
    'blob': TokenType.typeBlob,
    'bytea': TokenType.typeBlob,
    'bytes': TokenType.typeBlob,
    'true': TokenType.trueKeyword,
    'false': TokenType.falseKeyword,
    'cast': TokenType.castKeyword,
    'pragma': TokenType.pragmaKeyword,
    'describe': TokenType.describeKeyword,
    'columns': TokenType.columnsKeyword,
    'schemas': TokenType.schemasKeyword,
    'truncate': TokenType.truncateKeyword,
    'exists': TokenType.existsKeyword,
    'ilike': TokenType.ilikeKeyword,
    'not': TokenType.notKeyword,
    'null': TokenType.nullKeyword,
    'policy': TokenType.policyKeyword,
    'using': TokenType.usingKeyword,
    'conflict': TokenType.conflictKeyword,
    'do': TokenType.doKeyword,
    'nothing': TokenType.nothingKeyword,
    'replace': TokenType.replaceKeyword,
    'macro': TokenType.macroKeyword,
    'stream': TokenType.streamKeyword,
    'emit': TokenType.emitKeyword,
    'procedure': TokenType.procedureKeyword,
    'function': TokenType.functionKeyword,
    'returns': TokenType.returnsKeyword,
    'return': TokenType.returnKeyword,
    'call': TokenType.callKeyword,
    'union': TokenType.union,
    'all': TokenType.all,
    'over': TokenType.over,
    'partition': TokenType.partition,
    'intersect': TokenType.intersect,
    'except': TokenType.except,
    'distinct': TokenType.distinct,
    'offset': TokenType.offset,
    'savepoint': TokenType.savepointKeyword,
    'release': TokenType.releaseKeyword,
    'cursor': TokenType.cursorKeyword,
    'for': TokenType.forKeyword,
    'open': TokenType.openKeyword,
    'fetch': TokenType.fetchKeyword,
    'close': TokenType.closeKeyword,
    'trigger': TokenType.triggerKeyword,
    'before': TokenType.beforeKeyword,
    'after': TokenType.afterKeyword,
    'each': TokenType.eachKeyword,
    'row': TokenType.rowKeyword,
    'exception': TokenType.exceptionKeyword,
    'when': TokenType.whenKeyword,
    'fts': TokenType.ftsKeyword,
    'match': TokenType.matchKeyword,
    'recursive': TokenType.recursiveKeyword,
    'rollup': TokenType.rollupKeyword,
    'cube': TokenType.cubeKeyword,
    'grouping': TokenType.groupingKeyword,
    'sets': TokenType.setsKeyword,
    'foreign': TokenType.foreignKeyword,
    'server': TokenType.serverKeyword,
    'options': TokenType.optionsKeyword,
    'checkpoint': TokenType.checkpointKeyword,
    'vacuum': TokenType.vacuumKeyword,
    'full': TokenType.fullKeyword,
    'of': TokenType.ofKeyword,
    'system': TokenType.systemKeyword,
    'time': TokenType.timeKeyword,
    'transaction': TokenType.transactionKeyword,
    'range': TokenType.rangeKeyword,
    'masked': TokenType.maskedKeyword,
  };

  bool get _isAtEnd => _position >= source.length;

  String _peek() => _isAtEnd ? '' : source[_position];

  String _peekNext() =>
      (_position + 1 >= source.length) ? '' : source[_position + 1];

  String _advance() {
    if (_isAtEnd) return '';
    final char = source[_position++];
    if (char == '\n') {
      _line++;
      _column = 1;
    } else {
      _column++;
    }
    return char;
  }

  List<Token> tokenize() {
    final tokens = <Token>[];
    while (!_isAtEnd) {
      final token = _nextToken();
      if (token != null) {
        tokens.add(token);
        if (token.type == TokenType.eof) break;
      }
    }
    if (tokens.isEmpty || tokens.last.type != TokenType.eof) {
      tokens.add(Token(TokenType.eof, '', _line, _column));
    }
    return tokens;
  }

  Token? _nextToken() {
    _skipWhitespaceAndComments();

    if (_isAtEnd) {
      return Token(TokenType.eof, '', _line, _column);
    }

    final startLine = _line;
    final startCol = _column;
    final char = _advance();

    // Identifiers and Keywords
    if (_isAlpha(char)) {
      final buffer = StringBuffer(char);
      while (_isAlphaNumeric(_peek())) {
        buffer.write(_advance());
      }
      final lexeme = buffer.toString();
      final lowerLexeme = lexeme.toLowerCase();
      final type = _keywords[lowerLexeme] ?? TokenType.identifier;
      return Token(type, lexeme, startLine, startCol);
    }

    // Numbers
    if (_isDigit(char)) {
      final buffer = StringBuffer(char);
      while (_isDigit(_peek())) {
        buffer.write(_advance());
      }
      if (_peek() == '.' && _isDigit(_peekNext())) {
        buffer.write(_advance()); // Consume '.'
        while (_isDigit(_peek())) {
          buffer.write(_advance());
        }
      }
      return Token(
        TokenType.numberLiteral,
        buffer.toString(),
        startLine,
        startCol,
      );
    }

    // Strings (bounded by single quotes)
    if (char == "'") {
      final buffer = StringBuffer();
      while (_peek() != "'" && !_isAtEnd) {
        if (_peek() == '\n') {
          // Multiline string
        }
        buffer.write(_advance());
      }
      if (_isAtEnd) {
        return Token(
          TokenType.invalid,
          'Unterminated string literal',
          startLine,
          startCol,
        );
      }
      _advance(); // Consume closing quote
      return Token(
        TokenType.stringLiteral,
        buffer.toString(),
        startLine,
        startCol,
      );
    }

    // Single/Multi character operators & punctuation
    switch (char) {
      case '(':
        return Token(TokenType.lParen, '(', startLine, startCol);
      case ')':
        return Token(TokenType.rParen, ')', startLine, startCol);
      case '[':
        return Token(TokenType.lBracket, '[', startLine, startCol);
      case ']':
        return Token(TokenType.rBracket, ']', startLine, startCol);
      case ',':
        return Token(TokenType.comma, ',', startLine, startCol);
      case ';':
        return Token(TokenType.semicolon, ';', startLine, startCol);
      case '.':
        return Token(TokenType.dot, '.', startLine, startCol);
      case '+':
        return Token(TokenType.plus, '+', startLine, startCol);
      case '-':
        if (_peek() == '>') {
          _advance();
          if (_peek() == '>') {
            _advance();
            return Token(TokenType.arrowText, '->>', startLine, startCol);
          }
          return Token(TokenType.arrow, '->', startLine, startCol);
        }
        return Token(TokenType.minus, '-', startLine, startCol);
      case '*':
        return Token(TokenType.asterisk, '*', startLine, startCol);
      case '/':
        return Token(TokenType.slash, '/', startLine, startCol);
      case '%':
        return Token(TokenType.modulo, '%', startLine, startCol);
      case '=':
        return Token(TokenType.equals, '=', startLine, startCol);
      case '<':
        if (_peek() == '=') {
          _advance();
          return Token(TokenType.lessThanOrEquals, '<=', startLine, startCol);
        } else if (_peek() == '>') {
          _advance();
          return Token(TokenType.notEquals, '<>', startLine, startCol);
        }
        return Token(TokenType.lessThan, '<', startLine, startCol);
      case '>':
        if (_peek() == '=') {
          _advance();
          return Token(
            TokenType.greaterThanOrEquals,
            '>=',
            startLine,
            startCol,
          );
        }
        return Token(TokenType.greaterThan, '>', startLine, startCol);
      case '!':
        if (_peek() == '=') {
          _advance();
          return Token(TokenType.notEquals, '!=', startLine, startCol);
        }
        return Token(TokenType.invalid, '!', startLine, startCol);
      case ':':
        if (_peek() == '=') {
          _advance();
          return Token(TokenType.assign, ':=', startLine, startCol);
        } else if (_peek() == ':') {
          _advance();
          return Token(TokenType.doubleColon, '::', startLine, startCol);
        }
        return Token(TokenType.invalid, ':', startLine, startCol);
      case '|':
        if (_peek() == '|') {
          _advance();
          return Token(TokenType.concat, '||', startLine, startCol);
        }
        return Token(TokenType.invalid, '|', startLine, startCol);
      case '~':
        return Token(TokenType.tilde, '~', startLine, startCol);
      case '?':
        return Token(TokenType.placeholder, '?', startLine, startCol);
      case '\$':
        final buffer = StringBuffer(char);
        while (_isDigit(_peek())) {
          buffer.write(_advance());
        }
        if (buffer.length > 1) {
          return Token(
            TokenType.placeholder,
            buffer.toString(),
            startLine,
            startCol,
          );
        }
        return Token(TokenType.invalid, '\$', startLine, startCol);
    }

    return Token(TokenType.invalid, char, startLine, startCol);
  }

  void _skipWhitespaceAndComments() {
    while (!_isAtEnd) {
      final char = _peek();
      if (char == ' ' || char == '\r' || char == '\t' || char == '\n') {
        _advance();
      } else if (char == '-' && _peekNext() == '-') {
        // Skip comment line
        while (_peek() != '\n' && !_isAtEnd) {
          _advance();
        }
      } else {
        break;
      }
    }
  }

  bool _isAlpha(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || // A-Z
        (code >= 97 && code <= 122) || // a-z
        code == 95; // _
  }

  bool _isDigit(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57; // 0-9
  }

  bool _isAlphaNumeric(String char) {
    return _isAlpha(char) || _isDigit(char);
  }
}
