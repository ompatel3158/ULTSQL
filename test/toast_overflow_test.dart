import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/cache/page_cache.dart';
import 'package:ultsql/engine/storage/table_file.dart';
import 'package:ultsql/engine/executor/value.dart';

void main() {
  group('TOAST Overflow Engine', () {
    const dbDir = 'test_toast_db';
    
    setUp(() {
      try {
        final dir = Directory(dbDir);
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } catch (_) {}
      try {
        Directory(dbDir).createSync();
      } catch (_) {}
    });
    
    tearDown(() {
      try {
        final dir = Directory(dbDir);
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('Should TOAST and read large strings > 1024 bytes', () {
      final dbName = 'test_toast_1';
      Directory(dbName).createSync();
      final cache = PageCache(dbDirectory: dbName, maxCapacity: 100);
      final table = RowTableFile(cache: cache, tableName: 'test_toast', dbDirectory: dbName);
      
      String largeString = List.generate(5000, (index) => 'A').join();
      
      table.insertSync([DbInt(1), DbText(largeString)]);
      table.flushActivePageSync();
      
      final cursor = table.scanSync();
      expect(cursor.moveNext(), true);
      final row = cursor.current;
      expect(row[0].value, 1);
      expect(row[1].value, largeString);
      expect(cursor.moveNext(), false);
    });
    
    test('Should TOAST and read large JSON > 1024 bytes', () {
      final dbName = 'test_toast_2';
      Directory(dbName).createSync();
      final cache = PageCache(dbDirectory: dbName, maxCapacity: 100);
      final table = RowTableFile(cache: cache, tableName: 'test_toast_json', dbDirectory: dbName);
      
      Map<String, dynamic> largeJson = {
        'data': List.generate(1000, (index) => index),
      };
      
      table.insertSync([DbInt(2), DbJson(largeJson)]);
      table.flushActivePageSync();
      
      final cursor = table.scanSync();
      expect(cursor.moveNext(), true);
      final row = cursor.current;
      expect(row[0].value, 2);
      
      final rowJson = row[1] as DbJson;
      expect((rowJson.value['data'] as List).length, 1000);
    });
  });
}
