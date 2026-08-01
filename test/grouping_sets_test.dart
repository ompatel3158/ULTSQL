import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/storage/catalog.dart';
import 'dart:io';

void main() {
  group('Advanced Groupings Test', () {
    test('ROLLUP, CUBE, GROUPING SETS query execution', () async {
      final dbDir = 'test_grouping_db';
      final dir = Directory(dbDir);
      if (await dir.exists()) await dir.delete(recursive: true);
      
      final db = Database(dbDir);
      await db.init();
      final interpreter = Interpreter(db);

      await interpreter.executeScript('''
        CREATE TABLE sales (region text, product text, revenue int);
        INSERT INTO sales VALUES ('North', 'A', 100);
        INSERT INTO sales VALUES ('North', 'B', 200);
        INSERT INTO sales VALUES ('South', 'A', 150);
      ''');

      // Test GROUPING SETS
      final rsSets = await interpreter.executeScript('''
        SELECT region, product, SUM(revenue) 
        FROM sales 
        GROUP BY GROUPING SETS ((region, product), (region), ());
      ''');
      
      final rowsSets = rsSets.rows;
      expect(rowsSets.length, 6); // 3 (region,product) + 2 (region) + 1 ()
      
      // Test ROLLUP
      final rsRollup = await interpreter.executeScript('''
        SELECT region, product, SUM(revenue) 
        FROM sales 
        GROUP BY ROLLUP (region, product);
      ''');
      
      expect(rsRollup.rows.length, 6);
      
      // Test CUBE
      final rsCube = await interpreter.executeScript('''
        SELECT region, product, SUM(revenue) 
        FROM sales 
        GROUP BY CUBE (region, product);
      ''');
      
      // CUBE(region, product) -> (region, product), (region), (product), ()
      // (region,product): 3
      // (region): 2
      // (product): 2
      // (): 1
      expect(rsCube.rows.length, 8);
    });
  });
}
