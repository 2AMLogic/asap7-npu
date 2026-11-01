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
- **The ratified array size is 8 x 8 (`ARRAY_N = 8`)** (decision 0005,
  `65d9e28`). There is no 32 x 32 target, 16 x 16 fallback or 64 x 64 stretch;
  the predicted clock values in `spec/npu.md` are unchanged and not claimed at
  any size.

<!-- BEGIN LOOM ORCHESTRATION -->
This repository uses [Loom](https://github.com/rjwalters/loom) for AI-powered development orchestration — see the Loom repository for the full guide (roles, labels, worktrees, configuration). When installed, Loom also writes a locally-substituted copy of that guide to `.loom/CLAUDE.md`.

Work is coordinated through `loom:` labels on issues and pull requests, and the same roles run either under `loom-daemon` or by hand in an attended session — daemon mode is optional. Create the labels once with `.loom/scripts/sync-labels.sh` (an install ships `.github/labels.yml` but does not create the labels on the forge). A pull request ready for review carries `loom:review-requested`; Judge reviews it and applies `loom:pr` (approved) or `loom:changes-requested`; Doctor fixes a `loom:changes-requested` pull request and returns it to `loom:review-requested`. Only a `loom:pr` pull request gets merged, and always via this repo's merge script (`.loom/scripts/merge-pr.sh`) — never a raw forge merge command such as `gh pr merge`. Full state machine: `.loom/docs/label-state-machine.md`.
<!-- END LOOM ORCHESTRATION -->

<!-- BEGIN REPO-SKILLS -->
This repository has [Repo Skills](https://github.com/rjwalters/repo) v0.25.1 installed —
general repository hygiene and environment commands invoked as `/repo:<command>`. Run
`/repo:help` for the command list, or see `.claude/skills/repo/SKILL.md` for the full
guide. Hygiene commands apply safe, reversible fixes by default and report each
change; run with `--ask` to review first, and `--prune` to allow irreversible
removals. Managed by `install.sh` — edit outside the markers only.
<!-- END REPO-SKILLS -->
