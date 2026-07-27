import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/cache/page_cache.dart';
import 'package:hybrid_sql_engine/engine/storage/columnar_store.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';

void main() {
  group('Columnar Storage Engine', () {
    const dbDir = 'test_col_db';
    
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

    test('Should encode and decode plain columnar data', () {
      final dbName = 'test_col_plain';
      Directory(dbName).createSync();
      final cache = PageCache(dbDirectory: dbName, maxCapacity: 100);
      final store = CompressedColumnStore(cache: cache, tableName: 'test_col', dbDirectory: dbName);
      
      final values = [DbInt(10), DbInt(20), DbInt(30)];
      store.writeBatchSync(0, values);
      
      final readValues = store.readBatchSync(0, 0);
      expect(readValues.length, 3);
      expect(readValues[0].value, 10);
      expect(readValues[1].value, 20);
      expect(readValues[2].value, 30);
    });
    
    test('Should encode and decode RLE columnar data', () {
      final dbName = 'test_col_rle';
      Directory(dbName).createSync();
      final cache = PageCache(dbDirectory: dbName, maxCapacity: 100);
      final store = CompressedColumnStore(cache: cache, tableName: 'test_col', dbDirectory: dbName);
      
      final values = [DbInt(10), DbInt(10), DbInt(10), DbInt(20), DbInt(20)];
      store.writeBatchSync(0, values, useRle: true);
      
      final readValues = store.readBatchSync(0, 0);
      expect(readValues.length, 5);
      expect(readValues[0].value, 10);
      expect(readValues[2].value, 10);
      expect(readValues[3].value, 20);
      expect(readValues[4].value, 20);
    });

    test('Should encode and decode Dictionary columnar data', () {
      final dbName = 'test_col_dict';
      Directory(dbName).createSync();
      final cache = PageCache(dbDirectory: dbName, maxCapacity: 100);
      final store = CompressedColumnStore(cache: cache, tableName: 'test_col', dbDirectory: dbName);
      
      final values = [DbText('apple'), DbText('banana'), DbText('apple'), DbText('cherry')];
      store.writeBatchSync(0, values, useDict: true);
      
      final readValues = store.readBatchSync(0, 0);
      expect(readValues.length, 4);
      expect(readValues[0].value, 'apple');
      expect(readValues[1].value, 'banana');
      expect(readValues[2].value, 'apple');
      expect(readValues[3].value, 'cherry');
    });
  });
}
