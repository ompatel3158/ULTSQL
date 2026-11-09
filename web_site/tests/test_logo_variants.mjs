import { chromium } from 'playwright';
import fs from 'fs';

async function testLogoVariants() {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  await page.goto('http://127.0.0.1:8080/');

  // Variant 1: Pure transparent glyph (no background rect)
  // Let's create icon_transparent.svg
  const transparentSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="-14 -14 136 136" width="100%" height="100%">
  <defs>
    <mask id="center-hole">
      <rect x="-50" y="-50" width="236" height="236" fill="white" />
      <circle cx="54" cy="54" r="4.8" fill="black" />
    </mask>
  </defs>
  <g mask="url(#center-hole)">
    <g transform="translate(54, 54) scale(2.4) translate(-54, -54)" fill="#FFFFFF">
      <path d="M 54,35.5 A 4.2,10.1 0 1,1 54,55.7 A 4.2,10.1 0 1,1 54,35.5 Z" />
      <path d="M 54,35.5 A 4.2,10.1 0 1,1 54,55.7 A 4.2,10.1 0 1,1 54,35.5 Z" transform="rotate(120, 54, 54)" />
      <path d="M 54,35.5 A 4.2,10.1 0 1,1 54,55.7 A 4.2,10.1 0 1,1 54,35.5 Z" transform="rotate(240, 54, 54)" />
    </g>
  </g>
</svg>`;
  fs.writeFileSync('icon_transparent.svg', transparentSvg);

  // Test 1: Transparent in dark mode
  await page.evaluate(() => {
    document.querySelectorAll('.nav-brand img').forEach(img => img.src = 'icon_transparent.svg');
  });
  await page.waitForTimeout(200);
  await page.locator('.navbar-pill').screenshot({ path: 'tests/screenshots/test_transparent_dark.png' });

  // Test 1b: Transparent in light mode with brightness(0)
  await page.evaluate(() => {
    document.documentElement.setAttribute('data-theme', 'light');
    const style = document.createElement('style');
    style.id = 'temp-test-style';
    style.innerHTML = '[data-theme="light"] .nav-brand img { filter: brightness(0) !important; }';
    document.head.appendChild(style);
  });
  await page.waitForTimeout(200);
  await page.locator('.navbar-pill').screenshot({ path: 'tests/screenshots/test_transparent_light.png' });

  // Variant 2: Subtle adaptive rounded box
  // In dark mode: dark background + subtle border
  // In light mode: light background + subtle border + black icon
  await page.evaluate(() => {
    const style = document.getElementById('temp-test-style');
    style.innerHTML = `
      .nav-logo-icon {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 28px;
        height: 28px;
        border-radius: 6px;
        background: #18181b;
        border: 1px solid rgba(255, 255, 255, 0.15);
      }
      .nav-logo-icon img {
        width: 18px !important;
        height: 18px !important;
        filter: none !important;
      }
      [data-theme="light"] .nav-logo-icon {
        background: #f4f4f5;
        border: 1px solid rgba(0, 0, 0, 0.12);
      }
      [data-theme="light"] .nav-logo-icon img {
        filter: brightness(0) !important;
      }
    `;
  });
  await page.waitForTimeout(200);
  await page.locator('.navbar-pill').screenshot({ path: 'tests/screenshots/test_boxed_light.png' });

  // In dark mode
  await page.evaluate(() => {
    document.documentElement.setAttribute('data-theme', 'dark');
  });
  await page.waitForTimeout(200);
  await page.locator('.navbar-pill').screenshot({ path: 'tests/screenshots/test_boxed_dark.png' });

  await browser.close();
  console.log('Test screenshots captured.');
}

testLogoVariants();
