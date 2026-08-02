import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/storage/catalog.dart';
import 'dart:io';

void main() {
  group('Foreign Data Wrapper Test', () {
    test('CREATE FOREIGN TABLE and querying CSV', () async {
      final dbDir = 'test_fdw_db';
      final dir = Directory(dbDir);
      if (await dir.exists()) await dir.delete(recursive: true);
      
      final db = Database(dbDir);
      await db.init();
      final interpreter = Interpreter(db);
      
      // Create a test CSV file
      final csvFile = File('${dbDir}/data.csv');
      await csvFile.create(recursive: true);
      await csvFile.writeAsString("id,name,score\n1,Alice,95.5\n2,Bob,82.0\n3,Charlie,90.0");

      await interpreter.executeScript('''
        CREATE FOREIGN TABLE ext_users (id int, name text, score double)
        SERVER csv
        OPTIONS (filename '${dbDir}/data.csv');
      ''');
      
      final res = await interpreter.executeScript('SELECT * FROM ext_users;');
      print('RES COLUMNS: ${res.columns}');
      print('RES ROWS LEN: ${res.rows.length}');
      print('RES MESSAGE: ${res.message}');
      expect(res.rows.length, 3);
      expect(res.rows[0][0].toString(), '1');
      expect(res.rows[0][1].toString(), 'Alice');
      expect(res.rows[1][2].toString(), '82.0');
    });
  });
}
