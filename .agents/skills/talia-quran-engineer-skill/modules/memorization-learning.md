# Memorization & Learning

Treat memorization as an integrated journey, not a standalone screen.

Inspect current session/repetition flows, recitation/testing, **weak** ayah detection, **progress** persistence, exit/restore behavior, achievements/goals where relevant, and **revision** scheduling before proposing new systems.

Prefer extending existing capabilities. Validate transitions such as start → practice → pause/exit → restore → complete → schedule review → revisit weak items. Stored progress and identifiers are migration-sensitive.

Read the memorization boundaries in [Project Playbook](../references/project-playbook.md). Current work belongs to `features/memorization_plus` and shared `core/memorization`, including the V2 session engine. Inspect legacy `hifz` migration/read compatibility without restoring its retired write API.

For outcome changes, preserve committer transaction/idempotency and audience-specific effects: adult outbox processing versus child `awardKidsPoints`/session-log handling. Do not route child rewards through the adult processor. For account/child changes, check record keys, audience read scope, resume state, caches and cloud merges together. Use existing tests in `test/core/memorization/v2`, audience/owner tests and relevant `test/integration` paths; add a regression at the failing boundary rather than a second progress implementation.
