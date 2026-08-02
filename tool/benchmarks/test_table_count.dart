import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';

void main() async {
  const dbDir = 'test_debug_db';
  final dir = Directory(dbDir);
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
  dir.createSync(recursive: true);

  final db = Database(dbDir);
  await db.init();
  final interpreter = Interpreter(db);
  
  await interpreter.executeScript('CREATE TABLE users (id INT, name TEXT, age INT);');
  
  print('Inserting 1,000,000 users...');
  final sw = Stopwatch()..start();
  final plsqlInsert = '''
DECLARE
  i INT := 0;
BEGIN
  BEGIN TRANSACTION;
  WHILE i < 1000000 LOOP
    i := i + 1;
    INSERT INTO users VALUES (i, 'User_' || i, 25);
  END LOOP;
  COMMIT;
END;
''';
  await interpreter.executeScript(plsqlInsert);
  sw.stop();
  print('1M inserts completed in ${sw.elapsedMilliseconds / 1000.0}s');
  
  print('Creating index idx_users_age...');
  await interpreter.executeScript('CREATE INDEX idx_users_age ON users(age);');
  
  // Check sizes
  final tableFile = File('$dbDir/users.db');
  final indexFile = File('$dbDir/idx_users_age.idx');
  
  print('users.db size: ${tableFile.existsSync() ? tableFile.lengthSync() : "not found"}');
  print('idx_users_age.idx size: ${indexFile.existsSync() ? indexFile.lengthSync() : "not found"}');
  
  // Count via table scan
  final swTable = Stopwatch()..start();
  final tableScanRes = await interpreter.executeScript('SELECT COUNT(*) FROM users;');
  swTable.stop();
  print('Table scan COUNT(*): ${tableScanRes.rows[0][0]} in ${swTable.elapsedMilliseconds}ms');
  
  // Count via index scan
  final swIndex = Stopwatch()..start();
  final indexScanRes = await interpreter.executeScript('SELECT COUNT(*) FROM users WHERE age = 25;');
  swIndex.stop();
  print('Index scan COUNT(*): ${indexScanRes.rows[0][0]} in ${swIndex.elapsedMilliseconds}ms');
  
  await db.close();
}
