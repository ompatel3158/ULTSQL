import { chromium } from 'playwright';

async function verifyProduction() {
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 375, height: 667 },
    isMobile: true,
    hasTouch: true
  });
  const page = await context.newPage();

  const pages = [
    'https://ultsql.tech/',
    'https://ultsql.tech/benchmarks',
    'https://ultsql.tech/features',
    'https://ultsql.tech/docs'
  ];

  console.log('\n--- VERIFYING LIVE PRODUCTION (https://ultsql.tech) IN PHONE VIEW ---');

  for (const url of pages) {
    const res = await page.goto(url, { waitUntil: 'networkidle' });
    const sw = await page.evaluate(() => document.documentElement.scrollWidth);
    const cw = await page.evaluate(() => document.documentElement.clientWidth);
    const overflow = sw > cw;

    // Test toggle
    const toggle = page.locator('#mobileMenuToggle').first();
    await toggle.click();
    await page.waitForTimeout(300);
    const isOpen = await page.locator('#mobileNavDrawer').evaluate(el => el.classList.contains('open'));
    const drawerBox = await page.locator('#mobileNavDrawer').boundingBox();

    console.log(`[${url}] Status: ${res.status()} | Overflow: ${overflow ? 'FAIL' : 'PASS'} (sw: ${sw}, cw: ${cw}) | Drawer open: ${isOpen} (x: ${Math.round(drawerBox.x)}px, w: ${Math.round(drawerBox.width)}px)`);
  }

  await browser.close();
}

verifyProduction();
