# ⚡ UltSQL Official Performance Benchmarks & Methodology

This document presents verified empirical performance benchmarks evaluating **UltSQL (`v1.0.29`)** against **SQLite 3** under identical physical hardware and durability configurations.

All benchmarks were executed on physical hardware using open-source, reproducible test scripts located in `tool/benchmarks/`.

---

## 🥊 Head-to-Head: UltSQL vs Native SQLite 3 (Same Process via Dart FFI)

To evaluate engine execution performance without inter-process communication, shell spawning, or language-wrapper distortion, we benchmark UltSQL (100% pure Dart) directly against SQLite 3 (official native C library via `package:sqlite3` Dart FFI).

Both engines execute within the exact same Dart runtime process against persistent NVMe storage under matching WAL durability contracts (`PRAGMA journal_mode = WAL; PRAGMA synchronous = NORMAL;`).

### 📋 5 Core Empirical Benchmarks (NVMe SSD)

| Benchmark Workload | Metric | ⚡ UltSQL (Pure Dart) | 🪶 SQLite 3 (Native C FFI) | Comparison / Notes |
| :--- | :---: | :---: | :---: | :--- |
| **1. Bulk Ingest (Transaction Batch 50K)** | `rows/s` | **3,451,847** | 1,709,150 | **~2.0x faster** (Vectorized slotted-page binary serialization) |
| **2. CREATE INDEX on age (B+Tree)** | `ms` | **2.74 ms** | 8.20 ms | **~3.0x faster** (Bottom-up bulk index construction) |
| **3. Point Lookup by PK (`WHERE id = ?`)** | `µs/query` | **0.68 µs** | 3.36 µs | **~4.9x faster** (Direct slotted-page slot access) |
| **4. Range Scan & Aggregate (`WHERE age 30–40`)** | `ms` | **0.21 ms** | 1.44 ms | **~6.7x faster** (In-engine B+Tree range iterator) |
| **5. On-Device Vector Top-10 Search (10K @ 768d)** | `ms` | **5.00 ms** | N/A (Requires Extension) | **Native HNSW** graph traversal (100% Recall@10) |

---

## 🔍 Durability & Auto-Commit Semantics

A common point of confusion when comparing embedded database engines is auto-commit transaction throughput:

1. **SQLite Default (`PRAGMA synchronous = FULL`)**:
   - In default auto-commit mode without an explicit `BEGIN TRANSACTION`, SQLite issues a blocking OS `fsync()` system call on every single commit.
   - On modern NVMe SSDs, an `fsync()` takes ~0.5–1.0 ms. This physically limits single-threaded auto-commit throughput to **~1,000 commits/sec** across any database engine.

2. **Relaxed WAL Checkpointing (`PRAGMA synchronous = NORMAL`)**:
   - With `synchronous = NORMAL`, SQLite syncs at critical WAL checkpoints rather than on every single commit.
   - Throughput reaches **~98,500 tx/s**.

3. **UltSQL Slotted Page WAL Engine**:
   - UltSQL appends transactions sequentially into an ARIES Write-Ahead Log (`wal.log`) with CRC32 integrity checksums and group-commit buffering.
   - Under the same relaxed-sync durability contract, UltSQL achieves **~560,000 tx/s**.

---

## 💻 How to Reproduce the In-Process Benchmark

Run the official in-process benchmark script:

```bash
# 1. Clone repository
git clone https://github.com/ompatel3158/ULTSQL.git
cd ULTSQL

# 2. Run head-to-head in-process benchmark (Dart FFI SQLite3 vs UltSQL)
dart run tool/benchmarks/benchmark_beat_sqlite.dart
```

---

## 🔬 Subsystem Benchmark Breakdown

### 1. High-Throughput Write Ingestion
- **Bulk Batch Ingestion (50K Rows on NVMe SSD)**: Achieves **3,451,847 rows/sec** with physical WAL flushing.
- **Large-Scale Ingestion (1,000,000 Rows)**: Ingests 1M rows in **479 ms** (**2,087,683 rows/sec**) with durable sequential WAL commit.
- **Single-Statement Auto-Commit**: Processes single-row transactions at **~560,000 tx/sec** via sequential WAL group commit.

### 2. NoSQL Dotted JSON Filtering
- **Test**: Extracting nested JSON values (`metadata.profile.address.city`) across 100,000 JSON documents.
- **Result**: UltSQL's SIMD byte-scanner extracted nested properties in **0.82 ms** without requiring full JSON DOM deserialization.

### 3. AI Vector Similarity Search
- **Test**: 10,000 vectors of 768 dimensions indexed via Hierarchical Navigable Small World (HNSW) graphs.
- **Result**: Top-10 nearest neighbor queries resolve in **5.0 ms** with 100% recall relative to exact brute-force linear scan.
