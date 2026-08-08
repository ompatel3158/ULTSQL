# 🟢 UltSQL Node.js & TypeScript Package (`ultsql`)

The official Node.js & TypeScript client for **UltSQL** — the converged multimodal database engine combining Relational SQL, NoSQL JSON, HNSW Vector RAG, and PL/SQL.

---

## ⚡ Installation

```bash
npm install ultsql
```

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
