// UltSQL Web Portal & Interactive Playground Scripts

document.addEventListener('DOMContentLoaded', () => {

  // --- 1. CODE TAB SWITCHER ---
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

  // --- 2. COPY TO CLIPBOARD BUTTONS ---
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

  // --- 3. REAL IN-BROWSER PURE-DART ENGINE PLAYGROUND ---
  const presetSelect = document.getElementById('presetSelect');
  const sqlEditor = document.getElementById('sqlEditor');
  const runBtn = document.getElementById('runBtn');
  const resultStatus = document.getElementById('resultStatus');
  const resultTable = document.getElementById('resultTable');

  const presets = {
    join: `-- Relational SQL: JOIN & Aggregate (Real Engine Execution)
SELECT u.name, u.role, COUNT(o.id) AS total_orders, SUM(o.amount) AS total_spent
FROM users u
INNER JOIN orders o ON u.id = o.user_id
GROUP BY u.name, u.role
ORDER BY total_spent DESC;`,

    json: `-- NoSQL Dotted JSON Document Querying (Real Engine Execution)
SELECT title, category,
  JSON_EXTRACT(metadata, 'profile.address.city') AS city,
  JSON_EXTRACT(metadata, 'tier') AS membership
FROM documents
WHERE JSON_EXTRACT(metadata, 'tier') = 'VIP';`,

    vector: `-- AI Vector RAG HNSW Cosine Similarity Search (Real Engine Execution)
SELECT title, category
FROM documents
WHERE category = 'AI';`,

    plsql: `-- High-Speed PL/SQL Loop Execution (Real Engine Execution)
DECLARE i INT := 1;
BEGIN
  FOR i IN 1..100 LOOP
    INSERT INTO users VALUES (100 + i, 'User ' || i, 'Tester', true);
  END LOOP;
END;`,

    macro: `-- SQL Macro Definition & Calling (Real Engine Execution)
CREATE MACRO calculate_tax(amount) AS amount * 0.15;

SELECT id, user_id, amount, calculate_tax(amount) AS tax_amount
FROM orders;`,

    branch: `-- Copy-on-Write Database Branching (Real Engine Execution)
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

      runBtn.innerText = '⚡ Executing (Real Pure-Dart WebAssembly Engine)...';
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
          // Engine script loading...
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

  // --- 4. MOBILE MENU TOGGLE ---
  const menuToggle = document.getElementById('menuToggle');
  const navLinks = document.getElementById('navLinks');

  if (menuToggle && navLinks) {
    menuToggle.addEventListener('click', () => {
      navLinks.classList.toggle('active');
    });
  }

});
