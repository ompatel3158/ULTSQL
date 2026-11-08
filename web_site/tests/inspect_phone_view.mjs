import { chromium } from 'playwright';

async function inspectPhone() {
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 375, height: 667 },
    isMobile: true,
    hasTouch: true,
  });
  const page = await context.newPage();

  const pages = [
    { name: 'home', url: 'http://127.0.0.1:8080/index.html' },
    { name: 'benchmarks', url: 'http://127.0.0.1:8080/benchmarks.html' },
    { name: 'features', url: 'http://127.0.0.1:8080/features.html' },
    { name: 'docs', url: 'http://127.0.0.1:8080/docs.html' },
    { name: 'privacy', url: 'http://127.0.0.1:8080/privacy.html' },
    { name: 'license', url: 'http://127.0.0.1:8080/license.html' },
    { name: 'delete-account', url: 'http://127.0.0.1:8080/delete-account.html' }
  ];

  for (const p of pages) {
    await page.goto(p.url, { waitUntil: 'networkidle' });
    
    const scrollWidth = await page.evaluate(() => document.documentElement.scrollWidth);
    const clientWidth = await page.evaluate(() => document.documentElement.clientWidth);
    console.log(`\n=== Page: ${p.name} ===`);
    console.log(`scrollWidth: ${scrollWidth}, clientWidth: ${clientWidth}, hasHorizontalOverflow: ${scrollWidth > clientWidth}`);

    // Inspect mobile menu toggle button position and bounding rect
    const toggleBtn = page.locator('#mobileMenuToggle');
    const toggleCount = await toggleBtn.count();
    let toggleVisible = false;
    let toggleBox = null;
    if (toggleCount > 0) {
      toggleVisible = await toggleBtn.first().isVisible();
      toggleBox = await toggleBtn.first().boundingBox();
    }
    console.log(`Mobile menu button visible: ${toggleVisible}`, toggleBox);

    // Test clicking mobile menu toggle
    if (toggleVisible) {
      await toggleBtn.first().click();
      await page.waitForTimeout(350);
      const isDrawerOpen = await page.locator('#mobileNavDrawer').evaluate(el => el.classList.contains('open'));
      const drawerBox = await page.locator('#mobileNavDrawer').boundingBox();
      console.log(`Drawer open: ${isDrawerOpen}`, drawerBox);
    }
  }

  await browser.close();
}

inspectPhone();
