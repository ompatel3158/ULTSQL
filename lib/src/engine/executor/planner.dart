import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../parser/ast.dart';
import '../storage/catalog.dart';
import '../storage/table_file.dart';
import '../storage/btree_index.dart';
import '../storage/hnsw_index.dart';
import '../storage/ivf_flat_index.dart';
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

  String _normalizeExprString(String sql, String tableName) {
    String s = sql.trim();
    
    bool hasOuterParens(String str) {
      if (!str.startsWith('(') || !str.endsWith(')')) return false;
      int depth = 0;
      for (int i = 0; i < str.length - 1; i++) {
        if (str[i] == '(') depth++;
        else if (str[i] == ')') depth--;
        if (depth == 0) return false;
      }
      return depth == 1;
    }

    while (hasOuterParens(s)) {
      s = s.substring(1, s.length - 1).trim();
    }
    
    s = s.replaceAll(RegExp(r'\s+'), '');
    
    final lowerSql = s.toLowerCase();
    final lowerTable = tableName.toLowerCase();
    final prefix = '$lowerTable.';
    if (lowerSql.startsWith(prefix)) {
      return lowerSql.substring(prefix.length);
    }
    return lowerSql;
  }

  int _getKeyColumnsCount(IndexSchema idxSchema) {
    final schema = catalog.getTableSchema(idxSchema.tableName.toLowerCase());
    if (schema == null) return 1;
    final bool isSimple = idxSchema.columnName.split(',').every((col) => schema.columnNamesLower.contains(col.trim().toLowerCase()));
    return isSimple ? idxSchema.columnName.split(',').length : 1;
  }

  PlanNode buildPlan(Stmt stmt) {
    if (stmt is UnionStmt) return planUnion(stmt);
    if (stmt is IntersectStmt) return planIntersect(stmt);
    if (stmt is ExceptStmt) return planExcept(stmt);
    if (stmt is SelectStmt) return planSelect(stmt);
    throw Exception("Unsupported statement type for query planner: ${stmt.runtimeType}");
  }

  PlanNode planUnion(UnionStmt stmt) {
    final children = stmt.selectStmts.map((s) => planSelect(s)).toList();
    return UnionNode(children, stmt.isAllFlags);
  }

  PlanNode planIntersect(IntersectStmt stmt) {
    final children = stmt.selectStmts.map((s) => planSelect(s)).toList();
    return IntersectNode(children);
  }

  PlanNode planExcept(ExceptStmt stmt) {
    final children = stmt.selectStmts.map((s) => planSelect(s)).toList();
    return ExceptNode(children);
  }

  PlanNode planSelect(SelectStmt stmt) {
    if (stmt is CteSelectStmt) {
      if (stmt.isRecursive) {
        final cteName = stmt.ctes.keys.first;
        final cteStmt = stmt.ctes[cteName]!;
        SelectStmt anchorStmt;
        SelectStmt recursiveStmt;
        if (cteStmt is UnionStmt) {
          anchorStmt = cteStmt.selectStmts.first;
          recursiveStmt = cteStmt.selectStmts.last;
        } else if (cteStmt is SelectStmt) {
          anchorStmt = cteStmt;
          recursiveStmt = cteStmt;
        } else {
          final rewritten = _substituteCtes(stmt.mainSelect, stmt.ctes);
          return planSelect(rewritten);
        }
        return _planWithRecursiveCte(stmt, anchorStmt, recursiveStmt, cteName);
      } else {
        final rewritten = _substituteCtes(stmt.mainSelect, stmt.ctes);
        return planSelect(rewritten);
      }
    }
    stmt = _rewriteSelectStmt(stmt);

    TableSchema schema;
    late PlanNode scanNode;
    bool isParallelScan = false;
    List<Projection> projections = stmt.projections;

    IndexSchema? targetIndexSchema;
    List<double>? lowKeys;
    List<double>? highKeys;
    bool useIndexScan = false;
    bool needFilterNode = false;

    if (stmt.fromSubquery != null) {
      final subPlan = planSelect(stmt.fromSubquery!);
      final List<String> colNames = [];
      final List<DataType> colTypes = [];
      for (final proj in stmt.fromSubquery!.projections) {
        if (proj.alias != null) {
          colNames.add(proj.alias!);
        } else if (proj.expr is VariableExpr) {
          colNames.add((proj.expr as VariableExpr).path.last);
        } else {
          colNames.add(exprToSqlString(proj.expr));
        }
        colTypes.add(DataType.text);
      }
      final subqueryAlias = stmt.tableAlias ?? 'subquery';
      schema = TableSchema(
        name: subqueryAlias,
        columnNames: colNames,
        columnTypes: colTypes,
      );
      scanNode = SubqueryScanNode(subPlan, alias: stmt.tableAlias, selectColumns: colNames);
      projections = stmt.projections;
      if (projections.length == 1 &&
          projections[0].expr is VariableExpr &&
          (projections[0].expr as VariableExpr).path.first == '*') {
        final list = <Projection>[];
        for (final col in schema.columnNames) {
          list.add(Projection(VariableExpr([col]), null));
        }
        for (final join in stmt.joins) {
          final joinTable = join.tableName.toLowerCase();
          final joinSchema = catalog.getTableSchema(joinTable);
          if (joinSchema != null) {
            for (final col in joinSchema.columnNames) {
              list.add(Projection(VariableExpr([joinSchema.name, col]), null));
            }
          }
        }
        projections = list;
      }
    } else if (stmt.fromFunction != null) {
      final colNames = <String>[];
      final colTypes = <DataType>[];
      try {
        final val = evaluateExpression(stmt.fromFunction!, {});
        print("--- TVF EVAL VAL: $val (${val.runtimeType}) ---");
        List<dynamic> elements = [];
        if (val is DbList) {
          elements = val.elements;
        } else if (val is DbJson && val.value is List) {
          elements = val.value as List;
        } else if (val is DbText) {
          try {
            final decoded = json.decode(val.value);
            if (decoded is List) elements = decoded;
          } catch (_) {}
        }
        if (elements.isNotEmpty) {
          final first = elements.first;
          if (first is Map) {
            for (final k in first.keys) {
              colNames.add(k.toString());
              colTypes.add(DataType.text);
            }
          } else if (first is List) {
            for (int i = 0; i < first.length; i++) {
              colNames.add('col$i');
              colTypes.add(DataType.text);
            }
          } else if (first is DbJson && first.value is Map) {
            final map = first.value as Map;
            for (final k in map.keys) {
              colNames.add(k.toString());
              colTypes.add(DataType.text);
            }
          } else if (first is DbList) {
            for (int i = 0; i < first.elements.length; i++) {
              colNames.add('col$i');
              colTypes.add(first.elements[i].type);
            }
          } else if (first is DbJson && first.value is List) {
            final list = first.value as List;
            for (int i = 0; i < list.length; i++) {
              colNames.add('col$i');
              colTypes.add(DataType.text);
            }
          } else {
            colNames.add('value');
            colTypes.add(first is DbValue ? first.type : DataType.text);
          }
        }
      } catch (_) {}
      if (colNames.isEmpty) {
        colNames.add('value');
        colTypes.add(DataType.text);
      }
      final funcAlias = stmt.tableAlias ?? stmt.fromFunction!.name;
      schema = TableSchema(
        name: funcAlias,
        columnNames: colNames,
        columnTypes: colTypes,
      );
      scanNode = FunctionScanNode(stmt.fromFunction!, alias: stmt.tableAlias);
      projections = stmt.projections;
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
    } else {
      final tableName = stmt.tableName.toLowerCase();
      final loadedSchema = catalog.getTableSchema(tableName);
      print('Planner loaded schema for $tableName: isForeign=${loadedSchema?.isForeign}');
      if (loadedSchema == null) {
        if (tableName.isEmpty) {
          final colNames = <String>[];
          final colTypes = <DataType>[];
          for (final proj in stmt.projections) {
            if (proj.alias != null) {
              colNames.add(proj.alias!);
            } else if (proj.expr is VariableExpr) {
              colNames.add((proj.expr as VariableExpr).path.last);
            } else {
              colNames.add(exprToSqlString(proj.expr));
            }
            colTypes.add(DataType.text);
          }
          if (colNames.isEmpty) {
            colNames.add('dual');
            colTypes.add(DataType.text);
          }
          schema = TableSchema(name: 'dual', columnNames: colNames, columnTypes: colTypes);
          scanNode = MemoryScanNode([<String, DbValue>{}]);
        } else {
          throw Exception("Table '$tableName' does not exist in catalog.");
        }
      } else {
        schema = loadedSchema;
      }

      projections = stmt.projections;
      if (projections.length == 1 &&
          projections[0].expr is VariableExpr &&
          (projections[0].expr as VariableExpr).path.first == '*') {
        final list = <Projection>[];
        for (final col in schema.columnNames) {
          list.add(Projection(VariableExpr([col]), null));
        }
        for (final join in stmt.joins) {
          final joinTable = join.tableName.toLowerCase();
          final joinSchema = catalog.getTableSchema(joinTable);
          if (joinSchema != null) {
            for (final col in joinSchema.columnNames) {
              list.add(Projection(VariableExpr([joinSchema.name, col]), null));
            }
          }
        }
        projections = list;
      }

      if (schema.partitionChildren.isNotEmpty) {
        final childrenNodes = <PlanNode>[];
        for (final child in schema.partitionChildren) {
          final childStmt = SelectStmt(
            projections: [Projection(VariableExpr(['*']), null)],
            tableName: child,
          );
          PlanNode childNode = planSelect(childStmt);
          final parentAlias = stmt.tableAlias ?? stmt.tableName;
          childNode = SubqueryScanNode(childNode, alias: parentAlias, selectColumns: schema.columnNames);
          childrenNodes.add(childNode);
        }
        if (childrenNodes.isEmpty) {
          scanNode = MemoryScanNode([]);
        } else if (childrenNodes.length == 1) {
          scanNode = childrenNodes.first;
        } else {
          scanNode = UnionNode(childrenNodes, List.filled(childrenNodes.length - 1, true));
        }
      } else {
    // Check if we can use HNSW index scan for ORDER BY vector_distance
    if (stmt.orderBy != null) {
      final orderExpr = stmt.orderBy!.expr;
      FunctionCallExpr? vectorDistExpr;
      if (orderExpr is FunctionCallExpr && orderExpr.name.toLowerCase() == 'vector_distance') {
        vectorDistExpr = orderExpr;
      } else if (orderExpr is VariableExpr) {
        final alias = orderExpr.path.last.toLowerCase();
        for (final proj in stmt.projections) {
          if (proj.alias?.toLowerCase() == alias && proj.expr is FunctionCallExpr) {
            final func = proj.expr as FunctionCallExpr;
            if (func.name.toLowerCase() == 'vector_distance') {
              vectorDistExpr = func;
              break;
            }
          }
        }
      }

      if (vectorDistExpr != null && (vectorDistExpr.arguments.length == 2 || vectorDistExpr.arguments.length == 3)) {
        final firstArg = vectorDistExpr.arguments[0];
        if (firstArg is VariableExpr) {
          final colName = firstArg.path.last.toLowerCase();
          final idx = catalog.getIndexForColumn(tableName, colName);
          if (idx != null && (idx.usingMethod == 'hnsw' || idx.usingMethod == 'ivf_flat')) {
            var queryVecVal = evaluateExpression(vectorDistExpr.arguments[1], {});
            if (queryVecVal is DbText) {
              final text = queryVecVal.value.trim();
              if (text.startsWith('[') && text.endsWith(']')) {
                try {
                  final elements = text.substring(1, text.length - 1).split(',').map((e) => double.parse(e.trim())).toList();
                  queryVecVal = DbVector(elements);
                } catch (_) {}
              }
            }
            if (queryVecVal is DbVector) {
              String metric = 'euclidean';
              if (vectorDistExpr.arguments.length == 3) {
                final metricVal = evaluateExpression(vectorDistExpr.arguments[2], {});
                if (metricVal is DbText) {
                  metric = metricVal.value.toLowerCase();
                }
              }
              final limit = stmt.limit ?? 10;
              final rowTableFile = RowTableFile(cache: cache, tableName: schema.name, dbDirectory: dbDirectory);
              final isIvf = idx.usingMethod == 'ivf_flat';
              final indexFile = '$dbDirectory/${idx.name.toLowerCase()}.${isIvf ? 'ivf_flat' : 'hnsw'}';
              
              PlanNode plan;
              if (isIvf) {
                final ivfIndex = IvfFlatIndex(indexPath: indexFile, autoSave: false, metric: metric);
                plan = IvfFlatScanNode(
                  tableFile: rowTableFile,
                  schema: schema,
                  index: ivfIndex,
                  queryVector: queryVecVal,
                  limit: limit,
                  filterCondition: stmt.whereCondition,
                );
              } else {
                final hnswIndex = HnswIndex(indexPath: indexFile, autoSave: false, metric: metric);
                plan = HnswScanNode(
                  tableFile: rowTableFile,
                  schema: schema,
                  index: hnswIndex,
                  queryVector: queryVecVal,
                  limit: limit,
                  filterCondition: stmt.whereCondition,
                );
              }
              
              if (schema.policies.isNotEmpty) {
                Expression combinedPolicy = schema.policies.first.condition;
                for (int i = 1; i < schema.policies.length; i++) {
                  combinedPolicy = BinaryExpr('OR', combinedPolicy, schema.policies[i].condition);
                }
                plan = FilterNode(plan, combinedPolicy);
              }
              
              var projections = stmt.projections;
              if (projections.length == 1 &&
                  projections[0].expr is VariableExpr &&
                  (projections[0].expr as VariableExpr).path.first == '*') {
                final list = <Projection>[];
                for (final col in schema.columnNames) {
                  list.add(Projection(VariableExpr([col]), null));
                }
                projections = list;
              }
              
              plan = ProjectNode(plan, projections);
              return plan;
            }
          }
        }
      }
    }

    isParallelScan = false;

    targetIndexSchema = null;
    lowKeys = null;
    highKeys = null;
    useIndexScan = false;
    needFilterNode = false;

    if (!schema.isColumnar && stmt.whereCondition != null) {
      final matchExpr = _findMatchExpr(stmt.whereCondition!);
      if (matchExpr != null) {
        scanNode = FtsScanNode(
          tableName: tableName,
          columnName: matchExpr.columnName,
          searchQuery: matchExpr.searchQuery,
          dbDirectory: dbDirectory,
          cache: cache,
          catalog: catalog,
        );
        useIndexScan = true;
      } else {
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
          bool isPureEquality = false;
          if (stmt.whereCondition is BinaryExpr) {
            final bin = stmt.whereCondition as BinaryExpr;
            if (bin.operator == '=' && bin.left is VariableExpr) {
              final varCol = (bin.left as VariableExpr).path.last.toLowerCase().trim();
              if (indexColsSet.contains(varCol)) {
                isPureEquality = true;
              }
            }
          }
          if (!isPureEquality) {
            needFilterNode = true;
          } else {
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
    }
  }

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
      final btreeIndex = BTreeIndex(cache: cache, indexPath: indexFile, keyColumns: _getKeyColumnsCount(targetIndexSchema));
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
    } else if (!useIndexScan && stmt.fromSubquery == null && stmt.fromFunction == null && stmt.tableName.isNotEmpty) {
      final rowTableFile = RowTableFile(
        cache: cache,
        tableName: schema.name,
        dbDirectory: dbDirectory,
      );
      if (schema.isForeign) {
        final dummyStmt = CreateForeignTableStmt(
          schema.name,
          List.generate(schema.columnNames.length, (i) => ColumnDef(schema.columnNames[i], schema.columnTypes[i])),
          schema.foreignServer!,
          schema.foreignOptions!
        );
        scanNode = ForeignScanNode(dummyStmt);
      } else {
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
        int? asOfTxId;
        if (stmt.asOfClause != null) {
          final val = evaluateExpression(stmt.asOfClause!.expr, {});
          if (val is DbInt) {
            asOfTxId = val.value;
          } else if (val is DbDouble) {
            asOfTxId = val.value.toInt();
          } else {
            asOfTxId = int.tryParse(val.toString());
          }
        }
        scanNode = RowScanNode(rowTableFile, schema, neededColIndexes, asOfTxId);
      }
    }
    }
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

    final List<String> leftColumns = [];
    for (final col in schema.columnNames) {
      leftColumns.add(col);
      leftColumns.add('${schema.name}.$col');
    }

    if (stmt.joins.length > 1 && catalog.enableCBO) {
      stmt.joins.sort((a, b) {
        double getCost(Join j) {
          final table = j.tableName.toLowerCase();
          final stats = catalog.getTableStats(table);
          if (stats == null) return 10000.0;
          
          double selectivity = 0.1;
          String joinCol = '';
          if (j.onCondition is BinaryExpr && (j.onCondition as BinaryExpr).operator == '=') {
            final bin = j.onCondition as BinaryExpr;
            if (bin.left is VariableExpr && (bin.left as VariableExpr).path.first.toLowerCase() == table) {
              joinCol = (bin.left as VariableExpr).path.last.toLowerCase();
            } else if (bin.right is VariableExpr && (bin.right as VariableExpr).path.first.toLowerCase() == table) {
              joinCol = (bin.right as VariableExpr).path.last.toLowerCase();
            }
          }
          if (joinCol.isNotEmpty && stats.histograms.containsKey(joinCol)) {
            selectivity = stats.histograms[joinCol]!.calculateSelectivity(0.0);
          } else if (joinCol.isNotEmpty && stats.columnStats.containsKey(joinCol)) {
            final dist = stats.columnStats[joinCol]!.distinctCount;
            if (dist > 0) selectivity = 1.0 / dist;
          }
          return stats.rowCount * selectivity;
        }
        return getCost(a).compareTo(getCost(b));
      });
    }

    // 1. Handle JOIN
    for (final join in stmt.joins) {
      PlanNode joinScan;
      TableSchema joinSchema;
      String joinTable = '';
      if (join.fromSubquery != null) {
        final subPlan = planSelect(join.fromSubquery!);
        final List<String> colNames = [];
        final List<DataType> colTypes = [];
        for (final proj in join.fromSubquery!.projections) {
          if (proj.alias != null) {
            colNames.add(proj.alias!);
          } else if (proj.expr is VariableExpr) {
            colNames.add((proj.expr as VariableExpr).path.last);
          } else {
            colNames.add(exprToSqlString(proj.expr));
          }
          colTypes.add(DataType.text);
        }
        final joinAlias = join.alias ?? 'join_subquery';
        joinSchema = TableSchema(
          name: joinAlias,
          columnNames: colNames,
          columnTypes: colTypes,
        );
        joinScan = SubqueryScanNode(subPlan, alias: join.alias, selectColumns: colNames);
        joinTable = joinAlias;
      } else {
        joinTable = join.tableName.toLowerCase();
        final loadedJoinSchema = catalog.getTableSchema(joinTable);
        if (loadedJoinSchema == null) {
          throw Exception("Join table '$joinTable' does not exist.");
        }
        joinSchema = loadedJoinSchema;
        if (joinSchema.isColumnar) {
          // Collect all column indexes needed for join table
          final neededJoinColIndexes = _getReferencedColumnIndexesForJoin(stmt, join, joinSchema);
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
          final neededJoinColIndexes = _getReferencedColumnIndexesForJoin(stmt, join, joinSchema);
          joinScan = RowScanNode(rowTableFile, joinSchema, neededJoinColIndexes);
        }
      }

      if (joinSchema.policies.isNotEmpty) {
        Expression combinedJoinPolicy = joinSchema.policies.first.condition;
        for (int i = 1; i < joinSchema.policies.length; i++) {
          combinedJoinPolicy = BinaryExpr('OR', combinedJoinPolicy, joinSchema.policies[i].condition);
        }
        joinScan = FilterNode(joinScan, combinedJoinPolicy);
      }

      // Extract join columns from condition (e.g. users.dept_id = depts.id)
      final joinCond = join.onCondition;
      String leftJoinCol = '';
      String rightJoinCol = '';

      if (joinCond is BinaryExpr && joinCond.operator == '=') {
        if (joinCond.left is VariableExpr && joinCond.right is VariableExpr) {
          final leftVar = joinCond.left as VariableExpr;
          final rightVar = joinCond.right as VariableExpr;

          final tName = joinTable.toLowerCase();
          final tAlias = join.alias?.toLowerCase();

          final leftTable = leftVar.path[0].toLowerCase();
          final rightTable = rightVar.path[0].toLowerCase();

          if (rightTable == tName || (tAlias != null && rightTable == tAlias)) {
            leftJoinCol = leftVar.path.sublist(1).join('.');
            rightJoinCol = rightVar.path.sublist(1).join('.');
          } else if (leftTable == tName || (tAlias != null && leftTable == tAlias)) {
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
        final rightIndex = BTreeIndex(cache: cache, indexPath: indexFile!, keyColumns: _getKeyColumnsCount(idx!));
        currentPlan = IndexJoinNode(
          left: currentPlan,
          rightTable: rightTableFile,
          rightIndex: rightIndex,
          leftJoinCol: leftJoinCol,
          rightSchema: joinSchema,
          isLeftJoin: join.isLeftJoin,
          isRightJoin: join.isRightJoin,
          isFullJoin: join.isFullJoin,
          leftColumns: List<String>.from(leftColumns),
        );
      } else {
        currentPlan = HashJoinNode(
          left: currentPlan,
          right: joinScan,
          leftJoinCol: leftJoinCol,
          rightJoinCol: rightJoinCol,
          isLeftJoin: join.isLeftJoin,
          isRightJoin: join.isRightJoin,
          isFullJoin: join.isFullJoin,
          leftColumns: List<String>.from(leftColumns),
          rightSchema: joinSchema,
        );
      }

      for (final col in joinSchema.columnNames) {
        leftColumns.add(col);
        leftColumns.add('${joinSchema.name}.$col');
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
        targetIndex = BTreeIndex(cache: cache, indexPath: indexFile!, keyColumns: _getKeyColumnsCount(idx!));
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

    // 2.5 Handle GROUP BY and Window Functions
    final windowExprs = _findWindowExpressions(projections);
    if (windowExprs.isNotEmpty) {
      if (stmt.groupBy != null && !isParallelScan) {
        currentPlan = GroupByNode(currentPlan, stmt.groupBy!, projections, havingCondition: stmt.havingCondition);
      } else if (_hasAggregate(projections) && !isParallelScan) {
        currentPlan = GroupByNode(currentPlan, LiteralExpr(1), projections, havingCondition: stmt.havingCondition);
      }
      
      for (final windowExpr in windowExprs) {
        currentPlan = WindowNode(currentPlan, windowExpr);
      }
      
      if (stmt.groupBy == null && !_hasAggregate(projections) && !isParallelScan) {
        currentPlan = ProjectNode(currentPlan, projections);
      }
    } else {
      if (stmt.groupBy != null && !isParallelScan) {
        currentPlan = GroupByNode(currentPlan, stmt.groupBy!, projections, havingCondition: stmt.havingCondition);
      } else if (_hasAggregate(projections) && !isParallelScan) {
        currentPlan = GroupByNode(currentPlan, LiteralExpr(1), projections, havingCondition: stmt.havingCondition);
      } else if (!isParallelScan) {
        // 4. Handle Projection (if not grouped)
        currentPlan = ProjectNode(currentPlan, projections);
      }
    }

    // For parallel scan with having condition, filter using a filter node post-aggregation
    if (isParallelScan && stmt.havingCondition != null) {
      currentPlan = FilterNode(currentPlan, stmt.havingCondition!);
    }

    if (stmt.isDistinct) {
      currentPlan = DistinctNode(currentPlan);
    }

    // 3. Handle ORDER BY Clause
    if (stmt.orderBy != null) {
      currentPlan = SortNode(currentPlan, stmt.orderBy!.expr, stmt.orderBy!.ascending);
    }

    // 5. Handle LIMIT Clause
    if (stmt.limit != null) {
      currentPlan = LimitNode(currentPlan, stmt.limit!, stmt.offset ?? 0);
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
    for (final join in stmt.joins) {
      _collectVariables(join.onCondition, referencedNames);
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

  List<int> _getReferencedColumnIndexesForJoin(SelectStmt stmt, Join join, TableSchema joinSchema) {
    final referencedNames = <String>{};
    _collectVariables(join.onCondition, referencedNames);
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
    } else if (expr is JsonExtractExpr) {
      _collectVariables(expr.expr, collected);
    } else if (expr is BinaryExpr) {
      _collectVariables(expr.left, collected);
      _collectVariables(expr.right, collected);
    } else if (expr is FunctionCallExpr) {
      for (final arg in expr.arguments) {
        _collectVariables(arg, collected);
      }
    } else if (expr is WindowFunctionExpr) {
      for (final partition in expr.partitionBy) {
        _collectVariables(partition, collected);
      }
      if (expr.orderBy != null) {
        _collectVariables(expr.orderBy!.expr, collected);
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
    if (expr is JsonExtractExpr) {
      return _hasAggregateExpr(expr.expr);
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
    if (expr is BinaryExpr) {
      final op = expr.operator;
      final left = expr.left;
      final right = expr.right;
      if (right is LiteralExpr || right is PlaceholderExpr) {
        final leftSql = exprToSqlString(left);
        final colName = _normalizeExprString(leftSql, tableName);
        final val = _resolveValue(right);
        if (val is num) {
          final valD = val.toDouble();
          if (op == '=') return RangeCondition(colName: colName, low: valD, high: valD);
          if (op == '>=') return RangeCondition(colName: colName, low: valD, high: null);
          if (op == '>') return RangeCondition(colName: colName, low: valD + 0.000001, high: null);
          if (op == '<=') return RangeCondition(colName: colName, low: null, high: valD);
          if (op == '<') return RangeCondition(colName: colName, low: null, high: valD - 0.000001);
        }
      } else if (left is LiteralExpr || left is PlaceholderExpr) {
        final rightSql = exprToSqlString(right);
        final colName = _normalizeExprString(rightSql, tableName);
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
      if (expr is JsonExtractExpr) {
        return JsonExtractExpr(
          rewriteExpr(expr.expr),
          expr.path,
          expr.asText,
        );
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
      if (expr is WindowFunctionExpr) {
        return WindowFunctionExpr(
          functionName: expr.functionName,
          partitionBy: expr.partitionBy.map(rewriteExpr).toList(),
          orderBy: expr.orderBy != null
              ? OrderBy(rewriteExpr(expr.orderBy!.expr), expr.orderBy!.ascending)
              : null,
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
      fromSubquery: stmt.fromSubquery,
      fromFunction: stmt.fromFunction,
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
      final bool isSimple = idx.columnName.split(',').every((col) => schema.columnNamesLower.contains(col.trim().toLowerCase()));
      final List<String> idxCols = isSimple 
          ? idx.columnName.split(',').map((c) => c.trim().toLowerCase()).toList()
          : [idx.columnName.toLowerCase()];
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
        final targetNorm = _normalizeExprString(colName, tableName);
        if (right is LiteralExpr || right is PlaceholderExpr) {
          final leftSql = exprToSqlString(left);
          final leftNorm = _normalizeExprString(leftSql, tableName);
          if (leftNorm == targetNorm) {
            return _dbValueToDouble(_resolveValue(right));
          }
        }
        if (left is LiteralExpr || left is PlaceholderExpr) {
          final rightSql = exprToSqlString(right);
          final rightNorm = _normalizeExprString(rightSql, tableName);
          if (rightNorm == targetNorm) {
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

  List<WindowFunctionExpr> _findWindowExpressions(List<Projection> projections) {
    final list = <WindowFunctionExpr>[];
    for (final proj in projections) {
      _collectWindowExpressions(proj.expr, list);
    }
    return list;
  }

  void _collectWindowExpressions(Expression expr, List<WindowFunctionExpr> list) {
    if (expr is WindowFunctionExpr) {
      list.add(expr);
    } else if (expr is BinaryExpr) {
      _collectWindowExpressions(expr.left, list);
      _collectWindowExpressions(expr.right, list);
    } else if (expr is FunctionCallExpr) {
      for (final arg in expr.arguments) {
        _collectWindowExpressions(arg, list);
      }
    }
  }

  SelectStmt _substituteCtes(SelectStmt stmt, Map<String, dynamic> ctes) {
    final lowerTableName = stmt.tableName.toLowerCase();
    SelectStmt? fromSubquery = stmt.fromSubquery;
    String tableName = stmt.tableName;
    
    if (ctes.containsKey(lowerTableName)) {
      fromSubquery = ctes[lowerTableName];
      tableName = stmt.tableAlias ?? stmt.tableName;
    }
    
    if (fromSubquery != null) {
      fromSubquery = _substituteCtes(fromSubquery, ctes);
    }
    
    final newJoins = <Join>[];
    for (final join in stmt.joins) {
      final lowerJoinTable = join.tableName.toLowerCase();
      SelectStmt? joinSubquery = join.fromSubquery;
      String joinTable = join.tableName;
      
      if (ctes.containsKey(lowerJoinTable)) {
        joinSubquery = ctes[lowerJoinTable];
        joinTable = join.alias ?? join.tableName;
      }
      
      if (joinSubquery != null) {
        joinSubquery = _substituteCtes(joinSubquery, ctes);
      }
      
      newJoins.add(Join(
        joinTable,
        join.onCondition,
        fromSubquery: joinSubquery,
        alias: join.alias,
        isLeftJoin: join.isLeftJoin,
        isRightJoin: join.isRightJoin,
        isFullJoin: join.isFullJoin,
      ));
    }
    
    return SelectStmt(
      projections: stmt.projections,
      tableName: tableName,
      fromSubquery: fromSubquery,
      fromFunction: stmt.fromFunction,
      tableAlias: stmt.tableAlias,
      joins: newJoins,
      whereCondition: stmt.whereCondition,
      groupBy: stmt.groupBy,
      havingCondition: stmt.havingCondition,
      orderBy: stmt.orderBy,
      limit: stmt.limit,
      offset: stmt.offset,
      withRelationship: stmt.withRelationship,
      isDistinct: stmt.isDistinct,
    );
  }

  PlanNode _planWithRecursiveCte(CteSelectStmt stmt, SelectStmt anchorStmt, SelectStmt recursiveStmt, String cteName) {
    final anchorPlan = planSelect(anchorStmt);
    final recursiveNode = RecursiveCteNode(anchorPlan, (workingChild) {
      return _planRecursiveQuery(recursiveStmt, cteName, workingChild);
    });

    PlanNode currentPlan = recursiveNode;
    final mainSelect = stmt.mainSelect;

    if (mainSelect.whereCondition != null) {
      currentPlan = FilterNode(currentPlan, mainSelect.whereCondition!);
    }
    if (mainSelect.projections.isNotEmpty) {
      currentPlan = ProjectNode(currentPlan, mainSelect.projections);
    }
    if (mainSelect.orderBy != null) {
      currentPlan = SortNode(currentPlan, mainSelect.orderBy!.expr, mainSelect.orderBy!.ascending);
    }
    if (mainSelect.limit != null || mainSelect.offset != null) {
      currentPlan = LimitNode(currentPlan, mainSelect.limit ?? -1, mainSelect.offset ?? 0);
    }
    return currentPlan;
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

MatchExpr? _findMatchExpr(Expression expr) {
  if (expr is MatchExpr) return expr;
  if (expr is BinaryExpr) {
    return _findMatchExpr(expr.left) ?? _findMatchExpr(expr.right);
  }
  return null;
}

PlanNode _planRecursiveQuery(SelectStmt stmt, String cteName, PlanNode workingChild) {
  PlanNode current = workingChild;
  if (stmt.whereCondition != null) {
    current = FilterNode(current, stmt.whereCondition!);
  }
  if (stmt.projections.isNotEmpty) {
    current = ProjectNode(current, stmt.projections);
  }
  return current;
}

PlanNode _replaceScanWithNode(PlanNode plan, String tableName, PlanNode replacement) {
  final nameLower = tableName.toLowerCase();
  if (plan is SubqueryScanNode) {
    return replacement;
  }
  if (plan is RowScanNode && plan.schema.name.toLowerCase() == nameLower) {
    return replacement;
  }
  if (plan is ProjectNode) {
    return ProjectNode(_replaceScanWithNode(plan.child, tableName, replacement), plan.projections);
  }
  if (plan is FilterNode) {
    return FilterNode(_replaceScanWithNode(plan.child, tableName, replacement), plan.condition);
  }
  return plan;
}
