# layout

Predicted results against ASAP7, a predictive PDK. This block is never fabricated.

**No routed record exists yet.** This directory holds the place-and-route flow
and the abstract memory macro view only. Running the route, and attesting its
result for T1 item 2, is [#23](https://github.com/2AMLogic/asap7-npu/issues/23),
which is parked on batch-fleet capacity — not on a flow defect. Nothing here is
a result, and no timing figure is stated.

| Path | What |
|---|---|
| `flow/run.sh` | The one command: item 1's gate-level netlist -> routed GDS, via one `klt place-and-route` job. |
| `flow/make-pdk-root.sh` | Builds the throwaway ASAP7 PDK root (Liberty root of `rtl/synth/make-pdk-root.sh`, plus the cell LEF, tech LEF and GDS; asap7sc7p5t_28 @ `f970bd3`, decision 0001 pin). |
| `flow/prep-netlist.sh`, `flow/prep-netlist.py` | Derive the netlist OpenROAD reads from item 1's attested netlist, which is **not** modified: Yosys `hilomap` onto TIEHIx1/TIELOx1 tie cells, then the macro parameter blocks and escaped names. |
| `flow/make-request.py` | Writes the `klt place-and-route` request. The array size enters only through the synthesis record given to `run.sh`. |
| `flow/gen-macro-lef.py` | Deterministic generator for `macros/npu_sram_bank.lef`. Writes to stdout; parses no arguments. |
| `flow/write-record.py` | Writes the run record: outcome, wall time, peak memory, host and load. A run that does **not** finish is recorded too. |
| `flow/bin/openroad` | PATH shim that caps `openroad` at `OPENROAD_THREADS` (this host is shared). Mode `755`; inert without `+x`. |
| `flow/batch-route.sh`, `flow/batch-bin/uvx` | Run the same flow as a `repo-script` batch-fleet job, where one long P&R unit fits. |
| `flow/tests/` | Regression tests for the two steps that used to fail silently: the netlist prep post-conditions and the record written when `/usr/bin/time` left no output. Plain `python3 -I`, standard library only; run by `.github/workflows/flow-tests.yml`. |
| `macros/npu_sram_bank.lef` | Abstract macro view (`MACRO`/`PIN`/`OBS`) for the memory bank: no internal layout and no bitcell, per decision 0002. **Generated; do not hand-edit.** |

## Run it

```
layout/flow/run.sh [SYNTH_RECORD]
```

`SYNTH_RECORD` is a directory under `rtl/synth/records/` named
`<date>-asap7-n<N>`; it defaults to `rtl/synth/records/2026-10-27-asap7-n8`. The
array size `N` is parsed from that name, so the flow takes the size from the
netlist it is given. Step 2 regenerates the macro LEF and fails the run unless
it matches the committed `macros/npu_sram_bank.lef` byte for byte.

Do not run it on a shared dispatch worker: a full route is a batch-fleet job
(`layout/flow/batch-route.sh`).

### Environment

`run.sh` reads six variables:

| Variable | Default | What |
|---|---|---|
| `PDK_ROOT` | `${TMPDIR:-/tmp}/asap7-npu-pdkroot` | Throwaway ASAP7 PDK root; built by `make-pdk-root.sh` if it has no physical views. |
| `KLT_CACHE_DIR` | `${TMPDIR:-/tmp}/asap7-npu-klt-cache` | Where `klt` writes the merged Liberty. Must be under a path the `openroad` wrapper mounts (`$PWD`, `$PDK_ROOT`, `$TMPDIR`). |
| `KLT` | `klt` | The `klt` command (word-split, so it may carry arguments). |
| `RECORD_DATE` | today, UTC | Record date label. |
| `FLOW_TIMEOUT_S` | `7200` | Stop the run after this many seconds. |
| `OPENROAD_THREADS` | `2` | Thread cap applied by `flow/bin/openroad`. The default is the shared-worker cap; `batch-route.sh` raises it to the instance's core count. |

### Records

Records are written to `layout/records/<RECORD_DATE>-asap7-n<N>/` and are
**append-only**: `run.sh` refuses an existing directory and asks for a new
`RECORD_DATE`. Each record carries the request, the input hashes, the tool
versions, `/usr/bin/time -v` output and `run.json`. `layout/records/` is
committed evidence, like `rtl/synth/records/`; the flow's scratch directory
`layout/flow/work/` is not committed.

## Regenerate the macro LEF

```
python3 -I layout/flow/gen-macro-lef.py > layout/macros/npu_sram_bank.lef
```
