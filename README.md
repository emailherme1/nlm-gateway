# nlm-gateway (Simplified 1-Click Desktop)

Single-layer 1-Click Desktop with persistent Chromium session on Railway Volume.

## Features
- **Zero-Password noVNC**: Opened directly via `http://<host>:8080/vnc.html?autoconnect=true` (Single Auth Layer).
- **Persistent Chromium Daemon**: Automatically launches Chromium targeting `/data/chrome_profile` and auto-restarts if closed.
- **Session Survival**: Closing browser tab or disconnects will NOT terminate Chromium or the desktop.
