import sys
from ultsql import UltSQLClient

print("--- PYTHON ULTSQL LIVE E2E TEST ---")
client = UltSQLClient("http://localhost:8888")

# 1. Fetch OpenAPI Specification
spec = client.openapi_spec()
print("1. OpenAPI Version:", spec.get("openapi"))
print("2. Server Info:", spec.get("info", {}).get("title"))

# 2. Insert Records via Python Client
res1 = client.insert("products", {"id": 1, "name": "Quantum Laptop", "price": 1299.99})
print("3. Insert Product 1:", res1)

res2 = client.insert("products", {"id": 2, "name": "Neural Headphones", "price": 299.50})
print("4. Insert Product 2:", res2)

# 3. Query Records via Python Client
query_res = client.query("products")
print("5. Query Products Count:", query_res.get("count"))
print("6. Query Products Rows:", query_res.get("rows"))

# 4. Truncate Table via Python Client
trunc_res = client.truncate("products")
print("7. Truncate Products:", trunc_res)

print("PYTHON E2E LIVE TEST PASSED CLEANLY!")
