#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "common.typ": *

// Proposed inequivalence checking (§3.1, @fig:inequivalence)
#let fig-inequivalence = {
  set text(size: 8pt)
  set par(justify: false, leading: 0.45em)
  diagram(
    ..dstyle,
    spacing: (24pt, 16pt),
    tnode(
      (0, 1),
      [Adversarial Agents],
      body: [
        search for inputs that \ separate the two kernels \
        #v(2pt)
        #chip(c-kern)[Theorem Provers] #chip(c-kern)[Fuzzers] \
        #chip(c-kern)[Debuggers] \
        #chip(c-kern)[Static Analysis] \
        #chip(c-kern)[Runtime Analysis]
      ],
      col: c-kern,
      name: <adv>,
      width: 3.2cm,
      height: auto,
    ),
    tnode((1, 1), [Test Input $x$], body: [shapes, values, \ edge cases], col: c-grey, name: <x>, width: 2.4cm),
    tnode((2, 0), [$K_"ref" (x)$], body: [run on GPU], col: c-hw, name: <kref>, width: 1.9cm),
    tnode((2, 2), [$K_"opt" (x)$], body: [run on GPU], col: c-hw, name: <kopt>, width: 1.9cm),
    tnode((3, 1), [Compare], body: [outputs, within \ tolerance], col: c-hw, name: <cmp>, width: 2.1cm),
    tnode((4, 0), [Reject], body: [replayable \ counterexample], col: c-bad, name: <rej>, width: 2.5cm),
    tnode((4, 2), [Accept], body: [no counterexample \ within budget], col: c-ok, name: <acc>, width: 2.5cm),

    // Trust boundaries.
    node(
      enclose: (<kref>, <kopt>, <cmp>),
      stroke: (paint: c-hw, thickness: 0.6pt, dash: "dashed"),
      corner-radius: 6pt,
      inset: 5pt,
      name: <trusted>,
    ),
    node((2.5, 2.8), text(size: 6.5pt, fill: c-hw.darken(10%), style: "italic")[trusted: real execution on hardware]),
    node((0, 2.05), text(size: 6.5pt, fill: c-kern.darken(10%), style: "italic")[untrusted: search only]),

    edge(<adv>, <x>, "-|>"),
    edge(<x>, <kref>, "-|>"),
    edge(<x>, <kopt>, "-|>"),
    edge(<kref>, <cmp>, "-|>"),
    edge(<kopt>, <cmp>, "-|>"),
    // Labels sit on the part of the edge outside the dashed trust boundary.
    edge(<cmp>, <rej>, "-|>", text(fill: c-bad)[mismatch], label-side: right, label-pos: 0.72),
    edge(<cmp>, <acc>, "-|>", text(fill: c-ok)[match], label-side: left, label-pos: 0.72),
    edge(<cmp>, (3, -0.85), (0, -0.85), <adv>, "-|>", text(fill: c-muted)[no mismatch yet: keep searching], stroke: (paint: c-grey, thickness: 0.6pt, dash: "dashed"), label-pos: 0.5, label-side: right),
  )
}
