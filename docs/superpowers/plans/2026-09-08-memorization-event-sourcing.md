# Memorization Event-Sourcing Implementation Plan

**Source:** User-approved memorization and review remediation plan, 2026-09-08.

## Product invariants

1. Quran memorization progress is never advanced unless durable local evidence
   commits successfully.
2. No recording or recognized spoken text is persisted locally or remotely.
3. One review outcome is idempotent by `eventId` and by `(sessionId, taskId)`.
4. A manual grade is conservative practice: it completes the required task and
   schedules the next-day review, but cannot establish mastery or a certificate.
5. SM-2 remains the production scheduler. FSRS consumes the same event stream
   in shadow mode until its promotion gate is satisfied.
6. Legacy review records remain baselines, not fabricated review events.

## Delivery order

### Task 0 — Safety hotfix

- Derive a passed ayah from the engine's before/after `passedAyahNumbers`, not
  from a result that a state transition clears.
- Do not checkpoint, clear a session, show completion, or grant rewards after
  review persistence fails. Surface a retryable error instead.
- Validate persisted phase/index values and serialize stop/evaluate actions.
- Add end-to-end Cubit coverage for real engine results in blocks 1, 5, and 7.

**Gate:** each automatic pass persists exactly once; an injected save failure
leaves a resumable task and visible retry state.

### Task 1 — Local event and transactional outbox foundation

- Add Isar `ReviewEvidenceEvent` and `ReviewEffectOutbox` collections with
  unique idempotency keys, privacy-safe fields, UTC time, and study-day key.
- Add `commitReviewOutcome()` that atomically writes the event, review
  projection, checkpoint/plan state, and effects.
- Process XP, streak, stars, points, and certificates from receipts in the
  outbox rather than inline completion code.
- Make the legacy Hifz migration retry partial rows and only mark completion
  after all rows validate.

**Gate:** crash/failure injection at each storage boundary cannot lose an event,
duplicate a projection, or duplicate an effect.

### Task 2 — Outcome policy and corrected SM-2

- Derive `excellent`, `average`, and `weak` from all attempts, failures, and
  hints. A failed due review records a lapse even if later recovered.
- Bound an ayah to one SRS promotion per study day; later failures may lower it.
- Make manual results conservative and exclude them from mastery/certification.
- Persist automatic delayed-review evidence required for mastery and run FSRS
  in shadow mode against the event stream.

**Gate:** same-day repeats cannot inflate strength, and the mastery predicate
requires three automatic delayed successes on distinct study days.

### Task 3 — Global daily queue and explicit session specifications

- Introduce `MemorizationSessionSpec` and ordered `DailyPlanTask` with a full
  `AyahRef`, task identity, kind, due time, and completion event.
- Build the global queue across surahs: weak/late, near, far, retention, then
  new. Suppress new work when required backlog exceeds review capacity.
- Review sessions execute only their specified tasks. New memorization retains
  learning, recitation, and block-review phases.
- Keep old routes by converting their parameters to a session spec on entry.

**Gate:** multi-surah due work has no ayah-number collisions, retention is
visible/required, and review never expands into adjacent ayahs.

### Task 4 — Append-only cloud events

- Add `ayah_review_events`, append/pull RPCs, strict grants and RLS, and SQL
  tests for owner, other account, anonymous user, linked guardian, and revoked
  guardian.
- Server derives owner from `auth.uid()`, validates payloads, assigns a stable
  sequence, and never permits client update/delete of accepted events.
- Sync pushes idempotent events, pulls by `(server_sequence, event_id)`, then
  rebuilds affected local projections. Keep the current snapshot projection
  during the supported-version migration window.

**Gate:** offline two-device retries, response loss, and clock skew preserve
every accepted event without a stuck dirty state.

### Task 5 — Visible journey, migration, and controlled rollout

- Present weak, near, far, retention, and new sections with reasons, backlog,
  next due date, evaluation method, attempts, hints, and recovery work.
- Rename the misleading quiz entry and route notifications to a valid fresh
  session specification.
- Add accessible semantics/live announcements and narrow RTL/English layouts.
- Offer historical verification for unevidenced active-session passes; keep old
  completed sessions unchanged. Dual-write, feature flag, internally validate,
  then roll out 5%, 25%, and 100%.

**Gate:** old users retain baseline progress and receive an explicit gentle
verification task rather than silent demotion.

## Required verification

- TDD regression tests for every behavioral mutation named above.
- Flutter tests for blocks 1/3/5/8/10, manual/automatic outcomes, persistence
  errors, relaunch/retry, backlog, multi-surah tasks, account/audience privacy,
  and legacy migration.
- Supabase RLS/RPC tests before enabling cloud-event writes.
- `flutter test` and `flutter analyze` before each delivery gate; Android
  offline/relaunch/sync E2E remains required before staged activation.

## Scope discipline

- No table or legacy snapshot deletion in this delivery.
- No production FSRS scheduling before at least 1000 delayed automatic outcomes
  and a holdout result no worse than corrected SM-2.
- Schema/code generation are committed with their source models.
