# 🦀 UltSQL Rust Client Crate

Official asynchronous Rust client and embedded engine launcher for **UltSQL** - the converged multimodal database engine.

When using `ultsql` in Rust, **a small bundled engine process starts automatically** on a free port using `UltSqlClient::open("app.db").await?`, or you can connect to an existing remote instance with `UltSqlClient::new(...)`.

---

## ⚡ Installation

Add to your `Cargo.toml`:

```toml
[dependencies]
ultsql = "1.0.29"
tokio = { version = "1.0", features = ["full"] }
serde_json = "1.0"
```

---

## 💻 1-Line Standalone CLI Installation

- **Windows (PowerShell)**:
  ```powershell
  iwr -useb https://raw.githubusercontent.com/ompatel3158/ULTSQL/main/install.ps1 | iex
  ```
- **Linux & macOS (Bash)**:
  ```bash
  curl -sSL https://raw.githubusercontent.com/ompatel3158/ULTSQL/main/install.sh | bash
  ```

---

## 🚀 Usage Examples

### Method A: Embedded Auto-Start Launcher (Recommended)
```rust
use ultsql::UltSqlClient;
use serde_json::json;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Starts a small bundled engine process automatically on a free port,
    // waits until healthy, and auto-terminates on drop.
    let db = UltSqlClient::open("app.db").await?;

    // 1. High-speed batch ingestion
    db.insert_batch("users", &[
        json!({"id": 1, "name": "Alice", "score": 98.5}),
        json!({"id": 2, "name": "Bob", "score": 92.0}),
        json!({"id": 3, "name": "Charlie", "score": 89.0}),
    ]).await?;

    // 2. Query records
    let result = db.query("SELECT * FROM users WHERE score >= 90.0;").await?;
    println!("Columns: {:?}", result.columns);
    println!("Rows: {:?}", result.rows);

    Ok(())
}
```

### Method B: Connect to a Remote UltSQL Instance
```rust
let client = UltSqlClient::new("http://remote-server:8080");
let result = client.query("SELECT * FROM users;").await?;
```

### Method C: PostgreSQL Wire Protocol over TCP (Port 5432)
```rust
// Using tokio-postgres or sqlx
let (client, connection) =
    tokio_postgres::connect("host=localhost port=5432 user=admin dbname=ultsql_db", tokio_postgres::NoTls).await?;
```
