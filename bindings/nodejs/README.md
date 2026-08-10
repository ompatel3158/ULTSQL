# 🟢 UltSQL Node.js & TypeScript Package (`ultsql`)

The official Node.js & TypeScript client for **UltSQL** — the converged multimodal database engine combining Relational SQL, NoSQL JSON, HNSW Vector RAG, and PL/SQL.

---

## ⚡ Installation

```bash
npm install ultsql
```

### 💻 Install the `ultsql` CLI (1-Line Auto-Installer)

If you want to run the standalone `ultsql` server daemon or interactive CLI shell directly from your system terminal:

- **Windows (PowerShell)**:
  ```powershell
  iwr -useb https://raw.githubusercontent.com/ompatel3158/ULTSQL/main/install.ps1 | iex
  ```
- **Linux & macOS (Bash)**:
  ```bash
  curl -sSL https://raw.githubusercontent.com/ompatel3158/ULTSQL/main/install.sh | bash
  ```

After installation, open a new terminal window and run `ultsql --help` or `ultsql server`.

---

## 🚀 Quickstart Usage

```javascript
const { UltSQLClient } = require('ultsql');

// Connect to running UltSQL instance (via REST or PgWire)
const db = new UltSQLClient({ host: 'localhost', port: 8080 });

async function main() {
  // 1. Insert record
  await db.insert('users', { id: 1, name: 'Alice', score: 95.5 });

  // 2. Query records
  const result = await db.query('users');
  console.log('Users:', result.rows);
}

main();
```

---

## 🔌 PostgreSQL Wire Protocol Compatibility

You can also connect to UltSQL from Node.js using standard `pg` (`node-postgres`):

```javascript
const { Client } = require('pg');

const client = new Client({ host: 'localhost', port: 5432, user: 'admin', database: 'ultsql_db' });
await client.connect();

const res = await client.query('SELECT * FROM users');
console.log('Rows:', res.rows);
```
