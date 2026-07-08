import 'dart:convert';
import 'dart:io';
import '../parser/ast.dart';
import '../parser/lexer.dart';
import '../parser/parser.dart';

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
  final List<PolicySchema> policies;
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
    List<PolicySchema>? policies,
  })  : columnPrimaryKey = columnPrimaryKey ?? List.filled(columnNames.length, false),
        columnUnique = columnUnique ?? List.filled(columnNames.length, false),
        columnReferencesTable = columnReferencesTable ?? List.filled(columnNames.length, null),
        columnReferencesColumn = columnReferencesColumn ?? List.filled(columnNames.length, null),
        columnOnDeleteCascade = columnOnDeleteCascade ?? List.filled(columnNames.length, false),
        policies = policies ?? [] {
    columnNamesLower = columnNames.map((c) => c.toLowerCase()).toList();
    hasForeignKeys = this.columnReferencesTable.any((t) => t != null);
    hasUniqueOrPrimaryKey = this.columnPrimaryKey.any((b) => b) || this.columnUnique.any((b) => b);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'columnNames': columnNames,
        'columnTypes': columnTypes.map((t) => t.index).toList(),
        'isColumnar': isColumnar,
        'columnPrimaryKey': columnPrimaryKey,
        'columnUnique': columnUnique,
        'columnReferencesTable': columnReferencesTable,
        'columnReferencesColumn': columnReferencesColumn,
        'columnOnDeleteCascade': columnOnDeleteCascade,
        'policies': policies.map((p) => p.toJson()).toList(),
      };

  factory TableSchema.fromJson(Map<String, dynamic> json) {
    final names = List<String>.from(json['columnNames']);
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
      policies: json.containsKey('policies')
          ? (json['policies'] as List)
              .map((p) => PolicySchema.fromJson(p))
              .toList()
          : null,
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

  IndexSchema({
    required this.name,
    required this.tableName,
    required this.columnName,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'tableName': tableName,
        'columnName': columnName,
      };

  factory IndexSchema.fromJson(Map<String, dynamic> json) => IndexSchema(
        name: json['name'],
        tableName: json['tableName'],
        columnName: json['columnName'],
      );
}

class Catalog {
  final String basePath;
  final Map<String, TableSchema> _tables = {};
  final Map<String, RelationshipSchema> _relationships = {};
  final Map<String, IndexSchema> _indexes = {};
  final Map<String, TableStats> _stats = {};
  final Map<String, List<IndexSchema>> _tableIndexesCache = {};

  Catalog(this.basePath);

  Map<String, dynamic> getBackupState() {
    return {
      'tables': Map<String, TableSchema>.from(_tables),
      'relationships': Map<String, RelationshipSchema>.from(_relationships),
      'indexes': Map<String, IndexSchema>.from(_indexes),
      'stats': Map<String, TableStats>.from(_stats),
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

    final outputMap = {
      'tables': tablesMap,
      'relationships': relsMap,
      'indexes': indexesMap,
      'stats': statsMap,
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

class TableStats {
  int rowCount;
  final Map<String, MinMaxStats> columnStats;

  TableStats({this.rowCount = 0, Map<String, MinMaxStats>? columnStats})
      : columnStats = columnStats ?? {};

  Map<String, dynamic> toJson() => {
        'rowCount': rowCount,
        'columnStats': columnStats.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory TableStats.fromJson(Map<String, dynamic> json) {
    final stats = TableStats(rowCount: json['rowCount'] ?? 0);
    if (json.containsKey('columnStats')) {
      final colMap = json['columnStats'] as Map<String, dynamic>;
      colMap.forEach((k, v) {
        stats.columnStats[k] = MinMaxStats.fromJson(v);
      });
    }
    return stats;
  }
}
