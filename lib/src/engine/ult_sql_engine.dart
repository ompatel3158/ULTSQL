import 'package:ultsql/src/engine/executor/interpreter.dart';
import 'package:ultsql/src/engine/network/pg_wire_server.dart';
import 'package:ultsql/src/engine/executor/value.dart';

/// Unified Multi-Platform & Multi-Mode Deployment Driver for UltSQL.
/// Supports Embedded File DB, In-Memory DB, PGWire TCP Server, and Web storage.
class UltSqlEngine {
  /// The underlying [Database] instance.
  final Database db;
  late final Interpreter _interpreter;
  PgWireServer? _server;

  UltSqlEngine._(this.db) {
    _interpreter = Interpreter(db);
  }

  /// Open a file-persisted disk database on mobile, desktop, or server.
  static Future<UltSqlEngine> openFile(
    String dbPath, {
    String? passphrase,
  }) async {
    final db = Database(dbPath, passphrase: passphrase);
    await db.init();
    return UltSqlEngine._(db);
  }

  /// Open an in-memory high-speed ephemeral database.
  static Future<UltSqlEngine> openMemory({String? passphrase}) async {
    final db = Database(':memory:', passphrase: passphrase);
    await db.init();
    return UltSqlEngine._(db);
  }

  /// Start PostgreSQL Wire Protocol Server daemon on the specified TCP [port].
  Future<int> startServer({int port = 5432}) async {
    _server = PgWireServer(db, port: port);
    await _server!.start();
    return port;
  }

  /// Stop the active PostgreSQL Wire Protocol Server daemon.
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.stop();
      _server = null;
    }
  }

  /// Execute an SQL, PL/SQL, NoSQL, or Vector query script.
  Future<EngineQueryResult> query(String sql) async {
    final res = await _interpreter.executeScript(sql);
    return EngineQueryResult(res);
  }

  /// High-throughput structured batch insert through the public engine API.
  ///
  /// Ingests rows into [tableName] with automatic type coercion, slotted-page
  /// packing, B+ Tree index pointer generation, and catalog statistics synchronization.
  Future<EngineQueryResult> insertBatch(
    String tableName,
    List<List<dynamic>> rows, {
    List<String>? columns,
  }) async {
    final res = await _interpreter.insertBatch(
      tableName,
      rows,
      columnNames: columns,
    );
    return EngineQueryResult(res);
  }

  /// Synchronous high-throughput structured batch insert through the public engine API.
  EngineQueryResult insertBatchSync(
    String tableName,
    List<List<dynamic>> rows, {
    List<String>? columns,
  }) {
    final res = _interpreter.insertBatchSync(
      tableName,
      rows,
      columnNames: columns,
    );
    return EngineQueryResult(res);
  }

  /// High-throughput structured batch insert of record maps through the public engine API.
  Future<EngineQueryResult> insertBatchRecords(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    final res = await _interpreter.insertBatchRecords(tableName, records);
    return EngineQueryResult(res);
  }

  /// Synchronous high-throughput structured batch insert of record maps through the public engine API.
  EngineQueryResult insertBatchRecordsSync(
    String tableName,
    List<Map<String, dynamic>> records,
  ) {
    final res = _interpreter.insertBatchRecordsSync(tableName, records);
    return EngineQueryResult(res);
  }

  /// Close the database and release all underlying resources.
  Future<void> close() async {
    await stopServer();
    await db.close();
  }
}

/// Structured query result wrapper with helper methods.
class EngineQueryResult {
  /// Column names returned by the query.
  final List<String> columns;

  /// Row values returned by the query.
  final List<List<DbValue>> rows;

  /// Status or execution message.
  final String message;

  /// Total duration elapsed during execution.
  final Duration executionTime;

  /// Creates a new [EngineQueryResult] wrapping a raw [QueryResult].
  EngineQueryResult(QueryResult res)
    : columns = res.columns,
      rows = res.rows,
      message = res.message,
      executionTime = res.executionTime;

  /// Converts the result rows into a list of key-value maps.
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

  /// Number of rows in the result set.
  int get length => rows.length;
}
