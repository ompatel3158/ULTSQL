# Changelog

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
