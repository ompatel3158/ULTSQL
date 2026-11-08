import 'dart:io';
import 'package:ultsql/src/engine/executor/interpreter.dart';

void main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: dart crash_writer.dart <dbPath> <ackPath>');
    exit(1);
  }

  final dbPath = args[0];
  final ackPath = args[1];
  final ackFile = File(ackPath);

  final db = Database(dbPath);
  await db.init();
  final interp = Interpreter(db);

  await interp.executeScript('''
    CREATE TABLE IF NOT EXISTS accounts (id INT PRIMARY KEY, balance INT, note TEXT);
  ''');

  int currentId = 1;
  final maxRes = await interp.executeScript('SELECT MAX(id) FROM accounts;');
  if (maxRes.rows.isNotEmpty && maxRes.rows.first.first.value != null) {
    currentId = (maxRes.rows.first.first.value as int) + 1;
  }

  int batchId = 0;
  if (ackFile.existsSync()) {
    batchId = ackFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).length;
  }

  while (true) {
    batchId++;
    final sb = StringBuffer('BEGIN TRANSACTION;\n');
    for (int i = 0; i < 20; i++) {
      final id = currentId++;
      final balance = 1000 + (id * 10);
      sb.writeln("INSERT INTO accounts VALUES ($id, $balance, 'Note for account $id');");
    }
    sb.writeln('COMMIT;');

    await interp.executeScript(sb.toString());

    // Record acknowledged committed batch count
    ackFile.writeAsStringSync('$batchId\n', mode: FileMode.append, flush: true);

    // Short sleep so writer stays alive across multiple batches
    await Future.delayed(const Duration(milliseconds: 15));
  }
}
