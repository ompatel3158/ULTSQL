import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:ultsql/ultsql.dart';

@JS('executeUltSQL')
external set _executeUltSQL(JSFunction fn);

late UltSqlEngine engine;

void main() async {
  engine = await UltSqlEngine.openMemory();

  // Seed sample database tables so playground has live data immediately!
  await _seedSampleData();

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
      'rows': result.rows.map((row) => row.map((v) => v.value.toString()).toList()).toList(),
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

Future<void> _seedSampleData() async {
  try {
    await engine.query('CREATE TABLE IF NOT EXISTS users (id INT PRIMARY KEY, name VARCHAR(100), role VARCHAR(50), active BOOLEAN);');
    await engine.query("INSERT INTO users VALUES (1, 'Om Patel', 'Lead Architect', true), (2, 'Alice Chen', 'AI Researcher', true), (3, 'Marcus Vance', 'Backend Engineer', false);");

    await engine.query('CREATE TABLE IF NOT EXISTS orders (id INT PRIMARY KEY, user_id INT, amount DOUBLE);');
    await engine.query("INSERT INTO orders VALUES (101, 1, 14280.00), (102, 1, 350.00), (103, 2, 8950.50), (104, 3, 3410.00);");

    await engine.query('CREATE TABLE IF NOT EXISTS documents (id INT PRIMARY KEY, title VARCHAR(100), category VARCHAR(50), metadata JSON);');
    await engine.query("INSERT INTO documents VALUES (1, 'Attention Is All You Need', 'AI', '{\"tier\": \"VIP\", \"profile\": {\"address\": {\"city\": \"San Francisco\"}}}'), (2, 'Converged Database Architecture', 'Database', '{\"tier\": \"VIP\", \"profile\": {\"address\": {\"city\": \"New York\"}}}');");
  } catch (e) {
    print('Seed warning: $e');
  }
}
