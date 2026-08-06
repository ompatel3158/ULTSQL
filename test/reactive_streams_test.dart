import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/storage/catalog.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void main() {
  test('Reactive Query Streams test (db.watch)', () async {
    final tempDir = await Directory.systemTemp.createTemp('ultsql_watch_test_');
    final db = Database(tempDir.path);
    final interpreter = Interpreter(db);

    try {
      await interpreter.executeScript("CREATE TABLE live_users (id INT PRIMARY KEY, name TEXT)");
      
      final stream = db.watch(interpreter, "SELECT * FROM live_users");
      final results = <QueryResult>[];
      
      final sub = stream.listen((res) {
        results.add(res);
      });

      // Give initial query time to emit
      await Future.delayed(const Duration(milliseconds: 100));
      expect(results.length, 1);
      expect(results[0].rows.length, 0);

      // Perform INSERT mutation
      await interpreter.executeScript("INSERT INTO live_users VALUES (1, 'Alice')");
      await Future.delayed(const Duration(milliseconds: 100));
      expect(results.length, 2);
      expect(results[1].rows.length, 1);
      expect(results[1].rows[0][1], DbText('Alice'));

      // Perform UPDATE mutation
      await interpreter.executeScript("UPDATE live_users SET name = 'Alice Updated' WHERE id = 1");
      await Future.delayed(const Duration(milliseconds: 100));
      expect(results.length, 3);
      expect(results[2].rows[0][1], DbText('Alice Updated'));

      // Perform DELETE mutation
      await interpreter.executeScript("DELETE FROM live_users WHERE id = 1");
      await Future.delayed(const Duration(milliseconds: 100));
      expect(results.length, 4);
      expect(results[3].rows.length, 0);

      await sub.cancel();
      print("REACTIVE QUERY STREAMS (db.watch) TEST PASSED CLEANLY!");
    } finally {
      db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}
