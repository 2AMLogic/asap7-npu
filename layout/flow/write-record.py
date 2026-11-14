#!/usr/bin/env python3
"""write-record.py REPORT OUT RC START END LOAD_BEFORE LOAD_AFTER SYNTH_RECORD KLT THREADS

Called by run.sh: copies the routed GDS, DEF and post-route netlist that the klt
report names into OUT, rewrites the report without host paths, and writes
OUT/run.json (outcome, wall time and peak memory from `/usr/bin/time -v`, host
and load). A run that did not finish still gets run.json with the elapsed time
and last peak memory.
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

report_p, out, rc, start, end, load_before, load_after, rec_in, klt, threads = sys.argv[1:11]
try:
    rep = json.load(open(report_p))
except Exception:
    rep = {}
status = "finished" if rc == "0" and rep.get("status") == "ok" else "did_not_finish"

tv = open(os.path.join(out, "time-v.txt")).read()


def tv_get(pattern):
    m = re.search(pattern, tv)
    return m.group(1) if m else None


wall = tv_get(r"Elapsed \(wall clock\) time \(h:mm:ss or m:ss\): (\S+)")
secs = None
if wall:
    secs = sum(float(v) * 60 ** i for i, v in enumerate(reversed(wall.split(":"))))
peak = tv_get(r"Maximum resident set size \(kbytes\): (\d+)")


def as_path(v):
    return v.get("path") if isinstance(v, dict) else v


copied = {}
for key, name in (("gds_path", "npu_top.gds"), ("def_path", "npu_top.def"), ("verilog_path", "npu_top_postroute.v")):
    p = as_path(rep.get(key))
    if p and os.path.isfile(p):
        shutil.copyfile(p, os.path.join(out, name))
        copied[name] = hashlib.sha256(open(os.path.join(out, name), "rb").read()).hexdigest()
for key in ("gds_path", "def_path", "verilog_path"):
    if key in rep:
        rep[key] = os.path.basename(as_path(rep[key])) if as_path(rep[key]) else None
json.dump(rep, open(os.path.join(out, "report.json"), "w"), indent=2, sort_keys=True)


def first_line(*cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=60).stdout.strip().splitlines()[0]
    except Exception:
        return None


meta = {
    "schema": "layout-pnr-record/1",
    "record_id": os.path.basename(out),
    "synth_record": rec_in,
    "outcome": status,
    "klt_exit_code": int(rc),
    "klt_version": first_line(*klt.split(), "--version"),
    "openroad_version": rep.get("engine_version"),
    "openroad_threads": int(threads),
    "wall_seconds": secs,
    "peak_rss_kib": int(peak) if peak else None,
    "started_utc": start,
    "ended_utc": end,
    "host": {
        "id": os.uname().nodename,
        "cpu_cores": os.cpu_count(),
        "load_avg_before": load_before,
        "load_avg_after": load_after,
        "note": "shared dispatch host; other jobs run concurrently",
    },
    "artifact_sha256": copied,
    "predicted": True,
}
json.dump(meta, open(os.path.join(out, "run.json"), "w"), indent=2)
print(json.dumps({k: meta[k] for k in ("outcome", "wall_seconds", "peak_rss_kib")}))
