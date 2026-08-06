enum DataType {
  integer,
  double,
  text,
  vector,
  json,
  boolean,
  uuid,
  datetime,
  blob,
  decimal
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

class WindowFunctionExpr extends Expression {
  final String functionName;
  final List<Expression> arguments;
  final List<Expression> partitionBy;
  final OrderBy? orderBy;
  WindowFunctionExpr({
    required this.functionName,
    this.arguments = const [],
    required this.partitionBy,
    this.orderBy,
  });
}

class VectorLiteralExpr extends Expression {
  final List<double> elements;
  VectorLiteralExpr(this.elements);
}

class JsonExtractExpr extends Expression {
  final Expression expr;
  final String path;
  final bool asText;
  JsonExtractExpr(this.expr, this.path, this.asText);
}

class SubqueryExpr extends Expression {
  final SelectStmt selectStmt;
  SubqueryExpr(this.selectStmt);
}

class RollupExpr extends Expression {
  final List<Expression> expressions;
  RollupExpr(this.expressions);
}

class CubeExpr extends Expression {
  final List<Expression> expressions;
  CubeExpr(this.expressions);
}

class GroupingSetsExpr extends Expression {
  final List<List<Expression>> sets;
  GroupingSetsExpr(this.sets);
}

class AsOfClause extends ASTNode {
  final bool isSystemTime;
  final Expression expr;
  AsOfClause(this.isSystemTime, this.expr);
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
  final Expression? defaultValue;
  final Expression? checkExpression;
  final String? maskedWith;

  ColumnDef(
    this.name,
    this.type, {
    this.isPrimaryKey = false,
    this.isUnique = false,
    this.referencesTable,
    this.referencesColumn,
    this.onDeleteCascade = false,
    this.defaultValue,
    this.checkExpression,
    this.maskedWith,
  });
}

class Projection {
  final Expression expr;
  final String? alias;
  Projection(this.expr, this.alias);
}

class Join {
  final String tableName;
  final SelectStmt? fromSubquery;
  final String? alias;
  final Expression onCondition;
  final bool isLeftJoin;
  final bool isRightJoin;
  final bool isFullJoin;
  Join(this.tableName, this.onCondition, {
    this.fromSubquery,
    this.alias,
    this.isLeftJoin = false,
    this.isRightJoin = false,
    this.isFullJoin = false,
  });
}

class OrderBy {
  final Expression expr;
  final bool ascending;
  OrderBy(this.expr, this.ascending);
}

// Statements
abstract class Stmt extends ASTNode {}

class VacuumStmt extends Stmt {
  final String tableName;
  final bool full;
  VacuumStmt(this.tableName, {this.full = false});
}

// SQL Statements
class PartitionByClause extends ASTNode {
  final String type; // e.g., 'RANGE'
  final String columnName;
  PartitionByClause(this.type, this.columnName);
}

class PartitionOfClause extends ASTNode {
  final String parentTableName;
  final String fromValue;
  final String toValue;
  PartitionOfClause(this.parentTableName, this.fromValue, this.toValue);
}

class CreateTableStmt extends Stmt {
  final String tableName;
  final List<ColumnDef> columns;
  final PartitionByClause? partitionBy;
  final PartitionOfClause? partitionOf;
  final bool ifNotExists;
  CreateTableStmt(this.tableName, this.columns, {this.partitionBy, this.partitionOf, this.ifNotExists = false});
}

class CreateForeignTableStmt extends Stmt {
  final String tableName;
  final List<ColumnDef> columns;
  final String serverName;
  final Map<String, String> options;
  CreateForeignTableStmt(this.tableName, this.columns, this.serverName, this.options);
}

class MatchExpr extends Expression {
  final String columnName;
  final String searchQuery;
  MatchExpr(this.columnName, this.searchQuery);
}

enum AlterAction {
  add,
  drop,
  renameColumn,
  alterColumnType
}

class AlterTableStmt extends Stmt {
  final String tableName;
  final AlterAction action;
  final ColumnDef? columnToAdd; // For ADD
  final String? columnToDrop;  // For DROP
  final String? oldColumnName; // For RENAME COLUMN
  final String? newColumnName; // For RENAME COLUMN
  final String? targetColumnName; // For ALTER COLUMN TYPE
  final DataType? newDataType; // For ALTER COLUMN TYPE

  AlterTableStmt.add(this.tableName, this.columnToAdd)
      : action = AlterAction.add,
        columnToDrop = null,
        oldColumnName = null,
        newColumnName = null,
        targetColumnName = null,
        newDataType = null;

  AlterTableStmt.drop(this.tableName, this.columnToDrop)
      : action = AlterAction.drop,
        columnToAdd = null,
        oldColumnName = null,
        newColumnName = null,
        targetColumnName = null,
        newDataType = null;

  AlterTableStmt.renameColumn(this.tableName, this.oldColumnName, this.newColumnName)
      : action = AlterAction.renameColumn,
        columnToAdd = null,
        columnToDrop = null,
        targetColumnName = null,
        newDataType = null;

  AlterTableStmt.alterColumnType(this.tableName, this.targetColumnName, this.newDataType)
      : action = AlterAction.alterColumnType,
        columnToAdd = null,
        columnToDrop = null,
        oldColumnName = null,
        newColumnName = null;
}

class InsertStmt extends Stmt {
  final String tableName;
  final List<Expression> values;
  final List<String>? columnNames;
  final bool isReplace;
  final bool onConflictDoNothing;
  final String? conflictTargetColumn;
  final Map<String, Expression>? updateAssignments;

  InsertStmt(
    this.tableName,
    this.values, [
    this.columnNames,
    this.isReplace = false,
    this.onConflictDoNothing = false,
    this.conflictTargetColumn,
    this.updateAssignments,
  ]);
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
  final SelectStmt? fromSubquery;
  final FunctionCallExpr? fromFunction;
  final String? tableAlias;
  final List<Join> joins;
  final Expression? whereCondition;
  final Expression? groupBy;
  final Expression? havingCondition;
  final OrderBy? orderBy;
  final int? limit;
  final int? offset;
  final String? withRelationship;
  final bool isDistinct;
  final AsOfClause? asOfClause;

  SelectStmt({
    required this.projections,
    required this.tableName,
    this.fromSubquery,
    this.fromFunction,
    this.tableAlias,
    List<Join>? joins,
    Join? join,
    this.whereCondition,
    this.groupBy,
    this.havingCondition,
    this.orderBy,
    this.limit,
    this.offset,
    this.withRelationship,
    this.isDistinct = false,
    this.asOfClause,
  }) : this.joins = joins ?? (join != null ? [join] : const []);

  Join? get join => joins.isNotEmpty ? joins.first : null;
}

class CteSelectStmt extends SelectStmt {
  final Map<String, dynamic> ctes;
  final SelectStmt mainSelect;
  final bool isRecursive;

  CteSelectStmt({
    required this.ctes,
    required this.mainSelect,
    this.isRecursive = false,
  }) : super(
         projections: mainSelect.projections,
         tableName: mainSelect.tableName,
         fromSubquery: mainSelect.fromSubquery,
         fromFunction: mainSelect.fromFunction,
         tableAlias: mainSelect.tableAlias,
         joins: mainSelect.joins,
         whereCondition: mainSelect.whereCondition,
         groupBy: mainSelect.groupBy,
         havingCondition: mainSelect.havingCondition,
         orderBy: mainSelect.orderBy,
         limit: mainSelect.limit,
         offset: mainSelect.offset,
         withRelationship: mainSelect.withRelationship,
         isDistinct: mainSelect.isDistinct,
         asOfClause: mainSelect.asOfClause,
       );
}

class UnionStmt extends Stmt {
  final List<SelectStmt> selectStmts;
  final List<bool> isAllFlags;
  UnionStmt(this.selectStmts, this.isAllFlags);
}

class IntersectStmt extends Stmt {
  final List<SelectStmt> selectStmts;
  IntersectStmt(this.selectStmts);
}

class ExceptStmt extends Stmt {
  final List<SelectStmt> selectStmts;
  ExceptStmt(this.selectStmts);
}

// PL/SQL Statements
class VarDeclare {
  final String name;
  final DataType type;
  final Expression? initialValue;
  VarDeclare(this.name, this.type, this.initialValue);
}

class CursorDeclare {
  final String name;
  final SelectStmt selectStmt;
  CursorDeclare(this.name, this.selectStmt);
}

class ExceptionHandler {
  final String exceptionName;
  final List<Stmt> body;
  ExceptionHandler(this.exceptionName, this.body);
}

class PlSqlBlock extends Stmt {
  final List<VarDeclare> declarations;
  final List<CursorDeclare> cursors;
  final List<Stmt> body;
  final List<ExceptionHandler>? exceptionHandlers;
  PlSqlBlock(this.declarations, this.body, {this.cursors = const [], this.exceptionHandlers});
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

class SetEngineOptionStmt extends Stmt {
  final String optionName;
  final bool optionValue;
  SetEngineOptionStmt(this.optionName, this.optionValue);
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
  final bool ifNotExists;

  CreateIndexStmt(this.name, this.tableName, this.columnName, {this.usingMethod, this.ifNotExists = false});
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

class SavepointStmt extends Stmt {
  final String name;
  SavepointStmt(this.name);
}

class RollbackToSavepointStmt extends Stmt {
  final String name;
  RollbackToSavepointStmt(this.name);
}

class ReleaseSavepointStmt extends Stmt {
  final String name;
  ReleaseSavepointStmt(this.name);
}

class OpenCursorStmt extends Stmt {
  final String cursorName;
  OpenCursorStmt(this.cursorName);
}

class FetchCursorStmt extends Stmt {
  final String cursorName;
  final List<String> targetVars;
  FetchCursorStmt(this.cursorName, this.targetVars);
}

class CloseCursorStmt extends Stmt {
  final String cursorName;
  CloseCursorStmt(this.cursorName);
}

class CreateTriggerStmt extends Stmt {
  final String name;
  final String timing; // BEFORE, AFTER
  final String event; // INSERT, UPDATE, DELETE
  final String tableName;
  final bool forEachRow;
  final List<VarDeclare> declarations;
  final List<Stmt> body;
  final String sql;

  CreateTriggerStmt({
    required this.name,
    required this.timing,
    required this.event,
    required this.tableName,
    required this.forEachRow,
    required this.declarations,
    required this.body,
    required this.sql,
  });
}

class WhenBranch {
  final Expression condition;
  final Expression thenExpr;
  WhenBranch(this.condition, this.thenExpr);
}

class CaseExpr extends Expression {
  final List<WhenBranch> whenBranches;
  final Expression? elseBranch;
  CaseExpr(this.whenBranches, [this.elseBranch]);
}

class CastExpr extends Expression {
  final Expression expr;
  final DataType targetType;
  CastExpr(this.expr, this.targetType);
}

class DropTableStmt extends Stmt {
  final String tableName;
  final bool ifExists;
  DropTableStmt(this.tableName, {this.ifExists = false});
}

class DescribeTableStmt extends Stmt {
  final String tableName;
  DescribeTableStmt(this.tableName);
}

class ShowColumnsStmt extends Stmt {
  final String tableName;
  ShowColumnsStmt(this.tableName);
}

class ShowSchemasStmt extends Stmt {
  ShowSchemasStmt();
}

class PragmaTableInfoStmt extends Stmt {
  final String tableName;
  PragmaTableInfoStmt(this.tableName);
}

class TruncateTableStmt extends Stmt {
  final String tableName;
  TruncateTableStmt(this.tableName);
}

class DropIndexStmt extends Stmt {
  final String indexName;
  DropIndexStmt(this.indexName);
}

class ForLoopStmt extends Stmt {
  final String varName;
  final Expression startExpr;
  final Expression endExpr;
  final List<Stmt> body;
  ForLoopStmt(this.varName, this.startExpr, this.endExpr, this.body);
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
  } else if (expr is WindowFunctionExpr) {
    final partition = expr.partitionBy.isEmpty
        ? ''
        : 'PARTITION BY ${expr.partitionBy.map(exprToSqlString).join(', ')}';
    final order = expr.orderBy != null
        ? 'ORDER BY ${exprToSqlString(expr.orderBy!.expr)} ${expr.orderBy!.ascending ? 'ASC' : 'DESC'}'
        : '';
    final overInner = [if (partition.isNotEmpty) partition, if (order.isNotEmpty) order].join(' ');
    res = '${expr.functionName.toUpperCase()}() OVER ($overInner)';
  } else if (expr is VectorLiteralExpr) {
    res = '[${expr.elements.join(', ')}]';
  } else if (expr is JsonExtractExpr) {
    final op = expr.asText ? '->>' : '->';
    res = '${exprToSqlString(expr.expr)}$op\'${expr.path}\'';
  } else if (expr is SubqueryExpr) {
    res = '(SELECT ...)';
  } else if (expr is RollupExpr) {
    res = 'ROLLUP(${expr.expressions.map(exprToSqlString).join(', ')})';
  } else if (expr is CubeExpr) {
    res = 'CUBE(${expr.expressions.map(exprToSqlString).join(', ')})';
  } else if (expr is GroupingSetsExpr) {
    final setsStrings = expr.sets.map((s) => '(${s.map(exprToSqlString).join(', ')})').join(', ');
    res = 'GROUPING SETS($setsStrings)';
  } else if (expr is CastExpr) {
    res = 'CAST(${exprToSqlString(expr.expr)} AS ${expr.targetType.name.toUpperCase()})';
  } else {
    res = expr.toString();
  }
  
  expr._cachedSqlString = res;
  return res;
}

