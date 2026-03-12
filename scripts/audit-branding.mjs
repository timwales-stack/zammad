import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const { chromium } = require('C:/Users/timwa/AppData/Roaming/npm/node_modules/@playwright/test/node_modules/playwright');

const browser = await chromium.launch();
const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });

const screenshotDir = 'C:/Users/timwa/zammad/screenshots';

// 1. Login page (legacy)
console.log('1. Capturing legacy login page...');
const loginPage = await context.newPage();
await loginPage.goto('http://localhost:8090/#login', { waitUntil: 'networkidle' });
await loginPage.waitForTimeout(5000);
await loginPage.screenshot({ path: `${screenshotDir}/audit-01-legacy-login.png`, fullPage: true });

// 2. Desktop login page (Vue SPA)
console.log('2. Capturing desktop login page...');
const desktopLogin = await context.newPage();
await desktopLogin.goto('http://localhost:8090/desktop/login', { waitUntil: 'networkidle' });
await desktopLogin.waitForTimeout(5000);
await desktopLogin.screenshot({ path: `${screenshotDir}/audit-02-desktop-login.png`, fullPage: true });

// 3. Login as admin via desktop
console.log('3. Logging in as admin...');
try {
  await desktopLogin.fill('input[name="login"]', 'admin@blackravenit.com');
  await desktopLogin.fill('input[name="password"]', 'BlackRaven2024!');
  await desktopLogin.click('button[type="submit"]');
  await desktopLogin.waitForTimeout(8000);
  await desktopLogin.screenshot({ path: `${screenshotDir}/audit-03-admin-dashboard.png`, fullPage: true });
  // Sidebar close-up
  await desktopLogin.screenshot({ path: `${screenshotDir}/audit-04-admin-sidebar.png`, clip: { x: 0, y: 0, width: 80, height: 900 } });
} catch (e) {
  console.log('  Admin login error:', e.message);
  await desktopLogin.screenshot({ path: `${screenshotDir}/audit-03-admin-error.png`, fullPage: true });
}

// 4. Login as agent via legacy UI
console.log('4. Logging in as agent (legacy)...');
const agentCtx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
const agentPage = await agentCtx.newPage();
await agentPage.goto('http://localhost:8090/#login', { waitUntil: 'networkidle' });
await agentPage.waitForTimeout(4000);
try {
  await agentPage.fill('[name="username"]', 'tech@blackravenit.com');
  await agentPage.fill('[name="password"]', 'TechLead2024!');
  await agentPage.click('.btn--primary');
  await agentPage.waitForTimeout(8000);
  await agentPage.screenshot({ path: `${screenshotDir}/audit-05-agent-dashboard.png`, fullPage: true });
  await agentPage.screenshot({ path: `${screenshotDir}/audit-06-agent-sidebar.png`, clip: { x: 0, y: 0, width: 80, height: 900 } });
} catch (e) {
  console.log('  Agent login error:', e.message);
  await agentPage.screenshot({ path: `${screenshotDir}/audit-05-agent-error.png`, fullPage: true });
}

// 5. Login as customer via legacy UI
console.log('5. Logging in as customer (legacy)...');
const custCtx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
const custPage = await custCtx.newPage();
await custPage.goto('http://localhost:8090/#login', { waitUntil: 'networkidle' });
await custPage.waitForTimeout(4000);
try {
  await custPage.fill('[name="username"]', 'client@testcorp.com');
  await custPage.fill('[name="password"]', 'Client2024!');
  await custPage.click('.btn--primary');
  await custPage.waitForTimeout(8000);
  await custPage.screenshot({ path: `${screenshotDir}/audit-07-customer-portal.png`, fullPage: true });
  await custPage.screenshot({ path: `${screenshotDir}/audit-08-customer-sidebar.png`, clip: { x: 0, y: 0, width: 80, height: 900 } });
} catch (e) {
  console.log('  Customer login error:', e.message);
  await custPage.screenshot({ path: `${screenshotDir}/audit-07-customer-error.png`, fullPage: true });
}

// 6. Text audit - search for any "zammad" text
console.log('6. Scanning for Zammad text...');
const scanPage = await context.newPage();
await scanPage.goto('http://localhost:8090', { waitUntil: 'networkidle' });
await scanPage.waitForTimeout(3000);
const pageTitle = await scanPage.title();
console.log(`  Page title: "${pageTitle}"`);

const htmlContent = await scanPage.evaluate(() => document.documentElement.outerHTML);
const zammadCount = (htmlContent.match(/zammad/gi) || []).length;
console.log(`  "Zammad" occurrences in HTML: ${zammadCount}`);

await browser.close();
console.log('\nAudit complete! Screenshots in:', screenshotDir);
