# 0003: adopt the `asap7-riscv-core` ASAP7 bring-up

- Status: proposed
- Date: 2026-10-23
- Issue: #17
- Amends: 0001 (in part)

ASAP7 is a predictive PDK. This block is layout, DRC and timing only and is
never fabricated; every value below is a tool result against a predictive model,
quoted from another repo, not re-measured here.

## Context

0001 (2026-10-17) found no bring-up to adopt: `2AMLogic/asap7-riscv-core` `main`
was then `0167330411f8a01ea72fde72d7b3db2976a6e95a`, placeholders only, and 0001
said to re-check before ratifying. That repo has since landed one.

## Decision

Adopt the bring-up recorded in
`2AMLogic/asap7-riscv-core@22aa18094ea448efc536559d988c6049d92ac4c7`
(`main` as read on 2026-10-23), by reference. The sources are `spec/pdk-bringup.md`
and `spec/decisions/0001`, `0002` and `0005` at that commit. The DRC deck hash,
the `klt` pin and the LVS acceptance rule are **not copied here**: this repo
uses the values at that commit. Moving to a later commit needs a new decision
record.

## Comparison with 0001

| Item | 0001 here | `asap7-riscv-core@22aa180` | Verdict and what this repo uses |
|---|---|---|---|
| `asap7` upstream | `d24f8b857ff74cf5b21ab18a7e1b11a3954c449b` | same | same |
| `asap7sc7p5t_28` | `f970bd3c3292b79ae4d022a3ec80533534614066` | same | same |
| `asap7_pdk_r1p7` | `58d72c9d291e186a77468586ab0c43d8a21eda6a` | same | same |
| `asap7sc7p5t_27` (unused) | `adb6d0d354e76e46a782ad06498f1977257d5742` | fetched, not selected | same |
| `asap7sc6t_26` (unused) | `390b49923f5e9acb4f0a945c2590c5627c89bcdb` | not listed | differs: not pinned there. This repo keeps the 0001 pin; it is unused, so the difference has no effect on results. |
| `asap7_sram_0p0` | `522eeccbccefcd66e61893fa1059df24d95e9f86` | not listed | differs: this repo keeps it as a reference-only view for the abstract macros in 0002; the other repo has no memory macros to need it. |
| `klt` and KLayout | `0.7.1.dev1757+ge7cca478ef21`, KLayout 0.28.16 | released `0.7.0` (KLayout 0.30.12); dev `0.7.1.dev1743+g7ee09483b748` | differs: this repo adopts the dev pin `7ee09483b748`, because the released 0.7.0 deck covers FEOL and MOL only (see the next row) and a metal-stack DRC claim needs the full deck. The 0001 dev pin `e7cca478ef21` is superseded; its results were not re-run. |
| DRC deck | `sha256:30a8d86c...2aaf` from `klt deck info` | `sha256:08dba3ee047a3ec68b3cd761f982809c62a0d128b8d34ef4e76a28f61221aa6a` (263 categories, `provenance.deck.content_hash`), and `a14ce43a...dbd0` for released 0.7.0 (106 categories) | differs, and these are **different quantities**: `30a8d86c...` is the `deck info` content hash (the other repo records the same value for 0.7.0 in its section 2); `08dba3ee...` and `a14ce43a...` are the hashes of the deck file the run used. This repo adopts `08dba3ee...` as its DRC deck, by reference to decision 0005 there. The `deck info` hash is kept as an identifier of the released deck only. |
| LVS | only `nfet` and `pfet` classes noted | `finfet_bulk` opt-in assumption (`{"nmos":"VSS","pmos":"VDD"}`), `match` on 3 cells | differs: 0001 did not cover it. Adopted by reference, as a disclosed assumption, not a silent one. |

## Not established here

- Whether a released `klt` now carries the full deck. `klayout-tools` #3826 is
  closed (completed); the contents of any release were not checked, so this
  record does not claim one does. Until checked, the dev pin above stands.
- That the dev pin `7ee09483b748` resolves under `uvx`. The commit exists in
  `2AMLogic/klayout-tools` (checked by API 2026-10-23); installing it was not
  re-run.
- Anything the other repo marks as not compared or not re-measured, including
  its Liberty FF-corner anomaly (its section 5): this repo has the same
  Liberty files and inherits the open question.

## Gaps from 0001

`klayout-tools` #3782 and #3783 are closed (completed). 0001's findings stay as
recorded on 2026-10-17; whether the closures change them here has not been
re-run.

## Consequences

One pinned bring-up serves both ASAP7 repos. 0001's findings are unchanged and
carry an appended note. The README ladder line and the DRC/LVS section of
`spec/npu.md` point here for the deck and acceptance wording.
