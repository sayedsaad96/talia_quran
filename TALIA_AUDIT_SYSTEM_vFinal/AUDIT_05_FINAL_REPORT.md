# TALIA AUDIT — PROMPT 5 OF 5
# FINAL REPORT & RELEASE DECISION

---

## PREREQUISITES

You must have completed ALL previous prompts.

Input required:
- `TALIA_AUDIT_PHASE1_MAP.md`
- `TALIA_AUDIT_PHASE2_FEATURES.md`
- `TALIA_AUDIT_PHASE3_BUGS.md`
- `TALIA_AUDIT_PHASE4_SOURCE_OF_TRUTH.md`

Your job is to SYNTHESIZE — not re-audit.

If something is missing from the four input files, say so.
Do NOT re-scan the codebase. Do NOT fill gaps with assumptions.

---

## FINAL REPORT STRUCTURE

Produce `TALIA_AUDIT_FINAL_REPORT.md` with exactly these sections:

---

### SECTION 1 — Executive Summary

```
App: Talia (تالية) — Quran Memorization
Audit Date: [date]
Prompts completed: 1 → 2 → 3 → 4 → 5

RELEASE VERDICT: 🟢 READY / 🟡 CONDITIONALLY READY / 🔴 NOT READY

Release Confidence Score: [0–100]

Score breakdown:
  Architecture health:        [0–25] pts
  Feature completeness:       [0–25] pts
  Bug severity:               [0–25] pts
  Data integrity (SOT audit): [0–25] pts

One paragraph summary:
[What works, what doesn't, what must happen before release]
```

Score rule: if there are any P0 items (bugs OR fragmented entities),
the maximum score is 55. Non-negotiable.

---

### SECTION 2 — Actual Architecture

From Phase 1:

```
Confirmed stack:
  State management: [Cubit confirmed? / mixed?]
  Navigation: [GoRouter confirmed?]
  DI: [GetIt confirmed?]
  Backend: [Supabase confirmed?]
  Local DB: [Isar / Hive / both?]
  Architecture pattern: [feature-first / layer-first / mixed]

Deviations from intended:
  [List from Phase 3 architecture violations]
```

---

### SECTION 3 — Feature Inventory

Full table from Phase 2:

```
| Feature | Impl% | Reachable% | Risk | Notes |
|---------|-------|-----------|------|-------|
| Quran Reading | | | | |
| Hifz Memorization | | | | |
| Memorization Plus (Adult) | | | | |
| V2 Memorization | | | | |
| Spaced Review (SM-2) | | | | |
| Smart Coach | | | | |
| Kids Mode | | | | |
| Parent/Guardian Dashboard | | | | |
| Guest Mode | | | | |
| Certificates | | | | |
| Onboarding | | | | |
| Settings Hub | | | | |
| Auth (Login/Register) | | | | |
| Account Sync | | | | |
```

---

### SECTION 4 — Data Integrity Summary

From Phase 4 (this is a new top-level section — not in previous audit versions):

```
## Fragmentation Overview

Total critical entities audited: 8
Fragmented entities found: [N]
P0 fragmentation issues: [N]

| Entity | Status | Risk |
|--------|--------|------|
| Memorization Progress | SINGLE SOURCE / FRAGMENTED / UNKNOWN | P0/P1/P2 |
| SM-2 State | | |
| Daily Plan | | |
| Certificates | | |
| Kids Progress | | |
| Streaks | | |
| XP | | |
| Guest Migration | | |

Most critical fragmentation:
  [Entity name] — [why it's the most dangerous]
  Scenario: [what the user sees when data disagrees]
```

---

### SECTION 5 — Memorization System Map

From Phase 2:

```
Systems found: [N]

System 1: [Name] — Status: ACTIVE / LEGACY / DEAD
  SM-2: CORRECT / BUGGY / MISSING
  Isar write: YES / NO
  Supabase sync: YES / NO
  Source of Truth: SINGLE / FRAGMENTED

[Repeat per system]

Conflicts between systems:
  [List from Phase 2 + Phase 4]
```

---

### SECTION 6 — Smart Coach Readiness

From Phase 2:

```
Smart Coach Readiness: [0–100]%

Priority logic implemented:
  Priority 1 (Weak ayah due): IMPLEMENTED / PARTIAL / MISSING
  Priority 2 (Due near): IMPLEMENTED / PARTIAL / MISSING
  Priority 3 (Due far): IMPLEMENTED / PARTIAL / MISSING
  Priority 4 (Incomplete plan): IMPLEMENTED / PARTIAL / MISSING
  Priority 5 (New ayahs): IMPLEMENTED / PARTIAL / MISSING
  Priority 6 (Hifz fallback): IMPLEMENTED / PARTIAL / MISSING
  Priority 7 (Kids mission): IMPLEMENTED / PARTIAL / MISSING

Data availability:
  [Which signals exist / which are missing]

Can Smart Coach be activated now? YES / NO / PARTIALLY

Blockers: [list]
Estimated effort to production Smart Coach: S / M / L / XL
```

---

### SECTION 7 — Confirmed Bug Report

Only confirmed bugs from Phase 3. No speculation.

#### 🔴 P0 — Release Blockers

Each item:
```
BUG-P0-[N]: [Short title]
File: [path:line]
Code:
  [exact offending code — copy from Phase 3]
Execution path:
  [Screen] → [Cubit] → [Repository] → [bug here]
User impact:
  [what the user experiences]
Reproduction:
  1. [step]
  2. [step]
  3. [observed result]
Fix direction:
  [what to change — 1-2 lines]
Estimated effort: S / M / L
```

#### 🟠 P1 — High Priority

Same format, briefer acceptable.

#### 🟡 P2 — Medium Priority

Table format acceptable:
```
| # | File | Bug | Impact | Fix |
```

#### ⚪ P3 — Technical Debt

Table format.

---

### SECTION 8 — Data Fragmentation Bug Report

From Phase 4 — separate section because these are structural, not code-level:

```
FRAG-[N]: [Entity name] is fragmented

Systems that own it:
  Owner A: [file:line] — writes [what]
  Owner B: [file:line] — writes [what]

Conflict scenario:
  [Exact user action that produces disagreeing values]

User impact:
  [what the user sees — e.g. "streak shows 5 on home, 3 on profile"]

Resolution:
  Designated single source: [which storage + which owner]
  Others must: [read from that source / stop writing / merge strategy]

Priority: P0 / P1 / P2
```

---

### SECTION 9 — Architecture Violations

From Phase 3:

```
| # | File | Violation | Severity | Fix |
|---|------|-----------|----------|-----|
```

---

### SECTION 10 — What Should Be Deleted

Items verified as dead code in Phase 2:

```
| File/Folder | Type | Verified Reason | Risk of Deleting |
|-------------|------|-----------------|-----------------|
| lib/features/old_xyz/ | Dead feature | No route, no GetIt reg | LOW |
```

---

### SECTION 11 — What Should Be Refactored

Items that work but have structural problems:

```
| File/Area | Problem | Priority | Effort |
|-----------|---------|----------|--------|
```

---

### SECTION 12 — What Should Be Preserved

Well-implemented code that should NOT be touched:

```
[File or system] — [why it's good — be specific]
```

---

### SECTION 13 — Technical Debt Ranking

All items across all phases, ranked:

```
## P0 (Fix before ANY release):
1. [Item] — [file] — [1-line description]
2. ...

## P1 (Fix this sprint):
1. ...

## P2 (Fix before next release):
1. ...

## P3 (Backlog):
1. ...
```

---

### SECTION 14 — Release Decision

```
## RELEASE DECISION

Verdict: 🟢 READY / 🟡 CONDITIONALLY READY / 🔴 NOT READY

### If 🟡 CONDITIONALLY READY — must fix before shipping:
[Ordered list of P0 items]

### Safe to ship today:
[Features that are complete, single-source, and bug-free]

### Must NOT ship (disable or remove):
[Features that are broken, fragmented, or incomplete]

### Recommended phased release:

Phase 1 (ship after P0 fixes):
  [Feature A, Feature B]
  Estimated time to ready: [X days]

Phase 2 (after P1 fixes):
  [Feature C, Feature D]

Phase 3 (future — needs architecture work):
  [Feature E]

### Next 3 actions (in order):
1. [Most urgent — file + what to do + estimated Xh]
2. [Second — file + what to do + estimated Xh]
3. [Third — file + what to do + estimated Xh]
```

---

## FINAL VALIDATION (run before submitting)

Answer these before finishing:

```
Check 1: Does every P0 bug have file:line evidence from Phase 3?
  → If any P0 has no file:line → demote to UNVERIFIED, move to P3

Check 2: Is the Release Confidence Score consistent?
  → Any P0 bug → max score is 55
  → Any fragmented P0 entity → max score is 55
  → Both → max score is 40

Check 3: Did I include Phase 4 fragmentation findings?
  → Section 4 and Section 8 must be present

Check 4: Did I respect the 10 Non-Negotiable Product Rules?
  → Check RULE-01 through RULE-10 from Prompt 3

Check 5: Did I speculate anywhere?
  → Any finding without evidence → REMOVE IT

All 5 checks passed: YES / NO
If NO → fix before submitting.
```

---

**This is the final deliverable. Sayed reads this to decide what to fix next.**
