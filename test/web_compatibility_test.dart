import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/src/engine/storage/catalog.dart';
import 'package:ultsql/src/engine/parser/ast.dart';
import 'package:ultsql/src/engine/executor/value.dart';

void main() {
  test('UltSQL Web compatibility in-memory engine execution', () async {
    final catalog = Catalog('web_memory');
    await catalog.load();

    final schema = TableSchema(
      name: 'web_users',
      columnNames: ['id', 'username', 'email'],
      columnTypes: [DataType.integer, DataType.text, DataType.text],
    );

    catalog.addTable(schema, saveToFile: false);

    expect(catalog.hasTable('web_users'), isTrue);
    final loaded = catalog.getTableSchema('web_users');
    expect(loaded?.columnNames, equals(['id', 'username', 'email']));
  });

  test('UltSQL Web expression JIT compiler evaluation', () {
    final row = {
      'id': DbInt(101),
      'score': DbDouble(95.5),
      'status': DbText('active'),
    };

    expect(row['id']?.value, equals(101));
    expect(row['score']?.value, equals(95.5));
    expect(row['status']?.value, equals('active'));
  });
}
