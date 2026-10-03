// ULTSQL Dynamic Benchmarks Visualizer
(function () {
  'use strict';

  let rawData = null;

  async function loadBenchmarkData() {
    try {
      const res = await fetch('data/benchmarks.json');
      if (!res.ok) throw new Error('HTTP ' + res.status);
      rawData = await res.json();
      renderEnvironment(rawData.environment, rawData.generatedAt);
      renderCards(rawData.results, 'all');
      renderTable(rawData.results);
      initFilterTabs();
    } catch (e) {
      console.error('Failed to load benchmark data:', e);
      const container = document.getElementById('benchCardsGrid');
      if (container) {
        container.innerHTML = `<p style="color:#ef4444;text-align:center;grid-column:1/-1;">Could not load benchmarks.json. Run <code>dart run tool/benchmarks/run_all.dart</code> to generate.</p>`;
      }
    }
  }

  function renderEnvironment(env, dateStr) {
    if (!env) return;
    const cpuEl = document.getElementById('rigCpu');
    const ramEl = document.getElementById('rigRam');
    const diskEl = document.getElementById('rigDisk');
    const osEl = document.getElementById('rigOs');
    const enginesEl = document.getElementById('rigEngines');
    const timestampEl = document.getElementById('rigTimestamp');

    if (cpuEl) cpuEl.textContent = env.cpu || '13th Gen Intel Core i7-13650HX';
    if (ramEl) ramEl.textContent = `${env.ramGB || 16} GB DDR5 (${env.ramSpeedMHz || 4800} MHz)`;
    if (diskEl) diskEl.textContent = env.disk || 'NVMe SSD';
    if (osEl) osEl.textContent = `${env.os} (${env.logicalCores} threads)`;
    if (enginesEl) enginesEl.textContent = `ULTSQL v${env.ultsqlVersion} (Pure Dart) vs SQLite ${env.sqliteVersion} (C/FFI)`;
    if (timestampEl) {
      const d = dateStr ? new Date(dateStr) : new Date();
      timestampEl.textContent = `Measured on ${d.toLocaleDateString()} ${d.toLocaleTimeString()} (Commit: ${env.commit || 'c9f05ca'})`;
    }
  }

  function formatVal(v) {
    if (v === undefined || v === null) return 'N/A';
    if (v >= 1000) return Math.round(v).toLocaleString('en-US');
    if (v < 0.01) return v.toFixed(4);
    if (v < 10) return v.toFixed(3);
    return v.toFixed(1);
  }

  function renderCards(results, filterCategory) {
    const grid = document.getElementById('benchCardsGrid');
    if (!grid || !Array.isArray(results)) return;
    grid.innerHTML = '';

    results.forEach((item) => {
      // Determine card filter group
      let cat = 'relational';
      if (item.id.startsWith('big_')) cat = 'big';
      else if (item.group.includes('NoSQL')) cat = 'nosql';
      else if (item.group.includes('Key-Value')) cat = 'kv';
      else if (item.group.includes('Vector')) cat = 'vector';

      if (filterCategory !== 'all' && cat !== filterCategory) return;

      const card = document.createElement('article');
      card.className = 'bench-card';
      card.setAttribute('data-glow', '');

      const ult = item.engines && item.engines.ultsql ? item.engines.ultsql.median : null;
      const sq = item.engines && item.engines.sqlite ? item.engines.sqlite.median : null;

      let winnerTag = '';
      let ultFillPct = 0;
      let sqFillPct = 0;

      const higherBetter = item.better === 'higher';

      if (ult !== null && sq !== null) {
        if (higherBetter) {
          const maxVal = Math.max(ult, sq);
          ultFillPct = maxVal > 0 ? (ult / maxVal) * 100 : 0;
          sqFillPct = maxVal > 0 ? (sq / maxVal) * 100 : 0;

          if (ult >= sq) {
            const ratio = (ult / sq).toFixed(2);
            winnerTag = `<span class="bench-winner-tag tag-ultsql-win">🏆 ULTSQL ${ratio}x FASTER</span>`;
          } else {
            const delta = (((sq - ult) / sq) * 100).toFixed(1);
            winnerTag = `<span class="bench-winner-tag tag-sqlite-win">SQLite +${delta}%</span>`;
          }
        } else {
          // Lower is better (latency in ms or µs)
          const minVal = Math.min(ult, sq);
          const maxVal = Math.max(ult, sq);
          // Invert for progress bar visual (lower latency = longer green bar)
          ultFillPct = maxVal > 0 ? (minVal / ult) * 100 : 0;
          sqFillPct = maxVal > 0 ? (minVal / sq) * 100 : 0;

          if (ult <= sq) {
            const ratio = (sq / ult).toFixed(2);
            winnerTag = `<span class="bench-winner-tag tag-ultsql-win">🏆 ULTSQL ${ratio}x LOWER LATENCY</span>`;
          } else {
            const delta = (((ult - sq) / sq) * 100).toFixed(0);
            winnerTag = `<span class="bench-winner-tag tag-sqlite-win">SQLite +${delta}%</span>`;
          }
        }
      } else if (ult !== null) {
        ultFillPct = 100;
        winnerTag = `<span class="bench-winner-tag tag-standalone">AI Native Feature</span>`;
      }

      card.innerHTML = `
        <div class="bench-card-header">
          <div>
            <div class="bench-card-group">${item.group} &bull; ${item.better === 'higher' ? 'Higher is better' : 'Lower is better'}</div>
            <h3 class="bench-card-title">${item.label}</h3>
          </div>
          <div>${winnerTag}</div>
        </div>

        <div class="bench-bars-container">
          <div class="bench-bar-row">
            <div class="bench-bar-meta">
              <span class="bench-engine-label" style="color:#22d3ee;">⚡ ULTSQL (Pure Dart)</span>
              <span class="bench-engine-val" style="color:#22d3ee;">${ult !== null ? formatVal(ult) + ' ' + item.unit : 'N/A'}</span>
            </div>
            <div class="bench-bar-track">
              <div class="bench-bar-fill fill-ultsql" style="width: ${ultFillPct}%;"></div>
            </div>
          </div>

          ${sq !== null ? `
          <div class="bench-bar-row">
            <div class="bench-bar-meta">
              <span class="bench-engine-label" style="color:#94a3b8;">SQLite (Native C/FFI)</span>
              <span class="bench-engine-val" style="color:#94a3b8;">${formatVal(sq)} ${item.unit}</span>
            </div>
            <div class="bench-bar-track">
              <div class="bench-bar-fill fill-sqlite" style="width: ${sqFillPct}%;"></div>
            </div>
          </div>` : ''}
        </div>

        ${item.note ? `<div class="bench-card-note">${item.note}</div>` : ''}
      `;

      grid.appendChild(card);
    });

    if (window.UltMotion && window.UltMotion.observe) {
      window.UltMotion.observe(grid);
    }
  }

  function renderTable(results) {
    const tbody = document.getElementById('benchAuditTbody');
    if (!tbody || !Array.isArray(results)) return;
    tbody.innerHTML = '';

    results.forEach((item) => {
      const tr = document.createElement('tr');
      const ult = item.engines && item.engines.ultsql ? item.engines.ultsql.median : null;
      const sq = item.engines && item.engines.sqlite ? item.engines.sqlite.median : null;

      let winner = '—';
      if (ult !== null && sq !== null) {
        if (item.better === 'higher') {
          winner = ult >= sq ? '🏆 ULTSQL' : 'SQLite';
        } else {
          winner = ult <= sq ? '🏆 ULTSQL' : 'SQLite';
        }
      } else if (ult !== null) {
        winner = 'ULTSQL Only';
      }

      tr.innerHTML = `
        <td style="font-weight:600; color:#fff;">${item.label}</td>
        <td><code>${item.unit}</code></td>
        <td style="color:#22d3ee; font-weight:700; font-family:monospace;">${formatVal(ult)}</td>
        <td style="color:#94a3b8; font-family:monospace;">${sq !== null ? formatVal(sq) : 'N/A'}</td>
        <td style="font-weight:600;">${winner}</td>
      `;
      tbody.appendChild(tr);
    });
  }

  function initFilterTabs() {
    const btns = document.querySelectorAll('.bench-filter-btn');
    btns.forEach((btn) => {
      btn.addEventListener('click', () => {
        btns.forEach((b) => b.classList.remove('active'));
        btn.classList.add('active');
        const cat = btn.dataset.filter;
        if (rawData && rawData.results) {
          renderCards(rawData.results, cat);
        }
      });
    });

    const dlBtn = document.getElementById('downloadJsonBtn');
    if (dlBtn) {
      dlBtn.addEventListener('click', () => {
        if (!rawData) return;
        const blob = new Blob([JSON.stringify(rawData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `ultsql-benchmarks-${new Date().toISOString().slice(0,10)}.json`;
        a.click();
        URL.revokeObjectURL(url);
      });
    }
  }

  document.addEventListener('DOMContentLoaded', loadBenchmarkData);
})();
