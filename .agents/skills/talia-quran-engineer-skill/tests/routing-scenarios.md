# Routing Scenarios

## Quran page restore lag
Classification: `BUG + PERFORMANCE + QURAN_ENGINE + LOCAL_STORAGE`
Modules: debugging, performance, quran-engine, quran-integrity/testing as mappings demand.
Workflow: bug-fix + performance-investigation/runtime-investigation.
Risk: High when stored reading position/mapping is affected.

## supabase_flutter update
Classification: `DEPENDENCY + SUPABASE + TESTING`
Modules: dependency-upgrades, ecosystem-intelligence, supabase, testing-qa.
Workflow: dependency-upgrade.
Risk: Medium to High depending on auth/schema/client behavior.

## Kids path redesign
Classification: `UI_UX + FEATURE`
Modules: ui-ux, feature-development.
Workflow: new-feature.
Risk: Medium; adult/core Quran surfaces must remain unaffected.

## Wrong highlighted ayah
Classification: `BUG + AUDIO + QURAN_ENGINE + RUNTIME`
Modules: debugging, audio, quran-engine, quran-integrity.
Workflow: bug-fix + runtime-investigation.
Risk: High because recitation ↔ ayah synchronization is correctness-sensitive.

## RLS ownership failure
Classification: `BUG + SUPABASE + SECURITY`
Modules: debugging, supabase, security-privacy.
Workflow: bug-fix; supabase-migration only if schema/policy migration is required.
Risk: High/Critical depending on unauthorized data exposure.

## Release review
Classification: `RELEASE + STORE_REVIEW + SECURITY + PRIVACY`
Modules: release-readiness, security-privacy, verification.
Workflow: pre-release-audit.
Risk: High because platform/store facts are freshness-sensitive.
