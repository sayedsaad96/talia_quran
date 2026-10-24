# Progress — plan: 2026-10-25-quran-media-notification.md

- Baseline: clean working tree, existing 10 handler/scope tests passed during
  planning. Local branch codex/quran-media-notification created for execution.
- Ruling: user explicitly approved and requested execution of the plan; no
  further plan approval or execution-method question is needed.
- Test strategy: unit tests for metadata, lifecycle and navigation decisions;
  filesystem test for bundled artwork; widget test for navigation integration;
  existing audio regressions plus Android build/device smoke when available.
  No API contract/property/smoke-deployment tests: no public API or deployment.
- Initial device probe: adb server could not start under restricted execution;
  retry through the permitted host execution path before declaring unavailable.

## Implemented and verified

- Extended the existing handler with prepare/commit, live player state/index,
  metadata refresh for stable IDs, transport availability, and full disposal.
- Added the generation-bound media snapshot, localized metadata and persistent
  bundled cover, and app-level notification navigation/readiness handling.
- Ruling: preserve the Kids reader context by leaving navigation unchanged
  when the current route is under the Kids area. The shared player does not
  store a reader-origin identifier; opening an adult page would cross context.
- Ruling: initialization failure retains the existing audio fallback. No
  second AudioService.init path or automatic native retry loop was introduced.
- Independent Sol review found generation drift after same-surah seek and
  rejected ranges, plus delayed source events after queue commit. Each was
  reproduced RED and fixed GREEN. The same stale-index safeguard now protects
  the reader highlight; its dedicated regression also failed before the fix.
- Added the dynamically resolved notification drawable to Android resource
  keep rules; the existing icon and canonical Quran mappings are unchanged.
- Final focused test run: 117 passed, exit 0. Full output is in
  `build/media_notification_focused_tests.log`; includes handler, session,
  metadata/artwork, navigation widget, service integration, repeat, bedtime,
  media ownership, lifecycle, resume storage, Cubit and architecture tests.
- Final `dart analyze` of changed production and new/changed tests: exit 0,
  `No issues found!`. `git diff --check`: exit 0.
- Final Android x64 debug build: exit 0, generated
  `build/app/outputs/flutter-apk/app-debug.apk`. Existing home_widget and
  workmanager KGP migration warnings remain; no dependency upgrades performed.

## Verification limits

- The full `flutter test --no-pub --concurrency=2` run reached 451 passes,
  then a test engine failed to load `remote_child_dashboard_parse_test.dart`
  with native memory/thread allocation errors. The stalled run was stopped.
  That exact test passed in the subsequent sequential focused run. The full
  suite is incomplete, not green; log: `build/media_notification_tests.log`.
- Native Android 9/API 28: installed an earlier feature build with `adb install
  --no-streaming -r -t`, preserving application data. Starting Al-Fatihah
  produced an active Android media session (state 3), matching localized
  surah/ayah and reciter (Maher), and a real notification containing the local
  cover and Previous/Pause/Stop/Next controls. Screenshot captured at
  `build/media_notification_tmp/notification.png`. Natural completion removed
  the active notification and reached idle state 0.
- The final artifact was rebuilt after the last reader index regression fix.
  Its reinstall and subsequent device commands stalled when the emulator
  connection stopped responding; those task commands were cancelled. Playback
  buttons, lock screen, permission-denied/network interruptions, English UI
  and Android 13+ were not fully exercised on device. No modern AVD was listed.
- Automated tests verify pause/resume/stop/seek dispatch and navigation without
  restarting playback; they do not substitute for the unfinished device checks.
