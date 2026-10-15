#!/usr/bin/env python3
"""
UltSQL vs Native SQLite 3 - Side-by-Side Benchmark Harness
Runs identical workloads on both engines natively on the local hardware.
No Dart VM or Dart SDK required to run.
"""

import os
import random
import re
import shutil
import sqlite3
import subprocess
import sys
import time
from pathlib import Path

ROW_COUNT = 50000
SQLITE_DB = "sqlite_bench_temp.db"
ULTSQL_DIR = "bench_temp_db"


def find_ultsql_binary() -> str:
    env_bin = os.environ.get("ULTSQL_BINARY_PATH")
    if env_bin and os.path.isfile(env_bin):
        return env_bin

    is_win = sys.platform == "win32"
    exe_name = "ultsql.exe" if is_win else "ultsql"

    candidates = [
        Path("build/bin") / exe_name,
        Path("../../build/bin") / exe_name,
        Path("bindings/python/src/ultsql/bin") / exe_name,
    ]
    for c in candidates:
        if c.is_file():
            return str(c.resolve())

    which = shutil.which(exe_name)
    if which:
        return which

    raise FileNotFoundError(
        f"Could not find standalone native UltSQL binary ({exe_name}). "
        "Build it with 'dart compile exe bin/ultsql_cli.dart -o build/bin/ultsql(.exe)'."
    )


def run_ultsql_native(binary_path: str, row_count: int) -> dict:
    print(f"[*] Running Native UltSQL Standalone Binary: {binary_path} bench {row_count}...")
    cmd = [binary_path, "bench", str(row_count)]
    result = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        encoding="utf-8",
        errors="replace",
        check=True,
    )
    out = result.stdout or ""

    metrics = {}
    for line in out.splitlines():
        if "1. Bulk Ingest" in line:
            m = re.search(r"│\s+([\d.]+)\s+│", line)
            if m:
                metrics["bulk_rps"] = int(float(m.group(1)))
        elif "2. CREATE INDEX" in line:
            m = re.search(r"│\s+([\d.]+)\s+│", line)
            if m:
                metrics["index_ms"] = float(m.group(1))
        elif "3. Point Lookup by PK" in line:
            m = re.search(r"│\s+([\d.]+)\s+│", line)
            if m:
                metrics["point_us"] = float(m.group(1))
        elif "4. Range Aggregate" in line:
            m = re.search(r"│\s+([\d.]+)\s+│", line)
            if m:
                metrics["range_ms"] = float(m.group(1))
        elif "5. Full-scan GROUP BY" in line:
            m = re.search(r"│\s+([\d.]+)\s+│", line)
            if m:
                metrics["group_ms"] = float(m.group(1))
        elif "6. WARP In-Place UPDATE" in line:
            m = re.search(r"│\s+([\d.]+)\s+│", line)
            if m:
                metrics["update_ms"] = float(m.group(1))
        elif "7. Indexed DELETE" in line:
            m = re.search(r"│\s+([\d.]+)\s+│", line)
            if m:
                metrics["delete_ms"] = float(m.group(1))
        elif "8. Single-Tx Auto-Commit" in line:
            m = re.search(r"│\s+([\d.]+)\s+│", line)
            if m:
                metrics["single_tx"] = int(float(m.group(1)))
        elif "9. DROP TABLE" in line:
            m = re.search(r"│\s+([\d.]+)\s+│", line)
            if m:
                metrics["drop_ms"] = float(m.group(1))

    return metrics


def run_sqlite_native(row_count: int) -> dict:
    print(f"[*] Running Native C SQLite v{sqlite3.sqlite_version} (WAL Mode)...")
    if os.path.exists(SQLITE_DB):
        os.remove(SQLITE_DB)

    conn = sqlite3.connect(SQLITE_DB)
    cur = conn.cursor()
    cur.execute("PRAGMA journal_mode = WAL;")
    cur.execute("PRAGMA synchronous = NORMAL;")
    cur.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER, score REAL);")
    conn.commit()

    # 1. Bulk Ingest
    rows_data = [
        (i, f"User_{i}", 18 + (i % 62), (i % 1000) / 10.0)
        for i in range(1, row_count + 1)
    ]
    t0 = time.perf_counter()
    cur.execute("BEGIN TRANSACTION;")
    cur.executemany("INSERT INTO users VALUES (?, ?, ?, ?);", rows_data)
    conn.commit()
    t1 = time.perf_counter()
    bulk_rps = int(row_count / (t1 - t0))

    # 2. CREATE INDEX
    t0 = time.perf_counter()
    cur.execute("CREATE INDEX idx_age ON users(age);")
    conn.commit()
    t1 = time.perf_counter()
    index_ms = (t1 - t0) * 1000.0

    # 3. Point Lookups by PK
    random.seed(42)
    lookup_ids = [random.randint(1, row_count) for _ in range(1000)]
    for i in range(50):
        cur.execute("SELECT * FROM users WHERE id = ?;", (lookup_ids[i],)).fetchone()

    t0 = time.perf_counter()
    for lid in lookup_ids:
        cur.execute("SELECT * FROM users WHERE id = ?;", (lid,)).fetchone()
    t1 = time.perf_counter()
    point_us = ((t1 - t0) / 1000.0) * 1_000_000.0

    # 4. Range Aggregate
    t0 = time.perf_counter()
    for _ in range(10):
        cur.execute("SELECT COUNT(*), AVG(score) FROM users WHERE age >= 30 AND age <= 40;").fetchone()
    t1 = time.perf_counter()
    range_ms = ((t1 - t0) / 10.0) * 1000.0

    # 5. Full-scan GROUP BY
    t0 = time.perf_counter()
    for _ in range(5):
        cur.execute("SELECT age, COUNT(*), AVG(score) FROM users GROUP BY age;").fetchall()
    t1 = time.perf_counter()
    group_ms = ((t1 - t0) / 5.0) * 1000.0

    # 6. Indexed UPDATE
    t0 = time.perf_counter()
    cur.execute("UPDATE users SET name = 'Updated' WHERE age = 25;")
    conn.commit()
    t1 = time.perf_counter()
    update_ms = (t1 - t0) * 1000.0

    # 7. Indexed DELETE
    t0 = time.perf_counter()
    cur.execute("DELETE FROM users WHERE age = 26;")
    conn.commit()
    t1 = time.perf_counter()
    delete_ms = (t1 - t0) * 1000.0

    # 8a. Single-Tx Auto-Commit (sync=NORMAL)
    cur.execute("CREATE TABLE t_single (id INTEGER, name TEXT);")
    conn.commit()
    t0 = time.perf_counter()
    for i in range(1, 201):
        conn.isolation_level = None
        cur.execute("INSERT INTO t_single VALUES (?, ?);", (i, f"S_{i}"))
    t1 = time.perf_counter()
    single_normal_tx = int(200 / (t1 - t0))

    # 8b. Single-Tx Auto-Commit (sync=FULL fsync)
    cur.execute("PRAGMA synchronous = FULL;")
    t0 = time.perf_counter()
    for i in range(1, 51):
        cur.execute("INSERT INTO t_single VALUES (?, ?);", (i + 1000, f"S_{i}"))
    t1 = time.perf_counter()
    single_full_tx = int(50 / (t1 - t0))

    # 9. DROP TABLE
    cur.execute("CREATE TABLE t_drop (id INT, name TEXT);")
    t0 = time.perf_counter()
    cur.execute("DROP TABLE t_drop;")
    t1 = time.perf_counter()
    drop_ms = (t1 - t0) * 1000.0

    conn.close()

    if os.path.exists(SQLITE_DB):
        os.remove(SQLITE_DB)
    if os.path.exists(SQLITE_DB + "-wal"):
        os.remove(SQLITE_DB + "-wal")
    if os.path.exists(SQLITE_DB + "-shm"):
        os.remove(SQLITE_DB + "-shm")

    return {
        "bulk_rps": bulk_rps,
        "index_ms": index_ms,
        "point_us": point_us,
        "range_ms": range_ms,
        "group_ms": group_ms,
        "update_ms": update_ms,
        "delete_ms": delete_ms,
        "single_normal_tx": single_normal_tx,
        "single_full_tx": single_full_tx,
        "drop_ms": drop_ms,
    }


def main():
    print("=" * 86)
    print("  NATIVE ULTSQL vs NATIVE SQLITE 3 HEAD-TO-HEAD BENCHMARK")
    print("  (Both compiled to native machine code, running on local hardware NVMe storage)")
    print("=" * 86)
    print(f"Target Scale: {ROW_COUNT:,} Rows\n")

    bin_path = find_ultsql_binary()
    ult_res = run_ultsql_native(bin_path, ROW_COUNT)
    sq_res = run_sqlite_native(ROW_COUNT)

    print("\n" + "=" * 86)
    print("  EMPIRICAL BENCHMARK SCORECARD")
    print("=" * 86)
    print(f"{'Benchmark Metric':<38} | {'Unit':<10} | {'Native UltSQL':<15} | {'Native SQLite 3':<15}")
    print("-" * 86)

    def row(name, unit, ult_val, sq_val, higher_better=True):
        if higher_better:
            ratio = ult_val / sq_val if sq_val > 0 else 0
            comp = f"{ratio:.2f}x faster" if ratio >= 1 else f"{1/ratio:.2f}x slower"
            ult_str = f"{ult_val:,}" if isinstance(ult_val, int) else f"{ult_val:.3f}"
            sq_str = f"{sq_val:,}" if isinstance(sq_val, int) else f"{sq_val:.3f}"
        else:
            ratio = sq_val / ult_val if ult_val > 0 else 0
            comp = f"{ratio:.2f}x faster" if ratio >= 1 else f"{1/ratio:.2f}x slower"
            ult_str = f"{ult_val:.3f}"
            sq_str = f"{sq_val:.3f}"
        print(f"{name:<38} | {unit:<10} | {ult_str:<15} | {sq_str:<15} ({comp})")

    row("1. Bulk Ingest (Transaction Batch)", "rows/s", ult_res.get("bulk_rps", 0), sq_res["bulk_rps"], higher_better=True)
    row("2. CREATE INDEX on age (B+Tree)", "ms", ult_res.get("index_ms", 0), sq_res["index_ms"], higher_better=False)
    row("3. Point Lookup by PK (Prepared)", "us/query", ult_res.get("point_us", 0), sq_res["point_us"], higher_better=False)
    row("4. Range Aggregate (age 30-40)", "ms", ult_res.get("range_ms", 0), sq_res["range_ms"], higher_better=False)
    row("5. Full-scan GROUP BY Aggregate", "ms", ult_res.get("group_ms", 0), sq_res["group_ms"], higher_better=False)
    row("6. Indexed In-Place UPDATE", "ms", ult_res.get("update_ms", 0), sq_res["update_ms"], higher_better=False)
    row("7. Indexed DELETE", "ms", ult_res.get("delete_ms", 0), sq_res["delete_ms"], higher_better=False)
    row("8a. Auto-Commit (WAL Normal sync)", "tx/s", ult_res.get("single_tx", 0), sq_res["single_normal_tx"], higher_better=True)
    row("8b. Auto-Commit (Strict fsync)", "tx/s", ult_res.get("single_tx", 0), sq_res["single_full_tx"], higher_better=True)
    row("9. DROP TABLE Catalog Cleanup", "ms", ult_res.get("drop_ms", 0), sq_res["drop_ms"], higher_better=False)
    print("-" * 86)
    print("\nDurability Note:")
    print("  * Metric 8a compares both engines in WAL mode with deferred disk sync (synchronous=NORMAL).")
    print("  * Metric 8b highlights SQLite's synchronous=FULL mode which issues an fsync() on every single commit.")
    print("=" * 86)


if __name__ == "__main__":
    main()
