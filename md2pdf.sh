#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: ./md2pdf.sh [OPTIONS] [INPUT] [OUTPUT_DIR]

Options:
  -s, --single-sided   Use single-sided layout: left 2 cm, right 1 cm, page number at bottom right
  -d, --double-sided   Use double-sided layout (default): inner 2 cm, outer 1 cm, page number outside
  -f, --front-matter   Add a title page and table of contents
  -h, --help           Show this help
EOF
}

IMAGE=${MD2PDF_IMAGE:-md2pdf:latest}
print_mode=
front_matter=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--single-sided)
      if [[ -n "$print_mode" && "$print_mode" != single ]]; then
        echo "ERROR: --single-sided and --double-sided cannot be used together" >&2
        exit 64
      fi
      print_mode=single
      shift
      ;;
    -d|--double-sided)
      if [[ -n "$print_mode" && "$print_mode" != double ]]; then
        echo "ERROR: --single-sided and --double-sided cannot be used together" >&2
        exit 64
      fi
      print_mode=double
      shift
      ;;
    -f|--front-matter)
      front_matter=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      usage
      exit 64
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -gt 2 ]]; then
  echo "ERROR: too many arguments" >&2
  usage
  exit 64
fi

print_mode=${print_mode:-double}
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
    "$IMAGE" "/source/$(basename "$file")" "/output/$(basename "$out")" \
    "$print_mode" "$front_matter"
  echo "Wrote $out"
done
