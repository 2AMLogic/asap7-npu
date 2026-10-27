# manifests/

The block's signoff manifest and its graded report. `klt signoff` grades the
manifest against the T1 evidence tiers; CI re-grades it on every PR and push.

| File | Role |
|---|---|
| `asap7-npu.json` | The block manifest. Hand-edited: cites the evidence for each T1 item. It starts with empty evidence, so every item grades `unmet`. |
| `asap7-npu.signoff.json` | The graded report. **Generated; do not hand-edit.** |
| `inventories/item-10.json` | Hand-edited attestation inventory for T1 item 10 (repo hygiene). |
| `attestations/item-10.json` | The `klt signoff --attest 10` envelope. **Generated; do not hand-edit.** Its hash is cited from the manifest. |

The `klt` pin is a full commit SHA recorded in one place:
[`.github/workflows/signoff.yml`](../.github/workflows/signoff.yml).

## Regenerate

From the repo root, with `<sha>` the pin in the workflow file:

```
uvx --from "klayout-tools @ git+https://github.com/2AMLogic/klayout-tools@<sha>" \
  klt signoff --manifest manifests/asap7-npu.json --format json \
  > manifests/asap7-npu.signoff.json
```

Regenerate order after any change to an inventoried file or the inventory:
re-attest (`klt signoff --attest 10 --inventory manifests/inventories/item-10.json
-o manifests/attestations/item-10.json`), update the cited `content_hash` in
`asap7-npu.json`, then regenerate the report last.

Exit 3 means "not yet T1" and is expected today; exit 0 means T1 reached. Any
other exit is a failure.

## CI gate

`.github/workflows/signoff.yml` re-runs the command above and fails if its
output differs from the committed report, or if `klt` exits with anything but
0 or 3. A manifest edit therefore lands together with a regenerated report,
and **a `klt` pin bump lands with a regenerated report**.
