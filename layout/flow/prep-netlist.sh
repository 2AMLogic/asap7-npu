#!/usr/bin/env bash
#
# layout/flow/prep-netlist.sh SYNTH_NETLIST PDK_ROOT OUT_DIR -- derive the
# netlist OpenROAD reads from item 1's attested netlist (which is not modified).
#
#   1. Yosys `hilomap`: item 1's netlist still carries constant drivers
#      (`assign x = 1'h0;`). OpenROAD turns them into `zero_`/`one_` nets and
#      TritonRoute stops with DRT-0305 (klt synthesize maps constants onto tie
#      cells only for libraries it knows; ASAP7 is not one). The constants are
#      driven by TIEHIx1/TIELOx1 instead, one per module; `opt_clean` (not
#      -purge) then drops the unused wires.
#   2. prep-netlist.py: the macro instance parameter blocks and escaped names.
#
# Writes OUT_DIR/npu_top_pnr.v and OUT_DIR/renames.json.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNTH="${1:?usage: prep-netlist.sh SYNTH_NETLIST PDK_ROOT OUT_DIR}"
ROOT="${2:?}"
OUT="${3:?}"
LIB="${ROOT}/asap7/asap7sc7p5t_28/lib"
mkdir -p "${OUT}"
{
  for f in "${LIB}"/*.lib; do echo "read_liberty -lib ${f}"; done
  echo "read_verilog ${HERE}/../../rtl/pdk/asap7/npu_sram_bank.v"
  echo "read_verilog ${SYNTH}"
  echo "hierarchy -check -top npu_top"
  echo "hilomap -singleton -hicell TIEHIx1_ASAP7_75t_R H -locell TIELOx1_ASAP7_75t_R L"
  echo "opt_clean"
  echo "write_verilog -noattr ${OUT}/npu_top_tied.v"
} >"${OUT}/tie.ys"
yosys -q -l "${OUT}/tie.log" "${OUT}/tie.ys"
python3 -I "${HERE}/prep-netlist.py" "${OUT}/npu_top_tied.v" "${OUT}/npu_top_pnr.v" "${OUT}/renames.json" >/dev/null
