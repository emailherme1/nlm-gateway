#!/bin/bash
set -e

export DISPLAY=:99

echo "1. Starting Xvfb on :99 (1280x800)..."
Xvfb :99 -screen 0 1280x800x24 &
sleep 2

echo "2. Starting Fluxbox Window Manager..."
fluxbox &
sleep 1

echo "3. Starting x11vnc (no password)..."
x11vnc -rfbport 5900 -nopw -display :99 -forever -shared &
sleep 1

echo "4. Starting noVNC / websockify on port 8080..."
websockify --web /usr/share/novnc 8080 127.0.0.1:5900 &
sleep 1

echo "5. Starting persistent Chromium supervisor daemon..."
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

echo "Desktop & Persistent Chromium Daemon Ready!"
exec tail -f /dev/null
