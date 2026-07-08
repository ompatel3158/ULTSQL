enum TokenType {
  // Keywords - SQL
  explain,
  select,
  from,
  where,
  join,
  on,
  limit,
  orderBy,
  by,
  asc,
  desc,
  create,
  table,
  insert,
  into,
  valuesKeyword,
  as,
  commit,
  rollback,
  relationship,
  indexKeyword,
  to,
  withKeyword,
  generate,
  groupKeyword,
  likeKeyword,
  showKeyword,
  tablesKeyword,
  indexesKeyword,
  betweenKeyword,
  andKeyword,
  orKeyword,
  havingKeyword,
  primaryKeyword,
  keyKeyword,
  uniqueKeyword,
  referencesKeyword,
  deleteKeyword,
  cascadeKeyword,

  // Keywords - PL/SQL
  declare,
  begin,
  end,
  ifKeyword,
  then,
  elseKeyword,
  elsif,
  whileKeyword,
  loop,

  // Types
  typeInt,
  typeDouble,
  typeText,
  typeVector,
  typeJson,

  // Literals
  identifier,
  numberLiteral,
  stringLiteral,

  // Operators
  plus,
  minus,
  asterisk,
  slash,
  equals,
  notEquals,
  lessThan,
  greaterThan,
  lessThanOrEquals,
  greaterThanOrEquals,
  assign, // :=
  concat, // ||
  modulo, // %

  // Punctuation
  lParen,
  rParen,
  lBracket,
  rBracket,
  comma,
  semicolon,
  dot,

  // Special
  eof,
  invalid,
  placeholder,
  policyKeyword,
  usingKeyword,
  analyze,
  grant,
  revoke,
  privileges,
  all,
  setKeyword,
  userKeyword
}

class Token {
  final TokenType type;
  final String lexeme;
  final int line;
  final int column;

  Token(this.type, this.lexeme, this.line, this.column);

  @override
  String toString() {
    return 'Token($type, "$lexeme", L:$line:$column)';
  }
}
