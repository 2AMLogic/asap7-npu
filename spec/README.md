# spec

The target specification and its decision records. Nothing here is ratified;
ratification is a human act.

| File | What |
|---|---|
| [`npu.md`](npu.md) | Target spec: inherited items (tracked at the origin), re-derived items, open questions. Status: proposed. |
| [`tool-scaling-record.md`](tool-scaling-record.md) | Format for the per-run DRC/LVS runtime and peak-memory records, and the array sizes to sweep. |
| [`decisions/0001-asap7-pin-and-klt-bring-up.md`](decisions/0001-asap7-pin-and-klt-bring-up.md) | ASAP7 pin, `klt` bring-up result, missing DRC/LVS rules. |
| [`decisions/0002-memory-representation.md`](decisions/0002-memory-representation.md) | Abstract macro views for on-chip memory, and the black-box DRC/LVS limitation. |

ASAP7 is a predictive PDK. This block is layout, DRC and timing only and is
never fabricated.
