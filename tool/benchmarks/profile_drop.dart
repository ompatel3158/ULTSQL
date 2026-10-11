import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void main() async {
  final d = Directory.systemTemp.createTempSync('drop_prof_');
  final ultDb = Database('${d.path}/db', useWal: true, maxCapacity: 100000);
  ultDb.config.enableAuditLogging = false;
  ultDb.auditLogger.enabled = false;
  await ultDb.init();
  final it = Interpreter(ultDb);

  await it.executeScript('CREATE TABLE users (id INT PRIMARY KEY, name TEXT, age INT, score DOUBLE);');
  final ultIns = ultDb.prepare('INSERT INTO users VALUES (?, ?, ?, ?);');
  final rows = List<List<DbValue>>.generate(10000, (j) {
    final i = j + 1;
    return [DbInt(i), DbText('User_$i'), DbInt(18 + (i % 62)), DbDouble((i % 1000) / 10.0)];
  });
  ultIns.executeBatchSync(rows);
  await it.executeScript('CREATE INDEX idx_age ON users(age);');

  final sw = Stopwatch()..start();
  final res = await it.executeScript('DROP TABLE users;');
  sw.stop();
  print('DROP TABLE outer: ${sw.elapsedMicroseconds} us, inner executionTime: ${res.executionTime?.inMicroseconds} us');

  await it.executeScript('CREATE TABLE dummy (id INT PRIMARY KEY);');
  final sw2 = Stopwatch()..start();
  final res2 = await it.executeScript('DROP TABLE dummy;');
  sw2.stop();
  print('Second DROP TABLE outer: ${sw2.elapsedMicroseconds} us, inner executionTime: ${res2.executionTime?.inMicroseconds} us');


  await ultDb.close();
  try { d.deleteSync(recursive: true); } catch (_) {}
}
