import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/parser/lexer.dart';
import 'package:ultsql/src/engine/parser/parser.dart';
import 'package:ultsql/src/engine/parser/ast.dart';
import 'package:ultsql/src/engine/executor/plan_nodes.dart';

void main() async {
  final tempDir = Directory.systemTemp.createTempSync('profile_rg_');
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

  const sql = 'SELECT COUNT(*), AVG(score) FROM users WHERE age >= 30 AND age <= 40;';
  
  // 1. Parsing time
  final swParse = Stopwatch()..start();
  for (int i = 0; i < 20; i++) {
    final tokens = Lexer(sql).tokenize();
    Parser(tokens).parseScript();
  }
  swParse.stop();
  print('Parse time: ${swParse.elapsedMicroseconds / 20000.0} ms');

  // 2. Planning time
  final tokens = Lexer(sql).tokenize();
  final stmt = Parser(tokens).parseScript().first as SelectStmt;
  final swPlan = Stopwatch()..start();
  for (int i = 0; i < 20; i++) {
    db.planner.planSelect(stmt);
  }
  swPlan.stop();
  print('Plan time: ${swPlan.elapsedMicroseconds / 20000.0} ms');

  // 3. Execution time of plan
  final plan = db.planner.planSelect(stmt);
  print('Plan string:\n${plan.getPlanString()}');

  // 3. Detailed breakdown
  final btree = db.getOrInitIndexSync('idx_age');
  final swBtree = Stopwatch()..start();
  for (int i = 0; i < 20; i++) {
    btree.searchRangePackedSync([30.0], [40.0]);
  }
  swBtree.stop();
  print('Btree searchRangePackedSync time: ${swBtree.elapsedMicroseconds / 20000.0} ms');

  final scanOnly = (plan as GroupByNode).child;
  final swScan = Stopwatch()..start();
  int count = 0;
  for (int i = 0; i < 20; i++) {
    scanOnly.open();
    while (scanOnly.next() != null) {
      count++;
    }
    scanOnly.close();
  }
  swScan.stop();
  print('Scan only time: ${swScan.elapsedMicroseconds / 20000.0} ms (rows: ${count / 20})');

  final swExec = Stopwatch()..start();
  for (int i = 0; i < 20; i++) {
    plan.open();
    while (plan.next() != null) {}
    plan.close();
  }
  swExec.stop();
  final swTotal = Stopwatch()..start();
  for (int i = 0; i < 20; i++) {
    await it.executeScript(sql);
  }
  swTotal.stop();
  print('Total range it.executeScript per query: ${swTotal.elapsedMicroseconds / 20000.0} ms');

  // GroupBy benchmark
  final swGroupBy = Stopwatch()..start();
  await it.executeScript('SELECT age, COUNT(*), AVG(score) FROM users GROUP BY age;');
  swGroupBy.stop();
  print('GROUP BY time: ${swGroupBy.elapsedMicroseconds / 1000.0} ms');

  // UPDATE benchmark
  final swUpdate = Stopwatch()..start();
  await it.executeScript("UPDATE users SET name = 'Updated' WHERE age = 25;");
  swUpdate.stop();
  print('UPDATE time: ${swUpdate.elapsedMicroseconds / 1000.0} ms');

  // DELETE benchmark
  final swDelete = Stopwatch()..start();
  await it.executeScript('DELETE FROM users WHERE age = 26;');
  swDelete.stop();
  print('DELETE time: ${swDelete.elapsedMicroseconds / 1000.0} ms');

  // DROP TABLE benchmark
  await it.executeScript('CREATE TABLE t_drop (id INT, name TEXT);');
  final swDrop = Stopwatch()..start();
  await it.executeScript('DROP TABLE t_drop;');
  swDrop.stop();
  print('DROP TABLE time: ${swDrop.elapsedMicroseconds / 1000.0} ms');

  await db.close();
  try {
    tempDir.deleteSync(recursive: true);
  } catch (_) {}
}
