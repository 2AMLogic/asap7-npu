#!/usr/bin/env bash
#
# rtl/synth/synth.sh [PDK_ROOT] -- regenerate the ARRAY_N = 8 ASAP7 netlist.
#
#   ./rtl/synth/synth.sh /tmp/asap7-pdkroot     # builds the root if missing
#
# Single job; about 4 minutes and 320 MB at ARRAY_N = 8. klt writes its run
# directory under rtl/synth/.klt/ (scratch, not committed); copy a result you
# want to keep into a new dated directory under rtl/synth/records/ (append-only:
# never overwrite an existing record). Everything is a predicted result against
# a predictive model.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${1:-${TMPDIR:-/tmp}/asap7-npu-pdkroot}"
[ -f "${ROOT}/asap7/klt-pdk.json" ] || "${HERE}/make-pdk-root.sh" "${ROOT}"
/usr/bin/time -v klt synthesize --pdk asap7 --pdk-root "${ROOT}" --format json "${HERE}/synth-request.json"
