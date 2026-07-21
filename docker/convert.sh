#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: md2pdf-convert INPUT_MD OUTPUT_PDF" >&2
}

if [[ $# -ne 2 ]]; then
  usage
  exit 64
fi

input=$1
output=$2

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
\usepackage{lastpage}
\setmainfont{Noto Serif CJK SC}
\setsansfont{Noto Sans CJK SC}
\setCJKmainfont{Noto Serif CJK SC}
\setCJKsansfont{Noto Sans CJK SC}
\pagestyle{fancy}
\fancyhf{}
\fancyfoot[C]{\thepage{} / \pageref{LastPage}}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}
EOF_TEX


pandoc "$processed" \
  --from markdown+fenced_code_blocks+implicit_figures \
  --to pdf \
  --pdf-engine=xelatex \
  --resource-path="$srcdir:$workdir" \
  --metadata papersize=a4 \
  --metadata fontsize=12pt \
  --variable geometry:top=1cm \
  --variable geometry:bottom=1cm \
  --variable geometry:inner=2cm \
  --variable geometry:outer=1cm \
  --variable classoption=twoside \
  --include-in-header="$workdir/header.tex" \
  --output "$output"
