# MANIFEST — market-key

Installed for the `asap7-npu` spec-ratification PR (issue #30).

## Provenance

Copied from `2AMLogic/gf180-gate-driver`, `ratification/market-key/`, at commit
`d7a2b691541e06d639c3454e76fb65f48359985b` (read 2026-10-27). The reference
`MANIFEST.md` says "Do not hand-edit; regenerate instead". This copy **was
hand-adapted**, because the issue requires the rubric to be adapted to a digital
INT8 MAC array on the predictive ASAP7 PDK. Recorded divergence, not a
regeneration.

Protocol: `2AMLogic/2am` `ratification/protocol.md` §1-2. The `Output format`
section's `RATIFY-KEY` marker line and the
`competitive|adequate-for-catalog|uncompetitive|escalate` vocabulary are
**unchanged** from the reference.

## Skill files

- `SKILL.md`
- `comp-table-format.md`
- `rubric.md`

## Comp data

- `comps/int8-mac-array.md` — candidates only, no recorded values. The
  reference's `comps/gate-driver.md` is not copied (a different block class).

## Changes from the reference

- In-scope rows are array size, predicted clock targets and the arithmetic
  contract; the PDK, memory representation, DRC/LVS wording and
  `TRACKED AT ORIGIN` rows are out of scope.
- Comparison set is open INT8 arrays; a predicted-versus-measured rule is added.
- No product, price, customer or availability may be assumed; price rows
  removed.
- The two-operating-modes section is removed (this copy has one mode).
