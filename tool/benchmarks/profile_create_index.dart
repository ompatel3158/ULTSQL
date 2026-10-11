import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';
import 'package:ultsql/src/engine/storage/table_file.dart';

void main() async {
  final tempDir = Directory.systemTemp.createTempSync('prof_idx_');
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

  final rowTable = RowTableFile(cache: db.cache, tableName: 'users', dbDirectory: db.directory);
  final page0 = db.cache.pinPageSync(rowTable.filePath, 0);
  final bd0 = page0.byteData;
  final rCount0 = bd0.getUint16(1);
  final recOff0 = bd0.getUint16(5);
  final recLen0 = bd0.getUint16(7);
  final countAt12 = bd0.getUint16(recOff0 + 12);
  print('page 0: rowCount=$rCount0, recOff0=$recOff0, recLen0=$recLen0, countAt12=$countAt12, schemaLen=${db.catalog.getTableSchema("users")!.columnNames.length}');


  for (int k = 1; k <= 20; k++) {
    final sw = Stopwatch()..start();
    await it.executeScript('CREATE INDEX idx_age_$k ON users(age);');
    sw.stop();
    print('CREATE INDEX $k: ${sw.elapsedMicroseconds / 1000.0} ms');
  }

  final swRange1 = Stopwatch()..start();
  for (int i = 0; i < 20; i++) {
    await it.executeScript('SELECT COUNT(*), AVG(score) FROM users WHERE age >= 30 AND age <= 40;');
  }
  swRange1.stop();
  print('Range Aggregate (cold 20x avg): ${(swRange1.elapsedMicroseconds / 20.0) / 1000.0} ms');

  final btreeAge = db.getOrInitIndexSync('idx_age_1');
  for (int i = 0; i < 100; i++) {
    btreeAge.searchRangePackedSync([30.0], [40.0]);
  }
  final swBtree = Stopwatch()..start();
  for (int i = 0; i < 100; i++) {
    btreeAge.searchRangePackedSync([30.0], [40.0]);
  }
  swBtree.stop();
  print('Just searchRangePackedSync (warm 100x avg): ${(swBtree.elapsedMicroseconds / 100.0) / 1000.0} ms (matches: ${btreeAge.searchRangePackedSync([30.0], [40.0]).length})');

  for (int i = 0; i < 100; i++) {
    await it.executeScript('SELECT COUNT(*), AVG(score) FROM users WHERE age >= 30 AND age <= 40;');
  }
  final swRange2 = Stopwatch()..start();
  for (int i = 0; i < 100; i++) {
    await it.executeScript('SELECT COUNT(*), AVG(score) FROM users WHERE age >= 30 AND age <= 40;');
  }
  swRange2.stop();
  print('Range Aggregate (warm 100x avg): ${(swRange2.elapsedMicroseconds / 100.0) / 1000.0} ms');

  await db.close();
  tempDir.deleteSync(recursive: true);
}
