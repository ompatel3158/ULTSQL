import 'dart:convert';
import 'dart:io';
import '../parser/ast.dart';
import '../parser/lexer.dart';
import '../parser/parser.dart';

class ProcedureSchema {
  final String name;
  final String sql;
  late final List<Parameter> params;
  late final List<Stmt> body;

  ProcedureSchema({required this.name, required this.sql}) {
    _parse();
  }

  void _parse() {
    final lexer = Lexer(sql);
    final tokens = lexer.tokenize();
    final parser = Parser(tokens);
    final stmt = parser.parse();
    if (stmt is CreateProcedureStmt) {
      params = stmt.params;
      body = stmt.body;
    } else {
      throw Exception("Invalid procedure SQL stored in catalog");
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sql': sql,
      };

  factory ProcedureSchema.fromJson(Map<String, dynamic> json) {
    return ProcedureSchema(name: json['name'], sql: json['sql']);
  }
}

class FunctionSchema {
  final String name;
  final String sql;
  late final List<Parameter> params;
  late final DataType returnType;
  late final List<Stmt> body;

  FunctionSchema({required this.name, required this.sql}) {
    _parse();
  }

  void _parse() {
    final lexer = Lexer(sql);
    final tokens = lexer.tokenize();
    final parser = Parser(tokens);
    final stmt = parser.parse();
    if (stmt is CreateFunctionStmt) {
      params = stmt.params;
      returnType = stmt.returnType;
      body = stmt.body;
    } else {
      throw Exception("Invalid function SQL stored in catalog");
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sql': sql,
      };

  factory FunctionSchema.fromJson(Map<String, dynamic> json) {
    return FunctionSchema(name: json['name'], sql: json['sql']);
  }
}

class TriggerSchema {
  final String name;
  final String timing; // BEFORE, AFTER
  final String event; // INSERT, UPDATE, DELETE
  final String tableName;
  final bool forEachRow;
  final String sql;
  
  late final List<VarDeclare> declarations;
  late final List<Stmt> body;

  TriggerSchema({
    required this.name,
    required this.timing,
    required this.event,
    required this.tableName,
    required this.forEachRow,
    required this.sql,
  }) {
    _parse();
  }

  void _parse() {
    final lexer = Lexer(sql);
    final tokens = lexer.tokenize();
    final parser = Parser(tokens);
    final stmt = parser.parse();
    if (stmt is CreateTriggerStmt) {
      declarations = stmt.declarations;
      body = stmt.body;
    } else {
      throw Exception("Invalid trigger SQL stored in catalog");
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'timing': timing,
        'event': event,
        'tableName': tableName,
        'forEachRow': forEachRow,
        'sql': sql,
      };

  factory TriggerSchema.fromJson(Map<String, dynamic> json) {
    return TriggerSchema(
      name: json['name'],
      timing: json['timing'],
      event: json['event'],
      tableName: json['tableName'],
      forEachRow: json['forEachRow'] ?? false,
      sql: json['sql'],
    );
  }
}

class PolicySchema {
  final String name;
  final Expression condition;

  PolicySchema({required this.name, required this.condition});

  Map<String, dynamic> toJson() => {
        'name': name,
        'condition': exprToSqlString(condition),
      };

  factory PolicySchema.fromJson(Map<String, dynamic> json) {
    final lexer = Lexer(json['condition']);
    final tokens = lexer.tokenize();
    final parser = Parser(tokens);
    final expr = parser.parseExpression();
    return PolicySchema(name: json['name'], condition: expr);
  }
}

class TableSchema {
  final String name;
  final List<String> columnNames;
  final List<DataType> columnTypes;
  final bool isColumnar;

  final List<bool> columnPrimaryKey;
  final List<bool> columnUnique;
  final List<String?> columnReferencesTable;
  final List<String?> columnReferencesColumn;
  final List<bool> columnOnDeleteCascade;
  final List<Expression?> columnDefaultValues;
  final List<Expression?> columnCheckExpressions;
  final List<PolicySchema> policies;
  final List<String?> columnMaskedWith;
  
  final bool isForeign;
  final String? foreignServer;
  final Map<String, String>? foreignOptions;

  final String? partitionByColumn;
  final String? partitionOfParent;
  final String? partitionFromValue;
  final String? partitionToValue;
  final List<String> partitionChildren;

  late final List<String> columnNamesLower;
  late final bool hasForeignKeys;

  late final bool hasUniqueOrPrimaryKey;

  TableSchema({
    required this.name,
    required this.columnNames,
    required this.columnTypes,
    this.isColumnar = false,
    List<bool>? columnPrimaryKey,
    List<bool>? columnUnique,
    List<String?>? columnReferencesTable,
    List<String?>? columnReferencesColumn,
    List<bool>? columnOnDeleteCascade,
    List<Expression?>? columnDefaultValues,
    List<Expression?>? columnCheckExpressions,
    List<PolicySchema>? policies,
    List<String?>? columnMaskedWith,
    this.isForeign = false,
    this.foreignServer,
    this.foreignOptions,
    this.partitionByColumn,
    this.partitionOfParent,
    this.partitionFromValue,
    this.partitionToValue,
    List<String>? partitionChildren,
  })  : columnPrimaryKey = columnPrimaryKey ?? List.filled(columnNames.length, false),
        columnUnique = columnUnique ?? List.filled(columnNames.length, false),
        columnReferencesTable = columnReferencesTable ?? List.filled(columnNames.length, null),
        columnReferencesColumn = columnReferencesColumn ?? List.filled(columnNames.length, null),
        columnOnDeleteCascade = columnOnDeleteCascade ?? List.filled(columnNames.length, false),
        columnDefaultValues = columnDefaultValues ?? List.filled(columnNames.length, null),
        columnCheckExpressions = columnCheckExpressions ?? List.filled(columnNames.length, null),
        policies = policies ?? [],
        columnMaskedWith = columnMaskedWith ?? List.filled(columnNames.length, null),
        partitionChildren = partitionChildren ?? [] {
    columnNamesLower = columnNames.map((c) => c.toLowerCase()).toList();
    columnIndexMap = {for (int i = 0; i < columnNamesLower.length; i++) columnNamesLower[i]: i};
    hasForeignKeys = this.columnReferencesTable.any((t) => t != null);
    hasUniqueOrPrimaryKey = this.columnPrimaryKey.any((b) => b) || this.columnUnique.any((b) => b);
  }

  late final Map<String, int> columnIndexMap;
  int getColumnIndex(String colName) => columnIndexMap[colName.toLowerCase()] ?? -1;

  TableSchema addColumn(ColumnDef col) {
    return TableSchema(
      name: name,
      columnNames: [...columnNames, col.name],
      columnTypes: [...columnTypes, col.type],
      isColumnar: isColumnar,
      columnPrimaryKey: [...columnPrimaryKey, col.isPrimaryKey],
      columnUnique: [...columnUnique, col.isUnique],
      columnReferencesTable: [...columnReferencesTable, col.referencesTable],
      columnReferencesColumn: [...columnReferencesColumn, col.referencesColumn],
      columnOnDeleteCascade: [...columnOnDeleteCascade, col.onDeleteCascade],
      columnDefaultValues: [...columnDefaultValues, col.defaultValue],
      columnCheckExpressions: [...columnCheckExpressions, col.checkExpression],
      policies: policies,
      columnMaskedWith: [...columnMaskedWith, col.maskedWith],
    );
  }

  TableSchema dropColumn(String colName) {
    final idx = columnNamesLower.indexOf(colName.toLowerCase());
    if (idx == -1) {
      throw Exception("Column '$colName' not found in table '$name'.");
    }
    final newNames = List<String>.from(columnNames)..removeAt(idx);
    final newTypes = List<DataType>.from(columnTypes)..removeAt(idx);
    final newPrimaryKey = List<bool>.from(columnPrimaryKey)..removeAt(idx);
    final newUnique = List<bool>.from(columnUnique)..removeAt(idx);
    final newReferencesTable = List<String?>.from(columnReferencesTable)..removeAt(idx);
    final newReferencesColumn = List<String?>.from(columnReferencesColumn)..removeAt(idx);
    final newOnDeleteCascade = List<bool>.from(columnOnDeleteCascade)..removeAt(idx);
    final newDefaultValues = List<Expression?>.from(columnDefaultValues)..removeAt(idx);
    final newCheckExpressions = List<Expression?>.from(columnCheckExpressions)..removeAt(idx);

    return TableSchema(
      name: name,
      columnNames: newNames,
      columnTypes: newTypes,
      isColumnar: isColumnar,
      columnPrimaryKey: newPrimaryKey,
      columnUnique: newUnique,
      columnReferencesTable: newReferencesTable,
      columnReferencesColumn: newReferencesColumn,
      columnOnDeleteCascade: newOnDeleteCascade,
      columnDefaultValues: newDefaultValues,
      columnCheckExpressions: newCheckExpressions,
      policies: policies,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'columnNames': columnNames,
        'columnTypes': columnTypes.map((t) => t.index).toList(),
        'isColumnar': isColumnar,
        'isForeign': isForeign,
        'foreignServer': foreignServer,
        'foreignOptions': foreignOptions,
        'columnPrimaryKey': columnPrimaryKey,
        'columnUnique': columnUnique,
        'columnReferencesTable': columnReferencesTable,
        'columnReferencesColumn': columnReferencesColumn,
        'columnOnDeleteCascade': columnOnDeleteCascade,
        'columnDefaultValues': columnDefaultValues.map((e) => e != null ? exprToSqlString(e) : null).toList(),
        'columnCheckExpressions': columnCheckExpressions.map((e) => e != null ? exprToSqlString(e) : null).toList(),
        'policies': policies.map((p) => p.toJson()).toList(),
        'partitionByColumn': partitionByColumn,
        'partitionOfParent': partitionOfParent,
        'partitionFromValue': partitionFromValue,
        'partitionToValue': partitionToValue,
        'partitionChildren': partitionChildren,
      };

  factory TableSchema.fromJson(Map<String, dynamic> json) {
    final names = List<String>.from(json['columnNames']);

    final defaultExprs = json.containsKey('columnDefaultValues')
        ? (json['columnDefaultValues'] as List).map((val) {
            if (val == null) return null;
            final lexer = Lexer(val as String);
            final tokens = lexer.tokenize();
            final parser = Parser(tokens);
            return parser.parseExpression();
          }).toList()
        : List<Expression?>.filled(names.length, null);

    final checkExprs = json.containsKey('columnCheckExpressions')
        ? (json['columnCheckExpressions'] as List).map((val) {
            if (val == null) return null;
            final lexer = Lexer(val as String);
            final tokens = lexer.tokenize();
            final parser = Parser(tokens);
            return parser.parseExpression();
          }).toList()
        : List<Expression?>.filled(names.length, null);

    return TableSchema(
      name: json['name'],
      columnNames: names,
      columnTypes: (json['columnTypes'] as List)
          .map((idx) => DataType.values[idx])
          .toList(),
      isColumnar: json['isColumnar'] ?? false,
      columnPrimaryKey: json.containsKey('columnPrimaryKey')
          ? List<bool>.from(json['columnPrimaryKey'])
          : null,
      columnUnique: json.containsKey('columnUnique')
          ? List<bool>.from(json['columnUnique'])
          : null,
      columnReferencesTable: json.containsKey('columnReferencesTable')
          ? List<String?>.from(json['columnReferencesTable'])
          : null,
      columnReferencesColumn: json.containsKey('columnReferencesColumn')
          ? List<String?>.from(json['columnReferencesColumn'])
          : null,
      columnOnDeleteCascade: json.containsKey('columnOnDeleteCascade')
          ? List<bool>.from(json['columnOnDeleteCascade'])
          : null,
      columnDefaultValues: defaultExprs,
      columnCheckExpressions: checkExprs,
      policies: json.containsKey('policies')
          ? (json['policies'] as List)
              .map((p) => PolicySchema.fromJson(p))
              .toList()
          : null,
      isForeign: json['isForeign'] ?? false,
      foreignServer: json['foreignServer'],
      foreignOptions: json['foreignOptions'] != null ? Map<String, String>.from(json['foreignOptions']) : null,
      partitionByColumn: json['partitionByColumn'],
      partitionOfParent: json['partitionOfParent'],
      partitionFromValue: json['partitionFromValue'],
      partitionToValue: json['partitionToValue'],
      partitionChildren: json['partitionChildren'] != null ? List<String>.from(json['partitionChildren']) : null,
    );
  }
}

class RelationshipSchema {
  final String name;
  final String fromTable;
  final String toTable;
  final String fromKey;
  final String toKey;

  RelationshipSchema({
    required this.name,
    required this.fromTable,
    required this.toTable,
    required this.fromKey,
    required this.toKey,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'fromTable': fromTable,
        'toTable': toTable,
        'fromKey': fromKey,
        'toKey': toKey,
      };

  factory RelationshipSchema.fromJson(Map<String, dynamic> json) => RelationshipSchema(
        name: json['name'],
        fromTable: json['fromTable'],
        toTable: json['toTable'],
        fromKey: json['fromKey'],
        toKey: json['toKey'],
      );
}

class IndexSchema {
  final String name;
  final String tableName;
  final String columnName;
  final String? usingMethod;

  IndexSchema({
    required this.name,
    required this.tableName,
    required this.columnName,
    this.usingMethod,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'tableName': tableName,
        'columnName': columnName,
        'usingMethod': usingMethod,
      };

  factory IndexSchema.fromJson(Map<String, dynamic> json) => IndexSchema(
        name: json['name'],
        tableName: json['tableName'],
        columnName: json['columnName'],
        usingMethod: json['usingMethod'],
      );
}

class Catalog {
  final String basePath;
  bool enableCBO = true;
  final Map<String, TableSchema> _tables = {};
  final Map<String, RelationshipSchema> _relationships = {};
  final Map<String, IndexSchema> _indexes = {};
  final Map<String, TableStats> _stats = {};
  final Map<String, List<IndexSchema>> _tableIndexesCache = {};
  final Map<String, Map<String, List<String>>> _permissions = {};
  final Map<String, ProcedureSchema> _procedures = {};
  final Map<String, FunctionSchema> _functions = {};
  final Map<String, TriggerSchema> _triggers = {};

  Catalog(this.basePath);

  ProcedureSchema? getProcedure(String name) => _procedures[name.toLowerCase()];
  bool hasProcedure(String name) => _procedures.containsKey(name.toLowerCase());

  void addProcedure(ProcedureSchema proc, {bool saveToFile = true}) {
    _procedures[proc.name.toLowerCase()] = proc;
    if (saveToFile) save();
  }

  FunctionSchema? getFunction(String name) => _functions[name.toLowerCase()];
  bool hasFunction(String name) => _functions.containsKey(name.toLowerCase());

  void addFunction(FunctionSchema func, {bool saveToFile = true}) {
    _functions[func.name.toLowerCase()] = func;
    if (saveToFile) save();
  }

  TriggerSchema? getTrigger(String name) => _triggers[name.toLowerCase()];
  bool hasTrigger(String name) => _triggers.containsKey(name.toLowerCase());

  void addTrigger(TriggerSchema trig, {bool saveToFile = true}) {
    _triggers[trig.name.toLowerCase()] = trig;
    if (saveToFile) save();
  }

  List<TriggerSchema> getTriggersForTable(String tableName, String timing, String event) {
    final tName = tableName.toLowerCase();
    final tim = timing.toUpperCase();
    final ev = event.toUpperCase();
    return _triggers.values
        .where((trig) => trig.tableName.toLowerCase() == tName &&
                         trig.timing.toUpperCase() == tim &&
                         trig.event.toUpperCase() == ev)
        .toList();
  }

  void grantPrivilege(String user, String tableName, String privilege) {
    final u = user.toLowerCase();
    final t = tableName.toLowerCase();
    final p = privilege.toLowerCase();
    final userMap = _permissions.putIfAbsent(u, () => {});
    final tablePrivs = userMap.putIfAbsent(t, () => []);
    if (!tablePrivs.contains(p)) {
      tablePrivs.add(p);
    }
    save();
  }

  void revokePrivilege(String user, String tableName, String privilege) {
    final u = user.toLowerCase();
    final t = tableName.toLowerCase();
    final p = privilege.toLowerCase();
    final userMap = _permissions[u];
    if (userMap != null) {
      final tablePrivs = userMap[t];
      if (tablePrivs != null) {
        tablePrivs.remove(p);
        if (tablePrivs.isEmpty) {
          userMap.remove(t);
        }
        if (userMap.isEmpty) {
          _permissions.remove(u);
        }
        save();
      }
    }
  }

  bool hasPrivilege(String user, String tableName, String privilege) {
    final u = user.toLowerCase();
    if (u == 'admin' || u == 'sa') return true;
    final t = tableName.toLowerCase();
    final p = privilege.toLowerCase();
    final userMap = _permissions[u];
    if (userMap == null) return false;
    final tablePrivs = userMap[t];
    if (tablePrivs == null) return false;
    return tablePrivs.contains(p) || tablePrivs.contains('all');
  }

  Map<String, dynamic> getBackupState() {
    return {
      'tables': Map<String, TableSchema>.from(_tables),
      'relationships': Map<String, RelationshipSchema>.from(_relationships),
      'indexes': Map<String, IndexSchema>.from(_indexes),
      'stats': Map<String, TableStats>.from(_stats),
      'procedures': Map<String, ProcedureSchema>.from(_procedures),
      'functions': Map<String, FunctionSchema>.from(_functions),
      'triggers': Map<String, TriggerSchema>.from(_triggers),
    };
  }

  void restoreBackupState(Map<String, dynamic> state) {
    _tableIndexesCache.clear();
    _tables.clear();
    if (state['tables'] != null) {
      final rawTables = state['tables'] as Map;
      rawTables.forEach((k, v) {
        if (v is TableSchema) {
          _tables[k.toString()] = v;
        } else if (v is Map) {
          _tables[k.toString()] = TableSchema.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }

    _relationships.clear();
    if (state['relationships'] != null) {
      final rawRels = state['relationships'] as Map;
      rawRels.forEach((k, v) {
        if (v is RelationshipSchema) {
          _relationships[k.toString()] = v;
        } else if (v is Map) {
          _relationships[k.toString()] = RelationshipSchema.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }

    _indexes.clear();
    if (state['indexes'] != null) {
      final rawIdx = state['indexes'] as Map;
      rawIdx.forEach((k, v) {
        if (v is IndexSchema) {
          _indexes[k.toString()] = v;
        } else if (v is Map) {
          _indexes[k.toString()] = IndexSchema.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }

    _stats.clear();
    if (state['stats'] != null) {
      final rawStats = state['stats'] as Map;
      rawStats.forEach((k, v) {
        if (v is TableStats) {
          _stats[k.toString()] = v;
        } else if (v is Map) {
          _stats[k.toString()] = TableStats.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }

    _procedures.clear();
    if (state['procedures'] != null) {
      final rawProcs = state['procedures'] as Map;
      rawProcs.forEach((k, v) {
        if (v is ProcedureSchema) {
          _procedures[k.toString()] = v;
        } else if (v is Map) {
          _procedures[k.toString()] = ProcedureSchema.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }

    _functions.clear();
    if (state['functions'] != null) {
      final rawFuncs = state['functions'] as Map;
      rawFuncs.forEach((k, v) {
        if (v is FunctionSchema) {
          _functions[k.toString()] = v;
        } else if (v is Map) {
          _functions[k.toString()] = FunctionSchema.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }

    _triggers.clear();
    if (state['triggers'] != null) {
      final rawTrigs = state['triggers'] as Map;
      rawTrigs.forEach((k, v) {
        if (v is TriggerSchema) {
          _triggers[k.toString()] = v;
        } else if (v is Map) {
          _triggers[k.toString()] = TriggerSchema.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }
  }

  TableStats? getTableStats(String name) => _stats[name.toLowerCase()];

  TableStats getOrCreateStats(String name) {
    return _stats.putIfAbsent(name.toLowerCase(), () => TableStats());
  }

  // Deprecated compatibility methods
  Map<String, TableSchema> getTablesInternal() => _tables;
  void restoreTablesInternal(Map<String, TableSchema> backup) {
    _tables.clear();
    _tables.addAll(backup);
  }

  String get _catalogPath => '$basePath/catalog.db';

  TableSchema? getTableSchema(String name) => _tables[name.toLowerCase()];
  bool hasTable(String name) => _tables.containsKey(name.toLowerCase());

  void addTable(TableSchema schema, {bool saveToFile = true}) {
    _tables[schema.name.toLowerCase()] = schema;
    if (saveToFile) save();
  }

  RelationshipSchema? getRelationship(String name) => _relationships[name.toLowerCase()];
  bool hasRelationship(String name) => _relationships.containsKey(name.toLowerCase());

  void addRelationship(RelationshipSchema rel, {bool saveToFile = true}) {
    _relationships[rel.name.toLowerCase()] = rel;
    if (saveToFile) save();
  }

  IndexSchema? getIndex(String name) => _indexes[name.toLowerCase()];
  bool hasIndex(String name) => _indexes.containsKey(name.toLowerCase());

  void addIndex(IndexSchema idx, {bool saveToFile = true}) {
    _indexes[idx.name.toLowerCase()] = idx;
    _tableIndexesCache.clear();
    if (saveToFile) save();
  }

  void removeIndex(String name, {bool saveToFile = true}) {
    _indexes.remove(name.toLowerCase());
    _tableIndexesCache.clear();
    if (saveToFile) save();
  }

  List<IndexSchema> getIndexesForTable(String tableName) {
    final tName = tableName.toLowerCase();
    return _tableIndexesCache.putIfAbsent(tName, () {
      return _indexes.values.where((idx) => idx.tableName.toLowerCase() == tName).toList();
    });
  }

  List<IndexSchema> getAllIndexes() => _indexes.values.toList();

  IndexSchema? getIndexForColumn(String tableName, String columnName) {
    final tName = tableName.toLowerCase();
    final cName = columnName.toLowerCase();
    for (final idx in _indexes.values) {
      if (idx.tableName.toLowerCase() == tName && idx.columnName.toLowerCase() == cName) {
        return idx;
      }
    }
    return null;
  }

  Future<void> load() async {
    final file = File(_catalogPath);
    if (!await file.exists()) return;
    try {
      final content = await file.readAsString();
      final Map<String, dynamic> jsonMap = json.decode(content);
      _tableIndexesCache.clear();
      _tables.clear();
      _relationships.clear();
      _indexes.clear();

      if (jsonMap.containsKey('tables')) {
        final tablesMap = jsonMap['tables'] as Map<String, dynamic>;
        tablesMap.forEach((key, val) {
          _tables[key.toLowerCase()] = TableSchema.fromJson(val);
        });
      } else {
        // Compatibility with older single-tier format
        jsonMap.forEach((key, val) {
          _tables[key.toLowerCase()] = TableSchema.fromJson(val);
        });
      }

      if (jsonMap.containsKey('relationships')) {
        final relsMap = jsonMap['relationships'] as Map<String, dynamic>;
        relsMap.forEach((key, val) {
          _relationships[key.toLowerCase()] = RelationshipSchema.fromJson(val);
        });
      }

      if (jsonMap.containsKey('indexes')) {
        final indexesMap = jsonMap['indexes'] as Map<String, dynamic>;
        indexesMap.forEach((key, val) {
          _indexes[key.toLowerCase()] = IndexSchema.fromJson(val);
        });
      }
      if (jsonMap.containsKey('stats')) {
        final statsMap = jsonMap['stats'] as Map<String, dynamic>;
        statsMap.forEach((key, val) {
          _stats[key.toLowerCase()] = TableStats.fromJson(val);
        });
      }
      _permissions.clear();
      if (jsonMap.containsKey('permissions')) {
        final permMap = jsonMap['permissions'] as Map<String, dynamic>;
        permMap.forEach((user, tables) {
          final userMap = <String, List<String>>{};
          (tables as Map<String, dynamic>).forEach((table, privs) {
            userMap[table] = List<String>.from(privs);
          });
          _permissions[user.toLowerCase()] = userMap;
        });
      }
      _procedures.clear();
      if (jsonMap.containsKey('procedures')) {
        final procsMap = jsonMap['procedures'] as Map<String, dynamic>;
        procsMap.forEach((key, val) {
          _procedures[key.toLowerCase()] = ProcedureSchema.fromJson(val);
        });
      }
      _functions.clear();
      if (jsonMap.containsKey('functions')) {
        final funcsMap = jsonMap['functions'] as Map<String, dynamic>;
        funcsMap.forEach((key, val) {
          _functions[key.toLowerCase()] = FunctionSchema.fromJson(val);
        });
      }
      _triggers.clear();
      if (jsonMap.containsKey('triggers')) {
        final trigsMap = jsonMap['triggers'] as Map<String, dynamic>;
        trigsMap.forEach((key, val) {
          _triggers[key.toLowerCase()] = TriggerSchema.fromJson(val);
        });
      }
    } catch (e) {
      // Catalog corrupt or empty, ignore
    }
  }

  void save() {
    final file = File(_catalogPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    final Map<String, dynamic> tablesMap = {};
    _tables.forEach((key, val) {
      tablesMap[key] = val.toJson();
    });
    final Map<String, dynamic> relsMap = {};
    _relationships.forEach((key, val) {
      relsMap[key] = val.toJson();
    });
    final Map<String, dynamic> indexesMap = {};
    _indexes.forEach((key, val) {
      indexesMap[key] = val.toJson();
    });
    final Map<String, dynamic> statsMap = {};
    _stats.forEach((key, val) {
      statsMap[key] = val.toJson();
    });
    final Map<String, dynamic> permissionsMap = {};
    _permissions.forEach((user, tables) {
      final Map<String, dynamic> userMap = {};
      tables.forEach((table, privs) {
        userMap[table] = privs;
      });
      permissionsMap[user] = userMap;
    });
    final Map<String, dynamic> proceduresMap = {};
    _procedures.forEach((key, val) {
      proceduresMap[key] = val.toJson();
    });
    final Map<String, dynamic> functionsMap = {};
    _functions.forEach((key, val) {
      functionsMap[key] = val.toJson();
    });
    final Map<String, dynamic> triggersMap = {};
    _triggers.forEach((key, val) {
      triggersMap[key] = val.toJson();
    });

    final outputMap = {
      'tables': tablesMap,
      'relationships': relsMap,
      'indexes': indexesMap,
      'stats': statsMap,
      'permissions': permissionsMap,
      'procedures': proceduresMap,
      'functions': functionsMap,
      'triggers': triggersMap,
    };
    file.writeAsStringSync(json.encode(outputMap));
  }
}

class MinMaxStats {
  dynamic min;
  dynamic max;
  int distinctCount;

  MinMaxStats({this.min, this.max, this.distinctCount = 0});

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
        'distinctCount': distinctCount,
      };

  factory MinMaxStats.fromJson(Map<String, dynamic> json) => MinMaxStats(
        min: json['min'],
        max: json['max'],
        distinctCount: json['distinctCount'] ?? 0,
      );
}

class ColumnHistogram {
  List<double> buckets = [];

  ColumnHistogram([List<double>? initialBuckets]) {
    if (initialBuckets != null) {
      buckets = List<double>.from(initialBuckets);
    }
  }

  void buildFromValues(List<double> values) {
    if (values.isEmpty) {
      buckets.clear();
      return;
    }
    values.sort();
    buckets.clear();
    int bucketCount = 100;
    if (values.length < bucketCount) {
      bucketCount = values.length;
    }
    double step = values.length / bucketCount;
    for (int i = 1; i <= bucketCount; i++) {
      int idx = (i * step).round() - 1;
      if (idx < 0) idx = 0;
      if (idx >= values.length) idx = values.length - 1;
      buckets.add(values[idx]);
    }
  }

  double calculateSelectivity(double val) {
    if (buckets.isEmpty) return 0.05;
    if (val < buckets.first) return 0.01;
    if (val > buckets.last) return 0.01;
    // equi-depth: each bucket has roughly 1/buckets.length of the data
    return 1.0 / buckets.length;
  }

  Map<String, dynamic> toJson() => {
        'buckets': buckets,
      };

  factory ColumnHistogram.fromJson(Map<String, dynamic> json) {
    return ColumnHistogram(List<double>.from(json['buckets'] ?? []));
  }
}

class TableStats {
  int rowCount;
  final Map<String, MinMaxStats> columnStats;
  final Map<String, ColumnHistogram> histograms;

  TableStats({this.rowCount = 0, Map<String, MinMaxStats>? columnStats, Map<String, ColumnHistogram>? histograms})
      : columnStats = columnStats ?? {},
        histograms = histograms ?? {};

  Map<String, dynamic> toJson() => {
        'rowCount': rowCount,
        'columnStats': columnStats.map((k, v) => MapEntry(k, v.toJson())),
        'histograms': histograms.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory TableStats.fromJson(Map<String, dynamic> json) {
    final stats = TableStats(rowCount: json['rowCount'] ?? 0);
    if (json.containsKey('columnStats')) {
      final colMap = json['columnStats'] as Map<String, dynamic>;
      colMap.forEach((k, v) {
        stats.columnStats[k] = MinMaxStats.fromJson(v);
      });
    }
    if (json.containsKey('histograms')) {
      final histMap = json['histograms'] as Map<String, dynamic>;
      histMap.forEach((k, v) {
        stats.histograms[k] = ColumnHistogram.fromJson(v);
      });
    }
    return stats;
  }
}
