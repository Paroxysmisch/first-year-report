// Shared palette and drawing helpers for the report's diagrams.
// Colours match Figure 1 (the software → compiler → hardware spectrum).

#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

// ---------------------------------------------------------------------------
// Palette — shared with Figure 1 (software → compiler → hardware spectrum)
// ---------------------------------------------------------------------------
#let c-kern = rgb("#2563eb") // kernels / software
#let c-comp = rgb("#7c3aed") // compilers
#let c-hw = rgb("#c2410c") // hardware
#let c-ok = rgb("#1a7f37")
#let c-bad = rgb("#b42318")
#let c-ink = rgb("#111111")
#let c-muted = rgb("#6b6b6b")
#let c-grey = rgb("#9a9a9a")

// Standard height for ordinary boxes so that every box in a diagram lines up.
// Boxes that deserve emphasis (e.g. the correctness pipeline) pass
// `height: auto` and grow to fit their contents instead.
#let box-h = 1.45cm

// A titled, tinted box node in the style of Figure 1's stage boxes.
// Titles use Title Case; the optional body is a short (≤ 2 line) description.
#let tnode(pos, title, body: none, col: c-ink, width: auto, height: box-h, ..args) = node(
  pos,
  align(center + horizon, {
    text(weight: "bold", fill: col.darken(25%), title)
    if body != none {
      linebreak()
      text(size: 7pt, fill: rgb("#444444"), body)
    }
  }),
  fill: col.lighten(90%),
  stroke: 0.8pt + col,
  corner-radius: 4pt,
  inset: 6pt,
  width: width,
  height: height,
  ..args,
)

// Small rounded "chip" used for tool / item labels inside nodes (Title Case).
#let chip(col, body) = box(
  fill: col.lighten(80%),
  inset: (x: 4pt, y: 2pt),
  radius: 6pt,
  text(size: 6.5pt, fill: col.darken(30%), body),
)

// Edge label with a white backing, so labels stay legible where they sit
// close to a line or boundary.
#let elabel(body, col: c-ink) = box(
  fill: white,
  inset: (x: 2pt, y: 1pt),
  text(fill: col, body),
)

// Common diagram settings.
#let dstyle = (
  spacing: (16pt, 20pt),
  edge-stroke: 0.7pt + c-ink,
  mark-scale: 70%,
  label-size: 7pt,
  label-sep: 4pt,
)
