FROM node:20-slim

# Install system Chromium, Xvfb, Fluxbox window manager, x11vnc, noVNC, websockify
RUN apt-get update && apt-get install -y \
    chromium \
    xvfb \
    fluxbox \
    x11vnc \
    novnc \
    websockify \
    git \
    patch \
    ca-certificates \
    procps \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --break-system-packages notebooklm-mcp-cli

ENV BROWSER_CHANNEL=chromium
ENV BROWSER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV NOTEBOOKLM_TRANSPORT=http
ENV NOTEBOOKLM_HOST=0.0.0.0
ENV NOTEBOOKLM_PORT=3000
ENV NOTEBOOK_PROFILE_STRATEGY=single
ENV DISPLAY=:99

WORKDIR /app

# Clone notebooklm-mcp v2.0.0 tag
RUN git clone -b v2.0.0 https://github.com/PleasePrompto/notebooklm-mcp.git .

# Copy all patched TypeScript source files directly into cloned repo before build
COPY src/config.ts /app/src/config.ts
COPY src/auth/auth-manager.ts /app/src/auth/auth-manager.ts
COPY src/session/shared-context-manager.ts /app/src/session/shared-context-manager.ts
COPY src/session/browser-session.ts /app/src/session/browser-session.ts
COPY src/browser/chromium-fallback.ts /app/src/browser/chromium-fallback.ts
COPY src/tools/handlers.ts /app/src/tools/handlers.ts

# Install node dependencies & build project
RUN npm install
RUN npm run build

# Run runtime patches for persistent single-profile auth fallback
COPY patch.js /app/patch.js
RUN node patch.js

# Create directory for persistent Chrome profile and symlinks for env-paths
RUN mkdir -p /data/chrome_profile
RUN mkdir -p /root/.local/share/notebooklm-mcp
RUN ln -sf /data/chrome_profile /root/.local/share/notebooklm-mcp/chrome_profile

# Copy entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 3000 8080 5900

CMD ["/app/entrypoint.sh"]
