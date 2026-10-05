// run_page.js -- serve a directory over HTTP, open a page in headless Chrome,
// stream console output, wait for a marker text, optionally take screenshots.
// usage: CHROME=/path/to/chrome node run_page.js <dir> <page> [--wait TEXT] [--timeout SEC]
//        [--shot out.png] [--shot-every SEC] [--script file.js]
const http = require('http');
const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer-core');

const args = process.argv.slice(2);
const dir = path.resolve(args[0]);
const page = args[1];
function opt(name, def) {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : def;
}
const waitText = opt('--wait', null);
const timeout = parseFloat(opt('--timeout', '60')) * 1000;
const shot = opt('--shot', null);
const shotEvery = parseFloat(opt('--shot-every', '0'));
const script = opt('--script', null);
const failText = opt('--fail', 'green thread aborted');
const settle = parseFloat(opt('--settle', '0')) * 1000;
const actionsFile = opt('--actions', null);

const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.wasm': 'application/wasm', '.json': 'application/json', '.css': 'text/css',
  '.jar': 'application/java-archive', '.class': 'application/java-vm', '.png': 'image/png',
  '.gif': 'image/gif', '.jpg': 'image/jpeg', '.data': 'application/octet-stream' };

const server = http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p.endsWith('/')) p += 'index.html';
  const f = path.join(dir, p);
  if (!f.startsWith(dir) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) {
    res.writeHead(404); res.end('not found'); return;
  }
  res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream',
    'Cache-Control': 'no-store' });
  fs.createReadStream(f).pipe(res);
});

server.listen(0, '127.0.0.1', async () => {
  const port = server.address().port;
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME || 'chrome-headless-shell',
    args: ['--no-sandbox', '--disable-gpu', '--js-flags=--stack-size=984', ...(process.env.CHROME_ARGS ? process.env.CHROME_ARGS.split(' ') : [])],
    headless: 'shell',
    protocolTimeout: 0,
  });
  const pg = await browser.newPage();
  await pg.setViewport({ width: 1024, height: 768 });
  let done = false, ok = false, log = '', markerSeen = false;
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const waitFor = async (text, ms) => {
    const end = Date.now() + ms;
    while (Date.now() < end) { if (log.includes(text)) return true; await sleep(100); }
    return false;
  };
  const runActions = async () => {
    const steps = JSON.parse(fs.readFileSync(actionsFile, 'utf8'));
    for (const st of steps) {
      if (st.sleep) await sleep(st.sleep);
      if (st.click) { await pg.mouse.click(st.click[0], st.click[1]); }
      if (st.move) { await pg.mouse.move(st.move[0], st.move[1], { steps: st.steps || 5 }); }
      if (st.down) { await pg.mouse.down(); }
      if (st.up) { await pg.mouse.up(); }
      if (st.type) { await pg.keyboard.type(st.type, { delay: st.delay || 30 }); }
      if (st.press) { await pg.keyboard.press(st.press); }
      if (st.keydown) { await pg.keyboard.down(st.keydown); }
      if (st.keyup) { await pg.keyboard.up(st.keyup); }
      if (st.shot) { await pg.screenshot({ path: st.shot }); }
      if (st.wait) {
        if (!(await waitFor(st.wait, st.timeout || 30000))) { finish(false, 'missing ' + st.wait); return; }
      }
    }
    await sleep(settle);
    finish(true, 'actions completed');
  };
  const finish = async (success, why) => {
    if (done) return;
    done = true; ok = success;
    console.log(`\n=== ${success ? 'PASS' : 'FAIL'}: ${why}`);
    if (shot) { try { await pg.screenshot({ path: shot }); } catch (e) { console.log('screenshot failed', e.message); } }
    await browser.close();
    server.close();
    process.exit(success ? 0 : 1);
  };
  pg.on('console', (m) => {
    const t = m.text();
    log += t + '\n';
    console.log(t);
    if (waitText && log.includes(waitText) && !markerSeen) {
      markerSeen = true;
      if (actionsFile) runActions().catch((e) => finish(false, 'action error ' + e));
      else setTimeout(() => finish(true, 'found marker'), settle);
    }
    if (failText && t.includes(failText)) finish(false, 'failure marker');
  });
  pg.on('pageerror', (e) => { console.log('PAGEERROR ' + e.message); });
  if (shotEvery > 0 && shot) {
    let n = 0;
    setInterval(async () => {
      if (done) return;
      try { await pg.screenshot({ path: shot.replace(/\.png$/, `-${n++}.png`) }); } catch (e) {}
    }, shotEvery * 1000);
  }
  setTimeout(() => finish(!waitText, 'timeout'), timeout);
  await pg.goto(`http://127.0.0.1:${port}/${page}`);
  if (script) {
    const code = fs.readFileSync(script, 'utf8');
    try { await pg.evaluate(code); } catch (e) { console.log('script error', e.message); }
  }
});
