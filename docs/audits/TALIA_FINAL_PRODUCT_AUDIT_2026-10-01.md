# Talia — Final Product Audit (2026-10-01)

Severity scale follows `AGENTS.md`: **P0** release blocker, **P1** critical, **P2** major, **P3** minor, **P4** improvement.

## Method and coverage

- Built a fresh debug APK from `main` (commit `1eefc8ae`) with the `.env` Supabase config and ran it on the connected emulator (Android 9, x64) with cleared app data. Each flow was exercised as a new guest user, and observations were checked against the code.
- `flutter analyze`: 3 warnings, all in the untracked `audit_artifacts/` folder; `lib/` is clean.
- `flutter test`: 2,852 passed, 4 failed (see §5).
- **Runtime-verified:** onboarding, Home, Quran tab and Mushaf reader, audio, prayer settings and alarm scheduling, adult memorization (plan → session → completion), khatmah creation and reading, azkar, Progress, kids setup and mission, path reset, English locale, login-form validation.
- **Code-verified only** (not exercised at runtime):
  - sign-in, sign-up, cloud sync, family dashboard, guardian linking (accounts cannot be created on the hosted Supabase project during an audit);
  - offline mode (the emulator's network could not be cut without root).
- **Not covered:** iOS, notification delivery and taps (only scheduling was checked), Adhan audio, certificates, khatm dua, smart wird, bookmarks, tutorial.

## 1. Executive summary

The core is solid: the Mushaf, audio, prayer-time maths, the memorization pipeline, azkar, khatmah maths and progress numbers all work. It is not functionally complete for a first-time user yet:

- **Traps and dead ends:** a new user can get stuck in a memorization session, exit the app by pressing back on the khatmah dashboard, and a child can get stranded mid-mission.
- **Data loss:** signing out deletes the khatmah plan and history, even though the dialog promises the opposite.
- **Misread numbers:** several screens make numbers read ten times too large.
- **Prayer coverage:** prayer times only cover 20 cities.

## 2. Critical issues

1. **P1 → Memorization session trap (runtime).**
   - **Problem:** after saving a plan, or choosing the adult path, the session opens via `context.go`, so there is no back arrow. Pressing back, then «أكمل لاحقًا» (continue later), puts the user straight back into the same session. The next back press closes the app.
   - **Evidence:** [custom_plan_setup_page.dart:336](../../lib/features/memorization_plus/presentation/pages/custom_plan_setup_page.dart) and [v2_session_page.dart:190](../../lib/features/memorization_plus/presentation/pages/v2_session_page.dart): `/memorization-plus` redirects back into the session.
   - **Fix:** `push` the session, or fall back to `/memorization` (the hub).
2. **P1 → Khatmah dashboard dead end (runtime).**
   - **Problem:** after creating a khatmah, the dashboard is the only screen. It has no back button, and Android back exits the app. On iOS there is no way out at all.
   - **Evidence:** [khatmah_setup_page.dart:192](../../lib/features/khatmah/presentation/pages/khatmah_setup_page.dart).
   - **Fix:** push the dashboard, or give it an explicit back button to Home.
3. **P1 → Kids mission stuck after guardian confirmation (runtime).**
   - **Problem:** when recording fails and the guardian confirms with the PIN, the ayah gets a ✓ but nothing moves on. There is no Next, and the completion screen never appears.
   - **Evidence:** the normal completion path in [kids_mode_cubit.dart:902](../../lib/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart) does not clear `recordingError`. The page listener then handles that error first and returns early ([kids_gamified_listen_page.dart:134](../../lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart)). This will be the normal path on phones without speech recognition.
   - **Fix:** clear the error on completion, and check completion before errors in the listener.
4. **P1 → Sign-out deletes the khatmah plan and history (code-verified).**
   - **Problem:** the khatmah is local-only (never synced), but normal sign-out wipes it. The dialog says «سيبقى تقدمك المحلي متاحًا» (your local progress stays available).
   - **Evidence:** [account_data_reset.dart:102](../../lib/core/identity/account_data_reset.dart) and [app_ar.arb:266](../../lib/core/l10n/app_ar.arb).
   - **Fix:** sync the khatmah, or keep it on sign-out, and make the warning accurate.
5. **P1 → Guest memorization "disappears" after the first sign-in (code-verified).**
   - **Problem:** guest review records are stored under the owner `local`, and reads are filtered to the signed-in user. The only way to recover them is an unprompted Settings tile with hard-coded text. Reading, khatmah and bookmark data do carry over, so the behaviour is inconsistent.
   - **Evidence:** [memorization_review_records_storage.dart:43](../../lib/features/memorization_plus/data/datasources/memorization_review_records_storage.dart) and [settings_account_tiles.dart:676](../../lib/features/settings/presentation/widgets/settings_account_tiles.dart).
   - **Fix:** offer the import right after sign-in.
6. **P1 → Numbers read ten times too large in Arabic (runtime).**
   - **Problem:** the "·" separator next to Arabic-Indic digits looks like the Arabic zero "٠".
     - Al-Muzzammil shows «مكية · ٢٠ آية» as 200 ayahs.
     - A 3-minute resume shows as «٣٠ د», and 4 minutes as «٤٠ د».
   - **Evidence:** [app_ar.arb:2402](../../lib/core/l10n/app_ar.arb) and [home_hero_section.dart](../../lib/features/home/presentation/widgets/home_hero_section.dart). The minutes come from `journeyActionMinutes`, where resume = 3.
   - **Fix:** use «،» or «–» as the separator in Arabic.
7. **P1 → Prayer times are wrong for most of the world (runtime).**
   - **Problem:** there are only 20 cities in 16 countries. There is no GPS, no manual coordinates, only 5 calculation methods and no Hanafi Asr option. Several listed cities (Doha, Kuwait, Dubai, Jakarta, Istanbul, Casablanca) default to the Muslim World League method instead of their local authority's.
   - **Evidence:** [prayer_cities.json](../../assets/data/prayer_cities.json) and [settings_prayer_tiles.dart:221](../../lib/features/settings/presentation/widgets/settings_prayer_tiles.dart).
   - **Fix:** add device location or manual coordinates, expose all `adhan` methods, and add a madhab setting.
8. **P1 (content policy) → The closing ayah is hard-coded and not verbatim.**
   - **Problem:** «أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ» is typed into the ARB in plain script (no «ٱ»). It is only the end of Ar-Ra'd 13:28, but it is labelled as the whole ayah «الآية ٢٨». The canonical `quran.json` text differs.
   - **Evidence:** [app_ar.arb:2109](../../lib/core/l10n/app_ar.arb). This is the same pattern already fixed in onboarding (CONTENT-1).
   - **Fix:** load it from the corpus and mark it as an excerpt.

## 3. Functional issues

- **P2 → Plan templates under-deliver (runtime).** «خفيف» (light) promises 3 ayahs a day but gives 2. «متوازن» (balanced) promises 5 and gives 3; «مكثف» (intense) promises 10 and gives 7. The session-minutes cap wins ([plan_schedule_policy.dart:33](../../lib/features/memorization_plus/domain/services/plan_schedule_policy.dart)), and the finish-date estimate uses the advertised number. **Fix:** align each template's minutes with its ayah count.
- **P2 → The recitation "Accuracy level" setting (70/85/92%) does nothing.** `getSimilarityThreshold()` is never called. The engine always uses a hard-coded 0.88 ([recitation_evaluator.dart:17](../../lib/core/memorization/v2/recitation_evaluator.dart)), while the UI says the default is 85%. **Fix:** wire it into the engine, or remove it.
- **P2 → False "action required" alert on Home (runtime).** After a successful first session, every new user gets the top Home card «تنبيه تعليمي — مطلوب اتخاذ إجراء» (learning alert — action required). It leads to a hub with nothing to do. Retention is 0 when there are no reviews yet, and 0 < 0.70 triggers it ([adaptive_recommendations_usecase.dart:45](../../lib/features/memorization_plus/domain/usecases/adaptive_recommendations_usecase.dart)). **Fix:** require minimum review data first.
- **P2 → Prayer alerts setup gives stale feedback (runtime).** Prayer alerts are off by default. After choosing a city, the alerts tile keeps saying «اختر مدينتك أولًا» (choose your city first), and its button does nothing until the page is reopened ([settings_prayer_notification_tiles.dart:192](../../lib/features/settings/presentation/widgets/settings_prayer_notification_tiles.dart)).
- **P2 → A child can leave the kids track without the PIN (runtime).** The kids-home gear → Reset path works with one tap and no PIN, unless the guardian is linked from another device ([memorization_path_settings_sheet.dart:114](../../lib/features/memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart)). **Fix:** require the local PIN if one exists.
- **P2 (content) → Onboarding Mushaf card.** It stacks Al-Fatiha's basmala above Al-Isra 17:45 under a «سورة الإسراء» label, which implies a basmala before that ayah ([onboarding_mushaf_bento_view.dart:168](../../lib/features/onboarding/presentation/widgets/onboarding_mushaf_bento_view.dart)).
- **P2 (content) → Closing dua has no source.** It is an app-written dua with no cited source, shown after every session. The content policy says such items should stay blocked until reviewed.
- **P3 → Speech recognition missing is shown as a microphone problem.** The message is «تعذّر استخدام الميكروفون» (couldn't use the microphone). «بدء التسجيل» (start recording) stays the main button, and the self-grade option is a small link. The mic permission is also requested at every session start, during the learning phase.
- **P3 → Activity feed taps go to the wrong place.** A "review" entry opens the hub (the route gets no parameters), and a "memorize" entry ignores its `surahId`.
- **P3 → Review with nothing due opens plan creation.** «مراجعة بالتسميع» (review by recitation) with no reviews due silently opens plan creation instead of explaining.
- **P3 → Reopening azkar starts at the first item.** It shows the already-completed first item, not the next unfinished one.

## 4. UX issues

- **P3 → Tab screens open inside Home.** Quran and Memorization screens opened from Home (first-run card, "شيء آخر" sheet, learning alert) open inside the Home tab. Home stays highlighted and there is no back arrow ([home_first_run.dart:20](../../lib/features/home/presentation/widgets/home_first_run.dart)).
- **P3 → The "شيء آخر" (something else) sheet opens under the bottom nav.** The nav bar stays active above it because it is not opened on the root navigator.
- **P3 → Khatmah reader header is covered.** The long-press hint overlaps the khatmah strip and hides the reader's audio and menu buttons.
- **P3 → Progress does not match the completion message.** The session ends with «حفظتَ آيتين» (you memorized two ayahs), but Progress shows 0 memorized, the first-ayah badge at 0/1 and a 0% retention rate.
- **P3 → Home progress widgets are unlabelled.** The ring (percentage of the whole Quran memorized, so "0%" for weeks) and the 7 weekly dots have no labels.
- **P3 → Latin and Arabic-Indic digits are mixed** throughout the Arabic UI: page numbers, "XP", plan templates, «1-2», «2/2», the mini-player.
- **P4 → Copy and polish:**
  - Kids home ignores the child's name, and a new child sees «Last mission».
  - English pluralization bugs: "1 stars", "1 times".
  - Invisible button remnants on the kids listen screen.
  - The internal name "Memorization Plus" appears in user-facing copy.
  - «الكتلة» vs «المقطع» are used for the same thing.
  - Plan templates have no selected state.
  - Login «Skip» (opened from Settings) goes Home instead of back.
  - Pressing back dismisses the kids setup sheet and loses everything typed.
  - The listening quiz's empty state has no call to action.
  - There are 71 hard-coded bilingual strings outside the ARB files.

## 5. Performance and stability

- **P3 → Quran text search blocks the UI.** Each search re-normalizes all 6,236 ayahs on the UI isolate: about 252 ms per query measured on a desktop (Dart JIT), so likely a visible freeze on phones. Results are silently capped at 50. **Fix:** pre-normalize once, or use `compute`.
- **Tests:**
  - 3 golden/preview-capture failures: `home_night_goldens_test` (light), `home_preview_capture_test` (dark, light).
  - `khatmah_setup_page_test` "renders preset chips" fails because it depends on today's date: "31" matches two widgets.
  - `flutter analyze`: 3 warnings, all in the untracked `audit_artifacts/` folder.

## 6. Cross-feature issues

- **Sign-out and first sign-in treat data differently** (critical issues 4 and 5): khatmah, reading, bookmarks and memorization each behave differently.
- **The false learning alert pushes "continue reading" down** from the top Home card.
- **Resetting the path to adult** jumps straight into a new session beyond today's already-completed plan.

## 7. What is working well (verified on the device)

- **Onboarding:** back, skip and the adult/child fork, persisted correctly.
- **Mushaf:** tajweed rendering, page turns, and the read-confirmation timer. Reading statistics came out exact: 3 pages, 20 ayahs.
- **Audio:** streaming, the media session and the mini player.
- **Surah filtering:** works, with correct Makki/Madani labels.
- **Prayer times:** Cairo times are correct, including DST, and the native alarms are scheduled at those exact times.
- **Memorization:** the full pipeline (hints → self-grade gated behind revealing the ayah → block review → XP, streak and daily plan).
- **Khatmah:** maths and progress are correct and stay strictly separate from free reading.
- **Azkar:** sourced content, counters, auto-advance and saved progress.
- **Kids:** setup with PIN, the "listen 3 times" gate and the journey map.
- **English locale and login validation.**

## 8. Final action list

1. Replace `go` with `push` (or add explicit back buttons) for the memorization session, the khatmah dashboard and completion screens; fix the `/memorization-plus` fallback.
2. Clear `recordingError` on kids completion and reorder the listener checks.
3. Keep the khatmah through sign-out (or sync it), correct the sign-out warning, and prompt the guest-data import after sign-in.
4. Replace the "·" separator in Arabic strings.
5. Add prayer location input (GPS or coordinates), all calculation methods and a madhab option; refresh the alerts tile after a city is chosen.
6. Load the closing ayah from `quran.json`; send the closing dua and the onboarding basmala card for religious review.
7. Wire up or remove the accuracy setting; align the plan templates with their session minutes.
8. Gate the retention alert on real review data.
9. Require the local PIN to leave the kids track.
10. Move search off the UI isolate; fix the date-dependent test.

## Open questions

- Is the one-tap kids path reset without a PIN (when no remote guardian is linked) intentional? The code comment says the dialog counts as parent confirmation.
- After a kids ayah is completed, the home offers "Ready for review — Ayahs 1-1" instead of the next ayah. Is this the intended linked-review step?

## Fix log — critical issues (2026-10-01)

| # | Issue | Status | What changed |
|---|---|---|---|
| 1 | Memorization session trap | Fixed, test-verified | A session with no history shows a close button. Exits fall back to the hub (`/memorization`), not `/memorization-plus`, which redirected back into the session. Android back no longer closes the app. `v2_session_page.dart`, `v2_session_exit_test.dart`. |
| 2 | Khatmah dashboard dead end | Fixed, test-verified | New `FallbackPopScope` (`core/widgets/fallback_pop_scope.dart`). Dashboard → Home, history → dashboard, completion → Home. Back buttons appear when there is no history. |
| 3 | Kids mission stuck after guardian confirmation | Fixed, test-verified | `KidsModeCubit.markCompleted` clears `recordingError` on completion, so the page opens the completion screen. Covered in `kids_mode_cubit_test.dart` (fails without the fix). |
| 4 | Sign-out deletes the khatmah | Copy fixed; data behaviour unchanged (decision D1) | The sign-out warning now says the khatmah plan and history are device-only and will be removed. Copy test added. |
| 5 | Guest memorization hidden after first sign-in | Fixed, test-verified | After sign-in sync, the login flow offers to import guest records when any are claimable. The count goes through `countClaimableLocalReviewRecords`, which shares its eligibility check with the claim. The Settings dialog now uses localized strings (`guestImport*`). |
| 6 | Middle dot read as Arabic zero | Fixed, test-verified | `app_ar.arb` uses «، » instead of « · ». Dart call sites use `context.listSeparator`; share cards use `SocialShareCopy.separator`. Goldens updated: `home_loaded_dark`, onboarding `ar_fork_*`. |
| 7 | Prayer coverage | Partly fixed (decision D2) | All `adhan` methods are offered except `tehran` and `other`. There is now an Asr madhab setting (automatic by city, majority, Hanafi). Local-authority defaults: Doha `qatar`, Kuwait `kuwait`, Dubai `dubai`, Istanbul `turkey`, Jakarta and Kuala Lumpur `singapore`; Karachi uses Hanafi Asr. The method picker no longer mislabels unknown methods as MWL. Added a **custom location** (latitude/longitude, device time zone; Eastern Arabic digits accepted). It is validated, and Adhan scheduling resolves it through `PrayerTimesService.selectedCity()`. GPS is still not offered (D2). |
| 8 | Closing ayah hard-coded | Fixed, test-verified | `ClosingMomentAyahCard` loads Ar-Ra'd 13:28 in full from the corpus and fails closed if it is unavailable. The `closingAyah` / `closingAyahSource` ARB keys were removed. |

### Decisions

| ID | Decision | Reason |
|---|---|---|
| D1 | Keep clearing the khatmah on sign-out, but warn accurately. | Khatmah is account-owned by design (`AccountDataReset`). Keeping it would leak it into the next account or guest, and real sync needs a Supabase migration. Follow-up: khatmah cloud sync. |
| D2 | Use manual coordinates instead of GPS; `tehran` (Ja'fari) and `other` are not offered. | Coordinates cover every location with no new dependency, no location permission and no privacy-policy change, and they work offline. GPS can be added later on top of `setCustomLocation`. |

### Not changed by these fixes

- The closing dua and the onboarding basmala card still need religious review.
- Pre-existing test failures remain: `home_loaded_light` and the home preview captures (goldens), and the date-dependent `khatmah_setup_page_test` "renders preset chips".

### Runtime verification (2026-10-01, debug build on the Android 9 emulator)

- Saving a plan opens the session with a close button. «أكمل لاحقًا» (continue later) leads to the memorization hub.
- Creating a khatmah opens the dashboard with a back button, and Android back goes to Home.
- Kids: after a microphone failure and guardian PIN confirmation, the «Well done!» completion screen opens.
- Session completion shows the full Uthmani text of 13:28 from the corpus with its reference.
- Home shows «محفوظ، ٣ د» and «صفحة 1، ٤ د» (3 and 4 minutes), with no dot next to digits.
- Custom location (coordinates, device zone Africa/Cairo) shows «موقع مخصص» with prayer times on Home.
- Not verified at runtime: the sign-in import prompt and the sign-out warning, because no test account was available.

### Follow-ups found during verification

- Fixed in code but not yet seen in a build: the daily wird page number now uses locale digits (`daily_wird_card.dart`, `unified_journey_action_mapper.dart`).
- The free-reading "continue" card still shows the page number in Latin digits («الصفحة 202»).
- The prayer-alerts tile now rebuilds when the location changes (`PrayerSettingsPage` is stateful and `PrayerTimesSettingsSection.onChanged` rebuilds it); test-verified.
- Saving a custom location gives no success confirmation.

## Fix log — P2 and P3 batch (2026-10-01)

| Issue | Status | What changed |
|---|---|---|
| False "learning alert — action required" (P2) | Fixed, test-verified | Retention alerts need at least 10 ayahs (`AdaptiveRecommendationsUsecase.minAyahsForRetentionSignal`). |
| Accuracy-level setting did nothing (P2) | Fixed, test-verified | The session cubit reads `SettingsRepository.getSimilarityThreshold()`; a challenging plan still enforces 0.92. Levels: 70 / **88** (was labelled 85, the engine always used 0.88) / 92. A stored 0.85 reads as balanced. |
| Plan templates under-deliver (P2) | Fixed, test-verified | Presets fit their ayahs: light 3/day in 20 min, balanced 5/day in 30, intense 10/day in 50, Juz Amma 20. The estimate uses the ayahs that fit, and a hint appears when the minutes are too short. Juz Amma copy corrected (it ends at An-Naba, not Al-Fil). |
| Child leaves the kids track without the PIN (P2) | Fixed, test-verified | Resetting the path asks for the local parent PIN whenever one exists, not only when a guardian is linked. |
| Prayer-alerts tile stale after choosing a city (P2) | Fixed, test-verified | The tile rebuilds when the location changes. |
| Speech recognition unavailable (P3) | Fixed, test-verified | Self-grading becomes the main button, "try recording again" stays as a link, and the message names the real cause. |
| Tab screens opened inside Home (P3) | Fixed, test-verified | New `context.openLocation` switches tabs for tab locations. "Something else" opens on the root navigator with a SafeArea. |
| Activity-feed taps (P3) | Fixed, test-verified | Review opens the current review location; memorize opens that surah's practice. |
| Review with nothing due opened plan creation (P3) | Fixed | A message explains instead. |
| Azkar reopened on a finished item (P3) | Fixed, test-verified | Opens at the first unfinished dhikr. |
| Khatmah reader header covered by the hint (P3) | Fixed | The hint is laid out under the header. |
| Completion "you memorized" vs Progress (P3) | Fixed | Copy now says «تعلّمتَ…، وبالمراجعة تثبت» (you learned…; reviews make it stick). |
| Unlabelled Home ring and dots, Latin digits (P3) | Fixed | Ring caption, weekday letters, XP and wird/resume page numbers use locale digits. |
| Custom location gave no confirmation | Fixed, test-verified | A confirmation snackbar appears after saving. |
| Date-dependent tests | Fixed | `smart_wird_progress_store_test` pins its clock; `khatmah_setup_page_test` matches the duration, not the end date. |

Validation: `flutter analyze` clean. 2,886 tests pass, 3 fail; all 3 were failing before (home light golden and two preview captures). Goldens updated: `home_loaded_dark` (new captions).

Still open: the closing dua and the onboarding basmala card need religious review. Remaining P4 copy and polish items are listed in §4. The P2/P3 batch has not been re-verified on the device.

### Runtime verification of the P2/P3 batch (2026-10-01, Android 9 emulator)

- Home: «صفحة ١، ٤ د», «٠ XP», the ring captioned «حُفظ من القرآن», weekday letters under the dots (today highlighted), and «مكية، ١٩ آية» for Al-Alaq.
- The "something else" sheet opens above a dimmed bottom nav. Choosing «القرآن الكريم» switches to the Quran tab, which is then highlighted.
- «مراجعة بالتسميع» with nothing memorized shows the explanatory message.
- Plan presets show «٣ آيات/يوم • ٥ أيام • ٢٠ دقيقة» and Juz Amma «من الناس إلى النبأ». The light summary shows 20 minutes.
- Without a speech recognizer (this emulator), recitation shows «قيّم تسميعك بنفسك» as the main button, with the real cause and «حاول التسجيل مجددًا».
- Khatmah reader: session bar, reader top bar, then the hint; nothing is covered.
- Reopening evening azkar after finishing item 1 resumes at item 2 (Al-Ikhlas).
- The accuracy level shows «متوازن ٨٨٪».
- Kids: gear → Reset path asks for the parent PIN, and a wrong PIN shows «Incorrect code».
- The original emulator data was restored afterwards.

Remaining Latin digits seen: the azkar counter («1 من 22», «0 من 3») and the Home prayer countdown («53 دقيقة»). The activity-feed page number was fixed after this build («قراءة الصفحة ١»).

## Fix log — remaining items (2026-10-01)

| Issue | Status | What changed |
|---|---|---|
| Azkar counter and prayer countdown in Latin digits | Fixed, test-verified | Azkar counters, hub counts, free tasbeeh, smart wird and subcategory chips use locale digits. `formatPrayerRemainingTime*` return Arabic-Indic digits in Arabic («٥٣ دقيقة»). |
| Other Latin digits | Fixed, test-verified | Session ranges («الآيات من ١ إلى ٢», «اجتزتَ ٢ من ٢»), the passed tile, the mini player («آية ١») and the activity-feed page. |
| Quran text search blocked the UI (P3) | Fixed, test-verified | The normalized corpus is built once in a background isolate (`compute`) and cached; queries scan the cache. New real-corpus test `quran_search_test.dart`. |
| Prayer alerts off by default (P2 remainder) | Fixed, test-verified | The first time a location makes alerts possible, they switch on, unless the user already chose. Full Adhan audio stays opt-in. |
| Kids home ignores the name; «Last mission» (P4) | Fixed | The greeting uses the setup nickname («مرحباً يا {name}، بطل الحفظ!»). The label is «مهمتك الآن». |
| "1 stars", "1 times" (P4) | Fixed, test-verified | ICU plurals in both languages, with localized counts. |
| Invisible kids buttons (P4) | Fixed, test-verified | The disabled listen button has visible styling; «Try from memory» is removed once the ayah is complete. |
| "Memorization Plus" in copy (P4) | Fixed | Replaced with «قسم الحفظ» or «تبويب الحفظ». |
| «الكتلة» vs «المقطع» (P4) | Fixed | «قيّم تسميع المقطع بنفسك». |
| Plan presets had no selected state (P4) | Fixed | The applied preset is outlined and checked while its values are unchanged. |
| Login «Skip» from Settings went Home (P4) | Fixed | It pops back when there is history. |
| Back discarded the kids setup sheet (P4) | Fixed | A confirmation appears when anything was typed. |
| Listening quiz empty state had no CTA (P4) | Fixed | A «ابدأ الحفظ» button opens practice by surah. |

### Still open

- **Religious review (not code):** the closing dua and the onboarding basmala card.
- **71 hard-coded bilingual strings (P4):** a mechanical move into the ARB files, deferred as a separate change because of its regression surface.
- **New finding (P3) — English user guide:** 78 of 189 `tutorial*` strings in `app_en.arb` are placeholders («Guide 1», «What it does», «Step 1»). Some Arabic guide steps also describe controls that no longer exist (for example a «تأكيد القراءة» (confirm reading) button and a font-size button in the reader). This needs a content pass.
- **Pre-existing golden failures:** `home_loaded_light` and the two home preview captures need a decision on re-baselining.

## Fix log — user guide (2026-10-01)

- **Rewritten** (`tutorialS1–S12`, Arabic and English): the English guide had 160 placeholder strings («Guide 1», «Step 1»…), and the Arabic guide described a hub, controls and storage details that no longer exist. Every step now matches the current app: intro and path choice, Home, the reader (long-press options, three-dot menu, automatic read counting), search and bookmarks, memorization phases and hints, adhkar, the daily plan and reviews, plan presets, kids mode and the parent PIN, progress, settings, offline and data (including that signing out removes the khatmah).
- **Two new sections:** the Khatmah (13) and Prayer times and alerts (14). The guide now shows 14 topics.
- Removed internal terms (SharedPreferences, Isar) and development-only notes from user-facing text.

## Runtime verification, final batch (Android 9 emulator)

- Adhkar hub and counters: «٢٢ ذكر», «١ من ٢٢ مكتمل», «٠ من ٣».
- Home prayer countdown: «أذان الفجر خلال ٦ ساعات و ١١ دقيقة».
- Saving a custom location shows «حُفظ الموقع…», and prayer alerts switch on at once (toggle on, prayer chips visible).
- Kids: back with a typed name shows «Discard child setup?» with «Keep editing» / «Leave without saving». The greeting is «Welcome, Yusuf, memorization hero!» and the card says «Your mission». «Listen to the ayah 3 times…» reads correctly.
- User guide: 14 topics, new titles, expanded section renders.
- The emulator's original data was restored afterwards.

### Still open

- **Religious review (not code):** the closing dua and the onboarding basmala card.
- **71 hard-coded bilingual strings:** deferred to a separate change.
- **Golden baselines:** `home_loaded_light` and the two home preview captures were failing before this work and still need a re-baseline decision.
