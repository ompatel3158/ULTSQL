// UltSQL Web Documentation & Interactive Playground Logic

document.addEventListener('DOMContentLoaded', () => {
  initPlayground();
  initSmoothScroll();
});

const sampleSnippets = {
  sql: `-- 1. Create Table & Insert Data
CREATE TABLE users (id INT PRIMARY KEY, name TEXT, balance DOUBLE);
INSERT INTO users VALUES (1, 'Alice Vance', 1250.50);
INSERT INTO users VALUES (2, 'Bob Builder', 980.00);

-- 2. Query with Where & Order By
SELECT name, balance 
FROM users 
WHERE balance > 1000.0
ORDER BY balance DESC;`,

  nosql: `-- NoSQL Dotted JSON Query
CREATE TABLE customers (id INT PRIMARY KEY, info JSON);
INSERT INTO customers VALUES (1, '{"name": "Alice", "address": {"city": "New York"}}');
INSERT INTO customers VALUES (2, '{"name": "Bob", "address": {"city": "Boston"}}');

-- Query Dotted Path
SELECT info.name, info.address.city FROM customers;`,

  vector: `-- AI Native Vector RAG Similarity Search
CREATE TABLE products (id INT PRIMARY KEY, name TEXT, embedding VECTOR);
INSERT INTO products VALUES (1, 'AI Running Shoes', '[0.12, 0.85, -0.44]');
INSERT INTO products VALUES (2, 'Quantum Book', '[0.91, 0.05, 0.12]');

-- HNSW Vector Distance Query
SELECT name, vector_distance(embedding, '[0.11, 0.84, -0.42]') AS dist
FROM products ORDER BY dist ASC LIMIT 1;`,

  plsql: `DECLARE
  counter INT := 0;
  total DOUBLE := 0.0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Starting PL/SQL Loop...');
  WHILE counter < 5 LOOP
    counter := counter + 1;
    total := total + (counter * 100.5);
    DBMS_OUTPUT.PUT_LINE('Step ' || counter || ': total=' || total);
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('PL/SQL Loop Finished.');
END;`
};

const simulatedOutputs = {
  sql: `Query Execution Time: 0.14 ms | 1 Row Returned
+-------------+---------+
| name        | balance |
+-------------+---------+
| Alice Vance | 1250.50 |
+-------------+---------+`,

  nosql: `Query Execution Time: 0.18 ms | 2 Rows Returned
+------------+-------------------+
| info.name  | info.address.city |
+------------+-------------------+
| Alice      | New York          |
| Bob        | Boston            |
+------------+-------------------+`,

  vector: `Query Execution Time: 0.22 ms | HNSW Vector Distance
+------------------+---------------+
| name             | dist          |
+------------------+---------------+
| AI Running Shoes | 0.00042       |
+------------------+---------------+`,

  plsql: `PL/SQL Execution Time: 0.35 ms | Console Output Stream
[DBMS_OUTPUT] Starting PL/SQL Loop...
[DBMS_OUTPUT] Step 1: total=100.5
[DBMS_OUTPUT] Step 2: total=301.5
[DBMS_OUTPUT] Step 3: total=603.0
[DBMS_OUTPUT] Step 4: total=1005.0
[DBMS_OUTPUT] Step 5: total=1507.5
[DBMS_OUTPUT] PL/SQL Loop Finished.`
};

function initPlayground() {
  const codeArea = document.getElementById('playgroundCode');
  const outputArea = document.getElementById('playgroundOutput');
  const tabs = document.querySelectorAll('.tab-btn');
  const runBtn = document.getElementById('runBtn');

  if (!codeArea || !outputArea) return;

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const key = tab.dataset.snippet;
      if (sampleSnippets[key]) {
        codeArea.value = sampleSnippets[key];
        outputArea.textContent = simulatedOutputs[key] || 'Ready to run query...';
      }
    });
  });

  if (runBtn) {
    runBtn.addEventListener('click', () => {
      outputArea.textContent = '⚡ Running UltSQL Volcano Iterator Engine...\n';
      setTimeout(() => {
        const activeTab = document.querySelector('.tab-btn.active');
        const key = activeTab ? activeTab.dataset.snippet : 'sql';
        outputArea.textContent = simulatedOutputs[key] || 'Execution Completed Successfully.';
      }, 150);
    });
  }
}

function initSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        target.scrollIntoView({
          behavior: 'smooth'
        });
      }
    });
  });
}
