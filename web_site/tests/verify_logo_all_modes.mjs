import { chromium } from 'playwright';

async function verifyAll() {
  const browser = await chromium.launch();
  
  // Desktop
  const desktopPage = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  await desktopPage.goto('http://127.0.0.1:8080/');
  await desktopPage.waitForTimeout(300);

  // Desktop Dark
  await desktopPage.locator('.navbar-pill').screenshot({ path: 'tests/screenshots/verified_navbar_dark.png' });
  await desktopPage.locator('.site-footer').screenshot({ path: 'tests/screenshots/verified_footer_dark.png' });

  // Desktop Light
  await desktopPage.evaluate(() => {
    document.documentElement.setAttribute('data-theme', 'light');
    localStorage.setItem('ultsql_theme', 'light');
  });
  await desktopPage.waitForTimeout(300);
  await desktopPage.locator('.navbar-pill').screenshot({ path: 'tests/screenshots/verified_navbar_light.png' });
  await desktopPage.locator('.site-footer').screenshot({ path: 'tests/screenshots/verified_footer_light.png' });

  // Mobile
  const mobilePage = await browser.newPage({ viewport: { width: 375, height: 667 }, isMobile: true });
  await mobilePage.goto('http://127.0.0.1:8080/');
  await mobilePage.waitForTimeout(300);

  // Mobile Dark
  await mobilePage.locator('.navbar-pill').screenshot({ path: 'tests/screenshots/verified_mobile_navbar_dark.png' });
  await mobilePage.locator('#mobileMenuToggle').first().click();
  await mobilePage.waitForTimeout(300);
  await mobilePage.locator('.mobile-nav-header').screenshot({ path: 'tests/screenshots/verified_mobile_drawer_dark.png' });

  // Mobile Light
  await mobilePage.evaluate(() => {
    document.documentElement.setAttribute('data-theme', 'light');
    localStorage.setItem('ultsql_theme', 'light');
  });
  await mobilePage.waitForTimeout(300);
  await mobilePage.locator('.mobile-nav-header').screenshot({ path: 'tests/screenshots/verified_mobile_drawer_light.png' });
  await mobilePage.locator('#mobileMenuClose').first().click();
  await mobilePage.waitForTimeout(300);
  await mobilePage.locator('.navbar-pill').screenshot({ path: 'tests/screenshots/verified_mobile_navbar_light.png' });

  await browser.close();
  console.log('All verification screenshots captured.');
}

verifyAll();
