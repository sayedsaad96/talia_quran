# Pre-Release Audit

Start only when the user asks for an application audit. This workflow is read-only on application source; proposed fixes require a separate request. Root owns scope, coverage, assignments and verdict.

1. Ask `scout` for a complete feature/user-flow inventory, or reuse a current inventory with matching revision and scope. Refresh only changed areas. A feature-directory list alone is insufficient.
2. Assign distinct scopes to `qa-reviewer`, `flutter-reviewer`, `religious-reviewer`, `ux-accessibility-reviewer` and `release-auditor`. Run in waves within the concurrency limit, normally at most three subagents concurrently. Share inventory/evidence; search only gaps and disputed paths. Custom roles pin their own model/effort.
3. Reviewers remain read-only. `release-auditor` may run safe analyzer/tests/release build, capturing command, exit and relevant output. Inspect release/SQL helper scripts before running; never mutate a live backend as an audit shortcut. Refresh official platform/store facts when relevant.
4. Cover reader/QCF/restore/bookmarks/audio, adult and child memorization/revision/listening, family/auth/sync, khatmah/certificates, azkar/Islamic sources, home/progress/rewards, settings/onboarding, prayers/notifications, share/deep links, offline/upgrade and device lifecycle according to inventory. Mark unexercised paths unverified. A build does not prove a flow works.
5. Ask `final-reviewer` to consolidate findings, deduplicate and check contradictions against primary evidence. Root verifies missing coverage and gives the final release verdict.

Severity: **P0 Release Blocker**, **P1 Critical**, **P2 Major**, **P3 Minor**, **P4 Improvement**. Any credible Quran text/ayah numbering/surah order/religious-reliability concern stays P0 until checked against an authoritative source; difficulty reproducing is not grounds to downgrade it.

Each finding includes location, flow, verified defect versus reasoned risk/unknown, failure, evidence/reproduction where possible, impact, severity and remedy. Final report includes coverage, commands/results, unresolved questions, prioritized findings and verdict. Do not claim full coverage or `Release Verified` from partial gates. Escalate narrow critical findings according to [Model Delegation](../core/model-delegation.md); do not rerun a whole specialist audit for one uncertainty.
