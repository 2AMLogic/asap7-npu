# Work Log

Chronological record of merged PRs and closed issues. Maintained by the Guide role.

### 2026-10-27

- **PR #33**: docs: install EE and market ratification keys for the ASAP7 NPU
- **PR #27**: feat(signoff): pin klt v0.8.0 and attest T1 item 10 (repo hygiene)
- **Issue #21** (closed): T1 item 10 (repo hygiene): bump the signoff klt pin to one with --attest, add reproduce steps, attest item 10
- **PR #28**: feat(rtl): stamp origin RTL and attest T1 item 1 at ARRAY_N = 8 (ASAP7 synthesis)
- **Issue #22** (closed): T1 item 1 (design sources): stamp sky130-npu RTL at the ASAP7 array size and synthesize to asap7sc7p5t_28

### 2026-10-23

- **PR #19**: docs: adopt asap7-riscv-core ASAP7 bring-up by reference (decision 0003)
- **Issue #17** (closed): Adopt asap7-riscv-core's ASAP7 bring-up by pinned reference (decision 0001 re-check)

### 2026-10-21

- **PR #14**: Bump Repo Skills 0.24.3 -> 0.24.7

### 2026-10-20

- **PR #7**: ci: grade klt signoff manifest and fail on report drift
- **Issue #5** (closed): T1 item 10: commit a klt signoff block manifest and a CI job that keeps it graded
- **PR #11**: chore: remove always-green stub gate scripts from package.json
- **Issue #9** (closed): Remove stub package.json gate scripts that always exit 0 (test/lint/check:*)

### 2026-10-17

- **Issue #3** (closed): Draft and ratify the target spec
- **PR #6**: docs(spec): draft proposed target spec, ASAP7 pin and memory decision
- **PR #2**: chore(loom): commit the Loom merge-driver .gitattributes
- **PR #1**: chore(loom): Install Loom 0.19.1180
