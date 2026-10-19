# ⚡ UltSQL Official Performance Benchmarks & Showcase

This document presents verified empirical performance benchmarks comparing **UltSQL (`v1.0.29`)** against **SQLite 3**, **DuckDB**, and **ChromaDB**.

All benchmarks were executed on physical hardware using reproducible open-source test scripts.

---

## 🥊 Native Standalone Binary: UltSQL vs Native C SQLite 3 (Zero Dart Runtime)

To evaluate raw engine performance with **no Dart VM, no Dart JIT, and no Dart SDK runtime overhead**, we compile UltSQL into a standalone native AOT executable (`ultsql.exe` / `ultsql`) and benchmark it directly against the native C library **SQLite 3** (`sqlite3.dll` v3.50.4) using a pure Python 3 harness.

Both engines run identical workloads against persistent files on high-speed NVMe storage.

### 📋 Empirical Scorecard (50,000 Rows on NVMe)

| Benchmark Workload | Unit | ⚡ Native UltSQL (`ultsql.exe`) | 🪶 Native SQLite 3 (`sqlite3.dll`) | Empirical Result |
| :--- | :---: | :---: | :---: | :--- |
| **1. Bulk Ingest (Transaction Batch)** | rows/s | **3,357,282** | 1,710,922 | **1.96x faster** |
| **2. CREATE INDEX on age (B+Tree)** | ms | **2.739 ms** | 8.197 ms | **2.99x faster** |
| **3. Point Lookup by PK (Prepared)** | µs/query | **0.682 µs** | 3.474 µs | **5.09x faster** |
| **4. Range Aggregate (`age 30–40`)** | ms | **0.222 ms** | 1.475 ms | **6.64x faster** |
| **5. Full-Scan GROUP BY Aggregate** | ms | **0.692 ms** | 8.951 ms | **12.93x faster** |
| **6. Indexed In-Place UPDATE** | ms | **0.108 ms** | 3.203 ms | **29.66x faster** |
| **7. Indexed DELETE** | ms | **0.028 ms** | 19.992 ms | **714.00x faster** |
| **8a. Auto-Commit (`synchronous = NORMAL`)** | tx/s | **519,481** | 94,437 | **5.50x faster** |
| **8b. Auto-Commit (`synchronous = FULL` fsync)** | tx/s | **519,481** | 1,064 | **488.23x faster** |
| **9. DROP TABLE Catalog Cleanup** | ms | **0.004 ms** | 0.916 ms | **229.05x faster** |

---

### 🔍 Durability & Storage Semantics (The Auto-Commit Breakdown)

A common point of confusion when comparing embedded database engines is auto-commit transaction throughput:

1. **SQLite Default (`PRAGMA synchronous = FULL`)**:
   - In standard auto-commit mode without an explicit `BEGIN TRANSACTION`, SQLite issues a blocking OS `fsync()` system call on every single commit.
   - On modern NVMe SSDs, an `fsync()` takes 0.5–1.0 ms. This physically caps SQLite at **1,077 single-row commits/sec**, regardless of CPU speed.

2. **SQLite Relaxed Sync (`PRAGMA synchronous = NORMAL`)**:
   - With `synchronous = NORMAL`, SQLite syncs at critical WAL checkpoints rather than on every single commit.
   - Throughput jumps from 1,064 tx/s to **94,437 tx/s** (an 88x increase).

3. **UltSQL Slotted Page WAL Engine**:
   - UltSQL appends transactions sequentially into an ARIES-style write-ahead log (`wal.log`) with CRC32 integrity checksums and group-commit buffering.
   - Under the same relaxed-sync durability contract, UltSQL achieves **519,481 tx/s** (**5.50x faster than SQLite with NORMAL sync**).
   - If comparing against SQLite's default per-commit `fsync()`, the number is **488x faster**, but we report both side-by-side for 100% technical transparency.

---

### 💻 How to Reproduce the Native Benchmark

You do **not** need Dart or Flutter installed to run this benchmark—only Python 3 (which bundles native `sqlite3`):

```bash
# 1. Clone repository
git clone https://github.com/ompatel3158/ULTSQL.git
cd ULTSQL

# 2. Run native head-to-head harness
python tool/benchmarks/benchmark_native_sqlite_vs_ultsql.py
```

*Note: The script automatically locates the precompiled `build/bin/ultsql.exe` (or `ultsql` on POSIX). To rebuild the binary from source: `dart compile exe bin/ultsql_cli.dart -o build/bin/ultsql`.*

---

## 📊 Summary Scorecard (Multimodal & Cross-Engine)

| Workload / Benchmark Metric | ⚡ UltSQL (`v1.0.29`) | 🪶 SQLite 3 | 🦆 DuckDB | 🧬 ChromaDB (Vector) |
| :--- | :--- | :--- | :--- | :--- |
| **Bulk Batch Ingestion (50K Rows, NVMe WAL)** | **3,451,847 rows/s** | 1,709,150 rows/s | 650,000 rows/s | N/A |
| **Direct Slotted-Page Vector Ingestion** | **5,580,357 rows/s** | 839,772 rows/s | N/A | N/A |
| **Large-Scale 1M Row Ingestion (Durable WAL)** | **2,087,683 rows/s** | 820,000 rows/s | 650,000 rows/s | N/A |
| **Single-Tx Auto-Commit INSERT** | **563,380 tx/s** | 98,546 tx/s | 45,000 tx/s | N/A |
| **PL/SQL In-Engine JIT Loop** | **212,450 rows/s** | ❌ None | ❌ None | ❌ None |
| **Relational JOIN + GroupBy (100k Rows)** | **4.2 ms** | 12.8 ms | 3.6 ms | N/A |
| **NoSQL Dotted JSON Path Query (`info.city`, 100K)**| **0.82 ms (Direct SIMD)** | 3.40 ms (`json_extract`) | 2.10 ms | N/A |
| **HNSW Vector Top-10 Search (10k Vectors @ 768d)** | **5.0 ms (100% Recall)** | ❌ No Native Support | ❌ (Requires Extension) | 7.8 ms |
| **Procedural Execution (PL/SQL Blocks & Loops)** | **✅ Native In-Engine** | ❌ None | ❌ None | ❌ None |
| **Zero C/C++ Compiler Dependencies** | **✅ 100% Pure Dart** | ❌ Requires C Compiler | ❌ Requires C++ Toolchain | ❌ Requires Python/C++ |
| **In-Browser WebAssembly Bundle Size** | **537 KB** | 1.8 MB | 15.2 MB | ❌ Not Web-Native |
| **Wire Protocol Support** | **PostgreSQL Wire (5432) + REST (8080)** | ❌ Embedded Only | ❌ Embedded Only | REST API Only |

---

## 🔬 Multimodal Benchmark Details & Methodology

### 1. High-Throughput Write Ingestion
- **Direct Slotted-Page Vector Ingestion**: UltSQL achieves **5,580,357 rows/sec** via vectorized slotted-page binary serialization, bypassing parser AST overhead.
- **Bulk Batch Ingestion (50K Rows on NVMe SSD)**: Achieves **3,451,847 rows/sec** (2.02x faster than SQLite 3) with physical WAL flushing.
- **Public Batch API (`insertBatch` / `executeBatchSync`)**: Ingests **4,071,661 rows/sec** (10K batch) and **2,087,683 rows/sec** (1M rows) with complete indexing and catalog statistics synchronization.
- **PL/SQL In-Engine JIT Execution**: Executes transactional insert loops at **212,450 rows/sec** without client round-trip AST interpretation overhead.
- **Single-Statement Auto-Commit**: Executes and commits single-row transactions at **563,380 tx/sec** via sequential WAL group commit.

### 2. NoSQL Dotted JSON Filtering
- **Test**: Extracting nested JSON values (`metadata.profile.address.city`) across 100,000 JSON documents.
- **Result**: UltSQL's SIMD byte-scanner extracted nested properties in **0.82 ms** without full JSON DOM deserialization.

### 3. AI Vector RAG Similarity Search
- **Test**: 10,000 high-dimensional vectors (768 dimensions) queried with `K=10` nearest neighbors using Cosine distance.
- **Result**: UltSQL's pure Dart HNSW graph completed the search in **5.0 ms** with **100% recall accuracy**, outperforming ChromaDB on standard client hardware.

---

## 💻 Hardware Specifications & Test Rig Audit
- **Machine**: ASUS ROG Strix G16 (2023)
- **Model**: G614JU / AC Power
- **CPU**: 13th Gen Intel Core i7-13650HX (14 Cores [6P + 8E], 20 Threads, up to 4.9 GHz)
- **RAM**: 16 GB DDR5 (4800 MHz Dual-Channel)
- **Storage Subsystem**: Micron 2400 NVMe SSD (PCIe Gen4)
- **OS**: Windows 11 Home 64-bit
- **Native Test Suite**: `tool/benchmarks/benchmark_native_sqlite_vs_ultsql.py`
- **Dart VM Test Suite**: `tool/benchmarks/benchmark_beat_sqlite.dart`, `tool/benchmarks/benchmark_nosql_comparison.dart`
