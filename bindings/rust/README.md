# 🦀 UltSQL Rust Client Crate

Official asynchronous Rust client for **UltSQL** — the converged multimodal database engine.

---

## ⚡ Installation

Add to your `Cargo.toml`:

```toml
[dependencies]
ultsql = "1.0.21"
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

## 🚀 Usage Example

```rust
use ultsql::UltSqlClient;
use serde_json::json;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = UltSqlClient::new("http://localhost:8080");

    // 1. High-speed batch ingestion
    client.insert_batch("users", &[
        json!({"id": 1, "name": "Alice", "score": 98.5}),
        json!({"id": 2, "name": "Bob", "score": 92.0}),
        json!({"id": 3, "name": "Charlie", "score": 89.0}),
    ]).await?;

    // 2. Query records
    let result = client.query("SELECT * FROM users WHERE score >= 90.0;").await?;
    println!("Columns: {:?}", result.columns);
    println!("Rows: {:?}", result.rows);

    Ok(())
}
```
