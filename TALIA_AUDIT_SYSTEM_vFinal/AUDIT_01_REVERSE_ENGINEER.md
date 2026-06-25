# TALIA AUDIT — PROMPT 1 OF 4
# REVERSE ENGINEER THE APPLICATION

---

## YOUR ROLE

You are a Principal Flutter Architect and Reverse Engineer.

Your ONLY job in this prompt is to **understand**, not to evaluate.

Do NOT write any findings yet.

Do NOT flag any issues yet.

Build a complete mental model of Talia from source code only.

---

## CRITICAL RULES

### Sources of Truth (in priority order):

1. `lib/` — all Dart source code
2. `test/` — tests (tells you what was actually tested)
3. `pubspec.yaml` — dependencies, version, assets
4. Active Supabase migration files actually referenced by code
5. Localization files (`l10n/`, `arb/`)

### Forbidden Sources (treat as unreliable):

- README files
- Any `.md` documentation
- Code comments describing future plans
- Audit reports
- Prompt files
- Planning documents

The implementation is the truth. Documentation may lie.

---

## TALIA DOMAIN CONTEXT

Before you read code, know this:

Talia is a **Quran memorization app** for Arabic-speaking users (Egypt/MENA).

**Stack:**
- Flutter + Dart
- State: Cubit (flutter_bloc) — NOT Riverpod
- Navigation: GoRouter
- DI: GetIt
- Backend: Supabase (auth + sync)
- Local storage: Isar (primary) + Hive (legacy)
- Architecture: Clean Architecture, feature-first folders

**Known User Modes (may or may not be implemented):**
- Children mode (Kids)
- Adult mode (Memorization Plus / Hifz)
- Guest mode (no account)

**Known Feature Areas (verify from code, not from this list):**
- Quran reading
- Hifz (active memorization)
- Memorization Plus (adults)
- Spaced repetition review (SM-2 algorithm)
- Smart Coach (recommendations engine)
- V2 Memorization (may be behind feature flags)
- Certificates
- Parent/Guardian dashboard
- Settings Hub
- Onboarding

**V2 Memorization Note:**
There may be a parallel V2 memorization system behind feature flags
(`enable_memorization_v2`, `enable_memorization_v2_kids`).
Do NOT assume it is live. Verify from code.

---

## STEP 1 — SCAN FILE STRUCTURE

Run these commands first. Do not skip.

```bash
# Full dart file list (exclude generated/build)
find lib/ -type f -name "*.dart" \
  | grep -v ".dart_tool" \
  | grep -v "build/" \
  | grep -v ".g.dart" \
  | grep -v ".freezed.dart" \
  | sort

# Count files per feature folder
find lib/features -maxdepth 1 -type d | while read d; do
  count=$(find "$d" -name "*.dart" | grep -v ".g.dart" | wc -l)
  echo "$count  $d"
done | sort -rn

# Find all feature flags / toggles
grep -rn "enable_memorization\|feature_flag\|featureFlag\|FeatureFlag\|kIs" lib/ \
  --include="*.dart" | grep -v ".g.dart"

# Find all route definitions
grep -rn "GoRoute\|path:" lib/ --include="*.dart" | grep -v ".g.dart" | grep -v "//.*path"

# Find all GetIt registrations
grep -rn "registerSingleton\|registerFactory\|registerLazySingleton" lib/ \
  --include="*.dart" | grep -v ".g.dart"

# Find all Cubit definitions
grep -rn "extends Cubit\|extends HydratedCubit" lib/ \
  --include="*.dart" | grep -v ".g.dart"

# Find all Repository definitions
grep -rn "class.*Repository\|abstract.*Repository\|implements.*Repository" lib/ \
  --include="*.dart" | grep -v ".g.dart"

# Find all Isar collections
grep -rn "@collection\|@Collection" lib/ --include="*.dart" | grep -v ".g.dart"

# Check pubspec for key dependencies
cat pubspec.yaml
```

---

## STEP 2 — READ CRITICAL FILES

Read these files fully, in this order:

1. `lib/main.dart` — initialization order, what runs first
2. `lib/app/app.dart` or `lib/core/app/app.dart` — root widget, router setup
3. Router file (wherever GoRouter is defined) — full route tree
4. DI registration file (wherever GetIt registers everything)
5. `lib/core/` folder structure overview
6. One cubit per major feature (not all, just enough to understand pattern)

---

## STEP 3 — BUILD THE MENTAL MODEL

After reading code, produce exactly this output:

---

### OUTPUT FORMAT

#### A) FEATURE MAP

List every feature that exists in code (not in docs):

```
Feature: [name]
Folder: lib/features/[x]/
Cubit(s): [list]
Repository(ies): [list]
Route(s): [list]
Status: [Exists | Partial | Dead Code | Unknown]
```

#### B) NAVIGATION MAP

Draw the full route tree:

```
/ (root)
├── /home → HomeScreen
│   └── Guard: [auth guard name or none]
├── /quran → QuranScreen
├── /memorization → ...
│   ├── /memorization/hifz → ...
│   └── /memorization/plus → ...
├── /kids → ...
├── /auth → ...
│   ├── /auth/login → ...
│   └── /auth/register → ...
└── [all other routes]
```

Include: redirect guards, shell routes, nested routes.

#### C) DEPENDENCY MAP

Show what depends on what:

```
main.dart
  └── initializes: [Supabase, Isar, GetIt, ...]
  
GetIt registrations:
  [FeatureARepository] → depends on [SupabaseClient, IsarDb]
  [FeatureACubit] → depends on [FeatureARepository]
  ...
```

#### D) CUBIT → STATE → USE CASE → REPOSITORY GRAPH

For each major cubit:

```
[CubitName]
  States: [Loading, Loaded, Error, ...]
  Calls: [RepositoryMethod1, RepositoryMethod2]
  Repository: [RepositoryClass]
  Data Sources: [Isar | Supabase | SharedPrefs | ...]
```

#### E) DATA FLOW MAP

For each storage system:

```
Isar collections: [list all @collection classes]
Hive boxes: [list all box names opened in code]
SharedPreferences keys: [list all keys used]
Supabase tables: [list all .from('table') calls]
```

#### F) FEATURE FLAG MAP

```
Flag: [flag name]
Where defined: [file:line]
Where checked: [file:line]
Guards: [what feature it gates]
Currently: [enabled by default | disabled by default | runtime toggle]
```

---

## STOP RULE

If you cannot find a file referenced in code, write:

```
⚠️ UNRESOLVABLE: [file] referenced in [file:line] but not found
```

Do NOT assume its content. Do NOT hallucinate its implementation.

---

## OUTPUT FILE

Save your output as: `TALIA_AUDIT_PHASE1_MAP.md`

Structure:
```
# TALIA AUDIT — PHASE 1 — REVERSE ENGINEERED MAP
Generated: [date]
Codebase scanned: lib/ + test/ + pubspec.yaml

## Feature Map
[...]

## Navigation Map  
[...]

## Dependency Map
[...]

## Cubit Graph
[...]

## Data Flow Map
[...]

## Feature Flag Map
[...]

## UNRESOLVABLE ITEMS
[list or "None found"]
```

---

**When done: hand the output file to PROMPT 2.**
