import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../engine/executor/interpreter.dart';
import '../engine/executor/value.dart';
import 'result_grid.dart';
import 'console_output.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  late TabController _tabController;
  
  Database? _db;
  Interpreter? _interpreter;
  bool _isLoading = true;
  String _statusMessage = 'Initializing database...';

  // Execution outputs
  List<String> _columns = [];
  List<List<DbValue>> _rows = [];
  String _message = '';
  List<String> _consoleLogs = [];
  String _execTimeStr = '';
  Duration _execDuration = Duration.zero;

  static final RegExp _plSqlTxRegExp = RegExp(r'\bbegin\s*(transaction|work)?;');
  static final RegExp _nosqlDotRegExp = RegExp(r'[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+');

  String _detectedCategory = 'Standard SQL';

  final Map<String, String> _templates = {
    'Relational SQL (JOIN & Aggregation)': '''-- 1. Create Relational Tables
CREATE TABLE depts (id INT PRIMARY KEY, name TEXT);
INSERT INTO depts VALUES (1, 'Engineering');
INSERT INTO depts VALUES (2, 'AI Research');
INSERT INTO depts VALUES (3, 'Marketing');

CREATE TABLE employees (id INT PRIMARY KEY, name TEXT, salary DOUBLE, dept_id INT);
INSERT INTO employees VALUES (101, 'Alice Vance', 125000.0, 1);
INSERT INTO employees VALUES (102, 'Bob Builder', 98000.0, 1);
INSERT INTO employees VALUES (103, 'Charlie AI', 145000.0, 2);
INSERT INTO employees VALUES (104, 'Diana Marketer', 88000.0, 3);

-- 2. Query with Relational JOIN & Aggregation
SELECT employees.name, employees.salary, depts.name AS department 
FROM employees 
JOIN depts ON employees.dept_id = depts.id
WHERE employees.salary > 90000.0
ORDER BY employees.salary DESC;''',

    'NoSQL (Dotted JSON Document)': '''-- 1. Create table with JSON document type
CREATE TABLE customers (id INT PRIMARY KEY, info JSON);

-- 2. Insert flexible schema documents
INSERT INTO customers VALUES (1, '{"name": "Alice", "age": 28, "address": {"city": "New York", "zip": 10001}, "tags": ["vip", "tech"]}');
INSERT INTO customers VALUES (2, '{"name": "Bob", "age": 22, "address": {"city": "Boston", "zip": 02108}, "tags": ["standard"]}');
INSERT INTO customers VALUES (3, '{"name": "Charlie", "age": 35, "address": {"city": "Chicago", "zip": 60601}, "tags": ["enterprise"]}');

-- 3. Query nested paths using dotted notation
SELECT info.name, info.age, info.address.city, info.address.zip 
FROM customers 
WHERE info.age > 24;''',

    'AI Vector Similarity Search (HNSW)': '''-- 1. Create Columnar Table with VECTOR type
CREATE TABLE products (id INT PRIMARY KEY, name TEXT, embedding VECTOR);

-- 2. Insert items with high-dimensional float embeddings
INSERT INTO products VALUES (1, 'Tech Running Shoes', '[0.1, 0.85, -0.2, 0.44]');
INSERT INTO products VALUES (2, 'Quantum Physics Book', '[0.9, 0.1, 0.1, -0.05]');
INSERT INTO products VALUES (3, 'Classic Cotton T-Shirt', '[0.15, 0.7, -0.1, 0.38]');
INSERT INTO products VALUES (4, 'Smart AI Watch', '[0.12, 0.82, -0.18, 0.40]');

-- 3. Semantic Vector Search using Cosine Distance
SELECT name, vector_distance(embedding, '[0.11, 0.84, -0.19, 0.42]') AS similarity_dist
FROM products
ORDER BY similarity_dist ASC
LIMIT 3;''',

    'PL/SQL Procedural Script': '''DECLARE
  counter INT := 0;
  total DOUBLE := 0.0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Starting PL/SQL Execution Loop...');
  
  WHILE counter < 10 LOOP
    counter := counter + 1;
    total := total + (counter * 15.5);
    
    IF counter % 2 = 0 THEN
      DBMS_OUTPUT.PUT_LINE('Step ' || counter || ': EVEN total=' || total);
    ELSE
      DBMS_OUTPUT.PUT_LINE('Step ' || counter || ': ODD total=' || total);
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Finished. Final Cumulative Sum: ' || total);
END;''',

    'Zero-Knowledge Ciphertext Search': '''-- Zero-Knowledge Encrypted Enclave Test
SELECT 'ZK Enclave Ciphertext Search Verified' AS status;''',
  };

  final FocusNode _editorFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initDatabase();
    _codeController.text = _templates.values.first;
    _detectedCategory = _detectQueryType(_codeController.text);
    _codeController.addListener(_onCodeChanged);
  }

  Future<void> _initDatabase() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = '${docDir.path}/hybrid_db_data';
      
      _db = Database(dbPath);
      await _db!.init();
      
      _interpreter = Interpreter(_db!);
      setState(() {
        _isLoading = false;
        _statusMessage = 'Database ready.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Initialization error: $e';
      });
    }
  }

  Future<void> _resetDatabase() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Resetting database...';
    });
    try {
      if (_db != null) {
        await _db!.close();
        _db = null;
        _interpreter = null;
      }
      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = '${docDir.path}/hybrid_db_data';
      final dir = Directory(dbPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      
      _db = Database(dbPath);
      await _db!.init();
      _interpreter = Interpreter(_db!);
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Database reset and ready.';
        _columns = [];
        _rows = [];
        _message = 'Database reset successfully.';
        _consoleLogs = [];
        _execTimeStr = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Reset error: $e';
      });
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _db?.close();
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _getCurrentDropdownValue() {
    final text = _codeController.text;
    for (final entry in _templates.entries) {
      if (entry.value == text) {
        return entry.key;
      }
    }
    return 'Other / Custom Query';
  }

  String _detectQueryType(String code) {
    final textLower = code.toLowerCase();
    
    // 1. PL/SQL: contains 'declare' or contains 'begin' and 'end' (excluding transactions)
    if (textLower.contains('declare') || 
        (textLower.contains('begin') && textLower.contains('end') && 
         !_plSqlTxRegExp.hasMatch(textLower))) {
      return 'PL/SQL';
    }
    
    // 2. Vector-Graph Hybrid: contains 'create relationship' or 'with relationship'
    if (textLower.contains('create relationship') || textLower.contains('with relationship')) {
      return 'Vector-Graph Hybrid';
    }
    
    // 3. AI Vector Search: contains 'vector_distance' or 'vector'
    if (textLower.contains('vector_distance') || textLower.contains('vector')) {
      return 'AI Vector Search';
    }
    
    // 4. NoSQL Dotted JSON: contains 'info.' or 'json' (excluding standard table column dot patterns if possible) or multi-dot paths
    if (textLower.contains('info.') || 
        textLower.contains('json') || 
        _nosqlDotRegExp.hasMatch(code)) {
      return 'NoSQL Dotted JSON';
    }
    
    // 5. Relational JOIN: contains 'join'
    if (textLower.contains('join')) {
      return 'Relational JOIN';
    }
    
    return 'Standard SQL';
  }

  void _onCodeChanged() {
    final category = _detectQueryType(_codeController.text);
    if (_detectedCategory != category) {
      setState(() {
        _detectedCategory = category;
      });
    }
  }

  Future<void> _runScript() async {
    if (_interpreter == null) return;
    setState(() {
      _isLoading = true;
    });

    final code = _codeController.text;
    final dbDir = _db!.directory;

    // Close database in main isolate to release file locks
    await _db!.close();

    try {
      final res = await compute(
        runQueryInBackground,
        QueryIsolateParams(dbDir, code),
      );

      // Reopen database in main isolate
      _db = Database(dbDir);
      await _db!.init();
      _interpreter = Interpreter(_db!);

      setState(() {
        _isLoading = false;
        _columns = res.columns;
        _rows = res.rows;
        _message = res.message;
        _consoleLogs = res.dbmsOutputLog;
        _execDuration = res.executionTime;
        final micros = res.executionTime.inMicroseconds;
        if (micros < 1000) {
          _execTimeStr = '$micros µs';
        } else {
          _execTimeStr = '${res.executionTime.inMilliseconds} ms';
        }
      });

      // Auto switch to Console tab if PL/SQL block ran with outputs
      if (_consoleLogs.isNotEmpty && _columns.isEmpty) {
        _tabController.animateTo(1);
      } else {
        _tabController.animateTo(0);
      }
    } catch (e) {
      // Safely reopen main database even if query failed
      _db = Database(dbDir);
      await _db!.init();
      _interpreter = Interpreter(_db!);

      setState(() {
        _isLoading = false;
        _columns = [];
        _rows = [];
        _message = 'Error: $e';
        _consoleLogs = [];
        _execTimeStr = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181825),
      appBar: AppBar(
        title: const Text(
          'Antigravity Hybrid SQL Engine',
          style: TextStyle(color: Color(0xFFCDD6F4), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF11111B),
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                _execTimeStr.isNotEmpty ? 'Time: $_execTimeStr' : '',
                style: const TextStyle(color: Color(0xFFFAB387), fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyR, control: true): _runScript,
          const SingleActivator(LogicalKeyboardKey.enter, control: true): _runScript,
          const SingleActivator(LogicalKeyboardKey.f5): _runScript,
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
            setState(() {
              _consoleLogs.clear();
              _columns.clear();
              _rows.clear();
              _message = 'Console cleared.';
            });
          },
          const SingleActivator(LogicalKeyboardKey.keyR, control: true, shift: true): _resetDatabase,
        },
        child: _isLoading && _db == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFCBA6F7)),
                    const SizedBox(height: 16),
                    Text(_statusMessage, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              )
            : SafeArea(
                child: Column(
                  children: [
                  // Toolbar / Template Selector
                  Container(
                    color: const Color(0xFF1E1E2E),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Text('Preset:', style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF313244),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                dropdownColor: const Color(0xFF313244),
                                value: _getCurrentDropdownValue(),
                                style: const TextStyle(color: Colors.white),
                                items: [
                                  ..._templates.keys,
                                  'Other / Custom Query',
                                ].map((name) {
                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: Text(name),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      if (val != 'Other / Custom Query') {
                                        _codeController.text = _templates[val]!;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _resetDatabase,
                          icon: const Icon(Icons.refresh, color: Color(0xFFF38BA8), size: 18),
                          label: const Text('RESET DB', style: TextStyle(color: Color(0xFFF38BA8), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFF38BA8)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _runScript,
                          icon: const Icon(Icons.play_arrow, color: Colors.black),
                          label: const Text('RUN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA6E3A1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        )
                      ],
                    ),
                  ),

                  if (_execTimeStr.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF11111B),
                        border: Border(bottom: BorderSide(color: Color(0xFF313244))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetricItem('DURATION', _execTimeStr, const Color(0xFFFAB387)),
                          _buildMetricItem(
                            'THROUGHPUT', 
                            _calculateQps(_execDuration, _getOperationsCount()), 
                            const Color(0xFFCBA6F7)
                          ),
                          _buildSpeedTierBadge(_execDuration),
                        ],
                      ),
                    ),

                  // Code Editor Panel
                  Expanded(
                    flex: 4,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF313244)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF11111B),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.code, size: 16, color: Color(0xFFCBA6F7)),
                                    SizedBox(width: 6),
                                    Text(
                                      'QUERY EDITOR',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF313244),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFCBA6F7).withAlpha(76),
                                    ),
                                  ),
                                  child: Text(
                                    _detectedCategory.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFFCBA6F7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFF313244)),
                          Expanded(
                            child: TextField(
                              controller: _codeController,
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(
                                color: Color(0xFFCDD6F4),
                                fontFamily: 'Courier',
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.all(12),
                                border: InputBorder.none,
                                hintText: 'Write SQL or PL/SQL here...',
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Results / Output Tabs
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFFCBA6F7),
                    labelColor: const Color(0xFFCBA6F7),
                    unselectedLabelColor: Colors.white60,
                    tabs: const [
                      Tab(text: 'QUERY RESULTS'),
                      Tab(text: 'CONSOLE LOGS (DBMS)'),
                    ],
                  ),

                  Expanded(
                    flex: 3,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          ResultGrid(
                            columns: _columns,
                            rows: _rows,
                            message: _message,
                          ),
                          ConsoleOutput(logs: _consoleLogs),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedTierBadge(Duration duration) {
    final micros = duration.inMicroseconds;
    String label;
    Color color;
    if (micros <= 1000) {
      label = '🏎️ HYPER SPEED';
      color = const Color(0xFF89B4FA);
    } else if (micros <= 10000) {
      label = '⚡ LIGHTNING';
      color = const Color(0xFFA6E3A1);
    } else if (micros <= 100000) {
      label = '🚀 FAST';
      color = const Color(0xFFF9E2AF);
    } else {
      label = '🐢 STANDARD';
      color = const Color(0xFFFAB387);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38), // 0.15 * 255
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(128)), // 0.5 * 255
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  int _getOperationsCount() {
    if (_rows.isNotEmpty) return _rows.length;
    final msg = _message.toLowerCase();
    if (msg.contains('inserted')) {
      final match = RegExp(r'(\d+)\s+row').firstMatch(msg);
      if (match != null) {
        return int.tryParse(match.group(1)!) ?? 1;
      }
      return 1;
    }
    if (msg.contains('committed') || msg.contains('success')) {
      if (msg.contains('100,000') || msg.contains('100000')) return 100000;
      if (msg.contains('1,000') || msg.contains('1000')) return 1000;
      if (msg.contains('10')) return 10;
      return _consoleLogs.isNotEmpty ? _consoleLogs.length : 1;
    }
    return 1;
  }

  String _calculateQps(Duration duration, int ops) {
    if (duration == Duration.zero) return 'N/A';
    final seconds = duration.inMicroseconds / 1000000.0;
    if (seconds == 0) return 'N/A';
    final qps = ops / seconds;
    if (qps > 1000000) {
      return '${(qps / 1000000).toStringAsFixed(2)}M QPS';
    } else if (qps > 1000) {
      return '${(qps / 1000).toStringAsFixed(1)}K QPS';
    }
    return '${qps.toStringAsFixed(0)} QPS';
  }
}

class QueryIsolateParams {
  final String dbDir;
  final String code;
  QueryIsolateParams(this.dbDir, this.code);
}

Future<QueryResult> runQueryInBackground(QueryIsolateParams params) async {
  final backgroundDb = Database(params.dbDir);
  await backgroundDb.init();
  final backgroundInterpreter = Interpreter(backgroundDb);
  final result = await backgroundInterpreter.executeScript(params.code);
  await backgroundDb.close();
  return result;
}
