import 'dart:io';
import 'dart:typed_data';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/storage/table_file.dart';

void main() async {
  final tempDir = Directory.systemTemp.createTempSync('prof_ins_');
  final db = Database('${tempDir.path}/db', useWal: true, maxCapacity: 100000);
  await db.init();
  final it = Interpreter(db);
  await it.executeScript('CREATE TABLE users (id INT PRIMARY KEY, name TEXT, age INT, score DOUBLE);');

  final n = 10000;
  final batchRows = List<List<DbValue>>.generate(n, (j) {
    final i = j + 1;
    return [DbInt(i), DbText('User_$i'), DbInt(18 + (i % 62)), DbDouble((i % 1000) / 10.0)];
  });

  final ultIns = db.prepare('INSERT INTO users VALUES (?, ?, ?, ?);');
  final insertStmt = (ultIns as dynamic).statement;
  print('insertStmt values: ${insertStmt.values.map((e) => '${e.runtimeType}(${e.index})').toList()}');

  final swTotal = Stopwatch()..start();
  ultIns.executeBatchSync(batchRows);
  swTotal.stop();
  print('executeBatchSync (Run 1 cold) took: ${swTotal.elapsedMicroseconds} us (${swTotal.elapsedMilliseconds} ms) -> ${(n / (swTotal.elapsedMicroseconds / 1e6)).toStringAsFixed(0)} rows/s');

  await it.executeScript('CREATE TABLE users2 (id INT PRIMARY KEY, name TEXT, age INT, score DOUBLE);');
  final ultIns2 = db.prepare('INSERT INTO users2 VALUES (?, ?, ?, ?);');
  final swWarm = Stopwatch()..start();
  ultIns2.executeBatchSync(batchRows);
  swWarm.stop();
  print('executeBatchSync (Run 2 warm) took: ${swWarm.elapsedMicroseconds} us (${swWarm.elapsedMilliseconds} ms) -> ${(n / (swWarm.elapsedMicroseconds / 1e6)).toStringAsFixed(0)} rows/s');

  await db.close();
  try { tempDir.deleteSync(recursive: true); } catch (_) {}
}
