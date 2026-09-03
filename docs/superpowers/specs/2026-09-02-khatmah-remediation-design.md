# Khatmah Integrity and Production Remediation Design

## Goal

Make Quran Khatmah progress truthful, owner-safe, recoverable, and driven by one completion path. A Khatmah may be completed only after all Mushaf pages 1 through 604 have been explicitly recorded.

## Progress invariant

- `completedPages` is the source of truth and contains unique page numbers in `1..604`.
- `currentPage` is the highest page in the contiguous prefix starting at page 1; it never implies that skipped pages were read.
- `nextUnreadPage` is the first missing page in `1..604`. `startPage` is retained only for legacy migration.
- Digital reading records only the confirmed page.
- Physical Mushaf logging records the explicit inclusive range `nextUnreadPage..enteredPage` after the UI tells the user which range will be recorded.
- Re-recording a page is idempotent. Reading a later page does not fill gaps. Reading an earlier page never removes progress.
- Completion is valid only when every page in `1..604` is present.

## Command and state flow

`QuranReaderPage` and the physical logger call `RecordKhatmahReadingUsecase`. The use case validates active status, records pages, persists the plan, and completes it through the repository when coverage is complete. `KhatmahCubit` is the presentation owner of this command and emits active, paused, failure, wird-completed, or completed states. The Quran page cubit remains responsible only for generic Quran reading confirmation.

## Persistence and recovery

- Existing plans without `completedPages` migrate by treating `startPage..currentPage` as already completed, preserving previously shown progress.
- History writes are idempotent by plan id. Retrying completion cannot duplicate an archive row.
- Corrupt active-plan/history JSON is surfaced as a typed storage exception instead of being silently treated as empty data.
- The current release remains local-first. The unused `khatmah_cloud_dirty` promise is removed until an owner-scoped cloud schema and merge policy exist.
- Khatmah preference keys are account-owned and must be cleared on logout/account switch.

## Pausing and replacement

- Paused plans have a distinct state and cannot record digital or physical progress.
- Creating a new plan while any active or paused plan exists is rejected by the domain use case. UI must route the user to resume or explicitly abandon the existing plan first.

## Scheduling

- The expected completion date is inclusive: `start + max(days - 1, 0)`.
- A daily target is derived from the next unread page and the configured page count. `lastReadDate` prevents a completed daily target from silently rolling into another target on the same local day.
- Persist the local target date and its page-range anchor with the first reading write of that date. Coverage plus `lastReadDate` alone cannot reconstruct the day's original target after partial reading or a restart. Legacy plans without an anchor derive one from current coverage without inventing past daily activity.
- Keep that range stable for the local calendar day, including after reload, extra reading, and same-day schedule changes; the following day derives a new range from the next unread page. A target is complete only when every page in its range is covered, not merely when a later page was read.
- Planned duration and actual elapsed duration are separate. Completion UI displays elapsed calendar days, never `targetDays` as actual time.

## Completion and certificates

- The completion result carries the completed plan and persisted history entry.
- The completion screen requires this persisted result; direct navigation without valid completion redirects to the dashboard/home instead of displaying fabricated defaults.
- Certificate creation occurs only from the persisted completion result and is idempotent by Khatmah plan id.

## Islamic-content governance

- The fixed text is labeled as a suggested general supplication, not a prescribed or Prophetic Khatm formula.
- Preserve the Khatmah dedication option for living and deceased recipients. The project owner explicitly confirmed consultation with a scholar and instructed that dedication remain available, with deceased recipients described as preferred. Do not replace dedication with a prayer-only option.
- Record this as project-owner-reported scholarly review; do not invent the scholar's identity, a source citation, or unanimous scholarly agreement. This approval does not automatically approve every fixed supplication template.
- Religious text comes from one asset source, is registered in `content_manifest.json`, and carries review status, reviewer, source locator, version, and checksum before release.
- No gendered template is generated from a recipient name unless gender is explicitly modeled and the wording is approved; neutral reviewed wording is preferred.

## UX and accessibility

- Home exposes “Start a Khatmah” when no plan exists, “Continue” for active, and “Resume” for paused.
- All copy lives in ARB localization resources.
- Progress, daily target, errors, and physical range confirmation expose semantic labels and support large text without clipped fixed rows.

## Acceptance gates

- Jumping from page 1 to page 100 records page 100 only and leaves page 2 as next unread.
- Reading page 604 alone cannot complete a Khatmah.
- Sequential coverage of every page completes exactly once, archives exactly once, and navigates once.
- Paused plans reject progress.
- A Khatmah save failure is visible and retryable.
- Account switch/logout leaves no previous Khatmah plan, history, or recipient data.
- Existing cursor-only plans migrate without losing their previously represented progress.
