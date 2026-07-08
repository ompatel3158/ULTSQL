import 'dart:io';
import 'dart:typed_data';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart' as hybrid;
import 'package:hybrid_sql_engine/engine/executor/value.dart';
import 'package:hybrid_sql_engine/engine/storage/btree_index.dart';

void main() async {
  final dbDir = 'test_debug_db';
  final dir = Directory(dbDir);
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
  dir.createSync(recursive: true);

  final db = hybrid.Database(dbDir, useWal: false);
  await db.init();
  final interpreter = hybrid.Interpreter(db);

  await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, age INT);');

  print('Inserting 10,000 rows...');
  await interpreter.executeScript('BEGIN TRANSACTION;');
  final insertStmt = db.prepare('INSERT INTO users VALUES (?, ?, ?);');
  for (int i = 1; i <= 10000; i++) {
    insertStmt.executeSync([DbInt(i), DbText('User_$i'), DbInt(25)]);
  }
  await interpreter.executeScript('COMMIT;');

  print('Creating index...');
  await interpreter.executeScript('CREATE INDEX idx_users_age ON users(age);');

  final indexFile = '$dbDir/idx_users_age.idx';
  
  final btree = BTreeIndex(cache: db.cache, indexPath: indexFile, keyColumns: 1);
  btree.initSync();

  final page0 = db.cache.pinPageSync(indexFile, 0);
  print('Page 0: type = ${page0.byteData.getUint8(0)}, isLeaf = ${page0.byteData.getUint8(1) == 1}, count = ${page0.byteData.getUint16(2)}, sibling = ${page0.byteData.getInt32(btree.siblingOffset)}');
  db.cache.unpinPageSync(indexFile, 0, isDirty: false);

  print('B-Tree Root Page ID: ${btree.rootPageId}');
  final countResults = btree.countRangeSync(null, null);
  final rangeResults = btree.searchRangeSync(null, null);
  print('B-Tree countRangeSync(null, null) = $countResults');
  print('B-Tree searchRangeSync(null, null) length = ${rangeResults.length}');

  await db.close();
  try {
    dir.deleteSync(recursive: true);
  } catch (_) {}
}
