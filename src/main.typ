#import "/lib.typ": report, callout, directions
#import "@preview/abbr:0.3.1"

#abbr.make(
  ("AI", "Artificial Intelligence"),
  ("GPU", "Graphics Processing Unit"),
  ("TPU", "Tensor Processing Unit"),
  ("ML", "Machine Learning"),
  ("MoE", "Mixture of Experts"),
  ("LLM", "Large Language Model"),
  ("IR", "Intermediate Representation"),
)

#show: report.with(
  title: "Investigating the Emergent Dynamics of Distributed Consensus Protocols Under Adversarial Network Partitions",
  subtitle: "First Year Report",
  author: "Yash Shah",
  student-id: "123456789",
  department: "Department of Computer Science",
  institution: "University of Somewhere",
  degree: "Doctor of Philosophy",
  report-type: "First Year Report",
  supervisor: "Timothy M. Jones",
  advisor: "Robert Mullins",
  logo: "/res/ucam-logo.png",
  logo-width: 4cm,
  date: datetime(year: 2026, month: 9, day: 26),
  abstract: [
    This report summarizes progress made during the first year of a PhD
    investigating how distributed consensus protocols behave under
    adversarial network partitions. We motivate the problem, review related
    work, describe preliminary experiments, and outline a plan for the
    remaining years of the project.
  ],
  abbreviations: {
    // `abbr.list()` emits its own heading for a title; push it off to an
    // unused level and out of the outline so it doesn't consume a chapter
    // number or show up in the table of contents / running header.
    set heading(level: 6, outlined: false, numbering: none)
    abbr.list(title: [])
  },
  bibliography-file: "/refs.bib",
)

#show: abbr.show-rule

= Introduction
// - Scaling laws mean that larger LLMs are "smarter" and gives a nice, predictable method of improving models
// - Scaling laws are driving computational demand
//   - However, improvements in process node technology are not close to delivering the increase in performance required
//   - We are already utilizing massive parallelization with current GPUs, for example
//   - However, just increasing parallelization, while it can deliver the aggregate performance required, cannot hit power targets
//   - Just power delivery becomes a substantial cost of operation, particularly for inference
//   - The insatiable need for efficient compute drives more and more specialized designs
// - The machine learning/artificial intelligence community has assembled itself around the matrix multiplication primitive, which has thus begun the target and benchmark for performance/efficiency improvements
// - We see the rise of new accelerators e.g. TPUs, but importantly even more generous purpose GPUs are adopting more and more specialized compute units
//   - Concrete evidence is all the specialized operations introduced by NVIDIA from Ampere to Hopper to Blackwell (Ultra) to Rubin
// - Programming for such specialized accelerators requires much more hardware knowledge to maximize the hardware capabilities (Speed of Light)
//   - At the same time, despite the focus on the matrix multiplication primitive, there is intense development of the model architectures themselves e.g. the various MoE architectures coming out recently
//   - So there is immense demand to quickly evolve the software stack to take advantage of new generations or completely new types of hardware e.g. special inference accelerators
//   - Also, it's not just the chip hardware that is evolving, but even the networking stack e.g. the different NVLink generations and what they offer and how that changes certain parts of the programming model
//   - We also get a bunch of secondary tasks that become more difficult with the new hardware---one of which is verification
// - The rapid developments in the AI space, particularly the capabilities of Large Language Models provides an opportunity to tackle this increasing complexity at all levels of the stack from kernel design to even hardware design itself
// - Brief bit on what the verification project I just worked on
// - Brief bit highlighting 2--3 future projects and general PhD direction

The remarkable progress of modern @AI has been driven in large part by a simple observation: increasing model size, training data, and computation tends to produce predictable improvements in capability [C1,C2]. The consequence of empirical scaling laws is an ever-increasing demand for computation as models become larger and are trained and deployed at greater scale.

Meeting this demand through conventional semiconductor improvements alone is becoming increasingly difficult. The gains historically provided by process technology have slowed [C3], while modern @GPU:pla already exploit enormous amounts of parallelism. Increasing parallelism further can provide more aggregate computation, but at the cost of increasing power and infrastructure requirements. Power, cooling, and area are consequently becoming important constraints on @AI training and inference [C4--C6]. The goal is therefore not simply to provide more computation, but to provide more computation given energy, area, and cost constraints, driving increasing specialization of @AI hardware.

This specialization is particularly evident in @ML, where matrix multiplication has become a central computational primitive and a primary target for hardware optimization [C7]. The rise of dedicated accelerators such as Google's @TPU demonstrate the benefits of tailoring hardware to these workloads [C8], while general-purpose @GPU:pla are following the same trend. Across NVIDIA's Ampere, Hopper, Blackwell, and Rubin generations, increasingly specialized support has been introduced for low-precision computation, tensor operations, data movement, sparsity, and inter-@GPU communication [C9--C12]. The broader trend is clear: @AI performance increasingly depends on exploiting hardware mechanisms designed specifically for @ML workloads.

However, specialized hardware also makes the software problem harder. Achieving high performance requires detailed knowledge of the underlying hardware and compiler stack, including memory movement, synchronization, scheduling, and specialized arithmetic units such as Tensor Cores. Moreover, effective optimizations are often tightly intertwined, making the optimization space difficult to navigate [C13,C14]. Each new hardware generation introduces new mechanisms, constraints, and architectural characteristics that must be understood and incorporated into the software stack. Compilers themselves must also continually evolve to expose and exploit new hardware capabilities, introducing an additional delay between what the hardware can provide and what software can readily use. 

This difficulty is compounded by the rapid evolution of @ML workloads. As model architectures, continue to evolve (e.g., @MoE), different computation, memory, and communication patterns [C15] are introduced, while successive generations of accelerators and supporting infrastructure (e.g., interconnect like NVLink) expose new capabilities and programming constraints [C10,C12]. Software must therefore continually adapt to a moving target across both the workloads it executes and the hardware on which it runs.

The resulting complexity affects not only optimization but also verification. For example, modern @GPU programming increasingly relies on asynchronous execution, specialized memory movement, and synchronization mechanisms, creating more opportunities for subtle errors involving data races and ordering. While, formal systems such as GPUVerify have demonstrated the value of automated reasoning about @GPU correctness [C16], recent work continues to show that these problems remain challenging in practice [C17]. Verification must therefore evolve alongside the increasingly sophisticated hardware and software stack.

Recent advances in artificial intelligence, particularly in large language models, offer an opportunity to address this growing complexity. @LLM:pla can generate and transform code, reason over technical artefacts, interact with external tools, and iteratively refine their outputs. This enables agentic systems that can participate in engineering workflows rather than performing isolated code-generation tasks. Early work has demonstrated this potential for @GPU kernel optimization [C14], algorithmic discovery [C18], and even hardware design and verification [C19,C20]. More broadly, this suggests that @AI systems may be able to assist across the stack, from low-level kernel development to compiler and hardware design.

My work during the first year has explored how @LLM agents can be equipped to optimize and verify @GPU kernels. In Glueball, I developed an agentic optimization workflow for Gluon kernels that combines hardware profiling and benchmarking with formal reasoning, allowing theorem-proving tools to provide correctness feedback during optimization and help improve @LLM:pla' formal reasoning capabilities. The resulting hybrid approach combines symbolic execution, @LLM reasoning, and a high-level @GPU semantics model in Z3 to check both functional equivalence and program properties such as asynchronous race freedom and barrier ordering, with counterexamples used to diagnose failures and guide subsequent revisions.

The remainder of the PhD extends this idea across the hardware/software stack. One direction is to integrate theorem proving directly into kernel optimization workflows, using formal guarantees not only to detect errors but to enable more aggressive automated optimization. A second investigates how agents can participate in the co-development of the software and hardware stack, including their ability to understand and reason about compiler intermediate representations; recent work suggests that precise reasoning about @IR semantics remains a significant limitation of current @LLM:pla [C21]. A third explores @AI\-accelerated modelling for hardware design-space exploration, where the scale of modern architectural design spaces makes intelligent search increasingly attractive [C22,C23]. Together, these directions ask how increasingly capable @AI systems can help us design, optimize, and verify the increasingly specialized computing systems required by @AI itself.

#directions[
  *Integrating theorem proving into kernel optimization workflows.*
  #lorem(50)
][
  *Agent integration into (co-)development of the software and hardware stack.*
  #lorem(50)
][
  *AI-accelerated modelling for better design space exploration.*
  #lorem(50)
]


= Background <background>

Classical results on distributed time and ordering @lamport1978time underpin
much of modern consensus theory. More recent machine-learning approaches to
anomaly detection in distributed traces @shalev2014understanding and
attention-based sequence models @vaswani2017attention suggest promising
directions for automatically characterizing partition-induced failure
modes.

== Related Work

Prior work broadly falls into three categories: theoretical impossibility
results, empirical fault-injection studies, and learned failure predictors.

Theoretical work dates back to the FLP impossibility result, which shows
that no deterministic consensus protocol can guarantee both safety and
liveness in a fully asynchronous system where even a single process may
crash. Subsequent work relaxed this model in various ways: partial
synchrony assumptions, randomized protocols, and failure detectors each
recover liveness under different additional assumptions about the network.

Empirical fault-injection studies take a complementary approach, running
real implementations against synthetically induced partitions, message
delays, and node crashes to characterize how systems behave in practice
rather than in the worst case. These studies have repeatedly found that
production systems violate their theoretical guarantees under conditions
that are individually rare but collectively common at scale.

Learned failure predictors are the most recent addition to this landscape,
using traces of past incidents to anticipate partition-induced failures
before they cascade. Early results are promising but rely on labeled
incident data that is scarce and organization-specific, limiting how well
these models transfer across deployments.

== Open Problems

No existing approach jointly optimizes for both liveness under partition
and provable safety guarantees while remaining practical at scale.

A second open problem is evaluation: there is no standard benchmark suite
for partition tolerance, so published results across papers are difficult
to compare directly. Different works use different topologies, partition
schedules, and workloads, making it hard to tell whether a reported
improvement reflects a genuine advance or simply a more favorable
experimental setup.

A third, more practical problem is operability: even a protocol with
strong theoretical guarantees is of limited use if operators cannot
observe, reason about, and recover from a partition while it is happening.
Very little of the literature addresses the operational tooling needed to
make partition tolerance legible to the humans running these systems.

= Thesis proposal
== Thesis chapters
=== Integrating theorem proving into kernel optimization workflows

=== Agent integration into (co-)development of the software and hardware stack
- Can do some work on LLMs' understanding of Intermediate Representations
  - Inspired from #link("https://raw.githubusercontent.com/mlresearch/v267/main/assets/jiang25p/jiang25p.pdf")[this paper]

=== AI-accelerated modelling for better design space exploration

= Methodology <methodology>

Our approach combines a formally specified protocol variant with a
fault-injection test harness.

```python
def inject_partition(nodes, groups, duration_s):
    """Split `nodes` into `groups` for `duration_s` seconds."""
    topology = partition(nodes, groups)
    schedule(topology, duration_s)
    return topology
```

#figure(
  rect(width: 70%, height: 4cm, fill: rgb("#1B2A4A").lighten(85%), stroke: 1pt + rgb("#1B2A4A")),
  caption: [Placeholder plot standing in for a real throughput-vs-partition-rate figure.],
) <fig:placeholder>

As shown in @fig:placeholder, the harness records throughput and latency
across a sweep of partition rates.

= Preliminary Results <results>

Table 1 summarizes early measurements across three protocol variants.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, center, center, center),
    [*Protocol*], [*Nodes*], [*Partition Rate*], [*p99 Latency*],
    [Baseline], [5], [0%], [12ms],
    [Baseline], [5], [20%], [340ms],
    [Proposed], [5], [20%], [96ms],
  ),
  caption: [Preliminary latency comparison across protocol variants.],
)

Early results are encouraging: the proposed variant reduces tail latency
under partition by roughly 3.5x relative to the baseline, though further
runs are needed to establish statistical significance.

= Timeline and Future Work <timeline>

== Year Two

Extend the fault model to include Byzantine nodes and repeat the
experimental sweep at larger cluster sizes.

== Year Three

Write up formal safety proofs and prepare the primary dissertation
publication.
