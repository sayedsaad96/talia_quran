# Talia Feature Inventory

| ID | Feature / Screen | Source Path | Route / Entry Point | Guards / Flags | Runtime Reachable | Evidence | Status |
|---|---|---|---|---|---|---|---|
| F-001 | Splash Screen | `lib/features/splash/presentation/pages/splash_page.dart` | `AppRoutes.splash` (`/splash`) | Minimal pre-DI splash | Yes | App launch entry point | Verified |
| F-002 | Onboarding Flow | `lib/features/onboarding/presentation/pages/onboarding_page.dart` | `AppRoutes.onboarding` (`/onboarding`) | Shown if `onboarding_completed` is false | Yes | Initial launch | Verified |
| F-003 | Login & Auth | `lib/features/auth/presentation/pages/login_page.dart` | `AppRoutes.login` (`/login`) | Guest upgrade / protected routes | Yes | Nudge banners / settings / family dashboard | Verified |
| F-004 | Update Password | `lib/features/auth/presentation/pages/update_password_page.dart` | `AppRoutes.updatePassword` (`/auth/update-password`, `/update-password`) | Auth callback deep link | Gated | Reached via Supabase recovery link | Verified |
| F-005 | Home Screen | `lib/features/home/presentation/pages/home_page.dart` | `AppRoutes.home` (`/` - Shell Tab 0) | Public | Yes | Shell tab 0 default | Verified |
| F-006 | Home Hero Action | `lib/features/home/presentation/widgets/unified_hero_action_card.dart` | Embedded in `HomePage` | `JourneyFeatureFlags.unifiedJourneyEnabled` | Yes | Home scroll view | Verified |
| F-007 | Khatmah Hero Card | `lib/features/khatmah/presentation/widgets/khatmah_hero_card.dart` | Embedded in `HomePage` | None | Yes | Home scroll view | Verified |
| F-008 | Daily Wird Card | `lib/features/home/presentation/pages/home_page_widgets.dart` (`_DailyWirdCard`) | Embedded in `HomePage` | `dailyWirdPageDetail != null` | Yes | Home scroll view | Verified |
| F-009 | Home Engagement & Heatmap | `lib/features/home/presentation/pages/home_page_widgets.dart` | Embedded in `HomePage` | None | Yes | Home scroll view | Verified |
| F-010 | Home Quick Actions | `lib/features/home/presentation/pages/home_page_widgets.dart` (`_QuickActionsGrid`) | Embedded in `HomePage` | None | Yes | Home scroll view | Verified |
| F-011 | Quran Index (Surah List) | `lib/features/quran/presentation/pages/quran_page.dart` | `AppRoutes.quran` (`/quran` - Shell Tab 1) | Public | Yes | Shell tab 1 | Verified |
| F-012 | Quran Index (Juz List) | `lib/features/quran/presentation/pages/quran_page.dart` | Embedded in `QuranPage` (Tab 2) | Public | Yes | Tab switcher on Quran page | Verified |
| F-013 | Quran Bookmarks Browser | `lib/features/quran/presentation/pages/bookmarks_page.dart` (`BookmarksTab`) | Embedded in `QuranPage` (Tab 3) | Public | Yes | Tab switcher on Quran page | Verified |
| F-014 | Quran Search & Filter | `lib/features/quran/presentation/widgets/surah_search_bar.dart` | Embedded in `QuranPage` | Public | Yes | Search input on Quran page | Verified |
| F-015 | Quran Reader by Surah | `lib/features/quran/presentation/pages/quran_reader_page.dart` | `/quran/surah/:surahId` | `_isValidSurahId(surahId)` | Yes | Tap surah in Surah list | Verified |
| F-016 | Quran Reader by Page | `lib/features/quran/presentation/pages/quran_reader_page.dart` | `/quran/page/:pageNumber` | Valid page 1-604 | Yes | Tap page in Juz list, Daily wird, or Hero | Verified |
| F-017 | Quran Reader in Khatmah Mode | `lib/features/quran/presentation/pages/quran_reader_page.dart` | `/quran/page/:pageNumber?mode=khatmah` | Active Khatmah plan | Yes | Khatmah card resume button | Verified |
| F-018 | Ayah Context Menu & Actions | `lib/features/quran/presentation/pages/quran_reader_page.dart` | Reader bottom sheet | Ayah tap in reader | Yes | Tap any ayah in reader | Verified |
| F-019 | Quran Audio Mini Player | `lib/features/quran/presentation/widgets/quran_mini_player_bar.dart` | Shell overlay in `AppShell` | Audio playing / loaded | Yes | Triggered on ayah/surah audio play | Verified |
| F-020 | Reciter Selector Sheet | `lib/features/quran/presentation/widgets/reciter_selector_sheet.dart` | Modal bottom sheet | Reader audio controls / Settings | Yes | Tap reciter name in audio bar/settings | Verified |
| F-021 | Daily Ayah Redirect | `lib/core/router/app_router.dart` | `AppRoutes.quranDaily` (`/quran/daily`) | Date-seeded random redirect | Yes | Notification payload / deep link | Verified |
| F-022 | Khatmah Setup | `lib/features/khatmah/presentation/pages/khatmah_setup_page.dart` | `AppRoutes.khatmahSetup` (`/khatmah/setup`) | Public | Yes | Khatmah card when no plan | Verified |
| F-023 | Khatmah Dashboard | `lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart` | `AppRoutes.khatmahDashboard` (`/khatmah/dashboard`) | Public | Yes | Khatmah card header / details tap | Verified |
| F-024 | Khatmah Completion | `lib/features/khatmah/presentation/pages/khatmah_completion_page.dart` | `AppRoutes.khatmahCompletion` (`/khatmah/completion`) | Guard: `isValidCompletion` in extra | Yes | Reached upon reading final page 604 | Verified |
| F-025 | Khatm Al-Quran Dua | `lib/features/khatmah/presentation/pages/khatm_dua_page.dart` | `AppRoutes.khatmDua` (`/quran/khatm-dua`) | None (public) | Gated / Partially Hidden | Reached ONLY from KhatmahCompletionPage | Needs Review |
| F-026 | Memorization Hub | `lib/features/memorization_plus/presentation/pages/memorization_hub_page.dart` | `AppRoutes.memorizationHub` (`/memorization` - Shell Tab 2) | Public | Yes | Shell tab 2 | Verified |
| F-027 | Path Selection (Adult vs Kids) | `lib/features/memorization_plus/presentation/pages/path_selection_page.dart` | `AppRoutes.memorizationPlus` (`/memorization-plus`) | Route guard entryRedirect | Yes | Settings path switch / first hifz entry | Verified |
| F-028 | Practice by Surah | `lib/features/memorization_plus/presentation/pages/practice_surah_page.dart` | `AppRoutes.hifzPracticeSurah` (`/memorization/practice-surah`) | Adult only | Yes | Memorization Hub practice button | Verified |
| F-029 | Custom Plan Setup | `lib/features/memorization_plus/presentation/pages/custom_plan_setup_page.dart` | `AppRoutes.memorizationPlusCustomPlan` (`/memorization-plus/custom-plan`) | Adult only | Yes | Memorization Hub create custom plan | Verified |
| F-030 | Daily Plan Details | `lib/features/memorization_plus/presentation/pages/daily_plan_page.dart` | `AppRoutes.memorizationPlusDailyPlan` (`/memorization-plus/daily-plan`) | Adult only | Yes | Memorization Hub daily plan card | Verified |
| F-031 | V2 Memorization Session | `lib/features/memorization_plus/presentation/pages/v2_session_page.dart` | `AppRoutes.memorizationV2Session` (`/memorization-v2/session`) | Adult only, valid surahId/startAyah | Yes | Hub start session / Smart coach action | Verified |
| F-032 | STT Voice Evaluation & Mic | `lib/features/memorization_plus/presentation/pages/v2_session_page.dart` | Embedded in `V2SessionPage` | `Permission.microphone` | Yes | Voice mode in V2 session | Verified |
| F-033 | Kids Gamified Home | `lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart` | `AppRoutes.memorizationPlusKidsHome` (`/memorization-plus/kids-home`) | Kids profile guard | Yes | When profile is child | Verified |
| F-034 | Kids Gamified Journey Map | `lib/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart` | `AppRoutes.memorizationPlusKidsJourney` (`/memorization-plus/kids-journey`) | Kids profile guard | Yes | Kids home journey map tap | Verified |
| F-035 | Kids Gamified Stage | `lib/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart` | `AppRoutes.memorizationPlusKidsStage` (`/memorization-plus/kids-stage`) | Kids profile guard | Yes | Stage tap in Kids journey | Verified |
| F-036 | Kids Gamified Listen & Recite | `lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart` | `AppRoutes.memorizationPlusKids` (`/memorization-plus/kids`) | Kids profile guard | Yes | Mission start in Kids journey | Verified |
| F-037 | Kids Gamified Completion | `lib/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart` | `AppRoutes.memorizationPlusKidsCompletion` (`/memorization-plus/kids-completion`) | Kids profile guard | Yes | Completing mission in Kids flow | Verified |
| F-038 | Kids Quran Reader | `lib/features/quran/presentation/pages/kids_quran_reader_page.dart` | `AppRoutes.memorizationPlusKidsQuran` (`/memorization-plus/kids-quran`) | Kids profile guard | Yes | Kids home reading button | Verified |
| F-039 | Guardian Linking Page | `lib/features/memorization_plus/presentation/pages/guardian_linking_page.dart` | `AppRoutes.memorizationPlusGuardianLinking` (`/memorization-plus/guardian-linking`) | Child with required guardian link | Gated | Child onboarding / login redirect | Verified |
| F-040 | Family Dashboard | `lib/features/memorization_plus/presentation/pages/family_dashboard_page.dart` | `AppRoutes.familyDashboard` (`/family-dashboard`) | Remote protected: Parent mode + Authenticated | Gated | Home parent card / Settings parent tile | Verified |
| F-041 | Child Detail Dashboard | `lib/features/memorization_plus/presentation/pages/child_detail_page.dart` | `AppRoutes.childDetail` (`/family-dashboard/child`) | Remote protected: Parent mode + Authenticated | Gated | Family dashboard child card tap | Verified |
| F-042 | Azkar Main Hub | `lib/features/azkar/presentation/pages/azkar_page.dart` | `AppRoutes.azkar` (`/azkar` - Shell Tab 3) | Public | Yes | Shell tab 3 | Verified |
| F-043 | Azkar Counter (Morning/Evening) | `lib/features/azkar/presentation/pages/azkar_category_page.dart` | `/azkar/:category` (`morning`, `evening`) | Public | Yes | Tap morning/evening card in Azkar hub | Verified |
| F-044 | General Azkar & Selected Duas | `lib/features/azkar/presentation/pages/general_azkar_page.dart` | `/azkar/:category` (`general`, `duas`) | Public | Yes | Tap general/duas card in Azkar hub | Verified |
| F-045 | Progress Hub | `lib/features/progress/presentation/pages/progress_page.dart` | `AppRoutes.progress` (`/progress` - Shell Tab 4) | Public | Yes | Shell tab 4 | Verified |
| F-046 | Completion Certificate Viewer | `lib/features/certificate/presentation/pages/certificate_page.dart` | `/certificate` | Award in extra or empty state | Yes | Certificate card in Progress page / Home badge | Verified |
| F-047 | Categorized Achievements Modal | `lib/features/progress/presentation/widgets/progress_achievements.dart` | Modal bottom sheet | Achievements tap | Yes | Tap achievement badge in Progress page | Verified |
| F-048 | Social Share Studio | `lib/core/widgets/social_share/social_share_sheet.dart` | Modal bottom sheet | Share button on Progress, Reader, Ayah | Yes | Tap share icon on progress or reader | Verified |
| F-049 | Settings Main Page | `lib/features/settings/presentation/pages/settings_page.dart` | `AppRoutes.settings` (`/settings`) | Public | Yes | Header gear icon on Home / Quick actions | Verified |
| F-050 | Settings Notifications | `lib/features/settings/presentation/widgets/settings_notification_tiles.dart` | Embedded in `SettingsPage` | Public | Yes | Notification section in Settings | Verified |
| F-051 | Settings Memorization Path | `lib/features/settings/presentation/widgets/settings_memorization_tiles.dart` | Embedded in `SettingsPage` | Public | Yes | Memorization section in Settings | Verified |
| F-052 | Settings Account & Cloud Sync | `lib/features/settings/presentation/widgets/settings_account_tiles.dart` | Embedded in `SettingsPage` | Public | Yes | Account section in Settings | Verified |
| F-053 | Tutorial Guide | `lib/features/tutorial_guide/presentation/pages/tutorial_guide_page.dart` | `AppRoutes.tutorialGuide` (`/tutorial-guide`) | Public | Yes | Home tour banner / Settings | Verified |
| F-054 | Privacy Policy | `lib/features/settings/presentation/pages/privacy_policy_page.dart` | `AppRoutes.privacyPolicy` (`/settings/privacy-policy`) | Public | Yes | Settings About section tap | Verified |
| F-055 | QCF Rendering POC | `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart` | `AppRoutes.qcfRenderingPoc` (`/debug/qcf-rendering-poc`) | `kDebugMode` only | Unreachable in Release | Debug only, no UI link | Dev/Debug |

## Coverage gaps
- `AppRoutes.childOnboarding` (`/onboarding/child`) is defined in the router, but its route definition immediately redirects to `AppRoutes.memorizationPlusKidsHome`. There is no distinct ChildOnboardingPage in the codebase.
- `KhatmDuaPage` (`/quran/khatm-dua`) is currently ONLY reachable from `KhatmahCompletionPage`. A user reading through the Quran cannot access Dua Khatm Al-Quran from the reader (after page 604 / Surah An-Nas) or from the Azkar/Duas hub.

## Orphan / hidden implementations
- `QcfRenderingPocPage` (`/debug/qcf-rendering-poc`): Proof-of-concept page for QCF font rendering with no navigation entry point in the app UI.
- `KhatmDuaPage` (`/quran/khatm-dua`): Intended religious content that is hidden behind completing an entire 604-page Khatmah plan.
