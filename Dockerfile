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
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

ENV BROWSER_CHANNEL=chromium
ENV BROWSER_EXECUTABLE_PATH=/usr/bin/chromium
ENV DISPLAY=:99

WORKDIR /app

# Create directory for persistent Chrome profile
RUN mkdir -p /data/chrome_profile

# Copy entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 8080 5900

CMD ["/app/entrypoint.sh"]
