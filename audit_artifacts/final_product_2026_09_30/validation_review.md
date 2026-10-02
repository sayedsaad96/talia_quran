# Validation and reminders review — 2026-09-30

Scope: automated validation plus notification/reminder, prayer, quiet-hours, permission-denial, background-refresh, and resilience paths. No application source, test, asset, or configuration file was edited.

## Commands and evidence

| Command | Exit | Result |
| --- | --- | --- |
| `flutter analyze --no-pub` | 0 | Passed with no diagnostics. |
| `flutter test --no-pub --reporter expanded` | Running at this report update | No failures observed through test 1,415. The full suite includes deliberately expensive visual export/golden tests and has generated only normal `build/share_qa` outputs. Final exit status is pending. |
| `flutter test --no-pub --reporter expanded audit_artifacts\\final_product_2026_09_30\\flutter_race_regression_test.dart` | 1 | All three regression assertions executed and failed as described below. |

The earlier targeted invocation that returned no output was not treated as evidence; the explicit rerun above establishes the result.

## Findings

### P1 Critical — Quran reader state is overwritten by an older page request

- **Location:** `lib/features/quran/presentation/cubits/quran_page_cubit.dart` (`loadPage`); reproducer `audit_artifacts/final_product_2026_09_30/flutter_race_regression_test.dart:28-41`.
- **Trigger/evidence:** Start `loadPage(1)`, then `loadPage(2)`, resolve page 2 first and page 1 last. The test expected displayed page 2 but received page 1 (`exit 1`).
- **Impact:** A fast reader navigating pages can be returned to a previous Mushaf page after the UI has already shown the newer one, producing wrong reading context and potentially wrong subsequent actions.
- **Remedy:** Assign a monotonically increasing request token (or cancel/supersede the prior request) and only emit a result when its token remains current. Add the artifact regression to the normal test tree after the fix.

### P1 Critical — Read confirmation can be written for a page the user is not viewing

- **Location:** `lib/features/quran/presentation/cubits/quran_page_cubit.dart` (`confirmRead`); reproducer `audit_artifacts/final_product_2026_09_30/flutter_race_regression_test.dart:45-55`.
- **Trigger/evidence:** Load page 1, invoke `confirmRead(2)`. The test expected `false` with no write, but received `true` (`exit 1`).
- **Impact:** A stale tap, delayed callback, or wrong caller can persist progress for another page. This compromises reading progress and related streak/wird behavior.
- **Remedy:** Validate the requested page against the current loaded page immediately before persistence, and reject mismatches without calling the save use case or recording activity.

### P2 Major — Stopping playback while its source lookup is pending leaves an error state

- **Location:** `lib/core/services/quran_continuous_player_service.dart` (`playSurah`/`stop`); reproducer `audit_artifacts/final_product_2026_09_30/flutter_race_regression_test.dart:58-83`.
- **Trigger/evidence:** Begin `playSurah(1)` while the repository result is unresolved, then call `stop()` and resolve the lookup. Expected `PlaybackStatus.idle`; observed `PlaybackStatus.error` (`exit 1`).
- **Impact:** Leaving a Quran audio screen during a slow source lookup can show a spurious playback failure instead of a clean stopped state.
- **Remedy:** Use a playback-generation/cancellation token across async source lookup and ignore stale completions/errors after stop or dispose. Preserve `idle` after an explicit stop.

### P1 Critical — Enabled morning azkar, evening azkar, and daily dua reminders schedule no notification

- **Location:** `lib/core/content/approved_azkar_content.dart:68`, `lib/core/services/notification_service.dart:1469,1513,1559`, `assets/data/azkar_release.json`.
- **Trigger/evidence:** The bundled asset contains 116 `reviewStatus: approved` records (morning 22, evening 22, general 38, duas 34), but every record has no `tier` and no `authenticityGrade`. `_isApprovedReleaseRecord` requires `tier` for every record and a supported grade for non-Quran sources, so `extractApprovedAzkarTexts` returns an empty list for all affected categories. Each scheduling method first cancels the existing rolling reminders, then returns on the empty list.
- **Impact:** The settings switches can stay enabled while the three religious reminder types are silently absent. Existing `test/assets/adhkar_contract_test.dart` checks approval/citation/source/version but does not exercise runtime extraction on the real release asset or require these fields.
- **Remedy:** Reconcile the release-asset schema and the runtime approval policy, then add a production-asset contract asserting non-empty approved extraction for all reminder categories and scheduler tests proving enabled categories enqueue slots.

## Coverage and unknowns

- Static analysis and broad automated tests cover the notification scheduler queue, quiet-hour transformations and Companion suppression, prayer delivery migration/fallback, prayer-time city-zone/DST calculations, serenity watcher failures, and background notification-worker assembly.
- Permission-denial and platform alarm execution have source-level and mock coverage, but physical-device delivery after a denied or revoked permission was not independently executed in this review.
- The full suite was still running when this interim artifact was written; its final status must be appended before a release conclusion.
