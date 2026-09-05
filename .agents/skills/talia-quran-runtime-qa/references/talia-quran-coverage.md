# Talia Quran Coverage Model

Test only features that actually exist in the current repository, but explicitly inventory all of the following domains.

## Startup and Onboarding
- cold launch
- first-run onboarding
- returning-user startup
- back navigation
- crash/blank/infinite-loader detection

## Quran Navigation
- Surah list
- Juz navigation
- opening a Surah
- verse/ayah rendering
- switching between relevant reading modes if implemented
- back/forward navigation
- scroll position
- last-read behavior

## Mushaf / Reader Experience
- Arabic text direction
- page/ayah ordering
- clipping/overflow
- zoom/font/theme controls if implemented
- page transitions/scrolling
- orientation/responsive behavior where supported

## Audio / Recitation
- play
- pause
- resume
- stop
- next/previous if implemented
- audio state when navigating away
- missing/failed audio handling
- permissions where relevant

## Memorization
- memorization path selection
- child/adult paths if implemented
- progress updates
- repetition controls
- ayah-level completion
- recitation/voice tests if implemented
- microphone permission accept/deny

## Progress and Persistence
- bookmarks
- last read
- memorization progress
- preferences/settings
- close and relaunch app
- persistence after process restart when feasible

## Search / Discovery
- Quran search if implemented
- Surah/ayah lookup
- empty/no-result state
- malformed/edge input

## Settings / Localization
- Arabic RTL
- English UI if implemented
- theme/font/audio settings
- accessibility-relevant text scaling where feasible

## Error / Offline
- unavailable network
- missing local asset
- failed audio fetch
- loading
- empty state
- retry
- permission denial

## Reachability
Flag any implemented screen, route, Cubit/BLoC state, or user-facing feature that has no normal UI path.
