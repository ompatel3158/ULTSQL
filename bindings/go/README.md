# 🐹 UltSQL Go Client SDK

Official Go client and embedded engine launcher for **UltSQL** - the converged multimodal database engine combining Relational SQL, NoSQL JSON, HNSW Vector RAG, and PL/SQL.

When using `ultsql` in Go, **a small bundled engine process starts automatically** on a free port using `ultsql.Open("app.db")`, or you can connect to an existing remote instance using `ultsql.NewClient(...)`.

---

## ⚡ Installation

```bash
go get github.com/ompatel3158/ULTSQL/bindings/go
```

---

## 💻 1-Line Standalone CLI Installation (Auto-adds to PATH)

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
```go
package main

import (
	"context"
	"fmt"
	"log"

	"github.com/ompatel3158/ULTSQL/bindings/go"
)

func main() {
	// Starts a small bundled engine process automatically on a free port,
	// waits until healthy, and tears down cleanly when closed.
	db, err := ultsql.Open("app.db")
	if err != nil {
		log.Fatalf("Failed to open UltSQL: %v", err)
	}
	defer db.Close()

	ctx := context.Background()

	// 1. High-speed batch ingestion
	_, err = db.InsertBatch(ctx, "users", []map[string]interface{}{
		{"id": 1, "name": "Alice", "score": 98.5},
		{"id": 2, "name": "Bob", "score": 91.0},
		{"id": 3, "name": "Charlie", "score": 88.5},
	})
	if err != nil {
		log.Fatalf("InsertBatch failed: %v", err)
	}

	// 2. Query records
	res, err := db.Query(ctx, "SELECT * FROM users WHERE score > 90.0;")
	if err != nil {
		log.Fatalf("Query failed: %v", err)
	}

	fmt.Printf("Returned %d rows in %.2f ms\n", len(res.Rows), res.ExecutionTimeMs)
}
```

### Method B: Connect to a Remote UltSQL Instance
```go
client := ultsql.NewClient("http://remote-server:8080")
res, err := client.Query(context.Background(), "SELECT * FROM users;")
```

### Method C: Standard Go `database/sql` over PostgreSQL Wire Protocol
```go
import (
	"database/sql"
	_ "github.com/lib/pq"
)

db, err := sql.Open("postgres", "postgres://admin:admin@localhost:5432/ultsql_db?sslmode=disable")
rows, err := db.Query("SELECT name, score FROM users WHERE score >= $1", 90.0)
```
