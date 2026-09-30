# Onboarding review — 2026-09-29

Scope: `lib/features/onboarding/` (4-step Night Journey: Mushaf, Memorize, Habit, Fork).

## Findings and fixes

| # | Sev | Finding | Fix |
|---|-----|---------|-----|
| 1 | P1 | Slide 1 promised **"تفسير ميسر / Easy Tafsir — Instant word meanings"**. The app bundles no tafsir, and word meanings are postponed until KFGQPC grants permission. That's a false feature claim about religious content. | Replaced the card with **Khatmah plans** (a shipped feature) and reworded the slide-1 subtitle in both locales. Test asserts that no "tafsir" text appears. |
| 2 | P2 | Android system back on steps 2–4 left onboarding (it's reached with `go`, so back exits the app) instead of going to the previous step. | `PopScope` now goes back one step and only pops on step 1. Tested. |
| 3 | P2 | After a failed setup, choosing another path kept the error banner (`errorMessage` could never be cleared). | `selectUserType` resets the error status, and `copyWith(clearError:)` was added. Tested. |
| 4 | P3 | `PageController` listener called `setState` on every scroll frame, which rebuilt all four slides and the Bloc tree per frame. | Only the night sky listens now (`AnimatedBuilder`). |
| 5 | P3 | Hardcoded strings that bypassed l10n: `تفسير ميسر` (shown in Arabic in the English UI), status legend, and "Smart alert". | Moved into ARB keys (`onboardingBentoStatus*`, `onboardingBentoSmartAlert`, `onboardingBentoKhatmah*`). |
| 6 | P3 | "Works 100% offline" overclaims, because recitation audio streams before it's cached. | Now reads "Works offline" / "يعمل دون إنترنت". |
| 7 | P3 | Two progress indicators on the same screen (the top waypoints and tappable bottom dots with an 8px hit area). | Removed the bottom dots. The CTA is now full width. |
| 8 | P3 | Entrance animations and page transitions ignored the OS reduce-motion setting. | `JourneyEntrance` and `_goToStep` respect `MediaQuery.disableAnimationsOf`. |
| 9 | P4 | Short slides were top-aligned, which left a large empty area above the CTA. | New `JourneySlide` centers content that fits and scrolls when it doesn't. |
| 10 | P4 | Dead code: `WelcomeStepView` and its two ARB keys were unused. | Deleted. |
| 11 | P4 | The Back button stayed active while completion was saving. | Disabled while loading. |

## Decisions (delegated)

- **Khatmah replaces Tafsir.** Khatmah is a shipped, first-class feature that fits the "daily Mushaf" slide. Adding a tafsir would need a sourced, licensed work (content policy), which is out of scope here.
- **Kept the waypoints at the top and removed the bottom dots.** The top path is part of the direction contract ("path that fills with gold").

- **Slide 1 verse changed to Al-Isra 17:45** (owner request). The Fatiha basmala (1:1) is kept above it, both loaded verbatim from `quran.json`. The card header now reads "سورة الإسراء / Surat Al-Isra". The small pill that repeated the verse was removed, which resolves the duplicate-ayah issue. A test asserts the verbatim text.

## Left as-is (owner decision / follow-up)

- `OnboardingSourceAyah` caches a failed load for the whole session, so there's no retry. This is low risk because the source is a bundled asset.
- The streak mock's weekday row starts on Saturday in Arabic and Sunday in English. It's decorative only.

## Verification

- `flutter analyze`: no issues.
- `flutter test test/features/onboarding`: all pass, including 2 new flow tests and 2 new screenshot variants (`ar_memorize` and `ar_habit` in `.impeccable/shots/`).
- Full suite: only `home_preview_capture_test` fails (a 0.02% golden diff). It's unrelated to onboarding; those home files have uncommitted in-progress edits.
