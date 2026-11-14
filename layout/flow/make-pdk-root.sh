#!/usr/bin/env bash
#
# layout/flow/make-pdk-root.sh DEST -- build the throwaway ASAP7 PDK root that
# `klt place-and-route --pdk asap7 --pdk-root DEST` reads. Run it in a scratch
# directory outside this repo.
#
# It first builds the Liberty root of rtl/synth/make-pdk-root.sh (asap7sc7p5t_28
# @ f970bd3, decision 0001 pin; RVT/TT; normalisations listed there), then adds
# the physical views from the same checkout and maps them in klt-pdk.json:
#   cell_lef  LEF/asap7sc7p5t_28_R_1x_220121a.lef
#   tech_lef  techlef_misc/asap7_tech_1x_201209.lef  (unmodified; its M2 OFFSET
#             -0.27 is handled by floorplan.tracks in the request)
#   gds       GDS/asap7sc7p5t_28_R_220121a.gds
# The hashes of these files are recorded by run.sh in each record.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:?usage: make-pdk-root.sh DEST}"
[ -f "${DEST}/asap7/klt-pdk.json" ] || "${HERE}/../../rtl/synth/make-pdk-root.sh" "${DEST}"
SRC="${DEST}.src/cells"
V="${DEST}/asap7/asap7sc7p5t_28/views"
mkdir -p "${V}"
cp "${SRC}/LEF/asap7sc7p5t_28_R_1x_220121a.lef" "${V}/asap7sc7p5t_28_R.lef"
cp "${SRC}/techlef_misc/asap7_tech_1x_201209.lef" "${V}/asap7_tech_1x.lef"
cp "${SRC}/GDS/asap7sc7p5t_28_R_220121a.gds" "${V}/asap7sc7p5t_28_R.gds"
python3 -I - "${DEST}/asap7/klt-pdk.json" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d["views"] = {"asap7sc7p5t_28": {
    "cell_lef": "asap7sc7p5t_28/views/asap7sc7p5t_28_R.lef",
    "tech_lef": {"nom": "asap7sc7p5t_28/views/asap7_tech_1x.lef"},
    "gds": "asap7sc7p5t_28/views/asap7sc7p5t_28_R.gds"}}
json.dump(d, open(p, "w"), indent=1)
PY
echo "physical views mapped in ${DEST}/asap7/klt-pdk.json"
