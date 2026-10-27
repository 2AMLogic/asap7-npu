# MANIFEST — ee-key

Installed for the `asap7-npu` spec-ratification PR (issue #30).

## Provenance

Copied from `2AMLogic/gf180-gate-driver`, `ratification/ee-key/`, at commit
`d7a2b691541e06d639c3454e76fb65f48359985b` (read 2026-10-27). The reference
`MANIFEST.md` says "Do not hand-edit; regenerate instead". This copy **was
hand-adapted**, because the issue requires the rubric to be adapted to a digital
INT8 MAC array on the predictive ASAP7 PDK and the generator has no such
target. Recorded divergence, not a regeneration.

Protocol: `2AMLogic/2am` `ratification/protocol.md` §1-2. The `Output format`
section's `RATIFY-KEY` marker line and the `approve|request-changes` vocabulary
are **unchanged** from the reference.

## Skill files

- `SKILL.md`
- `rubric.md`

## Changes from the reference

- Block classification and derivation check recast for a digital block
  (RTL, synthesis record, Liberty corner, STA, DRC/LVS report); Monte Carlo
  `not_applicable` per `spec/npu.md`.
- A predictive-PDK rule: any silicon, shuttle, tape-out or measurement
  language is `unsound`; timing figures must be labelled predicted.
- Step 3 precedent siblings are `sky130-npu` (origin) and `asap7-riscv-core`.
  Rows marked `TRACKED AT ORIGIN` get no verdict.
- Dry-run references removed (no `dry-runs/` directory here).
