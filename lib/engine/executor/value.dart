import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:collection';
import '../parser/ast.dart';

abstract class DbValue implements Comparable<DbValue> {
  const DbValue();
  DataType get type;
  dynamic get value;

  Uint8List toBytes();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DbValue) return false;
    if (type != other.type) return false;
    if (this is DbNull && other is DbNull) return true;
    if (this is DbInt && other is DbInt) return value == other.value;
    if (this is DbDouble && other is DbDouble) return value == other.value;
    if (this is DbText && other is DbText) return value == other.value;
    if (this is DbVector && other is DbVector) {
      final v1 = value;
      final v2 = other.value;
      if (v1.length != v2.length) return false;
      for (int i = 0; i < v1.length; i++) {
        if (v1[i] != v2[i]) return false;
      }
      return true;
    }
    if (this is DbJson && other is DbJson) {
      return toString() == other.toString();
    }
    return false;
  }

  @override
  int get hashCode {
    if (this is DbNull) return 0;
    if (this is DbInt) return value.hashCode;
    if (this is DbDouble) return value.hashCode;
    if (this is DbText) return value.hashCode;
    if (this is DbVector) {
      int hash = 17;
      for (final val in value) {
        hash = 37 * hash + val.hashCode;
      }
      return hash;
    }
    if (this is DbJson) {
      return toString().hashCode;
    }
    return 0;
  }

  static DbValue fromBytes(ByteData data, int offset, int length) {
    if (length == 0) return DbNull();
    final typeCode = data.getUint8(offset);
    final valOffset = offset + 1;
    final valLen = length - 1;

    switch (typeCode) {
      case 0:
        return DbNull();
      case 1:
        if (valLen == 1) {
          return DbInt(data.getInt8(valOffset));
        } else if (valLen == 2) {
          return DbInt(data.getInt16(valOffset));
        } else if (valLen == 4) {
          return DbInt(data.getInt32(valOffset));
        } else if (valLen == 8) {
          return DbInt(data.getInt64(valOffset));
        }
        throw FormatException('Invalid DbInt length: $valLen');
      case 2:
        return DbDouble(data.getFloat64(valOffset));
      case 3:
        final bytes = data.buffer.asUint8List(data.offsetInBytes + valOffset, valLen);
        return DbText(utf8.decode(bytes));
      case 4:
        final count = valLen ~/ 8;
        final list = List<double>.generate(count, (i) => data.getFloat64(valOffset + i * 8));
        return DbVector(list);
      case 5:
        final bytes = data.buffer.asUint8List(data.offsetInBytes + valOffset, valLen);
        return DbJson.fromBytes(bytes);
      default:
        return DbNull();
    }
  }

  static DbValue parseLiteral(dynamic val) {
    if (val == null) return DbNull();
    if (val is int) {
      if (val >= -100 && val <= 1000) {
        return DbInt._smallIntCache[val + 100];
      }
      return DbInt(val);
    }
    if (val is double) return DbDouble(val);
    if (val is num) return DbDouble(val.toDouble());
    if (val is String) return DbText(val);
    if (val is List<double>) return DbVector(val);
    if (val is List) {
      // Could be vector elements parsed as dynamic list of nums
      if (val.every((e) => e is num)) {
        return DbVector(val.map((e) => (e as num).toDouble()).toList());
      }
      return DbJson(val);
    }
    if (val is Map) return DbJson(val);
    return DbText(val.toString());
  }

  // Operators
  DbValue operator +(DbValue other);
  DbValue operator -(DbValue other);
  DbValue operator *(DbValue other);
  DbValue operator /(DbValue other);
  DbValue concat(DbValue other);
}

class DbNull extends DbValue {
  @override
  DataType get type => DataType.text; // Default fallback
  @override
  Null get value => null;

  @override
  Uint8List toBytes() {
    final buffer = Uint8List(1);
    buffer[0] = 0;
    return buffer;
  }

  @override
  int compareTo(DbValue other) {
    if (other is DbNull) return 0;
    return -1; // Nulls sort first
  }

  @override
  DbValue operator +(DbValue other) => DbNull();
  @override
  DbValue operator -(DbValue other) => DbNull();
  @override
  DbValue operator *(DbValue other) => DbNull();
  @override
  DbValue operator /(DbValue other) => DbNull();
  @override
  DbValue concat(DbValue other) => DbNull();

  @override
  String toString() => 'NULL';
}

class DbInt extends DbValue {
  @override
  final int value;
  @override
  DataType get type => DataType.integer;

  const DbInt._(this.value);

  static final DbInt zero = DbInt._(0);
  static final DbInt one = DbInt._(1);
  static final List<DbInt> _smallIntCache = List.generate(1101, (i) => DbInt._(i - 100));

  factory DbInt(int value) {
    if (value == 0) return zero;
    if (value == 1) return one;
    if (value >= -100 && value <= 1000) {
      return _smallIntCache[value + 100];
    }
    return DbInt._(value);
  }

  @override
  Uint8List toBytes() {
    if (value >= -128 && value <= 127) {
      final buffer = Uint8List(2);
      buffer[0] = 1;
      ByteData.sublistView(buffer).setInt8(1, value);
      return buffer;
    } else if (value >= -32768 && value <= 32767) {
      final buffer = Uint8List(3);
      final data = ByteData.sublistView(buffer);
      data.setUint8(0, 1);
      data.setInt16(1, value);
      return buffer;
    } else if (value >= -2147483648 && value <= 2147483647) {
      final buffer = Uint8List(5);
      final data = ByteData.sublistView(buffer);
      data.setUint8(0, 1);
      data.setInt32(1, value);
      return buffer;
    } else {
      final buffer = Uint8List(9);
      final data = ByteData.sublistView(buffer);
      data.setUint8(0, 1);
      data.setInt64(1, value);
      return buffer;
    }
  }

  @override
  int compareTo(DbValue other) {
    if (other is DbNull) return 1;
    if (other is DbInt) return value.compareTo(other.value);
    if (other is DbDouble) return value.toDouble().compareTo(other.value);
    return toString().compareTo(other.toString());
  }

  @override
  DbValue operator +(DbValue other) {
    if (other is DbInt) return DbInt(value + other.value);
    if (other is DbDouble) return DbDouble(value + other.value);
    return DbNull();
  }

  @override
  DbValue operator -(DbValue other) {
    if (other is DbInt) return DbInt(value - other.value);
    if (other is DbDouble) return DbDouble(value - other.value);
    return DbNull();
  }

  @override
  DbValue operator *(DbValue other) {
    if (other is DbInt) return DbInt(value * other.value);
    if (other is DbDouble) return DbDouble(value * other.value);
    return DbNull();
  }

  @override
  DbValue operator /(DbValue other) {
    if (other is DbInt) return DbDouble(value / other.value);
    if (other is DbDouble) return DbDouble(value / other.value);
    return DbNull();
  }

  @override
  DbValue concat(DbValue other) => DbText(toString() + other.toString());

  @override
  String toString() => value.toString();
}

class DbDouble extends DbValue {
  @override
  final double value;
  @override
  DataType get type => DataType.double;

  DbDouble(this.value);

  @override
  Uint8List toBytes() {
    final buffer = Uint8List(9);
    final data = ByteData.sublistView(buffer);
    data.setUint8(0, 2);
    data.setFloat64(1, value);
    return buffer;
  }

  @override
  int compareTo(DbValue other) {
    if (other is DbNull) return 1;
    if (other is DbInt) return value.compareTo(other.value.toDouble());
    if (other is DbDouble) return value.compareTo(other.value);
    return toString().compareTo(other.toString());
  }

  @override
  DbValue operator +(DbValue other) {
    if (other is DbInt) return DbDouble(value + other.value);
    if (other is DbDouble) return DbDouble(value + other.value);
    return DbNull();
  }

  @override
  DbValue operator -(DbValue other) {
    if (other is DbInt) return DbDouble(value - other.value);
    if (other is DbDouble) return DbDouble(value - other.value);
    return DbNull();
  }

  @override
  DbValue operator *(DbValue other) {
    if (other is DbInt) return DbDouble(value * other.value);
    if (other is DbDouble) return DbDouble(value * other.value);
    return DbNull();
  }

  @override
  DbValue operator /(DbValue other) {
    if (other is DbInt) return DbDouble(value / other.value);
    if (other is DbDouble) return DbDouble(value / other.value);
    return DbNull();
  }

  @override
  DbValue concat(DbValue other) => DbText(toString() + other.toString());

  @override
  String toString() => value.toString();
}

class DbText extends DbValue {
  @override
  final String value;
  @override
  DataType get type => DataType.text;

  DbText(this.value);

  @override
  Uint8List toBytes() {
    final utf8Bytes = utf8.encode(value);
    final buffer = Uint8List(1 + utf8Bytes.length);
    buffer[0] = 3;
    buffer.setAll(1, utf8Bytes);
    return buffer;
  }

  @override
  int compareTo(DbValue other) {
    if (other is DbNull) return 1;
    return value.compareTo(other.toString());
  }

  @override
  DbValue operator +(DbValue other) => DbText(value + other.toString());
  @override
  DbValue operator -(DbValue other) => DbNull();
  @override
  DbValue operator *(DbValue other) => DbNull();
  @override
  DbValue operator /(DbValue other) => DbNull();

  @override
  DbValue concat(DbValue other) => DbText(value + other.toString());

  @override
  String toString() => value;
}

class DbVector extends DbValue {
  @override
  final List<double> value;
  @override
  DataType get type => DataType.vector;

  DbVector(this.value);

  @override
  Uint8List toBytes() {
    final buffer = Uint8List(1 + value.length * 8);
    final data = ByteData.sublistView(buffer);
    data.setUint8(0, 4);
    for (int i = 0; i < value.length; i++) {
      data.setFloat64(1 + i * 8, value[i]);
    }
    return buffer;
  }

  @override
  int compareTo(DbValue other) {
    if (other is DbNull) return 1;
    return toString().compareTo(other.toString());
  }

  @override
  DbValue operator +(DbValue other) => DbNull();
  @override
  DbValue operator -(DbValue other) => DbNull();
  @override
  DbValue operator *(DbValue other) => DbNull();
  @override
  DbValue operator /(DbValue other) => DbNull();
  @override
  DbValue concat(DbValue other) => DbNull();

  @override
  String toString() => '[${value.join(", ")}]';

  double distanceTo(DbVector other) {
    // Cosine similarity or Euclidean distance. Let's do Cosine Distance (1 - similarity)
    if (value.length != other.value.length || value.isEmpty) return 1.0;
    double dotProd = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < value.length; i++) {
      dotProd += value[i] * other.value[i];
      normA += value[i] * value[i];
      normB += other.value[i] * other.value[i];
    }
    if (normA == 0.0 || normB == 0.0) return 1.0;
    return 1.0 - (dotProd / (normA.isNaN ? 1.0 : (normB.isNaN ? 1.0 : (normA * normB == 0 ? 1.0 : (normA * normB < 0 ? 0.0 : (normA * normB).toDouble())).toDouble().sqrt().toDouble())));
  }
}

// Math extension for sqrt
extension on double {
  double sqrt() {
    return math.sqrt(this);
  }
}

DbValue extractJsonPathRaw(String jsonStr, List<String> path) {
  if (path.isEmpty) return DbJson(json.decode(jsonStr));

  int segmentIdx = 0;
  int pos = 0;
  final len = jsonStr.length;

  while (segmentIdx < path.length) {
    final targetKey = path[segmentIdx];
    int braceDepth = 0;
    int bracketDepth = 0;
    bool inString = false;
    bool escaped = false;

    int keyStart = -1;
    int keyEnd = -1;

    while (pos < len) {
      final c = jsonStr.codeUnitAt(pos);
      if (escaped) {
        escaped = false;
        pos++;
        continue;
      }
      if (c == 92) { // \
        escaped = true;
        pos++;
        continue;
      }
      if (c == 34) { // "
        inString = !inString;
        if (inString) {
          keyStart = pos + 1;
        } else {
          keyEnd = pos;
        }
        pos++;
        continue;
      }

      if (!inString) {
        if (c == 123) { // {
          braceDepth++;
        } else if (c == 125) { // }
          braceDepth--;
        } else if (c == 91) { // [
          bracketDepth++;
        } else if (c == 93) { // ]
          bracketDepth--;
        } else if (c == 58 && braceDepth == 1 && bracketDepth == 0) { // :
          if (keyStart != -1 && keyEnd != -1) {
            final key = jsonStr.substring(keyStart, keyEnd);
            if (key == targetKey) {
              pos++; // skip ':'
              while (pos < len) {
                final sc = jsonStr.codeUnitAt(pos);
                if (sc == 32 || sc == 9 || sc == 10 || sc == 13) {
                  pos++;
                } else {
                  break;
                }
              }

              if (segmentIdx == path.length - 1) {
                if (pos < len) {
                  final vc = jsonStr.codeUnitAt(pos);
                  if ((vc >= 48 && vc <= 57) || vc == 45) { // number
                    int end = pos + 1;
                    while (end < len) {
                      final ec = jsonStr.codeUnitAt(end);
                      if ((ec >= 48 && ec <= 57) || ec == 46 || ec == 101 || ec == 69 || ec == 45 || ec == 43) {
                        end++;
                      } else {
                        break;
                      }
                    }
                    final numStr = jsonStr.substring(pos, end);
                    final val = num.tryParse(numStr);
                    if (val != null) return DbValue.parseLiteral(val);
                  } else if (vc == 34) { // string
                    int end = pos + 1;
                    bool valEscaped = false;
                    while (end < len) {
                      final ec = jsonStr.codeUnitAt(end);
                      if (valEscaped) {
                        valEscaped = false;
                      } else if (ec == 92) {
                        valEscaped = true;
                      } else if (ec == 34) {
                        break;
                      }
                      end++;
                    }
                    if (end < len) {
                      return DbText(jsonStr.substring(pos + 1, end));
                    }
                  } else if (jsonStr.startsWith('true', pos)) {
                    return DbInt(1);
                  } else if (jsonStr.startsWith('false', pos)) {
                    return DbInt(0);
                  } else if (jsonStr.startsWith('null', pos)) {
                    return DbNull();
                  } else if (vc == 123 || vc == 91) {
                    break;
                  }
                }
                break;
              } else {
                if (pos < len && jsonStr.codeUnitAt(pos) == 123) {
                  segmentIdx++;
                  pos++;
                  break;
                } else {
                  return DbNull();
                }
              }
            }
          }
        }
      }
      pos++;
    }

    if (pos >= len) {
      break;
    }
  }

  // Fallback to full decode
  return DbJson(json.decode(jsonStr))._extractPathSlow(path);
}

class DbJson extends DbValue {
  @override
  DataType get type => DataType.json;

  dynamic _parsedValue;
  String? _jsonStr;
  Uint8List? _jsonBytes;

  DbJson(this._parsedValue) : _jsonStr = null, _jsonBytes = null;
  DbJson.fromStr(this._jsonStr) : _parsedValue = null, _jsonBytes = null;
  DbJson.fromBytes(this._jsonBytes) : _parsedValue = null, _jsonStr = null;

  String get jsonStr {
    if (_jsonStr == null) {
      if (_jsonBytes != null) {
        _jsonStr = utf8.decode(_jsonBytes!);
      } else {
        _jsonStr = json.encode(_parsedValue);
      }
    }
    return _jsonStr!;
  }

  @override
  dynamic get value {
    if (_parsedValue == null) {
      _parsedValue = json.decode(jsonStr);
    }
    return _parsedValue;
  }

  @override
  Uint8List toBytes() {
    if (_jsonBytes != null) {
      final buffer = Uint8List(1 + _jsonBytes!.length);
      buffer[0] = 5;
      buffer.setAll(1, _jsonBytes!);
      return buffer;
    }
    final utf8Bytes = utf8.encode(jsonStr);
    final buffer = Uint8List(1 + utf8Bytes.length);
    buffer[0] = 5;
    buffer.setAll(1, utf8Bytes);
    return buffer;
  }

  @override
  int compareTo(DbValue other) {
    if (other is DbNull) return 1;
    return toString().compareTo(other.toString());
  }

  DbValue extractPath(List<String> pathSegments) {
    if (_parsedValue == null) {
      return extractJsonPathRaw(jsonStr, pathSegments);
    }
    return _extractPathSlow(pathSegments);
  }

  DbValue _extractPathSlow(List<String> pathSegments) {
    dynamic current = value;
    for (final seg in pathSegments) {
      if (current is Map && current.containsKey(seg)) {
        current = current[seg];
      } else if (current is List) {
        final index = int.tryParse(seg);
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return DbNull();
        }
      } else {
        return DbNull();
      }
    }
    return DbValue.parseLiteral(current);
  }

  @override
  DbValue operator +(DbValue other) => DbNull();
  @override
  DbValue operator -(DbValue other) => DbNull();
  @override
  DbValue operator *(DbValue other) => DbNull();
  @override
  DbValue operator /(DbValue other) => DbNull();
  @override
  DbValue concat(DbValue other) => DbNull();

  @override
  String toString() => jsonStr;
}

class RowMap extends MapBase<String, DbValue> {
  final List<DbValue> values;
  final Map<String, int> keyToIndex;

  RowMap(this.values, this.keyToIndex);

  @override
  DbValue? operator [](Object? key) {
    if (key is String) {
      final idx = keyToIndex[key];
      if (idx != null && idx < values.length) {
        return values[idx];
      }
    }
    return null;
  }

  @override
  void operator []=(String key, DbValue value) {
    final idx = keyToIndex[key];
    if (idx != null && idx < values.length) {
      values[idx] = value;
    }
  }

  @override
  void clear() {}

  @override
  Iterable<String> get keys => keyToIndex.keys;

  @override
  DbValue? remove(Object? key) => null;
}
