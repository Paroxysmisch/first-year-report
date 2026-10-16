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
  ("BO", "Bayesian Optimization"),
  ("ISA", "Instruction Set Architecture"),
  ("RL", "Reinforcement Learning"),
)

#let yes = text(fill: rgb("#1a7f37"), sym.checkmark)
#let no = text(fill: rgb("#b42318"), sym.crossmark)

// Gap-analysis table: one column per feature, one row per prior work, and the
// proposed work as the last row (ticked in every column).
#let feature-table(features, rows, ours) = {
  set text(size: 7pt)
  set par(justify: false)
  let mark(b) = if b { yes } else { no }
  table(
    columns: (2.3fr,) + (1fr,) * features.len(),
    align: (x, y) => if x == 0 { left + horizon } else { center + horizon },
    inset: 3pt,
    stroke: none,
    table.hline(),
    table.header([*Work*], ..features.map(f => text(weight: "bold", f))),
    table.hline(stroke: 0.5pt),
    ..rows.map(r => (r.at(0), ..r.slice(1).map(mark))).flatten(),
    table.hline(stroke: 0.5pt),
    text(weight: "bold", ours), ..features.map(_ => yes),
    table.hline(),
  )
}

#show: report.with(
  title: [ Automating Machine Learning #linebreak() Systems Development ],
  // title: [ Automating Machine Learning #linebreak() Systems Development: Optimising Kernels, Building Compilers and Designing Hardware ],
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

== Automated Kernel Optimization and Verification

@LLM:pla are increasingly being used to generate and optimize @GPU and accelerator kernels, with recent approaches moving beyond single-shot code generation towards iterative search driven by compilation, correctness tests, and profiling feedback. KernelBench @kernelbench established a common evaluation setting for comparing generated kernels against PyTorch reference implementations, while TritonGym @TritonGym extends this setting to multi-step agentic workflows, including extensions to the Triton programming model.

Recent systems explore different ways to improve the generation process: EGG @EGG incorporates expert optimization principles into a staged workflow that separates algorithmic structure design from hardware-specific tuning; Dr. Kernel @DrKernel trains a Triton kernel generator using reinforcement learning with execution-based and profiling-based rewards; and KernelBand @KernelBand treats optimization as a search problem, using hardware-aware pruning and multi-armed bandits to balance exploration and exploitation. KernelFoundry @KernelFoundry instead combines evolutionary search over candidate kernels with prompt optimization and parameter tuning, while StitchCUDA @StitchCUDA extends generation from isolated kernels to end-to-end GPU programs that account for host-side decisions and kernel fusion. Beyond established GPU programming environments, KernelCraft @KernelCraft evaluates whether agents can generate and optimize low-level kernels for accelerators with unfamiliar @ISA:pla.

These systems make correctness testing an important part of the generation loop, but passing a finite set of tests does not establish that a kernel is correct for all valid inputs. Tests may miss errors involving boundary conditions, asynchronous code, or interactions between threads. However, test-based feedback provides limited coverage, and models may exploit flaws in the evaluation procedure to obtain apparent speedups without correctly implementing the intended computation, a failure mode known as reward hacking. Formal verification offers stronger guarantees by checking properties over a defined class of program behaviours rather than only the tested executions. The required properties differ: memory safety and data-race freedom rule out particular classes of invalid executions, synchronization verification checks whether threads coordinate correctly, and functional equivalence establishes that an optimized implementation preserves the behaviour of its reference.

GPUVerify @gpuverify established a static verification approach for CUDA and OpenCL kernels, checking data races and barrier divergence by reducing parallel-kernel verification to sequential reasoning. WEFT @WEFT extends formal reasoning to warp-specialized GPU programs that use producer-consumer synchronization through named barriers, addressing errors that arise from more complex synchronization patterns. More recently, #cite(<static-analysis-gpu>, form: "prose") introduce FaialAA, a static data-race detector for GPU programs that establishes a True Positive Theorem: for programs satisfying specific conditions, every reported warning corresponds to a genuine data race. These methods address specific safety and concurrency properties rather than generally proving that an optimized kernel computes the same result as its reference.

Other approaches aim for stronger functional guarantees. Kuiper @Kuiper provides a GPU programming language embedded in F\*, using dependent types and concurrent separation logic to prove memory safety, data-race freedom, and functional correctness. It demonstrates verified kernels including tiled matrix multiplication using tensor cores, with performance competitive with handwritten CUDA implementations. Rather than requiring kernels to be written in a verification-oriented language, VOLTA @volta performs post-hoc equivalence checking on GPU kernels represented in NVIDIA @PTX. It checks whether a candidate preserves the reference computation by formally comparing their outputs, supporting kernels with statically known array sizes, loop bounds, and memory accesses, but excluding recursion and control flow or memory accesses that depend on runtime inputs.

Recent work has also begun to use LLMs to reduce the effort of applying formal verification to generated kernels. ProofWright @ProofWright is an agentic framework that combines LLM-generated verification annotations with existing formal tools. For memory and thread safety, an LLM agent helps construct annotations for VerCors, which checks the resulting proof obligations. For semantic equivalence, a separate workflow derives specifications from PyTorch reference code and uses the Rocq theorem prover to establish correctness for a supported class of kernels. ProofWright is limited by the CUDA features supported by its underlying verifier, VerCors, which currently lacks support for modern tensor-core instructions such as `mma` and `wgmma`. Furthermore, semantic-equivalence verification requires the CUDA kernel's computation to be represented in Rocq and related specifications to be lowered into VerCors annotations, introducing an additional translation step whose correctness must be established.

Together, these works expose a gap between the rapid generation of optimized kernels and the guarantees available for their correctness. Existing generation systems largely rely on compilation, tests, and performance measurements, while formal methods either target particular safety properties, require a verification-oriented programming model, or support a defined class of kernels. LLMs can help construct specifications and annotations, but the resulting guarantees still depend on the underlying verification tools and their supported semantics. Integrating such checks into iterative kernel optimization offers a way to detect errors beyond those exposed by testing, while returning actionable counterexamples to guide subsequent revisions.

== Using LLMs to Improve the Software and Hardware Stack

@LLM:pla offer opportunities to improve @AI systems beyond model development, by automating parts of the software and hardware infrastructure on which those systems run. Recent work examines whether they can understand compiler representations, discover optimization strategies, generate compiler components, and design workload-specific accelerators. This section reviews these directions and the challenges that remain in developing reliable agents for developing the software and hardware stack.

=== LLMs for Compiler Optimization and Construction

Compilers are built around carefully engineered @IR:pla, optimization passes, and target-specific lowering pipelines, so a prerequisite for any @LLM\-based compiler tooling is the ability to reason about @IR. #cite(<llms-ir-understanding>, form:"prose") test this across control-flow graph reconstruction, decompilation, summarisation, and execution reasoning. They find that models recover high-level structure but struggle with instruction-level semantics, particularly branches, loops, and dynamic execution. This is a significant weakness, since optimization correctness depends on exactly these details. One response is specialisation: LLM Compiler @llm-compiler trains foundation models on LLVM @IR and assembly, improving code-size optimization and disassembly back into @IR.

The most convincing results arise where the @LLM works inside an existing compiler rather than in place of it. VEGA @vega generates target-specific backends from target descriptions, reducing the effort of retargeting. Magellan @magellan couples an @LLM coding agent with evolutionary search, building on AlphaEvolve @alphaevolve, to synthesise heuristics for existing passes. Its heuristics outperform expert-designed ones for LLVM function inlining and match the hand-tuned policy for register allocation. Crucially, a heuristic only decides _when_ a transformation is applied, while the surrounding pass still guarantees correctness. A poor heuristic therefore costs performance, but cannot miscompile a program.

Without a safety net, models struggle with preserving program semantics and correctness. PeepholeBench @peepholebench asks coding agents to implement real missed optimizations in LLVM's `InstCombine` pass, and finds that no agent matches human developers on both correctness and performance. CIRBench @cirbench reaches a similar conclusion for models that rewrite @IR directly. Individual transformations sometimes achieve considerable speedups, yet models fail on many instances and underperform the compiler at the median. The pattern is one of high variance: occasional wins beyond the compiler's reach, but no dependable baseline.

The most radical proposals remove compiler stages altogether. AI as a Compiler @ai-as-compiler uses an @LLM agent to translate Triton @triton-lang kernels directly into NVIDIA @PTX, achieving between 0.83× and 3.34× the performance of autotuned Triton. The largest gains come from transformations that Triton's lowering pipeline does not perform, which suggests that direct generation can exploit hardware features before a compiler supports them. Notably, the approach depends on a formal @PTX verifier, Volta @volta, which the authors had to extend to model recent Tensor Core interfaces. QiMeng-NeuComBack @neural-compilation similarly studies direct @IR\-to-assembly generation, using iterative prompt refinement to improve functional correctness. In both cases correctness remains the limiting factor.

=== LLMs for Hardware Design and Exploration

@LLM:pla have also been applied to hardware design. Rather than simply focussing on @RTL generation, many systems explore a structured design space encompassing parallelism, dataflow, and memory organisation. @LLM\-DSE @llm-dse, for example, uses collaborating agents to optimise high-level synthesis directives, while SECDA-DSE @secda integrates @LLM\-guided exploration with @FPGA synthesis and execution.

More ambitious work attempts to generate hardware around a particular algorithm. Design Conductor 2.0 @design-conductor-2 describes VerTQ, an inference accelerator designed specifically for the TurboQuant vector-quantisation algorithm. The authors report mapping the generated design to an @FPGA and estimating its area in a target @ASIC process. It illustrates a shift from optimising within a predefined architecture to generating specialised hardware that reflects an algorithm's computational requirements.

=== Early Work on Hardware–Software Co-Design

Hardware and software decisions are interdependent: a specialised hardware feature is valuable only if software can exploit it, while algorithmic demands determine which architectural capabilities are worth building. Optimising either side independently can therefore miss the best designs, and recent work has begun to address the joint problem. MACO @maco uses multiple agents to generate and iteratively refine coarse-grained reconfigurable array architectures together with their software mapping. HSCO-Bench @hsco-bench evaluates a broader end-to-end workflow: analysing an application, integrating accelerators into a @SoC, and mapping software kernels onto them, with prototypes deployed on an @FPGA. Only two of five frontier models produced valid prototypes. Even these left most of the available hardware resources unused, despite a peak speedup of 16.22×, which suggests that agents stop at the first working design rather than exploring the trade-off space.

Co-design thus compounds the difficulties seen in each domain: a larger search space, more complex toolchains, and expanded failure modes. Current results demonstrate early progress, but not general autonomous co-design across arbitrary workloads and platforms. Across all three areas, @LLM:pla are most dependable when proposing candidates that established tools can check, and least dependable when they must guarantee correctness and construct novel software and hardware mechanisms themselves.

== AI-Based Performance Modelling for Hardware-Software Co-Design

Exploring accelerator designs requires evaluating many combinations of hardware parameters, workloads, and compiler mappings. However, detailed performance evaluation through execution, simulation, or synthesis can be expensive, limiting the number of configurations that can be explored. @AI\-based performance models address this problem by learning to predict execution time, resource utilisation, or hardware implementation costs, allowing @DSE to focus expensive evaluations on promising candidates. Recent work has increasingly targeted not only prediction accuracy, but also the ability to transfer knowledge across hardware platforms and learn from fewer measurements.

Learned cost models guide compiler autotuning by predicting the performance of candidate schedules. SA-Cost @SACost uses attention to capture interactions between scheduling decisions, while UniCoX @UniCoX aligns schedule and hardware features to support tuning across heterogeneous accelerators. TCL @TCL combines a Mamba-based cost model with active sampling and continual knowledge distillation across platforms. However, these works do not establish how well such models generalise to low-level @GPU kernels whose performance depends on architecture-specific features, such as asynchronous memory pipelines.

Learned models are also being applied to hardware implementation costs. Conventional approaches can estimate @PPA from structured representations of @RTL designs, but may require representative training examples from the design family of interest. LLMulator @LLMulator explores a different approach by using a pretrained @LLM as a numerical cost model for dataflow accelerators. It predicts implementation metrics and execution cycles, using input-adaptive calibration and data augmentation to improve generalisability across workloads and hardware configurations. The authors report a @MAPE of 12.2% across their evaluated @ASIC scenarios. This demonstrates that @LLM:pla can be used as performance predictors rather than solely as code generators.

A related challenge is making the search itself data-efficient. Multi-fidelity methods combine inexpensive approximate evaluations with a smaller number of costly measurements, such as @RTL simulation. Polaris @Polaris combines multi-fidelity modelling with @BO. Its Starlight model first learns a representation of hardware/software configurations from inexpensive analytical-model estimates, then transfers this representation to a predictor trained on a smaller set of RTL-simulation results. The resulting model guides the search towards promising configurations while reserving expensive RTL evaluations for selected candidates.

More recent work integrates @LLM:pla into this optimization loop. Trust-aware @LLM\-assisted Bayesian optimization @TrustAwareBO incorporates @LLM guidance at several stages of the search, including the choice of initial designs, the construction of the performance prediction model, and the selection of candidates for evaluation. The @LLM has greater influence early in the search, when few measurements are available, while the process increasingly relies on measured results as more data is collected. Experiments demonstrate faster convergence and better trade-offs between design objectives than more traditional @BO methods.

Performance prediction has also been integrated into kernel optimization. Mapo @Mapo combines a multi-modal model of @GPU memory-access behavior with an @LLM\-based optimization loop, using predicted performance metrics as feedback to guide memory-oriented code transformations. This illustrates how learned models can provide quantitative feedback that is cheaper than repeatedly profiling each generated candidate. More broadly, these approaches suggest an opportunity to model the interaction between a kernel, its compiler mapping, and the target hardware rather than modelling the software or hardware in isolation. For custom accelerator design, such a model could combine inexpensive analytical or emulated evaluations with selectively collected simulation results, while using active learning to decide which candidates merit expensive evaluation. Success should therefore be measured not only by prediction error, but also by the quality of the designs found under a fixed evaluation budget and by generalisation to unseen workloads and hardware configurations.

= Thesis proposal
- Briefly repeat the core problems 1) Model architectures are evolving quickly 2) Hardware is also evolving quickly to help accelerate both training and inference of these models
- The idea is that there is a spectrum/pipeline of sorts from the kernel generation through to the compiler through to hardware design
  - At each stage, there is a lot manual effort
  - The overall thesis is addressing some of the bottlenecks in these stages, paving the way for end-to-end machine learning model and hardware co-design
- Three chapters to the thesis:
  - Integrating theorem proving into kernel optimization workflows
  - Agent integration into (co-)development of the software and hardware stack
  - AI-accelerated modelling for better design space exploration
- First chapter
  - Quickly introduce that we need a lot of new kernels for the new model architectures and hardware architectures, and so we want to use LLMs to address this by automatically generating kernels
  - However, LLMs can make mistakes so we want some sort of verification that goes beyond just randomized input testing
  - Refer to the work we looked at for this verification
    - There are a few areas of improvement for these works
    - Each proving approach *has* to make some simplifications, but some modelling assumptions are too limiting
    - Often, newer hardware features, especially a lot of asynchronous hardware stuff, is simply not modelled
    - Some require writing stuff in a dedicated theorem proving language
    - Others have limitations of only being able to model kernels with statically known inputs, and cannot handle dynamic control flow
    - Some other limitations...
    - Integration into the actual optimization flow is often missing
  - Glueball addresses these allowing asynchronous feature modelling in NVIDIA's Hopper and Blackwell, as well as working with dynamic control flow/inputs, and integrates well into the optimization flow
    - However, it has a few limitations 1) No guarantees are provided by it---the theorem prover is just another tool for the LLM, so the output cannot be 100% trusted e.g. we rely on the LLM to convert from Gluon to Z3, and this translation itself may be incorrect
  - My follow-up work using separation logic on PTX will help address this
    - The LLM then just comes-up with pre-/post-conditions and proof invariants etc.
    - Much higher confidence in the output as don't rely on translation into a theorem prover language by an LLM---separation logic allows us to just annotate around the PTX, given we have a semantics model
    - We also get the benefits of using separation logic over other SMT based approaches e.g. Z3 (need to expand on this)
  - Other improvements to the optimization itself too
    - Sometimes, we need optimization to tweak parameters like pipeline depth, etc. This is not strictly optimizing writing the kernel, but making decisions on kernel hyperparameters given hardware knowledge
    - We can build on work using BO + LLMs to embed LLM hardware knowledge into the search process, and still get confidence + other benefits of BO---this is also much faster to iterate that having the LLM agents manually make these small tweaks to the kernel
    - Some other directions to take automated kernel generation in (some research needed)
- Second chapter
  - Instead of only targeting single kernels/models, can we actually improve the compiler infrastructure itself with LLMs---that way, we can get an entire family of optimized kernels
  - Quite limited work in this field
  - Refer to paper using alphaevolve, but it is limited in a few ways---I think the LLM only proposes heurisitcs, not optimizations, and also humans pre-choose what heuristics they want to focus on
  - This could be automated end-to-end
  - More research needed to find limitations to address here too
- Third chapter
  - Would be cool to do some DSE using some simulators out there e.g. AI GPU cluster networking simulator
  - Could even create neural approximations to the simulators
  - Want some possible modelling papers to speed-up simulations with neural techniques, or LLM-assisted search
  - Look at the literature review to explore ideas

Continued progress in @AI depends on advances in both the software and hardware used to run it. New model architectures, modalities, and training methods can only deliver their full potential when supported by efficient kernels, effective compiler support, and suitable hardware, the development of which remains heavily reliant on specialist expertise. These components lie along a software-hardware spectrum and form the three main areas of this thesis: (1) kernel generation and optimization, (2) compiler development, and (3) hardware design. @fig:spectrum illustrates where this thesis directs its automation efforts within each area, with the long-term goal of enabling automated, end-to-end software–hardware co-design.

#figure(
  {
    set text(size: 8.5pt)
    set par(justify: false, leading: 0.5em)

    let c-kern = rgb("#2563eb")
    let c-comp = rgb("#7c3aed")
    let c-hw = rgb("#c2410c")
    let spectrum = gradient.linear(c-kern, c-comp, c-hw)
    let spectrum-light = gradient.linear(
      c-kern.lighten(88%), c-comp.lighten(88%), c-hw.lighten(88%),
    )

    // Horizontal double-headed arrow filled with the spectrum gradient.
    let head(dir) = polygon(
      fill: if dir == "left" { c-kern } else { c-hw },
      ..if dir == "left" { ((0pt, 3.5pt), (7pt, 0pt), (7pt, 7pt)) }
        else { ((0pt, 0pt), (7pt, 3.5pt), (0pt, 7pt)) },
    )
    let axis = grid(
      columns: (auto, auto, 1fr, auto, auto),
      align: horizon,
      column-gutter: 0pt,
      text(weight: "bold", fill: c-kern)[Software#h(6pt)],
      head("left"),
      rect(width: 100%, height: 2.5pt, fill: spectrum, stroke: none),
      head("right"),
      text(weight: "bold", fill: c-hw)[#h(6pt)Hardware],
    )

    // One stage of the spectrum.
    let stage(col, title, chapter, items, height: auto) = block(
      width: 100%,
      height: height,
      inset: (x: 7pt, y: 7pt),
      radius: 4pt,
      fill: col.lighten(90%),
      stroke: 0.8pt + col,
      {
        align(center)[
          #text(weight: "bold", fill: col.darken(25%), size: 9pt, title) \
          #text(fill: col.darken(10%), size: 7.5pt, style: "italic", chapter)
        ]
        v(2pt)
        set align(left)
        set list(marker: text(fill: col)[•], spacing: 0.45em, indent: 0pt, body-indent: 4pt)
        items
      },
    )

    let chevron(col) = text(fill: col, size: 14pt, weight: "bold")[›]

    let stage-specs = (
      (c-kern, [Algorithms & Kernels], [Chapter 1], [
        - Optimizing @ML model operations and architectures
        - Correctness of optimisations
      ]),
      (c-comp, [Compiler Infrastructure], [Chapter 2], [
        - Lowering kernels onto new hardware targets
        - Exposing new hardware features to software
      ]),
      (c-hw, [Hardware design], [Chapter 3], [
        - Performance modelling and simulation
        - @DSE:l
      ]),
    )

    // Equal-height stage boxes: measure each at its final width, use the tallest.
    let chev-w = 10pt
    let gutter = 3pt
    let stages = layout(size => {
      let w = (size.width - 2 * chev-w - 4 * gutter) / 3
      let h = calc.max(..stage-specs.map(s => measure(block(width: w, stage(..s))).height))
      let boxes = stage-specs.map(s => stage(..s, height: h))
      grid(
        columns: (1fr, chev-w, 1fr, chev-w, 1fr),
        column-gutter: gutter,
        align: (x, y) => if calc.odd(x) { horizon + center } else { top },
        boxes.at(0), chevron(c-comp), boxes.at(1), chevron(c-hw), boxes.at(2),
      )
    })

    // Co-design goal spanning the whole spectrum.
    let goal = block(
      width: 100%,
      inset: (x: 8pt, y: 6pt),
      radius: 4pt,
      fill: spectrum-light,
      stroke: (paint: spectrum, thickness: 0.8pt),
      align(center)[
        #text(weight: "bold")[Goal:] automated, end-to-end software–hardware co-design
      ],
    )

    stack(
      dir: ttb,
      spacing: 6pt,
      axis,
      stages,
      goal,
    )
  },
  caption: [The spectrum of software-hardware development considered in this
    thesis. Each chapter focuses on increasing the level of automation at one stage, working
    towards automated end-to-end co-design.],
) <fig:spectrum>

== Agentic Kernel Optimization and Verification

@LLM agents can now write and optimise kernels for both @GPU:pla and emerging accelerators, using compiler, profiler and benchmarking feedback to search for faster implementations @kernelbench @TritonGym @KernelFoundry @DrKernel @KernelCraft. However, verification of these generated kernels has received far less attention. Most systems accept a kernel if its outputs match a reference, within a tolerance, on a small set of random inputs. Random inputs rarely reach the cases where kernels actually fail, for example on tensor values with extreme magnitudes, catastrophic cancellation, or reduced-precision accumulation.

The problem is worse on modern asynchronous hardware. On Hopper and Blackwell, specialised producer and consumer warps coordinate @TMA transfers, asynchronous tensor-core operations and memory barriers, so correctness can depend on thread interleavings that a test run may never produce. The consequences are measurable. Under hardened evaluation, the best frontier model's geometric-mean speedup over PyTorch falls from 1.43× to 0.88× @kernelbench-verified, and SOL-ExecBench flags 14.5% of agent submissions as reward hacking @sol-execbench.

Existing work on @GPU kernel verification covers parts of this problem, but none of it covers modern optimised kernels (@tab:ch1-gap). GPUVerify @gpuverify and Faial @static-analysis-gpu detect data races and barrier errors soundly, but they check safety rather than functional correctness and predate asynchronous hardware. GKLEE @gklee and ESBMC-GPU @esbmc-gpu apply symbolic execution and bounded model checking to CUDA, but they predate tensor cores and their verification times scale poorly. VOLTA @volta checks the equivalence of @ML kernels, but it requires static shapes, compares a single @CTA, excludes asynchronous primitives and models tensor elements as reals. Kuiper @Kuiper proves functional correctness, but only for kernels rewritten in F\*, and ProofWright's agentic verification @ProofWright does not support `mma` or `wgmma`. Fuzzing avoids these restrictions but prior work's effectiveness depends on a hand-chosen input generation strategy @kernel-test-input-generation. Treating floating-point values as reals is particularly risky, because tensor-core arithmetic differs between architectures. For example, FP8 accumulation keeps 13 fractional bits on Hopper but 25 on Blackwell @mma-sim, so a kernel that is accurate on one @GPU can be wrong on the next.

#figure(
  feature-table(
    ([Functional Equivalence], [Async Ops], [Symbolic Execution], [Bit-Accurate FP], [Thread Interleavings], [Hardware-Validated Witnesses], [Unmodified Kernels], [In opt. loop]),
    (
      ([GPUVerify, Faial], false, false, true, false, true, false, true, false),
      ([GKLEE, ESBMC-GPU], false, false, false, false, true, false, true, false),
      ([VOLTA], true, false, false, false, false, false, true, false),
      ([Kuiper], true, false, true, false, true, false, false, false),
      ([ProofWright], true, false, true, false, true, false, true, false),
      ([KernelBench-Verified], true, true, false, false, false, true, true, false),
      ([Adversarial fuzzing], true, true, false, false, false, false, true, false),
      ([*Glueball (Year 1)*], true, true, true, false, true, true, true, true),
    ),
    [Proposed inequivalence checker],
  ),
  caption: [Gap analysis for Chapter 1: features of prior work on @GPU:s kernel correctness.],
  placement: top,
) <tab:ch1-gap>

In my first year, I worked on Glueball, which integrates formal reasoning tools into an agentic optimization loop for Gluon kernels. Gluon is a tile-level programming language in the Triton ecosystem that exposes low-level hardware features such as @TMA and warp specialization. Glueball uses agents to optimize kernels across an AI model, targeting end-to-end performance while requiring every candidate to pass a correctness pipeline before acceptance. This pipeline symbolically executes supported Triton @IR operations using Z3 and provides agents with a Gluon-to-Z3 library for reasoning about hardware properties, including asynchronous race freedom, barrier ordering, and memory-bank behavior. Agents can use these tools to investigate candidate kernels and generate counterexamples when they identify potential correctness violations.

Although Glueball improves both the precision and recall of bug detection, particularly for kernels that use modern asynchronous hardware features, its approach leaves important questions about trust and soundness. A central challenge in kernel equivalence checking is balancing the complexity of the behavior being modelled against the size of the trusted computing base. Glueball's approach requires trusting not only the Gluon-to-Z3 semantic models, but also the LLM's translation of Gluon programs into Z3 representations. This flexibility enables reasoning about complex hardware behavior, but an inaccurate translation can cause the resulting analysis to diverge from the actual kernel semantics, potentially allowing incorrect kernels to be accepted or causing correct kernels to be rejected.

I propose to investigate an alternative approach based on _inequivalence checking_. Rather than relying on an LLM to construct a formal representation of the kernel for verification, the project would use adversarial agents to search for inputs that cause a reference kernel and its optimized counterpart to produce different results. The agents would have access to a broad suite of tools, including theorem provers, fuzzers, debuggers, and static and runtime analyses, allowing them to explore the input space without being restricted to a fixed verification pipeline. Crucially, when a candidate is rejected on the basis of a validated counterexample, the rejection is grounded in a concrete discrepancy between the two kernels.

== Automated Compiler Development for Emerging Hardware
A new accelerator and its hardware features are only useful if software can exploit them effectively. The rapid evolution of machine learning algorithms and hardware accelerators places a substantial burden on compiler engineers, who must ensure that kernels written in high-level languages such as Triton can take full advantage of the underlying hardware. For example, NVIDIA's Hopper architecture introduced asynchronous @TMA transfers, warp-group @MMA instructions, and thread-block clusters. Yet FlashAttention-2 achieved only 35% of the H100's peak throughput, in part because it could not exploit these features; FlashAttention-3 subsequently raised this to 75%, more than two years after Hopper was announced @flashattention-3.

Recent advances in @LLM:pla have enabled kernel generation at multiple levels of the stack, from high-level languages such as Triton @TritonGym @DrKernel, through CUDA @kernelbench @StitchCUDA, to direct generation of @PTX:s and accelerator assembly @ai-as-compiler @KernelCraft. However, generation becomes increasingly challenging at lower levels of abstraction. Low-level code offers fewer safety abstractions and less protection against errors than higher-level programming and compilation pipelines. On unfamiliar accelerator @ISA:pla, for example, hallucinated opcodes are a leading cause of syntax errors @KernelCraft.

More fundamentally, low-level optimization requires reasoning about dependencies and resource usage across the entire kernel: register allocation and instruction scheduling depend on global dataflow and instruction dependencies, whereas @LLM:pla can parse @IR syntax but struggle with control flow, loops, and execution semantics @llms-ir-understanding. Register allocation illustrates this gap. The @IR of a single multi-head attention kernel can exceed tens of thousands of tokens, yet a general-purpose model tasked with allocating registers may resort to naive sequential assignment without reuse. Even a model fine-tuned for this task makes mistakes, 62–73% of which are dataflow violations; producing valid allocations requires a Z3-based verifier and repeated resampling @verilocc. Tellingly, state-of-the-art direct @GPU kernel generation targets @PTX:s, a virtual @ISA with an unbounded register model, thereby leaving physical register allocation and much of the low-level instruction scheduling to NVIDIA's assembler @ai-as-compiler.

== AI-accelerated Performance Modelling

// == Thesis chapters
// === Integrating theorem proving into kernel optimization workflows
//
// === Agent integration into (co-)development of the software and hardware stack
// - Can do some work on LLMs' understanding of Intermediate Representations
//   - Inspired from #link("https://raw.githubusercontent.com/mlresearch/v267/main/assets/jiang25p/jiang25p.pdf")[this paper]
//
// === AI-accelerated modelling for better design space exploration

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
