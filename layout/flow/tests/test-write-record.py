#!/usr/bin/env python3
"""Regression tests for run.sh's step 5 and layout/flow/write-record.py.

    python3 -I layout/flow/tests/test-write-record.py

Plain asserts, standard library only. Run by .github/workflows/flow-tests.yml.

What is pinned: a run in which `/usr/bin/time` itself never wrote time-v.txt --
it was killed outright rather than its child timing out -- still produces a
record. Two sites had to tolerate the missing file, and only the second is
obvious:

1. run.sh's step-5 `cp` named time-v.txt in its argument list, so under
   `set -euo pipefail` the cp failed and aborted the run one line BEFORE
   write-record.py was reached. Guarding the Python read alone was inert. Worse,
   `mkdir -p "${OUT}"` had already run, so the aborted run left a half-written
   record directory that run.sh's append-only guard then refuses to overwrite --
   the did-not-finish outcome was both unrecorded and un-retryable at the same
   RECORD_DATE.
2. write-record.py read OUT/time-v.txt unguarded and raised.

The step-5 `cp` block is extracted from run.sh itself and executed, so this test
cannot pass against a run.sh that reintroduces the unguarded copy.

No tool, PDK or batch-fleet job is involved: the klt report and the
`/usr/bin/time -v` output are text fixtures. ASAP7 is a predictive PDK and this
block is never fabricated.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
FLOW = os.path.dirname(HERE)
RUN_SH = os.path.join(FLOW, "run.sh")
WRITE_RECORD = os.path.join(FLOW, "write-record.py")

TIME_V = (
    "\tCommand being timed: \"klt place-and-route\"\n"
    "\tElapsed (wall clock) time (h:mm:ss or m:ss): 1:23.45\n"
    "\tMaximum resident set size (kbytes): 123456\n"
)

failures = []


def check(name, cond, detail=""):
    print(f"{'ok  ' if cond else 'FAIL'} {name}" + (f" -- {detail}" if detail else ""))
    if not cond:
        failures.append(name)


def step5_copy_block():
    """run.sh's step-5 copy commands, lifted from the script itself.

    Everything between the `# 5. record` marker and the write-record.py
    invocation: the mkdir and the cp commands, which are what must tolerate a
    missing time-v.txt.
    """
    src = open(RUN_SH, encoding="utf-8").read()
    m = re.search(r"^# 5\. record\n(.*?)^python3 -I \"\$\{HERE\}/write-record\.py\"",
                  src, re.M | re.S)
    assert m, "run.sh no longer has a `# 5. record` block ending at write-record.py"
    block = m.group(1)
    assert "cp " in block, "run.sh step 5 no longer copies anything"
    return block


def run_step5(work, out, block):
    return subprocess.run(["bash", "-c", "set -euo pipefail\n" + block],
                          env={**os.environ, "WORK": work, "OUT": out},
                          capture_output=True, text=True, timeout=120)


def write_record(report, out, rc):
    return subprocess.run(
        [sys.executable, "-I", WRITE_RECORD, report, out, rc,
         "2026-11-14T00:00:00Z", "2026-11-14T00:30:00Z",
         "1.00 2.00 3.00", "4.00 5.00 6.00",
         "rtl/synth/records/2026-10-27-asap7-n8", "true", "2"],
        capture_output=True, text=True, timeout=120)


def make_work(d, with_time_v):
    """A scratch WORK directory as run.sh leaves it before step 5."""
    work = os.path.join(d, "work")
    os.makedirs(work)
    for name in ("request.json", "renames.json", "tie.ys", "npu_top_pnr.v", "klt.stderr"):
        with open(os.path.join(work, name), "w", encoding="utf-8") as fh:
            fh.write("{}\n" if name.endswith(".json") else "")
    if with_time_v:
        with open(os.path.join(work, "time-v.txt"), "w", encoding="utf-8") as fh:
            fh.write(TIME_V)
    return work


block = step5_copy_block()
check("run.sh step 5 no longer copies time-v.txt unconditionally",
      not re.search(r'cp "\$\{WORK\}/request\.json".*time-v\.txt', block),
      block.strip().splitlines()[1] if len(block.strip().splitlines()) > 1 else "")

# --- /usr/bin/time was killed before writing time-v.txt ---
with tempfile.TemporaryDirectory() as d:
    work = make_work(d, with_time_v=False)
    out = os.path.join(d, "records", "2026-11-14-asap7-n8")
    p = run_step5(work, out, block)
    check("step 5 copies survive a missing time-v.txt", p.returncode == 0,
          f"rc={p.returncode} {p.stderr.strip()}")
    # klt was SIGKILLed, so it wrote no report either
    p = write_record(os.path.join(work, "report.json"), out, "137")
    check("write-record.py survives a missing time-v.txt", p.returncode == 0,
          f"rc={p.returncode} {p.stderr.strip()}")
    rj = os.path.join(out, "run.json")
    check("run.json was written", os.path.isfile(rj))
    if os.path.isfile(rj):
        rec = json.load(open(rj))
        check("outcome is did_not_finish", rec["outcome"] == "did_not_finish", rec["outcome"])
        check("wall_seconds is null", rec["wall_seconds"] is None, repr(rec["wall_seconds"]))
        check("peak_rss_kib is null", rec["peak_rss_kib"] is None, repr(rec["peak_rss_kib"]))
        check("klt_exit_code is recorded", rec["klt_exit_code"] == 137, repr(rec["klt_exit_code"]))
        check("the record is labelled predicted", rec.get("predicted") is True)

# --- the ordinary path still reads the timings (the guard must not swallow them) ---
with tempfile.TemporaryDirectory() as d:
    work = make_work(d, with_time_v=True)
    out = os.path.join(d, "records", "2026-11-14-asap7-n8")
    p = run_step5(work, out, block)
    check("step 5 copies time-v.txt when it exists", p.returncode == 0,
          f"rc={p.returncode} {p.stderr.strip()}")
    check("time-v.txt reached the record", os.path.isfile(os.path.join(out, "time-v.txt")))
    with open(os.path.join(work, "report.json"), "w", encoding="utf-8") as fh:
        json.dump({"status": "ok"}, fh)
    p = write_record(os.path.join(work, "report.json"), out, "0")
    check("write-record.py exits 0 on the ordinary path", p.returncode == 0,
          f"rc={p.returncode} {p.stderr.strip()}")
    rec = json.load(open(os.path.join(out, "run.json")))
    check("outcome is finished", rec["outcome"] == "finished", rec["outcome"])
    check("wall_seconds parsed from time-v.txt", rec["wall_seconds"] == 83.45,
          repr(rec["wall_seconds"]))
    check("peak_rss_kib parsed from time-v.txt", rec["peak_rss_kib"] == 123456,
          repr(rec["peak_rss_kib"]))

print()
if failures:
    sys.exit(f"test-write-record: {len(failures)} check(s) failed: {failures}")
print("test-write-record: all checks passed")
