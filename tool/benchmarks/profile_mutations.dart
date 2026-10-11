import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/parser/lexer.dart';
import 'package:ultsql/src/engine/parser/parser.dart';
import 'package:ultsql/src/engine/parser/ast.dart';

void main() async {
  final tempDir = Directory.systemTemp.createTempSync('profile_mut_');
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

  const sql = "UPDATE users SET name = 'Updated' WHERE age = 25;";

  // Parse
  final swParse = Stopwatch()..start();
  final tokens = Lexer(sql).tokenize();
  final stmt = Parser(tokens).parseScript().first as UpdateStmt;
  swParse.stop();
  print('Parse time: ${swParse.elapsedMicroseconds / 1000.0} ms');

  // Plan Index Range
  final swPlan = Stopwatch()..start();
  final range = db.planner.planIndexRange('users', stmt.whereCondition!);
  swPlan.stop();
  print('Plan index range: ${swPlan.elapsedMicroseconds / 1000.0} ms (range=$range)');

  // Search range
  final btree = db.getOrInitIndexSync(range!.indexSchema.name.toLowerCase());
  final swBtree = Stopwatch()..start();
  final ptrs = btree.searchRangeSync(range.low, range.high);
  swBtree.stop();
  print('Btree searchRange: ${swBtree.elapsedMicroseconds / 1000.0} ms (found ${ptrs.length} ptrs)');

  // Execute cold
  final swExec = Stopwatch()..start();
  await it.executeScript(sql);
  swExec.stop();
  print('Execute update cold: ${swExec.elapsedMicroseconds / 1000.0} ms');

  // Execute warm
  final swExecWarm = Stopwatch()..start();
  await it.executeScript(sql);
  swExecWarm.stop();
  print('Execute update warm: ${swExecWarm.elapsedMicroseconds / 1000.0} ms');

  // Delete
  final swDelete = Stopwatch()..start();
  await it.executeScript("DELETE FROM users WHERE age = 26;");
  swDelete.stop();
  print('Execute delete: ${swDelete.elapsedMicroseconds / 1000.0} ms');

  await db.close();
  tempDir.deleteSync(recursive: true);
}
