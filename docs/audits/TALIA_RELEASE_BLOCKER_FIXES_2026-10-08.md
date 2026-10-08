# Release blocker fixes (2026-10-08)

Fixes for the blockers found in the production-readiness audit of 2026-10-08
(HEAD `3f91360c`). Branch `fix/release-audit-blockers`.

## Fixes

| Audit ID | Severity | Fix | Files | Tests |
|---|---|---|---|---|
| Onboarding basmalah | P0 | The first onboarding card showed the Al-Fatihah 1:1 basmalah under a "سورة الإسراء" label above 17:45, which placed the basmalah where the Mushaf does not. The card now shows 17:45 alone. | `onboarding_mushaf_bento_view.dart` | `onboarding_flow_test.dart`; welcome goldens regenerated |
| Sources & licenses | P1 | Restored the tile on the About page. It is the only route to the Tanzil notice and tanzil.net link the Quran text licence requires. | `about_settings_page.dart` | `settings_page_test.dart` |
| P1-1 page index | P1 | 56 ayahs at page boundaries sat on a different page in the `quran.json` `page` field than in the QCF layout the reader draws (for example 5:77: drawn on 120, json 121). Long-press silently failed on them and page playback skipped or added ayahs. The datasource now takes each ayah's page from `qcf.getPageNumber`. `quran.json` is unchanged. Juz is unchanged (see open items). | `quran_local_datasource.dart` | `all_surahs_ayah_long_press_test.dart` |
| P1-2 sajdah sign | P1 | The trailing-number cleanup removed the sajdah sign (۩) with the ayah number on the home review card. ۩ and ۞ are no longer in the stripped set. | `quran_ayah_display_text.dart` | `quran_ayah_display_text_test.dart` (7:206, 96:19 from QCF data) |
| P1-3 sign-out | P1 | With the evidence transport off (the default; nothing enables it), local evidence counted as pending cloud work, so every signed-in learner was blocked from a normal sign-out. Disabled transport is no longer pending work; receipts are kept. | `review_evidence_sync_service.dart` | `review_evidence_sync_service_test.dart` |
| Kids PIN dead end | P2 | On a device where no guardian PIN was ever set, the "I finished memorizing" fallback asked for a PIN that could never match. When no PIN exists the child now confirms with a simple dialog; a set PIN is still required, and an unreadable setting keeps it required. | `kids_mode_cubit.dart`, `kids_gamified_listen_page.dart`, `injection.dart`, ARB (2 keys) | `kids_mode_cubit_test.dart` |
| Closing dua | P2 | The closing dua (ARB `closingDua`) has no recorded source or review, so it is hidden behind `kClosingDuaApproved = false` per the content policy. The text is kept. | `closing_moment.dart`, `v2_completion_page.dart`, `quran_reader_page.dart` | `v2_completion_page_test.dart`, `quran_reader_page_mode_test.dart` |

## Decisions

| Decision | Choice | Reason |
|---|---|---|
| Which page set is authoritative | The QCF layout | It is the page the user sees. Every other lookup in the app (reader, bookmarks, kids reader, hizb, read receipts, khatmah) already used it; the datasource was the last place using the json field. On device, page 120 ends with 5:77. |
| Juz membership (3:92, 9:93 differ between sources) | Left unchanged | Not confirmed against a printed Mushaf; never decide religious structure from memory. |
| Kids fallback without a PIN | Allow child confirmation | Same rule as reopening guardian linking ("a profile that never had a PIN is not locked out"). There is no guardian credential to ask for. The completion is recorded as a weak rating, so the ayah comes back in review. |
| Closing dua | Hide, do not rewrite | Content policy: unverified religious text stays blocked; no generated replacement. |

## Open items

- **Owner:** register the closing dua with a source and review, then set `kClosingDuaApproved` to true.
- **Owner:** confirm juz boundaries at 3:92 and 9:93 against a printed Madinah Mushaf.
- **Before enabling the evidence transport:** the local backlog will count as pending again, and dead-lettered evidence has no recovery path (audit P2-3).
- **Product:** with no PIN set, a child can reach the self-confirm dialog by denying the microphone. Setting a PIN during kids onboarding would close this.
- **Hardening:** corrupt parent settings read as "no PIN" (`memorization_kids_storage.dart`), which now opens the fallback without a PIN. The same applies to the existing linking precedent.
- **Not yet done:** Android 13+ device test, sign-in/sign-out on device, notifications, Play Console declarations.

## Verification

- `flutter analyze`: no issues.
- `flutter test`: 3562 passed (full suite after the main fixes), then the kids cubit and pages tests again after the review follow-ups.
- Independent review of the high-risk changes (page index, sync, PIN gate): approved, no P0–P2 findings. Its two follow-ups (stale state after the PIN awaits, a misplaced doc comment) are fixed.
