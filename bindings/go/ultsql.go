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

// Options specifies runtime configuration for the UltSQL client and local launcher.
type Options struct {
	AutoStart bool
	Host      string
	Port      int
	Timeout   time.Duration
}

// DefaultOptions returns the default secure client options (loopback 127.0.0.1, auto_start=true).
func DefaultOptions() Options {
	return Options{
		AutoStart: true,
		Host:      "127.0.0.1",
		Port:      0,
		Timeout:   10 * time.Second,
	}
}

// LocalClient wraps a Client connected to a locally spawned UltSQL engine process.
type LocalClient struct {
	*Client
	cmd    *exec.Cmd
	Port   int
	Host   string
	DBPath string
	mu     sync.Mutex
	closed bool
}

var (
	processRegistry = make(map[string]*LocalClient)
	registryMu      sync.Mutex
)

// Close gracefully terminates the spawned UltSQL engine process.
func (lc *LocalClient) Close() error {
	lc.mu.Lock()
	defer lc.mu.Unlock()
	if lc.closed {
		return nil
	}
	lc.closed = true

	registryMu.Lock()
	if abs, err := filepath.Abs(lc.DBPath); err == nil {
		delete(processRegistry, abs)
	}
	registryMu.Unlock()

	if lc.cmd != nil && lc.cmd.Process != nil {
		return lc.cmd.Process.Kill()
	}
	return nil
}

// Stop terminates the running server process (alias for Close).
func (lc *LocalClient) Stop() error {
	return lc.Close()
}

// Open launches a bundled UltSQL engine process on a free port, waits until it's healthy,
// and returns a ready-to-use LocalClient using DefaultOptions.
func Open(dbPath string) (*LocalClient, error) {
	return OpenWithOptions(dbPath, DefaultOptions())
}

// OpenWithOptions launches a bundled UltSQL engine process with custom Options.
func OpenWithOptions(dbPath string, opts Options) (*LocalClient, error) {
	if !opts.AutoStart {
		return nil, fmt.Errorf("ultsql: client is configured for local database path %q with AutoStart=false. Explicitly set AutoStart=true or connect via NewClient(\"http://127.0.0.1:8080\")", dbPath)
	}

	absPath, err := filepath.Abs(dbPath)
	if err != nil {
		absPath = dbPath
	}

	// Reuse existing process for the same database if already running
	registryMu.Lock()
	if existing, ok := processRegistry[absPath]; ok && !existing.closed {
		registryMu.Unlock()
		return existing, nil
	}
	registryMu.Unlock()

	binPath, err := FindEngineBinary()
	if err != nil {
		return nil, err
	}

	host := opts.Host
	if host == "" {
		host = "127.0.0.1"
	}

	port := opts.Port
	if port == 0 {
		allocated, err := findFreePort()
		if err != nil {
			return nil, fmt.Errorf("failed to allocate free port: %w", err)
		}
		port = allocated
	}

	cmd := exec.Command(binPath, "serve", "--host", host, "--port", fmt.Sprintf("%d", port), "--db", dbPath)
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("failed to start ultsql process: %w", err)
	}

	fmt.Printf("UltSQL local server started on %s:%d\n", host, port)

	baseURL := fmt.Sprintf("http://%s:%d", host, port)
	client := NewClient(baseURL)
	lc := &LocalClient{
		Client: client,
		cmd:    cmd,
		Port:   port,
		Host:   host,
		DBPath: dbPath,
	}

	timeout := opts.Timeout
	if timeout <= 0 {
		timeout = 10 * time.Second
	}

	// Poll health check until online
	deadline := time.Now().Add(timeout)
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
		return nil, fmt.Errorf("ultsql engine failed to become healthy within %v on port %d", timeout, port)
	}

	registryMu.Lock()
	processRegistry[absPath] = lc
	registryMu.Unlock()

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

// Status checks the health and returns telemetry metadata from the running engine.
func (c *Client) Status(ctx context.Context) (map[string]interface{}, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+"/", nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create status request: %w", err)
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch status from UltSQL: %w", err)
	}
	defer resp.Body.Close()

	var res map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&res); err != nil {
		return nil, fmt.Errorf("failed to decode status response: %w", err)
	}
	return res, nil
}
