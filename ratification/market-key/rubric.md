# Verdict rubric

Three tokens, applied per spec row (`SKILL.md` Step 3) and rolled up to one
overall verdict (`SKILL.md` Step 4). A fourth token, `escalate`, is not a
competitiveness verdict at all — it means Step 5's relax-after-measured-FAIL
check could not be satisfied and this key is declining to rule; see that
section of `SKILL.md` rather than this file for what it means.

Deliberately self-contained: nothing below names, numbers, or maps onto any
internal maturity/grading scheme. The token `adequate-for-catalog` is fixed by
the release protocol and is kept verbatim; here it means only "adequate against
the comparison set, with the gap named". It does **not** mean a product is or
will be sold. This block is a predictive-PDK canary that is never fabricated.

## Predicted versus measured

Every timing figure in this repo is **predicted** (post-route STA against
ASAP7's predictive Liberty models). A comp figure measured on a real process is
not the same kind of number. A comparison across that line is allowed only if
Notes names it; a verdict that treats a predicted figure as a measurement, or
that reads a comp's silicon result as a like-for-like bar for a predictive
one, is a rubric violation. Compare like with like where a comp publishes a
post-layout or RTL-level figure; otherwise say which side is which.

## `competitive`

The row's target matches or exceeds what the comp table found in comparable
open INT8 arrays, taking the predicted-versus-measured line above into
account, with nothing a knowledgeable reader would flag as a gap.

## `adequate-for-catalog`

The row does not match the strongest comp found, but is within a stated margin
of comparable arrays or clears a stated floor, **and** the gap is named
explicitly rather than hidden. This is also the correct verdict for a row whose
target is honestly marked proposed (not yet verified) when the *proposed value
itself*, if achieved, would clear the floor: "unverified" and "uncompetitive"
are separate facts, and the review states both rather than picking one.

The 16 x 16 at 500 MHz fallback and the 64 x 64 at 1.5 GHz stretch are
scored as what they are, a fallback and a stretch: a fallback that is
`adequate-for-catalog` while the target is `competitive` is an expected
result, not a defect.

## `uncompetitive`

The row falls short of the floor a comparable array sets, **or** no evidence at
all supports the value (a row asserted with no comp and no reasoning is
`uncompetitive` by default; absence of evidence is not evidence of adequacy).
A claim that implies silicon, a shuttle, a tape-out or a measurement for this
block is not a market claim at all and is `uncompetitive` on that ground: it
is also a disclosure problem to flag under `SKILL.md`.

## Rows with no verdict: `no-comp-found`

Used when Step 2.4 applies: a genuinely novel parameter or a class with no
public documentation. This is not a verdict on the row's value; it states that
this key could not evaluate it, rather than defaulting silently to a token.

## The market-key / EE-key jurisdiction boundary

This key only scores rows a reader comparing arrays could observe. A row
stating an internal implementation choice (the PDK, the memory representation,
the DRC/LVS acceptance wording, the verification methodology, anything
`TRACKED AT ORIGIN`) gets no verdict from this key; it is marked out of scope
in the row-classification table and left to the EE key. Scoring an out-of-scope
row, favorably or unfavorably, is itself a rubric violation: it defeats the
incentive-separation the two-key design exists to protect.

## Overall-verdict roll-up (restated from `SKILL.md` Step 4)

Overall verdict = the worst individual in-scope row verdict
(`uncompetitive` < `adequate-for-catalog` < `competitive`, treating
`no-comp-found` as a gap to flag rather than a score, and `escalate`
overriding all three when Step 5 applies), unless the PR under review already
states, with its own cited evidence, why a lagging row is acceptable. This key
never invents that justification; it reports whether the PR made the case.
