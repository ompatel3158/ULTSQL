import { chromium } from 'playwright';

async function findOverflow() {
  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width: 375, height: 667 } });
  const page = await context.newPage();

  for (const pageName of ['benchmarks.html', 'features.html', 'docs.html']) {
    await page.goto('http://127.0.0.1:8080/' + pageName, { waitUntil: 'networkidle' });
    
    const offenders = await page.evaluate(() => {
      const results = [];
      const docWidth = document.documentElement.clientWidth;
      document.querySelectorAll('body *').forEach(el => {
        // Ignore mobile drawer since it is translateX(100%) when closed
        if (el.id === 'mobileNavDrawer' || el.closest('#mobileNavDrawer')) return;
        if (el.classList.contains('bklit-dot-grid') || el.classList.contains('bklit-dot-grid-base')) return;

        const rect = el.getBoundingClientRect();
        if (rect.right > docWidth + 3 || rect.width > docWidth + 3) {
          results.push({
            tag: el.tagName,
            id: el.id,
            className: el.className,
            width: Math.round(rect.width),
            right: Math.round(rect.right),
            text: el.innerText ? el.innerText.substring(0, 40).replace(/\n/g, ' ') : ''
          });
        }
      });
      return results;
    });

    console.log(`\n=== OFFENDERS FOR ${pageName} (clientWidth: 375) ===`);
    offenders.slice(0, 15).forEach(o => {
      console.log(`- <${o.tag} id="${o.id}" class="${o.className}"> width: ${o.width}px, right: ${o.right}px | "${o.text}"`);
    });
  }

  await browser.close();
}

findOverflow();
