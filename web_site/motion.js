/* ULTSQL motion system.
 *  data-reveal="up|down|left|right|zoom|fade"  + data-reveal-delay="ms"
 *  data-stagger="ms" on a parent -> children with data-reveal get incremental delays
 *  data-count="12345" [data-count-decimals="1"] [data-count-suffix="+"] [data-count-prefix="~"]
 *  data-glow   -> cursor-following spotlight
 *  Dispatches 'ult:reveal' on elements as they enter the viewport.
 */
(function () {
  'use strict';
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const root = document.documentElement;
  root.classList.add('motion-ready');

  // ---- Count-up ----
  function formatNumber(v, decimals) {
    return v.toLocaleString('en-US', { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
  }
  function runCounter(el) {
    if (el.dataset.countDone) return;
    el.dataset.countDone = '1';
    const target = parseFloat(el.dataset.count);
    if (isNaN(target)) return;
    const decimals = parseInt(el.dataset.countDecimals || '0', 10);
    const prefix = el.dataset.countPrefix || '';
    const suffix = el.dataset.countSuffix || '';
    if (reduce) { el.textContent = prefix + formatNumber(target, decimals) + suffix; return; }
    const dur = parseInt(el.dataset.countDuration || '1600', 10);
    const t0 = performance.now();
    const ease = (t) => 1 - Math.pow(1 - t, 4);
    (function tick(now) {
      const p = Math.min(1, (now - t0) / dur);
      el.textContent = prefix + formatNumber(target * ease(p), decimals) + suffix;
      if (p < 1) requestAnimationFrame(tick);
    })(t0);
  }

  // ---- Reveal ----
  function applyStagger(scope) {
    scope.querySelectorAll('[data-stagger]').forEach((parent) => {
      const step = parseInt(parent.dataset.stagger || '80', 10);
      parent.querySelectorAll(':scope > [data-reveal]').forEach((child, i) => {
        if (!child.dataset.revealDelay) child.dataset.revealDelay = String(i * step);
      });
    });
  }

  let io = null;
  function reveal(el) {
    el.classList.add('is-revealed');
    el.querySelectorAll('[data-count]').forEach(runCounter);
    if (el.hasAttribute('data-count')) runCounter(el);
    el.dispatchEvent(new CustomEvent('ult:reveal', { bubbles: true }));
  }
  function observe(scope) {
    scope = scope || document;
    applyStagger(scope);
    const targets = scope.querySelectorAll('[data-reveal]:not(.is-revealed), [data-count]:not([data-count-done])');
    targets.forEach((el) => {
      if (el.dataset.revealDelay) el.style.setProperty('--reveal-delay', el.dataset.revealDelay + 'ms');
      if (reduce || !('IntersectionObserver' in window)) { reveal(el); return; }
      io.observe(el);
    });
  }
  if ('IntersectionObserver' in window) {
    io = new IntersectionObserver((entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) { reveal(e.target); io.unobserve(e.target); }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
  }

  // ---- Scroll progress ----
  function progressBar() {
    if (reduce) return;
    const bar = document.createElement('div');
    bar.className = 'ult-scroll-progress';
    bar.setAttribute('aria-hidden', 'true');
    document.body.appendChild(bar);
    let ticking = false;
    const update = () => {
      const h = document.documentElement.scrollHeight - innerHeight;
      bar.style.transform = 'scaleX(' + (h > 0 ? scrollY / h : 0) + ')';
      ticking = false;
    };
    addEventListener('scroll', () => { if (!ticking) { ticking = true; requestAnimationFrame(update); } }, { passive: true });
    update();
  }

  // ---- Spotlight glow ----
  function glow() {
    document.addEventListener('pointermove', (e) => {
      const card = e.target.closest && e.target.closest('[data-glow]');
      if (!card) return;
      const r = card.getBoundingClientRect();
      card.style.setProperty('--mx', (e.clientX - r.left) + 'px');
      card.style.setProperty('--my', (e.clientY - r.top) + 'px');
    }, { passive: true });
  }

  // ---- Smooth in-page anchors + page-leave fade ----
  function links() {
    document.addEventListener('click', (e) => {
      const a = e.target.closest && e.target.closest('a[href]');
      if (!a || e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || a.target === '_blank') return;
      const href = a.getAttribute('href');
      if (href.startsWith('#') && href.length > 1) {
        const t = document.getElementById(decodeURIComponent(href.slice(1)));
        if (t) {
          e.preventDefault();
          t.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' });
          history.pushState(null, '', href);
        }
        return;
      }
      const url = new URL(a.href, location.href);
      if (reduce || url.origin !== location.origin || url.pathname === location.pathname) return;
      e.preventDefault();
      root.classList.add('motion-leaving');
      setTimeout(() => { location.href = a.href; }, 200);
    });
    // Restore when navigating back via bfcache
    addEventListener('pageshow', () => root.classList.remove('motion-leaving'));
  }

  function init() {
    observe(document);
    progressBar();
    glow();
    links();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();

  // Public hook for dynamically rendered content.
  window.UltMotion = { observe, runCounter };
})();
