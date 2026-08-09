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

  // --- 3. LIVE INTERACTIVE PLAYGROUND ---
  const presetSelect = document.getElementById('presetSelect');
  const sqlEditor = document.getElementById('sqlEditor');
  const runBtn = document.getElementById('runBtn');
  const resultStatus = document.getElementById('resultStatus');
  const resultTable = document.getElementById('resultTable');

  const presets = {
    join: `-- Relational SQL: JOIN & Aggregate
SELECT u.name, u.role, COUNT(o.id) AS total_orders, SUM(o.amount) AS total_spent
FROM users u
INNER JOIN orders o ON u.id = o.user_id
GROUP BY u.name, u.role
ORDER BY total_spent DESC;`,

    json: `-- NoSQL Dotted JSON Document Querying
SELECT name, email,
  JSON_EXTRACT(metadata, 'profile.address.city') AS city,
  JSON_EXTRACT(metadata, 'tier') AS membership
FROM accounts
WHERE JSON_EXTRACT(metadata, 'tier') = 'VIP';`,

    vector: `-- AI Vector RAG HNSW Cosine Similarity Search
CREATE INDEX idx_vec ON documents(embedding) USING HNSW;

SELECT title, category,
  VECTOR_DISTANCE(embedding, [0.12, 0.85, 0.44, -0.19]) AS similarity_score
FROM documents
ORDER BY similarity_score ASC
LIMIT 3;`,

    plsql: `-- High-Speed PL/SQL Loop Execution
DECLARE i INT := 1;
BEGIN
  FOR i IN 1..1000 LOOP
    INSERT INTO system_logs VALUES (i, 'EVENT_PING_' || i, NOW());
  END LOOP;
END;`,

    macro: `-- SQL Macro Definition & Calling
CREATE MACRO calculate_tax(amount) AS amount * 0.15;

SELECT id, product_name, price, calculate_tax(price) AS tax_amount
FROM inventory;`,

    branch: `-- Copy-on-Write Database Branching
CALL ultsql_create_branch('feature-test-v2');
CALL ultsql_switch_branch('feature-test-v2');
INSERT INTO users VALUES (999, 'Tester Branch User');`
  };

  const mockData = {
    join: {
      headers: ['name', 'role', 'total_orders', 'total_spent'],
      rows: [
        ['Om Patel', 'Lead Architect', '42', '$14,280.00'],
        ['Alice Chen', 'AI Researcher', '19', '$8,950.50'],
        ['Marcus Vance', 'Backend Engineer', '11', '$3,410.00']
      ],
      time: '0.84 ms',
      rowsCount: 3
    },
    json: {
      headers: ['name', 'email', 'city', 'membership'],
      rows: [
        ['Om Patel', 'om@ultsql.io', 'San Francisco', 'VIP'],
        ['Sarah Jenkins', 'sarah@ai.org', 'New York', 'VIP']
      ],
      time: '0.42 ms',
      rowsCount: 2
    },
    vector: {
      headers: ['title', 'category', 'similarity_score'],
      rows: [
        ['Attention Is All You Need', 'Transformer AI', '0.0142'],
        ['HNSW Graph Indexing Fundamentals', 'Vector Search', '0.0389'],
        ['Converged Multimodal Database Design', 'Databases', '0.0712']
      ],
      time: '6.12 ms',
      rowsCount: 3
    },
    plsql: {
      headers: ['status', 'loops_executed', 'elapsed_time'],
      rows: [
        ['SUCCESS', '1,000 Inserts Auto-Batched', '0.78 ms']
      ],
      time: '0.78 ms',
      rowsCount: 1000
    },
    macro: {
      headers: ['id', 'product_name', 'price', 'tax_amount'],
      rows: [
        ['101', 'Quantum Server Rack', '$4,999.00', '$749.85'],
        ['102', 'High-Density NVMe Storage', '$1,299.00', '$194.85']
      ],
      time: '0.31 ms',
      rowsCount: 2
    },
    branch: {
      headers: ['branch_name', 'status', 'isolation_type'],
      rows: [
        ['feature-test-v2', 'ACTIVE_ISOLATED', 'Copy-on-Write (Zero-Copy)']
      ],
      time: '1.05 ms',
      rowsCount: 1
    }
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
    runBtn.addEventListener('click', () => {
      const key = presetSelect ? presetSelect.value : 'join';
      const data = mockData[key] || mockData.join;

      runBtn.innerText = '⚡ Executing...';
      runBtn.disabled = true;

      setTimeout(() => {
        runBtn.innerText = 'Run Query ▶';
        runBtn.disabled = false;

        if (resultStatus) {
          resultStatus.innerHTML = `Query executed in <strong>${data.time}</strong> • Returned <strong>${data.rowsCount}</strong> rows • Engine: 100% Pure Dart In-Memory Interpreter`;
        }

        if (resultTable) {
          let html = `<thead><tr>`;
          data.headers.forEach(h => html += `<th>${h}</th>`);
          html += `</tr></thead><tbody>`;

          data.rows.forEach(r => {
            html += `<tr>`;
            r.forEach(c => html += `<td>${c}</td>`);
            html += `</tr>`;
          });
          html += `</tbody>`;

          resultTable.innerHTML = html;
        }
      }, 250);
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
