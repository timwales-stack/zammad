import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const { chromium } = require('C:/Users/timwa/AppData/Roaming/npm/node_modules/@playwright/test/node_modules/playwright');

const browser = await chromium.launch();
const screenshotDir = 'C:/Users/timwa/zammad/screenshots';

// Desktop UI - admin login, zoom sidebar icon
console.log('1. Desktop UI sidebar icon...');
const ctx1 = await browser.newContext({ viewport: { width: 1280, height: 900 } });
const p1 = await ctx1.newPage();
await p1.goto('http://localhost:8090/desktop/login', { waitUntil: 'networkidle' });
await p1.waitForTimeout(3000);
await p1.fill('input[name="login"]', 'admin@blackravenit.com');
await p1.fill('input[name="password"]', 'BlackRaven2024!');
await p1.click('button[type="submit"]');
await p1.waitForTimeout(8000);
// Close beta UI modal if present
try { await p1.click('text=Confirm', { timeout: 3000 }); } catch(e) {}
await p1.waitForTimeout(2000);
// Zoom: capture top-right of sidebar where icon is
await p1.screenshot({ path: `${screenshotDir}/zoom-01-desktop-sidebar-icon.png`, clip: { x: 0, y: 0, width: 250, height: 60 } });
// Full sidebar
await p1.screenshot({ path: `${screenshotDir}/zoom-02-desktop-full-sidebar.png`, clip: { x: 0, y: 0, width: 250, height: 900 } });
console.log('  Desktop captured.');

// Legacy UI - agent login, zoom sidebar icon
console.log('2. Legacy UI sidebar icon...');
const ctx2 = await browser.newContext({ viewport: { width: 1280, height: 900 } });
const p2 = await ctx2.newPage();
await p2.goto('http://localhost:8090/#login', { waitUntil: 'networkidle' });
await p2.waitForTimeout(4000);
await p2.fill('[name="username"]', 'tech@blackravenit.com');
await p2.fill('[name="password"]', 'TechLead2024!');
await p2.click('.btn--primary');
await p2.waitForTimeout(8000);
// Zoom: top of sidebar where logo is
await p2.screenshot({ path: `${screenshotDir}/zoom-03-legacy-sidebar-icon.png`, clip: { x: 0, y: 0, width: 250, height: 60 } });
await p2.screenshot({ path: `${screenshotDir}/zoom-04-legacy-full-sidebar.png`, clip: { x: 0, y: 0, width: 250, height: 900 } });
console.log('  Legacy captured.');

// Login pages
console.log('3. Login pages...');
const ctx3 = await browser.newContext({ viewport: { width: 1280, height: 900 } });
const p3 = await ctx3.newPage();
await p3.goto('http://localhost:8090/#login', { waitUntil: 'networkidle' });
await p3.waitForTimeout(5000);
await p3.screenshot({ path: `${screenshotDir}/zoom-05-legacy-login.png`, fullPage: true });

const ctx4 = await browser.newContext({ viewport: { width: 1280, height: 900 } });
const p4 = await ctx4.newPage();
await p4.goto('http://localhost:8090/desktop/login', { waitUntil: 'networkidle' });
await p4.waitForTimeout(5000);
await p4.screenshot({ path: `${screenshotDir}/zoom-06-desktop-login.png`, fullPage: true });

await browser.close();
console.log('Done!');
