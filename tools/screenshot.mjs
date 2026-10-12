// Usage: node tools/screenshot.mjs <url> <out.png> [width=375] [maxHeight=6000] [clickSelector]
// Env: Y=<start y> crops from that offset, EVAL=<js expression> prints a value. Needs the Playwright Chromium cache.
import { spawn } from "node:child_process";
import { writeFileSync } from "node:fs";

const [, , url, out, width = "375", maxH = "6000", clickSel = ""] = process.argv;
const chrome = "C:/Users/ASADUZZAMAN/AppData/Local/ms-playwright/chromium-1243/chrome-win64/chrome.exe";
const port = 9333 + Math.floor(Math.random() * 500);
const proc = spawn(chrome, [`--remote-debugging-port=${port}`, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--user-data-dir=" + process.env.TEMP + "/cdp-" + port, "about:blank"], { stdio: "ignore" });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let targets;
for (let i = 0; i < 40; i++) {
  try {
    targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
    if (targets.length) break;
  } catch {}
  await sleep(250);
}
const ws = new WebSocket(targets.find((t) => t.type === "page").webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0;
const pending = new Map();
ws.onmessage = (m) => {
  const msg = JSON.parse(m.data);
  if (msg.id && pending.has(msg.id)) pending.get(msg.id)(msg.result);
};
const send = (method, params = {}) =>
  new Promise((resolve) => {
    const i = ++id;
    pending.set(i, resolve);
    ws.send(JSON.stringify({ id: i, method, params }));
  });

const w = Number(width);
const mobile = w < 600;
await send("Emulation.setDeviceMetricsOverride", { width: w, height: 800, deviceScaleFactor: 1, mobile });
await send("Page.enable");
await send("Page.navigate", { url });
await sleep(9000);
if (clickSel) {
  await send("Runtime.evaluate", { expression: `document.querySelector(${JSON.stringify(clickSel)})?.click()` });
  await sleep(1500);
}
for (let y = 0; y < 9000; y += 500) { await send("Runtime.evaluate", { expression: `window.scrollTo(0, ${y})` }); await sleep(250); }
await send("Runtime.evaluate", { expression: "window.scrollTo(0, 0)" });
await sleep(800);
const metrics = await send("Runtime.evaluate", {
  expression: "JSON.stringify({sw: document.documentElement.scrollWidth, cw: document.documentElement.clientWidth, sh: document.documentElement.scrollHeight})",
});
console.log(metrics.result.value);
if (process.env.EVAL) { const r = await send("Runtime.evaluate", { expression: process.env.EVAL }); console.log(r.result.value); await sleep(1200); }
const { sh } = JSON.parse(metrics.result.value);
const height = Math.min(sh, Number(maxH));
const shot = await send("Page.captureScreenshot", { format: "png", captureBeyondViewport: true, clip: { x: 0, y: Number(process.env.Y ?? 0), width: w, height: Math.min(Number(maxH), sh - Number(process.env.Y ?? 0)), scale: 1 } });
writeFileSync(out, Buffer.from(shot.data, "base64"));
ws.close();
proc.kill();
process.exit(0);
