import 'dart:async';
import 'dart:isolate';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../parser/token.dart';
import '../parser/lexer.dart';
import '../parser/ast.dart';
import '../parser/parser.dart';
import '../cache/page_cache.dart';
import '../storage/catalog.dart';
import '../storage/table_file.dart';
import '../storage/btree_index.dart';
import '../storage/hnsw_index.dart';
import 'value.dart';
import 'plan_nodes.dart';
import 'planner.dart';
import 'jit_compiler.dart';
import 'parallel_scan_nodes.dart';

class QueryResult {
  final List<String> columns;
  final List<List<DbValue>> rows;
  final String message;
  final Duration executionTime;
  final List<String> dbmsOutputLog;

  QueryResult({
    required this.columns,
    required this.rows,
    this.message = '',
    this.executionTime = Duration.zero,
    this.dbmsOutputLog = const [],
  });

  @override
  String toString() {
    if (rows.isEmpty) return message;
    final buffer = StringBuffer();
    buffer.writeln(columns.join(' | '));
    buffer.writeln('-' * (columns.length * 12));
    for (final row in rows) {
      buffer.writeln(row.map((v) => v.toString()).join(' | '));
    }
    return buffer.toString();
  }
}

class Database {
  final String directory;
  late final Catalog catalog;
  late final PageCache cache;
  late final QueryPlanner planner;
  final Map<String, BTreeIndex> _indexCache = {};

  Database(this.directory, {String? passphrase, bool useWal = true, int maxCapacity = 1000}) {
    catalog = Catalog(directory);
    cache = PageCache(maxCapacity: maxCapacity, dbDirectory: directory, useWal: useWal); // Configurable cache limit
    if (passphrase != null) {
      cache.encryptionKey = Uint8List.fromList(utf8.encode(passphrase));
    }
    planner = QueryPlanner(catalog: catalog, cache: cache, dbDirectory: directory);
  }

  Future<void> init() async {
    await catalog.load();
    cache.recoverSync(catalog);
  }

  BTreeIndex getOrInitIndexSync(String nameOrIndexName) {
    final name = nameOrIndexName.toLowerCase();
    if (_indexCache.containsKey(name)) {
      return _indexCache[name]!;
    }

    int columnsCount = 1;
    String finalIndexName = name;

    final idxSchema = catalog.getIndex(name);
    if (idxSchema != null) {
      columnsCount = idxSchema.columnName.split(',').length;
    } else {
      final primaryIdxSchema = catalog.getIndex('idx_${name}_id');
      if (primaryIdxSchema != null) {
        finalIndexName = 'idx_${name}_id';
        columnsCount = primaryIdxSchema.columnName.split(',').length;
      }
    }

    final indexFile = '$directory/$finalIndexName.idx';
    final btree = BTreeIndex(cache: cache, indexPath: indexFile, keyColumns: columnsCount);
    btree.initSync();
    _indexCache[name] = btree;
    _indexCache[finalIndexName] = btree;
    return btree;
  }

  Future<void> close() async {
    _indexCache.clear();
    cache.closeAllSync();
  }

  PreparedStatement prepare(String sql) {
    final lexer = Lexer(sql);
    final tokens = lexer.tokenize();
    final errors = tokens.where((t) => t.type == TokenType.invalid).toList();
    if (errors.isNotEmpty) {
      throw Exception("Lexer error: ${errors.first.lexeme} at Line ${errors.first.line}:${errors.first.column}");
    }
    final parser = Parser(tokens);
    final statements = parser.parseScript();
    if (statements.isEmpty) {
      throw Exception("No statement found to prepare.");
    }
    return PreparedStatement(this, statements.first);
  }
}

class PreparedStatement {
  final Database db;
  final ASTNode statement;
  late final Interpreter _interpreter;

  PreparedStatement(this.db, this.statement) {
    _interpreter = Interpreter(db);
  }

  Future<QueryResult> execute(List<DbValue> params) async {
    JitCompiler.currentParams = params;
    var res = (statement is InsertStmt)
        ? _interpreter._executeInsert(statement as InsertStmt)
        : _interpreter._executeNodeSync(statement);
    if (res is Future) {
      res = await res;
    }
    if (!_interpreter.db.cache.isTransactionActive) {
      _interpreter._flushActiveTablePages();
    }
    JitCompiler.currentParams = null;
    if (res is QueryResult) {
      return res;
    }
    return QueryResult(columns: [], rows: [], message: res.toString());
  }

  QueryResult executeSync(List<DbValue> params) {
    JitCompiler.currentParams = params;
    final res = (statement is InsertStmt)
        ? _interpreter._executeInsert(statement as InsertStmt)
        : _interpreter._executeNodeSync(statement);
    if (res is Future) {
      throw Exception("Asynchronous operation encountered in executeSync.");
    }
    if (!_interpreter.db.cache.isTransactionActive) {
      _interpreter._flushActiveTablePages();
    }
    JitCompiler.currentParams = null;
    if (res is QueryResult) {
      return res;
    }
    return QueryResult(columns: [], rows: [], message: res.toString());
  }

  QueryResult executeBatchSync(List<List<DbValue>> batchParams) {
    if (statement is! InsertStmt) {
      throw Exception("Batch execution is only supported for INSERT statements.");
    }
    final insertStmt = statement as InsertStmt;
    final tableName = insertStmt.tableName.toLowerCase();
    final schema = db.catalog.getTableSchema(tableName);
    if (schema == null) {
      throw Exception("Table '$tableName' does not exist.");
    }

    if (schema.isColumnar) {
      throw Exception("Batch insert is not supported on columnar tables.");
    }

    // Check if we can use a fast path: all values are simple placeholders in order (e.g. ?, ?, ?)
    bool isSimplePlaceholders = true;
    for (int i = 0; i < insertStmt.values.length; i++) {
      final expr = insertStmt.values[i];
      if (expr is! PlaceholderExpr || expr.index != i) {
        isSimplePlaceholders = false;
        break;
      }
    }

    final rowTable = _interpreter._rowTableCache.putIfAbsent(tableName, () => RowTableFile(
      cache: db.cache,
      tableName: schema.name,
      dbDirectory: db.directory,
    ));

    final currentTxId = db.cache.currentMvccTx?.txId ?? 0;
    
    // Evaluate row values for all parameter rows
    final List<List<DbValue>> rowsValues;
    if (isSimplePlaceholders) {
      final colTypes = schema.columnTypes;
      final numCols = colTypes.length;
      for (int r = 0; r < batchParams.length; r++) {
        final params = batchParams[r];
        for (int i = 0; i < numCols; i++) {
          final val = params[i];
          final expectedType = colTypes[i];
          if (val is! DbNull && val.type != expectedType) {
            if (expectedType == DataType.double && val is DbInt) {
              params[i] = DbDouble(val.value.toDouble());
            } else if (expectedType == DataType.json && val is DbText) {
              try {
                params[i] = DbJson(json.decode(val.value));
              } catch (_) {}
            } else if (expectedType == DataType.vector && val is DbText) {
              final vec = _parseVectorFromString(val.value);
              if (vec != null) params[i] = vec;
            }
          }
        }
      }
      rowsValues = batchParams;
    } else {
      rowsValues = <List<DbValue>>[];
      // Pre-compile JIT value expressions
      final valueJits = insertStmt.values.map((expr) => JitCompiler.compile(expr)).toList();
      for (int r = 0; r < batchParams.length; r++) {
        final params = batchParams[r];
        JitCompiler.currentParams = params;
        
        final rowValues = <DbValue>[];
        for (int i = 0; i < valueJits.length; i++) {
          final val = valueJits[i](_interpreter._env);
          final expectedType = schema.columnTypes[i];
          DbValue coercedVal = val;
          if (coercedVal is! DbNull && coercedVal.type != expectedType) {
            if (expectedType == DataType.double && coercedVal is DbInt) {
              coercedVal = DbDouble(coercedVal.value.toDouble());
            } else if (expectedType == DataType.json && coercedVal is DbText) {
              try {
                coercedVal = DbJson(json.decode(coercedVal.value));
              } catch (_) {}
            } else if (expectedType == DataType.vector && coercedVal is DbText) {
              final vec = _parseVectorFromString(coercedVal.value);
              if (vec != null) coercedVal = vec;
            }
          }
          rowValues.add(coercedVal);
        }
        rowsValues.add(rowValues);
      }
      JitCompiler.currentParams = null;
    }

    // Queue index updates if needed
    final tableIndexes = db.catalog.getIndexesForTable(tableName);
    final needsPointers = tableIndexes.isNotEmpty;

    // Insert all rows in batch
    final pointers = rowTable.insertBatchSync(rowsValues, xmin: currentTxId, generatePointers: needsPointers);

    // Update stats
    final stats = db.catalog.getOrCreateStats(tableName);
    stats.rowCount += batchParams.length;

    if (needsPointers) {
      // Pre-compute index metadata outside the loop to optimize performance
      final preparedIndexes = tableIndexes.map((idx) {
        final indexName = _interpreter._indexFileNameCache.putIfAbsent(idx, () => idx.name.toLowerCase());
        final cols = idx.columnName.split(',');
        final cIndexes = cols.map((col) {
          final colClean = col.trim().toLowerCase();
          return schema.columnNamesLower.indexOf(colClean);
        }).toList();
        return (indexName: indexName, columnName: idx.columnName, colIndexes: cIndexes);
      }).toList();

      for (int r = 0; r < rowsValues.length; r++) {
        final rowValues = rowsValues[r];
        final pointer = pointers![r];
        for (final pIdx in preparedIndexes) {
          final compositeKey = List<double>.filled(pIdx.colIndexes.length, 0.0);
          bool hasAllKeys = true;
          for (int i = 0; i < pIdx.colIndexes.length; i++) {
            final cIdx = pIdx.colIndexes[i];
            if (cIdx == -1) { hasAllKeys = false; break; }
            final keyVal = rowValues[cIdx];
            double? dKey;
            if (keyVal is DbInt) {
              dKey = keyVal.value.toDouble();
            } else if (keyVal is DbDouble) {
              dKey = keyVal.value;
            } else if (keyVal is DbText) {
              final parsed = double.tryParse(keyVal.value);
              if (parsed != null) {
                dKey = parsed;
              } else {
                double hash = 0.0;
                for (int j = 0; j < keyVal.value.length; j++) {
                  hash = (hash * 31.0 + keyVal.value.codeUnitAt(j)) % 9007199254740991;
                }
                dKey = hash;
              }
            }
            if (dKey == null) { hasAllKeys = false; break; }
            compositeKey[i] = dKey;
          }
          if (hasAllKeys) {
            _interpreter._delayedIndexUpdates.add(_IndexUpdate(
              indexName: pIdx.indexName,
              tableName: tableName,
              columnName: pIdx.columnName.toLowerCase(),
              key: compositeKey,
              pageId: pointer.pageId,
              slotId: pointer.slotId,
            ));
          }
        }
      }
    }

    _interpreter._flushDelayedIndexUpdates();

    return QueryResult(
      columns: [],
      rows: [],
      message: "${batchParams.length} rows inserted in batch successfully.",
    );
  }
}


class Interpreter {
  static final Map<String, List<ASTNode>> _astCache = {};

  Database _db;
  Database get db => _db;
  set db(Database val) => _db = val;
  String _currentUser = 'admin';

  String get currentUser => _currentUser;
  set currentUser(String val) => _currentUser = val;
  
  // Local environment for PL/SQL variables
  final Map<String, DbValue> _env = {};
  Map<String, DbValue> get env => _env;
  
  // Console print log (DBMS_OUTPUT)
  final List<String> dbmsOutputLog = [];

  final List<_IndexUpdate> _delayedIndexUpdates = [];

  // Performance caches
  final Map<Expression, JitClosure> _jitCache = {};
  final Map<String, RowTableFile> _rowTableCache = {};
  final Map<String, ColumnTableFile> _colTableCache = {};
  final Map<String, bool> _indexExistsCache = {};
  final Map<IndexSchema, int> _indexColIdxCache = {};
  final Map<IndexSchema, String> _indexFileNameCache = {};
  
  final Map<InsertStmt, TableSchema> _insertSchemaCache = {};
  final Map<InsertStmt, List<JitClosure>> _insertClosuresCache = {};
  final Map<InsertStmt, List<int>?> _insertPlaceholderIndicesCache = {};
  List<DbValue>? _reusedInsertRowValues;
  final Map<String, bool> _referencingTablesCache = {};
  final Map<String, DbValue> _rowContextCache = {};
  final Map<String, Map<String, int>> _schemaKeyToIndexCache = {};

  bool _isTableReferencedByAnyForeignKey(String parentTableName) {
    final parentLower = parentTableName.toLowerCase();
    return _referencingTablesCache.putIfAbsent(parentLower, () {
      for (final schema in db.catalog.getTablesInternal().values) {
        for (final refTable in schema.columnReferencesTable) {
          if (refTable != null && refTable.toLowerCase() == parentLower) {
            return true;
          }
        }
      }
      return false;
    });
  }

  bool _areKeysEqual(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  late SessionTxContext _sessionContext;

  Interpreter(Database initialDb) : _db = initialDb {
    _sessionContext = _db.cache.createSessionContext();
  }

  Future<QueryResult> executeScript(String sqlScript) async {
    return runZoned(() async {
      final stopwatch = Stopwatch()..start();
      dbmsOutputLog.clear();
      _env.clear();

      bool catalogModified = false;

      try {
        List<ASTNode> statements;
        if (_astCache.containsKey(sqlScript)) {
          statements = _astCache[sqlScript]!;
        } else {
          final lexer = Lexer(sqlScript);
          final tokens = lexer.tokenize();
          
          final errors = tokens.where((t) => t.type == TokenType.invalid).toList();
          if (errors.isNotEmpty) {
            throw Exception("Lexer error: ${errors.first.lexeme} at Line ${errors.first.line}:${errors.first.column}");
          }

          final parser = Parser(tokens);
          statements = parser.parseScript();
          
          _astCache[sqlScript] = statements;
        }

        if (statements.isEmpty) {
          throw Exception("No SQL statements found to execute.");
        }

        QueryResult? lastResult;
        final messages = <String>[];

        for (final stmt in statements) {
          try {
            if (stmt is CreateTableStmt || stmt is CreateRelationshipStmt || stmt is CreateIndexStmt || stmt is CreatePolicyStmt || stmt is CreateProcedureStmt || stmt is CreateFunctionStmt || stmt is AlterTableStmt) {
              catalogModified = true;
            }
            var res = _executeNodeSync(stmt);
            if (res is Future) {
              res = await res;
            }
            if (res is QueryResult) {
              lastResult = res;
              if (res.message.isNotEmpty) {
                messages.add(res.message);
              }
            }
          } catch (e) {
            _delayedIndexUpdates.clear();
            _flushActiveTablePages();
            db.cache.rollbackTransactionSync(db.catalog);
            rethrow;
          }
        }

        _flushDelayedIndexUpdates();
        _flushActiveTablePages();
        
        if (catalogModified) {
          db.catalog.save();
          _referencingTablesCache.clear();
          _insertSchemaCache.clear();
          _insertClosuresCache.clear();
        }
        
        if (!db.cache.isTransactionActive) {
          db.cache.flushAllSync();
        }
        
        stopwatch.stop();

        final combinedMessage = messages.join('\n');

        if (lastResult != null) {
          return QueryResult(
            columns: lastResult.columns,
            rows: lastResult.rows,
            message: combinedMessage.isEmpty ? 'Script executed successfully.' : combinedMessage,
            executionTime: stopwatch.elapsed,
            dbmsOutputLog: List<String>.from(dbmsOutputLog),
          );
        }

        return QueryResult(
          columns: [],
          rows: [],
          message: combinedMessage.isEmpty ? 'Statement executed successfully.' : combinedMessage,
          executionTime: stopwatch.elapsed,
          dbmsOutputLog: List<String>.from(dbmsOutputLog),
        );
      } catch (e) {
        stopwatch.stop();
        return QueryResult(
          columns: [],
          rows: [],
          message: 'Error: ${e.toString()}',
          executionTime: stopwatch.elapsed,
          dbmsOutputLog: List<String>.from(dbmsOutputLog),
        );
      }
    }, zoneValues: {
      #sessionTxContext: _sessionContext,
    });
  }

  dynamic executeNodeSync(ASTNode node) => _executeNodeSync(node);

  dynamic _executeNodeSync(ASTNode node) {
    JitCompiler.activeInterpreter = this;
    if (node is ReturnStmt) {
      final valFn = _jitCache.putIfAbsent(node.expr, () => JitCompiler.compile(node.expr));
      final val = valFn(_env);
      throw ReturnException(val);
    }
    if (node is CreateProcedureStmt) {
      return _executeCreateProcedure(node);
    }
    if (node is CreateFunctionStmt) {
      return _executeCreateFunction(node);
    }
    if (node is CallStmt) {
      return _executeCall(node);
    }
    if (node is ExplainStmt) {
      return _executeExplain(node);
    }
    if (node is AnalyzeStmt) {
      return _executeAnalyze(node);
    }
    if (node is CreateTableStmt) {
      return _executeCreateTable(node);
    }
    if (node is AlterTableStmt) {
      return _executeAlterTable(node);
    }
    if (node is CreateIndexStmt) {
      return _executeCreateIndex(node);
    }
    if (node is ShowTablesStmt) {
      return _executeShowTables();
    }
    if (node is ShowIndexesStmt) {
      return _executeShowIndexes(node);
    }
    if (node is InsertStmt) {
      return _executeInsert(node);
    }
    if (node is DeleteStmt) {
      return _executeDelete(node);
    }
    if (node is UpdateStmt) {
      return _executeUpdate(node);
    }
    if (node is SelectStmt) {
      return _executeSelect(node);
    }
    if (node is PlSqlBlock) {
      return _executePlSqlBlockSync(node);
    }
    if (node is AssignStmt) {
      return _executeAssign(node);
    }
    if (node is IfStmt) {
      return _executeIfSync(node);
    }
    if (node is WhileStmt) {
      return _executeWhileSync(node);
    }
    if (node is DbmsOutputStmt) {
      return _executeDbmsOutput(node);
    }
    if (node is BeginTxStmt) {
      db.cache.startTransaction(db.catalog);
      return QueryResult(columns: [], rows: [], message: 'Transaction started.');
    }
    if (node is CommitTxStmt) {
      _flushActiveTablePages();
      _flushDelayedIndexUpdates();
      db.cache.commitTransaction();
      db.cache.flushAllSync();
      return QueryResult(columns: [], rows: [], message: 'Transaction committed.');
    }
    if (node is RollbackTxStmt) {
      _delayedIndexUpdates.clear();
      _flushActiveTablePages();
      db.cache.rollbackTransactionSync(db.catalog);
      return QueryResult(columns: [], rows: [], message: 'Transaction rolled back.');
    }
    if (node is CreateRelationshipStmt) {
      return _executeCreateRelationship(node);
    }
    if (node is CreatePolicyStmt) {
      return _executeCreatePolicy(node);
    }
    if (node is GenerateStmt) {
      return _executeGenerate();
    }
    if (node is GrantStmt) {
      db.catalog.grantPrivilege(node.user, node.tableName, node.privilege);
      return QueryResult(columns: [], rows: [], message: 'Grant succeeded.');
    }
    if (node is RevokeStmt) {
      db.catalog.revokePrivilege(node.user, node.tableName, node.privilege);
      return QueryResult(columns: [], rows: [], message: 'Revoke succeeded.');
    }
    if (node is SetUserStmt) {
      currentUser = node.username;
      return QueryResult(columns: [], rows: [], message: 'User changed to $currentUser.');
    }
    if (node is CreateDatabaseStmt) {
      return _executeCreateDatabase(node);
    }
    if (node is UseDatabaseStmt) {
      return _executeUseDatabase(node);
    }
    throw Exception("Unsupported AST Node type: ${node.runtimeType}");
  }

  Future<QueryResult> _executeGenerate() async {
    // 1. Close active connections and wipe directory
    await db.close();
    
    final dir = Directory(db.directory);
    if (dir.existsSync()) {
      for (final file in dir.listSync()) {
        try {
          file.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
    
    // 2. Re-initialize
    db.catalog.restoreBackupState({'tables': {}, 'relationships': {}});
    await db.init();
    
    // 3. Execute the generator script
    final script = '''
CREATE TABLE depts (id INT, name TEXT);
INSERT INTO depts VALUES (1, 'Engineering');
INSERT INTO depts VALUES (2, 'Marketing');

CREATE TABLE employees (id INT, name TEXT, dept_id INT);
INSERT INTO employees VALUES (101, 'Alice', 1);
INSERT INTO employees VALUES (102, 'Bob', 1);
INSERT INTO employees VALUES (103, 'Charlie', 2);

CREATE TABLE customers (id INT, info JSON);
INSERT INTO customers VALUES (1, '{"name": "Alice", "age": 28, "address": {"city": "New York"}}');
INSERT INTO customers VALUES (2, '{"name": "Bob", "age": 22, "address": {"city": "Boston"}}');
INSERT INTO customers VALUES (3, '{"name": "Charlie", "age": 35, "address": {"city": "Chicago"}}');

CREATE TABLE products (id INT, name TEXT, embedding VECTOR);
INSERT INTO products VALUES (1, 'Tech Running Shoes', '[0.1, 0.85, -0.2]');
INSERT INTO products VALUES (2, 'Quantum Physics Book', '[0.9, 0.1, 0.1]');
INSERT INTO products VALUES (3, 'Classic Cotton T-Shirt', '[0.15, 0.7, -0.1]');

CREATE RELATIONSHIP works_in FROM employees TO depts ON dept_id = id;

DECLARE
  counter INT := 0;
  total INT := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Generating sample data successfully.');
  WHILE counter < 10 LOOP
    counter := counter + 1;
    total := total + counter;
    IF counter % 2 = 0 THEN
      DBMS_OUTPUT.PUT_LINE('Counter ' || counter || ' is EVEN');
    ELSE
      DBMS_OUTPUT.PUT_LINE('Counter ' || counter || ' is ODD');
    END IF;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('PL/SQL Cumulative Total: ' || total);
END;
''';

    // Temporary clear output log so we don't mix previous prints
    final savedOutputs = List<String>.from(dbmsOutputLog);
    dbmsOutputLog.clear();

    final res = await executeScript(script);

    // Combine output message
    final buffer = StringBuffer();
    buffer.writeln('=== GENERATION SUCCESSFUL ===');
    buffer.writeln('1. Relational Tables created (depts, employees).');
    buffer.writeln('2. NoSQL Table created (customers with info JSON).');
    buffer.writeln('3. AI Vector Table created (products with embeddings).');
    buffer.writeln('4. Graph Relationship created (works_in).');
    buffer.writeln('5. PL/SQL logic executed.');
    if (dbmsOutputLog.isNotEmpty) {
      buffer.writeln('\nPL/SQL Output:');
      for (final line in dbmsOutputLog) {
        buffer.writeln('  $line');
      }
    }
    
    // Restore and append
    dbmsOutputLog.insertAll(0, savedOutputs);

    return QueryResult(
      columns: ['status'],
      rows: [[DbText('SUCCESS')]],
      message: buffer.toString(),
      executionTime: res.executionTime,
    );
  }

  QueryResult _executeCreateProcedure(CreateProcedureStmt stmt) {
    final name = stmt.name.toLowerCase();
    if (db.catalog.hasProcedure(name)) {
      throw Exception("Procedure '$name' already exists.");
    }
    final schema = ProcedureSchema(name: stmt.name, sql: stmt.sql);
    db.catalog.addProcedure(schema);
    return QueryResult(
      columns: [],
      rows: [],
      message: "Procedure '${stmt.name}' created successfully.",
    );
  }

  QueryResult _executeCreateFunction(CreateFunctionStmt stmt) {
    final name = stmt.name.toLowerCase();
    if (db.catalog.hasFunction(name)) {
      throw Exception("Function '$name' already exists.");
    }
    final schema = FunctionSchema(name: stmt.name, sql: stmt.sql);
    db.catalog.addFunction(schema);
    return QueryResult(
      columns: [],
      rows: [],
      message: "Function '${stmt.name}' created successfully.",
    );
  }

  QueryResult _executeCall(CallStmt stmt) {
    final procSchema = db.catalog.getProcedure(stmt.name);
    if (procSchema == null) {
      throw Exception("Procedure '${stmt.name}' does not exist.");
    }
    
    final args = stmt.args.map((a) {
      final fn = _jitCache.putIfAbsent(a, () => JitCompiler.compile(a));
      return fn(_env);
    }).toList();
    
    final savedEnv = Map<String, DbValue>.from(_env);
    _env.clear();
    
    for (int i = 0; i < procSchema.params.length; i++) {
      final param = procSchema.params[i];
      final argVal = i < args.length ? args[i] : DbNull();
      _env[param.name] = argVal;
    }
    
    QueryResult? lastResult;
    try {
      for (final s in procSchema.body) {
        final res = _executeNodeSync(s);
        if (res is Future) {
          throw Exception("Asynchronous operations are not supported inside procedures.");
        }
        if (res is QueryResult) {
          lastResult = res;
        }
      }
    } on ReturnException catch (_) {
      // Early return from procedure
    } finally {
      _env.clear();
      _env.addAll(savedEnv);
    }
    
    return QueryResult(
      columns: lastResult?.columns ?? [],
      rows: lastResult?.rows ?? [],
      message: "Procedure '${stmt.name}' executed successfully.",
    );
  }

  QueryResult _executeCreateTable(CreateTableStmt stmt) {
    final tableName = stmt.tableName.toLowerCase();
    if (db.catalog.hasTable(tableName)) {
      throw Exception("Table '$tableName' already exists.");
    }

    bool isColumnar = stmt.columns.any((c) => c.type == DataType.vector);

    final schema = TableSchema(
      name: stmt.tableName,
      columnNames: stmt.columns.map((c) => c.name).toList(),
      columnTypes: stmt.columns.map((c) => c.type).toList(),
      isColumnar: isColumnar,
      columnPrimaryKey: stmt.columns.map((c) => c.isPrimaryKey).toList(),
      columnUnique: stmt.columns.map((c) => c.isUnique).toList(),
      columnReferencesTable: stmt.columns.map((c) => c.referencesTable).toList(),
      columnReferencesColumn: stmt.columns.map((c) => c.referencesColumn).toList(),
      columnOnDeleteCascade: stmt.columns.map((c) => c.onDeleteCascade).toList(),
    );

    db.catalog.addTable(schema, saveToFile: false);

    // Auto-provision indexes for primary key and unique columns
    for (final col in stmt.columns) {
      if (col.isPrimaryKey || col.isUnique) {
        final idxName = 'idx_${tableName}_${col.name.toLowerCase()}';
        if (!db.catalog.hasIndex(idxName)) {
          db.catalog.addIndex(IndexSchema(name: idxName, tableName: stmt.tableName, columnName: col.name), saveToFile: false);
          db.getOrInitIndexSync(idxName);
        }
      }
    }

    // Initialize index if it has an 'id' column as first column (legacy fallback compatibility)
    if (stmt.columns.isNotEmpty && stmt.columns[0].name.toLowerCase() == 'id') {
      final idxName = 'idx_${tableName}_id';
      if (!db.catalog.hasIndex(idxName)) {
        db.catalog.addIndex(IndexSchema(name: idxName, tableName: stmt.tableName, columnName: stmt.columns[0].name), saveToFile: false);
        db.getOrInitIndexSync(idxName);
      }
    }

    return QueryResult(
      columns: [],
      rows: [],
      message: "Table '${stmt.tableName}' created successfully${isColumnar ? ' (optimized Columnar store)' : ' (Row store)'}.",
    );
  }

  QueryResult _executeAlterTable(AlterTableStmt stmt) {
    final tableName = stmt.tableName.toLowerCase();
    final schema = db.catalog.getTableSchema(tableName);
    if (schema == null) {
      throw Exception("Table '$tableName' does not exist.");
    }

    if (stmt.action == AlterAction.add) {
      final colToAdd = stmt.columnToAdd!;
      if (schema.columnNamesLower.contains(colToAdd.name.toLowerCase())) {
        throw Exception("Column '${colToAdd.name}' already exists in table '$tableName'.");
      }
      
      // Update catalog schema
      final newSchema = schema.addColumn(colToAdd);
      db.catalog.addTable(newSchema, saveToFile: false);
      
      // Clear caches
      _referencingTablesCache.clear();
      _insertSchemaCache.clear();
      _insertClosuresCache.clear();
      _schemaKeyToIndexCache.clear();
      _rowTableCache.remove(tableName);

      return QueryResult(
        columns: [],
        rows: [],
        message: "Column '${colToAdd.name}' added to table '$tableName' successfully.",
      );
    } else if (stmt.action == AlterAction.drop) {
      final colName = stmt.columnToDrop!;
      final colIdx = schema.columnNamesLower.indexOf(colName.toLowerCase());
      if (colIdx == -1) {
        throw Exception("Column '$colName' not found in table '$tableName'.");
      }

      if (schema.columnPrimaryKey[colIdx]) {
        throw Exception("Cannot drop primary key column '$colName'.");
      }

      // First, remove associated index if any
      final idxSchema = db.catalog.getIndexForColumn(tableName, colName);
      if (idxSchema != null) {
        db.catalog.removeIndex(idxSchema.name, saveToFile: false);
        final idxFile = File('${db.directory}/${idxSchema.name.toLowerCase()}.idx');
        if (idxFile.existsSync()) {
          try {
            idxFile.deleteSync();
          } catch (_) {}
        }
      }

      // Rewrite the table data
      if (schema.isColumnar) {
        final colCount = schema.columnNames.length;
        // Evict column files from cache
        for (int i = colIdx; i < colCount; i++) {
          final filePath = '${db.directory}/${schema.name}.col_$i';
          db.cache.evictTableSync(filePath);
        }

        // Delete the file for the dropped column
        final fileToDelete = File('${db.directory}/${schema.name}.col_$colIdx');
        if (fileToDelete.existsSync()) {
          fileToDelete.deleteSync();
        }

        // Rename remaining column files
        for (int i = colIdx + 1; i < colCount; i++) {
          final oldFile = File('${db.directory}/${schema.name}.col_$i');
          if (oldFile.existsSync()) {
            oldFile.renameSync('${db.directory}/${schema.name}.col_${i - 1}');
          }
        }
      } else {
        final rowTable = RowTableFile(
          cache: db.cache,
          tableName: schema.name,
          dbDirectory: db.directory,
        );
        final pager = db.cache.getOrCreatePager(rowTable.filePath);
        final pageCount = pager.getPageCountSync();
        
        final records = <MvccRecord>[];
        for (int p = 0; p < pageCount; p++) {
          final page = db.cache.pinPageSync(rowTable.filePath, p);
          final rowCount = SlottedPageHelper.getRowCount(page);
          for (int s = 0; s < rowCount; s++) {
            final recBytes = SlottedPageHelper.getRecord(page, s);
            if (recBytes != null) {
              try {
                final mvccRec = MvccRecord.fromBytes(recBytes);
                final rowValues = RecordSerializer.deserializeRow(mvccRec.rowData);
                if (colIdx < rowValues.length) {
                  rowValues.removeAt(colIdx);
                }
                final newRowData = RecordSerializer.serializeRow(rowValues);
                records.add(MvccRecord(
                  xmin: mvccRec.xmin,
                  xmax: mvccRec.xmax,
                  rollPtr: mvccRec.rollPtr,
                  rowData: newRowData,
                ));
              } catch (_) {
                final rowValues = RecordSerializer.deserializeRow(recBytes);
                if (colIdx < rowValues.length) {
                  rowValues.removeAt(colIdx);
                }
                final newRowData = RecordSerializer.serializeRow(rowValues);
                records.add(MvccRecord(xmin: 0, xmax: 0, rollPtr: 0, rowData: newRowData));
              }
            }
          }
          db.cache.unpinPageSync(rowTable.filePath, p, isDirty: false);
        }

        // Evict table from cache
        db.cache.evictTableSync(rowTable.filePath);

        // Delete original file
        final file = File(rowTable.filePath);
        if (file.existsSync()) {
          file.deleteSync();
        }

        // Write records to a fresh file
        final newRowTable = RowTableFile(
          cache: db.cache,
          tableName: schema.name,
          dbDirectory: db.directory,
        );
        for (final rec in records) {
          newRowTable.insertRawRecordSync(rec.toBytes());
        }
        newRowTable.flushActivePageSync();
      }

      // Update catalog schema
      final newSchema = schema.dropColumn(colName);
      db.catalog.addTable(newSchema, saveToFile: false);

      // Clear caches
      _referencingTablesCache.clear();
      _insertSchemaCache.clear();
      _insertClosuresCache.clear();
      _schemaKeyToIndexCache.clear();
      _rowTableCache.remove(tableName);

      return QueryResult(
        columns: [],
        rows: [],
        message: "Column '$colName' dropped from table '$tableName' successfully.",
      );
    } else {
      throw Exception("Unsupported ALTER TABLE action.");
    }
  }


  QueryResult _executeCreateRelationship(CreateRelationshipStmt stmt) {
    final relName = stmt.name.toLowerCase();
    if (db.catalog.hasRelationship(relName)) {
      throw Exception("Relationship '$relName' already exists.");
    }
    if (!db.catalog.hasTable(stmt.fromTable)) {
      throw Exception("Source table '${stmt.fromTable}' does not exist.");
    }
    if (!db.catalog.hasTable(stmt.toTable)) {
      throw Exception("Destination table '${stmt.toTable}' does not exist.");
    }

    // Verify key columns exist
    final fromSchema = db.catalog.getTableSchema(stmt.fromTable)!;
    if (!fromSchema.columnNamesLower.contains(stmt.fromKey.toLowerCase())) {
      throw Exception("Key column '${stmt.fromKey}' does not exist in table '${stmt.fromTable}'.");
    }
    final toSchema = db.catalog.getTableSchema(stmt.toTable)!;
    if (!toSchema.columnNamesLower.contains(stmt.toKey.toLowerCase())) {
      throw Exception("Key column '${stmt.toKey}' does not exist in table '${stmt.toTable}'.");
    }

    final rel = RelationshipSchema(
      name: stmt.name,
      fromTable: stmt.fromTable,
      toTable: stmt.toTable,
      fromKey: stmt.fromKey,
      toKey: stmt.toKey,
    );

    db.catalog.addRelationship(rel, saveToFile: false);

    return QueryResult(
      columns: [],
      rows: [],
      message: "Relationship '${stmt.name}' created successfully.",
    );
  }

  QueryResult _executeCreatePolicy(CreatePolicyStmt stmt) {
    final tableName = stmt.tableName.toLowerCase();
    final schema = db.catalog.getTableSchema(tableName);
    if (schema == null) {
      throw Exception("Table '$tableName' does not exist.");
    }
    if (schema.policies.any((p) => p.name.toLowerCase() == stmt.name.toLowerCase())) {
      throw Exception("Policy '${stmt.name}' already exists on table '${stmt.tableName}'.");
    }
    schema.policies.add(PolicySchema(name: stmt.name, condition: stmt.condition));
    return QueryResult(
      columns: [],
      rows: [],
      message: "Policy '${stmt.name}' created successfully on table '${stmt.tableName}'.",
    );
  }

  Future<QueryResult> _executeCreateDatabase(CreateDatabaseStmt stmt) async {
    final dbDir = '${stmt.name}_db';
    final directory = Directory(dbDir);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    final newDb = Database(dbDir);
    await newDb.init();
    await newDb.close(); // Release file locks
    return QueryResult(columns: [], rows: [], message: "Database '${stmt.name}' created successfully.");
  }

  Future<QueryResult> _executeUseDatabase(UseDatabaseStmt stmt) async {
    final dbDir = '${stmt.name}_db';
    final directory = Directory(dbDir);
    if (!directory.existsSync()) {
      throw Exception("Database '${stmt.name}' does not exist.");
    }
    // 1. Close current database
    await _db.close();

    // 2. Instantiate and initialize target database
    final newDb = Database(dbDir);
    await newDb.init();
    _db = newDb;

    // 3. Clear interpreter caches
    _rowTableCache.clear();
    _colTableCache.clear();
    _indexExistsCache.clear();
    _indexColIdxCache.clear();
    _indexFileNameCache.clear();
    _insertSchemaCache.clear();
    _insertClosuresCache.clear();
    _insertPlaceholderIndicesCache.clear();
    _referencingTablesCache.clear();
    _rowContextCache.clear();
    _schemaKeyToIndexCache.clear();
    _jitCache.clear();

    // 4. Update session transaction context
    _sessionContext = _db.cache.createSessionContext();

    return QueryResult(columns: [], rows: [], message: "Switched to database '${stmt.name}'.");
  }

  QueryResult _executeInsert(InsertStmt stmt) {
    if (!db.catalog.hasPrivilege(currentUser, stmt.tableName, 'insert')) {
      throw Exception("Permission denied: INSERT privilege required on table '${stmt.tableName}' for user '$currentUser'.");
    }
    final schema = _insertSchemaCache.putIfAbsent(stmt, () {
      final tableName = stmt.tableName.toLowerCase();
      final s = db.catalog.getTableSchema(tableName);
      if (s == null) {
        throw Exception("Table '$tableName' does not exist.");
      }
      return s;
    });

    final tableName = schema.name.toLowerCase();

    if (stmt.values.length != schema.columnNames.length) {
      throw Exception("Column count mismatch. Expected ${schema.columnNames.length} values, found ${stmt.values.length}.");
    }

    final len = stmt.values.length;
    if (_reusedInsertRowValues == null || _reusedInsertRowValues!.length != len) {
      _reusedInsertRowValues = List<DbValue>.filled(len, DbNull());
    }
    final rowValues = _reusedInsertRowValues!;
    final placeholderIndices = _insertPlaceholderIndicesCache.putIfAbsent(stmt, () {
      final list = <int>[];
      for (final expr in stmt.values) {
        if (expr is PlaceholderExpr && expr.index != null) {
          list.add(expr.index!);
        } else {
          return null;
        }
      }
      return list;
    });

    if (placeholderIndices != null) {
      final params = JitCompiler.currentParams;
      if (params != null) {
        for (int i = 0; i < len; i++) {
          final paramIdx = placeholderIndices[i];
          final val = paramIdx < params.length ? params[paramIdx] : DbNull();
          final expectedType = schema.columnTypes[i];
          DbValue coercedVal = val;
          if (coercedVal is! DbNull && coercedVal.type != expectedType) {
            if (expectedType == DataType.double && coercedVal is DbInt) {
              coercedVal = DbDouble(coercedVal.value.toDouble());
            } else if (expectedType == DataType.json && coercedVal is DbText) {
              try {
                coercedVal = DbJson(json.decode(coercedVal.value));
              } catch (_) {
                throw Exception("Type mismatch for column '${schema.columnNames[i]}'. Expected $expectedType, found ${val.type}.");
              }
            } else if (expectedType == DataType.vector && coercedVal is DbText) {
              final vec = _parseVectorFromString(coercedVal.value);
              if (vec != null) {
                coercedVal = vec;
              } else {
                throw Exception("Type mismatch for column '${schema.columnNames[i]}'. Expected $expectedType, found ${val.type}.");
              }
            } else {
              throw Exception("Type mismatch for column '${schema.columnNames[i]}'. Expected $expectedType, found ${val.type}.");
            }
          }
          rowValues[i] = coercedVal;
        }
      }
    } else {
      final closures = _insertClosuresCache.putIfAbsent(stmt, () {
        return stmt.values.map((expr) => JitCompiler.compile(expr)).toList();
      });
      for (int i = 0; i < len; i++) {
        final val = closures[i](_env);
        final expectedType = schema.columnTypes[i];
        DbValue coercedVal = val;
        if (coercedVal is! DbNull && coercedVal.type != expectedType) {
          if (expectedType == DataType.double && coercedVal is DbInt) {
            coercedVal = DbDouble(coercedVal.value.toDouble());
          } else if (expectedType == DataType.json && coercedVal is DbText) {
            try {
              coercedVal = DbJson(json.decode(coercedVal.value));
            } catch (_) {
              throw Exception("Type mismatch for column '${schema.columnNames[i]}'. Expected $expectedType, found ${val.type}.");
            }
          } else if (expectedType == DataType.vector && coercedVal is DbText) {
            final vec = _parseVectorFromString(coercedVal.value);
            if (vec != null) {
              coercedVal = vec;
            } else {
              throw Exception("Type mismatch for column '${schema.columnNames[i]}'. Expected $expectedType, found ${val.type}.");
            }
          } else {
            throw Exception("Type mismatch for column '${schema.columnNames[i]}'. Expected $expectedType, found ${val.type}.");
          }
        }
        rowValues[i] = coercedVal;
      }
    }

    // Enforce UNIQUE and PRIMARY KEY constraints
    if (schema.hasUniqueOrPrimaryKey) {
      for (int i = 0; i < schema.columnNames.length; i++) {
        if (schema.columnPrimaryKey[i] || schema.columnUnique[i]) {
          final val = rowValues[i];
          if (val is DbNull) {
            if (schema.columnPrimaryKey[i]) {
              throw Exception("Primary key column '${schema.columnNames[i]}' cannot be NULL.");
            }
            continue; // Null values are allowed in UNIQUE columns (unless primary key)
          }
          
          final idx = db.catalog.getIndexForColumn(tableName, schema.columnNames[i]);
          bool checkedWithIndex = false;
          if (idx != null && (val is DbInt || val is DbDouble)) {
            final double? dKey = val is DbInt ? val.value.toDouble() : (val is DbDouble ? val.value : null);
            if (dKey != null) {
              final rowTable = _rowTableCache.putIfAbsent(tableName, () => RowTableFile(
                cache: db.cache,
                tableName: schema.name,
                dbDirectory: db.directory,
              ));
              final btree = db.getOrInitIndexSync(idx.name);
              final ptrs = btree.searchRangeSync([dKey], [dKey]);
              bool hasVisible = false;
              for (final ptr in ptrs) {
                final page = db.cache.pinPageSync(rowTable.filePath, ptr.pageId);
                final recBytes = SlottedPageHelper.getRecord(page, ptr.slotId);
                if (recBytes != null) {
                  try {
                    final mvccRecord = MvccRecord.fromBytes(recBytes);
                    final currentTx = db.cache.currentMvccTx;
                    final txManager = db.cache.mvccTxManager;
                    final currentTxId = currentTx?.txId ?? 0;
                    final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
                    if (txManager.isVisible(mvccRecord.xmin, mvccRecord.xmax, currentTxId, activeTxIds)) {
                      hasVisible = true;
                      db.cache.unpinPageSync(rowTable.filePath, ptr.pageId, isDirty: false);
                      break;
                    }
                  } catch (_) {
                    hasVisible = true; // Non-MVCC
                    db.cache.unpinPageSync(rowTable.filePath, ptr.pageId, isDirty: false);
                    break;
                  }
                }
                db.cache.unpinPageSync(rowTable.filePath, ptr.pageId, isDirty: false);
              }
              if (hasVisible) {
                throw Exception("Unique constraint violation: value '${val.toString()}' already exists in unique column '${schema.columnNames[i]}'.");
              }
              checkedWithIndex = true;
            }
          }
          
          if (!checkedWithIndex) {
            // Fallback: sequential scan check
            final rowTable = _rowTableCache.putIfAbsent(tableName, () => RowTableFile(
              cache: db.cache,
              tableName: schema.name,
              dbDirectory: db.directory,
            ));
            final pager = db.cache.getOrCreatePager(rowTable.filePath);
            final pageCount = pager.getPageCountSync();
            for (int pageId = 0; pageId < pageCount; pageId++) {
              final page = db.cache.pinPageSync(rowTable.filePath, pageId);
              final rowCount = SlottedPageHelper.getRowCount(page);
              for (int slotId = 0; slotId < rowCount; slotId++) {
                final recBytes = SlottedPageHelper.getRecord(page, slotId);
                if (recBytes != null) {
                  List<DbValue>? existingRow;
                  try {
                    final mvccRecord = MvccRecord.fromBytes(recBytes);
                    final currentTx = db.cache.currentMvccTx;
                    final txManager = db.cache.mvccTxManager;
                    final currentTxId = currentTx?.txId ?? 0;
                    final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
                    if (txManager.isVisible(mvccRecord.xmin, mvccRecord.xmax, currentTxId, activeTxIds)) {
                      existingRow = RecordSerializer.deserializeRow(mvccRecord.rowData);
                    }
                  } catch (_) {
                    existingRow = RecordSerializer.deserializeRow(recBytes);
                  }
                  if (existingRow == null) continue;
                  if (i < existingRow.length) {
                    final existingVal = existingRow[i];
                    if (existingVal.compareTo(val) == 0) {
                      db.cache.unpinPageSync(rowTable.filePath, pageId, isDirty: false);
                      throw Exception("Unique constraint violation: value '${val.toString()}' already exists in unique column '${schema.columnNames[i]}'.");
                    }
                  }
                }
              }
              db.cache.unpinPageSync(rowTable.filePath, pageId, isDirty: false);
            }
          }
        }
      }
    }

    // Enforce FOREIGN KEY references constraints on insert
    if (schema.hasForeignKeys) {
      for (int i = 0; i < schema.columnNames.length; i++) {
        final refTable = schema.columnReferencesTable[i];
        final refCol = schema.columnReferencesColumn[i];
        if (refTable != null && refCol != null) {
          final val = rowValues[i];
          if (val is DbNull) continue; // Null foreign keys are allowed (unless also primary key/not null)

          final refSchema = db.catalog.getTableSchema(refTable);
          if (refSchema == null) {
            throw Exception("Foreign key constraint error: referenced table '$refTable' does not exist.");
          }
          final refColIdx = refSchema.columnNamesLower.indexOf(refCol.toLowerCase());
          if (refColIdx == -1) {
            throw Exception("Foreign key constraint error: referenced column '$refCol' does not exist in table '$refTable'.");
          }

          final idx = db.catalog.getIndexForColumn(refTable, refCol);
          bool verifiedWithIndex = false;
          if (idx != null && (val is DbInt || val is DbDouble)) {
            final double? dKey = val is DbInt ? val.value.toDouble() : (val is DbDouble ? val.value : null);
            if (dKey != null) {
              final btree = db.getOrInitIndexSync(idx.name);
              final ptr = btree.searchSync([dKey]);
              if (ptr != null) {
                verifiedWithIndex = true;
              }
            }
          }

          if (!verifiedWithIndex) {
            // Sequential scan verification
            final refRowTable = _rowTableCache.putIfAbsent(refTable.toLowerCase(), () => RowTableFile(
              cache: db.cache,
              tableName: refSchema.name,
              dbDirectory: db.directory,
            ));
            final pager = db.cache.getOrCreatePager(refRowTable.filePath);
            final pageCount = pager.getPageCountSync();
            bool found = false;
            for (int pageId = 0; pageId < pageCount; pageId++) {
              final page = db.cache.pinPageSync(refRowTable.filePath, pageId);
              final rowCount = SlottedPageHelper.getRowCount(page);
              for (int slotId = 0; slotId < rowCount; slotId++) {
                final recBytes = SlottedPageHelper.getRecord(page, slotId);
                if (recBytes != null) {
                  List<DbValue>? refRow;
                  try {
                    final mvccRecord = MvccRecord.fromBytes(recBytes);
                    final currentTx = db.cache.currentMvccTx;
                    final txManager = db.cache.mvccTxManager;
                    final currentTxId = currentTx?.txId ?? 0;
                    final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
                    if (txManager.isVisible(mvccRecord.xmin, mvccRecord.xmax, currentTxId, activeTxIds)) {
                      refRow = RecordSerializer.deserializeRow(mvccRecord.rowData);
                    }
                  } catch (_) {
                    refRow = RecordSerializer.deserializeRow(recBytes);
                  }
                  if (refRow == null) continue;
                  if (refColIdx < refRow.length) {
                    final refVal = refRow[refColIdx];
                    if (refVal.compareTo(val) == 0) {
                      found = true;
                      break;
                    }
                  }
                }
              }
              db.cache.unpinPageSync(refRowTable.filePath, pageId, isDirty: false);
              if (found) break;
            }
            if (!found) {
              throw Exception("Foreign key constraint violation: value '${val.toString()}' in column '${schema.columnNames[i]}' does not exist in referenced column '$refTable($refCol)'.");
            }
          }
        }
      }
    }

    int recordPageId = 0;
    int recordSlotId = 0;

    if (schema.isColumnar) {
      final colTable = _colTableCache.putIfAbsent(tableName, () => ColumnTableFile(
        cache: db.cache,
        tableName: schema.name,
        dbDirectory: db.directory,
        schema: schema,
      ));
      colTable.insertSync(rowValues);
    } else {
      final rowTable = _rowTableCache.putIfAbsent(tableName, () => RowTableFile(
        cache: db.cache,
        tableName: schema.name,
        dbDirectory: db.directory,
      ));
      
      final currentTxId = db.cache.currentMvccTx?.txId ?? 0;
      final pointer = rowTable.insertSync(rowValues, xmin: currentTxId);
      recordPageId = pointer.pageId;
      recordSlotId = pointer.slotId;
    }

    // Update table statistics
    final stats = db.catalog.getOrCreateStats(tableName);
    stats.rowCount++;

    // Update B+ Tree indexes if present (Delayed WAL-style index updates)
    final tableIndexes = db.catalog.getIndexesForTable(tableName);
    for (final idx in tableIndexes) {
      final indexName = _indexFileNameCache.putIfAbsent(idx, () => idx.name.toLowerCase());
      final indexCols = idx.columnName.split(',');
      final List<double> compositeKey = [];
      bool hasAllKeys = true;
      for (final col in indexCols) {
        final colClean = col.trim().toLowerCase();
        final cIdx = schema.columnNamesLower.indexOf(colClean);
        if (cIdx == -1) {
          hasAllKeys = false;
          break;
        }
        final keyVal = rowValues[cIdx];
        double? dKey;
        if (keyVal is DbInt) {
          dKey = keyVal.value.toDouble();
        } else if (keyVal is DbDouble) {
          dKey = keyVal.value;
        } else if (keyVal is DbText) {
          final parsed = double.tryParse(keyVal.value);
          if (parsed != null) {
            dKey = parsed;
          } else {
            double hash = 0.0;
            for (int j = 0; j < keyVal.value.length; j++) {
              hash = (hash * 31.0 + keyVal.value.codeUnitAt(j)) % 9007199254740991;
            }
            dKey = hash;
          }
        }
        if (dKey == null) {
          hasAllKeys = false;
          break;
        }
        compositeKey.add(dKey);
      }
      if (hasAllKeys && compositeKey.length == indexCols.length) {
        _delayedIndexUpdates.add(_IndexUpdate(
          indexName: indexName,
          tableName: tableName,
          columnName: idx.columnName.toLowerCase(),
          key: compositeKey,
          pageId: recordPageId,
          slotId: recordSlotId,
        ));
      }
    }

    return QueryResult(
      columns: [],
      rows: [],
      message: "1 row inserted successfully.",
    );
  }

  QueryResult _executeDelete(DeleteStmt stmt) {
    if (!db.catalog.hasPrivilege(currentUser, stmt.tableName, 'delete')) {
      throw Exception("Permission denied: DELETE privilege required on table '${stmt.tableName}' for user '$currentUser'.");
    }
    _flushDelayedIndexUpdates();
    final tableName = stmt.tableName.toLowerCase();
    final schema = db.catalog.getTableSchema(tableName);
    if (schema == null) {
      throw Exception("Table '$tableName' does not exist.");
    }
    if (schema.isColumnar) {
      throw Exception("Deletes are not supported on columnar tables.");
    }

    final wasTxActive = db.cache.isTransactionActive;
    if (!wasTxActive) {
      db.cache.startTransaction(db.catalog);
    }

    final currentTxId = db.cache.currentMvccTx?.txId ?? 0;
    int deletedCount = 0;

    try {
      final rowTable = _rowTableCache.putIfAbsent(tableName, () => RowTableFile(
        cache: db.cache,
        tableName: schema.name,
        dbDirectory: db.directory,
      ));

      final pager = db.cache.getOrCreatePager(rowTable.filePath);
      final pageCount = pager.getPageCountSync();

      // Collect target pageId and slotId to avoid pin count / concurrent mod issues
      final toDelete = <_DeleteTarget>[];

      // Try index scan first if simple equality filter on indexed column
      final cond = stmt.whereCondition;
      bool usedIndex = false;
      if (cond is BinaryExpr && cond.operator == '=' && cond.left is VariableExpr) {
        final varExpr = cond.left as VariableExpr;
        if (varExpr.path.length == 1 || varExpr.path.first.toLowerCase() == tableName) {
          final colName = varExpr.path.last.toLowerCase();
          final idx = db.catalog.getIndexForColumn(tableName, colName);
          if (idx != null) {
            final rightValFn = _jitCache.putIfAbsent(cond.right, () => JitCompiler.compile(cond.right));
            final rightVal = rightValFn({}); // Evaluate with empty context
            final double? searchKey = rightVal is DbInt
                ? rightVal.value.toDouble()
                : (rightVal is DbDouble ? rightVal.value : null);

            if (searchKey != null) {
              final btree = db.getOrInitIndexSync(idx.name.toLowerCase());
              final ptr = btree.searchSync([searchKey]);
              if (ptr != null) {
                final page = db.cache.pinPageSync(rowTable.filePath, ptr.pageId);
                final recBytes = SlottedPageHelper.getRecord(page, ptr.slotId);
                if (recBytes != null) {
                  List<DbValue>? rowValues;
                  try {
                    final mvccRecord = MvccRecord.fromBytes(recBytes);
                    final currentTx = db.cache.currentMvccTx;
                    final txManager = db.cache.mvccTxManager;
                    final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
                    if (txManager.isVisible(mvccRecord.xmin, mvccRecord.xmax, currentTxId, activeTxIds)) {
                      rowValues = RecordSerializer.deserializeRow(mvccRecord.rowData);
                    }
                  } catch (_) {
                    rowValues = RecordSerializer.deserializeRow(recBytes);
                  }
                  if (rowValues != null) {
                    toDelete.add(_DeleteTarget(ptr.pageId, ptr.slotId, rowValues));
                  }
                }
                db.cache.unpinPageSync(rowTable.filePath, ptr.pageId, isDirty: false);
              }
              usedIndex = true;
            }
          }
        }
      }

      if (!usedIndex) {
        for (int pageId = 0; pageId < pageCount; pageId++) {
          final page = db.cache.pinPageSync(rowTable.filePath, pageId);
          final rowCount = SlottedPageHelper.getRowCount(page);
          for (int slotId = 0; slotId < rowCount; slotId++) {
            final recBytes = SlottedPageHelper.getRecord(page, slotId);
            if (recBytes != null) {
              List<DbValue>? rowValues;
              try {
                final mvccRecord = MvccRecord.fromBytes(recBytes);
                final currentTx = db.cache.currentMvccTx;
                final txManager = db.cache.mvccTxManager;
                final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
                if (txManager.isVisible(mvccRecord.xmin, mvccRecord.xmax, currentTxId, activeTxIds)) {
                  rowValues = RecordSerializer.deserializeRow(mvccRecord.rowData);
                }
              } catch (_) {
                rowValues = RecordSerializer.deserializeRow(recBytes);
              }

              if (rowValues != null) {
                bool matches = true;
                if (stmt.whereCondition != null) {
                  final keyToIndex = _schemaKeyToIndexCache.putIfAbsent(schema.name.toLowerCase(), () {
                    final map = <String, int>{};
                    for (int i = 0; i < schema.columnNames.length; i++) {
                      map['${schema.name}.${schema.columnNames[i]}'] = i;
                      map[schema.columnNames[i]] = i;
                    }
                    return map;
                  });
                  final rowMap = RowMap(rowValues, keyToIndex);
                  final condFn = _jitCache.putIfAbsent(stmt.whereCondition!, () => JitCompiler.compile(stmt.whereCondition!));
                  final condVal = condFn(rowMap);
                  matches = (condVal is DbInt && condVal.value == 1) || (condVal is DbDouble && condVal.value > 0.0);
                }

                if (matches) {
                  toDelete.add(_DeleteTarget(pageId, slotId, rowValues));
                }
              }
            }
          }
          db.cache.unpinPageSync(rowTable.filePath, pageId, isDirty: false);
        }
      }

      final hasReferencing = _isTableReferencedByAnyForeignKey(schema.name);
      final stats = db.catalog.getOrCreateStats(schema.name);
      final visitedTables = <String>{};
      for (final target in toDelete) {
        rowTable.deleteRecordSync(target.pageId, target.slotId, currentTxId);
        deletedCount++;

        // Update statistics
        stats.rowCount = (stats.rowCount > 0) ? stats.rowCount - 1 : 0;

        if (hasReferencing) {
          // Cascade delete for each column of the deleted row
          for (int k = 0; k < schema.columnNames.length; k++) {
            _cascadeDeleteSync(schema.name, schema.columnNames[k], target.rowValues[k], currentTxId, visitedTables);
          }
        }
      }

      if (!wasTxActive) {
        db.cache.commitTransaction();
      }

      return QueryResult(
        columns: [],
        rows: [],
        message: "$deletedCount rows deleted successfully.",
      );
    } catch (e) {
      if (!wasTxActive) {
        db.cache.rollbackTransactionSync(db.catalog);
      }
      rethrow;
    }
  }

  QueryResult _executeUpdate(UpdateStmt stmt) {
    if (!db.catalog.hasPrivilege(currentUser, stmt.tableName, 'update')) {
      throw Exception("Permission denied: UPDATE privilege required on table '${stmt.tableName}' for user '$currentUser'.");
    }
    _flushDelayedIndexUpdates();
    final tableName = stmt.tableName.toLowerCase();
    final schema = db.catalog.getTableSchema(tableName);
    if (schema == null) {
      throw Exception("Table '$tableName' does not exist.");
    }
    if (schema.isColumnar) {
      throw Exception("Updates are not supported on columnar tables.");
    }

    final colIndex = schema.columnNames.indexWhere((c) => c.toLowerCase() == stmt.columnName.toLowerCase());
    if (colIndex == -1) {
      throw Exception("Column '${stmt.columnName}' does not exist on table '$tableName'.");
    }

    final wasTxActive = db.cache.isTransactionActive;
    if (!wasTxActive) {
      db.cache.startTransaction(db.catalog);
    }

    final currentTxId = db.cache.currentMvccTx?.txId ?? 0;
    int updatedCount = 0;

    try {
      final rowTable = _rowTableCache.putIfAbsent(tableName, () => RowTableFile(
        cache: db.cache,
        tableName: schema.name,
        dbDirectory: db.directory,
      ));

      // 1. Locate targets (pageId, slotId) to update
      final toUpdate = <_DeleteTarget>[];
      final pager = db.cache.getOrCreatePager(rowTable.filePath);
      final pageCount = pager.getPageCountSync();

      // Check if we can use index range scan
      final cond = stmt.whereCondition;
      IndexRange? range;
      if (cond != null) {
        range = db.planner.planIndexRange(tableName, cond);
      }

      if (range != null) {
        final btree = db.getOrInitIndexSync(range.indexSchema.name.toLowerCase());
        final ptrs = btree.searchRangeSync(range.low, range.high);
        
        // Sort physically by pageId & slotId to maximize sequential cache hits
        ptrs.sort((a, b) {
          final cmp = a.pageId.compareTo(b.pageId);
          if (cmp != 0) return cmp;
          return a.slotId.compareTo(b.slotId);
        });

        for (final ptr in ptrs) {
          final page = db.cache.pinPageSync(rowTable.filePath, ptr.pageId);
          final recBytes = SlottedPageHelper.getRecord(page, ptr.slotId);
          if (recBytes != null) {
            List<DbValue>? rowValues;
            try {
              final mvccRecord = MvccRecord.fromBytes(recBytes);
              final currentTx = db.cache.currentMvccTx;
              final txManager = db.cache.mvccTxManager;
              final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
              if (txManager.isVisible(mvccRecord.xmin, mvccRecord.xmax, currentTxId, activeTxIds)) {
                rowValues = RecordSerializer.deserializeRow(mvccRecord.rowData);
              }
            } catch (_) {
              rowValues = RecordSerializer.deserializeRow(recBytes);
            }
            if (rowValues != null) {
              toUpdate.add(_DeleteTarget(ptr.pageId, ptr.slotId, rowValues));
            }
          }
          db.cache.unpinPageSync(rowTable.filePath, ptr.pageId, isDirty: false);
        }
      } else {
        // Fallback: sequential scan
        for (int pageId = 0; pageId < pageCount; pageId++) {
          final page = db.cache.pinPageSync(rowTable.filePath, pageId);
          final rowCount = SlottedPageHelper.getRowCount(page);
          for (int slotId = 0; slotId < rowCount; slotId++) {
            final recBytes = SlottedPageHelper.getRecord(page, slotId);
            if (recBytes != null) {
              List<DbValue>? rowValues;
              try {
                final mvccRecord = MvccRecord.fromBytes(recBytes);
                final currentTx = db.cache.currentMvccTx;
                final txManager = db.cache.mvccTxManager;
                final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
                if (txManager.isVisible(mvccRecord.xmin, mvccRecord.xmax, currentTxId, activeTxIds)) {
                  rowValues = RecordSerializer.deserializeRow(mvccRecord.rowData);
                }
              } catch (_) {
                rowValues = RecordSerializer.deserializeRow(recBytes);
              }

              if (rowValues != null) {
                bool matches = true;
                if (stmt.whereCondition != null) {
                  final keyToIndex = _schemaKeyToIndexCache.putIfAbsent(schema.name.toLowerCase(), () {
                    final map = <String, int>{};
                    for (int i = 0; i < schema.columnNames.length; i++) {
                      map['${schema.name}.${schema.columnNames[i]}'] = i;
                      map[schema.columnNames[i]] = i;
                    }
                    return map;
                  });
                  final rowMap = RowMap(rowValues, keyToIndex);
                  final condFn = _jitCache.putIfAbsent(stmt.whereCondition!, () => JitCompiler.compile(stmt.whereCondition!));
                  final condVal = condFn(rowMap);
                  matches = (condVal is DbInt && condVal.value == 1) || (condVal is DbDouble && condVal.value > 0.0);
                }

                if (matches) {
                  toUpdate.add(_DeleteTarget(pageId, slotId, rowValues));
                }
              }
            }
          }
          db.cache.unpinPageSync(rowTable.filePath, pageId, isDirty: false);
        }
      }

      // Compile set expression
      final valFn = _jitCache.putIfAbsent(stmt.valueExpr, () => JitCompiler.compile(stmt.valueExpr));

      // 2. Perform updates using ISURA (In-Place Slotted Update & Relocation Algorithm)
      final keyToIndex = _schemaKeyToIndexCache.putIfAbsent(schema.name.toLowerCase(), () {
        final map = <String, int>{};
        for (int i = 0; i < schema.columnNames.length; i++) {
          map['${schema.name}.${schema.columnNames[i]}'] = i;
          map[schema.columnNames[i]] = i;
        }
        return map;
      });

      for (final target in toUpdate) {
        final rowMap = RowMap(target.rowValues, keyToIndex);
        final newVal = valFn(rowMap);
        final expectedType = schema.columnTypes[colIndex];
        DbValue coercedVal = newVal;
        if (coercedVal is! DbNull && coercedVal.type != expectedType) {
          if (expectedType == DataType.double && coercedVal is DbInt) {
            coercedVal = DbDouble(coercedVal.value.toDouble());
          } else if (expectedType == DataType.json && coercedVal is DbText) {
            try { coercedVal = DbJson(json.decode(coercedVal.value)); } catch (_) {}
          }
        }

        // Construct new row values
        final newRowValues = List<DbValue>.from(target.rowValues);
        newRowValues[colIndex] = coercedVal;

        // Serialize new record
        final newRowData = RecordSerializer.serializeRow(newRowValues);
        final mvccRecord = MvccRecord(xmin: currentTxId, xmax: 0, rollPtr: 0, rowData: newRowData);
        final newBytes = mvccRecord.toBytes();

        // Pin the data page to perform Slotted Page manipulation
        final page = db.cache.pinPageSync(rowTable.filePath, target.pageId);
        final data = page.byteData;
        final slotOffset = SlottedPageHelper.headerSize + target.slotId * 4;
        final oldOffset = data.getUint16(slotOffset);
        final oldLen = data.getUint16(slotOffset + 2);

        if (newBytes.length <= oldLen) {
          // ISURA Case 1: In-Place Overwrite (reuses same slot bytes, no index changes)
          page.data.setAll(oldOffset, newBytes);
          data.setUint16(slotOffset + 2, newBytes.length);
          db.cache.unpinPageSync(rowTable.filePath, target.pageId, isDirty: true);
          updatedCount++;
        } else {
          // ISURA Case 2: In-Page Relocation (same pageId/slotId, no index changes)
          final freeSpaceOffset = data.getUint16(3);
          final rowCount = data.getUint16(1);
          final slotEnd = SlottedPageHelper.headerSize + rowCount * 4;

          if (freeSpaceOffset - slotEnd >= newBytes.length) {
            final newOffset = freeSpaceOffset - newBytes.length;
            page.data.setAll(newOffset, newBytes);
            data.setUint16(slotOffset, newOffset);
            data.setUint16(slotOffset + 2, newBytes.length);
            data.setUint16(3, newOffset);
            db.cache.unpinPageSync(rowTable.filePath, target.pageId, isDirty: true);
            updatedCount++;
          } else {
            // ISURA Case 3: Out-of-Page Relocation (reverts to Delete + Insert)
            db.cache.unpinPageSync(rowTable.filePath, target.pageId, isDirty: false);
            
            // Delete old record
            rowTable.deleteRecordSync(target.pageId, target.slotId, currentTxId);

            // Insert new record
            final newPtr = rowTable.insertSync(newRowValues, xmin: currentTxId);

            // Queue new index pointer mapping (since physical location changed)
            final tableIndexes = db.catalog.getIndexesForTable(tableName);
            for (final idx in tableIndexes) {
              final indexName = _indexFileNameCache.putIfAbsent(idx, () => idx.name.toLowerCase());
              final cols = idx.columnName.split(',').map((c) => c.trim().toLowerCase()).toList();
              final keyList = <double>[];
              for (final col in cols) {
                final cIdx = schema.columnNames.indexWhere((n) => n.toLowerCase() == col);
                if (cIdx != -1) {
                  final v = newRowValues[cIdx];
                  final dKey = v is DbInt ? v.value.toDouble() : (v is DbDouble ? v.value : 0.0);
                  keyList.add(dKey);
                }
              }
              if (keyList.isNotEmpty) {
                _delayedIndexUpdates.add(_IndexUpdate(
                  indexName: indexName,
                  tableName: tableName,
                  columnName: idx.columnName,
                  key: keyList,
                  pageId: newPtr.pageId,
                  slotId: newPtr.slotId,
                ));
              }
            }
            updatedCount++;
          }
        }
      }

      if (!wasTxActive) {
        db.cache.commitTransaction();
      }

      return QueryResult(
        columns: [],
        rows: [],
        message: "$updatedCount rows updated successfully.",
      );
    } catch (e) {
      if (!wasTxActive) {
        db.cache.rollbackTransactionSync(db.catalog);
      }
      rethrow;
    }
  }

  void _cascadeDeleteSync(String parentTableName, String parentColName, DbValue parentVal, int currentTxId, Set<String> visitedTables) {
    if (visitedTables.contains(parentTableName.toLowerCase())) return;
    visitedTables.add(parentTableName.toLowerCase());

    // Iterate over all tables in catalog to find referencing tables
    for (final schema in db.catalog.getTablesInternal().values) {
      final tableName = schema.name.toLowerCase();
      for (int i = 0; i < schema.columnNames.length; i++) {
        final refTable = schema.columnReferencesTable[i];
        final refCol = schema.columnReferencesColumn[i];
        if (refTable != null && refCol != null) {
          if (refTable.toLowerCase() == parentTableName.toLowerCase() &&
              refCol.toLowerCase() == parentColName.toLowerCase()) {
            // Found a referencing column!
            _deleteRowsSync(schema.name, schema.columnNames[i], parentVal, currentTxId, visitedTables);
          }
        }
      }
    }
    visitedTables.remove(parentTableName.toLowerCase());
  }

  void _deleteRowsSync(String tableName, String colName, DbValue targetVal, int currentTxId, Set<String> visitedTables) {
    final schema = db.catalog.getTableSchema(tableName.toLowerCase());
    if (schema == null) return;

    final rowTable = _rowTableCache.putIfAbsent(tableName.toLowerCase(), () => RowTableFile(
      cache: db.cache,
      tableName: schema.name,
      dbDirectory: db.directory,
    ));

    final pager = db.cache.getOrCreatePager(rowTable.filePath);
    final pageCount = pager.getPageCountSync();
    
    final colIdx = schema.columnNamesLower.indexOf(colName.toLowerCase());
    if (colIdx == -1) return;

    final toDelete = <_DeleteTarget>[];

    for (int pageId = 0; pageId < pageCount; pageId++) {
      final page = db.cache.pinPageSync(rowTable.filePath, pageId);
      final rowCount = SlottedPageHelper.getRowCount(page);
      for (int slotId = 0; slotId < rowCount; slotId++) {
        final recBytes = SlottedPageHelper.getRecord(page, slotId);
        if (recBytes != null) {
          List<DbValue>? rowValues;
          try {
            final mvccRecord = MvccRecord.fromBytes(recBytes);
            final currentTx = db.cache.currentMvccTx;
            final txManager = db.cache.mvccTxManager;
            final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
            if (txManager.isVisible(mvccRecord.xmin, mvccRecord.xmax, currentTxId, activeTxIds)) {
              rowValues = RecordSerializer.deserializeRow(mvccRecord.rowData);
            }
          } catch (_) {
            rowValues = RecordSerializer.deserializeRow(recBytes);
          }
          if (rowValues == null) continue;
          if (colIdx < rowValues.length) {
            final val = rowValues[colIdx];
            if (val.compareTo(targetVal) == 0) {
              toDelete.add(_DeleteTarget(pageId, slotId, rowValues));
            }
          }
        }
      }
      db.cache.unpinPageSync(rowTable.filePath, pageId, isDirty: false);
    }

    for (final target in toDelete) {
      rowTable.deleteRecordSync(target.pageId, target.slotId, currentTxId);

      // Update statistics
      final stats = db.catalog.getOrCreateStats(schema.name);
      stats.rowCount = (stats.rowCount > 0) ? stats.rowCount - 1 : 0;

      // Cascade delete recursively for each column of the deleted row
      for (int k = 0; k < schema.columnNames.length; k++) {
        _cascadeDeleteSync(schema.name, schema.columnNames[k], target.rowValues[k], currentTxId, visitedTables);
      }
    }
  }


  dynamic _executeSelect(SelectStmt stmt) {
    if (!db.catalog.hasPrivilege(currentUser, stmt.tableName, 'select')) {
      throw Exception("Permission denied: SELECT privilege required on table '${stmt.tableName}' for user '$currentUser'.");
    }
    if (stmt.join != null) {
      if (!db.catalog.hasPrivilege(currentUser, stmt.join!.tableName, 'select')) {
        throw Exception("Permission denied: SELECT privilege required on table '${stmt.join!.tableName}' for user '$currentUser'.");
      }
    }
    _flushDelayedIndexUpdates();
    final tableName = stmt.tableName.toLowerCase();
    final schema = db.catalog.getTableSchema(tableName);
    
    if (schema != null &&
        !schema.isColumnar &&
        stmt.whereCondition != null &&
        stmt.join == null &&
        stmt.withRelationship == null &&
        stmt.groupBy == null &&
        !_hasAggregate(stmt.projections)) {
      final cond = stmt.whereCondition;
      if (cond is BinaryExpr && cond.operator == '=' && cond.left is VariableExpr) {
        final varExpr = cond.left as VariableExpr;
        if (varExpr.path.length == 1 || varExpr.path.first.toLowerCase() == tableName) {
          final colName = varExpr.path.last.toLowerCase();
        
          final idx = db.catalog.getIndexForColumn(tableName, colName);
          if (idx != null) {
            if (cond.right is LiteralExpr) {
              final val = (cond.right as LiteralExpr).value;
              final double? searchKey = val is num ? val.toDouble() : null;
              if (searchKey != null) {
                final indexName = idx.name.toLowerCase();
                final indexFile = '${db.directory}/$indexName.idx';
                final btree = db.getOrInitIndexSync(indexName);
                final ptr = btree.searchSync([searchKey]);
                
                if (ptr != null) {
                  final rowTable = RowTableFile(cache: db.cache, tableName: schema.name, dbDirectory: db.directory);
                  final page = db.cache.pinPageSync(rowTable.filePath, ptr.pageId);
                  final recBytes = SlottedPageHelper.getRecord(page, ptr.slotId);
                  
                  final rows = <List<DbValue>>[];
                  if (recBytes != null) {
                    List<DbValue>? fullRow;
                    try {
                      final mvccRecord = MvccRecord.fromBytes(recBytes);
                      final currentTx = db.cache.currentMvccTx;
                      final txManager = db.cache.mvccTxManager;
                      final currentTxId = currentTx?.txId ?? 0;
                      final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
                      if (txManager.isVisible(mvccRecord.xmin, mvccRecord.xmax, currentTxId, activeTxIds)) {
                        fullRow = RecordSerializer.deserializeRow(mvccRecord.rowData);
                      }
                    } catch (_) {
                      fullRow = RecordSerializer.deserializeRow(recBytes);
                    }
                    if (fullRow != null) {
                      final rowContext = <String, DbValue>{};
                      for (int i = 0; i < schema.columnNames.length; i++) {
                        rowContext['${schema.name}.${schema.columnNames[i]}'] = fullRow[i];
                        rowContext[schema.columnNames[i]] = fullRow[i];
                      }

                      final projectedRow = <DbValue>[];
                      final columns = <String>[];
                      var localProjections = stmt.projections;
                      if (localProjections.length == 1 &&
                          localProjections[0].expr is VariableExpr &&
                          (localProjections[0].expr as VariableExpr).path.first == '*') {
                        localProjections = schema.columnNames.map((colName) {
                          return Projection(VariableExpr([colName]), null);
                        }).toList();
                      }
                      for (final proj in localProjections) {
                        final pVal = evaluateExpression(proj.expr, rowContext);
                        projectedRow.add(pVal);
                        columns.add(proj.alias ?? (proj.expr is VariableExpr ? (proj.expr as VariableExpr).fullName : pVal.toString()));
                      }
                      rows.add(projectedRow);
                      db.cache.unpinPageSync(rowTable.filePath, ptr.pageId, isDirty: false);
                      return QueryResult(columns: columns, rows: rows, message: "Index scan completed successfully.");
                    }
                  }
                  db.cache.unpinPageSync(rowTable.filePath, ptr.pageId, isDirty: false);
                }
              }
            }
          }
        }
      }
    }

    // Volcano execution
    final planNode = db.planner.planSelect(stmt);

    bool hasParallel(PlanNode node) {
      if (node is ParallelScanNode) return true;
      if (node is FilterNode) return hasParallel(node.child);
      if (node is ProjectNode) return hasParallel(node.child);
      if (node is GroupByNode) return hasParallel(node.child);
      if (node is SortNode) return hasParallel(node.child);
      if (node is LimitNode) return hasParallel(node.child);
      if (node is HashJoinNode) return hasParallel(node.left) || hasParallel(node.right);
      if (node is IndexJoinNode) return hasParallel(node.left);
      if (node is GraphJoinNode) return hasParallel(node.left);
      return false;
    }

    if (hasParallel(planNode)) {
      return () async {
        Future<void> initParallelNodes(PlanNode node) async {
          if (node is ParallelScanNode) {
            await node.executeParallelScan();
          } else if (node is FilterNode) {
            await initParallelNodes(node.child);
          } else if (node is ProjectNode) {
            await initParallelNodes(node.child);
          } else if (node is GroupByNode) {
            await initParallelNodes(node.child);
          } else if (node is SortNode) {
            await initParallelNodes(node.child);
          } else if (node is LimitNode) {
            await initParallelNodes(node.child);
          } else if (node is HashJoinNode) {
            await initParallelNodes(node.left);
            await initParallelNodes(node.right);
          } else if (node is IndexJoinNode) {
            await initParallelNodes(node.left);
          } else if (node is GraphJoinNode) {
            await initParallelNodes(node.left);
          }
        }

        db.cache.flushAllSync();
        await initParallelNodes(planNode);
        planNode.open();

        final rows = <List<DbValue>>[];
        List<String> columns = [];
        bool colsInitialized = false;

        while (true) {
          final row = planNode.next();
          if (row == null) break;

          if (!colsInitialized) {
            columns = row.keys.toList();
            colsInitialized = true;
          }
          final rowCells = <DbValue>[];
          for (final col in columns) {
            rowCells.add(row[col] ?? DbNull());
          }
          rows.add(rowCells);
        }

        planNode.close();
        return QueryResult(
          columns: columns,
          rows: rows,
          message: "${rows.length} rows returned.",
        );
      }();
    } else {
      planNode.open();

      final rows = <List<DbValue>>[];
      List<String> columns = [];
      bool colsInitialized = false;

      while (true) {
        final row = planNode.next();
        if (row == null) break;

        if (!colsInitialized) {
          columns = row.keys.toList();
          colsInitialized = true;
        }
        final rowCells = <DbValue>[];
        for (final col in columns) {
          rowCells.add(row[col] ?? DbNull());
        }
        rows.add(rowCells);
      }

      planNode.close();
      return QueryResult(
        columns: columns,
        rows: rows,
        message: "${rows.length} rows returned.",
      );
    }
  }


  void _executeAssign(AssignStmt stmt) {
    if (!_env.containsKey(stmt.varName)) {
      throw Exception("Variable '${stmt.varName}' is not declared.");
    }
    final fn = _jitCache.putIfAbsent(stmt.expr, () => JitCompiler.compile(stmt.expr));
    _env[stmt.varName] = fn(_env);
  }


  void _executeDbmsOutput(DbmsOutputStmt stmt) {
    final fn = _jitCache.putIfAbsent(stmt.expr, () => JitCompiler.compile(stmt.expr));
    final val = fn(_env);
    dbmsOutputLog.add(val.toString());
  }

  QueryResult _executeShowTables() {
    final cols = ['table_name', 'columns', 'type'];
    final rows = <List<DbValue>>[];
    
    db.catalog.getTablesInternal().forEach((name, schema) {
      rows.add([
        DbText(schema.name),
        DbText(schema.columnNames.join(', ')),
        DbText(schema.isColumnar ? 'Columnar' : 'Row'),
      ]);
    });
    
    return QueryResult(
      columns: cols,
      rows: rows,
      message: "${rows.length} tables found.",
    );
  }

  QueryResult _executeShowIndexes(ShowIndexesStmt stmt) {
    final cols = ['index_name', 'table_name', 'column_name', 'type'];
    final rows = <List<DbValue>>[];
    
    final indexes = stmt.tableName != null
        ? db.catalog.getIndexesForTable(stmt.tableName!)
        : db.catalog.getAllIndexes();
        
    for (final idx in indexes) {
      rows.add([
        DbText(idx.name),
        DbText(idx.tableName),
        DbText(idx.columnName),
        DbText('B+ Tree'),
      ]);
    }
    
    return QueryResult(
      columns: cols,
      rows: rows,
      message: "${rows.length} indexes found.",
    );
  }

  Future<QueryResult> _executeCreateIndex(CreateIndexStmt stmt) async {
    final indexName = stmt.name.toLowerCase();
    final tableName = stmt.tableName.toLowerCase();
    final colName = stmt.columnName.toLowerCase();

    if (db.catalog.hasIndex(indexName)) {
      throw Exception("Index '$indexName' already exists.");
    }

    final schema = db.catalog.getTableSchema(tableName);
    if (schema == null) {
      throw Exception("Table '$tableName' does not exist.");
    }

    // Verify columns exist
    final indexCols = colName.split(',');
    final colIndexes = <int>[];
    for (final col in indexCols) {
      final colClean = col.trim();
      final cIdx = schema.columnNamesLower.indexOf(colClean);
      if (cIdx == -1) {
        throw Exception("Column '$colClean' does not exist in table '$tableName'.");
      }
      colIndexes.add(cIdx);
    }

    if (schema.isColumnar && stmt.usingMethod != 'hnsw') {
      throw Exception("B+ Tree indexes are not supported on columnar tables.");
    }

    // Register index schema
    final idxSchema = IndexSchema(
      name: stmt.name,
      tableName: stmt.tableName,
      columnName: stmt.columnName,
      usingMethod: stmt.usingMethod,
    );
    db.catalog.addIndex(idxSchema, saveToFile: true);

    if (stmt.usingMethod == 'hnsw') {
      final indexFile = '${db.directory}/$indexName.hnsw';
      final hnsw = HnswIndex(indexPath: indexFile, autoSave: false);
      final colIdx = colIndexes[0];
      
      if (schema.isColumnar) {
        final colTable = ColumnTableFile(
          cache: db.cache,
          tableName: schema.name,
          dbDirectory: db.directory,
          schema: schema,
        );
        final colFilePath = colTable.getColumnFilePath(colIdx);
        final pager = db.cache.getOrCreatePager(colFilePath);
        final pageCount = pager.getPageCountSync();
        for (int pageId = 0; pageId < pageCount; pageId++) {
          final page = db.cache.pinPageSync(colFilePath, pageId);
          final byteData = page.byteData;
          final rowCount = byteData.getUint16(1);
          for (int slotId = 0; slotId < rowCount; slotId++) {
            final slotOffset = 5 + slotId * 4;
            final recordOffset = byteData.getUint16(slotOffset);
            final recordLen = byteData.getUint16(slotOffset + 2);
            if (recordLen == 0 || recordOffset >= 4096) continue;
            final recBytes = SlottedPageHelper.getRecord(page, slotId);
            if (recBytes != null) {
              final data = ByteData.sublistView(recBytes);
              final val = DbValue.fromBytes(data, 0, recBytes.length);
              if (val is DbVector) {
                hnsw.insertSync(val, pageId, slotId);
              }
            }
          }
          db.cache.unpinPageSync(colFilePath, pageId, isDirty: false);
        }
      } else {
        final rowTable = RowTableFile(cache: db.cache, tableName: schema.name, dbDirectory: db.directory);
        final pager = db.cache.getOrCreatePager(rowTable.filePath);
        final pageCount = pager.getPageCountSync();
        for (int pageId = 0; pageId < pageCount; pageId++) {
          final page = db.cache.pinPageSync(rowTable.filePath, pageId);
          final byteData = page.byteData;
          final rowCount = byteData.getUint16(1);
          for (int slotId = 0; slotId < rowCount; slotId++) {
            final slotOffset = 5 + slotId * 4;
            final recordOffset = byteData.getUint16(slotOffset);
            final recordLen = byteData.getUint16(slotOffset + 2);
            if (recordLen == 0 || recordOffset >= 4096) continue;
            final recBytes = SlottedPageHelper.getRecord(page, slotId);
            if (recBytes != null) {
              final rowValues = RecordSerializer.deserializeRow(recBytes);
              if (colIdx < rowValues.length) {
                final val = rowValues[colIdx];
                if (val is DbVector) {
                  hnsw.insertSync(val, pageId, slotId);
                }
              }
            }
          }
          db.cache.unpinPageSync(rowTable.filePath, pageId, isDirty: false);
        }
      }
      hnsw.saveSync();
      return QueryResult(columns: [], rows: [], message: "HNSW Vector Index '$indexName' created successfully.");
    }

    // Initialize index file
    final indexFile = '${db.directory}/$indexName.idx';
    final btree = BTreeIndex(cache: db.cache, indexPath: indexFile, keyColumns: indexCols.length);
    btree.initSync();
    
    // Scan table and populate index for existing rows
    final swTotal = Stopwatch()..start();
    final rowTable = RowTableFile(cache: db.cache, tableName: schema.name, dbDirectory: db.directory);
    final pager = db.cache.getOrCreatePager(rowTable.filePath);
    final pageCount = pager.getPageCountSync();

    final K = indexCols.length;

    final stats = db.catalog.getOrCreateStats(tableName);
    int totalRowCount = stats.rowCount;
    if (totalRowCount <= 0 && pageCount > 0) {
      totalRowCount = pageCount * 100;
    }

    var keys = Float64List(totalRowCount * K);
    var pageIds = Int32List(totalRowCount);
    var slotIds = Int32List(totalRowCount);

    int destIdx = 0;
    final schemaLen = schema.columnNames.length;

    final swExtract = Stopwatch()..start();
    if (K == 1) {
      final colIndex = colIndexes[0];
      for (int pageId = 0; pageId < pageCount; pageId++) {
        final page = db.cache.pinPageSync(rowTable.filePath, pageId);
        final byteData = page.byteData;
        final rowCount = byteData.getUint16(1);

        for (int slotId = 0; slotId < rowCount; slotId++) {
          final slotOffset = 5 + slotId * 4;
          final recordOffset = byteData.getUint16(slotOffset);
          final recordLen = byteData.getUint16(slotOffset + 2);

          if (recordLen == 0 || recordOffset >= 4096) continue;

          int rowStartOffset = recordOffset;
          int rowLength = recordLen;

          if (recordLen >= 12) {
            final countAt12 = byteData.getUint16(recordOffset + 12);
            if (countAt12 == schemaLen) {
              rowStartOffset = recordOffset + 12;
              rowLength = recordLen - 12;
            }
          }

          final count = byteData.getUint16(rowStartOffset);
          if (colIndex >= count) continue;

          final startOffset = byteData.getUint16(rowStartOffset + 2 + colIndex * 2);
          final endOffset = (colIndex + 1 < count)
              ? byteData.getUint16(rowStartOffset + 2 + (colIndex + 1) * 2)
              : rowLength;

          final len = endOffset - startOffset;
          if (len <= 0) continue;

          final cellPageOffset = rowStartOffset + startOffset;
          final typeCode = byteData.getUint8(cellPageOffset);
          double? dKey;
          if (typeCode == 1) {
            final valLen = len - 1;
            if (valLen == 1) {
              dKey = byteData.getInt8(cellPageOffset + 1).toDouble();
            } else if (valLen == 2) {
              dKey = byteData.getInt16(cellPageOffset + 1).toDouble();
            } else if (valLen == 4) {
              dKey = byteData.getInt32(cellPageOffset + 1).toDouble();
            } else if (valLen == 8) {
              dKey = byteData.getInt64(cellPageOffset + 1).toDouble();
            }
          } else if (typeCode == 2) {
            dKey = byteData.getFloat64(cellPageOffset + 1);
          } else if (typeCode == 3) {
            final valOffset = cellPageOffset + 1;
            final valLen = len - 1;
            final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes + valOffset, valLen);
            final str = utf8.decode(bytes);
            final parsed = double.tryParse(str);
            if (parsed != null) {
              dKey = parsed;
            } else {
              double hash = 0.0;
              for (int j = 0; j < str.length; j++) {
                hash = (hash * 31.0 + str.codeUnitAt(j)) % 9007199254740991;
              }
              dKey = hash;
            }
          }

          if (dKey != null) {
            if (destIdx >= totalRowCount) {
              final newSize = (totalRowCount * 1.5).toInt() + 100;
              final newKeys = Float64List(newSize);
              newKeys.setRange(0, destIdx, keys);
              final newPageIds = Int32List(newSize);
              newPageIds.setRange(0, destIdx, pageIds);
              final newSlotIds = Int32List(newSize);
              newSlotIds.setRange(0, destIdx, slotIds);
              keys = newKeys;
              pageIds = newPageIds;
              slotIds = newSlotIds;
              totalRowCount = newSize;
            }
            keys[destIdx] = dKey;
            pageIds[destIdx] = pageId;
            slotIds[destIdx] = slotId;
            destIdx++;
          }
        }
        db.cache.unpinPageSync(rowTable.filePath, pageId, isDirty: false);
      }
    } else {
      final compositeKey = List<double>.filled(K, 0.0);
      for (int pageId = 0; pageId < pageCount; pageId++) {
        final page = db.cache.pinPageSync(rowTable.filePath, pageId);
        final byteData = page.byteData;
        final rowCount = byteData.getUint16(1);

        for (int slotId = 0; slotId < rowCount; slotId++) {
          final slotOffset = 5 + slotId * 4;
          final recordOffset = byteData.getUint16(slotOffset);
          final recordLen = byteData.getUint16(slotOffset + 2);

          if (recordLen == 0 || recordOffset >= 4096) continue;

          int rowStartOffset = recordOffset;
          int rowLength = recordLen;

          if (recordLen >= 12) {
            final countAt12 = byteData.getUint16(recordOffset + 12);
            if (countAt12 == schemaLen) {
              rowStartOffset = recordOffset + 12;
              rowLength = recordLen - 12;
            }
          }

          final count = byteData.getUint16(rowStartOffset);
          bool hasAllKeys = true;
          for (int i = 0; i < K; i++) {
            final cIdx = colIndexes[i];
            if (cIdx == -1 || cIdx >= count) {
              hasAllKeys = false;
              break;
            }

            final startOffset = byteData.getUint16(rowStartOffset + 2 + cIdx * 2);
            final endOffset = (cIdx + 1 < count)
                ? byteData.getUint16(rowStartOffset + 2 + (cIdx + 1) * 2)
                : rowLength;

            final len = endOffset - startOffset;
            if (len <= 0) {
              hasAllKeys = false;
              break;
            }

            final cellPageOffset = rowStartOffset + startOffset;
            final typeCode = byteData.getUint8(cellPageOffset);
            double? dKey;
            if (typeCode == 1) {
              final valLen = len - 1;
              if (valLen == 1) {
                dKey = byteData.getInt8(cellPageOffset + 1).toDouble();
              } else if (valLen == 2) {
                dKey = byteData.getInt16(cellPageOffset + 1).toDouble();
              } else if (valLen == 4) {
                dKey = byteData.getInt32(cellPageOffset + 1).toDouble();
              } else if (valLen == 8) {
                dKey = byteData.getInt64(cellPageOffset + 1).toDouble();
              }
            } else if (typeCode == 2) {
              dKey = byteData.getFloat64(cellPageOffset + 1);
            } else if (typeCode == 3) {
              final valOffset = cellPageOffset + 1;
              final valLen = len - 1;
              final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes + valOffset, valLen);
              final str = utf8.decode(bytes);
              final parsed = double.tryParse(str);
              if (parsed != null) {
                dKey = parsed;
              } else {
                double hash = 0.0;
                for (int j = 0; j < str.length; j++) {
                  hash = (hash * 31.0 + str.codeUnitAt(j)) % 9007199254740991;
                }
                dKey = hash;
              }
            }

            if (dKey == null) {
              hasAllKeys = false;
              break;
            }
            compositeKey[i] = dKey;
          }

          if (hasAllKeys) {
            if (destIdx >= totalRowCount) {
              final newSize = (totalRowCount * 1.5).toInt() + 100;
              final newKeys = Float64List(newSize * K);
              newKeys.setRange(0, destIdx * K, keys);
              final newPageIds = Int32List(newSize);
              newPageIds.setRange(0, destIdx, pageIds);
              final newSlotIds = Int32List(newSize);
              newSlotIds.setRange(0, destIdx, slotIds);
              keys = newKeys;
              pageIds = newPageIds;
              slotIds = newSlotIds;
              totalRowCount = newSize;
            }
            for (int i = 0; i < K; i++) {
              keys[destIdx * K + i] = compositeKey[i];
            }
            pageIds[destIdx] = pageId;
            slotIds[destIdx] = slotId;
            destIdx++;
          }
        }
        db.cache.unpinPageSync(rowTable.filePath, pageId, isDirty: false);
      }
    }
    swExtract.stop();
    print('--> TIME: Extracting keys took: ${swExtract.elapsedMilliseconds}ms');

    final swSort = Stopwatch()..start();
    final actualRowCount = destIdx;
    final finalKeys = actualRowCount == totalRowCount ? keys : (K == 1 ? Float64List.sublistView(keys, 0, actualRowCount) : Float64List.sublistView(keys, 0, actualRowCount * K));
    final finalPageIds = actualRowCount == totalRowCount ? pageIds : Int32List.sublistView(pageIds, 0, actualRowCount);
    final finalSlotIds = actualRowCount == totalRowCount ? slotIds : Int32List.sublistView(slotIds, 0, actualRowCount);

    final indices = Int32List(actualRowCount);
    for (int i = 0; i < actualRowCount; i++) {
      indices[i] = i;
    }

    if (K == 1) {
      _quickSort1(indices, finalKeys, finalPageIds, finalSlotIds, 0, actualRowCount - 1);
    } else {
      _quickSortK(indices, finalKeys, finalPageIds, finalSlotIds, K, 0, actualRowCount - 1);
    }
    swSort.stop();
    print('--> TIME: Sorting indices took: ${swSort.elapsedMilliseconds}ms');

    totalRowCount = actualRowCount;
    print('Calling btree.insertSortedBatchSync with actualRowCount = $actualRowCount');

    final swBtree = Stopwatch()..start();
    btree.insertSortedBatchSync(finalKeys, finalPageIds, finalSlotIds, K, indices: indices);
    swBtree.stop();
    print('--> TIME: B-Tree insertSortedBatchSync took: ${swBtree.elapsedMilliseconds}ms');
    swTotal.stop();
    print('--> TIME: TOTAL CREATE INDEX took: ${swTotal.elapsedMilliseconds}ms');


    final cStats = stats.columnStats.putIfAbsent(colName, () => MinMaxStats());

    int distinctCount = 0;
    if (totalRowCount > 0) {
      distinctCount = 1;
      if (K == 1) {
        for (int i = 1; i < totalRowCount; i++) {
          if (finalKeys[indices[i]] != finalKeys[indices[i - 1]]) {
            distinctCount++;
          }
        }
      } else {
        for (int i = 1; i < totalRowCount; i++) {
          final idxCurr = indices[i];
          final idxPrev = indices[i - 1];
          bool diff = false;
          for (int k = 0; k < K; k++) {
            if (finalKeys[idxCurr * K + k] != finalKeys[idxPrev * K + k]) {
              diff = true;
              break;
            }
          }
          if (diff) {
            distinctCount++;
          }
        }
      }
    }

    cStats.distinctCount += distinctCount;
    if (totalRowCount > 0) {
      final minVal = finalKeys[indices[0] * K];
      final maxVal = finalKeys[indices[totalRowCount - 1] * K];
      if (cStats.min == null || minVal < cStats.min!) cStats.min = minVal;
      if (cStats.max == null || maxVal > cStats.max!) cStats.max = maxVal;
    }

    stats.rowCount = totalRowCount;
    final indexedCount = totalRowCount;

    return QueryResult(
      columns: [],
      rows: [],
      message: "Index '${stmt.name}' created successfully on '$tableName($colName)' ($indexedCount rows indexed).",
    );
  }

  QueryResult _executePlSqlBlockSync(PlSqlBlock block) {
    for (final decl in block.declarations) {
      DbValue initialVal = DbNull();
      if (decl.initialValue != null) {
        final fn = _jitCache.putIfAbsent(decl.initialValue!, () => JitCompiler.compile(decl.initialValue!));
        initialVal = fn(_env);
        if (initialVal is! DbNull && initialVal.type != decl.type) {
          if (decl.type == DataType.double && initialVal is DbInt) {
            initialVal = DbDouble(initialVal.value.toDouble());
          } else {
            throw Exception("Type mismatch in declaration of '${decl.name}'. Expected ${decl.type}, found ${initialVal.type}.");
          }
        }
      }
      _env[decl.name] = initialVal;
    }

    QueryResult? lastResult;
    for (final stmt in block.body) {
      final res = _executeNodeSync(stmt);
      if (res is Future) {
        throw Exception("Asynchronous operations are not supported inside PL/SQL blocks.");
      }
      if (res is QueryResult) {
        lastResult = res;
      }
    }

    return lastResult ?? QueryResult(
      columns: [],
      rows: [],
      message: "PL/SQL block executed successfully.",
    );
  }

  void _executeIfSync(IfStmt stmt) {
    final condFn = _jitCache.putIfAbsent(stmt.condition, () => JitCompiler.compile(stmt.condition));
    final cond = condFn(_env);
    if (cond is DbInt && cond.value == 1) {
      for (final s in stmt.thenBranch) {
        final res = _executeNodeSync(s);
        if (res is Future) {
          throw Exception("Asynchronous operations are not supported inside IF branches.");
        }
      }
      return;
    }

    for (final branch in stmt.elsifBranches) {
      final elsifCondFn = _jitCache.putIfAbsent(branch.condition, () => JitCompiler.compile(branch.condition));
      final elsifCond = elsifCondFn(_env);
      if (elsifCond is DbInt && elsifCond.value == 1) {
        for (final s in branch.body) {
          final res = _executeNodeSync(s);
          if (res is Future) {
            throw Exception("Asynchronous operations are not supported inside ELSIF branches.");
          }
        }
        return;
      }
    }

    if (stmt.elseBranch != null) {
      for (final s in stmt.elseBranch!) {
        final res = _executeNodeSync(s);
        if (res is Future) {
          throw Exception("Asynchronous operations are not supported inside ELSE branches.");
        }
      }
    }
  }

  void _executeWhileSync(WhileStmt stmt) {
    final condFn = _jitCache.putIfAbsent(stmt.condition, () => JitCompiler.compile(stmt.condition));
    while (true) {
      final cond = condFn(_env);
      if (cond is DbInt && cond.value == 1) {
        for (final s in stmt.body) {
          final res = _executeNodeSync(s);
          if (res is Future) {
            throw Exception("Asynchronous operations are not supported inside WHILE loops.");
          }
        }
      } else {
        break;
      }
    }
  }

  void _flushDelayedIndexUpdates() {
    if (_delayedIndexUpdates.isEmpty) return;
    final grouped = <String, List<_IndexUpdate>>{};
    for (final update in _delayedIndexUpdates) {
      grouped.putIfAbsent(update.indexName, () => []).add(update);
    }
    for (final entry in grouped.entries) {
      final indexName = entry.key;
      final btree = db.getOrInitIndexSync(indexName);
      final updates = entry.value;
      
      // Check if updates are already sorted (common for sequential auto-increment keys)
      bool isSorted = true;
      for (int i = 0; i < updates.length - 1; i++) {
        final a = updates[i].key;
        final b = updates[i + 1].key;
        final len = a.length < b.length ? a.length : b.length;
        int cmp = 0;
        for (int j = 0; j < len; j++) {
          cmp = a[j].compareTo(b[j]);
          if (cmp != 0) break;
        }
        if (cmp == 0) {
          cmp = a.length.compareTo(b.length);
        }
        if (cmp > 0) {
          isSorted = false;
          break;
        }
      }
      if (!isSorted) {
        updates.sort((a, b) {
          final len = a.key.length < b.key.length ? a.key.length : b.key.length;
          for (int i = 0; i < len; i++) {
            final cmp = a.key[i].compareTo(b.key[i]);
            if (cmp != 0) return cmp;
          }
          return a.key.length.compareTo(b.key.length);
        });
      }

      // Check if index is safe for batch loading
      bool canUseBatch = false;
      if (updates.isNotEmpty && updates[0].key.isNotEmpty) {
        btree.initSync();
        final minNewKey = updates[0].key[0];
        if (btree.isSafeForBatch(minNewKey)) {
          canUseBatch = true;
        }
      }

      if (canUseBatch) {
        final stats = db.catalog.getOrCreateStats(updates[0].tableName);
        final cStats = stats.columnStats.putIfAbsent(updates[0].columnName, () => MinMaxStats());

        final K = updates[0].key.length;
        final keys = Float64List(updates.length * K);
        final pageIds = Int32List(updates.length);
        final slotIds = Int32List(updates.length);

        int distinctCountDelta = 0;
        List<double>? lastKey;

        for (int i = 0; i < updates.length; i++) {
          final u = updates[i];
          for (int k = 0; k < K; k++) {
            keys[i * K + k] = u.key[k];
          }
          pageIds[i] = u.pageId;
          slotIds[i] = u.slotId;

          if (lastKey == null || !_areKeysEqual(lastKey, u.key)) {
            distinctCountDelta++;
            lastKey = u.key;
          }
        }

        btree.insertSortedBatchSync(keys, pageIds, slotIds, K);

        cStats.distinctCount += distinctCountDelta;
        if (updates.isNotEmpty && updates.first.key.isNotEmpty) {
          final minVal = updates.first.key[0];
          final maxVal = updates.last.key[0];
          if (cStats.min == null || minVal < cStats.min!) cStats.min = minVal;
          if (cStats.max == null || maxVal > cStats.max!) cStats.max = maxVal;
        }
      } else {
        for (final u in updates) {
          final isNewKey = btree.insertSync(u.key, u.pageId, u.slotId);
          if (isNewKey) {
            final stats = db.catalog.getOrCreateStats(u.tableName);
            final cStats = stats.columnStats.putIfAbsent(u.columnName, () => MinMaxStats());
            cStats.distinctCount++;
            if (u.key.isNotEmpty) {
              final keyVal = u.key[0];
              if (cStats.min == null || keyVal < cStats.min!) cStats.min = keyVal;
              if (cStats.max == null || keyVal > cStats.max!) cStats.max = keyVal;
            }
          }
        }
      }
    }
    _flushActiveTablePages();
    _delayedIndexUpdates.clear();
  }

  void _flushActiveTablePages() {
    for (final table in _rowTableCache.values) {
      table.flushActivePageSync();
    }
    db.cache.logAllDirtyPagesToWalSync();
  }

  QueryResult _executeExplain(ExplainStmt stmt) {
    _flushDelayedIndexUpdates();
    final plan = db.planner.planSelect(stmt.selectStmt);
    final planStr = plan.getPlanString();
    return QueryResult(
      columns: ['QUERY PLAN'],
      rows: [[DbText(planStr)]],
      message: 'Explain plan generated successfully.',
    );
  }

  QueryResult _executeAnalyze(AnalyzeStmt stmt) {
    final tableName = stmt.tableName.toLowerCase();
    final schema = db.catalog.getTableSchema(tableName);
    if (schema == null) {
      throw Exception("Table '$tableName' does not exist.");
    }
    if (schema.isColumnar) {
      throw Exception("Analyze is not supported on columnar tables.");
    }

    final stats = db.catalog.getOrCreateStats(schema.name);
    stats.rowCount = 0;
    stats.columnStats.clear();

    final rowTable = _rowTableCache.putIfAbsent(tableName, () => RowTableFile(
      cache: db.cache,
      tableName: schema.name,
      dbDirectory: db.directory,
    ));

    final pager = db.cache.getOrCreatePager(rowTable.filePath);
    final pageCount = pager.getPageCountSync();

    final Map<int, Set<DbValue>> colValues = {};
    for (int i = 0; i < schema.columnNames.length; i++) {
      colValues[i] = <DbValue>{};
    }

    final currentTx = db.cache.currentMvccTx;
    final currentTxId = currentTx?.txId ?? 0;
    final activeTxIds = currentTx?.activeTxIds ?? const <int>{};
    final txManager = db.cache.mvccTxManager;

    for (int pageId = 0; pageId < pageCount; pageId++) {
      final page = db.cache.pinPageSync(rowTable.filePath, pageId);
      final rowCount = SlottedPageHelper.getRowCount(page);
      for (int slotId = 0; slotId < rowCount; slotId++) {
        final recBytes = SlottedPageHelper.getRecord(page, slotId);
        if (recBytes != null) {
          List<DbValue>? rowValues;
          try {
            final mvccRecord = MvccRecord.fromBytes(recBytes);
            if (txManager.isVisible(mvccRecord.xmin, mvccRecord.xmax, currentTxId, activeTxIds)) {
              rowValues = RecordSerializer.deserializeRow(mvccRecord.rowData);
            }
          } catch (_) {
            rowValues = RecordSerializer.deserializeRow(recBytes);
          }

          if (rowValues != null) {
            stats.rowCount++;
            for (int i = 0; i < schema.columnNames.length; i++) {
              if (i < rowValues.length) {
                final val = rowValues[i];
                if (val is! DbNull) {
                  colValues[i]!.add(val);
                }
              }
            }
          }
        }
      }
      db.cache.unpinPageSync(rowTable.filePath, pageId, isDirty: false);
    }

    // Now populate MinMaxStats
    for (int i = 0; i < schema.columnNames.length; i++) {
      final colName = schema.columnNames[i].toLowerCase();
      final vals = colValues[i]!;
      if (vals.isNotEmpty) {
        final cStats = MinMaxStats();
        cStats.distinctCount = vals.length;
        
        double? minVal;
        double? maxVal;
        for (final val in vals) {
          final rawVal = val.value;
          if (rawVal is num) {
            final dVal = rawVal.toDouble();
            if (minVal == null || dVal < minVal) minVal = dVal;
            if (maxVal == null || dVal > maxVal) maxVal = dVal;
          }
        }
        cStats.min = minVal;
        cStats.max = maxVal;
        stats.columnStats[colName] = cStats;
      }
    }

    db.catalog.save();

    return QueryResult(
      columns: ['status'],
      rows: [[DbText('SUCCESS')]],
      message: "Analyzed table '$tableName'. Row count: ${stats.rowCount}.",
    );
  }
}

class _IndexUpdate {
  final String indexName;
  final String tableName;
  final String columnName;
  final List<double> key;
  final int pageId;
  final int slotId;

  _IndexUpdate({
    required this.indexName,
    required this.tableName,
    required this.columnName,
    required this.key,
    required this.pageId,
    required this.slotId,
  });
}

  bool _hasAggregate(List<Projection> projections) {
    for (final proj in projections) {
      if (_hasAggregateExpr(proj.expr)) return true;
    }
    return false;
  }

  bool _hasAggregateExpr(Expression expr) {
    if (expr is FunctionCallExpr) {
      final name = expr.name.toLowerCase();
      if (name == 'count' || name == 'sum' || name == 'avg' || name == 'min' || name == 'max') {
        return true;
      }
    }
    if (expr is BinaryExpr) {
      return _hasAggregateExpr(expr.left) || _hasAggregateExpr(expr.right);
    }
    return false;
  }

DbVector? _parseVectorFromString(String s) {
  final trimmed = s.trim();
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    final body = trimmed.substring(1, trimmed.length - 1).trim();
    if (body.isEmpty) return DbVector([]);
    try {
      final elements = body.split(',').map((e) => double.parse(e.trim())).toList();
      return DbVector(elements);
    } catch (_) {
      return null;
    }
  }
  return null;
}

class _DeleteTarget {
  final int pageId;
  final int slotId;
  final List<DbValue> rowValues;
  _DeleteTarget(this.pageId, this.slotId, this.rowValues);
}

void _insertionSort1(Int32List indices, Float64List keys, Int32List pageIds, Int32List slotIds, int left, int right) {
  for (int i = left + 1; i <= right; i++) {
    final tempIdx = indices[i];
    final tempKey = keys[tempIdx];
    final tempPage = pageIds[tempIdx];
    final tempSlot = slotIds[tempIdx];
    
    int j = i - 1;
    while (j >= left) {
      final idxJ = indices[j];
      final kJ = keys[idxJ];
      
      bool isJGreaterThanTemp = false;
      if (kJ > tempKey) {
        isJGreaterThanTemp = true;
      } else if (kJ == tempKey) {
        final pJ = pageIds[idxJ];
        if (pJ > tempPage) {
          isJGreaterThanTemp = true;
        } else if (pJ == tempPage) {
          if (slotIds[idxJ] > tempSlot) {
            isJGreaterThanTemp = true;
          }
        }
      }
      
      if (!isJGreaterThanTemp) break;
      indices[j + 1] = indices[j];
      j--;
    }
    indices[j + 1] = tempIdx;
  }
}

void _quickSort1(Int32List indices, Float64List keys, Int32List pageIds, Int32List slotIds, int left, int right) {
  if (left >= right) return;
  if (right - left <= 15) {
    _insertionSort1(indices, keys, pageIds, slotIds, left, right);
    return;
  }

  final center = (left + right) >> 1;
  if (keys[indices[left]] > keys[indices[center]]) {
    _swap(indices, left, center);
  }
  if (keys[indices[left]] > keys[indices[right]]) {
    _swap(indices, left, right);
  }
  if (keys[indices[center]] > keys[indices[right]]) {
    _swap(indices, center, right);
  }

  final pivotIdx = indices[center];
  final pivotKey = keys[pivotIdx];
  final pivotPage = pageIds[pivotIdx];
  final pivotSlot = slotIds[pivotIdx];

  int i = left;
  int j = right;
  while (i <= j) {
    while (true) {
      final idx = indices[i];
      final k = keys[idx];
      if (k < pivotKey) { i++; continue; }
      if (k > pivotKey) break;
      final p = pageIds[idx];
      if (p < pivotPage) { i++; continue; }
      if (p > pivotPage) break;
      if (slotIds[idx] < pivotSlot) { i++; continue; }
      break;
    }
    while (true) {
      final idx = indices[j];
      final k = keys[idx];
      if (k > pivotKey) { j--; continue; }
      if (k < pivotKey) break;
      final p = pageIds[idx];
      if (p > pivotPage) { j--; continue; }
      if (p < pivotPage) break;
      if (slotIds[idx] > pivotSlot) { j--; continue; }
      break;
    }
    if (i <= j) {
      final temp = indices[i];
      indices[i] = indices[j];
      indices[j] = temp;
      i++;
      j--;
    }
  }
  if (left < j) _quickSort1(indices, keys, pageIds, slotIds, left, j);
  if (i < right) _quickSort1(indices, keys, pageIds, slotIds, i, right);
}

void _quickSortK(Int32List indices, Float64List keys, Int32List pageIds, Int32List slotIds, int K, int left, int right) {
  if (left >= right) return;

  final center = (left + right) >> 1;
  if (_compareK(indices[left], indices[center], keys, pageIds, slotIds, K) > 0) {
    _swap(indices, left, center);
  }
  if (_compareK(indices[left], indices[right], keys, pageIds, slotIds, K) > 0) {
    _swap(indices, left, right);
  }
  if (_compareK(indices[center], indices[right], keys, pageIds, slotIds, K) > 0) {
    _swap(indices, center, right);
  }

  final pivotIdx = indices[center];
  int i = left;
  int j = right;
  while (i <= j) {
    while (_compareK(indices[i], pivotIdx, keys, pageIds, slotIds, K) < 0) {
      i++;
    }
    while (_compareK(indices[j], pivotIdx, keys, pageIds, slotIds, K) > 0) {
      j--;
    }
    if (i <= j) {
      final temp = indices[i];
      indices[i] = indices[j];
      indices[j] = temp;
      i++;
      j--;
    }
  }
  if (left < j) _quickSortK(indices, keys, pageIds, slotIds, K, left, j);
  if (i < right) _quickSortK(indices, keys, pageIds, slotIds, K, i, right);
}

int _compareK(int idxA, int idxB, Float64List keys, Int32List pageIds, Int32List slotIds, int K) {
  for (int k = 0; k < K; k++) {
    final cmp = keys[idxA * K + k].compareTo(keys[idxB * K + k]);
    if (cmp != 0) return cmp;
  }
  final cmpPage = pageIds[idxA].compareTo(pageIds[idxB]);
  if (cmpPage != 0) return cmpPage;
  return slotIds[idxA].compareTo(slotIds[idxB]);
}

void _swap(Int32List indices, int i, int j) {
  final temp = indices[i];
  indices[i] = indices[j];
  indices[j] = temp;
}

