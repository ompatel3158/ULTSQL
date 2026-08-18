import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:convert';

// Import local packages
import 'package:ultsql/src/engine/storage/catalog.dart';
import 'package:ultsql/src/engine/storage/table_file.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/executor/plan_nodes.dart';
import 'package:ultsql/src/engine/executor/jit_compiler.dart';
import 'package:ultsql/src/engine/parser/ast.dart';
import 'package:ultsql/src/engine/cache/page_cache.dart';

class ParallelScanTask {
  final String filePath;
  final int startPage;
  final int endPage;
  final Uint8List? encryptionKey;
  final TableSchema schema;
  final Expression? condition; // JIT filter
  final List<Projection>? projections; // JIT projections
  final Expression? groupByExpr;
  final List<Projection>? aggProjections;

  ParallelScanTask({
    required this.filePath,
    required this.startPage,
    required this.endPage,
    this.encryptionKey,
    required this.schema,
    this.condition,
    this.projections,
    this.groupByExpr,
    this.aggProjections,
  });
}

// Function executed in worker isolate for simple scan + JIT filter
List<Map<String, DbValue>> runParallelScanWorker(ParallelScanTask task) {
  final cache = PageCache(maxCapacity: 100, dbDirectory: null);
  cache.encryptionKey = task.encryptionKey;

  final conditionFn = task.condition != null
      ? JitCompiler.compile(task.condition!)
      : null;
  final results = <Map<String, DbValue>>[];

  for (int pageId = task.startPage; pageId < task.endPage; pageId++) {
    final page = cache.pinPageSync(task.filePath, pageId);
    final rowCount = SlottedPageHelper.getRowCount(page);

    for (int slot = 0; slot < rowCount; slot++) {
      final recBytes = SlottedPageHelper.getRecord(page, slot);
      if (recBytes != null) {
        List<DbValue> row;
        try {
          final mvccRecord = MvccRecord.fromBytes(recBytes);
          row = RecordSerializer.deserializeRow(mvccRecord.rowData);
        } catch (_) {
          row = RecordSerializer.deserializeRow(recBytes);
        }

        final rowMap = <String, DbValue>{};
        for (int i = 0; i < task.schema.columnNames.length; i++) {
          rowMap[task.schema.columnNames[i]] = row[i];
          rowMap['${task.schema.name}.${task.schema.columnNames[i]}'] = row[i];
        }

        if (conditionFn != null) {
          final filterVal = conditionFn(rowMap);
          final isTrue =
              (filterVal is DbInt && filterVal.value == 1) ||
              (filterVal is DbDouble && filterVal.value > 0.0);
          if (!isTrue) continue;
        }

        if (task.projections != null) {
          final projectedRow = <String, DbValue>{};
          for (final proj in task.projections!) {
            final val = evaluateExpression(proj.expr, rowMap);
            final key =
                proj.alias ??
                (proj.expr is VariableExpr
                    ? (proj.expr as VariableExpr).fullName
                    : val.toString());
            projectedRow[key] = val;
          }
          results.add(projectedRow);
        } else {
          results.add(rowMap);
        }
      }
    }
    cache.unpinPageSync(task.filePath, pageId, isDirty: false);
  }

  cache.closeAllSync();
  return results;
}

// Function executed in worker isolate for scan + local pre-aggregation
List<Map<String, DbValue>> runParallelAggWorker(ParallelScanTask task) {
  final cache = PageCache(maxCapacity: 100, dbDirectory: null);
  cache.encryptionKey = task.encryptionKey;

  final conditionFn = task.condition != null
      ? JitCompiler.compile(task.condition!)
      : null;
  final groupKeyFn = task.groupByExpr != null
      ? JitCompiler.compile(task.groupByExpr!)
      : null;

  final argJits = <Projection, JitClosure>{};
  if (task.aggProjections != null) {
    for (final proj in task.aggProjections!) {
      final expr = proj.expr;
      if (expr is FunctionCallExpr && expr.arguments.isNotEmpty) {
        argJits[proj] = JitCompiler.compile(expr.arguments[0]);
      } else if (expr is! FunctionCallExpr) {
        argJits[proj] = JitCompiler.compile(expr);
      }
    }
  }

  final groups = <DbValue, AggregationState>{};

  for (int pageId = task.startPage; pageId < task.endPage; pageId++) {
    final page = cache.pinPageSync(task.filePath, pageId);
    final rowCount = SlottedPageHelper.getRowCount(page);

    for (int slot = 0; slot < rowCount; slot++) {
      final recBytes = SlottedPageHelper.getRecord(page, slot);
      if (recBytes != null) {
        List<DbValue> row;
        try {
          final mvccRecord = MvccRecord.fromBytes(recBytes);
          row = RecordSerializer.deserializeRow(mvccRecord.rowData);
        } catch (_) {
          row = RecordSerializer.deserializeRow(recBytes);
        }

        final rowMap = <String, DbValue>{};
        for (int i = 0; i < task.schema.columnNames.length; i++) {
          rowMap[task.schema.columnNames[i]] = row[i];
          rowMap['${task.schema.name}.${task.schema.columnNames[i]}'] = row[i];
        }

        if (conditionFn != null) {
          final filterVal = conditionFn(rowMap);
          final isTrue =
              (filterVal is DbInt && filterVal.value == 1) ||
              (filterVal is DbDouble && filterVal.value > 0.0);
          if (!isTrue) continue;
        }

        if (groupKeyFn != null) {
          final key = groupKeyFn(rowMap);
          final state = groups.putIfAbsent(key, () => AggregationState(rowMap));
          state.update(rowMap, task.aggProjections!, argJits);
        } else {
          final key = DbInt(1);
          final state = groups.putIfAbsent(key, () => AggregationState(rowMap));
          state.update(rowMap, task.aggProjections!, argJits);
        }
      }
    }
    cache.unpinPageSync(task.filePath, pageId, isDirty: false);
  }

  final localAggregated = <Map<String, DbValue>>[];
  for (final entry in groups.entries) {
    final keyVal = entry.key;
    final state = entry.value;

    final aggMap = <String, DbValue>{};
    aggMap['group_key'] = keyVal;

    for (final proj in task.aggProjections!) {
      final expr = proj.expr;
      final key = proj.alias ?? exprToSqlString(expr);

      if (expr is FunctionCallExpr) {
        final funcName = expr.name.toLowerCase();
        if (funcName == 'count') {
          aggMap[key] = DbInt(state.counts[key] ?? 0);
        } else if (funcName == 'sum') {
          final sumVal = state.sums[key];
          if (sumVal == null) {
            aggMap[key] = DbNull();
          } else {
            aggMap[key] = (state.sumsIsDouble[key] ?? false)
                ? DbDouble(sumVal)
                : DbInt(sumVal.toInt());
          }
        } else if (funcName == 'avg') {
          aggMap[key] = DbDouble(state.avgSums[key] ?? 0.0);
          aggMap['${key}_count'] = DbInt(state.avgCounts[key] ?? 0);
        } else if (funcName == 'min') {
          aggMap[key] = state.mins[key] ?? DbNull();
        } else if (funcName == 'max') {
          aggMap[key] = state.maxes[key] ?? DbNull();
        } else {
          aggMap[key] = state.firstVals[key] ?? DbNull();
        }
      } else {
        aggMap[key] = state.firstVals[key] ?? DbNull();
      }
    }
    localAggregated.add(aggMap);
  }

  cache.closeAllSync();
  return localAggregated;
}

class ParallelScanNode extends PlanNode {
  final String filePath;
  final TableSchema schema;
  final Uint8List? encryptionKey;
  final Expression? condition;
  final List<Projection>? projections;
  final int pageCount;
  final int numWorkers;

  final Expression? groupByExpr;
  final List<Projection>? aggProjections;

  List<Map<String, DbValue>>? _rows;
  int _cursor = 0;

  ParallelScanNode({
    required this.filePath,
    required this.schema,
    this.encryptionKey,
    this.condition,
    this.projections,
    required this.pageCount,
    this.numWorkers = 4,
    this.groupByExpr,
    this.aggProjections,
  });

  @override
  void open() {
    _cursor = 0;
  }

  Future<void> executeParallelScan() async {
    if (pageCount == 0) {
      _rows = [];
      return;
    }

    final futures = <Future<List<Map<String, DbValue>>>>[];

    for (int k = 0; k < numWorkers; k++) {
      final startPage =
          k * (pageCount ~/ numWorkers) +
          (k < pageCount % numWorkers ? k : pageCount % numWorkers);
      final endPage =
          (k + 1) * (pageCount ~/ numWorkers) +
          ((k + 1) < pageCount % numWorkers ? (k + 1) : pageCount % numWorkers);

      if (startPage >= endPage) continue;

      final task = ParallelScanTask(
        filePath: filePath,
        startPage: startPage,
        endPage: endPage,
        encryptionKey: encryptionKey,
        schema: schema,
        condition: condition,
        projections: projections,
        groupByExpr: groupByExpr,
        aggProjections: aggProjections,
      );

      if (groupByExpr != null || aggProjections != null) {
        futures.add(Isolate.run(() => runParallelAggWorker(task)));
      } else {
        futures.add(Isolate.run(() => runParallelScanWorker(task)));
      }
    }

    final results = await Future.wait(futures);

    if (groupByExpr != null || aggProjections != null) {
      final mergedGroups = <DbValue, Map<String, DbValue>>{};

      for (final workerRes in results) {
        for (final row in workerRes) {
          final groupKey = row['group_key']!;
          if (!mergedGroups.containsKey(groupKey)) {
            mergedGroups[groupKey] = Map<String, DbValue>.from(row);
          } else {
            final mergedRow = mergedGroups[groupKey]!;
            for (final proj in aggProjections!) {
              final key = proj.alias ?? exprToSqlString(proj.expr);
              final expr = proj.expr;
              if (expr is FunctionCallExpr) {
                final funcName = expr.name.toLowerCase();
                final val1 = mergedRow[key]!;
                final val2 = row[key]!;
                if (funcName == 'count' || funcName == 'sum') {
                  if (val1 is DbInt && val2 is DbInt) {
                    mergedRow[key] = DbInt(val1.value + val2.value);
                  } else if (val1 is DbDouble || val2 is DbDouble) {
                    final d1 = val1 is DbInt
                        ? val1.value.toDouble()
                        : (val1 is DbDouble ? val1.value : 0.0);
                    final d2 = val2 is DbInt
                        ? val2.value.toDouble()
                        : (val2 is DbDouble ? val2.value : 0.0);
                    mergedRow[key] = DbDouble(d1 + d2);
                  }
                } else if (funcName == 'avg') {
                  final totalSum =
                      (val1 as DbDouble).value + (val2 as DbDouble).value;
                  final totalCount =
                      (mergedRow['${key}_count'] as DbInt).value +
                      (row['${key}_count'] as DbInt).value;
                  mergedRow[key] = DbDouble(totalSum);
                  mergedRow['${key}_count'] = DbInt(totalCount);
                } else if (funcName == 'min') {
                  if (val1 is! DbNull && val2 is! DbNull) {
                    mergedRow[key] = val1.compareTo(val2) < 0 ? val1 : val2;
                  } else if (val1 is DbNull) {
                    mergedRow[key] = val2;
                  }
                } else if (funcName == 'max') {
                  if (val1 is! DbNull && val2 is! DbNull) {
                    mergedRow[key] = val1.compareTo(val2) > 0 ? val1 : val2;
                  } else if (val1 is DbNull) {
                    mergedRow[key] = val2;
                  }
                }
              }
            }
          }
        }
      }

      for (final row in mergedGroups.values) {
        row.remove('group_key');
        for (final proj in aggProjections!) {
          final expr = proj.expr;
          if (expr is FunctionCallExpr && expr.name.toLowerCase() == 'avg') {
            final key = proj.alias ?? exprToSqlString(expr);
            final totalSum = row[key] as DbDouble;
            final totalCount = row['${key}_count'] as DbInt;
            row[key] = totalCount.value > 0
                ? DbDouble(totalSum.value / totalCount.value)
                : DbNull();
            row.remove('${key}_count');
          }
        }
      }

      _rows = mergedGroups.values.toList();
    } else {
      _rows = results.expand((x) => x).toList();
    }
  }

  @override
  Map<String, DbValue>? next() {
    if (_rows == null) {
      throw StateError(
        "ParallelScanNode not executed. Call executeParallelScan() first.",
      );
    }
    if (_cursor >= _rows!.length) return null;
    return _rows![_cursor++];
  }

  @override
  void close() {
    _rows = null;
  }

  @override
  String getPlanString([int indent = 0]) {
    final padding = '  ' * indent;
    return '${padding}ParallelScanNode(table: ${schema.name}, workers: $numWorkers)';
  }
}

class IndexExtractorTask {
  final String filePath;
  final int startPage;
  final int endPage;
  final List<int> colIndexes;
  final int keyColumns;
  final Uint8List? encryptionKey;
  final TableSchema schema;

  IndexExtractorTask({
    required this.filePath,
    required this.startPage,
    required this.endPage,
    required this.colIndexes,
    required this.keyColumns,
    this.encryptionKey,
    required this.schema,
  });
}

Float64List runParallelIndexKeyExtractor(IndexExtractorTask task) {
  final cache = PageCache(maxCapacity: 100, dbDirectory: null);
  cache.encryptionKey = task.encryptionKey;

  final entries = <double>[];
  final K = task.keyColumns;
  final schemaLen = task.schema.columnNames.length;

  for (int pageId = task.startPage; pageId < task.endPage; pageId++) {
    final page = cache.pinPageSync(task.filePath, pageId);
    final byteData = page.byteData;
    final rowCount = SlottedPageHelper.getRowCount(page);

    for (int slotId = 0; slotId < rowCount; slotId++) {
      final slotOffset = SlottedPageHelper.headerSize + slotId * 4;
      final recordOffset = byteData.getUint16(slotOffset);
      final recordLen = byteData.getUint16(slotOffset + 2);

      if (recordLen == 0 || recordOffset >= page.data.length) continue;

      // Determine where rowData starts (MVCC check)
      int rowStartOffset = recordOffset;
      int rowLength = recordLen;

      if (recordLen >= 12) {
        final countAt12 = byteData.getUint16(recordOffset + 12);
        if (countAt12 == schemaLen) {
          rowStartOffset = recordOffset + 12;
          rowLength = recordLen - 12;
        }
      }

      final count = byteData.getUint16(rowStartOffset);

      bool hasAllKeys = true;
      final compositeKey = List<double>.filled(K, 0.0);
      for (int i = 0; i < K; i++) {
        final cIdx = task.colIndexes[i];
        if (cIdx == -1 || cIdx >= count) {
          hasAllKeys = false;
          break;
        }

        // Get cell offset and length within the page
        final startOffset = byteData.getUint16(rowStartOffset + 2 + cIdx * 2);
        final endOffset = (cIdx + 1 < count)
            ? byteData.getUint16(rowStartOffset + 2 + (cIdx + 1) * 2)
            : rowLength;

        final len = endOffset - startOffset;
        if (len <= 0) {
          hasAllKeys = false;
          break;
        }

        final cellPageOffset = rowStartOffset + startOffset;
        final typeCode = byteData.getUint8(cellPageOffset);
        double? dKey;
        if (typeCode == 1) {
          final valLen = len - 1;
          if (valLen == 1) {
            dKey = byteData.getInt8(cellPageOffset + 1).toDouble();
          } else if (valLen == 2) {
            dKey = byteData.getInt16(cellPageOffset + 1).toDouble();
          } else if (valLen == 4) {
            dKey = byteData.getInt32(cellPageOffset + 1).toDouble();
          } else if (valLen == 8) {
            dKey = byteData.getInt64(cellPageOffset + 1).toDouble();
          }
        } else if (typeCode == 2) {
          dKey = byteData.getFloat64(cellPageOffset + 1);
        } else if (typeCode == 3) {
          final valOffset = cellPageOffset + 1;
          final valLen = len - 1;
          final bytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes + valOffset,
            valLen,
          );
          final str = utf8.decode(bytes);
          final parsed = double.tryParse(str);
          if (parsed != null) {
            dKey = parsed;
          } else {
            double hash = 0.0;
            for (int j = 0; j < str.length; j++) {
              hash = (hash * 31.0 + str.codeUnitAt(j)) % 9007199254740991;
            }
            dKey = hash;
          }
        }

        if (dKey == null) {
          hasAllKeys = false;
          break;
        }
        compositeKey[i] = dKey;
      }

      if (hasAllKeys) {
        for (int i = 0; i < K; i++) {
          entries.add(compositeKey[i]);
        }
        entries.add(pageId.toDouble());
        entries.add(slotId.toDouble());
      }
    }
    cache.unpinPageSync(task.filePath, pageId, isDirty: false);
  }

  cache.closeAllSync();
  return Float64List.fromList(entries);
}
