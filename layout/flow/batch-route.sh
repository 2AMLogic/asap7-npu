#!/usr/bin/env bash
#
# layout/flow/batch-route.sh -- run layout/flow/run.sh as a `repo-script` job on
# the batch fleet (2am infra/aws/repo-script-batch.md), where one long P&R unit
# fits and a shared dispatch worker is not occupied for hours. Submit with:
#
#   <2am>/infra/aws/repo-script-submit.py --source-dir . --script layout/flow/batch-route.sh \
#       --output layout/records/<RECORD_DATE>-asap7-n8 --issue 23 --capacity on-demand \
#       --shard "<RECORD_DATE>"
#
# Argument 1 is the record date label (run.sh's RECORD_DATE). The instance's
# tools are the batch image's; the first lines of the log say which are missing
# if the image cannot run the flow. OpenROAD threads default to the instance's
# cores here (the 2-thread cap in run.sh is for the shared worker only).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
export RECORD_DATE="${1:?usage: batch-route.sh RECORD_DATE}"
for t in klt openroad yosys python3 git; do
  if command -v "$t" >/dev/null 2>&1; then echo "batch-route: $t -> $(command -v "$t")"
  else echo "batch-route: MISSING tool: $t" >&2; fi
done
export OPENROAD_THREADS="${OPENROAD_THREADS:-$(nproc)}"
export FLOW_TIMEOUT_S="${FLOW_TIMEOUT_S:-6600}"
exec layout/flow/run.sh
