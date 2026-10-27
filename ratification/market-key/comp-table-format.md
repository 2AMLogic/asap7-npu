# Comp-table format

The exact table schema `SKILL.md`'s research procedure fills in, and the
schema the comp library's own entries use, so a market-key review and a
comp-library entry are always literally the same table shape — one can be
pasted into the other with no reformatting.

Candidate comps for this block are listed in `comps/int8-mac-array.md`.

## The table

| # | Row | Our target | Comp source | Comp value | Verdict | Notes |
|---|---|---|---|---|---|---|

- **#** — the spec row's own number, matching the target repo's own spec
  table/decision-record numbering where one exists (`spec/npu.md` has none: number the rows in table order and say so).
- **Row** — the parameter name, in the target spec's own words.
- **Our target** — the ratified (or proposed, if this is a PR under review
  rather than an already-ratified spec) value, with its citation back to the
  decision record that sets it.
- **Comp source** — `<Project or vendor> <design name>, <paper or document ID>`. One comp source per
  table row is the floor; prefer two independent sources per row so the
  table is not a single point of failure (see `SKILL.md` Step 2.2). When two
  sources are used for one spec row, add a second table row directly below
  the first repeating the `#`/`Row`/`Our target` columns.
- **Comp value** — the comp's stated value for the equivalent parameter, with
  enough of the comp's own test condition quoted (process node, corner, frequency, array dimensions, silicon-measured or predicted) that a reader can judge comparability rather than trust
  it. **Do not strip the test condition to make two numbers look more
  comparable than they are** — if the comparison is apples-to-oranges (e.g.
  a predicted figure against a silicon-measured one, different process node), say so in Notes rather
  than silently presenting bare numbers side by side.
- **Verdict** — one of the three tokens from `rubric.md`
  (`competitive` / `adequate-for-catalog` / `uncompetitive`), or `no-comp-found`
  if Step 2.4 applied.
- **Notes** — anything a reader needs to trust the comparison: measurement
  basis mismatches, whether the comp is still maintained or only historically relevant.

## Sourcing rules

1. **Primary sources only.** The project's own paper, repository or
   documentation — never a third-party aggregator's restated numbers (blog
   posts or forum posts quoting a figure from memory) unless the primary source is
   confirmed unreachable, in which case say so and flag the number
   UNVERIFIED rather than presenting it with primary-source confidence.

2. **Every fetched source gets a `Sources` table row** (URL, date fetched,
   what it establishes) at the bottom of the review/comp-file, per
   `SKILL.md`'s "Output format" — not just cited inline in prose.
3. **Date every fetch.** Datasheets get revised; a comp value is only as
   good as the revision it was read from. Cite the paper's venue and year, or the repository's commit, not just a
   project name.
4. **Quote the figure and its test condition in the review**, since a link may
   break and the review is the evidence record.

5. **No price rows.** This block is not a product; do not add price or
   availability to a comp table.

## Row classification table (companion, from `SKILL.md` Step 1)

| # | Row | In scope? | Why |
|---|---|---|---|

Same numbering as the comp table. `Why` for an out-of-scope row should name
which kind of internal-implementation choice it is (PDK, memory representation, RTL structure, verification methodology,
tracked-at-origin row) — enough that a
reader can confirm the exclusion is principled, not a row the review simply
skipped.
