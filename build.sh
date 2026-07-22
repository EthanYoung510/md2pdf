#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME=${MD2PDF_IMAGE_NAME:-md2pdf}
VERSION=$(tr -d '[:space:]' < VERSION)
PANDOC_BASE_IMAGE=${PANDOC_BASE_IMAGE:-docker.io/pandoc/extra:3.10.0-ubuntu}
NODE_BASE_IMAGE=${NODE_BASE_IMAGE:-docker.io/library/node:22.23.1-bookworm-slim}
MERMAID_CLI_VERSION=${MERMAID_CLI_VERSION:-11.16.0}
PUPPETEER_VERSION=${PUPPETEER_VERSION:-24.43.1}

if [[ -z "$VERSION" ]]; then
  echo "ERROR: VERSION is empty" >&2
  exit 65
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker command not found" >&2
  exit 69
fi

docker pull "$PANDOC_BASE_IMAGE"

docker build \
  --build-arg "PANDOC_BASE_IMAGE=$PANDOC_BASE_IMAGE" \
  --build-arg "NODE_BASE_IMAGE=$NODE_BASE_IMAGE" \
  --build-arg "MERMAID_CLI_VERSION=$MERMAID_CLI_VERSION" \
  --build-arg "PUPPETEER_VERSION=$PUPPETEER_VERSION" \
  -t "$IMAGE_NAME:latest" \
  -t "$IMAGE_NAME:$VERSION" \
  .

printf 'Built %s:latest and %s:%s\n' "$IMAGE_NAME" "$IMAGE_NAME" "$VERSION"
