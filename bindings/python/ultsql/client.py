"""
UltSQL Python Client Module
"""
import json
import urllib.request
import urllib.parse

class UltSQLClient:
    """Python Client for UltSQL Database Engine via REST Daemon."""

    def __init__(self, host="http://localhost:8080"):
        self.host = host.rstrip('/')

    def query(self, table_name):
        """Fetch all records from a table."""
        url = f"{self.host}/{table_name}"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            return data

    def insert(self, table_name, data_dict):
        """Insert a record into a table."""
        url = f"{self.host}/{table_name}"
        payload = json.dumps(data_dict).encode('utf-8')
        req = urllib.request.Request(url, data=payload, headers={'Content-Type': 'application/json'}, method='POST')
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode('utf-8'))

    def truncate(self, table_name):
        """Truncate a table."""
        url = f"{self.host}/{table_name}"
        req = urllib.request.Request(url, method='DELETE')
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode('utf-8'))

    def openapi_spec(self):
        """Get OpenAPI 3.0 documentation spec."""
        url = f"{self.host}/openapi.json"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode('utf-8'))
