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

# Install patchright & playwright browsers directly into /root/.cache/ms-playwright
RUN npm install
RUN npx patchright install chromium || true
RUN npx playwright install chromium || true
RUN mkdir -p /root/.cache/ms-playwright/chromium_headless_shell-1194/chrome-linux/
RUN ln -sf /usr/bin/chromium /root/.cache/ms-playwright/chromium_headless_shell-1194/chrome-linux/headless_shell
RUN npm run build

# Create directory for persistent Chrome profile and symlink for env-paths
RUN mkdir -p /data/chrome_profile
RUN mkdir -p /root/.local/share/notebooklm-mcp
RUN ln -sf /data/chrome_profile /root/.local/share/notebooklm-mcp/chrome_profile

# Copy entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 3000 8080 5900

CMD ["/app/entrypoint.sh"]
