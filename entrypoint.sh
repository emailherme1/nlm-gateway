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

echo "2. Syncing cookies from /data/chrome_profile for nlm CLI..."
python3 -c '
import sqlite3, json, glob, os
from notebooklm_tools.core.auth import AuthManager

dbs = glob.glob("/data/chrome_profile/**/Cookies", recursive=True) + glob.glob("/data/chrome_profile/**/Network/Cookies", recursive=True)
cookies = []
for db in dbs:
    try:
        conn = sqlite3.connect(db)
        c = conn.cursor()
        c.execute("SELECT host_key, name, value, path, expires_utc, is_secure, is_httponly FROM cookies WHERE host_key LIKE \"%google%\"")
        for row in c.fetchall():
            cookies.append({
                "domain": row[0],
                "name": row[1],
                "value": row[2],
                "path": row[3],
                "expires": row[4],
                "secure": bool(row[5]),
                "httpOnly": bool(row[6])
            })
        conn.close()
    except Exception as e:
        print("Cookie read error:", e)

if cookies:
    am = AuthManager("default")
    am.save_profile(cookies=cookies, force=True)
    print("✅ nlm profile synced successfully with", len(cookies), "cookies!")
else:
    print("⚠️ No cookies found in /data/chrome_profile")
' || true

echo "3. Starting NotebookLM MCP HTTP Server on port 3000..."
node dist/index.js --transport http --port 3000 --host 0.0.0.0 &
sleep 1

echo "MCP Server Ready! (headless-only, no desktop daemons, no Chrome profile locks)"
exec tail -f /dev/null
