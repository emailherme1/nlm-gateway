#!/bin/bash
set -e

VNC_PASS=${VNC_PASSWORD:-"hermes123"}

echo "1. Starting Xvfb on :99..."
Xvfb :99 -screen 0 1280x800x24 &
sleep 2

echo "2. Starting Fluxbox Window Manager on :99..."
fluxbox -display :99 &
sleep 1

echo "3. Starting x11vnc on port 5900..."
x11vnc -storepasswd "$VNC_PASS" /tmp/x11vnc.pass
x11vnc -rfbport 5900 -rfbauth /tmp/x11vnc.pass -display :99 -forever -shared &
sleep 1

echo "4. Starting noVNC / websockify on port 8080..."
websockify --web /usr/share/novnc 8080 localhost:5900 &
sleep 1

echo "5. Auto-launching Chromium on DISPLAY=:99 with persistent profile..."
chromium \
  --no-sandbox \
  --user-data-dir=/data/chrome_profile \
  --display=:99 \
  --window-size=1280,800 \
  --window-position=0,0 \
  --start-maximized \
  "https://accounts.google.com" &

echo "Desktop & Chromium Launched Successfully!"
exec tail -f /dev/null
