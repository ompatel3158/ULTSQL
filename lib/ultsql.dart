/// UltSQL — 100% Pure Dart Multimodal Database Engine.
///
/// Combines Relational SQL, PL/SQL, NoSQL Dotted JSON, and HNSW Vector RAG
/// with zero C/C++ native dependencies.
library;

export 'src/engine/ult_sql_engine.dart';
export 'src/engine/executor/interpreter.dart'
    show
        Interpreter,
        QueryResult,
        PreparedStatement,
        Database,
        DatabaseLockException;
export 'src/engine/executor/value.dart'
    show
        DbValue,
        DbInt,
        DbDouble,
        DbText,
        DbBool,
        DbBlob,
        DbJson,
        DbVector,
        DbNull,
        DbDateTime,
        DbUuid,
        DbDecimal;
export 'src/engine/parser/ast.dart' show DataType;
export 'src/engine/network/pg_wire_server.dart' show PgWireServer;
export 'src/engine/network/rest_server.dart' show RestServer;
export 'src/engine/executor/telemetry.dart'
    show FlightRecorder, FlightRecorderReport, FlightRecorderStep;
export 'src/services/local_database_service.dart' show LocalDatabaseService;
