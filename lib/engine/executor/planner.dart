import 'dart:async';
import 'dart:io';
import '../parser/ast.dart';
import '../storage/catalog.dart';
import '../storage/table_file.dart';
import '../storage/btree_index.dart';
import '../cache/page_cache.dart';
import 'plan_nodes.dart';
import 'value.dart';
import 'jit_compiler.dart';
import 'parallel_scan_nodes.dart';

class QueryPlanner {
  final Catalog catalog;
  final PageCache cache;
  final String dbDirectory;

  QueryPlanner({
    required this.catalog,
    required this.cache,
    required this.dbDirectory,
  });

  PlanNode planSelect(SelectStmt stmt) {
    stmt = _rewriteSelectStmt(stmt);
    final tableName = stmt.tableName.toLowerCase();
    final schema = catalog.getTableSchema(tableName);
    if (schema == null) {
      throw Exception("Table '$tableName' does not exist in catalog.");
    }
    bool isParallelScan = false;

    var projections = stmt.projections;
    if (projections.length == 1 &&
        projections[0].expr is VariableExpr &&
        (projections[0].expr as VariableExpr).path.first == '*') {
      final list = <Projection>[];
      for (final col in schema.columnNames) {
        list.add(Projection(VariableExpr([col]), null));
      }
      if (stmt.join != null) {
        final joinTable = stmt.join!.tableName.toLowerCase();
        final joinSchema = catalog.getTableSchema(joinTable);
        if (joinSchema != null) {
          for (final col in joinSchema.columnNames) {
            list.add(Projection(VariableExpr([joinSchema.name, col]), null));
          }
        }
      }
      projections = list;
    }

    IndexSchema? targetIndexSchema;
    List<double>? lowKeys;
    List<double>? highKeys;
    bool useIndexScan = false;
    bool needFilterNode = false;

    if (!schema.isColumnar && stmt.whereCondition != null) {
      final indexes = catalog.getIndexesForTable(tableName);
      IndexSchema? bestIndex;
      List<double>? bestLowKeys;
      List<double>? bestHighKeys;
      int bestMatchCount = -1;

      for (final idx in indexes) {
        final idxCols = idx.columnName.split(',').map((c) => c.trim().toLowerCase()).toList();
        if (idxCols.isEmpty) continue;
        
        final keys = _extractCompositeKeys(stmt.whereCondition!, tableName, idxCols);
        if (keys != null) {
          final matchCount = keys[0].length;
          if (matchCount > bestMatchCount) {
            bestIndex = idx;
            bestLowKeys = keys[0];
            bestHighKeys = keys[1];
            bestMatchCount = matchCount;
          }
        }
      }

      if (bestIndex != null) {
        targetIndexSchema = bestIndex;
        lowKeys = bestLowKeys;
        highKeys = bestHighKeys;
        
        final stats = catalog.getTableStats(tableName);
        final rowCount = stats?.rowCount ?? 1000;
        
        bool isPoint = true;
        if (lowKeys == null || highKeys == null || lowKeys.isEmpty || lowKeys.length != highKeys.length) {
          isPoint = false;
        } else {
          for (int i = 0; i < lowKeys.length; i++) {
            if (lowKeys[i] != highKeys[i]) {
              isPoint = false;
              break;
            }
          }
        }
        
        double selectivity = 0.05;
        if (isPoint) {
          final colStats = stats?.columnStats[bestIndex.columnName.split(',').first.trim().toLowerCase()];
          final distinctCount = colStats?.distinctCount ?? 10;
          selectivity = distinctCount > 0 ? 1.0 / distinctCount : 0.01;
        } else {
          final firstCol = bestIndex.columnName.split(',').first.trim().toLowerCase();
          final colStats = stats?.columnStats[firstCol];
          final minVal = colStats?.min;
          final maxVal = colStats?.max;
          final rangeLow = (lowKeys != null && lowKeys.isNotEmpty) ? lowKeys[0] : null;
          final rangeHigh = (highKeys != null && highKeys.isNotEmpty) ? highKeys[0] : null;
          if (minVal is num && maxVal is num && maxVal > minVal) {
            final low = rangeLow ?? minVal.toDouble();
            final high = rangeHigh ?? maxVal.toDouble();
            selectivity = (high - low) / (maxVal - minVal);
          } else {
            selectivity = 0.1;
          }
        }
        selectivity = selectivity.clamp(0.0, 1.0);
        final indexScanCost = selectivity * rowCount;
        final tableScanCost = rowCount.toDouble();

        if (isPoint || indexScanCost < 0.4 * tableScanCost) {
          useIndexScan = true;
          
          final condVars = <String>{};
          _collectVariables(stmt.whereCondition!, condVars);
          final indexColsSet = targetIndexSchema.columnName.split(',').map((c) => c.trim().toLowerCase()).toSet();
          for (final v in condVars) {
            final vClean = v.toLowerCase().trim();
            final vParts = vClean.split('.');
            final colName = vParts.last;
            if (!indexColsSet.contains(colName)) {
              needFilterNode = true;
              break;
            }
          }
        }
      }
    }

    PlanNode scanNode;
    if (schema.isColumnar) {
      // Columnar Projection Push-down Optimization
      final neededColIndexes = _getReferencedColumnIndexes(stmt, schema);
      final colTableFile = ColumnTableFile(
        cache: cache,
        tableName: schema.name,
        dbDirectory: dbDirectory,
        schema: schema,
      );
      scanNode = ColumnScanNode(colTableFile, schema, neededColIndexes);
    } else if (useIndexScan && targetIndexSchema != null) {
      final indexName = targetIndexSchema.name.toLowerCase();
      final indexFile = '$dbDirectory/$indexName.idx';
      final btreeIndex = BTreeIndex(cache: cache, indexPath: indexFile, keyColumns: targetIndexSchema.columnName.split(',').length);
      final rowTableFile = RowTableFile(
        cache: cache,
        tableName: schema.name,
        dbDirectory: dbDirectory,
      );
      final skipWhere = useIndexScan && !needFilterNode;
      final neededColIndexes = _getReferencedColumnIndexes(stmt, schema, skipWhere);
      scanNode = IndexScanNode(
        tableFile: rowTableFile,
        schema: schema,
        index: btreeIndex,
        low: lowKeys,
        high: highKeys,
        projectedColIndexes: neededColIndexes,
      );
    } else {
      final rowTableFile = RowTableFile(
        cache: cache,
        tableName: schema.name,
        dbDirectory: dbDirectory,
      );
      final pager = cache.getOrCreatePager(rowTableFile.filePath);
      final pageCount = pager.getPageCountSync();
      final neededColIndexes = _getReferencedColumnIndexes(stmt, schema);
      
      // If table is large and not inside an active transaction, run in parallel using workers
      if (pageCount > 50 && !cache.isTransactionActive && stmt.join == null && stmt.withRelationship == null) {
        scanNode = ParallelScanNode(
          filePath: rowTableFile.filePath,
          schema: schema,
          encryptionKey: cache.encryptionKey,
          condition: stmt.whereCondition,
          projections: stmt.groupBy == null && !_hasAggregate(stmt.projections) ? projections : null,
          pageCount: pageCount,
          numWorkers: Platform.numberOfProcessors,
          groupByExpr: stmt.groupBy,
          aggProjections: stmt.groupBy != null || _hasAggregate(stmt.projections) ? projections : null,
        );
        isParallelScan = true;
      } else {
        scanNode = RowScanNode(rowTableFile, schema, neededColIndexes);
      }
    }

    if (schema.policies.isNotEmpty) {
      Expression combinedPolicy = schema.policies.first.condition;
      for (int i = 1; i < schema.policies.length; i++) {
        combinedPolicy = BinaryExpr('OR', combinedPolicy, schema.policies[i].condition);
      }
      scanNode = FilterNode(scanNode, combinedPolicy);
    }

    PlanNode currentPlan = scanNode;

    // 1. Handle JOIN
    if (stmt.join != null) {
      final joinTable = stmt.join!.tableName.toLowerCase();
      final joinSchema = catalog.getTableSchema(joinTable);
      if (joinSchema == null) {
        throw Exception("Join table '$joinTable' does not exist.");
      }

      PlanNode joinScan;
      if (joinSchema.isColumnar) {
        // Collect all column indexes needed for join table
        final neededJoinColIndexes = _getReferencedColumnIndexesForJoin(stmt, joinSchema);
        final colTableFile = ColumnTableFile(
          cache: cache,
          tableName: joinSchema.name,
          dbDirectory: dbDirectory,
          schema: joinSchema,
        );
        joinScan = ColumnScanNode(colTableFile, joinSchema, neededJoinColIndexes);
      } else {
        final rowTableFile = RowTableFile(
          cache: cache,
          tableName: joinSchema.name,
          dbDirectory: dbDirectory,
        );
        final neededJoinColIndexes = _getReferencedColumnIndexesForJoin(stmt, joinSchema);
        joinScan = RowScanNode(rowTableFile, joinSchema, neededJoinColIndexes);
      }

      if (joinSchema.policies.isNotEmpty) {
        Expression combinedJoinPolicy = joinSchema.policies.first.condition;
        for (int i = 1; i < joinSchema.policies.length; i++) {
          combinedJoinPolicy = BinaryExpr('OR', combinedJoinPolicy, joinSchema.policies[i].condition);
        }
        joinScan = FilterNode(joinScan, combinedJoinPolicy);
      }

      // Extract join columns from condition (e.g. users.dept_id = depts.id)
      final joinCond = stmt.join!.onCondition;
      String leftJoinCol = '';
      String rightJoinCol = '';

      if (joinCond is BinaryExpr && joinCond.operator == '=') {
        if (joinCond.left is VariableExpr && joinCond.right is VariableExpr) {
          final leftVar = joinCond.left as VariableExpr;
          final rightVar = joinCond.right as VariableExpr;

          final leftTable = leftVar.path[0].toLowerCase();
          if (leftTable == schema.name.toLowerCase()) {
            leftJoinCol = leftVar.path.sublist(1).join('.');
            rightJoinCol = rightVar.path.sublist(1).join('.');
          } else {
            leftJoinCol = rightVar.path.sublist(1).join('.');
            rightJoinCol = leftVar.path.sublist(1).join('.');
          }
        }
      }

      if (leftJoinCol.isEmpty || rightJoinCol.isEmpty) {
        throw Exception("Supported JOIN condition must be 'table1.col1 = table2.col2'");
      }

      final idx = catalog.getIndexForColumn(joinTable, rightJoinCol);
      final indexName = idx?.name.toLowerCase();
      final indexFile = indexName != null ? '$dbDirectory/$indexName.idx' : null;
      final hasIndex = !joinSchema.isColumnar && indexFile != null;

      if (hasIndex) {
        final rightTableFile = RowTableFile(
          cache: cache,
          tableName: joinSchema.name,
          dbDirectory: dbDirectory,
        );
        final rightIndex = BTreeIndex(cache: cache, indexPath: indexFile!, keyColumns: idx!.columnName.split(',').length);
        currentPlan = IndexJoinNode(
          left: currentPlan,
          rightTable: rightTableFile,
          rightIndex: rightIndex,
          leftJoinCol: leftJoinCol,
          rightSchema: joinSchema,
        );
      } else {
        currentPlan = HashJoinNode(
          left: currentPlan,
          right: joinScan,
          leftJoinCol: leftJoinCol,
          rightJoinCol: rightJoinCol,
        );
      }
    }

    // 1.1 Handle WITH RELATIONSHIP (Graph Query Traversal)
    if (stmt.withRelationship != null) {
      final relName = stmt.withRelationship!.toLowerCase();
      final rel = catalog.getRelationship(relName);
      if (rel == null) {
        throw Exception("Relationship '$relName' does not exist in catalog.");
      }

      final targetTable = rel.toTable.toLowerCase();
      final targetSchema = catalog.getTableSchema(targetTable);
      if (targetSchema == null) {
        throw Exception("Target table '$targetTable' of relationship '$relName' does not exist.");
      }

      RowTableFile? targetRowTable;
      ColumnTableFile? targetColumnTable;

      if (targetSchema.isColumnar) {
        targetColumnTable = ColumnTableFile(
          cache: cache,
          tableName: targetSchema.name,
          dbDirectory: dbDirectory,
          schema: targetSchema,
        );
      } else {
        targetRowTable = RowTableFile(
          cache: cache,
          tableName: targetSchema.name,
          dbDirectory: dbDirectory,
        );
      }

      final idx = catalog.getIndexForColumn(targetTable, rel.toKey);
      final indexName = idx?.name.toLowerCase();
      final indexFile = indexName != null ? '$dbDirectory/$indexName.idx' : null;
      final hasIndex = !targetSchema.isColumnar && indexFile != null;

      BTreeIndex? targetIndex;
      if (hasIndex) {
        targetIndex = BTreeIndex(cache: cache, indexPath: indexFile!, keyColumns: idx!.columnName.split(',').length);
      }

      currentPlan = GraphJoinNode(
        left: currentPlan,
        rightTable: targetRowTable,
        rightColumnTable: targetColumnTable,
        rightIndex: targetIndex,
        leftJoinCol: rel.fromKey,
        rightJoinCol: rel.toKey,
        rightSchema: targetSchema,
      );
    }

    // 2. Handle WHERE Clause
    if (stmt.whereCondition != null && (!useIndexScan || needFilterNode) && !isParallelScan) {
      currentPlan = FilterNode(currentPlan, stmt.whereCondition!);
    }

    // 2.5 Handle GROUP BY
    if (stmt.groupBy != null && !isParallelScan) {
      currentPlan = GroupByNode(currentPlan, stmt.groupBy!, projections, havingCondition: stmt.havingCondition);
    } else if (_hasAggregate(projections) && !isParallelScan) {
      currentPlan = GroupByNode(currentPlan, LiteralExpr(1), projections, havingCondition: stmt.havingCondition);
    } else if (!isParallelScan) {
      // 4. Handle Projection (if not grouped)
      currentPlan = ProjectNode(currentPlan, projections);
    }

    // For parallel scan with having condition, filter using a filter node post-aggregation
    if (isParallelScan && stmt.havingCondition != null) {
      currentPlan = FilterNode(currentPlan, stmt.havingCondition!);
    }

    // 3. Handle ORDER BY Clause
    if (stmt.orderBy != null) {
      currentPlan = SortNode(currentPlan, stmt.orderBy!.expr, stmt.orderBy!.ascending);
    }

    // 5. Handle LIMIT Clause
    if (stmt.limit != null) {
      currentPlan = LimitNode(currentPlan, stmt.limit!);
    }

    return currentPlan;
  }

  List<int> _getReferencedColumnIndexes(SelectStmt stmt, TableSchema schema, [bool useIndexScan = false]) {
    // If selecting *, we need all columns
    if (stmt.projections.length == 1 &&
        stmt.projections[0].expr is VariableExpr &&
        (stmt.projections[0].expr as VariableExpr).path.first == '*') {
      return List<int>.generate(schema.columnNames.length, (i) => i);
    }

    final referencedNames = <String>{};
    
    // Projections
    for (final proj in stmt.projections) {
      _collectVariables(proj.expr, referencedNames);
    }

    // Where
    if (stmt.whereCondition != null && !useIndexScan) {
      _collectVariables(stmt.whereCondition!, referencedNames);
    }

    // Join Condition
    if (stmt.join != null) {
      _collectVariables(stmt.join!.onCondition, referencedNames);
    }

    // Order By
    if (stmt.orderBy != null) {
      _collectVariables(stmt.orderBy!.expr, referencedNames);
    }

    // Relationship key
    if (stmt.withRelationship != null) {
      final rel = catalog.getRelationship(stmt.withRelationship!.toLowerCase());
      if (rel != null && rel.fromTable.toLowerCase() == schema.name.toLowerCase()) {
        referencedNames.add(rel.fromKey);
      }
    }

    final indexes = <int>{};
    for (final name in referencedNames) {
      final nameLower = name.toLowerCase();
      // Match column with or without table prefix
      for (int i = 0; i < schema.columnNames.length; i++) {
        final colName = schema.columnNames[i].toLowerCase();
        if (nameLower == colName || nameLower == '${schema.name.toLowerCase()}.$colName') {
          indexes.add(i);
        } else if (nameLower.startsWith('$colName.')) {
          // JSON path nested extraction
          indexes.add(i);
        }
      }
    }

    if (indexes.isEmpty) {
      if (useIndexScan) {
        return [];
      }
      // Must load at least one column (e.g. if we do SELECT 1 FROM table)
      return [0];
    }

    final sorted = indexes.toList()..sort();
    return sorted;
  }

  List<int> _getReferencedColumnIndexesForJoin(SelectStmt stmt, TableSchema joinSchema) {
    final referencedNames = <String>{};
    if (stmt.join != null) {
      _collectVariables(stmt.join!.onCondition, referencedNames);
    }
    for (final proj in stmt.projections) {
      _collectVariables(proj.expr, referencedNames);
    }
    if (stmt.whereCondition != null) {
      _collectVariables(stmt.whereCondition!, referencedNames);
    }

    final indexes = <int>{};
    for (final name in referencedNames) {
      final nameLower = name.toLowerCase();
      for (int i = 0; i < joinSchema.columnNames.length; i++) {
        final colName = joinSchema.columnNames[i].toLowerCase();
        if (nameLower == colName || nameLower == '${joinSchema.name.toLowerCase()}.$colName') {
          indexes.add(i);
        }
      }
    }
    if (indexes.isEmpty) return [0];
    return indexes.toList()..sort();
  }

  void _collectVariables(Expression expr, Set<String> collected) {
    if (expr is VariableExpr) {
      collected.add(expr.fullName);
    } else if (expr is BinaryExpr) {
      _collectVariables(expr.left, collected);
      _collectVariables(expr.right, collected);
    } else if (expr is FunctionCallExpr) {
      for (final arg in expr.arguments) {
        _collectVariables(arg, collected);
      }
    }
  }

  bool _hasAggregate(List<Projection> projections) {
    for (final proj in projections) {
      if (_hasAggregateExpr(proj.expr)) return true;
    }
    return false;
  }

  bool _hasAggregateExpr(Expression expr) {
    if (expr is FunctionCallExpr) {
      final name = expr.name.toLowerCase();
      if (name == 'count' || name == 'sum' || name == 'avg' || name == 'min' || name == 'max') {
        return true;
      }
    }
    if (expr is BinaryExpr) {
      return _hasAggregateExpr(expr.left) || _hasAggregateExpr(expr.right);
    }
    return false;
  }

  RangeCondition? _tryExtractRange(Expression cond, String tableName) {
    if (cond is BinaryExpr) {
      final op = cond.operator.toUpperCase();
      if (op == 'AND') {
        final leftRange = _tryExtractSimpleRange(cond.left, tableName);
        final rightRange = _tryExtractSimpleRange(cond.right, tableName);
        if (leftRange != null && rightRange != null && leftRange.colName == rightRange.colName) {
          return RangeCondition(
            colName: leftRange.colName,
            low: leftRange.low ?? rightRange.low,
            high: leftRange.high ?? rightRange.high,
          );
        }
      } else {
        return _tryExtractSimpleRange(cond, tableName);
      }
    }
    return null;
  }

  dynamic _resolveValue(Expression expr) {
    if (expr is LiteralExpr) {
      return expr.value;
    }
    if (expr is PlaceholderExpr) {
      final idx = expr.index;
      if (idx != null) {
        final params = JitCompiler.currentParams;
        if (params != null && idx < params.length) {
          return params[idx].value;
        }
      }
    }
    return null;
  }

  RangeCondition? _tryExtractSimpleRange(Expression expr, String tableName) {
    final tName = tableName.toLowerCase();
    if (expr is BinaryExpr) {
      final op = expr.operator;
      final left = expr.left;
      final right = expr.right;
      if (left is VariableExpr && (right is LiteralExpr || right is PlaceholderExpr)) {
        if (left.path.length > 1 && left.path.first.toLowerCase() != tName) {
          return null;
        }
        final colName = left.path.last.toLowerCase();
        final val = _resolveValue(right);
        if (val is num) {
          final valD = val.toDouble();
          if (op == '=') return RangeCondition(colName: colName, low: valD, high: valD);
          if (op == '>=') return RangeCondition(colName: colName, low: valD, high: null);
          if (op == '>') return RangeCondition(colName: colName, low: valD + 0.000001, high: null);
          if (op == '<=') return RangeCondition(colName: colName, low: null, high: valD);
          if (op == '<') return RangeCondition(colName: colName, low: null, high: valD - 0.000001);
        }
      } else if ((left is LiteralExpr || left is PlaceholderExpr) && right is VariableExpr) {
        if (right.path.length > 1 && right.path.first.toLowerCase() != tName) {
          return null;
        }
        final colName = right.path.last.toLowerCase();
        final val = _resolveValue(left);
        if (val is num) {
          final valD = val.toDouble();
          if (op == '=') return RangeCondition(colName: colName, low: valD, high: valD);
          if (op == '<=') return RangeCondition(colName: colName, low: valD, high: null);
          if (op == '<') return RangeCondition(colName: colName, low: valD + 0.000001, high: null);
          if (op == '>=') return RangeCondition(colName: colName, low: null, high: valD);
          if (op == '>') return RangeCondition(colName: colName, low: null, high: valD - 0.000001);
        }
      }
    }
    return null;
  }

  SelectStmt _rewriteSelectStmt(SelectStmt stmt) {
    final mainTable = stmt.tableName.toLowerCase();
    final mainAlias = stmt.tableAlias?.toLowerCase();
    final joinTable = stmt.join?.tableName.toLowerCase();
    final joinAlias = stmt.join?.alias?.toLowerCase();

    if (mainAlias == null && joinAlias == null) {
      return stmt;
    }

    Expression rewriteExpr(Expression expr) {
      if (expr is VariableExpr) {
        if (expr.path.isNotEmpty) {
          final first = expr.path.first.toLowerCase();
          if (mainAlias != null && first == mainAlias) {
            return VariableExpr([stmt.tableName, ...expr.path.sublist(1)]);
          }
          if (joinAlias != null && first == joinAlias) {
            return VariableExpr([stmt.join!.tableName, ...expr.path.sublist(1)]);
          }
        }
        return expr;
      }
      if (expr is BinaryExpr) {
        return BinaryExpr(
          expr.operator,
          rewriteExpr(expr.left),
          rewriteExpr(expr.right),
        );
      }
      if (expr is FunctionCallExpr) {
        return FunctionCallExpr(
          expr.name,
          expr.arguments.map(rewriteExpr).toList(),
        );
      }
      return expr;
    }

    final newProjections = stmt.projections.map((p) => Projection(rewriteExpr(p.expr), p.alias)).toList();
    final newJoin = stmt.join != null 
        ? Join(stmt.join!.tableName, rewriteExpr(stmt.join!.onCondition), alias: stmt.join!.alias) 
        : null;
    final newWhere = stmt.whereCondition != null ? rewriteExpr(stmt.whereCondition!) : null;
    final newGroupBy = stmt.groupBy != null ? rewriteExpr(stmt.groupBy!) : null;
    final newHaving = stmt.havingCondition != null ? rewriteExpr(stmt.havingCondition!) : null;
    final newOrderBy = stmt.orderBy != null 
        ? OrderBy(rewriteExpr(stmt.orderBy!.expr), stmt.orderBy!.ascending) 
        : null;

    return SelectStmt(
      projections: newProjections,
      tableName: stmt.tableName,
      tableAlias: stmt.tableAlias,
      join: newJoin,
      whereCondition: newWhere,
      groupBy: newGroupBy,
      havingCondition: newHaving,
      orderBy: newOrderBy,
      limit: stmt.limit,
      withRelationship: stmt.withRelationship,
    );
  }

  IndexRange? planIndexRange(String tableName, Expression condition) {
    final schema = catalog.getTableSchema(tableName);
    if (schema == null) return null;
    final indexes = catalog.getIndexesForTable(tableName);
    IndexSchema? bestIndex;
    List<double>? bestLowKeys;
    List<double>? bestHighKeys;
    int bestMatchCount = -1;

    for (final idx in indexes) {
      final idxCols = idx.columnName.split(',').map((c) => c.trim().toLowerCase()).toList();
      if (idxCols.isEmpty) continue;
      
      final keys = _extractCompositeKeys(condition, tableName, idxCols);
      if (keys != null) {
        final matchCount = keys[0].length;
        if (matchCount > bestMatchCount) {
          bestIndex = idx;
          bestLowKeys = keys[0];
          bestHighKeys = keys[1];
          bestMatchCount = matchCount;
        }
      }
    }
    if (bestIndex != null) {
      return IndexRange(bestIndex, bestLowKeys, bestHighKeys);
    }
    return null;
  }

  List<List<double>>? _extractCompositeKeys(Expression cond, String tableName, List<String> indexCols) {
    final lowKeys = <double>[];
    final highKeys = <double>[];
    
    for (int i = 0; i < indexCols.length; i++) {
      final colName = indexCols[i].trim().toLowerCase();
      final eqVal = _findEqualityValue(cond, tableName, colName);
      if (eqVal != null) {
        lowKeys.add(eqVal);
        highKeys.add(eqVal);
      } else if (i == 0) {
        final rangeCond = _tryExtractRange(cond, tableName);
        if (rangeCond != null && rangeCond.colName == colName) {
          if (rangeCond.low != null) lowKeys.add(rangeCond.low!);
          if (rangeCond.high != null) highKeys.add(rangeCond.high!);
          break;
        } else {
          return null;
        }
      } else {
        break;
      }
    }
    
    return [lowKeys, highKeys];
  }

  double? _findEqualityValue(Expression cond, String tableName, String colName) {
    if (cond is BinaryExpr) {
      final op = cond.operator.toUpperCase();
      if (op == 'AND') {
        final leftVal = _findEqualityValue(cond.left, tableName, colName);
        if (leftVal != null) return leftVal;
        return _findEqualityValue(cond.right, tableName, colName);
      } else if (op == '=') {
        final left = cond.left;
        final right = cond.right;
        final tName = tableName.toLowerCase();
        if (left is VariableExpr && (right is LiteralExpr || right is PlaceholderExpr)) {
          if (left.path.length > 1 && left.path.first.toLowerCase() != tName) {
            return null;
          }
          if (left.path.last.toLowerCase() == colName) {
            return _dbValueToDouble(_resolveValue(right));
          }
        } else if ((left is LiteralExpr || left is PlaceholderExpr) && right is VariableExpr) {
          if (right.path.length > 1 && right.path.first.toLowerCase() != tName) {
            return null;
          }
          if (right.path.last.toLowerCase() == colName) {
            return _dbValueToDouble(_resolveValue(left));
          }
        }
      }
    }
    return null;
  }

  double? _dbValueToDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) {
      final parsed = double.tryParse(val);
      if (parsed != null) return parsed;
      double hash = 0.0;
      for (int i = 0; i < val.length; i++) {
        hash = (hash * 31.0 + val.codeUnitAt(i)) % 9007199254740991;
      }
      return hash;
    }
    return null;
  }
}

class RangeCondition {
  final String colName;
  final double? low;
  final double? high;
  RangeCondition({required this.colName, this.low, this.high});
}

class IndexRange {
  final IndexSchema indexSchema;
  final List<double>? low;
  final List<double>? high;
  IndexRange(this.indexSchema, this.low, this.high);
}
