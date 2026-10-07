# Task Router

## Task Contract

Before execution record: Goal; Affected area; Risk level; Evidence available; Modules/workflows required; Expected behavior; Verification method.

## Labels

`FEATURE`, `BUG`, `RUNTIME`, `PERFORMANCE`, `UI_UX`, `REFACTOR`, `ARCHITECTURE`, `DEPENDENCY`, `FLUTTER_SDK`, `SUPABASE`, `DATABASE_MIGRATION`, `QURAN_ENGINE`, `AUDIO`, `MEMORIZATION`, `REVISION`, `LEARNING`, `LOCAL_STORAGE`, `SECURITY`, `PRIVACY`, `TESTING`, `RELEASE`, `STORE_REVIEW`, `ACCESSIBILITY`, `LOCALIZATION`, `TECH_DEBT`, `EXPLORATION`, `SKILL_MAINTENANCE`.

## Routing Rules

- Bug/unexpected behavior → `modules/debugging.md` + `workflows/bug-fix.md`.
- Crash/data/security/Quran-integrity production failure → `modules/incident-response.md` + `workflows/incident-response.md`.
- Lag/jank/startup/memory → `modules/performance.md` + `workflows/performance-investigation.md`.
- Package/SDK update → `modules/dependency-upgrades.md` + `modules/ecosystem-intelligence.md` + `workflows/dependency-upgrade.md`.
- Supabase/RLS/schema/auth → `modules/supabase.md` + `modules/security-privacy.md`; schema change also loads `workflows/supabase-migration.md`.
- Quran mapping/navigation/recitation references → `modules/quran-engine.md` + `modules/quran-integrity.md` + `modules/testing-qa.md`.
- Memorization/revision → `modules/memorization-learning.md` and/or `modules/revision.md`, plus Quran integrity if identifiers are touched.
- Audio/lifecycle/synchronization → `modules/audio.md`; load Quran engine if ayah synchronization is involved.
- UI redesign → `modules/ui-ux.md` + relevant product/domain module.
- New feature → `modules/feature-development.md` + `workflows/new-feature.md`.
- Architecture refactor → `modules/architecture-refactoring.md`.
- Release/store review → `modules/release-readiness.md` + `workflows/pre-release-audit.md`.

Load only modules that materially affect the task.

## Project-specific dispatch

Use [Project Playbook](../references/project-playbook.md) and [Repository Map](../knowledge/repo-map.md) before editing. Select the current owner, not merely a similarly named legacy feature.

- Identity/account switch/family data → security + memorization/supabase as applicable; check owner/audience/child scope and queue acknowledgements.
- Lost or duplicate review/reward → memorization + debugging; trace audience-specific committer → adult outbox OR child `awardKidsPoints`/session log → cloud reconciliation/read model before editing UI totals.
- Khatmah credit/completion → Quran confirmation gate + khatmah use cases/repository + certificates when affected.
- Prayer/reminder delivery → scheduler and `core/prayer_delivery` + runtime validation; distinguish calculated events from OS delivery.
- Quran/azkar/dua/copy/share/notification content → Quran safety + repository Islamic source policy, even when the change looks like UI copy.
- Isar/isolate/schema → storage invariant in playbook + data migration verification; never open the default database with a subset schema.
- Release audit → only on explicit user request, using the repository's specialist coverage workflow. Ordinary fixes use focused verification.
- Skill maintenance → inspect source/instructions read-only and update this skill's resources only. Use the available skill-authoring guidance; preserve concurrent work, validate links/frontmatter/repository paths, run the skill's Python tests, syntax-check changed helpers and forward-test material behavior. Do not fix application code, run production SQL or launch an app audit unless separately requested. Report skill validation separately from application verification.
