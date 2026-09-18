# Task Router

## Task Contract

Before execution record: Goal; Affected area; Risk level; Evidence available; Modules/workflows required; Expected behavior; Verification method.

## Labels

`FEATURE`, `BUG`, `RUNTIME`, `PERFORMANCE`, `UI_UX`, `REFACTOR`, `ARCHITECTURE`, `DEPENDENCY`, `FLUTTER_SDK`, `SUPABASE`, `DATABASE_MIGRATION`, `QURAN_ENGINE`, `AUDIO`, `MEMORIZATION`, `REVISION`, `LEARNING`, `LOCAL_STORAGE`, `SECURITY`, `PRIVACY`, `TESTING`, `RELEASE`, `STORE_REVIEW`, `ACCESSIBILITY`, `LOCALIZATION`, `TECH_DEBT`, `EXPLORATION`.

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
