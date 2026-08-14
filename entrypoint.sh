#!/bin/bash
set -e

echo "1. Starting Xvfb on :99..."
Xvfb :99 -screen 0 1280x800x24 &
sleep 2

echo "2. Starting Fluxbox Window Manager..."
fluxbox -display :99 &
sleep 1

echo "3. Starting x11vnc (no password, single auth layer)..."
x11vnc -rfbport 5900 -nopw -display :99 -forever -shared &
sleep 1

echo "4. Starting noVNC / websockify..."
websockify --web /usr/share/novnc 8080 localhost:5900 &
sleep 1

echo "5. Starting persistent Chromium supervisor loop..."
(
  while true; do
    echo "[Chromium Supervisor] Launching Chromium..."
    chromium \
      --no-sandbox \
      --user-data-dir=/data/chrome_profile \
      --display=:99 \
      --window-size=1280,800 \
      --window-position=0,0 \
      --start-maximized \
      --disable-session-crashed-bubble \
      --disable-infobars \
      "https://notebook.google.com" || true
    echo "[Chromium Supervisor] Chromium exited. Restarting in 3 seconds..."
    sleep 3
  done
) &

echo "Desktop & Persistent Chromium Daemon Ready!"
exec tail -f /dev/null
