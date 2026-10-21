#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "common.typ": *

// Proposed unified performance model (§3.3, @fig:perf-model)
#let fig-perf-model = {
  set text(size: 8pt)
  set par(justify: false, leading: 0.45em)
  let sup = (paint: c-muted, thickness: 0.6pt, dash: "dashed")
  diagram(
    ..dstyle,
    spacing: (26pt, 18pt),
    // Inputs.
    tnode((0, 0), [Hardware Design], body: [configuration + \ RTL of each unit], col: c-hw, name: <hw>, width: 3cm),
    tnode((0, 1), [Documentation], body: [opcode semantics, natural- \ language unit descriptions], col: c-grey, name: <docs>, width: 3.4cm),
    tnode((0, 2), [Workload], body: [machine learning \ model/program], col: c-kern, name: <wl>, width: 3cm),
    tnode((1, 0), [RTL Encoder], body: [learned embedding \ per hardware unit], col: c-hw, name: <enc>, width: 3cm),
    tnode((1, 2), [Compiler #text(weight: "regular")[(Ch. 2)]], body: [instruction stream \ for this design], col: c-comp, name: <cc>, width: 3cm),
    // Model and outputs.
    tnode(
      (2, 1),
      [Learned Model],
      body: [
        predicts PPA for each \ design–workload pair \
        #v(2pt)
        #chip(c-ink)[Language Model] #chip(c-ink)[GNN] \
        #chip(c-ink)[Multi-Layer Perceptron]
      ],
      col: c-ink,
      name: <model>,
      width: 3.4cm,
      height: auto,
    ),
    tnode((3, 1), [PPA Estimates], body: [time, power, area, perf / W], col: c-ok, name: <out>, width: 2.7cm),
    // Supervision (training data).
    tnode((2, -1), [Synthesis], body: [once per design: \ area, clock, power], col: c-grey, name: <syn>, width: 3cm),
    tnode((2, 3), [Simulation], body: [PLENA, per pairing: \ cycles, activity], col: c-grey, name: <simu>, width: 3cm),

    edge(<hw>, <enc>, "-|>"),
    edge(<wl>, <cc>, "-|>"),
    edge(<enc>, <model>, "-|>"),
    edge(<docs>, <model>, "-|>"),
    edge(<cc>, <model>, "-|>"),
    edge(<model>, <out>, "-|>"),
    edge(<hw>, (0, -1), <syn>, "-|>"),
    edge(<cc>, (1, 3), <simu>, "-|>"),
    edge(<syn>, <model>, "-|>", text(fill: c-muted)[supervision], stroke: sup, label-side: left),
    edge(<simu>, <model>, "-|>", text(fill: c-muted)[supervision], stroke: sup, label-side: right),
  )
}
