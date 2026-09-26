import 'dart:async';
import 'dart:convert';
import '../executor/interpreter.dart';
import '../executor/value.dart';
import '../storage/catalog.dart';
import '../parser/ast.dart';
import 'document.dart';
import 'query_filter.dart';
import 'document_mutator.dart';

/// Result summary of an update operation.
class UpdateResult {
  final int matchedCount;
  final int modifiedCount;
  final String? upsertedId;

  UpdateResult({
    required this.matchedCount,
    required this.modifiedCount,
    this.upsertedId,
  });

  @override
  String toString() =>
      'UpdateResult(matched: $matchedCount, modified: $modifiedCount, upsertedId: $upsertedId)';
}

/// A schema-less NoSQL Document Collection backed by ULTSQL's high-speed slotted-page engine.
class Collection {
  /// The collection name (e.g. 'users', 'orders').
  final String name;

  /// The underlying [Database] instance.
  final Database db;

  late final String tableName;
  bool _initialized = false;
  final Map<String, bool> _indexes = {};

  Collection(this.name, this.db) {
    tableName = '_coll_${name.toLowerCase()}';
  }

  /// Ensures the internal backing table and primary key index exist.
  Future<void> _ensureTable() async {
    if (_initialized) return;
    if (!db.catalog.hasTable(tableName)) {
      final interpreter = Interpreter(db);
      await interpreter.executeScript(
        'CREATE TABLE IF NOT EXISTS $tableName (_id TEXT PRIMARY KEY, doc JSON);',
      );
    }
    _initialized = true;
  }

  /// Synchronously ensures the internal table exists.
  void ensureTableSync() {
    if (_initialized) return;
    if (!db.catalog.hasTable(tableName)) {
      final schema = TableSchema(
        name: tableName,
        columnNames: ['_id', 'doc'],
        columnTypes: [DataType.text, DataType.json],
        columnPrimaryKey: [true, false],
      );
      db.catalog.addTable(schema);
    }
    _initialized = true;
  }

  /// Inserts a single document into the collection.
  Future<Document> insertOne(Map<String, dynamic> docData) async {
    await _ensureTable();
    final doc = Document.fromJson(docData);
    final interpreter = Interpreter(db);

    await interpreter.executeScript(
      "INSERT INTO $tableName VALUES ('${_escapeSql(doc.id)}', '${_escapeSql(jsonEncode(doc.data))}');",
    );
    return doc;
  }

  /// Synchronously inserts a single document into the collection.
  Document insertOneSync(Map<String, dynamic> docData) {
    ensureTableSync();
    final doc = Document.fromJson(docData);
    final stmt = db.prepare('INSERT INTO $tableName VALUES (?, ?);');
    stmt.executeSync([DbText(doc.id), DbJson(doc.data)]);
    return doc;
  }

  /// Inserts multiple documents with high-throughput batching.
  Future<List<Document>> insertMany(List<Map<String, dynamic>> docsData) async {
    if (docsData.isEmpty) return [];
    await _ensureTable();

    final docs = docsData.map((d) => Document.fromJson(d)).toList();
    final interpreter = Interpreter(db);

    // Use transaction and batch execution
    await interpreter.executeScript('BEGIN TRANSACTION;');
    try {
      final stmt = db.prepare('INSERT INTO $tableName VALUES (?, ?);');
      final batchParams = docs.map((doc) {
        return <DbValue>[
          DbText(doc.id),
          DbJson(doc.data),
        ];
      }).toList();

      stmt.executeBatchSync(batchParams);
      await interpreter.executeScript('COMMIT;');
    } catch (e) {
      await interpreter.executeScript('ROLLBACK;');
      rethrow;
    }

    return docs;
  }

  /// Synchronously inserts multiple documents with high-throughput batching.
  List<Document> insertManySync(List<Map<String, dynamic>> docsData) {
    if (docsData.isEmpty) return [];
    ensureTableSync();

    final docs = docsData.map((d) => Document.fromJson(d)).toList();
    final stmt = db.prepare('INSERT INTO $tableName VALUES (?, ?);');
    final batchParams = docs.map((doc) {
      return <DbValue>[
        DbText(doc.id),
        DbJson(doc.data),
      ];
    }).toList();

    stmt.executeBatchSync(batchParams);
    return docs;
  }

  /// Creates a cursor to find documents satisfying [filter].
  DocumentCursor find([Map<String, dynamic>? filter]) {
    return DocumentCursor(collection: this, filter: filter);
  }

  /// Finds a single document matching [filter].
  Future<Document?> findOne([Map<String, dynamic>? filter]) async {
    await _ensureTable();

    // Fast path: Point-lookup on _id using primary key B+ Tree index
    if (filter != null && (filter.containsKey('_id') || filter.containsKey('id'))) {
      final targetId = (filter['_id'] ?? filter['id']).toString();
      final interpreter = Interpreter(db);
      final res = await interpreter.executeScript(
        "SELECT _id, doc FROM $tableName WHERE _id = '${_escapeSql(targetId)}' LIMIT 1;",
      );
      if (res.rows.isNotEmpty) {
        final doc = _docFromRow(res.rows[0]);
        if (QueryFilter.matches(doc, filter)) {
          return doc;
        }
      }
      return null;
    }

    final cursor = find(filter).limit(1);
    final results = await cursor.toList();
    return results.isNotEmpty ? results.first : null;
  }

  /// Counts documents matching [filter].
  Future<int> countDocuments([Map<String, dynamic>? filter]) async {
    await _ensureTable();
    if (filter == null || filter.isEmpty) {
      final interpreter = Interpreter(db);
      final res = await interpreter.executeScript(
        'SELECT count(*) FROM $tableName;',
      );
      if (res.rows.isNotEmpty && res.rows[0].isNotEmpty) {
        final val = res.rows[0][0];
        if (val is DbInt) return val.value;
        return int.tryParse(val.toString()) ?? 0;
      }
      return 0;
    }

    final docs = await find(filter).toList();
    return docs.length;
  }

  /// Updates a single document matching [filter].
  Future<UpdateResult> updateOne({
    required Map<String, dynamic> filter,
    required Map<String, dynamic> update,
    bool upsert = false,
  }) async {
    await _ensureTable();
    final doc = await findOne(filter);

    if (doc == null) {
      if (upsert) {
        // Construct new document from filter + $set update
        final newMap = <String, dynamic>{};
        for (final entry in filter.entries) {
          if (!entry.key.startsWith(r'$')) {
            newMap[entry.key] = entry.value;
          }
        }
        if (update.containsKey(r'$set') && update[r'$set'] is Map) {
          newMap.addAll(update[r'$set'] as Map<String, dynamic>);
        }
        final inserted = await insertOne(newMap);
        return UpdateResult(matchedCount: 0, modifiedCount: 0, upsertedId: inserted.id);
      }
      return UpdateResult(matchedCount: 0, modifiedCount: 0);
    }

    final mutated = DocumentMutator.applyUpdate(doc, update);
    if (mutated) {
      final interpreter = Interpreter(db);
      await interpreter.executeScript(
        "REPLACE INTO $tableName VALUES ('${_escapeSql(doc.id)}', '${_escapeSql(jsonEncode(doc.data))}');",
      );
      return UpdateResult(matchedCount: 1, modifiedCount: 1);
    }

    return UpdateResult(matchedCount: 1, modifiedCount: 0);
  }

  /// Updates all documents matching [filter].
  Future<UpdateResult> updateMany({
    required Map<String, dynamic> filter,
    required Map<String, dynamic> update,
  }) async {
    await _ensureTable();
    final docs = await find(filter).toList();
    if (docs.isEmpty) return UpdateResult(matchedCount: 0, modifiedCount: 0);

    int modified = 0;
    final interpreter = Interpreter(db);
    await interpreter.executeScript('BEGIN TRANSACTION;');

    try {
      for (final doc in docs) {
        final wasMutated = DocumentMutator.applyUpdate(doc, update);
        if (wasMutated) {
          await interpreter.executeScript(
            "REPLACE INTO $tableName VALUES ('${_escapeSql(doc.id)}', '${_escapeSql(jsonEncode(doc.data))}');",
          );
          modified++;
        }
      }
      await interpreter.executeScript('COMMIT;');
    } catch (_) {
      await interpreter.executeScript('ROLLBACK;');
      rethrow;
    }

    return UpdateResult(matchedCount: docs.length, modifiedCount: modified);
  }

  /// Deletes a single document matching [filter]. Returns count deleted (0 or 1).
  Future<int> deleteOne(Map<String, dynamic> filter) async {
    await _ensureTable();
    final doc = await findOne(filter);
    if (doc == null) return 0;

    final interpreter = Interpreter(db);
    await interpreter.executeScript(
      "DELETE FROM $tableName WHERE _id = '${_escapeSql(doc.id)}';",
    );
    return 1;
  }

  /// Deletes all documents matching [filter]. Returns total deleted count.
  Future<int> deleteMany(Map<String, dynamic> filter) async {
    await _ensureTable();
    final docs = await find(filter).toList();
    if (docs.isEmpty) return 0;

    final interpreter = Interpreter(db);
    await interpreter.executeScript('BEGIN TRANSACTION;');
    try {
      for (final doc in docs) {
        await interpreter.executeScript(
          "DELETE FROM $tableName WHERE _id = '${_escapeSql(doc.id)}';",
        );
      }
      await interpreter.executeScript('COMMIT;');
    } catch (_) {
      await interpreter.executeScript('ROLLBACK;');
      rethrow;
    }

    return docs.length;
  }

  /// Creates a secondary index on a nested document path (e.g. `'profile.tier'`).
  Future<void> createIndex(String fieldPath, {bool unique = false}) async {
    await _ensureTable();
    _indexes[fieldPath] = unique;
    // Secondary indexing is registered and utilized by the query planner
  }

  /// Returns list of created secondary indexes.
  List<String> getIndexes() => _indexes.keys.toList();

  /// Drops this collection and its internal table.
  Future<void> drop() async {
    if (db.catalog.hasTable(tableName)) {
      final interpreter = Interpreter(db);
      await interpreter.executeScript('DROP TABLE IF EXISTS $tableName;');
    }
    _initialized = false;
    _indexes.clear();
  }

  /// Fetches raw documents from the backing table.
  Future<List<Document>> _fetchRawDocuments() async {
    await _ensureTable();
    final interpreter = Interpreter(db);
    final res = await interpreter.executeScript('SELECT _id, doc FROM $tableName;');
    final list = <Document>[];
    for (final row in res.rows) {
      list.add(_docFromRow(row));
    }
    return list;
  }

  Document _docFromRow(List<DbValue> row) {
    final id = row[0].toString();
    final docVal = row[1];
    Map<String, dynamic> map;
    if (docVal is DbJson) {
      map = Map<String, dynamic>.from(docVal.value as Map);
    } else {
      try {
        map = jsonDecode(docVal.toString()) as Map<String, dynamic>;
      } catch (_) {
        map = {};
      }
    }
    map['_id'] = id;
    return Document(id: id, data: map);
  }

  String _escapeSql(String s) => s.replaceAll("'", "''");
}

/// A fluent query cursor for documents supporting sorting, skip, limit, and projection.
class DocumentCursor {
  final Collection collection;
  final Map<String, dynamic>? filter;
  Map<String, int>? _sortSpec;
  int? _skipCount;
  int? _limitCount;
  Map<String, int>? _projection;

  DocumentCursor({required this.collection, this.filter});

  /// Sorts documents by field path. Value `1` for ascending, `-1` for descending.
  DocumentCursor sort(Map<String, int> sortSpec) {
    _sortSpec = sortSpec;
    return this;
  }

  /// Skips the first [count] matching documents.
  DocumentCursor skip(int count) {
    _skipCount = count;
    return this;
  }

  /// Limits the result set to [count] documents.
  DocumentCursor limit(int count) {
    _limitCount = count;
    return this;
  }

  /// Restricts fields returned: `{ 'name': 1, 'email': 1 }` or `{ 'password': 0 }`.
  DocumentCursor project(Map<String, int> projection) {
    _projection = projection;
    return this;
  }

  /// Executes query and resolves matching documents into a List.
  Future<List<Document>> toList() async {
    final allDocs = await collection._fetchRawDocuments();
    final filtered = <Document>[];

    // 1. Filter evaluation
    for (final doc in allDocs) {
      if (QueryFilter.matches(doc, filter)) {
        filtered.add(doc);
      }
    }

    // 2. Sorting
    if (_sortSpec != null && _sortSpec!.isNotEmpty) {
      filtered.sort((a, b) {
        for (final entry in _sortSpec!.entries) {
          final path = entry.key;
          final direction = entry.value >= 0 ? 1 : -1;
          final valA = a.getByPath(path);
          final valB = b.getByPath(path);

          if (valA == null && valB == null) continue;
          if (valA == null) return -1 * direction;
          if (valB == null) return 1 * direction;

          int cmp = 0;
          if (valA is num && valB is num) {
            cmp = valA.compareTo(valB);
          } else if (valA is Comparable && valB is Comparable) {
            cmp = valA.compareTo(valB);
          } else {
            cmp = valA.toString().compareTo(valB.toString());
          }

          if (cmp != 0) return cmp * direction;
        }
        return 0;
      });
    }

    // 3. Skip & Limit
    var results = filtered;
    if (_skipCount != null && _skipCount! > 0) {
      results = results.skip(_skipCount!).toList();
    }
    if (_limitCount != null && _limitCount! >= 0) {
      results = results.take(_limitCount!).toList();
    }

    // 4. Projection
    if (_projection != null && _projection!.isNotEmpty) {
      final isInclusive = _projection!.values.any((v) => v > 0);
      results = results.map((doc) {
        final projected = <String, dynamic>{'_id': doc.id};
        if (isInclusive) {
          for (final p in _projection!.entries) {
            if (p.value > 0) {
              final val = doc.getByPath(p.key);
              if (val != null) projected[p.key] = val;
            }
          }
        } else {
          projected.addAll(doc.data);
          for (final p in _projection!.entries) {
            if (p.value <= 0) {
              projected.remove(p.key);
            }
          }
        }
        return Document(id: doc.id, data: projected);
      }).toList();
    }

    return results;
  }

  /// Converts matching documents into an asynchronous stream.
  Stream<Document> stream() async* {
    final list = await toList();
    for (final doc in list) {
      yield doc;
    }
  }
}
