import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:ultsql/engine/spatial/geometry.dart';
import 'package:ultsql/engine/spatial/rtree_index.dart';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'package:ultsql/engine/executor/value.dart';

void main() {
  group('Spatial Geometry Tests', () {
    test('Point2D Distance', () {
      final p1 = Point2D(0, 0);
      final p2 = Point2D(3, 4);
      expect(p1.distanceTo(p2), equals(5.0));
    });

    test('BoundingBox2D Contains & Intersects', () {
      final bbox1 = BoundingBox2D(0, 0, 10, 10);
      final bbox2 = BoundingBox2D(5, 5, 15, 15);
      final bbox3 = BoundingBox2D(20, 20, 30, 30);
      
      expect(bbox1.contains(Point2D(5, 5)), isTrue);
      expect(bbox1.contains(Point2D(15, 5)), isFalse);
      
      expect(bbox1.intersects(bbox2), isTrue);
      expect(bbox1.intersects(bbox3), isFalse);
      
      final expanded = bbox1.expandToInclude(bbox3);
      expect(expanded.minX, equals(0));
      expect(expanded.minY, equals(0));
      expect(expanded.maxX, equals(30));
      expect(expanded.maxY, equals(30));
    });

    test('Polygon2D Contains', () {
      final poly = Polygon2D([
        Point2D(0, 0),
        Point2D(0, 10),
        Point2D(10, 10),
        Point2D(10, 0),
        Point2D(0, 0)
      ]);
      
      expect(poly.contains(Point2D(5, 5)), isTrue);
      expect(poly.contains(Point2D(15, 5)), isFalse);
    });
  });

  group('RTree Index Tests', () {
    test('Insert and Search', () {
      final rtree = RTreeIndex<String>(maxChildren: 4);
      
      rtree.insert(BoundingBox2D(0, 0, 2, 2), "A");
      rtree.insert(BoundingBox2D(5, 5, 7, 7), "B");
      rtree.insert(BoundingBox2D(8, 8, 10, 10), "C");
      
      final results1 = rtree.search(BoundingBox2D(1, 1, 6, 6));
      expect(results1, containsAll(["A", "B"]));
      expect(results1, isNot(contains("C")));
      
      final results2 = rtree.search(BoundingBox2D(20, 20, 30, 30));
      expect(results2, isEmpty);
    });
  });

  group('GIS SQL Functions Tests', () {
    late Database db;

    setUp(() async {
      final dbDir = Directory('test_gis_db');
      if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);
      dbDir.createSync();
      db = Database('test_gis_db');
      await db.init();
    });

    tearDown(() async {
      await db.close();
      final dbDir = Directory('test_gis_db');
      if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);
    });

    test('ST_Point, ST_Distance, ST_Contains', () async {
      final script = '''
        CREATE TABLE locations (id INT, geom TEXT);
        INSERT INTO locations VALUES (1, ST_Point(0, 0));
        INSERT INTO locations VALUES (2, ST_Point(3, 4));
        INSERT INTO locations VALUES (3, ST_Point(10, 10));
      ''';
      
      final interp = Interpreter(db);
      await interp.executeScript(script);

      // Test ST_Distance
      final res1 = await interp.executeScript('''
        SELECT id, ST_Distance(geom, ST_Point(0, 0)) as dist FROM locations;
      ''');
      
      expect(res1.rows.length, 3);
      expect((res1.rows[0][1] as DbDouble).value, equals(0.0));
      expect((res1.rows[1][1] as DbDouble).value, equals(5.0));
      
      // Test ST_Contains
      final res2 = await interp.executeScript('''
        SELECT id FROM locations 
        WHERE ST_Contains('POLYGON((0 0, 0 5, 5 5, 5 0, 0 0))', geom) = 1;
      ''');
      
      expect(res2.rows.length, 2);
      expect((res2.rows[0][0] as DbInt).value, equals(1));
      expect((res2.rows[1][0] as DbInt).value, equals(2));
    });
  });
}
