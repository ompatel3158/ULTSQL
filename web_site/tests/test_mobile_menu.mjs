import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 375, height: 667 } });
  const errors = [];
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  page.on('pageerror', err => errors.push(err.message + ' at ' + err.stack));

  for (const p of ['index.html', 'benchmarks.html', 'features.html', 'docs.html']) {
    errors.length = 0;
    await page.goto('http://127.0.0.1:8080/' + p, { waitUntil: 'domcontentloaded' });
    console.log(`\n--- PAGE: ${p} ---`);
    console.log('Errors:', errors);
    const btn = page.locator('#mobileMenuToggle');
    const btnVisible = await btn.isVisible().catch(() => false);
    console.log('Mobile menu button visible:', btnVisible);
    if (btnVisible) {
      await btn.click();
      await page.waitForTimeout(200);
      const isOpen = await page.locator('#mobileNavDrawer').evaluate(el => el.classList.contains('open')).catch(() => false);
      console.log('Drawer has "open" class:', isOpen);
      const drawerVisible = await page.locator('#mobileNavDrawer').isVisible().catch(() => false);
      console.log('Drawer is visible on screen:', drawerVisible);
    }
  }
  await browser.close();
}

test();
