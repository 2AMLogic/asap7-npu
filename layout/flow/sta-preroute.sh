#!/usr/bin/env bash
#
# layout/flow/sta-preroute.sh [SYNTH_RECORD] -- pre-route multi-corner `klt sta`
# bring-up on item 1's committed synthesized netlist (issue #80). One job:
# a single `klt sta` request characterizes the same netlist at the three
# spec/npu.md corners (RVT_SS, RVT_TT, RVT_FF) with the placeholder macro
# Liberty views read at every corner. Writes an append-only record
# rtl/synth/records/<RECORD_DATE>-sta-preroute-n<N>/ (default date: today, UTC;
# refuses an existing one). The README.md inside the record is authored from
# the response afterwards; this script writes the mechanical files.
#
#   layout/flow/sta-preroute.sh                                   # the n8 record
#   RECORD_DATE=2026-12-01 layout/flow/sta-preroute.sh rtl/synth/records/<date>-asap7-n<N>
#
# The attested netlist is not modified: prep-netlist.sh derives the netlist
# OpenSTA reads (tie cells + macro instance renames), the same derivation the
# place-and-route flow uses. The committed request runs byte-for-byte
# unchanged: every input it names is staged under sta-inputs/ beside the
# staged copy. A PRE-ROUTE result: geometry_source "netlist_estimate", ideal
# clock, no wire parasitics of any kind. Everything is a tool result against a
# predictive model (ASAP7); timing is "predicted", and the macro arcs are
# placeholders (RULE lib-anchored-placeholder-v1), so any slack that depends
# on them is a placeholder result.
#
# Environment:
#   PDK_ROOT         throwaway ASAP7 root (built by layout/flow/make-pdk-root.sh
#                    plus sta-add-corners.sh if missing)
#                    default: ${TMPDIR:-/tmp}/asap7-npu-pdkroot
#   KLT_CACHE_DIR    where klt writes the merged Liberty; must be under a path
#                    the openroad wrapper mounts ($PWD, $PDK_ROOT, $TMPDIR)
#                    default: ${TMPDIR:-/tmp}/asap7-npu-klt-cache
#   KLT              klt command (default: klt)
#   RECORD_DATE      record date label (default: today, UTC)
#   FLOW_TIMEOUT_S   stop the run after this many seconds (default 3600)
#   OPENROAD_THREADS thread cap applied by bin/openroad (default 2)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${HERE}/../.." && pwd)"
cd "${REPO}"
die() { echo "sta-preroute.sh: $*" >&2; exit "${2:-2}"; }

REC_IN="${1:-rtl/synth/records/2026-10-27-asap7-n8}"
REC_IN="${REC_IN%/}"
[[ -f "${REC_IN}/npu_top_synth.v" && -f "${REC_IN}/envelope.json" ]] || die "not a synthesis record: ${REC_IN}"
[[ "$(basename "${REC_IN}")" =~ -asap7-n([0-9]+)$ ]] || die "record name must end in -asap7-n<N>: ${REC_IN}"
N="${BASH_REMATCH[1]}"
DATE="${RECORD_DATE:-$(date -u +%Y-%m-%d)}"
OUT="rtl/synth/records/${DATE}-sta-preroute-n${N}"
[[ ! -e "${OUT}" ]] || die "${OUT} exists; records are append-only: set RECORD_DATE to a new label"

TMP="${TMPDIR:-/tmp}"
export PDK_ROOT="${PDK_ROOT:-${TMP}/asap7-npu-pdkroot}"
export KLT_CACHE_DIR="${KLT_CACHE_DIR:-${TMP}/asap7-npu-klt-cache}"
export OPENROAD_THREADS="${OPENROAD_THREADS:-2}"
export PATH="${HERE}/bin:${PATH}"
read -r -a KLT <<<"${KLT:-klt}"
WORK="${HERE}/sta-work"
rm -rf "${WORK}"
mkdir -p "${WORK}/sta-inputs" "${WORK}/gen-libs"

# 1. PDK root: TT Liberty + physical views (layout flow's script, which builds
#    on rtl/synth/make-pdk-root.sh), then the SS/FF corner groups
grep -q '"views"' "${PDK_ROOT}/asap7/klt-pdk.json" 2>/dev/null || "${HERE}/make-pdk-root.sh" "${PDK_ROOT}"
"${HERE}/sta-add-corners.sh" "${PDK_ROOT}"

# 2. macro views: regenerate LEF and the three Liberty views, and require them
#    to match the committed bytes
python3 -I "${HERE}/gen-macro-lef.py" >"${WORK}/sta-inputs/npu_sram_bank.lef"
cmp -s "${WORK}/sta-inputs/npu_sram_bank.lef" layout/macros/npu_sram_bank.lef \
  || die "layout/macros/npu_sram_bank.lef differs from gen-macro-lef.py output: regenerate and commit it" 1
python3 -I "${HERE}/gen-macro-lib.py" "${WORK}/gen-libs" >/dev/null
for c in ss tt ff; do
  cmp -s "${WORK}/gen-libs/npu_sram_bank_${c}.lib" "layout/macros/npu_sram_bank_${c}.lib" \
    || die "layout/macros/npu_sram_bank_${c}.lib differs from gen-macro-lib.py output: regenerate and commit it" 1
  cp "${WORK}/gen-libs/npu_sram_bank_${c}.lib" "${WORK}/sta-inputs/"
done

# 3. netlist OpenSTA reads (derived; the attested netlist is not modified)
"${HERE}/prep-netlist.sh" "${REPO}/${REC_IN}/npu_top_synth.v" "${PDK_ROOT}" "${WORK}"
cp "${WORK}/npu_top_pnr.v" "${WORK}/sta-inputs/npu_top_sta.v"

# 4. the committed request, byte-for-byte, with its named inputs staged beside it
cp "${HERE}/sta-constraints.sdc" "${WORK}/sta-inputs/"
cp "${HERE}/sta-request.json" "${WORK}/sta-request.json"
MACROS_JSON="$(python3 -I - "${WORK}/renames.json" <<'PY'
import json, sys
renames = json.load(open(sys.argv[1]))
print("\n".join(r["to"] for r in renames if r.get("module") == "npu_sram_bank"))
PY
)"
python3 -I - "${WORK}/sta-request.json" "${MACROS_JSON}" <<'PY'
import json, sys
req = json.load(open(sys.argv[1]))
# npu_banks is instantiated as u_banks inside npu_top (make-request.py spells
# the same prefix), so the linked-design instance path is u_banks/<renamed>
report = req["constraints"]["report_instances"]
expected = sorted("u_banks/" + n for n in sys.argv[2].split())
if sorted(report) != expected:
    sys.exit(f"sta-request.json report_instances {sorted(report)} do not match the "
             f"macro instances prep-netlist.py renamed ({expected}): regenerate the request")
PY

# 5. klt sta, timed from outside the tool
LOAD_BEFORE="$(cut -d' ' -f1-3 /proc/loadavg)"
START="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
CMD=("${KLT[@]}" sta "${WORK}/sta-request.json" --pdk asap7 --pdk-root "${PDK_ROOT}" --format json)
RC=0
/usr/bin/time -v -o "${WORK}/time-v.txt" timeout --kill-after=60 "${FLOW_TIMEOUT_S:-3600}" \
  "${CMD[@]}" >"${WORK}/sta.json" 2>"${WORK}/klt.stderr" || RC=$?
END="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LOAD_AFTER="$(cut -d' ' -f1-3 /proc/loadavg)"

# 6. record
mkdir -p "${OUT}"
cp "${WORK}/sta-request.json" "${OUT}/"
if [[ -f "${WORK}/time-v.txt" ]]; then cp "${WORK}/time-v.txt" "${OUT}/"; fi
cp "${WORK}/sta-inputs/npu_top_sta.v" "${OUT}/npu_top_sta_in.v"
cp "${WORK}/klt.stderr" "${OUT}/klt.stderr.txt"
if [[ -s "${WORK}/sta.json" ]]; then cp "${WORK}/sta.json" "${OUT}/"; fi
( cd "${OUT}" && sha256sum sta-request.json npu_top_sta_in.v \
    ../../../../layout/macros/npu_sram_bank.lef \
    ../../../../layout/macros/npu_sram_bank_ss.lib \
    ../../../../layout/macros/npu_sram_bank_tt.lib \
    ../../../../layout/macros/npu_sram_bank_ff.lib \
    ../../../../layout/flow/sta-constraints.sdc \
    "../../../../${REC_IN}/npu_top_synth.v" >inputs.sha256 )
{
  echo "klt: $("${KLT[@]}" --version)"
  echo "openroad: $(openroad -version 2>&1 | head -1)"
  echo "yosys: $(yosys -V 2>&1 | head -1)"
  for f in "${PDK_ROOT}"/asap7/asap7sc7p5t_28/lib/*.lib; do
    echo "pdk-liberty: $(sha256sum "${f}" | cut -d' ' -f1)  $(basename "${f}")"
  done
  for f in "${PDK_ROOT}"/asap7/asap7sc7p5t_28/views/*; do echo "pdk-view: $(sha256sum "${f}" | cut -d' ' -f1)  $(basename "${f}")"; done
} >"${OUT}/tool-versions.txt"
python3 -I - "${OUT}" "${RC}" "${START}" "${END}" "${LOAD_BEFORE}" "${LOAD_AFTER}" \
  "${REC_IN}" "${KLT[*]}" "${OPENROAD_THREADS}" <<'PY'
import json, os, re, subprocess, sys

out, rc, start, end, load_before, load_after, rec_in, klt, threads = sys.argv[1:11]
try:
    rep = json.load(open(os.path.join(out, "sta.json")))
except Exception:
    rep = {}
status = "finished" if rc == "0" and rep.get("status") == "ok" else "did_not_finish"
try:
    tv = open(os.path.join(out, "time-v.txt")).read()
except Exception:
    tv = ""


def tv_get(pattern):
    m = re.search(pattern, tv)
    return m.group(1) if m else None


wall = tv_get(r"Elapsed \(wall clock\) time \(h:mm:ss or m:ss\): (\S+)")
secs = None
if wall:
    secs = sum(float(v) * 60 ** i for i, v in enumerate(reversed(wall.split(":"))))
peak = tv_get(r"Maximum resident set size \(kbytes\): (\d+)")
meta = {
    "schema": "sta-preroute-record/1",
    "record_id": os.path.basename(out),
    "synth_record": rec_in,
    "outcome": status,
    "klt_exit_code": int(rc),
    "klt_version": subprocess.run(klt.split() + ["--version"], capture_output=True, text=True).stdout.strip(),
    "openroad_version": rep.get("engine_version"),
    "openroad_threads": int(threads),
    "wall_seconds": secs,
    "peak_rss_kib": int(peak) if peak else None,
    "started_utc": start,
    "ended_utc": end,
    "loadavg_before": load_before,
    "loadavg_after": load_after,
    "corners_requested": (rep.get("corners") and [c.get("corner") for c in rep["corners"]]) or None,
}
json.dump(meta, open(os.path.join(out, "run.json"), "w"), indent=2, sort_keys=True)
print(f"outcome: {status}, wall {secs}s, peak rss {peak or '?'} KiB")
PY
echo "sta-preroute.sh: record ${OUT} (klt exit ${RC})" >&2
exit "${RC}"
