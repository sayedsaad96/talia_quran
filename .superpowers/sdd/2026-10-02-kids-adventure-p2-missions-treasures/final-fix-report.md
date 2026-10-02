# Final fix wave report

1. Day-sky headings: new `lib/features/memorization_plus/presentation/widgets/kids_section_heading.dart` (reads palette in own build). Used in `kids_treasures_page.dart` (certificates heading; removed palette read + import) and `kids_gamified_home_page.dart` `_missionTiles`. Tests: day-phase colour == `KidsWorldPalette.day.onScene` in `kids_treasures_page_test.dart` and `kids_gamified_home_page_test.dart`. Goldens changed: only `kids_treasures_day.png`, `kids_home_missions_day.png` (verified headings dark; night goldens unchanged).
2. Home reload: `_reloadAfterReader` helper in `kids_gamified_home_page.dart`, used by `onMushafTap` and `onReadingMissionTap` (guarded by `context.mounted`). Test: "returning from the Mushaf tab reloads the journey" (GoRouter + fake cubit; loads 1 -> 2).
3. Reader guard: `kidsReaderPageIsLoaded` in `kids_quran_reader_page.dart`, used in the `confirmRead` closure. Test in `kids_quran_reader_page_test.dart` (mismatch -> false, store empty).
4. `AccountDataReset.clearedPreferencePrefixes` += `kids_reading_receipts_`; `account_data_reset_test.dart` seeds and asserts clearing.
5. Removed double blank line in `kids_treasures_page.dart`.

Verify: focused tests pass; `flutter analyze` -> No issues found!; full `flutter test` -> +3068 -2 (only the 2 known public_privacy_pages_test failures); after a final lint-only tweak, analyze re-run clean and home page tests re-run green.
