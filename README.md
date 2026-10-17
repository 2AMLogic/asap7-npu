# asap7-npu

A large INT8 multiply-accumulate array on
[ASAP7](https://github.com/The-OpenROAD-Project/asap7), a **predictive**
7 nm FinFET PDK — the architecture of
[sky130-npu](https://github.com/2AMLogic/sky130-npu), scaled up — laid out
by AI agents driving
[klayout-tools](https://github.com/2AMLogic/klayout-tools) and the
open-source cocotb + Icarus, Yosys and OpenROAD flow.

**ASAP7 is a predictive PDK, not a foundry process.** It models a 7 nm
FinFET node for research and teaching; no fab manufactures it. This block is
**layout, DRC and timing only, and it is never fabricated.** Every result in
this repo is a tool result against a predictive model — there is no silicon,
no shuttle and no measurement at the end of the ladder.

**Status: just opened, specification phase.** Nothing is designed yet.

**Built agent-native.** Every specification, decision record, testbench, and
line of documentation here is produced by AI agents working from a ratified
spec and an append-only evidence trail — not human-authored work that agents
merely assisted with. Verification is the product: every claim traces to a
recorded result. Where the agents hit friction with the open-source tooling —
most often [klayout-tools](https://github.com/2AMLogic/klayout-tools) — that
friction is filed as a public issue against the tool itself, so the fix
benefits everyone using ASAP7, not just this repo.

## Why this block, on this PDK

This is a **port, and a scale test**. The architecture, the integer golden
model and the testbenches come from `sky130-npu`, which is master for all of
them. What changes is size: a MAC array many times larger, on a PDK whose
rules are far denser, is expected to produce a layout with more shapes than
any other fleet block. That is the experiment — **how klayout-tools' DRC and LVS
behave at scale**: runtime, memory, hierarchy handling, and whether the
results stay trustworthy when the layout is large.

ASAP7 is not in the fleet's `open_pdks` store, so bringing it up under `klt`
is part of the work. If `asap7-riscv-core` has already done that bring-up,
take its pinned setup rather than building a second one.

## Scope

- **In scope**: the scaled array and controller from `sky130-npu`'s RTL with
  a larger array parameter; synthesis, place-and-route, DRC, LVS and STA on
  ASAP7; DRC/LVS runtime and memory recorded as first-class results.
- **Not in scope**: a new architecture (departures from the origin are
  decision records), an SRAM bitcell or compiler (on-chip memory is
  represented by abstract macro views — the choice is a decision record), and
  anything that implies manufacture.

## Target specification (DRAFT — engineering to ratify, see issue #1)

All frequencies are predicted by STA against ASAP7's predictive models.

| Parameter | Target | Fallback | Stretch |
|---|---|---|---|
| Architecture | `sky130-npu`'s, unmodified except the array parameter | — | — |
| MAC array | 32 x 32 (1,024 MACs), INT8 x INT8 → INT32 | 16 x 16 | 64 x 64 |
| On-chip memory | abstract macro views, banking scaled from the origin | — | — |
| Predicted clock (post-route STA, slow corner) | 1 GHz | 500 MHz | 1.5 GHz |
| Numerical correctness | bit-exact against the origin's golden model | — | — |
| DRC | clean against the pinned ASAP7 deck, full chip, flat and hierarchical | hierarchical only, recorded | — |
| LVS | clean | — | — |
| Tool scaling | DRC/LVS runtime and peak memory recorded per array size | — | — |

Maturity ladder: ASAP7 brought up under `klt` → spec ratified → origin RTL
bit-exact at the scaled size → synthesized → placed and routed → DRC/LVS
clean → post-route multi-corner STA closed at the target. **That is the end
of the ladder; there is no fabrication step.** **Current position:
pre-spec.**

## Repo layout

```
spec/          ratified spec + decision records, including the PDK bring-up
rtl/           top-level wrapper; stamped copies from sky130-npu under rtl/common/
verification/  stamped golden model + testbenches, run records
layout/        GDS + DRC/LVS reports + STA reports + tool runtime records
```

## License

Apache License 2.0 — see [LICENSE](LICENSE).
