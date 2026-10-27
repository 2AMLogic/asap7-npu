# 0004: attest T1 item 1 at `ARRAY_N = 8` as an interim

- Status: proposed
- Date: 2026-10-27
- Issue: #22

ASAP7 is a predictive PDK. This block is never fabricated; every figure below is
a tool result against a predictive model.

## Context

The target is 32 x 32 and the fallback is 16 x 16 (`spec/npu.md`, proposed). The
stamped origin RTL (`sky130-npu` @ `c5a8548`) accepts `ARRAY_N` 4 and 8 only.
Elaborating `npu_top` with `ARRAY_N = 16` fails with
`ERROR_ARRAY_N_must_be_4_or_8__16_is_legal_in_the_spec_but_not_implemented__see_rtl_README`
(reproduced here with Yosys `hierarchy -check`, 2026-10-27). The origin README
says adding 16 is a change to `npu_banks` and the bank-role map. Neither size
can be built by changing only the array parameter.

## Decision (proposed)

1. T1 item 1 is attested at **`ARRAY_N = 8`**, an interim size below the 16 x 16
   fallback. Every artifact and citation names the size. This does not claim the
   target or the fallback.
2. 16 x 16 and 32 x 32 are **blocked at the origin**. Unblock: the origin
   implements and ratifies a larger legal `ARRAY_N` (asked at `sky130-npu#52`),
   this repo re-stamps at the new commit, regenerates the netlist
   (`rtl/synth/synth.sh`) and re-attests. Forking `npu_banks.v` here is rejected
   (stamped-file edit).
3. The memory seam `rtl/pdk/asap7/npu_sram_bank.v` is authored here (the origin's
   seam is sky130-specific and not stamped), keeps the origin port list and
   timing contract, and is a `(* blackbox *)` module, per decision 0002.
   Black-box area is excluded from the reported area.

## Consequences

- The synthesis record (`rtl/synth/records/2026-10-27-asap7-n8/`) is the first
  synthesis runtime and memory row for the scale experiment: 3:45 wall clock,
  223 s user CPU, 318 MB peak resident, 77,834 mapped instances, one job.
  It is `ARRAY_N = 8`, not a scale figure for the target.
- The mapped area (7,770.5 um^2, of which 1,337.0 um^2 sequential) excludes the
  four memory macros and carries no timing: `klt synthesize` reports `timing:
  null` here (no gate-level STA stage in the installed build) and skipped
  constraint-driven mapping for this cell library. It is a netlist, not a
  timing or area claim.
- `klt synthesize` has no ASAP7 PDK install to resolve in this fleet. The run
  used a throwaway root built by `rtl/synth/make-pdk-root.sh` from
  `asap7sc7p5t_28` @ `f970bd3` (the decision 0001 pin), RVT/TT. Its Liberty files
  needed header normalisation to merge (library name/date, one file's template
  names, one `default_max_transition`; no cell data changed), tracked at
  `klayout-tools#4184`. The merged Liberty hash is therefore of a derived file.
- The record was made with host `klt 0.8.1.dev55+g879d39bad82b`, which is not
  the repo's pinned bring-up (decision 0003). The attestation was graded with the
  CI pin in `.github/workflows/signoff.yml`. Moving the pin is #21.
- Item 1 grades `met` from the committed `--attest 1` envelope. Re-attest after
  any change to a source, the request, `make-pdk-root.sh`, or the `klt` version.

## Not established here

- Functional equivalence of the netlist to the RTL (`--verify-equivalence` is
  combinational-only and was not run) and bit-exactness (testbenches: #16).
- Whether the black-boxed bank matches the eventual abstract macro views
  (decision 0002 is proposed).
- Any timing or area at 16 x 16, 32 x 32 or 64 x 64.
