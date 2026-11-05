// Records docs/demo.gif from the real web build, so the GIF shows the actual
// sync: in demo mode "Anis" changes the list every few seconds.
//
//   flutter build web --release --base-href /fridge-note/ --dart-define=DEMO=true
//   npm install --no-save playwright-core   (once, plus `npx playwright install chromium`)
//   node tool/record_demo.cjs               (writes PNG frames to build/demo_frames)
//   python tool/make_demo_gif.py            (needs Pillow, joins them into docs/demo.gif)
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright-core');
const { serve } = require('./web_server.cjs');

const root = path.resolve(__dirname, '..');
const framesDir = path.join(root, 'build', 'demo_frames');

// Positions on a 390 x 844 phone screen.
const navTab = (i) => ({ x: 20 + (350 * (i + 0.5)) / 5, y: 796 });
const secondCheckCircle = { x: 342, y: 318 };

(async () => {
  fs.rmSync(framesDir, { recursive: true, force: true });
  fs.mkdirSync(framesDir, { recursive: true });

  const server = await serve(path.join(root, 'build', 'web'), 8099);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });

  const frames = [];
  const start = Date.now();
  async function capture(ms) {
    const until = Date.now() + ms;
    while (Date.now() < until) {
      const file = path.join(framesDir, `${String(frames.length).padStart(4, '0')}.png`);
      await page.screenshot({ path: file });
      frames.push({ file: path.basename(file), t: Date.now() - start });
      await page.waitForTimeout(120);
    }
  }

  await page.goto('http://localhost:8099/fridge-note/list');
  await page.waitForTimeout(6000); // app start

  await capture(9000); // Anis checks things off on "his phone"
  await page.mouse.click(secondCheckCircle.x, secondCheckCircle.y); // our own check-off
  await capture(4000);
  await page.mouse.click(navTab(2).x, navTab(2).y); // the shopping trip tab
  await capture(9000);

  fs.writeFileSync(path.join(framesDir, 'frames.json'), JSON.stringify(frames, null, 1));
  console.log(`${frames.length} frames in ${framesDir}`);
  await browser.close();
  server.close();
})();
