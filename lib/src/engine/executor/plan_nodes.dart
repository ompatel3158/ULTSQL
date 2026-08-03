import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../cache/page_cache.dart';
import '../cache/page.dart';
import '../parser/ast.dart';
import '../storage/table_file.dart';
import '../storage/catalog.dart';
import '../storage/btree_index.dart';
import 'value.dart';
import 'jit_compiler.dart';
import '../storage/hnsw_index.dart';
import '../storage/fts_index.dart';
import '../storage/ivf_flat_index.dart';
import '../fdw/fdw_manager.dart';

/// Abstract base class for Volcano-iterator physical execution plan nodes.
abstract class PlanNode {
  void open();
  Map<String, DbValue>? next();
  void close();
  String getPlanString([int indent = 0]);
}

// Expression Evaluator Helper (Standard Fallback)
bool matchLike(String str, String pattern) {
  final escaped = RegExp.escape(pattern)
      .replaceAll(r'\%', '%')
      .replaceAll(r'\_', '_')
      .replaceAll('%', '.*')
      .replaceAll('_', '.');
  final regex = RegExp('^$escaped\$', caseSensitive: false);
  return regex.hasMatch(str);
}

DbValue evaluateExpression(Expression expr, Map<String, DbValue> rowContext) {
  final sqlStr = exprToSqlString(expr);
  if (rowContext.containsKey(sqlStr)) {
    return rowContext[sqlStr]!;
  }
  for (final key in rowContext.keys) {
    if (key.toLowerCase() == sqlStr.toLowerCase()) {
      return rowContext[key]!;
    }
  }

  if (expr is SubqueryExpr) {
    final active = JitCompiler.activeInterpreter;
    if (active == null) {
      return DbNull();
    }
    SubqueryContext.push(rowContext);
    try {
      final res = active.executeNodeSync(expr.selectStmt);
      if (res != null) {
        final rows = res.rows;
        if (rows is List) {
          if (rows.isEmpty) {
            return DbList([]);
          }
          if (rows.length == 1 && rows[0].length == 1) {
            return rows[0][0];
          }
          return DbList(rows.map<DbValue>((r) => r.isNotEmpty ? r[0] as DbValue : DbNull()).toList());
        }
      }
      return DbNull();
    } finally {
      SubqueryContext.pop();
    }
  }

  if (expr is JsonExtractExpr) {
    final baseVal = evaluateExpression(expr.expr, rowContext);
    if (baseVal is DbJson) {
      final jsonMapOrList = baseVal.value;
      dynamic extractedRaw;
      if (jsonMapOrList is Map) {
        extractedRaw = jsonMapOrList[expr.path];
      } else if (jsonMapOrList is List) {
        final idx = int.tryParse(expr.path);
        if (idx != null && idx >= 0 && idx < jsonMapOrList.length) {
          extractedRaw = jsonMapOrList[idx];
        }
      }
      if (extractedRaw == null) {
        return DbNull();
      }
      if (expr.asText) {
        if (extractedRaw is String) {
          return DbText(extractedRaw);
        } else {
          return DbText(json.encode(extractedRaw));
        }
      } else {
        if (extractedRaw is int) {
          return DbInt(extractedRaw);
        } else if (extractedRaw is double) {
          return DbDouble(extractedRaw);
        } else if (extractedRaw is num) {
          return DbDouble(extractedRaw.toDouble());
        } else if (extractedRaw is bool) {
          return DbInt(extractedRaw ? 1 : 0);
        } else {
          return DbJson(extractedRaw);
        }
      }
    }
    return DbNull();
  }

  if (expr is PlaceholderExpr) {
    final idx = expr.index;
    if (idx != null) {
      final params = JitCompiler.currentParams;
      if (params != null && idx < params.length) {
        return params[idx];
      }
    }
    return DbNull();
  }

  if (expr is LiteralExpr) {
    return DbValue.parseLiteral(expr.value);
  }

  if (expr is VectorLiteralExpr) {
    return DbVector(expr.elements);
  }

  if (expr is VariableExpr) {
    final path = expr.path;
    if (path.isEmpty) return DbNull();

    final fullName = expr.fullName;
    final lowerName = fullName.toLowerCase();
    if (lowerName == 'true') {
      return DbJson(true);
    }
    if (lowerName == 'false') {
      return DbJson(false);
    }

    if (rowContext.containsKey(fullName)) {
      return rowContext[fullName]!;
    }

    if (path.length >= 2) {
      final possibleColName = '${path[0]}.${path[1]}';
      if (rowContext.containsKey(possibleColName)) {
        final colVal = rowContext[possibleColName]!;
        if (colVal is DbJson) {
          return colVal.extractPath(path.sublist(2));
        }
      }
    }

    if (path.length >= 2) {
      final colName = path[0];
      if (rowContext.containsKey(colName)) {
        final colVal = rowContext[colName]!;
        if (colVal is DbJson) {
          return colVal.extractPath(path.sublist(1));
        }
      }
      for (final key in rowContext.keys) {
        if (key.endsWith('.$colName')) {
          final colVal = rowContext[key]!;
          if (colVal is DbJson) {
            return colVal.extractPath(path.sublist(1));
          }
        }
      }
    }

    final name = path[0];
    for (final entry in rowContext.entries) {
      final key = entry.key;
      if (key == name || key.endsWith('.$name')) {
        return entry.value;
      }
    }

    final parentVal = SubqueryContext.lookup(expr.fullName);
    if (parentVal != null) {
      return parentVal;
    }

    return DbNull();
  }

  if (expr is BinaryExpr) {
    final leftVal = evaluateExpression(expr.left, rowContext);
    final rightVal = evaluateExpression(expr.right, rowContext);

    switch (expr.operator.toLowerCase()) {
      case '+':
        return leftVal + rightVal;
      case '-':
        return leftVal - rightVal;
      case '*':
        return leftVal * rightVal;
      case '/':
        return leftVal / rightVal;
      case '%':
        if (leftVal is DbInt && rightVal is DbInt) {
          return DbInt(leftVal.value % rightVal.value);
        } else if (leftVal is DbInt && rightVal is DbDouble) {
          return DbDouble(leftVal.value % rightVal.value);
        } else if (leftVal is DbDouble && rightVal is DbInt) {
          return DbDouble(leftVal.value % rightVal.value);
        } else if (leftVal is DbDouble && rightVal is DbDouble) {
          return DbDouble(leftVal.value % rightVal.value);
        }
        return DbNull();
      case '||':
        return leftVal.concat(rightVal);
      case '=':
        return DbInt(leftVal.compareTo(rightVal) == 0 ? 1 : 0);
      case '!=':
      case '<>':
        return DbInt(leftVal.compareTo(rightVal) != 0 ? 1 : 0);
      case '<':
        return DbInt(leftVal.compareTo(rightVal) < 0 ? 1 : 0);
      case '<=':
        return DbInt(leftVal.compareTo(rightVal) <= 0 ? 1 : 0);
      case '>':
        return DbInt(leftVal.compareTo(rightVal) > 0 ? 1 : 0);
      case '>=':
        return DbInt(leftVal.compareTo(rightVal) >= 0 ? 1 : 0);
      case 'like':
        return DbInt(matchLike(leftVal.toString(), rightVal.toString()) ? 1 : 0);
      case 'in':
        if (rightVal is DbList) {
          bool found = false;
          for (final elem in rightVal.elements) {
            if (leftVal.compareTo(elem) == 0) {
              found = true;
              break;
            }
          }
          return DbInt(found ? 1 : 0);
        } else {
          return DbInt(leftVal.compareTo(rightVal) == 0 ? 1 : 0);
        }
      case 'and':
        final leftTrue = (leftVal is DbInt && leftVal.value == 1) || (leftVal is DbDouble && leftVal.value > 0.0);
        final rightTrue = (rightVal is DbInt && rightVal.value == 1) || (rightVal is DbDouble && rightVal.value > 0.0);
        return DbInt(leftTrue && rightTrue ? 1 : 0);
      case 'or':
        final leftTrue = (leftVal is DbInt && leftVal.value == 1) || (leftVal is DbDouble && leftVal.value > 0.0);
        final rightTrue = (rightVal is DbInt && rightVal.value == 1) || (rightVal is DbDouble && rightVal.value > 0.0);
        return DbInt(leftTrue || rightTrue ? 1 : 0);
      default:
        return DbNull();
    }
  }

  if (expr is FunctionCallExpr) {
    final name = expr.name.toLowerCase();
    final args = expr.arguments.map((a) => evaluateExpression(a, rowContext)).toList();
    if (name == 'in_list') {
      return DbList(args);
    }

    if (JitCompiler.activeInterpreter != null) {
      final active = JitCompiler.activeInterpreter!;
      final funcSchema = active.db.catalog.getFunction(name);
      if (funcSchema != null) {
        final savedEnv = Map<String, DbValue>.from(active.env);
        active.env.clear();
        for (int i = 0; i < funcSchema.params.length; i++) {
          final param = funcSchema.params[i];
          final argVal = i < args.length ? args[i] : DbNull();
          active.env[param.name] = argVal;
        }
        DbValue returnValue = DbNull();
        try {
          for (final stmt in funcSchema.body) {
            active.executeNodeSync(stmt);
          }
        } on ReturnException catch (e) {
          returnValue = e.value as DbValue;
        } finally {
          active.env.clear();
          active.env.addAll(savedEnv);
        }
        return returnValue;
      }
    }

    if (name == 'vector_distance' && (args.length == 2 || args.length == 3)) {
      var v1 = args[0];
      var v2 = args[1];
      String metric = 'euclidean';
      if (args.length == 3) {
        final metricVal = args[2];
        if (metricVal is DbText) {
          metric = metricVal.value.toLowerCase();
        }
      }
      if (v1 is DbText) {
        v1 = _parseVectorFromString(v1.value) ?? v1;
      }
      if (v2 is DbText) {
        v2 = _parseVectorFromString(v2.value) ?? v2;
      }
      if (v1 is DbVector && v2 is DbVector) {
        switch (metric) {
          case 'cosine':
            return DbDouble(v1.cosineDistanceTo(v2));
          case 'dot':
            return DbDouble(v1.dotProductTo(v2));
          case 'euclidean':
          default:
            return DbDouble(v1.distanceTo(v2));
        }
      }
    }
    if (name == 'cast' && args.length == 2) {
      final val = args[0];
      final typeStr = (expr.arguments[1] as LiteralExpr).value.toString();
      if (val is DbNull) return DbNull();
      if (typeStr == 'DataType.text') {
        return DbText(val.toString());
      } else if (typeStr == 'DataType.integer') {
        if (val is DbInt) return val;
        if (val is DbDouble) return DbInt(val.value.toInt());
        return DbInt(int.tryParse(val.toString()) ?? 0);
      } else if (typeStr == 'DataType.double') {
        if (val is DbDouble) return val;
        if (val is DbInt) return DbDouble(val.value.toDouble());
        return DbDouble(double.tryParse(val.toString()) ?? 0.0);
      }
    }
    if (name == 'json_set' && args.length == 3) {
      return evalJsonSet(args[0], args[1], args[2]);
    }
    if (name == 'json_remove' && args.length == 2) {
      return evalJsonRemove(args[0], args[1]);
    }
    if (name == 'json_array') {
      return evalJsonArray(args);
    }
    if (name == 'json_object') {
      return evalJsonObject(args);
    }
    return DbNull();
  }

  return DbNull();
}

// Row-based Slotted Data Page Scan
class RowScanNode extends PlanNode {
  final RowTableFile tableFile;
  final TableSchema schema;
  final List<int>? projectedColIndexes;
  final int? asOfTxId;
  Iterator<List<DbValue>>? _iterator;

  late final List<int> _colsToLoad;
  late final List<String> _prefixKeys;
  late final List<String> _shortKeys;
  late final Map<String, int> _staticKeyToIndex;

  RowScanNode(this.tableFile, this.schema, [this.projectedColIndexes, this.asOfTxId]) {
    _colsToLoad = projectedColIndexes ?? List<int>.generate(schema.columnNames.length, (i) => i);
    _prefixKeys = _colsToLoad.map((idx) => '${schema.name}.${schema.columnNames[idx]}').toList();
    _shortKeys = _colsToLoad.map((idx) => schema.columnNames[idx]).toList();
    _staticKeyToIndex = {};
    for (int i = 0; i < _colsToLoad.length; i++) {
      final colIdx = _colsToLoad[i];
      _staticKeyToIndex[_prefixKeys[i]] = colIdx;
      _staticKeyToIndex[_shortKeys[i]] = colIdx;
    }
  }

  @override
  void open() {
    final currentTx = tableFile.cache.currentMvccTx;
    _iterator = tableFile.scanSync(
      currentTxId: currentTx?.txId ?? 0,
      activeTxIds: currentTx?.activeTxIds ?? const <int>{},
      txManager: tableFile.cache.mvccTxManager,
      projectedColIndexes: _colsToLoad,
      expectedColumnCount: schema.columnNames.length,
      asOfTxId: asOfTxId,
    ).iterator;
  }

  @override
  Map<String, DbValue>? next() {
    if (_iterator == null) return null;
    final hasNext = _iterator!.moveNext();
    if (!hasNext) return null;

    final values = _iterator!.current;
    return RowMap(values, _staticKeyToIndex);
  }

  @override
  void close() {
    _iterator = null;
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final colsStr = projectedColIndexes != null ? ', projected: $projectedColIndexes' : '';
    return '${padding}RowScanNode(table: ${schema.name}$colsStr)';
  }
}

class SubqueryScanNode extends PlanNode {
  final PlanNode child;
  final String? alias;
  final List<String> selectColumns;

  SubqueryScanNode(this.child, {this.alias, required this.selectColumns});

  @override
  void open() {
    child.open();
  }

  @override
  Map<String, DbValue>? next() {
    final row = child.next();
    if (row == null) return null;

    final newRow = <String, DbValue>{};
    for (final entry in row.entries) {
      final key = entry.key;
      newRow[key] = entry.value;

      final parts = key.split('.');
      final shortName = parts.last;
      newRow[shortName] = entry.value;
      if (alias != null) {
        newRow['${alias!.toLowerCase()}.$shortName'] = entry.value;
      }
    }
    return newRow;
  }

  @override
  void close() {
    child.close();
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final aliasStr = alias != null ? ' AS $alias' : '';
    return '${padding}SubqueryScanNode$aliasStr\n${child.getPlanString(indent + 1)}';
  }
}

class FunctionScanNode extends PlanNode {
  final FunctionCallExpr functionCall;
  final String? alias;
  
  List<Map<String, DbValue>>? _rows;
  int _cursor = 0;

  FunctionScanNode(this.functionCall, {this.alias});

  @override
  void open() {
    _cursor = 0;
    _rows = [];
    
    final active = JitCompiler.activeInterpreter;
    if (active == null) {
      return;
    }
    
    final dbVal = evaluateExpression(functionCall, {});
    List<dynamic> elements = [];
    if (dbVal is DbList) {
      elements = dbVal.elements;
    } else if (dbVal is DbJson) {
      if (dbVal.value is List) {
        elements = dbVal.value as List;
      }
    } else if (dbVal is DbText) {
      try {
        final decoded = json.decode(dbVal.value);
        if (decoded is List) {
          elements = decoded;
        }
      } catch (_) {}
    }
    
    for (final element in elements) {
      final rowMap = <String, DbValue>{};
      if (element is Map) {
        element.forEach((k, v) {
          final colName = k.toString();
          final dbV = DbValue.parseLiteral(v);
          rowMap[colName] = dbV;
          if (alias != null) {
            rowMap['${alias!.toLowerCase()}.$colName'] = dbV;
          } else {
            rowMap['${functionCall.name.toLowerCase()}.$colName'] = dbV;
          }
        });
      } else if (element is List) {
        for (int i = 0; i < element.length; i++) {
          final colName = 'col$i';
          final dbV = DbValue.parseLiteral(element[i]);
          rowMap[colName] = dbV;
          if (alias != null) {
            rowMap['${alias!.toLowerCase()}.$colName'] = dbV;
          } else {
            rowMap['${functionCall.name.toLowerCase()}.$colName'] = dbV;
          }
        }
      } else if (element is DbJson && element.value is Map) {
        final map = element.value as Map;
        map.forEach((k, v) {
          final colName = k.toString();
          final dbV = DbValue.parseLiteral(v);
          rowMap[colName] = dbV;
          if (alias != null) {
            rowMap['${alias!.toLowerCase()}.$colName'] = dbV;
          } else {
            rowMap['${functionCall.name.toLowerCase()}.$colName'] = dbV;
          }
        });
      } else if (element is DbList) {
        for (int i = 0; i < element.elements.length; i++) {
          final colName = 'col$i';
          final dbV = element.elements[i];
          rowMap[colName] = dbV;
          if (alias != null) {
            rowMap['${alias!.toLowerCase()}.$colName'] = dbV;
          } else {
            rowMap['${functionCall.name.toLowerCase()}.$colName'] = dbV;
          }
        }
      } else if (element is DbJson && element.value is List) {
        final list = element.value as List;
        for (int i = 0; i < list.length; i++) {
          final colName = 'col$i';
          final dbV = DbValue.parseLiteral(list[i]);
          rowMap[colName] = dbV;
          if (alias != null) {
            rowMap['${alias!.toLowerCase()}.$colName'] = dbV;
          } else {
            rowMap['${functionCall.name.toLowerCase()}.$colName'] = dbV;
          }
        }
      } else {
        final colName = 'value';
        final dbV = element is DbValue ? element : DbValue.parseLiteral(element);
        rowMap[colName] = dbV;
        if (alias != null) {
          rowMap['${alias!.toLowerCase()}.$colName'] = dbV;
        } else {
          rowMap['${functionCall.name.toLowerCase()}.$colName'] = dbV;
        }
      }
      _rows!.add(rowMap);
    }
  }

  @override
  Map<String, DbValue>? next() {
    if (_rows == null || _cursor >= _rows!.length) return null;
    return _rows![_cursor++];
  }

  @override
  void close() {
    _rows = null;
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final aliasStr = alias != null ? ' AS $alias' : '';
    return '${padding}FunctionScanNode(${exprToSqlString(functionCall)}$aliasStr)';
  }
}

// Foreign Data Wrapper Scan Node
class ForeignScanNode extends PlanNode {
  final CreateForeignTableStmt stmt;
  List<Map<String, DbValue>>? _rows;
  int _cursor = 0;

  ForeignScanNode(this.stmt);

  @override
  void open() {
    _rows = [];
    _cursor = 0;
    // For simplicity in this synchronous execution model, we load all rows synchronously
    // In a fully async engine, this would yield.
    final server = stmt.serverName.toLowerCase();
    var filename = stmt.options['filename'];
    if (filename == null) throw Exception('Foreign table requires filename in options');
    
    // Strip quotes if any
    if (filename.startsWith("'") && filename.endsWith("'")) {
      filename = filename.substring(1, filename.length - 1);
    }
    
    final file = File(filename);
    if (!file.existsSync()) {
      print('Foreign file does not exist: $filename (absolute: ${file.absolute.path})');
      return;
    }

    if (server == 'csv') {
      final lines = file.readAsLinesSync();
      if (lines.isEmpty) return;
      final header = lines[0].split(',');
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        final parts = lines[i].split(',');
        final row = <String, DbValue>{};
        for (int j = 0; j < header.length && j < parts.length; j++) {
          final colName = header[j].trim();
          final val = parts[j].trim();
          final colNameLower = colName.toLowerCase();
          final def = stmt.columns.firstWhere((c) => c.name.toLowerCase() == colNameLower, orElse: () => ColumnDef(colName, DataType.text));
          
          DbValue dbVal;
          if (def.type == DataType.integer) {
            dbVal = DbInt(int.tryParse(val) ?? 0);
          } else if (def.type == DataType.double) {
            dbVal = DbDouble(double.tryParse(val) ?? 0.0);
          } else {
            dbVal = DbText(val);
          }
          row['${stmt.tableName.toLowerCase()}.$colNameLower'] = dbVal;
          row[colName] = dbVal;
          row[colNameLower] = dbVal;
        }
        _rows!.add(row);
      }
      print('ForeignScanNode loaded ${_rows!.length} rows');
    } else {
      throw Exception('Unsupported foreign server: $server');
    }
  }

  @override
  Map<String, DbValue>? next() {
    if (_rows == null || _cursor >= _rows!.length) return null;
    return _rows![_cursor++];
  }

  @override
  void close() {
    _rows = null;
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    return '${padding}ForeignScanNode(${stmt.tableName})';
  }
}

// Column-oriented Scan (loads ONLY requested columns)
class ColumnScanNode extends PlanNode {
  final ColumnTableFile tableFile;
  final TableSchema schema;
  final List<int> projectedColIndexes;
  final List<Iterator<DbValue>> _iterators = [];
  bool _hasMore = false;

  late final List<String> _prefixKeys;
  late final List<String> _shortKeys;

  ColumnScanNode(this.tableFile, this.schema, this.projectedColIndexes) {
    _prefixKeys = projectedColIndexes.map((idx) => '${schema.name}.${schema.columnNames[idx]}').toList();
    _shortKeys = projectedColIndexes.map((idx) => schema.columnNames[idx]).toList();
  }

  @override
  void open() {
    _iterators.clear();
    for (final colIdx in projectedColIndexes) {
      final iterable = tableFile.scanColumnSync(colIdx);
      _iterators.add(iterable.iterator);
    }
    _hasMore = _iterators.isNotEmpty;
    for (final it in _iterators) {
      final hasNext = it.moveNext(); // Prime the iterators
      if (!hasNext) {
        _hasMore = false;
      }
    }
  }

  final Map<String, DbValue> _reusedMap = {};

  @override
  Map<String, DbValue>? next() {
    if (!_hasMore || _iterators.isEmpty) return null;

    _reusedMap.clear();
    for (int i = 0; i < projectedColIndexes.length; i++) {
      final colIdx = projectedColIndexes[i];
      final it = _iterators[i];
      
      final val = it.current;
      _reusedMap[_prefixKeys[i]] = val;
      _reusedMap[_shortKeys[i]] = val;

      // Advance this column iterator for the next round
      final hasNext = it.moveNext();
      if (!hasNext) {
        _hasMore = false;
      }
    }
    return _reusedMap;
  }

  @override
  void close() {
    _iterators.clear();
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final cols = projectedColIndexes.map((idx) => schema.columnNames[idx]).join(', ');
    return '${padding}ColumnScanNode(table: ${schema.name}, columns: [$cols])';
  }
}

class IndexScanNode extends PlanNode {
  final RowTableFile tableFile;
  final TableSchema schema;
  final BTreeIndex index;
  final List<double>? low;
  final List<double>? high;
  final List<int> projectedColIndexes;

  List<BTreePointer>? _pointers;
  int _cursor = 0;
  Page? _pinnedPage;
  int? _pinnedPageId;
  int? _fastCount;

  late final List<String> _prefixKeys;
  late final List<String> _shortKeys;
  late final Map<String, int> _staticKeyToIndex;
  late final List<DbValue> _reusedRowList;

  IndexScanNode({
    required this.tableFile,
    required this.schema,
    required this.index,
    required this.low,
    required this.high,
    required this.projectedColIndexes,
  }) {
    _prefixKeys = projectedColIndexes.map((idx) => '${schema.name}.${schema.columnNames[idx]}').toList();
    _shortKeys = projectedColIndexes.map((idx) => schema.columnNames[idx]).toList();
    _staticKeyToIndex = {};
    for (int i = 0; i < projectedColIndexes.length; i++) {
      final colIdx = projectedColIndexes[i];
      _staticKeyToIndex[_prefixKeys[i]] = colIdx;
      _staticKeyToIndex[_shortKeys[i]] = colIdx;
    }
    _reusedRowList = List<DbValue>.filled(schema.columnNames.length, DbNull());
  }

  int? getFastCount() {
    final sw = Stopwatch()..start();
    final currentTx = tableFile.cache.currentMvccTx;
    final txManager = tableFile.cache.mvccTxManager;
    if (currentTx != null && currentTx.txId != 0) {
      final status = txManager.txStatusMap[currentTx.txId];
      if (status == TxStatus.active) {
        return null;
      }
    }
    if (txManager.activeTxIds.isNotEmpty) {
      return null;
    }
    if (_fastCount != null) return _fastCount;
    if (_pointers != null) return _pointers!.length;
    index.initSync();
    _fastCount = index.countRangeSync(low, high);
    sw.stop();
    print('--> TIME: IndexScanNode.getFastCount took: ${sw.elapsedMicroseconds}us, count=$_fastCount');
    return _fastCount;
  }

  @override
  void open() {
    _fastCount = null;
    _pointers = null;
    _cursor = 0;
    _pinnedPage = null;
    _pinnedPageId = null;
  }

  bool _isRowVisible(RowTableFile tableFile, ByteData bd, int length) {
    if (length < 12) return true; // Non-MVCC records are always visible
    final xmin = bd.getUint32(0);
    final xmax = bd.getUint32(4);
    final currentTx = tableFile.cache.currentMvccTx;
    final txManager = tableFile.cache.mvccTxManager;
    final currentTxId = currentTx?.txId ?? 0;
    final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
    return txManager.isVisible(xmin, xmax, currentTxId, activeTxIds);
  }

  DbValue _getVisibleCellValue(RowTableFile tableFile, ByteData bd, int length, int colIndex) {
    if (length < 12) {
      return RecordSerializer.deserializeCellFromView(bd, 0, length, colIndex);
    }
    return RecordSerializer.deserializeCellFromView(bd, 12, length - 12, colIndex);
  }

  @override
  Map<String, DbValue>? next() {
    if (_pointers == null) {
      index.initSync();
      _pointers = index.searchRangeSync(low, high);
      if (projectedColIndexes.isNotEmpty && _pointers!.length > 250) {
        _pointers!.sort((a, b) {
          final cmp = a.pageId.compareTo(b.pageId);
          if (cmp != 0) return cmp;
          return a.slotId.compareTo(b.slotId);
        });
      }
    }
    while (_cursor < _pointers!.length) {
      final ptr = _pointers![_cursor++];
      
      // Keep page pinned if it is the same page
      if (_pinnedPageId != ptr.pageId) {
        if (_pinnedPage != null) {
          tableFile.cache.unpinPageSync(tableFile.filePath, _pinnedPageId!, isDirty: false);
        }
        _pinnedPage = tableFile.cache.pinPageSync(tableFile.filePath, ptr.pageId);
        _pinnedPageId = ptr.pageId;
      }

      final recBytes = SlottedPageHelper.getRecord(_pinnedPage!, ptr.slotId);
      if (recBytes != null) {
        final bd = ByteData.sublistView(recBytes);
        if (_isRowVisible(tableFile, bd, recBytes.length)) {
          _reusedRowList.fillRange(0, _reusedRowList.length, DbNull());
          for (int i = 0; i < projectedColIndexes.length; i++) {
            final idx = projectedColIndexes[i];
            _reusedRowList[idx] = _getVisibleCellValue(tableFile, bd, recBytes.length, idx);
          }
          return RowMap(_reusedRowList, _staticKeyToIndex);
        }
      }
    }
    
    if (_pinnedPage != null) {
      tableFile.cache.unpinPageSync(tableFile.filePath, _pinnedPageId!, isDirty: false);
      _pinnedPage = null;
      _pinnedPageId = null;
    }
    return null;
  }

  @override
  void close() {
    if (_pinnedPage != null) {
      tableFile.cache.unpinPageSync(tableFile.filePath, _pinnedPageId!, isDirty: false);
      _pinnedPage = null;
      _pinnedPageId = null;
    }
    _pointers = null;
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final indexName = index.indexPath.split('/').last.replaceAll('.idx', '');
    return '${padding}IndexScanNode(table: ${schema.name}, index: $indexName, range: [${low ?? '-∞'}, ${high ?? '∞'}])';
  }
}


class FilterNode extends PlanNode {
  final PlanNode child;
  final Expression condition;
  late final JitClosure _jitCond;

  FilterNode(this.child, this.condition) {
    _jitCond = JitCompiler.compile(condition);
  }

  @override
  void open() => child.open();

  @override
  Map<String, DbValue>? next() {
    while (true) {
      final row = child.next();
      if (row == null) return null;

      final res = _jitCond(row);
      if (res is DbInt && res.value == 1) {
        return row;
      }
      if (res is DbDouble && res.value > 0.0) {
        return row;
      }
    }
  }

  @override
  void close() => child.close();

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final childPlan = child.getPlanString(indent + 1);
    return '${padding}FilterNode(condition: ${exprToSqlString(condition)})\n$childPlan';
  }
}

class ProjectNode extends PlanNode {
  final PlanNode child;
  final List<Projection> projections;
  late final List<JitClosure> _jitProjs;

  ProjectNode(this.child, this.projections) {
    _jitProjs = projections.map((p) => JitCompiler.compile(p.expr)).toList();
  }

  @override
  void open() => child.open();

  @override
  Map<String, DbValue>? next() {
    final row = child.next();
    if (row == null) return null;

    final projectedRow = <String, DbValue>{};
    for (int i = 0; i < projections.length; i++) {
      final proj = projections[i];
      if (proj.expr is VariableExpr && (proj.expr as VariableExpr).path.first == '*') {
        projectedRow.addAll(row);
        continue;
      }
      final val = _jitProjs[i](row);
      if (proj.alias != null) {
        projectedRow[proj.alias!] = val;
      } else if (proj.expr is VariableExpr) {
        projectedRow[(proj.expr as VariableExpr).fullName] = val;
      } else {
        projectedRow[exprToSqlString(proj.expr)] = val;
      }
    }
    return projectedRow;
  }

  @override
  void close() => child.close();

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final childPlan = child.getPlanString(indent + 1);
    final projs = projections.map((p) => p.alias ?? exprToSqlString(p.expr)).join(', ');
    return '${padding}ProjectNode(projections: [$projs])\n$childPlan';
  }
}

class AggregationState {
  final Map<String, DbValue> groupKeyRow;
  final Map<String, int> counts = {};
  final Map<String, double> sums = {};
  final Map<String, bool> sumsIsDouble = {};
  final Map<String, int> avgCounts = {};
  final Map<String, double> avgSums = {};
  final Map<String, DbValue> mins = {};
  final Map<String, DbValue> maxes = {};
  final Map<String, DbValue> firstVals = {};

  AggregationState(Map<String, DbValue> row) : groupKeyRow = Map<String, DbValue>.of(row);

  void update(Map<String, DbValue> row, List<Projection> projections, Map<Projection, JitClosure> argJits) {
    for (final proj in projections) {
      final expr = proj.expr;
      final alias = proj.alias ?? exprToSqlString(expr);
      if (expr is FunctionCallExpr) {
        final funcName = expr.name.toLowerCase();
        if (funcName == 'count') {
          if (expr.arguments.isEmpty || (expr.arguments[0] is VariableExpr && (expr.arguments[0] as VariableExpr).path.first == '*')) {
            counts[alias] = (counts[alias] ?? 0) + 1;
          } else {
            final val = argJits[proj]!(row);
            if (val is! DbNull) {
              counts[alias] = (counts[alias] ?? 0) + 1;
            }
          }
        } else if (funcName == 'sum') {
          final val = argJits[proj]!(row);
          if (val is DbInt) {
            sums[alias] = (sums[alias] ?? 0.0) + val.value;
            sumsIsDouble[alias] = sumsIsDouble[alias] ?? false;
          } else if (val is DbDouble) {
            sums[alias] = (sums[alias] ?? 0.0) + val.value;
            sumsIsDouble[alias] = true;
          }
        } else if (funcName == 'avg') {
          final val = argJits[proj]!(row);
          if (val is DbInt) {
            avgSums[alias] = (avgSums[alias] ?? 0.0) + val.value;
            avgCounts[alias] = (avgCounts[alias] ?? 0) + 1;
          } else if (val is DbDouble) {
            avgSums[alias] = (avgSums[alias] ?? 0.0) + val.value;
            avgCounts[alias] = (avgCounts[alias] ?? 0) + 1;
          }
        } else if (funcName == 'min') {
          final val = argJits[proj]!(row);
          if (val is! DbNull) {
            final currentMin = mins[alias];
            if (currentMin == null || val.compareTo(currentMin) < 0) {
              mins[alias] = val;
            }
          }
        } else if (funcName == 'max') {
          final val = argJits[proj]!(row);
          if (val is! DbNull) {
            final currentMax = maxes[alias];
            if (currentMax == null || val.compareTo(currentMax) > 0) {
              maxes[alias] = val;
            }
          }
        } else {
          firstVals[alias] ??= argJits[proj]!(row);
        }
      } else {
        firstVals[alias] ??= argJits[proj]!(row);
      }
    }
  }

  Map<String, DbValue> finalize(List<Projection> projections) {
    final result = <String, DbValue>{};
    for (final proj in projections) {
      final expr = proj.expr;
      final alias = proj.alias ?? exprToSqlString(expr);
      if (expr is FunctionCallExpr) {
        final funcName = expr.name.toLowerCase();
        if (funcName == 'count') {
          result[alias] = DbInt(counts[alias] ?? 0);
        } else if (funcName == 'sum') {
          final sumVal = sums[alias];
          if (sumVal == null) {
            result[alias] = DbNull();
          } else {
            result[alias] = (sumsIsDouble[alias] ?? false) ? DbDouble(sumVal) : DbInt(sumVal.toInt());
          }
        } else if (funcName == 'avg') {
          final count = avgCounts[alias] ?? 0;
          final sumVal = avgSums[alias] ?? 0.0;
          result[alias] = count > 0 ? DbDouble(sumVal / count) : DbNull();
        } else if (funcName == 'min') {
          result[alias] = mins[alias] ?? DbNull();
        } else if (funcName == 'max') {
          result[alias] = maxes[alias] ?? DbNull();
        } else {
          result[alias] = firstVals[alias] ?? DbNull();
        }
      } else {
        result[alias] = firstVals[alias] ?? DbNull();
      }
    }
    return result;
  }
}

class GroupByNode extends PlanNode {
  final PlanNode child;
  final Expression groupByExpr;
  final List<Projection> projections;
  final Expression? havingCondition;
  
  List<Map<String, DbValue>>? _aggregatedRows;
  int _currentIndex = 0;

  GroupByNode(this.child, this.groupByExpr, this.projections, {this.havingCondition});

  @override
  void open() {
    child.open();
    _aggregatedRows = null;
    _currentIndex = 0;
  }
  
  void _performAggregation() {
    // Fast path: Global COUNT(*) aggregation without any GROUP BY columns
    if (groupByExpr is LiteralExpr &&
        projections.length == 1 &&
        projections[0].expr is FunctionCallExpr) {
      final func = projections[0].expr as FunctionCallExpr;
      if (func.name.toLowerCase() == 'count') {
        final isCountAll = func.arguments.isEmpty ||
            (func.arguments.length == 1 &&
             ((func.arguments[0] is VariableExpr && (func.arguments[0] as VariableExpr).path.first == '*') ||
              (func.arguments[0] is LiteralExpr && (func.arguments[0] as LiteralExpr).value.toString().contains('*'))));
        if (isCountAll) {
          int count = 0;
          bool fastCountSuccess = false;
          bool hasFilter = false;
          PlanNode baseNode = child;
          while (baseNode is FilterNode || baseNode is ProjectNode) {
            if (baseNode is FilterNode) {
              hasFilter = true;
              baseNode = baseNode.child;
            } else if (baseNode is ProjectNode) {
              baseNode = baseNode.child;
            }
          }
          if (baseNode is IndexScanNode) {
            final scan = baseNode as IndexScanNode;
            final fastCount = scan.getFastCount();
            if (fastCount != null) {
              count = fastCount;
              fastCountSuccess = true;
            }
          } else if (baseNode is RowScanNode && !hasFilter) {
            final scan = baseNode;
            final activeInterpreter = JitCompiler.activeInterpreter;
            if (activeInterpreter != null) {
              final stats = activeInterpreter.db.catalog.getOrCreateStats(scan.schema.name);
              if (stats.rowCount > 0) {
                count = stats.rowCount;
                fastCountSuccess = true;
              }
            }
          }
          if (!fastCountSuccess) {
            while (true) {
              final row = child.next();
              if (row == null) break;
              count++;
            }
          }
          final aliasStr = projections[0].alias ?? 'COUNT(*)';
          final sqlStr = exprToSqlString(projections[0].expr);
          _aggregatedRows = [
            {
              aliasStr: DbInt(count),
              sqlStr: DbInt(count),
              'COUNT(*)': DbInt(count),
              'count(*)': DbInt(count),
            }
          ];
          return;
        }
      }
    }

    if (groupByExpr is LiteralExpr) {
      final len = projections.length;
      final aggTypes = Int8List(len);
      final argJitsList = List<JitClosure?>.filled(len, null);
      final aliases = List<String>.filled(len, '');
      
      final counts = Int32List(len);
      final sums = Float64List(len);
      final sumsIsDouble = Uint8List(len);
      final avgCounts = Int32List(len);
      final avgSums = Float64List(len);
      final mins = List<DbValue?>.filled(len, null);
      final maxes = List<DbValue?>.filled(len, null);
      final firsts = List<DbValue?>.filled(len, null);

      for (int i = 0; i < len; i++) {
        final proj = projections[i];
        final expr = proj.expr;
        aliases[i] = proj.alias ?? exprToSqlString(expr);
        if (expr is FunctionCallExpr) {
          final funcName = expr.name.toLowerCase();
          if (funcName == 'count') {
            if (expr.arguments.isEmpty || (expr.arguments[0] is VariableExpr && (expr.arguments[0] as VariableExpr).path.first == '*')) {
              aggTypes[i] = 1;
            } else {
              aggTypes[i] = 2;
              argJitsList[i] = JitCompiler.compile(expr.arguments[0]);
            }
          } else if (funcName == 'sum') {
            aggTypes[i] = 3;
            argJitsList[i] = JitCompiler.compile(expr.arguments[0]);
          } else if (funcName == 'avg') {
            aggTypes[i] = 4;
            argJitsList[i] = JitCompiler.compile(expr.arguments[0]);
          } else if (funcName == 'min') {
            aggTypes[i] = 5;
            argJitsList[i] = JitCompiler.compile(expr.arguments[0]);
          } else if (funcName == 'max') {
            aggTypes[i] = 6;
            argJitsList[i] = JitCompiler.compile(expr.arguments[0]);
          } else {
            aggTypes[i] = 7;
            if (expr.arguments.isNotEmpty) {
              argJitsList[i] = JitCompiler.compile(expr.arguments[0]);
            }
          }
        } else {
          aggTypes[i] = 7;
          argJitsList[i] = JitCompiler.compile(expr);
        }
      }

      while (true) {
        final row = child.next();
        if (row == null) break;

        for (int i = 0; i < len; i++) {
          final type = aggTypes[i];
          if (type == 1) {
            counts[i]++;
          } else {
            final val = argJitsList[i]!(row);
            if (val is! DbNull) {
              if (type == 2) {
                counts[i]++;
              } else if (type == 3) {
                if (val is DbInt) {
                  sums[i] += val.value;
                } else if (val is DbDouble) {
                  sums[i] += val.value;
                  sumsIsDouble[i] = 1;
                }
              } else if (type == 4) {
                if (val is DbInt) {
                  avgSums[i] += val.value;
                  avgCounts[i]++;
                } else if (val is DbDouble) {
                  avgSums[i] += val.value;
                  avgCounts[i]++;
                }
              } else if (type == 5) {
                final curMin = mins[i];
                if (curMin == null || val.compareTo(curMin) < 0) {
                  mins[i] = val;
                }
              } else if (type == 6) {
                final curMax = maxes[i];
                if (curMax == null || val.compareTo(curMax) > 0) {
                  maxes[i] = val;
                }
              } else if (type == 7) {
                firsts[i] ??= val;
              }
            }
          }
        }
      }

      final resultRow = <String, DbValue>{};
      for (int i = 0; i < len; i++) {
        final type = aggTypes[i];
        final alias = aliases[i];
        if (type == 1 || type == 2) {
          resultRow[alias] = DbInt(counts[i]);
        } else if (type == 3) {
          final isDouble = sumsIsDouble[i] == 1;
          resultRow[alias] = isDouble ? DbDouble(sums[i]) : DbInt(sums[i].toInt());
        } else if (type == 4) {
          final count = avgCounts[i];
          resultRow[alias] = count > 0 ? DbDouble(avgSums[i] / count) : DbNull();
        } else if (type == 5) {
          resultRow[alias] = mins[i] ?? DbNull();
        } else if (type == 6) {
          resultRow[alias] = maxes[i] ?? DbNull();
        } else {
          resultRow[alias] = firsts[i] ?? DbNull();
        }
      }

      final jitHaving = havingCondition != null ? JitCompiler.compile(havingCondition!) : null;
      if (jitHaving != null) {
        final pass = jitHaving(resultRow);
        if (pass is DbInt && pass.value == 0 || pass is DbNull) {
          _aggregatedRows = [];
          return;
        }
      }

      _aggregatedRows = [resultRow];
      return;
    }

    final groups = <String, AggregationState>{};
    
    List<List<Expression>> sets = [];
    if (groupByExpr is GroupingSetsExpr) {
      sets = (groupByExpr as GroupingSetsExpr).sets;
    } else if (groupByExpr is RollupExpr) {
      final exprs = (groupByExpr as RollupExpr).expressions;
      for (int i = exprs.length; i >= 0; i--) {
        sets.add(exprs.sublist(0, i));
      }
    } else if (groupByExpr is CubeExpr) {
      final exprs = (groupByExpr as CubeExpr).expressions;
      int n = exprs.length;
      int numSets = 1 << n;
      for (int i = 0; i < numSets; i++) {
        List<Expression> subset = [];
        for (int j = 0; j < n; j++) {
          if ((i & (1 << j)) != 0) {
            subset.add(exprs[j]);
          }
        }
        sets.add(subset);
      }
    } else {
      sets = [[groupByExpr]];
    }

    // JIT compile expressions for each grouping set
    final setJits = sets.map((set) => set.map((e) => JitCompiler.compile(e)).toList()).toList();
    final setExprStrings = sets.map((set) => set.map((e) => exprToSqlString(e)).toList()).toList();

    // JIT compile all aggregate inputs and projection expressions beforehand
    final argJits = <Projection, JitClosure>{};
    for (final proj in projections) {
      final expr = proj.expr;
      if (expr is FunctionCallExpr && expr.arguments.isNotEmpty) {
        argJits[proj] = JitCompiler.compile(expr.arguments[0]);
      } else if (expr is! FunctionCallExpr) {
        argJits[proj] = JitCompiler.compile(expr);
      }
    }
    final jitHaving = havingCondition != null ? JitCompiler.compile(havingCondition!) : null;

    while (true) {
      final row = child.next();
      if (row == null) {
        break;
      }
      for (int sIdx = 0; sIdx < sets.length; sIdx++) {
        final currentSetJits = setJits[sIdx];
        final currentSetExprs = setExprStrings[sIdx];
        
        // Build the key and the modified row for this grouping set
        final keyParts = <String>[];
        final groupedRow = Map<String, DbValue>.of(row);
        
        // Find which expressions are NOT in this grouping set and set their columns to DbNull()
        // Wait, it's easier to just form a key from the set index and the values.
        for (int i = 0; i < currentSetJits.length; i++) {
          final val = currentSetJits[i](row);
          keyParts.add(val.toString());
        }
        
        final key = '$sIdx:' + keyParts.join(',');
        
        // To construct the group's "base row", we take the first row and set missing grouping columns to DbNull
        final state = groups.putIfAbsent(key, () {
          final stateRow = Map<String, DbValue>.of(row);
          // For advanced grouping, columns that are grouped by in OTHER sets but not THIS set should be NULL.
          // Since we don't know all columns easily, we'll just evaluate the projection properly.
          // Wait, any column in the original row that is part of the overall grouping expressions but not in this set should be null.
          if (sets.length > 1) {
            // Find all unique expressions across all sets
            final allExprs = sets.expand((s) => s.map((e) => exprToSqlString(e))).toSet();
            for (final exprStr in allExprs) {
              if (!currentSetExprs.contains(exprStr)) {
                // Set the corresponding column in stateRow to NULL if it exists
                // We assume the expr is a simple VariableExpr or column name
                if (stateRow.containsKey(exprStr)) {
                  stateRow[exprStr] = DbNull();
                } else {
                  // Handle dotted paths or simple names
                  final shortName = exprStr.split('.').last;
                  for (final k in stateRow.keys) {
                    if (k.split('.').last == shortName) {
                      stateRow[k] = DbNull();
                    }
                  }
                }
              }
            }
          }
          return AggregationState(stateRow);
        });
        state.update(row, projections, argJits);
      }
    }

    // If it's global aggregation (no GROUP BY but has aggregates) and no rows matched,
    // we still need to output one row with aggregate defaults (e.g. COUNT = 0)
    if (groups.isEmpty && groupByExpr is LiteralExpr) {
      groups['1'] = AggregationState({});
      groups['1']!.update({}, projections, argJits);
    }

    _aggregatedRows = [];

    for (final entry in groups.entries) {
      final state = entry.value;
      final projectedRow = state.finalize(projections);
      
      if (jitHaving != null) {
        final pass = jitHaving(projectedRow);
        if (pass is DbInt && pass.value == 0) {
          continue;
        } else if (pass is DbNull) {
          continue;
        }
      }
      
      _aggregatedRows!.add(projectedRow);
    }
  }


  @override
  Map<String, DbValue>? next() {
    if (_aggregatedRows == null) {
      _performAggregation();
    }
    if (_currentIndex >= _aggregatedRows!.length) {
      return null;
    }
    return _aggregatedRows![_currentIndex++];
  }

  @override
  void close() {
    child.close();
    _aggregatedRows = null;
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final childPlan = child.getPlanString(indent + 1);
    final projs = projections.map((p) => p.alias ?? exprToSqlString(p.expr)).join(', ');
    final havingStr = havingCondition != null ? ', having: ${exprToSqlString(havingCondition!)}' : '';
    return '${padding}GroupByNode(groupBy: ${exprToSqlString(groupByExpr)}, projections: [$projs]$havingStr)\n$childPlan';
  }
}

// Volcano Hash Join Node (O(N+M) complexity)
class HashJoinNode extends PlanNode {
  final PlanNode left;
  final PlanNode right;
  final String leftJoinCol;
  final String rightJoinCol;
  final bool isLeftJoin;
  final bool isRightJoin;
  final bool isFullJoin;
  final List<String>? leftColumns;
  final TableSchema? rightSchema;
  late final JitClosure _jitLeftKey;
  late final JitClosure _jitRightKey;

  final Map<String, List<Map<String, DbValue>>> _hashTable = {};
  Map<String, DbValue>? _currentLeftRow;
  List<Map<String, DbValue>>? _currentMatches;
  int _matchIdx = 0;

  final List<Map<String, DbValue>> _allRightRows = [];
  final Set<Map<String, DbValue>> _seenRightRows = {};
  Iterator<Map<String, DbValue>>? _unmatchedRightIterator;

  HashJoinNode({
    required this.left,
    required this.right,
    required this.leftJoinCol,
    required this.rightJoinCol,
    this.isLeftJoin = false,
    this.isRightJoin = false,
    this.isFullJoin = false,
    this.leftColumns,
    this.rightSchema,
  }) {
    _jitLeftKey = JitCompiler.compile(VariableExpr([leftJoinCol]));
    _jitRightKey = JitCompiler.compile(VariableExpr([rightJoinCol]));
  }

  Map<String, DbValue> _createNullRow() {
    final nullRow = <String, DbValue>{};
    if (rightSchema != null) {
      for (final colName in rightSchema!.columnNames) {
        nullRow['${rightSchema!.name}.$colName'] = DbNull();
        nullRow[colName] = DbNull();
      }
    }
    return nullRow;
  }

  @override
  void open() {
    left.open();
    right.open();
    _hashTable.clear();
    _allRightRows.clear();
    _seenRightRows.clear();
    _currentLeftRow = null;
    _currentMatches = null;
    _matchIdx = 0;
    _unmatchedRightIterator = null;

    // Load right relation and build hash table in memory synchronously
    while (true) {
      final rightRow = right.next();
      if (rightRow == null) break;

      final keyVal = _jitRightKey(rightRow);
      final key = keyVal.toString();
      final rightRowCopy = Map<String, DbValue>.of(rightRow);
      _hashTable.putIfAbsent(key, () => []).add(rightRowCopy);
      if (isRightJoin || isFullJoin) {
        _allRightRows.add(rightRowCopy);
      }
    }
  }

  @override
  Map<String, DbValue>? next() {
    while (true) {
      // 1. If we are currently streaming unmatched right rows:
      if (_unmatchedRightIterator != null) {
        if (_unmatchedRightIterator!.moveNext()) {
          final rightRow = _unmatchedRightIterator!.current;
          final leftNullRow = <String, DbValue>{};
          if (leftColumns != null) {
            for (final col in leftColumns!) {
              leftNullRow[col] = DbNull();
            }
          }
          return Map<String, DbValue>.from(leftNullRow)..addAll(rightRow);
        } else {
          return null; // All done!
        }
      }

      // 2. If we are currently streaming matches for a left row:
      if (_currentMatches != null && _matchIdx < _currentMatches!.length) {
        final rightRow = _currentMatches![_matchIdx++];
        if (isRightJoin || isFullJoin) {
          _seenRightRows.add(rightRow);
        }
        final mergedRow = Map<String, DbValue>.from(_currentLeftRow!)..addAll(rightRow);
        return mergedRow;
      }

      // 3. Read next left row
      _currentLeftRow = left.next();
      if (_currentLeftRow == null) {
        // Left relation is exhausted.
        // If this is a RIGHT or FULL join, we must now stream the unmatched right rows!
        if (isRightJoin || isFullJoin) {
          final unmatched = _allRightRows.where((r) => !_seenRightRows.contains(r)).toList();
          _unmatchedRightIterator = unmatched.iterator;
          continue; // Loop again to process the iterator
        }
        return null;
      }

      final keyVal = _jitLeftKey(_currentLeftRow!);
      final key = keyVal.toString();

      if (_hashTable.containsKey(key)) {
        _currentMatches = _hashTable[key];
        _matchIdx = 0;
      } else {
        _currentMatches = null;
        if (isLeftJoin || isFullJoin) {
          final nullRow = _createNullRow();
          final mergedRow = Map<String, DbValue>.from(_currentLeftRow!)..addAll(nullRow);
          return mergedRow;
        }
      }
    }
  }

  @override
  void close() {
    left.close();
    right.close();
    _hashTable.clear();
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final leftPlan = left.getPlanString(indent + 1);
    final rightPlan = right.getPlanString(indent + 1);
    return '${padding}HashJoinNode(on: $leftJoinCol = $rightJoinCol)\n$leftPlan\n$rightPlan';
  }
}

class NestedLoopJoinNode extends PlanNode {
  final PlanNode left;
  final PlanNode right;
  final Expression onCondition;
  final bool isLeftJoin;
  final bool isRightJoin;
  final bool isFullJoin;
  final List<String>? leftColumns;
  final TableSchema? rightSchema;
  late final JitClosure _jitCond;

  final List<Map<String, DbValue>> _allRightRows = [];
  final Set<Map<String, DbValue>> _seenRightRows = {};
  Map<String, DbValue>? _currentLeftRow;
  int _rightIdx = 0;
  bool _matchedCurrentLeft = false;
  Iterator<Map<String, DbValue>>? _unmatchedRightIterator;

  NestedLoopJoinNode({
    required this.left,
    required this.right,
    required this.onCondition,
    this.isLeftJoin = false,
    this.isRightJoin = false,
    this.isFullJoin = false,
    this.leftColumns,
    this.rightSchema,
  }) {
    _jitCond = JitCompiler.compile(onCondition);
  }

  Map<String, DbValue> _createNullRow() {
    final nullRow = <String, DbValue>{};
    if (rightSchema != null) {
      for (final colName in rightSchema!.columnNames) {
        nullRow['${rightSchema!.name}.$colName'] = DbNull();
        nullRow[colName] = DbNull();
      }
    }
    return nullRow;
  }

  @override
  void open() {
    left.open();
    right.open();
    _allRightRows.clear();
    _seenRightRows.clear();
    _currentLeftRow = null;
    _rightIdx = 0;
    _matchedCurrentLeft = false;
    _unmatchedRightIterator = null;

    while (true) {
      final rightRow = right.next();
      if (rightRow == null) break;
      _allRightRows.add(Map<String, DbValue>.of(rightRow));
    }
  }

  @override
  Map<String, DbValue>? next() {
    while (true) {
      if (_unmatchedRightIterator != null) {
        if (_unmatchedRightIterator!.moveNext()) {
          final rightRow = _unmatchedRightIterator!.current;
          final leftNullRow = <String, DbValue>{};
          if (leftColumns != null) {
            for (final col in leftColumns!) {
              leftNullRow[col] = DbNull();
            }
          }
          return Map<String, DbValue>.from(leftNullRow)..addAll(rightRow);
        } else {
          return null;
        }
      }

      if (_currentLeftRow == null) {
        _currentLeftRow = left.next();
        if (_currentLeftRow == null) {
          if (isRightJoin || isFullJoin) {
            final unmatched = _allRightRows.where((r) => !_seenRightRows.contains(r)).toList();
            _unmatchedRightIterator = unmatched.iterator;
            continue;
          }
          return null;
        }
        _rightIdx = 0;
        _matchedCurrentLeft = false;
      }

      while (_rightIdx < _allRightRows.length) {
        final rightRow = _allRightRows[_rightIdx++];
        final mergedRow = Map<String, DbValue>.from(_currentLeftRow!)..addAll(rightRow);
        final condVal = _jitCond(mergedRow);
        final isTrue = (condVal is DbInt && condVal.value == 1) || (condVal is DbDouble && condVal.value > 0.0);
        if (isTrue) {
          _matchedCurrentLeft = true;
          if (isRightJoin || isFullJoin) {
            _seenRightRows.add(rightRow);
          }
          return mergedRow;
        }
      }

      final finishedLeft = _currentLeftRow!;
      _currentLeftRow = null;

      if (!_matchedCurrentLeft && (isLeftJoin || isFullJoin)) {
        final nullRow = _createNullRow();
        return Map<String, DbValue>.from(finishedLeft)..addAll(nullRow);
      }
    }
  }

  @override
  void close() {
    left.close();
    right.close();
    _allRightRows.clear();
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    return '${padding}NestedLoopJoinNode(on: ${exprToSqlString(onCondition)})\n${left.getPlanString(indent + 1)}\n${right.getPlanString(indent + 1)}';
  }
}

// Sort Node for ORDER BY (In-memory sort)
class SortNode extends PlanNode {
  final PlanNode child;
  final Expression orderByExpr;
  final bool ascending;
  late final JitClosure _jitOrderBy;

  final List<Map<String, DbValue>> _sortedRows = [];
  int _cursor = 0;

  SortNode(this.child, this.orderByExpr, this.ascending) {
    _jitOrderBy = JitCompiler.compile(orderByExpr);
  }

  @override
  void open() {
    child.open();
    _sortedRows.clear();
    _cursor = 0;

    // Pull all rows synchronously
    while (true) {
      final row = child.next();
      if (row == null) break;
      _sortedRows.add(Map<String, DbValue>.of(row));
    }

    // Sort
    _sortedRows.sort((a, b) {
      final valA = _jitOrderBy(a);
      final valB = _jitOrderBy(b);
      final comp = valA.compareTo(valB);
      return ascending ? comp : -comp;
    });
  }

  @override
  Map<String, DbValue>? next() {
    if (_cursor >= _sortedRows.length) return null;
    return _sortedRows[_cursor++];
  }

  @override
  void close() {
    child.close();
    _sortedRows.clear();
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final childPlan = child.getPlanString(indent + 1);
    return '${padding}SortNode(orderBy: ${exprToSqlString(orderByExpr)}, asc: $ascending)\n$childPlan';
  }
}

class WindowNode extends PlanNode {
  final PlanNode child;
  final WindowFunctionExpr windowExpr;

  List<Map<String, DbValue>>? _resultRows;
  int _currentIndex = 0;

  WindowNode(this.child, this.windowExpr);

  @override
  void open() {
    child.open();
    _resultRows = null;
    _currentIndex = 0;
  }

  void _processWindow() {
    final allRows = <Map<String, DbValue>>[];
    while (true) {
      final row = child.next();
      if (row == null) break;
      allRows.add(Map<String, DbValue>.of(row));
    }

    final partitionJits = windowExpr.partitionBy.map((expr) => JitCompiler.compile(expr)).toList();
    final partitions = <String, List<Map<String, DbValue>>>{};
    for (final row in allRows) {
      final key = partitionJits.isEmpty
          ? ''
          : partitionJits.map((jit) => jit(row).toString()).join('\x00');
      partitions.putIfAbsent(key, () => []).add(row);
    }

    final orderBy = windowExpr.orderBy;
    if (orderBy != null) {
      final jitOrder = JitCompiler.compile(orderBy.expr);
      final ascending = orderBy.ascending;
      for (final partitionRows in partitions.values) {
        partitionRows.sort((a, b) {
          final valA = jitOrder(a);
          final valB = jitOrder(b);
          final comp = valA.compareTo(valB);
          return ascending ? comp : -comp;
        });
      }
    }

    final fnName = windowExpr.functionName.toLowerCase();
    final colName = exprToSqlString(windowExpr);
    _resultRows = [];

    for (final partitionRows in partitions.values) {
      if (fnName == 'rank') {
        int currentRank = 1;
        DbValue? prevVal;
        final jitOrder = orderBy != null ? JitCompiler.compile(orderBy.expr) : null;
        for (int i = 0; i < partitionRows.length; i++) {
          final row = Map<String, DbValue>.of(partitionRows[i]);
          if (jitOrder != null) {
            final curVal = jitOrder(row);
            if (prevVal != null && curVal.compareTo(prevVal) != 0) {
              currentRank = i + 1;
            }
            prevVal = curVal;
          } else {
            currentRank = i + 1;
          }
          row[colName] = DbInt(currentRank);
          _resultRows!.add(row);
        }
      } else if (fnName == 'dense_rank') {
        int currentRank = 1;
        DbValue? prevVal;
        final jitOrder = orderBy != null ? JitCompiler.compile(orderBy.expr) : null;
        for (int i = 0; i < partitionRows.length; i++) {
          final row = Map<String, DbValue>.of(partitionRows[i]);
          if (jitOrder != null) {
            final curVal = jitOrder(row);
            if (prevVal != null && curVal.compareTo(prevVal) != 0) {
              currentRank++;
            }
            prevVal = curVal;
          } else {
            currentRank = i + 1;
          }
          row[colName] = DbInt(currentRank);
          _resultRows!.add(row);
        }
      } else if (fnName == 'lag' || fnName == 'lead') {
        int offset = 1;
        final rawArg = windowExpr.arguments.isNotEmpty ? exprToSqlString(windowExpr.arguments.first) : '';
        for (int i = 0; i < partitionRows.length; i++) {
          final row = Map<String, DbValue>.of(partitionRows[i]);
          final targetIdx = fnName == 'lag' ? i - offset : i + offset;
          if (targetIdx >= 0 && targetIdx < partitionRows.length) {
            final targetRow = partitionRows[targetIdx];
            DbValue targetVal = DbNull();
            if (rawArg.isNotEmpty) {
              final targetColName = rawArg.split('.').last.toLowerCase();
              for (final k in targetRow.keys) {
                final kLower = k.split('.').last.toLowerCase();
                if (kLower == targetColName) {
                  targetVal = targetRow[k]!;
                  break;
                }
              }
            } else {
              targetVal = targetRow.values.isNotEmpty ? targetRow.values.first : DbNull();
            }
            row[colName] = targetVal;
          } else {
            row[colName] = DbNull();
          }
          _resultRows!.add(row);
        }
      } else {
        for (int i = 0; i < partitionRows.length; i++) {
          final row = Map<String, DbValue>.of(partitionRows[i]);
          row[colName] = DbInt(i + 1);
          _resultRows!.add(row);
        }
      }
    }
  }

  @override
  Map<String, DbValue>? next() {
    if (_resultRows == null) {
      _processWindow();
    }
    if (_currentIndex >= _resultRows!.length) {
      return null;
    }
    return _resultRows![_currentIndex++];
  }

  @override
  void close() {
    child.close();
    _resultRows = null;
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    return '${padding}WindowNode(func: ${windowExpr.functionName})';
  }
}

class FtsScanNode extends PlanNode {
  final String tableName;
  final String columnName;
  final String searchQuery;
  final String dbDirectory;
  final PageCache cache;
  final Catalog catalog;

  List<Map<String, DbValue>>? _matchingRows;
  int _currentIndex = 0;

  FtsScanNode({
    required this.tableName,
    required this.columnName,
    required this.searchQuery,
    required this.dbDirectory,
    required this.cache,
    required this.catalog,
  });

  @override
  void open() {
    _matchingRows = null;
    _currentIndex = 0;
  }

  void _executeFtsScan() {
    _matchingRows = [];
    IndexSchema? idxSchema;
    for (final idx in catalog.getIndexesForTable(tableName)) {
      if (idx.usingMethod == 'fts' && idx.columnName.toLowerCase() == columnName.toLowerCase()) {
        idxSchema = idx;
        break;
      }
    }
    final indexPath = '$dbDirectory/${idxSchema?.name.toLowerCase() ?? "fts_${tableName}_$columnName"}.fts';
    final ftsIndex = FtsIndex(indexPath: indexPath);
    ftsIndex.initSync();

    final cleanQuery = searchQuery.replaceAll("'", "").replaceAll('"', "");
    final postings = ftsIndex.searchSync(cleanQuery);
    if (postings.isEmpty) return;

    final schema = catalog.getTableSchema(tableName.toLowerCase());
    if (schema == null) return;

    final rowTable = RowTableFile(cache: cache, tableName: schema.name, dbDirectory: dbDirectory);
    rowTable.flushActivePageSync();

    for (final posting in postings) {
      final page = cache.pinPageSync(rowTable.filePath, posting.pageId);
      final recBytes = SlottedPageHelper.getRecord(page, posting.slotId);
      if (recBytes != null) {
        List<DbValue>? rowValues;
        try {
          final mvccRecord = MvccRecord.fromBytes(recBytes);
          final currentTx = cache.currentMvccTx;
          final txManager = cache.mvccTxManager;
          final currentTxId = currentTx?.txId ?? 0;
          final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
          if (txManager.isVisible(mvccRecord.xmin, mvccRecord.xmax, currentTxId, activeTxIds)) {
            rowValues = RecordSerializer.deserializeRow(mvccRecord.rowData);
          }
        } catch (_) {
          rowValues = RecordSerializer.deserializeRow(recBytes);
        }
        if (rowValues != null) {
          final rowMap = <String, DbValue>{};
          for (int i = 0; i < schema.columnNames.length; i++) {
            rowMap['${schema.name.toLowerCase()}.${schema.columnNamesLower[i]}'] = rowValues[i];
            rowMap[schema.columnNamesLower[i]] = rowValues[i];
          }
          _matchingRows!.add(rowMap);
        }
      }
      cache.unpinPageSync(rowTable.filePath, posting.pageId, isDirty: false);
    }
  }

  @override
  Map<String, DbValue>? next() {
    if (_matchingRows == null) {
      _executeFtsScan();
    }
    if (_currentIndex >= _matchingRows!.length) {
      return null;
    }
    return _matchingRows![_currentIndex++];
  }

  @override
  void close() {
    _matchingRows = null;
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    return '${padding}FtsScanNode(table: $tableName, column: $columnName, query: "$searchQuery")';
  }
}

class MemoryScanNode extends PlanNode {
  final List<Map<String, DbValue>> rows;
  int _index = 0;
  MemoryScanNode(this.rows);

  @override
  void open() {
    _index = 0;
  }

  @override
  Map<String, DbValue>? next() {
    if (_index >= rows.length) return null;
    return rows[_index++];
  }

  @override
  void close() {}

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    return '${padding}MemoryScanNode(rowCount: ${rows.length})';
  }
}

class RecursiveCteNode extends PlanNode {
  final PlanNode anchorChild;
  final PlanNode Function(PlanNode workingChild) recursiveChildBuilder;

  List<Map<String, DbValue>>? _allRows;
  int _currentIndex = 0;

  RecursiveCteNode(this.anchorChild, this.recursiveChildBuilder);

  @override
  void open() {
    anchorChild.open();
    _allRows = null;
    _currentIndex = 0;
  }

  void _executeRecursiveCte() {
    _allRows = [];
    final workingTable = <Map<String, DbValue>>[];

    anchorChild.open();
    while (true) {
      final row = anchorChild.next();
      if (row == null) break;
      _allRows!.add(Map<String, DbValue>.from(row));
      workingTable.add(Map<String, DbValue>.from(row));
    }
    anchorChild.close();

    int maxDepth = 100;
    int depth = 0;
    while (workingTable.isNotEmpty && depth < maxDepth) {
      depth++;
      final currentWorkingPlan = MemoryScanNode(List<Map<String, DbValue>>.from(workingTable));
      final recursivePlan = recursiveChildBuilder(currentWorkingPlan);
      recursivePlan.open();

      final nextWorkingTable = <Map<String, DbValue>>[];
      while (true) {
        final row = recursivePlan.next();
        if (row == null) break;

        final standardizedRow = <String, DbValue>{};
        if (_allRows!.isNotEmpty) {
          final anchorKeys = _allRows!.first.keys.toList();
          final rowValues = row.values.toList();
          for (int k = 0; k < anchorKeys.length; k++) {
            final val = k < rowValues.length ? rowValues[k] : DbNull();
            standardizedRow[anchorKeys[k]] = val;
            final shortKey = anchorKeys[k].split('.').last;
            standardizedRow[shortKey] = val;
          }
        } else {
          standardizedRow.addAll(row);
        }

        bool exists = _allRows!.any((existing) {
          for (final key in standardizedRow.keys) {
            if (existing[key] != standardizedRow[key]) return false;
          }
          return true;
        });

        if (!exists) {
          _allRows!.add(standardizedRow);
          nextWorkingTable.add(standardizedRow);
        }
      }
      recursivePlan.close();
      workingTable.clear();
      workingTable.addAll(nextWorkingTable);
    }
  }

  @override
  Map<String, DbValue>? next() {
    if (_allRows == null) {
      _executeRecursiveCte();
    }
    if (_currentIndex >= _allRows!.length) {
      return null;
    }
    return _allRows![_currentIndex++];
  }

  @override
  void close() {
    anchorChild.close();
    _allRows = null;
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    return '${padding}RecursiveCteNode()';
  }
}

// Limit Node to cap results
class LimitNode extends PlanNode {
  final PlanNode child;
  final int limit;
  final int offset;
  int _count = 0;
  int _skipped = 0;

  LimitNode(this.child, this.limit, [this.offset = 0]);

  @override
  void open() {
    child.open();
    _count = 0;
    _skipped = 0;
  }

  @override
  Map<String, DbValue>? next() {
    while (_skipped < offset) {
      final row = child.next();
      if (row == null) return null;
      _skipped++;
    }

    if (_count >= limit) return null;
    final row = child.next();
    if (row == null) return null;
    _count++;
    return row;
  }

  @override
  void close() {
    child.close();
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final childPlan = child.getPlanString(indent + 1);
    return '${padding}LimitNode(limit: $limit, offset: $offset)\n$childPlan';
  }
}

DbVector? _parseVectorFromString(String s) {
  final trimmed = s.trim();
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    final body = trimmed.substring(1, trimmed.length - 1).trim();
    if (body.isEmpty) return DbVector([]);
    try {
      final elements = body.split(',').map((e) => double.parse(e.trim())).toList();
      return DbVector(elements);
    } catch (_) {
      return null;
    }
  }
  return null;
}

List<DbValue>? _getVisibleRowValues(RowTableFile tableFile, Uint8List recBytes, [int? expectedColumnCount]) {
  try {
    final mvccRecord = MvccRecord.fromBytes(recBytes);
    final currentTx = tableFile.cache.currentMvccTx;
    final txManager = tableFile.cache.mvccTxManager;
    final currentTxId = currentTx?.txId ?? 0;
    final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
    if (txManager.isVisible(mvccRecord.xmin, mvccRecord.xmax, currentTxId, activeTxIds)) {
      return RecordSerializer.deserializeRow(mvccRecord.rowData, expectedColumnCount);
    }
    return null;
  } catch (_) {
    return RecordSerializer.deserializeRow(recBytes, expectedColumnCount);
  }
}

class IndexJoinNode extends PlanNode {
  final PlanNode left;
  final RowTableFile rightTable;
  final BTreeIndex rightIndex;
  final String leftJoinCol;
  final TableSchema rightSchema;
  final bool isLeftJoin;
  final bool isRightJoin;
  final bool isFullJoin;
  final List<String>? leftColumns;
  late final JitClosure _jitLeftKey;

  Page? _pinnedPage;
  int? _pinnedPageId;
  final Map<double, Map<String, DbValue>?> _joinCache = {};

  final List<Map<String, DbValue>> _allRightRows = [];
  final Set<Map<String, DbValue>> _seenRightRows = {};
  Iterator<Map<String, DbValue>>? _unmatchedRightIterator;

  IndexJoinNode({
    required this.left,
    required this.rightTable,
    required this.rightIndex,
    required this.leftJoinCol,
    required this.rightSchema,
    this.isLeftJoin = false,
    this.isRightJoin = false,
    this.isFullJoin = false,
    this.leftColumns,
  }) {
    _jitLeftKey = JitCompiler.compile(VariableExpr([leftJoinCol]));
  }

  Map<String, DbValue> _createNullRow() {
    final nullRow = <String, DbValue>{};
    for (final colName in rightSchema.columnNames) {
      nullRow['${rightSchema.name}.$colName'] = DbNull();
      nullRow[colName] = DbNull();
    }
    return nullRow;
  }

  @override
  void open() {
    left.open();
    rightIndex.initSync();
    _pinnedPage = null;
    _pinnedPageId = null;
    _joinCache.clear();
    _allRightRows.clear();
    _seenRightRows.clear();
    _unmatchedRightIterator = null;

    if (isRightJoin || isFullJoin) {
      final currentTx = rightTable.cache.currentMvccTx;
      final Iterable<List<DbValue>> rows;
      if (currentTx != null) {
        rows = rightTable.scanSync(
          currentTxId: currentTx.txId,
          activeTxIds: currentTx.activeTxIds,
          txManager: rightTable.cache.mvccTxManager,
          expectedColumnCount: rightSchema.columnNames.length,
        );
      } else {
        rows = rightTable.scanSync(
          expectedColumnCount: rightSchema.columnNames.length,
        );
      }

      final keyToIndex = <String, int>{};
      for (int i = 0; i < rightSchema.columnNames.length; i++) {
        final colName = rightSchema.columnNames[i];
        keyToIndex['${rightSchema.name}.$colName'] = i;
        keyToIndex[colName] = i;
      }

      for (final rowVals in rows) {
        _allRightRows.add(RowMap(rowVals, keyToIndex));
      }
    }
  }

  bool _rightRowsEqual(Map<String, DbValue> r1, Map<String, DbValue> r2) {
    for (final col in rightSchema.columnNames) {
      if (r1[col] != r2[col]) return false;
    }
    return true;
  }

  @override
  Map<String, DbValue>? next() {
    while (true) {
      // 1. If we are streaming unmatched right rows
      if (_unmatchedRightIterator != null) {
        if (_unmatchedRightIterator!.moveNext()) {
          final rightRow = _unmatchedRightIterator!.current;
          final leftNullRow = <String, DbValue>{};
          if (leftColumns != null) {
            for (final col in leftColumns!) {
              leftNullRow[col] = DbNull();
            }
          }
          return Map<String, DbValue>.from(leftNullRow)..addAll(rightRow);
        } else {
          return null; // All done!
        }
      }

      final leftRow = left.next();
      if (leftRow == null) {
        // Left is exhausted, stream unmatched right rows if RIGHT or FULL join
        if (isRightJoin || isFullJoin) {
          final unmatched = _allRightRows.where((r) => !_seenRightRows.contains(r)).toList();
          _unmatchedRightIterator = unmatched.iterator;
          continue;
        }
        return null;
      }

      final keyVal = _jitLeftKey(leftRow);
      final double? searchKey = keyVal is DbInt
          ? keyVal.value.toDouble()
          : (keyVal is DbDouble ? keyVal.value : null);

      if (searchKey != null) {
        if (_joinCache.containsKey(searchKey)) {
          final rightRow = _joinCache[searchKey];
          if (rightRow != null) {
            if (isRightJoin || isFullJoin) {
              for (final r in _allRightRows) {
                if (_rightRowsEqual(r, rightRow)) {
                  _seenRightRows.add(r);
                  break;
                }
              }
            }
            final mergedRow = Map<String, DbValue>.from(leftRow)..addAll(rightRow);
            return mergedRow;
          }
          if (isLeftJoin || isFullJoin) {
            final nullRow = _createNullRow();
            final mergedRow = Map<String, DbValue>.from(leftRow)..addAll(nullRow);
            return mergedRow;
          }
          continue;
        }

        final ptr = rightIndex.searchSync([searchKey]);
        if (ptr != null) {
          if (_pinnedPageId != ptr.pageId) {
            if (_pinnedPage != null) {
              rightTable.cache.unpinPageSync(rightTable.filePath, _pinnedPageId!, isDirty: false);
            }
            _pinnedPage = rightTable.cache.pinPageSync(rightTable.filePath, ptr.pageId);
            _pinnedPageId = ptr.pageId;
          }
          final recBytes = SlottedPageHelper.getRecord(_pinnedPage!, ptr.slotId);
          if (recBytes != null) {
            final rightRowValues = _getVisibleRowValues(rightTable, recBytes, rightSchema.columnNames.length);
            if (rightRowValues != null) {
              final rightRow = <String, DbValue>{};
              for (int i = 0; i < rightSchema.columnNames.length; i++) {
                if (i < rightRowValues.length) {
                  final colName = rightSchema.columnNames[i];
                  rightRow['${rightSchema.name}.$colName'] = rightRowValues[i];
                  rightRow[colName] = rightRowValues[i];
                }
              }
              _joinCache[searchKey] = rightRow;
              if (isRightJoin || isFullJoin) {
                for (final r in _allRightRows) {
                  if (_rightRowsEqual(r, rightRow)) {
                    _seenRightRows.add(r);
                    break;
                  }
                }
              }
              final mergedRow = Map<String, DbValue>.from(leftRow)..addAll(rightRow);
              return mergedRow;
            }
          }
        }
        _joinCache[searchKey] = null;
        if (isLeftJoin || isFullJoin) {
          final nullRow = _createNullRow();
          final mergedRow = Map<String, DbValue>.from(leftRow)..addAll(nullRow);
          return mergedRow;
        }
      } else {
        if (isLeftJoin || isFullJoin) {
          final nullRow = _createNullRow();
          final mergedRow = Map<String, DbValue>.from(leftRow)..addAll(nullRow);
          return mergedRow;
        }
      }
    }
  }

  @override
  void close() {
    if (_pinnedPage != null) {
      rightTable.cache.unpinPageSync(rightTable.filePath, _pinnedPageId!, isDirty: false);
      _pinnedPage = null;
      _pinnedPageId = null;
    }
    _joinCache.clear();
    left.close();
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final leftPlan = left.getPlanString(indent + 1);
    final indexName = rightIndex.indexPath.split('/').last.replaceAll('.idx', '');
    return '${padding}IndexJoinNode(on: $leftJoinCol = ${rightSchema.name}.$indexName)\n$leftPlan';
  }
}

class GraphJoinNode extends PlanNode {
  final PlanNode left;
  final RowTableFile? rightTable;
  final ColumnTableFile? rightColumnTable;
  final BTreeIndex? rightIndex;
  final String leftJoinCol;
  final String rightJoinCol;
  final TableSchema rightSchema;
  late final JitClosure _jitLeftKey;

  GraphJoinNode({
    required this.left,
    this.rightTable,
    this.rightColumnTable,
    this.rightIndex,
    required this.leftJoinCol,
    required this.rightJoinCol,
    required this.rightSchema,
  }) {
    _jitLeftKey = JitCompiler.compile(VariableExpr([leftJoinCol]));
  }

  @override
  void open() {
    left.open();
    if (rightIndex != null) {
      rightIndex!.initSync();
    }
  }

  @override
  Map<String, DbValue>? next() {
    while (true) {
      final leftRow = left.next();
      if (leftRow == null) return null;

      final keyVal = _jitLeftKey(leftRow);
      
      // Index lookup path
      if (rightIndex != null && rightTable != null) {
        final double? searchKey = keyVal is DbInt
            ? keyVal.value.toDouble()
            : (keyVal is DbDouble ? keyVal.value : null);

        if (searchKey != null) {
          final ptr = rightIndex!.searchSync([searchKey]);
          if (ptr != null) {
            final page = rightTable!.cache.pinPageSync(rightTable!.filePath, ptr.pageId);
            final recBytes = SlottedPageHelper.getRecord(page, ptr.slotId);
            if (recBytes != null) {
              final rightRowValues = _getVisibleRowValues(rightTable!, recBytes, rightSchema.columnNames.length);
              if (rightRowValues != null) {
                final rightRow = <String, DbValue>{};
                for (int i = 0; i < rightSchema.columnNames.length; i++) {
                  if (i < rightRowValues.length) {
                    final colName = rightSchema.columnNames[i];
                    rightRow['${rightSchema.name}.$colName'] = rightRowValues[i];
                    rightRow[colName] = rightRowValues[i];
                  }
                }
                rightTable!.cache.unpinPageSync(rightTable!.filePath, ptr.pageId, isDirty: false);
                final mergedRow = Map<String, DbValue>.from(leftRow)..addAll(rightRow);
                return mergedRow;
              }
            }
            rightTable!.cache.unpinPageSync(rightTable!.filePath, ptr.pageId, isDirty: false);
          }
        }
      } else if (rightColumnTable != null) {
        // Columnar fallback scan path
        final rightJoinColLower = rightJoinCol.toLowerCase();
        final rightJoinColIdx = rightSchema.columnNamesLower.indexOf(rightJoinColLower);
        if (rightJoinColIdx != -1) {
          final iterators = <Iterator<DbValue>>[];
          for (int i = 0; i < rightSchema.columnNames.length; i++) {
            iterators.add(rightColumnTable!.scanColumnSync(i).iterator);
          }

          bool hasMore = iterators.isNotEmpty;
          for (final it in iterators) {
            if (!it.moveNext()) hasMore = false;
          }

          Map<String, DbValue>? matchedRow;
          while (hasMore) {
            final values = iterators.map((it) => it.current).toList();
            if (rightJoinColIdx < values.length) {
              final targetVal = values[rightJoinColIdx];
              if (targetVal.compareTo(keyVal) == 0) {
                matchedRow = {};
                for (int i = 0; i < rightSchema.columnNames.length; i++) {
                  final colName = rightSchema.columnNames[i];
                  matchedRow['${rightSchema.name}.$colName'] = values[i];
                  matchedRow[colName] = values[i];
                }
                break;
              }
            }

            for (final it in iterators) {
              if (!it.moveNext()) hasMore = false;
            }
          }

          if (matchedRow != null) {
            final mergedRow = Map<String, DbValue>.from(leftRow)..addAll(matchedRow);
            return mergedRow;
          }
        }
      } else if (rightTable != null) {
        // Row table fallback scan path (O(N) search)
        final rightJoinColLower = rightJoinCol.toLowerCase();
        final rightJoinColIdx = rightSchema.columnNamesLower.indexOf(rightJoinColLower);
        if (rightJoinColIdx != -1) {
          Map<String, DbValue>? matchedRow;
          final rows = rightTable!.scanSync();
          for (final values in rows) {
            if (rightJoinColIdx < values.length) {
              final targetVal = values[rightJoinColIdx];
              if (targetVal.compareTo(keyVal) == 0) {
                matchedRow = {};
                for (int i = 0; i < rightSchema.columnNames.length; i++) {
                  if (i < values.length) {
                    final colName = rightSchema.columnNames[i];
                    matchedRow['${rightSchema.name}.$colName'] = values[i];
                    matchedRow[colName] = values[i];
                  }
                }
                break;
              }
            }
          }
          if (matchedRow != null) {
            final mergedRow = Map<String, DbValue>.from(leftRow)..addAll(matchedRow);
            return mergedRow;
          }
        }
      }
    }
  }

  @override
  void close() {
    left.close();
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final leftPlan = left.getPlanString(indent + 1);
    return '${padding}GraphJoinNode(on: $leftJoinCol -> ${rightSchema.name}.$rightJoinCol)\n$leftPlan';
  }
}

// HNSW Vector Index Scan Node
class HnswScanNode extends PlanNode {
  final RowTableFile tableFile;
  final TableSchema schema;
  final HnswIndex index;
  final DbVector queryVector;
  final int limit;
  final double? maxDistance;
  final Expression? filterCondition;

  List<HnswNode>? _results;
  int _cursor = 0;

  HnswScanNode({
    required this.tableFile,
    required this.schema,
    required this.index,
    required this.queryVector,
    required this.limit,
    this.maxDistance,
    this.filterCondition,
  });

  @override
  void open() {
    index.initSync();
    bool Function(int pageId, int slotId)? filterPredicate;
    if (filterCondition != null) {
      final jitFilter = JitCompiler.compile(filterCondition!);
      filterPredicate = (int pageId, int slotId) {
        final map = <String, DbValue>{};
        if (schema.isColumnar) {
          final colTable = ColumnTableFile(
            cache: tableFile.cache,
            tableName: schema.name,
            dbDirectory: tableFile.dbDirectory,
            schema: schema,
          );
          for (int i = 0; i < schema.columnNames.length; i++) {
            final colFilePath = colTable.getColumnFilePath(i);
            final pager = tableFile.cache.getOrCreatePager(colFilePath);
            if (pageId >= pager.getPageCountSync()) {
              return false;
            }
            final page = tableFile.cache.pinPageSync(colFilePath, pageId);
            try {
              final recBytes = SlottedPageHelper.getRecord(page, slotId);
              if (recBytes != null) {
                final data = ByteData.sublistView(recBytes);
                final val = DbValue.fromBytes(data, 0, recBytes.length);
                final colName = schema.columnNames[i];
                map['${schema.name}.$colName'] = val;
                map[colName] = val;
              }
            } finally {
              tableFile.cache.unpinPageSync(colFilePath, pageId, isDirty: false);
            }
          }
        } else {
          final page = tableFile.cache.pinPageSync(tableFile.filePath, pageId);
          try {
            final recBytes = SlottedPageHelper.getRecord(page, slotId);
            if (recBytes == null) {
              return false;
            }
            final values = RecordSerializer.deserializeRow(recBytes);
            for (int i = 0; i < schema.columnNames.length; i++) {
              if (i < values.length) {
                final colName = schema.columnNames[i];
                map['${schema.name}.$colName'] = values[i];
                map[colName] = values[i];
              }
            }
          } finally {
            tableFile.cache.unpinPageSync(tableFile.filePath, pageId, isDirty: false);
          }
        }
        final res = jitFilter(map);
        return (res is DbInt && res.value == 1) || (res is DbDouble && res.value > 0.0);
      };
    }
    _results = index.search(queryVector, limit, filter: filterPredicate);
    if (maxDistance != null) {
      _results = _results!
          .where((n) {
            switch (index.metric.toLowerCase()) {
              case 'cosine':
                return n.vector.cosineDistanceTo(queryVector) <= maxDistance!;
              case 'dot':
                return n.vector.dotProductTo(queryVector) <= maxDistance!;
              case 'euclidean':
              default:
                return n.vector.distanceTo(queryVector) <= maxDistance!;
            }
          })
          .toList();
    }
    _cursor = 0;
  }

  @override
  Map<String, DbValue>? next() {
    if (_results == null || _cursor >= _results!.length) return null;
    final node = _results![_cursor++];
    final map = <String, DbValue>{};
    
    if (schema.isColumnar) {
      final colTable = ColumnTableFile(
        cache: tableFile.cache,
        tableName: schema.name,
        dbDirectory: tableFile.dbDirectory,
        schema: schema,
      );
      for (int i = 0; i < schema.columnNames.length; i++) {
        final colFilePath = colTable.getColumnFilePath(i);
        final pager = tableFile.cache.getOrCreatePager(colFilePath);
        if (node.pageId >= pager.getPageCountSync()) {
          return next();
        }
        final page = tableFile.cache.pinPageSync(colFilePath, node.pageId);
        final recBytes = SlottedPageHelper.getRecord(page, node.slotId);
        if (recBytes != null) {
          final data = ByteData.sublistView(recBytes);
          final val = DbValue.fromBytes(data, 0, recBytes.length);
          final colName = schema.columnNames[i];
          map['${schema.name}.$colName'] = val;
          map[colName] = val;
        }
        tableFile.cache.unpinPageSync(colFilePath, node.pageId, isDirty: false);
      }
    } else {
      final page = tableFile.cache.pinPageSync(tableFile.filePath, node.pageId);
      final recBytes = SlottedPageHelper.getRecord(page, node.slotId);
      if (recBytes == null) {
        tableFile.cache.unpinPageSync(tableFile.filePath, node.pageId, isDirty: false);
        return next(); // Try next
      }
      final values = RecordSerializer.deserializeRow(recBytes);
      for (int i = 0; i < schema.columnNames.length; i++) {
        if (i < values.length) {
          final colName = schema.columnNames[i];
          map['${schema.name}.$colName'] = values[i];
          map[colName] = values[i];
        }
      }
      tableFile.cache.unpinPageSync(tableFile.filePath, node.pageId, isDirty: false);
    }
    return map;
  }

  @override
  void close() {
    _results = null;
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final condStr = filterCondition != null ? ', filter: ${exprToSqlString(filterCondition!)}' : '';
    return '${padding}HnswScanNode(table: ${schema.name}, limit: $limit, maxDistance: $maxDistance$condStr)';
  }
}

// IVF-FLAT Vector Index Scan Node
class IvfFlatScanNode extends PlanNode {
  final RowTableFile tableFile;
  final TableSchema schema;
  final IvfFlatIndex index;
  final DbVector queryVector;
  final int limit;
  final double? maxDistance;
  final Expression? filterCondition;

  List<IvfFlatNode>? _results;
  int _cursor = 0;

  IvfFlatScanNode({
    required this.tableFile,
    required this.schema,
    required this.index,
    required this.queryVector,
    required this.limit,
    this.maxDistance,
    this.filterCondition,
  });

  @override
  void open() {
    index.initSync();
    bool Function(int pageId, int slotId)? filterPredicate;
    if (filterCondition != null) {
      final jitFilter = JitCompiler.compile(filterCondition!);
      filterPredicate = (int pageId, int slotId) {
        final map = <String, DbValue>{};
        if (schema.isColumnar) {
          final colTable = ColumnTableFile(
            cache: tableFile.cache,
            tableName: schema.name,
            dbDirectory: tableFile.dbDirectory,
            schema: schema,
          );
          for (int i = 0; i < schema.columnNames.length; i++) {
            final colFilePath = colTable.getColumnFilePath(i);
            final pager = tableFile.cache.getOrCreatePager(colFilePath);
            if (pageId >= pager.getPageCountSync()) {
              return false;
            }
            final page = tableFile.cache.pinPageSync(colFilePath, pageId);
            try {
              final recBytes = SlottedPageHelper.getRecord(page, slotId);
              if (recBytes != null) {
                final data = ByteData.sublistView(recBytes);
                final val = DbValue.fromBytes(data, 0, recBytes.length);
                final colName = schema.columnNames[i];
                map['${schema.name}.$colName'] = val;
                map[colName] = val;
              }
            } finally {
              tableFile.cache.unpinPageSync(colFilePath, pageId, isDirty: false);
            }
          }
        } else {
          final page = tableFile.cache.pinPageSync(tableFile.filePath, pageId);
          try {
            final recBytes = SlottedPageHelper.getRecord(page, slotId);
            if (recBytes == null) {
              return false;
            }
            final values = RecordSerializer.deserializeRow(recBytes);
            for (int i = 0; i < schema.columnNames.length; i++) {
              if (i < values.length) {
                final colName = schema.columnNames[i];
                map['${schema.name}.$colName'] = values[i];
                map[colName] = values[i];
              }
            }
          } finally {
            tableFile.cache.unpinPageSync(tableFile.filePath, pageId, isDirty: false);
          }
        }
        final res = jitFilter(map);
        return (res is DbInt && res.value == 1) || (res is DbDouble && res.value > 0.0);
      };
    }
    _results = index.search(queryVector, limit, filter: filterPredicate);
    if (maxDistance != null) {
      _results = _results!
          .where((n) {
            switch (index.metric.toLowerCase()) {
              case 'cosine':
                return n.vector.cosineDistanceTo(queryVector) <= maxDistance!;
              case 'dot':
                return n.vector.dotProductTo(queryVector) <= maxDistance!;
              case 'euclidean':
              default:
                return n.vector.distanceTo(queryVector) <= maxDistance!;
            }
          })
          .toList();
    }
    _cursor = 0;
  }

  @override
  Map<String, DbValue>? next() {
    if (_results == null || _cursor >= _results!.length) return null;
    final node = _results![_cursor++];
    final map = <String, DbValue>{};
    
    if (schema.isColumnar) {
      final colTable = ColumnTableFile(
        cache: tableFile.cache,
        tableName: schema.name,
        dbDirectory: tableFile.dbDirectory,
        schema: schema,
      );
      for (int i = 0; i < schema.columnNames.length; i++) {
        final colFilePath = colTable.getColumnFilePath(i);
        final pager = tableFile.cache.getOrCreatePager(colFilePath);
        if (node.pageId >= pager.getPageCountSync()) {
          return next();
        }
        final page = tableFile.cache.pinPageSync(colFilePath, node.pageId);
        final recBytes = SlottedPageHelper.getRecord(page, node.slotId);
        if (recBytes != null) {
          final data = ByteData.sublistView(recBytes);
          final val = DbValue.fromBytes(data, 0, recBytes.length);
          final colName = schema.columnNames[i];
          map['${schema.name}.$colName'] = val;
          map[colName] = val;
        }
        tableFile.cache.unpinPageSync(colFilePath, node.pageId, isDirty: false);
      }
    } else {
      final page = tableFile.cache.pinPageSync(tableFile.filePath, node.pageId);
      final recBytes = SlottedPageHelper.getRecord(page, node.slotId);
      if (recBytes == null) {
        tableFile.cache.unpinPageSync(tableFile.filePath, node.pageId, isDirty: false);
        return next(); // Try next
      }
      final values = RecordSerializer.deserializeRow(recBytes);
      for (int i = 0; i < schema.columnNames.length; i++) {
        if (i < values.length) {
          final colName = schema.columnNames[i];
          map['${schema.name}.$colName'] = values[i];
          map[colName] = values[i];
        }
      }
      tableFile.cache.unpinPageSync(tableFile.filePath, node.pageId, isDirty: false);
    }
    return map;
  }

  @override
  void close() {
    _results = null;
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final condStr = filterCondition != null ? ', filter: ${exprToSqlString(filterCondition!)}' : '';
    return '${padding}IvfFlatScanNode(table: ${schema.name}, limit: $limit, maxDistance: $maxDistance$condStr)';
  }
}



class RowValueList {
  final List<DbValue> values;
  RowValueList(this.values);

  @override
  bool operator ==(Object other) {
    if (other is! RowValueList) return false;
    if (values.length != other.values.length) return false;
    for (int i = 0; i < values.length; i++) {
      if (values[i] != other.values[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    int hash = 17;
    for (final val in values) {
      hash = 37 * hash + val.hashCode;
    }
    return hash;
  }
}

class UnionNode extends PlanNode {
  final List<PlanNode> children;
  final List<bool> isAllFlags;

  int _currentChildIndex = 0;
  final Set<RowValueList> _seenRows = {};
  List<String>? _columnKeys;
  int _lastUnionIndex = -1;

  UnionNode(this.children, this.isAllFlags) {
    for (int i = 0; i < isAllFlags.length; i++) {
      if (!isAllFlags[i]) {
        _lastUnionIndex = i;
      }
    }
  }

  @override
  void open() {
    _currentChildIndex = 0;
    _seenRows.clear();
    _columnKeys = null;
    for (final child in children) {
      child.open();
    }
  }

  List<DbValue> _getRowValues(Map<String, DbValue> row) {
    if (row is RowMap) {
      return row.values;
    }
    return row.values.toList();
  }

  List<String> _getRowKeys(Map<String, DbValue> row) {
    if (row is RowMap) {
      final keys = List<String>.filled(row.values.length, '');
      row.keyToIndex.forEach((key, idx) {
        if (idx < keys.length) {
          final shortKey = key.split('.').last;
          if (keys[idx].isEmpty || !key.contains('.')) {
            keys[idx] = shortKey;
          }
        }
      });
      return keys;
    }
    return row.keys.map((k) => k.split('.').last).toList();
  }

  @override
  Map<String, DbValue>? next() {
    while (_currentChildIndex < children.length) {
      final child = children[_currentChildIndex];
      final row = child.next();
      if (row == null) {
        _currentChildIndex++;
        continue;
      }

      final vals = _getRowValues(row);
      _columnKeys ??= _getRowKeys(row);

      if (_lastUnionIndex != -1 && _currentChildIndex <= _lastUnionIndex + 1) {
        final rowValList = RowValueList(vals);
        if (!_seenRows.add(rowValList)) {
          // Duplicate found, skip
          continue;
        }
      }

      // Return mapped row map aligning with _columnKeys
      final resultRow = <String, DbValue>{};
      for (int i = 0; i < _columnKeys!.length; i++) {
        final key = _columnKeys![i];
        final val = i < vals.length ? vals[i] : DbNull();
        resultRow[key] = val;
        resultRow[key.split('.').last] = val;
      }
      return resultRow;
    }
    return null;
  }

  @override
  void close() {
    for (final child in children) {
      child.close();
    }
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final buffer = StringBuffer();
    buffer.write('${padding}UnionNode(isAllFlags: $isAllFlags)\n');
    for (int i = 0; i < children.length; i++) {
      buffer.write(children[i].getPlanString(indent + 1));
      if (i < children.length - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }
}

class IntersectNode extends PlanNode {
  final List<PlanNode> children;
  final Set<RowValueList> _seenRows = {};
  List<Set<RowValueList>>? _targetSets;
  List<String>? _columnKeys;
  bool _initialized = false;

  IntersectNode(this.children);

  @override
  void open() {
    for (final child in children) {
      child.open();
    }
    _seenRows.clear();
    _targetSets = null;
    _columnKeys = null;
    _initialized = false;
  }

  List<DbValue> _getRowValues(Map<String, DbValue> row) {
    if (row is RowMap) {
      return row.values;
    }
    return row.values.toList();
  }

  List<String> _getRowKeys(Map<String, DbValue> row) {
    if (row is RowMap) {
      final keys = List<String>.filled(row.values.length, '');
      row.keyToIndex.forEach((key, idx) {
        if (idx < keys.length) {
          if (keys[idx].isEmpty || keys[idx].contains('.')) {
            keys[idx] = key;
          }
        }
      });
      return keys;
    }
    return row.keys.toList();
  }

  void _lazyInit() {
    if (_initialized) return;
    _initialized = true;

    // Load children[1..] into targetSets
    _targetSets = [];
    for (int i = 1; i < children.length; i++) {
      final set = <RowValueList>{};
      final child = children[i];
      while (true) {
        final row = child.next();
        if (row == null) break;
        set.add(RowValueList(_getRowValues(row)));
      }
      _targetSets!.add(set);
    }
  }

  @override
  Map<String, DbValue>? next() {
    _lazyInit();

    while (true) {
      final row = children[0].next();
      if (row == null) return null;

      final vals = _getRowValues(row);
      _columnKeys ??= _getRowKeys(row);
      final rowValList = RowValueList(vals);

      // Check if present in ALL target sets
      bool presentInAll = true;
      for (final targetSet in _targetSets!) {
        if (!targetSet.contains(rowValList)) {
          presentInAll = false;
          break;
        }
      }

      if (!presentInAll) continue;

      if (!_seenRows.add(rowValList)) {
        // Already returned this row (INTERSECT is distinct by default)
        continue;
      }

      // Return mapped row map aligning with _columnKeys
      final resultRow = <String, DbValue>{};
      for (int i = 0; i < _columnKeys!.length; i++) {
        final key = _columnKeys![i];
        final val = i < vals.length ? vals[i] : DbNull();
        resultRow[key] = val;
      }
      return resultRow;
    }
  }

  @override
  void close() {
    for (final child in children) {
      child.close();
    }
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final buffer = StringBuffer();
    buffer.write('${padding}IntersectNode\n');
    for (int i = 0; i < children.length; i++) {
      buffer.write(children[i].getPlanString(indent + 1));
      if (i < children.length - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }
}

class ExceptNode extends PlanNode {
  final List<PlanNode> children;
  final Set<RowValueList> _seenRows = {};
  List<Set<RowValueList>>? _targetSets;
  List<String>? _columnKeys;
  bool _initialized = false;

  ExceptNode(this.children);

  @override
  void open() {
    for (final child in children) {
      child.open();
    }
    _seenRows.clear();
    _targetSets = null;
    _columnKeys = null;
    _initialized = false;
  }

  List<DbValue> _getRowValues(Map<String, DbValue> row) {
    if (row is RowMap) {
      return row.values;
    }
    return row.values.toList();
  }

  List<String> _getRowKeys(Map<String, DbValue> row) {
    if (row is RowMap) {
      final keys = List<String>.filled(row.values.length, '');
      row.keyToIndex.forEach((key, idx) {
        if (idx < keys.length) {
          if (keys[idx].isEmpty || keys[idx].contains('.')) {
            keys[idx] = key;
          }
        }
      });
      return keys;
    }
    return row.keys.toList();
  }

  void _lazyInit() {
    if (_initialized) return;
    _initialized = true;

    // Load children[1..] into targetSets
    _targetSets = [];
    for (int i = 1; i < children.length; i++) {
      final set = <RowValueList>{};
      final child = children[i];
      while (true) {
        final row = child.next();
        if (row == null) break;
        set.add(RowValueList(_getRowValues(row)));
      }
      _targetSets!.add(set);
    }
  }

  @override
  Map<String, DbValue>? next() {
    _lazyInit();

    while (true) {
      final row = children[0].next();
      if (row == null) return null;

      final vals = _getRowValues(row);
      _columnKeys ??= _getRowKeys(row);
      final rowValList = RowValueList(vals);

      // Check if present in ANY target sets
      bool presentInAny = false;
      for (final targetSet in _targetSets!) {
        if (targetSet.contains(rowValList)) {
          presentInAny = true;
          break;
        }
      }

      if (presentInAny) continue;

      if (!_seenRows.add(rowValList)) {
        // Already returned this row (EXCEPT is distinct by default)
        continue;
      }

      // Return mapped row map aligning with _columnKeys
      final resultRow = <String, DbValue>{};
      for (int i = 0; i < _columnKeys!.length; i++) {
        final key = _columnKeys![i];
        final val = i < vals.length ? vals[i] : DbNull();
        resultRow[key] = val;
      }
      return resultRow;
    }
  }

  @override
  void close() {
    for (final child in children) {
      child.close();
    }
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    final buffer = StringBuffer();
    buffer.write('${padding}ExceptNode\n');
    for (int i = 0; i < children.length; i++) {
      buffer.write(children[i].getPlanString(indent + 1));
      if (i < children.length - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }
}

class DistinctNode extends PlanNode {
  final PlanNode child;
  final Set<RowValueList> _seenRows = {};

  DistinctNode(this.child);

  @override
  void open() {
    child.open();
    _seenRows.clear();
  }

  List<DbValue> _getRowValues(Map<String, DbValue> row) {
    if (row is RowMap) {
      return row.values;
    }
    return row.values.toList();
  }

  @override
  Map<String, DbValue>? next() {
    while (true) {
      final row = child.next();
      if (row == null) return null;

      final vals = _getRowValues(row);
      final rowValList = RowValueList(vals);
      if (!_seenRows.add(rowValList)) {
        // Duplicate row, skip
        continue;
      }
      return row;
    }
  }

  @override
  void close() {
    child.close();
    _seenRows.clear();
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    return '${padding}DistinctNode\n${child.getPlanString(indent + 1)}';
  }
}

