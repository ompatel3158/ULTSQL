# 🐍 UltSQL Python Package (`ultsql`)

The official Python client for **UltSQL** — the converged multimodal database engine combining Relational SQL, NoSQL JSON, HNSW Vector RAG, and PL/SQL.

---

## ⚡ Installation

```bash
pip install ultsql
```

---

## 🚀 Quickstart Usage

```python
from ultsql import UltSQLClient

# Connect to running UltSQL instance (via REST or PgWire)
db = UltSQLClient("http://localhost:8080")

# 1. Query records
result = db.query("users")
print("Users:", result["rows"])

# 2. Insert record
db.insert("users", {"id": 1, "name": "Alice", "score": 95.5})

# 3. Get OpenAPI 3.0 Documentation Schema
spec = db.openapi_spec()
print("OpenAPI Version:", spec["openapi"])
```

---

## 🔌 PostgreSQL Wire Protocol Compatibility

You can also connect to UltSQL from Python using standard `psycopg2` or `asyncpg`:

```python
import psycopg2

conn = psycopg2.connect("host=localhost port=5432 user=admin password=admin dbname=ultsql_db")
cur = conn.cursor()
cur.execute("SELECT * FROM users")
print(cur.fetchall())
```
