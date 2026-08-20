import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:ultsql/ultsql.dart';

@JS('executeUltSQL')
external set _executeUltSQL(JSFunction fn);

late UltSqlEngine engine;

void main() async {
  engine = await UltSqlEngine.openMemory();

  _executeUltSQL = ((JSString queryJS) {
    return _runQuery(queryJS.toDart).toJS;
  }).toJS;

  print('⚡ Real UltSQL 100% Pure Dart Engine Initialized in Browser!');
}

Future<JSString> _runQuery(String sql) async {
  final stopwatch = Stopwatch()..start();
  try {
    final result = await engine.query(sql);
    stopwatch.stop();

    final response = {
      'status': 'success',
      'elapsedMs': (stopwatch.elapsedMicroseconds / 1000).toStringAsFixed(2),
      'columns': result.columns,
      'rows': result.rows.map((row) => row.map((v) => v is DbNull ? 'NULL' : (v.value?.toString() ?? 'NULL')).toList()).toList(),
      'message': result.message,
    };
    return jsonEncode(response).toJS;
  } catch (e) {
    stopwatch.stop();
    final response = {
      'status': 'error',
      'elapsedMs': (stopwatch.elapsedMicroseconds / 1000).toStringAsFixed(2),
      'error': e.toString(),
    };
    return jsonEncode(response).toJS;
  }
}
