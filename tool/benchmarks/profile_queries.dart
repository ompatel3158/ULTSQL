import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

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

  // 1. CREATE INDEX
  final swIdx = Stopwatch()..start();
  await it.executeScript('CREATE INDEX idx_age ON users(age);');
  swIdx.stop();
  print('CREATE INDEX: ${swIdx.elapsedMicroseconds / 1000.0} ms');

  // 2. Point lookup
  final pt = db.prepare('SELECT * FROM users WHERE id = ?;');
  final randIds = [1, 50, 100, 500, 1000, 5000, 9999];
  final swPoint = Stopwatch()..start();
  for (int i = 0; i < 10000; i++) {
    pt.executeSync([DbInt(randIds[i % randIds.length])]);
  }
  swPoint.stop();
  print('Point lookup (10K): ${swPoint.elapsedMicroseconds / 10000.0} us/query');

  // 3. Range aggregate
  const rangeSql = 'SELECT COUNT(*), AVG(score) FROM users WHERE age >= 30 AND age <= 40;';
  final swParseR = Stopwatch()..start();
  final rangeStmt = db.prepare(rangeSql);
  swParseR.stop();
  print('Range prepare time: ${swParseR.elapsedMicroseconds / 1000.0} ms');

  final swExec1 = Stopwatch()..start();
  await it.executeScript(rangeSql);
  swExec1.stop();
  print('Range executeScript cold: ${swExec1.elapsedMicroseconds / 1000.0} ms');

  final swRange = Stopwatch()..start();
  for (int i = 0; i < 20; i++) {
    await it.executeScript(rangeSql);
  }
  swRange.stop();
  print('Range aggregate: ${swRange.elapsedMicroseconds / 20000.0} ms/query');

  // 4. GROUP BY cold
  final swGbCold = Stopwatch()..start();
  await it.executeScript('SELECT age, COUNT(*), AVG(score) FROM users GROUP BY age;');
  swGbCold.stop();
  print('GROUP BY cold: ${swGbCold.elapsedMicroseconds / 1000.0} ms');

  // GROUP BY warm
  final swGbWarm = Stopwatch()..start();
  await it.executeScript('SELECT age, COUNT(*), AVG(score) FROM users GROUP BY age;');
  swGbWarm.stop();
  print('GROUP BY warm: ${swGbWarm.elapsedMicroseconds / 1000.0} ms');

  // 5. UPDATE
  final swUpdCold = Stopwatch()..start();
  await it.executeScript("UPDATE users SET name = 'Updated' WHERE age = 25;");
  swUpdCold.stop();
  print('UPDATE cold: ${swUpdCold.elapsedMicroseconds / 1000.0} ms');

  final swUpdWarm = Stopwatch()..start();
  await it.executeScript("UPDATE users SET name = 'Updated' WHERE age = 25;");
  swUpdWarm.stop();
  print('UPDATE warm: ${swUpdWarm.elapsedMicroseconds / 1000.0} ms');

  // 6. DELETE
  final swDel = Stopwatch()..start();
  await it.executeScript("DELETE FROM users WHERE age = 26;");
  swDel.stop();
  print('DELETE: ${swDel.elapsedMicroseconds / 1000.0} ms');

  // 7. DROP TABLE
  await it.executeScript('CREATE TABLE t_drop (id INT, name TEXT);');
  final swDrop = Stopwatch()..start();
  await it.executeScript('DROP TABLE t_drop;');
  swDrop.stop();
  print('DROP TABLE: ${swDrop.elapsedMicroseconds / 1000.0} ms');

  await it.executeScript('CREATE TABLE t_drop2 (id INT, name TEXT);');
  final swDrop2 = Stopwatch()..start();
  await it.executeScript('DROP TABLE t_drop2;');
  swDrop2.stop();
  print('DROP TABLE 2: ${swDrop2.elapsedMicroseconds / 1000.0} ms');

  await db.close();
  tempDir.deleteSync(recursive: true);
}
