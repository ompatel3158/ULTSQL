enum DataType {
  integer,
  double,
  text,
  vector,
  json
}

abstract class ASTNode {}

abstract class Expression extends ASTNode {
  String? _cachedSqlString;
}

class LiteralExpr extends Expression {
  final dynamic value;
  LiteralExpr(this.value);
}

class PlaceholderExpr extends Expression {
  final String placeholder; // '?' or '$1'
  final int? index; // 0-based parameter index
  PlaceholderExpr(this.placeholder, [this.index]);
}

class VariableExpr extends Expression {
  final List<String> path; // e.g. ["users", "info", "age"] representing users.info.age
  VariableExpr(this.path);
  
  String get fullName => path.join('.');
}

class BinaryExpr extends Expression {
  final String operator;
  final Expression left;
  final Expression right;
  BinaryExpr(this.operator, this.left, this.right);
}

class FunctionCallExpr extends Expression {
  final String name;
  final List<Expression> arguments;
  FunctionCallExpr(this.name, this.arguments);
}

class VectorLiteralExpr extends Expression {
  final List<double> elements;
  VectorLiteralExpr(this.elements);
}

// Helper structures
class ColumnDef {
  final String name;
  final DataType type;
  final bool isPrimaryKey;
  final bool isUnique;
  final String? referencesTable;
  final String? referencesColumn;
  final bool onDeleteCascade;

  ColumnDef(
    this.name,
    this.type, {
    this.isPrimaryKey = false,
    this.isUnique = false,
    this.referencesTable,
    this.referencesColumn,
    this.onDeleteCascade = false,
  });
}

class Projection {
  final Expression expr;
  final String? alias;
  Projection(this.expr, this.alias);
}

class Join {
  final String tableName;
  final String? alias;
  final Expression onCondition;
  final bool isLeftJoin;
  Join(this.tableName, this.onCondition, {this.alias, this.isLeftJoin = false});
}

class OrderBy {
  final Expression expr;
  final bool ascending;
  OrderBy(this.expr, this.ascending);
}

// Statements
abstract class Stmt extends ASTNode {}

// SQL Statements
class CreateTableStmt extends Stmt {
  final String tableName;
  final List<ColumnDef> columns;
  CreateTableStmt(this.tableName, this.columns);
}

enum AlterAction {
  add,
  drop
}

class AlterTableStmt extends Stmt {
  final String tableName;
  final AlterAction action;
  final ColumnDef? columnToAdd; // For ADD
  final String? columnToDrop;  // For DROP

  AlterTableStmt.add(this.tableName, this.columnToAdd)
      : action = AlterAction.add,
        columnToDrop = null;

  AlterTableStmt.drop(this.tableName, this.columnToDrop)
      : action = AlterAction.drop,
        columnToAdd = null;
}

class InsertStmt extends Stmt {
  final String tableName;
  final List<Expression> values;
  InsertStmt(this.tableName, this.values);
}

class DeleteStmt extends Stmt {
  final String tableName;
  final Expression? whereCondition;
  DeleteStmt(this.tableName, this.whereCondition);
}

class UpdateStmt extends Stmt {
  final String tableName;
  final String columnName;
  final Expression valueExpr;
  final Expression? whereCondition;
  UpdateStmt(this.tableName, this.columnName, this.valueExpr, this.whereCondition);
}

class SelectStmt extends Stmt {
  final List<Projection> projections;
  final String tableName;
  final String? tableAlias;
  final Join? join;
  final Expression? whereCondition;
  final Expression? groupBy;
  final Expression? havingCondition;
  final OrderBy? orderBy;
  final int? limit;
  final String? withRelationship;

  SelectStmt({
    required this.projections,
    required this.tableName,
    this.tableAlias,
    this.join,
    this.whereCondition,
    this.groupBy,
    this.havingCondition,
    this.orderBy,
    this.limit,
    this.withRelationship,
  });
}

// PL/SQL Statements
class VarDeclare {
  final String name;
  final DataType type;
  final Expression? initialValue;
  VarDeclare(this.name, this.type, this.initialValue);
}

class PlSqlBlock extends Stmt {
  final List<VarDeclare> declarations;
  final List<Stmt> body;
  PlSqlBlock(this.declarations, this.body);
}

class AssignStmt extends Stmt {
  final String varName;
  final Expression expr;
  AssignStmt(this.varName, this.expr);
}

class ElsifBranch {
  final Expression condition;
  final List<Stmt> body;
  ElsifBranch(this.condition, this.body);
}

class IfStmt extends Stmt {
  final Expression condition;
  final List<Stmt> thenBranch;
  final List<ElsifBranch> elsifBranches;
  final List<Stmt>? elseBranch;
  IfStmt(this.condition, this.thenBranch, this.elsifBranches, this.elseBranch);
}

class WhileStmt extends Stmt {
  final Expression condition;
  final List<Stmt> body;
  WhileStmt(this.condition, this.body);
}

class DbmsOutputStmt extends Stmt {
  final Expression expr;
  DbmsOutputStmt(this.expr);
}

// Transaction Statements
class BeginTxStmt extends Stmt {}
class CommitTxStmt extends Stmt {}
class RollbackTxStmt extends Stmt {}

// DCL Statements
class GrantStmt extends Stmt {
  final String privilege;
  final String tableName;
  final String user;
  GrantStmt(this.privilege, this.tableName, this.user);
}

class RevokeStmt extends Stmt {
  final String privilege;
  final String tableName;
  final String user;
  RevokeStmt(this.privilege, this.tableName, this.user);
}

class SetUserStmt extends Stmt {
  final String username;
  SetUserStmt(this.username);
}

class CreateDatabaseStmt extends Stmt {
  final String name;
  CreateDatabaseStmt(this.name);
}

class UseDatabaseStmt extends Stmt {
  final String name;
  UseDatabaseStmt(this.name);
}

class CreateRelationshipStmt extends Stmt {
  final String name;
  final String fromTable;
  final String toTable;
  final String fromKey;
  final String toKey;

  CreateRelationshipStmt({
    required this.name,
    required this.fromTable,
    required this.toTable,
    required this.fromKey,
    required this.toKey,
  });
}

class CreateIndexStmt extends Stmt {
  final String name;
  final String tableName;
  final String columnName;
  final String? usingMethod;

  CreateIndexStmt(this.name, this.tableName, this.columnName, {this.usingMethod});
}

class GenerateStmt extends Stmt {}

class ExplainStmt extends Stmt {
  final SelectStmt selectStmt;
  ExplainStmt(this.selectStmt);
}

class AnalyzeStmt extends Stmt {
  final String tableName;
  AnalyzeStmt(this.tableName);
}

class ShowTablesStmt extends Stmt {}

class ShowIndexesStmt extends Stmt {
  final String? tableName;
  ShowIndexesStmt({this.tableName});
}

class CreatePolicyStmt extends Stmt {
  final String name;
  final String tableName;
  final Expression condition;
  CreatePolicyStmt(this.name, this.tableName, this.condition);
}

class Parameter {
  final String name;
  final DataType type;
  Parameter(this.name, this.type);
}

class CreateProcedureStmt extends Stmt {
  final String name;
  final List<Parameter> params;
  final List<Stmt> body;
  final String sql;
  CreateProcedureStmt(this.name, this.params, this.body, this.sql);
}

class CreateFunctionStmt extends Stmt {
  final String name;
  final List<Parameter> params;
  final DataType returnType;
  final List<Stmt> body;
  final String sql;
  CreateFunctionStmt(this.name, this.params, this.returnType, this.body, this.sql);
}

class CallStmt extends Stmt {
  final String name;
  final List<Expression> args;
  CallStmt(this.name, this.args);
}

class ReturnStmt extends Stmt {
  final Expression expr;
  ReturnStmt(this.expr);
}

class ReturnException implements Exception {
  final dynamic value;
  ReturnException(this.value);
}

String exprToSqlString(Expression expr) {
  if (expr._cachedSqlString != null) return expr._cachedSqlString!;
  
  String res;
  if (expr is PlaceholderExpr) {
    res = expr.placeholder;
  } else if (expr is LiteralExpr) {
    res = expr.value.toString();
  } else if (expr is VariableExpr) {
    res = expr.fullName;
  } else if (expr is BinaryExpr) {
    res = '${exprToSqlString(expr.left)} ${expr.operator} ${exprToSqlString(expr.right)}';
  } else if (expr is FunctionCallExpr) {
    final args = expr.arguments.map(exprToSqlString).join(', ');
    res = '${expr.name.toLowerCase()}($args)';
  } else if (expr is VectorLiteralExpr) {
    res = '[${expr.elements.join(', ')}]';
  } else {
    res = expr.toString();
  }
  
  expr._cachedSqlString = res;
  return res;
}

