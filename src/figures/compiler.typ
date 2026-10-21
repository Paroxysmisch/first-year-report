#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "common.typ": *

// Proposed agent-built compiler workflow (§3.2, @fig:compiler)
#let fig-compiler = {
  set text(size: 8pt)
  set par(justify: false, leading: 0.45em)
  diagram(
    ..dstyle,
    spacing: (20pt, 30pt),
    tnode((0, 0), [Documentation], body: [PLENA ISA, memory \ hierarchy, manuals], col: c-grey, name: <docs>, width: 3.1cm),
    tnode((0, 1), [New Hardware Feature], body: [e.g. LUT Tensor Core], col: c-hw, name: <newhw>, width: 3.1cm),
    tnode((1, 0), [Compiler Agents], body: [write, test and extend \ the backends], col: c-comp, name: <agents>, width: 3.3cm),
    tnode((1, 1), [Probe Experiments], body: [resolve ambiguous or \ missing semantics], col: c-comp, name: <probe>, width: 3.3cm),
    tnode((2, 0), [Agent-Built Backends], body: [#chip(c-comp)[XLA] #chip(c-comp)[Triton]], col: c-comp, name: <be>, width: 3.6cm),
    tnode((2, 1), [Program Suite], body: [JAX programs & Triton \ kernels used for testing], col: c-kern, name: <progs>, width: 3.6cm),
    tnode((2, 2), [CPU Reference], body: [runs the same \ programs], col: c-grey, name: <cpu>, width: 3.6cm),
    tnode((3, 0), [PLENA Simulator], body: [runs the compiled \ programs], col: c-hw, name: <sim>, width: 3.1cm),
    tnode((3, 2), [Compare], body: [outputs + inequivalence \ checking (Ch. 1)], col: c-kern, name: <cmp>, width: 3.1cm),

    edge(<docs>, <agents>, "-|>", [read]),
    edge(<agents>, <probe>, "<|-|>", [run / observe], label-side: left),
    edge(<newhw>, <agents>, "-|>", elabel(col: c-hw)[adapt], stroke: (paint: c-hw, thickness: 0.7pt, dash: "dashed"), label-side: left, label-pos: 0.45),
    edge(<agents>, <be>, "-|>", [build]),
    edge(<progs>, <be>, "-|>", [compile], label-side: right),
    edge(<progs>, <cpu>, "-|>"),
    edge(<be>, <sim>, "-|>"),
    edge(<sim>, <cmp>, "-|>"),
    edge(<cpu>, <cmp>, "-|>"),
    edge(<cmp>, (3, 2.75), (1, 2.75), <probe>, "-|>", text(fill: c-bad)[failing programs, counterexamples], stroke: 0.7pt + c-bad, label-side: left, label-pos: 0.5),
  )
}
