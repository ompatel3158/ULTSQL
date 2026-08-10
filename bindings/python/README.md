# 🐍 UltSQL for Python Developers

**Zero Dart / Zero Setup Required!** 

If you are a Python developer, you **DO NOT need Dart or Flutter installed on your machine**. Everything works using standard Python code and tools (`pip`).

---

## 🚀 Quickstart Guide for Python Developers

### Step 1: Install Package
```bash
pip install ultsql
```

### 💻 Install the `ultsql` CLI (1-Line Auto-Installer)
If you want to run the standalone `ultsql` server daemon or interactive CLI shell directly from your terminal:

- **Windows (PowerShell)**:
  ```powershell
  iwr -useb https://raw.githubusercontent.com/ompatel3158/ULTSQL/main/install.ps1 | iex
  ```
- **Linux & macOS (Bash)**:
  ```bash
  curl -sSL https://raw.githubusercontent.com/ompatel3158/ULTSQL/main/install.sh | bash
  ```

After running the installer, open a new terminal and type `ultsql --help` or `ultsql server`.

### Step 2: Use in Python

#### Method A: Using the UltSQL Python Client (REST API)
```python
from ultsql import UltSQLClient

# Connect to ULTSQL
db = UltSQLClient("http://localhost:8080")

# 1. Insert records
db.insert("users", {"id": 1, "name": "Alice", "score": 98.5})

# 2. Query records
users = db.query("users")
print("User rows:", users["rows"])

# 3. Truncate table
db.truncate("users")
```

#### Method B: Using Standard PostgreSQL Drivers (`psycopg2` / `asyncpg`)
Because ULTSQL speaks the **PostgreSQL Wire Protocol**, you can use standard Python database libraries:

```bash
pip install psycopg2-binary
```

```python
import psycopg2

# Connect to ULTSQL PostgreSQL wire port (default: 5432)
conn = psycopg2.connect("host=localhost port=5432 user=admin password=admin dbname=ultsql_db")
cur = conn.cursor()

cur.execute("SELECT * FROM users WHERE score >= %s", (90.0,))
rows = cur.fetchall()
print("Postgres Client Rows:", rows)
```

---

## ❓ Frequently Asked Questions for Python Users

- **Do I need to install Dart or Flutter?**  
  **No!** Python developers only need Python and `pip`.
- **Can I run ULTSQL without any background server app?**  
  **Yes!** ULTSQL bundles precompiled dynamic C libraries (`libultsql.so` on Linux, `ultsql.dll` on Windows, `libultsql.dylib` on macOS) so the database engine can run directly inside Python process memory just like SQLite.
