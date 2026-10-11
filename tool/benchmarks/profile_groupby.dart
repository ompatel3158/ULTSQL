import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/parser/lexer.dart';
import 'package:ultsql/src/engine/parser/parser.dart';
import 'package:ultsql/src/engine/parser/ast.dart';

void main() async {
  final tempDir = Directory.systemTemp.createTempSync('profile_gb_');
  final db = Database('${tempDir.path}/db', useWal: true, maxCapacity: 100000);
  await db.init();
  final it = Interpreter(db);
  await it.executeScript('CREATE TABLE users (id INT PRIMARY KEY, name TEXT, age INT, score DOUBLE);');

  final n = 10000;
  final batchRows = List<List<DbValue>>.generate(n, (j) {
    final i = j + 1;
    return [DbInt(i), DbText('User_$i'), DbInt(18 + (i % 62)), DbDouble((i % 1000) / 10.0)];
  });

  final ins = db.prepare('INSERT INTO users VALUES (?, ?, ?, ?);');
  ins.executeBatchSync(batchRows);
  await it.executeScript('CREATE INDEX idx_age ON users(age);');

  const sql = 'SELECT age, COUNT(*), AVG(score) FROM users GROUP BY age;';
  
  final swLex = Stopwatch()..start();
  final tokens = Lexer(sql).tokenize();
  swLex.stop();
  final swParse = Stopwatch()..start();
  final ast = Parser(tokens).parseScript();
  swParse.stop();
  final swPlan = Stopwatch()..start();
  final plan = db.planner.planSelect(ast.first as SelectStmt);
  swPlan.stop();
  final swExec = Stopwatch()..start();
  plan.open();
  while (plan.next() != null) {}
  plan.close();
  swExec.stop();
  print('Lexer: ${swLex.elapsedMicroseconds / 1000.0} ms, Parser: ${swParse.elapsedMicroseconds / 1000.0} ms, Planner: ${swPlan.elapsedMicroseconds / 1000.0} ms, Exec: ${swExec.elapsedMicroseconds / 1000.0} ms');

  for (int i = 0; i < 6; i++) {
    final sw = Stopwatch()..start();
    await it.executeScript(sql);
    sw.stop();
    print('Run $i: ${sw.elapsedMicroseconds / 1000.0} ms');
  }

  await db.close();
  tempDir.deleteSync(recursive: true);
}
