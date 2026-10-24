# Quran media notification implementation plan

Goal: extend the existing Android Quran listening session with local Talia
artwork, localized metadata, reliable transport state and return-to-listening.
Architecture: one existing just_audio player and audio_service handler; preserve
hands-free leases, Quran identifiers, background preference and stored progress.
Spec: the user-approved Arabic plan in this chat (2026-10-25).
Risk: 3, audio lifecycle and reader navigation. No dependency or schema changes.

1. Add regression tests, then implement generation-bound reader metadata,
   explicit queue prepare/commit, same-ID refresh, playing-only state updates,
   transport availability and stop/disposal invalidation.
2. Test and add an offline artwork provider and localized metadata factory;
   inject the current locale and refresh active metadata on locale changes.
3. Test and add a notification navigation coordinator; wire once after app
   readiness, route to the current reader page, preserve playback and ignore
   practice ownership, idle state and duplicate destinations.
4. Run focused audio/reader/navigation tests, analysis, Android build and
   device validation where available; obtain an independent code review.

Verification: unit regressions for transitions and deferred initialization;
widget navigation integration; existing ownership/lifecycle/repeat tests;
Android notification/lock-screen smoke checks on pre-33 and current Android.
Native appearance is unverified unless actually exercised on a device.

Defaults: reuse the existing square launcher image and notification icon;
no full-surah duration estimate, reciter photos, iOS-specific changes or
automatic restart after force-stop. No automatic reinitialization loop.
