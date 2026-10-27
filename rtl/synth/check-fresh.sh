#!/usr/bin/env bash
#
# rtl/synth/check-fresh.sh [RECORD_DIR] -- is the committed netlist still the
# product of its inputs? Exit 0 fresh, 3 stale, 1 error.
#
# Stale if any of these changed since the record was made: a stamped or authored
# source, the synthesis request, make-pdk-root.sh (the Liberty normalisation),
# the `klt` version, or the committed netlist itself no longer matches the hash
# in the envelope. PDK-free, so it runs anywhere `klt` is installed; the
# stronger `klt synthesize --check envelope.json request.json` (re-hashes the
# Liberty too) needs the ASAP7 root from make-pdk-root.sh.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REC="${1:-${HERE}/records/2026-10-27-asap7-n8}"
stale=0
(cd "${HERE}" && sha256sum --quiet -c "${REC}/inputs.sha256") || { echo "stale: an input changed" >&2; stale=1; }
want="$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))["netlist_sha256"])' "${REC}/envelope.json")"
have="$(sha256sum "${REC}/npu_top_synth.v" | cut -d' ' -f1)"
[ "${want}" = "${have}" ] || { echo "stale: netlist differs from envelope netlist_sha256" >&2; stale=1; }
[ "$(klt --version)" = "$(cat "${REC}/klt-version.txt")" ] || { echo "stale: klt version is not $(cat "${REC}/klt-version.txt")" >&2; stale=1; }
[ "${stale}" = 0 ] && { echo "fresh: ${REC##*/}"; exit 0; }
exit 3
