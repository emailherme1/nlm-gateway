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

echo "2. Extracting Netscape cookies from /data/chrome_profile for nlm CLI..."
node -e '
const { chromium } = require("patchright");
const fs = require("fs");

(async () => {
  try {
    const context = await chromium.launchPersistentContext("/data/chrome_profile", {
      executablePath: "/usr/bin/chromium",
      headless: true,
      args: ["--no-sandbox", "--disable-dev-shm-usage", "--disable-gpu"]
    });
    
    const cookies = await context.cookies(["https://google.com", "https://notebooklm.google.com", "https://accounts.google.com"]);
    console.log("Extracted cookies count via Patchright:", cookies.length);
    
    let netscapeData = "# Netscape HTTP Cookie File\n";
    for (const c of cookies) {
      const domain = c.domain.startsWith(".") ? c.domain : "." + c.domain;
      const includeSubdomains = "TRUE";
      const path = c.path;
      const secure = c.secure ? "TRUE" : "FALSE";
      const expiry = c.expires && c.expires > 0 ? Math.floor(c.expires) : Math.floor(Date.now() / 1000) + 86400 * 30;
      netscapeData += `${domain}\t${includeSubdomains}\t${path}\t${secure}\t${expiry}\t${c.name}\t${c.value}\n`;
    }
    
    fs.writeFileSync("/data/cookies.txt", netscapeData);
    await context.close();
    console.log("COOKIES_EXTRACTED_SUCCESS");
  } catch (e) {
    console.error("Extraction error:", e.message);
  }
})();
' || true

if [ -f /data/cookies.txt ]; then
  echo "Importing /data/cookies.txt into nlm..."
  nlm login --manual --file /data/cookies.txt --force || true
fi

echo "3. Starting NotebookLM MCP HTTP Server on port 3000..."
node dist/index.js --transport http --port 3000 --host 0.0.0.0 &
sleep 1

echo "MCP Server Ready! (headless-only, no desktop daemons, no Chrome profile locks)"
exec tail -f /dev/null
