# Quran Reader Performance, Background Font Delivery, and Page-Turn Design

Date: 2026-08-29
Status: Awaiting user confirmation

## Context

The reader uses `qcf_quran_plus` with 604 page-specific QCF4 Tajweed fonts. Today those fonts are shipped as ZIP assets, extracted to disk, and registered dynamically. The app also starts registering all 604 fonts shortly after launch, while the adult and kids readers preload a radius of eight pages.

This causes frame competition, a page-level shimmer while a font is prepared, and unnecessary reader rebuilds. The current font inventory is about 65.5 MB compressed and 159.3 MB as extracted TTF files.

The previously approved static-font proposal is replaced by a Google Play Asset Delivery `fast-follow` pack. Google Play starts the pack automatically after installation without blocking the rest of the app. The first launch checks and resumes delivery and reports progress.

Font files persist after delivery, but Flutter font registration belongs to the current engine session. The design therefore separates one-time pack delivery from small per-session page preparation and never registers all 604 fonts at startup.

## Scope and Platform Decision

This phase targets the production Android App Bundle distributed through Google Play. Fast-follow behavior is not available in a normal standalone APK. Local verification must use bundletool local testing and Google Play Internal App Sharing.

Font delivery is hidden behind a platform-neutral interface. If iOS is released from this repository, its existing bundled font source remains available through an iOS-specific provider. Migrating iOS to Background Assets is a separate change.

## Goals

- Start the complete Mushaf font-pack download automatically after Play installation.
- Download each pack version once. Re-delivery is allowed only after an app/pack update, cleared app data, or Play invalidation.
- Keep the rest of the application usable during the first download.
- Never enter the reader or display QCF glyph codes before the required fonts are ready.
- Remove Mushaf page shimmer and system-font fallback.
- Keep adjacent page turns smooth and add a lightweight physical page-turn effect.
- Prevent metadata, persistence, and read-confirmation state from rebuilding the Quran page body.
- Prevent stale page requests from overwriting a newer page.
- Preserve the current corpus, layout, Tajweed colors, interactions, bookmarks, audio hooks, and last-page restoration.
- Meet a 60 fps target in profile mode on the connected Samsung device.

## Non-goals

- Replacing the Quran corpus or page mappings.
- Migrating to the community 47-font dataset.
- Adding a shader-based full page curl.
- Promising first-use Quran access before the background pack is complete.
- Supporting production fast-follow through a sideloaded APK.
- Migrating iOS delivery in this phase.
- Refactoring unrelated features.

## Font Pack and Distribution

### Vendored rendering package

Vendor the pinned `qcf_quran_plus` version locally. Preserve its Quran data, page numbering, rendering behavior, public API, and font-family names. Record the upstream version and local changes.

Remove the package's font ZIP declarations so Android does not contain both the old ZIP archive and the new asset pack. The package continues to provide data and rendering helpers; the application owns font delivery and session registration.

### Fast-follow pack

Create an Android asset-pack module named `quran_fonts` with `fast-follow` delivery. Store the 604 extracted TTF files directly in the pack, with families `QCF4_tajweed_001` through `QCF4_tajweed_604`. Do not add another ZIP layer because Play already archives and expands the pack.

Generate a versioned manifest containing the schema version, content version, page range, filename, family, size, SHA-256 digest, and aggregate inventory digest. A deterministic validator fails if any page is missing, duplicated, incorrectly named, mapped to the wrong family, or still packaged in the Android base module.

### Android bridge

Add a narrow bridge over Play Asset Delivery that can:

- inspect status and the current pack location;
- stream total bytes, downloaded bytes, and delivery state;
- request or retry delivery when fast-follow has not completed;
- return the read-only asset path after completion;
- map no-network, insufficient-storage, Play-unavailable, canceled, and failed states.

The bridge contains no reader UI or font-registration logic. Pack locations are checked on every launch and are never persisted as permanent paths.

## First-Use Experience

`QuranFontPackService` is the source of truth for these states:

- `checking`;
- `downloading`;
- `validating`;
- `ready`;
- `waitingForNetwork`, `insufficientStorage`, `playUnavailable`, or `failed`.

The service starts after application initialization without blocking the rest of the app. If Quran is opened before readiness, show one dedicated Mushaf preparation screen outside the reader. It shows the one-time download explanation, size/progress, and an appropriate retry or network action. It never shows a fake page, shimmer, fallback text, or partial glyphs.

Validation runs off the UI thread. The validated content version and aggregate digest are stored. Later launches still check Play's pack location, but do not hash all 159.3 MB again when the same validated pack is present. After validation, the originally requested Quran destination opens automatically.

An update, cleared app data, or Play invalidation can require this safe preparation flow again; normal launches do not download the same version again.

## Per-Session Font Readiness

`QuranFontSessionRegistry` maps each page to its verified TTF and unchanged family name. It deduplicates concurrent requests, records fonts registered in the current engine, and surfaces failures instead of allowing fallback.

Before opening the reader, prepare the selected/restored page and its immediately previous and next pages. This is local-disk work after pack readiness and occurs while the entry/preparation surface remains visible. Each settled page prepares the next frontier page in both directions. The default window is current ±1; profiling may justify ±2, but never the current radius of eight.

Swipes are enabled only toward ready pages. If rapid swiping reaches an unprepared frontier, the current fully rendered page stays visible until local registration finishes. Direct jumps prepare the target ±1 before `jumpToPage`; the current screen remains stable meanwhile. No page-level shimmer or blank Quran page is used.

After replacement tests pass, remove ZIP extraction, all-font startup registration, `preloadPages(... radius: 8)`, and `QuranPageFontGuard`. Quran data warm-up remains data-only and runs in a background isolate.

## Reader Rebuild Boundaries

Separate the stable page body from reader chrome:

- the page body owns the stable `PageController`, immutable page data, ready window, transform, and verse gestures;
- top and bottom chrome observe lightweight page metadata;
- persistence, streak, read-confirmation, and audio coordination run outside animation ticks;
- loading metadata never replaces a rendered page body with a loading state.

`QuranPageCubit` uses a monotonically increasing request generation. Only the latest request may emit loaded or error state, preventing a slow earlier response from overwriting a newer page.

Adult and kids readers share the same readiness coordinator and page-turn widget.

## Lightweight Physical Page Turn

Wrap each stable page child in an `AnimatedBuilder` driven by the existing `PageController`. Animation ticks update only transform and edge shade, not Quran lines.

- Clamp horizontal progress to the current viewport.
- Use small perspective and bounded Y-axis rotation.
- Align the transform to the physical RTL binding edge.
- Add a lightweight folding-edge gradient.
- Settle adjacent navigation in 280 ms with a decelerating curve.

Avoid shader code, `ClipPath`, blur, and repeated `saveLayer`. When `MediaQuery.disableAnimations` is true, disable the 3D rotation and shade while keeping normal page snapping. Large jumps prepare their target window and then jump directly.

## Failure Handling and Quran Integrity

An invalid or missing font blocks the Quran destination with a recoverable preparation error. QCF glyph codes must never render through a system Arabic font.

The current corpus remains authoritative. Tests compare corpus data, page mappings, family mappings, and the font inventory. Visual checks cover pages 1, 2, 42, a multi-surah page, and 604 in light and dark Tajweed modes.

If the user is offline before first delivery completes, the rest of the app remains available and the preparation screen explains the required connection. Insufficient storage is reported without a retry loop. A failed/canceled download can resume without corrupting a verified version.

No user-data migration is required. Existing bookmark, last-page, read-confirmation, and audio identifiers remain unchanged.

## Test-First Implementation Sequence

1. Capture baseline bundle size, startup/page-turn traces, and the current font/corpus inventory.
2. Test the 604-file manifest and prove old ZIPs are absent from the Android base module.
3. Test pack states, progress, validation, retry, update invalidation, and readiness.
4. Test Android Play Asset Delivery status mapping and pack lookup.
5. Test idempotent session registration, concurrent deduplication, exact family mapping, and the bounded page window.
6. Test that the route is gated before readiness and no skeleton/shimmer appears after readiness.
7. Test that swipes never expose an unready page and distant jumps keep the current surface visible.
8. Test RTL transform direction, progress clamping, 280 ms settling, and reduced motion.
9. Test that the Quran page child stays stable while only the transform changes.
10. Test that stale Cubit responses cannot overwrite the latest request.
11. Run adult/kids reader, corpus, bookmark, audio-hook, and rendering regressions.
12. Verify via bundletool and Play Internal App Sharing, then profile on the Samsung device.

## Planned Change Areas

- locally vendored `qcf_quran_plus` without runtime font ZIP assets;
- Android `quran_fonts` asset-pack module and Gradle registration;
- Android Play Asset Delivery bridge;
- shared pack-state, validation, and session-registry services;
- dependency injection and application initialization;
- Quran preparation UI and Arabic/English messages;
- adult/kids reader readiness, rebuild boundaries, and navigation;
- shared lightweight page-turn widget;
- validators, unit/widget tests, PAD integration checks, and profiling.

## Acceptance

- Play automatically starts the pack after installation; first launch observes/resumes it.
- The rest of the app works during the one-time preparation.
- The reader never shows shimmer, a blank page, bad glyphs, or fallback fonts.
- After pack readiness, no network request is needed for any page.
- Normal launches never re-download the same verified pack version.
- Only a bounded page window is registered per engine session; all 604 fonts are never registered in the background.
- Normal adjacent turns stay within the 16.7 ms frame budget without repeated jank.
- Quran content, page assignment, Tajweed, actions, bookmarks, audio, and restoration remain correct.
- Release behavior is verified from a Play-delivered App Bundle, not inferred from `flutter run`.

Implementation stops for packaging correction if old ZIPs remain in the base module or the pack fails in Internal App Sharing. If 3D motion causes repeated frame violations, keep all readiness/rebuild improvements and reduce the effect to translation plus edge shade.

## Rollback

Delivery and registration sit behind platform-neutral interfaces. Android rollback changes `quran_fonts` from `fast-follow` to `install-time` while retaining the verified inventory and readiness contract. It does not restore all-font startup registration or page shimmer. Animation can be independently reduced or disabled. User and Quran data are unaffected.
