import 'dart:async';
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
    final middlePct = pattern.substring(firstPct ? 1 : 0, pattern.length - (lastPct ? 1 : 0)).contains('%');
    if (!middlePct) {
      final subject = _toLowerCaseFast(str);
      final query = pattern.substring(firstPct ? 1 : 0, pattern.length - (lastPct ? 1 : 0)).toLowerCase();
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

  static JitClosure compile(Expression expr) {
    if (expr is LiteralExpr || expr is PlaceholderExpr || expr is VectorLiteralExpr) {
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
              if (isSubPath && val is DbJson && jsonPathStartIndex < path.length) {
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
        for (final key in row.keys) {
          if (key == name || key.endsWith('.$name')) {
            resolvedKey = key;
            jsonPathStartIndex = 1;
            final val = row[key]!;
            if (path.length > 1 && val is DbJson) {
              return val.extractPath(path.sublist(1));
            }
            return val;
          }
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
            if (l is DbInt && r is DbInt) return l.value == r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbDouble) return l.value == r.value ? DbInt.one : DbInt.zero;
            if (l is DbInt && r is DbDouble) return l.value == r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbInt) return l.value == r.value ? DbInt.one : DbInt.zero;
            if (l is DbText && r is DbText) return l.value == r.value ? DbInt.one : DbInt.zero;
            return l.compareTo(r) == 0 ? DbInt.one : DbInt.zero;
          };
        case '!=':
        case '<>':
          return (row) {
            final l = leftFn(row);
            final r = rightFn(row);
            if (l is DbInt && r is DbInt) return l.value != r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbDouble) return l.value != r.value ? DbInt.one : DbInt.zero;
            if (l is DbInt && r is DbDouble) return l.value != r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbInt) return l.value != r.value ? DbInt.one : DbInt.zero;
            if (l is DbText && r is DbText) return l.value != r.value ? DbInt.one : DbInt.zero;
            return l.compareTo(r) != 0 ? DbInt.one : DbInt.zero;
          };
        case '<':
          return (row) {
            final l = leftFn(row);
            final r = rightFn(row);
            if (l is DbInt && r is DbInt) return l.value < r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbDouble) return l.value < r.value ? DbInt.one : DbInt.zero;
            if (l is DbInt && r is DbDouble) return l.value < r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbInt) return l.value < r.value ? DbInt.one : DbInt.zero;
            return l.compareTo(r) < 0 ? DbInt.one : DbInt.zero;
          };
        case '<=':
          return (row) {
            final l = leftFn(row);
            final r = rightFn(row);
            if (l is DbInt && r is DbInt) return l.value <= r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbDouble) return l.value <= r.value ? DbInt.one : DbInt.zero;
            if (l is DbInt && r is DbDouble) return l.value <= r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbInt) return l.value <= r.value ? DbInt.one : DbInt.zero;
            return l.compareTo(r) <= 0 ? DbInt.one : DbInt.zero;
          };
        case '>':
          return (row) {
            final l = leftFn(row);
            final r = rightFn(row);
            if (l is DbInt && r is DbInt) return l.value > r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbDouble) return l.value > r.value ? DbInt.one : DbInt.zero;
            if (l is DbInt && r is DbDouble) return l.value > r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbInt) return l.value > r.value ? DbInt.one : DbInt.zero;
            return l.compareTo(r) > 0 ? DbInt.one : DbInt.zero;
          };
        case '>=':
          return (row) {
            final l = leftFn(row);
            final r = rightFn(row);
            if (l is DbInt && r is DbInt) return l.value >= r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbDouble) return l.value >= r.value ? DbInt.one : DbInt.zero;
            if (l is DbInt && r is DbDouble) return l.value >= r.value ? DbInt.one : DbInt.zero;
            if (l is DbDouble && r is DbInt) return l.value >= r.value ? DbInt.one : DbInt.zero;
            return l.compareTo(r) >= 0 ? DbInt.one : DbInt.zero;
          };
        case 'like':
          final right = expr.right;
          final rightIsConstant = right is LiteralExpr || right is PlaceholderExpr;
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
                final curParam = (params != null && paramIdx < params.length) ? params[paramIdx] : null;
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
                    final middlePct = pat.substring(firstPct ? 1 : 0, pat.length - (lastPct ? 1 : 0)).contains('%');
                    if (!middlePct) {
                      if (firstPct && lastPct && pat.length >= 2) {
                        isSimpleContains = true;
                        simpleQuery = pat.substring(1, pat.length - 1).toLowerCase();
                      } else if (firstPct && !lastPct && pat.length >= 1) {
                        isSimpleEndsWith = true;
                        simpleQuery = pat.substring(1).toLowerCase();
                      } else if (!firstPct && lastPct && pat.length >= 1) {
                        isSimpleStartsWith = true;
                        simpleQuery = pat.substring(0, pat.length - 1).toLowerCase();
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

                  if (cachedRegex == null && !isSimpleContains && !isSimpleStartsWith && !isSimpleEndsWith && !isSimpleEquals) {
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
                    final middlePct = pat.substring(firstPct ? 1 : 0, pat.length - (lastPct ? 1 : 0)).contains('%');
                    if (!middlePct) {
                      if (firstPct && lastPct && pat.length >= 2) {
                        isSimpleContains = true;
                        simpleQuery = pat.substring(1, pat.length - 1).toLowerCase();
                      } else if (firstPct && !lastPct && pat.length >= 1) {
                        isSimpleEndsWith = true;
                        simpleQuery = pat.substring(1).toLowerCase();
                      } else if (!firstPct && lastPct && pat.length >= 1) {
                        isSimpleStartsWith = true;
                        simpleQuery = pat.substring(0, pat.length - 1).toLowerCase();
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

                  if (cachedRegex == null && !isSimpleContains && !isSimpleStartsWith && !isSimpleEndsWith && !isSimpleEquals) {
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
          return (row) => matchLike(leftFn(row).toString(), rightFn(row).toString()) ? DbInt.one : DbInt.zero;
        case 'and':
          return (row) {
            final leftVal = leftFn(row);
            final rightVal = rightFn(row);
            final leftTrue = (leftVal is DbInt && leftVal.value == 1) || (leftVal is DbDouble && leftVal.value > 0.0);
            final rightTrue = (rightVal is DbInt && rightVal.value == 1) || (rightVal is DbDouble && rightVal.value > 0.0);
            return leftTrue && rightTrue ? DbInt.one : DbInt.zero;
          };
        case 'or':
          return (row) {
            final leftVal = leftFn(row);
            final rightVal = rightFn(row);
            final leftTrue = (leftVal is DbInt && leftVal.value == 1) || (leftVal is DbDouble && leftVal.value > 0.0);
            final rightTrue = (rightVal is DbInt && rightVal.value == 1) || (rightVal is DbDouble && rightVal.value > 0.0);
            return leftTrue || rightTrue ? DbInt.one : DbInt.zero;
          };
        default:
          return (row) => DbNull();
      }
    }

    if (expr is FunctionCallExpr) {
      final name = expr.name.toLowerCase();
      final argFns = expr.arguments.map((a) => _compileDefault(a)).toList();

      if (name == 'vector_distance' && argFns.length == 2) {
        final v1Fn = argFns[0];
        final v2Fn = argFns[1];
        return (row) {
          var v1 = v1Fn(row);
          var v2 = v2Fn(row);
          if (v1 is DbText) {
            v1 = _parseVectorFromString(v1.value) ?? v1;
          }
          if (v2 is DbText) {
            v2 = _parseVectorFromString(v2.value) ?? v2;
          }
          if (v1 is DbVector && v2 is DbVector) {
            return DbDouble(v1.distanceTo(v2));
          }
          return DbNull();
        };
      }
      if (name == 'cast' && argFns.length == 2) {
        final valFn = argFns[0];
        final typeStr = (expr.arguments[1] as LiteralExpr).value.toString();
        return (row) {
          final val = valFn(row);
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
        };
      }
    }

    return (row) => DbNull();
  }

  static DbVector? _parseVectorFromString(String s) {
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
}
