# Reciter expansion validation — 2026-10-24

**Historical preparation report:** The later direct owner request to activate all ten additions superseded the availability/publication decision below. Current activation and verification are recorded in `activation.md`; original technical evidence and unresolved rights/audible-review facts remain valid.

This is focused feature evidence, not a release audit. The catalog contains sixteen identities; only the original six are available. All ten additions remain `blockedPendingReview`.

## Source verification

- Publisher catalog: https://everyayah.com/recitations_ayat.html.
- Reusable check: `scripts/verify_reciter_catalog.py` using the bundled Python runtime.
- Successful network run exit code: **0**. Exact expected ayah filenames: **6,236 per candidate**, **zero missing** across all ten directories.
- **60** bounded HTTP samples passed the response type and MP3-header check, six per candidate. Each read is capped at 1 KiB. No audio corpus was imported.
- Original restricted-network attempt failed DNS; the successful permission-enabled run supersedes it. Detailed response statuses, URL identities, index digests and sample-prefix digests are in `verification.json`.
- These checks do **not** verify the audible ayah, segmentation, speaker identity or riwayah. Explicit reuse permission and affected-content owner approval remain **unverified/pending**. No source has been promoted based on HTTP success.
- Individual source/review records: `docs/content/quran_reciter_sources.json`. Ibrahim Akhdar uses the 32 kbps directory; the publisher flags the 64 kbps set as missing all 6,236 files.

## Automated checks

- Before implementation: 46 existing focused audio/selector/download tests passed (exit 0).
- Implementation TDD: missing candidate/availability symbols produced expected failures before production changes; the implementing agent reports 52 focused Dart tests passed after implementation.
- Python verifier regression command: `python -m unittest discover -s test/scripts -p verify_reciter_catalog_test.py -v`: **3 tests passed**, exit 0. Tests reject a missing ayah even with HTTP success and reject non-audio/missing-type responses, while allowing extra basmalah files.
- Integrated regression: `flutter test --no-pub --reporter expanded test/features/quran` plus every audio-related `test/core/services/*_test.dart`: **364 tests passed**, exit 0; full log in `flutter_tests.log`.
- Additional selector tests use the real audio cubit and player service with an external audio-engine boundary fixture: **4 passed**. Arabic and English 320×480 layouts at 1.7 text scale reach/select the last available reciter, update playback state and retain the choice after service recreation. Dropdown and storage tests exclude all pending names.
- Targeted analysis of the 11 changed production and 6 affected test files: **exit 0, no issues found**; output in `dart_analyze.log`.

## Android runtime attempt

- `adb devices -l` and `flutter devices --device-timeout 5 --machine` confirmed device `127.0.0.1:5555`, NE2211, Android 9/API 28, Android x64.
- `flutter build apk --debug --no-pub`: **exit 1**, before application compilation: `java.io.IOException: Unable to establish loopback connection`.
- `android/gradlew.bat help --stacktrace --no-daemon`: **exit 1** with the same failure. The cause is Java `PipeImpl` → `UnixDomainSockets.connect` → `java.net.SocketException: Invalid argument: connect` while connecting to the Gradle daemon.
- Process-only temporary-directory and selector-provider diagnostic retries also failed. No Gradle/project configuration was changed.
- No APK from these changes was installed or launched. Android selector interactions, audible samples, background switching and actual offline playback are therefore **not runtime verified**. An older installed build is not evidence for this revision.

## Publication gate

Keep every new entry blocked until rights evidence, Hafs/ayah-segment validation, owner review and device playback checks are recorded. Preserve existing identifiers, preference values, resume JSON and per-reciter cache namespaces. A plan approval does not stand in for recording-specific rights/content approval.
