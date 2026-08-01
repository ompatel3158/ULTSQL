# Changelog

## 1.0.0

- Initial release of **UltSQL** (`package:ultsql`), a 100% Pure Dart converged database engine.
- High-throughput Volcano Iterator engine capable of 1.2M+ rows/sec in-memory ingestion.
- Embedded B+ Tree indexing, HNSW 768-dim Vector RAG search, and PL/SQL procedural runtime.
- Standalone PostgreSQL Wire Protocol TCP Server daemon (`bin/ultsql_server.dart`).
- Interactive REPL terminal client (`bin/ultsql_cli.dart`).
- Multi-database manager and `LocalDatabaseService` for drop-in Flutter app integration.
- Pure Dart cross-platform support: Android, iOS, Windows, macOS, Linux, and Web.
