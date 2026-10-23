# 0001: ASAP7 pin and `klt` bring-up

- Status: proposed
- Date: 2026-10-17
- Issue: #3

## Context

ASAP7 is a predictive PDK and is not in the fleet's `open_pdks` store. The
README asks to adopt `asap7-riscv-core`'s pinned bring-up if there is one.

## Findings

**No bring-up to adopt.** `2AMLogic/asap7-riscv-core` `main` @
`0167330411f8a01ea72fde72d7b3db2976a6e95a` holds only placeholder READMEs under
`spec/`, `rtl/`, `verification/` and `layout/`. This record brings it up here.
Re-check that repo before ratifying; adopt its pin if one has landed.

## Decision: the pin

Upstream `The-OpenROAD-Project/asap7` @ `d24f8b857ff74cf5b21ab18a7e1b11a3954c449b`
(committed 2025-03-12). It is a set of submodules; those used here:

| Part | Repo | Commit |
|---|---|---|
| PDK (docs, models, Cadence layermaps) | `asap7_pdk_r1p7` | `58d72c9d291e186a77468586ab0c43d8a21eda6a` |
| 7.5-track cell library (GDS, LEF, Liberty) | `asap7sc7p5t_28` | `f970bd3c3292b79ae4d022a3ec80533534614066` |
| SRAM bank views (reference only, see 0002) | `asap7_sram_0p0` | `522eeccbccefcd66e61893fa1059df24d95e9f86` |

`asap7sc7p5t_27` (`adb6d0d354e76e46a782ad06498f1977257d5742`) and `asap7sc6t_26`
(`390b49923f5e9acb4f0a945c2590c5627c89bcdb`) are not used. Licence: BSD-3-Clause.
Read at the pin: the top-level `LICENSE` and `asap7sc7p5t_28/license/LICENSE.txt`
(both BSD 3-Clause, ASU copyright). The other submodule `LICENSE` files were not read.

Files used from `asap7sc7p5t_28`: `GDS/asap7sc7p5t_28_R_220121a.gds`,
`LEF/asap7sc7p5t_28_R_1x_220121a.lef`, `techlef_misc/asap7_tech_1x_201209.lef`,
and `LIB/NLDM/*_RVT_{SS,TT,FF}_nldm_*.lib.7z` (names in `spec/npu.md`). Layer
maps: `asap7_pdk_r1p7/cdslib/asap7_TechLib_10/asap7_TechLib_08.layermap`.

## Bring-up result under `klt`

Host: `loom-worker-3`, `klt 0.7.1.dev1757+ge7cca478ef21`, KLayout 0.28.16.
Run 2026-10-17 against a checkout of the pin in a scratch directory outside the repo.

| Step | Command | Result |
|---|---|---|
| Resolve the PDK | `klt pdk find --pdk-root <checkout> --pdk asap7` (also with `<checkout>/asap7sc7p5t_28`) | **Does not resolve.** "no supported-layout PDK install ... was found". `klt pdk check` the same. |
| Read the cell GDS | `klt cells asap7sc7p5t_28/GDS/asap7sc7p5t_28_R_220121a.gds` | **Works.** 212 cells, `dbu_um` 0.00025. |
| Read the SRAM bank GDS | `klt cells asap7_sram_0p0/gds/srambank_{32,64,128}b.gds` | **Works.** 108, 112, 112 cells; `dbu_um` 0.00025. |
| DRC | `klt drc --deck asap7 ...` and `--list-rules` | **Refused.** `unknown deck 'asap7' (available: gf180mcu, sg13cmos5l, sg13g2, sky130)`, although `klt drc --help` lists `asap7`. |
| Deck rules | `klt deck rules --deck asap7` | **Refused**, same message. |
| Deck info | `klt deck info` | asap7: `sha256:30a8d86cc36f99ffc54b0c86ab69a737acd91ba0fd21f6de3c842f9fba9d2aaf`, device classes `nfet, pfet`, released 0.7.0. |
| Deck devices | `klt deck devices --deck asap7` | Works; lists `nmos_rvt` among the classes. |
| Liberty | not exercised | Shipped as `.lib.7z`; no `7z` on the host and host tools are not changed. `klt synthesize` resolves liberty through `klt pdk`, which does not resolve this tree. |
| KLayout tech (`.lyt`/`.lyp`) | not found | None in the pinned upstream tree; only Cadence `.layermap` files. |

**Conclusion: ASAP7 does not yet fully resolve under `klt`.** Layout streams are
readable and the extraction deck is identified, but PDK resolution, the DRC deck
and Liberty resolution are not available from `klt` for this tree. The flow
bring-up (a later ladder step) must supply those paths explicitly or wait on the
tool gaps below. This is a result, recorded as such.

## Missing DRC / LVS rules

- DRC: the upstream tree ships no DRC deck for open tools. `calibre/ruledirs/{drc,lvs,rcx}`
  in `asap7_pdk_r1p7` contain only a `README.txt` each. `klt` has no registered
  `asap7` DRC rules on this build (above). A full-chip "clean" cannot be claimed
  until a deck exists; until then any run is "clean against the deck subset".
- Known `klt` gaps, filed earlier by others: `klayout-tools#2760` (DRC deck),
  `#2812` (FEOL/MOL gap tracker), `#3147` (BEOL rules needing track, net, corner
  or grid predicates). Closed: `#2758`, `#3155`, `#3156`, `#2761`.
- LVS: `klt deck devices` lists only `nfet`/`pfet` classes for asap7, so only
  RVT-flavor MOS devices are recognised; other Vt flavors, if ever used, are not.

## Gaps filed at `2AMLogic/klayout-tools`

- `#3782`: `pdk`/`synthesize` cannot resolve a non-open_pdks PDK tree; Liberty ships only as `.7z`.
- `#3783`: `drc`/`deck`: `asap7` listed in help and `deck info` but rejected as unknown by `drc` and `deck rules`.

## Consequences

The pin is what later steps use. The spec's "ASAP7 resolves under `klt`" gate is
met for layout reading only; the rest is open and tracked by the issues above.

## Superseded in part by 0003 (2026-10-23)

The "No bring-up to adopt" finding is out of date: `asap7-riscv-core` has landed
one. [0003](0003-adopt-asap7-riscv-core-bring-up.md) adopts it by reference and
records, row by row, where this record's pins agree and where they differ (`klt`
pin, DRC deck, LVS options). The findings above are unchanged.
