# Tool-scaling record format

**Status: proposed.** This file defines a format only. No runs are recorded
here.

The question this repo answers is how `klt` DRC and LVS behave on a very large,
very regular layout. Every DRC and LVS run is recorded, at every array size, as
evidence in its own right. A run that does not finish is a result: record it
and file the gap. Records are **append-only**; a wrong record is corrected by a
new record that references it, never edited.

## Where

`layout/tool-scaling/<YYYY-MM-DD>-<tool>-<N>x<N>-<mode>-<seq>.json`, one file per
run, committed with the run's report. Do not rewrite an existing file.

## Fields

| Field | Type | Meaning |
|---|---|---|
| `schema` | string | `tool-scaling-record/1` |
| `record_id` | string | the file stem |
| `corrects` | string or null | `record_id` this record supersedes |
| `tool` | `"drc"` or `"lvs"` | |
| `array_size` | string | `"8x8"`, `"16x16"`, `"32x32"` or `"64x64"` |
| `mode` | `"flat"` or `"hierarchical"` | |
| `layout` | object | `path`, `sha256`, `shape_count`, `cell_count` (from `klt stats` / `klt cells`) |
| `deck` | object | `name`, `content_hash` (from `klt deck info`), `rules_missing` (list, may be empty) |
| `klt_version` | string | output of `klt --version` |
| `klayout_version` | string | |
| `host` | object | `id`, `cpu_cores`, `ram_gib`, and the concurrent load noted (the host is shared) |
| `command` | string | exact command line |
| `wall_seconds` | number or null | elapsed wall clock; null only when the run was killed before any timing |
| `peak_rss_kib` | number or null | maximum resident set size, e.g. from `/usr/bin/time -v` |
| `outcome` | enum | `finished_clean`, `finished_violations`, `did_not_finish_timeout`, `did_not_finish_oom`, `did_not_finish_other`, `tool_error` |
| `violations` | number or null | count; null when not finished |
| `waivers` | number | waivers applied (0 if none) |
| `limit_hit` | object or null | for a did-not-finish: the `timeout_s` or memory ceiling that stopped it |
| `gap_issue` | string or null | URL of the issue filed for a did-not-finish or tool error |
| `report` | string | path of the committed `klt` report |
| `notes` | string | free text; no claim beyond the measured numbers |

A did-not-finish record still carries every field it can: the elapsed time at
the kill and the last observed peak memory. All timing in a record is of the
tool, not of the design; design timing figures are separate and labelled
"predicted".

## Sweep

Each of these is run, flat and hierarchical, for both DRC and LVS:

| Array size | Role |
|---|---|
| 16 x 16 | fallback |
| 32 x 32 | target |
| 64 x 64 | stretch |

A size that is not reached because an earlier size did not finish gets a
`did_not_finish_*` record at the earlier size and a note in the later one; it
is not silently omitted. Additional intermediate sizes (e.g. 8 x 8) may be
added to locate where a run stops finishing; they follow the same format.

## Rules

- Measure peak memory from outside the tool (`/usr/bin/time -v` or equivalent), not from the tool's own report.
- This host class is shared; keep runs modest, note the load, and do not run a grid in parallel by hand.
- Never present a tool-scaling figure as a measurement of silicon: ASAP7 is a predictive PDK and the block is never fabricated.
