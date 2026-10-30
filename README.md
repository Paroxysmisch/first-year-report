# first-year-report

A clean, modern Typst template for PhD first-year / annual reports.
New Computer Modern serif body text, generous margins, mostly black-and-white
typography, and a customizable navy + amber accent palette used only in
small touches — a heading numeral, a short rule, captions, links, a callout
border. The cover page is left-aligned and minimal: author tucked top-right,
a big title, plain supervisor/advisor lines, and the institution/logo tucked
away at the bottom — no centered blocks, no boring bordered info table.

## Layout

```
typst.toml       package + template manifest
build.sh         full build: typst compile + append the Glueball manuscript PDF
src/
  lib.typ        the template implementation (import target)
  main.typ       the report itself
  refs.bib       bibliography entries
  figures/       Typst source for diagrams used in the report
  res/
    logo.svg               placeholder "university crest" (swap for your own)
    glueball-truncated.pdf manuscript appended after the Manuscripts appendix — see build.sh
```

This follows Typst's own conventions for authoring a template package: a
`typst.toml` manifest with a `[template]` table, an absolute-path entrypoint
(`src/lib.typ`) relative to the package root, and a self-contained `src/`
folder that is what gets copied when someone scaffolds a new project from
this package.

## Try it now (no install needed)

From the repo root:

```sh
typst compile src/main.typ src/main.pdf
```

No `--root` flag needed: `src/main.typ`'s absolute imports (`/lib.typ`, and
paths like `/res/logo.svg`) are written assuming `src/` itself is the root,
which is exactly what Typst defaults to (the entry file's own directory) —
and matches how it resolves once this is installed as a real package too.

Open `src/main.pdf` to view the result.

### Full build (with the Glueball manuscript appended)

`src/main.typ`'s Manuscripts appendix ends with the Glueball paper, which
exists as its own PDF (`src/res/glueball-truncated.pdf`) rather than as
Typst source — re-typesetting someone else's paper would lose its original
figures/pagination and risks subtly misrepresenting a manuscript under
review. Instead, `./build.sh` compiles the Typst report on its own and then
stitches the manuscript's pages onto the end verbatim with `pdfunite`
(part of `poppler-utils`), which concatenates PDF pages at the file level —
no rasterization or re-layout. Run:

```sh
./build.sh
```

This only works because the manuscript is the very last thing in the
document: `main.typ` passes `auto-bibliography: false` to `report()` and
calls `#references(...)` by hand *before* `#show: appendix`, so References
lands ahead of the appendix and nothing Typst-rendered follows the
manuscript. A plain `typst compile` still works for fast iteration — it
just won't have the manuscript's pages appended.

## Use it in other projects

To make the template importable from *any* Typst project (and usable with
`typst init`), install it into Typst's local package directory:

```sh
mkdir -p ~/.local/share/typst/packages/local/first-year-report/0.1.0
cp -r . ~/.local/share/typst/packages/local/first-year-report/0.1.0
```

Then, in a new or existing project:

```sh
typst init @local/first-year-report:0.1.0 my-report
```

or import it directly into an existing `.typ` file:

```typ
#import "@local/first-year-report:0.1.0": report, callout, directions, appendix, references

#show: report.with(
  title: "My First Year Report",
  author: "Your Name",
  supervisor: "Prof. Someone",
  advisor: "Dr. Someone Else",
  logo: "res/logo.svg",
)

= Introduction
...
```

## Customizing

Every color and font is a parameter to `report()` — override any of them at
call-time, nothing is hard-coded elsewhere in `lib.typ`:

| Parameter | Default | Notes |
|---|---|---|
| `title` | `"Report Title"` | Plain string; auto-shrinks for long titles (>55 / >90 chars) so it still wraps cleanly on the cover page. |
| `subtitle` | `none` | Optional italic line under the title. |
| `author` | `"Author Name"` | |
| `student-id` | `none` | Skipped on the cover page if `none`. |
| `department` | `"Department Name"` | |
| `institution` | `"Institution Name"` | Shown in small caps above the title. |
| `degree` | `"Doctor of Philosophy"` | |
| `report-type` | `"First Year Report"` | |
| `supervisor` | `none` | Skipped if `none`. |
| `advisor` | `none` | Skipped if `none`. |
| `logo` | `none` | Path to an image (svg/png/pdf); shown small, next to the institution line tucked at the bottom of the cover. Use an absolute path (e.g. `"/res/logo.svg"`) if it doesn't sit next to your entry file. |
| `logo-width` | `1.6cm` | |
| `date` | `datetime.today()` | |
| `abstract` | `none` | Content; adds an Abstract page if given. |
| `abbreviations` | `none` | Content; adds a "List of Abbreviations" page (styled like the Abstract) before the table of contents if given, e.g. `abbr.list()` from `@preview/abbr`. |
| `abbreviations-title` | `"List of Abbreviations"` | |
| `bibliography-file` | `none` | Path to a `.bib` file; adds a References section if given. |
| `bibliography-style` | `"apa"` | Any style Typst's `bibliography()` accepts. Only used when `citation-style` is `"long"`. |
| `citation-style` | `"long"` | `"long"` uses `bibliography-style` (e.g. apa author-year citations); `"short"` ignores it and falls back to Typst's own built-in default citation style (compact numeric, e.g. `[1]`). |
| `auto-bibliography` | `true` | Renders References automatically at the very end of the document. Set to `false` if you call `references()` yourself somewhere else in the body (e.g. before an appendix). |
| `show-word-count` | `false` | Show a word count of the main text (after the contents, before the references) on the cover, via `@preview/wordometer`. |
| `word-count-exclude` | `(figure,)` | Extra elements to leave out of the word count (functions, names, or labels), e.g. `(figure, raw)`. |
| `primary-color` | `rgb("#1B2A4A")` (deep navy) | Headings, rules, title text. |
| `accent-color` | `rgb("#C98A2B")` (warm amber) | Rules, captions, links, page numbers, callouts. |
| `body-font` | `"New Computer Modern"` | Bundled with Typst — no install needed. |
| `heading-font` | `"New Computer Modern"` | |
| `mono-font` | `"DejaVu Sans Mono"` | Used in code blocks. |
| `chapter-label` | `"Chapter"` | The small gray kicker word printed above each level-1 heading (e.g. `"Section"` instead). |
| `font-size` | `12pt` | |
| `paper` | `"a4"` | Any Typst paper size string. |

Example — a teal/rust palette with a different mono font:

```typ
#show: report.with(
  title: "My Report",
  author: "Your Name",
  primary-color: rgb("#1D3E40"),
  accent-color: rgb("#B5502C"),
  mono-font: "Cascadia Code",
)
```

A `#callout(title: "Note", color: accent-color)[...]` helper is also
exported for tinted, left-bordered admonition boxes — handy for flagging
open questions or discussion points for your supervisor meetings.

A `#directions[...][...][...]` helper is exported too — a compact numbered
list styled like the table of contents' big bold numerals, just smaller,
for outlining a short list of directions, options, or steps inline in the
body text (e.g. the research directions you plan to pursue). Each
bracketed argument is one item's content.

For appendices, wrap the rest of the document with `#show: appendix` —
the same way `#show: report.with(...)` wraps the whole document, so
everything *before* the call is untouched and everything *after* it
becomes an appendix. Level-1 headings switch from "Chapter N" to
"Appendix A", "Appendix B", ... (same visual treatment, just lettered),
and the heading counter restarts from scratch:

```typ
#show: appendix

= Experiment Configurations
...

= Survey Instrument
...
```

Pass `label: "Something Else"` to `appendix()` to change the kicker word,
just like `chapter-label` does for regular chapters. It also drives what
`@label` refs print: a reference to a heading inside the appendix reads
e.g. "Appendix A.1" (matching `label`) rather than Typst's default
"Section A.1", at any heading level.

If you need References to land *before* the appendix (the usual
convention) rather than at the very end, pass `auto-bibliography: false`
to `report()` and call `#references("/refs.bib")` yourself at the point
you want it — see `src/main.typ` for a worked example that does exactly
this to fit an appended manuscript after the appendix.

`src/res/logo.svg` is just a placeholder crest — replace it with your own
university's logo file and update the `logo:` path.
