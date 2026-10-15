//! # UltSQL Rust Client
//! 
//! High-performance async Rust SDK and embedded launcher for UltSQL multimodal database.

use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::net::TcpListener;
use std::path::PathBuf;
use std::process::{Child, Command};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum UltSqlError {
    #[error("Network error: {0}")]
    Network(#[from] reqwest::Error),
    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
    #[error("Database error ({status}): {message}")]
    Database { status: u16, message: String },
}

#[derive(Debug, Serialize, Deserialize)]
pub struct QueryResult {
    pub columns: Vec<String>,
    pub rows: Vec<Vec<serde_json::Value>>,
    pub message: Option<String>,
    pub execution_time_ms: Option<f64>,
}

/// Locates the ultsql standalone executable binary on PATH, env, or build dirs.
pub fn find_engine_binary() -> Option<PathBuf> {
    if let Ok(env_path) = std::env::var("ULTSQL_BINARY_PATH") {
        let p = PathBuf::from(env_path);
        if p.is_file() {
            return Some(p);
        }
    }

    let exe = if cfg!(windows) { "ultsql.exe" } else { "ultsql" };

    if let Ok(path_var) = std::env::var("PATH") {
        for dir in std::env::split_paths(&path_var) {
            let candidate = dir.join(exe);
            if candidate.is_file() {
                return Some(candidate);
            }
        }
    }

    let dev_candidates = [
        format!("build/bin/{}", exe),
        format!("../build/bin/{}", exe),
        format!("../../build/bin/{}", exe),
        format!("bin/{}", exe),
    ];
    for c in &dev_candidates {
        let p = PathBuf::from(c);
        if p.is_file() {
            return Some(p);
        }
    }

    None
}

/// Client managing a locally spawned UltSQL engine process.
pub struct LocalUltSqlClient {
    client: UltSqlClient,
    child: Arc<Mutex<Option<Child>>>,
    pub port: u16,
    pub db_path: String,
}

impl std::ops::Deref for LocalUltSqlClient {
    type Target = UltSqlClient;
    fn deref(&self) -> &Self::Target {
        &self.client
    }
}

impl Drop for LocalUltSqlClient {
    fn drop(&mut self) {
        self.close();
    }
}

impl LocalUltSqlClient {
    pub fn close(&self) {
        if let Ok(mut lock) = self.child.lock() {
            if let Some(mut child) = lock.take() {
                let _ = child.kill();
                let _ = child.wait();
            }
        }
    }
}

#[derive(Clone)]
pub struct UltSqlClient {
    pub base_url: String,
    http: Client,
}

impl UltSqlClient {
    /// Connects to a remote UltSQL instance.
    pub fn new(base_url: impl Into<String>) -> Self {
        Self {
            base_url: base_url.into(),
            http: Client::new(),
        }
    }

    /// Launches a local UltSQL engine process on a free port, waits until healthy,
    /// and returns a managed `LocalUltSqlClient`. Automatically terminates on drop.
    pub async fn open(db_path: &str) -> Result<LocalUltSqlClient, UltSqlError> {
        let binary = find_engine_binary().ok_or_else(|| UltSqlError::Database {
            status: 500,
            message: "Could not locate ultsql binary. Ensure it is installed or set ULTSQL_BINARY_PATH.".into(),
        })?;

        let listener = TcpListener::bind("127.0.0.1:0").map_err(|e| UltSqlError::Database {
            status: 500,
            message: format!("Failed to find free port: {}", e),
        })?;
        let port = listener
            .local_addr()
            .map_err(|e| UltSqlError::Database {
                status: 500,
                message: format!("Failed to read local addr: {}", e),
            })?
            .port();
        drop(listener);

        let child = Command::new(&binary)
            .args(["serve", "--db", db_path, "--port", &port.to_string()])
            .spawn()
            .map_err(|e| UltSqlError::Database {
                status: 500,
                message: format!("Failed to spawn ultsql engine: {}", e),
            })?;

        let base_url = format!("http://127.0.0.1:{}", port);
        let client = UltSqlClient::new(&base_url);
        let start = Instant::now();
        let timeout = Duration::from_secs(10);
        let mut healthy = false;

        while start.elapsed() < timeout {
            if let Ok(resp) = client.http.get(&base_url).send().await {
                if resp.status().is_success() {
                    healthy = true;
                    break;
                }
            }
            tokio::time::sleep(Duration::from_millis(50)).await;
        }

        if !healthy {
            let mut c = child;
            let _ = c.kill();
            return Err(UltSqlError::Database {
                status: 500,
                message: format!("UltSQL engine on port {} failed to become healthy within 10s", port),
            });
        }

        Ok(LocalUltSqlClient {
            client,
            child: Arc::new(Mutex::new(Some(child))),
            port,
            db_path: db_path.to_string(),
        })
    }

    /// Execute an SQL, NoSQL JSON, or Vector query script.
    pub async fn query(&self, sql: &str) -> Result<QueryResult, UltSqlError> {
        let payload = serde_json::json!({ "query": sql });
        let resp = self
            .http
            .post(format!("{}/query", self.base_url))
            .json(&payload)
            .send()
            .await?;

        let status = resp.status();
        if !status.is_success() {
            let msg = resp.text().await.unwrap_or_default();
            return Err(UltSqlError::Database {
                status: status.as_u16(),
                message: msg,
            });
        }

        let result: QueryResult = resp.json().await?;
        Ok(result)
    }

    /// Insert a record into a table with automatic dynamic schema creation.
    pub async fn insert(&self, table: &str, record: &serde_json::Value) -> Result<QueryResult, UltSqlError> {
        let resp = self
            .http
            .post(format!("{}/{}", self.base_url, table))
            .json(record)
            .send()
            .await?;

        let status = resp.status();
        if !status.is_success() {
            let msg = resp.text().await.unwrap_or_default();
            return Err(UltSqlError::Database {
                status: status.as_u16(),
                message: msg,
            });
        }

        let result: QueryResult = resp.json().await?;
        Ok(result)
    }

    /// High-throughput batch insert of multiple records into a table.
    pub async fn insert_batch(&self, table: &str, records: &[serde_json::Value]) -> Result<QueryResult, UltSqlError> {
        let resp = self
            .http
            .post(format!("{}/{}/batch", self.base_url, table))
            .json(records)
            .send()
            .await?;

        let status = resp.status();
        if !status.is_success() {
            let msg = resp.text().await.unwrap_or_default();
            return Err(UltSqlError::Database {
                status: status.as_u16(),
                message: msg,
            });
        }

        let result: QueryResult = resp.json().await?;
        Ok(result)
    }
}
