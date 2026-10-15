# 🟢 UltSQL Node.js & TypeScript Package (`ultsql`)

The official Node.js & TypeScript client and embedded engine launcher for **UltSQL** - the converged multimodal database engine combining Relational SQL, NoSQL JSON, HNSW Vector RAG, and PL/SQL.

When using `ultsql` in Node.js, **a small bundled engine process starts automatically** using the esbuild distribution pattern (via platform-specific optionalDependencies like `@ultsql/win32-x64`, `@ultsql/linux-x64`, `@ultsql/darwin-arm64`).

---

## ⚡ Installation

```bash
npm install ultsql
```

npm automatically installs only the matching platform package for your OS and architecture.

---

## 🚀 Quickstart Usage

### Method A: Embedded Auto-Start Launcher (Recommended)
```javascript
const ultsql = require('ultsql');

async function main() {
  // Starts a small bundled engine process automatically on a free port,
  // polls the health endpoint, and cleans up on process exit.
  const db = await ultsql.open('app.db');

  // 1. Execute SQL DDL
  await db.sql(`
    CREATE TABLE users (
      id INT PRIMARY KEY,
      name TEXT,
      score DOUBLE
    );
  `);

  // 2. High-speed batch ingestion
  await db.insertBatch('users', [
    { id: 1, name: 'Alice', score: 95.5 },
    { id: 2, name: 'Bob', score: 88.0 },
    { id: 3, name: 'Charlie', score: 92.3 }
  ]);

  // 3. Single record insert
  await db.insert('users', { id: 4, name: 'Diana', score: 99.0 });

  // 4. Query records
  const result = await db.query('users');
  console.log('Users:', result.rows);

  // 5. Explicit close (also auto-cleaned on process termination)
  db.close();
}

main();
```

### Method B: Connect to a Remote UltSQL Instance
```javascript
const { UltSQLClient } = require('ultsql');

// Connect to existing UltSQL REST server
const client = new UltSQLClient({ host: 'remote-server', port: 8080 });
const users = await client.query('users');
```

### Method C: PostgreSQL Wire Protocol Compatibility
You can also connect to UltSQL from Node.js using standard `pg` (`node-postgres`):

```bash
npm install pg
```

```javascript
const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  user: 'admin',
  database: 'ultsql_db'
});
await client.connect();

const res = await client.query('SELECT * FROM users');
console.log('Rows:', res.rows);
```

---

## 💻 Standalone CLI (Optional)
If you want to run the standalone `ultsql` server daemon or interactive CLI shell directly from your terminal:

- **Windows (PowerShell)**:
  ```powershell
  iwr -useb https://raw.githubusercontent.com/ompatel3158/ULTSQL/main/install.ps1 | iex
  ```
- **Linux & macOS (Bash)**:
  ```bash
  curl -sSL https://raw.githubusercontent.com/ompatel3158/ULTSQL/main/install.sh | bash
  ```
