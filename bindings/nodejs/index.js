/**
 * UltSQL Universal Node.js Client & Embedded Engine Launcher
 * Connects to a remote UltSQL instance or automatically manages a bundled local engine process.
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
 * Finds an available TCP port on the host.
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

class UltSQLClient {
  constructor(options = {}) {
    if (typeof options === 'string') {
      const parsed = new URL(options.startsWith('http') ? options : `http://${options}`);
      this.host = parsed.hostname || '127.0.0.1';
      this.port = parseInt(parsed.port || '8080', 10);
    } else {
      this.host = options.host || '127.0.0.1';
      this.port = options.port || 8080;
    }
    this._child = null;
    this._cleanupHandler = null;
  }

  /**
   * Execute raw SQL statements against the UltSQL REST daemon.
   */
  sql(sqlQuery) {
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

  query(tableName) {
    return new Promise((resolve, reject) => {
      http.get(`http://${this.host}:${this.port}/${tableName}`, (res) => {
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

  insertBatch(tableName, recordsArray) {
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

  truncate(tableName) {
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

  openapiSpec() {
    return new Promise((resolve, reject) => {
      http.get(`http://${this.host}:${this.port}/openapi.json`, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error(`Failed to parse openapi response: ${data}`));
          }
        });
      }).on('error', reject);
    });
  }

  close() {
    if (this._child) {
      try {
        this._child.kill();
      } catch (_) {}
      this._child = null;
    }
    if (this._cleanupHandler) {
      process.removeListener('exit', this._cleanupHandler);
      process.removeListener('SIGINT', this._cleanupHandler);
      process.removeListener('SIGTERM', this._cleanupHandler);
      this._cleanupHandler = null;
    }
  }
}

/**
 * Automatically starts the bundled UltSQL engine binary on a free port,
 * waits until it is healthy, and registers process exit hooks.
 *
 * @param {string} dbPath - Path to database directory or file (e.g. 'app.db')
 * @param {object} [options] - Configuration options
 * @returns {Promise<UltSQLClient>}
 */
async function open(dbPath = 'app.db', options = {}) {
  const host = options.host || '127.0.0.1';
  const port = options.port || await findFreePort(host);
  const binaryPath = options.binaryPath || getBinaryPath();
  const timeoutMs = options.timeout || 10000;

  const args = ['serve', '--db', dbPath, '--port', String(port)];
  if (options.passphrase) {
    args.push('--password', options.passphrase);
  }

  const child = child_process.spawn(binaryPath, args, {
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

  while (Date.now() - start < timeoutMs) {
    if (child.exitCode !== null) {
      throw new Error(`UltSQL engine exited prematurely with code ${child.exitCode}:\n${stderrOutput}`);
    }

    try {
      const res = await new Promise((resolve, reject) => {
        const req = http.get(`http://${host}:${port}/`, { timeout: 400 }, (res) => {
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
    throw new Error(`UltSQL engine failed to start on port ${port} within ${timeoutMs}ms:\n${stderrOutput}`);
  }

  const client = new UltSQLClient({ host, port });
  client._child = child;

  const cleanup = () => {
    client.close();
  };
  client._cleanupHandler = cleanup;

  process.once('exit', cleanup);
  process.once('SIGINT', cleanup);
  process.once('SIGTERM', cleanup);

  return client;
}

module.exports = UltSQLClient;
module.exports.UltSQLClient = UltSQLClient;
module.exports.open = open;
module.exports.getBinaryPath = getBinaryPath;
