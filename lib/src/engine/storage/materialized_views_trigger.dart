import 'dart:convert';
import 'dart:io';

class MaterializedViewDef {
  final String viewName;
  final String sourceTable;
  final String selectQuery;

  MaterializedViewDef({
    required this.viewName,
    required this.sourceTable,
    required this.selectQuery,
  });

  Map<String, dynamic> toJson() => {
    'viewName': viewName,
    'sourceTable': sourceTable,
    'selectQuery': selectQuery,
  };

  factory MaterializedViewDef.fromJson(Map<String, dynamic> json) =>
      MaterializedViewDef(
        viewName: json['viewName'],
        sourceTable: json['sourceTable'],
        selectQuery: json['selectQuery'],
      );
}

class MaterializedViewManager {
  final String dbDirectory;
  final Map<String, MaterializedViewDef> _views = {};

  MaterializedViewManager(this.dbDirectory);

  String get _registryPath => '$dbDirectory/mv_registry.json';

  void initSync() {
    final file = File(_registryPath);
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        final Map<String, dynamic> jsonMap = json.decode(content);
        _views.clear();
        jsonMap.forEach((key, val) {
          _views[key.toLowerCase()] = MaterializedViewDef.fromJson(val);
        });
      } catch (_) {}
    }
  }

  void saveSync() {
    final file = File(_registryPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    final jsonMap = _views.map((k, v) => MapEntry(k, v.toJson()));
    file.writeAsStringSync(json.encode(jsonMap));
  }

  void registerView(String viewName, String sourceTable, String selectQuery) {
    _views[viewName.toLowerCase()] = MaterializedViewDef(
      viewName: viewName,
      sourceTable: sourceTable,
      selectQuery: selectQuery,
    );
    saveSync();
  }

  List<MaterializedViewDef> getViewsForTable(String tableName) {
    final tName = tableName.toLowerCase();
    return _views.values
        .where((v) => v.sourceTable.toLowerCase() == tName)
        .toList();
  }
}
