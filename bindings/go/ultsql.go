// Package ultsql provides the official Go client for the converged UltSQL database engine.
package ultsql

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
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

// NewClient initializes a new UltSQL REST client.
func NewClient(baseURL string) *Client {
	return &Client{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
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

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, fmt.Sprintf("%s/tables/%s/insert", c.baseURL, tableName), bytes.NewReader(reqBody))
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

// OpenPgWire connects to UltSQL using the standard Go database/sql interface over TCP PgWire.
func OpenPgWire(host string, port int, user, password, dbname string) (*sql.DB, error) {
	connStr := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)
	return sql.Open("postgres", connStr)
}
