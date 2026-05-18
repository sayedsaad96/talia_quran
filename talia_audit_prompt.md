# 🔍 Talia Quran — Full Project Audit Prompt

> Paste this prompt directly into Cursor / Windsurf / Claude Code at the root of the project.

---

## ROLE

You are a **senior Flutter engineer performing a full production-readiness audit**.  
Your job is to discover, verify, and report on every feature in this codebase **by reading the code only**.  
Do NOT rely on README.md, comments, or any documentation — treat them as potentially outdated.

---

## PHASE 1 — CODEBASE MAPPING (read before touching anything)

Execute these steps in order:

### 1.1 — Structural scan
```
Read the full directory tree. Identify:
- Top-level folders (lib/, assets/, test/, supabase/, scripts/, etc.)
- Architecture pattern in use (clean arch / feature-first / layered?)
- State management library (check pubspec.yaml + imports in providers/)
- Navigation library (check router file)
- Backend (Supabase / Firebase / REST?)
- Key packages (pubspec.yaml → dependencies block)
```

### 1.2 — Entry point trace
```
Start from lib/main.dart:
- What providers/services are initialized at startup?
- What is the root widget and initial route?
- Is there a splash/onboarding flow?
- How is auth state handled at app launch?
```

### 1.3 — Feature discovery (the real source of truth)
```
For each folder under lib/features/ (or equivalent):
- List every screen file (*.dart with Scaffold or build method)
- List every provider/bloc/cubit/notifier
- List every repository and its methods
- List every model/entity
- Map the data flow: UI → Provider → Repository → Data Source
```

### 1.4 — Shared/core layer
```
Read lib/core/ (or shared/, common/):
- What reusable widgets exist?
- What services are global (connectivity, notifications, storage, analytics)?
- What constants/configs/theme files?
- What utility/extension files?
```

---

## PHASE 2 — FEATURE VERIFICATION CHECKLIST

For **each feature discovered in Phase 1**, answer every question below:

```
FEATURE: [feature name]
─────────────────────────────────────────────
[ ] UI COMPLETENESS
    - Does every screen handle: loading / error / empty / success states?
    - Are there any screens with hardcoded data or TODO placeholders?
    - Is RTL/Arabic text properly supported (TextDirection, alignment)?

[ ] STATE MANAGEMENT CORRECTNESS
    - Is AsyncValue handled exhaustively (AsyncData / AsyncError / AsyncLoading)?
    - Are providers disposed correctly (autoDispose where needed)?
    - Are there any setState() calls that should be Riverpod providers?
    - Is there any shared mutable state that could cause race conditions?

[ ] DATA LAYER
    - Does the repository method actually call the backend (Supabase/Firebase/API)?
    - Are all CRUD operations fully wired end-to-end?
    - Is error handling in place (try/catch at repository boundary)?
    - Are DTOs/models correctly mapping from/to JSON?

[ ] NAVIGATION
    - Are all routes defined in the router?
    - Are deep links / redirect guards implemented?
    - Are there any broken GoRouter routes (missing path params)?

[ ] PERSISTENCE
    - Is local storage (SharedPreferences / Hive / Isar) read AND written?
    - Is there data that should persist but doesn't?

[ ] OFFLINE / CONNECTIVITY
    - Is there connectivity checking before network calls?
    - Is there graceful degradation when offline?

[ ] ASYNC / LIFECYCLE
    - Are Future/Stream subscriptions cancelled in dispose()?
    - Are there any unawaited futures?
    - Any setState() after dispose()?

[ ] SECURITY / AUTH
    - Are protected routes guarded in the router?
    - Are Supabase RLS policies respected (no client-side-only auth checks)?
    - Is the auth token refreshed automatically?

[ ] LOCALIZATION
    - Are all user-facing strings using the localization system?
    - Any hardcoded English/Arabic strings that should be in .arb files?
```

---

## PHASE 3 — CROSS-CUTTING CONCERNS

After verifying individual features, check these globally:

### 3.1 — Dead code & stubs
```
Search for:
- Files that are imported nowhere
- Methods with // TODO, throw UnimplementedError(), or empty bodies
- Providers that are defined but never watched/read
- Screens that are defined but not in the router
```

### 3.2 — Dependency consistency
```
- Does pubspec.yaml version match what's actually used in code?
- Are there packages imported in code but missing from pubspec.yaml?
- Are there packages in pubspec.yaml never imported in code?
- Any version conflicts (flutter pub outdated)?
```

### 3.3 — Performance red flags
```
Search for:
- build() methods doing heavy computation (should be memoized/moved)
- ListView without itemExtent or without itemBuilder (large lists)
- setState() rebuilding large widget trees unnecessarily
- Images without caching (should use cached_network_image)
- Missing const constructors on stateless widgets
```

### 3.4 — Crash risks
```
Search for:
- Null-unsafe patterns (! operator without null check)
- List[index] without bounds checking
- JSON parsing without try/catch
- Navigator.pop() without checking canPop()
- FutureBuilder/StreamBuilder without error snapshot handling
```

---

## PHASE 4 — SUPABASE-SPECIFIC CHECKS

```
[ ] supabase/migrations/ — are all tables in schema reflected in Dart models?
[ ] RLS policies — are they enabled on all tables with user data?
[ ] Realtime — if subscribed, is the channel properly closed on dispose?
[ ] Auth — is session persisted across app restarts?
[ ] Storage — are bucket names and paths consistent between SQL and Dart code?
[ ] Edge functions — are they called with correct headers and error handling?
[ ] Stored procedures (rpc) — do Dart calls match function signatures exactly?
```

---

## PHASE 5 — REPORT FORMAT

After completing all phases, output a structured report:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TALIA QURAN — AUDIT REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🗺 CODEBASE OVERVIEW
- Architecture: [what you found]
- Features discovered: [list]
- State management: [library + version]
- Navigation: [GoRouter / AutoRoute / etc]
- Backend: [Supabase / Firebase / etc]
- Total screens: [count]
- Total providers: [count]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ✅ FULLY WORKING FEATURES
[Feature name] — [brief evidence from code]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ⚠️ PARTIALLY IMPLEMENTED
[Feature name]
  - What works: [...]
  - What's missing: [file/line reference]
  - Fix required: [specific action]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔴 BROKEN / NOT IMPLEMENTED
[Feature name]
  - Problem: [exact issue with file reference]
  - Crash risk: [yes/no]
  - Fix: [what needs to be done]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🧹 CODE QUALITY ISSUES
[Issue] — [file:line] — [severity: low/medium/high]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🚨 CRASH RISKS (fix before release)
[Risk] — [file:line] — [scenario that triggers it]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 📋 PRIORITIZED FIX LIST
P0 (blocker):     [...]
P1 (before ship): [...]
P2 (nice to fix): [...]
P3 (tech debt):   [...]
```

---

## CONSTRAINTS

- **Never guess** — every finding must reference a specific file and line number
- **Never fix anything** during this audit unless explicitly asked
- **Never skip a feature** because it "looks fine" — read the actual implementation
- **Treat TODOs as bugs** — a TODO in production code is a missing feature
- **Read test files** if they exist — they reveal intended behavior vs actual behavior
- Start your response with: `"Audit started. Reading codebase..."` and end with the full report above
