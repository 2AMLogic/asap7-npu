# 0002: Memory representation

- Status: proposed
- Date: 2026-10-17
- Issue: #3

## Context

The block needs on-chip memory. `CLAUDE.md` rules out an SRAM bitcell or
compiler here, so memory is represented by abstract macro views. The origin
(`sky130-npu` @ `81be5b3`) has not ratified its banking, so bank count and word
geometry are not decidable here (TRACKED AT ORIGIN: `sky130-npu#3`).

## Options

1. **Abstract macro views generated here.** A parameter table (bank count,
   words, bits) generates, per macro: a LEF abstract (`MACRO`/`PIN`/`OBS`, via
   `klt lef-abstract` from a socket descriptor), a Liberty timing model, and a
   behavioural Verilog model. The macro has no internal layout.
2. **Upstream `asap7_sram_0p0` views as shipped.** The pin ships LEF and Liberty
   for fixed geometries (`srambank_{64,128,256}x4x{16..80}_6t122`; e.g.
   `srambank_64x4x64_6t122` is 9.612 x 77.76 um, 0.7 V, 25 C) and GDS for three
   banks only (`srambank_{32,64,128}b.gds`, which `klt cells` reads).
3. **Synthesized flop arrays.** Rejected: the memory would be standard cells, which
   changes the area and timing question this repo answers.

## Decision (proposed)

Option 1. Memory is an abstract macro view with the three views above, sized
from the origin's banking once ratified. Option 2 is kept as a reference for
plausible macro footprint and timing only: its geometries are fixed, so adopting
them would let the upstream word sizes choose the banking, which belongs to the
origin. A macro-size change from either source is a new decision record.

The macro Liberty model is generated at the three corners in `spec/npu.md`
(SS, TT, FF), so STA sees the same corners as the logic. Its numbers are
placeholders derived from a stated rule, labelled as such, and never presented
as a memory measurement.

## Recorded limitation: black boxes in DRC and LVS

The abstract view has no internal layout, so DRC and LVS treat each macro as a
black box: the interior is not checked, and LVS compares the macro as a
`.subckt` black box matched at its pins. A "clean" result therefore says
nothing about memory internals. Every DRC/LVS result that includes a macro
repeats this limitation.

## Open

Whether the black-box macros pass DRC and LVS in a placed block is not known.
It is answered by the run listed in `spec/npu.md`, Open questions. The
Liberty-model generation rule and the bank table are TRACKED AT ORIGIN until
the origin ratifies banking.
