#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME=${MD2PDF_IMAGE_NAME:-md2pdf}
VERSION=$(<VERSION)
TARGET_PLATFORM=${MD2PDF_PLATFORM:-linux/amd64}
PANDOC_BASE_IMAGE=${PANDOC_BASE_IMAGE:-docker.io/pandoc/extra:3.10.0-ubuntu}
NODE_BASE_IMAGE=${NODE_BASE_IMAGE:-docker.io/library/node:22.23.1-bookworm-slim}
MERMAID_CLI_VERSION=${MERMAID_CLI_VERSION:-11.16.0}
PUPPETEER_VERSION=${PUPPETEER_VERSION:-24.43.1}

if [[ ! "$VERSION" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "ERROR: VERSION must be a release SemVer in MAJOR.MINOR.PATCH form: $VERSION" >&2
  exit 65
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker command not found" >&2
  exit 69
fi

docker pull --platform "$TARGET_PLATFORM" "$PANDOC_BASE_IMAGE"

docker build \
  --platform "$TARGET_PLATFORM" \
  --build-arg "PROJECT_VERSION=$VERSION" \
  --build-arg "PANDOC_BASE_IMAGE=$PANDOC_BASE_IMAGE" \
  --build-arg "NODE_BASE_IMAGE=$NODE_BASE_IMAGE" \
  --build-arg "MERMAID_CLI_VERSION=$MERMAID_CLI_VERSION" \
  --build-arg "PUPPETEER_VERSION=$PUPPETEER_VERSION" \
  -t "$IMAGE_NAME:latest" \
  -t "$IMAGE_NAME:$VERSION" \
  .

printf 'Built %s:latest and %s:%s for %s\n' "$IMAGE_NAME" "$IMAGE_NAME" "$VERSION" "$TARGET_PLATFORM"
