# 🚀 ULTSQL — Ultra-High Performance Converged Multimodal Database Engine

[![pub package](https://img.shields.io/pub/v/ultsql.svg)](https://pub.dev/packages/ultsql)
[![Dart SDK](https://img.shields.io/badge/Dart-3.4+-0175C2.svg?logo=dart)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B.svg?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://github.com/ompatel3158/ULTSQL/blob/main/LICENSE)
[![Build Status](https://img.shields.io/github/actions/workflow/status/ompatel3158/ULTSQL/test.yml?branch=main&label=build)](https://github.com/ompatel3158/ULTSQL/actions)

📦 **Package**: [ultsql | Flutter package](https://pub.dev/packages/ultsql)

**UltSQL** is a ground-up, zero-dependency, 4-in-1 converged database engine written in 100% pure Dart. It seamlessly combines **Relational SQL**, **PL/SQL Procedural Execution**, **NoSQL Dotted-Path Document Querying**, and **AI-Native Vector RAG Search** into a single, high-throughput storage model with zero native C dependencies or unsafe memory pointers.

---

## <a name="standalone-engine-metrics"></a>🌟 Standalone Engine Metrics

| Capability / Benchmark | UltSQL Performance | Feature Status |
| :--- | :--- | :--- |
| **In-Memory Batch Write Throughput** | **1,200,000+ rows/sec** (Peak 3.48M/s) | ⚡ High-Throughput Memory Engine |
| **B+ Tree Index Build (100K Rows)** | **17 ms** | 🏆 Ultra-Fast Sub-Second Indexing |
| **768-Dim HNSW AI Vector RAG** | **6 ms** (100% Recall) | 🧠 Native AI Embedded Vector Engine |
| **Network TCP Wire Protocol Server** | **Port 5432 Supported** | 🌐 Remote Client Network Connections |
| **Self-Healing Corrupted Recovery** | **Auto-Repairs CRC Mismatches** | 🛠️ Zero-DBA Self-Healing |
| **P2P Offline Device-to-Device Sync** | **LWW-Element-Set CRDT Sync** | 📲 Local-First P2P Mesh Sync |
| **Universal Direct File SQL Queries** | **CSV, JSON, LOG Files** | 📁 Zero-ETL Direct Queries |
| **Zero-Knowledge Ciphertext Search** | **Homomorphic XOR Search** | 🔐 Secure Privacy Enclave |

---

## <a name="system-architecture"></a>🏛️ System Architecture

UltSQL uses a multi-layered Volcano-iterator query engine over custom slotted-page disk/memory tables, LRU page caching, B+ Trees, and HNSW vector graphs:

```mermaid
graph TD
    UI[Flutter IDE Console / Client App] -->|SQL / PL-SQL / NL Prompt| Interpreter[Interpreter Engine]
    Interpreter -->|Natural Language AI| NlEngine[NL-to-SQL AI Compiler]
    Interpreter -->|Lexical Analysis| Lexer[Hand-Written Lexer]
    Lexer -->|Tokens| Parser[Hand-Written Parser]
    Parser -->|AST Tree| QueryPlanner[Optimizing Query Planner]
    QueryPlanner -->|Physical Execution Plan| VolcanoEngine[Volcano Iterator Execution Engine]
    
    VolcanoEngine -->|Page Operations| PageCache[LRU Page Cache Buffer]
    PageCache -->|CRC32 Page Verification| Pager[Slotted Page Pager]
    Pager -->|Storage Engines| StorageAdapters
    
    subgraph StorageAdapters[Converters & Adapters]
      MemoryStore[MemoryTable: 1.2M+ rows/sec]
      RowStore[.db: Row-Oriented Slotted Pages]
      ColumnStore[.col_*: Columnar Parquet Store]
      BTreeIndex[.idx: B+ Tree Indexes]
      HnswIndex[.hnsw: HNSW Vector Graph]
      FileAdapter[Universal CSV / JSON / LOG Adapter]
    end
    
    VolcanoEngine -->|Network Server| PgWireServer[TCP Wire Protocol Server]
    VolcanoEngine -->|P2P Mesh| P2pNode[CRDT P2P Peer Node]
```

---

## <a name="table-of-contents"></a>📑 Table of Contents

1. [🌟 Standalone Engine Metrics](#standalone-engine-metrics)
2. [🏛️ System Architecture](#system-architecture)
3. [💎 The 15 Signature Innovations](#the-15-signature-innovations)
4. [⚖️ Storage Modes: Switchable Performance](#storage-modes-switchable-performance)
5. [🛠️ SQL & PL/SQL Feature Guide](#sql--plsql-feature-guide)
6. [📄 NoSQL Dotted-Path JSON Querying](#nosql-dotted-path-json-querying)
7. [🧠 AI-Native HNSW Vector RAG Search](#ai-native-hnsw-vector-rag-search)
8. [🌐 Network TCP Wire Protocol Server](#network-tcp-wire-protocol-server)
9. [🛠️ Self-Healing & Auto-Indexing Telemetry](#self-healing--auto-indexing-telemetry)
10. [📲 P2P Offline Device-to-Device Sync](#p2p-offline-device-to-device-sync)
11. [📁 Direct File SQL Queries (CSV / JSON / LOG)](#direct-file-sql-queries)
12. [🔐 Zero-Knowledge Security Enclave](#zero-knowledge-security-enclave)
13. [📊 Standalone Engine Performance Metrics](#standalone-engine-performance-metrics)
14. [🚀 Getting Started & Installation](#getting-started--installation)
15. [📜 License](#license)

---

## <a name="the-15-signature-innovations"></a>💎 The 15 Signature Innovations

UltSQL introduces 15 signature database innovations engineered specifically for high-throughput client and cloud workloads:

1. ⚡ **1.2M+ Rows/sec In-Memory Batch Engine**: Zero-allocation linear byte array memory ingestion.
2. 🏆 **Ultra-Fast B+ Tree Bulk Indexing**: `insertSortedBatchSync` constructs 100K-row B+ Trees in 17 ms.
3. 🧠 **Native HNSW Vector RAG Graph**: Cosine & Euclidean similarity search over 768-dim embeddings in 6 ms.
4. 🌐 **Network TCP Wire Protocol Server**: Accepts incoming connections from standard database drivers.
5. 🛠️ **Self-Healing Page Auto-Repair**: Auto-detects CRC32 page corruption and rebuilds intact state from WAL logs.
6. 🤖 **Autonomous Telemetry Auto-Indexer**: Monitors query scan frequencies and automatically provisions B+ Tree indexes.
7. 📁 **Universal Direct File SQL Adapter**: Runs live SQL queries over standard `.csv`, `.json`, and `.log` files without importing into tables.
8. 🗣️ **AI Natural Language to SQL Compiler**: Translates natural language prompts into executable SQL statements.
9. 🔐 **Zero-Knowledge Encrypted Enclave**: Performs fast ciphertext searches over homomorphically XOR-encrypted data.
10. 📲 **P2P Offline LWW CRDT Sync**: Merges peer database changes over local network without central servers.
11. 📦 **Zero-Allocation `RowMap` Tuple Wrapper**: Replaces Dart `Map` instantiations with zero-allocation array index views.
12. ⚡ **JIT Compiled Expression Expressions**: Compiles SQL `WHERE` conditions into native Dart closure delegates.
13. 📊 **Auto-Optimized Columnar Parquet Store**: Automatically converts tables with `VECTOR` or analytical data into columnar layout.
14. 🔄 **MVCC Multi-Version Concurrency Control**: Provides lock-free readers and repeatable read transaction isolation.
15. 🛡️ **AES-256 Transparent Page Encryption**: Encrypts storage pages on disk using 256-bit AES-CBC.

---

## <a name="storage-modes-switchable-performance"></a>⚖️ Storage Modes: Switchable Performance

Switch between in-memory speed and durable disk storage with a single line of code:

### 1. ⚡ In-Memory Storage Mode (`1,200,000+ rows/sec`)
For high-frequency streaming, real-time AI vector search, and temporary session caches:
```dart
final db = Database(':memory:');
await db.init();
```

### 2. 💾 Durable Disk Storage Mode (`360,000+ rows/sec`)
For persistent local application data with ACID crash safety and auto-healing WAL recovery:
```dart
final db = Database('/path/to/app_data/my_database');
await db.init();
```

### 3. 🔄 Hybrid Ingest & Snapshot
```dart
final prep = db.prepare("INSERT INTO users VALUES (?, ?, ?);");
prep.executeBatchSync(batchRows);
await db.flushWalSync(); // Flush WAL snapshot to disk
```

---

## <a name="sql--plsql-feature-guide"></a>🛠️ SQL & PL/SQL Feature Guide

### Data Definition Language (DDL)
```sql
CREATE TABLE users (
  id INT PRIMARY KEY,
  name TEXT,
  balance DOUBLE,
  metadata JSON,
  embedding VECTOR
);
```

### Data Manipulation Language (DML)
```sql
INSERT INTO users VALUES (1, 'Alice', 1500.50, '{"role": "admin", "department": "Engineering"}', '[0.12, 0.85, -0.44]');
INSERT INTO users VALUES (2, 'Bob', 820.00, '{"role": "developer", "department": "AI"}', '[0.91, 0.05, 0.12]');
```

### PL/SQL Procedural Script Execution
```sql
DECLARE
  counter INT := 0;
  total DOUBLE := 0.0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Starting calculation...');
  
  WHILE counter < 5 LOOP
    counter := counter + 1;
    total := total + (counter * 100.5);
    
    IF counter % 2 = 0 THEN
      DBMS_OUTPUT.PUT_LINE('Iteration ' || counter || ': EVEN total=' || total);
    ELSE
      DBMS_OUTPUT.PUT_LINE('Iteration ' || counter || ': ODD total=' || total);
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Calculations Completed.');
END;
```

---

## <a name="nosql-dotted-path-json-querying"></a>📄 NoSQL Dotted-Path JSON Querying

Query nested JSON document attributes directly using standard SQL dotted-path navigation syntax:

```sql
-- Query nested JSON properties directly
SELECT name, metadata->>'role' AS user_role, metadata->>'department' AS dept
FROM users
WHERE metadata->>'role' = 'admin';
```

---

## <a name="ai-native-vector-rag-search"></a>🧠 AI-Native HNSW Vector RAG Search

Create an HNSW index and execute sub-7ms vector similarity queries:

```sql
CREATE INDEX idx_products_emb ON products (embedding) USING HNSW;

SELECT name, vector_distance(embedding, '[0.12, 0.85, -0.44]') AS dist
FROM products
ORDER BY dist ASC
LIMIT 5;
```

---

## <a name="network-tcp-wire-protocol-server"></a>🌐 Network TCP Wire Protocol Server

UltSQL embeds a full Network TCP Wire Protocol server. Connect directly using network database drivers:

```dart
final pgServer = PgWireServer(db: db, port: 5432);
await pgServer.start();
print('TCP Wire Protocol Server running on port 5432...');
```

---

## <a name="self-healing--auto-indexing-telemetry"></a>🛠️ Self-Healing & Auto-Indexing Telemetry

UltSQL features autonomous telemetry monitoring that auto-repairs corrupted disk pages from WAL logs and provisions B+ Tree indexes based on query scan frequencies:

```sql
-- Enable automated self-healing & telemetry index recommendations
SET engine_option enable_autovacuum = true;
SET engine_option auto_create_indexes = true;
```

---

## <a name="p2p-offline-device-to-device-sync"></a>📲 P2P Offline Device-to-Device Sync

Synchronize database states between offline mobile devices using Conflict-Free Replicated Data Types (CRDT):

```dart
final localNode = P2pSyncNode(nodeId: 'device_A', db: db);

// Merge peer update record
localNode.applyPeerUpdate(P2pUpdateRecord(
  entityId: 'user_101',
  timestamp: DateTime.now().millisecondsSinceEpoch,
  data: {'name': 'Alice Updated', 'balance': 2000.0},
));
```

---

## <a name="direct-file-sql-queries"></a>📁 Direct File SQL Queries (CSV / JSON / LOG)

Execute standard SQL queries directly over external files without ETL or table imports:

```dart
final fileAdapter = UniversalFileAdapter();

// Query external CSV file directly using SQL
final csvResults = fileAdapter.queryCsvSync(
  filePath: '/data/logs.csv',
  sqlQuery: "SELECT * FROM file WHERE status = 'ERROR'",
);
```

---

## <a name="zero-knowledge-security-enclave"></a>🔐 Zero-Knowledge Security Enclave

Perform fast ciphertext searches over homomorphically XOR-encrypted data without decrypting database records:

```sql
-- Query encrypted zero-knowledge enclave data safely
SELECT * FROM confidential_table WHERE zk_match(ciphertext, 'search_key') = true;
```

---

## <a name="standalone-engine-performance-metrics"></a>📊 Standalone Engine Performance Metrics

Empirical performance measurements recorded on 100,000 records on local disk:

```text
======================================================
🔥 ULTSQL STANDALONE ENGINE PERFORMANCE (100,000 ROWS) 🔥
======================================================
1. Bulk Insert Throughput (100,000 Rows):
   - UltSQL (Memory Mode): 82 ms (1,219,512 rows/sec)
   - UltSQL (Disk Mode): 278 ms (359,712 rows/sec)

2. B+ Tree Index Build (100,000 Rows):
   - UltSQL: 17 ms (Ultra-Fast B+ Tree Indexing)

3. Multimodal Features:
   - 768-Dim HNSW Vector Search: 6 ms (100% Recall Accuracy)
   - Network TCP Wire Server: Port 5432 Supported
   - Self-Healing Page Repair: CRC Auto-Recovery Supported
   - P2P Device-to-Device Sync: LWW-CRDT Sync Supported
======================================================
```

> [!NOTE]
> **Hardware Environment & Benchmark Disclosure**:
> Performance benchmark metrics were tested by **Om** on an **ASUS ROG Strix G16 (2023)**. Actual performance throughput may vary (better or worse) depending on your device hardware, CPU architecture, memory bandwidth, and disk I/O capabilities.
>
> **Test System Specifications**:
> - **Laptop Model**: ASUS ROG Strix G16 (2023)
> - **CPU**: Intel Core i7-13650HX
> - **RAM**: 16 GB DDR5 (4800 MT/s)
> - **Storage**: 1 TB Gen 5 NVMe SSD
> - **GPU**: NVIDIA GeForce RTX 4050 (6 GB)

---

## <a name="getting-started--installation"></a>🚀 Getting Started & Installation

### Prerequisites
* [Dart SDK 3.4+](https://dart.dev) or [Flutter SDK 3.22+](https://flutter.dev)

### Installation
1. Clone repository:
   ```bash
   git clone https://github.com/ompatel3158/ULTSQL.git
   cd ULTSQL
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the comprehensive test suite:
   ```bash
   flutter test
   ```
4. Run the interactive UI Console IDE:
   ```bash
   flutter run
   ```

---

## <a name="license"></a>📜 License

UltSQL is licensed under the **BSD 3-Clause License** (the official license used by Flutter & Google). Built with ❤️ in pure Dart.
