#!/usr/bin/env python3
"""Regression tests for layout/flow/prep-netlist.py.

    python3 -I layout/flow/tests/test-prep-netlist.py

Plain asserts, standard library only -- this repo has no Python test harness and
these tests are not worth a new pin. Run by .github/workflows/flow-tests.yml.

What is pinned, and why each case exists:

1. The output post-condition fires on both shapes the rewrite pattern can miss
   (a surviving parameter block; an escaped instance name with no parameter
   block). Before it existed, either one passed through unchanged with 0 renames
   and exit 0 -- indistinguishable from "nothing needed rewriting" -- and the run
   failed three steps later in OpenSTA, naming OpenROAD instead of this step.
2. It does NOT fire on a well-formed netlist. The expression that matches an
   escaped instance name can also match a Yosys module declaration whose name is
   escaped, capturing the keyword `module`; a negative lookahead excludes it. Get
   that wrong and step 3 of run.sh fails on every run.
3. The `defined` set captures bare module names. Yosys writes
   `module npu_top(clk, ...);` with no space before `(`, so a `\\S+` capture
   swallows it, and the guard that leaves already-defined modules alone goes
   dead -- which would make the post-condition above report residue on every
   instance of a defined module carrying an escaped name.
4. The pattern matches linearly. An earlier form backtracked exponentially on an
   unterminated `#(` block (~1.1 s at n=12, ~16x per added repetition); this
   asserts a generous wall-clock ceiling at n=12 and n=200 so that cannot return.

Nothing here touches a PDK, a tool, or the batch fleet: it is pure Python over
text fixtures plus the stamped synthesis netlist already in the repo. ASAP7 is a
predictive PDK and this block is never fabricated.
"""
import ast
import json
import os
import re
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
FLOW = os.path.dirname(HERE)
REPO = os.path.dirname(os.path.dirname(FLOW))
SCRIPT = os.path.join(FLOW, "prep-netlist.py")
STAMPED = os.path.join(REPO, "rtl", "synth", "records", "2026-10-27-asap7-n8", "npu_top_synth.v")

# A generous ceiling, not the measured value: the fixed pattern runs the n=200
# case in ~0.03 s wall (whole interpreter, on a loaded shared 8-core host), so
# this leaves ~30x headroom, while the exponential form it replaced took ~1.1 s
# at n=12 alone and grew ~16x per added repetition.
CEILING_S = 1.0

PARAM_BLOCK = "  npu_sram_bank #(\n    .DEPTH_WORDS(32'sd1024),\n    .WORD_BITS(32'sd32)\n"
failures = []


def check(name, cond, detail=""):
    print(f"{'ok  ' if cond else 'FAIL'} {name}" + (f" -- {detail}" if detail else ""))
    if not cond:
        failures.append(name)


def run(text, workdir):
    """Run prep-netlist.py over `text`; return (rc, stdout, stderr, out_text, renames)."""
    src = os.path.join(workdir, "in.v")
    dst = os.path.join(workdir, "out.v")
    mapf = os.path.join(workdir, "map.json")
    with open(src, "w", encoding="utf-8") as fh:
        fh.write(text)
    p = subprocess.run([sys.executable, "-I", SCRIPT, src, dst, mapf],
                       capture_output=True, text=True, timeout=120)
    out = open(dst, encoding="utf-8").read() if os.path.exists(dst) else None
    ren = json.load(open(mapf)) if os.path.exists(mapf) else None
    return p.returncode, p.stdout, p.stderr, out, ren


def run_file(path, workdir):
    dst = os.path.join(workdir, "out.v")
    mapf = os.path.join(workdir, "map.json")
    p = subprocess.run([sys.executable, "-I", SCRIPT, path, dst, mapf],
                       capture_output=True, text=True, timeout=300)
    out = open(dst, encoding="utf-8").read() if os.path.exists(dst) else None
    ren = json.load(open(mapf)) if os.path.exists(mapf) else None
    return p.returncode, p.stdout, p.stderr, out, ren


def module_name_pattern():
    """The regex prep-netlist.py builds its `defined` set with.

    Lifted from the source rather than re-typed, so this test cannot pass
    against a pattern the script no longer uses.
    """
    src = open(SCRIPT, encoding="utf-8").read()
    m = re.search(r'^defined = set\(re\.findall\((r"[^"]*"), text, re\.M\)\)$', src, re.M)
    assert m, "prep-netlist.py no longer builds `defined` on one line; update this helper"
    return ast.literal_eval(m.group(1))


with tempfile.TemporaryDirectory() as tmp:
    # --- a surviving parameter block (an unterminated `#(`) must fail loudly ---
    rc, so, se, out, ren = run(
        "module npu_top(clk);\n  input clk;\n" + PARAM_BLOCK + "endmodule\n", tmp)
    check("truncated netlist: exits non-zero", rc != 0, f"rc={rc}")
    check("truncated netlist: names STA-0171", "STA-0171" in se)
    check("truncated netlist: names the offending module", "npu_sram_bank" in se)

    # --- an escaped instance name with no parameter block: the second shape the
    #     rewrite pattern never matched, so it silently did not happen ---
    rc, so, se, out, ren = run(
        "module npu_top(clk);\n  input clk;\n"
        "  npu_sram_bank \\g_bank[0].u_bank  ( .clk(clk) );\nendmodule\n", tmp)
    check("escaped name, no #(): exits non-zero", rc != 0, f"rc={rc}")
    check("escaped name, no #(): names STA-0171", "STA-0171" in se)
    check("escaped name, no #(): names the offending module", "npu_sram_bank" in se)

    # --- a DEFINED module instantiated with an escaped instance name and no
    #     parameter block is legitimate and must stay silent. This is what the
    #     bare-name `defined` capture buys: with the old `\S+` capture, `npu_pe`
    #     is stored as `npu_pe(clk,` and gets reported as residue. ---
    rc, so, se, out, ren = run(
        "module npu_top(clk);\n  input clk;\n"
        "  npu_pe \\g_pe[0].u_pe  ( .clk(clk) );\nendmodule\n"
        "module npu_pe(clk);\n  input clk;\nendmodule\n", tmp)
    check("defined module, escaped instance name: exits 0", rc == 0, f"rc={rc} stderr={se.strip()}")
    check("defined module, escaped instance name: 0 renames", so.strip() == "0", so.strip())

    # --- a netlist with no macro instances at all: the post-condition keys on
    #     residue, not on a nonzero rename count, so this must not regress into a
    #     spurious failure ---
    rc, so, se, out, ren = run(
        "module npu_top(clk);\n  input clk;\n"
        "  INVx1_ASAP7_75t_R u_i ( .A(clk) );\nendmodule\n", tmp)
    check("zero macro instances: exits 0", rc == 0, f"rc={rc} stderr={se.strip()}")
    check("zero macro instances: 0 renames", so.strip() == "0", so.strip())

    # --- the well-formed stamped netlist: no false positive, rename count
    #     unchanged. envelope.json records npu_sram_bank: 4. ---
    check("stamped netlist is present", os.path.isfile(STAMPED), STAMPED)
    if os.path.isfile(STAMPED):
        rc, so, se, out, ren = run_file(STAMPED, tmp)
        check("stamped netlist: exits 0", rc == 0, f"rc={rc} stderr={se.strip()}")
        check("stamped netlist: 4 renames", so.strip() == "4", so.strip())
        check("stamped netlist: 4 entries in the rename map",
              ren is not None and len(ren) == 4, str(ren if ren is None else len(ren)))
        check("stamped netlist: every rename is an npu_sram_bank instance",
              ren is not None and all(r["module"] == "npu_sram_bank" for r in ren))
        # Only the macro INSTANCE name is rewritten. Escaped net names from the
        # same generate block (`wire \g_bank[0].op_rw ;`) are untouched by
        # design -- OpenROAD's problem was the instance name, not the nets.
        check("stamped netlist: every instance carries its rewritten plain name",
              out is not None and ren is not None
              and all(f"npu_sram_bank {r['to']} (" in out for r in ren))
        check("stamped netlist: no npu_sram_bank instance keeps an escaped name",
              out is not None and not re.search(r"^[ \t]*npu_sram_bank\s+\\", out, re.M))
        env = os.path.join(os.path.dirname(STAMPED), "envelope.json")
        expect = json.load(open(env))["instance_counts_by_type"]["npu_sram_bank"]
        check("stamped netlist: rename count matches envelope.json",
              ren is not None and len(ren) == expect, f"envelope={expect}")

        # `defined` captures bare module names, not `npu_top(clk,`
        names = set(re.findall(module_name_pattern(), open(STAMPED, encoding="utf-8").read(), re.M))
        for want in ("npu_top", "npu_pe", "npu_requant"):
            check(f"defined set contains bare {want!r}", want in names,
                  sorted(n for n in names if n.startswith("npu_") and "(" in n) or "no mangled names")

    # --- linear matching: an unterminated `#(` block at n=12 and n=200 ---
    for n in (12, 200):
        text = "module npu_top(clk);\n  input clk;\n" + PARAM_BLOCK * n + "endmodule\n"
        t0 = time.perf_counter()
        rc, so, se, out, ren = run(text, tmp)
        dt = time.perf_counter() - t0
        # rc is 1 here by design (the post-condition fires), so only the time is
        # asserted -- not the exit code.
        check(f"unterminated #() x{n}: completes in under {CEILING_S}s",
              dt < CEILING_S, f"{dt:.4f}s (rc={rc})")

print()
if failures:
    sys.exit(f"test-prep-netlist: {len(failures)} check(s) failed: {failures}")
print("test-prep-netlist: all checks passed")
