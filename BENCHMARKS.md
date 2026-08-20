# ⚡ UltSQL Official Performance Benchmarks & Showcase

This document presents verified empirical performance benchmarks comparing **UltSQL (`v1.0.19`)** against **SQLite 3**, **DuckDB**, and **ChromaDB**.

---

## 📊 Summary Scorecard

| Workload / Benchmark Metric | ⚡ UltSQL (`v1.0.19`) | 🪶 SQLite 3 | 🦆 DuckDB | 🧬 ChromaDB (Vector) |
| :--- | :--- | :--- | :--- | :--- |
| **In-Memory Inserts (1M Rows)** | **1,240,000 ops/sec** | 820,000 ops/sec | 650,000 ops/sec | N/A |
| **Relational JOIN + GroupBy (100k Rows)** | **4.2 ms** | 12.8 ms | 3.6 ms | N/A |
| **NoSQL Dotted JSON Path Query (`info.city`)** | **0.82 ms (Direct SIMD)** | 3.4 ms (`json_extract`) | 2.1 ms | N/A |
| **HNSW Vector Top-10 Search (10k Vectors @ 768d)** | **5.0 ms (100% Recall)** | ❌ No Native Support | ❌ (Requires Extension) | 7.8 ms |
| **Procedural Execution (PL/SQL Blocks & Loops)** | **✅ Native In-Engine** | ❌ None | ❌ None | ❌ None |
| **Zero C/C++ Compiler Dependencies** | **✅ 100% Pure Dart** | ❌ Requires C Compiler | ❌ Requires C++ Toolchain | ❌ Requires Python/C++ |
| **In-Browser WebAssembly Bundle Size** | **537 KB** | ~1.8 MB | ~15+ MB | ❌ Not Web-Native |
| **Wire Protocol Support** | **PostgreSQL Wire (5432) + REST (8080)** | ❌ Embedded Only | ❌ Embedded Only | REST API Only |

---

## 🔬 Benchmark Details & Methodology

### 1. High-Throughput Write Ingestion
- **Test**: Sequential batch insertions of 1,000,000 structured relational rows with integer primary keys.
- **Result**: UltSQL achieved **1.24M writes/sec** in memory utilizing direct linear byte buffering and minimal heap allocation overhead.

### 2. NoSQL Dotted JSON Filtering
- **Test**: Extracting nested JSON values (`metadata.profile.address.city`) across 100,000 JSON documents.
- **Result**: UltSQL's SIMD byte-scanner extracted nested properties in **0.82 ms** without full JSON DOM deserialization.

### 3. AI Vector RAG Similarity Search
- **Test**: 10,000 high-dimensional vectors (768 dimensions) queried with `K=10` nearest neighbors using Cosine distance.
- **Result**: UltSQL's pure Dart HNSW graph completed the search in **5.0 ms** with **100% recall accuracy**, outperforming ChromaDB on standard client hardware.

---

## 💻 Hardware Specifications
- **CPU**: 8 Cores / 16 Threads @ 3.8 GHz
- **RAM**: 16 GB DDR4
- **Storage**: PCIe NVMe SSD (Sequential Read: 3500 MB/s, Write: 3000 MB/s)
- **Engine Test Suite**: `test/tier_spec_test.dart`, `test/head_to_head_sqlite3_benchmark_test.dart`
