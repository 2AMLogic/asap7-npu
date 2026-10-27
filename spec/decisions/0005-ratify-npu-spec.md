# 0005: ratify `spec/npu.md`

- Status: proposed (ratified on the operator's approval of the PR that adds it)
- Date: 2026-10-27
- Issue: #30

ASAP7 is a predictive PDK. This block is never fabricated; every figure in the
ratified spec is a tool result against a predictive model, and every timing
figure is predicted.

## Context

`spec/npu.md` carries `Status: proposed`. The operator ruled (2026-10-27) that
this repo's spec is ratified by the standard two-key path: the EE key and the
market key review, then the operator ratifies (2AMLogic/2am#5346). The keys are
installed under `ratification/` (PR #33; see each `MANIFEST.md` for provenance).

## What is being ratified

The content of `spec/npu.md` at `48f176768c4b0968c21ce36df0c007107b9a03b7`
(main when this record was written), apart from its status line:

- the predictive PDK statement;
- the array sizes (32 x 32 target, 16 x 16 fallback, 64 x 64 stretch) and that
  only the array-size parameter changes;
- the on-chip memory stance (abstract macro views, decision 0002);
- the predicted clock targets (1 GHz, 500 MHz, 1.5 GHz; post-route STA, SS
  corner);
- the PVT corner set (SS, TT, FF; RVT) and `Monte Carlo: not_applicable`;
- the DRC/LVS acceptance rules, the waiver rule and the tool-scaling-record
  requirement;
- the open questions and the out-of-scope list.

## What is not being ratified

- The rows `spec/npu.md` marks `TRACKED AT ORIGIN`: dataflow, arithmetic,
  operation set, host interface, RTL and array parameter, golden model and
  testbenches. They stay decided at `2AMLogic/sky130-npu`.
- Decision records 0001-0004. Their statuses are unchanged by this change.
- Any claim that a target has been met. Ratifying a target is not meeting it.

## Decision (proposed)

1. The ratification PR changes the status line of `spec/npu.md` and adds this
   record, and nothing else. No value in `spec/npu.md` is changed.
2. The EE key and the market key each post a `RATIFY-KEY` review on that PR, as
   non-authors (protocol §1-3).
3. **Ratification is the operator's approval of that PR.** Merging ratifies. No
   agent merges it and no agent marks the spec ratified. A key finding that a
   row is unsound is recorded and the spec is revised by a separate decision
   record; the spec is not relaxed to pass a key.
4. After the operator's approval, issue #4 is updated with a dated comment so
   its items 5-8 can be filed or released.

## Consequences

- Until the operator approves, `spec/npu.md` stays proposed and #4 items 5-8
  stay blocked.
- Edits to the spec after ratification go through a decision record.
