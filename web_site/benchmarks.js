// ULTSQL Dynamic Benchmarks Visualizer
(function () {
  'use strict';

  let rawData = null;

  function renderSkeletons() {
    const grid = document.getElementById('benchCardsGrid');
    if (!grid) return;
    grid.innerHTML = Array(4).fill(0).map(() => `
      <article class="bench-card metric-card bench-skeleton-card">
        <div class="skeleton-line" style="width: 35%; height: 12px; margin-bottom: 12px;"></div>
        <div class="skeleton-line" style="width: 70%; height: 22px; margin-bottom: 24px;"></div>
        <div class="skeleton-line" style="width: 100%; height: 10px; margin-bottom: 12px;"></div>
        <div class="skeleton-line" style="width: 100%; height: 10px;"></div>
      </article>
    `).join('');
  }

  async function loadBenchmarkData() {
    renderSkeletons();
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
        container.innerHTML = `<p style="color:var(--text-secondary);text-align:center;grid-column:1/-1;">Could not load benchmarks.json. Run <code>dart run tool/benchmarks/run_all.dart</code> to generate.</p>`;
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
    if (enginesEl) enginesEl.textContent = `ULTSQL v${env.ultsqlVersion} (Pure Dart & Standalone AOT) vs SQLite ${env.sqliteVersion} (Native C/FFI)`;
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
      card.className = 'bench-card metric-card';
      card.setAttribute('data-glow', '');

      const ult = item.engines && item.engines.ultsql ? item.engines.ultsql.median : null;
      const sq = item.engines && item.engines.sqlite ? item.engines.sqlite.median : null;

      let winnerTag = '';
      let ultFillPct = 0;
      let sqFillPct = 0;

      const higherBetter = item.better === 'higher';

      if (ult !== null && sq !== null) {
        const maxVal = Math.max(ult, sq);
        // Bar length is strictly proportional to the number displayed next to it
        ultFillPct = maxVal > 0 ? Math.max(Math.round((ult / maxVal) * 100), 4) : 0;
        sqFillPct = maxVal > 0 ? Math.max(Math.round((sq / maxVal) * 100), 4) : 0;

        if (higherBetter) {
          if (ult >= sq) {
            const ratio = (ult / sq).toFixed(2);
            winnerTag = `<span class="bench-winner-tag tag-ultsql-win">🏆 ULTSQL ${ratio}x FASTER</span>`;
          } else {
            const delta = (((sq - ult) / sq) * 100).toFixed(1);
            winnerTag = `<span class="bench-winner-tag tag-sqlite-win">SQLite +${delta}%</span>`;
          }
        } else {
          // Lower is better (latency in ms or µs: shorter bar is faster / winner)
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
              <span class="bench-engine-label" style="color:var(--text-primary);">⚡ ULTSQL (Pure Dart)</span>
              <span class="bench-engine-val" style="color:var(--text-primary);">${ult !== null ? formatVal(ult) + ' ' + item.unit : 'N/A'}</span>
            </div>
            <div class="bench-bar-track">
              <div class="bench-bar-fill fill-ultsql" style="width: 0%;" data-target-width="${ultFillPct}%"></div>
            </div>
          </div>

          ${sq !== null ? `
          <div class="bench-bar-row">
            <div class="bench-bar-meta">
              <span class="bench-engine-label" style="color:var(--text-secondary);">SQLite (Native C/FFI)</span>
              <span class="bench-engine-val" style="color:var(--text-secondary);">${formatVal(sq)} ${item.unit}</span>
            </div>
            <div class="bench-bar-track">
              <div class="bench-bar-fill fill-sqlite" style="width: 0%;" data-target-width="${sqFillPct}%"></div>
            </div>
          </div>` : ''}
        </div>

        ${item.note ? `<div class="bench-card-note">${item.note}</div>` : ''}
      `;

      grid.appendChild(card);
    });

    // Animate cards entrance
    const cards = grid.querySelectorAll('.bench-card');
    if (window.anime && typeof window.anime.animate === 'function' && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      window.anime.animate(cards, {
        opacity: [0, 1],
        translateY: [16, 0],
        delay: (el, i) => i * 35,
        duration: 380,
        ease: 'out(4)'
      });
    }

    // Smooth progressive bar fill animation
    requestAnimationFrame(() => {
      grid.querySelectorAll('.bench-bar-fill').forEach((bar) => {
        const target = bar.getAttribute('data-target-width');
        if (target) {
          bar.style.width = target;
        }
      });
    });

    if (window.UltMotion && window.UltMotion.observe) {
      window.UltMotion.observe(grid);
    }
    if (typeof window.injectCornerCrosshairs === 'function') {
      window.injectCornerCrosshairs(grid);
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

      let winner = '-';
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
        <td style="font-weight:600; color:var(--text-primary);">${item.label}</td>
        <td><code>${item.unit}</code></td>
        <td style="color:var(--text-primary); font-weight:700; font-family:var(--font-mono);">${formatVal(ult)}</td>
        <td style="color:var(--text-secondary); font-family:var(--font-mono);">${sq !== null ? formatVal(sq) : 'N/A'}</td>
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

  document.addEventListener('DOMContentLoaded', () => {
    loadBenchmarkData();
  });
})();
