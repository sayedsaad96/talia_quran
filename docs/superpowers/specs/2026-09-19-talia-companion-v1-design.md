# Talia Companion V1 — Design Specification

**Product:** Talia Quran
**Feature:** Talia Companion
**Version:** V1
**Date:** 2026-09-19
**Status:** Revised design for review against `main` at `a0db3fb` (2026-09-25). This is a design proposal, not an implementation claim. The implementation plan must follow approval of this revision.

---

## 1. Purpose

Talia Companion is a context-aware visual companion layer for Talia Quran. It is not a generic mascot, not an open AI assistant, and not a replacement for existing feature logic.

Its job is to make the product feel more guided, personal, coherent, and encouraging by presenting the right visual state, message, and action at the right moment while respecting Quran focus, user choice, privacy, performance, and existing feature ownership.

V1 serves both adults and children with the same Talia identity, but with different presence density, tone, and interaction patterns.

### Core product principle

> Central intelligence, local presentation.

Talia can be aware of multiple features, but each screen owns where Talia is rendered. There is no global floating companion overlay.

### Experience contract: useful, quiet, and optional

Talia earns attention by making an existing next step clearer. A visible character is not a reason to interrupt the user. The default adult experience is quiet; the Kids experience becomes more expressive only at a meaningful transition or when guidance is requested.

- A screen may reserve a local Talia slot, but it may render nothing. Silence and absence are successful outcomes when there is no useful action.
- Talia never opens a dialog, sheet, microphone session, or speech response on her own. Proactive presentation stays inline and never steals focus or changes the current route.
- Every proactive message must have a current, valid source, an intelligible reason, and one relevant action. No generic engagement prompt is shown to fill empty space.
- A dismissed suggestion is not immediately replaced by another. Adult Hide Today suppresses all optional Talia presentation until the next local calendar day; it does not hide existing feature controls.
- Every adult Talia surface with a suggestion offers an accessible one-step dismiss action. Long-term presence and suggestion frequency remain available in Talia Settings; no tutorial or forced setup is required to decline.
- Explicit settings override adaptation. A user can keep Talia minimal, reduce suggestions, or turn her off without losing Home, Journey, review, or other feature functions.
- A child can complete every supported activity using visible controls. Voice never becomes the only route forward.
- Do not infer that a user wants encouragement from a missed prayer, broken streak, overdue review, or long absence. Use neutral, optional continuation language.

### Default interruption budget

These are V1 product defaults to validate in usability and runtime QA, not measured claims about current behavior:

| Context | Default rule |
|---|---|
| Adult Home | One Talia message and one Talia action at most. Existing Home cards may remain; Talia must not add a competing primary action. |
| Adult non-Home | At most one proactive inline Talia suggestion per app session, only after the surface has settled and only when no higher-priority task or focus activity is active. |
| Repeated message type | Do not repeat within the same session or within 24 hours of its last presentation. |
| Dismissed suggestion | Suppress that suggestion type for seven local days unless the user explicitly opens Talia or a materially new task becomes due. |
| Kids guidance | Show on stage entry, a real instruction need, a requested Help action, or a meaningful completion. Do not repeat guidance during uninterrupted practice. |
| Notifications | Do not add a Talia notification when an existing reminder already covers the same opportunity. Existing notification preferences and quiet periods remain authoritative. |

The coordinator applies these limits before selecting copy or animation. If a limit suppresses a candidate, it emits `hidden` or a silent `minimal` state rather than substituting a lower-value prompt.

### Signature moments without extra noise

- **Adult continuity:** When an existing resumable reading or learning session is valid, Home may show Talia beside that exact continuation with one short reason and the existing route. Returning after an absence uses the same calm continuation; it does not mention missed days or invent a new goal.
- **Kids direction:** On the Journey map, an approved guide pose may draw attention to the current available stage once. At stage start, one short instruction points to the existing control. During practice, Talia settles and leaves the task visually dominant.
- **Earned celebration:** A meaningful completion may use one brief pose or motion, then settle into a static state. If the feature already shows a certificate or major reward, Talia yields or becomes part of that composition; there is never a second celebration layer.

Each moment must work with static art, reduced motion, and Talia disabled. Delight comes from relevant timing, clear direction, and visual craft rather than constant speech or movement.

---

## 2. Scope

### Included in V1

- Adult context-aware companion experience.
- Adult Home Hero companion area.
- Adult inline contextual companion outside Home.
- Kids Journey Guide experience.
- Character visual-state system with multiple expressive poses.
- Micro-animations and selected PNG frame animations.
- Context-aware message catalog.
- Adaptive adult presence using explicit deterministic rules.
- Selective Talia-aware notifications.
- Kids Voice Pilot on supported non-Quran learning screens.
- Per-child parental consent for the Kids Voice Pilot.
- Verified on-device speech recognition first on supported devices; separately consented online fallback only after provider review.
- Pre-recorded fixed Talia voice responses.
- Safe telemetry without stored child audio or full transcripts.
- Feature flags / kill switches.
- Accessibility and reduced-motion behavior.

### Explicitly excluded from V1

- Full Talia Voice Learning.
- Free-form voice chat.
- LLM-based intent understanding.
- Wake word / always-listening mode.
- Runtime TTS.
- Full recitation assessment through Talia Companion.
- Dynamic religious generation.
- Storing child voice recordings or voice history.
- Rive or Lottie.
- Global Talia overlay on every screen.
- Talia inside focused Quran Reader / Mushaf reading surfaces.

Full Talia Voice Learning remains a V2 direction.

---

## 3. Repository Source-of-Truth Rule

This specification defines product and architecture intent, not a blind implementation map.

Implementation MUST begin with a fresh Phase 0 repository audit against the current codebase. Previous audits and file names may be stale and must not be treated as authoritative.

The implementation agent must:

1. Inspect current routing, feature boundaries, Cubit/BLoC ownership, audio/recording state, lifecycle handling, user/profile scoping, localization, feature flags, notifications, and current Home/Kids implementations.
2. Reuse existing repositories, events, cubits, recommendation systems, prayer systems, learning systems, persistence stores, and analytics infrastructure when appropriate.
3. Avoid duplicating business logic that already exists.
4. Adjust adapters and integration points to the code that actually exists now.
5. Ask for manual input instead of inventing secrets, provider keys, policy choices, signing values, or release configuration.

### Verified `main` integration baseline (2026-09-25, `a0db3fb`)

This is a dated starting map, not a substitute for the fresh Phase 0 audit above. It describes code present at the stated commit, not implemented Talia Companion behavior.

| Existing owner | Current code evidence | Consequence for this design |
|---|---|---|
| Home action choice | `lib/core/journey/unified_journey_engine.dart`, `lib/features/home/domain/services/home_primary_action_resolver.dart`, `lib/features/home/presentation/pages/home_page.dart` | Talia presents or contextualizes a valid existing action. She does not replace the Journey engine, the khatmah-first Home rule, or Home's feature controls. |
| Home contextual content | `lib/features/home/domain/entities/home_contextual_slot.dart`, `lib/features/home/presentation/widgets/home_contextual_slot.dart` | Use the existing screen layout and define explicit precedence; do not insert a second simultaneous suggestion beside an active slot. |
| Kids Journey | `lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart`, `lib/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart`, `lib/features/memorization_plus/presentation/widgets/kids_progress_header.dart`, `lib/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart` | Add local Guide slots to the current Journey. The current progress header uses a kid avatar, not a Talia state renderer. |
| Quran and recitation audio | `lib/features/quran/presentation/cubits/quran_audio_player_cubit.dart`, `lib/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart`, `lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart` | Confirm current playback and capture signals in Phase 0, then expose only read-only suppression signals to Talia. Existing recitation recognition is not the Voice Pilot. |
| Profiles and routing | `lib/features/memorization_plus/domain/entities/memorization_profile.dart`, `lib/core/router/app_router.dart` | Bind consent and transient voice work to a stable child identity and actual route. Do not assume the current profile entity already stores Voice Pilot consent. |
| Notifications | `lib/core/services/notification_scheduler.dart`, `lib/core/services/notification_service.dart`, `lib/app.dart` | Reuse scheduling and normal route handling. `lib/features/prayer_companion/` is a separate prayer feature despite the shared word “Companion.” |
| Character assets | `assets/talia/*.png`, `assets/images/character/`, `pubspec.yaml` | Existing image files are candidates only. `assets/talia/` is not currently declared as a Flutter asset path or wired to a Companion renderer. |

No `lib/features/talia_companion/` implementation, Voice Pilot flow, or Talia-specific kill switches were found in this baseline. Recheck before planning or implementation; absence is not evidence that related generic infrastructure is absent.

---

## 4. Architecture

### Chosen approach

**Central Companion Coordinator + Feature Adapters + Local Presentation Slots**

```text
Existing feature state
        ↓
Feature adapters
        ↓
Talia context snapshot
        ↓
Talia Companion Coordinator
        ↓
Suppression + priority + timing + presence policies
        ↓
Talia view state
        ↓
Local screen-owned Talia slot
```

### Package boundary

Talia Companion is a standalone feature, expected conceptually under:

```text
lib/features/talia_companion/
```

Exact folder names must follow the current project conventions after the fresh audit.

### Important boundary

Talia reads feature state through adapters. Existing features should not acquire Talia-specific domain behavior unless an existing generic interface already supports it.

For example, Prayer owns prayer logic. Memorization owns memorization logic. Daily Question owns Daily Question logic. Talia only decides whether and how an already-valid opportunity should be presented.

There are two different decisions. Existing feature and Home systems decide **what work is valid and where it leads**. The Companion coordinator decides **whether Talia may present that work, and in what visual form**. Companion priority must never recalculate due reviews, select a different khatmah destination, or replace the Home primary-action resolver. Adapters carry stable candidate IDs, destination routes, freshness/expiry, and brief reason codes; they do not copy entire feature states. If an existing candidate expires or changes owner, the Talia view state is discarded and resolved again.

The first implementation should use a small, testable coordinator fed by explicit context updates. Do not add a broad app-wide event bus just for Talia. Where an existing Cubit has no reliable public audio or recording signal, Phase 0 must identify the smallest read-only bridge and its lifecycle before coding it.

### No global overlay

Presentation is local to each eligible surface:

- Adult Home → Hero Companion Area.
- Adult non-Home screens → Compact Assist Strip / inline contextual slot.
- Kids Journey → Journey Guide slot.
- Supported Kids learning screens → Guide / Voice Pilot slot.
- Quran Reader → no Talia presentation.

Screen owners reserve and dispose their own slots. A route that is offstage, in an inactive indexed tab, or behind a focused Quran surface cannot keep a Talia ticker or delayed prompt alive. A local slot must remain usable with the character hidden, images missing, or motion disabled.

---

## 5. Core Models

### TaliaCompanionState

The visible state must describe more than mood.

Conceptually it contains:

```text
surface
presence
visualState
contentId
primaryAction
secondaryAction (only where explicitly allowed)
interactionMode
suppressionReason
motionMode
```

### Surface

Defines where Talia may render.

Example conceptual values:

```text
adultHomeHero
adultInline
progressInline
kidsJourneyGuide
kidsStageGuide
kidsVoicePilot
achievement
none
```

### Presence

```text
hidden
minimal
companion
guide
```

- `hidden` — nothing rendered.
- `minimal` — quiet character presence with little or no message.
- `companion` — character plus contextual assistance.
- `guide` — stronger guidance role, mainly for Kids Journey / instruction moments.

### Visual state

Examples:

```text
idle
resting
wave
guide
listening
thinking
happy
encourage
celebrate
reading
attention
speaking
success
retry
```

### Interaction mode

Visual state and interaction state are separate.

For example, `listening` as a visual pose does not by itself mean the microphone is actively recording.

Conceptual interaction modes may include:

```text
none
voiceListening
voiceRecognizing
voiceResponding
quickActionsOpen
```

---

## 6. Context Snapshot

The coordinator must work from a concise context snapshot instead of directly reaching into many widgets.

Conceptual inputs include:

- Active route / surface.
- App lifecycle state.
- Adult vs child profile.
- Current child profile identity.
- Quran Reader active state.
- Quran audio state.
- User recording state.
- Kids Voice Pilot state.
- Memorization / learning context.
- Due review context.
- Resumable reading or memorization context.
- Prayer context.
- Daily Question availability.
- Existing recommendation / SmartCoach output.
- Kids Journey state.
- Feature rollout flags.
- User preferences.
- Adult adaptive presence state.
- Temporary cooldowns.
- Hide Today.

Adapters should expose only the data needed by Talia, not leak whole feature internals.

Each snapshot must also carry a monotonically changing context revision and stable profile/surface identity. A coordinator result is applied only if its revision still matches the active route, profile, and source candidate. This applies to delayed prompts and animation completion as well as voice work. Unknown audio, recording, profile, or route state is treated as suppressed for speech and proactive output until the signal becomes trustworthy.

---

## 7. Priority Engine

Priority resolves from highest to lowest:

```text
P0  Feature disabled / user disabled
P1  Quran sacred focus
P2  App lifecycle / invisible surface
P3  Quran audio / user recording / voice privacy
P4  Explicit user interaction
P5  Active learning / memorization context
P6  Important due task
P7  Completion / achievement
P8  Limited proactive recommendation
P9  Silent minimal presence
P10 Hidden ambient state
```

### Non-negotiable principles

> Suppression beats engagement.
> User intent beats adaptation.
> Relevance beats visibility.
> One Talia moment at a time.

### Quran sacred focus

Focused Quran reading surfaces always win.

When Quran Reader / Mushaf / Kids Quran Reader is active:

```text
presence = hidden
```

No recommendation, celebration, greeting, prayer context, Voice Pilot, or companion bubble may override this.

This includes screen transitions into a Quran route and reader surfaces embedded within another route. The router path alone is insufficient if the visible screen can enter a focused Mushaf mode without navigation. The screen owner is the final authority for whether its Talia slot is eligible.

### Lifecycle

When the app becomes inactive/backgrounded:

- Stop active character animation.
- Stop frame loops.
- Cancel invalid timers.
- Suspend proactive presentation.
- Cancel stale voice work if context is no longer valid.

On resume, recalculate context rather than replaying previous transient states.

### Audio / recording

Quran audio and user recording suppress automatic Talia speech and proactive behavior.

Audio priority:

```text
Quran recitation / user recording
>
Voice input
>
Talia prerecorded response
>
Ambient companion behavior
```

Stopping speech is immediate; passive static presence may remain only where the screen owner permits it and where it does not cover playback controls. Recording or audio state that cannot be observed reliably blocks proactive Talia speech. Talia never starts or resumes Quran playback herself.

---

## 8. Adult Experience

### 8.1 Home Hero

The Adult Home Hero is the primary identity-defining surface for Talia.

Rules:

- Calm, premium, mature composition.
- Talia is visually integrated into the Hero, not floating over the page.
- One message only.
- One primary CTA only.
- No permanent speech bubble.
- No stacked recommendations.

These limits apply to **Talia's own Hero composition**. They do not silently remove or rewrite existing Home feature cards. Home currently resolves a primary action separately, including khatmah continuation priority and the Unified Journey action. Talia's Hero may wrap or accompany the action selected by that existing rule; it must not pick a competing CTA. If an active Home contextual slot already offers the same task, deduplicate by candidate ID or route and show only the higher-value presentation.

When there is no valid action, use a silent minimal character state or no character. Do not show a greeting just to occupy the Hero. Opening Home never triggers spoken audio or a dialog.

Core rule:

> One message. One action. One reason to care.

Candidate sources may include:

- Due review.
- Continue reading / memorization.
- Prayer context.
- Daily Question.
- Quran Learning Journey.
- Existing SmartCoach / recommendation output.

Talia does not create a second recommendation engine. It arbitrates between existing valid candidates.

### 8.2 Adult Inline Companion

Outside Home, the approved design direction is:

**Compact Assist Strip**

It appears only when useful and sits inside the normal screen layout.

It must not become a second Hero or a global navigation system.

The strip is opt-in by relevance: it appears only for a screen-owned, current task that the user can act on there. It does not appear in Quran reading, during recording, on a route whose host has not declared a slot, or immediately after the user dismissed a suggestion. The host keeps its normal navigation and controls when Talia is hidden.

### 8.3 Adult quick interaction

Tapping Talia may show contextual actions.

The first actions may change with context, such as:

- Start Review.
- Continue Today.
- Continue last position.
- Open Daily Question.

Fixed utilities may include:

- Help.
- Hide Today.
- Talia Settings.

Quick Actions must remain small and focused.

---

## 9. Adult Adaptive Presence

Adults start at `minimal` unless their explicit setting says otherwise.

No hidden engagement score is used.

Promotion is deterministic and testable. Example design rule:

```text
At least 3 useful Talia interactions
across at least 2 separate app sessions
AND no recent hide/reduce signal
→ eligible for minimal → companion promotion
```

Exact thresholds may be tuned during implementation and usability testing, but the model must remain explicit rather than opaque.

Positive signals may include:

- Used Continue Today.
- Used Talia Help.
- Used a contextual Talia action.
- Completed a task after a Talia action.
- Repeatedly opened Talia actions voluntarily.

Reduction signals may include:

- Hide Today.
- Repeated dismissals.
- Less Often preference.
- Manual Minimal selection.

### Demotion is faster than promotion

Talia must earn stronger presence. User resistance should reduce presence quickly.

### Manual choice always wins

If the user manually selects Minimal, adaptation must not promote to Companion.

If the user manually selects Companion, adaptation must not demote it except for normal suppression contexts.

---

## 10. Kids Experience

### 10.1 Journey Guide

Talia is an active Journey Guide in Kids Journey.

She is visibly present in:

- Journey map.
- Stage start.
- Instructions.
- Important progression moments.
- Selected celebrations.

Presence is strongest during transition and guidance moments, then reduces during focus activities.

Typical mapping:

```text
Journey Map       → guide
Stage Start       → guide
Instructions      → guide
Simple exercise   → companion
Achievement       → companion / celebrate
Quran Reader      → hidden
Quran playback    → suppressed
User recording    → suppressed
```

The current Kids Home and Journey already have progress, mission, and stage UI. Guide presentation belongs in those screen-owned layouts, especially at stage selection and instruction transitions. Talia must not replace the child's progress avatar by accident or obscure the existing mission CTA. The stage or mission Cubit remains authoritative for progression; a Talia celebration never advances a stage itself.

Default behavior is one brief guide moment on entry to a new stage or requested Help, followed by a quiet/static state during exercise. Re-entering the same stage in one session does not replay the introduction. The child can dismiss guidance without losing stage instructions or buttons.

### 10.2 Kids Voice Pilot

The Voice Pilot is a limited V1 experiment designed to validate the path toward Talia Voice Learning V2.

It is not an open assistant.

**Rollout gate:** The visual Companion may launch without the Voice Pilot. Voice Pilot remains behind its own default-off kill switch until the supported device recognizer, consent storage, audio arbitration, navigation cancellation, and visual fallback pass runtime checks. The current recitation recorder is a separate feature; its microphone permission or success does not grant Voice Pilot consent or prove offline recognition.

#### Supported scope

Only on supported Kids Journey and non-Quran learning screens, such as:

- Journey map.
- Stage selection.
- Instructions.
- Simple exercises.
- Step navigation.

Completely unavailable in:

- Quran Reader.
- Kids Quran Reader.
- Quran playback contexts.
- Child recitation recording contexts.

The microphone control should not render at all in unsupported / suppressed contexts.

It also does not render for a child whose current consent version is missing or revoked, while the active child identity is unresolved, or while Quran playback or recitation capture is active. A parent-facing entry may explain why voice is unavailable; the child-facing task still offers ordinary buttons.

#### Interaction model

Push-to-Talk only.

```text
Idle
↓ press / hold
Listening
↓ release
Recognizing
↓
Intent matched → perform action → short approved voice response
OR
Unknown → retry
```

No wake word. No always-listening mode.

The microphone has an explicit pressed/listening state and a clear release or cancel affordance. If no recognized command is produced, the child sees a calm retry choice; there is no automatic repeated microphone activation. Talia speaks only after a supported action has been validated and only if higher-priority audio is idle. If audio output cannot play safely, the action still completes with visual feedback.

#### Closed intents

V1 supports only:

```text
start
next
repeat
back
help
finish
```

Natural Arabic variations may map into these intents, but the intent set remains closed.

#### Language

V1 Voice Pilot is Arabic only.

Supported phrasing style:

- Simple Modern Standard Arabic.
- Simple Egyptian Arabic variants.

Architecture should not hard-code Arabic so English can be added later.

#### Retry / fallback

Recognition failure behavior:

- Attempt 1 fails → short fixed retry prompt.
- Attempt 2 fails → stop trying and show visual command buttons.
- Never guess an uncertain command.

Example retry copy concept:

> ممكن تقولها تاني؟

#### Recognition architecture

Hybrid recognition:

1. Use a verified on-device recognition path first on devices where the platform/provider actually guarantees it. The presence of `speech_to_text` in the current recitation flow is not proof of this guarantee.
2. If confidence is insufficient and online fallback is separately consented, configured, and available, use online recognition. No online provider or retention behavior is assumed by this design.
3. If still unknown / unavailable, use visual fallback.

No LLM is required for V1 intent classification.

If the selected platform cannot distinguish on-device from network-backed recognition or cannot provide a reliable confidence/alternative signal, do not silently label it “on-device” or execute a guessed command. Gate voice off on that platform until the capability and privacy behavior are verified; keep the visual Companion usable. The implementation plan must name the recognizer abstraction and its actual capability checks before enabling the pilot.

#### Response voice

Talia uses one fixed approved AI voice.

Responses are generated ahead of time and bundled as audio assets.

No runtime TTS in V1.

---

## 11. Character System

Talia must never be implemented as one repeated image.

She is a character state system composed of multiple expressive poses plus motion behavior.

### Static / pose states

Recommended V1 set:

```text
idle
guide
thinking
happy
encourage
reading
resting
attention
speaking
retry
success
```

### Animated sequence states

Approved PNG-sequence animation for:

```text
wave
listening
celebrate
```

Optional later, only if asset quality justifies it:

```text
encourage
speaking
```

### Asset organization concept

```text
assets/talia/
├── poses/
│   ├── talia_idle.png
│   ├── talia_guide.png
│   ├── talia_thinking.png
│   ├── talia_happy.png
│   ├── talia_encourage.png
│   ├── talia_reading.png
│   ├── talia_resting.png
│   ├── talia_attention.png
│   ├── talia_speaking.png
│   ├── talia_retry.png
│   └── talia_success.png
└── animations/
    ├── wave/
    ├── listening/
    └── celebrate/
```

The domain asks for a semantic character state, never a frame file name.

Example:

```text
TaliaVisualState.wave
```

The renderer chooses assets, frame timing, looping, transition behavior, and reduced-motion fallback.

**Current repository distinction:** `assets/talia/` contains individual candidate images such as `talia_idle.png`, `talia_wave.png`, `talia_listening.png`, and `talia_celebrate.png`; it does not currently contain the proposed frame-sequence directory structure. `pubspec.yaml` does not declare `assets/talia/`, and the current Kids Journey uses a kid avatar. These files require visual identity review, asset declaration, and screen integration before they count as implemented Companion states. Do not infer a complete pose or animation set from filenames.

The renderer contract maps semantic states to an approved pose, optional short motion, and an explicit static/reduced-motion fallback. Missing optional motion must never make a character state unusable. The visual release may start with approved static poses and restrained micro-motion; the selected PNG sequences are an acceptance item for the full V1 character scope after asset and runtime review, not a reason to ship unreviewed frames.

### Asset consistency

All Talia assets must preserve:

- Face proportions.
- Skin tone.
- Hair / head-covering identity as defined by the approved character.
- Outfit identity.
- Body proportions.
- Illustration/render style.
- Lighting family.
- Camera-angle family.
- Transparent background.
- Consistent visual scale.

Different states must not look like different characters.

---

## 12. Motion System

Every visible Talia state must define both its visual pose and motion behavior.

> A Talia state is not complete with an image asset alone.

### Motion layers

#### Layer 1 — Static pose + micro-motion

Used for most states:

- Breathing.
- Fade.
- Small scale settle.
- Small translation.
- Subtle pulse.
- Small tilt / sway.

#### Layer 2 — Short PNG sequences

Used only for selected expressive moments:

- Wave.
- Listening.
- Celebrate.

#### Layer 3 — State transitions

Examples:

```text
idle → guide
listening → thinking
thinking → success
success → idle
```

Use short crossfades / scale / translation to avoid abrupt image swaps.

### Motion targets

Design timing ranges:

```text
Micro transition      180–280 ms
Guide entrance        250–400 ms
Wave animation        0.8–1.2 s
Success motion        0.5–0.9 s
Celebrate             1.2–1.8 s
Listening loop        ~0.7–1.0 s
Idle breathing        ~3–4 s
```

These are tuning targets, not immutable constants.

### Motion rules

- Wave is one-shot, then returns to a calmer state.
- Celebrate is one-shot.
- Listening may loop only while Push-to-Talk is active.
- Thinking uses subtle motion.
- Idle loops must be nearly unnoticeable.
- Expressive gestures only happen for a real context reason.
- No long animation queues.
- Current context wins over replaying old animation events.
- No automatic idle loop is required. If one is used, it must pause after its short cycle and must not restart simply because a widget rebuilds.
- Focus moments reduce motion.
- Transition moments may use stronger motion.

### Immediate interruption

Active character motion must stop immediately when any of these become true:

- Quran Reader opens.
- Quran audio starts.
- User recording starts.
- App backgrounds.
- Talia is disabled.
- User hides Talia.
- Profile changes invalidate current context.

### Conflict order for visible character control

```text
Hidden / suppression
>
Active Voice Listening
>
Explicit user interaction
>
Required learning guidance
>
Celebration
>
Contextual suggestion
>
Ambient presence
```

### Reduced motion

Respect platform reduced-motion settings.

Fallback behavior may include:

```text
PNG sequence → static final pose
bounce → fade
translation → crossfade
```

Functionality must never depend on animation.

### Performance

- Avoid long frame sequences.
- Avoid high-FPS character animation.
- Prefer approximately 8–12 frames for short sequences where suitable.
- Load animation assets only when needed.
- Do not precache all Talia animations at startup.
- Stop tickers in inactive/offstage routes.
- Decode images close to actual display size.
- Do not run hidden character loops behind an indexed navigation stack.

---

## 13. Content & Personality System

### One identity, two tones

#### Adult

- Calm.
- Concise.
- Mature.
- Non-patronizing.
- Low emotional intensity.

#### Kids

- Warmer.
- Simpler.
- More encouraging.
- Shorter instructions.
- More expressive, but not childish or noisy.

### Finite message catalog

V1 does not generate free text at runtime.

Talia uses reviewed message IDs, for example:

```text
adult.review_due.short
adult.continue_last_session
adult.daily_question.ready
kids.stage.start
kids.stage.retry
kids.voice.retry_once
kids.voice.fallback_buttons
```

The coordinator selects message IDs. Localization resolves the actual copy.

### Silence is valid

Talia may be visually present without text.

Examples:

- Idle may show no message.
- Listening shows no automatic bubble.
- Thinking may use no text or one tiny status label.
- Happy motion may be enough without copy.

### Adult brevity rule

Adult companion copy should generally follow:

```text
Short headline
Optional one-line support
One CTA
```

### Kids language rule

- One idea at a time.
- Short sentences.
- Direct verbs.
- Familiar vocabulary.
- Simple MSA + supported Egyptian variants for Voice Pilot phrase recognition.

### Message rotation

Some message types may have 2–4 approved variants to reduce repetition.

Rotation must be controlled, not unrestricted random generation.

The system may remember the last variant to avoid immediate repetition.

### Cooldowns

Use both:

- Talia presentation cooldown.
- Message-type cooldown.

Examples:

- Greeting only after an explicit Talia interaction; it is not an automatic session opener.
- Review reminder not repeated multiple times in one session.
- Prayer suggestion not repeated every few minutes.
- Ignored Help suggestion should not reappear immediately.

The default interruption budget in Section 1 is the source of truth for V1 timing. Message rotation cannot bypass a message-type cooldown: changing the wording of the same suggestion does not make it a new opportunity. A new, materially different due task may bypass the seven-day dismissal of an older task only when the existing feature owner identifies it as a new candidate.

### Religious governance

Talia must not dynamically generate:

- Quran verses.
- Hadith.
- Tafsir.
- Fatwas.
- Religious rulings.
- Specific claims of reward or punishment.
- Ungoverned religious advice.

Religious content must come from reviewed fixed content or an existing governed feature source.

### No guilt language

Especially for:

- Prayer.
- Quran reading.
- Review.
- Memorization.
- Streaks.

Avoid blame, shame, or coercive guilt.

Prefer gentle continuation language, such as:

> تحب تبدأ الآن؟

or

> نقدر نكمل من آخر نقطة.

### Persona boundary

Talia V1 is:

**Companion + Guide + Encourager**

Talia V1 is not:

**Mufti + therapist + open chatbot + general-purpose teacher**

---

## 14. Voice Response Catalog

Voice responses use their own small finite catalog.

Conceptual IDs:

```text
voice.start_ack
voice.next_ack
voice.repeat_ack
voice.back_ack
voice.help_ack
voice.finish_ack
voice.retry_once
voice.fallback
voice.unavailable
```

Files may conceptually live under:

```text
assets/talia/voice/ar/
```

The final naming convention should follow current asset conventions.

Voice clips must be short, fixed, reviewed, and bundled.

---

## 15. Celebration Policy

One celebration channel at a time.

If an existing Certificate Dialog or other major completion UI owns the moment, Talia must yield.

Allowed patterns:

- Talia-led short celebration when no stronger channel exists.
- Talia integrated into a certificate composition.
- Adult subtle acknowledgment for routine success.

Disallowed pattern:

```text
certificate dialog
+ Talia overlay
+ confetti overlay
+ extra banner
```

The goal is hierarchy, not stacking.

---

## 16. Notifications

Talia-aware notifications are selective.

Suitable contexts may include:

- Due review.
- Continue from last position.
- Daily Question.
- Gentle prayer-related context.
- Meaningful milestone / return-to-journey context.

System/technical notifications remain neutral, including:

- Sync failure.
- Permission warnings.
- Internal errors.
- Technical system state.

Opening a Talia-aware notification should navigate through the normal application route. Talia then recalculates context. Notification payloads should not directly force a stale companion state.

Talia-aware wording is an optional presentation of an existing valid reminder, not an independent second schedule. Deduplicate by feature opportunity and scheduled window before delivery. Reuse the current notification service, preferences, quiet periods, and route handling; do not introduce a second notification ID space or treat `PrayerCompanionController` as the Talia Companion coordinator. A muted or disabled reminder stays muted even if Talia's visual presence is enabled. Notification copy must state the action plainly and must not impersonate a personal message from a child or imply that Talia observed private behavior.

---

## 17. Persistence

Use a hybrid model.

### Account / profile-scoped persistent state

Examples:

- Talia presence preference.
- Suggestion-frequency preference.
- Adult adaptive presence state.
- Per-child Voice Pilot consent.
- Per-child online fallback consent.

Persist Voice Pilot consent in a dedicated guardian-managed store keyed by the stable child identity and consent version. The current `MemorizationProfile` describes path and guardian linkage; it does not itself establish Voice Pilot consent. If a stable child identity is unavailable, voice stays disabled. Keep adult presence settings scoped to the appropriate account/profile identity and define guest behavior during Phase 0; never let one signed-in account inherit another account's Talia settings from device preferences.

### Device-local / transient state

Examples:

- Hide Today.
- Cooldowns.
- Session state.
- Current animation state.
- Voice retry count.
- Temporary request identifiers.

Child profiles must be isolated from each other.

Define `Hide Today` by the device's local calendar date, reset at the next local day, and clear it on account switch. Store only the minimum cooldown keys required for deterministic behavior. On logout, child unlink, or account-data reset, remove the associated Companion preferences, consent, cooldowns, and queued voice work through the existing data-reset path. Do not persist a raw speech result or a voice request payload as transient state.

---

## 18. Privacy & Parental Consent

### Core privacy rule

> No stored child voice. No voice history. No full transcripts. No training use in V1.

### Per-child consent

Consent is independent for each Child Profile.

Enabling Voice Pilot for Child A does not enable it for Child B.

### Versioned consent

Do not model consent as a single Boolean only.

Conceptually preserve:

```text
consentVersion
acceptedAt
onlineFallbackAllowed
```

If V2 materially changes data use, prior consent must not be assumed to cover the new behavior.

Consent must identify the child, the guardian action, the text/version accepted, and whether online fallback was separately allowed. Revoking consent takes effect immediately for that child: hide the microphone, cancel in-flight recognition and playback, discard pending results, and clear related transient state. A guardian's approval for one child is never copied during profile switching or child linking. The first rollout must provide a visible path to review and revoke this choice.

### Just-in-time permission

Do not request microphone permission during general app onboarding.

Recommended flow:

```text
Parent opens Voice Pilot settings / entry
→ reads consent
→ approves
→ child attempts first Push-to-Talk
→ microphone permission requested
```

### Online fallback privacy

If online recognition is used:

- Send only the temporary audio required for recognition.
- Do not persist the audio in the app.
- Do not create voice history.
- Do not use the recording after recognition completes.
- Follow the chosen provider’s actual retention/privacy behavior and disclose it accurately before release.

Provider-specific legal/privacy claims must not be invented before a provider is selected and verified.

Until a provider, data flow, retention policy, and child-consent copy have been reviewed, online fallback remains disabled. Network connectivity alone is never authorization to upload audio. If these prerequisites are not met during V1, ship the visual fallback and supported verified local path without online fallback.

---

## 19. Recognition Confidence & Safety

The intent classifier must prefer uncertainty over incorrect execution.

If recognition is ambiguous:

```text
unknown
```

not “closest likely intent”.

No guessing.

### Technical failure is not child failure

Examples:

- Microphone error.
- Permission denied.
- Recognizer unavailable.
- Network timeout.
- Provider failure.
- Audio engine failure.

These must map to a neutral technical state, not encouragement implying the child made a mistake.

Example concept:

> الصوت مش متاح دلوقتي. استخدم الأزرار.

---

## 20. Async Safety & Cancellation

All Talia async work must be cancellation-aware.

Especially:

- Speech recognition.
- Online recognition fallback.
- Prerecorded voice playback.
- PNG animation sequences.
- Delayed proactive prompts.
- Cooldown timers.

Cancel invalid work on:

- Route change.
- Profile switch.
- App background.
- Quran focus.
- Logout.
- Feature disable.
- Consent revocation.

### Stale result protection

A Voice Pilot request should carry enough context to reject old results, conceptually:

```text
requestId
childProfileId
surface
stage/session context
```

If recognition completes after the originating context is gone, discard the result.

Never execute a stale `next`, `back`, or other command on a different screen.

---

## 21. Child Profile Switching

On Child A → Child B switch:

- Cancel active voice recognition.
- Stop Talia voice playback.
- Clear retries.
- Clear transient child-specific state.
- Load Child B consent and preferences.
- Re-evaluate Talia context.

No transient Voice Pilot state may leak across profiles.

---

## 22. Offline Behavior

When offline:

- Use on-device recognition if available.
- If recognition fails or is unavailable, use visual fallback.
- Do not present a large error solely because online fallback is unavailable.

The Voice Pilot should remain partially usable offline when the device recognizer permits it.

---

## 23. Safe Telemetry

Telemetry exists to measure whether the Kids Voice Pilot is useful enough to inform V2.

Allowed event concepts:

```text
voice_pilot_started
intent_recognized
intent_unknown
recognition_retry
visual_fallback_used
online_fallback_used
voice_latency_bucket
voice_cancelled
```

Allowed properties may include:

```text
intent
recognitionPath
retryCount
latencyBucket
fallbackToButtons
```

Do not record:

```text
rawAudio
audioFilePath
fullTranscript
spokenPhrase
childName
```

If analytics requires identifiers, prefer internal pseudonymous identifiers over child names.

The current repository does not establish a dedicated Companion event pipeline in this design baseline. Before collecting events, Phase 0 must identify an approved existing analytics path or choose minimal local aggregate counters. The Voice Pilot must not create a new third-party tracker merely to satisfy a success metric. Telemetry is optional to using the feature, and raw recognized text is never logged, attached to errors, or used as an event property. If no approved telemetry path is available, label V1 voice learnings as qualitative/runtime findings rather than claiming measured pilot outcomes.

### Adaptive-presence telemetry

May measure events such as:

- Talia contextual action used.
- Help used.
- Hide Today used.
- Suggestion dismissed.
- Presence promoted / demoted.

Do not turn this into a broad behavioral profiling system.

---

## 24. Feature Flags / Kill Switches

Talia Companion and Kids Voice Pilot must be independently controllable.

Conceptually:

```text
TALIA_COMPANION_ENABLED
TALIA_KIDS_VOICE_PILOT_ENABLED
```

The exact flag system must reuse the project’s current rollout/config infrastructure where possible.

The Voice Pilot must be disableable without disabling the visual companion.

Both switches default off before their respective rollout gates. Disabling the visual Companion removes local Talia presentation and cancels its motion/timers; disabling Voice Pilot additionally cancels recognition/playback and hides the mic without affecting visual Companion or existing recitation features. Flag state is evaluated again on app resume and profile switch. The existing Unified Journey flag is not a Talia kill switch, and disabling Talia must not disable the Home Journey action.

---

## 25. Error Handling Matrix

| Failure type | Behavior |
|---|---|
| Recognition unknown | Retry up to two attempts, then visual buttons |
| Technical recognition failure | Neutral technical fallback, then visual buttons |
| Permission denied | Explain permission path; keep visual controls usable |
| Online fallback unavailable | Continue with on-device / visual fallback |
| Route changed during recognition | Cancel / discard result |
| Profile switched | Cancel / clear transient state |
| Quran focus begins | Stop / hide immediately |
| Quran audio starts | Stop Talia voice and proactive output |
| User recording starts | Stop Talia voice; suppress companion speech |
| Consent revoked | Cancel voice work, hide mic immediately |

---

## 26. Accessibility

- Respect system reduced-motion preference.
- Do not make functionality depend on animation.
- Ensure readable contrast for companion copy.
- Maintain appropriate touch targets.
- Maintain RTL semantics for Arabic.
- Character direction / guide gestures must mirror semantically where needed rather than relying on asset file names such as `pointRight`.
- Voice Pilot must always have a visible non-voice fallback.

---

## 27. Testing Strategy

Implementation must include tests at several levels.

### Unit tests

Test pure policies and resolvers, including:

- Suppression precedence.
- Priority resolution.
- Adult adaptive presence promotion/demotion.
- Manual preference override.
- Message cooldowns.
- Message rotation.
- Voice intent classification.
- Retry count behavior.
- Stale request rejection.
- Per-child consent isolation.
- Presentation budget, dismissal, Hide Today boundary, and message-type cooldown precedence.
- Existing Home candidate deduplication and preservation of khatmah/Unified Journey ownership.
- Profile, route, source-candidate, and context-revision invalidation for delayed results.

### Widget tests

Validate:

- Home Hero renders one message / one CTA.
- Adult inline companion remains compact.
- Talia is not rendered in Quran Reader.
- Voice mic is absent on unsupported screens.
- Reduced-motion fallback.
- Visual fallback after second failed voice attempt.
- Certificate/celebration hierarchy.
- Existing Home controls remain available when Talia is hidden or disabled.
- No automatic dialog, speech, or microphone activation when opening an eligible screen.
- Kids Guide can be dismissed without losing stage instructions or visual actions.

### Integration / runtime tests

Use real runtime testing on supported Android devices/emulators to verify:

- Route transitions.
- Indexed-stack/offstage behavior.
- Audio suppression.
- Recording suppression.
- Voice cancellation on navigation.
- Profile switching.
- App background/resume.
- Mic permission denied / allowed flows.
- Offline behavior.
- Low-confidence recognition.
- Online fallback path after provider integration.
- Animation smoothness.
- Memory and image decode behavior.
- No hidden frame loops on inactive tabs.
- Adult repeated visits and dismissals obey the presentation budget across sessions and local-day rollover.
- Existing Home primary-action selection is unchanged with Companion on and off.
- Voice Pilot cannot inherit recitation microphone use or another child's consent.
- A mid-flight flag change or consent revocation stops voice work and rejects the result.

### Performance acceptance

Do not approve performance based on code inspection alone.

Measure actual runtime behavior, including:

- Frame jank during Talia animations.
- Memory growth while changing states.
- PNG sequence loading behavior.
- Offstage animation activity.
- Home Hero scrolling performance.
- Voice latency buckets.

---

## 28. V1 Success Criteria

Talia Companion V1 is successful when:

1. Adults perceive Talia as helpful and calm, not noisy or childish.
2. Kids experience Talia as a recognizable Journey Guide.
3. Talia never interrupts focused Quran reading.
4. Character states visibly change with context rather than repeating one image.
5. Talia has meaningful motion without becoming a heavy animation system.
6. Adult Home shows one high-value companion action at a time.
7. Adult inline appearances remain restrained.
8. Voice Pilot executes only closed supported intents.
9. Voice uncertainty falls back safely instead of guessing.
10. No child audio or full transcript is stored by the app.
11. Per-child consent and state isolation work correctly.
12. Voice Pilot evidence informs V2 through an approved privacy-safe telemetry path or explicitly labeled qualitative/runtime findings; no audio or transcripts are collected to fill a metric gap.
13. Talia integrates existing systems instead of duplicating their business logic.
14. Runtime performance remains acceptable on the project’s target Android devices.
15. Existing Quran, memorization, prayer, Daily Question, Share Good, and other features remain authoritative for their own logic.

### Experience acceptance gates

Before enabling visual Companion for adults, observe representative Home, return-to-app, review-due, Quran-reading, and dismissal journeys. Participants should be able to explain why a Talia action appeared and complete the same task with Talia off. Treat repeated dismissals, accidental taps, unclear action ownership, or descriptions of Talia as intrusive as reasons to reduce presence or revise placement before widening rollout. Do not declare the experience “calm” from implementation inspection alone.

For Kids, observe first-time and repeat Journey visits, stage instructions, a failed attempt, and a completed stage. The guide should help a child find the next step without delaying it, repeating the same prompt, covering controls, or speaking without a deliberate voice action. Validate with guardians that consent and revocation are understandable before enabling Voice Pilot.

Runtime acceptance also requires zero Talia presentation on focused Quran surfaces, no proactive speech over Quran audio or recording, no stale command execution after navigation/profile changes, and no hidden/offstage animation loop in measured test scenarios. Record actual device observations and performance measurements; this specification does not invent success percentages or frame/memory targets.

---

## 29. Implementation Sequencing Constraints

The future implementation plan should prefer incremental integration rather than a big-bang rollout.

A likely safe sequence is:

1. Fresh Phase 0 repository audit, including the current Home action owner, child identity, route visibility, audio/recording signals, notification preferences, asset quality, and recognizer capabilities.
2. Semantic state, source-candidate adapters, suppression policy, context revision, and visual kill switch. Verify that turning Talia off leaves existing feature decisions unchanged.
3. Approved static asset mapping, renderer fallback, and local slot lifecycle. Add only the assets actually used to `pubspec.yaml`.
4. Adult Home integration with the existing primary-action resolver; then restrained adult inline slots. Verify frequency and dismissal behavior before expansion.
5. Kids Journey Guide in existing Home/Journey/stage layouts; validate instructions, control access, and quiet repeat visits.
6. Account/profile-scoped preferences, adult adaptive presence, finite localized catalog, and message cooldowns.
7. Selected PNG sequences, accessibility, indexed-tab/background cancellation, and measured performance. Complete the V1 visual-character acceptance scope only after asset review.
8. Selective notification copy through existing delivery and preferences, with opportunity deduplication.
9. Separate Voice Pilot consent store and recognizer/audio abstraction; prove supported on-device behavior or keep the pilot off on unsupported devices.
10. Closed-intent actions, visual fallback, pre-recorded responses, cancellation, and child isolation. Integrate online fallback only after provider/privacy review and separate guardian consent.
11. Privacy-safe telemetry only through an approved path, followed by runtime QA, usability review, and independent kill-switch validation before widening either rollout.

This sequence is design guidance only. The implementation plan must be derived from the freshly audited repository.

---

## 30. Deferred V2 Direction

Talia Voice Learning V2 may build on the V1 pilot, but V1 must not prematurely implement the V2 system.

V2 may explore:

- Broader guided voice learning flows.
- More language support.
- Richer learning intents.
- Recitation-oriented voice learning where religious, privacy, and accuracy requirements are satisfied.
- More sophisticated context continuity.

V2 must receive its own design process and consent/privacy review.

---

## 31. Final Non-Negotiables

1. Talia is a feature, not a generic global core utility.
2. Central decision-making; local presentation.
3. No global floating overlay.
4. Quran focus always wins.
5. No single repeated character image.
6. Every visible character state defines both pose and motion.
7. Multiple expressive poses plus micro-motion plus selected PNG-sequence animations.
8. Adult motion and language stay restrained.
9. Kids Journey gets stronger guide presence.
10. Full Voice Learning is deferred to V2.
11. V1 Voice Pilot is closed-intent, Push-to-Talk, Arabic-first.
12. Verified on-device recognition first on supported devices; online fallback only under approved conditions. Voice stays off where neither path meets the privacy and confidence gates.
13. No runtime TTS.
14. No stored child voice or full transcripts.
15. Consent is per child and versioned.
16. No guessing uncertain voice commands.
17. Technical failure is never treated as child failure.
18. One celebration channel at a time.
19. Religious content is finite and governed.
20. User preference overrides adaptation.
21. Offstage/background animations stop.
22. Talia does not duplicate existing feature business logic.
23. Fresh repository audit is mandatory before implementation.
24. A valid existing feature action remains authoritative; Talia does not create another Home primary-action decision.
25. Proactive presentation obeys the V1 interruption budget, and dismissing Talia never removes essential controls.
26. Visual Companion and Voice Pilot have separate rollout gates; an unverified recognizer or consent path keeps Voice Pilot off.

---

## 32. Prior Approval and Revision State

The following design areas were approved during the original brainstorming. The refinements in this revision remain subject to user review:

- Context-Aware Companion direction.
- Feature-local architecture.
- Central Coordinator + Feature Adapters + Local Presentation Slots.
- Adult Home Hero direction.
- Adult Compact Assist Strip direction.
- Kids Journey Guide direction.
- Kids Voice Pilot UX flow.
- Selective Talia-aware notifications.
- Celebration hierarchy.
- Adult/Kids presence split.
- Character State & Asset Matrix.
- PNG sequence approach for selected animations.
- Interaction & Animation Rules.
- Content & Personality System.
- Privacy, Consent, Telemetry, and Failure Handling.

This 2026-09-25 revision incorporates a code-grounded integration baseline and explicit experience/rollout gates. The next process step is user review of the revised written spec. Only after approval should an implementation plan be written from a fresh repository audit.
