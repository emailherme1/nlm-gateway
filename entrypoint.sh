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

echo "2. Extracting Netscape cookies & checking Google user account email..."
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
    
    const page = context.pages()[0] || await context.newPage();
    await page.goto("https://myaccount.google.com/", { waitUntil: "domcontentloaded", timeout: 30000 });
    await page.waitForTimeout(2000);
    
    const pageText = await page.innerText("body").catch(() => "");
    const emailMatch = pageText.match(/[a-zA-Z0-9._%+-]+@gmail\.com/i) || pageText.match(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/i);
    const activeEmail = emailMatch ? emailMatch[0] : "UNKNOWN_EMAIL";
    console.log("=== ACTIVE GOOGLE USER EMAIL ===", activeEmail);
    fs.writeFileSync("/data/active_email.txt", activeEmail);

    await page.goto("https://notebooklm.google.com/notebook/8ea457f6-2a15-4b96-b689-60839083c577", { waitUntil: "domcontentloaded", timeout: 30000 });
    await page.waitForTimeout(3000);
    await page.screenshot({ path: "/data/notebook_screenshot.png", fullPage: true }).catch(() => undefined);
    console.log("=== SCREENSHOT SAVED AT /data/notebook_screenshot.png ===");

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
  
  echo "=== ZERO-MOCK VERIFICATION STEP 1: ADD SOURCE ==="
  nlm source add 8ea457f6-2a15-4b96-b689-60839083c577 --title "VERIFY-SOURCE-8841" --text "کد امنیتی تایید هویت سیستم هرمس برابر است با: SECRET-KEY-994421" --wait || true
  
  echo "=== ZERO-MOCK VERIFICATION STEP 2: QUERY SECRET KEY ==="
  nlm notebook query 8ea457f6-2a15-4b96-b689-60839083c577 "کد امنیتی تایید هویت هرمس (SECRET-KEY) چیست؟" || true
  
  echo "=== ZERO-MOCK VERIFICATION STEP 3: SOURCE LIST ==="
  nlm source list 8ea457f6-2a15-4b96-b689-60839083c577 || true
fi

echo "3. Starting NotebookLM MCP HTTP Server on port 3000..."
node dist/index.js --transport http --port 3000 --host 0.0.0.0 &
sleep 1

echo "MCP Server Ready! (headless-only, no desktop daemons, no Chrome profile locks)"
exec tail -f /dev/null
