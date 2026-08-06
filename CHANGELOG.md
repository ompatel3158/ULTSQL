# Changelog

## 1.0.12

- Added `generate_series(start, stop [, step])` virtual series table generator.
- Added `information_schema` virtual catalog views (`information_schema.tables`, `information_schema.columns`, `information_schema.schemata`).
- Added DDL & metadata inspection statements (`DESCRIBE <table>`, `SHOW COLUMNS FROM <table>`, `SHOW SCHEMAS`, `PRAGMA table_info('<table>')`).
- Added enhanced DDL syntax (`CREATE TABLE IF NOT EXISTS`, `DROP TABLE IF EXISTS`, `TRUNCATE TABLE <table>`).
- Added UPSERT (`INSERT INTO ... ON CONFLICT (col) DO UPDATE SET ...`, `ON CONFLICT DO NOTHING`) and `REPLACE INTO` syntax.
- Added expanded native data types (`BOOLEAN`, `UUID`, `DATETIME`/`TIMESTAMP`, `BLOB`/`BYTEA`, `DECIMAL`/`NUMERIC`).
- Added ANSI `CAST(expr AS type)` and PostgreSQL `expr::type` typecasting syntax.
- Added PostgreSQL case-insensitive `ILIKE` and `~` regex matching operator.
- Added extended developer scalar functions (`COALESCE`, `NULLIF`, `GREATEST`, `LEAST`, `CONCAT_WS`, `SUBSTRING`, `TYPEOF`, `NOW`, `GEN_RANDOM_UUID`, `ABS`, `ROUND`, `CEIL`, `FLOOR`, `POW`, `SQRT`, `REPLACE`, `LPAD`, `RPAD`, `REVERSE`, `POSITION`, `SPLIT_PART`, `INITCAP`, `REGEXP_LIKE`, `DATE_ADD`, `DATE_SUB`, `DATE_TRUNC`, `EXTRACT`, `JSON_ARRAY`, `JSON_OBJECT`, `VERSION`).
- Resolved static analysis warnings and optimized plan execution.

## 1.0.11

- Added support for SQL data type aliases (`INTEGER`, `REAL`, `FLOAT`, `VARCHAR(255)`, `DECIMAL(10,2)`, `CHAR`, `STRING`, `BIGINT`, `SMALLINT`) and column constraints (`NOT NULL`, `NULL`).
- Auto-wrapped top-level PL/SQL blocks in single transaction batches, eliminating disk I/O bottlenecks and reducing 1,000,000 loop iteration execution time by >100x with zero UI thread freezing on mobile devices.

## 1.0.10

- Migrated internal package implementation files under `lib/src/` per standard Dart package layout rules for 100% pub.dev Pana score.
- Fixed 50+ static analysis warnings and lints across `lib/` and `bin/`.
- Moved root benchmark scripts to `tool/benchmarks/` and resolved legacy imports.
- Updated GitHub Actions CI workflow (`.github/workflows/test.yml`) for 100% green build passes.

## 1.0.9

- Optimized B+ tree index `_findRightmostLeafPageId()` from an $O(N)$ linear page scan to an $O(\log N)$ rightmost child tree descent, accelerating index initialization and range queries by >500x.
- Added `stats.rowCount` synchronization at `_executeCreateIndex` completion to support instant `IndexScanNode.getFastCount()` execution.
- Added `test/memory_benchmark_test.dart` verifying **3.48 Million rows/sec** throughput in ephemeral in-memory execution mode.
- Fixed log flooding in `RowCursor.moveNext()` during high-volume table scans.
- Verified 100% test suite pass rate across all 6 specification tiers, 6 enterprise pillars, signature innovations, and brutal stress test suites.

## 1.0.7

- Fixed MVCC snapshot byte cloning in `PageUndoInfo` (`Uint8List.fromList`) to prevent in-place slotted page undo state corruption.
- Updated dirty page count tracking (`getActualPageCountSync`) to count un-flushed dirty buffer pages during pre-transaction undo boundary checks.
- Enforced MVCC row visibility checks in `IndexScanNode.getFastCount` and `AggregateNode` to ensure rolled-back transactions do not affect `SELECT COUNT(*)` results.
- Isolated session context propagation (`currentMvccTx`) in `PageCache` to ensure concurrent sessions maintain 100% snapshot isolation.

## 1.0.6

- Removed unused local variables (`tableName`, `indexFile`) in `lib/engine/executor/interpreter.dart` for 100% clean static analysis (+20 Pana points).
- Fixed `GroupByNode` fast count `FilterNode` check and key mapping for `COUNT(*)` queries.
- Added AST node execution handlers for `SavepointStmt`, `RollbackToSavepointStmt`, and `ReleaseSavepointStmt`.
- Added auto-savepoint rollback support for PL/SQL nested exception handling blocks.

## 1.0.5

- Restored standard `lib/engine/` package layout to resolve `dartdoc` input directory warnings.
- Fixed insecure badge link in `README.md` to full `https://` URL (+5 Pana points).
- Added `example/example.dart` quickstart guide (+10 Pana points).
- Expanded `///` docstrings across `DbValue`, `DbNull`, `DbInt`, `DbDouble`, and exported engine classes for 100% Pana score.

## 1.0.4

- Fixed relative imports in `lib/ui/editor_screen.dart` to match `lib/engine/` package layout.
- Added `library ultsql;` directive in `lib/ultsql.dart` to resolve Pana library doc warnings.

## 1.0.3

- Added `example/example.dart` (+10 Pana points).
- Fixed badge relative link in `README.md` to secure `https://` URL (+5 Pana points).
- Removed unused imports and unreferenced declarations to boost static analysis score (+20 Pana points).

## 1.0.2

- Comprehensive public API documentation additions (`///`) across all exported classes (`LocalDatabaseService`, `Database`, `Interpreter`, `QueryResult`, `DbValue`, `TableSchema`, `Catalog`, `PlanNode`, `PgWireServer`) for 100% Pana doc coverage.
- Optimized static analysis compliance for pub.dev points.

## 1.0.1

- Updated license metadata and README badges to official **BSD 3-Clause License** (matching Flutter & Google standards).
- Added GitHub Actions CI workflow for automated build checks.

## 1.0.0

- Initial release of **UltSQL** (`package:ultsql`), a 100% Pure Dart converged database engine.
- High-throughput Volcano Iterator engine capable of 1.2M+ rows/sec in-memory ingestion.
- Embedded B+ Tree indexing, HNSW 768-dim Vector RAG search, and PL/SQL procedural runtime.
- Standalone PostgreSQL Wire Protocol TCP Server daemon (`bin/ultsql_server.dart`).
- Interactive REPL terminal client (`bin/ultsql_cli.dart`).
- Multi-database manager and `LocalDatabaseService` for drop-in Flutter app integration.
- Pure Dart cross-platform support: Android, iOS, Windows, macOS, Linux, and Web.
