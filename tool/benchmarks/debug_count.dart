import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void main() async {
  const dbDir = 'test_nosql_workload_db';
  final db = Database(dbDir);
  await db.init();
  final interpreter = Interpreter(db);

  print('=== EXPLAIN SELECT COUNT(*) FROM nosql ===');
  final explainRes = await interpreter.executeScript('EXPLAIN SELECT COUNT(*) FROM nosql;');
  print(explainRes);

  print('\n=== EXECUTE SELECT COUNT(*) FROM nosql ===');
  final res = await interpreter.executeScript('SELECT COUNT(*) FROM nosql;');
  print('Result message: ${res.message}');
  print('Columns: ${res.columns}');
  print('Rows length: ${res.rows.length}');
  if (res.rows.isNotEmpty) {
    print('Row 0: ${res.rows[0]}');
  }

  await db.close();
}
