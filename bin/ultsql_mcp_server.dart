import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ultsql/ultsql.dart';

/// Active databases cache by directory/path
final Map<String, Database> _databases = {};
final Map<String, Interpreter> _interpreters = {};

Future<Database> _getDatabase(String? path, {String? passphrase}) async {
  final target = (path == null || path.trim().isEmpty) ? ':memory:' : path.trim();
  if (_databases.containsKey(target)) {
    return _databases[target]!;
  }

  final db = Database(target, passphrase: passphrase);
  await db.init();
  _databases[target] = db;
  _interpreters[target] = Interpreter(db);
  return db;
}

Interpreter _getInterpreter(String target, Database db) {
  return _interpreters.putIfAbsent(target, () => Interpreter(db));
}

dynamic _dbValueToPrimitive(DbValue v) {
  if (v is DbNull) return null;
  if (v is DbInt) return v.value;
  if (v is DbDouble) return v.value;
  if (v is DbText) return v.value;
  if (v is DbBool) return v.value;
  if (v is DbVector) return v.value;
  if (v is DbJson) return v.value;
  if (v is DbBlob) return v.value;
  if (v is DbUuid) return v.value;
  if (v is DbDateTime) return v.value.toIso8601String();
  if (v is DbDecimal) return v.value;
  return v.value;
}

Future<void> main(List<String> args) async {
  // Ensure stderr is used for any internal logs so stdout remains clean JSON-RPC
  stderr.writeln('🚀 Starting UltSQL Model Context Protocol (MCP) Server v$ultSqlVersion...');

  // Handle graceful shutdown
  void cleanup() async {
    for (final db in _databases.values) {
      try {
        await db.close();
      } catch (_) {}
    }
  }

  ProcessSignal.sigint.watch().listen((_) async {
    cleanup();
    exit(0);
  });

  final inputStream = stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  await for (final line in inputStream) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    try {
      final message = jsonDecode(trimmed);
      if (message is! Map<String, dynamic>) continue;
      await _handleRpcMessage(message);
    } catch (e, stack) {
      stderr.writeln('Error processing message: $e\n$stack');
      _sendRpcError(null, -32700, 'Parse error: ${e.toString()}');
    }
  }

  cleanup();
}

Future<void> _handleRpcMessage(Map<String, dynamic> msg) async {
  final id = msg['id'];
  final method = msg['method'] as String?;

  // Notification (no ID)
  if (id == null) {
    if (method == 'notifications/initialized') {
      stderr.writeln('✔ Client initialized successfully.');
    }
    return;
  }

  switch (method) {
    case 'initialize':
      _sendRpcResult(id, {
        'protocolVersion': '2024-11-05',
        'capabilities': {
          'tools': {},
        },
        'serverInfo': {
          'name': 'ultsql-mcp-server',
          'version': ultSqlVersion,
          'title': 'UltSQL Pure-Dart Multimodal Database MCP Server',
        },
      });
      break;

    case 'ping':
      _sendRpcResult(id, {});
      break;

    case 'tools/list':
      _sendRpcResult(id, {
        'tools': _getToolDefinitions(),
      });
      break;

    case 'tools/call':
      final params = msg['params'] as Map<String, dynamic>? ?? {};
      final toolName = params['name'] as String?;
      final arguments = params['arguments'] as Map<String, dynamic>? ?? {};
      await _handleToolCall(id, toolName, arguments);
      break;

    default:
      _sendRpcError(id, -32601, 'Method not found: $method');
      break;
  }
}

List<Map<String, dynamic>> _getToolDefinitions() {
  return [
    {
      'name': 'ultsql_query',
      'description':
          'Executes an ANSI SQL query, DDL, DML, or PL/SQL procedural block against UltSQL. Supports CTEs, Window functions, JOINs, aggregations, transactions, and vector distance functions.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'The SQL query or PL/SQL script to execute.',
          },
          'database': {
            'type': 'string',
            'description':
                'Database directory path or ":memory:". Defaults to ":memory:".',
          },
          'passphrase': {
            'type': 'string',
            'description': 'Optional encryption passphrase for AES-256 databases.',
          },
        },
        'required': ['query'],
      },
    },
    {
      'name': 'ultsql_describe_schema',
      'description':
          'Introspects tables, views, columns, types, primary keys, and row counts in the UltSQL database.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'database': {
            'type': 'string',
            'description': 'Database directory path or ":memory:". Defaults to ":memory:".',
          },
          'table': {
            'type': 'string',
            'description': 'Optional specific table name to inspect in detail.',
          },
        },
      },
    },
    {
      'name': 'ultsql_batch_insert',
      'description':
          'High-throughput vector-fast batch ingestion (up to 700K+ rows/sec) into an existing table, bypassing SQL parser overhead directly into 4KB slotted pages.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'table': {
            'type': 'string',
            'description': 'Target table name.',
          },
          'records': {
            'type': 'array',
            'description': 'List of JSON row objects to insert, e.g. [{"id": 1, "name": "Alice"}].',
            'items': {'type': 'object'},
          },
          'database': {
            'type': 'string',
            'description': 'Database directory path or ":memory:". Defaults to ":memory:".',
          },
        },
        'required': ['table', 'records'],
      },
    },
    {
      'name': 'ultsql_doc_insert',
      'description':
          'Inserts one or more schema-less JSON documents into an UltSQL NoSQL collection (MongoDB-compatible).',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'collection': {
            'type': 'string',
            'description': 'NoSQL collection name.',
          },
          'documents': {
            'type': 'array',
            'description': 'Array of JSON objects to insert into the collection.',
            'items': {'type': 'object'},
          },
          'database': {
            'type': 'string',
            'description': 'Database directory path or ":memory:". Defaults to ":memory:".',
          },
        },
        'required': ['collection', 'documents'],
      },
    },
    {
      'name': 'ultsql_doc_find',
      'description':
          r'Queries an UltSQL NoSQL collection using MongoDB-style filter syntax, supporting dotted paths (e.g. "profile.city": "London") and comparison operators ($gte, $lte, $in, $eq, $ne).',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'collection': {
            'type': 'string',
            'description': 'NoSQL collection name.',
          },
          'filter': {
            'type': 'object',
            'description': 'Query filter object (defaults to {} matching all documents).',
          },
          'limit': {
            'type': 'integer',
            'description': 'Maximum number of documents to return.',
          },
          'skip': {
            'type': 'integer',
            'description': 'Number of documents to skip for pagination.',
          },
          'database': {
            'type': 'string',
            'description': 'Database directory path or ":memory:". Defaults to ":memory:".',
          },
        },
        'required': ['collection'],
      },
    },
    {
      'name': 'ultsql_kv_set',
      'description':
          'Sets a key-value pair in UltSQL\'s persistent in-memory Key-Value cache (Redis-style), with optional TTL.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'key': {
            'type': 'string',
            'description': 'Key name.',
          },
          'value': {
            'description': 'Value to store (scalar, array, or object).',
          },
          'ttl_seconds': {
            'type': 'integer',
            'description': 'Optional Time-To-Live in seconds.',
          },
          'database': {
            'type': 'string',
            'description': 'Database directory path or ":memory:". Defaults to ":memory:".',
          },
        },
        'required': ['key', 'value'],
      },
    },
    {
      'name': 'ultsql_kv_get',
      'description':
          'Retrieves a value from UltSQL\'s Key-Value store by key.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'key': {
            'type': 'string',
            'description': 'Key name to lookup.',
          },
          'database': {
            'type': 'string',
            'description': 'Database directory path or ":memory:". Defaults to ":memory:".',
          },
        },
        'required': ['key'],
      },
    },
    {
      'name': 'ultsql_vector_search',
      'description':
          'Performs AI vector similarity search (k-NN) using cosine, L2, or dot-product distance metrics, leveraging HNSW graph acceleration when indexed.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'table': {
            'type': 'string',
            'description': 'Table name containing the VECTOR column.',
          },
          'vector_column': {
            'type': 'string',
            'description': 'Name of the VECTOR column (e.g., "embedding").',
          },
          'query_vector': {
            'type': 'array',
            'description': 'Floating point numbers representing the query vector embedding.',
            'items': {'type': 'number'},
          },
          'metric': {
            'type': 'string',
            'description': 'Distance metric: "cosine", "l2", or "dot". Default: "cosine".',
            'enum': ['cosine', 'l2', 'dot'],
          },
          'limit': {
            'type': 'integer',
            'description': 'Maximum number of nearest neighbors to return. Default: 10.',
          },
          'where': {
            'type': 'string',
            'description': 'Optional SQL WHERE filter predicate for pre-filtering (e.g. "category = \'science\'").',
          },
          'database': {
            'type': 'string',
            'description': 'Database directory path or ":memory:". Defaults to ":memory:".',
          },
        },
        'required': ['table', 'vector_column', 'query_vector'],
      },
    },
    {
      'name': 'ultsql_explain',
      'description':
          'Analyzes query execution plan (Cost-Based Optimizer plan nodes and index scans) for an SQL query.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'SQL query to explain.',
          },
          'database': {
            'type': 'string',
            'description': 'Database directory path or ":memory:". Defaults to ":memory:".',
          },
        },
        'required': ['query'],
      },
    },
  ];
}

Future<void> _handleToolCall(
    dynamic id, String? name, Map<String, dynamic> args) async {
  try {
    final dbPath = (args['database'] as String?) ?? ':memory:';
    final passphrase = args['passphrase'] as String?;
    final db = await _getDatabase(dbPath, passphrase: passphrase);

    dynamic toolResult;

    switch (name) {
      case 'ultsql_query':
        toolResult = await _executeSql(db, dbPath, args['query'] as String);
        break;

      case 'ultsql_describe_schema':
        toolResult = _describeSchema(db, args['table'] as String?);
        break;

      case 'ultsql_batch_insert':
        final table = args['table'] as String;
        final records = (args['records'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        toolResult = _batchInsert(db, table, records);
        break;

      case 'ultsql_doc_insert':
        final collName = args['collection'] as String;
        final documents = (args['documents'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        toolResult = await _docInsert(db, collName, documents);
        break;

      case 'ultsql_doc_find':
        final collName = args['collection'] as String;
        final filter = args['filter'] as Map<String, dynamic>? ?? {};
        final limit = args['limit'] as int?;
        final skip = args['skip'] as int?;
        toolResult = await _docFind(db, collName, filter, limit: limit, skip: skip);
        break;

      case 'ultsql_kv_set':
        final key = args['key'] as String;
        final value = args['value'];
        final ttlSec = args['ttl_seconds'] as int?;
        toolResult = await _kvSet(db, key, value, ttlSec);
        break;

      case 'ultsql_kv_get':
        final key = args['key'] as String;
        toolResult = await _kvGet(db, key);
        break;

      case 'ultsql_vector_search':
        final table = args['table'] as String;
        final vecCol = args['vector_column'] as String;
        final queryVector = (args['query_vector'] as List).map((n) => (n as num).toDouble()).toList();
        final metric = (args['metric'] as String?) ?? 'cosine';
        final limit = (args['limit'] as int?) ?? 10;
        final where = args['where'] as String?;
        toolResult = await _vectorSearch(db, dbPath, table, vecCol, queryVector, metric, limit, where);
        break;

      case 'ultsql_explain':
        final query = args['query'] as String;
        toolResult = await _executeSql(db, dbPath, 'EXPLAIN QUERY PLAN $query');
        break;

      default:
        _sendToolError(id, 'Unknown tool: $name');
        return;
    }

    _sendToolSuccess(id, toolResult);
  } catch (e, stack) {
    stderr.writeln('Tool execution error ($name): $e\n$stack');
    _sendToolError(id, 'Execution error: $e');
  }
}

Future<Map<String, dynamic>> _executeSql(Database db, String target, String sql) async {
  final it = _getInterpreter(target, db);
  final sw = Stopwatch()..start();
  final res = await it.executeScript(sql);
  sw.stop();

  final rowsList = <Map<String, dynamic>>[];
  for (final row in res.rows) {
    final map = <String, dynamic>{};
    for (int i = 0; i < res.columns.length && i < row.length; i++) {
      map[res.columns[i]] = _dbValueToPrimitive(row[i]);
    }
    rowsList.add(map);
  }

  return {
    'columns': res.columns,
    'rows': rowsList,
    'rowCount': res.rows.length,
    'message': res.message,
    'executionTimeMs': sw.elapsedMicroseconds / 1000.0,
    if (res.dbmsOutputLog.isNotEmpty) 'dbmsOutput': res.dbmsOutputLog,
  };
}

Map<String, dynamic> _describeSchema(Database db, String? targetTable) {
  final catalog = db.catalog;
  final tables = catalog.tables;

  if (targetTable != null) {
    final schema = catalog.getTableSchema(targetTable);
    if (schema == null) {
      return {'error': 'Table "$targetTable" does not exist.'};
    }
    final stats = catalog.getOrCreateStats(targetTable);
    return {
      'table': targetTable,
      'rowCount': stats.rowCount,
      'isColumnar': schema.isColumnar,
      'columns': List.generate(schema.columnNames.length, (i) {
        return {
          'name': schema.columnNames[i],
          'type': schema.columnTypes[i].name,
          'primaryKey': schema.columnPrimaryKey[i],
          'unique': schema.columnUnique[i],
          'defaultValue': schema.columnDefaultValues[i]?.toString(),
        };
      }),
    };
  }

  final summary = <String, dynamic>{};
  for (final entry in tables.entries) {
    if (entry.key.startsWith('_coll_')) continue; // internal NoSQL tables
    final schema = entry.value;
    final stats = catalog.getOrCreateStats(entry.key);
    summary[entry.key] = {
      'rowCount': stats.rowCount,
      'isColumnar': schema.isColumnar,
      'columns': schema.columnNames.map((c) => c).toList(),
      'types': schema.columnTypes.map((t) => t.name).toList(),
    };
  }

  final collections = db.listCollections();

  return {
    'tables': summary,
    'noSqlCollections': collections,
  };
}

Map<String, dynamic> _batchInsert(Database db, String table, List<Map<String, dynamic>> records) {
  final sw = Stopwatch()..start();
  final res = db.insertBatchRecordsSync(table, records);
  sw.stop();
  final stats = db.catalog.getOrCreateStats(table);

  return {
    'inserted': records.length,
    'table': table,
    'totalRowCount': stats.rowCount,
    'message': res.message,
    'executionTimeMs': sw.elapsedMicroseconds / 1000.0,
    'throughputRowsSec': records.isNotEmpty && sw.elapsedMicroseconds > 0
        ? (records.length / (sw.elapsedMicroseconds / 1e6)).round()
        : 0,
  };
}

Future<Map<String, dynamic>> _docInsert(Database db, String collName, List<Map<String, dynamic>> documents) async {
  final coll = db.collection(collName);
  final sw = Stopwatch()..start();
  final inserted = await coll.insertMany(documents);
  sw.stop();

  return {
    'collection': collName,
    'insertedCount': inserted.length,
    'insertedIds': inserted.map((d) => d.id).toList(),
    'executionTimeMs': sw.elapsedMicroseconds / 1000.0,
  };
}

Future<Map<String, dynamic>> _docFind(
    Database db, String collName, Map<String, dynamic> filter, {int? limit, int? skip}) async {
  final coll = db.collection(collName);
  final sw = Stopwatch()..start();
  var cursor = coll.find(filter);
  if (skip != null) cursor = cursor.skip(skip);
  if (limit != null) cursor = cursor.limit(limit);
  final docs = await cursor.toList();
  sw.stop();

  return {
    'collection': collName,
    'matchedCount': docs.length,
    'documents': docs.map((d) => {'_id': d.id, ...d.data}).toList(),
    'executionTimeMs': sw.elapsedMicroseconds / 1000.0,
  };
}

Future<Map<String, dynamic>> _kvSet(Database db, String key, dynamic value, int? ttlSec) async {
  final ttl = ttlSec != null ? Duration(seconds: ttlSec) : null;
  await db.kv.set(key, value, ttl: ttl);
  return {
    'key': key,
    'status': 'OK',
    'ttlSeconds': ttlSec,
  };
}

Future<Map<String, dynamic>> _kvGet(Database db, String key) async {
  final exists = await db.kv.has(key);
  final value = exists ? await db.kv.get(key) : null;
  return {
    'key': key,
    'exists': exists,
    'value': value,
  };
}

Future<Map<String, dynamic>> _vectorSearch(Database db, String target, String table, String vecCol,
    List<double> queryVec, String metric, int limit, String? whereClause) async {
  final schema = db.catalog.getTableSchema(table);
  final cols = schema?.columnNames ?? [];
  final selectCols = cols.isNotEmpty ? '${cols.join(", ")}, ' : '';
  final vecLiteral = jsonEncode(queryVec);
  final where = (whereClause != null && whereClause.trim().isNotEmpty) ? 'WHERE $whereClause' : '';
  final sql = '''
SELECT $selectCols vector_distance($vecCol, '$vecLiteral', '$metric') AS distance
FROM $table
$where
ORDER BY distance ASC
LIMIT $limit;
''';
  return await _executeSql(db, target, sql);
}

void _sendToolSuccess(dynamic id, dynamic result) {
  _sendRpcResult(id, {
    'content': [
      {
        'type': 'text',
        'text': const JsonEncoder.withIndent('  ').convert(result),
      }
    ],
    'isError': false,
  });
}

void _sendToolError(dynamic id, String errorMessage) {
  _sendRpcResult(id, {
    'content': [
      {
        'type': 'text',
        'text': '❌ $errorMessage',
      }
    ],
    'isError': true,
  });
}

void _sendRpcResult(dynamic id, Map<String, dynamic> result) {
  final response = {
    'jsonrpc': '2.0',
    'id': id,
    'result': result,
  };
  stdout.writeln(jsonEncode(response));
}

void _sendRpcError(dynamic id, int code, String message) {
  final response = {
    'jsonrpc': '2.0',
    'id': id,
    'error': {
      'code': code,
      'message': message,
    },
  };
  stdout.writeln(jsonEncode(response));
}
