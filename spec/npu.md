# asap7-npu target specification

**Status: ratified on the operator's approval of the pull request that carries
this line** (`spec/decisions/0005-ratify-npu-spec.md`). Until that approval is
merged this file is proposed. Ratification is a human act; agents do not merge
the change or mark this file ratified (see `CLAUDE.md`). Edits after
ratification go through a decision record under `spec/decisions/`.

## Predictive PDK statement

ASAP7 is a **predictive** 7 nm FinFET PDK, not a foundry process. This block
is **layout, DRC and timing only, and it is never fabricated.** Every number in
this repo is a tool result against a predictive model. Every timing figure is
**predicted** (post-route STA against ASAP7's predictive Liberty models).
Nothing here is a measurement.

## Inherited from `sky130-npu` (not re-decided here)

Origin: `2AMLogic/sky130-npu`, `main` @ `25d9c71e377de9c52171ec15e34ecfeca2c4c880`
(read 2026-10-29). The origin's `spec/npu.md` is ratified (`sky130-npu#3`,
closed 2026-10-17); section numbers below are that file's. The RTL here is
stamped from the origin at `c5a85481fe3782dcae6cd81ba225ceb131597d7c`
(`reuse.lock.json`). Rows are decided at the origin, not here.

| Item | Status here | Origin pointer |
|---|---|---|
| Dataflow: output-stationary | DECIDED AT ORIGIN | origin spec §2, decision `0001-dataflow` |
| Arithmetic: INT8 x INT8 -> INT32, requantization | DECIDED AT ORIGIN | origin spec §3 |
| Operation set | DECIDED AT ORIGIN | origin spec §1 |
| Host interface: Wishbone B4 classic, 32-bit, slave | DECIDED AT ORIGIN | origin spec §6 |
| RTL, array size as a single parameter (`ARRAY_N`, legal values {4, 8, 16}; the stamped RTL implements 4 and 8 only) | DECIDED AT ORIGIN | origin spec §1; stamped RTL `c5a8548` |
| Integer golden model | TRACKED AT ORIGIN | `sky130-npu#8` (open) |
| Testbenches (bit-exact against the golden model) | TRACKED AT ORIGIN | `sky130-npu#8` (open) |

Numerical correctness for this port is: bit-exact against the origin's golden
model, or it fails.

## Re-derived for ASAP7

### Array size

| | Size | MACs |
|---|---|---|
| Array size | 8 x 8 (`ARRAY_N = 8`) | 64 |

This is the interim size (`spec/decisions/0004-interim-array-size-for-item-1.md`):
the largest size the stamped origin RTL elaborates. The block is attested at
`ARRAY_N = 8` only; no larger size can be elaborated today.

No larger target, fallback or stretch is set here. 16 x 16 is legal at the
origin but not implemented there, and by operator ruling (`sky130-npu#52`,
2026-10-28) it waits for the origin's 8 x 8 / 50 MHz target to close
post-route, then a new decision record. 32 x 32 stays outside the origin
spec; this spec sets no 32 x 32 or 64 x 64 target. Changing either would need
an origin spec amendment and a decision record here.

Only the array-size parameter changes. Any other departure from the origin is a
decision record.

### On-chip memory

Abstract macro views, not a bitcell or compiler. The values ratified here
(a change to any needs a decision record):

- Each macro is represented by three views generated from a parameter table:
  a LEF abstract, a Liberty timing model and a behavioural Verilog model. The
  macro has no internal layout.
- The Liberty model is generated at the SS, TT and FF corners below. Its numbers
  are placeholders derived from a stated rule, labelled as such, and never a
  memory measurement.
- Synthesized flop arrays are not used as memory.
- Bank count and word geometry are those of the origin's ratified banking
  (origin spec §2, §5), at `ARRAY_N = 8` only.

Rationale, options and the rejected alternatives:
`spec/decisions/0002-memory-representation.md` (proposed; not itself ratified
here).

### Predicted clock (post-route STA, slow corner)

| Target | Fallback | Stretch |
|---|---|---|
| 1 GHz | 500 MHz | 1.5 GHz |

All figures are predicted, against the SS corner below. They are unchanged by
this revision and are not claimed at any size: no post-route STA exists yet.
Whether the placeholder memory-macro timing arcs count toward closure or are
reported separately must be stated with every timing result.

### PVT corners

Named by the Liberty file in `asap7sc7p5t_28` @ `f970bd3c3292b79ae4d022a3ec80533534614066`
(`LIB/NLDM/`, shipped as `.lib.7z`). The cell library is the 7.5-track RVT
flavor. Each corner is five files, one per function group:

| Corner | Voltage / temperature | Role | Liberty files (`asap7sc7p5t_<group>_RVT_<corner>_nldm_<date>.lib.7z`) |
|---|---|---|---|
| SS | 0.63 V / 100 C | slow: closure corner for the predicted clock | `AO_RVT_SS_nldm_211120`, `INVBUF_RVT_SS_nldm_220122`, `OA_RVT_SS_nldm_211120`, `SEQ_RVT_SS_nldm_220123`, `SIMPLE_RVT_SS_nldm_211120` |
| TT | 0.7 V / 25 C | typical | `AO_RVT_TT_nldm_211120`, `INVBUF_RVT_TT_nldm_220122`, `OA_RVT_TT_nldm_211120`, `SEQ_RVT_TT_nldm_220123`, `SIMPLE_RVT_TT_nldm_211120` |
| FF | 0.77 V / 0 C (see anomaly) | fast: hold check, **provisional** | `AO_RVT_FF_nldm_211120`, `INVBUF_RVT_FF_nldm_220122`, `OA_RVT_FF_nldm_211120`, `SEQ_RVT_FF_nldm_220123`, `SIMPLE_RVT_FF_nldm_211120` |

**FF is provisional, not a ratified sign-off corner.** The header of
`SIMPLE_RVT_FF_nldm_211120` says 0.7 V / 25 C (`PVT_0P7V_25C`), not the
0.77 V / 0 C of the other four FF files, and its body differs from the
`SIMPLE_RVT_TT` file. Whether its tables are characterised at FF conditions is
not established. This matches `2AMLogic/asap7-riscv-core@22aa180`
(`spec/pdk-bringup.md` §5), which also does not treat FF as a sign-off corner
until this is resolved. This is an upstream data question, not a `klt` gap. A
hold result at FF names this anomaly. The voltages and temperatures above are
read from the Liberty headers quoted in that document, not re-measured here.
No regeneration is needed to disclose it; resolving it needs a characterisation
check of the upstream file.

LVT, SLVT and SRAM-flavor libraries also ship; they are out of scope for this
spec (a different Vt flavor is a decision record). The CCS variants are not used.
The Liberty files are compressed in the upstream tree; `klt` does not unpack
them (klayout-tools#3782), so the unpack step is part of the flow bring-up.

**Monte Carlo: `not_applicable`.** This is a digital block closed on static
corners; there is no statistical row.

### DRC / LVS acceptance

"Clean" means: zero violations from the pinned deck, on the full chip, with
every missing rule listed. The values ratified here (a change to any needs a
decision record), adopted from `2AMLogic/asap7-riscv-core@22aa180`:

- DRC deck file hash
  `sha256:08dba3ee047a3ec68b3cd761f982809c62a0d128b8d34ef4e76a28f61221aa6a`
  (263 categories);
- `klt` pin `0.7.1.dev1743+g7ee09483b748`;
- LVS options: the `finfet_bulk` assumption `{"nmos":"VSS","pmos":"VDD"}`,
  disclosed as an assumption, and `match` on 3 cells.

Background and comparison: `spec/decisions/0001-asap7-pin-and-klt-bring-up.md`
and `spec/decisions/0003-adopt-asap7-riscv-core-bring-up.md` (both proposed;
not themselves ratified here). A run against a deck with
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

Each is an explicit open item with the run that would answer it.

| Question | Run that answers it |
|---|---|
| At what array size does a flat DRC run stop finishing on a fleet host? | Flat `klt drc` at 8 x 8 now, and at each larger size if the origin implements one, each recorded per `spec/tool-scaling-record.md`. Needs a layout at each size, so it waits on P&R. |
| Do the abstract memory views pass DRC and LVS as black boxes? | DRC and LVS on a placed block that instantiates the abstract views. Needs the first placed block with a memory macro. |
| Does the origin's RTL scale to 32 x 32 by parameter alone? | **Answered: no.** The stamped RTL rejects `ARRAY_N = 16` (decision 0004, 2026-10-27); a larger size changes `npu_banks` and the bank-role map. The origin ruled on `sky130-npu#52` (2026-10-28) to defer 16 and keep 32 outside its spec. |

## Out of scope

No SRAM bitcell or compiler; no new architecture; no step beyond predicted
timing, DRC and LVS.
