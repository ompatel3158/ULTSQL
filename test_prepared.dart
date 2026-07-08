import 'dart:io';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';

void main() async {
  const dbDir = 'test_prep_db';
  final dir = Directory(dbDir);
  if (dir.existsSync()) {
    try { dir.deleteSync(recursive: true); } catch (_) {}
  }
  dir.createSync(recursive: true);

  final db = Database(dbDir);
  await db.init();
  final interpreter = Interpreter(db);
  await interpreter.executeScript('CREATE TABLE t_prep(id INT, name TEXT);');
  await interpreter.executeScript('INSERT INTO t_prep VALUES (10, \'Alice\');');
  
  try {
    final stmt = db.prepare('DELETE FROM t_prep WHERE name = ?;');
    await stmt.execute([DbText('Alice')]);
    
    final res = await interpreter.executeScript('SELECT * FROM t_prep;');
    print('Result: ${res.rows}');
    print('SUCCESS');
  } catch (e) {
    print('ERROR: ${e.toString()}');
  }
  
  await db.close();
  try { dir.deleteSync(recursive: true); } catch (_) {}
}
