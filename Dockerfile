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

# Replace dockets
RUN grep -rl 'notebooklm\.google\.com' --include='*.ts' /app/src | xargs -r sed -i 's/notebooklm\.google\.com/notebook\.google\.com/g'
RUN grep -rl 'notebooklm%2Egoogle%2Ecom' --include='*.ts' /app/src | xargs -r sed -i 's/notebooklm%2Egoogle%2Ecom/notebook%2Egoogle%2Ecom/g'

# Build project so dist/ exists
RUN npm install
RUN npm run build

# Run node patcher on compiled dist JS files
COPY patch_dist.js /app/patch_dist.js
RUN node /app/patch_dist.js

# Create directory for persistent Chrome profile
RUN mkdir -p /data/chrome_profile

# Copy entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 3000 8080 5900

CMD ["/app/entrypoint.sh"]
