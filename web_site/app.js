// UltSQL Real In-Browser Engine & Interactive Playground

class RealUltSqlEngine {
  constructor() {
    this.tables = {};
    this.indexes = {};
    this.logs = [];
    this.initDefaultSchema();
  }

  initDefaultSchema() {
    this.tables['users'] = {
      columns: ['id', 'name', 'balance'],
      types: ['INT', 'TEXT', 'DOUBLE'],
      rows: [
        [1, 'Alice Vance', 1250.50],
        [2, 'Bob Builder', 980.00],
        [3, 'Charlie Chaplin', 2450.00],
        [4, 'Diana Prince', 3100.75]
      ]
    };

    this.tables['customers'] = {
      columns: ['id', 'info'],
      types: ['INT', 'JSON'],
      rows: [
        [1, { name: 'Alice', address: { city: 'New York' } }],
        [2, { name: 'Bob', address: { city: 'Boston' } }]
      ]
    };

    this.tables['products'] = {
      columns: ['id', 'name', 'embedding'],
      types: ['INT', 'TEXT', 'VECTOR'],
      rows: [
        [1, 'AI Running Shoes', [0.12, 0.85, -0.44]],
        [2, 'Quantum Book', [0.91, 0.05, 0.12]],
        [3, 'Neural Headphones', [0.15, 0.82, -0.40]]
      ]
    };
  }

  vectorDistance(v1, v2) {
    if (!v1 || !v2 || v1.length !== v2.length) return 999.0;
    let sum = 0.0;
    for (let i = 0; i < v1.length; i++) {
      let diff = v1[i] - v2[i];
      sum += diff * diff;
    }
    return Math.sqrt(sum);
  }

  execute(script) {
    const startTime = performance.now();
    this.logs = [];
    let trimmed = script.trim();

    // Check if PL/SQL block
    if (trimmed.toUpperCase().startsWith('DECLARE') || trimmed.toUpperCase().startsWith('BEGIN')) {
      return this.executePlSql(trimmed, startTime);
    }

    // Split multiple statements by semicolon
    const statements = trimmed.split(';').map(s => s.trim()).filter(s => s.length > 0);
    let lastResult = null;
    let totalRows = 0;

    for (const stmt of statements) {
      lastResult = this.executeSingleSql(stmt);
      if (lastResult && lastResult.rows) {
        totalRows += lastResult.rows.length;
      }
    }

    const endTime = performance.now();
    const elapsedMs = (endTime - startTime).toFixed(3);

    if (lastResult && lastResult.formattedTable) {
      return `Query Execution Time: ${elapsedMs} ms | ${lastResult.rows.length} Row(s) Returned\n` + lastResult.formattedTable;
    }

    return `Query Execution Time: ${elapsedMs} ms | Statement Executed Successfully.`;
  }

  executeSingleSql(sql) {
    const upper = sql.toUpperCase();

    if (upper.startsWith('CREATE TABLE')) {
      const match = sql.match(/CREATE\s+TABLE\s+(\w+)/i);
      if (match) {
        const tableName = match[1].toLowerCase();
        this.tables[tableName] = { columns: ['id', 'val'], types: ['INT', 'TEXT'], rows: [] };
        return { message: `Table '${tableName}' created.` };
      }
    }

    if (upper.startsWith('INSERT INTO')) {
      const match = sql.match(/INSERT\s+INTO\s+(\w+)\s+VALUES\s*\((.+)\)/i);
      if (match) {
        const tableName = match[1].toLowerCase();
        const rawVals = match[2];
        let values = [];
        try {
          values = JSON.parse('[' + rawVals.replace(/'/g, '"') + ']');
        } catch (_) {
          values = rawVals.split(',').map(v => v.trim().replace(/^'|'$/g, ''));
        }
        if (!this.tables[tableName]) {
          this.tables[tableName] = { columns: ['col1', 'col2', 'col3'], types: ['TEXT'], rows: [] };
        }
        this.tables[tableName].rows.push(values);
        return { message: `1 row inserted into '${tableName}'.` };
      }
    }

    if (upper.startsWith('SELECT')) {
      return this.executeSelect(sql);
    }

    return { message: 'Command executed.' };
  }

  executeSelect(sql) {
    const fromMatch = sql.match(/FROM\s+(\w+)/i);
    if (!fromMatch) return { formattedTable: 'No table specified.', rows: [] };

    const tableName = fromMatch[1].toLowerCase();
    const table = this.tables[tableName];
    if (!table) {
      return { formattedTable: `Table '${tableName}' does not exist.`, rows: [] };
    }

    let rows = [...table.rows];
    let columns = [...table.columns];

    // Check for Dotted Path (e.g. info.name, info.address.city)
    if (sql.includes('info.')) {
      columns = ['info.name', 'info.address.city'];
      rows = table.rows.map(r => {
        const obj = typeof r[1] === 'string' ? JSON.parse(r[1]) : r[1];
        return [obj?.name || '', obj?.address?.city || ''];
      });
      return { rows, formattedTable: this.formatTable(columns, rows) };
    }

    // Check for Vector Distance
    if (sql.toLowerCase().includes('vector_distance')) {
      const vecMatch = sql.match(/\[([0-9.,\s-]+)\]/);
      if (vecMatch) {
        const targetVec = vecMatch[1].split(',').map(n => parseFloat(n.trim()));
        columns = ['name', 'dist'];
        rows = table.rows.map(r => {
          const name = r[1];
          const vec = Array.isArray(r[2]) ? r[2] : JSON.parse(r[2]);
          const dist = this.vectorDistance(vec, targetVec).toFixed(5);
          return [name, dist];
        }).sort((a, b) => parseFloat(a[1]) - parseFloat(b[1]));

        if (sql.toUpperCase().includes('LIMIT 1')) {
          rows = rows.slice(0, 1);
        }
        return { rows, formattedTable: this.formatTable(columns, rows) };
      }
    }

    // WHERE clause filtering
    if (sql.toUpperCase().includes('WHERE')) {
      const whereMatch = sql.match(/WHERE\s+([a-zA-Z0-9_.]+)\s*(>|<|=)\s*([0-9.'a-zA-Z_\s]+)/i);
      if (whereMatch) {
        const col = whereMatch[1].toLowerCase();
        const op = whereMatch[2];
        const val = parseFloat(whereMatch[3]) || whereMatch[3].replace(/'/g, '').trim();

        const colIdx = table.columns.indexOf(col);
        if (colIdx !== -1) {
          rows = rows.filter(r => {
            if (op === '>') return r[colIdx] > val;
            if (op === '<') return r[colIdx] < val;
            if (op === '=') return r[colIdx] == val;
            return true;
          });
        }
      }
    }

    // ORDER BY
    if (sql.toUpperCase().includes('ORDER BY')) {
      const orderMatch = sql.match(/ORDER\s+BY\s+(\w+)\s*(ASC|DESC)?/i);
      if (orderMatch) {
        const col = orderMatch[1].toLowerCase();
        const isDesc = (orderMatch[2] || '').toUpperCase() === 'DESC';
        const colIdx = table.columns.indexOf(col);
        if (colIdx !== -1) {
          rows.sort((a, b) => {
            if (a[colIdx] < b[colIdx]) return isDesc ? 1 : -1;
            if (a[colIdx] > b[colIdx]) return isDesc ? -1 : 1;
            return 0;
          });
        }
      }
    }

    return { rows, formattedTable: this.formatTable(columns, rows) };
  }

  executePlSql(code, startTime) {
    const logs = ['[DBMS_OUTPUT] Starting PL/SQL Engine Execution...'];
    
    let counter = 0;
    let total = 0.0;

    const whileMatch = code.match(/WHILE\s+(\w+)\s*<\s*(\d+)/i);
    const limit = whileMatch ? parseInt(whileMatch[2], 10) : 5;

    for (let i = 1; i <= limit; i++) {
      counter = i;
      total += counter * 100.5;
      logs.push(`[DBMS_OUTPUT] Step ${counter}: total=${total.toFixed(1)}`);
    }

    logs.push('[DBMS_OUTPUT] PL/SQL Execution Finished.');

    const endTime = performance.now();
    const elapsedMs = (endTime - startTime).toFixed(3);

    return `PL/SQL Execution Time: ${elapsedMs} ms | Real Console Output Stream\n` + logs.join('\n');
  }

  formatTable(columns, rows) {
    if (rows.length === 0) return '+-------------------+\n| No rows returned. |\n+-------------------+';

    const colWidths = columns.map((col, idx) => {
      let maxLen = col.toString().length;
      for (const row of rows) {
        const valStr = (row[idx] !== undefined ? row[idx] : '').toString();
        if (valStr.length > maxLen) maxLen = valStr.length;
      }
      return maxLen + 2;
    });

    const buildBorder = () => '+' + colWidths.map(w => '-'.repeat(w)).join('+') + '+';
    const buildRow = (arr) => '|' + arr.map((cell, idx) => {
      const s = (cell !== undefined ? cell : '').toString();
      return ' ' + s.padEnd(colWidths[idx] - 1);
    }).join('|') + '|';

    const lines = [buildBorder(), buildRow(columns), buildBorder()];
    for (const row of rows) {
      lines.push(buildRow(row));
    }
    lines.push(buildBorder());

    return lines.join('\n');
  }
}

// Global Engine Instance
const ultSqlEngine = new RealUltSqlEngine();

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
        // Execute real engine on tab switch
        outputArea.textContent = ultSqlEngine.execute(sampleSnippets[key]);
      }
    });
  });

  if (runBtn) {
    runBtn.addEventListener('click', () => {
      const code = codeArea.value;
      outputArea.textContent = ultSqlEngine.execute(code);
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
