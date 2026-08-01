import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/executor/interpreter.dart';

void main() {
  const dbDir = 'test_data_time_series';

  setUp(() async {
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  });

  tearDown(() async {
    final dir = Directory(dbDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('Temporal Engine - time_bucket function', () async {
    final db = Database(dbDir);
    await db.init();
    final interpreter = Interpreter(db);
    
    final createRes = await interpreter.executeScript('''
      CREATE TABLE metrics (
        id INT,
        temperature DOUBLE,
        ts TEXT
      );
    ''');
    print('CREATE RES: \${createRes.message}');
      
    await interpreter.executeScript("INSERT INTO metrics VALUES (1, 22.5, '2023-01-01T10:02:00Z');");
    await interpreter.executeScript("INSERT INTO metrics VALUES (2, 23.0, '2023-01-01T10:04:00Z');");
    await interpreter.executeScript("INSERT INTO metrics VALUES (3, 21.5, '2023-01-01T10:06:00Z');");
    await interpreter.executeScript("INSERT INTO metrics VALUES (4, 21.0, '2023-01-01T10:09:00Z');");
    
    final res = await interpreter.executeScript('''
      SELECT time_bucket('5m', ts) as bucket, temperature 
      FROM metrics;
    ''');
    print('RES: ${res.toString()}');
    expect(res.rows.length, 4);
    
    // 10:02 and 10:04 should bucket to 10:00
    expect(res.rows[0][0].toString(), '2023-01-01T10:00:00.000Z');
    expect(res.rows[1][0].toString(), '2023-01-01T10:00:00.000Z');
    
    // 10:06 and 10:09 should bucket to 10:05
    expect(res.rows[2][0].toString(), '2023-01-01T10:05:00.000Z');
    expect(res.rows[3][0].toString(), '2023-01-01T10:05:00.000Z');
    
    await db.close();
  });
}
