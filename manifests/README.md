# manifests/

The block's signoff manifest and its graded report. `klt signoff` grades the
manifest against the T1 evidence tiers; CI re-grades it on every PR and push.

| File | Role |
|---|---|
| `asap7-npu.json` | The block manifest. Hand-edited: one `evidence` entry per T1 item, each citing a file and a `content_hash` (see "What `content_hash` cites"). An item with no entry grades `unmet`. |
| `asap7-npu.signoff.json` | The graded report. **Generated; do not hand-edit.** |
| `spec-rows.json` | Hand-edited: one `id` per requirement row of `spec/npu.md` for T1 item 6 (ids are slugs, defined in the file's `note`; the Open questions table is excluded). |
| `item6-na-statement.json` | Hand-edited: one `{id, class, reason}` per spec row, same id set as `spec-rows.json`, saying why the row is not statistical. Both item 6 files are hash-cited from the manifest. |
| `inventories/item-10.json` | Hand-edited attestation inventory for T1 item 10 (repo hygiene). Its hash is the one the manifest cites for item 10. |
| `attestations/item-10.json` | The `klt signoff --attest 10` envelope. **Generated; do not hand-edit.** It is the file the manifest cites for item 10 — under the inventory's hash, not its own. |

The `klt` pin is a full commit SHA recorded in one place:
[`.github/workflows/signoff.yml`](../.github/workflows/signoff.yml).

## What `content_hash` cites

An `evidence` entry that cites a **`klt signoff --attest` envelope** (items 1
and 10) carries the `sha256` of that envelope's **input inventory** — the file
named at `provenance.input.path` inside the envelope — **not** of
`evidence.<N>.file` itself. `--attest --inventory` pins the inventory's hash
into the envelope it writes; the grader re-reads the inventory, compares, and
records the match as `citation.input_verified` in the report. An entry that
cites a plain hand-edited file (item 6's `spec-rows.json` and
`item6-na-statement.json`) carries the hash of that file.

The consequence for maintenance: **re-attesting never changes the value the
manifest cites — only editing an inventory does.** Replacing a cited inventory
hash with the envelope's own `sha256` grades the item `unmet` with
`reason: "stale_evidence"`, which drops `t1_met_count` and fails the CI diff
gate.

## Regenerate

From the repo root, with `<sha>` the pin in the workflow file:

```
uvx --from "klayout-tools @ git+https://github.com/2AMLogic/klayout-tools@<sha>" \
  klt signoff --manifest manifests/asap7-npu.json --format json \
  > manifests/asap7-npu.signoff.json
```

Exit 3 means "not yet T1" and is expected today; exit 0 means T1 reached. Any
other exit is a failure.

Whether the report needs regenerating at all depends on what changed. Both
cases start by re-attesting item 10:

```
klt signoff --attest 10 --inventory manifests/inventories/item-10.json \
  -o manifests/attestations/item-10.json
```

**An inventoried file changed** (`README.md`, `LICENSE` or
`.github/workflows/signoff.yml` — the `hygiene` list in
`inventories/item-10.json`): re-attest, and stop. The cited `content_hash` is
the inventory's, and the inventory did not change, so the manifest needs no
edit and the graded report is byte-identical. The re-attest is still required:
CI re-runs it and `--check`s the committed envelope
([`signoff.yml`](../.github/workflows/signoff.yml)), so a stale envelope fails
the build.

**The inventory itself changed** (`inventories/item-10.json` — a file added to
`hygiene`, a check added or edited): re-attest, update item 10's
`content_hash` in `asap7-npu.json` to the new `sha256sum` **of the inventory**,
then regenerate the report last.

## CI gate

`.github/workflows/signoff.yml` re-runs the grading command above and fails if
its output differs from the committed report, or if `klt` exits with anything
but 0 or 3. A manifest edit therefore lands together with a regenerated report,
and **a `klt` pin bump lands with a regenerated report**. It then re-attests
item 10 and `--check`s the committed envelope, so an envelope left stale by a
change to an inventoried file fails the build even though no report changed.

## Item 1 evidence

`item-1.inventory.json` is the `klt signoff --attest 1` inventory;
`evidence/item1.json` is its envelope, cited from `asap7-npu.json`. The attested
netlist is **`ARRAY_N = 8`** (interim; decision 0004). The same two cases apply,
both starting from a re-attest:

```
klt signoff --attest 1 --inventory manifests/item-1.inventory.json \
  -o manifests/evidence/item1.json
```

**A file the inventory lists changed** (an RTL source, the synthesized
netlist): re-attest, and stop — the cited `content_hash` is
`item-1.inventory.json`'s and does not move, so neither the manifest nor the
report changes.

**`item-1.inventory.json` itself changed** (a source added or removed, the
`derived` entry repointed): re-attest, put the inventory's new `sha256sum` in
the manifest, then regenerate the report last.

## Item 6 evidence (`not_applicable`)

The ratified spec has no statistical row, so item 6 is discharged by a recorded
`not_applicable`: `spec-rows.json` (the ratified rows) and
`item6-na-statement.json` (a class and reason for each) are cited from the
manifest under `evidence."6".not_applicable` with their `content_hash`. The
`class` vocabulary is the origin's (`sky130-npu/manifests/`). Keep the two files
in step with `spec/npu.md`: when a counted row is added or removed, change both
files, recompute both hashes **after the final edit of each file**, then
regenerate the report last. Avoid ids that sound statistical (`klt` flags them
as `not_applicable_statistical_row`, which is why the Monte Carlo line's id is
`no-statistical-row`).
