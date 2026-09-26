#import "/lib.typ": report, callout

#show: report.with(
  title: "Investigating the Emergent Dynamics of Distributed Consensus Protocols Under Adversarial Network Partitions",
  subtitle: "First Year Progress Report",
  author: "Jane Doe",
  student-id: "123456789",
  department: "Department of Computer Science",
  institution: "University of Somewhere",
  degree: "Doctor of Philosophy",
  report-type: "First Year Report",
  supervisor: "Prof. Alex Smith",
  advisor: "Dr. Bailey Jones",
  logo: "/template/logo.svg",
  date: datetime(year: 2026, month: 9, day: 26),
  abstract: [
    This report summarizes progress made during the first year of a PhD
    investigating how distributed consensus protocols behave under
    adversarial network partitions. We motivate the problem, review related
    work, describe preliminary experiments, and outline a plan for the
    remaining years of the project.
  ],
  bibliography-file: "/template/refs.bib",
)

= Introduction

Distributed systems must make progress even when parts of the network
misbehave. This report describes the motivation, background, and early
results of a research programme studying consensus protocols under
adversarial conditions @lamport1978time.

#callout(title: "Discussion Point")[
  Should the threat model in Chapter 2 also account for partially
  synchronous adversaries, or is a fully asynchronous model sufficient for
  the first publication? Raise with supervisor before the next milestone.
]

The remainder of this report is organized as follows: @background reviews
related work, @methodology describes the experimental setup, @results
presents preliminary findings, and @timeline lays out a plan for the next
two years.

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
