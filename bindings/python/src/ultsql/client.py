"""
UltSQL Python Client & Embedded Engine Launcher
Connects to a remote UltSQL server or starts a bundled engine process automatically.
"""

import atexit
import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Optional


def find_engine_binary() -> str:
    """
    Locates the UltSQL standalone engine executable binary.
    Checks:
      1. ULTSQL_BINARY_PATH environment variable
      2. Bundled package binary at `ultsql/bin/ultsql(.exe)`
      3. System PATH (`ultsql` or `ultsql.exe`)
      4. Local workspace build directory (`build/bin/ultsql(.exe)`)
    """
    # 1. Environment variable override
    env_bin = os.environ.get("ULTSQL_BINARY_PATH")
    if env_bin and os.path.isfile(env_bin) and os.access(env_bin, os.X_OK | os.R_OK):
        return env_bin

    is_windows = sys.platform == "win32"
    exe_name = "ultsql.exe" if is_windows else "ultsql"

    # 2. Bundled inside package directory `ultsql/bin/`
    pkg_dir = Path(__file__).resolve().parent
    bundled_bin = pkg_dir / "bin" / exe_name
    if bundled_bin.is_file():
        return str(bundled_bin)

    bundled_bin_no_ext = pkg_dir / "bin" / "ultsql"
    if bundled_bin_no_ext.is_file():
        return str(bundled_bin_no_ext)

    # 3. System PATH
    which_bin = shutil.which(exe_name) or shutil.which("ultsql")
    if which_bin:
        return which_bin

    # 4. Local workspace build output (for local development/testing)
    candidate_dirs = [
        pkg_dir.parents[2] / "build" / "bin",  # repo_root/build/bin
        Path.cwd() / "build" / "bin",
        Path.cwd() / "bin",
    ]
    for cdir in candidate_dirs:
        candidate = cdir / exe_name
        if candidate.is_file():
            return str(candidate)

    raise FileNotFoundError(
        f"Could not locate the UltSQL engine binary ({exe_name}).\n"
        "Ensure the package is installed with platform-specific binaries, or set "
        "the ULTSQL_BINARY_PATH environment variable to point to the `ultsql` executable."
    )


def find_free_port(host: str = "127.0.0.1") -> int:
    """Finds an ephemeral unused TCP port on the local machine."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((host, 0))
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        return s.getsockname()[1]


class UltSQLClient:
    """Universal client for UltSQL Database via REST Daemon."""

    def __init__(self, host: str = "http://localhost:8080") -> None:
        if not host.startswith("http://") and not host.startswith("https://"):
            host = f"http://{host}"
        self.host: str = host.rstrip("/")

    def sql(self, sql_query: str) -> Dict[str, Any]:
        """Execute a raw SQL script or query against the database engine."""
        url = f"{self.host}/query"
        payload = json.dumps({"sql": sql_query}).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))

    def execute(self, sql_query: str) -> Dict[str, Any]:
        """Alias for sql(sql_query)."""
        return self.sql(sql_query)

    def query(self, table_name: str) -> Dict[str, Any]:
        """Fetch all records from a table."""
        url = f"{self.host}/{table_name}"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as resp:
            data: Dict[str, Any] = json.loads(resp.read().decode("utf-8"))
            return data

    def insert(self, table_name: str, data_dict: Dict[str, Any]) -> Dict[str, Any]:
        """Insert a single record into a table."""
        url = f"{self.host}/{table_name}"
        payload = json.dumps(data_dict).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))

    def insert_batch(self, table_name: str, records: List[Dict[str, Any]]) -> Dict[str, Any]:
        """High-throughput batch insert of multiple records into a table."""
        url = f"{self.host}/{table_name}/batch"
        payload = json.dumps(records).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))

    def truncate(self, table_name: str) -> Dict[str, Any]:
        """Truncate a table."""
        url = f"{self.host}/{table_name}"
        req = urllib.request.Request(url, method="DELETE")
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))

    def openapi_spec(self) -> Dict[str, Any]:
        """Get OpenAPI 3.0 documentation spec."""
        url = f"{self.host}/openapi.json"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))

    def close(self) -> None:
        """Close connection (no-op for remote HTTP client)."""
        pass


class LocalUltSQLClient(UltSQLClient):
    """
    UltSQL client that manages an embedded local daemon process.
    Automatically shuts down the engine process when finished or on Python exit.
    """

    def __init__(
        self,
        host: str,
        process: subprocess.Popen,
        db_path: str,
        port: int,
        log_file: Optional[tempfile._TemporaryFileWrapper] = None,
    ) -> None:
        super().__init__(host=host)
        self._process: Optional[subprocess.Popen] = process
        self.db_path: str = db_path
        self.port: int = port
        self._log_file = log_file
        self._closed: bool = False
        atexit.register(self.close)

    def close(self) -> None:
        """Gracefully terminate the bundled UltSQL engine process."""
        if self._closed:
            return
        self._closed = True

        if self._process is not None:
            try:
                self._process.terminate()
                self._process.wait(timeout=2.0)
            except Exception:
                try:
                    self._process.kill()
                    self._process.wait(timeout=1.0)
                except Exception:
                    pass
            self._process = None

        if self._log_file is not None:
            try:
                self._log_file.close()
            except Exception:
                pass
            self._log_file = None

    def __enter__(self) -> "LocalUltSQLClient":
        return self

    def __exit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        self.close()

    def __del__(self) -> None:
        self.close()


def open(
    db_path: str = "app.db",
    host: str = "127.0.0.1",
    port: Optional[int] = None,
    passphrase: Optional[str] = None,
    timeout: float = 10.0,
    binary_path: Optional[str] = None,
) -> LocalUltSQLClient:
    """
    Launches a bundled UltSQL engine process on a free port, waits until it's healthy,
    and returns a ready-to-use client instance. The engine process is automatically terminated on exit.

    Example:
        db = ultsql.open("app.db")
        db.insert("users", {"name": "Alice", "score": 95})
        print(db.query("users"))
        db.close()
    """
    if binary_path is None:
        binary_path = find_engine_binary()

    if port is None:
        port = find_free_port(host)

    cmd = [binary_path, "serve", "--db", db_path, "--port", str(port)]
    if passphrase:
        cmd.extend(["--password", passphrase])

    # Log process output to temporary file for diagnostic output if startup fails
    log_file = tempfile.NamedTemporaryFile(
        mode="w+",
        encoding="utf-8",
        prefix="ultsql_engine_",
        suffix=".log",
        delete=False,
    )

    proc = subprocess.Popen(
        cmd,
        stdout=log_file,
        stderr=subprocess.STDOUT,
    )

    health_url = f"http://{host}:{port}/"
    deadline = time.time() + timeout
    healthy = False

    while time.time() < deadline:
        if proc.poll() is not None:
            log_file.seek(0)
            logs = log_file.read()
            raise RuntimeError(
                f"UltSQL engine process exited prematurely with code {proc.returncode}.\n"
                f"Process logs:\n{logs}"
            )
        try:
            req = urllib.request.Request(health_url)
            with urllib.request.urlopen(req, timeout=0.5) as resp:
                if resp.status == 200:
                    body = json.loads(resp.read().decode("utf-8"))
                    if body.get("status") == "online":
                        healthy = True
                        break
        except Exception:
            pass
        time.sleep(0.05)

    if not healthy:
        try:
            proc.terminate()
            proc.wait(timeout=1.0)
        except Exception:
            try:
                proc.kill()
            except Exception:
                pass
        log_file.seek(0)
        logs = log_file.read()
        raise TimeoutError(
            f"UltSQL engine failed to become healthy on port {port} within {timeout} seconds.\n"
            f"Logs:\n{logs}"
        )

    return LocalUltSQLClient(
        host=health_url,
        process=proc,
        db_path=db_path,
        port=port,
        log_file=log_file,
    )
