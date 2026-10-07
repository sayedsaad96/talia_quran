# Verification

Use [Completion Contract](../core/completion-contract.md). Evidence must be fresh for this task.

## Status Vocabulary

`Implemented`, `Statically Verified`, `Test Verified`, `Runtime Verified`, `Measured`, `Release Verified` are independent evidence labels, not an automatic promotion ladder. Tests do not imply device runtime verification; a measurement does not imply release readiness.

## Evidence Ledger

Record each command/scenario, observed result, and whether it is pass/fail/**Not verified**. Separate pre-existing failures from failures introduced by the task; do not hide them behind “unrelated”.

Verification depth follows risk: low = targeted static/test; medium = tests + runtime; high = baseline + regressions + runtime/data state; critical = deterministic correctness + migration/recovery + no unresolved load-bearing risk.

Use [Project Playbook](../references/project-playbook.md) for commands and existing test locations. Record revision, dirty-source scope, tool/device, duration when relevant, exit code and log location. If source changes during validation, reassess the affected gates before attaching results to the final revision. Never hide blocked/unrun gates behind a helper script's closing message.
