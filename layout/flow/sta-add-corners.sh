#!/usr/bin/env bash
#
# layout/flow/sta-add-corners.sh DEST -- add the SS and FF RVT Liberty corner
# groups to a PDK root that layout/flow/make-pdk-root.sh already built, for the
# pre-route multi-corner `klt sta` bring-up (issue #80). The extractor and the
# asap7sc7p5t_28 pin are not duplicated and are not edited: this script never
# fetches, and refuses a root without DEST/asap7/klt-pdk.json -- DEST.src/cells
# is the pinned checkout (f970bd3, decision 0001) that rtl/synth/make-pdk-root.sh
# made, and the SS/FF archives come out of that same checkout. The RVT_TT group
# and every TT .lib byte are untouched: item 1's freshness check hashes
# rtl/synth/make-pdk-root.sh, so growing corners inside that script would mark
# the attested synthesis record stale; the one repeated line is the py7zr
# extraction invocation, kept byte-identical to the one it reuses.
#
# The three header normalisations are the ones rtl/synth/make-pdk-root.sh
# documents, with the corner-appropriate library name
# (asap7sc7p5t_28_RVT_SS / asap7sc7p5t_28_RVT_FF). No cell group, timing table
# or area value is edited. The SIMPLE_RVT_FF header anomaly (spec/npu.md, PVT
# corners: 0.7 V / 25 C header in a 0.77 V / 0 C corner) reaches fields klt's
# merge compares, so the FF corner would not merge at all; for that one file
# the sibling's documented merge rule is applied (header from the first file
# in sorted order, cells from all -- asap7-riscv-core flow/merge_lib.py),
# which makes the corner mergeable. The anomaly is still named in the STA
# record; this is a disclosure aid, not a ratification of FF. Re-running is
# deterministic and cheap (re-extracts from the pinned checkout).
set -euo pipefail
DEST="${1:?usage: sta-add-corners.sh DEST}"
JSON="${DEST}/asap7/klt-pdk.json"
if [[ ! -f "${JSON}" ]]; then
  echo "sta-add-corners.sh: ${JSON} missing; build the root with layout/flow/make-pdk-root.sh first" >&2
  exit 2
fi
SRC="${DEST}.src/cells"
LIB="${DEST}/asap7/asap7sc7p5t_28/lib"
for corner in SS FF; do
  for z in "${SRC}"/LIB/NLDM/*_RVT_${corner}_*.lib.7z; do
    uvx --from py7zr python -c 'import py7zr,sys; py7zr.SevenZipFile(sys.argv[1]).extractall(sys.argv[2])' "$z" "${LIB}"
  done
done
python3 -I - "${DEST}" <<'PY'
import glob, json, os, re, sys

dest = sys.argv[1]
lib = os.path.join(dest, "asap7", "asap7sc7p5t_28", "lib")
groups = {}
for corner in ("SS", "FF"):
    for p in sorted(glob.glob(lib + f"/*_RVT_{corner}_*.lib")):
        t = open(p, errors="replace").read()
        i = t.index("  cell (")
        h, b = t[:i], t[i:]
        h = re.sub(r"library \(\S+\)", f"library (asap7sc7p5t_28_RVT_{corner})", h)
        h = re.sub(r"/\* Models written by.*?\*/", "/* normalised header */", h)
        h = re.sub(r'date : "[^"]*";', 'date : "normalised";', h)
        h = h.replace("default_max_transition : 4000;", "default_max_transition : 320;")
        if "_SEQ_" in p:
            seq_fix = r"\b(delay_template_7x7|passive_power_template_7x1|power_template_7x7)\b"
            h = re.sub(seq_fix, r"\1_x1", h)
            b = re.sub(seq_fix, r"\1_x1", b)
        # SIMPLE_RVT_FF only: the spec/npu.md PVT-corners anomaly (0.7 V / 25 C
        # header in the 0.77 V / 0 C corner) reaches voltage_map/nom_*/
        # operating_conditions and the threshold voltages, and klt's merge
        # refuses the five-file corner on the mismatch. Apply the sibling's
        # documented merge rule (asap7-riscv-core flow/merge_lib.py: the header
        # comes from the first file in sorted order, the cells from all) to
        # this one file: its header becomes the already-normalised AO_FF
        # header, its cell groups are untouched. The anomaly stays disclosed
        # in the STA record -- this makes the corner mergeable, not ratified.
        if "_SIMPLE_RVT_FF_" in p:
            ao = open(sorted(glob.glob(lib + "/*_AO_RVT_FF_*.lib"))[0], errors="replace").read()
            h = ao[:ao.index("  cell (")]
        open(p, "w").write(h + b)
    groups[f"RVT_{corner}"] = sorted(os.path.relpath(p, os.path.dirname(os.path.dirname(lib)))
                                     for p in glob.glob(lib + f"/*_RVT_{corner}_*.lib"))

root = os.path.join(dest, "asap7", "klt-pdk.json")
d = json.load(open(root))
d["liberty"]["asap7sc7p5t_28"].update(groups)
json.dump(d, open(root, "w"), indent=1)
print(f"corner groups added to {root}: " + ", ".join(f"{k}: {len(v)} libs" for k, v in sorted(groups.items())))
PY
