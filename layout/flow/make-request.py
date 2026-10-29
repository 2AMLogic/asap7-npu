#!/usr/bin/env python3
"""make-request.py SYNTH_RECORD MACRO_LEF RENAMES OUT -- write the klt place-and-route request.

The array size enters only through the synthesis record it is given: the netlist
area (record's envelope.json `area_um2`, black boxes excluded) and the macro
instances (RENAMES, from prep-netlist.py). Everything else is a fixed flow input.

Floorplan rule: core area = std-cell area / STD_UTIL + the macro slots (macro
footprint plus HALO on each side); the core is a square of whole rows, the die
adds a margin of whole rows. Macros are packed left to right, wrapping, in a band
centred vertically in the core. These are flow inputs, not results.
"""
import json
import math
import re
import sys
from pathlib import Path

record, lef, renames, out = (Path(a) for a in sys.argv[1:5])

STD_UTIL = 0.47          # std-cell area / (core area - macro slots)
HALO = 2.0               # um, keep-out on each side of a macro
ROW = 0.27               # um, one ASAP7 7.5-track row
SITE = 0.054             # um, one placement site
MARGIN = 8 * ROW         # die margin around the core
CLOCK_PERIOD_NS = 2.0    # the 500 MHz fallback target; a flow input, not a claim

env = json.loads((record / "envelope.json").read_text())
std_area = env["area_um2"]
size = re.search(r"SIZE\s+([\d.]+)\s+BY\s+([\d.]+)", lef.read_text())
mw, mh = float(size.group(1)), float(size.group(2))
macros = json.loads(renames.read_text())
n = len(macros)
slot_w, slot_h = mw + 2 * HALO, mh + 2 * HALO

core_area = std_area / STD_UTIL + n * slot_w * slot_h
side = math.ceil(math.sqrt(core_area) / ROW) * ROW
while True:
    per_row = int(side // slot_w)
    rows_needed = math.ceil(n / per_row) if per_row else 10**9
    if rows_needed * slot_h <= side:
        break
    side += ROW
r3 = lambda v: round(v, 3)
die = [0, 0, r3(side + 2 * MARGIN), r3(side + 2 * MARGIN)]
core = [r3(MARGIN), r3(MARGIN), r3(MARGIN + side), r3(MARGIN + side)]

band_y = MARGIN + (side - rows_needed * slot_h) / 2
placed = []
for i, m in enumerate(macros):
    r, c = divmod(i, per_row)
    placed.append({
        "instance": "u_banks/" + m["to"],  # flattened path: instance of npu_banks u_banks
        "lef": "../../macros/" + lef.name,
        "x_um": r3(round((MARGIN + c * slot_w + HALO) / SITE) * SITE),
        "y_um": r3(round((band_y + r * slot_h + HALO) / ROW) * ROW),
        "orientation": "R0",
        "halo": HALO,
    })

tracks = [  # explicit tracks: the tech LEF's M2 OFFSET -0.27 aborts a bare make_tracks
    {"layer": layer, "x_offset_um": xo, "x_pitch_um": p, "y_offset_um": yo, "y_pitch_um": p}
    for layer, xo, yo, p in (
        ("M1", 0.0, 0.0, 0.036), ("M2", 0.0, 0.0, 0.036), ("M3", 0.0, 0.0, 0.036),
        ("M4", 0.003, 0.003, 0.048), ("M5", 0.0, 0.0, 0.048),
        ("M6", 0.0, 0.0, 0.064), ("M7", 0.0, 0.0, 0.064))
]
req = {
    "schema": "klt.place_and_route.request/1",
    "engine": "openroad",
    "netlist": "npu_top_pnr.v",
    "hdl_toplevel": "npu_top",
    "pdk": {"cell_library": "asap7sc7p5t_28", "corner": "RVT_TT"},
    "floorplan": {"method": "explicit", "die_area_um": die, "core_area_um": core,
                  "site": "asap7sc7p5t", "tracks": tracks},
    "io": {"layer_h": "M4", "layer_v": "M5"},
    "macros": placed,
    "power": {
        "power_net": "VDD", "ground_net": "VSS",
        "straps": [
            {"layer": "M1", "width_um": 0.018, "pitch_um": 0.54, "followpins": True},
            {"layer": "M2", "width_um": 0.018, "pitch_um": 0.54, "followpins": True},
            {"layer": "M5", "width_um": 0.12, "spacing_um": 0.072, "pitch_um": 0.56, "offset_um": 0.3},
            {"layer": "M6", "width_um": 0.288, "spacing_um": 0.096, "pitch_um": 0.96, "offset_um": 0.3},
        ],
    },
    "library": {
        "cts_buffer": "BUFx4_ASAP7_75t_R",
        "power_pins": [{"net_role": "power", "pattern": "VDD", "primary": True},
                       {"net_role": "ground", "pattern": "VSS", "primary": True}],
        # placeholders, not extracted values: the tech LEF carries no RC. Predicted-timing only.
        "wire_rc": {"resistance_ohm_per_um": 0.0242, "capacitance_pf_per_um": 0.00016579},
        "route_layers": {"low": "M2", "high": "M7"},
        "antenna_diode": None,
        "tapcell": {"master": "TAPCELL_ASAP7_75t_R", "endcap": "TAPCELL_ASAP7_75t_R", "distance_um": 25},
        "filler": ["FILLERxp5_ASAP7_75t_R"],
    },
    "constraints": {"clock_port": "clk", "clock_period_ns": CLOCK_PERIOD_NS,
                    "input_delay_ns": 0, "output_delay_ns": 0},
    "seed": 1,
    "target_stage": "route",
    "portable_paths": True,
}
out.write_text(json.dumps(req, indent=2) + "\n")
print(f"core {side:.2f} um square, die {die[2]} um, {n} macros in {rows_needed} row(s)")
