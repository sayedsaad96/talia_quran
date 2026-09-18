# Dependency Upgrades

Reject blind **update everything** behavior.

## Audit

1. Run `flutter pub outdated`.
2. Separate direct from transitive packages.
3. Classify patch, minor, and major changes.
4. Read official changelog/migration guidance for meaningful changes.
5. Map affected Talia features and platform requirements.
6. Upgrade in controlled batches; run analyzer/tests/runtime checks after each risky batch.

## Adoption / Replacement

Before adding or replacing a package, record the real problem, built-in alternative, maintenance health, license, Flutter/platform support, API stability, transitive dependencies, privacy, migration cost, app-size/performance impact when meaningful, and rollback/removal path.

A newer or more popular package is not sufficient reason to replace a working dependency.
