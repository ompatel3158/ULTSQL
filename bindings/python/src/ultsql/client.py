"""
UltSQL Python Client Module
"""
import json
import urllib.request
import urllib.parse
from typing import Dict, Any, List

class UltSQLClient:
    """Python Client for UltSQL Database Engine via REST Daemon."""

    def __init__(self, host: str = "http://localhost:8080") -> None:
        self.host: str = host.rstrip('/')

    def query(self, table_name: str) -> Dict[str, Any]:
        """Fetch all records from a table."""
        url = f"{self.host}/{table_name}"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as resp:
            data: Dict[str, Any] = json.loads(resp.read().decode('utf-8'))
            return data

    def insert(self, table_name: str, data_dict: Dict[str, Any]) -> Dict[str, Any]:
        """Insert a record into a table."""
        url = f"{self.host}/{table_name}"
        payload = json.dumps(data_dict).encode('utf-8')
        req = urllib.request.Request(url, data=payload, headers={'Content-Type': 'application/json'}, method='POST')
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode('utf-8'))

    def truncate(self, table_name: str) -> Dict[str, Any]:
        """Truncate a table."""
        url = f"{self.host}/{table_name}"
        req = urllib.request.Request(url, method='DELETE')
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode('utf-8'))

    def openapi_spec(self) -> Dict[str, Any]:
        """Get OpenAPI 3.0 documentation spec."""
        url = f"{self.host}/openapi.json"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode('utf-8'))
