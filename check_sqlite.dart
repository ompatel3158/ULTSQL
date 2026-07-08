import 'package:sqlite3/sqlite3.dart';

void main() {
  print('Loading sqlite3...');
  try {
    final db = sqlite3.openInMemory();
    db.dispose();
    print('SUCCESS: SQLite loaded and executed in-memory successfully');
  } catch (e) {
    print('ERROR: ${e.toString()}');
  }
}
