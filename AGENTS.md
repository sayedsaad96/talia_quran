# AGENTS.md — Talia (تالية) Quran App
> AI Agent Operating Manual — Read this entirely before touching any file.

---

## 🕌 Project Identity

| Field        | Value                                                                 |
|--------------|-----------------------------------------------------------------------|
| App Name     | تالية (Talia)                                                         |
| Type         | Flutter — Quran Reading + Hifz Memorization + Azkar + Islamic Productivity |
| Architecture | Clean Architecture + Cubit/BLoC                                       |
| State Mgmt   | flutter_bloc / Cubit                                                  |
| Navigation   | GoRouter                                                              |
| Backend      | Supabase                                                              |
| Storage      | Hive (local) + Supabase (remote)                                      |
| Localization | Arabic (primary) + English, RTL-first                                 |
| Target       | Egyptian / MENA market — children, youth, and adult users             |

---

## 🔒 Current Default Mode

**Default mode is `AUDIT MODE` unless the user explicitly says: "Start fixing".**

### In Audit Mode:
- Do NOT modify any application source code
- Do NOT refactor anything
- Do NOT rename files or folders
- Do NOT change `pubspec.yaml` or `analysis_options.yaml`
- Do NOT run `flutter pub add` or any package commands
- Only READ, ANALYZE, and produce documentation files under `docs/`

### To exit Audit Mode:
The user must explicitly say one of:
- `"Start fixing"`
- `"Apply Phase 1"`
- `"Fix this specific issue: ..."`

Anything less is not permission to write code.

---

## 📁 Required Generated Files

During a full audit, the agent creates **only** these three files:

| File | Purpose |
|------|---------|
| `docs/CODEX_FULL_PROJECT_AUDIT.md` | Complete audit report (all 14 sections) |
| `docs/CODEX_FIX_PLAN.md` | Phased implementation plan with risk labels |
| `docs/CODEX_RELEASE_CHECKLIST.md` | Pre-production checklist before shipping |

Do not modify any application source code during the audit step.  
Do not create any other files unless explicitly requested.

---

## 🧠 Core Mission

This is a **production-grade Islamic app** handling sensitive spiritual user flows.

The agent must:
- Deeply understand the project before writing a single line of code
- Protect user data, memorization progress, and streak records at all costs
- Prioritize stability and reversibility over clever refactoring
- Maintain correct, respectful Arabic text across all Islamic content
- Treat every Quran rendering change as high-risk

---

## 🔴 MANDATORY PROCESS — Never Skip Steps

```
1. READ  → Scan the full project structure
2. MAP   → Build architecture + feature understanding
3. RUN   → Execute analysis and test commands
4. AUDIT → Produce full report with all sections
5. PLAN  → Write the implementation plan with safe order
6. FIX   → Apply changes incrementally, one subsystem at a time
7. TEST  → Re-run tests after every change phase
8. VERIFY → Confirm no regressions before moving forward
```

Jumping from step 1 to step 6 is a critical violation.

---

## 🛑 Hard Rules — NEVER Do These

```
❌ Do not write or modify code before completing the audit
❌ Do not delete any file, route, widget, or asset without proof it is unused
❌ Do not perform large refactors without explicit user approval
❌ Do not change Arabic Quran text, ayah numbering, or page layout logic
❌ Do not break offline functionality — the app must work without internet
❌ Do not silently change business logic (memorization scoring, streaks, SM-2)
❌ Do not introduce new packages without checking pubspec.yaml conflicts
❌ Do not ignore analyzer warnings — report them all
❌ Do not add over-engineered solutions for simple problems
❌ Do not duplicate business logic that already exists
❌ Do not mix Cubit/BLoC with Riverpod — the project uses one pattern only
❌ Do not use BuildContext across async gaps without mounted checks
❌ Do not remove user-facing error handling
❌ Do not change localization keys without updating all .arb files
```

---

## ✅ Required Inspection Checklist

Before producing the audit, inspect **all** of the following:

### Project Structure
- [ ] `lib/` — full directory tree, all layers
- [ ] `pubspec.yaml` — dependencies, versions, conflicts, outdated packages
- [ ] `assets/` — fonts, images, JSON data files (Quran data, azkar, etc.)
- [ ] `test/` — existing tests, coverage gaps
- [ ] `android/` — manifest permissions, gradle config, signing
- [ ] `ios/` — Info.plist, entitlements, capabilities
- [ ] `analysis_options.yaml` — lint rules
- [ ] `.env` or secrets handling — no hardcoded keys

### Architecture Layers
- [ ] `domain/` — entities, use cases, repository interfaces
- [ ] `data/` — repository implementations, data sources, DTOs
- [ ] `presentation/` — cubits, states, screens, widgets

### Feature Flows
- [ ] Quran display logic (page, surah, ayah rendering, tajweed colors)
- [ ] Hifz / memorization flow (SM-2 algorithm, session logic)
- [ ] Smart memorization system
- [ ] Azkar system (morning, evening, after salah)
- [ ] Children learning mode
- [ ] Audio-only learner mode
- [ ] Youth / advanced mode
- [ ] Progress tracking and streak logic (UTC correctness)
- [ ] Certificates system
- [ ] Onboarding / tutorial flows
- [ ] Offline functionality and connectivity handling
- [ ] Notifications and settings toggles
- [ ] Last-read position tracking
- [ ] Payment / subscription logic (if present)
- [ ] Authentication and user session management

### State Management
- [ ] All Cubit state classes are sealed/exhaustive
- [ ] No business logic leaks into widgets
- [ ] Cubits properly closed / disposed
- [ ] No duplicate Cubit instances

### Navigation
- [ ] All GoRouter routes defined and functional
- [ ] Deep links / redirect guards work
- [ ] No orphaned routes
- [ ] Back navigation preserves state correctly

### Local Storage
- [ ] Hive boxes opened before use, closed properly
- [ ] Migration strategy for schema changes
- [ ] No data loss on app update

### Performance
- [ ] No expensive work in `build()`
- [ ] ListView / GridView use builders (not children)
- [ ] Images use cached_network_image or similar
- [ ] Quran JSON loaded lazily (not all at startup)
- [ ] `const` constructors used everywhere possible
- [ ] No widget rebuild storms from broad `BlocBuilder` selectors

### Arabic / RTL
- [ ] All Arabic text uses correct Quran/Uthmani font
- [ ] RTL layout tested on all key screens
- [ ] No LTR assumptions in layout logic
- [ ] Diacritics (tashkeel) render correctly

---

## ⚙️ Required Commands

Run in order. Report exact output for each, including failures.

```bash
# 1. Dependency resolution
flutter pub get

# 2. Code formatting check
dart format --set-exit-if-changed .

# 3. Static analysis — capture ALL warnings and errors
flutter analyze

# 4. Unit and widget tests
flutter test

# 5. Test coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html  # if lcov available

# 6. Debug build validation
flutter build apk --debug

# 7. Windows build (if available)
flutter build windows --debug
```

> Report the **exact error message** for every failure. Do not summarize or skip errors.

---

## 📋 Required Audit Output Format

Produce all sections — do not skip any.

### 1. Executive Summary
One paragraph: what the project does, overall health score (1–10), biggest risk, and top 3 priorities.

### 2. Critical Bugs 🔴
Issues that cause crashes, data loss, wrong Quran text, broken memorization scoring, or broken auth.  
Format: `[FILE:LINE] Description — Impact — Root Cause`

### 3. High Priority Issues 🟠
Significant but non-crashing: performance degradations, memory leaks, broken flows, UX blockers.

### 4. Medium Priority Issues 🟡
Code quality, missing error handling, non-critical UX issues, linting violations.

### 5. Low Priority / Improvements 🟢
Refactoring opportunities, naming, comments, code organization.

### 6. UX / UI Problems
RTL issues, Arabic text errors, accessibility gaps, font rendering, layout overflow.

### 7. Architecture Problems
Layer violations, Cubit misuse, navigation issues, dependency injection problems.

### 8. Testing Gaps
Missing tests for critical logic (SM-2, streaks, Quran pagination, offline sync).  
List: which features have zero test coverage.

### 9. Security / Data Risks
Hardcoded secrets, Supabase RLS gaps, unencrypted local storage of sensitive data.

### 10. Performance Issues
Identified rebuild hotspots, startup time problems, large asset loading, Quran data inefficiency.

### 11. Step-by-Step Fix Plan
Ordered list of fixes. Each item must include:
- What to fix
- Which file(s) to change
- Estimated risk (Low / Medium / High)
- Whether user approval is needed before proceeding

### 12. Safe Implementation Order
Group fixes by phase:
- **Phase 1** — Zero-risk fixes (formatting, linting, const constructors)
- **Phase 2** — Low-risk fixes (error handling, missing mounted checks)
- **Phase 3** — Medium-risk fixes (performance, architecture cleanup) — requires approval
- **Phase 4** — High-risk fixes (business logic, Quran data, streaks) — requires approval + tests first

### 13. Files Likely Affected
List every file that will be touched per phase.

### 14. Pre-Production Risks
What could go wrong in production if shipped today. What must be fixed before release.

---

## 🏗️ Architecture Reference

The agent must match this structure exactly. Do not invent new layers.

```
lib/
├── core/
│   ├── constants/         # App-wide constants (Quran pages, surahs, etc.)
│   ├── errors/            # AppException hierarchy (sealed classes)
│   ├── extensions/        # Dart/Flutter extension methods
│   ├── theme/             # ThemeData, colors, text styles
│   ├── utils/             # Pure utility functions
│   └── widgets/           # Shared reusable widgets
│
├── features/
│   └── [feature_name]/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/      # Abstract interfaces only
│       │   └── use_cases/
│       ├── data/
│       │   ├── datasources/       # Supabase, Hive, local JSON
│       │   ├── models/            # DTOs with fromJson/toJson
│       │   └── repositories/     # Implementations
│       └── presentation/
│           ├── cubit/             # XxxCubit + XxxState
│           ├── screens/
│           └── widgets/
│
├── config/
│   ├── router/            # GoRouter definition
│   └── di/                # Dependency injection / service locator
│
└── main.dart
```

---

## 🕋 Islamic / Quran Domain Rules

These are non-negotiable. Any change to these areas requires human approval.

| Area | Rule |
|------|------|
| Quran text | Never modify Uthmani text, ayah count, or surah order |
| Page mapping | Hafs 'an 'Asim, 604-page standard Mushaf layout |
| Tajweed colors | Preserve existing color scheme — users depend on it |
| Ayah numbering | 1-based per surah, never 0-based |
| Bismillah | Handle correctly — it's not ayah 1 in non-Fatiha surahs |
| Hizb / Juz | Boundaries must match standard Mushaf |
| Azkar | Text sourced from authenticated hadith — never paraphrase |
| Duaa text | Preserve exact Arabic wording |
| SM-2 algorithm | Any change must be tested and approved — it affects all memorization data |
| Streaks | UTC-based calculation — local timezone offset bugs are critical |

---

## 📦 Dependency Policy

Before adding any package:
1. Check if the functionality already exists in the project
2. Check pub.dev score, likes, and last publish date
3. Check for conflicts with existing versions in pubspec.yaml
4. Prefer packages already used in the project
5. Get user approval before adding to pubspec.yaml

Before updating any package:
1. Read the changelog for breaking changes
2. Check if it affects Quran rendering, audio, or local storage
3. Run tests after update

---

## 🔒 Data Safety Rules

User data that must never be lost:
- Memorization progress (which ayahs reviewed, when, SM-2 intervals)
- Streak records and statistics
- Last-read position per surah / juz
- Completed Hifz certificates
- Custom bookmarks and notes
- Notification preferences
- User mode (child / audio / youth / advanced)

If any fix could touch persistence layer (Hive, Supabase sync), it requires:
- A data migration plan
- Rollback strategy
- User approval before implementation

---

## 🧪 Testing Standards

For every new fix or feature, the agent must:

1. Write or update unit tests for business logic (SM-2, streak calculation, Quran pagination)
2. Write widget tests for any new/modified screen
3. Confirm existing tests still pass after changes
4. Flag any critical untested logic discovered during audit

Minimum test coverage targets:
- SM-2 / spaced repetition logic: **100%**
- Streak calculation: **100%**
- Repository implementations: **80%+**
- Cubit state transitions: **80%+**

---

## 💬 Communication Rules

- Always explain **why** before **what**
- For high-risk changes: present the plan and wait for approval before coding
- Use Arabic for any user-visible text suggestions
- Flag ambiguity — never silently assume
- If a fix has trade-offs, present them clearly
- Never say "I fixed it" without showing the changed code and test output

---

## Regression Prevention Rules

Before marking any fix complete:
- verify related features still work
- verify no navigation regressions
- verify no state persistence regressions
- verify no RTL/UI regressions
- verify Quran rendering consistency

---

## Current Default Mode

Default mode is AUDIT MODE unless the user explicitly says: "Start fixing".

In Audit Mode:
- Do not modify app code.
- Do not refactor.
- Do not rename files.
- Do not change pubspec.yaml.
- Only create or update files inside docs/.