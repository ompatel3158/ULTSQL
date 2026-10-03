// ULTSQL Documentation Client-Side Interactivity
(function () {
  'use strict';

  // 1. Copy-to-Clipboard
  function initCopyButtons() {
    document.querySelectorAll('.code-copy-btn').forEach((btn) => {
      btn.addEventListener('click', async () => {
        const card = btn.closest('.code-card');
        if (!card) return;
        const activeBlock = card.querySelector('.code-block:not([style*="display: none"])') || card.querySelector('.code-block');
        const codeText = activeBlock ? activeBlock.innerText : '';
        try {
          await navigator.clipboard.writeText(codeText);
          const origText = btn.innerHTML;
          btn.innerHTML = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg> Copied!`;
          btn.style.color = 'var(--text-primary)';
          btn.style.borderColor = 'var(--border-strong)';
          setTimeout(() => {
            btn.innerHTML = origText;
            btn.style.color = '';
            btn.style.borderColor = '';
          }, 2000);
        } catch (e) {
          console.error('Clipboard copy failed:', e);
        }
      });
    });
  }

  // 2. Multi-Language Tabs
  function initLanguageTabs() {
    const savedLang = localStorage.getItem('ultsql_doc_lang') || 'dart';

    function switchLang(targetLang) {
      localStorage.setItem('ultsql_doc_lang', targetLang);
      document.querySelectorAll('.code-card[data-tabs]').forEach((card) => {
        const tabs = card.querySelectorAll('.code-tab-btn');
        const blocks = card.querySelectorAll('.code-block');
        let matched = false;

        tabs.forEach((tab) => {
          if (tab.dataset.lang === targetLang) {
            tab.classList.add('active');
            matched = true;
          } else {
            tab.classList.remove('active');
          }
        });

        blocks.forEach((block) => {
          if (block.dataset.lang === targetLang) {
            block.style.display = 'block';
          } else if (matched) {
            block.style.display = 'none';
          }
        });
      });
    }

    document.querySelectorAll('.code-tab-btn').forEach((btn) => {
      btn.addEventListener('click', () => {
        const lang = btn.dataset.lang;
        if (lang) switchLang(lang);
      });
    });

    switchLang(savedLang);
  }

  // 3. Search Filter
  function initSearch() {
    const input = document.getElementById('docsSearchInput');
    if (!input) return;

    input.addEventListener('input', () => {
      const q = input.value.trim().toLowerCase();
      const navLinks = document.querySelectorAll('.docs-nav-link');
      const sections = document.querySelectorAll('.doc-section');

      if (!q) {
        navLinks.forEach((a) => (a.parentElement.style.display = ''));
        sections.forEach((sec) => (sec.style.display = ''));
        return;
      }

      const matchingIds = new Set();
      sections.forEach((sec) => {
        const text = sec.innerText.toLowerCase();
        if (text.includes(q)) {
          matchingIds.add(sec.id);
          sec.style.display = '';
        } else {
          sec.style.display = 'none';
        }
      });

      navLinks.forEach((a) => {
        const href = a.getAttribute('href');
        if (href && href.startsWith('#')) {
          const id = href.slice(1);
          if (matchingIds.has(id)) {
            a.parentElement.style.display = '';
          } else {
            a.parentElement.style.display = 'none';
          }
        }
      });
    });

    // Keyboard shortcut / and Ctrl+K
    window.addEventListener('keydown', (e) => {
      if ((e.key === '/' || (e.ctrlKey && e.key === 'k')) && document.activeElement !== input) {
        e.preventDefault();
        input.focus();
        input.select();
      } else if (e.key === 'Escape' && document.activeElement === input) {
        input.blur();
      }
    });
  }

  // 4. ScrollSpy for Sidebar & TOC
  function initScrollSpy() {
    const sections = Array.from(document.querySelectorAll('.doc-section'));
    const navLinks = document.querySelectorAll('.docs-nav-link');
    const tocLinks = document.querySelectorAll('.docs-toc-link');

    if (!('IntersectionObserver' in window)) return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const id = entry.target.id;
            navLinks.forEach((link) => {
              if (link.getAttribute('href') === `#${id}`) {
                link.classList.add('active');
              } else {
                link.classList.remove('active');
              }
            });
            tocLinks.forEach((link) => {
              if (link.getAttribute('href') === `#${id}`) {
                link.classList.add('active');
              } else {
                link.classList.remove('active');
              }
            });
          }
        });
      },
      {
        rootMargin: '-20% 0px -70% 0px',
        threshold: 0,
      }
    );

    sections.forEach((sec) => observer.observe(sec));
  }

  // 5. Lightweight Syntax Highlighting
  function highlightCode() {
    const keywords = /\b(SELECT|FROM|WHERE|INSERT|INTO|VALUES|CREATE|TABLE|INDEX|PRIMARY|KEY|USING|HNSW|UPDATE|SET|DELETE|ORDER|BY|ASC|DESC|LIMIT|OFFSET|JOIN|ON|GROUP|HAVING|EXPLAIN|BEGIN|COMMIT|ROLLBACK|DECLARE|FUNCTION|RETURN|RETURNS|INT|TEXT|DOUBLE|VECTOR|BOOLEAN|BLOB|JSON|UUID|DATETIME|DECIMAL|async|await|final|class|import|package|void|for|in|var|const|new|return|function|def|None|True|False|package|func|struct|mut|pub)\b/g;
    const strings = /('(?:\\'|[^'\r\n])*'|"(?:\\"|[^"\r\n])*")/g;
    const comments = /(\/\/[^\r\n]*|--[^\r\n]*|#[^\r\n]*)/g;
    const numbers = /\b([0-9]+(?:\.[0-9]+)?)\b/g;

    document.querySelectorAll('.code-block code').forEach((el) => {
      if (el.dataset.highlighted) return;
      el.dataset.highlighted = 'true';
      let html = el.innerHTML;
      // Protect HTML entities
      html = html
        .replace(strings, '<span class="hl-str">$1</span>')
        .replace(comments, '<span class="hl-com">$1</span>')
        .replace(keywords, '<span class="hl-kw">$1</span>')
        .replace(numbers, '<span class="hl-num">$1</span>');
      el.innerHTML = html;
    });
  }

  document.addEventListener('DOMContentLoaded', () => {
    initCopyButtons();
    initLanguageTabs();
    initSearch();
    initScrollSpy();
    highlightCode();
  });
})();
