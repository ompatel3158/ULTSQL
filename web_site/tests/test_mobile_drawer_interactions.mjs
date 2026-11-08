import { chromium } from 'playwright';

async function testMobileInteractions() {
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 375, height: 667 },
    isMobile: true,
    hasTouch: true
  });
  const page = await context.newPage();

  const pages = ['index.html', 'benchmarks.html', 'features.html', 'docs.html'];

  console.log('\n--- VERIFYING MOBILE DRAWER BACKDROP & DISMISS INTERACTIONS ---');

  for (const p of pages) {
    await page.goto('http://127.0.0.1:8080/' + p, { waitUntil: 'networkidle' });

    // 1. Open drawer
    await page.locator('#mobileMenuToggle').first().click();
    await page.waitForTimeout(200);

    const isDrawerOpen = await page.locator('#mobileNavDrawer').evaluate(el => el.classList.contains('open'));
    const isBackdropOpen = await page.locator('#mobileNavBackdrop').evaluate(el => el.classList.contains('open'));
    console.log(`[${p}] Drawer open: ${isDrawerOpen}, Backdrop open: ${isBackdropOpen}`);
    if (!isDrawerOpen || !isBackdropOpen) throw new Error(`${p}: Drawer or backdrop failed to open`);

    // 2. Dismiss via backdrop tap
    await page.locator('#mobileNavBackdrop').click({ position: { x: 20, y: 300 } });
    await page.waitForTimeout(200);

    const isDrawerClosedAfterBackdrop = await page.locator('#mobileNavDrawer').evaluate(el => !el.classList.contains('open'));
    console.log(`[${p}] Backdrop click closed drawer: ${isDrawerClosedAfterBackdrop}`);
    if (!isDrawerClosedAfterBackdrop) throw new Error(`${p}: Failed to close via backdrop`);

    // 3. Open drawer again, test dismiss via Escape key
    await page.locator('#mobileMenuToggle').first().click();
    await page.waitForTimeout(200);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(200);

    const isDrawerClosedAfterEscape = await page.locator('#mobileNavDrawer').evaluate(el => !el.classList.contains('open'));
    console.log(`[${p}] Escape key closed drawer: ${isDrawerClosedAfterEscape}`);
    if (!isDrawerClosedAfterEscape) throw new Error(`${p}: Failed to close via Escape key`);

    // 4. Verify laser top loader element exists
    const hasTopLoader = await page.locator('#cadTopLoader').count() > 0;
    console.log(`[${p}] Top Laser Loader in DOM: ${hasTopLoader}`);
    if (!hasTopLoader) throw new Error(`${p}: Top loader missing`);
  }

  await browser.close();
  console.log('\nALL MOBILE INTERACTION TESTS PASSED!\n');
}

testMobileInteractions();
