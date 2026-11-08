// ULTSQL Features Page Interactivity & Live Metric Binding
(function () {
  'use strict';

  // 1. Category Filtering
  function initFilters() {
    const buttons = document.querySelectorAll('.feature-chip-btn');
    const cards = document.querySelectorAll('.feature-card');

    buttons.forEach((btn) => {
      btn.addEventListener('click', () => {
        buttons.forEach((b) => b.classList.remove('active'));
        btn.classList.add('active');

        const cat = btn.dataset.category;
        const visibleCards = [];

        cards.forEach((card) => {
          if (cat === 'all' || card.dataset.category === cat) {
            card.style.display = 'flex';
            visibleCards.push(card);
          } else {
            card.style.display = 'none';
          }
        });

        if (window.anime && typeof window.anime.animate === 'function' && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
          window.anime.animate(visibleCards, {
            opacity: [0, 1],
            translateY: [14, 0],
            delay: (el, i) => i * 35,
            duration: 360,
            ease: 'out(4)'
          });
        }
      });
    });
  }

  // 2. Fetch Real Measured Benchmark Metrics from data/benchmarks.json
  async function bindLiveMetrics() {
    try {
      const res = await fetch('data/benchmarks.json');
      if (!res.ok) return;
      const data = await res.json();
      if (!data || !Array.isArray(data.results)) return;

      const metricMap = new Map();
      data.results.forEach((item) => {
        if (item.engines && item.engines.ultsql) {
          metricMap.set(item.id, {
            median: item.engines.ultsql.median,
            unit: item.unit,
          });
        }
      });

      document.querySelectorAll('[data-metric]').forEach((el) => {
        const metricId = el.dataset.metric;
        const metric = metricMap.get(metricId);
        if (metric) {
          let formattedVal = metric.median;
          if (formattedVal >= 1000) {
            formattedVal = Math.round(formattedVal).toLocaleString('en-US');
          } else if (formattedVal < 10) {
            formattedVal = formattedVal.toFixed(2);
          } else {
            formattedVal = formattedVal.toFixed(1);
          }
          el.innerHTML = `⚡ <strong>${formattedVal} ${metric.unit}</strong> (tested on this rig)`;
          el.style.display = 'inline-flex';
        } else {
          el.style.display = 'none';
        }
      });
    } catch (e) {
      console.warn('Could not bind live metrics:', e);
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    initFilters();
    bindLiveMetrics();
  });
})();
