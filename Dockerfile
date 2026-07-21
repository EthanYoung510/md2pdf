ARG DEBIAN_CODENAME=trixie
ARG MERMAID_CLI_VERSION=11.16.0
FROM debian:${DEBIAN_CODENAME}-slim

ARG MERMAID_CLI_VERSION
LABEL org.opencontainers.image.title="md2pdf" \
      org.opencontainers.image.version="1.3" \
      org.opencontainers.image.description="Offline Markdown to PDF converter with Pandoc, XeLaTeX and Mermaid"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    HOME=/tmp/home \
    XDG_CACHE_HOME=/tmp/cache \
    XDG_CONFIG_HOME=/tmp/config

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      chromium \
      fonts-noto-cjk \
      lmodern \
      nodejs \
      npm \
      pandoc \
      python3 \
      texlive-fonts-recommended \
      texlive-lang-chinese \
      texlive-latex-extra \
      texlive-xetex \
    && npm install -g "@mermaid-js/mermaid-cli@${MERMAID_CLI_VERSION}" \
    && apt-get purge -y --auto-remove npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /root/.cache /tmp/*

COPY docker/convert.sh /usr/local/bin/md2pdf-convert
RUN printf '{"args":["--no-sandbox","--disable-setuid-sandbox","--disable-dev-shm-usage","--font-render-hinting=none"]}\n' > /usr/local/share/md2pdf-puppeteer.json \
    && chmod +x /usr/local/bin/md2pdf-convert

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/md2pdf-convert"]
