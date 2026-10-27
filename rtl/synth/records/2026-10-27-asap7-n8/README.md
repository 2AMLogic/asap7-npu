# 2026-10-27 ASAP7 synthesis, `ARRAY_N = 8` (interim)

Append-only record. A tool result against a predictive model, not a measurement.
Not the 16 x 16 fallback and not the 32 x 32 target (decision 0004).

| | |
|---|---|
| Design | `npu_top`, `ARRAY_N = 8`, `npu_sram_bank` black-boxed (4 instances' area excluded) |
| Cells | `asap7sc7p5t_28` @ `f970bd3`, RVT, TT, Liberty normalised by `../../make-pdk-root.sh` |
| Tools | `klt 0.8.1.dev55+g879d39bad82b`, Yosys 0.67+post |
| Result | 77,834 instances; area 7,770.51 um^2 (sequential 1,336.99); latches 0, comb loops 0 |
| Runtime | 3:45.13 wall, 223.34 s user, 0.99 s system (one job) |
| Peak memory | 318,592 kB maximum resident set (`/usr/bin/time -v`, `time-v.txt`) |
| Timing | none (`timing: null`) |

Files: `envelope.json` (klt response, verbatim), `npu_top_synth.v` (netlist; its
sha256 is `netlist_sha256` in the envelope), `synth-request.json`, `inputs.sha256`
(what the freshness check re-hashes), `pdk-liberty.sha256` (normalised Liberty
files), `time-v.txt`, `npu_top_stats.json`, `synth_npu_top.ys`,
`npu_top_blackboxes.txt`, `klt-version.txt`, `yosys-version.txt`.

The envelope's `netlist_path` names the scratch run directory (`rtl/synth/.klt/...`)
that was copied here. `klt synthesize --check` against this envelope needs the
ASAP7 root from `make-pdk-root.sh`.
