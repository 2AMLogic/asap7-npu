# asap7-npu — agent instructions

Open-source canary block: a large INT8 MAC array on ASAP7, a port of
`sky130-npu` scaled up, designed and verified by AI agents. **Digital.**

- **ASAP7 is a predictive PDK. This block is never fabricated.** It is
  layout, DRC and timing only. Never write anything that implies silicon, a
  shuttle, a tape-out or a measurement — every number here is a tool result
  against a predictive model, and is labelled "predicted" where it is a
  timing figure.
- **PDK**: ASAP7 (The-OpenROAD-Project/asap7), 7.5-track standard cells.
  Digital flow: cocotb + Icarus for simulation, Yosys for synthesis,
  OpenROAD for place-and-route and timing. Layout, DRC, and LVS through
  klayout-tools (`klt`). ASAP7 is not in the fleet's `open_pdks` store; reuse
  `asap7-riscv-core`'s pinned bring-up if it exists, and build it here only
  if it does not.
- **Scale is the point, and the risk.** The question this repo answers is how
  `klt` DRC and LVS behave on a very large, very regular layout. Record
  runtime and peak memory for every DRC and LVS run, at each array size, as
  evidence in its own right. A run that does not finish is a result, not a
  failure to hide — record it and file the gap.
- **The architecture is not the variable.** The RTL, the integer golden
  model and the testbenches are mastered in `sky130-npu` (lineage makes it
  master) and arrive as stamped copies pinned in `reuse.lock.json`. Change
  only the array-size parameter. Do not edit a stamped file locally; fix it
  at the origin, or record the divergence in a decision record.
- **Scope discipline.** No SRAM bitcell or compiler here: on-chip memory is
  abstract macro views, chosen in a decision record. No new architecture.
- **Friction protocol (the canary's job)**: every time klayout-tools is
  awkward, missing a capability, or wrong for what you need, file an issue at
  `2AMLogic/klayout-tools` describing the tool gap generically — that tracker
  is scoped to the tool, so keep design-specific detail out of it and describe
  the gap, not the design.
- **Verification is the product**: no claim without a testbench. Results
  are bit-exact against the origin's golden model or they fail. Recorded
  results are append-only evidence.
- Spec changes go through `spec/` with a decision record; agents do not relax
  the ratified spec to make results pass.
- **32 x 32 at a predicted 1 GHz post-route is the target.** 16 x 16 at
  500 MHz is the fallback and 64 x 64 at 1.5 GHz is a stretch.
