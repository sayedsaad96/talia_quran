# Progress page ("تقدمي") audit and improvements

Date: 2026-09-29. Scope: `lib/features/progress/**` and `lib/core/widgets/activity_heatmap.dart` (used only by this page).

## Defects fixed

| # | Sev | Defect | Fix |
|---|-----|--------|-----|
| 1 | P2 | Every progress event (read page, review, streak, cloud pull) emitted `ProgressLoading`, so the whole page flashed to a skeleton, lost its scroll position, replayed its entrance animation and reset the achievement tab. | `load()` shows the skeleton only on the first load. Later reloads swap data in place. |
| 2 | P2 | A failed background reload replaced good data with a full-screen error. | The cubit keeps the last loaded data. The error screen appears only on a failed first load. |
| 3 | P2 | A failure in the heatmap or XP read (Isar) threw out of `load()` and left the page stuck on the skeleton. | Heatmap, XP and profile fail open to defaults and log through `TaliaLogger.w`. |
| 4 | P3 | Overlapping loads could finish out of order, so an older result could overwrite a newer one. | A generation counter drops stale results. |
| 5 | P3 | The XP card went stale because XP-only events are filtered out of full reloads. | XP events now call `refreshXp()`, which updates only the XP fields. |
| 6 | P2 | The memorization card put up to 7 info chips in one `Row` of `Expanded` cells, which overflowed on phones. | The chips are now a wrapping 3-column grid (2 columns below 280dp). The last-memorized ayah takes a full row. |
| 7 | P2 | When the header collapsed, the gradient faded to the page background and left the white share icon invisible in light theme. | The header keeps its gradient when pinned and cross-fades to a compact title. |
| 8 | P3 | Badge tiers compared targets in mixed units (pages, ayahs, surahs, juz, days). Because `>= 15` was checked before `>= 564`, "50 ayahs" rendered as diamond. | Each achievement id now has an explicit tier. |
| 9 | P3 | "جزء عمّ" unlocked after any 564 memorized ayahs, even ones outside Juz 30. | The badge counts only ayahs memorized inside Juz 30. The copy now says "احفظ جزء عمّ كاملاً". |
| 10 | P3 | The stat card labelled "قيد المراجعة" showed *due* reviews. | The label is now "مراجعات مستحقة". |
| 11 | P3 | The streak unit was always "أيام" ("1 أيام"). | The unit uses ICU plurals (`progressStreakDaysUnit`). |
| 12 | P3 | Certificate dates were hard-coded as `d/m/y`, and certificates flashed a spinner even though they load synchronously. | Dates use `formatMediumDate`. Certificates load before first paint, reload after a cloud pull or a track switch, and sort newest first. |
| 13 | P3 | The heatmap drew up to 730 days under a "year activity" title, and its tooltips showed raw `YYYY-MM-DD` keys. | The heatmap is capped at 365 days, uses calendar arithmetic that is safe across DST, shows localized tooltip dates and an active-days count, and wraps its cells in a `RepaintBoundary`. |
| 14 | P3 | Overflows at 1.3× text scale in the detail bars, the kids card title, the certificate cards and the achievement grid. | Bars take the full width on phones, and the fixed heights now scale with the text scaler. |
| 15 | P4 | `OverallProgress.props` listed `overdueReviews` twice and left out the totals and `lastActiveDate`. | Corrected. |

## Improvements

- **Next milestone card.** Shows the locked achievement the user is closest to, with its progress, and opens the achievement sheet on tap. When every achievement is unlocked, it shows a celebration line instead.
- **Due-review nudge (adult).** A banner with a "ابدأ المراجعة" button that opens the memorization tab.
- **Tappable stats.** Pages read opens the Quran tab. Due reviews opens the memorization tab. The XP card shows a bar for progress to the next level.
- **Pull-to-refresh** on the whole page.
- Numbers count up (skipped when reduce-motion is on), and each stat card and chip has a combined screen-reader label.

## Decisions (delegated)

| Decision | Choice | Reason |
|---|---|---|
| Next-milestone ranking | Highest `progressPercent` among locked achievements; ties go to the smaller target | Surfaces the goal that is actually within reach |
| Juz Amma target | Size of the juz-30 key set from `QuranStructureMaps` (falls back to 564 if the map is missing) | Uses the canonical data, not a hard-coded number |
| Tab navigation from stats | `context.go` to the shell branch routes | Switches tabs in `StatefulShellRoute` without stacking pages |
| Due-review nudge scope | Adult only | Kids already have their own journey home |
| Heatmap window | Minimum 30 days, maximum 365 days | Matches the "year activity" title |

## Verification

- `flutter analyze`: no new issues. One pre-existing info in `kids_gamified_listen_page.dart` is unrelated to this change.
- `test/features/progress/`: new tests for silent reload, error retention, first-load error, the stale-load guard, XP-only refresh, XP failure fail-open, the `nextMilestone` rules and the Juz 30 achievement.
- `progress_page_layout_test.dart` renders the full page at 360dp in ar and en, in light and dark themes, and at 1.3× text scale. All renders are overflow-free.
