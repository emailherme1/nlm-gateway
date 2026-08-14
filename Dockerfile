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

# Structure-independent patch for Google Rebrand (notebooklm.google.com -> notebook.google.com)
RUN grep -rl 'notebooklm\.google\.com' --include='*.ts' /app/src \
    | xargs -r sed -i 's/notebooklm\.google\.com/notebook\.google\.com/g'

# Conditional helper check in src/config.ts
RUN grep -q 'isNotebookLmUrl' src/config.ts \
    || echo '
export function isNotebookLmUrl(url: string): boolean { return url.includes("notebook.google.com") || url.includes("notebooklm.google.com"); }' >> src/config.ts

# Build project
RUN npm install
RUN npm run build

# Create directory for persistent Chrome profile
RUN mkdir -p /data/chrome_profile

# Copy entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 3000 8080 5900

CMD ["/app/entrypoint.sh"]
