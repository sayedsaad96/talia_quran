# TALIA AUDIT — PROMPT 2 OF 5
# FEATURE COMPLETENESS, SMART COACH & EXECUTION PATH ANALYSIS

---

## PREREQUISITES

You must have completed PROMPT 1 first.

Input required: `TALIA_AUDIT_PHASE1_MAP.md`

Read it now. Use it as your map.

Do NOT re-scan the full codebase from scratch.

Use Phase 1 findings to guide WHERE to look.

---

## CRITICAL RULES

- Code is truth. No documentation, no assumptions.
- If a path is untraceable → mark UNVERIFIABLE. Do NOT guess.
- Every finding needs: file:line as evidence.
- If evidence is missing → do not report the finding.

---

## TALIA DOMAIN RULES (Non-Negotiable)

These are product invariants. If code contradicts them → FINDING, not a correction:

1. State management is Cubit only — no Riverpod
2. Email confirmation is disabled by product decision
3. Reading confirmation is timer-based only (no tap-to-confirm)
4. Certificates are shared across ALL memorization paths (Hifz, Plus, Kids, legacy)
5. Smart Coach adult priority order:
   1. Weak ayah due → quiz
   2. Due near revision → daily plan
   3. Due far revision → daily plan
   4. Incomplete daily plan
   5. New ayahs in plan
   6. Hifz due fallback
   7. Kids current mission
6. `memorizedReviewDue` kind → adult only → routes to `/memorization-plus/quiz?surahId=...`
7. V2 memorization is behind feature flags — verify if active in production builds

---

## PART A — FEATURE COMPLETENESS AUDIT

For every feature found in Phase 1, determine:

### For each feature, answer these 5 questions from code:

**1. Is the UI reachable?**
Trace: Does any live route point to this screen?
Is it behind a feature flag that defaults to disabled?

**2. Is the Cubit wired?**
Trace: Is the Cubit registered in GetIt?
Is it provided to the screen via BlocProvider?

**3. Does the business logic complete?**
Trace: Cubit method → Repository call → Data source.
Does it actually return data, or does it dead-end?

**4. Is the data persisted correctly?**
Trace: What gets saved after a user action?
Is Isar write confirmed? Is Supabase sync attempted?

**5. Is there a recovery path on error?**
What happens when the network is down?
What happens when Isar is empty?

### Output format per feature:

```
## Feature: [Name]

| Question | Answer | Evidence (file:line) |
|----------|--------|----------------------|
| UI Reachable? | YES / NO / PARTIAL | |
| Cubit Wired? | YES / NO / PARTIAL | |
| Business Logic Complete? | YES / NO / PARTIAL | |
| Data Persisted? | YES / NO / PARTIAL | |
| Error Recovery? | YES / NO / MISSING | |

Implementation %: [0–100]
Reachability %: [0–100]
Risk: LOW / MEDIUM / HIGH / CRITICAL

Notes: [anything unusual found in code]
```

---

## PART B — SMART COACH ARCHITECTURE AUDIT

Smart Coach is the core product direction for Talia — not a secondary feature.

Audit it here in Phase 2 because it reveals structural problems early,
before the bug hunt in Phase 3.

### Step 1 — Locate Smart Coach in code

Start from Phase 1 map. Find:
- The SmartCoach class or service
- The Cubit that drives it
- The repository or data source it queries
- The screen(s) that display its output
- The routes it navigates to

Do NOT grep blindly. Use the class names from Phase 1 map.

Trace the call graph:

```
SmartCoachCubit (or equivalent)
  ↓ calls
[Repository or Service]
  ↓ queries
[Data Source: Isar / Supabase / hardcoded]
  ↓ returns
[RecommendationSignal or equivalent type]
  ↓ drives
[HomeScreen card or widget]
  ↓ on tap navigates to
[Target route]
```

If any link in this chain is missing → mark as BROKEN at that step.

### Step 2 — Verify the 7-priority logic

For each of the 7 Smart Coach priorities, find the code that implements it:

```
Priority 1: Weak ayah due → quiz
  Code location: [file:line or NOT FOUND]
  "Weak ayah" defined as: [what threshold/condition in code]
  Data source for weak ayahs: [Isar collection / field name]

Priority 2: Due near revision → daily plan
  Code location: [file:line or NOT FOUND]
  "Near" defined as: [what threshold in days]
  Data source: [file:line]

Priority 3: Due far revision → daily plan
  Code location: [file:line or NOT FOUND]
  Data source: [file:line]

Priority 4: Incomplete daily plan
  Code location: [file:line or NOT FOUND]
  Daily plan tracked in: [Isar collection / field]

Priority 5: New ayahs in plan
  Code location: [file:line or NOT FOUND]

Priority 6: Hifz due fallback
  Code location: [file:line or NOT FOUND]

Priority 7: Kids current mission
  Code location: [file:line or NOT FOUND]
  Guard: is this correctly excluded from adult mode?
```

### Step 3 — Data availability for Smart Coach

For each signal Smart Coach needs, determine where the data lives:

```
Signal: failureCount / mistake tracking
  Stored in: [Isar field / Supabase column / NOT STORED]
  Written by: [file:line]
  Read by Smart Coach: [file:line or NOT READ]

Signal: nextReview date (SM-2)
  Stored in: [file:line]
  Read by Smart Coach: [file:line or NOT READ]

Signal: dailyPlan completion status
  Stored in: [file:line]
  Read by Smart Coach: [file:line or NOT READ]

Signal: sessionHistory
  Stored in: [file:line]
  Read by Smart Coach: [file:line or NOT READ]
```

### Step 4 — Smart Coach output

```
Smart Coach Implementation Status:

| Component | Status | Evidence |
|-----------|--------|----------|
| Priority logic (7 rules) | COMPLETE / PARTIAL / MISSING / HARDCODED | |
| Data queries exist | YES / PARTIAL / NO | |
| Navigation targets valid | YES / PARTIAL / NO | |
| Kids/Adult guard | YES / MISSING | |
| memorizedReviewDue adult-only | YES / MISSING | |

Readiness: [0–100]%

Blockers:
1. [...]
2. [...]

Estimated effort to production-ready Smart Coach: S / M / L / XL
```

---

## PART C — MEMORIZATION SYSTEM DEEP AUDIT

Talia may have multiple overlapping memorization systems.
Map all of them and determine if they conflict.

### Step 1 — Count the systems

Use class names from Phase 1 map, then verify:

```
Memorization Systems Found:
1. [Name] — Entry point: [file] — Status: [active/legacy/dead]
2. [Name] — ...
```

For each system, open its entry file and trace:
- Where does it start?
- What Cubit drives it?
- What does it write to Isar?
- What does it sync to Supabase?
- Can it run simultaneously with another system?

### Step 2 — SM-2 Implementation

Find the SM-2 algorithm implementation. Open the file directly — don't grep.

Verify:
- Does EF clamp to minimum 1.3?
- Does it use UTC dates for comparison?
  - `DateTime.now()` without `.toUtc()` for date comparison → **BUG**
- Is it applied per-ayah globally or per-surah?
- Is there one SM-2 implementation or multiple?

If multiple SM-2 implementations exist:
- Do they produce the same results for the same inputs?
- Which one does production use?

Flag any implementation that:
- Uses `DateTime.now()` without `.toUtc()` for date comparison → **BUG**
- Has EF minimum below 1.3 → **BUG**
- Resets repetitions on grade < 3 but doesn't reset intervalDays to 1 → **BUG**

### Step 3 — Review System Map

For each review system found:

```
Review System: [Name]
Trigger: [what launches it — route + Cubit method]
SM-2 Update: [YES/NO — file:line]
Isar Write: [YES/NO — file:line]
Supabase Sync: [YES/NO — file:line]
Conflicts with: [other review system name or NONE]
```

### Step 4 — Progress Calculation

Find every place where memorization progress is calculated.

Do NOT use broad grep. Instead:
- Open each feature's cubit
- Look for methods that return a percentage, count, or progress value
- Identify what data source each reads from

For each calculation:
- Is it reading from Isar, Supabase, or SharedPreferences?
- Could two different screens show different values for the same user?
- If yes → **DATA CONSISTENCY BUG**

---

═══════════════════════════════════════════════════════════
PART C.5 — SOURCE OF TRUTH AUDIT
═══════════════════════════════════════════════════════════

OBJECTIVE
─────────
For every critical business domain in Talia, identify the
single source of truth. Detect fragmentation, stale reads,
and screens that could show inconsistent data.

Do NOT rely on docs or comments.
Trace actual write paths through the live codebase.

───────────────────────────────────────────────────────────
DOMAINS TO AUDIT (10 total)
───────────────────────────────────────────────────────────

Audit each domain below using the OUTPUT FORMAT.

1.  Memorization Progress
    (which ayahs/surahs are considered memorized)

2.  Review Progress
    (SM-2 intervals, due dates, review history)

3.  Daily Plan
    (today's plan — generated vs persisted vs derived)

4.  Certificates
    (which certificates are unlocked and when)

5.  Kids Progress
    (missions, stars, houses, points)

6.  XP
    (total XP, XP history)

7.  Streaks
    (current streak, freeze state, last activity date)

8.  Smart Coach Signals
    (what data Smart Coach reads to generate recommendations)

9.  User Profile
    (name, mode, plan, onboarding state)

10. Guardian / Parent Data
    (linked children, parent permissions, child sessions)

───────────────────────────────────────────────────────────
OUTPUT FORMAT — per domain
───────────────────────────────────────────────────────────

For each domain, produce:

DOMAIN: <name>
─────────────────────────────────────────────────────────
PRIMARY SOURCE:
  Collection/Table : <exact Isar collection or Supabase table>
  File             : <path:line>

WRITERS:
  • <CubitOrRepo>  → <method>  → <file:line>
  • <CubitOrRepo>  → <method>  → <file:line>

READERS:
  • <Screen/Cubit> → <method>  → <file:line>

SECONDARY SOURCES (if any):
  • <collection or cache>  → <file:line>

DIVERGENCE POSSIBLE?
  YES / NO
  Reason: <one sentence>

VERDICT:
  [ OK ]               — single writer, consistent reads
  [ CONSISTENCY_BUG ]  — two screens could show different values
  [ DATA_FRAGMENTATION ]— multiple writable sources for same concept
  [ STALE_READ ]       — a screen reads from a non-primary source
  [ UNKNOWN ]          — cannot determine without runtime trace

IF verdict is not OK:
  EXACT CONFLICT:
    Writer A : <file:line>
    Writer B : <file:line>
    Reader X sees: <source>
    Reader Y sees: <source>
  RISK: <one sentence on user-visible impact>

───────────────────────────────────────────────────────────
CROSS-DOMAIN CONSISTENCY CHECK
───────────────────────────────────────────────────────────

After auditing all 10 domains, answer these questions
with exact file:line evidence:

Q1. Can the Home screen show a streak value different
    from the Profile/Progress screen?

Q2. Can a certificate appear unlocked on the Certificates
    screen but not trigger in the AchievementService?

Q3. Can Kids progress affect Adult Smart Coach signals?
    (i.e. is there a leak from kidsMode records into
     adult ReviewDueEvaluator reads?)

Q4. Can two concurrent sessions (e.g. background sync +
    active session) write to the same Isar collection
    simultaneously? If yes, is there a transaction guard?

Q5. After Guest-to-Account migration, which domains
    carry over and which are reset? Is this intentional?

───────────────────────────────────────────────────────────
FRAGMENTATION SUMMARY TABLE
───────────────────────────────────────────────────────────

Produce this table last:

| Domain              | Primary Source | Writers | Verdict              |
|---------------------|----------------|---------|----------------------|
| Memorization        |                |         |                      |
| Review              |                |         |                      |
| Daily Plan          |                |         |                      |
| Certificates        |                |         |                      |
| Kids Progress       |                |         |                      |
| XP                  |                |         |                      |
| Streaks             |                |         |                      |
| Smart Coach Signals |                |         |                      |
| User Profile        |                |         |                      |
| Guardian Data       |                |         |                      |

Any row with verdict ≠ OK is a blocker for production.

## PART D — EXECUTION PATH TRACES

Trace these exact user journeys end to end.
For each journey, write every function call in the chain.

**Format:**
```
Journey: [name]
User Action: [what user taps/does]

Execution Chain:
[ScreenWidget] → onTap()
  → [CubitName].[methodName]()
    → [UseCaseName].call() [if exists]
      → [RepositoryImpl].[method]()
        → [DataSource].[query]()
          → [Storage/Network call]

Result:
  Success path: [what happens]
  Failure path: [what happens or MISSING]

Status: COMPLETE / BROKEN / PARTIAL / UNVERIFIABLE
Broken at: [exact file:line if broken]
```

### Journeys to trace:

**J1 — New User Onboarding**
User opens app for first time → completes onboarding → reaches home.

**J2 — Guest Mode Entry**
User skips auth → uses app as guest → what features are accessible?
Does any path attempt a Supabase write? → **BUG if yes**

**J3 — Adult Memorization Session**
Home → tap memorize → pick surah/ayah → complete session → progress saved.

**J4 — Spaced Review Session**
Home → Smart Coach or Review card → review due ayah → grade → SM-2 updated.

**J5 — Kids Mode Session**
Parent sets up child → child opens kids home → completes mission.

**J6 — Quran Reading**
Open Quran reader → navigate to surah → read ayahs → reading tracked?

**J7 — Certificate Generation**
User reaches certificate milestone → certificate shown.
What triggers it? Is it consistent across all memorization paths?

**J8 — Account Sync**
User has local data → logs in → what syncs? What stays local?
Is there a conflict resolution strategy?

**J9 — V2 Memorization (if feature flag active)**
Trace the V2 flow: what is different from V1?
Do V2 sessions write to the same Isar collections as V1? → **BUG if yes**

**J10 — Smart Coach → Navigation**
App loads → Smart Coach evaluates → recommendation shown → user taps.
Does `memorizedReviewDue` correctly route adult-only to `/memorization-plus/quiz?surahId=...`?

---

## PART E — DUPLICATION AUDIT

Find duplicate implementations — same logic written twice.

Do NOT use name-collision grep. Instead:
- From Phase 1 Cubit graph, find cubits with similar state types
- From Phase 1 repository graph, find repositories querying the same Isar collection
- From Phase 1 navigation map, find routes leading to visually identical screens

Report only confirmed duplicates, not naming coincidences.

**Output format:**
```
Duplication: [short title]
  System A: [file:line]
  System B: [file:line]
  Overlap: [what they share]
  Impact: [which one should survive]
```

---

## PART F — DEAD CODE AUDIT

Find code that exists but is never reached.

Start from Phase 1 navigation map:
- Take every route in the router
- Verify there is at least one `context.go()` or `context.push()` pointing to it from live code
- Routes with no callers → DEAD ROUTE

Then for Phase 1 Cubit graph:
- Take every registered Cubit
- Verify at least one widget provides it via BlocProvider
- Cubits with no provider → DEAD CUBIT

**Output format:**
```
Dead Code Item:
  Type: [Screen | Cubit | Repository | Route | Service]
  File: [path]
  Reason: UNREACHABLE / UNREGISTERED / UNROUTED
  Safe to delete: YES / NEEDS INVESTIGATION
```

---

## OUTPUT FILE

Save as: `TALIA_AUDIT_PHASE2_FEATURES.md`

Structure:
```
# TALIA AUDIT — PHASE 2 — FEATURES, SMART COACH & FLOWS
Generated: [date]

## Feature Completeness Table
[Feature | Impl% | Reachability% | Risk]

## Smart Coach Architecture Audit
[7-priority verification + data availability + readiness score]

## Memorization System Audit
[All systems + conflicts]

## SM-2 Audit
[Algorithm correctness]

## Execution Path Traces
[All 10 journeys]

## Duplication Findings
[Confirmed duplicates only]

## Dead Code Findings
[Navigation-verified dead items]

## UNVERIFIABLE PATHS
[Anything that couldn't be traced]
```

---

**When done: hand both output files to PROMPT 3.**
