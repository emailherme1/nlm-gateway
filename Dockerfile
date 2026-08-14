FROM node:20-slim

# Install Chromium, Xvfb, Fluxbox window manager, x11vnc, noVNC, websockify
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
    && rm -rf /var/lib/apt/lists/*

ENV BROWSER_CHANNEL=chromium
ENV BROWSER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PLAYWRIGHT_BROWSERS_PATH=/data/ms-playwright
ENV NOTEBOOKLM_TRANSPORT=http
ENV NOTEBOOKLM_HOST=0.0.0.0
ENV NOTEBOOKLM_PORT=3000
ENV DISPLAY=:99

WORKDIR /app

# Clone notebooklm-mcp v2.0.0 tag
RUN git clone -b v2.0.0 https://github.com/PleasePrompto/notebooklm-mcp.git .

# Copy patched TypeScript source files directly into cloned repo before build
COPY src/tools/handlers.ts /app/src/tools/handlers.ts
COPY src/auth/auth-manager.ts /app/src/auth/auth-manager.ts
COPY src/session/shared-context-manager.ts /app/src/session/shared-context-manager.ts

# Install node dependencies & build
RUN npm install
RUN npm run build

# Create directory for persistent Chrome profile and symlinks
RUN mkdir -p /data/chrome_profile
RUN mkdir -p /data/ms-playwright
RUN mkdir -p /root/.local/share/notebooklm-mcp
RUN mkdir -p /root/.cache
RUN ln -sf /data/chrome_profile /root/.local/share/notebooklm-mcp/chrome_profile
RUN ln -sf /data/ms-playwright /root/.cache/ms-playwright

# Copy entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 3000 8080 5900

CMD ["/app/entrypoint.sh"]
