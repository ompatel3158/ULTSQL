import 'dart:io';
import 'package:ultsql/engine/executor/interpreter.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._internal();
  LocalDatabaseService._internal();

  Database? _activeDb;
  Interpreter? _interpreter;
  String _activeDbName = 'main_local.db';
  String _dataDirectory = './ultsql_app_data';

  final Map<String, Database> _openedDatabases = {};
  final Map<String, Interpreter> _openedInterpreters = {};

  String get activeDatabaseName => _activeDbName;
  Database? get activeDatabase => _activeDb;
  Interpreter? get activeInterpreter => _interpreter;

  /// Set directory for local database files
  void setDataDirectory(String path) {
    _dataDirectory = path;
  }

  /// Initialize default database and local tables
  Future<Interpreter> init({String defaultDbName = 'main_local.db'}) async {
    _activeDbName = defaultDbName;
    return await switchDatabase(_activeDbName);
  }

  /// Switch active database file on the fly
  Future<Interpreter> switchDatabase(String dbName) async {
    if (_openedInterpreters.containsKey(dbName)) {
      _activeDbName = dbName;
      _activeDb = _openedDatabases[dbName];
      _interpreter = _openedInterpreters[dbName];
      return _interpreter!;
    }

    final dir = Directory(_dataDirectory);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final dbPath = dbName == ':memory:' ? ':memory:' : '${dir.path}/$dbName';

    final db = Database(dbPath);
    await db.init();
    final interpreter = Interpreter(db);

    _openedDatabases[dbName] = db;
    _openedInterpreters[dbName] = interpreter;

    _activeDbName = dbName;
    _activeDb = db;
    _interpreter = interpreter;

    // Auto-provision standard local tables
    await _ensureLocalTablesExist(interpreter);

    return interpreter;
  }

  /// Ensure all 4 standard local tables exist
  Future<void> _ensureLocalTablesExist(Interpreter interpreter) async {
    await interpreter.executeScript('''
      CREATE TABLE IF NOT EXISTS query_history (
        id INT PRIMARY KEY,
        query TEXT,
        executed_at TEXT,
        is_success INT,
        result TEXT,
        result_output TEXT,
        error TEXT,
        is_remote_query INT,
        remote_request_id TEXT,
        encrypted_query TEXT,
        sender_user_id TEXT,
        sender_display_name TEXT,
        is_encrypted INT,
        encrypted_at TEXT,
        is_read INT,
        execution_time_ms DOUBLE
      );

      CREATE TABLE IF NOT EXISTS user_tables (
        table_name TEXT PRIMARY KEY,
        created_at TEXT,
        schema TEXT
      );

      CREATE TABLE IF NOT EXISTS ai_chat_history (
        id INT PRIMARY KEY,
        message TEXT,
        response TEXT,
        timestamp TEXT
      );

      CREATE TABLE IF NOT EXISTS tasks (
        id INT PRIMARY KEY,
        title TEXT,
        description TEXT,
        points INT,
        type TEXT,
        is_completed INT,
        completed_at TEXT
      );
    ''');
  }

  /// Execute user SQL/PL-SQL query with precise Stopwatch performance timing (ms)
  Future<Map<String, dynamic>> executeQuery(String sqlScript) async {
    final interpreter = _interpreter ?? await switchDatabase(_activeDbName);
    final stopwatch = Stopwatch()..start();

    try {
      final result = await interpreter.executeScript(sqlScript);
      stopwatch.stop();

      final executionTimeMs = stopwatch.elapsedMicroseconds / 1000.0;

      // Extract formatted rows
      final List<String> columns = result.columns;
      final List<Map<String, dynamic>> formattedRows = [];

      for (final row in result.rows) {
        final Map<String, dynamic> rowMap = {};
        for (int i = 0; i < row.length; i++) {
          final colName = i < columns.length ? columns[i] : 'col_$i';
          rowMap[colName] = row[i].value;
        }
        formattedRows.add(rowMap);
      }

      // Log to query_history table
      final historyId = DateTime.now().millisecondsSinceEpoch;
      final timeStr = DateTime.now().toIso8601String();
      await interpreter.executeScript('''
        INSERT INTO query_history VALUES (
          $historyId,
          '${_escapeSql(sqlScript)}',
          '$timeStr',
          1,
          '${formattedRows.length} rows returned',
          '',
          '',
          0, '', '', '', '', 0, '', 1,
          $executionTimeMs
        );
      ''');

      return {
        'is_success': true,
        'execution_time_ms': executionTimeMs,
        'affected_rows': formattedRows.length,
        'columns': columns,
        'rows': formattedRows,
        'message': result.message,
      };
    } catch (e) {
      stopwatch.stop();
      final executionTimeMs = stopwatch.elapsedMicroseconds / 1000.0;
      final timeStr = DateTime.now().toIso8601String();

      // Log failure to query_history table
      final historyId = DateTime.now().millisecondsSinceEpoch;
      await interpreter.executeScript('''
        INSERT INTO query_history VALUES (
          $historyId,
          '${_escapeSql(sqlScript)}',
          '$timeStr',
          0,
          '',
          '',
          '${_escapeSql(e.toString())}',
          0, '', '', '', '', 0, '', 1,
          $executionTimeMs
        );
      ''');

      return {
        'is_success': false,
        'execution_time_ms': executionTimeMs,
        'affected_rows': 0,
        'columns': <String>[],
        'rows': <Map<String, dynamic>>[],
        'error': e.toString(),
      };
    }
  }

  /// Get list of all table names & schema details for ER Diagram Screen
  Future<List<Map<String, dynamic>>> getTablesAndSchemas() async {
    final db = _activeDb;
    if (db == null) return [];

    final List<Map<String, dynamic>> schemas = [];
    final tableNames = db.catalog.tables.keys;

    for (final tableName in tableNames) {
      final schema = db.catalog.getTableSchema(tableName);
      if (schema != null) {
        final primaryKeys = <String>[];
        final foreignKeys = <Map<String, String>>[];

        for (int i = 0; i < schema.columnNames.length; i++) {
          if (i < schema.columnPrimaryKey.length && schema.columnPrimaryKey[i]) {
            primaryKeys.add(schema.columnNames[i]);
          }
          if (i < schema.columnReferencesTable.length && schema.columnReferencesTable[i] != null) {
            foreignKeys.add({
              'column': schema.columnNames[i],
              'foreign_table': schema.columnReferencesTable[i]!,
              'foreign_column': schema.columnReferencesColumn[i] ?? 'id',
            });
          }
        }

        schemas.add({
          'table_name': schema.name,
          'columns': schema.columnNames,
          'types': schema.columnTypes.map((t) => t.name).toList(),
          'primary_key': primaryKeys.isNotEmpty ? primaryKeys.first : null,
          'foreign_keys': foreignKeys,
        });
      }
    }
    return schemas;
  }

  /// Save AI Chat History
  Future<void> saveAiChatMessage(String prompt, String response) async {
    final interpreter = _interpreter ?? await switchDatabase(_activeDbName);
    final id = DateTime.now().millisecondsSinceEpoch;
    final timeStr = DateTime.now().toIso8601String();

    await interpreter.executeScript('''
      INSERT INTO ai_chat_history VALUES (
        $id,
        '${_escapeSql(prompt)}',
        '${_escapeSql(response)}',
        '$timeStr'
      );
    ''');
  }

  /// Close active and all opened database instances
  Future<void> closeAll() async {
    for (final db in _openedDatabases.values) {
      await db.close();
    }
    _openedDatabases.clear();
    _openedInterpreters.clear();
    _activeDb = null;
    _interpreter = null;
  }

  String _escapeSql(String text) {
    return text.replaceAll("'", "''");
  }
}
