# Talia Companion V1 Phase 0 Repository Audit Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a current, evidence-backed repository integration map for Talia Companion V1 before any feature code is written.

**Architecture:** This plan does not implement Talia Companion. It verifies the current Flutter project structure, identifies authoritative feature owners and exact integration points, and produces the file/symbol map needed to write two safe implementation plans: Talia Companion Core and Kids Voice Pilot. The approved design remains authoritative for product behavior; the repository audit is authoritative for code paths and reusable systems.

**Tech Stack:** Flutter, Dart, flutter_bloc/Cubit or the current state-management stack discovered in the repository, GoRouter or the current router, Supabase and existing persistence/analytics/notification infrastructure as actually present in the current codebase.

**Spec:** `docs/superpowers/specs/2026-09-19-talia-companion-v1-design.md`

## Global Constraints

- Do not implement feature code during Phase 0.
- The current repository is the source of truth for file paths, symbols, services, and ownership.
- Previous audits are reference material only; never treat them as authoritative.
- Talia remains a feature, not a generic global core utility.
- Central decision-making; local presentation; no global floating overlay.
- Quran focus always wins and Talia must not render in focused Quran Reader / Mushaf surfaces.
- No single repeated character image; every visible character state defines pose and motion.
- Full Talia Voice Learning is deferred to V2.
- V1 Kids Voice Pilot is closed-intent, Push-to-Talk, Arabic-first, with intents `start`, `next`, `repeat`, `back`, `help`, `finish` only.
- On-device recognition first; online fallback only under approved conditions.
- No runtime TTS.
- No stored child voice, voice history, or full transcripts.
- Consent is per child and versioned.
- No guessing uncertain voice commands.
- Technical failure is never treated as child failure.
- One celebration channel at a time.
- Religious content is finite and governed; no dynamic Quran/hadith/tafsir/fatwa/religious-ruling generation.
- User preference overrides adaptive presence.
- Offstage/background animations stop.
- Talia must not duplicate existing feature business logic.
- If a required provider, key, legal/privacy choice, signing value, or manual release configuration is missing, stop and ask the user rather than inventing it.

---

### Task 1: Establish a Clean Baseline and Repository Identity

**Files:**
- Read: `pubspec.yaml`
- Read: `analysis_options.yaml` if present
- Read: `l10n.yaml` if present
- Read: `README.md` and root architecture docs if present
- Create: `docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md`

**Interfaces:**
- Consumes: approved design spec at `docs/superpowers/specs/2026-09-19-talia-companion-v1-design.md`.
- Produces: audit header containing branch/commit, Flutter/Dart versions, baseline quality status, and package inventory.

- [ ] **Step 1: Confirm the working tree and current revision**

Run:

```bash
git status --short
git branch --show-current
git rev-parse HEAD
git log -5 --oneline
```

Expected: capture the current branch and commit SHA. If the tree has unrelated modifications, record them in the audit and do not overwrite them.

- [ ] **Step 2: Record Flutter/Dart/project versions**

Run:

```bash
flutter --version
dart --version
flutter pub deps --style=compact
```

Expected: commands succeed. Record Flutter/Dart versions plus the current versions of routing, state-management, persistence, analytics, notification, speech-recognition, audio, and Supabase-related packages if present.

- [ ] **Step 3: Verify the approved spec exists in the repository**

Run:

```bash
test -f docs/superpowers/specs/2026-09-19-talia-companion-v1-design.md
sed -n '1,220p' docs/superpowers/specs/2026-09-19-talia-companion-v1-design.md
```

Expected: the spec exists and starts with `# Talia Companion V1 — Design Specification`. If it is missing, stop and add the approved spec to the repository before continuing.

- [ ] **Step 4: Establish static-analysis baseline**

Run:

```bash
flutter analyze
```

Expected: record PASS or the exact pre-existing findings. Do not fix unrelated findings in Phase 0.

- [ ] **Step 5: Establish test baseline**

Run:

```bash
flutter test
```

Expected: record PASS or the exact pre-existing failing test names. Phase 0 must distinguish pre-existing failures from future Talia regressions.

- [ ] **Step 6: Create the audit document header**

Create `docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md` with this exact initial structure:

```markdown
# Talia Companion V1 — Phase 0 Repository Audit

**Audit date:** 2026-09-19
**Spec:** `docs/superpowers/specs/2026-09-19-talia-companion-v1-design.md`
**Branch:** `<captured branch>`
**Commit:** `<captured SHA>`
**Flutter:** `<captured Flutter version>`
**Dart:** `<captured Dart version>`

## Baseline

- `flutter analyze`: PASS / PRE-EXISTING FINDINGS
- `flutter test`: PASS / PRE-EXISTING FAILURES
- Working tree notes: <facts only>

## Package Inventory

| Capability | Current package/system | Version | Notes |
|---|---|---:|---|
| State management | | | |
| Routing | | | |
| Persistence | | | |
| Supabase | | | |
| Audio playback | | | |
| Speech recognition | | | |
| Notifications | | | |
| Analytics / telemetry | | | |
| Remote config / feature flags | | | |
```

Use the actual captured values; do not leave angle-bracket placeholders in the completed audit.

- [ ] **Step 7: Commit only the audit header if the repository workflow permits documentation commits**

```bash
git add docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md
git commit -m "docs: start Talia Companion phase 0 audit"
```

If the project convention does not commit intermediate documentation, record that fact and continue without committing. Do not commit unrelated working-tree changes.

---

### Task 2: Map Current Architecture, Routing, Lifecycle, and Surface Ownership

**Files:**
- Read: all current routing entry points discovered by search
- Read: app/root lifecycle composition files discovered by search
- Read: current Home composition files
- Read: current Kids Journey and stage composition files
- Read: current Quran Reader / Mushaf surfaces
- Modify: `docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md`

**Interfaces:**
- Consumes: current repository layout.
- Produces: exact route/surface map and the symbols that own lifecycle, active-tab/offstage state, Adult Home, Adult inline targets, Kids Journey, and focused Quran reading.

- [ ] **Step 1: Inventory feature and core directories**

Run:

```bash
find lib -maxdepth 3 -type d | sort
```

Expected: identify the current feature-first or alternative project structure. Record whether `lib/features/talia_companion/` already exists and, if so, whether it contains any real implementation.

- [ ] **Step 2: Locate router ownership and navigation-shell behavior**

Run:

```bash
rg -n "GoRouter|StatefulShellRoute|ShellRoute|MaterialApp\.router|RouterConfig|routeInformationParser|Navigator" lib
```

Expected: identify the exact router file(s), shell/navigation structure, and how active versus offstage tabs are represented.

- [ ] **Step 3: Enumerate all focused Quran reading routes and widgets**

Run:

```bash
rg -n "QuranReader|Mushaf|KidsQuranReader|quran/page|quran/surah|reader" lib/features lib/core
```

Expected: produce a definitive list of route patterns and screen/widget symbols where Talia must be `hidden`. Do not infer from old audits.

- [ ] **Step 4: Locate lifecycle ownership**

Run:

```bash
rg -n "WidgetsBindingObserver|AppLifecycleState|didChangeAppLifecycleState|TickerMode|Offstage|IndexedStack" lib
```

Expected: identify exact lifecycle observer(s), offstage/ticker handling, and whether there is already a reusable visibility/lifecycle signal.

- [ ] **Step 5: Locate the active Adult Home composition**

Run:

```bash
rg -n "class .*Home|HomePage|HomeHeader|HomeNight|SmartCoach|Continue Today|continue.*today|welcome|greeting" lib/features/home lib 2>/dev/null
```

Expected: identify the exact current widget that owns the top Home Hero/header, existing greeting text, existing recommendation/coach component, and the safest local presentation slot for Talia.

- [ ] **Step 6: Locate current Kids Journey / stage surfaces**

Run:

```bash
rg -n "Kids.*Journey|Journey.*Kids|kids.*stage|Stage.*Kids|gamified|learning.*journey|KidsJourney" lib/features lib/core
```

Expected: identify exact map, stage-start, instruction, and simple-exercise surfaces; explicitly distinguish them from Quran Reader and recitation-recording surfaces.

- [ ] **Step 7: Add the route/surface map to the audit**

Append a table with the exact current values:

```markdown
## Route and Surface Map

| Surface | Exact route(s) | Owning file | Owning symbol | Talia policy | Notes |
|---|---|---|---|---|---|
| Adult Home Hero | | | | eligible | |
| Adult inline candidate 1 | | | | eligible when useful | |
| Kids Journey Map | | | | guide | |
| Kids Stage Start | | | | guide | |
| Kids simple exercise | | | | companion / voice eligible | |
| Quran Reader | | | | hidden | |
| Kids Quran Reader | | | | hidden | |
```

The completed audit must contain real routes, paths, and symbols. Omit rows that do not exist rather than inventing them.

- [ ] **Step 8: Run format/analyze guard**

No code should have changed. Run:

```bash
git diff --check
flutter analyze
```

Expected: no new code changes and no new analysis findings caused by Phase 0.

---

### Task 3: Map Authoritative Feature State and Candidate Adapters

**Files:**
- Read: current Adult/Kids profile resolver and owner identity code
- Read: Quran audio state owner
- Read: memorization/learning session state owners
- Read: review/due-work owner
- Read: resume/last-location owner
- Read: prayer owner
- Read: Daily Question owner
- Read: Quran Learning Journey owner, if present
- Read: SmartCoach/recommendation owner, if present
- Modify: `docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md`

**Interfaces:**
- Consumes: exact current state owners.
- Produces: adapter candidate map showing what Talia may read and what it must never own or duplicate.

- [ ] **Step 1: Locate Adult/Kids profile source of truth**

Run:

```bash
rg -n "isChild|childProfile|ChildProfile|MemorizationProfile|PathResolver|experience.*kids|kids.*mode|profile.*kids" lib
```

Expected: identify the authoritative runtime Adult/Child determination and profile-switch events. Do not use onboarding-only state as runtime truth unless the current code proves it is authoritative.

- [ ] **Step 2: Locate record/account/profile ownership and persistence scoping**

Run:

```bash
rg -n "RecordOwner|ownerId|currentOwner|profileId|Encrypted.*Preferences|SharedPreferences|secure.*storage|account.*reset|logout" lib
```

Expected: identify how signed-in, guest, adult, and child data are scoped; identify account reset/logout cleanup inventory.

- [ ] **Step 3: Locate Quran audio and local playback sources**

Run:

```bash
rg -n "QuranAudio|AudioPlayer|hasActiveAudio|isPlaying|playback|just_audio|audioplayers" lib
```

Expected: identify the global Quran audio owner plus any local memorization/Kids playback that must suppress automatic Talia output.

- [ ] **Step 4: Locate user recording and recognition/evaluation sources**

Run:

```bash
rg -n "isRecording|recording|reciting|speech.*recogn|SpeechToText|speech_to_text|evaluate|evaluation|verdict|remediation|technical.*error|audioFailed|speechIssue" lib
```

Expected: identify current recording state, technical-error state, and any existing speech-recognition abstraction/package. Record whether it is safe to reuse for the Kids Voice Pilot or requires a new abstraction.

- [ ] **Step 5: Locate review, resume, and recommendation owners**

Run:

```bash
rg -n "review.*due|due.*review|spaced.*review|last.*read|last.*location|restorable|resume|SmartCoach|recommendation|coach" lib
```

Expected: identify existing authoritative sources for due review, Continue Today/resume, and SmartCoach/recommendations. Talia must not duplicate these algorithms.

- [ ] **Step 6: Locate prayer, Daily Question, learning journey, and Share Good state owners**

Run:

```bash
rg -n "prayer|adhan|DailyQuestion|daily_question|question.*daily|LearningJourney|learning_journey|ShareGood|share_good" lib
```

Expected: record only real existing systems. If one is absent, mark it `not present in current repo` rather than proposing a new subsystem under Talia.

- [ ] **Step 7: Build the adapter-source table**

Append:

```markdown
## Authoritative State Owners and Candidate Adapters

| Talia context need | Existing owner | File + symbol | Read mechanism | New adapter needed? | Must not duplicate |
|---|---|---|---|---|---|
| Adult/Child mode | | | | | |
| Current child profile | | | | | |
| Quran audio active | | | | | |
| User recording active | | | | | |
| Memorization/learning state | | | | | |
| Due review | | | | | |
| Resume/continue | | | | | |
| Prayer context | | | | | |
| Daily Question | | | | | |
| Learning Journey | | | | | |
| SmartCoach/recommendation | | | | | |
```

Use exact current names. If a source does not exist, write `absent` and explain the impact.

- [ ] **Step 8: Identify the minimum adapter set**

Add a short section `## Minimum Adapter Set` listing only adapters justified by current code. Each line must include:

```text
Adapter name → exact source owner → exact values exposed to Talia → why it cannot be read more simply
```

Do not create one adapter per feature mechanically.

---

### Task 4: Map Presentation, Assets, Motion, Localization, Accessibility, and Religious Governance

**Files:**
- Read: `pubspec.yaml`
- Read: current Talia/character asset directories
- Read: current design-token/theme files
- Read: current localization config and ARB files
- Read: existing reduced-motion examples
- Read: religious-output governance test(s)
- Modify: `docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md`

**Interfaces:**
- Consumes: approved Character State & Asset Matrix and Motion System from the spec.
- Produces: exact asset pipeline, renderer integration constraints, localization path, and test/governance reuse map.

- [ ] **Step 1: Inventory all current Talia/character assets and references**

Run:

```bash
find assets -type f \( -iname '*talia*' -o -path '*character*' \) | sort
rg -n "Talia|talia_|assets/talia|character/" lib test pubspec.yaml
```

Expected: identify legacy onboarding/social assets separately from the new companion asset pack. Record every current reference that must remain untouched unless the spec explicitly requires integration.

- [ ] **Step 2: Verify current asset registration conventions**

Run:

```bash
sed -n '/flutter:/,/^[^[:space:]]/p' pubspec.yaml
```

Expected: capture how assets are registered today and whether folder-level asset registration is already used.

- [ ] **Step 3: Locate animation and reduced-motion conventions**

Run:

```bash
rg -n "disableAnimations|reduce.*motion|AnimationController|TickerProvider|TickerMode|AnimatedSwitcher|FadeTransition|ScaleTransition|SlideTransition" lib
```

Expected: identify reusable app conventions for reduced motion, one-shot animations, and stopping offstage tickers.

- [ ] **Step 4: Locate design tokens and Kids theme ownership**

Run:

```bash
rg -n "class AppColors|class AppTypography|class AppSpacing|KidsTheme|ThemeExtension|ColorScheme" lib
```

Expected: identify exact tokens the renderer/Home Hero/Compact Assist Strip/Kids Guide should use rather than inventing a parallel style system.

- [ ] **Step 5: Locate localization source files and generation workflow**

Run:

```bash
find lib -type f \( -name '*.arb' -o -name '*l10n*' \) | sort
cat l10n.yaml 2>/dev/null || true
rg -n "gen-l10n|flutter_gen|AppLocalizations" pubspec.yaml lib tool scripts 2>/dev/null
```

Expected: record the authoritative ARB/template file(s), English/Arabic files, and the exact localization generation command used by the project.

- [ ] **Step 6: Locate religious content governance tests**

Run:

```bash
find test -type f | sort | rg "relig|govern|quran|hadith|content"
rg -n "ungoverned|religious|hadith|tafsir|fatwa|Quran" test/core test/features 2>/dev/null
```

Expected: identify exact governance tests that Talia message IDs must extend or satisfy.

- [ ] **Step 7: Add asset/motion/localization governance section**

Append exact facts under:

```markdown
## Character Asset and Motion Integration

### Existing legacy character assets that must remain untouched
- `...`

### Proposed new companion asset root
- Exact path compatible with current `pubspec.yaml`: `...`

### Current reduced-motion convention
- File + symbol: `...`
- API used: `...`

### Design tokens to reuse
- Colors: `...`
- Typography: `...`
- Spacing: `...`
- Kids theme: `...`

## Localization and Religious Governance

- ARB/template source: `...`
- Arabic source: `...`
- English source: `...`
- Generation command: `...`
- Governance test(s): `...`
```

Use real paths and symbols; do not leave ellipses in the completed audit.

---

### Task 5: Map Notifications, Analytics, Feature Flags, Voice Recognition, and Privacy-Critical Infrastructure

**Files:**
- Read: current local/push notification services
- Read: current analytics/telemetry service
- Read: current remote-config/feature-flag infrastructure
- Read: current speech-recognition/audio-recording packages and wrappers
- Read: current permission handling
- Modify: `docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md`

**Interfaces:**
- Consumes: V1 notification, telemetry, consent, and Voice Pilot requirements.
- Produces: verified infrastructure reuse decisions and a list of external/provider decisions that require user approval before implementation.

- [ ] **Step 1: Locate notification ownership**

Run:

```bash
rg -n "flutter_local_notifications|FirebaseMessaging|notification|schedule.*notification|push.*notification|local.*notification" lib pubspec.yaml
```

Expected: identify exact notification service(s), payload route behavior, and where companion-aware copy could be selected without making Talia own notification delivery logic.

- [ ] **Step 2: Locate analytics/telemetry ownership**

Run:

```bash
rg -n "analytics|telemetry|logEvent|trackEvent|FirebaseAnalytics|PostHog|Sentry|Amplitude|Mixpanel" lib pubspec.yaml
```

Expected: identify exact analytics abstraction, if any. Record whether it supports event-name + safe-property logging without raw audio/transcript capture.

- [ ] **Step 3: Locate feature flags / remote configuration**

Run:

```bash
rg -n "FeatureFlag|feature.*flag|RemoteConfig|remote.*config|rollout|enabled.*feature|bool\.fromEnvironment|String\.fromEnvironment" lib pubspec.yaml
```

Expected: identify current flag convention and whether independent Talia Companion and Kids Voice Pilot kill switches can reuse it.

- [ ] **Step 4: Locate microphone permission handling and speech-recognition infrastructure**

Run:

```bash
rg -n "Permission\.microphone|microphone.*permission|permission_handler|SpeechToText|speech_to_text|Recognizer|speech.*recogn|record\(" lib pubspec.yaml
```

Expected: identify existing permission UX and recognition providers/packages. Do not select a new online provider during Phase 0.

- [ ] **Step 5: Verify whether an online speech-recognition provider is already integrated**

Run:

```bash
rg -n "Google.*Speech|Azure.*Speech|Deepgram|AssemblyAI|Whisper|speech.*api|recognition.*api" lib supabase functions tool pubspec.yaml 2>/dev/null
```

Expected: record `existing provider: <name>` or `no provider found`.

If no provider exists, add this as an explicit implementation blocker requiring user/provider selection and privacy verification before online fallback can ship. Do not invent provider retention claims.

- [ ] **Step 6: Map consent persistence and child-profile isolation support**

Run:

```bash
rg -n "consent|privacy|parent|guardian|child.*settings|profile.*settings|acceptedAt|version.*consent" lib
```

Expected: identify reusable per-child settings storage or confirm that Talia Voice consent requires a new repository under the Talia feature.

- [ ] **Step 7: Append infrastructure table**

```markdown
## Notifications, Analytics, Flags, Voice, and Consent Infrastructure

| Concern | Existing system | File + symbol | Reuse decision | User/provider decision required? |
|---|---|---|---|---|
| Notifications | | | | |
| Analytics | | | | |
| Companion flag | | | | |
| Voice Pilot flag | | | | |
| Microphone permission | | | | |
| On-device recognition | | | | |
| Online recognition fallback | | | | |
| Per-child consent storage | | | | |
| Prerecorded Talia audio playback | | | | |
```

Completed rows must contain actual facts from the current repository.

---

### Task 6: Produce the Exact Implementation Map and Split the Work into Two Executable Plans

**Files:**
- Modify: `docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md`
- Do not create implementation source files yet

**Interfaces:**
- Consumes: all findings from Tasks 1–5.
- Produces: exact file/symbol map that the next planning step will use to create:
  - `docs/superpowers/plans/2026-09-19-talia-companion-v1-core.md`
  - `docs/superpowers/plans/2026-09-19-talia-kids-voice-pilot-v1.md`

- [ ] **Step 1: Create the Core Companion integration map**

Append:

```markdown
## Plan A — Talia Companion Core Integration Map

| Responsibility | Create/Modify | Exact path | Exact symbol(s) | Existing dependency reused | Test target |
|---|---|---|---|---|---|
| Semantic models | | | | | |
| Context snapshot | | | | | |
| Coordinator | | | | | |
| Suppression policy | | | | | |
| Priority policy | | | | | |
| Adaptive presence | | | | | |
| Persistence | | | | | |
| Character renderer | | | | | |
| PNG sequence renderer | | | | | |
| Adult Home Hero | | | | | |
| Adult Compact Assist Strip | | | | | |
| Kids Journey Guide | | | | | |
| Message catalog | | | | | |
| Celebration coordination | | | | | |
| Talia-aware notification copy | | | | | |
| Feature flag | | | | | |
| Religious-content governance | | | | | |
| Performance/runtime verification | | | | | |
```

Every row must have an exact path/symbol or be removed with a written reason. No speculative path names are allowed in the completed audit.

- [ ] **Step 2: Create the Kids Voice Pilot integration map**

Append:

```markdown
## Plan B — Kids Voice Pilot Integration Map

| Responsibility | Create/Modify | Exact path | Exact symbol(s) | Existing dependency reused | Test target |
|---|---|---|---|---|---|
| Per-child consent model | | | | | |
| Consent repository | | | | | |
| Push-to-Talk controller | | | | | |
| On-device recognizer adapter | | | | | |
| Online fallback adapter | | | | | |
| Closed Arabic intent classifier | | | | | |
| Request-context / stale-result guard | | | | | |
| Prerecorded response catalog | | | | | |
| Voice/audio arbitration | | | | | |
| Retry / visual fallback UI | | | | | |
| Safe telemetry | | | | | |
| Voice Pilot feature flag | | | | | |
| Permission flow | | | | | |
| Offline behavior | | | | | |
| Runtime voice QA | | | | | |
```

If online recognition has no approved provider, mark only that row `BLOCKED — provider/user privacy decision required`; all other rows must still be exact.

- [ ] **Step 3: Document targeted repository improvements only**

Add a section `## Required Targeted Refactors` only when a current file that Talia must modify is too entangled to integrate safely. For each refactor include:

```text
current file → problem observed → smallest extraction needed → why Talia requires it
```

Do not add unrelated cleanup.

- [ ] **Step 4: Document manual decisions/blockers**

Add `## Decisions Required Before Implementation` containing only decisions that cannot be derived from the repository, such as an online recognition provider or missing approved voice clips.

Do not add speculative questions that the code already answers.

- [ ] **Step 5: Verify the audit has no placeholders**

Run:

```bash
rg -n "TBD|TODO|<captured|<name>|<facts|\.\.\." docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md
```

Expected: no placeholder matches. If a literal `...` is part of quoted code or an existing symbol, inspect it manually; otherwise replace it with actual content.

- [ ] **Step 6: Verify every non-negotiable is mapped to an implementation owner or test**

Check the audit against Sections 27, 29, and 31 of the approved spec. Confirm there is a row/test owner for:

```text
Quran suppression
one-message/one-CTA Home Hero
Compact Assist Strip
Kids Journey Guide
multi-pose character system
micro-motion + PNG sequences
reduced motion
offstage/background stop
adaptive presence + manual override
finite governed messages
one celebration channel
selective notifications
independent kill switches
per-child consent
closed voice intents
no guessing
technical failure neutrality
stale voice-result cancellation
no stored voice/transcript
safe telemetry
runtime performance measurement
```

Expected: every item is covered by an exact current source/test integration point or a clearly documented new file to be created in the next implementation plan.

- [ ] **Step 7: Run final baseline verification**

```bash
git diff --check
flutter analyze
flutter test
```

Expected: same or better result than the Task 1 baseline. Phase 0 should not introduce production-code regressions because it should not modify feature code.

- [ ] **Step 8: Commit the completed audit**

```bash
git add docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md
git commit -m "docs: complete Talia Companion phase 0 audit"
```

Do not include unrelated files in the commit.

---

## Phase 0 Completion Gate

Phase 0 is complete only when all of the following are true:

- The audit records the exact current branch and commit.
- Static-analysis and test baselines are recorded.
- Exact current router and Quran-focus surfaces are identified.
- Exact Home Hero, Adult inline, Kids Journey, and supported Kids learning surfaces are identified.
- Authoritative state owners for audio, recording, profiles, review, resume, prayer, Daily Question, learning/recommendation context are documented where they exist.
- Existing notification, analytics, feature-flag, permission, recognition, and consent infrastructure is documented.
- Legacy Talia assets and current asset conventions are documented.
- Localization and religious-governance integration points are exact.
- Core Companion and Kids Voice Pilot integration-map tables contain exact paths and symbols.
- Any provider/privacy blocker is explicit and not guessed.
- No Talia production feature code has been written.
- The completed audit contains no `TBD`, `TODO`, or unresolved placeholders.

## Required Next Planning Step

After this audit is completed, do **not** jump directly into implementation. Use `superpowers:writing-plans` again against the completed audit and approved design spec to generate two file-by-file TDD plans:

1. `docs/superpowers/plans/2026-09-19-talia-companion-v1-core.md`
2. `docs/superpowers/plans/2026-09-19-talia-kids-voice-pilot-v1.md`

The Core plan must produce a complete visual/context-aware companion with the Voice Pilot disabled. The Voice Pilot plan must layer onto that working Core feature and remain independently kill-switchable.
