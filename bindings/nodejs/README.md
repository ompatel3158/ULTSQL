# 🟢 UltSQL for Node.js & TypeScript Developers

**Universal Embedded & Client SDK for UltSQL**

UltSQL provides a fast, multi-model database engine (Relational SQL, JSON Document store, KV caching, Vector HNSW embeddings) for Node.js and TypeScript applications.

---

## 🏛 Architecture

Understanding the client-runtime architecture:

```text
Node.js / TypeScript Application
        ↓
UltSQL Node.js SDK (client package)
        ↓  (HTTP / REST JSON)
local UltSQL server process (strictly 127.0.0.1)
        ↓
Database File (*.ultsql)
```

The npm package `ultsql` is a **Client SDK**. The compiled native binary is the **Server Runtime**.

UltSQL supports two operating modes:
1. **Embedded / Local Mode**: The SDK manages a local engine helper process running on `127.0.0.1` when `auto_start: true` or `UltSQL.open()` is used.
2. **Client Mode**: Connects directly to an already-running local or remote UltSQL server (`auto_start: false`).

---

## ⚡ Installation

```bash
npm install ultsql
```

npm uses the `esbuild` distribution pattern via optional platform packages (`@ultsql/win32-x64`, `@ultsql/linux-x64`, `@ultsql/darwin-arm64`, etc.), downloading only the native engine binary for your machine. **Zero Dart or Flutter installation required.**

---

## 🚀 Usage Modes

### Mode 1: Convenient Local Mode (Opt-in `auto_start: true`)

In this mode, UltSQL starts a local helper engine on loopback (`127.0.0.1`), assigns a random available port (or specified port), and terminates cleanly when the application exits.

```javascript
const { UltSQL, UltSQLClient } = require('ultsql');

async function main() {
  // Convenient local mode launcher
  const db = await UltSQL.open('./app.ultsql', { auto_start: true });

  // Or explicitly with UltSQLClient:
  // const db = new UltSQLClient('./app.ultsql', { auto_start: true, host: '127.0.0.1', port: 0 });

  // Check health and metadata
  const status = await db.status();
  console.log('Status:', status);
  // Output: { status: 'online', host: '127.0.0.1', port: 54321, pid: 1234, ... }

  // 1. Execute SQL DDL / Queries
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

### Mode 2: Client Mode (Connecting to an Existing Server)

When connecting to an already-running local or remote server, pass the server URL (`auto_start: false` by default):

```javascript
const { UltSQLClient } = require('ultsql');

// Connect to existing UltSQL REST server
const client = new UltSQLClient('http://127.0.0.1:8080');

const users = await client.query('users');
console.log(users);
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
- **Port Conflict Safe**: Defaults to dynamic port allocation (`port: 0`) to avoid conflicts.
- **Process Reuse**: Multiple client instances accessing the same database file share a single engine process instead of spawning redundant servers.
- **Explicit Lifecycle**: Complete control with `db.status()`, `db.stop()`, `db.close()`, and automatic cleanup upon exit.
- **Transparency**: Clear startup logging: `UltSQL local server started on 127.0.0.1:<port>`.

---

## 🐘 PostgreSQL Wire Protocol Support

You can also connect to UltSQL from Node.js using standard `pg` (`node-postgres`):

```bash
npm install pg
```

```javascript
const { Client } = require('pg');

const client = new Client({
  host: '127.0.0.1',
  port: 5432,
  user: 'admin',
  database: 'ultsql_db'
});
await client.connect();

const res = await client.query('SELECT * FROM users');
console.log('Rows:', res.rows);
```
