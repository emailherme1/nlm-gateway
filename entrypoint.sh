#!/bin/bash
set -e

VNC_PASS=${VNC_PASSWORD:-"hermes123"}

echo "Starting Xvfb on :99..."
Xvfb :99 -screen 0 1280x800x24 &
sleep 2

echo "Starting x11vnc..."
x11vnc -storepasswd "$VNC_PASS" /tmp/x11vnc.pass
x11vnc -rfbport 5900 -rfbauth /tmp/x11vnc.pass -display :99 -forever -shared &
sleep 1

echo "Starting noVNC / websockify on port 8080..."
websockify --web /usr/share/novnc 8080 localhost:5900 &
sleep 1

echo "Starting NotebookLM MCP HTTP Server on port 3000..."
node dist/index.js --transport http --port 3000 --host 0.0.0.0 &

echo "Gateway Services Started Successfully!"
exec tail -f /dev/null
