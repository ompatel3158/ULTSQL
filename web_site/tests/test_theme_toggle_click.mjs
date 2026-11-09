import { chromium } from 'playwright';

async function testThemeToggleClick() {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  await page.goto('http://127.0.0.1:8080/');
  await page.waitForTimeout(300);

  // 1. Initial state (Dark)
  const initialTheme = await page.evaluate(() => document.documentElement.getAttribute('data-theme') || 'dark');
  console.log(`Initial theme: ${initialTheme}`);

  // 2. Click theme toggle button to switch to Light
  const toggleBtn = page.locator('#themeToggle').first();
  await toggleBtn.click();
  await page.waitForTimeout(300);

  const themeAfterClick1 = await page.evaluate(() => document.documentElement.getAttribute('data-theme'));
  console.log(`Theme after 1st click: ${themeAfterClick1}`);
  if (themeAfterClick1 !== 'light') throw new Error(`Expected light, got ${themeAfterClick1}`);

  // 3. Click theme toggle button again to switch back to Dark
  await toggleBtn.click();
  await page.waitForTimeout(300);

  const themeAfterClick2 = await page.evaluate(() => document.documentElement.getAttribute('data-theme'));
  console.log(`Theme after 2nd click: ${themeAfterClick2}`);
  if (themeAfterClick2 !== 'dark') throw new Error(`Expected dark, got ${themeAfterClick2}`);

  await browser.close();
  console.log('Interactive Theme Toggle test passed 100%!');
}

testThemeToggleClick();
