#!/bin/bash
set -e

export DISPLAY=:99
export PLAYWRIGHT_BROWSERS_PATH=/data/ms-playwright

echo "1. Ensuring persistent directories, symlinks & cleaning up chromium locks..."
mkdir -p /data/chrome_profile
mkdir -p /data/ms-playwright
mkdir -p /root/.local/share/notebooklm-mcp
mkdir -p /root/.cache

# Kill any stale chromium or chrome process that holds the lock
pkill -9 chromium || true
pkill -9 chrome || true
rm -rf /data/chrome_profile/Singleton* 2>/dev/null || true

ln -sf /data/chrome_profile /root/.local/share/notebooklm-mcp/chrome_profile
ln -sf /data/ms-playwright /root/.cache/ms-playwright

echo "2. Starting Xvfb on :99 (1280x800)..."
Xvfb :99 -screen 0 1280x800x24 &
sleep 2

echo "3. Starting Fluxbox Window Manager..."
fluxbox &
sleep 1

echo "4. Starting x11vnc (no password)..."
x11vnc -rfbport 5900 -nopw -display :99 -forever -shared &
sleep 1

echo "5. Starting noVNC / websockify on port 8080..."
websockify --web /usr/share/novnc 8080 127.0.0.1:5900 &
sleep 1

echo "6. Starting NotebookLM MCP HTTP Server on port 3000..."
node dist/index.js --transport http --port 3000 --host 0.0.0.0 &
sleep 1

echo "Desktop & MCP Server Ready! (No background daemon locking Chrome profile)"
exec tail -f /dev/null
