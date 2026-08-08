/**
 * UltSQL Universal Node.js Client
 * Connects Node.js applications to ULTSQL via REST or PostgreSQL Wire Protocol.
 */
const http = require('http');

class UltSQLClient {
  constructor(options = {}) {
    this.host = options.host || 'localhost';
    this.port = options.port || 8080;
  }

  query(tableName) {
    return new Promise((resolve, reject) => {
      http.get(`http://${this.host}:${this.port}/${tableName}`, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => resolve(JSON.parse(data)));
      }).on('error', reject);
    });
  }

  insert(tableName, recordObject) {
    return new Promise((resolve, reject) => {
      const payload = JSON.stringify(recordObject);
      const req = http.request({
        hostname: this.host,
        port: this.port,
        path: `/${tableName}`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(payload)
        }
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => resolve(JSON.parse(data)));
      });
      req.on('error', reject);
      req.write(payload);
      req.end();
    });
  }
}

UltSQLClient.UltSQLClient = UltSQLClient;
module.exports = UltSQLClient;
