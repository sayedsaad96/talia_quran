---
name: talia-quran-engineer
description: Use when working on any feature, bug, refactor, dependency upgrade, UI/UX or performance task, Supabase change, Quran reading/memorization/learning flow, architecture decision, runtime incident, or release review in the Talia Quran Flutter application.
---

# Talia Engineering OS

Treat Talia as a product-specific engineering system, not a generic Flutter repository.

## Constitution

1. **Repository first.** Inspect current relevant code before proposing changes.
2. **Diagnose before fixing.** Unexpected behavior requires root-cause investigation.
3. **Extend before rebuilding.** Search for existing capabilities before creating parallel systems.
4. **Evidence before claims.** Tests, runtime, performance and compatibility claims require fresh evidence.
5. **Tests before completion.** Applicable verification gates define done.
6. **Quran integrity above convenience.** Canonical Quran content and mappings are correctness-critical.
7. **Current sources before ecosystem decisions.** Verify authoritative current sources when freshness matters.
8. **Repository beats knowledge.** Living knowledge accelerates discovery but never overrides code reality.
9. **Smallest safe change.** Avoid unrelated refactors and uncontrolled migrations.
10. **Unknown is not assumed.** Search, measure, or mark unknown explicitly.

## Start Here

1. Determine operating mode: `DISCOVER`, `PLAN`, `IMPLEMENT`, or `INCIDENT`.
2. Inspect task-relevant repository context and living knowledge.
3. Create the task contract: goal, affected area, risk, evidence, modules/workflows, expected behavior, verification.
4. Use [Task Router](core/task-router.md) to select modules/workflows.
5. Use [Risk Engine](core/risk-engine.md) to set verification and autonomy depth.
6. Apply [Autonomy Policy](core/autonomy-policy.md).
7. Before any completion claim, apply [Completion Contract](core/completion-contract.md).

## Always-Required Product/Safety Context

Read [Talia Product Context](references/talia-product-context.md), [Engineering Principles](references/engineering-principles.md), and [Quran Safety Contract](references/quran-safety-contract.md) when the task touches their scope.

For freshness-sensitive decisions use [Source Authority](references/source-authority.md) and [Freshness & Upgrades](references/freshness-and-upgrades.md).

## Living Knowledge Rule

Use `knowledge/` as a navigation accelerator. Refresh task-relevant entries when stale. If knowledge conflicts with repository evidence, repository evidence wins and verified knowledge is corrected after the task.

## Completion

Report only statuses supported by fresh evidence: `Implemented`, `Statically Verified`, `Test Verified`, `Runtime Verified`, `Measured`, or `Release Verified`.
