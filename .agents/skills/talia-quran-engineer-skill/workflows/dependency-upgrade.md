# Dependency Upgrade Workflow

1. State the reason for upgrade and affected Talia capability.
2. Capture current Flutter/Dart constraints and `flutter pub outdated`.
3. Separate direct/transitive dependencies and classify patch/minor/major.
4. Read authoritative changelog, migration, platform, and breaking-change guidance.
5. Map affected features and data/platform contracts.
6. Upgrade in the smallest controlled batch.
7. Run analyzer, targeted/full tests, build/runtime checks proportional to risk.
8. Update `knowledge/dependency-baseline.md`, `tech-radar.md`, or `update-backlog.md` only with verified outcomes.
