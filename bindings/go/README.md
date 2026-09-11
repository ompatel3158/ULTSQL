# 🐹 UltSQL Go Client SDK

Official Go client for **UltSQL** — the converged multimodal database engine combining Relational SQL, NoSQL JSON, HNSW Vector RAG, and PL/SQL.

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

## 🚀 Usage Example

```go
package main

import (
	"context"
	"fmt"
	"log"

	"github.com/ompatel3158/ULTSQL/bindings/go"
)

func main() {
	client := ultsql.NewClient("http://localhost:8080")

	// 1. High-speed batch ingestion
	_, err := client.InsertBatch(context.Background(), "users", []map[string]interface{}{
		{"id": 1, "name": "Alice", "score": 98.5},
		{"id": 2, "name": "Bob", "score": 91.0},
		{"id": 3, "name": "Charlie", "score": 88.5},
	})
	if err != nil {
		log.Fatalf("InsertBatch failed: %v", err)
	}

	// 2. Query record
	res, err := client.Query(context.Background(), "SELECT * FROM users WHERE score > 90.0;")
	if err != nil {
		log.Fatalf("Query failed: %v", err)
	}

	fmt.Printf("Returned %d rows in %.2f ms\n", len(res.Rows), res.ExecutionTimeMs)
}
```
