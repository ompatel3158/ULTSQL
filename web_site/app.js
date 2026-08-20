// UltSQL Web Portal & Interactive Playground Scripts

document.addEventListener('DOMContentLoaded', () => {

  // --- 1. DARK / LIGHT THEME TOGGLE WITH LOCALSTORAGE ---
  const savedTheme = localStorage.getItem('ultsql_theme') || 'dark';
  document.documentElement.setAttribute('data-theme', savedTheme);
  updateThemeButton(savedTheme);

  const themeToggleBtn = document.getElementById('themeToggle');
  if (themeToggleBtn) {
    themeToggleBtn.addEventListener('click', () => {
      const active = document.documentElement.getAttribute('data-theme') || 'dark';
      const nextTheme = active === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', nextTheme);
      localStorage.setItem('ultsql_theme', nextTheme);
      updateThemeButton(nextTheme);
    });
  }

  function updateThemeButton(theme) {
    const btn = document.getElementById('themeToggle');
    if (btn) {
      btn.innerHTML = theme === 'dark' ? '🌙 Dark' : '☀️ Light';
    }
  }

  // --- 2. CODE TAB SWITCHER ---
  const tabBtns = document.querySelectorAll('.tab-btn');
  const tabContents = document.querySelectorAll('.tab-content');

  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-tab');

      tabBtns.forEach(b => b.classList.remove('active'));
      tabContents.forEach(c => c.classList.remove('active'));

      btn.classList.add('active');
      const targetContent = document.getElementById(targetId);
      if (targetContent) {
        targetContent.classList.add('active');
      }
    });
  });

  // --- 3. COPY TO CLIPBOARD BUTTONS ---
  const copyBtns = document.querySelectorAll('.copy-btn');
  const toast = document.getElementById('toast');

  copyBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const codeText = btn.previousElementSibling ? btn.previousElementSibling.innerText : btn.parentElement.innerText;
      
      navigator.clipboard.writeText(codeText).then(() => {
        showToast('✅ Copied to clipboard!');
      }).catch(() => {
        showToast('📋 Copied!');
      });
    });
  });

  function showToast(msg) {
    if (!toast) return;
    toast.innerText = msg;
    toast.classList.add('show');
    setTimeout(() => {
      toast.classList.remove('show');
    }, 2500);
  }

  // --- 4. REAL IN-BROWSER PURE-DART ENGINE PLAYGROUND ---
  const presetSelect = document.getElementById('presetSelect');
  const sqlEditor = document.getElementById('sqlEditor');
  const runBtn = document.getElementById('runBtn');
  const resultStatus = document.getElementById('resultStatus');
  const resultTable = document.getElementById('resultTable');

  const presets = {
    join: `-- Relational SQL: JOIN & Aggregate Query
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS users;

CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(100), role VARCHAR(50), active BOOLEAN);
CREATE TABLE orders (id INT PRIMARY KEY, user_id INT, amount DOUBLE);

INSERT INTO users VALUES (1, 'Om Patel', 'Lead Architect', true), (2, 'Alice Chen', 'AI Researcher', true);
INSERT INTO orders VALUES (101, 1, 14280.00), (102, 1, 350.00), (103, 2, 8950.50);

SELECT u.name, u.role, COUNT(o.id) AS total_orders, SUM(o.amount) AS total_spent
FROM users u
INNER JOIN orders o ON u.id = o.user_id
GROUP BY u.name, u.role
ORDER BY total_spent DESC;`,

    json: `-- NoSQL Dotted JSON Document Querying
DROP TABLE IF EXISTS documents;

CREATE TABLE documents (id INT PRIMARY KEY, title VARCHAR(100), category VARCHAR(50), metadata JSON);
INSERT INTO documents VALUES (1, 'Attention Is All You Need', 'AI', '{"tier": "VIP", "profile": {"address": {"city": "San Francisco"}}}');

SELECT title, category,
  JSON_EXTRACT(metadata, 'profile.address.city') AS city,
  JSON_EXTRACT(metadata, 'tier') AS membership
FROM documents;`,

    vector: `-- AI Vector RAG Search
DROP TABLE IF EXISTS documents;

CREATE TABLE documents (id INT PRIMARY KEY, title VARCHAR(100), category VARCHAR(50), embedding VECTOR);
INSERT INTO documents VALUES 
(1, 'Attention Is All You Need', 'AI', '[0.12, 0.88, -0.45]'),
(2, 'Converged Database Architecture', 'Database', '[0.05, 0.72, -0.21]');

SELECT title, category, VECTOR_DISTANCE(embedding, '[0.10, 0.85, -0.40]') AS distance
FROM documents
ORDER BY distance ASC;`,

    plsql: `-- High-Speed PL/SQL Loop Execution
DROP TABLE IF EXISTS system_logs;

CREATE TABLE system_logs (id INT PRIMARY KEY, event_name VARCHAR(100));

DECLARE i INT := 1;
BEGIN
  FOR i IN 1..10 LOOP
    INSERT INTO system_logs VALUES (i, 'EVENT_PING_' || i);
  END LOOP;
END;

SELECT * FROM system_logs;`,

    macro: `-- SQL Macro Calculation
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (id INT PRIMARY KEY, amount DOUBLE);
INSERT INTO orders VALUES (101, 14280.00), (102, 350.00);

CREATE MACRO calculate_tax(amount) AS amount * 0.15;
SELECT id, amount, calculate_tax(amount) AS tax_amount FROM orders;`,

    branch: `-- Table Query
DROP TABLE IF EXISTS users;

CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(100), role VARCHAR(50), active BOOLEAN);
INSERT INTO users VALUES (1, 'Om Patel', 'Lead Architect', true);

SELECT * FROM users WHERE active = true;`
  };

  if (presetSelect && sqlEditor) {
    presetSelect.addEventListener('change', () => {
      const key = presetSelect.value;
      if (presets[key]) {
        sqlEditor.value = presets[key];
      }
    });
  }

  if (runBtn) {
    runBtn.addEventListener('click', async () => {
      const sqlText = sqlEditor ? sqlEditor.value : 'SELECT * FROM users;';

      runBtn.innerText = '⚡ Executing (Real Pure-Dart Wasm Engine)...';
      runBtn.disabled = true;

      try {
        if (typeof window.executeUltSQL === 'function') {
          const rawResult = await window.executeUltSQL(sqlText);
          const res = typeof rawResult === 'string' ? JSON.parse(rawResult) : rawResult;

          runBtn.innerText = 'Run Query ▶';
          runBtn.disabled = false;

          if (res.status === 'success') {
            if (resultStatus) {
              resultStatus.innerHTML = `✅ Real Engine Executed in <strong>${res.elapsedMs} ms</strong> • Returned <strong>${res.rows ? res.rows.length : 0}</strong> rows • ⚡ 100% Pure Dart In-Browser Wasm Engine`;
            }

            if (resultTable && res.columns && res.rows && res.columns.length > 0) {
              let html = `<thead><tr>`;
              res.columns.forEach(h => html += `<th>${h}</th>`);
              html += `</tr></thead><tbody>`;

              res.rows.forEach(r => {
                html += `<tr>`;
                r.forEach(c => html += `<td>${c}</td>`);
                html += `</tr>`;
              });
              html += `</tbody>`;
              resultTable.innerHTML = html;
            } else if (resultTable && res.message) {
              resultTable.innerHTML = `<tbody><tr><td style="color: #10b981; font-family: monospace;">${res.message}</td></tr></tbody>`;
            } else if (resultTable) {
              resultTable.innerHTML = `<tbody><tr><td style="color: #10b981; font-family: monospace;">Query executed successfully with 0 rows returned.</td></tr></tbody>`;
            }
          } else {
            if (resultStatus) {
              resultStatus.innerHTML = `❌ Real Engine Error (<strong>${res.elapsedMs} ms</strong>): ${res.error}`;
            }
          }
        } else {
          if (resultStatus) {
            resultStatus.innerHTML = `⏳ Loading 100% Pure Dart UltSQL Engine Wasm Bundle...`;
          }
          runBtn.innerText = 'Run Query ▶';
          runBtn.disabled = false;
        }
      } catch (err) {
        runBtn.innerText = 'Run Query ▶';
        runBtn.disabled = false;
        if (resultStatus) {
          resultStatus.innerHTML = `❌ Execution Exception: ${err.message}`;
        }
      }
    });
  }

  // --- 5. MOBILE MENU TOGGLE ---
  const menuToggle = document.getElementById('menuToggle');
  const navLinks = document.getElementById('navLinks');

  if (menuToggle && navLinks) {
    menuToggle.addEventListener('click', () => {
      navLinks.classList.toggle('active');
    });
  }

});
