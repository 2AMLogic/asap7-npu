#!/usr/bin/env bash
#
# layout/flow/run.sh [SYNTH_RECORD] -- item 1's gate-level netlist -> routed GDS.
#
#   layout/flow/run.sh                                   # the n8 synthesis record
#   RECORD_DATE=2026-11-02 layout/flow/run.sh rtl/synth/records/<date>-asap7-n16
#
# SYNTH_RECORD is a directory under rtl/synth/records/ named <date>-asap7-n<N>;
# the array size N, the netlist area and the macro instances come from it, so
# the flow takes the size from the netlist it is given. One job: `klt
# place-and-route` runs OpenROAD (through the host's container wrapper, capped at
# OPENROAD_THREADS, default 2, by layout/flow/bin/openroad). Writes an
# append-only record layout/records/<RECORD_DATE>-asap7-n<N>/ (default date:
# today, UTC); refuses an existing one. A run that does not finish is recorded
# too, with its elapsed time and last peak memory.
#
# Everything is a tool result against a predictive model (ASAP7); nothing here
# is fabricated or measured on silicon, and timing is "predicted".
#
# Environment:
#   PDK_ROOT         throwaway ASAP7 root (built by make-pdk-root.sh if missing)
#                    default: ${TMPDIR:-/tmp}/asap7-npu-pdkroot
#   KLT_CACHE_DIR    where klt writes the merged Liberty; it must be under a path
#                    the openroad wrapper mounts ($PWD, $PDK_ROOT, $TMPDIR)
#                    default: ${TMPDIR:-/tmp}/asap7-npu-klt-cache
#   KLT              klt command (default: klt)
#   RECORD_DATE      record date label (default: today, UTC)
#   FLOW_TIMEOUT_S   stop the run after this many seconds (default 7200)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${HERE}/../.." && pwd)"
cd "${REPO}"
die() { echo "run.sh: $*" >&2; exit "${2:-2}"; }

REC_IN="${1:-rtl/synth/records/2026-10-27-asap7-n8}"
REC_IN="${REC_IN%/}"
[[ -f "${REC_IN}/npu_top_synth.v" && -f "${REC_IN}/envelope.json" ]] || die "not a synthesis record: ${REC_IN}"
[[ "$(basename "${REC_IN}")" =~ -asap7-n([0-9]+)$ ]] || die "record name must end in -asap7-n<N>: ${REC_IN}"
N="${BASH_REMATCH[1]}"
DATE="${RECORD_DATE:-$(date -u +%Y-%m-%d)}"
OUT="layout/records/${DATE}-asap7-n${N}"
[[ ! -e "${OUT}" ]] || die "${OUT} exists; records are append-only: set RECORD_DATE to a new label"

TMP="${TMPDIR:-/tmp}"
export PDK_ROOT="${PDK_ROOT:-${TMP}/asap7-npu-pdkroot}"
export KLT_CACHE_DIR="${KLT_CACHE_DIR:-${TMP}/asap7-npu-klt-cache}"
export OPENROAD_THREADS="${OPENROAD_THREADS:-2}"
export PATH="${HERE}/bin:${PATH}"
read -r -a KLT <<<"${KLT:-klt}"
WORK="${HERE}/work"
rm -rf "${WORK}"
mkdir -p "${WORK}"

# 1. PDK root with the physical views (idempotent)
grep -q '"views"' "${PDK_ROOT}/asap7/klt-pdk.json" 2>/dev/null || "${HERE}/make-pdk-root.sh" "${PDK_ROOT}"

# 2. macro LEF: regenerate and require it to match the committed one
python3 -I "${HERE}/gen-macro-lef.py" >"${WORK}/npu_sram_bank.lef"
cmp -s "${WORK}/npu_sram_bank.lef" layout/macros/npu_sram_bank.lef \
  || die "layout/macros/npu_sram_bank.lef differs from gen-macro-lef.py output: regenerate and commit it" 1

# 3. netlist OpenROAD reads, and the request
"${HERE}/prep-netlist.sh" "${REPO}/${REC_IN}/npu_top_synth.v" "${PDK_ROOT}" "${WORK}"
python3 -I "${HERE}/make-request.py" "${REC_IN}" layout/macros/npu_sram_bank.lef "${WORK}/renames.json" "${WORK}/request.json"

# 4. place and route, timed from outside the tool
LOAD_BEFORE="$(cut -d' ' -f1-3 /proc/loadavg)"
START="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
CMD=("${KLT[@]}" place-and-route "${WORK}/request.json" --pdk asap7 --pdk-root "${PDK_ROOT}" --format json)
# The openroad wrapper runs a container that outlives a killed client; after a
# timeout stop the ones that mount this checkout so no process outlives the run.
stop_containers() {
  local c
  for c in $(docker ps -q 2>/dev/null); do
    if docker inspect -f '{{range .Mounts}}{{.Source}} {{end}}' "${c}" 2>/dev/null | grep -q "${REPO}"; then
      docker kill "${c}" >/dev/null 2>&1 || true
    fi
  done
}
trap stop_containers INT TERM
RC=0
/usr/bin/time -v -o "${WORK}/time-v.txt" timeout --kill-after=60 "${FLOW_TIMEOUT_S:-7200}" \
  "${CMD[@]}" >"${WORK}/report.json" 2>"${WORK}/klt.stderr" || RC=$?
[[ "${RC}" -eq 0 ]] || stop_containers
END="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LOAD_AFTER="$(cut -d' ' -f1-3 /proc/loadavg)"

# 5. record
mkdir -p "${OUT}"
cp "${WORK}/request.json" "${WORK}/renames.json" "${WORK}/time-v.txt" "${WORK}/tie.ys" "${OUT}/"
cp "${WORK}/npu_top_pnr.v" "${OUT}/npu_top_pnr_in.v"
cp "${WORK}/klt.stderr" "${OUT}/klt.stderr.txt"
python3 -I "${HERE}/write-record.py" "${WORK}/report.json" "${OUT}" "${RC}" "${START}" "${END}" \
  "${LOAD_BEFORE}" "${LOAD_AFTER}" "${REC_IN}" "${KLT[*]}" "${OPENROAD_THREADS}"
( cd "${OUT}" && sha256sum request.json npu_top_pnr_in.v renames.json ../../macros/npu_sram_bank.lef \
    "../../../${REC_IN}/npu_top_synth.v" >inputs.sha256 )
{
  echo "klt: $("${KLT[@]}" --version)"
  echo "openroad: $(openroad -version 2>&1 | head -1)"
  echo "yosys: $(yosys -V 2>&1 | head -1)"
  for f in "${PDK_ROOT}"/asap7/asap7sc7p5t_28/views/*; do echo "pdk-view: $(sha256sum "${f}" | cut -d' ' -f1)  $(basename "${f}")"; done
} >"${OUT}/tool-versions.txt"
echo "run.sh: record ${OUT} (klt exit ${RC})" >&2
exit "${RC}"
