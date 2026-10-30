# Children’s memorization journey switching

**Goal:** Add a children-only entry in memorization path settings to switch between the existing Juz Amma adventure and Quran journeys in either direction.

**Design:** Extend the current path settings sheet with a localized “Change memorization journey” tile. Reuse the existing three-option journey selector, show the stored selection, and keep edits as a draft until Save. Explain that memorization progress is retained. Keep identity reset as its separate existing action.

**Architecture:** A small Cubit coordinates reads, draft selection, authorization scope and targeted saving through `ParentAccessUsecase`. The widget owns dialogs and navigation. Use the existing `setKidsJourneyPath` operation; it preserves progress and repairs a starting surah outside the new path. No content, schema, backend, or progress migration is required. Risk level 3 because the UI exposes a persisted memorization preference and guardian authorization.

**Constraints:** Children only; honor the existing Quran journey flag. Preserve identity, guardian link, session logs, rewards and completed ayahs. Preserve existing unrelated working-tree changes. Reuse Arabic/English localization and current theme tokens.

**Alternatives:** Reusing identity reset would restart unrelated setup and affect guardian linking. Sending users to the family dashboard would bury the requested action. A dedicated entry backed by the existing targeted operation is the smallest useful extension.

## Implementation and verification

- [x] Add focused Cubit tests for current selection, all three journey choices, unchanged/cancel behavior, read/write failures and duplicate submission.
- [x] Capture owner and account lease before asynchronous work; reject stale owner/reset or guardian scope after authorization. Use existing guardian PIN verification/creation rules; linked children cannot create a local PIN.
- [x] Add a localized scrollable picker and children-only settings entry. Save requires a changed selection; cancel writes nothing. On success notify the path resolver and reopen the memorization entry route so the home and map reload.
- [x] Add widget tests for visibility, PIN protection, navigation, Arabic RTL and a narrow screen with enlarged text.
- [x] Reuse and strengthen storage integration coverage for adventure → Quran → adventure, checking progress and unrelated settings survive.
- [x] Run formatting, affected static analysis, targeted tests and existing path-settings regressions.
- [x] Attempt Android runtime validation if a device is available; otherwise explicitly report it as unverified.

## Review focus

Account changes while dialogs are open must abort authorization. Guardian linking changes must invalidate an earlier weaker authorization. Errors must not navigate as success. Repeated taps must not submit twice. Quran journeys and adventure must reload from persisted state rather than leaving an old home or map visible.

## Test strategy

Unit tests exercise the Cubit’s state transitions and guards. Widget tests exercise the settings entry and picker behavior. The existing corpus-backed host integration test exercises actual storage and progress preservation. Contract, property-based, deployment smoke and release builds are outside this local finite-choice change. Android runtime evidence is separate from host tests.

## Verification evidence

- Baseline before implementation: 36 focused tests passed.
- Final focused suite: 51 tests passed (Cubit, picker, existing path settings, targeted path storage, and corpus-backed host integration).
- Changed Dart formatting: 7 files checked, 0 changes required.
- Affected static analysis: no issues found.
- Android build/install/launch: debug x64 APK built successfully (exit 0), installed with adb install -r (Success), and launched on Android 9 x64 emulator 127.0.0.1:5555.
- Build environment: initial Java local socket failure traced to temporary socket path; command-scoped jdk.net.unixdomain.tmpdir override allowed Gradle to start. No project build configuration changed.

- Android UI verified: children home -> settings -> Change memorization journey; three existing paths appear, adventure selected, unchanged Save disabled; selecting Quran journey and Save opens guardian PIN creation as expected.
- Android save success remains unverified: creating a test guardian PIN failed with Android KeyStore InvalidKeyException / Incompatible purpose in FlutterSecureStorage. The picker did not save or navigate as success. Cancelled both dialogs; retained the original journey and progress. No storage reset or destructive recovery was attempted. The unrelated secure-storage working-tree changes were preserved.
- Runtime screenshots: build/journey_switch_qa/settings-final.png, picker.png and authorization.png.

