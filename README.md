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
src/
  lib.typ        the template implementation (import target)
  main.typ       demo report — compile this to see the template in action
  refs.bib       dummy bibliography entries used by the demo
  res/
    logo.svg     placeholder "university crest" used on the demo cover page
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
#import "@local/first-year-report:0.1.0": report, callout

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
| `bibliography-file` | `none` | Path to a `.bib` file; adds a References section if given. |
| `bibliography-style` | `"ieee"` | Any style Typst's `bibliography()` accepts. |
| `primary-color` | `rgb("#1B2A4A")` (deep navy) | Headings, rules, title text. |
| `accent-color` | `rgb("#C98A2B")` (warm amber) | Rules, captions, links, page numbers, callouts. |
| `body-font` | `"New Computer Modern"` | Bundled with Typst — no install needed. |
| `heading-font` | `"New Computer Modern"` | |
| `mono-font` | `"DejaVu Sans Mono"` | Used in code blocks. |
| `chapter-label` | `"Chapter"` | The small gray kicker word printed above each level-1 heading (e.g. `"Section"` instead). |
| `font-size` | `11pt` | |
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

`src/res/logo.svg` is just a placeholder crest — replace it with your own
university's logo file and update the `logo:` path.
