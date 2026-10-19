"""
UltSQL Python Client SDK & Local Process Manager
Connects to an existing UltSQL server or manages a local engine process.
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


class _ServerProcess:
    """Represents a running local UltSQL engine server process."""

    def __init__(
        self,
        process: subprocess.Popen,
        host: str,
        port: int,
        db_path: str,
        log_file: Optional[tempfile._TemporaryFileWrapper] = None,
    ) -> None:
        self.process = process
        self.host = host
        self.port = port
        self.db_path = db_path
        self.log_file = log_file
        self.ref_count = 1

    def is_alive(self) -> bool:
        return self.process.poll() is None

    def stop(self) -> None:
        if self.process is not None:
            try:
                self.process.terminate()
                self.process.wait(timeout=2.0)
            except Exception:
                try:
                    self.process.kill()
                    self.process.wait(timeout=1.0)
                except Exception:
                    pass
            self.process = None

        if self.log_file is not None:
            try:
                self.log_file.close()
            except Exception:
                pass
            self.log_file = None


# Global registry of active local servers to reuse existing processes for the same database
_ACTIVE_SERVERS: Dict[str, _ServerProcess] = {}


def _cleanup_all_active_servers() -> None:
    for server in list(_ACTIVE_SERVERS.values()):
        server.stop()
    _ACTIVE_SERVERS.clear()


atexit.register(_cleanup_all_active_servers)


class UltSQLClient:
    """
    Universal Client SDK for UltSQL.
    
    Supports two operating modes:
      1. Client mode: Connects to an existing remote or local UltSQL server (auto_start=False).
      2. Embedded local mode: Automatically launches and manages a local helper server on 127.0.0.1 (auto_start=True).
    """

    def __init__(
        self,
        target: str = "http://127.0.0.1:8080",
        auto_start: bool = False,
        host: str = "127.0.0.1",
        port: int = 0,
        passphrase: Optional[str] = None,
        timeout: float = 10.0,
        binary_path: Optional[str] = None,
        quiet: bool = False,
    ) -> None:
        self.target: str = target
        self.auto_start: bool = auto_start
        self.passphrase: Optional[str] = passphrase
        self.timeout: float = timeout
        self.binary_path: Optional[str] = binary_path
        self.quiet: bool = quiet

        self._server: Optional[_ServerProcess] = None
        self._closed: bool = False

        if target.startswith("http://") or target.startswith("https://"):
            self._is_url: bool = True
            parsed = urllib.parse.urlparse(target)
            self.host: str = parsed.hostname or host or "127.0.0.1"
            self.port: int = parsed.port or (443 if parsed.scheme == "https" else 8080)
            self._base_url: str = target.rstrip("/")
            self._db_path: Optional[str] = None
        else:
            self._is_url = False
            # Never bind to 0.0.0.0 for local process
            self.host = "127.0.0.1"
            self.port = port
            self._db_path = target
            self._base_url = f"http://{self.host}:{self.port}" if self.port > 0 else ""

        if not self._is_url and self.auto_start:
            self._ensure_server()

    def _ensure_server(self) -> None:
        """Starts or attaches to the local server process if needed."""
        if self._is_url:
            return
        if self._server is not None and self._server.is_alive():
            return

        if not self.auto_start:
            raise ConnectionError(
                f"UltSQLClient is configured for local database path '{self.target}' with auto_start=False.\n"
                f"Either start an UltSQL server explicitly ('ultsql dev' or 'ultsql serve'),\n"
                f"or enable automatic startup by setting auto_start=True."
            )

        norm_db = os.path.abspath(self._db_path or "app.ultsql")
        existing = _ACTIVE_SERVERS.get(norm_db)
        if existing is not None and existing.is_alive():
            self._server = existing
            existing.ref_count += 1
            self.port = existing.port
            self.host = existing.host
            self._base_url = f"http://{self.host}:{self.port}"
            return

        # Bind host is strictly loopback
        self.host = "127.0.0.1"
        if self.port <= 0:
            self.port = find_free_port(self.host)
        self._base_url = f"http://{self.host}:{self.port}"

        bin_path = self.binary_path or find_engine_binary()
        cmd = [bin_path, "serve", "--host", self.host, "--port", str(self.port), "--db", self._db_path or "app.ultsql"]
        if self.passphrase:
            cmd.extend(["--password", self.passphrase])

        log_file = tempfile.NamedTemporaryFile(
            mode="w+",
            encoding="utf-8",
            prefix="ultsql_server_",
            suffix=".log",
            delete=False,
        )

        proc = subprocess.Popen(
            cmd,
            stdout=log_file,
            stderr=subprocess.STDOUT,
        )

        health_url = f"http://{self.host}:{self.port}/"
        deadline = time.time() + self.timeout
        healthy = False

        while time.time() < deadline:
            if proc.poll() is not None:
                log_file.seek(0)
                logs = log_file.read()
                raise RuntimeError(
                    f"UltSQL local engine server exited prematurely with code {proc.returncode}.\n"
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
                f"UltSQL local engine failed to become healthy on {self.host}:{self.port} within {self.timeout} seconds.\n"
                f"Logs:\n{logs}"
            )

        server_proc = _ServerProcess(
            process=proc,
            host=self.host,
            port=self.port,
            db_path=norm_db,
            log_file=log_file,
        )
        self._server = server_proc
        _ACTIVE_SERVERS[norm_db] = server_proc

        if not self.quiet:
            print(f"UltSQL local server started on {self.host}:{self.port}")

    def status(self) -> Dict[str, Any]:
        """Returns the health status and metadata of the database connection."""
        is_online = False
        server_info = {}
        try:
            url = f"{self._base_url}/"
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req, timeout=0.8) as resp:
                if resp.status == 200:
                    server_info = json.loads(resp.read().decode("utf-8"))
                    is_online = server_info.get("status") == "online"
        except Exception:
            is_online = False

        pid = self._server.process.pid if (self._server and self._server.process) else None

        return {
            "status": "online" if is_online else "offline",
            "host": self.host,
            "port": self.port,
            "url": self._base_url,
            "target": self.target,
            "auto_start": self.auto_start,
            "is_local": self._server is not None,
            "pid": pid,
            "server_info": server_info,
        }

    def sql(self, sql_query: str) -> Dict[str, Any]:
        """Execute a raw SQL script or query against the database engine."""
        self._ensure_server()
        url = f"{self._base_url}/query"
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
        self._ensure_server()
        url = f"{self._base_url}/{table_name}"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))

    def insert(self, table_name: str, data_dict: Dict[str, Any]) -> Dict[str, Any]:
        """Insert a single record into a table."""
        self._ensure_server()
        url = f"{self._base_url}/{table_name}"
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
        self._ensure_server()
        url = f"{self._base_url}/{table_name}/batch"
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
        self._ensure_server()
        url = f"{self._base_url}/{table_name}"
        req = urllib.request.Request(url, method="DELETE")
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))

    def openapi_spec(self) -> Dict[str, Any]:
        """Get OpenAPI 3.0 documentation spec."""
        self._ensure_server()
        url = f"{self._base_url}/openapi.json"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))

    def stop(self) -> None:
        """Stops the managed local UltSQL server process if running."""
        if self._server is not None:
            norm_db = os.path.abspath(self._db_path or "")
            self._server.ref_count -= 1
            if self._server.ref_count <= 0:
                self._server.stop()
                if norm_db in _ACTIVE_SERVERS:
                    del _ACTIVE_SERVERS[norm_db]
            self._server = None

    def close(self) -> None:
        """Closes the client connection and stops local helper process if owned."""
        if self._closed:
            return
        self._closed = True
        self.stop()

    def __enter__(self) -> "UltSQLClient":
        return self

    def __exit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        self.close()

    def __del__(self) -> None:
        self.close()


class LocalUltSQLClient(UltSQLClient):
    """Backwards-compatible alias for local UltSQLClient with auto_start=True."""

    def __init__(
        self,
        db_path: str = "app.ultsql",
        host: str = "127.0.0.1",
        port: int = 0,
        **kwargs: Any,
    ) -> None:
        super().__init__(target=db_path, auto_start=True, host=host, port=port, **kwargs)


class UltSQL:
    """Namespace providing convenient client construction and local helper modes."""

    Client = UltSQLClient

    @staticmethod
    def open(
        db_path: str = "./app.ultsql",
        auto_start: bool = True,
        host: str = "127.0.0.1",
        port: int = 0,
        **kwargs: Any,
    ) -> UltSQLClient:
        """
        Convenient local mode helper:
        Connects to or automatically launches a local UltSQL server for the given database file.
        """
        return UltSQLClient(
            target=db_path,
            auto_start=auto_start,
            host=host,
            port=port,
            **kwargs,
        )


def open(
    db_path: str = "./app.ultsql",
    auto_start: bool = True,
    host: str = "127.0.0.1",
    port: int = 0,
    **kwargs: Any,
) -> UltSQLClient:
    """Convenience alias for UltSQL.open()."""
    return UltSQL.open(
        db_path=db_path,
        auto_start=auto_start,
        host=host,
        port=port,
        **kwargs,
    )
