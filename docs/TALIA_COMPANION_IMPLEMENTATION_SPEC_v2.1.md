# Talia Companion System — Production Implementation Specification v2.1

> **Project:** Talia Quran (Flutter)  
> **Status:** Implementation-ready specification  
> **Audience:** Codex / senior Flutter engineer / reviewer  
> **Primary objective:** Make Talia a calm, context-aware companion and a core part of the Talia Quran identity without distracting from Quran reading, recitation, memorization, or adult-focused sanctuary experiences.  
> **Canonical spec path:** `docs/TALIA_COMPANION_IMPLEMENTATION_SPEC_v2.1.md`

---

## 0. Document Authority & Implementation Contract

This document defines the **product/UX contracts, behavioral rules, safety constraints, performance requirements, and integration boundaries** for Talia Companion v1.

The repository remains the **source of truth for implementation details** such as actual class names, file locations, dependency-injection patterns, router APIs, persistence APIs, theme APIs, and test utilities.

### Mandatory rule

Before changing code, the implementer MUST inspect the current repository and verify every integration point named in this specification.

If the repository differs from this document:

- **Repository structure and current APIs win for implementation details.**
- **This specification wins for product behavior, UX constraints, privacy/account scope, religious-content governance, performance constraints, and focus/suppression rules.**
- Do NOT create a parallel service, event bus, theme layer, lifecycle observer, storage mechanism, localization mechanism, router abstraction, or celebration system when an existing project facility can be reused.
- If a product contract cannot be satisfied cleanly with the current architecture, STOP and report the conflict before implementing a workaround.

### Normative language

- **MUST / MUST NOT** = non-negotiable requirement.
- **SHOULD / SHOULD NOT** = strong default; deviation requires a documented reason.
- **MAY** = optional.

---

# 1. Product Intent

Talia is not a decorative mascot floating over the app. She is the **identity-bearing companion of the Quran journey**.

Her role is to be:

1. **Guide** — helps users understand what to do next.
2. **Companion** — creates continuity across the journey.
3. **Motivator** — encourages without guilt or pressure.
4. **Celebrator** — recognizes meaningful progress modestly.

The governing principle is:

> **Talia is present when useful, quiet when focus matters, and invisible when the Quran itself should be the only focal point.**

### V1 interaction model

Talia v1 is:

- **Reactive:** responds to trusted application/domain events.
- **Context-aware:** route, experience mode, audio, recording, lifecycle, and user preference affect her behavior.
- **Boundedly interactive:** tapping Talia can expose a small set of predefined actions.

Talia v1 is NOT:

- a conversational AI,
- a free-text assistant,
- a tafsir engine,
- a fatwa or religious-advice engine,
- a voice assistant,
- a real-time 3D character.

---

# 2. V1 Scope

## 2.1 In scope

- Static transparent character assets from `assets/talia/`.
- Native Flutter transitions and micro-animations only.
- Centralized Talia state/policy coordination.
- Different behavior for Adult Sanctuary vs Kids Journey.
- Home integration without duplicate greeting UI.
- Memorization integration using the real session state machine.
- Revision/progress integration where existing flows support it.
- Quran reader/focus suppression.
- Quran audio/recording suppression rules.
- Existing celebration-system integration.
- Approved localized message bank.
- User controls: enabled state, encouragement level, hide-for-today, motion behavior.
- Record-owner aware persistence where required.
- Lifecycle-safe timers and state transitions.
- Accessibility, RTL, responsive/adaptive behavior.
- Feature flag / kill switch.
- Unit, widget, integration, and regression tests appropriate to the repository.

## 2.2 Explicitly out of scope

Do NOT add in v1:

- Rive.
- Lottie.
- Realtime 3D runtime.
- Sprite-sheet animation unless separately approved after v1.
- AI chat.
- Free-form Talia Q&A.
- Talia-generated tafsir, fatwa, religious rulings, hadith, Quran quotations, or religious commentary.
- Talia voice synthesis.
- Lip sync.
- Backend or server-side companion state.
- New analytics SDK solely for this feature.
- New state-management framework.
- New routing framework.
- Complex new gamification system.
- Automatic replacement of legacy/share character assets outside the explicitly scoped integrations.

---

# 3. Non-Negotiable UX Rules

1. Talia MUST NEVER cover Quran text, ayah controls, recitation controls, critical forms, or critical navigation.
2. Talia MUST be hidden in the Mushaf/Quran Reader focused reading experience.
3. Automatic speech bubbles MUST be suppressed while Quran audio is actively playing.
4. Automatic speech bubbles MUST be suppressed while the user is actively recording/reciting.
5. Talia MUST NOT re-greet the same record owner more than once per local calendar day.
6. Talia MUST NOT show guilt-based, shame-based, streak-pressure, or spiritually judgmental copy.
7. Talia MUST NOT interpret speech-recognition/STT/audio technical failure as user failure.
8. Talia MUST NOT create a second greeting surface on Home when one already exists.
9. Talia MUST NOT create a second celebration channel when the existing celebration/certificate/dialog system is active.
10. Talia MUST NOT use perpetual distracting animation in v1.
11. Talia MUST respect platform reduced-motion settings and the app's existing animation-disabling behavior.
12. Talia MUST NOT be the only way to access a critical action.
13. Adult Sanctuary and Kids Journey MUST NOT receive the same default companion intensity.
14. All Talia user-facing copy MUST use the existing localization system; no hardcoded Arabic or English in widgets.
15. All religiously sensitive copy MUST come from an approved, finite message-ID set.

---

# 4. Known Repository Integration Points to Verify

The following points were identified during project review. **Do not trust line numbers from old reviews; verify current code before implementation.**

Known/likely integration points include:

- `lib/app.dart`
  - app lifecycle handling
  - existing `disableAnimations`/motion behavior
- `lib/core/di/injection.dart`
  - GetIt / dependency injection
- `lib/core/router/app_router.dart`
  - `StatefulShellRoute.indexedStack`
  - route/focus behavior
- `lib/core/memorization/v2/session_phase.dart`
  - real memorization phases
- `lib/core/widgets/celebration_overlay.dart`
  - existing celebration channel
- `lib/features/home/presentation/pages/home_page_widgets.dart`
  - existing time/name greeting
- `lib/features/memorization_plus/presentation/pages/v2_session_page.dart`
  - existing memorization completion/certificate behavior
- `lib/core/identity/record_owner_provider.dart`
  - record-owner scoping
- `lib/core/widgets/social_share/social_share_model.dart`
  - existing character/share assets that MUST NOT be auto-replaced
- `test/core/content/no_ungoverned_religious_output_test.dart`
  - content governance regression guard
- `pubspec.yaml`
  - confirm `assets/talia/` registration

Also search the repository for current definitions/usages of:

- `ExperienceForkView`
- Adult Sanctuary experience
- Kids Journey / kids mode
- `KidsModeCubit`
- `kids_gamified_stage_page`
- `SmartCoach`
- `ProgressEventsBus`
- `QuranAudioPlayerCubit`
- `quran_mini_player_bar.dart`
- `MemorizationSessionCubit`
- route visibility / shell-navigation helpers
- current theme tokens (`AppColors`, `AppTypography`, `AppSpacing`, `KidsTheme`, or repository equivalents)
- current localization ARB files
- current local persistence abstraction
- current feature-flag mechanism

If a named symbol has been renamed or removed, locate the repository-equivalent rather than introducing a duplicate abstraction.

---

# 5. Experience Contract — Adult Sanctuary vs Kids Journey

This is a major product requirement.

## 5.1 Adult Sanctuary default

Default companion intensity: **Minimal**.

Adult Talia SHOULD feel elegant, quiet, and optional.

Allowed default presence:

- Home: small/medium integrated presence.
- Progress: small contextual presence.
- Smart recommendation/coach area: minimal presence if composition supports it.
- Meaningful completion: modest appearance.
- Settings/help: avatar/minimal presence.

Default suppression:

- Quran Reader/Mushaf: hidden.
- Focus reading: hidden.
- Active Quran audio: no automatic speech bubble; no auto-appearance.
- Active user recording: silent/minimal or hidden according to layout.
- Routine navigation: no proactive popup behavior.

Adult Talia MUST NOT turn the experience into a childlike gamified surface.

## 5.2 Kids Journey default

Default companion intensity: **Companion**.

Kids Talia SHOULD be a visible journey companion where appropriate:

- Journey/stage map.
- Memorization learning.
- Revision.
- Stars/progress moments.
- Achievements.
- Completion moments.
- Onboarding/tutorial guidance.

Even in Kids mode:

- Mushaf/Quran Reader remains hidden.
- Active Quran audio suppresses automatic speech bubbles.
- Active recording suppresses automatic speech bubbles.
- No constant animation loops.
- No guilt, shame, or pressure language.

## 5.3 Default selection

Default behavior SHOULD derive from the user's existing selected experience mode/profile.

Recommended defaults:

| Experience | Enabled | Presence | Encouragement |
|---|---:|---|---|
| Adult Sanctuary | true | minimal | minimal |
| Kids Journey | true | companion | normal |

If the repository has stronger existing defaults or parent controls, integrate with them rather than bypassing them.

---

# 6. Architecture

## 6.1 Architectural objective

Avoid direct ad-hoc calls from many screens such as:

```text
HomePage -> TaliaCubit
MemorizationPage -> TaliaCubit
KidsPage -> TaliaCubit
AudioBar -> TaliaCubit
ProgressPage -> TaliaCubit
```

Instead use a central coordination model:

```text
ProgressEventsBus ──────────────┐
Memorization mapping ───────────┤
Quran audio state ──────────────┤
Recording state ────────────────┤
Kids/adult experience ──────────┤
Route/focus state ──────────────┤
Lifecycle ──────────────────────┤
Explicit user action ───────────┤
                                ↓
                    TaliaCompanionCoordinator
                                ↓
                     TaliaCompanionCubit
                                ↓
                        TaliaViewState
                                ↓
                     TaliaCompanion UI
```

## 6.2 Responsibilities

### `TaliaCompanionCoordinator`

Owns **why and when** Talia changes.

Responsibilities:

- consume normalized Talia signals/events,
- maintain/observe contextual constraints,
- apply priority resolution,
- apply anti-annoyance policy,
- suppress stale/invalid delayed transitions,
- apply record-owner/day/cooldown rules,
- request a view-state transition from the Cubit.

The coordinator MUST NOT own Quran/memorization business logic.

### `TaliaCompanionCubit`

Owns **current presentation state**.

Responsibilities:

- current mood,
- presence level,
- optional approved message ID,
- interaction availability,
- transient-state lifecycle,
- transition token/version where needed.

It SHOULD remain small and testable.

### Feature-specific mappers/adapters

Domain-specific features SHOULD convert their native states to semantic Talia signals rather than exposing internal implementation details to the companion feature.

Example:

```text
MemorizationSessionState
        ↓
TaliaMemorizationMapper
        ↓
TaliaSignal
```

### UI

The UI renders the already-resolved state. It MUST NOT implement business rules such as greeting frequency, audio suppression, account scope, or memorization result classification.

## 6.3 Suggested feature boundary

Adapt to the repository's current conventions:

```text
lib/features/talia_companion/
  application/
    talia_companion_coordinator.dart
    talia_signal.dart
    talia_context_snapshot.dart
  domain/
    models/
      talia_mood.dart
      talia_presence_level.dart
      talia_companion_size.dart
      talia_preferences.dart
      talia_message_id.dart
      talia_interaction_action.dart
    policies/
      talia_priority_policy.dart
      talia_presence_policy.dart
      talia_timing_policy.dart
      talia_message_policy.dart
  data/
    talia_preferences_repository.dart
  presentation/
    cubit/
      talia_companion_cubit.dart
      talia_companion_state.dart
    widgets/
      talia_companion.dart
      talia_character_image.dart
      talia_speech_bubble.dart
      talia_actions_sheet.dart
```

Feature integration mappers MAY live near the feature they adapt if that better respects dependency direction.

---

# 7. Core Models

## 7.1 `TaliaMood`

Use semantic names, not physical direction names.

Recommended:

```dart
enum TaliaMood {
  idle,
  welcome,
  happy,
  listening,
  speaking,
  thinking,
  readingQuran,
  encourage,
  celebrate,
  guide,
}
```

Notes:

- `welcome` maps to the wave asset.
- `guide` maps to the current pointing asset and is mirrored by text direction/placement as needed.
- `readingQuran` MUST NOT imply permission to show Talia inside the Quran Reader. It is for safe contexts such as onboarding, a "continue reading" card, Kids Journey, or approved completion artwork.
- `speaking` means **Talia is explaining/guiding**, not that the user is reciting.

## 7.2 `TaliaPresenceLevel`

```dart
enum TaliaPresenceLevel {
  hidden,
  minimal,
  companion,
  interactive,
}
```

## 7.3 `TaliaMotionPreference`

```dart
enum TaliaMotionPreference {
  full,
  minimal,
  off,
}
```

Platform/app `disableAnimations` or reduced-motion preference MUST override Talia's local preference.

## 7.4 `TaliaInteractionAction`

Recommended bounded actions:

```dart
enum TaliaInteractionAction {
  continueToday,
  explainCurrentScreen,
  hideForToday,
  openSettings,
}
```

Only expose an action when the current context can fulfill it safely.

## 7.5 `TaliaSignal`

Use semantic signals rather than UI-specific commands.

Examples:

```text
appReady
firstHomeVisitToday
explicitHelpRequested
memorizationListening
memorizationReciting
memorizationEvaluating
memorizationCorrect
memorizationRemediation
memorizationCompleted
revisionCompleted
achievementUnlocked
quranFocusEntered
quranFocusExited
quranAudioStarted
quranAudioStopped
recordingStarted
recordingStopped
technicalErrorOccurred
appBecameInactive
appBecameActive
routeChanged
ownerChanged
```

Do not introduce every signal as a public class if the repository has a more idiomatic sealed-event approach. Preserve semantics.

---

# 8. Asset Contract

Expected assets:

```text
assets/talia/
  talia_idle.png
  talia_wave.png
  talia_happy.png
  talia_listening.png
  talia_speaking.png
  talia_thinking.png
  talia_reading_quran.png
  talia_encourage.png
  talia_celebrate.png
  talia_point_right.png
```

## 8.1 Registration

If missing, register:

```yaml
flutter:
  assets:
    - assets/talia/
```

Do not duplicate existing asset entries unnecessarily.

## 8.2 Central registry

There MUST be a single resolver/registry.

Example semantic mapping:

| Mood | Asset |
|---|---|
| `idle` | `talia_idle.png` |
| `welcome` | `talia_wave.png` |
| `happy` | `talia_happy.png` |
| `listening` | `talia_listening.png` |
| `speaking` | `talia_speaking.png` |
| `thinking` | `talia_thinking.png` |
| `readingQuran` | `talia_reading_quran.png` |
| `encourage` | `talia_encourage.png` |
| `celebrate` | `talia_celebrate.png` |
| `guide` | `talia_point_right.png` |

No screen may hardcode Talia asset paths.

## 8.3 Legacy/share asset safety

Do NOT automatically replace character assets already used in:

- social sharing,
- certificates,
- onboarding illustrations,
- existing legacy branded surfaces,

unless that surface is explicitly included in this implementation and regression-tested.

---

# 9. State & Priority Matrix

Talia must resolve competing events centrally.

Priority order from highest to lowest:

```text
1. Quran Reader / Sacred Focus
2. App Backgrounded / Inactive
3. Quran Audio Playing / User Recording
4. Explicit User Interaction / Help
5. Technical Error Guard
6. Completion / Achievement
7. Result Feedback / Remediation
8. Greeting
9. Idle
```

Higher priority ALWAYS suppresses or replaces lower priority behavior.

## 9.1 Priority behavior

### P1 — Quran Reader / Sacred Focus

- Presence: `hidden`.
- Speech bubble: none.
- Auto appearance: none.
- Celebration/greeting/result feedback is suppressed or deferred only if still semantically valid after focus exits.
- Do not queue trivial greetings for later replay.

### P2 — App backgrounded/inactive

- No visible transition.
- Timers canceled/paused according to lifecycle contract.
- No greeting or celebration replay on resume.

### P3 — Quran audio playing / user recording

Quran audio:

- If Talia is already visible on a non-reader screen, she MAY use `listening` silently.
- Do NOT auto-show Talia merely because audio started.
- All automatic speech bubbles are suppressed.

User recording/recitation:

- No automatic speech bubble.
- Prefer hidden/minimal or passive `listening`, depending on layout.
- Never use `speaking` for the user's recitation state.

### P4 — Explicit user interaction/help

A direct tap/request from the user may open the bounded action sheet unless blocked by Quran Reader/critical focus.

Explicit user interaction can bypass proactive-message cooldown but MUST NOT bypass sacred-focus, lifecycle, or active-recording safety rules.

### P5 — Technical error guard

Technical failures do not map to encouragement or failure emotion.

Examples:

- microphone failure,
- permission failure,
- STT service error,
- audio decode/playback error,
- network failure.

Behavior:

- show the repository's normal technical error UI,
- Talia remains silent/idle/hidden according to context,
- do not say "try again" as if the user's memorization was wrong unless the app has actually classified the attempt as remediation.

### P6 — Completion / achievement

- Coordinate with existing celebration system.
- One celebration channel at a time.
- Do not stack Talia celebration + certificate dialog + confetti overlay independently.

### P7 — Result feedback / remediation

- Correct result -> `happy` once.
- Remediation -> `encourage` after the actual result is known.
- Never classify technical failure as remediation.

### P8 — Greeting

- Only if owner is eligible, not hidden-for-today, not already greeted today, and no higher-priority context is active.

### P9 — Idle

- Default safe state.
- No autonomous looping animation required in v1.

---

# 10. Memorization Integration Contract

The implementation MUST inspect and use the real memorization state machine, including `SessionPhase` / `MemorizationSessionState` or their current equivalents.

Do NOT implement the old generic flow `listening -> speaking -> happy` by guessing from UI actions.

## 10.1 Required mapping

Use a small mapper from native session state to Talia signal/view intent.

Recommended mapping:

| Real memorization state | Talia behavior |
|---|---|
| `learning` + ayah audio playing | `listening`, no bubble covering content |
| `memorizing` | `idle` / minimal; guidance only on explicit request |
| `reciting` | silent `listening` or hidden/minimal; **never `speaking`** |
| `blockReview` | silent `listening` or hidden/minimal |
| `isEvaluating` | `thinking` briefly, if visible and not audio-suppressed |
| classified correct result | `happy` once |
| `remediation` | `encourage` only after classification |
| technical audio/STT/permission error | technical error guard; no `encourage` |
| `completed` | coordinated `celebrate` through existing celebration flow |

## 10.2 Mapper requirements

`TaliaMemorizationMapper` (name may adapt) SHOULD be pure/testable where possible.

It MUST NOT:

- start/stop audio,
- own memorization progression,
- own scoring logic,
- infer success from raw STT details,
- alter session state.

It only translates trusted domain state into semantic companion signals.

## 10.3 Duplicate-event protection

Correct/completion/remediation events MUST not fire repeatedly because of rebuilds or repeated identical Cubit states.

Prefer existing stable identifiers such as:

- session ID,
- ayah/item ID,
- attempt ID,
- result version,
- completion ID.

If the existing domain state lacks a stable event ID, implement the smallest safe dedupe mechanism around semantic state transitions rather than a global arbitrary debounce.

---

# 11. Quran Reader, Audio & Recording Contract

## 11.1 Quran Reader / Mushaf

Always:

```text
presence = hidden
speechBubble = none
autoMessage = none
```

Talia MUST NOT float over the Mushaf.

If the existing reader has an established toolbar/help area, a small non-character help entry point MAY exist only if it does not reduce reading focus.

## 11.2 Global Quran audio player

The repository contains/uses a persistent Quran audio experience (e.g. `QuranAudioPlayerCubit`, mini player bar, or current equivalent).

When Quran audio is actively playing on any non-reader screen:

- automatic Talia text is muted,
- no proactive greeting/encouragement/celebration bubble appears,
- if Talia is already visible, `listening` MAY be used silently,
- Talia MUST NOT auto-appear because playback began.

When playback stops:

- do not replay suppressed low-value messages,
- restore the state valid for the current route/context.

## 11.3 User recording

During active user recording:

- no Talia bubble,
- no Talia speaking pose,
- no celebratory interruption,
- no result feedback until recording/evaluation state actually completes.

---

# 12. Home Integration Contract

The Home page already has a greeting based on time/name. Talia MUST integrate with or replace that composition rather than create a second greeting.

Forbidden:

```text
Existing Home Greeting
+
Independent Talia Speech Bubble Greeting
```

Required approach:

```text
Existing greeting content
        ↓
Talia-aware Home greeting composition
```

## 12.1 First eligible home visit of local day

If all rules allow:

1. render `welcome`/wave briefly,
2. use the existing greeting content/message surface,
3. settle to `idle`,
4. mark greeting as shown for the current record owner and local calendar date.

## 12.2 Repeat visits same day

- no second proactive greeting,
- render normal `idle`/minimal state according to experience mode.

## 12.3 Layout

Talia must be part of normal responsive page composition, not an uncontrolled global floating overlay.

The Home integration MUST be tested at narrow widths and large text scaling.

---

# 13. Celebration Integration Contract

The repository already has celebration/certificate behavior (e.g. `CelebrationOverlay` and session completion UI).

Talia MUST reuse/coordinate with that system.

## 13.1 One celebration channel at a time

Forbidden:

```text
CelebrationOverlay
+ independent Talia overlay
+ certificate dialog
+ separate confetti
```

Preferred strategies:

1. Existing celebration surface accepts an optional Talia visual/state.
2. Talia celebration is suppressed while a higher-value existing certificate/dialog is active.
3. Existing celebration event drives the Talia coordinator rather than creating a parallel celebration trigger.

## 13.2 Timing

Celebration is transient and must settle/dismiss cleanly.

Recommended maximum visual celebration duration:

- Adult: ~2.0–2.5 seconds if no dialog is present.
- Kids: ~2.5–3.2 seconds if no dialog is present.

If the existing celebration flow already defines timing, integrate with it instead of forcing a second timer.

---

# 14. V1 Interaction Contract

Talia is boundedly interactive.

## 14.1 Tap behavior

When Talia is tappable and current focus rules permit, tapping opens a small context-aware bottom sheet/action surface.

Possible actions:

1. **Continue today's task**
   - only when the app has a meaningful existing destination.
2. **Explain this screen**
   - approved static help copy only.
3. **Hide Talia for today**
   - owner-scoped snooze until next local calendar day.
4. **Talia settings**
   - open existing settings route/section.

The sheet MUST use existing design system, bottom-sheet conventions, localization, and routing.

## 14.2 Not allowed

- free-form text input,
- chat history,
- generative answers,
- religious Q&A,
- open-ended voice conversation,
- unreviewed contextual advice.

## 14.3 Contextual availability

Actions that cannot be fulfilled safely MUST be omitted/disabled rather than shown as dead ends.

---

# 15. Anti-Annoyance & Timing Policy

Centralize timing values in one policy/configuration object rather than scattering magic numbers.

Recommended v1 defaults, unless existing UX timings provide a better repository-consistent value:

| Behavior | Adult | Kids |
|---|---:|---:|
| entrance/state fade/switch | 200–300 ms | 220–350 ms |
| proactive message visible | ~4 s | ~4.5–5 s |
| correct-result happy state | ~1.4–1.8 s | ~1.8–2.2 s |
| proactive-message cooldown | 120 s | 60 s |
| celebration max (without existing dialog) | 2.0–2.5 s | 2.5–3.2 s |

Rules:

- greeting is max once per local calendar day per record owner,
- no more than one proactive Talia surface at once,
- explicit user interaction may bypass proactive cooldown but not focus/safety suppression,
- state changes caused by route/audio/recording/focus immediately invalidate lower-priority pending messages,
- do not queue ordinary greetings/encouragement for delayed replay,
- no periodic idle loop in v1,
- if `disableAnimations` / reduced motion is active, use no motion or a minimal fade only.

## 15.1 Stale callback protection

Any delayed transition (e.g. `happy -> idle`) MUST verify it still belongs to the current state/event.

Recommended approaches:

- state generation/version token,
- cancellable timer owned by Cubit/coordinator,
- compare expected current event key before applying delayed state.

A timer from an old result MUST NOT overwrite a newer Quran-focus/audio/help state.

---

# 16. Religious Content Governance

This section is mandatory.

## 16.1 Approved message IDs only

Talia user-facing messages MUST be selected from a finite, reviewed enum/key set.

Example:

```dart
enum TaliaMessageId {
  dailyMorningGreeting,
  dailyEveningGreeting,
  memorizationReady,
  listenCarefully,
  yourTurn,
  correctResult,
  retryEncouragement,
  revisionReady,
  sessionCompleted,
  screenHelpHome,
  screenHelpMemorization,
  screenHelpRevision,
}
```

Exact names may adapt to localization conventions.

## 16.2 Localization source

Resolution flow:

```text
TaliaMessageId
      ↓
existing localization layer / ARB
      ↓
localized approved copy
```

No raw Talia strings in widgets, Cubits, coordinator, or mappers.

## 16.3 Prohibited behavior

Talia v1 MUST NOT:

- generate Quranic verses dynamically,
- generate hadith dynamically,
- generate tafsir,
- generate fatwa/religious rulings,
- claim spiritual causes for product events,
- interpret a low pronunciation score as moral/spiritual weakness,
- shame the user for missed practice,
- invent religious quotations or references.

Any Quran/hadith content shown by the app remains governed by the app's existing trusted content pipeline.

## 16.4 Regression guard

The implementation MUST preserve and extend, where appropriate, existing religious-content governance tests such as `no_ungoverned_religious_output_test.dart` or its current equivalent.

---

# 17. Dialogue / Copy Pool Contract

Add ARB/localization keys using the repository's exact localization conventions.

The message bank SHOULD cover at minimum:

### Greeting

- morning greeting
- daytime/general greeting
- evening greeting

### Memorization

- ready to begin
- listen carefully
- user turn prompt (only before recording, not during it)
- correct-result encouragement
- calm retry/remediation encouragement

### Revision

- revision ready
- revision completion

### Completion

- session completed
- achievement/milestone completed

### Screen help

- Home help
- Memorization help
- Revision help
- Progress help if needed

Tone requirements:

- short,
- warm,
- calm,
- child-friendly in Kids mode,
- not childish in Adult mode,
- no guilt,
- no spiritual judgment,
- no fake quotes.

Adult and Kids modes MAY use different approved keys where tone genuinely needs to differ.

---

# 18. Persistence & Account Scope

The app distinguishes record owners/users. Companion state MUST not leak between them.

## 18.1 Record-owner scoped data

Store per record owner where applicable:

- Talia enabled/disabled,
- presence/intensity preference,
- encouragement preference,
- last greeting local date,
- hide-for-today/snooze date,
- lightweight cooldown metadata only if persistence across process restarts is intentionally desired.

Use `RecordOwnerProvider` or current repository equivalent.

## 18.2 Device/application scoped data

Recommended device-level concerns:

- user-selected Talia motion intensity if the existing settings architecture treats animation preferences as device settings,
- platform reduced-motion / `disableAnimations` is observed from platform/app state and should not be duplicated as a Talia preference.

If the repository has a strong established profile-scoped settings model, follow it consistently and document the choice.

## 18.3 Versioned keys

Use versioned stable keys/namespaces, e.g.:

```text
talia_companion.v1.enabled
talia_companion.v1.presence
talia_companion.v1.encouragement
talia_companion.v1.last_greeting_date
talia_companion.v1.hidden_until_date
talia_companion.v1.motion_preference
```

Owner-scoped storage MUST include/use the existing owner identity mechanism rather than manually concatenating unsafe identifiers if the repository already provides scoped storage.

## 18.4 "Once per day" semantics

"Once per day" means **local calendar date**, not `lastTimestamp + 24h`.

Use an injectable/testable clock abstraction rather than calling `DateTime.now()` throughout the feature.

Recommended abstraction:

```dart
abstract interface class Clock {
  DateTime now();
}
```

Use the repository's existing clock/time abstraction if one already exists.

## 18.5 Account switching

On record-owner change:

- cancel transient Talia timers,
- clear non-persisted transient state,
- load the new owner's preferences/greeting/snooze state,
- do not inherit previous owner's cooldown/greeting state,
- do not replay a stale celebration from the prior owner.

## 18.6 Data clearing/logout

Follow the existing account/local-data semantics. Do not invent independent cleanup behavior that conflicts with repository rules.

---

# 19. Lifecycle & IndexedStack Contract

The app already observes lifecycle and uses indexed-stack navigation. This matters because hidden pages/Cubits may remain alive.

## 19.1 Lifecycle

On `inactive`, `paused`, or equivalent non-interactive state:

- cancel or pause transient timers,
- suppress new visual transitions,
- stop animation controllers/tickers,
- invalidate delayed callbacks that should not survive.

On resume:

- re-evaluate current route/audio/recording/owner context,
- restore only the currently valid state,
- do NOT automatically replay greeting, result feedback, or celebration.

## 19.2 Ticker behavior

Use existing `TickerMode`/route visibility behavior where available.

Talia animations MUST NOT continue on an offstage tab retained by `StatefulShellRoute.indexedStack`.

## 19.3 Route visibility

Coordinator context MUST distinguish:

- active visible route,
- retained/offstage route,
- Quran Reader/focus route,
- modal/dialog state when it affects companion visibility.

Do not infer visibility only from widget existence.

---

# 20. Performance & Asset Memory Budget

The current assets are approximately `1086 x 1448` each and around ~1 MB compressed per image. A full decode is roughly:

```text
1086 × 1448 × 4 bytes ≈ 6 MB RAM per bitmap
```

Therefore, decoding/pre-caching all poses at source size is unacceptable.

## 20.1 Required image strategy

- Register `assets/talia/` once.
- Decode images near actual display size.
- Use `cacheWidth` or `ResizeImage` through one centralized character-image widget.
- Do not precache all Talia assets.
- At startup, load only what the initial composition requires (normally `idle`; `wave` only when actually eligible).
- Load other moods lazily.
- Do not create separate full-resolution `Image.asset` calls in screens.

## 20.2 Decode-width calculation

The character-image component SHOULD derive physical decode width from logical display size and device pixel ratio:

```dart
final targetPhysicalWidth =
    (logicalWidth * MediaQuery.devicePixelRatioOf(context)).ceil();
```

Then clamp to a reasonable per-size maximum and never exceed source width.

Recommended maximum decode widths:

| UI size | Approx logical use | Max decode width |
|---|---:|---:|
| avatar | ~48–80 dp | 256 px |
| small | ~96–160 dp | 384 px |
| medium | ~180–280 dp | 640 px |
| large | ~300–420 dp | 960 px |

These are ceilings, not mandatory fixed widths. Use smaller values when the actual layout is smaller.

## 20.3 Precache policy

Allowed:

- current pose,
- optionally the immediate likely next pose if a measured transition benefits.

Forbidden:

- pre-cache all 10 full-resolution assets at startup.

## 20.4 Rendering/rebuild rules

- Mood changes MUST NOT rebuild the entire screen unnecessarily.
- Animation controllers MUST be scoped and disposed.
- No heavy particle package.
- No new heavy dependency solely for Talia.
- Prefer `RepaintBoundary` only if profiling shows it is beneficial; do not add blindly.

## 20.5 Production asset optimization

After v1 behavior is correct, optimized transparent WebP MAY be evaluated.

Do not replace source PNGs automatically without:

- visual quality comparison,
- transparency validation,
- app-size comparison,
- decode/render regression check.

---

# 21. Native Flutter Motion Contract

Allowed tools:

- `AnimatedSwitcher`
- `AnimatedOpacity`
- `FadeTransition`
- small `Transform.translate`
- small `Transform.scale`
- existing lightweight app animation utilities

V1 MUST NOT have perpetual autonomous movement.

Recommended behavior:

- one-off entrance/pose transition,
- small scale/fade on success,
- small finite celebration transition,
- no constant bobbing/breathing loop.

When motion is minimal/off or platform animations are disabled:

- use immediate swap or minimal fade,
- no translate/scale flourish.

---

# 22. RTL, Localization, Typography & Design System

## 22.1 Semantic direction

Do not expose domain state named `pointRight`.

Use semantic `guide` intent, then let UI choose physical direction based on:

- `TextDirection`,
- Talia's placement,
- target control position.

The current `talia_point_right.png` asset MAY be mirrored horizontally with Flutter when needed.

## 22.2 Speech bubble direction

The bubble/tail MUST adapt to RTL/LTR and character placement.

Do not hardcode left/right padding or pointer placement that breaks Arabic layouts.

## 22.3 Typography

Use the app's established UI typography for ordinary Talia messages.

Do NOT use a Quran-specific typeface such as Amiri merely because Talia is in a Quran app unless the existing design system explicitly uses it for that UI role.

Quran text remains governed by the app's Quran typography system.

## 22.4 Design tokens

Talia UI MUST reuse repository tokens such as:

- `AppColors`,
- `AppTypography`,
- `AppSpacing`,
- Adult theme/sanctuary tokens,
- Kids theme tokens,

or their current equivalents.

No new standalone Talia color/spacing/typography system unless a token is genuinely missing and added through the existing design system.

---

# 23. Accessibility & Responsive/Adaptive Contract

## 23.1 Accessibility

- Decorative character image SHOULD be excluded from noisy semantics when no information is conveyed.
- If Talia conveys required information, the same information must exist as accessible text.
- Talia MUST not be the sole entry point to a critical action.
- Respect reduced motion.
- Speech-bubble contrast must satisfy the app's accessibility standards.
- Interactive Talia/tap targets must meet the app's minimum touch target.

## 23.2 Text scaling

Test with increased system text scale.

Speech bubbles MUST:

- grow vertically,
- wrap naturally,
- avoid clipping,
- avoid covering primary content,
- allow the layout to move Talia or suppress the bubble at extreme constraints.

## 23.3 Widths

At minimum verify common narrow mobile widths such as:

- 320 logical px,
- 360 logical px,

plus standard larger phones/tablets if the app supports them.

## 23.4 Themes

Verify both light and dark modes where applicable.

Adult and Kids themes must remain visually distinct.

---

# 24. Talia Companion Widget API

Build one reusable component.

Illustrative API only; adapt to repository conventions:

```dart
TaliaCompanion(
  state: taliaState,
  size: TaliaCompanionSize.medium,
  placement: TaliaPlacement.trailing,
  onTap: canInteract ? onTapTalia : null,
)
```

The widget SHOULD receive already-resolved presentation state rather than business events.

It owns:

- asset resolution,
- decode sizing,
- transition rendering,
- optional speech bubble,
- semantics,
- RTL mirroring for semantic guide pose,
- reduced-motion rendering,
- tap target.

It does NOT own:

- daily greeting eligibility,
- audio suppression,
- recording suppression,
- owner persistence,
- memorization scoring,
- religious message selection logic beyond resolving an approved message ID through localization.

---

# 25. Preferences & Settings UI

Add a Talia Companion section through the existing settings architecture.

Minimum user controls:

```text
Talia Companion: On / Off
Companion intensity: Minimal / Companion (where appropriate)
Motion: Full / Minimal / Off
Encouragement: Normal / Minimal / Off
Hide for today
```

Notes:

- Adult/Kids defaults come from experience mode, but the user may override within allowed product rules.
- Platform/app reduced-motion overrides Talia motion.
- "Hide for today" is temporary and owner-scoped.
- Permanent Off remains available.
- If parental controls or Kids settings impose restrictions, integrate with them rather than bypassing them.

---

# 26. Feature Flag / Kill Switch

Talia Companion v1 MUST have a safe rollout switch.

Preferred order:

1. Reuse existing feature-flag system if present.
2. Otherwise use a lightweight compile/runtime configuration already supported by the app (e.g. app config / `--dart-define`).

Do NOT add a backend solely to host this flag.

When disabled:

- Talia companion UI/integrations do not appear,
- existing app functionality and legacy character assets remain intact,
- no orphaned blank space remains in layouts.

---

# 27. Event Integration Rules

## 27.1 Prefer existing event infrastructure

If `ProgressEventsBus` or equivalent already publishes meaningful progress/completion events, reuse it.

Do not publish duplicate events solely for Talia when a trusted existing event can be adapted.

## 27.2 Avoid tight cross-feature imports

Where possible:

```text
Feature native state/event
        ↓
small adapter/mapper
        ↓
TaliaSignal
        ↓
Coordinator
```

## 27.3 Event idempotency

The coordinator must be safe when:

- a Cubit re-emits equivalent states,
- an indexed-stack tab remains alive,
- route listeners reattach,
- lifecycle resumes,
- multiple sources report the same completion.

Do not rely on widget rebuild frequency as an event source.

---

# 28. Test Matrix

Tests must follow the repository's existing style and avoid unnecessary tooling.

## 28.1 Unit tests — policies/models

Required:

1. Every `TaliaMood` maps to the correct asset.
2. Asset registry contains no missing asset path.
3. Priority resolver enforces:
   - Quran focus > all lower priorities,
   - inactive/background > transient events,
   - audio/recording > proactive message,
   - explicit user help > cooldown but not focus safety.
4. Greeting eligibility is once per **local calendar day**.
5. Greeting is owner-scoped.
6. Hide-for-today is owner-scoped.
7. Owner switch clears transient state.
8. Technical error never maps to `encourage`/failure feedback.
9. Completion/result events are deduped.
10. Stale timer callback cannot overwrite a newer high-priority state.
11. Adult default is minimal.
12. Kids default is companion.
13. Platform reduced motion overrides Talia motion preference.

## 28.2 Memorization mapper tests

Required:

- learning + audio -> listening/no automatic bubble,
- memorizing -> idle/minimal,
- reciting -> silent listening/hidden, not speaking,
- block review -> silent listening/hidden,
- evaluating -> thinking,
- classified correct -> happy once,
- remediation -> encourage,
- technical STT/audio error -> no encourage,
- completed -> completion signal once.

## 28.3 Widget tests

Required:

- `hidden` renders no character,
- asset decode sizing is applied through the character-image component,
- reduced motion/off removes non-essential motion,
- RTL guide pose mirrors/positions correctly,
- speech-bubble tail/alignment is correct in RTL/LTR,
- 320px width does not overflow,
- 360px width does not overflow,
- large text scale does not clip critical copy,
- dark/light themes remain legible,
- Talia is not the only accessible critical action.

## 28.4 Integration/regression tests

Required where repository test infrastructure permits:

- `assets/talia/` is present in asset manifest.
- Home does not render duplicate greeting surfaces.
- same owner does not receive repeated same-day greeting.
- different owner does not inherit prior owner's greeting/snooze.
- Quran Reader always hides Talia.
- global Quran audio suppresses proactive bubble.
- active recording suppresses proactive bubble.
- indexed-stack tab switching does not leave hidden Talia animations running.
- lifecycle background/resume does not replay greeting/celebration.
- existing celebration + Talia never produce duplicate competing overlays.
- existing social-share character asset is not unintentionally replaced.
- no ungoverned religious output is introduced.
- feature flag disabled leaves existing app behavior intact.

## 28.5 Static checks

After each implementation phase:

```text
flutter format / dart format (repository convention)
flutter analyze
relevant flutter tests
```

Fix new issues before continuing.

---

# 29. Implementation Phases & Quality Gates

Do NOT implement the entire feature in one uncontrolled pass.

## Phase 0 — Repository Audit (NO CODE CHANGES)

Verify:

- `AGENTS.md` / repository instructions,
- state-management conventions,
- GetIt/DI,
- router/indexedStack,
- lifecycle observer,
- Adult/Kids experience switch,
- localization/ARB,
- themes/tokens,
- persistence and record-owner scoping,
- feature flags,
- Home greeting,
- memorization state machine,
- Quran audio player,
- user recording flow,
- ProgressEventsBus,
- celebration overlay/certificate flow,
- existing Talia/legacy character usage,
- current tests.

**Deliverable:** audit + implementation plan only. STOP for approval.

## Phase 1 — Foundation

Implement only:

- asset registration if needed,
- central asset registry,
- core models,
- approved message IDs,
- preferences repository/scoping,
- clock integration,
- timing/priority/presence policies,
- `TaliaCompanionCoordinator`,
- `TaliaCompanionCubit/state`,
- reusable `TaliaCompanion`/image/bubble primitives,
- feature flag plumbing,
- core unit/widget tests.

No broad screen integration yet.

### Phase 1 gate

- format clean,
- analyze clean/no new issues,
- relevant tests pass,
- no heavy dependency added,
- no direct Talia asset path in feature screens.

STOP for review.

## Phase 2 — Primary Integration

Implement:

- Adult/Kids default context,
- Home integrated greeting (no duplicate),
- Quran Reader hidden behavior,
- global Quran audio suppression,
- recording suppression,
- real memorization mapper/integration,
- completion coordination with existing celebration system.

### Phase 2 gate

Add/verify regression tests for Home, Reader, audio, recording, memorization, celebration, owner scope.

STOP for review.

## Phase 3 — Bounded Interaction & Settings

Implement:

- Talia tap action sheet,
- continue-today action where supported,
- static screen-help action,
- hide-for-today,
- settings integration,
- RTL action sheet/bubble behavior,
- approved localized dialogue keys.

STOP for review.

## Phase 4 — Secondary Integration

Integrate only where product value is clear and layout supports it:

- Revision,
- Progress,
- Kids Journey/stage map,
- onboarding safe contexts,
- SmartCoach/recommendation surface,
- other approved achievement moments.

Do not force Talia into every screen.

STOP for review.

## Phase 5 — Production Quality Pass

- lifecycle edge cases,
- indexed-stack offstage behavior,
- stale timer cancellation,
- image decode/memory review,
- responsive/adaptive layouts,
- 320/360 widths,
- text scaling,
- RTL/LTR,
- light/dark,
- reduced motion,
- content-governance tests,
- feature-flag-off regression,
- full relevant test suite,
- `flutter analyze`.

---

# 30. Definition of Done

The feature is complete only when ALL applicable requirements are satisfied:

## Architecture

- one central Talia asset registry exists,
- one central coordinator/policy layer exists,
- presentation state is centrally controlled,
- feature-specific mappings are narrow/testable,
- no parallel architecture/framework was introduced.

## UX

- Adult defaults to quiet/minimal behavior,
- Kids defaults to companion behavior,
- Quran Reader remains completely distraction-free,
- audio/recording suppress automatic bubbles,
- Home greeting is not duplicated,
- celebration channels are not duplicated,
- Talia interaction is bounded and non-AI,
- hide-for-today and permanent controls work.

## Religious content

- all Talia messages use approved message IDs,
- all copy comes through localization,
- no ungoverned religious generation/output path was introduced,
- existing religious-content tests remain green.

## Account/persistence

- owner-scoped data does not leak between accounts/children/adults,
- local-day greeting semantics are correct,
- account switching cancels transient state,
- clock is testable/injectable or existing equivalent is used.

## Performance

- `assets/talia/` is correctly registered,
- images are decoded near display size,
- no all-assets full-size precache,
- no unnecessary whole-screen rebuilds,
- no heavy animation dependency added.

## Lifecycle/accessibility

- timers/controllers are disposed/canceled safely,
- offstage indexed-stack pages do not keep Talia animating,
- reduced motion is respected,
- RTL/LTR works,
- narrow widths/text scaling do not break layout,
- critical actions remain accessible without Talia.

## Verification

- formatter succeeds,
- `flutter analyze` has no new warning/error attributable to the feature,
- all relevant tests pass,
- existing behavior remains intact when feature flag is disabled.

Displaying PNGs alone is NOT completion. The feature must behave contextually according to this specification.

---

# 31. Required Implementation Report After Each Phase

Codex/implementer must report:

1. phase completed,
2. exact files created,
3. exact files modified,
4. integration points used,
5. behavior implemented,
6. tests added/updated,
7. commands run and actual results,
8. deviations from this spec and why,
9. known risks/remaining items,
10. confirmation that no unrelated refactor was performed.

Do not claim success without command/test evidence.

---

# 32. MASTER CODEX PROMPT — Phase 0 Audit

Place this file at exactly:

```text
docs/TALIA_COMPANION_IMPLEMENTATION_SPEC_v2.1.md
```

Then run the following prompt from the repository root.

```text
You are working inside the existing Talia Quran Flutter repository as a senior Flutter engineer and implementation reviewer.

Your task is to implement the Talia Companion System defined in:

docs/TALIA_COMPANION_IMPLEMENTATION_SPEC_v2.1.md

Character assets are expected under:

assets/talia/

CRITICAL: THIS FIRST RUN IS AUDIT + PLAN ONLY. DO NOT MODIFY CODE YET.

Before doing anything else:

1. Read AGENTS.md and all repository-specific instructions that apply to this project.
2. Read the entire Talia Companion v2.1 specification.
3. Inspect the actual repository deeply enough to verify every relevant integration point.
4. Treat the repository as the source of truth for implementation details, but treat the specification as authoritative for product/UX behavior, religious-content governance, focus/suppression rules, account scope, performance constraints, and Definition of Done.
5. Do not create parallel systems where the repository already has an equivalent service, Cubit/BLoC, event bus, lifecycle observer, router abstraction, persistence layer, localization layer, design system, celebration mechanism, feature flag, or test helper.

VERIFY AT MINIMUM:

- project architecture and feature/module conventions
- current BLoC/Cubit/state-management patterns
- GetIt/dependency injection
- GoRouter / StatefulShellRoute.indexedStack behavior
- app lifecycle handling and disableAnimations/reduced-motion handling
- Adult Sanctuary vs Kids Journey / ExperienceFork behavior
- localization and ARB files
- AppColors/AppTypography/AppSpacing/KidsTheme or current equivalents
- persistence layer and RecordOwnerProvider/current owner-scoping mechanism
- feature-flag/config mechanism
- Home greeting implementation
- MemorizationSessionCubit / SessionPhase / MemorizationSessionState actual state machine
- QuranAudioPlayerCubit and persistent mini-player behavior
- active user recording/recitation flow
- ProgressEventsBus or existing progress event infrastructure
- CelebrationOverlay and memorization certificate/completion flow
- existing Talia/character assets used by onboarding/social sharing/legacy UI
- test/core/content/no_ungoverned_religious_output_test.dart or current equivalent
- pubspec.yaml asset registration
- existing tests that can be extended

SEARCH FOR THESE KNOWN POINTS/SYMBOLS RATHER THAN ASSUMING PATHS ARE STILL CURRENT:

app.dart
injection.dart
app_router.dart
session_phase.dart
celebration_overlay.dart
home_page_widgets.dart
v2_session_page.dart
record_owner_provider.dart
social_share_model.dart
quran_mini_player_bar.dart
ExperienceForkView
KidsModeCubit
SmartCoach
ProgressEventsBus
QuranAudioPlayerCubit
MemorizationSessionCubit

AUDIT OUTPUT REQUIRED:

A. Repository findings
- confirmed architecture/state management/DI/routing/localization/theme/persistence patterns
- confirmed actual paths/classes for every relevant integration point

B. Spec-to-repository compatibility table
For each major area, classify:
- directly compatible
- compatible with adaptation
- conflict / requires decision

C. Exact implementation plan by phase
For each phase include:
- files to create
- files to modify
- existing systems to reuse
- data flow
- risks
- tests

D. Explicit risk checks
Confirm how you will prevent:
- duplicate Home greeting
- duplicate celebration overlays/dialogs
- wrong recitation mapping to talia_speaking
- technical STT/audio errors being treated as user mistakes
- Talia showing in Quran Reader
- Talia bubbles during Quran audio or active recording
- state leaks between record owners
- stale timers after route/lifecycle changes
- indexedStack offstage animations
- full-resolution mass image decoding
- ungoverned religious copy
- accidental replacement of social-share/legacy character assets

E. Any required spec clarification
Only list genuine blockers that cannot be resolved by inspecting the repository.

STOP AFTER THE AUDIT AND PLAN.
DO NOT EDIT FILES.
DO NOT IMPLEMENT PHASE 1 UNTIL I APPROVE THE PLAN.
```

---

# 33. CODEX PHASE 1 EXECUTION PROMPT

Use only after approving Phase 0 plan:

```text
The Phase 0 audit/plan is approved.

Implement Phase 1 ONLY from:

docs/TALIA_COMPANION_IMPLEMENTATION_SPEC_v2.1.md

Phase 1 scope:
- asset registration if missing
- central asset registry/resolver
- core models
- approved TaliaMessageId model
- preferences/account-scope plumbing
- injectable/existing Clock integration
- timing/priority/presence policies
- TaliaCompanionCoordinator
- TaliaCompanionCubit/state
- reusable TaliaCompanion/TaliaCharacterImage/TaliaSpeechBubble primitives
- feature flag plumbing
- core unit/widget tests

Do NOT integrate broadly into Home, Memorization, Quran Reader, Revision, Progress, or Kids screens yet unless a tiny composition-root connection is strictly required for the foundation.

Requirements:
- follow existing architecture exactly
- no unrelated refactors
- no Rive/Lottie/3D/new state framework
- no hardcoded user-facing copy
- no all-assets full-resolution precache
- no religious dynamic output

Before completion:
- run formatter using repository convention
- run flutter analyze
- run all relevant Phase 1 tests
- fix new issues

Then report the Required Implementation Report from section 31 and STOP for review.
```

---

# 34. CODEX PHASE 2 EXECUTION PROMPT

Use only after Phase 1 approval:

```text
Phase 1 is approved.

Implement Phase 2 ONLY from:

docs/TALIA_COMPANION_IMPLEMENTATION_SPEC_v2.1.md

Phase 2 scope:
- Adult Sanctuary vs Kids Journey defaults/context
- Home integrated greeting WITHOUT duplicate greeting UI
- Quran Reader hidden behavior
- global Quran audio suppression
- active recording suppression
- real MemorizationSessionState/SessionPhase mapper and integration
- technical error guard
- completion coordination with existing CelebrationOverlay/certificate flow
- owner-safe transient state handling
- regression tests for all above

Do not implement Phase 3 or Phase 4 yet.

Pay special attention to StatefulShellRoute.indexedStack and existing kept-alive Cubits/pages.

Before completion:
- run formatter
- run flutter analyze
- run relevant tests
- fix new issues

Then provide the section 31 implementation report and STOP for review.
```

---

# 35. CODEX PHASE 3 EXECUTION PROMPT

```text
Phase 2 is approved.

Implement Phase 3 ONLY from:

docs/TALIA_COMPANION_IMPLEMENTATION_SPEC_v2.1.md

Scope:
- bounded Talia tap interaction
- context-aware action sheet
- Continue Today when an existing valid destination exists
- approved static Explain Current Screen help
- Hide Talia for Today
- Talia settings integration
- ARB/localization message bank
- RTL/LTR behavior
- accessibility/reduced-motion behavior for these interactions
- tests

No AI, free-form chat, voice assistant, tafsir generation, or backend.

Run formatter, flutter analyze, and relevant tests before reporting.
STOP after the phase report.
```

---

# 36. CODEX PHASE 4 EXECUTION PROMPT

```text
Phase 3 is approved.

Implement Phase 4 ONLY from:

docs/TALIA_COMPANION_IMPLEMENTATION_SPEC_v2.1.md

Integrate Talia only where it provides clear value and layout allows it:
- Revision
- Progress
- Kids Journey/stage map
- onboarding safe contexts
- SmartCoach/recommendation surface
- approved achievement moments

Do NOT force Talia into every page.
Do NOT change Quran Reader focus rules.
Do NOT replace existing legacy/social-share character assets unless explicitly approved.

Run formatter, flutter analyze, and relevant tests before reporting.
STOP after the phase report.
```

---

# 37. CODEX PHASE 5 PRODUCTION QUALITY PROMPT

```text
Phases 1–4 are approved.

Perform Phase 5 production-quality verification for Talia Companion v2.1.

Required checks:
- lifecycle/background/resume
- stale timer cancellation
- account/record-owner switching
- indexedStack offstage animation behavior
- Quran Reader hidden guarantee
- Quran audio suppression
- recording suppression
- technical error guard
- duplicate-event prevention
- duplicate Home greeting prevention
- duplicate celebration prevention
- asset manifest
- image decode/cacheWidth strategy
- no all-assets full-size precache
- 320px / 360px widths
- large text scaling
- RTL/LTR
- light/dark themes where applicable
- Adult vs Kids defaults
- reduced motion / disableAnimations
- approved religious message IDs only
- no ungoverned religious output
- feature flag OFF regression
- legacy/social-share character assets unchanged unless explicitly intended

Run:
- repository formatter
- flutter analyze
- complete relevant test suite

Do not claim completion unless verification evidence is clean.

Provide:
1. final behavior summary
2. exact files changed
3. where Talia appears
4. where Talia is intentionally hidden/silent
5. test matrix and results
6. analyze result
7. remaining limitations/follow-ups
8. explicit Definition of Done checklist from section 30
```

---

# 38. Final Product Principle

The successful result should feel like:

> **A Quran experience accompanied by Talia — not a Quran app with a mascot pasted on top.**

When the user needs guidance, Talia is present.  
When the user succeeds, Talia can acknowledge it.  
When the user is listening, Talia becomes quiet.  
When the user is reciting, Talia does not interrupt.  
When the user opens the Mushaf, Talia disappears.

That balance is the core of the feature.
