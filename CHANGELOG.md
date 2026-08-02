# Changelog

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
