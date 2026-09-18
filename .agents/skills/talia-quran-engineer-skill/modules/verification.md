# Verification

Use [Completion Contract](../core/completion-contract.md). Evidence must be fresh for this task.

## Status Vocabulary

`Implemented` → `Statically Verified` → `Test Verified` → `Runtime Verified` → `Measured` → `Release Verified` as applicable. Never promote a status without the evidence that defines it.

## Evidence Ledger

Record each command/scenario, observed result, and whether it is pass/fail/**Not verified**. Separate pre-existing failures from failures introduced by the task; do not hide them behind “unrelated”.

Verification depth follows risk: low = targeted static/test; medium = tests + runtime; high = baseline + regressions + runtime/data state; critical = deterministic correctness + migration/recovery + no unresolved load-bearing risk.
