// ULTSQL Modern Glassmorphic Web Portal Scripts

document.addEventListener('DOMContentLoaded', () => {

  // --- 1. DARK / LIGHT THEME TOGGLE (Default: Dark) ---
  const savedTheme = localStorage.getItem('ultsql_theme') || 'dark';
  document.documentElement.setAttribute('data-theme', savedTheme);
  updateThemeUI(savedTheme);

  const themeToggleBtns = document.querySelectorAll('.theme-btn, #themeToggle');
  themeToggleBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const active = document.documentElement.getAttribute('data-theme') || 'dark';
      const nextTheme = active === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', nextTheme);
      localStorage.setItem('ultsql_theme', nextTheme);
      updateThemeUI(nextTheme);
    });
  });

  function updateThemeUI(theme) {
    const icons = document.querySelectorAll('.theme-icon');
    icons.forEach(icon => {
      icon.innerHTML = theme === 'dark' 
        ? `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><path d="M12 1v2M12 21v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M1 12h2M21 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4"/></svg>`
        : `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>`;
    });
  }

  // --- 2. MOBILE MENU DRAWER ---
  const menuToggle = document.getElementById('mobileMenuToggle');
  const navDrawer = document.getElementById('mobileNavDrawer');
  if (menuToggle && navDrawer) {
    menuToggle.addEventListener('click', (e) => {
      e.stopPropagation();
      navDrawer.classList.toggle('open');
    });
    navDrawer.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        navDrawer.classList.remove('open');
      });
    });
    document.addEventListener('click', (e) => {
      if (!navDrawer.contains(e.target) && !menuToggle.contains(e.target)) {
        navDrawer.classList.remove('open');
      }
    });
  }

  // --- 3. INSTALLATION TAB SWITCHER ---
  const tabPills = document.querySelectorAll('.tab-pill-btn');
  const installBoxes = document.querySelectorAll('.install-box-content');

  tabPills.forEach(pill => {
    pill.addEventListener('click', () => {
      const targetTab = pill.getAttribute('data-tab');

      tabPills.forEach(p => p.classList.remove('active'));
      installBoxes.forEach(box => box.style.display = 'none');

      pill.classList.add('active');
      const activeBox = document.getElementById(targetTab);
      if (activeBox) {
        activeBox.style.display = 'block';
      }
    });
  });

  // --- 4. COPY TO CLIPBOARD WITH TOAST ---
  const toast = document.getElementById('toast');
  document.querySelectorAll('.copy-btn, .install-copy-btn, .copy-icon-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const codeTarget = btn.getAttribute('data-code');
      const textToCopy = codeTarget ? codeTarget : (btn.previousElementSibling ? btn.previousElementSibling.innerText : btn.innerText);

      navigator.clipboard.writeText(textToCopy).then(() => {
        showToast('Copied to clipboard');
        const orig = btn.innerHTML;
        btn.innerHTML = '<span>✓ Copied</span>';
        setTimeout(() => { btn.innerHTML = orig; }, 1800);
      }).catch(() => {
        showToast('Copied to clipboard');
      });
    });
  });

  function showToast(msg) {
    if (!toast) return;
    toast.innerText = msg;
    toast.classList.add('show');
    setTimeout(() => {
      toast.classList.remove('show');
    }, 2200);
  }

  // --- 5. IN-BROWSER PURE DART ENGINE PLAYGROUND ---
  const sqlEditor = document.getElementById('sqlEditor');
  const runBtn = document.getElementById('runBtn');
  const resultStatus = document.getElementById('resultStatus');
  const resultTable = document.getElementById('resultTable');
  const presetTabs = document.querySelectorAll('.preset-tab');

  const presets = {
    sql: `-- 1. Relational SQL: JOIN, Aggregates & Slotted Page Tables
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS users;

CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(100), role VARCHAR(50), active BOOLEAN);
CREATE TABLE orders (id INT PRIMARY KEY, user_id INT, amount DOUBLE);

INSERT INTO users VALUES 
(1, 'Om Patel', 'Lead Architect', true),
(2, 'Alice Chen', 'AI Researcher', true),
(3, 'Marcus Vance', 'Backend Engineer', true);

INSERT INTO orders VALUES 
(101, 1, 14280.00),
(102, 1, 350.00),
(103, 2, 8950.50),
(104, 3, 1200.00);

SELECT u.name, u.role, COUNT(o.id) AS total_orders, SUM(o.amount) AS total_spent
FROM users u
INNER JOIN orders o ON u.id = o.user_id
GROUP BY u.name, u.role
ORDER BY total_spent DESC;`,

    vector: `-- 2. AI Vector RAG: 768-Dim HNSW Similarity Search
DROP TABLE IF EXISTS documents;

CREATE TABLE documents (
  id INT PRIMARY KEY,
  title VARCHAR(100),
  category VARCHAR(50),
  embedding VECTOR
);

INSERT INTO documents VALUES 
(1, 'Attention Is All You Need', 'AI', '[0.12, 0.88, -0.45]'),
(2, 'Converged Multimodal Database Architecture', 'Database', '[0.05, 0.72, -0.21]'),
(3, 'High Performance Slotted Pages with CRC32', 'Storage', '[-0.22, 0.15, 0.65]');

-- Query nearest vectors using Euclidean / Cosine similarity
SELECT title, category, VECTOR_DISTANCE(embedding, '[0.10, 0.85, -0.40]') AS distance
FROM documents
ORDER BY distance ASC
LIMIT 2;`,

    nosql: `-- 3. NoSQL JSON: Dotted-Path Document Traversal
DROP TABLE IF EXISTS user_profiles;

CREATE TABLE user_profiles (
  id INT PRIMARY KEY,
  username VARCHAR(50),
  metadata JSON
);

INSERT INTO user_profiles VALUES 
(1, 'ompatel', '{"profile": {"city": "San Francisco", "tier": "Enterprise"}, "features": ["pgwire", "vector"]}'),
(2, 'alice', '{"profile": {"city": "New York", "tier": "Pro"}, "features": ["crdt", "json"]}');

-- Direct dotted JSON attribute extraction
SELECT username,
  JSON_EXTRACT(metadata, 'profile.tier') AS tier,
  JSON_EXTRACT(metadata, 'profile.city') AS location
FROM user_profiles
WHERE JSON_EXTRACT(metadata, 'profile.tier') = 'Enterprise';`,

    plsql: `-- 4. PL/SQL Procedural Script Execution
DROP TABLE IF EXISTS system_audit;
CREATE TABLE system_audit (id INT PRIMARY KEY, event_tag VARCHAR(100), val DOUBLE);

DECLARE
  counter INT := 0;
  total DOUBLE := 0.0;
BEGIN
  WHILE counter < 5 LOOP
    counter := counter + 1;
    total := total + (counter * 10.5);
    INSERT INTO system_audit VALUES (counter, 'METRIC_TICK_' || counter, total);
  END LOOP;
END;

SELECT * FROM system_audit ORDER BY id ASC;`
  };

  presetTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const presetKey = tab.getAttribute('data-preset');
      if (presets[presetKey] && sqlEditor) {
        sqlEditor.value = presets[presetKey];
        presetTabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
      }
    });
  });

  if (runBtn) {
    runBtn.addEventListener('click', async () => {
      const sqlText = sqlEditor ? sqlEditor.value : 'SELECT * FROM users;';

      runBtn.innerText = 'Executing...';
      runBtn.disabled = true;

      try {
        if (typeof window.executeUltSQL === 'function') {
          const rawResult = await window.executeUltSQL(sqlText);
          const res = typeof rawResult === 'string' ? JSON.parse(rawResult) : rawResult;

          runBtn.innerText = 'Run Query';
          runBtn.disabled = false;

          if (res.status === 'success') {
            if (resultStatus) {
              resultStatus.innerHTML = `<span style="color: var(--accent-emerald); font-weight: 600;">⚡ Executed in ${res.elapsedMs} ms</span> • ${res.rows ? res.rows.length : 0} rows`;
            }

            if (resultTable && res.columns && res.rows && res.columns.length > 0) {
              let html = `<thead><tr style="border-bottom: 1px solid var(--border-subtle); text-align: left;">`;
              res.columns.forEach(h => html += `<th style="padding: 0.5rem 0.75rem; color: var(--text-tertiary); font-size: 0.75rem;">${escapeHtml(h)}</th>`);
              html += `</tr></thead><tbody>`;

              res.rows.forEach(r => {
                html += `<tr style="border-bottom: 1px solid rgba(255,255,255,0.03);">`;
                r.forEach(c => html += `<td style="padding: 0.5rem 0.75rem; font-size: 0.82rem; font-family: var(--font-mono); color: var(--text-primary);">${escapeHtml(c)}</td>`);
                html += `</tr>`;
              });
              html += `</tbody>`;
              resultTable.innerHTML = html;
            } else if (resultTable && res.message) {
              resultTable.innerHTML = `<tbody><tr><td style="color: var(--accent-emerald); font-family: var(--font-mono); font-size: 0.85rem; padding: 0.75rem;">${escapeHtml(res.message)}</td></tr></tbody>`;
            } else if (resultTable) {
              resultTable.innerHTML = `<tbody><tr><td style="color: var(--accent-emerald); font-family: var(--font-mono); font-size: 0.85rem; padding: 0.75rem;">Command completed successfully.</td></tr></tbody>`;
            }
          } else {
            const title = res.errorTitle || 'Execution Error';
            const errorMsg = res.error || res.rawError || 'An unexpected error occurred.';
            const hint = res.errorHint || 'Check your SQL syntax or table declarations.';

            if (resultStatus) {
              resultStatus.innerHTML = `<span style="color: #ef4444; font-weight: 600;">[Error] (${res.elapsedMs} ms)</span>`;
            }

            if (resultTable) {
              resultTable.innerHTML = `
                <tbody>
                  <tr>
                    <td style="padding: 1rem; background: rgba(239, 68, 68, 0.08); border: 1px solid rgba(239, 68, 68, 0.3); border-radius: var(--radius-sm);">
                      <div style="font-size: 0.88rem; font-weight: 700; color: #f87171; margin-bottom: 0.35rem;">${escapeHtml(title)}</div>
                      <div style="color: #fca5a5; font-family: var(--font-mono); font-size: 0.82rem; line-height: 1.5; white-space: pre-wrap;">${escapeHtml(errorMsg)}</div>
                      ${hint ? `<div style="color: var(--text-tertiary); font-size: 0.78rem; margin-top: 0.5rem;"><strong>Suggestion:</strong> ${escapeHtml(hint)}</div>` : ''}
                    </td>
                  </tr>
                </tbody>
              `;
            }
          }
        } else {
          if (resultStatus) {
            resultStatus.innerHTML = `Initializing Pure-Dart Wasm Engine...`;
          }
          runBtn.innerText = 'Run Query';
          runBtn.disabled = false;
        }
      } catch (err) {
        runBtn.innerText = 'Run Query';
        runBtn.disabled = false;
        if (resultStatus) {
          resultStatus.innerHTML = `<span style="color: #ef4444; font-weight: 600;">Execution Error</span>`;
        }
        if (resultTable) {
          resultTable.innerHTML = `<tbody><tr><td style="color: #ef4444; padding: 0.75rem;">${escapeHtml(err.message)}</td></tr></tbody>`;
        }
      }
    });
  }

  function escapeHtml(str) {
    if (str === null || str === undefined) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

});
