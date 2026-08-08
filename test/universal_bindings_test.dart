import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ffi/ffi.dart';
import 'package:ultsql/src/engine/ffi/c_api.dart';

void expectVal(dynamic actual, dynamic expected, String message) {
  final actualStr = actual.toString();
  final expectedStr = expected.toString();
  if (actualStr != expectedStr) {
    throw Exception("FAIL [$message]: Expected '$expectedStr', but got '$actualStr'");
  }
}

void main() {
  test('Universal C FFI Bindings API test', () async {
    final tempDir = await Directory.systemTemp.createTemp('ultsql_c_ffi_test_');
    
    try {
      final pathPtr = tempDir.path.toNativeUtf8();
      final dbHandle = ultsql_open_c(pathPtr);
      expectVal(dbHandle > 0, true, "Database handle opened successfully");

      final sqlCreate = "CREATE TABLE ffi_users (id INT PRIMARY KEY, name TEXT, score DOUBLE)".toNativeUtf8();
      final resCreate = await ultsql_exec_async(dbHandle, sqlCreate);
      expectVal(resCreate > 0, true, "Exec CREATE TABLE handle");

      final sqlInsert = "INSERT INTO ffi_users VALUES (10, 'Universal', 99.5)".toNativeUtf8();
      final resInsert = await ultsql_exec_async(dbHandle, sqlInsert);
      expectVal(resInsert > 0, true, "Exec INSERT handle");

      final sqlSelect = "SELECT * FROM ffi_users WHERE id = 10".toNativeUtf8();
      final resSelect = await ultsql_exec_async(dbHandle, sqlSelect);
      
      final hasRow = ultsql_step_c(resSelect);
      expectVal(hasRow, 1, "step() returned row");

      final colText = ultsql_column_text_c(resSelect, 1).toDartString();
      expectVal(colText, 'Universal', "Column 1 text value");

      ultsql_close_c(dbHandle);
      print("UNIVERSAL C FFI BINDINGS TEST PASSED CLEANLY!");
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}
