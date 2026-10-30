#!/usr/bin/env bash
# Builds src/main.pdf.
#
# The report itself is typeset by Typst, but the Glueball manuscript
# (src/res/glueball-truncated.pdf) is an existing PDF, not Typst source —
# re-typesetting it would lose its original figures/pagination and risk
# subtly misrepresenting a paper under review. Instead we compile the
# Typst report on its own, then stitch the manuscript's pages onto the end
# verbatim with `pdfunite` (poppler-utils), which concatenates PDF pages
# at the file level with no rasterization or re-layout involved. This
# only works because the manuscript is the very last thing in the
# document — see the `auto-bibliography: false` + manual `#references(...)`
# call in main.typ, which moves References before the "Manuscripts"
# appendix so nothing in the Typst output follows it.
set -euo pipefail
cd "$(dirname "$0")/src"

typst compile main.typ .main-typst-only.pdf
pdfunite .main-typst-only.pdf res/glueball-truncated.pdf main.pdf
rm .main-typst-only.pdf

echo "Built src/main.pdf ($(pdfinfo main.pdf | awk '/^Pages/{print $2}') pages)"
