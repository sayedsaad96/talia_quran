# Architecture Contract

- Follow the current Talia repository architecture unless measurable pain justifies change.
- Prefer focused, testable, incremental changes over broad rewrites.
- Search for existing repositories/services/state flows before adding parallel abstractions.
- A new package/framework requires a concrete problem, built-in alternative review, maintenance/platform assessment, migration cost, transitive-dependency impact, and rollback/removal thinking.
- Architecture changes require evidence of architectural pain.
- If a small task expands across unrelated subsystems, stop and reevaluate the root cause/change radius.
- Local fix first; minimal enabling refactor second; architectural proposal only when the first two cannot safely solve the real problem.
- Preserve public/domain contracts and stored data unless the task explicitly includes a migration.
