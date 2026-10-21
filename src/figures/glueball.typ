#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "common.typ": *

// Glueball optimization loop (§3.1, @fig:glueball)
#let fig-glueball = {
  set text(size: 8pt)
  set par(justify: false, leading: 0.45em)
  diagram(
    ..dstyle,
    spacing: (34pt, 30pt),
    tnode((0, 0), [Reference Model], body: [PyTorch model with \ reference Triton kernels], col: c-grey, name: <ref>, width: 3.3cm),
    tnode((1, 0), [Optimizer Agent], body: [LLM proposes a faster \ Gluon kernel], col: c-kern, name: <agent>, width: 3.3cm),
    tnode((2, 0), [Candidate Kernel], body: [TMA, warp specialization, \ async MMA, ...], col: c-kern, name: <cand>, width: 3.6cm),
    tnode(
      (2, 1),
      [Correctness Pipeline],
      body: [
        symbolic execution of Triton IR (Z3) \
        Gluon-to-Z3 hardware semantics \
        #v(1pt)
        #chip(c-comp)[Race Freedom] #chip(c-comp)[Barrier Ordering] \
        #chip(c-comp)[Bank Behaviour]
      ],
      col: c-comp,
      name: <check>,
      width: 4.6cm,
      height: auto,
    ),
    tnode((1, 1), [Benchmark & Profile], body: [end-to-end model \ performance on GPU], col: c-hw, name: <bench>, width: 3.7cm),

    edge(<ref>, <agent>, "-|>"),
    edge(<agent>, <cand>, "-|>", [generate]),
    edge(<cand>, <check>, "-|>", [check], label-side: left),
    edge(<check>, <bench>, "-|>", [pass], label-side: left),
    edge(<check>, <agent>, "-|>", elabel(col: c-bad)[counterexample], stroke: 0.7pt + c-bad, bend: 18deg, label-pos: 0.5, label-side: right),
    edge(<bench>, <agent>, "-|>", text(fill: c-hw.darken(10%))[profile feedback], stroke: (paint: c-hw, thickness: 0.7pt, dash: "dashed"), label-side: left),
  )
}
