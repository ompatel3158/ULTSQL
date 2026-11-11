import { chromium } from 'playwright';

async function verifyProdLightLogo() {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  
  await page.goto('https://ultsql.tech/', { waitUntil: 'networkidle' });
  await page.evaluate(() => {
    document.documentElement.setAttribute('data-theme', 'light');
    localStorage.setItem('ultsql_theme', 'light');
  });
  await page.waitForTimeout(500);

  await page.locator('.navbar-pill').screenshot({ path: 'tests/screenshots/prod_navbar_light.png' });
  await page.locator('.site-footer').screenshot({ path: 'tests/screenshots/prod_footer_light.png' });

  await browser.close();
  console.log('Production light mode screenshots taken.');
}

verifyProdLightLogo();
