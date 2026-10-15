# 🐍 UltSQL for Python Developers

**Zero Dart / Zero External Services Required!** 

When using `ultsql` in Python, **a small bundled engine process starts automatically** on a free port, waits until it's healthy, and terminates cleanly when your application exits. You **DO NOT need Dart or Flutter installed on your machine**—everything is shipped inside native platform wheels via `pip`.

---

## 🚀 Quickstart Guide for Python Developers

### Step 1: Install Package
```bash
pip install ultsql
```
`pip` automatically downloads the native wheel for your OS and architecture (`win_amd64`, `manylinux_2_28_x86_64`, `manylinux_2_28_aarch64`, `macosx_11_0_x86_64`, `macosx_11_0_arm64`).

---

### Step 2: Use in Python

#### Method A: Embedded Auto-Start Launcher (Recommended)
```python
import ultsql

# Embedded mode: starts a small bundled engine process automatically on a free port,
# polls the health endpoint, and cleans up on exit.
db = ultsql.open("app.db")

# 1. Execute SQL DDL / Queries
db.sql("""
    CREATE TABLE users (
        id INT PRIMARY KEY,
        name TEXT,
        score DOUBLE
    );
""")

# 2. Single record insert
db.insert("users", {"id": 1, "name": "Alice", "score": 98.5})

# 3. High-throughput batch insert
db.insert_batch("users", [
    {"id": 2, "name": "Bob", "score": 91.2},
    {"id": 3, "name": "Charlie", "score": 87.0},
])

# 4. Query table records
users = db.query("users")
print("User rows:", users["rows"])

# 5. Clean close (also registered via atexit automatically)
db.close()
```

#### Method B: Connect to a Remote UltSQL Server
If you already run a remote UltSQL instance or Docker container, use `UltSQLClient`:
```python
from ultsql import UltSQLClient

client = UltSQLClient("http://remote-server:8080")
users = client.query("users")
```

#### Method C: Standard PostgreSQL Drivers (`psycopg2` / `asyncpg`)
Because UltSQL also provides a native **PostgreSQL Wire Protocol** daemon, you can connect with standard PostgreSQL drivers:

```bash
pip install psycopg2-binary
```

```python
import psycopg2

conn = psycopg2.connect("host=localhost port=5432 user=admin password=admin dbname=ultsql_db")
cur = conn.cursor()
cur.execute("SELECT * FROM users WHERE score >= %s", (90.0,))
rows = cur.fetchall()
print("Rows:", rows)
```

---

## 💻 Standalone CLI (Optional)
If you also want to run the standalone `ultsql` CLI shell or server daemon directly from your command prompt:

- **Windows (PowerShell)**:
  ```powershell
  iwr -useb https://raw.githubusercontent.com/ompatel3158/ULTSQL/main/install.ps1 | iex
  ```
- **Linux & macOS (Bash)**:
  ```bash
  curl -sSL https://raw.githubusercontent.com/ompatel3158/ULTSQL/main/install.sh | bash
  ```

---

## ❓ Frequently Asked Questions for Python Users

- **Do I need to install Dart or Flutter?**  
  **No!** Native compiled binaries are bundled directly within the platform wheels.
- **How does it work under the hood?**  
  When you call `ultsql.open("app.db")`, a small bundled engine process starts automatically in the background on an ephemeral port, verifies readiness via local health check, and tears down automatically upon script completion.
- **Can I connect to remote instances?**  
  Yes! Use `ultsql.UltSQLClient("http://host:port")` to communicate with any remote UltSQL REST or PGWire server.
