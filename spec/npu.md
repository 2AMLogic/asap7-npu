# asap7-npu target specification

**Status: proposed.** Not ratified. Ratification is a human act; agents do not
mark this file ratified (see `CLAUDE.md`). Edits after ratification go through
a decision record under `spec/decisions/`.

## Predictive PDK statement

ASAP7 is a **predictive** 7 nm FinFET PDK, not a foundry process. This block
is **layout, DRC and timing only, and it is never fabricated.** Every number in
this repo is a tool result against a predictive model. Every timing figure is
**predicted** (post-route STA against ASAP7's predictive Liberty models).
Nothing here is a measurement.

## Inherited from `sky130-npu` (not re-decided here)

Origin: `2AMLogic/sky130-npu`, `main` @ `81be5b3fc180d0cd02d828b9b2ca93195eef0a78`
(read 2026-10-17). At that commit the origin has an empty `spec/`, no RTL, no
golden model and no testbenches, and its own target table is still a draft.
So nothing can yet be cited to an origin commit; each row is tracked at the
origin and decided there. When the origin lands a row, replace the pointer with
the origin commit and stamp the copy into `reuse.lock.json`.

| Item | Status here | Origin pointer |
|---|---|---|
| Dataflow | TRACKED AT ORIGIN | `sky130-npu#3` |
| Arithmetic: INT8 operands, INT32 accumulation, requantization | TRACKED AT ORIGIN | `sky130-npu#3` |
| Operation set | TRACKED AT ORIGIN | `sky130-npu#3` |
| Host interface | TRACKED AT ORIGIN | `sky130-npu#3` |
| RTL, array size as a single parameter | TRACKED AT ORIGIN | `sky130-npu#8` |
| Integer golden model | TRACKED AT ORIGIN | `sky130-npu#8` |
| Testbenches (bit-exact against the golden model) | TRACKED AT ORIGIN | `sky130-npu#8` |

Numerical correctness for this port is: bit-exact against the origin's golden
model, or it fails.

## Re-derived for ASAP7

### Array size

| | Size | MACs |
|---|---|---|
| Target | 32 x 32 | 1,024 |
| Fallback | 16 x 16 | 256 |
| Stretch | 64 x 64 | 4,096 |

Only the array-size parameter changes. Any other departure from the origin is a
decision record.

### On-chip memory

Abstract macro views, not a bitcell or compiler. Representation, generation and
limitations: `spec/decisions/0002-memory-representation.md`. Banking is scaled
from the origin's banking, which the origin has not ratified; the bank count and
word geometry are TRACKED AT ORIGIN (`sky130-npu#3`).

### Predicted clock (post-route STA, slow corner)

| Target | Fallback | Stretch |
|---|---|---|
| 1 GHz | 500 MHz | 1.5 GHz |

All figures are predicted. The slow corner is the SS corner below.

### PVT corners

Named by the Liberty file in `asap7sc7p5t_28` @ `f970bd3c3292b79ae4d022a3ec80533534614066`
(`LIB/NLDM/`, shipped as `.lib.7z`). The cell library is the 7.5-track RVT
flavor. Each corner is five files, one per function group:

| Corner | Role | Liberty files (`asap7sc7p5t_<group>_RVT_<corner>_nldm_<date>.lib.7z`) |
|---|---|---|
| SS | slow: closure corner for the predicted clock | `AO_RVT_SS_nldm_211120`, `INVBUF_RVT_SS_nldm_220122`, `OA_RVT_SS_nldm_211120`, `SEQ_RVT_SS_nldm_220123`, `SIMPLE_RVT_SS_nldm_211120` |
| TT | typical | `AO_RVT_TT_nldm_211120`, `INVBUF_RVT_TT_nldm_220122`, `OA_RVT_TT_nldm_211120`, `SEQ_RVT_TT_nldm_220123`, `SIMPLE_RVT_TT_nldm_211120` |
| FF | fast: hold check | `AO_RVT_FF_nldm_211120`, `INVBUF_RVT_FF_nldm_220122`, `OA_RVT_FF_nldm_211120`, `SEQ_RVT_FF_nldm_220123`, `SIMPLE_RVT_FF_nldm_211120` |

LVT, SLVT and SRAM-flavor libraries also ship; they are out of scope for this
spec (a different Vt flavor is a decision record). The CCS variants are not used.
The Liberty files are compressed in the upstream tree; `klt` does not unpack
them (klayout-tools#3782), so the unpack step is part of the flow bring-up.

**Monte Carlo: `not_applicable`.** This is a digital block closed on static
corners; there is no statistical row.

### DRC / LVS acceptance

"Clean" means: zero violations from the pinned deck, on the full chip, with
every missing rule listed. The pinned deck and its known gaps are in
`spec/decisions/0001-asap7-pin-and-klt-bring-up.md`; the deck hash, `klt`
pin and LVS options are adopted by reference in
`spec/decisions/0003-adopt-asap7-riscv-core-bring-up.md`. A run against a deck with
missing rules is reported as "clean against the deck subset", with the missing
rules named, never as plain "clean".

- **Flat and hierarchical.** Target: both flat and hierarchical runs are
  clean on the full chip. Fallback: hierarchical only, recorded as a
  limitation along with why the flat run did not finish (a flat run that does
  not finish is a result, filed as a tool-scaling record).
- **Macros.** Abstract memory macros are black boxes in DRC and LVS; their
  interiors are not checked. This is a recorded limitation, not a waiver.
- **LVS.** Clean means the extracted netlist matches the reference netlist
  with no mismatches, at the same hierarchy level as the DRC run.
- **Waiver rule.** A violation may be waived only through a committed waiver
  file passed to `klt drc --waivers`. Each entry names the rule id, the
  location, a written justification and a linked issue, and is approved by a
  human reviewer. No blanket or per-rule waivers. The waiver count is reported
  with every result. Agents do not waive a violation to make a result pass.

### Tool-scaling records

Every DRC and LVS run records runtime and peak memory, including runs that do
not finish. Format and sweep sizes: `spec/tool-scaling-record.md`.

## Open questions

Each is an explicit open item with the run that would answer it. None is
answered yet.

| Question | Run that answers it |
|---|---|
| At what array size does a flat DRC run stop finishing on a fleet host? | Flat `klt drc` at 16 x 16, 32 x 32 and 64 x 64, each recorded per `spec/tool-scaling-record.md`. Needs a layout at each size, so it waits on P&R. |
| Do the abstract memory views pass DRC and LVS as black boxes? | DRC and LVS on a placed block that instantiates the abstract views. Needs the first placed block with a memory macro. |
| Does the origin's RTL scale to 32 x 32 by parameter alone? | Elaborate and run the stamped testbenches at 16, 32 and 64 with only the array parameter changed. Needs `sky130-npu#8`. |

## Out of scope

No SRAM bitcell or compiler; no new architecture; no step beyond predicted
timing, DRC and LVS.
