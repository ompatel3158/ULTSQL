//! # UltSQL Rust Client
//! 
//! High-performance async Rust SDK for connecting to UltSQL via REST or PostgreSQL Wire Protocol.

use reqwest::Client;
use serde::{Deserialize, Serialize};
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

#[derive(Clone)]
pub struct UltSqlClient {
    base_url: String,
    http: Client,
}

impl UltSqlClient {
    pub fn new(base_url: impl Into<String>) -> Self {
        Self {
            base_url: base_url.into(),
            http: Client::new(),
        }
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
            .post(format!("{}/tables/{}/insert", self.base_url, table))
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
}
