ARG PANDOC_BASE_IMAGE=docker.io/pandoc/extra:3.10.0-ubuntu
ARG NODE_BASE_IMAGE=docker.io/library/node:22.23.1-bookworm-slim
ARG MERMAID_CLI_VERSION=11.16.0
ARG PUPPETEER_VERSION=24.43.1

FROM ${NODE_BASE_IMAGE} AS node-runtime
FROM ${PANDOC_BASE_IMAGE}

ARG PROJECT_VERSION
ARG MERMAID_CLI_VERSION
ARG PUPPETEER_VERSION
LABEL org.opencontainers.image.title="md2pdf" \
      org.opencontainers.image.version="${PROJECT_VERSION}" \
      org.opencontainers.image.description="Offline Markdown to PDF converter with Pandoc, XeLaTeX and Mermaid"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PUPPETEER_CACHE_DIR=/opt/puppeteer \
    HOME=/tmp/home \
    XDG_CACHE_HOME=/tmp/cache \
    XDG_CONFIG_HOME=/tmp/config

USER root

RUN test -n "${PROJECT_VERSION}"

COPY --from=node-runtime /usr/local/bin/node /usr/local/bin/node
COPY --from=node-runtime /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN apt-get -q --no-allow-insecure-repositories update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      fonts-noto-cjk \
      python3 \
    && test "$(dpkg --print-architecture)" = amd64 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* \
    && fc-cache -f

RUN test "$(node --version)" = v22.23.1 \
    && ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && mkdir -p /opt/mermaid-cli \
    && cd /opt/mermaid-cli \
    && npm init --yes \
    && npm install --omit=dev --save-exact \
      "@mermaid-js/mermaid-cli@${MERMAID_CLI_VERSION}" \
      "puppeteer@${PUPPETEER_VERSION}" \
    && ln -s /opt/mermaid-cli/node_modules/.bin/mmdc /usr/local/bin/mmdc

RUN apt-get -q --no-allow-insecure-repositories update \
    && /opt/mermaid-cli/node_modules/.bin/puppeteer browsers install chrome --install-deps \
    && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /root/.cache /tmp/*

RUN kpsewhich zref-lastpage.sty >/dev/null \
    && kpsewhich zref-user.sty >/dev/null \
    && kpsewhich pzdr.tfm >/dev/null \
    && mmdc --version | grep -Fx "${MERMAID_CLI_VERSION}"

COPY docker/convert.sh /usr/local/bin/md2pdf-convert
RUN printf '{"args":["--no-sandbox","--disable-setuid-sandbox","--disable-dev-shm-usage","--font-render-hinting=none"]}\n' > /usr/local/share/md2pdf-puppeteer.json \
    && chmod +x /usr/local/bin/md2pdf-convert

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/md2pdf-convert"]
