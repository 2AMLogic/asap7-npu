# asap7-npu roadmap

An INT8 multiply-accumulate array ported from
[sky130-npu](https://github.com/2AMLogic/sky130-npu) onto ASAP7, a predictive
7 nm PDK, to find out how `klt` DRC and LVS behave on a large, regular layout.
Nothing here is fabricated; every figure is a tool result against a predictive
model, and timing is "predicted".

Status as of 2026-11-14, `main` @ `af4b608`.

The graded state of record is
[`manifests/asap7-npu.signoff.json`](manifests/asap7-npu.signoff.json), which CI
regenerates and diffs on every PR and push. This file says what comes next and
why; when the two disagree, the report wins. The tracker is #4.

## Where it stands

The spec is ratified at 8 x 8 (`ARRAY_N = 8`, 64 MACs): decision
[0005](spec/decisions/0005-ratify-npu-spec.md), `65d9e28`. Decisions 0001 to
0004 are still proposed. The origin RTL accepts `ARRAY_N` 4 and 8 only, and the
origin deferred 16 and keeps 32 outside its spec (`spec/npu.md`, Open questions).

T1 checklist as graded by `klt` v0.8.0 (2 met, 1 not applicable, 8 unmet of 11):

| Item | State | Evidence or owner |
|---|---|---|
| 1 Design sources | met | stamped RTL in `rtl/common/` (pin in `reuse.lock.json`), netlist in `rtl/synth/records/2026-10-27-asap7-n8/`, PR #28 |
| 2 Layout | unmet | #23, blocked (see below) |
| 3 DRC clean | unmet | #24, needs item 2 |
| 4 LVS clean | unmet | #25, needs item 2 |
| 5 Full corner verification | unmet | no issue yet; needs items 2 and 9 |
| 6 Statistical claims | not applicable | `manifests/spec-rows.json`, `manifests/item6-na-statement.json`, PR #45 |
| 7 Post-layout verification | unmet | no issue yet; needs items 2 and 9 |
| 8 Characterization report | unmet | no issue yet; needs items 2 and 5 |
| 9 Testbenches shipped | unmet | #16, PR #18 open and held (see below) |
| 10 Repo hygiene | met | `manifests/attestations/item-10.json`, PR #27 |
| 11 Power delivery | unmet | #26, needs items 2 and 4 |

Also in place: the ASAP7 bring-up is adopted from `asap7-riscv-core` by
reference (decision 0003, PR #19); the record format for DRC and LVS runs is
defined in `spec/tool-scaling-record.md` (proposed; no run recorded yet).
`layout/` and `verification/` hold only placeholder READMEs on `main`.

Not on `main`: branch `feature/issue-23` carries a place-and-route flow
(`layout/flow/`) and an abstract memory macro LEF (`layout/macros/`), and PR #66
proposes landing both without the route. Per the builder notes on #23, floorplan,
placement and clock-tree synthesis finished at `ARRAY_N = 8`; the route has never
finished.

Landed since the previous snapshot (`5619c8a` to `af4b608`): the README no longer
carries hand-maintained status prose and points at the signoff report and
`spec/README.md` instead, and item 10 is re-attested (#62, PR #63).

## Now

1. **Land the place-and-route flow and the memory macro LEF on `main`, without
   the route** (#65, `loom:building`; PR #66 open and awaiting review). The flow
   is the reusable part of #23 and until #66 merges exists only on unmerged
   branches. Done when `layout/flow/` and `layout/macros/npu_sram_bank.lef` are
   on `main`, `gen-macro-lef.py` reproduces the committed LEF byte for byte,
   `layout/README.md` documents the one-command invocation, and no routed
   artifact or item-2 claim is added. #23 then shrinks to "run it and attest".

## Next

- **Item 2, routed GDS at 8 x 8** (#23). Done when a routed GDS, DEF and
  post-route netlist are committed under an append-only record with P&R wall
  time and peak memory, an item-2 attestation is cited in the manifest, and
  the report grades item 2 `met`. Blocked on compute: see below.
- **Item 9, testbenches** (#16, PR #18). Done when the stamped harness from
  `sky130-npu` runs from a fresh clone, every stamped file matches its
  `reuse.lock.json` hash, and the `verification` workflow is green. Blocked on
  a ruling about the simulation memory model: see below.
- **Item 3, DRC** (#24) after item 2. Done when flat and hierarchical
  `klt drc` runs on the routed GDS each have a record in
  `layout/tool-scaling/` (a did-not-finish is a valid record, with a gap issue
  filed at klayout-tools) and item 3 is graded from them.
- **Item 4, LVS** (#25) after item 2. Done when `klt lvs` of the routed layout
  against the post-route netlist, with `power_connectivity`, is recorded the
  same way. This also answers the spec's open question on whether the
  abstract memory views pass DRC and LVS as black boxes.
- **Item 11, power delivery** (#26) after items 2 and 4. Done when `klt erc`
  supply evidence on the routed block is committed and cited.
- **File owner issues for items 5, 7 and 8** once items 2 and 9 have landed;
  #4 asks that they are not filed speculatively. Item 5 is multi-corner
  `klt sta` plus the bit-exact suite, item 7 the suite on the post-route
  netlist, item 8 the predicted Fmax, area and power report.

## Later

- **A larger array.** Question first: does the origin implement and ratify a
  legal `ARRAY_N` above 8? Until it does, forking `npu_banks.v` here is
  rejected (decision 0004). When it does: re-stamp, re-synthesize, re-run the
  flow at that size, and add a row to the tool-scaling sweep by a new
  decision record.
- **The scale answer itself.** Question first: at 8 x 8, do flat DRC and LVS
  finish on a fleet host at all? `spec/npu.md` leaves "at what array size does
  a flat DRC run stop finishing" open, and 8 x 8 is the only size that can be
  measured today.
- **Ratifying decisions 0001 to 0004.** Question first: does 0004's rule
  "re-attest after any `klt` version change" survive #54?

## Blocked and waiting

- **#23 (item 2) is blocked on compute, not on design.** The route did not
  finish in 2 h 43 min at 2 threads on a shared host, and two batch attempts on
  2026-11-12 were interrupted after about 60 and 70 minutes without a result
  (builder notes on #23). The fix is in batch infrastructure outside this
  repo; the park record at the bottom of #23 names it. Items 3, 4, 5, 7, 8 and
  11 all wait behind this one.
- **PR #18 (item 9) is held for an operator ruling.** The stamped bit-exact
  suite cannot pass here because `rtl/pdk/asap7/npu_sram_bank.v` is a black
  box with no behaviour, so every bank read is X. The options on the PR are a
  simulation-only behavioural seam authored here (with a decision record), a
  fix at the origin, or a recorded waiver. The PR also conflicts with `main`.
- **#54 and #58 are held for operator decisions:** whether
  `rtl/synth/check-fresh.sh` keeps its `klt`-version clause (#51 waits on it),
  and whether `package.json` is removed.

No issue is dispatchable today: no open issue carries `loom:issue`. The one
`## Now` item is already claimed (#65 is `loom:building`, with PR #66 awaiting
review), and everything on the critical path is parked.

## Not planned

- Fabrication, a shuttle, silicon measurement, or any tier above T1: the
  report grades those `tier_not_supported`, and ASAP7 is not manufacturable.
- An SRAM bitcell or compiler; memory stays an abstract macro view
  (decision 0002).
- A new architecture, or a local edit to a stamped file.
- Array sizes 16 x 16, 32 x 32 or 64 x 64 as targets; `spec/npu.md` sets none.
