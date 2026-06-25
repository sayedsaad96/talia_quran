# TALIA AUDIT — PROMPT 4 OF 5
# SOURCE OF TRUTH AUDIT

---

## PREREQUISITES

You must have completed PROMPTS 1, 2, and 3 first.

Input required:
- `TALIA_AUDIT_PHASE1_MAP.md` (data flow map section)
- `TALIA_AUDIT_PHASE2_FEATURES.md` (memorization systems section)
- `TALIA_AUDIT_PHASE3_BUGS.md` (data consistency bugs section)

This is the most important structural audit in the system.

---

## WHY THIS AUDIT EXISTS

Talia has at minimum:
- Hifz system
- Memorization Plus system
- V2 system
- Smart Coach
- Kids Mode
- Review engine
- Streak tracking

Each of these reads and writes data.

The critical question is not "does the feature work?"

The critical question is: **"When two features read the same data, do they agree?"**

Data fragmentation — where the same logical fact (e.g. "user has memorized ayah X")
is stored, computed, or updated differently by different features — is the
hardest class of bug to find and the most damaging in production.

One wrong sync, one missed write, one stale cache — and the user's progress
is silently wrong. They may never know until they lose months of memorization records.

---

## CRITICAL RULES

- Every answer must cite file:line
- If you cannot find evidence → write UNKNOWN, not a guess
- UNKNOWN is not a failure — it is critical information
- Multiple owners of the same data = DATA FRAGMENTATION (flag immediately)

---

## THE 8 CRITICAL DATA ENTITIES

For each entity below, answer the 5 questions.

If you find multiple owners → this is a **DATA FRAGMENTATION** finding, ranked P0.

---

### ENTITY 1: Memorization Progress

*"How many ayahs has the user memorized?"*

```
Single Source of Truth:
  Storage location: [Isar collection name + field / Supabase table.column / UNKNOWN]
  Owner (who writes it): [file:line]

Read by:
  Home screen: [file:line or NOT READ HERE]
  Progress/stats screen: [file:line or NOT READ HERE]
  Smart Coach: [file:line or NOT READ HERE]
  Certificates: [file:line or NOT READ HERE]
  Other: [list]

Write triggers:
  After memorization session: [file:line or NOT WRITTEN]
  After review: [file:line or NOT WRITTEN]
  On sync from Supabase: [file:line or NOT WRITTEN]

Conflict risk:
  Do all readers query the same collection + field? YES / NO / UNKNOWN
  Could V1 and V2 sessions write to different fields? YES / NO / UNKNOWN

Fragmentation verdict: SINGLE SOURCE / FRAGMENTED / UNKNOWN
```

---

### ENTITY 2: Review Progress (SM-2 State)

*"What is the SM-2 state (EF, interval, nextReview) for each memorized ayah?"*

```
Single Source of Truth:
  Storage location: [Isar collection + fields / Supabase table / UNKNOWN]
  Owner (who writes it): [file:line]

Read by:
  Review due evaluator: [file:line or NOT READ HERE]
  Smart Coach: [file:line or NOT READ HERE]
  Stats screen: [file:line or NOT READ HERE]

Write triggers:
  After review session grades submitted: [file:line or NOT WRITTEN]
  After V2 session: [file:line — same collection as V1? YES/NO]
  On Supabase sync: [file:line or NOT WRITTEN]

SM-2 state fields stored:
  easeFactor: [field name in Isar + type]
  intervalDays: [field name + type]
  repetitions: [field name + type]
  nextReview: [field name + type — DateTime with timezone? stored as UTC?]
  lastGrade: [field name + type]

Conflict risk:
  Is nextReview stored as UTC? [YES / NO — check the @IsarType annotation]
  Is there a separate nextReview per memorization path? [YES / NO]

Fragmentation verdict: SINGLE SOURCE / FRAGMENTED / UNKNOWN
```

---

### ENTITY 3: Daily Plan

*"What is the user's study plan for today?"*

```
Single Source of Truth:
  Storage location: [Isar collection / Supabase / computed at runtime / UNKNOWN]
  Owner (who creates/updates it): [file:line]

Read by:
  Home screen "today's plan": [file:line or NOT READ HERE]
  Smart Coach (Priority 4: incomplete plan): [file:line or NOT READ HERE]
  Progress screen: [file:line or NOT READ HERE]

Write triggers:
  When user creates plan: [file:line or NOT WRITTEN]
  When plan item completed: [file:line or NOT WRITTEN]
  When day changes (rollover): [file:line or NOT WRITTEN — or NOT HANDLED]

Completion tracking:
  Is "plan item completed" stored separately from memorization progress? [YES / NO]
  Or is it derived from SM-2 records? [YES / NO]

Conflict risk:
  Can a plan item show "complete" on home but "pending" in Smart Coach? [YES / NO / UNKNOWN]

Fragmentation verdict: SINGLE SOURCE / FRAGMENTED / UNKNOWN / NOT IMPLEMENTED
```

---

### ENTITY 4: Certificates

*"Has the user earned certificate X?"*

```
Single Source of Truth:
  Storage location: [Isar collection / Supabase table / computed each time / UNKNOWN]
  Owner (who grants it): [file:line]

Read by:
  Certificate screen: [file:line or NOT READ HERE]
  Home achievements section: [file:line or NOT READ HERE]
  Profile: [file:line or NOT READ HERE]

Write triggers:
  After Hifz milestone: [file:line or NOT WRITTEN]
  After Memorization Plus milestone: [file:line or NOT WRITTEN]
  After Kids Mode milestone: [file:line or NOT WRITTEN]
  After V2 session milestone: [file:line or NOT WRITTEN]

Consistency check (RULE-05):
  All memorization paths grant certificates via same code path? [YES / NO]
  If NO → which paths are missing? [list]

Conflict risk:
  Can user earn same certificate twice? [YES / NO / UNKNOWN]
  Is certificate stored by ID or by milestone condition? [ID / CONDITION / UNKNOWN]

Fragmentation verdict: SINGLE SOURCE / FRAGMENTED / UNKNOWN
```

---

### ENTITY 5: Kids Progress

*"What has the child completed in Kids Mode?"*

```
Single Source of Truth:
  Storage location: [Isar collection / Supabase / UNKNOWN]
  Scoped to child user? [YES / NO — is there a childId or userId field?]
  Owner (who writes it): [file:line]

Read by:
  Kids home (current mission): [file:line or NOT READ HERE]
  Parent dashboard: [file:line or NOT READ HERE]
  Smart Coach Priority 7: [file:line or NOT READ HERE]

Write triggers:
  After kids session completes: [file:line or NOT WRITTEN]
  After parent review: [file:line or NOT WRITTEN]

Isolation check:
  Is kids progress stored in a separate collection from adult progress? [YES / NO]
  If NO — could adult review affect kids SM-2 state? [YES / NO / UNKNOWN]

Fragmentation verdict: SINGLE SOURCE / FRAGMENTED / UNKNOWN
```

---

### ENTITY 6: Streaks

*"How many consecutive days has the user studied?"*

```
Single Source of Truth:
  Storage location: [SharedPreferences key / Isar field / Supabase column / UNKNOWN]
  Owner (who increments/resets it): [file:line]

Read by:
  Home streak display: [file:line or NOT READ HERE]
  Profile: [file:line or NOT READ HERE]
  Notifications (if any): [file:line or NOT READ HERE]

Write triggers:
  After any memorization session: [file:line or NOT WRITTEN]
  After any review session: [file:line or NOT WRITTEN]
  After midnight (reset check): [file:line or NOT WRITTEN — or NOT HANDLED]

UTC check:
  Is streak comparison using UTC dates? [YES / NO]
  DateTime.now() vs DateTime.now().toUtc() — which is used? [file:line]

Streak Freeze:
  Is Streak Freeze implemented? [YES / NO]
  If yes: does it write to same storage as streak counter? [YES / NO]
  Can freeze and actual streak get out of sync? [YES / NO / UNKNOWN]

Fragmentation verdict: SINGLE SOURCE / FRAGMENTED / UNKNOWN
```

---

### ENTITY 7: XP / Points

*"How many XP points has the user earned?"*

```
Single Source of Truth:
  Storage location: [Isar / SharedPreferences / Supabase / UNKNOWN]
  Owner (who awards it): [file:line]

Read by:
  Home XP display: [file:line or NOT READ HERE]
  Achievements screen: [file:line or NOT READ HERE]
  Leaderboard (if any): [file:line or NOT READ HERE]

Write triggers:
  After memorization session: [file:line or NOT WRITTEN]
  After review session: [file:line or NOT WRITTEN]
  After certificate earned: [file:line or NOT WRITTEN]
  After kids session: [file:line or NOT WRITTEN]

Conflict risk:
  Is XP awarded by multiple code paths that might double-award? [YES / NO / UNKNOWN]

Fragmentation verdict: SINGLE SOURCE / FRAGMENTED / UNKNOWN / NOT IMPLEMENTED
```

---

### ENTITY 8: Guest-to-Account Migration

*"When a guest signs up, what happens to their local data?"*

```
Migration strategy:
  Does a migration flow exist in code? [YES / NO / UNKNOWN]
  File: [file:line or NOT FOUND]

What gets migrated:
  Memorization progress: [YES / NO / UNKNOWN]
  SM-2 state: [YES / NO / UNKNOWN]
  Streaks: [YES / NO / UNKNOWN]
  Daily plan: [YES / NO / UNKNOWN]

Conflict resolution:
  If guest has local data AND server has data for new account:
  Which wins? [LOCAL / SERVER / MERGE / NOT HANDLED]
  Conflict dialog shown to user? [YES / NO / UNKNOWN]

Data loss risk:
  Can guest data be silently lost on account creation? [YES / NO / UNKNOWN]
  Evidence: [file:line]

Fragmentation verdict: MIGRATION SAFE / MIGRATION RISKY / NOT IMPLEMENTED
```

---

## SYNTHESIS: FRAGMENTATION MAP

After completing all 8 entities, produce:

```
## DATA FRAGMENTATION MAP

Entity | Source Count | Fragmented? | Risk | Evidence
-------|-------------|-------------|------|----------
Memorization Progress | [N] | YES/NO | P0/P1/P2 | [file:line]
Review Progress (SM-2) | [N] | YES/NO | P0/P1/P2 | [file:line]
Daily Plan | [N] | YES/NO | P0/P1/P2 | [file:line]
Certificates | [N] | YES/NO | P0/P1/P2 | [file:line]
Kids Progress | [N] | YES/NO | P0/P1/P2 | [file:line]
Streaks | [N] | YES/NO | P0/P1/P2 | [file:line]
XP | [N] | YES/NO | P0/P1/P2 | [file:line]
Guest Migration | N/A | SAFE/RISKY | P0/P1/P2 | [file:line]

Total fragmented entities: [N]
```

---

## CROSS-SYSTEM CONFLICT CHECK

For every FRAGMENTED entity, answer:

```
Can the following pair of systems show DIFFERENT values for the same data?

Pair: [Hifz] vs [Memorization Plus]
  Entity: Memorization Progress
  How A reads it: [file:line]
  How B reads it: [file:line]
  Can they disagree? YES / NO
  Scenario where they disagree: [describe or N/A]

[Repeat for every fragmented entity + every system pair that touches it]
```

---

## OUTPUT FILE

Save as: `TALIA_AUDIT_PHASE4_SOURCE_OF_TRUTH.md`

```
# TALIA AUDIT — PHASE 4 — SOURCE OF TRUTH AUDIT
Generated: [date]

## Entity Analysis
[All 8 entities — full answers]

## Fragmentation Map
[Summary table]

## Cross-System Conflict Check
[All fragmented entities × all system pairs]

## P0 Fragmentation Issues
[Any FRAGMENTED entity with P0 risk — these are release blockers]

## Recommended Single Source Assignments
[For each fragmented entity: which storage + which owner should win]
```

---

**When done: hand all four output files to PROMPT 5 (Final Report).**
