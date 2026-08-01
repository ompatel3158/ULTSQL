import 'dart:async';
import 'dart:convert';
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
  static dynamic activeInterpreter;

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
              return DbList(rows.map<DbValue>((r) => r.isNotEmpty ? r[0] as DbValue : DbNull()).toList());
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
          if (expr.left is VariableExpr && expr.right is VariableExpr) {
            final leftVar = expr.left as VariableExpr;
            final rightVar = expr.right as VariableExpr;
            final rightAttr = rightVar.fullName.toLowerCase();
            if (rightAttr == 'found' || rightAttr == 'notfound') {
              final envKey = '${leftVar.fullName.toLowerCase()}%$rightAttr';
              return (row) => row[envKey] ?? DbInt(0);
            }
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
      if (name == 'in_list') {
        return (row) {
          final args = argFns.map((fn) => fn(row)).toList();
          return DbList(args);
        };
      }

      if (name == 'st_point' && argFns.length == 2) {
        return (row) {
          final x = argFns[0](row);
          final y = argFns[1](row);
          double dx = 0.0, dy = 0.0;
          if (x is DbDouble) dx = x.value;
          else if (x is DbInt) dx = x.value.toDouble();
          if (y is DbDouble) dy = y.value;
          else if (y is DbInt) dy = y.value.toDouble();
          return DbText('POINT($dx $dy)');
        };
      }
      if (name == 'st_distance' && argFns.length == 2) {
        return (row) {
          final p1 = argFns[0](row);
          final p2 = argFns[1](row);
          if (p1 is DbText && p2 is DbText) {
            final pt1 = _parsePoint(p1.value);
            final pt2 = _parsePoint(p2.value);
            if (pt1 != null && pt2 != null) {
              final dist = math.sqrt(math.pow(pt1[0] - pt2[0], 2) + math.pow(pt1[1] - pt2[1], 2));
              return DbDouble(dist);
            }
          }
          return DbNull();
        };
      }
      if (name == 'st_contains' && argFns.length == 2) {
        return (row) {
          final poly = argFns[0](row);
          final pt = argFns[1](row);
          if (poly is DbText && pt is DbText) {
            final polygon = _parsePolygon(poly.value);
            final point = _parsePoint(pt.value);
            if (polygon != null && point != null) {
              // Ray casting algorithm
              bool inside = false;
              for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
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
        };
      }

      return (row) {
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
                bucketMillis = (int.tryParse(bucketStr.replaceAll('m', '')) ?? 0) * 60 * 1000;
              } else if (bucketStr.endsWith('h')) {
                bucketMillis = (int.tryParse(bucketStr.replaceAll('h', '')) ?? 0) * 60 * 60 * 1000;
              } else if (bucketStr.endsWith('s')) {
                bucketMillis = (int.tryParse(bucketStr.replaceAll('s', '')) ?? 0) * 1000;
              }
              if (bucketMillis > 0) {
                final ms = dt.millisecondsSinceEpoch;
                final bucketed = (ms ~/ bucketMillis) * bucketMillis;
                return DbText(DateTime.fromMillisecondsSinceEpoch(bucketed, isUtc: dt.isUtc).toIso8601String());
              }
            }
          }
          return DbNull();
        }

        if (name == 'vector_distance' && (argFns.length == 2 || argFns.length == 3)) {
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
        final elements = body.split(',').map((e) => double.parse(e.trim())).toList();
        return DbVector(elements);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<double>? _parsePoint(String s) {
    // Expected format: POINT(x y)
    final regex = RegExp(r'POINT\s*\(\s*([0-9.-]+)\s+([0-9.-]+)\s*\)', caseSensitive: false);
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
        return decoded.map((e) => [ (e[0] as num).toDouble(), (e[1] as num).toDouble() ]).toList();
      } catch (_) {
        return null;
      }
    }
    
    final regex = RegExp(r'POLYGON\s*\(\s*\(([^)]+)\)\s*\)', caseSensitive: false);
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
