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

# 1. High-speed batch ingestion (slotted pages & B+Tree indexed)
db.insert_batch("users", [
    {"id": 1, "name": "Alice", "score": 98.5},
    {"id": 2, "name": "Bob", "score": 91.2},
    {"id": 3, "name": "Charlie", "score": 87.0},
])

# 2. Single record insert
db.insert("users", {"id": 4, "name": "Diana", "score": 95.0})

# 3. Query records
users = db.query("users")
print("User rows:", users["rows"])

# 4. Truncate table
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
- **How do I run the UltSQL database?**  
  Use the 1-line auto-installer to install the standalone `ultsql` executable on Windows, Linux, or macOS. Then simply run `ultsql serve` to start the daemon, or use `ultsql import data.csv users` for direct batch ingestion.

