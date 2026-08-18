import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import '../parser/ast.dart';
import 'value.dart';

typedef JitClosure = DbValue Function(Map<String, DbValue> rowContext);

String _toLowerCaseFast(String s) {
  final len = s.length;
  for (int i = 0; i < len; i++) {
    final c = s.codeUnitAt(i);
    if (c >= 65 && c <= 90) {
      return s.toLowerCase();
    }
  }
  return s;
}

bool matchLike(String str, String pattern) {
  if (!pattern.contains('_') && !pattern.contains('\\')) {
    final firstPct = pattern.startsWith('%');
    final lastPct = pattern.endsWith('%');
    final middlePct = pattern
        .substring(firstPct ? 1 : 0, pattern.length - (lastPct ? 1 : 0))
        .contains('%');
    if (!middlePct) {
      final subject = _toLowerCaseFast(str);
      final query = pattern
          .substring(firstPct ? 1 : 0, pattern.length - (lastPct ? 1 : 0))
          .toLowerCase();
      if (firstPct && lastPct) {
        return subject.contains(query);
      } else if (firstPct) {
        return subject.endsWith(query);
      } else if (lastPct) {
        return subject.startsWith(query);
      } else {
        return subject == query;
      }
    }
  }
  final escaped = RegExp.escape(pattern)
      .replaceAll(r'\%', '%')
      .replaceAll(r'\_', '_')
      .replaceAll('%', '.*')
      .replaceAll('_', '.');
  final regex = RegExp('^$escaped\$', caseSensitive: false);
  return regex.hasMatch(str);
}

class JitCompiler {
  static List<DbValue>? currentParams;
  static dynamic activeInterpreter;

  static JitClosure compile(Expression expr) {
    if (expr is LiteralExpr ||
        expr is PlaceholderExpr ||
        expr is VectorLiteralExpr) {
      return _compileDefault(expr);
    }
    final sqlStr = exprToSqlString(expr);
    final defaultClosure = _compileDefault(expr);

    String? resolvedKey;
    bool fallbackToDefault = false;

    return (row) {
      if (fallbackToDefault) {
        return defaultClosure(row);
      }

      if (resolvedKey != null) {
        final val = row[resolvedKey];
        if (val != null) {
          return val;
        }
      }

      if (row.containsKey(sqlStr)) {
        resolvedKey = sqlStr;
        return row[sqlStr]!;
      }

      final lowerSqlStr = sqlStr.toLowerCase();
      for (final key in row.keys) {
        if (key.toLowerCase() == lowerSqlStr) {
          resolvedKey = key;
          return row[key]!;
        }
      }

      fallbackToDefault = true;
      return defaultClosure(row);
    };
  }

  static JitClosure _compileDefault(Expression expr) {
    if (expr is SubqueryExpr) {
      return (row) {
        final active = JitCompiler.activeInterpreter;
        if (active == null) {
          return DbNull();
        }
        SubqueryContext.push(row);
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
              return DbList(
                rows
                    .map<DbValue>(
                      (r) => r.isNotEmpty ? r[0] as DbValue : DbNull(),
                    )
                    .toList(),
              );
            }
          }
          return DbNull();
        } finally {
          SubqueryContext.pop();
        }
      };
    }

    if (expr is JsonExtractExpr) {
      final baseFn = JitCompiler.compile(expr.expr);
      final path = expr.path;
      final asText = expr.asText;

      return (row) {
        final baseVal = baseFn(row);
        if (baseVal is DbJson) {
          final jsonMapOrList = baseVal.value;
          dynamic extractedRaw;
          if (jsonMapOrList is Map) {
            extractedRaw = jsonMapOrList[path];
          } else if (jsonMapOrList is List) {
            final idx = int.tryParse(path);
            if (idx != null && idx >= 0 && idx < jsonMapOrList.length) {
              extractedRaw = jsonMapOrList[idx];
            }
          }
          if (extractedRaw == null) {
            return DbNull();
          }
          if (asText) {
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
      };
    }

    if (expr is PlaceholderExpr) {
      final idx = expr.index;
      return (row) {
        if (idx != null) {
          final params = JitCompiler.currentParams;
          if (params != null && idx < params.length) {
            return params[idx];
          }
        }
        return DbNull();
      };
    }

    if (expr is LiteralExpr) {
      final val = DbValue.parseLiteral(expr.value);
      return (row) => val;
    }

    if (expr is VectorLiteralExpr) {
      final vec = DbVector(expr.elements);
      return (row) => vec;
    }

    if (expr is VariableExpr) {
      final path = expr.path;
      if (path.isEmpty) return (row) => DbNull();
      final lowerName = expr.fullName.toLowerCase();
      if (lowerName == 'true') {
        return (row) => DbJson(true);
      }
      if (lowerName == 'false') {
        return (row) => DbJson(false);
      }

      String? resolvedKey;
      int? resolvedIndex;
      int jsonPathStartIndex = 1;
      bool isSubPath = path.length > 1;

      return (row) {
        if (resolvedIndex != null && row is RowMap) {
          final val = row.values[resolvedIndex!];
          if (isSubPath && val is DbJson && jsonPathStartIndex < path.length) {
            return val.extractPath(path.sublist(jsonPathStartIndex));
          }
          return val;
        }
        if (resolvedKey != null) {
          if (row is RowMap) {
            final idx = row.keyToIndex[resolvedKey!];
            if (idx != null) {
              resolvedIndex = idx;
              final val = row.values[idx];
              if (isSubPath &&
                  val is DbJson &&
                  jsonPathStartIndex < path.length) {
                return val.extractPath(path.sublist(jsonPathStartIndex));
              }
              return val;
            }
          }
          final val = row[resolvedKey];
          if (val == null) return DbNull();
          if (isSubPath && val is DbJson && jsonPathStartIndex < path.length) {
            return val.extractPath(path.sublist(jsonPathStartIndex));
          }
          return val;
        }

        // First run: resolve the key
        final fullName = expr.fullName;
        if (row.containsKey(fullName)) {
          resolvedKey = fullName;
          jsonPathStartIndex = path.length; // No JSON path
          return row[fullName]!;
        }

        if (path.length >= 2) {
          final possibleColName = '${path[0]}.${path[1]}';
          if (row.containsKey(possibleColName)) {
            resolvedKey = possibleColName;
            jsonPathStartIndex = 2;
            final val = row[possibleColName]!;
            if (path.length > 2 && val is DbJson) {
              return val.extractPath(path.sublist(2));
            }
            return val;
          }
        }

        // Find match by column name suffix (e.g. "id" matching "users.id")
        final name = path[0];
        final lowerName = name.toLowerCase();
        for (final key in row.keys) {
          final lowerKey = key.toLowerCase();
          if (lowerKey == lowerName || lowerKey.endsWith('.$lowerName')) {
            resolvedKey = key;
            jsonPathStartIndex = 1;
            final val = row[key]!;
            if (path.length > 1 && val is DbJson) {
              return val.extractPath(path.sublist(1));
            }
            return val;
          }
        }
        final parentVal = SubqueryContext.lookup(fullName);
        if (parentVal != null) {
          return parentVal;
        }

        return DbNull();
      };
    }

    if (expr is BinaryExpr) {
      final leftFn = _compileDefault(expr.left);
      final rightFn = _compileDefault(expr.right);
      final op = expr.operator;

      switch (op.toLowerCase()) {
        case '+':
          return (row) => leftFn(row) + rightFn(row);
        case '-':
          return (row) => leftFn(row) - rightFn(row);
        case '*':
          return (row) => leftFn(row) * rightFn(row);
        case '/':
          return (row) => leftFn(row) / rightFn(row);
        case '%':
          final leftExpr = expr.left;
          final rightExpr = expr.right;
          if (leftExpr is VariableExpr &&
              rightExpr is VariableExpr &&
              (rightExpr.fullName.toLowerCase() == 'found' ||
                  rightExpr.fullName.toLowerCase() == 'notfound')) {
            final attrKey = '${leftExpr.fullName}%${rightExpr.fullName}'
                .toLowerCase();
            return (row) => row[attrKey] ?? DbNull();
          }
          return (row) {
            final leftVal = leftFn(row);
            final rightVal = rightFn(row);
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
          };
        case '||':
          return (row) => leftFn(row).concat(rightFn(row));
        case '=':
          return (row) {
            final l = leftFn(row);
            final r = rightFn(row);
            if (l is DbInt && r is DbInt)
              return l.value == r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbDouble)
              return l.value == r.value ? DbInt.one : DbInt.zero;
            if (l is DbInt && r is DbDouble)
              return l.value == r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbInt)
              return l.value == r.value ? DbInt.one : DbInt.zero;
            if (l is DbText && r is DbText)
              return l.value == r.value ? DbInt.one : DbInt.zero;
            return l.compareTo(r) == 0 ? DbInt.one : DbInt.zero;
          };
        case '!=':
        case '<>':
          return (row) {
            final l = leftFn(row);
            final r = rightFn(row);
            if (l is DbInt && r is DbInt)
              return l.value != r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbDouble)
              return l.value != r.value ? DbInt.one : DbInt.zero;
            if (l is DbInt && r is DbDouble)
              return l.value != r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbInt)
              return l.value != r.value ? DbInt.one : DbInt.zero;
            if (l is DbText && r is DbText)
              return l.value != r.value ? DbInt.one : DbInt.zero;
            return l.compareTo(r) != 0 ? DbInt.one : DbInt.zero;
          };
        case '<':
          return (row) {
            final l = leftFn(row);
            final r = rightFn(row);
            if (l is DbInt && r is DbInt)
              return l.value < r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbDouble)
              return l.value < r.value ? DbInt.one : DbInt.zero;
            if (l is DbInt && r is DbDouble)
              return l.value < r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbInt)
              return l.value < r.value ? DbInt.one : DbInt.zero;
            return l.compareTo(r) < 0 ? DbInt.one : DbInt.zero;
          };
        case '<=':
          return (row) {
            final l = leftFn(row);
            final r = rightFn(row);
            if (l is DbInt && r is DbInt)
              return l.value <= r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbDouble)
              return l.value <= r.value ? DbInt.one : DbInt.zero;
            if (l is DbInt && r is DbDouble)
              return l.value <= r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbInt)
              return l.value <= r.value ? DbInt.one : DbInt.zero;
            return l.compareTo(r) <= 0 ? DbInt.one : DbInt.zero;
          };
        case '>':
          return (row) {
            final l = leftFn(row);
            final r = rightFn(row);
            if (l is DbInt && r is DbInt)
              return l.value > r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbDouble)
              return l.value > r.value ? DbInt.one : DbInt.zero;
            if (l is DbInt && r is DbDouble)
              return l.value > r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbInt)
              return l.value > r.value ? DbInt.one : DbInt.zero;
            return l.compareTo(r) > 0 ? DbInt.one : DbInt.zero;
          };
        case '>=':
          return (row) {
            final l = leftFn(row);
            final r = rightFn(row);
            if (l is DbInt && r is DbInt)
              return l.value >= r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbDouble)
              return l.value >= r.value ? DbInt.one : DbInt.zero;
            if (l is DbInt && r is DbDouble)
              return l.value >= r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbInt)
              return l.value >= r.value ? DbInt.one : DbInt.zero;
            return l.compareTo(r) >= 0 ? DbInt.one : DbInt.zero;
          };
        case '~':
          final regFn = _compileDefault(expr.right);
          RegExp? cachedReg;
          String? lastPat;
          return (row) {
            final l = leftFn(row).toString();
            final pat = regFn(row).toString();
            if (pat != lastPat) {
              lastPat = pat;
              cachedReg = RegExp(pat);
            }
            return cachedReg?.hasMatch(l) == true ? DbInt.one : DbInt.zero;
          };
        case 'like':
        case 'ilike':
          final right = expr.right;
          final rightIsConstant =
              right is LiteralExpr || right is PlaceholderExpr;
          if (rightIsConstant) {
            RegExp? cachedRegex;
            String? lastPattern;
            DbValue? lastParam;

            bool isSimpleContains = false;
            bool isSimpleStartsWith = false;
            bool isSimpleEndsWith = false;
            bool isSimpleEquals = false;
            String simpleQuery = '';

            final int? paramIdx = right is PlaceholderExpr ? right.index : null;

            return (row) {
              if (paramIdx != null) {
                final params = JitCompiler.currentParams;
                final curParam = (params != null && paramIdx < params.length)
                    ? params[paramIdx]
                    : null;
                if (!identical(lastParam, curParam)) {
                  lastParam = curParam;
                  final pat = curParam?.toString() ?? '';
                  lastPattern = pat;
                  isSimpleContains = false;
                  isSimpleStartsWith = false;
                  isSimpleEndsWith = false;
                  isSimpleEquals = false;
                  if (!pat.contains('_') && !pat.contains('\\')) {
                    final firstPct = pat.startsWith('%');
                    final lastPct = pat.endsWith('%');
                    final middlePct = pat
                        .substring(
                          firstPct ? 1 : 0,
                          pat.length - (lastPct ? 1 : 0),
                        )
                        .contains('%');
                    if (!middlePct) {
                      if (firstPct && lastPct && pat.length >= 2) {
                        isSimpleContains = true;
                        simpleQuery = pat
                            .substring(1, pat.length - 1)
                            .toLowerCase();
                      } else if (firstPct && !lastPct && pat.length >= 1) {
                        isSimpleEndsWith = true;
                        simpleQuery = pat.substring(1).toLowerCase();
                      } else if (!firstPct && lastPct && pat.length >= 1) {
                        isSimpleStartsWith = true;
                        simpleQuery = pat
                            .substring(0, pat.length - 1)
                            .toLowerCase();
                      } else if (!firstPct && !lastPct) {
                        isSimpleEquals = true;
                        simpleQuery = pat.toLowerCase();
                      } else {
                        cachedRegex = null;
                      }
                    } else {
                      cachedRegex = null;
                    }
                  } else {
                    cachedRegex = null;
                  }

                  if (cachedRegex == null &&
                      !isSimpleContains &&
                      !isSimpleStartsWith &&
                      !isSimpleEndsWith &&
                      !isSimpleEquals) {
                    final escaped = RegExp.escape(pat)
                        .replaceAll(r'\%', '%')
                        .replaceAll(r'\_', '_')
                        .replaceAll('%', '.*')
                        .replaceAll('_', '.');
                    cachedRegex = RegExp('^$escaped\$', caseSensitive: false);
                  }
                }
              } else {
                if (lastPattern == null) {
                  final pat = rightFn(row).toString();
                  lastPattern = pat;
                  isSimpleContains = false;
                  isSimpleStartsWith = false;
                  isSimpleEndsWith = false;
                  isSimpleEquals = false;
                  if (!pat.contains('_') && !pat.contains('\\')) {
                    final firstPct = pat.startsWith('%');
                    final lastPct = pat.endsWith('%');
                    final middlePct = pat
                        .substring(
                          firstPct ? 1 : 0,
                          pat.length - (lastPct ? 1 : 0),
                        )
                        .contains('%');
                    if (!middlePct) {
                      if (firstPct && lastPct && pat.length >= 2) {
                        isSimpleContains = true;
                        simpleQuery = pat
                            .substring(1, pat.length - 1)
                            .toLowerCase();
                      } else if (firstPct && !lastPct && pat.length >= 1) {
                        isSimpleEndsWith = true;
                        simpleQuery = pat.substring(1).toLowerCase();
                      } else if (!firstPct && lastPct && pat.length >= 1) {
                        isSimpleStartsWith = true;
                        simpleQuery = pat
                            .substring(0, pat.length - 1)
                            .toLowerCase();
                      } else if (!firstPct && !lastPct) {
                        isSimpleEquals = true;
                        simpleQuery = pat.toLowerCase();
                      } else {
                        cachedRegex = null;
                      }
                    } else {
                      cachedRegex = null;
                    }
                  } else {
                    cachedRegex = null;
                  }

                  if (cachedRegex == null &&
                      !isSimpleContains &&
                      !isSimpleStartsWith &&
                      !isSimpleEndsWith &&
                      !isSimpleEquals) {
                    final escaped = RegExp.escape(pat)
                        .replaceAll(r'\%', '%')
                        .replaceAll(r'\_', '_')
                        .replaceAll('%', '.*')
                        .replaceAll('_', '.');
                    cachedRegex = RegExp('^$escaped\$', caseSensitive: false);
                  }
                }
              }

              final leftVal = leftFn(row);
              if (leftVal is DbNull) return DbInt.zero;
              final subject = _toLowerCaseFast(leftVal.toString());

              if (isSimpleContains) {
                return subject.contains(simpleQuery) ? DbInt.one : DbInt.zero;
              }
              if (isSimpleStartsWith) {
                return subject.startsWith(simpleQuery) ? DbInt.one : DbInt.zero;
              }
              if (isSimpleEndsWith) {
                return subject.endsWith(simpleQuery) ? DbInt.one : DbInt.zero;
              }
              if (isSimpleEquals) {
                return subject == simpleQuery ? DbInt.one : DbInt.zero;
              }

              return cachedRegex!.hasMatch(subject) ? DbInt.one : DbInt.zero;
            };
          }
          return (row) =>
              matchLike(leftFn(row).toString(), rightFn(row).toString())
              ? DbInt.one
              : DbInt.zero;
        case 'in':
          return (row) {
            final leftVal = leftFn(row);
            final rightVal = rightFn(row);
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
          };
        case 'and':
          return (row) {
            final leftVal = leftFn(row);
            final rightVal = rightFn(row);
            final leftTrue =
                (leftVal is DbInt && leftVal.value == 1) ||
                (leftVal is DbDouble && leftVal.value > 0.0);
            final rightTrue =
                (rightVal is DbInt && rightVal.value == 1) ||
                (rightVal is DbDouble && rightVal.value > 0.0);
            return leftTrue && rightTrue ? DbInt.one : DbInt.zero;
          };
        case 'or':
          return (row) {
            final leftVal = leftFn(row);
            final rightVal = rightFn(row);
            final leftTrue =
                (leftVal is DbInt && leftVal.value == 1) ||
                (leftVal is DbDouble && leftVal.value > 0.0);
            final rightTrue =
                (rightVal is DbInt && rightVal.value == 1) ||
                (rightVal is DbDouble && rightVal.value > 0.0);
            return leftTrue || rightTrue ? DbInt.one : DbInt.zero;
          };
        default:
          return (row) => DbNull();
      }
    }

    if (expr is CaseExpr) {
      final whenFns = expr.whenBranches
          .map(
            (w) => (
              condFn: _compileDefault(w.condition),
              thenFn: _compileDefault(w.thenExpr),
            ),
          )
          .toList();
      final elseFn = expr.elseBranch != null
          ? _compileDefault(expr.elseBranch!)
          : null;

      return (row) {
        for (final branch in whenFns) {
          final condVal = branch.condFn(row);
          // print("DEBUG CASE: row=$row, condVal=$condVal");
          final isTrue =
              (condVal is DbInt && condVal.value == 1) ||
              (condVal is DbDouble && condVal.value > 0.0) ||
              (condVal is DbText && condVal.value.toLowerCase() == 'true');
          if (isTrue) {
            return branch.thenFn(row);
          }
        }
        if (elseFn != null) {
          return elseFn(row);
        }
        return DbNull();
      };
    }

    if (expr is CastExpr) {
      final innerFn = _compileDefault(expr.expr);
      final targetType = expr.targetType;
      return (row) {
        final val = innerFn(row);
        if (val is DbNull) return DbNull();
        switch (targetType) {
          case DataType.integer:
            if (val is DbInt) return val;
            if (val is DbBool) return DbInt(val.value ? 1 : 0);
            return DbInt(int.tryParse(val.toString()) ?? 0);
          case DataType.double:
          case DataType.decimal:
            if (val is DbDouble) return val;
            if (val is DbDecimal) return val;
            if (val is DbInt) return DbDouble(val.value.toDouble());
            return DbDouble(double.tryParse(val.toString()) ?? 0.0);
          case DataType.text:
            return DbText(val.toString());
          case DataType.boolean:
            if (val is DbBool) return val;
            if (val is DbInt) return DbBool(val.value != 0);
            final s = val.toString().toLowerCase();
            return DbBool(s == 'true' || s == '1' || s == 'yes' || s == 't');
          case DataType.uuid:
            return DbUuid(val.toString());
          case DataType.datetime:
            final parsed = DateTime.tryParse(val.toString()) ?? DateTime.now();
            return DbDateTime(parsed);
          case DataType.blob:
            if (val is DbBlob) return val;
            return DbBlob(Uint8List.fromList(utf8.encode(val.toString())));
          case DataType.vector:
          case DataType.json:
            return val;
        }
      };
    }

    if (expr is FunctionCallExpr) {
      final name = expr.name.toLowerCase();
      final fullName = exprToSqlString(expr);
      final argFns = expr.arguments.map((a) => _compileDefault(a)).toList();

      return (row) {
        if (row.containsKey(fullName)) return row[fullName]!;
        final lowerFull = fullName.toLowerCase();
        if (row.containsKey(lowerFull)) return row[lowerFull]!;
        for (final k in row.keys) {
          if (k.toLowerCase() == lowerFull) return row[k]!;
        }

        if (name == 'concat') {
          final sb = StringBuffer();
          for (final fn in argFns) {
            final v = fn(row);
            if (v is! DbNull) sb.write(v.toString());
          }
          return DbText(sb.toString());
        }
        if (name == 'concat_ws' && argFns.length >= 2) {
          final sep = argFns[0](row).toString();
          final sb = StringBuffer();
          bool first = true;
          for (int i = 1; i < argFns.length; i++) {
            final v = argFns[i](row);
            if (v is! DbNull) {
              if (!first) sb.write(sep);
              sb.write(v.toString());
              first = false;
            }
          }
          return DbText(sb.toString());
        }
        if (name == 'length' || name == 'len') {
          if (argFns.isEmpty) return DbNull();
          final v = argFns.first(row);
          return v is DbNull ? DbNull() : DbInt(v.toString().length);
        }
        if (name == 'upper') {
          if (argFns.isEmpty) return DbNull();
          final v = argFns.first(row);
          return v is DbNull ? DbNull() : DbText(v.toString().toUpperCase());
        }
        if (name == 'lower') {
          if (argFns.isEmpty) return DbNull();
          final v = argFns.first(row);
          return v is DbNull ? DbNull() : DbText(v.toString().toLowerCase());
        }
        if (name == 'trim') {
          if (argFns.isEmpty) return DbNull();
          final v = argFns.first(row);
          return v is DbNull ? DbNull() : DbText(v.toString().trim());
        }
        if (name == 'substring' || name == 'substr') {
          if (argFns.isEmpty) return DbNull();
          final str = argFns[0](row).toString();
          if (str.isEmpty) return DbText('');
          final startVal = argFns.length > 1 ? argFns[1](row) : DbInt(1);
          final start =
              (startVal is DbInt
                  ? startVal.value
                  : int.tryParse(startVal.toString()) ?? 1) -
              1;
          final clampStart = start.clamp(0, str.length);
          if (argFns.length > 2) {
            final lenVal = argFns[2](row);
            final len = lenVal is DbInt
                ? lenVal.value
                : int.tryParse(lenVal.toString()) ?? str.length;
            final end = (clampStart + len).clamp(clampStart, str.length);
            return DbText(str.substring(clampStart, end));
          }
          return DbText(str.substring(clampStart));
        }
        if (name == 'coalesce') {
          for (final fn in argFns) {
            final v = fn(row);
            if (v is! DbNull) return v;
          }
          return DbNull();
        }
        if (name == 'nullif' && argFns.length >= 2) {
          final v1 = argFns[0](row);
          final v2 = argFns[1](row);
          if (v1 == v2 || v1.toString() == v2.toString()) return DbNull();
          return v1;
        }
        if (name == 'greatest') {
          DbValue? maxVal;
          for (final fn in argFns) {
            final v = fn(row);
            if (v is! DbNull) {
              if (maxVal == null || v.compareTo(maxVal) > 0) {
                maxVal = v;
              }
            }
          }
          return maxVal ?? DbNull();
        }
        if (name == 'least') {
          DbValue? minVal;
          for (final fn in argFns) {
            final v = fn(row);
            if (v is! DbNull) {
              if (minVal == null || v.compareTo(minVal) < 0) {
                minVal = v;
              }
            }
          }
          return minVal ?? DbNull();
        }
        if (name == 'typeof' && argFns.isNotEmpty) {
          final v = argFns[0](row);
          return DbText(v.type.name.toUpperCase());
        }
        if (name == 'now' || name == 'current_timestamp') {
          return DbDateTime(DateTime.now());
        }
        if (name == 'current_date') {
          final dt = DateTime.now();
          final m = dt.month.toString().padLeft(2, '0');
          final d = dt.day.toString().padLeft(2, '0');
          return DbText('${dt.year}-$m-$d');
        }
        if (name == 'gen_random_uuid' || name == 'uuid') {
          final r = math.Random();
          final u = List<int>.generate(16, (_) => r.nextInt(256));
          u[6] = (u[6] & 0x0f) | 0x40;
          u[8] = (u[8] & 0x3f) | 0x80;
          final hex = u.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
          final uuidStr =
              '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
          return DbUuid(uuidStr);
        }
        if (name == 'generate_series') {
          final args = argFns.map((fn) => fn(row)).toList();
          final start = args.isNotEmpty && args[0] is DbInt
              ? (args[0] as DbInt).value
              : int.tryParse(args.isNotEmpty ? args[0].toString() : '1') ?? 1;
          final stop = args.length > 1 && args[1] is DbInt
              ? (args[1] as DbInt).value
              : int.tryParse(args.length > 1 ? args[1].toString() : '10') ?? 10;
          final step = args.length > 2 && args[2] is DbInt
              ? (args[2] as DbInt).value
              : int.tryParse(args.length > 2 ? args[2].toString() : '1') ?? 1;
          final list = <DbValue>[];
          if (step > 0) {
            for (int i = start; i <= stop; i += step) {
              list.add(DbInt(i));
            }
          } else if (step < 0) {
            for (int i = start; i >= stop; i += step) {
              list.add(DbInt(i));
            }
          }
          return DbList(list);
        }
        if (name == 'ifnull' || name == 'nvl') {
          if (argFns.length < 2) return DbNull();
          final v1 = argFns[0](row);
          return v1 is! DbNull ? v1 : argFns[1](row);
        }
        if (name == 'date') {
          final val = argFns.isEmpty
              ? DateTime.now().toIso8601String()
              : argFns[0](row).toString();
          final dt = DateTime.tryParse(val) ?? DateTime.now();
          final m = dt.month.toString().padLeft(2, '0');
          final d = dt.day.toString().padLeft(2, '0');
          return DbText('${dt.year}-$m-$d');
        }
        if (name == 'time') {
          final val = argFns.isEmpty
              ? DateTime.now().toIso8601String()
              : argFns[0](row).toString();
          final dt = DateTime.tryParse(val) ?? DateTime.now();
          final h = dt.hour.toString().padLeft(2, '0');
          final m = dt.minute.toString().padLeft(2, '0');
          final s = dt.second.toString().padLeft(2, '0');
          return DbText('$h:$m:$s');
        }
        if (name == 'datetime') {
          final val = argFns.isEmpty ? null : argFns[0](row).toString();
          final dt = val != null && val != 'now'
              ? (DateTime.tryParse(val) ?? DateTime.now())
              : DateTime.now();
          final m = dt.month.toString().padLeft(2, '0');
          final d = dt.day.toString().padLeft(2, '0');
          final h = dt.hour.toString().padLeft(2, '0');
          final min = dt.minute.toString().padLeft(2, '0');
          final s = dt.second.toString().padLeft(2, '0');
          return DbText('${dt.year}-$m-$d $h:$min:$s');
        }
        if (name == 'abs' && argFns.isNotEmpty) {
          final v = argFns[0](row);
          if (v is DbInt) return DbInt(v.value.abs());
          if (v is DbDouble) return DbDouble(v.value.abs());
          if (v is DbDecimal) return DbDecimal(v.value.abs());
          final numVal = num.tryParse(v.toString()) ?? 0;
          return numVal is int
              ? DbInt(numVal.abs())
              : DbDouble(numVal.abs().toDouble());
        }
        if (name == 'round' && argFns.isNotEmpty) {
          final v = argFns[0](row);
          final decimals = argFns.length > 1
              ? (int.tryParse(argFns[1](row).toString()) ?? 0)
              : 0;
          final d = double.tryParse(v.toString()) ?? 0.0;
          if (decimals == 0) return DbInt(d.round());
          final mod = math.pow(10, decimals);
          return DbDouble((d * mod).round() / mod);
        }
        if ((name == 'ceil' || name == 'ceiling') && argFns.isNotEmpty) {
          final d = double.tryParse(argFns[0](row).toString()) ?? 0.0;
          return DbInt(d.ceil());
        }
        if (name == 'floor' && argFns.isNotEmpty) {
          final d = double.tryParse(argFns[0](row).toString()) ?? 0.0;
          return DbInt(d.floor());
        }
        if ((name == 'power' || name == 'pow') && argFns.length >= 2) {
          final base = double.tryParse(argFns[0](row).toString()) ?? 0.0;
          final exp = double.tryParse(argFns[1](row).toString()) ?? 0.0;
          return DbDouble(math.pow(base, exp).toDouble());
        }
        if (name == 'sqrt' && argFns.isNotEmpty) {
          final d = double.tryParse(argFns[0](row).toString()) ?? 0.0;
          return DbDouble(math.sqrt(d));
        }
        if (name == 'mod' && argFns.length >= 2) {
          final n1 = int.tryParse(argFns[0](row).toString()) ?? 0;
          final n2 = int.tryParse(argFns[1](row).toString()) ?? 1;
          return DbInt(n1 % n2);
        }
        if (name == 'sign' && argFns.isNotEmpty) {
          final d = double.tryParse(argFns[0](row).toString()) ?? 0.0;
          if (d > 0) return DbInt(1);
          if (d < 0) return DbInt(-1);
          return DbInt(0);
        }
        if (name == 'replace' && argFns.length >= 3) {
          final str = argFns[0](row).toString();
          final from = argFns[1](row).toString();
          final to = argFns[2](row).toString();
          return DbText(str.replaceAll(from, to));
        }
        if (name == 'lpad' && argFns.length >= 2) {
          final str = argFns[0](row).toString();
          final targetLen =
              int.tryParse(argFns[1](row).toString()) ?? str.length;
          final padChar = argFns.length > 2 ? argFns[2](row).toString() : ' ';
          return DbText(str.padLeft(targetLen, padChar));
        }
        if (name == 'rpad' && argFns.length >= 2) {
          final str = argFns[0](row).toString();
          final targetLen =
              int.tryParse(argFns[1](row).toString()) ?? str.length;
          final padChar = argFns.length > 2 ? argFns[2](row).toString() : ' ';
          return DbText(str.padRight(targetLen, padChar));
        }
        if (name == 'reverse' && argFns.isNotEmpty) {
          final str = argFns[0](row).toString();
          return DbText(str.split('').reversed.join());
        }
        if (name == 'regexp_like' && argFns.length >= 2) {
          final str = argFns[0](row).toString();
          final pat = argFns[1](row).toString();
          return DbBool(RegExp(pat).hasMatch(str));
        }
        if (name == 'split_part' && argFns.length >= 3) {
          final str = argFns[0](row).toString();
          final delim = argFns[1](row).toString();
          final idx = (int.tryParse(argFns[2](row).toString()) ?? 1) - 1;
          final parts = str.split(delim);
          if (idx >= 0 && idx < parts.length) return DbText(parts[idx]);
          return DbText('');
        }
        if (name == 'initcap' && argFns.isNotEmpty) {
          final str = argFns[0](row).toString();
          final res = str
              .split(' ')
              .map(
                (w) => w.isEmpty
                    ? ''
                    : w[0].toUpperCase() + w.substring(1).toLowerCase(),
              )
              .join(' ');
          return DbText(res);
        }
        if (name == 'date_add' && argFns.length >= 2) {
          final val = argFns[0](row).toString();
          final days = int.tryParse(argFns[1](row).toString()) ?? 0;
          final dt = DateTime.tryParse(val) ?? DateTime.now();
          final added = dt.add(Duration(days: days));
          final m = added.month.toString().padLeft(2, '0');
          final d = added.day.toString().padLeft(2, '0');
          return DbText('${added.year}-$m-$d');
        }
        if (name == 'date_sub' && argFns.length >= 2) {
          final val = argFns[0](row).toString();
          final days = int.tryParse(argFns[1](row).toString()) ?? 0;
          final dt = DateTime.tryParse(val) ?? DateTime.now();
          final subbed = dt.subtract(Duration(days: days));
          final m = subbed.month.toString().padLeft(2, '0');
          final d = subbed.day.toString().padLeft(2, '0');
          return DbText('${subbed.year}-$m-$d');
        }
        if (name == 'date_trunc' && argFns.length >= 2) {
          final unit = argFns[0](row).toString().toLowerCase();
          final val = argFns[1](row).toString();
          final dt = DateTime.tryParse(val) ?? DateTime.now();
          if (unit == 'year') return DbText('${dt.year}-01-01 00:00:00');
          if (unit == 'month')
            return DbText(
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-01 00:00:00',
            );
          if (unit == 'day')
            return DbText(
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} 00:00:00',
            );
          if (unit == 'hour')
            return DbText(
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:00:00',
            );
          return DbText(dt.toIso8601String());
        }
        if (name == 'extract' && argFns.length >= 2) {
          final part = argFns[0](row).toString().toLowerCase();
          final val = argFns[1](row).toString();
          final dt = DateTime.tryParse(val) ?? DateTime.now();
          if (part == 'year') return DbInt(dt.year);
          if (part == 'month') return DbInt(dt.month);
          if (part == 'day') return DbInt(dt.day);
          if (part == 'hour') return DbInt(dt.hour);
          if (part == 'minute') return DbInt(dt.minute);
          if (part == 'second') return DbInt(dt.second);
          return DbInt(0);
        }
        if (name == 'json_array') {
          final items = argFns.map((fn) => fn(row).toString()).toList();
          return DbJson(items);
        }
        if (name == 'json_object') {
          final map = <String, dynamic>{};
          for (int i = 0; i < argFns.length - 1; i += 2) {
            final k = argFns[i](row).toString();
            final v = argFns[i + 1](row);
            map[k] = v is DbInt
                ? v.value
                : (v is DbDouble ? v.value : v.toString());
          }
          return DbJson(map);
        }
        if (name == 'version') {
          return DbText('ULTSQL v1.0.12 (Pure-Dart Converged Database Engine)');
        }
        if ((name == 'position' || name == 'strpos') && argFns.length >= 2) {
          final sub = argFns[0](row).toString();
          final str = argFns[1](row).toString();
          final pos = str.indexOf(sub);
          return DbInt(pos == -1 ? 0 : pos + 1);
        }
        if (name == 'strftime') {
          if (argFns.length < 2) return DbNull();
          final fmt = argFns[0](row).toString();
          final val = argFns[1](row).toString();
          final dt = val == 'now'
              ? DateTime.now()
              : (DateTime.tryParse(val) ?? DateTime.now());
          final res = fmt
              .replaceAll('%Y', dt.year.toString())
              .replaceAll('%m', dt.month.toString().padLeft(2, '0'))
              .replaceAll('%d', dt.day.toString().padLeft(2, '0'))
              .replaceAll('%H', dt.hour.toString().padLeft(2, '0'))
              .replaceAll('%M', dt.minute.toString().padLeft(2, '0'))
              .replaceAll('%S', dt.second.toString().padLeft(2, '0'));
          return DbText(res);
        }
        if (name == 'in_list') {
          final args = argFns.map((fn) => fn(row)).toList();
          return DbList(args);
        }
        if (name == 'st_point' && argFns.length == 2) {
          final x = argFns[0](row);
          final y = argFns[1](row);
          double dx = 0.0, dy = 0.0;
          if (x is DbDouble)
            dx = x.value;
          else if (x is DbInt)
            dx = x.value.toDouble();
          if (y is DbDouble)
            dy = y.value;
          else if (y is DbInt)
            dy = y.value.toDouble();
          return DbText('POINT($dx $dy)');
        }
        if (name == 'st_distance' && argFns.length == 2) {
          final p1 = argFns[0](row);
          final p2 = argFns[1](row);
          if (p1 is DbText && p2 is DbText) {
            final pt1 = _parsePoint(p1.value);
            final pt2 = _parsePoint(p2.value);
            if (pt1 != null && pt2 != null) {
              final dist = math.sqrt(
                math.pow(pt1[0] - pt2[0], 2) + math.pow(pt1[1] - pt2[1], 2),
              );
              return DbDouble(dist);
            }
          }
          return DbNull();
        }
        if (name == 'st_contains' && argFns.length == 2) {
          final poly = argFns[0](row);
          final pt = argFns[1](row);
          if (poly is DbText && pt is DbText) {
            final polygon = _parsePolygon(poly.value);
            final point = _parsePoint(pt.value);
            if (polygon != null && point != null) {
              bool inside = false;
              for (
                int i = 0, j = polygon.length - 1;
                i < polygon.length;
                j = i++
              ) {
                if ((polygon[i][1] > point[1]) != (polygon[j][1] > point[1]) &&
                    point[0] <
                        (polygon[j][0] - polygon[i][0]) *
                                (point[1] - polygon[i][1]) /
                                (polygon[j][1] - polygon[i][1]) +
                            polygon[i][0]) {
                  inside = !inside;
                }
              }
              return DbInt(inside ? 1 : 0);
            }
          }
          return DbNull();
        }
        if (activeInterpreter != null) {
          final active = activeInterpreter!;
          final funcSchema = active.db.catalog.getFunction(name);
          if (funcSchema != null) {
            final args = argFns.map((fn) => fn(row)).toList();
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
        if (name == 'time_bucket' && argFns.length == 2) {
          final bucket = argFns[0](row);
          final time = argFns[1](row);
          if (bucket is DbText && time is DbText) {
            final bucketStr = bucket.value;
            final timeStr = time.value;
            final dt = DateTime.tryParse(timeStr);
            if (dt != null) {
              int bucketMillis = 0;
              if (bucketStr.endsWith('m')) {
                bucketMillis =
                    (int.tryParse(bucketStr.replaceAll('m', '')) ?? 0) *
                    60 *
                    1000;
              } else if (bucketStr.endsWith('h')) {
                bucketMillis =
                    (int.tryParse(bucketStr.replaceAll('h', '')) ?? 0) *
                    60 *
                    60 *
                    1000;
              } else if (bucketStr.endsWith('s')) {
                bucketMillis =
                    (int.tryParse(bucketStr.replaceAll('s', '')) ?? 0) * 1000;
              }
              if (bucketMillis > 0) {
                final ms = dt.millisecondsSinceEpoch;
                final bucketed = (ms ~/ bucketMillis) * bucketMillis;
                return DbText(
                  DateTime.fromMillisecondsSinceEpoch(
                    bucketed,
                    isUtc: dt.isUtc,
                  ).toIso8601String(),
                );
              }
            }
          }
          return DbNull();
        }
        if (name == 'vector_distance' &&
            (argFns.length == 2 || argFns.length == 3)) {
          var v1 = argFns[0](row);
          var v2 = argFns[1](row);
          String metric = 'euclidean';
          if (argFns.length == 3) {
            final mVal = argFns[2](row);
            if (mVal is DbText) {
              metric = mVal.value.toLowerCase();
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
          return DbNull();
        }
        if (name == 'cast' && argFns.length == 2) {
          final val = argFns[0](row);
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
          return DbNull();
        }
        if (name == 'json_set' && argFns.length == 3) {
          return evalJsonSet(argFns[0](row), argFns[1](row), argFns[2](row));
        }
        if (name == 'json_remove' && argFns.length == 2) {
          return evalJsonRemove(argFns[0](row), argFns[1](row));
        }
        if (name == 'json_array') {
          return evalJsonArray(argFns.map((fn) => fn(row)).toList());
        }
        if (name == 'json_object') {
          return evalJsonObject(argFns.map((fn) => fn(row)).toList());
        }
        return DbNull();
      };
    }

    return (row) => DbNull();
  }

  static DbVector? _parseVectorFromString(String s) {
    final trimmed = s.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      final body = trimmed.substring(1, trimmed.length - 1).trim();
      if (body.isEmpty) return DbVector([]);
      try {
        final elements = body
            .split(',')
            .map((e) => double.parse(e.trim()))
            .toList();
        return DbVector(elements);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<double>? _parsePoint(String s) {
    // Expected format: POINT(x y)
    final regex = RegExp(
      r'POINT\s*\(\s*([0-9.-]+)\s+([0-9.-]+)\s*\)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(s);
    if (match != null) {
      return [double.parse(match.group(1)!), double.parse(match.group(2)!)];
    }
    return null;
  }

  static List<List<double>>? _parsePolygon(String s) {
    // Simple parser for POLYGON((x1 y1, x2 y2, ...)) or JSON [[x,y],...]
    if (s.trim().startsWith('[')) {
      try {
        final decoded = json.decode(s) as List;
        return decoded
            .map((e) => [(e[0] as num).toDouble(), (e[1] as num).toDouble()])
            .toList();
      } catch (_) {
        return null;
      }
    }

    final regex = RegExp(
      r'POLYGON\s*\(\s*\(([^)]+)\)\s*\)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(s);
    if (match != null) {
      final pointsStr = match.group(1)!;
      final parts = pointsStr.split(',');
      final points = <List<double>>[];
      for (final p in parts) {
        final coords = p.trim().split(RegExp(r'\s+'));
        if (coords.length >= 2) {
          points.add([double.parse(coords[0]), double.parse(coords[1])]);
        }
      }
      return points;
    }
    return null;
  }
}
