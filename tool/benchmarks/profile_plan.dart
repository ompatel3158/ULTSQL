import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/parser/lexer.dart';
import 'package:ultsql/src/engine/parser/parser.dart';
import 'package:ultsql/src/engine/parser/ast.dart';

void main() async {
  final tempDir = Directory.systemTemp.createTempSync('prof_plan_');
  final db = Database('${tempDir.path}/db', useWal: true, maxCapacity: 100000);
  await db.init();
  final it = Interpreter(db);
  await it.executeScript('CREATE TABLE users (id INT PRIMARY KEY, name TEXT, age INT, score DOUBLE);');
  const sql = 'SELECT age, COUNT(*), AVG(score) FROM users GROUP BY age;';
  final tokens = Lexer(sql).tokenize();
  final ast = Parser(tokens).parseScript().first as SelectStmt;
  
  for (int i = 0; i < 5; i++) {
    final sw = Stopwatch()..start();
    final p = db.planner.planSelect(ast);
    sw.stop();
    print('Plan $i: ${sw.elapsedMicroseconds} us');
  }
  await db.close();
  tempDir.deleteSync(recursive: true);
}
