import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/parser/lexer.dart';
import 'package:ultsql/src/engine/parser/parser.dart';
import 'package:ultsql/src/engine/storage/table_file.dart';

void main() async {
  final tempDir = Directory.systemTemp.createTempSync('prof_range_');
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
  
  // Cold run
  var sw = Stopwatch()..start();
  final res1 = await it.executeScript(sql);
  sw.stop();
  print('Run 1 (cold): ${sw.elapsedMicroseconds} us (${sw.elapsedMilliseconds} ms) -> res: ${res1.rows}');

  // Warm runs
  sw = Stopwatch()..start();
  for (int i = 0; i < 20; i++) {
    await it.executeScript(sql);
  }
  sw.stop();
  print('Warm 20 runs avg: ${sw.elapsedMicroseconds / 20.0} us (${sw.elapsedMicroseconds / 20000.0} ms/query)');

  final btree = db.getOrInitIndexSync('idx_age');
  final rowTable = RowTableFile(cache: db.cache, tableName: 'users', dbDirectory: db.directory);

  final swBtree = Stopwatch()..start();
  for (int i = 0; i < 20; i++) {
    btree.searchRangePackedSync([30.0], [40.0]);
  }
  swBtree.stop();
  print('searchRangePackedSync 20 runs avg: ${swBtree.elapsedMicroseconds / 20.0} us');


  await db.close();
  tempDir.deleteSync(recursive: true);
}
