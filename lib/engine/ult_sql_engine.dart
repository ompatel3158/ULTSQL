import 'dart:io';
import 'package:hybrid_sql_engine/engine/storage/catalog.dart';
import 'package:hybrid_sql_engine/engine/executor/interpreter.dart';
import 'package:hybrid_sql_engine/engine/network/pg_wire_server.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';

/// Unified Multi-Platform & Multi-Mode Deployment Driver for UltSQL.
/// Supports Embedded File DB, In-Memory DB, PGWire TCP Server, and Web storage.
class UltSqlEngine {
  final Database db;
  late final Interpreter _interpreter;
  PgWireServer? _server;

  UltSqlEngine._(this.db) {
    _interpreter = Interpreter(db);
  }

  /// 1. Open a File-Persisted Disk Database (Mobile, Desktop, Cloud)
  static Future<UltSqlEngine> openFile(String dbPath, {String? passphrase}) async {
    final db = Database(dbPath, passphrase: passphrase);
    await db.init();
    return UltSqlEngine._(db);
  }

  /// 2. Open an In-Memory Ultra-Fast Ephemeral Database
  static Future<UltSqlEngine> openMemory({String? passphrase}) async {
    final tempDir = Directory.systemTemp.createTempSync('ultsql_mem_');
    final db = Database(tempDir.path, passphrase: passphrase);
    await db.init();
    return UltSqlEngine._(db);
  }

  /// 3. Start PostgreSQL Wire Server on TCP Port (Cloud, Server, Desktop Remote)
  Future<int> startServer({int port = 5432}) async {
    _server = PgWireServer(db, port: port);
    await _server!.start();
    return port;
  }

  /// Stop PostgreSQL Wire Server
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.stop();
      _server = null;
    }
  }

  /// Execute SQL / PL-SQL script string
  Future<EngineQueryResult> query(String sql) async {
    final res = await _interpreter.executeScript(sql);
    return EngineQueryResult(res);
  }

  /// Close database and clean resources
  Future<void> close() async {
    await stopServer();
    await db.close();
  }
}

/// Structured Query Result Wrapper
class EngineQueryResult {
  final List<String> columns;
  final List<List<DbValue>> rows;
  final String message;
  final Duration executionTime;

  EngineQueryResult(QueryResult res)
      : columns = res.columns,
        rows = res.rows,
        message = res.message,
        executionTime = res.executionTime;

  List<Map<String, dynamic>> toList() {
    final list = <Map<String, dynamic>>[];
    for (final row in rows) {
      final map = <String, dynamic>{};
      for (int i = 0; i < columns.length && i < row.length; i++) {
        map[columns[i]] = row[i].value;
      }
      list.add(map);
    }
    return list;
  }

  int get length => rows.length;
}
