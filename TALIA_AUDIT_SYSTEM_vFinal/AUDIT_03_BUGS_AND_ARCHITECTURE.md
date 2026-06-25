# TALIA AUDIT — PROMPT 3 OF 5
# BUG HUNT & ARCHITECTURE VIOLATIONS

---

## PREREQUISITES

You must have completed PROMPTS 1 and 2 first.

Input required:
- `TALIA_AUDIT_PHASE1_MAP.md`
- `TALIA_AUDIT_PHASE2_FEATURES.md`

Use the maps already built. Do NOT re-scan blindly.

This prompt is about finding REAL bugs. Not style issues. Not preferences. Real bugs.

---

## CRITICAL RULES

- Report ONLY verified bugs — not speculation
- Every bug must have: file + line + execution path + user impact
- Every architecture violation must have: file + line + rule violated
- If you cannot find the evidence → do NOT report the finding
- Use Find Usages / call-graph tracing — not broad grep when possible

---

## HOW TO SEARCH (IMPORTANT)

Broad grep like `grep -rn "progress"` produces hundreds of false positives.

Instead, use this approach:

**Step 1 — Identify the class or method from Phase 1 map**
Example: "SM-2 is implemented in `SM2Algorithm` class in `lib/core/services/sm2_algorithm.dart`"

**Step 2 — Open that file directly**
Read the actual implementation.

**Step 3 — Trace callers**
Find what calls it:
```bash
grep -rn "SM2Algorithm\|sm2Algorithm" lib/ --include="*.dart" | grep -v ".g.dart"
```

**Step 4 — Follow the call graph**
Open each caller. Read it. Then find its callers. Go 2-3 levels deep.

This gives you a real call graph — not keyword noise.

Use broad grep ONLY as a last resort when you don't know the class name.
When you do use grep, always filter aggressively:
```bash
# BAD: grep -rn "progress" lib/
# GOOD: grep -rn "class.*Progress\|ProgressCalculator\|calculateProgress" lib/ \
#         --include="*.dart" | grep -v ".g.dart" | grep -v "//.*progress"
```

---

## TALIA-SPECIFIC NON-NEGOTIABLE PRODUCT RULES

If code violates any of these → **product bug**, not an architecture preference:

```
RULE-01: SM-2 dates must use UTC.
         DateTime.now() without .toUtc() for date comparison = bug.

RULE-02: SM-2 EF minimum = 1.3.
         Any EF allowed below 1.3 = calculation bug.

RULE-03: V2 memorization must NOT write to V1 Isar collections.
         They must be fully isolated.

RULE-04: Guest mode → no Supabase writes.
         Any repository write without isGuest guard = bug.

RULE-05: Certificate trigger must be consistent across all memorization paths.
         If only one path triggers certificates = product bug.

RULE-06: memorizedReviewDue is adult-only.
         If routed in kids mode = navigation bug.

RULE-07: Email confirmation is disabled.
         If any auth flow requires email confirmation = product violation.

RULE-08: Reading confirmation is timer-based only.
         Any tap-to-confirm in reading flow = product violation.

RULE-09: Smart Coach must not recommend unreachable features.
         Verify navigation targets from Phase 2 findings.

RULE-10: Feature flags must default to disabled in production.
         Check default value of enable_memorization_v2.
```

---

## PART A — BUG HUNT

Work through these categories in order.
For each category: start from Phase 1/2 maps, open relevant files, read the code.

---

### Category 1: SM-2 / Spaced Repetition Bugs

These cause silent data corruption. The user won't see it until their schedule breaks.

**Step 1:** From Phase 2 SM-2 audit, find where the algorithm runs.
Open that file. Read it completely.

**Step 2:** Find every place SM-2 is called:
```bash
grep -rn "[SM2ClassName]\|[sm2MethodName]" lib/ --include="*.dart" | grep -v ".g.dart"
```
(Replace with actual class/method name from Phase 1 map)

**Step 3:** For each call site, check:

```
BUG-SM2-1: Date comparison without UTC
  Look for: DateTime.now() used to compare against nextReview WITHOUT .toUtc()
  Where to check: the SM-2 getDueEntries or equivalent method
  And: any streak or review-due check in repositories
  Effect: reviews trigger at wrong time by timezone offset hours

BUG-SM2-2: EF not clamped to minimum 1.3
  Look for: the EF update formula — does it have .clamp(1.3, 5.0)?
  Effect: EF drops below 1.3, intervals shrink forever for hard ayahs

BUG-SM2-3: Incomplete reset on failure
  Look for: the grade < 3 branch — does it reset BOTH repetitions AND intervalDays to 1?
  Effect: forgotten ayah not reviewed next day if only one field is reset

BUG-SM2-4: Duplicate SM-2 update in one session
  Look for: can submitReview() be called twice for same ayah in one flow?
  Effect: artificially inflated interval, ayah disappears from reviews

BUG-SM2-5: SM-2 saved to Isar but Supabase sync never called
  Trace: repository.save() → does it call supabase.upsert() or just isar.put()?
  Effect: all progress lost on reinstall
```

---

### Category 2: State Bugs (Cubit)

**Step 1:** From Phase 1 Cubit graph, list all cubits with async operations.

**Step 2:** Open each. Find every `emit()` inside a Future or Stream callback.

**Step 3:** Check:

```
BUG-STATE-1: emit() after close
  Look for: async methods where emit() is called without "if (!isClosed)" guard
  Reproduction: navigate away quickly during any loading operation
  Effect: "Bad state: Cannot emit new states after calling close()" crash

BUG-STATE-2: Loading state not cleared on error
  Look for: emit(Loading()) → try → catch → emit(Error())
  Missing: is there an emit(Loaded) or emit(Idle) that never fires on the error path?
  Effect: infinite spinner after any network error

BUG-STATE-3: Race condition on rapid user action
  Look for: cubit methods that can be called again while already running
  Missing: is there a guard like "if (state is Loading) return;"?
  Effect: duplicate writes, double-navigation, inconsistent state
```

---

### Category 3: Navigation Bugs

**Step 1:** From Phase 1 navigation map, open the router file.

**Step 2:** Read every redirect function. Check:

```
BUG-NAV-1: go() vs push() confusion
  go() replaces the stack — correct for tab switches
  push() adds to stack — correct for detail screens
  Find: any go() in a detail screen flow where back-button should work
  Effect: back button skips screens or exits the app unexpectedly

BUG-NAV-2: Async operation in redirect
  Look for: redirect: (context, state) async { ... }
  GoRouter redirect MUST be synchronous — async redirect causes black screen
  Effect: infinite loading or black screen on navigation

BUG-NAV-3: Auth guard not reactive
  Look for: redirect reading auth state as one-time value (not listening to stream)
  Effect: user logs out but protected screen stays visible until full restart

BUG-NAV-4: Route parameter not null-checked
  From Phase 2 journeys: any route that expects surahId or similar
  Look for: final surahId = state.pathParameters['surahId']! (force unwrap)
  Effect: crash on malformed deep link or direct navigation
```

---

### Category 4: Data Consistency Bugs

**Step 1:** From Phase 1 data flow map, list all storage systems (Isar, Hive, SharedPrefs, Supabase).

**Step 2:** From Phase 1 Cubit graph, find which cubits read from multiple sources.

**Step 3:** Check:

```
BUG-DATA-1: Same data, multiple sources
  Find: any field (streak, progress %, ayah count) read from different sources
  in different cubits or screens.
  Evidence: open both files — confirm they read different collections.
  Effect: Home shows streak=5, Profile shows streak=3.

BUG-DATA-2: Sync overwrites newer local data
  Look for: sync logic that does a full replace instead of conflict-aware merge.
  Find: the sync repository method. Does it check timestamps before writing?
  Effect: offline progress lost after reconnecting.

BUG-DATA-3: Hive and Isar storing same data
  From Phase 1 map — list Hive boxes and Isar collections.
  Find overlap: is streak/progress stored in both?
  Effect: whichever is read last wins. Race condition.

BUG-DATA-4: Isar not cleared on logout
  Find: the logout method in auth repository.
  Does it call isar.clear() or equivalent for user-specific collections?
  Effect: user A's data visible to user B on shared device.

BUG-DATA-5: V2 writing to V1 Isar collections (RULE-03)
  From Phase 2: find V2 session Isar writes.
  Confirm they write to V2-specific collections, not V1 collections.
  Effect: V2 test data corrupts V1 production progress.
```

---

### Category 5: Async / Resource Bugs

**Step 1:** From Phase 1 map, find all StreamSubscription usage and AudioPlayer usage.

**Step 2:** For each, check its dispose lifecycle:

```
BUG-ASYNC-1: StreamSubscription leak
  Find: every StreamSubscription declared in a Cubit or State.
  Check: is cancel() called in the cubit's close() or widget's dispose()?
  Effect: memory leak, callbacks fire on dead objects.

BUG-ASYNC-2: AudioPlayer not disposed
  Find: the audio player initialization.
  Check: is dispose() called when leaving the memorization screen?
  Effect: audio continues after navigation, memory leak.

BUG-ASYNC-3: Future in initState without mounted check
  Find: any StatefulWidget with initState calling an async method
  that calls setState().
  Check: does it guard with "if (!mounted) return;"?
  Effect: setState after dispose → crash.

BUG-ASYNC-4: Supabase realtime subscription accumulation
  Find: any supabase.channel() or .stream() subscription.
  Check: is unsubscribe() called in dispose?
  Effect: N subscriptions after N screen visits → performance degradation.
```

---

### Category 6: Talia-Specific Business Logic Bugs

```
BUG-TALIA-1: Supabase write for guest user (RULE-04)
  Find: the guest auth state type in code.
  Then find: every repository write method.
  Check: does it guard with "if (isGuest) return;" before any Supabase call?
  Effect: Supabase auth error or silent failure for guest users.

BUG-TALIA-2: Smart Coach shows adult content in kids session
  From Phase 2 Smart Coach audit: find the kids/adult mode switch.
  Check: is priority 7 (Kids current mission) only shown in kids mode?
  Check: is memorizedReviewDue excluded from kids mode?
  Effect: child taps recommendation → wrong screen → parent confused.

BUG-TALIA-3: Certificate triggered inconsistently (RULE-05)
  Find: every place certificate logic runs.
  Check: does Hifz path trigger it? Does Memorization Plus? Does Kids mode?
  If any path is missing → product bug.

BUG-TALIA-4: Feature flag checked inconsistently (RULE-10)
  Find: every screen that belongs to V2 flow.
  Check: does every entry point read the feature flag before rendering?
  Effect: V2 UI partially visible when flag is disabled.
```

---

## PART B — ARCHITECTURE VIOLATIONS

### Clean Architecture Rules for Talia:

```
LAYER RULES:
presentation/ → can import from domain/ ONLY
domain/ → cannot import from data/ or presentation/
data/ → can import from domain/ ONLY
core/ → can be imported by any layer

FEATURE RULES:
Each feature is self-contained in lib/features/[feature]/
Cross-feature dependencies must go through core/ or domain interfaces

DI RULES:
GetIt is the ONLY service locator
No Supabase.instance.client accessed directly in repositories
No sl<X>() or getIt<X>() called inside business logic
```

### How to verify (call-graph approach):

**For layer violations:**
From Phase 1 folder structure, identify presentation files.
Open each. Check imports. Flag any import containing `data/repository` or `data/datasource`.

```bash
# Targeted — only checks presentation layer imports
grep -rn "^import.*\/data\/" lib/features/*/presentation/ \
  --include="*.dart" | grep -v ".g.dart"
```

**For DI bypass:**
From Phase 1 map, find all repository files.
Open each. Check if it accesses `Supabase.instance.client` directly
instead of using the injected client.

```bash
grep -rn "Supabase\.instance\.client" lib/features/ \
  --include="*.dart" | grep -v ".g.dart"
```

**For service locator abuse:**
Find cubits and repositories.
Check if any call `sl<X>()` or `getIt<X>()` inside business logic
(only acceptable in DI registration files).

```bash
grep -rn "sl<\|getIt<\|GetIt\.instance\." lib/features/ \
  --include="*.dart" | grep -v ".g.dart" \
  | grep -v "injection\|di\.dart\|locator\.dart\|service_locator"
```

**For god files:**
```bash
find lib/ -name "*.dart" \
  | grep -v ".g.dart" | grep -v ".freezed.dart" \
  | xargs wc -l 2>/dev/null | sort -rn | head -15
```
Any file over 400 lines: open it, verify it has more than one responsibility.

**Report each violation as:**
```
VIOLATION: [type]
File: [path:line]
Rule violated: [which rule above]
Evidence: [exact import or method call]
Risk: LOW / MEDIUM / HIGH
Fix direction: [1-line description of what to change]
```

---

## PART C — TEST COVERAGE REALITY CHECK

Not how many tests. What is actually verified.

**Step 1:** List all test files:
```bash
find test/ -name "*.dart" | sort
```

**Step 2:** For each test file, open it and read what it actually tests.

**Step 3:** Map tests to critical flows from Phase 2 journeys.

Output:
```
Tested Features:
  [Feature] → [scenarios covered]

Critical Flows With NO Tests:
  [Journey] → [why dangerous without tests]

Riskiest untested path:
  [The single most dangerous untested flow]

Test Effectiveness: LOW / MEDIUM / HIGH
```

---

## OUTPUT FILE

Save as: `TALIA_AUDIT_PHASE3_BUGS.md`

```
# TALIA AUDIT — PHASE 3 — BUGS & ARCHITECTURE
Generated: [date]

## CONFIRMED BUGS

### P0 — Release Blockers
[file:line | execution path | user impact | reproduction steps]

### P1 — High Priority
[...]

### P2 — Medium Priority
[...]

### P3 — Technical Debt
[...]

## ARCHITECTURE VIOLATIONS
[file:line | rule violated | fix direction]

## PRODUCT RULE VIOLATIONS
[Any code contradicting the 10 NON-NEGOTIABLE RULES]

## TEST COVERAGE REALITY
[What's tested | critical untested flows]
```

---

**When done: hand all three output files to PROMPT 4 (Source of Truth Audit).**
