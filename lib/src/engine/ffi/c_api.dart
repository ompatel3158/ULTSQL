import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../executor/interpreter.dart';
import '../executor/value.dart';

/// Opaque pointers for C FFI bindings.
final class UltSqlDbStruct extends Opaque {}

final class UltSqlResStruct extends Opaque {}

/// C FFI Session Handle wrapper.
class UltSqlDbHandle {
  final Database db;
  late final Interpreter interpreter;

  UltSqlDbHandle(this.db) {
    interpreter = Interpreter(db);
  }
}

/// C FFI Result Handle wrapper.
class UltSqlResHandle {
  final QueryResult result;
  int currentRowIndex = -1;

  UltSqlResHandle(this.result);

  bool step() {
    if (currentRowIndex + 1 < result.rows.length) {
      currentRowIndex++;
      return true;
    }
    return false;
  }

  String getColumnText(int colIndex) {
    if (currentRowIndex >= 0 && currentRowIndex < result.rows.length) {
      final row = result.rows[currentRowIndex];
      if (colIndex >= 0 && colIndex < row.length) {
        return row[colIndex].value.toString();
      }
    }
    return '';
  }

  int getColumnInt(int colIndex) {
    if (currentRowIndex >= 0 && currentRowIndex < result.rows.length) {
      final row = result.rows[currentRowIndex];
      if (colIndex >= 0 && colIndex < row.length) {
        final val = row[colIndex];
        if (val is DbInt) return val.value;
        return int.tryParse(val.value.toString()) ?? 0;
      }
    }
    return 0;
  }

  double getColumnDouble(int colIndex) {
    if (currentRowIndex >= 0 && currentRowIndex < result.rows.length) {
      final row = result.rows[currentRowIndex];
      if (colIndex >= 0 && colIndex < row.length) {
        final val = row[colIndex];
        if (val is DbDouble) return val.value;
        if (val is DbInt) return val.value.toDouble();
        return double.tryParse(val.value.toString()) ?? 0.0;
      }
    }
    return 0.0;
  }
}

/// Global registry mapping handles for C ABI export.
final Map<int, UltSqlDbHandle> _cDbHandles = {};
final Map<int, UltSqlResHandle> _cResHandles = {};
int _handleCounter = 1;

/// C ABI Function: Open database instance.
int ultsql_open_c(Pointer<Utf8> pathPtr) {
  final path = pathPtr.toDartString();
  final db = Database(path);
  final handleId = _handleCounter++;
  _cDbHandles[handleId] = UltSqlDbHandle(db);
  return handleId;
}

/// C ABI Function: Execute SQL script (async).
Future<int> ultsql_exec_async(int dbHandleId, Pointer<Utf8> sqlPtr) async {
  final dbHandle = _cDbHandles[dbHandleId];
  if (dbHandle == null) return 0;
  final sql = sqlPtr.toDartString();

  final res = await dbHandle.interpreter.executeScript(sql);

  final resHandleId = _handleCounter++;
  _cResHandles[resHandleId] = UltSqlResHandle(res);
  return resHandleId;
}

/// C ABI Function: Step through query results.
int ultsql_step_c(int resHandleId) {
  final resHandle = _cResHandles[resHandleId];
  if (resHandle == null) return 0;
  return resHandle.step() ? 1 : 0;
}

/// C ABI Function: Get column text value.
Pointer<Utf8> ultsql_column_text_c(int resHandleId, int colIndex) {
  final resHandle = _cResHandles[resHandleId];
  if (resHandle == null) return ''.toNativeUtf8();
  return resHandle.getColumnText(colIndex).toNativeUtf8();
}

/// C ABI Function: Close database instance.
void ultsql_close_c(int dbHandleId) {
  final handle = _cDbHandles.remove(dbHandleId);
  handle?.db.close();
}
