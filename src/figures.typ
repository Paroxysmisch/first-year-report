// Additional candidate figures (not yet used in the report).
//
// The four figures already in the report (Glueball loop, inequivalence
// checking, agent-built compiler, unified performance model) live in
// `figures/` and are imported here only so this preview shows them too.
//
// Compiling this file directly (`typst compile src/figures.typ`) renders a
// preview of every figure with a suggested caption and placement.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "/figures/common.typ": *
#import "/figures/glueball.typ": fig-glueball
#import "/figures/inequivalence.typ": fig-inequivalence
#import "/figures/compiler.typ": fig-compiler
#import "/figures/perf-model.typ": fig-perf-model
#import "@preview/cetz:0.3.4"

// ===========================================================================
// Figure C — Warp-specialised asynchronous pipeline (§2.2)
// A producer warp issues TMA loads into a 2-stage shared-memory ring buffer;
// a consumer warpgroup runs MMA + softmax. "full"/"empty" barriers order
// them; dropping one creates a race that only some interleavings expose.
// ===========================================================================
#let fig-async-pipeline = {
  set text(size: 7.5pt)
  cetz.canvas(length: 0.88cm, {
    import cetz.draw: *

    let stage-col = (c-kern, c-comp)
    let lane-h = 0.62
    let y-prod = 2.2
    let y-cons = 0.6
    let x0 = 2.7 // left edge of the time axis (labels sit to its left)

    // Lane labels and guide lines.
    content((x0 - 0.15, y-prod + lane-h / 2), anchor: "east", align(right)[*Producer Warp* \ #text(fill: c-muted)[TMA loads]])
    content((x0 - 0.15, y-cons + lane-h / 2), anchor: "east", align(right)[*Consumer Warpgroup* \ #text(fill: c-muted)[MMA + softmax]])
    for y in (y-prod, y-cons) {
      line((x0, y - 0.08), (x0 + 13.2, y - 0.08), stroke: 0.4pt + rgb("#dddddd"))
    }

    // An activity block on a lane.
    let act(t0, t1, y, col, label, light: false) = {
      rect(
        (x0 + t0 + 0.04, y),
        (x0 + t1 - 0.04, y + lane-h),
        fill: if light { col.lighten(85%) } else { col.lighten(70%) },
        stroke: 0.6pt + col,
        radius: 2pt,
      )
      content(((x0 + (t0 + t1) / 2), y + lane-h / 2), text(size: if light { 6.5pt } else { 7pt }, fill: col.darken(35%), label))
    }

    // Producer: loads of tiles 0..3 into stages 0,1,0,1.
    let loads = ((0, 2, 0), (2, 4, 1), (4, 6, 0), (7, 9, 1))
    for (i, (a, b, s)) in loads.enumerate() {
      act(a, b, y-prod, stage-col.at(s), [load $T_#i$ → $s_#s$])
    }
    // Consumer: MMA (reads the stage) then softmax.
    let mmas = ((2, 4, 0), (5, 7, 1), (8, 10, 0), (11, 13, 1))
    for (i, (a, b, s)) in mmas.enumerate() {
      act(a, b, y-cons, stage-col.at(s), [MMA $T_#i$ ← $s_#s$])
      if i < 3 { act(b, b + 1, y-cons, c-grey, [softmax], light: true) }
    }

    // Barrier arrows: "full" (load done → MMA may read) and
    // "empty" (MMA done → stage may be overwritten).
    let barrier(from, to, col, dash: none) = line(
      from, to,
      stroke: (paint: col, thickness: 0.6pt, dash: dash),
      mark: (end: ">", fill: col, scale: 0.5),
    )
    for ((la, lb, s), (ma, mb, _)) in loads.zip(mmas) {
      barrier((x0 + lb - 0.1, y-prod), (x0 + ma + 0.12, y-cons + lane-h), c-ok)
    }
    // empty(s0) after MMA T0 releases tile 2's load; empty(s1) after MMA T1 releases tile 3's load.
    barrier((x0 + 4 - 0.1, y-cons + lane-h), (x0 + 4 + 0.12, y-prod), c-hw, dash: "dashed")
    barrier((x0 + 7 - 0.1, y-cons + lane-h), (x0 + 7 + 0.12, y-prod), c-hw, dash: "dashed")

    // Time axis.
    line((x0, 0.25), (x0 + 13.3, 0.25), stroke: 0.5pt + c-muted, mark: (end: ">", fill: c-muted, scale: 0.5))
    content((x0 + 13.3, 0.05), anchor: "north-east", text(fill: c-muted, style: "italic")[time])

    // Hazard annotation on the empty(s0) wait.
    let hx = x0 + 4.05
    circle((hx, y-prod + lane-h + 0.22), radius: 0.13, fill: c-bad, stroke: none)
    content((hx, y-prod + lane-h + 0.22), text(fill: white, weight: "bold", size: 6pt)[!])
    line((hx + 0.15, y-prod + lane-h + 0.22), (hx + 0.7, y-prod + lane-h + 0.55), stroke: 0.5pt + c-bad)
    content(
      (hx + 0.75, y-prod + lane-h + 0.55),
      anchor: "west",
      box(width: 7.2cm, text(fill: c-bad, size: 7pt)[Omit this _empty_ wait and load $T_2$ may overwrite $s_0$ while MMA $T_0$ is still reading it — a race that only some thread interleavings expose.]),
    )

    // Legend.
    let ly = -0.55
    let lx = x0
    line((lx, ly), (lx + 0.6, ly), stroke: 0.6pt + c-ok, mark: (end: ">", fill: c-ok, scale: 0.5))
    content((lx + 0.7, ly), anchor: "west")[_full_ barrier: data has landed]
    line((lx + 4.9, ly), (lx + 5.5, ly), stroke: (paint: c-hw, thickness: 0.6pt, dash: "dashed"), mark: (end: ">", fill: c-hw, scale: 0.5))
    content((lx + 5.6, ly), anchor: "west")[_empty_ barrier: stage free to reuse]
    rect((lx + 10.6, ly - 0.14), (lx + 10.9, ly + 0.14), fill: c-kern.lighten(70%), stroke: 0.6pt + c-kern, radius: 1pt)
    rect((lx + 11.0, ly - 0.14), (lx + 11.3, ly + 0.14), fill: c-comp.lighten(70%), stroke: 0.6pt + c-comp, radius: 1pt)
    content((lx + 11.4, ly), anchor: "west")[smem stage $s_0$ / $s_1$]
  })
}

// ===========================================================================
// Figure D — NVFP4 block-scaled format (§2.2, numerical representation)
// ===========================================================================
#let fig-nvfp4 = {
  set text(size: 7.5pt)
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let cw = 0.19 // element cell width
    let ch = 0.42 // element cell height
    let gap = 0.3 // gap between blocks
    let nblocks = 4
    let bw = 16 * cw
    let total = nblocks * bw + (nblocks - 1) * gap
    let y = 1.2 // bottom of the element row

    // Tensor-wide FP32 scale.
    let tx = total / 2
    rect((tx - 1.6, 2.75), (tx + 1.6, 3.2), fill: c-hw.lighten(80%), stroke: 0.7pt + c-hw, radius: 3pt)
    content((tx, 2.975), text(fill: c-hw.darken(30%))[*FP32* Tensor Scale $s_"tensor"$])
    line((0, 2.25), (0, 2.4), (total, 2.4), (total, 2.25), stroke: 0.6pt + c-hw)
    line((tx, 2.4), (tx, 2.75), stroke: 0.6pt + c-hw)
    content((total + 0.1, 2.4), anchor: "west", text(fill: c-muted)[one per tensor])

    for b in range(nblocks) {
      let bx = b * (bw + gap)
      // 16 four-bit elements.
      for i in range(16) {
        rect(
          (bx + i * cw, y),
          (bx + (i + 1) * cw, y + ch),
          fill: if calc.even(i) { c-kern.lighten(78%) } else { c-kern.lighten(68%) },
          stroke: 0.4pt + c-kern,
        )
      }
      // Block bracket + FP8 scale.
      let mx = bx + bw / 2
      line((bx, y - 0.1), (bx, y - 0.25), (bx + bw, y - 0.25), (bx + bw, y - 0.1), stroke: 0.6pt + c-comp)
      line((mx, y - 0.25), (mx, y - 0.45), stroke: 0.6pt + c-comp)
      rect((mx - 0.95, y - 0.9), (mx + 0.95, y - 0.45), fill: c-comp.lighten(82%), stroke: 0.7pt + c-comp, radius: 3pt)
      content((mx, y - 0.675), text(fill: c-comp.darken(30%))[*FP8* $s_#b$ (E4M3)])
      // Block label above.
      content((mx, y + ch + 0.22), text(fill: c-muted)[Block #b · 16 × FP4])
    }
    content((total + 0.1, y + ch / 2), anchor: "west", text(fill: c-muted)[...])
    content((total + 0.1, y - 0.675), anchor: "west", text(fill: c-muted)[one per 16 values])

    // Zoom into a single element: E2M1 bit layout.
    let zx = 0.3
    let zy = -1.55
    let bits = (([S], c-grey), ([E], c-kern), ([E], c-kern), ([M], c-comp))
    line((0, y), (zx, zy + 0.5), stroke: (paint: c-muted, thickness: 0.4pt, dash: "dotted"))
    line((cw, y), (zx + 4 * 0.5, zy + 0.5), stroke: (paint: c-muted, thickness: 0.4pt, dash: "dotted"))
    for (i, (lbl, col)) in bits.enumerate() {
      rect((zx + i * 0.5, zy), (zx + (i + 1) * 0.5, zy + 0.5), fill: col.lighten(80%), stroke: 0.6pt + col)
      content((zx + i * 0.5 + 0.25, zy + 0.25), text(weight: "bold", fill: col.darken(30%), lbl))
    }
    content((zx, zy - 0.3), anchor: "west", text(fill: c-muted)[FP4 element (E2M1): sign, 2 exponent, 1 mantissa bit])

    // Decoding formula + storage cost.
    content(
      (zx + 6.6, zy + 0.25),
      anchor: "west",
      align(left)[
        #text(size: 9pt)[$x_i = "fp4"_i dot s_("block"(i)) dot s_"tensor"$] \
        #v(2pt)
        #text(fill: c-muted)[$16 times 4 + 8 = 72$ bits per block $arrow.r.double$ *4.5 bits / value*] \
        #text(fill: c-muted)[Blackwell MMA applies $s_b$ in hardware — no expansion to FP16]
      ],
    )
  })
}

// ===========================================================================
// Figure G — PhD timeline as a Gantt chart (Timeline chapter)
// ===========================================================================
#let fig-timeline = {
  set text(size: 7.5pt)
  set par(justify: false)
  let terms = ([Mich.], [Lent], [Easter], [Mich.], [Lent], [Easter], [Mich.])
  let years = (([2026], 1), ([2027], 3), ([2028], 3))

  // (label, start term, end term (inclusive), colour, milestone label or none)
  let tasks = (
    ([Glueball reviews (ICLR 2027)], 0, 0, c-kern, none),
    ([Inequivalence checking], 0, 1, c-kern, [submit]),
    ([Kernel opt. & verification manuscript], 1, 1, c-kern, none),
    ([Agent-built compilers (PLENA)], 2, 3, c-comp, [submit]),
    ([Hardware-aware inference optimization], 3, 4, c-comp, [submit]),
    ([Compiler development manuscript], 4, 4, c-comp, none),
    ([AI-accelerated performance modelling], 4, 5, c-hw, [submit]),
    ([Industry research internship], 5, 5, c-grey, none),
    ([Performance modelling manuscript], 5, 5, c-hw, none),
    ([Thesis write-up and submission], 6, 6, c-ink, [submit]),
  )

  let bar(col, milestone, light) = block(
    width: 100%,
    height: 11pt,
    fill: if light { col.lighten(75%) } else { col.lighten(35%) },
    stroke: 0.6pt + col,
    radius: 5.5pt,
    {
      if milestone != none {
        place(right + horizon, dx: 1pt, text(size: 11pt, fill: col.darken(20%))[◆])
      }
    },
  )

  let n = terms.len()
  let cells = ()
  // Header: years, then terms.
  cells.push([])
  for (y, span) in years {
    cells.push(grid.cell(colspan: span, align(center, text(weight: "bold")[#y])))
  }
  cells.push([])
  for t in terms { cells.push(align(center, text(fill: c-muted, t))) }
  // Rows.
  for (label, a, b, col, ms) in tasks {
    cells.push(align(right + horizon, label))
    for i in range(a) { cells.push([]) }
    let manuscript = repr(label).contains("manuscript")
    cells.push(grid.cell(colspan: b - a + 1, align(horizon, bar(col, ms, manuscript))))
    for i in range(n - b - 1) { cells.push([]) }
  }

  grid(
    columns: (auto,) + (1fr,) * n,
    column-gutter: 3pt,
    row-gutter: 5pt,
    align: horizon,
    // Light vertical term separators and a year separator.
    stroke: (x, y) => if x > 0 and y > 0 {
      (left: if x in (2, 5) { 0.6pt + c-grey } else { 0.3pt + rgb("#e5e5e5") })
    },
    inset: (x: 3pt, y: 2pt),
    ..cells,
  )
  v(4pt)
  align(center, text(fill: c-muted, size: 7pt)[
    #box(width: 14pt, height: 6pt, fill: c-kern.lighten(35%), radius: 3pt) kernels #h(8pt)
    #box(width: 14pt, height: 6pt, fill: c-comp.lighten(35%), radius: 3pt) compilers #h(8pt)
    #box(width: 14pt, height: 6pt, fill: c-hw.lighten(35%), radius: 3pt) hardware #h(8pt)
    #box(width: 14pt, height: 6pt, fill: c-grey.lighten(75%), stroke: 0.5pt + c-grey, radius: 3pt) write-up / other #h(8pt)
    ◆ paper submission
  ])
}

// ===========================================================================
// Preview document (only rendered when this file is compiled directly)
// ===========================================================================
#set page(paper: "a4", margin: (x: 2.75cm, top: 3cm, bottom: 3cm))
#set text(font: "New Computer Modern", size: 12pt, fill: c-ink)
#set par(justify: true)
#show figure: set block(breakable: false)
#show figure: it => block(above: 1.5em, below: 2.5em, it)
#show figure.caption: it => text(size: 9.5pt)[
  #text(weight: "bold", fill: rgb("#C98A2B"))[
    #it.supplement #context it.counter.display(it.numbering)#it.separator
  ]
  #it.body
]

#let placement(body) = block(
  width: 100%,
  inset: (x: 8pt, y: 5pt),
  fill: rgb("#F6F6F6"),
  radius: 2pt,
  text(size: 8.5pt, fill: c-muted)[*Suggested placement:* #body],
)

#text(size: 25pt, style: "italic")[Candidate figures]
#v(4pt)
#text(size: 10pt, fill: c-muted)[Preview of figures defined in `figures.typ`. Import a figure with
  `#import "/figures.typ": fig-glueball` and wrap it in `#figure(...)`.]

#placement[Introduction (the Glueball paragraph) or the start of §3.1, next to "In my first year, I worked on Glueball…".]
#figure(fig-glueball, caption: [Glueball's optimization loop. Starting from a PyTorch model and its reference Triton kernels, an agent proposes candidate Gluon kernels; each must pass a correctness pipeline combining symbolic execution and a Z3 model of GPU hardware semantics before being benchmarked end-to-end. Counterexamples and profiling results are fed back to guide the next revision.])

#placement[§3.1, after the paragraph introducing _inequivalence checking_.]
#figure(fig-inequivalence, caption: [Proposed inequivalence checking. Agents may use any tool to search for a separating input, but are never trusted: a kernel is only rejected on a counterexample whose mismatch has been reproduced by running both kernels on real hardware.])

#placement[§2.2 Developments in AI Computer Architecture, alongside the paragraph on asynchronous execution (or §3.1 when motivating why random testing misses bugs).]
#figure(fig-async-pipeline, caption: [A warp-specialized pipeline on Hopper/Blackwell. A producer warp issues asynchronous TMA loads into a two-stage shared-memory buffer while a consumer warpgroup runs MMA and softmax. _Full_ and _empty_ barriers order the two; a single missing wait introduces a data race that ordinary testing rarely exposes.])

#placement[§2.2, next to the paragraph on numerical representation and NVFP4.]
#figure(fig-nvfp4, caption: [The NVFP4 block-scaled format. Each 4-bit E2M1 value shares an FP8 scale with the other 15 values in its block, and all values share an FP32 tensor-wide scale. Blackwell's block-scaled MMA instructions apply these scales directly in hardware.])

#placement[§3.2, after the paragraph describing the PLENA backend project.]
#figure(fig-compiler, caption: [Proposed agent-built compiler workflow. Agents learn PLENA from its documentation and their own probe experiments, then build XLA and Triton backends. A suite of development programs is compiled and run on the PLENA simulator and checked against a CPU reference, with failing programs and counterexamples fed back to the agents. As new hardware features are added to PLENA, the agents adapt the backends to exploit them.])

#placement[§3.3, after the paragraph proposing the unified framework.]
#figure(fig-perf-model, caption: [Proposed unified performance model. It unifies two currently separate strands of learned performance modelling: _workload-aware_ models, which predict how a program executes on a fixed or parameterised architecture (e.g. Concorde, NeuSight), and _circuit_ models, which predict the power and area of hardware from its RTL independently of any workload (e.g. CircuitFusion, TopoRTL). Given a design's RTL, its documentation (e.g. opcode semantics and natural-language descriptions of each unit) and a workload's compiled instruction stream, a single learned model estimates power, performance and area. Synthesis and PLENA simulation provide the supervision used to train it.])

#placement[Timeline and Future Work chapter, directly under the chapter heading (also gives it the lead-in text it currently lacks).]
#figure(fig-timeline, caption: [Planned timeline for the remainder of the PhD, coloured by position on the software–hardware spectrum of Figure 1. Lighter bars are write-up activities; diamonds mark planned paper submissions.])
