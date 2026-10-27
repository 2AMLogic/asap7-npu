# Verdict rubric

Three tokens, applied per row (`SKILL.md` Step 4) and rolled up to one
overall `approve`/`request-changes` verdict (`SKILL.md`'s "Output format").

Deliberately self-contained: nothing below names, numbers, or references
this repo's own internal fleet-operations detail — only the target
repo's own cited evidence, public PDK facts, and `klayout-tools`' public
`docs/design-evidence-tiers.md`.

## `sound`

The row's claim is independently re-derivable from cited design sources
(RTL, synthesis netlist, Liberty corner, STA or DRC/LVS report) and/or backed by committed evidence that
passes the relevant `design-evidence-tiers.md` T1 items for that row
(provenance-fresh, corner coverage matching the claim, Monte Carlo present
if the row is statistical; for this digital block Monte Carlo is
`not_applicable` per `spec/npu.md`). A row whose value is a **mechanical consequence**
of an already-ratified row plus the merged design's own structure — with no
new measurement needed — is also `sound`, provided the derivation is
actually checked against the source rather than merely asserted.

## `insufficient-evidence`

The row's value is not implausible, but the evidence backing it
falls short of what `design-evidence-tiers.md`'s T1 checklist requires for
the claim being made — an "informal, uncommitted" sanity check the design
doc itself disclaims as non-evidentiary, a single-corner check
standing in for a multi-corner claim, a plumbing-only record (the flow ran but
the design did not complete it) standing in for a design result, a
smaller array size standing in for the claimed one, or a statistical row
backed only by a static corner run. This is not a
verdict that the value is wrong — it is a statement that this key cannot
certify it as `sound` on the evidence actually on record, and the row should
stay unratified (or be flagged) until the gap closes.

## `unsound`

The row's claim contradicts what the cited design source, the PDK, or
existing committed evidence actually shows — a re-derivation that does not
match the PR's stated conclusion, a claim that ignores a corner-dependent
effect the block's own structure is known to be sensitive to, a claim that
implies silicon, a shuttle, a tape-out or a measurement on a predictive PDK
that is never fabricated, a timing figure not labelled predicted, or a row ratified on the back of evidence that itself failed (see the
relax-after-measured-FAIL check, `SKILL.md` Step 5) without an independent
technical justification for why the weaker value still holds. Absence of any
evidence at all for a claim with no plausible mechanical derivation is
`unsound` by default, the same way the market key's own rubric treats an
uncited value as `uncompetitive` by default rather than extending it the
benefit of the doubt.

## The EE-key / market-key jurisdiction boundary

This key reviews **every** row a ratification PR proposes for technical
soundness — unlike the market key, there is no row-classification split
into "in scope"/"out of scope" here, because every spec row makes an
engineering claim whether or not a buyer could observe it externally. What
this key does **not** do is rule on whether a technically sound value is
*competitive* — a row can be `sound` (well-derived, adequately evidenced) and still be weak against the market, or `unsound` and still
happen to beat every public comp; the two questions are independent by
design.
Scoring competitiveness,
favorably or unfavorably, is itself a rubric violation for this key — it
lets the EE key exercise judgment over ground the two-key design reserves
for the market key, defeating the incentive-separation the mechanism exists
to protect.

## Rows this key does not rule on

Rows `spec/npu.md` marks `TRACKED AT ORIGIN` are decided at
`2AMLogic/sky130-npu`. This key reads them only to confirm the PR leaves them
unchanged; it gives them no verdict.
