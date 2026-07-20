#!/usr/bin/env bash
set -euo pipefail

IMAGE=${MD2PDF_IMAGE:-md2pdf:latest}
INPUT=${1:-./}
OUTPUT_DIR=${2:-}

if [[ ! -e "$INPUT" ]]; then
  echo "ERROR: input does not exist: $INPUT" >&2
  exit 66
fi

input_abs=$(cd "$(dirname "$INPUT")" && pwd -P)/$(basename "$INPUT")

if [[ -f "$input_abs" && "${input_abs##*.}" != "md" ]]; then
  echo "ERROR: input file must have .md extension: $input_abs" >&2
  exit 66
fi

mapfile -d '' files < <(
  if [[ -f "$input_abs" ]]; then
    printf '%s\0' "$input_abs"
  else
    find "$input_abs" -type f -name '*.md' -print0 | sort -z
  fi
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No Markdown files found under: $input_abs" >&2
  exit 0
fi

if [[ -n "$OUTPUT_DIR" ]]; then
  mkdir -p "$OUTPUT_DIR"
  output_abs=$(cd "$OUTPUT_DIR" && pwd -P)
  declare -A seen=()
  for file in "${files[@]}"; do
    pdf_name="$(basename "${file%.md}.pdf")"
    if [[ -n "${seen[$pdf_name]:-}" ]]; then
      echo "ERROR: flattened output name collision: $pdf_name" >&2
      echo "  ${seen[$pdf_name]}" >&2
      echo "  $file" >&2
      exit 65
    fi
    seen[$pdf_name]=$file
  done
fi

for file in "${files[@]}"; do
  if [[ -n "$OUTPUT_DIR" ]]; then
    out="$output_abs/$(basename "${file%.md}.pdf")"
  else
    out="$(dirname "$file")/$(basename "${file%.md}.pdf")"
  fi
  mkdir -p "$(dirname "$out")"
  docker run --rm \
    --network none \
    --read-only \
    --tmpfs /tmp:rw,nosuid,nodev,noexec,size=512m \
    --tmpfs /run:rw,nosuid,nodev,noexec,size=64m \
    --security-opt no-new-privileges \
    -v "$(dirname "$file"):/source:ro" \
    -v "$(dirname "$out"):/output:rw" \
    "$IMAGE" "/source/$(basename "$file")" "/output/$(basename "$out")"
  echo "Wrote $out"
done
