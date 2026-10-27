# rtl

Predicted results against ASAP7, a predictive PDK. This block is never fabricated.

| Path | What |
|---|---|
| `common/` | Origin RTL, stamped unmodified from `sky130-npu` @ `c5a8548` (pin and hashes in `../reuse.lock.json`). Do not edit; fix at the origin. |
| `pdk/asap7/npu_sram_bank.v` | Authored here: black-box memory seam, same ports and timing contract as the origin's sky130 seam (decision 0002). |
| `synth/` | `synth-request.json` (`klt synthesize`, `ARRAY_N = 8`), `synth.sh`, `make-pdk-root.sh`, `check-fresh.sh`, and append-only `records/`. |

Only `ARRAY_N` 4 and 8 elaborate in the origin RTL, so the item-1 netlist is
**`ARRAY_N = 8`**, an interim below the 16 x 16 fallback (decision 0004).

Regenerate: `rtl/synth/synth.sh` (about 4 minutes, 320 MB, single job), then copy the
result into a new dated directory under `rtl/synth/records/`. Check freshness:
`rtl/synth/check-fresh.sh` (exit 0 fresh, 3 stale).
