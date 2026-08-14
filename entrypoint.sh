#!/bin/bash
set -e

export DISPLAY=:99
export PLAYWRIGHT_BROWSERS_PATH=/data/ms-playwright

echo "1. Ensuring persistent directories & symlinks..."
mkdir -p /data/chrome_profile
mkdir -p /data/ms-playwright
mkdir -p /root/.local/share/notebooklm-mcp
mkdir -p /root/.cache

# Remove non-symlink /root/.cache/ms-playwright if present to avoid nested symlinks
if [ -d "/root/.cache/ms-playwright" ] && [ ! -L "/root/.cache/ms-playwright" ]; then
    rm -rf /root/.cache/ms-playwright
fi

ln -sf /data/chrome_profile /root/.local/share/notebooklm-mcp/chrome_profile
ln -sf /data/ms-playwright /root/.cache/ms-playwright

# Install patchright browsers if headless_shell does not exist in volume
if [ ! -f "/data/ms-playwright/chromium_headless_shell-1194/chrome-linux/headless_shell" ]; then
    echo "Downloading Patchright browsers (chromium & chromium-headless-shell) into /data/ms-playwright..."
    npx patchright install chromium chromium-headless-shell || npx playwright install chromium chromium-headless-shell || true
    
    # Fallback symlink if patchright download did not populate headless_shell
    if [ ! -f "/data/ms-playwright/chromium_headless_shell-1194/chrome-linux/headless_shell" ]; then
        echo "Creating fallback symlink for headless_shell to system chromium..."
        mkdir -p /data/ms-playwright/chromium_headless_shell-1194/chrome-linux
        ln -sf /usr/bin/chromium /data/ms-playwright/chromium_headless_shell-1194/chrome-linux/headless_shell
    fi
fi

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

echo "7. Starting persistent Chromium supervisor daemon..."
(
  while true; do
    echo "[Chromium Supervisor] Launching Chromium..."
    chromium \
      --no-sandbox \
      --disable-dev-shm-usage \
      --disable-gpu \
      --user-data-dir=/data/chrome_profile \
      --window-size=1280,800 \
      --window-position=0,0 \
      --start-maximized \
      --disable-session-crashed-bubble \
      --disable-infobars \
      "https://notebook.google.com" || true
    echo "[Chromium Supervisor] Chromium process exited. Restarting in 2 seconds..."
    sleep 2
  done
) &

echo "Desktop, MCP Server & Persistent Chromium Daemon Ready!"
exec tail -f /dev/null
