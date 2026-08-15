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

# Kill any stale chromium or chrome process that holds the lock
pkill -9 chromium || true
pkill -9 chrome || true
rm -rf /data/chrome_profile/Singleton* 2>/dev/null || true

ln -sf /data/chrome_profile /root/.local/share/notebooklm-mcp/chrome_profile
ln -sf /data/browser_state /root/.local/share/notebooklm-mcp/browser_state
ln -sf /data/ms-playwright /root/.cache/ms-playwright

echo "2. (desktop Xvfb/fluxbox/x11vnc/websockify DISABLED to save RAM)"

echo "3. Starting NotebookLM MCP HTTP Server on port 3000..."
node dist/index.js --transport http --port 3000 --host 0.0.0.0 &
sleep 1

echo "MCP Server Ready! (headless-only, no desktop daemons, no Chrome profile locks)"
exec tail -f /dev/null
