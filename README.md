# nlm-gateway (Google NotebookLM Gateway Service)

Gateway service for Google NotebookLM MCP server running on Chromium with persistent profile and web-based noVNC authentication.

## Ports
- **3000**: MCP HTTP Transport endpoint (`POST /mcp`, `GET /mcp`, `GET /healthz`)
- **8080**: noVNC Web GUI for interactive one-time Google Login (`http://<host>:8080/vnc.html`)
- **5900**: Direct VNC port

## Environment Variables
- `VNC_PASSWORD`: Password for noVNC/VNC login (Default: `hermes123`)
- `NOTEBOOKLM_TRANSPORT`: `http`
- `NOTEBOOKLM_PORT`: `3000`
- `NOTEBOOKLM_HOST`: `0.0.0.0`

## Google Rebrand Patches Applied
- Replaced `notebooklm.google.com` with `notebook.google.com` across `src/config.ts`, `src/auth/auth-manager.ts`, and `src/chat/chat-session.ts` (PR #90 / PR #80 compatibility).
