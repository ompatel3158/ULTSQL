# 🐍 UltSQL for Python Developers

**Universal Embedded & Client SDK for UltSQL**

UltSQL provides a fast, multi-model database engine (Relational SQL, JSON Document store, KV caching, Vector HNSW embeddings) for Python applications.

---

## 🏛 Architecture

Understanding the client-runtime architecture:

```text
Python Application
        ↓
UltSQL Python SDK (client package)
        ↓  (HTTP / REST JSON)
local UltSQL server process (strictly 127.0.0.1)
        ↓
Database File (*.ultsql)
```

The Python package `ultsql` is a **Client SDK**. The compiled native binary is the **Server Runtime**.

UltSQL supports two operating modes:
1. **Embedded / Local Mode**: The SDK manages a local engine helper process running on `127.0.0.1` when `auto_start=True` or `UltSQL.open()` is used.
2. **Client Mode**: Connects directly to an already-running local or remote UltSQL server (`auto_start=False`).

---

## 🚀 Quickstart Guide

### 1. Installation

```bash
pip install ultsql
```

`pip` downloads the prebuilt native wheel with the engine runtime for your platform (`win_amd64`, `manylinux_2_28_x86_64`, `manylinux_2_28_aarch64`, `macosx_11_0_x86_64`, `macosx_11_0_arm64`). **Zero Dart or external dependencies required.**

---

### 2. Usage Modes

#### Mode 1: Convenient Local Mode (Opt-in `auto_start=True`)

In this mode, UltSQL starts a local helper engine on loopback (`127.0.0.1`), assigns a random available port (or specified port), and terminates cleanly when the application exits.

```python
import ultsql

# Convenient local mode launcher
db = ultsql.open("./app.ultsql", auto_start=True)

# Or via UltSQLClient with full configuration:
# db = ultsql.UltSQLClient("./app.ultsql", auto_start=True, host="127.0.0.1", port=0)

# Check status
print(db.status())
# Output: {'status': 'online', 'host': '127.0.0.1', 'port': 54321, 'pid': 1234, ...}

# 1. Execute SQL DDL / Queries
db.sql("""
    CREATE TABLE users (
        id INT PRIMARY KEY,
        name TEXT,
        score DOUBLE
    );
""")

# 2. Insert records
db.insert("users", {"id": 1, "name": "Alice", "score": 98.5})

# 3. High-throughput batch insert
db.insert_batch("users", [
    {"id": 2, "name": "Bob", "score": 91.2},
    {"id": 3, "name": "Charlie", "score": 87.0},
])

# 4. Query table records
users = db.query("users")
print("User rows:", users["rows"])

# 5. Clean close (also handled automatically on exit via atexit)
db.close()
```

#### Using Context Managers:
```python
with ultsql.open("./app.ultsql") as db:
    db.sql("SELECT 1;")
```

#### Mode 2: Client Mode (Connecting to an Existing Server)

When connecting to an already-running local or remote server, pass the URL (`auto_start=False` by default):

```python
from ultsql import UltSQLClient

# Connect to local dev server or remote instance
client = UltSQLClient("http://127.0.0.1:8080")

users = client.query("users")
print(users)
```

---

## 🛠 Running the Server Explicitly via CLI

Advanced users can launch the server runtime explicitly from the terminal:

```bash
# Development server (defaults to 127.0.0.1:8080 with live logs)
ultsql dev --db ./app.ultsql

# Or standard production server daemon
ultsql serve --host 127.0.0.1 --port 8080 --db ./app.ultsql
```

---

## 🔒 Security & Lifecycle Guarantees

- **Loopback Binding**: Local engine servers bind exclusively to `127.0.0.1`, never `0.0.0.0`.
- **Port Conflict Safe**: Defaults to dynamic port allocation (`port=0`) to avoid conflicts.
- **Process Reuse**: Multiple client instances accessing the same database file share a single engine process instead of spawning redundant servers.
- **Explicit Lifecycle**: Complete control with `db.status()`, `db.stop()`, `db.close()`, and automatic cleanup upon exit.
- **Transparency**: Clear startup logging: `UltSQL local server started on 127.0.0.1:<port>`.

---

## 🐘 PostgreSQL Wire Protocol Support

Because UltSQL also provides a native PostgreSQL wire protocol listener:

```bash
pip install psycopg2-binary
```

```python
import psycopg2

conn = psycopg2.connect("host=127.0.0.1 port=5432 user=admin password=admin dbname=ultsql_db")
cur = conn.cursor()
cur.execute("SELECT * FROM users WHERE score >= %s", (90.0,))
rows = cur.fetchall()
print("Rows:", rows)
```
