FROM node:20-slim

# Install Chromium, xvfb, x11vnc, novnc, websockify, git, patch, ca-certificates
RUN apt-get update && apt-get install -y \
    chromium \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    git \
    patch \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Set environment for patchright/chromium
ENV BROWSER_CHANNEL=chromium
ENV BROWSER_EXECUTABLE_PATH=/usr/bin/chromium
ENV NOTEBOOKLM_TRANSPORT=http
ENV NOTEBOOKLM_HOST=0.0.0.0
ENV NOTEBOOKLM_PORT=3000
ENV DISPLAY=:99

WORKDIR /app

# Clone notebooklm-mcp v2.0.0 tag
RUN git clone -b v2.0.0 https://github.com/PleasePrompto/notebooklm-mcp.git .

# Build project first
RUN npm install
RUN npm run build

# Copy and execute node patcher script on compiled dist/
COPY patch.js /app/patch.js
RUN node /app/patch.js

# Create directory for persistent Chrome profile
RUN mkdir -p /data/chrome_profile

# Copy entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 3000 8080 5900

CMD ["/app/entrypoint.sh"]
