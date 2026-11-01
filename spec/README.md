# spec

The target specification and its decision records. `npu.md` is ratified
(decision 0005, merge commit `65d9e28`, 2026-11-01); decisions 0001-0004 are
not ratified by 0005. Ratification is a human act.

| File | What |
|---|---|
| [`npu.md`](npu.md) | Target spec: inherited items (tracked at the origin), re-derived items, open questions. Status: ratified (0005, `65d9e28`); array size 8 x 8. |
| [`tool-scaling-record.md`](tool-scaling-record.md) | Format for the per-run DRC/LVS runtime and peak-memory records, and the array sizes to sweep. |
| [`decisions/0001-asap7-pin-and-klt-bring-up.md`](decisions/0001-asap7-pin-and-klt-bring-up.md) | ASAP7 pin, `klt` bring-up result, missing DRC/LVS rules. |
| [`decisions/0002-memory-representation.md`](decisions/0002-memory-representation.md) | Abstract macro views for on-chip memory, and the black-box DRC/LVS limitation. |
| [`decisions/0003-adopt-asap7-riscv-core-bring-up.md`](decisions/0003-adopt-asap7-riscv-core-bring-up.md) | Adopt `asap7-riscv-core`'s bring-up. Proposed. |
| [`decisions/0004-interim-array-size-for-item-1.md`](decisions/0004-interim-array-size-for-item-1.md) | Interim array size (8 x 8). Proposed; not ratified by 0005. |
| [`decisions/0005-ratify-npu-spec.md`](decisions/0005-ratify-npu-spec.md) | Ratifies `npu.md`. |

ASAP7 is a predictive PDK. This block is layout, DRC and timing only and is
never fabricated.
