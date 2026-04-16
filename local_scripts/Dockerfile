FROM ubuntu:24.04

COPY certs /etc/ssl/certs

RUN set -eux; \
    sed -i 's|URIs: http://|URIs: https://|g' /etc/apt/sources.list.d/ubuntu.sources; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl ca-certificates git python3 python3-pip python3-pytest bash \
        ripgrep ffmpeg libxcb-shm0 libx11-xcb1 libx11-6 libxcb1 libxext6 libxrandr2 libxcomposite1 libxcursor1 libxdamage1 libxfixes3 libxi6 libgtk-3-0t64 libpangocairo-1.0-0 libpango-1.0-0 libatk1.0-0t64 libcairo-gobject2 libcairo2 libgdk-pixbuf-2.0-0 libxrender1 libasound2t64 libfreetype6 libfontconfig1 libdbus-1-3 libnss3 libnspr4 libatk-bridge2.0-0t64 libdrm2 libxkbcommon0 libatspi2.0-0t64 libcups2t64 libxshmfence1 libgbm1

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - 
RUN apt-get install -y --no-install-recommends nodejs 

# Install agent-browser
RUN npm i -g agent-browser
# Install chrome for agent-browser
RUN agent-browser install

# Install uv uvx
RUN curl -sSfL https://astral.sh/uv/0.9.7/install.sh | sh

# Install Pochi CLI
RUN curl -fsSL https://getpochi.com/install.sh | bash && ln -sf ~/.pochi/bin/pochi /usr/local/bin/pochi

# Proxy ENVs
ENV http_proxy="http://172.17.0.1:1087"
ENV https_proxy="http://172.17.0.1:1087"
ENV no_proxy="192.168.0.0/16, 10.0.0.0/8, localhost, 127.0.0.10"

CMD ["/bin/bash"]
