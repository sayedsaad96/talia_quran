# Freshness and Upgrade Policy

## Principle

Keep Talia current without treating every new release as an automatic migration. A dependency can be newer without being better for Talia.

## Freshness Check

When a task depends on current ecosystem state, verify authoritative current sources as defined in [Source Authority](source-authority.md). Never freeze a permanently “latest” version into this skill.

## Dependency Audit

Start with:

```bash
flutter pub outdated
```

For major-version investigation, prefer a dry run before editing:

```bash
dart pub upgrade --major-versions --dry-run
```

Classify direct and transitive dependencies; trace transitive constraints back to the direct package that owns them.

- Patch: usually lower migration risk, still test.
- Minor: inspect changelog/API changes.
- Major: treat as a migration with breaking-change review.
- Overrides: do not use `dependency_overrides` as a permanent upgrade strategy without a documented reason.

## Package Adoption

Before adding/replacing a package, record the problem solved, built-in alternative, license, maintenance/activity, supported Flutter/platform versions, API stability, transitive dependencies, size/performance/privacy impact when meaningful, migration cost, and rollback/removal plan.

## Upgrade Decision

Upgrade when the change fixes a relevant bug/security/platform issue or materially improves Talia with understood migration risk and verification. Defer when value is low, support is immature, critical Quran/progress flows lack coverage, or the update forces unrelated architecture churn.
