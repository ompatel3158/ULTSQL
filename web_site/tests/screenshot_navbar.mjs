import { chromium } from 'playwright';

async function captureNavbars() {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  await page.goto('http://127.0.0.1:8080/');
  await page.waitForTimeout(500);

  // Dark mode navbar
  await page.locator('.navbar-pill').screenshot({ path: 'tests/screenshots/navbar_dark.png' });

  // Light mode navbar
  await page.evaluate(() => {
    document.documentElement.setAttribute('data-theme', 'light');
    localStorage.setItem('ultsql_theme', 'light');
  });
  await page.waitForTimeout(500);
  await page.locator('.navbar-pill').screenshot({ path: 'tests/screenshots/navbar_light_current.png' });

  // Also check mobile drawer in light mode
  const mobilePage = await browser.newPage({ viewport: { width: 375, height: 667 }, isMobile: true });
  await mobilePage.goto('http://127.0.0.1:8080/');
  await mobilePage.evaluate(() => {
    document.documentElement.setAttribute('data-theme', 'light');
  });
  await mobilePage.locator('#mobileMenuToggle').first().click();
  await mobilePage.waitForTimeout(300);
  await mobilePage.locator('.mobile-nav-header').screenshot({ path: 'tests/screenshots/mobile_header_light_current.png' });

  await browser.close();
  console.log('Screenshots captured successfully.');
}

captureNavbars();
