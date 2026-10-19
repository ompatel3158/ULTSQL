/**
 * UltSQL Universal Node.js Client SDK & Local Process Manager
 * Connects to a remote UltSQL instance or manages a local helper engine process.
 */

const path = require('path');
const fs = require('fs');
const http = require('http');
const net = require('net');
const child_process = require('child_process');

/**
 * Resolves the path to the standalone UltSQL engine binary.
 */
function getBinaryPath() {
  if (process.env.ULTSQL_BINARY_PATH && fs.existsSync(process.env.ULTSQL_BINARY_PATH)) {
    return process.env.ULTSQL_BINARY_PATH;
  }

  const platform = process.platform;
  const arch = process.arch;
  const exeName = platform === 'win32' ? 'ultsql.exe' : 'ultsql';

  // 1. Try platform-specific npm optionalDependency (@ultsql/<platform>-<arch>)
  const platformPkg = `@ultsql/${platform}-${arch}`;
  try {
    const pkgJsonPath = require.resolve(`${platformPkg}/package.json`);
    const binPath = path.join(path.dirname(pkgJsonPath), 'bin', exeName);
    if (fs.existsSync(binPath)) {
      return binPath;
    }
  } catch (e) {
    // Platform package not resolved
  }

  // 2. Check local bundled bin in main package directory
  const localBin = path.join(__dirname, 'bin', exeName);
  if (fs.existsSync(localBin)) {
    return localBin;
  }

  // 3. Check npm platforms template folder (for local monorepo / CI development)
  const npmDevBin = path.join(__dirname, 'npm', `${platform}-${arch}`, 'bin', exeName);
  if (fs.existsSync(npmDevBin)) {
    return npmDevBin;
  }

  // 4. Check repo build directory for local testing
  const repoDevBin = path.join(__dirname, '..', '..', 'build', 'bin', exeName);
  if (fs.existsSync(repoDevBin)) {
    return repoDevBin;
  }

  // 5. Check system PATH
  const pathDirs = (process.env.PATH || '').split(path.delimiter);
  for (const dir of pathDirs) {
    const candidate = path.join(dir, exeName);
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  throw new Error(
    `Could not locate the UltSQL engine binary for platform "${platform}-${arch}".\n` +
    `Ensure "@ultsql/${platform}-${arch}" is installed, or set the ULTSQL_BINARY_PATH environment variable.`
  );
}

/**
 * Finds an available TCP port on the host (defaults strictly to 127.0.0.1).
 */
function findFreePort(host = '127.0.0.1') {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.unref();
    server.on('error', reject);
    server.listen(0, host, () => {
      const port = server.address().port;
      server.close(() => resolve(port));
    });
  });
}

// Global active server process registry to reuse existing processes for the same database
const _ACTIVE_SERVERS = new Map();

function _cleanupAllActiveServers() {
  for (const [normPath, serverInfo] of _ACTIVE_SERVERS.entries()) {
    if (serverInfo.child) {
      try {
        serverInfo.child.kill();
      } catch (_) {}
    }
  }
  _ACTIVE_SERVERS.clear();
}

process.once('exit', _cleanupAllActiveServers);
process.once('SIGINT', _cleanupAllActiveServers);
process.once('SIGTERM', _cleanupAllActiveServers);

class UltSQLClient {
  /**
   * @param {string} [target='http://127.0.0.1:8080'] - Remote server URL or local database path.
   * @param {object} [options={}] - Configuration options.
   * @param {boolean} [options.auto_start=false] - Whether to automatically start a local server if target is a file path.
   * @param {string} [options.host='127.0.0.1'] - Local binding host (strictly 127.0.0.1).
   * @param {number} [options.port=0] - Port (0 for auto-assign free port).
   */
  constructor(target = 'http://127.0.0.1:8080', options = {}) {
    if (typeof target === 'object' && target !== null) {
      options = target;
      target = options.url || options.target || 'http://127.0.0.1:8080';
    }

    this.target = target;
    this.options = options;
    this.autoStart = options.auto_start !== undefined ? options.auto_start : (options.autoStart || false);
    this.passphrase = options.passphrase || null;
    this.timeoutMs = options.timeout || 10000;
    this.binaryPath = options.binaryPath || null;
    this.quiet = options.quiet || false;

    this._child = null;
    this._serverKey = null;

    if (target.startsWith('http://') || target.startsWith('https://')) {
      this.isUrl = true;
      const parsed = new URL(target);
      this.host = parsed.hostname || options.host || '127.0.0.1';
      this.port = parseInt(parsed.port || (parsed.protocol === 'https:' ? '443' : '8080'), 10);
      this.baseUrl = target.replace(/\/+$/, '');
      this.dbPath = null;
    } else {
      this.isUrl = false;
      this.host = '127.0.0.1'; // Enforce loopback binding
      this.port = options.port || 0;
      this.dbPath = target;
      this.baseUrl = this.port > 0 ? `http://${this.host}:${this.port}` : '';
    }

    if (!this.isUrl && this.autoStart) {
      this._startPromise = this._startServer().catch(() => {});
    }
  }

  async _ensureServer() {
    if (this.isUrl) return;
    if (this._closed) {
      throw new Error('UltSQLClient has been closed.');
    }
    if (this._child && this._child.exitCode === null) return;

    if (this._startPromise) {
      await this._startPromise;
      if (this._child && this._child.exitCode === null) return;
    }

    if (!this.autoStart) {
      throw new Error(
        `UltSQLClient is configured for local database path "${this.target}" with auto_start=false.\n` +
        `Either start an UltSQL server explicitly ('ultsql dev' or 'ultsql serve'),\n` +
        `or enable automatic startup by setting auto_start: true.`
      );
    }

    this._startPromise = this._startServer();
    await this._startPromise;
  }

  async _startServer() {
    const normDb = path.resolve(this.dbPath);
    this._serverKey = normDb;

    const existing = _ACTIVE_SERVERS.get(normDb);
    if (existing) {
      if (existing.startPromise) {
        await existing.startPromise;
      }
      if (existing.child && existing.child.exitCode === null) {
        existing.refCount++;
        this._child = existing.child;
        this.host = existing.host;
        this.port = existing.port;
        this.baseUrl = `http://${this.host}:${this.port}`;
        return;
      }
    }

    this.host = '127.0.0.1';
    if (!this.port || this.port <= 0) {
      this.port = await findFreePort(this.host);
    }
    this.baseUrl = `http://${this.host}:${this.port}`;

    const serverEntry = {
      child: null,
      host: this.host,
      port: this.port,
      refCount: 1,
      startPromise: null,
    };
    _ACTIVE_SERVERS.set(normDb, serverEntry);

    const binPath = this.binaryPath || getBinaryPath();
    const args = ['serve', '--host', this.host, '--port', String(this.port), '--db', this.dbPath];
    if (this.passphrase) {
      args.push('--password', this.passphrase);
    }

    const child = child_process.spawn(binPath, args, {
      stdio: ['ignore', 'ignore', 'pipe'],
      windowsHide: true,
    });

    let stderrOutput = '';
    if (child.stderr) {
      child.stderr.on('data', (chunk) => {
        stderrOutput += chunk.toString();
      });
    }

    let healthy = false;
    const start = Date.now();

    while (Date.now() - start < this.timeoutMs) {
      if (child.exitCode !== null) {
        _ACTIVE_SERVERS.delete(normDb);
        throw new Error(`UltSQL local engine exited prematurely with code ${child.exitCode}:\n${stderrOutput}`);
      }

      try {
        const res = await new Promise((resolve, reject) => {
          const req = http.get(`http://${this.host}:${this.port}/`, { timeout: 400 }, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
              try {
                resolve(JSON.parse(body));
              } catch (_) {
                resolve(null);
              }
            });
          });
          req.on('error', reject);
          req.on('timeout', () => {
            req.destroy();
            reject(new Error('timeout'));
          });
        });

        if (res && res.status === 'online') {
          healthy = true;
          break;
        }
      } catch (_) {}

      await new Promise(r => setTimeout(r, 60));
    }

    if (!healthy) {
      try {
        child.kill();
      } catch (_) {}
      _ACTIVE_SERVERS.delete(normDb);
      throw new Error(`UltSQL local engine failed to become healthy on ${this.host}:${this.port} within ${this.timeoutMs}ms:\n${stderrOutput}`);
    }

    this._child = child;
    serverEntry.child = child;
    serverEntry.startPromise = null;

    if (!this.quiet) {
      console.log(`UltSQL local server started on ${this.host}:${this.port}`);
    }
  }

  async status() {
    if (this._closed) {
      return {
        status: 'offline',
        host: this.host,
        port: this.port,
        url: this.baseUrl,
        target: this.target,
        auto_start: this.autoStart,
        pid: null,
        server_info: null,
      };
    }

    if (this._startPromise) {
      try {
        await this._startPromise;
      } catch (_) {}
    }

    let isOnline = false;
    let serverInfo = null;
    try {
      if (this.baseUrl) {
        const res = await new Promise((resolve, reject) => {
          const req = http.get(`${this.baseUrl}/`, { timeout: 800 }, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
              try {
                resolve(JSON.parse(body));
              } catch (_) {
                resolve(null);
              }
            });
          });
          req.on('error', reject);
          req.on('timeout', () => {
            req.destroy();
            reject(new Error('timeout'));
          });
        });
        if (res && res.status === 'online') {
          isOnline = true;
          serverInfo = res;
        }
      }
    } catch (_) {
      isOnline = false;
    }

    return {
      status: isOnline ? 'online' : 'offline',
      host: this.host,
      port: this.port,
      url: this.baseUrl,
      target: this.target,
      auto_start: this.autoStart,
      pid: this._child ? this._child.pid : null,
      server_info: serverInfo,
    };
  }

  async sql(sqlQuery) {
    if (this._startPromise) await this._startPromise;
    await this._ensureServer();

    return new Promise((resolve, reject) => {
      const payload = JSON.stringify({ sql: sqlQuery });
      const req = http.request({
        hostname: this.host,
        port: this.port,
        path: '/query',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(payload)
        }
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error(`Failed to parse response: ${data}`));
          }
        });
      });
      req.on('error', reject);
      req.write(payload);
      req.end();
    });
  }

  execute(sqlQuery) {
    return this.sql(sqlQuery);
  }

  async query(tableName) {
    if (this._startPromise) await this._startPromise;
    await this._ensureServer();

    return new Promise((resolve, reject) => {
      http.get(`${this.baseUrl}/${tableName}`, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error(`Failed to parse query response: ${data}`));
          }
        });
      }).on('error', reject);
    });
  }

  async insert(tableName, recordObject) {
    if (this._startPromise) await this._startPromise;
    await this._ensureServer();

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
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error(`Failed to parse insert response: ${data}`));
          }
        });
      });
      req.on('error', reject);
      req.write(payload);
      req.end();
    });
  }

  async insertBatch(tableName, recordsArray) {
    if (this._startPromise) await this._startPromise;
    await this._ensureServer();

    return new Promise((resolve, reject) => {
      const payload = JSON.stringify(recordsArray);
      const req = http.request({
        hostname: this.host,
        port: this.port,
        path: `/${tableName}/batch`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(payload)
        }
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error(`Failed to parse batch insert response: ${data}`));
          }
        });
      });
      req.on('error', reject);
      req.write(payload);
      req.end();
    });
  }

  async truncate(tableName) {
    if (this._startPromise) await this._startPromise;
    await this._ensureServer();

    return new Promise((resolve, reject) => {
      const req = http.request({
        hostname: this.host,
        port: this.port,
        path: `/${tableName}`,
        method: 'DELETE'
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error(`Failed to parse truncate response: ${data}`));
          }
        });
      });
      req.on('error', reject);
      req.end();
    });
  }

  async openapiSpec() {
    if (this._startPromise) await this._startPromise;
    await this._ensureServer();

    return new Promise((resolve, reject) => {
      http.get(`${this.baseUrl}/openapi.json`, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error(`Failed to parse OpenAPI spec: ${data}`));
          }
        });
      }).on('error', reject);
    });
  }

  stop() {
    this._closed = true;
    if (this._serverKey) {
      const existing = _ACTIVE_SERVERS.get(this._serverKey);
      if (existing) {
        existing.refCount--;
        if (existing.refCount <= 0) {
          try {
            if (existing.child && existing.child.exitCode === null) {
              existing.child.kill();
            }
          } catch (_) {}
          _ACTIVE_SERVERS.delete(this._serverKey);
        }
      }
    } else if (this._child && this._child.exitCode === null) {
      try {
        this._child.kill();
      } catch (_) {}
    }
    this._child = null;
    this._serverKey = null;
    this._startPromise = null;
    this.baseUrl = '';
  }

  close() {
    this.stop();
  }
}

class UltSQL {
  static Client = UltSQLClient;

  /**
   * Convenient local mode helper:
   * Connects to or automatically launches a local UltSQL server for the given database file.
   */
  static open(dbPath = './app.ultsql', options = {}) {
    return open(dbPath, options);
  }
}

/**
 * Automatically starts the bundled UltSQL engine binary on a free loopback port (127.0.0.1)
 * and returns a ready-to-use client.
 */
async function open(dbPath = './app.ultsql', options = {}) {
  const client = new UltSQLClient(dbPath, {
    auto_start: true,
    ...options,
  });
  await client._ensureServer();
  return client;
}

module.exports = UltSQLClient;
module.exports.UltSQL = UltSQL;
module.exports.UltSQLClient = UltSQLClient;
module.exports.open = open;
module.exports.getBinaryPath = getBinaryPath;
