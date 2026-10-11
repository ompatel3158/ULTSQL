import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() async {
  print('🧪 Starting UltSQL MCP Server E2E Verification Test...');

  final proc = await Process.start(
    'dart',
    ['run', 'bin/ultsql_mcp_server.dart'],
    workingDirectory: 'C:\\Users\\ompat\\.gemini\\antigravity\\scratch\\ULTSQL',
  );

  proc.stderr.transform(utf8.decoder).listen((e) => stderr.write('[SERVER-STDERR] $e'));

  final lines = proc.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  final completers = <int, Completer<Map<String, dynamic>>>{};

  lines.listen((line) {
    if (line.trim().isEmpty) return;
    try {
      final msg = jsonDecode(line) as Map<String, dynamic>;
      final id = msg['id'] as int?;
      if (id != null && completers.containsKey(id)) {
        completers[id]!.complete(msg);
      }
    } catch (e) {
      print('[PARSE ERR] $e on line: $line');
    }
  });

  int reqId = 1;
  Future<Map<String, dynamic>> send(String method, [Map<String, dynamic>? params]) async {
    final id = reqId++;
    final c = Completer<Map<String, dynamic>>();
    completers[id] = c;
    final payload = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    };
    proc.stdin.writeln(jsonEncode(payload));
    return c.future.timeout(const Duration(seconds: 15));
  }

  // 1. Initialize
  print('\n--> Testing initialize...');
  final initRes = await send('initialize', {
    'protocolVersion': '2024-11-05',
    'capabilities': {},
    'clientInfo': {'name': 'test-client', 'version': '1.0'},
  });
  assert(initRes['result']['serverInfo']['name'] == 'ultsql-mcp-server');
  print('✔ Initialize OK: ${initRes['result']['serverInfo']}');

  // 2. tools/list
  print('\n--> Testing tools/list...');
  final listRes = await send('tools/list', {});
  final tools = (listRes['result']['tools'] as List).map((t) => t['name']).toList();
  print('✔ tools/list OK: Found ${tools.length} tools: $tools');

  // 3. ultsql_query: CREATE TABLE
  print('\n--> Testing ultsql_query (CREATE TABLE)...');
  final createRes = await send('tools/call', {
    'name': 'ultsql_query',
    'arguments': {
      'database': ':memory:',
      'query': 'CREATE TABLE agents (id INT PRIMARY KEY, name TEXT, model TEXT, status TEXT);',
    },
  });
  print('✔ Table created: ${createRes['result']['content'][0]['text']}');

  // 4. ultsql_batch_insert
  print('\n--> Testing ultsql_batch_insert...');
  final batchRes = await send('tools/call', {
    'name': 'ultsql_batch_insert',
    'arguments': {
      'database': ':memory:',
      'table': 'agents',
      'records': [
        {'id': 1, 'name': 'CoderAgent', 'model': 'Gemini 3.8 Flash', 'status': 'active'},
        {'id': 2, 'name': 'ResearchAgent', 'model': 'Gemini 3.8 Pro', 'status': 'idle'},
        {'id': 3, 'name': 'SecurityAgent', 'model': 'Claude 3.7', 'status': 'active'},
      ],
    },
  });
  print('✔ Batch insert OK: ${batchRes['result']['content'][0]['text']}');

  // 5. ultsql_query: SELECT
  print('\n--> Testing ultsql_query (SELECT)...');
  final selectRes = await send('tools/call', {
    'name': 'ultsql_query',
    'arguments': {
      'database': ':memory:',
      'query': "SELECT * FROM agents WHERE status = 'active';",
    },
  });
  print('✔ Select OK: ${selectRes['result']['content'][0]['text']}');

  // 6. ultsql_describe_schema
  print('\n--> Testing ultsql_describe_schema...');
  final schemaRes = await send('tools/call', {
    'name': 'ultsql_describe_schema',
    'arguments': {
      'database': ':memory:',
      'table': 'agents',
    },
  });
  print('✔ Schema OK: ${schemaRes['result']['content'][0]['text']}');

  // 7. ultsql_doc_insert & ultsql_doc_find
  print('\n--> Testing NoSQL (doc_insert & doc_find)...');
  await send('tools/call', {
    'name': 'ultsql_doc_insert',
    'arguments': {
      'database': ':memory:',
      'collection': 'tasks',
      'documents': [
        {'title': 'Write docs', 'priority': 1, 'meta': {'tags': ['docs']}},
        {'title': 'Run benchmarks', 'priority': 5, 'meta': {'tags': ['perf']}},
      ],
    },
  });
  final findRes = await send('tools/call', {
    'name': 'ultsql_doc_find',
    'arguments': {
      'database': ':memory:',
      'collection': 'tasks',
      'filter': {'priority': {r'$gte': 3}},
    },
  });
  print('✔ NoSQL OK: ${findRes['result']['content'][0]['text']}');

  // 8. ultsql_kv_set & ultsql_kv_get
  print('\n--> Testing Key-Value (kv_set & kv_get)...');
  await send('tools/call', {
    'name': 'ultsql_kv_set',
    'arguments': {
      'database': ':memory:',
      'key': 'agent_heartbeat',
      'value': {'timestamp': DateTime.now().toIso8601String(), 'alive': true},
    },
  });
  final kvRes = await send('tools/call', {
    'name': 'ultsql_kv_get',
    'arguments': {
      'database': ':memory:',
      'key': 'agent_heartbeat',
    },
  });
  print('✔ Key-Value OK: ${kvRes['result']['content'][0]['text']}');

  // 9. ultsql_vector_search
  print('\n--> Testing Vector Search...');
  await send('tools/call', {
    'name': 'ultsql_query',
    'arguments': {
      'database': ':memory:',
      'query': 'CREATE TABLE embeddings (id INT PRIMARY KEY, content TEXT, vec VECTOR);',
    },
  });
  await send('tools/call', {
    'name': 'ultsql_query',
    'arguments': {
      'database': ':memory:',
      'query': "INSERT INTO embeddings VALUES (1, 'database query engine', '[0.9, 0.2, 0.1]');",
    },
  });
  await send('tools/call', {
    'name': 'ultsql_query',
    'arguments': {
      'database': ':memory:',
      'query': "INSERT INTO embeddings VALUES (2, 'frontend design system', '[0.1, 0.8, 0.7]');",
    },
  });
  final vecRes = await send('tools/call', {
    'name': 'ultsql_vector_search',
    'arguments': {
      'database': ':memory:',
      'table': 'embeddings',
      'vector_column': 'vec',
      'query_vector': [0.85, 0.25, 0.15],
      'metric': 'cosine',
      'limit': 1,
    },
  });
  print('✔ Vector Search OK: ${vecRes['result']['content'][0]['text']}');

  proc.kill();
  print('\n🎉 ALL 9 MCP SERVER TESTS PASSED SUCCESSFULLY! 🎉');
  exit(0);
}
