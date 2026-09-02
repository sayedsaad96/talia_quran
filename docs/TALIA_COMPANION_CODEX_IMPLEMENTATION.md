# Talia Companion System — Codex Implementation Specification

## Goal
Implement **Talia Companion** as a calm, contextual companion across the Talia Quran Flutter app using the prepared static transparent PNG asset pack.

Talia is **not** a floating mascot that stays on every screen. She should feel present when useful and disappear during Quran reading/recitation focus.

---

## 1. Non-negotiable UX principles

1. Talia never covers Quran text or important controls.
2. Talia must be hidden during focused Quran reading and recitation playback unless the user explicitly requests help.
3. No continuous distracting animation.
4. No repeated popups or repeated greetings in the same session/day.
5. No guilt-based messaging, streak pressure, or negative language.
6. User must be able to reduce or disable Talia animations/encouragement.
7. Respect reduced-motion accessibility settings.
8. Keep the implementation lightweight: static PNGs + Flutter native animation only. Do not add Rive, Lottie, or a 3D runtime.

---

## 2. Asset pack

Expected location:

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

Update `pubspec.yaml` only if the project does not already include the folder.

Prefer folder-level registration:

```yaml
flutter:
  assets:
    - assets/talia/
```

---

## 3. Architecture

First inspect the repository and follow its existing architecture, naming, routing, state-management, localization, theming, dependency injection, and testing patterns.

Do **not** create a parallel architecture.

If the project already uses BLoC/Cubit, implement the feature using Cubit. Do not introduce Riverpod only for this feature.

Suggested feature boundary:

```text
lib/features/talia_companion/
  domain/
    models/
      talia_mood.dart
      talia_presence_level.dart
      talia_preferences.dart
    rules/
      talia_presence_rules.dart
      talia_message_rules.dart
  presentation/
    cubit/
      talia_companion_cubit.dart
      talia_companion_state.dart
    widgets/
      talia_companion.dart
      talia_character_image.dart
      talia_speech_bubble.dart
      talia_effects.dart
  data/
    talia_preferences_repository.dart
```

Adapt this layout to the repository's current structure when necessary.

---

## 4. Core models

### TaliaMood

```dart
enum TaliaMood {
  idle,
  wave,
  happy,
  listening,
  speaking,
  thinking,
  readingQuran,
  encourage,
  celebrate,
  pointRight,
}
```

Create a single asset resolver/registry. Do not hardcode asset paths across screens.

### TaliaPresenceLevel

```dart
enum TaliaPresenceLevel {
  hidden,      // level 0
  minimal,     // level 1
  companion,   // level 2
  interactive, // level 3
}
```

### TaliaMotionPreference

```dart
enum TaliaMotionPreference {
  full,
  minimal,
  off,
}
```

---

## 5. Presence rules

### Level 0 — Hidden
Use for:
- Quran reader / Mushaf focus screen
- full-screen recitation playback
- any screen where Talia could cover Quran text

Behavior:
- no character overlay
- no automatic message
- optional small Help entry point only if the current product already has a suitable toolbar/action area

### Level 1 — Minimal
Use for:
- settings
- search
- bookmarks
- secondary utility screens

Behavior:
- avatar/small Talia only when useful
- no idle looping motion

### Level 2 — Companion
Use for:
- home
- memorization
- revision
- progress

Behavior:
- half-body or full-body contextual appearance
- subtle native Flutter motion
- short contextual messages

### Level 3 — Interactive
Use for:
- onboarding
- completion/achievement moments
- explicitly interactive learning moments

Behavior:
- larger Talia presentation is allowed
- short celebration/guide transition is allowed

---

## 6. Anti-annoyance rules

Implement these centrally, not individually in each screen.

- Greeting is shown at most once per day.
- Do not show another proactive Talia message within a short cooldown window after one has just appeared.
- Do not interrupt an active audio recitation.
- Do not interrupt text input or navigation transitions.
- Celebration should auto-settle back to idle after a short duration.
- Encourage state should never use failure language.
- Avoid more than one proactive Talia surface at a time.
- If motion is disabled, state changes should use either no transition or a very small fade only.

Persist only preferences and lightweight timestamps needed for these rules. Avoid unnecessary backend work.

---

## 7. TaliaCompanion widget API

Build one reusable component rather than manually placing images everywhere.

Example target API:

```dart
TaliaCompanion(
  mood: TaliaMood.happy,
  presence: TaliaPresenceLevel.companion,
  message: context.l10n.taliaGreatJob,
  size: TaliaCompanionSize.medium,
  onTap: ..., // optional
)
```

Suggested sizes:
- avatar
- small
- medium
- large

The component should own:
- image resolution
- AnimatedSwitcher/fade transition
- optional subtle idle movement
- optional speech bubble
- semantics/accessibility
- reduced-motion behavior

Do not let feature screens duplicate animation code.

---

## 8. Native Flutter motion

Use Flutter-only micro-animation.

Allowed examples:
- `AnimatedSwitcher`
- `FadeTransition`
- very small `Transform.translate`
- very small `Transform.scale`
- optional short celebration particles implemented locally only if lightweight

Motion constraints:
- no perpetual energetic looping
- idle motion amplitude should be tiny
- transitions should usually be about 200–450 ms
- celebration can be slightly longer but must settle automatically
- stop/disable motion when the app is backgrounded when applicable

---

## 9. Screen integration

### Home
Default:
- `idle`
- level `companion`

First visit of the day:
- `wave`
- short greeting
- then return to `idle`

Talia should be part of the page composition, not a floating overlay covering content.

### Onboarding
- level `interactive`
- use `wave`, `speaking`, `pointRight`
- keep onboarding short
- do not make Talia block navigation

### Memorization
Suggested state flow:

```text
idle
→ listening (while verse audio is being listened to)
→ speaking (when it is the user's turn)
→ happy (good result)
OR
→ encourage (retry)
→ celebrate (session/goal completed)
→ idle
```

Do not couple the companion engine directly to speech-recognition implementation details. Feed it domain/UI events.

### Revision
- `thinking` while preparing/selecting revision item if there is a real loading/decision moment
- `encourage` for retry
- `happy` for successful completion

### Progress
- `happy` or `idle`
- contextual short progress message
- do not replace useful statistics with character-only UI

### Quran reader
- `hidden`
- no floating full character
- no automatic animation or speech bubble

### Audio recitation
- `hidden` during active focus playback unless the existing design explicitly reserves a non-intrusive help entry point

### Achievement/completion
- level `interactive`
- `celebrate`
- short modest effect
- auto-return or dismiss cleanly

---

## 10. Preferences

Add a Talia Companion section in the existing settings architecture.

Minimum settings:

```text
Talia Companion: On / Off
Motion: Full / Minimal / Off
Encouragement: Normal / Minimal / Off
```

If localization exists, add all strings to the current localization system. Do not hardcode Arabic/English UI text in widgets.

Do not add voice in this implementation unless the project already has an approved local voice feature for Talia.

---

## 11. State management responsibilities

`TaliaCompanionCubit` (or equivalent existing architecture unit) should handle presentation state and high-level rules, for example:

```text
AppOpened
FirstOpenToday
MemorizationStarted
VerseListeningStarted
UserTurnStarted
AttemptSucceeded
AttemptNeedsRetry
SessionCompleted
AchievementUnlocked
FocusReadingStarted
FocusReadingEnded
```

Avoid a god-object. Domain-specific features should publish meaningful events or invoke narrow methods; the companion should not own Quran/memorization business logic.

---

## 12. Performance

- Precache only the most likely first-use assets (`idle`, optionally `wave`).
- Load other poses on demand unless the current app architecture has a better asset-cache strategy.
- Do not decode all full-resolution PNGs at startup.
- Use `cacheWidth`/appropriate image sizing where beneficial and safe.
- Do not rebuild the entire screen when only Talia mood changes.
- Keep animation controllers scoped and disposed correctly.
- No new heavy dependency for this feature.

---

## 13. Accessibility

- Respect platform reduced-motion preferences where possible.
- Decorative Talia images should not create noisy screen-reader output.
- If Talia conveys required information, the same information must exist as accessible text.
- Ensure speech bubbles meet contrast/theme requirements.
- Talia must never be the only way to access a critical action.

---

## 14. Testing

Add tests matching the repository's test style.

Minimum coverage:

1. Asset resolver maps every `TaliaMood` correctly.
2. `hidden` presence does not render a character.
3. greeting frequency rule works.
4. motion preference `off` disables non-essential motion.
5. successful memorization event produces `happy`.
6. retry event produces `encourage`.
7. completion produces `celebrate`, then settles.
8. Quran reader integration keeps Talia hidden.
9. settings persistence works.

Add golden/widget tests only if the project already uses them or they can be added without unnecessary tooling.

---

## 15. Out of scope for v1

Do not implement now:
- Rive
- Lottie
- realtime 3D
- AI chat character
- Talia voice assistant
- lip sync
- server-side companion logic
- backend dependency for companion state
- complex gamification

Keep extension points clean for future upgrades.

---

## 16. Definition of Done

The implementation is complete only when:

- all Talia assets are registered and resolved centrally
- one reusable `TaliaCompanion` widget exists
- companion state is centrally controlled
- presence rules are respected
- Home integration is complete
- Memorization integration is complete
- Progress/Revision integration is complete where those screens exist
- Quran reader remains distraction-free
- settings to control Talia exist
- reduced motion is respected
- localization follows existing app conventions
- tests pass
- `flutter analyze` passes with no new warnings/errors
- existing app behavior remains intact

---

# MASTER CODEX PROMPT

Use this prompt from the repository root after placing this specification in the project, for example at `docs/TALIA_COMPANION_IMPLEMENTATION.md`.

```text
You are working inside the existing Talia Quran Flutter repository.

Your task is to implement the Talia Companion System described in:

docs/TALIA_COMPANION_IMPLEMENTATION.md

The character assets are located at:

assets/talia/

IMPORTANT WORKFLOW:

1. Do not start coding immediately.
2. First inspect the repository deeply enough to understand:
   - current feature/module structure
   - state management
   - dependency injection
   - routing/navigation
   - localization
   - themes/design system
   - local persistence
   - Home screen
   - Memorization flow
   - Revision/Progress flows
   - Quran reader / Mushaf screen
   - audio playback flow
   - current tests
3. Read AGENTS.md and any project-specific instructions before changing code.
4. Compare the specification with the actual repository and adapt implementation details to the existing architecture. Do not create a competing architecture.
5. Before editing, produce a concise implementation plan containing:
   - files to create
   - files to modify
   - integration points
   - risks
   - test strategy
6. Then implement the plan incrementally.
7. Preserve existing app behavior. Do not perform unrelated refactors.
8. Do not add Rive, Lottie, realtime 3D, Riverpod, or other heavy/new frameworks solely for this feature.
9. Use the existing state-management solution; if the app uses BLoC/Cubit, implement the companion using Cubit.
10. Use static transparent PNG assets plus native Flutter micro-animations only.
11. Never place Talia over Quran text. The Quran reader must remain distraction-free.
12. Centralize Talia state, asset mapping, presence rules, preferences, and anti-annoyance rules. Do not hardcode behavior separately in every screen.
13. Reuse the current localization and theme systems; no hardcoded user-facing strings.
14. Respect accessibility and reduced-motion settings.
15. Keep the implementation performant, responsive, and adaptive.

IMPLEMENTATION PRIORITY:

Phase 1 — Foundation
- asset registry/resolver
- mood model
- presence level
- preferences model/repository
- TaliaCompanionCubit/state
- reusable TaliaCompanion widget
- native Flutter transitions
- tests for core behavior

Phase 2 — Primary integration
- Home daily greeting + idle companion
- Memorization state integration
- Quran reader hidden behavior

Phase 3 — Secondary integration
- Revision
- Progress
- Onboarding where applicable
- Achievement/completion moments
- Settings controls

Phase 4 — Quality pass
- accessibility
- reduced motion
- image memory/performance
- responsive/adaptive layouts
- localization
- tests
- flutter analyze
- run relevant test suite

After each phase:
- run formatter
- run flutter analyze
- run relevant tests
- fix issues before continuing

At the end, provide:
1. summary of implemented behavior
2. exact files created/changed
3. where Talia appears and where she is intentionally hidden
4. tests added
5. commands/checks run and results
6. any remaining limitation or follow-up item

Do not mark the task complete if the companion is merely displayed as images. It must behave contextually according to the specification and presence rules.
```

---

## Recommended execution method

Do not ask Codex to implement everything in one uncontrolled pass. Give it the master prompt, review its implementation plan, then allow it to complete phases in order. If a phase causes regressions, stop there and fix them before moving to the next phase.
