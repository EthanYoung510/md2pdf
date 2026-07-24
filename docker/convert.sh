#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: md2pdf-convert INPUT_MD OUTPUT_PDF [single|double] [true|false]" >&2
}

if [[ $# -lt 2 || $# -gt 4 ]]; then
  usage
  exit 64
fi

input=$1
output=$2
print_mode=${3:-double}
front_matter=${4:-false}

if [[ "$print_mode" != single && "$print_mode" != double ]]; then
  echo "ERROR: print mode must be single or double: $print_mode" >&2
  exit 64
fi

if [[ "$front_matter" != true && "$front_matter" != false ]]; then
  echo "ERROR: front matter must be true or false: $front_matter" >&2
  exit 64
fi

if [[ ! -f "$input" || "${input##*.}" != "md" ]]; then
  echo "ERROR: input must be an existing .md file: $input" >&2
  exit 66
fi

mkdir -p "$(dirname "$output")"
workdir=$(mktemp -d /tmp/md2pdf.XXXXXX)
trap 'rm -rf "$workdir"' EXIT

srcdir=$(cd "$(dirname "$input")" && pwd -P)
base=$(basename "$input" .md)
processed="$workdir/$base.processed.md"
assets="$workdir/mermaid-assets"
mkdir -p "$assets"

python3 - "$input" "$processed" "$assets" <<'PY'
import hashlib
import pathlib
import re
import subprocess
import sys

source = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
assets = pathlib.Path(sys.argv[3])
text = source.read_text(encoding="utf-8")
pattern = re.compile(r"(^```mermaid[ \t]*\n)(.*?)(^```[ \t]*$)", re.MULTILINE | re.DOTALL)


def render(match):
    code = match.group(2).strip() + "\n"
    digest = hashlib.sha256(code.encode("utf-8")).hexdigest()[:16]
    mmd = assets / f"mermaid-{digest}.mmd"
    png = assets / f"mermaid-{digest}.png"
    mmd.write_text(code, encoding="utf-8")
    subprocess.run(
        [
            "mmdc",
            "--input", str(mmd),
            "--output", str(png),
            "--scale", "3",
            "--backgroundColor", "white",
            "--puppeteerConfigFile", "/usr/local/share/md2pdf-puppeteer.json",
        ],
        check=True,
    )
    return f"\n![]({png})\n"

target.write_text(pattern.sub(render, text), encoding="utf-8")
PY

cat > "$workdir/header.tex" <<'EOF_TEX'
\usepackage{fontspec}
\usepackage{xeCJK}
\usepackage{fancyhdr}
\usepackage{zref-lastpage}
\usepackage{zref-user}
\setmainfont{Noto Serif CJK SC}
\setsansfont{Noto Sans CJK SC}
\setCJKmainfont{Noto Serif CJK SC}
\setCJKsansfont{Noto Sans CJK SC}
\pagestyle{fancy}
\fancyhf{}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}
EOF_TEX

geometry_args=(
  --variable geometry:top=2cm
  --variable geometry:bottom=2cm
)
class_options=()

if [[ "$print_mode" == single ]]; then
  geometry_args+=(
    --variable geometry:left=2cm
    --variable geometry:right=1cm
  )
  printf '%s\n' '\fancyfoot[R]{\thepage{} / \zpageref{LastPage}}' >> "$workdir/header.tex"
else
  geometry_args+=(
    --variable geometry:inner=2cm
    --variable geometry:outer=1cm
  )
  class_options+=(twoside)
  printf '%s\n' '\fancyfoot[LE,RO]{\thepage{} / \zpageref{LastPage}}' >> "$workdir/header.tex"
fi

pandoc_args=(
  "$processed"
  --from markdown+fenced_code_blocks+implicit_figures
  --to pdf
  --pdf-engine=xelatex
  --resource-path="$srcdir:$workdir"
  --metadata papersize=a4
  --metadata fontsize=12pt
  "${geometry_args[@]}"
  --include-in-header="$workdir/header.tex"
  --output "$output"
)

if [[ "$front_matter" == true ]]; then
  cat > "$workdir/front-matter.lua" <<'EOF_LUA'
function Pandoc(doc)
  local fallback = doc.meta["md2pdf-fallback-title"]
  doc.meta["md2pdf-fallback-title"] = nil

  if doc.meta.title then
    return doc
  end

  for index, block in ipairs(doc.blocks) do
    if block.t == "Header" and block.level == 1 then
      doc.meta.title = pandoc.MetaInlines(block.content)
      table.remove(doc.blocks, index)
      return doc
    end
  end

  doc.meta.title = fallback
  return doc
end
EOF_LUA
  class_options+=(titlepage)
  pandoc_args+=(
    --lua-filter="$workdir/front-matter.lua"
    --metadata "md2pdf-fallback-title=$base"
    --toc
  )
fi

if [[ ${#class_options[@]} -gt 0 ]]; then
  class_option=$(IFS=,; printf '%s' "${class_options[*]}")
  pandoc_args+=(--variable "classoption=$class_option")
fi

pandoc "${pandoc_args[@]}"
