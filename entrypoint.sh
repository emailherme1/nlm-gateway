#!/bin/bash
set -e

export DISPLAY=:99
export PLAYWRIGHT_BROWSERS_PATH=/data/ms-playwright

echo "1. Ensuring persistent directories, symlinks & cleaning up chromium locks..."
mkdir -p /data/chrome_profile
mkdir -p /data/browser_state
mkdir -p /data/ms-playwright
mkdir -p /root/.local/share/notebooklm-mcp
mkdir -p /root/.cache

# Kill any standalone chromium/chrome process holding locks for interactive login
pkill -9 chromium || true
pkill -9 chrome || true
rm -rf /data/chrome_profile/Singleton* 2>/dev/null || true

ln -sf /data/chrome_profile /root/.local/share/notebooklm-mcp/chrome_profile
ln -sf /data/browser_state /root/.local/share/notebooklm-mcp/browser_state
ln -sf /data/ms-playwright /root/.cache/ms-playwright

echo "2. Starting desktop GUI daemons (Xvfb, Fluxbox, x11vnc, websockify/noVNC)..."
Xvfb :99 -screen 0 1280x1024x24 &
sleep 1
fluxbox &
x11vnc -forever -shared -rfbport 5900 -display :99 -nopw &
/usr/share/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 8080 &

echo "3. Exporting storageState from persistent profile if state.json is missing..."
node -e '
(async () => {
  const fs = require("fs");
  const statePath = "/data/browser_state/state.json";
  let needRefresh = !fs.existsSync(statePath);
  if (!needRefresh) {
    try {
      const stats = fs.statSync(statePath);
      const fileAgeSeconds = (Date.now() - stats.mtimeMs) / 1000;
      if (fileAgeSeconds > 20 * 3600) { // refresh if older than 20h
        console.log("⚠️ state.json is old, refreshing from profile...");
        needRefresh = true;
      }
    } catch { needRefresh = true; }
  }
  if (needRefresh) {
    try {
      const { chromium } = require("patchright");
      const context = await chromium.launchPersistentContext("/data/chrome_profile", {
        executablePath: "/usr/bin/chromium",
        headless: true,
        args: [
          "--no-sandbox",
          "--disable-dev-shm-usage",
          "--disable-gpu",
          "--renderer-process-limit=1",
          "--disable-smooth-scrolling",
          "--disable-component-update",
          "--disable-features=Translate,OptimizationHints,MediaRouter",
          "--js-flags=--max-old-space-size=256"
        ]
      });
      const page = await context.newPage();
      await page.goto("https://notebook.google.com/", { waitUntil: "domcontentloaded", timeout: 30000 });
      await context.storageState({ path: statePath });
      await context.close();
      console.log("✅ Dumped state.json from persistent profile!");
    } catch (e) {
      console.error("❌ Could not dump state.json:", e.message);
    }
  }
})();
'

echo "4. Starting NotebookLM MCP HTTP Server on port 3000..."
node dist/index.js --transport http --port 3000 --host 0.0.0.0 &
sleep 1

echo "MCP Server Ready! (headless-only, no desktop daemons, no Chrome profile locks)"
exec tail -f /dev/null
