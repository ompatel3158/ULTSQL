// Package ultsql provides the official Go client and embedded launcher for the converged UltSQL database engine.
package ultsql

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sync"
	"time"

	_ "github.com/lib/pq"
)

// Client represents an HTTP/REST connection to an active UltSQL daemon.
type Client struct {
	baseURL    string
	httpClient *http.Client
}

// QueryResult represents the structured response returned by UltSQL.
type QueryResult struct {
	Columns         []string        `json:"columns"`
	Rows            [][]interface{} `json:"rows"`
	Message         string          `json:"message"`
	ExecutionTimeMs float64         `json:"execution_time_ms"`
}

// NewClient initializes a new UltSQL REST client for a remote server.
func NewClient(baseURL string) *Client {
	return &Client{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// FindEngineBinary searches for the ultsql standalone executable.
func FindEngineBinary() (string, error) {
	if envBin := os.Getenv("ULTSQL_BINARY_PATH"); envBin != "" {
		if _, err := os.Stat(envBin); err == nil {
			return envBin, nil
		}
	}

	exeName := "ultsql"
	if runtime.GOOS == "windows" {
		exeName = "ultsql.exe"
	}

	// 1. Search PATH
	if p, err := exec.LookPath(exeName); err == nil {
		return p, nil
	}

	// 2. Search common development and repository paths
	candidates := []string{
		filepath.Join(".", "bin", exeName),
		filepath.Join(".", "build", "bin", exeName),
		filepath.Join("..", "bin", exeName),
		filepath.Join("..", "..", "build", "bin", exeName),
	}
	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			abs, err := filepath.Abs(c)
			if err == nil {
				return abs, nil
			}
			return c, nil
		}
	}

	return "", fmt.Errorf("could not locate ultsql binary (%s); install via install.sh / install.ps1 or set ULTSQL_BINARY_PATH", exeName)
}

func findFreePort() (int, error) {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return 0, err
	}
	defer l.Close()
	return l.Addr().(*net.TCPAddr).Port, nil
}

// LocalClient wraps a Client connected to a locally spawned UltSQL engine process.
type LocalClient struct {
	*Client
	cmd    *exec.Cmd
	Port   int
	DBPath string
	mu     sync.Mutex
	closed bool
}

// Close gracefully terminates the spawned UltSQL engine process.
func (lc *LocalClient) Close() error {
	lc.mu.Lock()
	defer lc.mu.Unlock()
	if lc.closed {
		return nil
	}
	lc.closed = true
	if lc.cmd != nil && lc.cmd.Process != nil {
		return lc.cmd.Process.Kill()
	}
	return nil
}

// Open launches a bundled UltSQL engine process on a free port, waits until it's healthy,
// and returns a ready-to-use LocalClient.
func Open(dbPath string) (*LocalClient, error) {
	binPath, err := FindEngineBinary()
	if err != nil {
		return nil, err
	}

	port, err := findFreePort()
	if err != nil {
		return nil, fmt.Errorf("failed to allocate free port: %w", err)
	}

	cmd := exec.Command(binPath, "serve", "--db", dbPath, "--port", fmt.Sprintf("%d", port))
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("failed to start ultsql process: %w", err)
	}

	baseURL := fmt.Sprintf("http://127.0.0.1:%d", port)
	client := NewClient(baseURL)
	lc := &LocalClient{
		Client: client,
		cmd:    cmd,
		Port:   port,
		DBPath: dbPath,
	}

	// Poll health check until online
	deadline := time.Now().Add(10 * time.Second)
	healthy := false
	for time.Now().Before(deadline) {
		resp, err := http.Get(baseURL + "/")
		if err == nil {
			var body map[string]interface{}
			if json.NewDecoder(resp.Body).Decode(&body) == nil {
				if status, ok := body["status"].(string); ok && status == "online" {
					resp.Body.Close()
					healthy = true
					break
				}
			}
			resp.Body.Close()
		}
		time.Sleep(50 * time.Millisecond)
	}

	if !healthy {
		_ = lc.Close()
		return nil, fmt.Errorf("ultsql engine failed to become healthy within 10s on port %d", port)
	}

	return lc, nil
}

// Query executes an SQL, NoSQL JSON, or Vector query script and returns the result set.
func (c *Client) Query(ctx context.Context, sqlScript string) (*QueryResult, error) {
	reqBody, err := json.Marshal(map[string]string{
		"query": sqlScript,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to encode query request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/query", bytes.NewReader(reqBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create http request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to execute request against UltSQL: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("ultsql error (%d): %s", resp.StatusCode, string(body))
	}

	var res QueryResult
	if err := json.Unmarshal(body, &res); err != nil {
		return nil, fmt.Errorf("failed to parse QueryResult: %w", err)
	}

	return &res, nil
}

// Insert inserts a single record map into the target table with automatic schema detection.
func (c *Client) Insert(ctx context.Context, tableName string, record map[string]interface{}) (*QueryResult, error) {
	reqBody, err := json.Marshal(record)
	if err != nil {
		return nil, fmt.Errorf("failed to encode record: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, fmt.Sprintf("%s/%s", c.baseURL, tableName), bytes.NewReader(reqBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create http request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to insert record into UltSQL: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var res QueryResult
	if err := json.Unmarshal(body, &res); err != nil {
		return nil, fmt.Errorf("failed to parse insert response: %w", err)
	}

	return &res, nil
}

// InsertBatch inserts a batch of records into the target table with high-throughput batch ingestion.
func (c *Client) InsertBatch(ctx context.Context, tableName string, records []map[string]interface{}) (*QueryResult, error) {
	reqBody, err := json.Marshal(records)
	if err != nil {
		return nil, fmt.Errorf("failed to encode records: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, fmt.Sprintf("%s/%s/batch", c.baseURL, tableName), bytes.NewReader(reqBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create http request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to batch insert records into UltSQL: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var res QueryResult
	if err := json.Unmarshal(body, &res); err != nil {
		return nil, fmt.Errorf("failed to parse batch insert response: %w", err)
	}

	return &res, nil
}

// OpenPgWire connects to UltSQL using the standard Go database/sql interface over TCP PgWire.
func OpenPgWire(host string, port int, user, password, dbname string) (*sql.DB, error) {
	connStr := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)
	return sql.Open("postgres", connStr)
}
