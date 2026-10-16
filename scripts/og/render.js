// Renders the social card and every app icon from the sources in scripts/og/.
//   node scripts/og/render.js   (needs playwright; e.g. NODE_PATH=$(npm root -g))
//
// - example/web/og.png                  social card (scripts/og/og.html), 1200x630 @2x
// - example/web/favicon.svg|png, icons  web favicon + PWA icons
// - example/ios/.../AppIcon.appiconset  iOS icons (full-bleed, no alpha)
// - example/macos/.../AppIcon.appiconset macOS icons
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const { iconSvg } = require('./icon');

const root = path.resolve(__dirname, '..', '..');
const web = path.join(root, 'example/web');
const ios = path.join(root, 'example/ios/Runner/Assets.xcassets/AppIcon.appiconset');
const mac = path.join(root, 'example/macos/Runner/Assets.xcassets/AppIcon.appiconset');

async function renderSvg(browser, svg, size, file, { opaque = false } = {}) {
  const page = await browser.newPage({ viewport: { width: size, height: size } });
  const bg = opaque ? '#0A0A0C' : 'transparent';
  await page.setContent(
    `<html><body style="margin:0;background:${bg}">` +
      svg.replace('<svg ', `<svg width="${size}" height="${size}" `) +
      '</body></html>',
  );
  await page.screenshot({ path: file, omitBackground: !opaque });
  await page.close();
}

(async () => {
  const browser = await chromium.launch();
  // Written first: the social card uses it as its logo.
  fs.writeFileSync(path.join(web, 'favicon.svg'), iconSvg('rounded'));

  // Social card.
  const card = await browser.newPage({ viewport: { width: 1200, height: 630 }, deviceScaleFactor: 2 });
  await card.goto('file://' + path.join(__dirname, 'og.html'));
  await card.evaluate(() => document.fonts.ready);
  await card.screenshot({ path: path.join(web, 'og.png') });
  await card.close();

  // Web.
  await renderSvg(browser, iconSvg('rounded'), 32, path.join(web, 'favicon.png'));
  await renderSvg(browser, iconSvg('rounded'), 180, path.join(web, 'icons/apple-touch-icon.png'));
  for (const s of [192, 512]) {
    await renderSvg(browser, iconSvg('rounded'), s, path.join(web, `icons/Icon-${s}.png`));
    await renderSvg(browser, iconSvg('full'), s, path.join(web, `icons/Icon-maskable-${s}.png`), { opaque: true });
  }

  // iOS: sizes come from the file names (Icon-App-<pt>x<pt>@<scale>x.png).
  for (const f of fs.readdirSync(ios).filter((f) => f.endsWith('.png'))) {
    const [, pt, scale] = f.match(/Icon-App-([\d.]+)x[\d.]+@(\d)x\.png/);
    await renderSvg(browser, iconSvg('full'), Math.round(pt * scale), path.join(ios, f), { opaque: true });
  }

  // macOS: app_icon_<px>.png.
  for (const f of fs.readdirSync(mac).filter((f) => f.endsWith('.png'))) {
    const px = Number(f.match(/app_icon_(\d+)\.png/)[1]);
    await renderSvg(browser, iconSvg('mac'), px, path.join(mac, f));
  }

  await browser.close();
})();
