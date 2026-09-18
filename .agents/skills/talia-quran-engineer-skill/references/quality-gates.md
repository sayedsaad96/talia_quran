# Quality Gates

Use only gates relevant to the task and risk level.

## Domains

- Static: analyzer/lints and deterministic package checks.
- Automated tests: unit/domain, widget, integration as appropriate.
- Runtime: real navigation/state/lifecycle/error/offline scenarios.
- Quran: mapping, restore, bookmarks, QCF/rendering, audio sync, memorization/revision references.
- Data: persistence, migrations, upgrade-from-existing state, rollback/recovery.
- Supabase/security: schema, RLS allowed and denied paths, auth/ownership, rollout compatibility.
- UI/UX: Arabic RTL, English LTR, text scaling, small screens, accessibility and interaction states.
- Performance: baseline/profile/before-after measurements; static suspicions are risks, not measured results.
- Release: build, primary flows, permissions, privacy/policies, background behavior, deep links, signing, store requirements.

Detailed execution belongs in `modules/verification.md` and `workflows/runtime-validation.md` once loaded by the task router.
