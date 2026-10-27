#!/usr/bin/env bash
#
# rtl/synth/make-pdk-root.sh DEST -- build the throwaway ASAP7 PDK root that
# `klt synthesize --pdk asap7 --pdk-root DEST` reads. Run it in a scratch
# directory outside this repo. DEST/asap7 gets a klt-pdk.json descriptor and the
# RVT/TT Liberty files of asap7sc7p5t_28 @ f970bd3 (decision 0001 pin).
#
# Three normalisations are needed because `klt`'s Liberty merge (a list of
# files for one corner) requires identical library headers, and the five
# shipped TT files differ in ways that are not cell data:
#   1. library name, generator comment and date line     -> one shared header
#   2. SEQ file template names (delay_template_7x7 ...)   -> the _x1 names the
#      other four use (definitions are identical; names are renamed everywhere)
#   3. SIMPLE file default_max_transition 4000            -> 320 (the other four)
# No cell group, timing table or area value is edited. Item 3 changes a default
# that cells without their own max_transition would inherit; it does not affect
# the mapping or area `klt synthesize` reports. Recorded in the synthesis record.
set -euo pipefail
DEST="${1:?usage: make-pdk-root.sh DEST}"
CELLS_COMMIT=f970bd3c3292b79ae4d022a3ec80533534614066
mkdir -p "${DEST}.src" "${DEST}/asap7/asap7sc7p5t_28/lib"
cd "${DEST}.src"
git init -q cells
cd cells
git remote add o https://github.com/The-OpenROAD-Project/asap7sc7p5t_28.git
git fetch -q --depth 1 --filter=blob:none o "${CELLS_COMMIT}"
git checkout -q FETCH_HEAD
LIB="${DEST}/asap7/asap7sc7p5t_28/lib"
for z in LIB/NLDM/*_RVT_TT_*.lib.7z; do
  uvx --from py7zr python -c 'import py7zr,sys; py7zr.SevenZipFile(sys.argv[1]).extractall(sys.argv[2])' "$z" "${LIB}"
done
python3 -I - "${LIB}" <<'PY'
import glob, json, os, re, sys
lib = sys.argv[1]
for p in sorted(glob.glob(lib + "/*.lib")):
    t = open(p, errors="replace").read()
    i = t.index("  cell (")
    h, b = t[:i], t[i:]
    h = re.sub(r"library \(\S+\)", "library (asap7sc7p5t_28_RVT_TT)", h)
    h = re.sub(r"/\* Models written by.*?\*/", "/* normalised header */", h)
    h = re.sub(r'date : "[^"]*";', 'date : "normalised";', h)
    h = h.replace("default_max_transition : 4000;", "default_max_transition : 320;")
    t = h + b
    if "_SEQ_" in p:
        t = re.sub(r"\b(delay_template_7x7|passive_power_template_7x1|power_template_7x7)\b", r"\1_x1", t)
    open(p, "w").write(t)
root = os.path.join(lib, "..", "..")
libs = sorted(os.path.relpath(p, root) for p in glob.glob(lib + "/*.lib"))
json.dump({"schema_version": 1, "variant": "asap7", "assets": {"libs_ref": "."},
           "liberty": {"asap7sc7p5t_28": {"RVT_TT": libs}}},
          open(os.path.join(root, "klt-pdk.json"), "w"), indent=1)
PY
echo "PDK root ready: ${DEST} (pass --pdk asap7 --pdk-root ${DEST})"
