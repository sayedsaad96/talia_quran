# Talia Quran Coverage Model

Use only flows that actually exist in the `talia_quran` repository. Discover first; do not invent features.

## High-value user journeys

1. Cold launch and first meaningful screen.
2. First-run/onboarding flow, skip/back/re-entry if implemented.
3. Quran discovery: Surah list, Juz/Hizb/index/navigation, search if implemented.
4. Mushaf/Quran reader: open Surah → render ayat correctly → scroll/page/navigation → return.
5. Ayah integrity: Surah/ayah numbers, ordering, Basmala handling, verse boundaries, no duplicated/missing content.
6. Mushaf visual quality: Arabic shaping, RTL direction, line/page overflow, clipping, spacing, selected/highlighted ayah state, device-size behavior.
7. Audio/recitation if implemented: play/pause/seek/repeat, ayah transitions, background/interruption behavior, failed/missing audio handling.
8. Memorization flow if implemented: choose memorization path → start session → current ayah/progress → repeat/review → complete/resume.
9. Voice/recitation test if implemented: microphone permission, recording/listening state, result/error/retry, denied permission, interruption handling.
10. Child/adult path selection if implemented: correct entry path, persistence, no cross-path state leakage.
11. Bookmarks/favorites/last-read/progress/history if implemented.
12. Settings: language, audio/reciter, theme/font/text size, notifications or other available controls.
13. Arabic RTL and any English/localized UI. Quran Arabic content must never be reversed or treated as ordinary LTR text.
14. Persistence: relaunch after last-read, bookmark, memorization progress, path, and settings changes.
15. Loading, empty, error, offline, retry, slow-operation states for Quran/audio/local/cloud data as applicable.
16. Navigation: back behavior, deep links/routes if implemented, dead ends, duplicate stacks, accidental reset of reading position.
17. Responsive/adaptive: small phone, typical phone, large phone/tablet when available.
18. Accessibility basics: tappable targets, semantics for critical controls, readable contrast/text scale stress where practical.

## Quran-specific invariants

Treat these as high-risk regressions whenever affected code changes:

- Opening a Surah must show the intended Surah, not stale data from a prior selection.
- Ayat must remain in canonical order with no runtime duplication or omission caused by UI/state logic.
- Reader navigation must not silently lose the user's last-read/progress state when persistence is intended.
- Audio/ayah selection must stay synchronized when synchronization exists in the product.
- Memorization state must not advance, reset, or mark completion incorrectly after relaunch/back navigation.
- Permission denial or offline state must not trap the user in an unusable screen.

## Runtime exploration rules

- Scroll every primary Quran/reader screen through enough content to expose lazy-loading/layout problems.
- Exercise every visible primary action in the current journey.
- Test at least one short Surah and one longer Surah when reader changes could depend on content length.
- Test one abnormal interaction per critical screen: rapid tap, back during load/audio, relaunch, denied permission, missing network, or empty data as applicable.
- A screenshot is evidence, not proof by itself; pair it with assertions/logs when diagnosing behavior.
- Native UI tree is especially useful for system dialogs, microphone permissions, notifications, WebViews, and controls not visible to Flutter finders.
