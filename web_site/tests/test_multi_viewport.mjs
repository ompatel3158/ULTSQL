import { chromium } from 'playwright';

async function testViewports() {
  const browser = await chromium.launch();
  const viewports = [
    { name: 'iPhone SE (375x667)', width: 375, height: 667 },
    { name: 'Android Small (360x800)', width: 360, height: 800 },
    { name: 'iPhone 15 Pro (393x852)', width: 393, height: 852 },
    { name: 'Pixel 7 (412x915)', width: 412, height: 915 },
    { name: 'iPad Mini (768x1024)', width: 768, height: 1024 }
  ];

  const pages = ['index.html', 'benchmarks.html', 'features.html', 'docs.html'];

  let allPassed = true;

  for (const vp of viewports) {
    console.log(`\n--- Testing ${vp.name} ---`);
    const context = await browser.newContext({ viewport: { width: vp.width, height: vp.height }, isMobile: true, hasTouch: true });
    const page = await context.newPage();

    for (const p of pages) {
      await page.goto('http://127.0.0.1:8080/' + p, { waitUntil: 'networkidle' });
      const sw = await page.evaluate(() => document.documentElement.scrollWidth);
      const cw = await page.evaluate(() => document.documentElement.clientWidth);
      const overflow = sw > cw;
      
      // Test toggle
      const toggle = page.locator('#mobileMenuToggle').first();
      await toggle.click();
      await page.waitForTimeout(250);
      const isOpen = await page.locator('#mobileNavDrawer').evaluate(el => el.classList.contains('open'));
      const drawerBox = await page.locator('#mobileNavDrawer').boundingBox();
      
      // Test close
      const closeBtn = page.locator('#mobileMenuClose').first();
      await closeBtn.click();
      await page.waitForTimeout(250);
      const isClosed = await page.locator('#mobileNavDrawer').evaluate(el => !el.classList.contains('open'));

      const isDrawerInside = drawerBox && drawerBox.x >= 0 && (drawerBox.x + drawerBox.width) <= vp.width + 1;

      console.log(`  ${p.padEnd(16)}: overflow=${overflow ? 'FAIL' : 'PASS'} | drawerOpen=${isOpen} (${Math.round(drawerBox.x)}px, w:${Math.round(drawerBox.width)}px) | drawerClosed=${isClosed} | inside=${isDrawerInside}`);

      if (overflow || !isOpen || !isClosed || !isDrawerInside) {
        allPassed = false;
      }
    }
    await context.close();
  }

  await browser.close();
  console.log(`\nAll Viewport Tests: ${allPassed ? 'ALL PASSED' : 'SOME FAILED'}`);
}

testViewports();
