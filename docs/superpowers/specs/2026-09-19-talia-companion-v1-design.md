# Talia Companion V1 — Design Specification

**Product:** Talia Quran  
**Feature:** Talia Companion  
**Version:** V1  
**Date:** 2026-09-19  
**Status:** Design approved in brainstorming; implementation plan not started yet.

---

## 1. Purpose

Talia Companion is a context-aware visual companion layer for Talia Quran. It is not a generic mascot, not an open AI assistant, and not a replacement for existing feature logic.

Its job is to make the product feel more guided, personal, coherent, and encouraging by presenting the right visual state, message, and action at the right moment while respecting Quran focus, user choice, privacy, performance, and existing feature ownership.

V1 serves both adults and children with the same Talia identity, but with different presence density, tone, and interaction patterns.

### Core product principle

> Central intelligence, local presentation.

Talia can be aware of multiple features, but each screen owns where Talia is rendered. There is no global floating companion overlay.

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
- On-device speech recognition first, optional online fallback.
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

### No global overlay

Presentation is local to each eligible surface:

- Adult Home → Hero Companion Area.
- Adult non-Home screens → Compact Assist Strip / inline contextual slot.
- Kids Journey → Journey Guide slot.
- Supported Kids learning screens → Guide / Voice Pilot slot.
- Quran Reader → no Talia presentation.

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
P9  Greeting
P10 Ambient idle
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

### 10.2 Kids Voice Pilot

The Voice Pilot is a limited V1 experiment designed to validate the path toward Talia Voice Learning V2.

It is not an open assistant.

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

1. On-device recognition first.
2. If confidence is insufficient and online fallback is allowed and connectivity exists, use online recognition.
3. If still unknown / unavailable, use visual fallback.

No LLM is required for V1 intent classification.

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

- Greeting generally once per session.
- Review reminder not repeated multiple times in one session.
- Prayer suggestion not repeated every few minutes.
- Ignored Help suggestion should not reappear immediately.

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

### Device-local / transient state

Examples:

- Hide Today.
- Cooldowns.
- Session state.
- Current animation state.
- Voice retry count.
- Temporary request identifiers.

Child profiles must be isolated from each other.

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

### Widget tests

Validate:

- Home Hero renders one message / one CTA.
- Adult inline companion remains compact.
- Talia is not rendered in Quran Reader.
- Voice mic is absent on unsupported screens.
- Reduced-motion fallback.
- Visual fallback after second failed voice attempt.
- Certificate/celebration hierarchy.

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
12. Voice Pilot telemetry provides enough evidence to inform V2.
13. Talia integrates existing systems instead of duplicating their business logic.
14. Runtime performance remains acceptable on the project’s target Android devices.
15. Existing Quran, memorization, prayer, Daily Question, Share Good, and other features remain authoritative for their own logic.

---

## 29. Implementation Sequencing Constraints

The future implementation plan should prefer incremental integration rather than a big-bang rollout.

A likely safe sequence is:

1. Fresh Phase 0 repository audit.
2. Core semantic models and suppression/priority policies.
3. Character renderer + asset/motion system.
4. Adult Home Hero integration.
5. Adult inline companion integration.
6. Kids Journey Guide integration.
7. Persistence / adaptive presence.
8. Message catalog and governance.
9. Notifications integration.
10. Kids Voice Pilot foundation.
11. Consent / privacy / recognition abstraction.
12. Pre-recorded voice responses.
13. Safe telemetry.
14. Runtime QA, accessibility, performance tuning, kill-switch validation.

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
12. On-device recognition first; online fallback only under approved conditions.
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

---

## 32. Design Approval State

The following design areas were approved during brainstorming:

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

The next process step is user review of this written spec. Only after approval should an implementation plan be written.
