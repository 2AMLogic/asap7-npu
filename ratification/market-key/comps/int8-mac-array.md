# INT8 MAC-array comp candidates

Candidates only. **No value is recorded here.** Each figure a review uses must
be fetched from the primary source and dated in that review's `Sources` table
(`../comp-table-format.md`). Compare a predicted figure with a silicon-measured
one only with the mismatch named (`../rubric.md`).

| Candidate | Class | What to fetch | Primary source to find |
|---|---|---|---|
| Google TPU v1 | Large INT8 systolic matrix unit | Array dimensions, clock, process node, measured | Jouppi et al., "In-Datacenter Performance Analysis of a Tensor Processing Unit", ISCA 2017 |
| Gemmini | Open-source generated systolic array | Default and largest published dimensions, clock, process, measured or predicted | The Gemmini paper (DAC 2021) and the `ucb-bar/gemmini` repository |
| NVDLA | Open INT8 inference accelerator | MAC count per configuration, clock and process if stated | The `nvdla/hw` repository and its published configuration documentation |
| Eyeriss v2 | Published spatial INT8 array | Array dimensions, clock, process, measured | Chen et al., IEEE JETCAS 2019 |

If a candidate states no figure for a row, record `no-comp-found` for that
candidate and row. Add or drop candidates in the review, not here.
