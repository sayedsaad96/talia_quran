# 🔍 Talia Quran App — Full Production Readiness Code Review Prompt

> **استخدم هذا الـ prompt في Cursor / Windsurf / Claude Projects / أي AI IDE**  
> **الهدف:** مراجعة شاملة للكود من A إلى Z وتجهيز التطبيق للـ production

---

## 📌 CONTEXT — اقرأ الكود الأول قبل أي حاجة

```
You are a senior Flutter engineer with 5+ years of production experience specializing in:
- Clean Architecture with Riverpod 2.x
- Quran / Islamic apps with RTL Arabic support
- Production-grade mobile applications

Your task is a COMPLETE end-to-end code review of the Talia Quran app.

⚠️ CRITICAL PRIORITY RULE:
Prioritize REAL production risks over style nitpicks.
Do NOT overwhelm the report with low-value cosmetic suggestions.
Focus your energy on:
  - Crashes and runtime exceptions
  - Memory leaks and resource management
  - Architecture violations
  - Data corruption risks (especially Quran data integrity)
  - Performance bottlenecks
  - Security vulnerabilities
  - Scalability issues

**MANDATORY FIRST STEP:**
Before writing a single line of analysis, you MUST:
1. Read and index the ENTIRE codebase file by file
2. Map every file → its purpose, dependencies, and layer (data / domain / presentation)
3. Build a mental dependency graph of all providers, repositories, and services
4. Index all architectural and functional relationships relevant to production quality

DO NOT skip any file. DO NOT assume. DO NOT hallucinate APIs.
Do NOT apply any code modifications unless explicitly requested by the user.
```

---

## 🗂️ PHASE 1 — Codebase Mapping (افهم المشروع الأول)

```
Produce a structured map of the entire project:

### Project Structure Report
For EVERY file, output:
| File Path | Layer | Responsibility | LOC | Key Dependencies |
|-----------|-------|----------------|-----|-----------------|

### Architecture Overview
- State management: (which Riverpod patterns used, consistent or mixed?)
- Navigation: (GoRouter setup, routes defined, guards in place?)
- Data layer: (repositories, data sources, models)
- Domain layer: (use cases, entities, interfaces — present or missing?)
- Feature organization: (feature-first or layer-first or mixed?)

### Dependency Graph
List every provider and what it depends on. Flag:
- Circular dependencies
- Providers doing too much (God providers)
- Missing autoDispose on providers that should have it
- ref.read() used inside build() (anti-pattern)
```

---

## 🛠️ PHASE 2 — Static Analysis & Linting (الأدوات الرسمية)

```
Run (or simulate running) the following Dart/Flutter official tools and analyze their output:

### Tools to Execute
- flutter analyze          → List all warnings and errors
- dart fix --dry-run       → Show all auto-fixable issues
- flutter pub outdated     → Show outdated packages
- dart format --set-exit-if-changed .  → Find formatting inconsistencies

### Output Format per Finding:
**[LINT-###] Severity: ERROR | WARNING | INFO**
- File: `path/to/file.dart` — Line: XX
- Rule violated: (analyzer rule name)
- Issue: (description)
- Auto-fixable: YES | NO

### What to Flag:
- All analyzer errors (must fix before release)
- Deprecated API usage (will break in future Flutter versions)
- Packages with major version upgrades available
- Unsafe package versions with known security issues
- Formatting inconsistencies (tabs vs spaces, trailing commas)
- Dead imports that inflate compile time
```

---

## 🐛 PHASE 3 — Bug & Error Detection (الأخطاء والمشاكل)

```
Scan every file for the following categories of bugs. For each issue found, output:

**[BUG-###] Severity: CRITICAL | HIGH | MEDIUM | LOW**
- File: `path/to/file.dart` — Line: XX
- Issue: (clear description)
- Impact: (what breaks at runtime?)
- Fix: (exact code change needed)

### 3.1 — Null Safety Violations
- Unsafe `!` operators that can throw at runtime
- Missing null checks before accessing nullable fields
- Late variables that may not be initialized

### 3.2 — Async / Await Errors
- Missing await on async calls
- Unawaited futures (fire-and-forget that should be awaited)
- async methods that don't handle errors
- setState() or ref.read() called after widget disposed

### 3.3 — State Management Bugs
- Providers not invalidated when data changes
- State shared across screens that should be isolated (missing .family or scoping)
- Missing autoDispose causing memory leaks
- ref.watch() inside callbacks / listeners (should be ref.read())
- Providers reading other providers in their build() creating unnecessary rebuilds

### 3.4 — Navigation Bugs
- GoRouter routes missing required params
- Pop without checking if navigator can pop
- Navigation after widget is disposed
- Missing redirect guards for authenticated routes

### 3.5 — Data & Logic Bugs
- Supabase queries without error handling
- Missing RLS enforcement assumptions in client code
- Pagination state not reset when filters change
- Quran data (ayahs, surahs, pages) — any off-by-one errors in indices
- Streak / progress tracking — UTC vs local time bugs
- SM-2 spaced repetition algorithm — correct implementation?

### 3.6 — Memory & Performance Leaks
- StreamSubscription not cancelled in dispose()
- AnimationController not disposed
- ScrollController / TextEditingController not disposed
- Timer not cancelled on widget unmount
- Heavy operations running on the main thread (should use compute())
```

---

## 🔁 PHASE 4 — Code Duplication & Redundancy (الكود المكرر)

```
Find all duplicated or redundant code:

### 4.1 — Duplicated Logic
For each duplication found:
**[DUP-###]**
- Files involved: (list all files with the duplicated code)
- Duplicated code snippet: (show the repeated pattern)
- Proposed solution: (extract to utility / mixin / extension / base class)

Look for:
- Copy-pasted error handling blocks
- Same Supabase query patterns repeated across repositories
- Repeated padding / spacing values (should be in AppDimensions or theme)
- Same loading / error widgets rebuilt in multiple screens
- Text styles defined inline instead of using the theme
- Navigation calls duplicated instead of using a NavigationService
- Same validation logic copy-pasted across forms

### 4.2 — Dead Code
- Unused imports (dart analyze will catch these but list them)
- Unused variables / parameters
- Commented-out code blocks that should be deleted
- Unused assets in pubspec.yaml
- Feature flags or debug code left in production paths
- Unreachable code after return statements

### 4.3 — Over-Engineering / Under-Engineering
- Classes created for single-use (can be a function or extension)
- Abstractions with only one implementation (is the interface needed?)
- Logic that belongs in the domain layer put directly in widgets
- Business logic inside GoRouter redirect callbacks
```

---

## 🎨 PHASE 5 — UI/UX Code Quality (الـ UI والـ UX)

```
Review every screen and widget for these issues:

### 5.1 — Widget Tree Problems
For each screen, check:
- Is the widget tree deeper than 7-8 levels? → extract sub-widgets
- Are there inline anonymous builders that should be extracted?
- Nested Columns/Rows that could be Flex children?
- Missing Expanded / Flexible causing overflow?
- Missing SingleChildScrollView on scrollable forms?

### 5.2 — Hardcoded Values
Flag every instance of:
- Hardcoded colors (Color(0xFF...) instead of Theme.of(context).colorScheme.X)
- Hardcoded text styles (TextStyle(...) instead of Theme.of(context).textTheme.X)
- Hardcoded padding numbers not from AppDimensions
- Hardcoded strings that should be in localization (l10n)
- Hardcoded Arabic strings mixed with English in the same file

### 5.3 — RTL / Arabic Support
- Are all Arabic strings properly right-aligned?
- Are Directionality widgets used where needed?
- Are EdgeInsets replaced with EdgeInsetsDirectional for RTL-aware spacing?
- Do icons flip correctly in RTL? (use Directionality.of(context))
- Does text overflow handle Arabic diacritics (tashkeel) correctly?
- Font (likely Uthmanic/Amiri) — is it applied consistently on all Quran text?

### 5.4 — Accessibility
- Are all interactive elements wrapped in Semantics or have tooltip?
- Are minimum touch targets 48x48dp?
- Do images have semanticLabel?
- Are loading states announced to screen readers?

### 5.5 — Performance Anti-Patterns
- build() methods with heavy computation (should be memoized)
- Missing const constructors on stateless widgets
- ListView without itemExtent when all items are same height
- Images without cacheWidth / cacheHeight
- Network images without caching (should use cached_network_image)
- Rebuilding entire screens when only a small part changed
  → Flag every case where .select() should be used on a Riverpod provider

### 5.6 — Large Files → Reusable Widget Extraction
For any Dart file with > 350 lines, evaluate extraction opportunities:
**[REFACTOR-###] File: path/to/screen.dart (XXX lines)**
Propose splitting into:
- `_SectionNameWidget` for each logical UI section
- Separate files if widget is reusable across screens
Show the exact extraction plan:
  - Widget name
  - Props it needs
  - File it should live in
```

---

## 📖 PHASE 6 — Quran Data Integrity (سلامة البيانات القرآنية)

```
THIS IS MANDATORY — Any error in Quran data is unacceptable for release.

### 6.1 — Ayah & Surah Data Correctness
Verify:
- Total ayah count = 6236 (exact)
- Total surah count = 114
- Each surah's ayah count matches the official Uthmani mushaf
- No off-by-one errors in surah/ayah index mapping
- Surah 1 (Al-Fatiha) = 7 ayahs, Surah 2 (Al-Baqarah) = 286 ayahs (spot-check several)

### 6.2 — Special Cases Handling
Check that the code correctly handles:
- Bismillah: appears as Ayah 1 in Al-Fatiha but NOT as a separate ayah in other surahs
  (Surah 9 Al-Tawbah has NO Bismillah — is this handled?)
- Sajda ayahs: all 15 sajda positions mapped correctly?
- Surah Al-Anfal & At-Tawbah: treated as one unit in some counts?

### 6.3 — Juz, Hizb, Page Mappings
- Are juz boundaries (30 juz) correct?
- Hizb / Rub al-Hizb boundaries correct?
- Mushaf page numbers (604 pages) — are page-to-ayah mappings correct?

### 6.4 — Text Integrity
- Any truncated ayahs in the data source?
- Any duplicated ayahs?
- Unicode normalization — is Arabic text normalized (NFC/NFD) consistently?
- Tashkeel (diacritics) — complete and rendering correctly?
- Hamza forms consistent (ء أ إ ئ ؤ)?
- No missing Quranic symbols (ۚ ۖ ۗ ۘ ۙ ۛ)?

### 6.5 — Data Source Validation
- Where does the Quran text come from? (local DB / API / bundled JSON?)
- Is there a checksum or version hash to verify data integrity?
- Is the data source the same as a known trusted source (Tanzil, Quran.com API)?

Output: **[QURAN-###] Severity: CRITICAL | HIGH**
```

---

## 🎵 PHASE 7 — Audio System Audit (نظام الصوت)

```
For just_audio and related audio infrastructure:

### 7.1 — Memory & Resource Management
- Is AudioPlayer disposed in every widget that creates one?
- Are there multiple AudioPlayer instances created without cleanup?
- Is there a singleton AudioService or is audio created per-screen?
- Does audio continue playing after screen pop? (expected behavior vs bug?)

### 7.2 — Streaming & Caching
- Is audio streamed or downloaded?
- Is there a caching layer? (just_audio_cache or manual caching?)
- What happens if CDN URL changes? (hardcoded URLs vs configurable?)
- Is there buffering state shown to the user during loading?

### 7.3 — Platform Behavior
- iOS: Audio session configured correctly? (AVAudioSession category set?)
- Android: AudioFocus requested and released properly?
- Background playback: declared in AndroidManifest.xml and Info.plist?
- Lock screen controls: MediaNotification / NowPlayingInfo configured?
- Headphone disconnect: does audio pause automatically?
- Interruptions (calls, notifications): does audio pause and resume?

### 7.4 — Error Handling
- What happens if audio URL is unreachable?
- Is there retry logic for failed audio loads?
- Does the player recover from errors without app restart?

Output: **[AUDIO-###] Severity: CRITICAL | HIGH | MEDIUM**
```

---

## 🏗️ PHASE 8 — Architecture & Clean Code (البنية والمعايير)

```
### 8.1 — Layer Violations (Clean Architecture)
Flag any case where:
- UI (widgets) directly calls Supabase / Firebase SDK (should go through repository)
- Repository directly uses BuildContext
- Domain models contain Flutter-specific imports (should be pure Dart)
- Providers contain UI logic (navigation, showing dialogs)
- Data models used directly in UI instead of mapping to domain entities

### 8.2 — Error Handling Architecture
- Is there a unified AppException hierarchy?
- Are all repository methods catching exceptions and wrapping them?
- Does the UI always handle AsyncError state?
- Are error messages user-friendly and localized (not raw exception messages)?
- Is there a global error handler / observer for uncaught errors?

### 8.3 — Naming Conventions
Flag inconsistencies:
- Files: snake_case ✅ | camelCase ❌ | PascalCase ❌
- Classes: PascalCase ✅
- Variables/methods: camelCase ✅
- Constants: kConstantName or SCREAMING_SNAKE ✅
- Private members: _prefixed ✅
- Providers: descriptive names ending in Provider ✅
- Check: are repository, notifier, controller naming consistent?

### 8.4 — Code Organization Within Files
Each Dart file should follow this order:
1. Imports (dart: → package: → relative:)
2. Part directives
3. Constants / typedefs
4. Abstract classes / interfaces
5. Main class
6. Private helper classes
7. Extensions

Flag any file that violates this order.

### 8.5 — Missing Documentation
Flag:
- Public API methods without /// doc comments
- Complex business logic (SM-2 algorithm, streak calculation) without explanation
- Non-obvious Supabase RPC calls without comments explaining what they do
```

---

## ✅ PHASE 9 — Testing Readiness (جاهزية للـ testing)

```
### 9.1 — Testability Assessment
For each repository and notifier:
- Is it constructor-injectable (can dependencies be mocked)?
- Does it have a fake/mock implementation path?
- Is any singleton used that breaks test isolation?

### 9.2 — Missing Tests Inventory
List every critical path that needs a test:
**[TEST-###] Priority: HIGH | MEDIUM**
- Component: (class/function name)
- Test type: unit | widget | integration
- What to test: (specific behavior)
- Why critical: (what user-facing feature breaks without it)

Focus on:
- SM-2 spaced repetition calculation
- Streak logic (UTC edge cases)
- Quran navigation (surah → page → ayah mapping)
- Auth flow (login → session persistence → logout)
- Offline mode (cached data displayed when no internet)
- Progress persistence (memorization progress saved correctly)

### 9.3 — Test Infrastructure
- Is there a test/ directory structure?
- Are there test helpers / fakes / mocks?
- Is there a test pubspec with test-only dependencies?
```

---

## 🚀 PHASE 10 — Production Readiness Checklist

```
Go through each item and mark: ✅ DONE | ⚠️ PARTIAL | ❌ MISSING | 🔍 NEEDS REVIEW

### Security (Mobile Security Audit)
[ ] API keys / secrets NOT hardcoded in Dart files (check for exposed keys in git history too)
[ ] Supabase anon key used correctly (not service role key on client)
[ ] RLS policies enforced — client never bypasses them
[ ] User input sanitized before Supabase queries
[ ] No sensitive data logged in production (check logger setup)
[ ] Local storage encryption — is sensitive user data (tokens, progress) encrypted at rest?
[ ] Token persistence — are refresh tokens stored in secure storage (flutter_secure_storage)?
[ ] Screenshot protection on sensitive screens (e.g., subscription screens)?
[ ] No hardcoded credentials in test files either
[ ] SSL pinning — required? (Supabase uses HTTPS, but is certificate validation enforced?)
[ ] Debug mode protections — are debug flags, logs, and dev endpoints stripped in release build?
[ ] Clipboard leaks — are sensitive values (passwords, tokens) being copied to clipboard?

### Dependency Health Check
For every package in pubspec.yaml:
[ ] Is it actively maintained? (last commit < 12 months ago)
[ ] Compatible with latest Flutter stable?
[ ] Any better alternative available in 2026?
[ ] Any package causing significant app size bloat?
[ ] Any known memory leaks or performance issues in this package version?
[ ] Any packages with duplicate functionality (two packages doing the same thing)?

Output: **[DEP-###]** for each package issue found.

### Build Size Audit (APK/AAB)
Analyze and flag:
[ ] Largest asset folders (fonts, images, audio, JSON data)
[ ] Unused fonts declared in pubspec.yaml but not used in code
[ ] Duplicate assets (same image in multiple resolutions or formats)
[ ] Oversized images that could be compressed without quality loss
[ ] Uncompressed audio files (WAV instead of MP3/AAC?)
[ ] Tree-shaking opportunities (unused code included in build?)
[ ] Should ABI splits be used? (separate APK per architecture)
[ ] Font subsetting — are full Arabic font files included when only Quran Unicode range is needed?
[ ] Deferred loading opportunities for non-critical features

Suggest estimated size savings for each finding.
Output: **[SIZE-###]** for each finding.

### Performance
[ ] Quran data loaded lazily (not all 6236 ayahs at once)
[ ] Images optimized and cached
[ ] Initial load time < 2 seconds on mid-range device
[ ] No jank during Quran page scroll (check frame rate)
[ ] Audio streaming without memory leak (just_audio dispose)

### Offline Support
[ ] Quran text available offline
[ ] User progress readable offline
[ ] Clear UX when offline (not a blank screen)
[ ] Sync when back online

### Crash Prevention & Observability
[ ] All async operations have try/catch
[ ] No uncaught exceptions in release mode
[ ] Firebase Crashlytics or Sentry integrated and configured
[ ] Structured logging with log levels (no raw print() in production)
[ ] Logs filtered in release mode (no debug logs shipped)
[ ] Analytics events consistent and meaningful
[ ] Performance monitoring enabled
[ ] App doesn't crash on permission denial

### CI/CD & Release Pipeline
[ ] Is there a GitHub Actions or Codemagic workflow?
[ ] Automated flutter analyze runs on every PR
[ ] Automated tests run before merge
[ ] Environment separation: dev / staging / production?
[ ] Secrets managed via environment variables (not committed to git)
[ ] Build versioning automated (not manual)?
[ ] Release builds signed with production keystore?

### App Store Requirements
[ ] App icon in all required sizes
[ ] Splash screen properly configured
[ ] Privacy policy URL set
[ ] App permissions explained (microphone? notifications?)
[ ] Deep links / universal links configured
[ ] Background audio mode declared (iOS: info.plist, Android: manifest)

### Localization
[ ] All user-facing strings in .arb files (not hardcoded)
[ ] Arabic (ar) and English (en) both complete
[ ] No missing translation keys
[ ] RTL layout tested on a real device or RTL emulator
```

---

## 📋 PHASE 11 — Final Output Format (الـ Output المطلوب)

```
After completing all phases, produce the following:

### EXECUTIVE SUMMARY
- Total issues found: (broken down by severity)
- Estimated effort to fix: (hours / days)
- Biggest risks for production: (top 3)
- Overall production readiness score: X/10

### PRIORITIZED ACTION PLAN
Group all findings into sprints:

**🔴 SPRINT 0 — BLOCKERS (Fix before ANY production build)**
(CRITICAL bugs that will crash the app or expose user data)
- [ ] BUG-001: ...
- [ ] BUG-002: ...

**🟠 SPRINT 1 — HIGH PRIORITY (Fix before soft launch)**
(Performance issues, major UX problems, data corruption risks)
- [ ] BUG-XXX: ...
- [ ] REFACTOR-XXX: ...

**🟡 SPRINT 2 — MEDIUM (Fix before wide release)**
(Code quality, duplication, missing tests)
- [ ] DUP-XXX: ...
- [ ] TEST-XXX: ...

**🟢 SPRINT 3 — LOW (Nice to have / tech debt)**
(Minor cleanup, naming, documentation)

### FILE-BY-FILE REFACTOR PLAN
For each file that needs splitting (> 350 lines):
Show the exact new file structure with widget names and responsibilities.

### QUICK WINS (< 30 minutes each)
List all fixes that are < 5 lines of code, sorted by impact.
```

---

## ⚙️ EXECUTION RULES — Rules the AI Must Follow

```
CRITICAL CONSTRAINTS:
1. READ EVERYTHING FIRST — Do not output analysis before indexing all files
2. NO HALLUCINATION — Only report issues you actually found in the code
3. SHOW EVIDENCE — Every issue must include the file path and line number
4. NO BREAKING CHANGES — All proposed fixes must be backward-compatible
5. MATCH EXISTING PATTERNS — When proposing refactors, match the existing code style
6. NEVER REMOVE FEATURES — Refactoring must not change behavior
7. ARABIC FIRST — This is an Arabic Quran app; RTL is not optional
8. SIZE THRESHOLD — Files above 350 lines should be evaluated for extraction opportunities
9. NO AUTO-MODIFY — Do not apply any code changes unless explicitly requested by the user
10. PRODUCTION STANDARD — Every suggestion must meet Play Store / App Store standards
11. REAL RISKS FIRST — Prioritize crashes, leaks, and data corruption over cosmetic issues
12. QURAN ACCURACY — Any issue with Quran data is automatically CRITICAL severity
```

---

## 🎯 HOW TO USE THIS PROMPT

### In Cursor / Windsurf:
1. Open the project folder
2. Start a new AI chat
3. Paste this entire prompt
4. Add: `"The GitHub repo is: https://github.com/sayedsaad96/talia_quran — please clone and analyze"`
5. Wait for Phase 1 (mapping) to complete before asking for Phase 2

### In Claude Projects:
1. Create a new Project
2. Upload all Dart files as project knowledge
3. Paste this prompt as the first message
4. The AI will have full context of all files

### Recommended Order:
```
Step 1:  Run Phase 1 only → Review the codebase map → Confirm understanding
Step 2:  Run Phase 2 → Fix all static analysis / lint errors
Step 3:  Run Phase 3 → Fix CRITICAL bugs first
Step 4:  Run Phase 4 → Clean up duplication and dead code
Step 5:  Run Phase 5 → Fix UI issues and extract large widgets
Step 6:  Run Phase 6 → 🚨 Quran data integrity (NEVER skip this)
Step 7:  Run Phase 7 → Audio system audit
Step 8:  Run Phase 8 → Architecture and clean code
Step 9:  Run Phase 9 → Testing readiness
Step 10: Run Phase 10 → Full production checklist (security, deps, build size, CI/CD)
Step 11: Run Phase 11 → Final action plan and sprint breakdown
```

---

## 📎 ADDITIONAL CONTEXT FOR THE AI

```
Tech Stack:
- Flutter (latest stable)
- Riverpod 2.x (code generation)  
- GoRouter
- Supabase (auth + database + storage)
- just_audio (Quran audio streaming)
- RTL Arabic support (primary language)
- SM-2 Spaced Repetition for memorization
- Three user modes: children / audio-only / youth-advanced

Known Pending Tasks (from previous review):
- Streak UTC timezone fix
- ReviewService implementation
- NotificationService with settings toggle
- LastReadPosition tracking

App: تالية (Talia) — Quran reading and memorization
Target Market: Arabic-speaking Muslims, Egypt/MENA
GitHub: https://github.com/sayedsaad96/talia_quran
```
