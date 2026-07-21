#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME=${MD2PDF_IMAGE_NAME:-md2pdf}
VERSION=$(tr -d '[:space:]' < VERSION)
DEBIAN_CODENAME=${DEBIAN_CODENAME:-trixie}
MERMAID_CLI_VERSION=${MERMAID_CLI_VERSION:-11.16.0}

if [[ -z "$VERSION" ]]; then
  echo "ERROR: VERSION is empty" >&2
  exit 65
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker command not found" >&2
  exit 69
fi

docker build \
  --build-arg "DEBIAN_CODENAME=$DEBIAN_CODENAME" \
  --build-arg "MERMAID_CLI_VERSION=$MERMAID_CLI_VERSION" \
  -t "$IMAGE_NAME:latest" \
  -t "$IMAGE_NAME:$VERSION" \
  .

printf 'Built %s:latest and %s:%s\n' "$IMAGE_NAME" "$IMAGE_NAME" "$VERSION"
