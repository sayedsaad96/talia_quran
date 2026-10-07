# Completion Contract

**No completion claim without fresh verification evidence.**

## Status vocabulary

- `Implemented`: code/content changed; not yet proven by execution.
- `Statically Verified`: static analysis or deterministic document checks passed.
- `Test Verified`: relevant automated tests passed freshly.
- `Runtime Verified`: the real scenario was exercised successfully.
- `Measured`: before/after metrics were captured and compared.
- `Release Verified`: release-specific gates were run and passed.

## Final report guidance

Match detail and language to the user. For small tasks use a concise summary of what changed, checks actually run and material limitations; do not force empty sections or ecosystem statements. For substantial changes, the following fields form an evidence checklist rather than a required output layout. Verification statuses are independent: a test pass never implies Android runtime or release certification. Distinguish pre-existing failures, new failures and unavailable checks with evidence.

Use Arabic when the user communicates in Arabic, with clickable changed-file links where useful.

```text
TASK
State the user-requested goal in one sentence.

CHANGED
List only files/behavior actually changed.

VERIFIED
List each command/scenario actually run with its observed result.

NOT VERIFIED
List relevant checks that were not performed.

RISKS / COMPATIBILITY
State remaining migration, rollback, coexistence, or correctness concerns.

ECOSYSTEM EVIDENCE
List authoritative current external facts checked for this task, or state that none were required.

FOLLOW-UP
List only meaningful next work that is outside the completed scope.
```
