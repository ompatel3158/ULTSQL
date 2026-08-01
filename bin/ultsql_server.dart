import 'dart:io';
import 'package:ultsql/engine/executor/interpreter.dart';
import 'package:ultsql/engine/network/pg_wire_server.dart';

void main(List<String> args) async {
  int port = 5432;
  String host = '0.0.0.0';
  String dataDir = './ultsql_data';
  String defaultDbName = 'main.db';

  for (int i = 0; i < args.length; i++) {
    final arg = args[i];
    if ((arg == '--port' || arg == '-p') && i + 1 < args.length) {
      port = int.tryParse(args[i + 1]) ?? 5432;
    } else if ((arg == '--host' || arg == '-h') && i + 1 < args.length) {
      host = args[i + 1];
    } else if ((arg == '--data-dir' || arg == '-d') && i + 1 < args.length) {
      dataDir = args[i + 1];
    } else if (arg == '--help') {
      _printHelp();
      exit(0);
    }
  }

  final dir = Directory(dataDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  print('===============================================================');
  print('🚀 UltSQL Server Daemon v1.0.0');
  print('   Converged Database Engine (SQL + NoSQL + Vector RAG + PL/SQL)');
  print('===============================================================');
  print('📁 Data Directory : ${dir.absolute.path}');
  print('🌐 Host Address   : $host');
  print('🔌 Protocol Port   : $port (PostgreSQL Wire Protocol v3)');

  final dbPath = '$dataDir/$defaultDbName';
  final db = Database(dbPath);
  await db.init();

  final pgServer = PgWireServer(
    db,
    port: port,
    address: host,
  );

  await pgServer.start();
  print('✅ UltSQL Server Daemon is RUNNING & ready for connections!');
  print('👉 Connect using psql, DBeaver, DataGrip, or UltSQL Client App.');
  print('   Example: psql -h 127.0.0.1 -p $port -U postgres');
  print('Press Ctrl+C to stop server.\n');

  ProcessSignal.sigint.watch().listen((_) async {
    print('\n🛑 Shutting down UltSQL Server Daemon...');
    await pgServer.stop();
    await db.close();
    print('👋 Server stopped cleanly. Goodbye!');
    exit(0);
  });
}

void _printHelp() {
  print('''
UltSQL Server Daemon Command Line Options:
  -p, --port <number>     TCP Port to listen on (Default: 5432)
  -h, --host <address>    Host interface binding (Default: 0.0.0.0)
  -d, --data-dir <path>   Directory path to store database files (Default: ./ultsql_data)
  --help                  Show this help message
''');
}
