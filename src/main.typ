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
  ("TMA", "Tensor Memory Accelerator"),
  ("SSM", "State Space Model"),
  ("MIMO", "Multi-Input Multi-Output"),
  ("CTA", "Cooperative Thread Array"),
  ("TMEM", "Tensor Memory"),
  ("HBM4", "High Bandwidth Memory 4"),
  ("MMA", "Matrix Multiply-Accumulate"),
  ("PTX", "Parallel Thread Execution"),
  ("RTL", "Register-Transfer Level"),
  ("FPGA", "Field-Programmable Gate Array"),
  ("ASIC", "Application-Specific Integrated Circuit"),
  ("SoC", "System on a Chip"),
  ("DSE", "Design-Space Exploration"),
  ("PPA", "Power, Performance, and Area"),
  ("MAPE", "Mean Absolute Percentage Error"),
  ("BO", "Bayesian Optimisation"),
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
  date: datetime(year: 2026, month: 10, day: 30),
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

The remarkable progress of modern @AI has been driven in large part by a simple observation: increasing model size, training data, and computation tends to produce predictable improvements in capability @scaling-laws@chinchilla-law. The consequence of empirical scaling laws is an ever-increasing demand for computation as models become larger and are trained and deployed at greater scale.

Meeting this demand through conventional semiconductor improvements alone is becoming increasingly difficult. The gains historically provided by process technology have slowed @computer-architecture-golden-age, while modern @GPU:pla already exploit enormous amounts of parallelism. Increasing parallelism further can provide more aggregate computation, but at the cost of increasing power and infrastructure requirements. Power, cooling, and area are consequently becoming important constraints on @AI training and inference @energy-ai. The goal is therefore not simply to provide more computation, but to provide more computation given energy, area, and cost constraints, driving increasing specialization of @AI hardware.

This specialization is particularly evident in @ML, where matrix multiplication has become a central computational primitive and a primary target for hardware optimization @tpu-MAC. The rise of dedicated accelerators such as Google's @TPU demonstrate the benefits of tailoring hardware to these workloads @domain-specific-accelerators, with general-purpose @GPU:pla following the same trend. Across NVIDIA's Ampere, Hopper, Blackwell, and Rubin generations, increasingly specialized support has been introduced for low-precision computation, tensor operations, data movement, sparsity, and inter-@GPU communication @nvidia-ampere @nvidia-hopper @nvidia-blackwell @nvidia-rubin. The broader trend is clear: @AI performance increasingly depends on exploiting hardware mechanisms designed specifically for @ML workloads.

However, specialized hardware also makes the software problem harder. Achieving high performance requires detailed knowledge of the underlying hardware and compiler stack, including memory movement, synchronization, scheduling, and specialized arithmetic units such as Tensor Cores. Moreover, effective optimizations are often tightly intertwined, making the optimization space difficult to navigate @triton-lang. Each new hardware generation introduces new mechanisms, constraints, and architectural characteristics that must be understood and incorporated into the software stack. Compilers themselves must also continually evolve to expose and exploit new hardware capabilities, introducing an additional delay between what the hardware can provide and what software can readily use. 

This difficulty is compounded by the rapid evolution of @ML workloads. As model architectures, continue to evolve (e.g., @MoE @deepseek-v3), different computation, memory, and communication patterns are introduced, while successive generations of accelerators and supporting infrastructure (e.g., interconnect like NVLink) expose new capabilities and programming constraints. Software must therefore continually adapt to a moving target across both the workloads it executes and the hardware on which it runs.

The resulting complexity affects not only optimization but also verification. For example, modern @GPU programming increasingly relies on asynchronous execution, specialized memory movement, and synchronization mechanisms, creating more opportunities for subtle errors involving data races and ordering. While, formal systems such as GPUVerify have demonstrated the value of automated reasoning about @GPU correctness @gpuverify, recent work continues to show that these problems remain challenging in practice @static-analysis-gpu. Verification must therefore evolve alongside the increasingly sophisticated hardware and software stack.

Recent advances in artificial intelligence, particularly in large language models, offer an opportunity to address this growing complexity. @LLM:pla can generate and transform code, reason over technical artefacts, interact with external tools, and iteratively refine their outputs. This enables agentic systems that can participate in engineering workflows rather than performing isolated code-generation tasks. Early work has demonstrated this potential for @GPU kernel optimization @kernelbench, algorithmic discovery @alphaevolve, and even hardware design @chipnemo @RTLLM. More broadly, this suggests that @AI systems may be able to assist across the stack, from low-level kernel development to compiler and hardware design.

My work during the first year has explored how @LLM agents can be equipped to optimize and verify @GPU kernels. In Glueball, I developed an agentic optimization workflow for Gluon kernels that combines hardware profiling and benchmarking with formal reasoning, allowing theorem-proving tools to provide correctness feedback during optimization and help improve @LLM:pla' formal reasoning capabilities. The resulting hybrid approach combines symbolic execution, @LLM reasoning, and a high-level @GPU semantics model in Z3 @z3 to check both functional equivalence and program properties such as asynchronous race freedom and barrier ordering, with counterexamples used to diagnose failures and guide subsequent revisions.

The remainder of the PhD extends this idea across the hardware/software stack. One direction is to integrate theorem proving directly into kernel optimization workflows, using formal guarantees not only to detect errors but to enable more aggressive automated optimization. A second investigates how agents can participate in the co-development of the software and hardware stack, including their ability to understand and reason about compiler intermediate representations; recent work suggests that precise reasoning about @IR semantics remains a significant limitation of current @LLM:pla @llms-ir-understanding. A third explores @AI\-accelerated modelling for hardware design-space exploration, where the scale of modern architectural design spaces makes intelligent search increasingly attractive @MARL-DSE @chiplet-gym. Together, these directions ask how increasingly capable @AI systems can help us design, optimize, and verify the increasingly specialized computing systems required by @AI itself.

#directions[
  *Integrating theorem proving into kernel optimization workflows.*
  #lorem(50)
][
  *Agentic (co-)development of the software and hardware stack.*
  #lorem(50)
][
  *AI-accelerated modelling for design space exploration.*
  #lorem(50)
]

= Literature Review <sec:literature_review>
- New developments to computer architecture
  - Discuss in detail improvements made to GPUs and future directions
  - New floating-point formats
  - Dedicated hardware for matrix multiplication
  - Asynchronous execution
  - Developments to interconnect e.g. NVLink and TPU donuts, and their hardware/software impact
  - TPUs, and special inference architecture
- New model architecture developments e.g. developments to MoE, Mamba, Flash Attention and how they aim to maximize the most out of the current hardware
- Key point is that we are really centering both software and hardware developments around the matrix multiplication primitive
- Introduce the problem of kernel generation itself---why is it difficult
- Introduce the verification problem
- What work has been done around LLMs understanding/working with the compiler stack
  - LLMs have shown to directly generate assembly
  - Some work on LLMs understanding intermediate representations
- What work has been done around LLMs for hardware design
  - Possibly also try to find some co-design work
- Use of AI in creating (surrogate) models e.g. for faster DSE, or combating limited data

== Model Architecture and Hardware Co-Evolution

=== Model Architectures adapting to Current Hardware

Recent model architectures increasingly adapt their computation to the capabilities of contemporary accelerators. FlashAttention provides a particularly clear example. FlashAttention-3 was designed around Hopper's asynchronous Tensor Cores, @TMA, warp specialization, and FP8 support, restructuring the attention pipeline so that data movement and matrix computation can proceed concurrently @flashattention-3. FlashAttention-4 then redesigns the kernels for Blackwell, whose Tensor Core throughput has increased substantially faster than resources such as the hardware used to evaluate exponentials @flashattention-4. This changes the attention bottleneck: the kernel must focus on reducing the cost of the softmax operation so that less of its work sits on the critical path. Additionally, the exponential evaluation is overlapped with matrix multiplication, and shared-memory traffic reduced. Thus, the same attention algorithm requires a different implementation as the relative capabilities of the underlying hardware change.

State-space models show a similar progression. Mamba-2 reformulated the @SSM computation to expose more matrix-multiplication-friendly structure and thereby make better use of modern @GPU compute units @mamba2. Mamba-3 addresses a different hardware limitation during autoregressive decoding: the recurrent state update is relatively inexpensive in terms of arithmetic but requires repeatedly reading and updating state, leaving a GPU with substantial unused compute capacity @mamba3. Its @MIMO formulation allows several input streams to share the same recurrent state, replacing the rank-1 outer-product update with a hardware-friendly matrix multiplication. This increases the amount of arithmetic performed per unit of state traffic, raising hardware utilization without increasing the size of the persistent state or the decode latency substantially. The model's mathematical formulation is changed for a computational structure more suited to the accelerator.

=== Model Architectures driving Future Hardware Requirements
The relationship between model and accelerator architecture is increasingly bidirectional. New models are beginning to explore execution patterns that are poorly represented by today's dominant accelerator designs, particularly the assumption of regular, dense tensor operations with largely static dataflow. @MoE models make computation and communication input-dependent: only a small subset of experts is activated for each token, but the resulting token routing can produce irregular memory accesses and substantial inter-device communication @moe-communication.

Other directions include recursive and looped Transformers, which make computation depth itself variable, with Mixture-of-Recursions allowing different tokens to undergo different numbers of recursive steps while selectively retaining their state @mixture-of-recursions. Long-context architectures such as Kimi Linear combine recurrent-style state updates with periodic full attention, creating heterogeneous execution within a single layer stack @kimi-linear.

Regarding numerical representation, recent work on fully quantized training is moving beyond using low precision merely as a deployment optimization: FP4 is increasingly being incorporated directly into training @fp4-training, while Blackwell provides native support for NVFP4 computation @quartet-2. The latest Nemotron models combine hybrid Mamba-Attention layers, sparse @MoE, multi-token prediction, and NVFP4 training, illustrating how model architecture, numerical representation, and accelerator capabilities can be designed jointly @nemotron-3-ultra. Taken together, these developments point towards increasingly heterogeneous workload characteristics, which future accelerators may need to cater for.

== Developments in AI Computer Architecture
Modern GPUs have evolved into increasingly heterogeneous accelerators, with specialized hardware targeting coordination of computation, data movement, and communication. NVIDIA's Hopper generation introduced the @TMA, letting kernels initiate transfers between global and shared memory asynchronously, alongside Tensor Cores and @CTA clusters @hopper-tuning-guide. Blackwell extends this approach with dedicated @TMEM for matrix operands and accumulators, and native block-scaled matrix multiplication for low-precision formats @nvidia-blackwell-cutlass. Rubin continues this trajectory with @HBM4, higher-throughput Tensor Cores, and refinements to asynchronous data movement and communication @nvidia-rubin. For example, its enhanced @TMA supports inline descriptor updates, allowing kernels to maintain a unified tensor descriptor for shared layouts, instead of a separate one for each active expert. Rubin also introduces finer-grained producer–consumer triggering allowing tile-level kernel overlap and lower-overhead synchronization for @GPU\-to-@GPU communication.

Numerical representation is another increasingly specialized aspect of accelerator design. NVIDIA's NVFP4 represents each value using four bits, with an FP8 scale shared by each block of 16 values and an additional tensor-wide FP32 scale @nvidia-nvfp4. On Blackwell, supported block-scaled @MMA instructions consume packed low-precision operands alongside their block-scale metadata, applying the scaling factors as part of matrix multiplication rather than requiring software to expand the entire tensor into FP16 or BF16 first. Avant-Garde explores a more general architectural solution for formats with multiple levels of scaling: an Operand Transformer flattens their scaling hierarchies into a common internal representation, which a redesigned Tensor Core can process directly @avant-garde. Its aim is to reduce the instruction and register overhead of supporting diverse scaled formats. Rubin also introduces hardware-accelerated activation compression: NVIDIA's documented attention example converts intermediate scores into a structured 2:4 sparse representation with metadata @nvidia-rubin, exploiting sparsity to reduce data movement and computation.

Asynchronous execution further changes how kernels must be programmed and optimized. @TMA transfers can overlap with computation, while specialized matrix instructions can execute asynchronously and signal completion through hardware synchronization mechanisms. FlashAttention-3 demonstrates how these capabilities can be combined through warp specialization, assigning different warps to data movement and computation, and overlapping matrix multiplication with softmax @flashattention-3. However, exploiting this hardware requires careful scheduling: programmers and compilers must choose pipeline depth, buffer counts, tile sizes, producer–consumer roles, and synchronization points while balancing overlap against shared-memory, register, and occupancy constraints. Recent work on optimal software pipelining and warp specialization uses solver-based scheduling to find effective configurations across Hopper and Blackwell, illustrating how difficult it is to derive good schedules from hardware features alone @twill-software-pipelining. Each new generation therefore expands not only the available performance, but also the space of hardware-dependent decisions that software must make.

At the system level, interconnect topology and communication scheduling are increasingly important. These topologies influence how distributed workloads are partitioned and how devices exchange data. In tensor parallelism, for example, devices share input shards or partial results through collectives such as all-gather and reduce-scatter. MeshSlice jointly optimizes mesh shape, matrix dataflow, and communication granularity, using an autotuner to find configurations that overlap smaller transfers with computation @meshslice. Distributed performance therefore depends not only on accelerator count and link bandwidth, but also on how computation and communication are mapped and scheduled across the network.

== Using LLMs to Improve the Software and Hardware Stack

@LLM:pla offer opportunities to improve @AI systems beyond model development, by automating parts of the software and hardware infrastructure on which those systems run. Recent work examines whether they can understand compiler representations, discover optimisation strategies, generate compiler components, and design workload-specific accelerators. This section reviews these directions and the challenges that remain in developing reliable agents for developing the software and hardware stack.

=== LLMs for Compiler Optimisation and Construction

Compilers are built around carefully engineered @IR:pla, optimisation passes, and target-specific lowering pipelines, so a prerequisite for any @LLM\-based compiler tooling is the ability to reason about @IR. #cite(<llms-ir-understanding>, form:"prose") test this across control-flow graph reconstruction, decompilation, summarisation, and execution reasoning. They find that models recover high-level structure but struggle with instruction-level semantics, particularly branches, loops, and dynamic execution. This is a significant weakness, since optimisation correctness depends on exactly these details. One response is specialisation: LLM Compiler @llm-compiler trains foundation models on LLVM @IR and assembly, improving code-size optimisation and disassembly back into @IR.

The most convincing results arise where the @LLM works inside an existing compiler rather than in place of it. VEGA @vega generates target-specific backends from target descriptions, reducing the effort of retargeting. Magellan @magellan couples an @LLM coding agent with evolutionary search, building on AlphaEvolve @alphaevolve, to synthesise heuristics for existing passes. Its heuristics outperform expert-designed ones for LLVM function inlining and match the hand-tuned policy for register allocation. Crucially, a heuristic only decides _when_ a transformation is applied, while the surrounding pass still guarantees correctness. A poor heuristic therefore costs performance, but cannot miscompile a program.

Without a safety net, models struggle with preserving program semantics and correctness. PeepholeBench @peepholebench asks coding agents to implement real missed optimisations in LLVM's `InstCombine` pass, and finds that no agent matches human developers on both correctness and performance. CIRBench @cirbench reaches a similar conclusion for models that rewrite @IR directly. Individual transformations sometimes achieve considerable speedups, yet models fail on many instances and underperform the compiler at the median. The pattern is one of high variance: occasional wins beyond the compiler's reach, but no dependable baseline.

The most radical proposals remove compiler stages altogether. AI as a Compiler @ai-as-compiler uses an @LLM agent to translate Triton @triton-lang kernels directly into NVIDIA @PTX, achieving between 0.83× and 3.34× the performance of autotuned Triton. The largest gains come from transformations that Triton's lowering pipeline does not perform, which suggests that direct generation can exploit hardware features before a compiler supports them. Notably, the approach depends on a formal @PTX verifier, Volta @volta, which the authors had to extend to model recent Tensor Core interfaces. QiMeng-NeuComBack @neural-compilation similarly studies direct @IR\-to-assembly generation, using iterative prompt refinement to improve functional correctness. In both cases correctness remains the limiting factor.

=== LLMs for Hardware Design and Exploration

@LLM:pla have also been applied to hardware design. Rather than simply focussing on @RTL generation, many systems explore a structured design space encompassing parallelism, dataflow, and memory organisation. @LLM\-DSE @llm-dse, for example, uses collaborating agents to optimise high-level synthesis directives, while SECDA-DSE @secda integrates @LLM\-guided exploration with @FPGA synthesis and execution.

More ambitious work attempts to generate hardware around a particular algorithm. Design Conductor 2.0 @design-conductor-2 describes VerTQ, an inference accelerator designed specifically for the TurboQuant vector-quantisation algorithm. The authors report mapping the generated design to an @FPGA and estimating its area in a target @ASIC process. It illustrates a shift from optimising within a predefined architecture to generating specialised hardware that reflects an algorithm's computational requirements.

=== Early Work on Hardware–Software Co-Design

Hardware and software decisions are interdependent: a specialised hardware feature is valuable only if software can exploit it, while algorithmic demands determine which architectural capabilities are worth building. Optimising either side independently can therefore miss the best designs, and recent work has begun to address the joint problem. MACO @maco uses multiple agents to generate and iteratively refine coarse-grained reconfigurable array architectures together with their software mapping. HSCO-Bench @hsco-bench evaluates a broader end-to-end workflow: analysing an application, integrating accelerators into a @SoC, and mapping software kernels onto them, with prototypes deployed on an @FPGA. Only two of five frontier models produced valid prototypes. Even these left most of the available hardware resources unused, despite a peak speedup of 16.22×, which suggests that agents stop at the first working design rather than exploring the trade-off space.

Co-design thus compounds the difficulties seen in each domain: a larger search space, more complex toolchains, and expanded failure modes. Current results demonstrate early progress, but not general autonomous co-design across arbitrary workloads and platforms. Across all three areas, @LLM:pla are most dependable when proposing candidates that established tools can check, and least dependable when they must guarantee correctness and construct novel software and hardware mechanisms themselves.

== AI-Based Performance Modelling for Hardware-Software Co-Design

Exploring accelerator designs requires evaluating many combinations of hardware parameters, workloads, and compiler mappings. However, detailed performance evaluation through execution, simulation, or synthesis can be expensive, limiting the number of configurations that can be explored. @AI\-based performance models address this problem by learning to predict execution time, resource utilisation, or hardware implementation costs, allowing @DSE to focus expensive evaluations on promising candidates. Recent work has increasingly targeted not only prediction accuracy, but also the ability to transfer knowledge across hardware platforms and learn from fewer measurements.

In compiler optimisation, learned cost models estimate the performance of candidate schedules, reducing the need to execute every program generated during autotuning. Recent models increasingly represent the structure of compiler decisions explicitly. SA-Cost @SACost uses attention to model relationships between scheduling primitives, rather than treating a tensor program as an undifferentiated feature vector. However, its evaluation focuses on tensor-program tuning, leaving its generalisation to substantially different hardware and low-level @GPU execution behaviour to be established. UniCoX @UniCoX extends this direction by aligning schedule and hardware features to support cost prediction across heterogeneous accelerators. Its authors report an 11.3× reduction in search time within the evaluated MetaSchedule framework, although transfer to previously unseen architectures remains an important question. TCL @TCL addresses the expense of collecting training data more directly: it combines active selection of representative, diverse, and uncertain samples with a Mamba-based cost model and continual knowledge distillation across platforms. It reports using only 10% of the programs for data collection and substantially faster tuning than a TenSet-MLP baseline. Together, these approaches illustrate a shift towards models that encode compiler structure and reuse information across targets; nevertheless, their reported results do not establish that the models will accurately predict the effects of architecture-specific instructions, synchronisation, and memory pipelines on an unfamiliar @GPU.

Learned models are also being applied to hardware implementation costs. Conventional approaches can estimate @PPA from structured representations of @RTL designs, but may require representative training examples from the design family of interest. LLMulator @LLMulator explores a different approach by using a pretrained @LLM as a numerical cost model for dataflow accelerators. It predicts implementation metrics and execution cycles, using input-adaptive calibration and data augmentation to improve generalisability across workloads and hardware configurations. The authors report a @MAPE of 12.2% across their evaluated @ASIC scenarios. This demonstrates that @LLM:pla can be used as performance predictors rather than solely as code generators. However, the results concern a particular class of dataflow accelerators and should not be taken as evidence that an @LLM can predict performance reliably for arbitrary @GPU architectures.

A related challenge is making the search itself data-efficient. Multi-fidelity methods combine inexpensive approximate evaluations with a smaller number of costly measurements, such as @RTL simulation. Polaris @Polaris provides an example: its learned Starlight model transfers information from analytical estimates to higher-fidelity simulation results, and its search procedure uses the model to explore hardware-software configurations more quickly. More recent work integrates @LLM:pla into this optimisation loop. Trust-aware @LLM\-assisted Bayesian optimisation @TrustAwareBO combines @LLM guidance with a statistical surrogate and a trust-control mechanism, using the @LLM to inform the search while retaining measured evaluations to guide candidate selection. Its evaluation covers a configurable digital baseband generator and a systolic-array neural processing unit; whether this combination generalises to broader accelerator families remains open.

Recent @GPU\-specific work also connects performance prediction directly to kernel optimisation. Mapo @Mapo combines a model of @GPU memory-access behaviour with an @LLM\-based optimisation loop, using predicted performance metrics as feedback to guide memory-oriented code transformations. This illustrates how learned models can provide quantitative feedback that is cheaper than repeatedly profiling each generated candidate. More broadly, these approaches suggest an opportunity to model the interaction between a kernel, its compiler mapping, and the target hardware rather than modelling the software or hardware in isolation. For custom @GPU design, such a model could combine inexpensive analytical or emulated evaluations with selectively collected simulation results, while using active learning to decide which candidates merit expensive evaluation. Success should therefore be measured not only by prediction error, but also by the quality of the designs found under a fixed evaluation budget and by generalisation to unseen workloads and hardware configurations.

= Background <sec:background>

Classical results on distributed time and ordering  underpin
much of modern consensus theory. More recent machine-learning approaches to
anomaly detection in distributed traces  and
attention-based sequence models  suggest promising
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

= Methodology <sec:methodology>

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
