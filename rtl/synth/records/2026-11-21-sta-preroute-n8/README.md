# 2026-11-21 pre-route multi-corner `klt sta` bring-up, `ARRAY_N = 8`

Append-only record. A tool result against a predictive model, not a
measurement, and **not an item-5 citation**: `manifests/asap7-npu.json` is
unchanged by this record, and the spec's predicted clock is post-route STA
only (issue #80). Produced by `layout/flow/sta-preroute.sh` (the one command;
see `sta-request.json`, committed at `layout/flow/sta-request.json` and run
byte-for-byte unchanged).

**Pre-route bring-up.** `geometry_source: "netlist_estimate"`: the design is
the item-1 synthesized netlist (`rtl/synth/records/2026-10-27-asap7-n8/`,
sha256 in `inputs.sha256`), linked with no DEF, no floorplan, no placement,
no routing, ideal clock (`clock_mode: "ideal"`, skew 0), no wire parasitics of
any kind (no wire-load model; the ASAP7 Liberty declares none, so interconnect
delay is zero). The clock period 2.0 ns and the 0.0 ns I/O delays are the
layout flow's existing constraint inputs (`layout/flow/make-request.py`), not
claims. OpenSTA reads the derived netlist `npu_top_sta_in.v`
(prep-netlist.sh's tie-cell + macro-rename derivation of the attested netlist,
which is not modified); the response's `provenance.input.content_hash` equals
its sha256.

**Macro-arc treatment.** The four `npu_sram_bank` instances are timed, not
blackboxed: `blackboxed_cells: []`, and each corner's session reads the
placeholder macro Liberty (`layout/macros/npu_sram_bank_{ss,tt,ff}.lib`,
RULE lib-anchored-placeholder-v1) alongside the standard-cell deck. The
placeholder macro arcs are **included** in every aggregate number below, and
the worst paths through each macro pin are **reported separately** via
`constraints.report_instances` (per-corner `instance_paths` in `sta.json`).
Every number that depends on a macro arc is therefore a placeholder result,
per spec/npu.md ("On-chip memory") and decision 0002.

**FF anomaly.** The RVT_FF hold result is provisional: the FF deck includes
`SIMPLE_RVT_FF_nldm_211120`, whose header says 0.7 V / 25 C rather than the
corner's 0.77 V / 0 C (spec/npu.md, PVT corners; the sibling's open evidence
issue is 2AMLogic/asap7-riscv-core#60). Whether its tables are characterised
at FF is not established. To make the five FF files merge at all, that one
file's header was normalised to its siblings' by the sibling's documented
merge rule (header from the first file in sorted order, cells from all --
`asap7-riscv-core flow/merge_lib.py`); no cell group, timing table or area
value was edited, and the TT deck bytes are unchanged from the item-1 record
(hash-compared in `tool-versions.txt`). This is a disclosure aid, not a
ratification of FF.

## Results (all three corners `timing_status: "constrained"`,
`constraint_completeness: "complete"` -- 0 unconstrained endpoints, 0
unclocked registers; no endpoint is left unconstrained by a missing macro
model)

| Corner | WNS setup (ns) | TNS setup (ns) | WNS hold (ns) | fmax (MHz) | setup viol. | hold viol. |
|---|---|---|---|---|---|---|
| RVT_SS | -7.37974 | -15784.9 | -0.00560 | 106.613 | 2472 | 68 |
| RVT_TT | -3.92305 | -8248.69 | -0.00318 | 168.832 | 2284 | 68 |
| RVT_FF | -2.38163 | -4942.47 | -0.00399 | 228.226 | 2284 | 68 |

The worst setup path is the same at every corner, control-to-array
(`u_ctrl/_2310_/QN -> u_array/g_row[0].g_col[0].u_pe/_1587_/D`), not a macro
path. The worst macro-involving path at SS arrives at a macro input pin
(`u_ctrl/_2310_/QN -> u_banks/g_bank_1_u_bank/rw_addr[9]`, -5.4212 ns); the
worst path out of a macro pin has positive slack at SS (+0.9815 ns,
`u_banks/g_bank_2_u_bank/r_rdata[1] -> _8244_/D`). The worst hold path at
every corner is `rst -> u_host/.../D` (data hold, ideal clock, so no clock
skew is modelled).

Negative slack is a recorded result that feeds a later design iteration, not
a spec edit (issue #80, Rejected). No `klt` gap was found: `klt sta` 0.9.3
ran the multi-corner list and the per-corner macro Liberty natively
(`pdk.corners` + `macros[].lib`); nothing to file upstream.

## Files

`sta-request.json` (byte-identical to `layout/flow/sta-request.json`),
`sta.json` (klt response, verbatim; the `macros[].lib` paths inside it name
the scratch run directory `layout/flow/sta-work/`, as the item-1 envelope
names `rtl/synth/.klt/`), `npu_top_sta_in.v` (netlist OpenSTA read),
`inputs.sha256` (request, derived netlist, macro LEF + three Liberty views,
SDC, attested synthesis netlist), `time-v.txt`, `run.json` (outcome, wall
time, peak RSS), `tool-versions.txt` (klt 0.9.3.dev2575+g6bd18bbc8637,
OpenROAD 26Q3-1510-g6cb3f2b704, Yosys 0.67+post, and the sha256 of all 15
normalised PDK Liberty files -- 5 per corner).

Wall time 66.39 s, peak RSS 336,852 KiB (one `klt sta` process, three
internal OpenSTA sessions, OpenROAD capped at 2 threads), host load ~9-11
(shared 8-vCPU worker).

## PDK Liberty for the corners

`RVT_TT` from the flow's root (`layout/flow/make-pdk-root.sh`, building on
`rtl/synth/make-pdk-root.sh`: the pinned `asap7sc7p5t_28` @ `f970bd3`
checkout, the same three header normalisations); `RVT_SS` / `RVT_FF` added by
`layout/flow/sta-add-corners.sh` from the same checkout with the same
normalisations (plus the SIMPLE FF header rule above). The extractor is not
duplicated and `rtl/synth/make-pdk-root.sh` is not edited, so this change adds
no stale leg to the item-1 freshness check (`rtl/synth/check-fresh.sh` still
reports only its pre-existing klt-version clause, held as issue #54).
