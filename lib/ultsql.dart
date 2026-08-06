/// UltSQL — 100% Pure Dart Multimodal Database Engine.
///
/// Combines Relational SQL, PL/SQL, NoSQL Dotted JSON, and HNSW Vector RAG
/// with zero C/C++ native dependencies.
library;

export 'src/engine/ult_sql_engine.dart';
export 'src/engine/executor/interpreter.dart';
export 'src/engine/executor/value.dart';
export 'src/engine/executor/plan_nodes.dart';
export 'src/engine/storage/catalog.dart';
export 'src/engine/network/pg_wire_server.dart';
export 'src/engine/executor/telemetry.dart';
export 'src/services/local_database_service.dart';
