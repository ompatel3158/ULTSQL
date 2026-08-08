# 📘 UltSQL Complete User Manual & Documentation

Welcome to the official user manual for **UltSQL** — the converged 4-in-1 multimodal database engine combining Relational SQL, NoSQL JSON, HNSW Vector RAG, and PL/SQL.

---

## 📖 Table of Contents
1. [Starting the UltSQL Server Daemon](#1-starting-the-ultsql-server-daemon)
2. [CLI Terminal Commands & Meta Options](#2-cli-terminal-commands--meta-options)
3. [Python Package (`pip install ultsql`)](#3-python-package-pip-install-ultsql)
4. [Node.js Package (`npm install ultsql`)](#4-nodejs-package-npm-install-ultsql)
5. [PostgreSQL Wire Protocol Connections](#5-postgresql-wire-protocol-connections)
6. [Standalone Binaries (Windows, Linux, macOS)](#6-standalone-binaries-windows-linux-macos)
7. [Advanced Multimodal SQL Features](#7-advanced-multimodal-sql-features)

---

## 1. Starting the UltSQL Server Daemon

### Option A: Standalone Native Executable (Zero Dependencies)
No Flutter, Dart, Python, or Node required! Download `ultsql.exe` from [GitHub Releases](https://github.com/ompatel3158/ULTSQL/releases):

```bash
# Start REST & OpenAPI Daemon on port 8080
./ultsql serve --port 8080 --db ./my_database

# Start PostgreSQL Wire Server on port 5432
./ultsql .pgwire 5432
```

### Option B: Python `ultsql-server` CLI
Installed automatically when running `pip install ultsql`:

```bash
ultsql-server --port 8080 --db ./my_database
```

### Option C: Docker Container
Deploy on any cloud server or Kubernetes cluster:

```bash
docker run -p 8080:8080 -v ./data:/db ompatel3158/ultsql serve --port 8080 --db /db
```

---

## 2. CLI Terminal Commands & Meta Options

Inside the interactive `ultsql` CLI prompt:

| Command | Description | Example |
| :--- | :--- | :--- |
| `ultsql serve [--port] [--db]` | Launches HTTP REST daemon and live OpenAPI 3.0 specification. | `ultsql serve --port 8080 --db ./app.db` |
| `.pgwire [port]` | Launches PostgreSQL Wire Protocol server daemon. | `.pgwire 5432` |
| `.tables` | Lists all tables in the active catalog. | `.tables` |
| `.schema [table]` | Displays DDL column definitions for a table. | `.schema users` |
| `.databases` | Displays active database storage path. | `.databases` |
| `.exit` / `exit` | Flushes WAL logs and exits session. | `.exit` |

---

## 3. Python Package (`pip install ultsql`)

No Dart or Flutter required! Full PEP 621 PyPA compliance.

```bash
pip install ultsql
```

```python
from ultsql import UltSQLClient

# Connect to UltSQL Daemon
db = UltSQLClient("http://localhost:8080")

# 1. Insert record (Auto-creates table schema if missing)
db.insert("products", {"id": 1, "name": "Quantum Laptop", "price": 1299.99})

# 2. Fetch records
result = db.query("products")
print("Count:", result["count"])
print("Rows:", result["rows"])

# 3. OpenAPI 3.0 Documentation Specification
spec = db.openapi_spec()
print("OpenAPI Title:", spec["info"]["title"])
```

---

## 4. Node.js Package (`npm install ultsql`)

Includes TypeScript definitions (`index.d.ts`) and supports both default and named imports.

```bash
npm install ultsql
```

```javascript
const { UltSQLClient } = require('ultsql');

const db = new UltSQLClient({ host: 'localhost', port: 8080 });

async function run() {
  // Insert record
  await db.insert('users', { id: 101, name: 'Om Patel', tier: 'VIP' });

  // Query records
  const result = await db.query('users');
  console.log('Users:', result.rows);
}

run();
```

---

## 5. PostgreSQL Wire Protocol Connections

Connect directly using standard Postgres drivers in any language:

- **Python (`psycopg2`)**: `psycopg2.connect("host=localhost port=5432 user=admin password=admin dbname=ultsql_db")`
- **Node.js (`pg`)**: `new Client({ host: 'localhost', port: 5432, user: 'admin', database: 'ultsql_db' })`
- **Java (`JDBC`)**: `DriverManager.getConnection("jdbc:postgresql://localhost:5432/ultsql_db", "admin", "admin")`
- **Go (`lib/pq`)**: `sql.Open("postgres", "host=localhost port=5432 user=admin dbname=ultsql_db sslmode=disable")`
- **CLI (`psql`)**: `psql -h localhost -p 5432 -U admin -d ultsql_db`

---

## 6. Standalone Binaries (Windows, Linux, macOS)

Precompiled native machine code executables with **ZERO dependencies**:

- **Windows**: `ultsql.exe`
- **Linux**: `ultsql-linux`
- **macOS**: `ultsql-mac`

Run anywhere with zero installation!

---

## 7. Advanced Multimodal SQL Features

### Reactive Query Streams (`db.watch()`)
```dart
final stream = db.watch(interpreter, "SELECT * FROM users WHERE active = true");
stream.listen((result) {
  print("Updated rows: ${result.rows}");
});
```

### SQL Macros (`CREATE MACRO`)
```sql
CREATE MACRO calculate_tax(amount) AS amount * 0.15;
SELECT id, price, calculate_tax(price) AS tax FROM orders;
```

### Event Streams (`CREATE STREAM` & `EMIT TO`)
```sql
CREATE STREAM order_events;
EMIT TO order_events VALUES (101, 'order_placed', NOW());
```

### Database Branching (`ultsql branch`)
```dart
db.createBranch('feature-dev');
db.switchBranch('feature-dev');
db.mergeBranch('feature-dev', 'main');
```
