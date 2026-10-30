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

The content of `spec/npu.md` at the head of this PR (revised 2026-10-29 after
the EE-key review at `ef07c1f`; the unrevised content was `48f1767`), apart
from its status line:

- the predictive PDK statement;
- the array size: **8 x 8 (`ARRAY_N = 8`), the interim size**, attested at that
  size only. There is no 32 x 32 target, no 64 x 64 stretch and no 16 x 16
  fallback in this spec. Per the operator's ruling of 2026-10-29 the earlier
  32 x 32 and 64 x 64 targets are dropped, because they are not reachable under
  the parameter-only rule (the origin's legal `ARRAY_N` is {4, 8, 16} and the
  stamped RTL implements 4 and 8). 16 x 16 waits for the origin's 8 x 8 / 50 MHz
  post-route close (`sky130-npu#52`, 2026-10-28), then a new decision record.
  No target is raised;
- the on-chip memory stance, as stated in `spec/npu.md` (abstract macro views,
  the three views, placeholder Liberty, no flop arrays). Decision 0002 is the
  rationale and is not ratified;
- the predicted clock values (1 GHz, 500 MHz, 1.5 GHz; post-route STA, SS
  corner), unchanged and not claimed at any size;
- the PVT corner set (SS, TT, FF; RVT) with voltages and temperatures, **FF
  provisional and not a ratified sign-off corner** because of the
  `SIMPLE_RVT_FF` Liberty anomaly (matches `asap7-riscv-core`), and
  `Monte Carlo: not_applicable`;
- the DRC/LVS acceptance rules including the deck hash, `klt` pin and LVS
  options now stated in `spec/npu.md`, the waiver rule and the
  tool-scaling-record requirement;
- the open questions (question 3 marked answered) and the out-of-scope list.

## What is not being ratified

- The rows `spec/npu.md` marks `TRACKED AT ORIGIN` (integer golden model and
  testbenches, `sky130-npu#8`) and the rows it marks `DECIDED AT ORIGIN`
  (dataflow, arithmetic, operation set, host interface, RTL and array
  parameter). They stay decided at `2AMLogic/sky130-npu` (`25d9c71`, ratified).
- Decision records 0001-0004. Their statuses are unchanged by this change; the
  values this spec depends on from 0001-0003 are restated in `spec/npu.md`
  so that none of the ratified rows has an unratified referent.
- Any claim that a target has been met. Ratifying a target is not meeting it.

## Decision (proposed)

1. The ratification PR changes the status line and the revised rows of
   `spec/npu.md` described above, `spec/tool-scaling-record.md` (allows
   `8x8` in `array_size`) and adds this record.
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
