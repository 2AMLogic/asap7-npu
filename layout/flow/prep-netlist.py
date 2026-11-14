#!/usr/bin/env python3
"""prep-netlist.py IN OUT MAP -- derive the netlist OpenROAD reads from item 1's.

Item 1's netlist (rtl/synth/records/<date>-asap7-nN/npu_top_synth.v) is kept
byte-for-byte as attested. Two things in it do not survive OpenROAD, both on the
instances of the black-box memory macro (a module with no definition in the
file, whose view is the LEF):

1. Yosys writes the parameter override block

       npu_sram_bank #(
           .DEPTH_WORDS(32'sd1024),
           .WORD_BITS(32'sd32)
         ) \\g_bank[0].u_bank  ( ...ports... );

   which OpenSTA's Verilog reader rejects (STA-0171). The LEF view has no
   parameters, so the `#( ... )` block is removed.
2. The instance name is an escaped identifier (`\\g_bank[0].u_bank `). Inside
   OpenROAD it becomes `u_banks/g_bank\\[0\\].u_bank`, and the same string is used
   unquoted by `place_macro` and braced by `define_pdn_grid -instances`, so no
   request spelling matches both. The name is rewritten to plain characters
   (`g_bank_0_u_bank`).

Nothing else changes. MAP is a JSON list of {"module", "from", "to"} renames.
"""
import json
import re
import sys

src, dst, mapfile = sys.argv[1:4]
text = open(src, encoding="utf-8").read()
# Yosys writes `module npu_top(clk, ...);` with no space before `(`, so a bare
# `\S+` swallows it and the group("mod") lookup below can never match a plain
# module name. Stop the name at whitespace, `(` or `;`.
defined = set(re.findall(r"^module\s+(\\?[^\s(;]+)", text, re.M))
# `<module> #( .P(v), ... ) <name> (` where <name> is plain or an escaped identifier
pat = re.compile(
    r"^(?P<ind>[ \t]*)(?P<mod>\w+)\s+#\(\s*(?:\.\w+\([^)]*\)\s*(?:,\s*)?)+\)\s*"
    r"(?P<name>\\\S+|\w+)(?P<sp>\s*)\(",
    re.M,
)
renames = []


def fix(m):
    if m.group("mod") in defined:
        return m.group(0)
    old = m.group("name")
    new = re.sub(r"[^A-Za-z0-9_]+", "_", old.lstrip("\\")).strip("_")
    renames.append({"module": m.group("mod"), "from": old, "to": new})
    return f"{m.group('ind')}{m.group('mod')} {new} ("


out = pat.sub(fix, text)
# Post-condition: the rewrite is not optional, so "the pattern matched nothing"
# must not look like "nothing needed rewriting". Without this, an input whose
# shape the pattern does not cover passes through unchanged with 0 renames and
# exit 0, and the run fails three steps later in OpenSTA's Verilog reader
# (STA-0171) -- naming OpenROAD rather than this step. Scan the OUTPUT, not the
# rename count: that also catches a partial match, where some instances were
# rewritten and others were not.
#
# Two residual shapes are rejected: a surviving parameter block, and an escaped
# instance name with no parameter block (which `pat` never matched, so item 2 of
# the docstring silently did not happen).
#
# `(?!module\b)` is load-bearing. Yosys emits parameterised modules with escaped
# names (`module \$paramod\npu_array\ARRAY_N=s32'...0001000 (clk, ...);`), which
# the second expression would otherwise match, capturing the keyword `module` --
# never a member of `defined`, so it would report residue on every well-formed
# netlist. Neither expression has a nested quantifier, so they match linearly and
# cannot reintroduce the backtracking `pat` was fixed for.
RESIDUE = (
    re.compile(r"^[ \t]*(?!module\b)(\w+)\s+#\(", re.M),
    re.compile(r"^[ \t]*(?!module\b)(\w+)\s+\\\S+\s*\(", re.M),
)
resid = sorted({m.group(1) for p in RESIDUE for m in p.finditer(out)} - defined)
if resid:
    sys.exit(
        f"prep-netlist: {len(renames)} rename(s) made, but instances of undefined "
        f"module(s) {resid} still carry a parameter block or an escaped name; "
        f"OpenSTA will reject this netlist (STA-0171). The rewrite pattern did "
        f"not match this netlist."
    )
if len({r["to"] for r in renames}) != len(renames):
    sys.exit("prep-netlist: renamed instance names collide")
open(dst, "w", encoding="utf-8").write(out)
json.dump(renames, open(mapfile, "w"), indent=1)
print(len(renames))
