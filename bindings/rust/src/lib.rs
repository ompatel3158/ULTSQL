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

/// Options configuring the local UltSQL engine launcher.
#[derive(Debug, Clone)]
pub struct OpenOptions {
    pub auto_start: bool,
    pub host: String,
    pub port: u16,
    pub timeout: Duration,
}

impl Default for OpenOptions {
    fn default() -> Self {
        Self {
            auto_start: true,
            host: "127.0.0.1".into(),
            port: 0,
            timeout: Duration::from_secs(10),
        }
    }
}

/// Client managing a locally spawned UltSQL engine process.
pub struct LocalUltSqlClient {
    client: UltSqlClient,
    child: Arc<Mutex<Option<Child>>>,
    pub port: u16,
    pub host: String,
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

    /// Stops the running local engine process (alias for close).
    pub fn stop(&self) {
        self.close();
    }

    /// Queries the engine's health status and metadata.
    pub async fn status(&self) -> Result<serde_json::Value, UltSqlError> {
        let resp = self.client.http.get(&self.client.base_url).send().await?;
        let json: serde_json::Value = resp.json().await?;
        Ok(json)
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
        Self::open_with_options(db_path, OpenOptions::default()).await
    }

    /// Launches a local UltSQL engine process with customized `OpenOptions`.
    pub async fn open_with_options(db_path: &str, opts: OpenOptions) -> Result<LocalUltSqlClient, UltSqlError> {
        if !opts.auto_start {
            return Err(UltSqlError::Database {
                status: 400,
                message: format!(
                    "UltSQL: Client configured for local database '{}' with auto_start=false. Explicitly set auto_start=true or connect via UltSqlClient::new(\"http://127.0.0.1:8080\")",
                    db_path
                ),
            });
        }

        let binary = find_engine_binary().ok_or_else(|| UltSqlError::Database {
            status: 500,
            message: "Could not locate ultsql binary. Ensure it is installed or set ULTSQL_BINARY_PATH.".into(),
        })?;

        let host = if opts.host.is_empty() { "127.0.0.1".to_string() } else { opts.host };
        let port = if opts.port == 0 {
            let listener = TcpListener::bind(format!("{}:0", host)).map_err(|e| UltSqlError::Database {
                status: 500,
                message: format!("Failed to find free port: {}", e),
            })?;
            let p = listener
                .local_addr()
                .map_err(|e| UltSqlError::Database {
                    status: 500,
                    message: format!("Failed to read local addr: {}", e),
                })?
                .port();
            drop(listener);
            p
        } else {
            opts.port
        };

        let child = Command::new(&binary)
            .args([
                "serve",
                "--host",
                &host,
                "--port",
                &port.to_string(),
                "--db",
                db_path,
            ])
            .spawn()
            .map_err(|e| UltSqlError::Database {
                status: 500,
                message: format!("Failed to spawn ultsql engine: {}", e),
            })?;

        println!("UltSQL local server started on {}:{}", host, port);

        let base_url = format!("http://{}:{}", host, port);
        let client = UltSqlClient::new(&base_url);
        let start = Instant::now();
        let timeout = opts.timeout;
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
                message: format!("UltSQL engine on {}:{} failed to become healthy within {:?}", host, port, timeout),
            });
        }

        Ok(LocalUltSqlClient {
            client,
            child: Arc::new(Mutex::new(Some(child))),
            port,
            host,
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
