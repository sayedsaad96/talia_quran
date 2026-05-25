# Real User Experience Testing Report

Date: 2026-05-24  
Mode: Audit-only UX/product review. No application source code was modified.

## Review Method

This report simulates real users from the Dart code paths, routes, screens, Cubits, and visible UI copy. It focuses on production user experience, product logic, emotional motivation, accessibility, Arabic UX, and real-life interruption scenarios.

Primary code reviewed:

- `lib/core/router/app_router.dart`
- `lib/core/services/app_session_service.dart`
- `lib/core/widgets/app_shell.dart`
- `lib/features/splash/presentation/pages/splash_page.dart`
- `lib/features/onboarding/presentation/pages/onboarding_page.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/home/presentation/pages/home_page_widgets.dart`
- `lib/features/quran/presentation/pages/quran_page.dart`
- `lib/features/quran/presentation/pages/quran_reader_page.dart`
- `lib/features/hifz/presentation/pages/hifz_page.dart`
- `lib/features/hifz/presentation/pages/hifz_session_page.dart`
- `lib/features/memorization_plus/presentation/pages/path_selection_page.dart`
- `lib/features/memorization_plus/presentation/pages/custom_plan_setup_page.dart`
- `lib/features/memorization_plus/presentation/pages/daily_plan_page.dart`
- `lib/features/memorization_plus/presentation/pages/kids_journey_page.dart`
- `lib/features/memorization_plus/presentation/pages/kids_mode_page.dart`
- `lib/features/memorization_plus/presentation/pages/guardian_linking_page.dart`
- `lib/features/memorization_plus/presentation/pages/parent_dashboard_page.dart`
- `lib/features/memorization_plus/presentation/pages/quiz_page.dart`
- `lib/features/azkar/presentation/pages/azkar_category_page.dart`
- `lib/features/progress/presentation/pages/progress_page.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/settings/presentation/pages/settings_page_tiles.dart`
- `lib/features/auth/presentation/pages/login_page.dart`

No device/emulator session was run in this pass; findings are based on static review and interaction simulation from code.

## Executive UX Summary

Talia has a strong product foundation: Quran reading, memorization, smart review, kids mode, guardian tools, azkar, progress, certificates, XP, and streaks are all present. The emotional promise is clear, especially around "رحلة الحفظ", "اختبر حفظك", points, stars, and certificates. The biggest UX risk is that the app exposes many powerful flows without enough guided explanation, recovery, and trust-building moments. First-time users can skip onboarding into a dense dashboard, adults can face a complex plan builder too early, children can encounter guardian/QR concepts inside their own journey, and parents get functional tools without enough clarity about security, goals, and what action to take next.

Overall UX readiness score: 6.5/10.

Top priorities:

1. Add progressive onboarding that asks user intent and routes to reading, adult hifz, child journey, or parent setup.
2. Reduce cognitive load in custom memorization setup with presets, defaults, and a review step.
3. Make interruption, offline, and mistake recovery visible and reassuring across hifz, quiz, kids mode, and guardian flows.

## Tested User Personas

- First-time user: enters through splash, onboarding, home, Quran, hifz, azkar, settings.
- Child using memorization flow: path selection, guardian linking, kids journey, kids mode.
- Parent/guardian: guardian linking, parent dashboard, PIN gate, rewards, remote QR tools.
- Beginner Quran learner: Quran reader, ayah options, audio, hifz session, quiz.
- Returning daily user: splash restore, daily wird, activity heatmap, streak, progress.
- Power user: custom plan, accuracy settings, notifications, Juz navigation, bookmarks.
- Non-technical user: onboarding, settings, auth, QR, manual token, voice permission.
- Weak internet user: auth, Supabase redirects, audio, speech recognition, QR/remote sync.
- Mistake-prone user: delete/reset plan, wrong PIN, wrong rating, skipped ayahs, failed quiz.
- User who skips onboarding/tutorials: direct home, hidden tutorial guide, late sign-in prompt.

## Top 10 UX Problems

1. Onboarding is inspirational but not actionable; it does not personalize the app or explain the first task.
2. Memorization setup is split across path selection, guardian linking, custom plan, daily plan, kids journey, and hifz, creating navigation ambiguity.
3. Custom plan setup is too dense for a first real-world adult user.
4. Child journey mixes child motivation with guardian/QR administration.
5. Guardian linking contains mixed English/Arabic copy and unclear cross-device steps.
6. Voice-based quiz depends heavily on microphone/speech recognition with weak fallback guidance.
7. Self-evaluation buttons in daily plan can be misunderstood and accidentally mark progress.
8. Returning users can be restored directly into deep task locations without a "resume or go home" choice.
9. Sign-in/backup is delayed until after progress exists, increasing anxiety about data loss.
10. Several important flows use snackbars for critical feedback, which non-technical users may miss.

## Detailed UX Findings

### UX-01: Onboarding Does Not Create A Guided First Success

- Severity: High
- User type affected: First-time user, non-technical user, user who skips tutorials
- Scenario: User opens app for the first time, sees three slides, taps "ابدأ الآن" or "تخطي", then lands on home.
- Exact screen/feature: `OnboardingPage`, lines 54-177; `SplashPage`, lines 49-66.
- Why it feels bad/confusing: The slides describe Quran, smart memorization, and kids mode, but no intent is captured. A user who wants "read Quran", "memorize myself", "set up child", or "parent dashboard" receives the same generic landing. The app asks for no goal, schedule, age/context, or notification preference.
- Suggested UX improvement: Turn onboarding into a lightweight setup wizard: choose goal, user type, preferred daily time, and whether to back up progress.
- Suggested implementation approach: Add a final intent screen before `_completeOnboarding()`. Persist the selected goal in preferences/profile and route to `/quran`, `/memorization-plus`, `/memorization-plus/guardian-linking`, or home with a highlighted first card.
- Priority level: P0

### UX-02: Skip Onboarding Has No Safety Net

- Severity: Medium
- User type affected: User who skips onboarding/tutorials, first-time user
- Scenario: User taps "تخطي" at line 60 and goes straight to `/`.
- Exact screen/feature: `OnboardingPage`, lines 54-71; tutorial guide is only surfaced in settings (`SettingsPage`, lines 149-153).
- Why it feels bad/confusing: Skipping removes all guidance, and the tutorial guide is hidden under Settings/About. A user who skips once may never discover how hifz, kids mode, quiz, bookmarks, or azkar counters work.
- Suggested UX improvement: After skip, show contextual "start here" coach marks on home for the first three sessions.
- Suggested implementation approach: Store `onboardingSkipped=true`; in `HomePage`, show a dismissible first-run task strip with "اقرأ صفحة", "ابدأ الحفظ", "دليل سريع".
- Priority level: P1

### UX-03: Returning Users Can Be Dropped Into Deep Work Without Reorientation

- Severity: High
- User type affected: Returning daily user, child, user who closes app during memorization, user after long inactivity
- Scenario: App splash restores `lastLocation` directly after 2.5 seconds.
- Exact screen/feature: `SplashPage`, lines 49-66; `AppSessionService`, lines 10-20 and 39-51.
- Why it feels bad/confusing: The app may reopen directly into `/hifz/session`, `/memorization-plus/kids`, `/memorization-plus/quiz`, or parent dashboard. This is efficient for power users, but after a day or week away, users may feel lost and not remember what this session is.
- Suggested UX improvement: Restore to home with a prominent "استكمال من حيث توقفت" card, or show a lightweight resume sheet with context.
- Suggested implementation approach: Keep storing deep links, but route splash to home. Let the home continue chip include screen-specific labels and "not now".
- Priority level: P0

### UX-04: Home Is Rich But Competes For Attention

- Severity: Medium
- User type affected: First-time user, returning daily user, beginner learner
- Scenario: User lands on home and sees hero, streak/XP, sign-in nudge, daily wird, continue reading, progress, azkar, memorization card, parent shortcut, heatmap, and debug card in debug builds.
- Exact screen/feature: `HomePage`, lines 80-245.
- Why it feels bad/confusing: The dashboard is motivational but dense. A beginner may not know whether to read daily wird, continue reading, memorize, open azkar, or inspect progress.
- Suggested UX improvement: Add a single primary "today's next best action" area above secondary cards.
- Suggested implementation approach: In `HomeCubit`, compute `nextAction` from last location, due reviews, azkar time, and onboarding goal. Render one large CTA and move lower-priority modules below.
- Priority level: P1

### UX-05: Backup/Sign-In Appears Too Late

- Severity: High
- User type affected: First-time user, returning daily user, weak internet user
- Scenario: User uses the app as guest, accumulates progress, then sees backup nudge only if streak progress exists.
- Exact screen/feature: `_SignInNudgeBanner`, `home_page_widgets.dart`, lines 1257-1384; `LoginPage`, lines 263-269.
- Why it feels bad/confusing: Users can skip auth easily and only later learn progress needs backup. If the phone changes or data is cleared, this creates avoidable loss anxiety.
- Suggested UX improvement: Position sign-in as optional "حفظ تقدمك بأمان" during onboarding and after first completed meaningful action, not only after streak.
- Suggested implementation approach: Add progressive auth prompts after first bookmark, first hifz completion, or first daily plan completion. Keep guest mode, but show what is local vs cloud.
- Priority level: P0

### UX-06: Memorization Path Selection Is Too Binary And Too Committal

- Severity: High
- User type affected: Adult memorizer, child, parent/guardian, user who makes mistakes
- Scenario: User taps "مسار البالغين" or "مسار الأطفال"; app immediately saves and redirects.
- Exact screen/feature: `PathSelectionPage`, lines 31-106.
- Why it feels bad/confusing: The cards are attractive but do not explain long-term consequences, whether the choice can be changed, what data is created, or how parent mode differs from child mode.
- Suggested UX improvement: Add a "compare paths" section and a confirmation/review step before committing.
- Suggested implementation approach: On tap, show a bottom sheet with "ماذا سيحدث بعد ذلك؟", data impact, and "يمكن تغييره من الإعدادات". Commit only after confirmation.
- Priority level: P0

### UX-07: Custom Plan Builder Is Powerful But Overwhelming

- Severity: High
- User type affected: Beginner Quran learner, adult memorizer, non-technical user
- Scenario: Adult chooses custom plan and sees name, target user, surah range, start ayah, ayahs/day, days/week, minutes, difficulty, near revision, far revision, estimated duration, save.
- Exact screen/feature: `CustomPlanSetupPage`, lines 222-417 and 639-928.
- Why it feels bad/confusing: Too many knobs appear before the user has completed one session. Terms like near revision, far revision, difficulty, and available days require memorization-product literacy.
- Suggested UX improvement: Provide presets first: "خفيف", "متوازن", "مكثف", "حفظ جزء عم". Put advanced controls behind "تخصيص متقدم".
- Suggested implementation approach: Pre-fill `CustomMemorizationPlan` from preset cards; collapse review settings into an expandable section; add a final summary card before save.
- Priority level: P0

### UX-08: Start Ayah Input Allows Unrealistic Choices

- Severity: High
- User type affected: Mistake-prone user, beginner learner
- Scenario: User selects any start ayah number >= 1.
- Exact screen/feature: `CustomPlanSetupPage`, lines 530-576.
- Why it feels bad/confusing: The UI does not show the selected surah's ayah count or prevent entering an ayah beyond the surah. Even if backend guards exist later, the user receives no immediate clarity.
- Suggested UX improvement: Validate start ayah against selected surah and show "هذه السورة فيها X آيات".
- Suggested implementation approach: Load surah metadata into a map; add `TextFormField` validator and clamp/reset when `_startSurahId` changes.
- Priority level: P0

### UX-09: Delete/Reset Memorization Changes Need Stronger Data Warnings

- Severity: High
- User type affected: Power user, parent, user who makes mistakes
- Scenario: User deletes current plan or resets memorization path.
- Exact screen/feature: `CustomPlanSetupPage`, lines 419-463; `_ResetMemorizationPathTile`, `settings_page_tiles.dart`, lines 174-208.
- Why it feels bad/confusing: The dialogs warn, but they do not clearly distinguish deleting a plan from preserving historical memorization records, streaks, kids data, certificates, or reviews. Users need confidence before destructive-feeling actions.
- Suggested UX improvement: Show exactly what will be kept and what will change.
- Suggested implementation approach: Use a checklist-style confirmation: "سيبقى: الإنجازات، السجل، الشهادات. سيتغير: اختيار المسار والخطة الحالية." Require typing a short confirmation only for high-risk reset.
- Priority level: P0

### UX-10: Daily Plan Self-Evaluation Can Be Misunderstood

- Severity: High
- User type affected: Beginner learner, returning daily user, mistake-prone user
- Scenario: User taps weak/average/excellent to evaluate ayahs.
- Exact screen/feature: `DailyPlanPage`, lines 638-710.
- Why it feels bad/confusing: The UI asks the user to judge memorization quality, but does not explain what weak/average/excellent mean or that ratings change review scheduling. A user may tap "ممتاز" to feel good rather than because recall was correct.
- Suggested UX improvement: Add microcopy and optional guided assessment: "هل قرأتها من حفظك بدون نظر؟"
- Suggested implementation approach: On first use, show a one-time explanation sheet. Add labels: "ضعيف: احتجت للمصحف", "متوسط: أخطاء بسيطة", "ممتاز: بدون خطأ".
- Priority level: P0

### UX-11: Daily Plan Completion Is Rewarding But Not Habit-Forming Enough

- Severity: Medium
- User type affected: Returning daily user, power user
- Scenario: User completes all plan items and sees a celebration bottom sheet.
- Exact screen/feature: `DailyPlanPage`, lines 210-315 and 830-868.
- Why it feels bad/confusing: The celebration confirms completion, but it does not explain tomorrow's next step, streak impact, or give an emotional hook to return.
- Suggested UX improvement: Add "موعدك القادم" and streak/progress impact to the celebration.
- Suggested implementation approach: Include next due review date/time from plan generation; show "حافظت على سلسلة X أيام" and CTA "ذكرني غداً".
- Priority level: P1

### UX-12: Child Journey Includes Parent Admin Work

- Severity: High
- User type affected: Child, parent/guardian
- Scenario: Child opens journey and sees "ربط ولي الأمر عن بعد" with QR creation.
- Exact screen/feature: `KidsJourneyPage`, lines 232-299.
- Why it feels bad/confusing: A child-focused screen suddenly introduces remote linking and QR admin. This can break the playful journey and may confuse children who do not know what QR or another device means.
- Suggested UX improvement: Move remote guardian tools into parent dashboard/settings; keep child screen focused on progress, next stage, stars, and encouragement.
- Suggested implementation approach: Hide `_RemoteLinkCard` unless parent mode is active or user explicitly enters guardian setup.
- Priority level: P0

### UX-13: Guardian Linking Has Mixed Language And Unclear Steps

- Severity: High
- User type affected: Parent/guardian, non-technical user, weak internet user
- Scenario: User creates a pairing session, sees QR code, pairing code, expiry text, and regenerate button.
- Exact screen/feature: `GuardianLinkingPage`, lines 76-123 and 191-214.
- Why it feels bad/confusing: UI mixes Arabic with English: "Valid until" and "Regenerate code". The flow does not explain what the parent should open, whether the QR works offline, what happens after expiry, or whether the child can continue safely.
- Suggested UX improvement: Use fully Arabic copy and a numbered 3-step guide.
- Suggested implementation approach: Replace English strings, add countdown, add "افتح تالية على جهاز ولي الأمر > الإعدادات > لوحة ولي الأمر > مسح QR".
- Priority level: P0

### UX-14: Parent PIN Flow Is Functional But Weak On Trust

- Severity: High
- User type affected: Parent/guardian, child, user who makes mistakes
- Scenario: Parent creates or enters 4-digit PIN; if forgotten, can reset locally.
- Exact screen/feature: `ParentDashboardPage`, lines 89-112 and 239-286.
- Why it feels bad/confusing: A 4-digit PIN is simple, but there is no confirmation field when creating, no explanation of what PIN protects, and "نسيت الرمز؟ إعادة ضبط محلية" may sound insecure or confusing.
- Suggested UX improvement: Add PIN confirmation, explain protection scope, and make reset require adult confirmation.
- Suggested implementation approach: In `ParentDashboardNeedsPin`, collect PIN twice. Rename reset to "إعادة ضبط على هذا الجهاز" and show what it affects.
- Priority level: P0

### UX-15: Parent Dashboard Gives Data But Not Coaching

- Severity: Medium
- User type affected: Parent/guardian
- Scenario: Parent sees points, stars, weekly sessions, rewards, logs.
- Exact screen/feature: `ParentDashboardPage`, lines 294-505.
- Why it feels bad/confusing: The parent can observe but gets little guidance: no "what should I do today?", no praise suggestions, no low-activity warning, no recommended reward timing.
- Suggested UX improvement: Add a parent insight card.
- Suggested implementation approach: Compute from logs and goals: "الطفل أكمل جلستين هذا الأسبوع، شجعه بجملة..." or "لم يتدرب منذ 3 أيام".
- Priority level: P1

### UX-16: Kids Mode Completion Button Invites Premature Taps

- Severity: Medium
- User type affected: Child, mistake-prone user
- Scenario: Child taps "أنهيت المراجعة" before listening 3 times.
- Exact screen/feature: `KidsModePage`, lines 466-524; `KidsModeCubit`, lines 130-145.
- Why it feels bad/confusing: The cubit prevents completion and shows a warning, but the button remains visible and active. Children will repeatedly tap it and experience a soft denial instead of a clear disabled state.
- Suggested UX improvement: Disable or visually lock completion until listening requirement is met.
- Suggested implementation approach: Change button state based on `currentLoop >= maxLoops`; show progress copy "استمع 3 مرات لفتح الزر".
- Priority level: P1

### UX-17: Kids Mode Audio Depends On Network Without Child-Friendly Failure

- Severity: High
- User type affected: Child, weak internet user, parent
- Scenario: Child taps play while offline or on weak internet.
- Exact screen/feature: `KidsModeCubit`, lines 89-107; `KidsModePage`, lines 413-463.
- Why it feels bad/confusing: Audio failures are swallowed into `isPlaying=false`; the child may see the play button stop with no explanation. This is especially frustrating in a child flow where listening is required before completion.
- Suggested UX improvement: Show a friendly offline/audio error with retry and cached-audio guidance.
- Suggested implementation approach: Add `audioError` to `KidsModeLoaded`; use `AudioCacheService` like Quran reader options; display a small banner.
- Priority level: P0

### UX-18: Quiz Voice Recognition Needs A Non-Voice Fallback

- Severity: High
- User type affected: Beginner learner, weak internet/device user, non-technical user
- Scenario: User opens quiz, grants or denies mic permission, speech recognition may fail.
- Exact screen/feature: `QuizPage`, lines 160-205 and 499-545.
- Why it feels bad/confusing: If speech recognition is unavailable, the user only gets a snackbar. There is no manual "I recited correctly/incorrectly" fallback, no retry help, no explanation of noise/language limitations.
- Suggested UX improvement: Provide three fallback modes: retry mic, self-grade, or skip this ayah.
- Suggested implementation approach: When `_speechEnabled` is false or repeated recognition is empty, show an inline panel with "استخدم التقييم اليدوي" mapped to weak/average/excellent.
- Priority level: P0

### UX-19: Quiz Feedback Can Feel Punitive

- Severity: Medium
- User type affected: Beginner learner, child, emotional/motivation-sensitive user
- Scenario: User fails a recitation and sees red failure icon and "حاول مرة أخرى".
- Exact screen/feature: `QuizPage`, lines 560-672 and 747-897.
- Why it feels bad/confusing: The result compares recognized text against correct Quran text but does not highlight what was missed, whether voice recognition was uncertain, or how to practice next. For a beginner, this can feel like a judgment rather than coaching.
- Suggested UX improvement: Frame failure as "مراجعة مقترحة" and offer "استمع ثم أعد".
- Suggested implementation approach: Add confidence-aware message, listen button on result, and a "practice once" action before next question.
- Priority level: P1

### UX-20: Hifz Session Has Good Exit Protection But Weak Mid-Session Orientation

- Severity: Medium
- User type affected: Beginner learner, returning user, user who closes app mid-session
- Scenario: User enters hifz session, sees current ayah, listen, record, skip.
- Exact screen/feature: `HifzSessionPage`, lines 45-75 and 136-375.
- Why it feels bad/confusing: Exit confirmation is good, but there is no visible "step X of Y" or "today's objective" in the session body. A user may not know how many ayahs remain or why a checkpoint appears.
- Suggested UX improvement: Add session progress and checkpoint explanation.
- Suggested implementation approach: Show "آية 3 من 7" near the header and an info line before checkpoint review.
- Priority level: P1

### UX-21: Skip Ayah Is Easy But Emotionally Ambiguous

- Severity: Medium
- User type affected: Beginner learner, mistake-prone user
- Scenario: User taps skip in hifz session.
- Exact screen/feature: `HifzSessionPage`, lines 353-370.
- Why it feels bad/confusing: The code comment says skip applies a soft penalty, but UI copy only says skip. The user does not know whether skipping hurts progress, schedules review, or simply advances.
- Suggested UX improvement: Explain skip consequence before first use.
- Suggested implementation approach: On first skip, show a bottom sheet: "سنضيف هذه الآية للمراجعة لاحقاً، لا تقلق."
- Priority level: P1

### UX-22: Quran Reader Long-Press Actions Are Not Discoverable

- Severity: Medium
- User type affected: Beginner Quran learner, non-technical user, power user
- Scenario: User reads a page and can long-press ayah for play/copy/bookmark.
- Exact screen/feature: `QuranReaderPage`, lines 135-151 and 248-289; ayah options lines 425-615.
- Why it feels bad/confusing: Long press is hidden. Users may never discover audio, copy, and bookmarks from the Mushaf reader.
- Suggested UX improvement: Show a one-time hint: "اضغط مطولاً على الآية للاستماع أو الحفظ كعلامة."
- Suggested implementation approach: Persist `quran_long_press_hint_seen`; display a subtle dismissible hint in the top/bottom bar on first reader open.
- Priority level: P1

### UX-23: Quran Reading Progress Is Confirmed Invisibly

- Severity: Medium
- User type affected: Returning daily user, power user
- Scenario: User stays on a Quran page long enough; timer confirms read automatically.
- Exact screen/feature: `QuranReaderPage`, lines 92-112 and 207-220.
- Why it feels bad/confusing: Auto-confirming read pages is convenient, but users do not see what counts as read. This can create distrust in progress numbers.
- Suggested UX improvement: Show subtle "تم احتساب الصفحة" feedback or a small progress indicator.
- Suggested implementation approach: When `isReadConfirmed` changes, show an unobtrusive checkmark in footer instead of only error snackbar handling.
- Priority level: P2

### UX-24: Azkar Counter Is Pleasant But Error-Prone

- Severity: Medium
- User type affected: Non-technical user, user who makes mistakes frequently
- Scenario: User taps large counter area; every tap increments.
- Exact screen/feature: `AzkarCategoryPage`, lines 382-411 and 539-606.
- Why it feels bad/confusing: The large tap target is good, but there is no undo, no accidental tap correction, and no haptic/visual distinction between count increments and "done".
- Suggested UX improvement: Add undo for last count and better completion transition.
- Suggested implementation approach: Add an undo button or snackbar after increment; persist per-zikr count immediately; support long-press decrement.
- Priority level: P1

### UX-25: Notification Settings Are Fixed-Time Toggles

- Severity: Medium
- User type affected: Returning daily user, parent, power user
- Scenario: User sees notification toggles for review, streak, morning/evening azkar, daily duaa.
- Exact screen/feature: `settings_page_tiles.dart`, lines 1006-1304.
- Why it feels bad/confusing: Times appear fixed in subtitles; users cannot pick a schedule. For habit formation, reminder timing is personal and essential.
- Suggested UX improvement: Let users set times for review, azkar, and streak protection.
- Suggested implementation approach: Add `TimeOfDay` pickers and store chosen times in SharedPreferences/settings repository; update notification scheduling.
- Priority level: P1

### UX-26: Recitation Accuracy Settings Are Too Abstract

- Severity: Medium
- User type affected: Beginner learner, parent, power user
- Scenario: User selects easy/medium/hard accuracy.
- Exact screen/feature: `settings_page_tiles.dart`, lines 920-1000.
- Why it feels bad/confusing: Easy/medium/hard do not explain how scoring changes or which user should choose each. Parents may make the app too strict for a child.
- Suggested UX improvement: Add plain-language descriptions.
- Suggested implementation approach: Replace dropdown with three segmented cards: "متسامح للأطفال", "متوازن", "دقيق للمتقدمين", each showing approximate threshold.
- Priority level: P2

### UX-27: Mixed Hardcoded Arabic Weakens English Mode

- Severity: High
- User type affected: English user, bilingual user, non-Arabic parent
- Scenario: User changes language but many memorization/guardian/kids strings remain hardcoded Arabic.
- Exact screen/feature: examples include `PathSelectionPage`, lines 31-106; `CustomPlanSetupPage`, lines 191-417; `GuardianLinkingPage`, lines 76-214; `DailyPlanPage`, lines 104-189; `KidsJourneyPage`, lines 142-150; `KidsModePage`, lines 227-590.
- Why it feels bad/confusing: The app claims Arabic + English support, but key flows remain Arabic-only. This is especially hard for parents/guardians who may not read Arabic fluently.
- Suggested UX improvement: Move all user-visible strings to ARB localization.
- Suggested implementation approach: Add keys to `app_ar.arb` and `app_en.arb`; replace hardcoded strings with `context.l10n`.
- Priority level: P0

### UX-28: Critical Feedback Often Uses Snackbars Only

- Severity: Medium
- User type affected: Non-technical user, child, weak internet user
- Scenario: Errors and confirmations appear as snackbars in auth, path selection, guardian linking, Quran reader, azkar, settings.
- Exact screen/feature: examples: `PathSelectionPage`, lines 42-48; `GuardianLinkingPage`, lines 49-56; `LoginPage`, lines 63-98; `QuranReaderPage`, lines 217-220; `SettingsPage`, lines 47-57.
- Why it feels bad/confusing: Snackbars are temporary and easy to miss, especially in RTL layouts, during keyboard entry, or when a child is focused on a large CTA.
- Suggested UX improvement: Use inline persistent error states for critical failures and snackbars for low-risk confirmations only.
- Suggested implementation approach: Add error banners/components to Cubit states for auth, guardian, audio, and plan save failures.
- Priority level: P1

## Real Usage Scenario Notes

### User Closes App During Memorization

The app stores hifz session locations (`HifzSessionPage`, lines 111-118) and can restore them from splash. This protects continuity but needs a resume decision layer so users are not surprised after inactivity.

Recommended UX: resume sheet with "استكمال التسميع", "عرض خطتي", "الرئيسية".

### User Loses Progress Or Uses Weak Internet

Guest mode is supported, but backup is not strongly introduced. Audio in kids mode uses direct URL playback without visible error. Auth errors are mostly snackbars.

Recommended UX: visible "محفوظ على هذا الجهاز" vs "محفوظ في السحابة" indicators, offline banners, and cached audio states.

### User Skips Tasks

Hifz skip applies scheduling behavior in code comments but not in UX. Daily plan "weak" schedules review, but users may not understand rating consequences.

Recommended UX: make rescheduling explicit and emotionally safe: "لا بأس، سنراجعها غداً".

### Child Fails Revision

Kids mode is more repetition-based than failure-based, which is good. Quiz/hifz failure states use red failure indicators and numeric scores. Children need softer coaching and parent-friendly framing.

Recommended UX: "تحتاج تدريباً أكثر" instead of "failed"; add "استمع مرة أخرى" and encouragement.

### Parent Checks Child Progress

Parent dashboard shows metrics and logs but does not guide action. Rewards exist but are not connected to recommended parent behavior.

Recommended UX: weekly insight, praise suggestion, and reward recommendation.

### User Opens App After Long Inactivity

Splash restore can deep-link into old work. There is no "welcome back" repair flow.

Recommended UX: detect inactivity and show "مرحباً بعودتك" with a gentler reduced plan and review catch-up.

## Features Users May Love

- Real Mushaf-style Quran page rendering with tajweed and page navigation.
- Long-press ayah actions: listen, copy, bookmark.
- Daily wird card and continue-reading chip.
- Activity heatmap and progress dashboard.
- Kids stars, points, levels, and journey stages.
- Parent rewards and weekly session summary.
- Certificates and certificate celebration dialog.
- Azkar reader with large tap counter, index sheet, copy/share.
- Smart daily plan with new/near/far revision.
- Voice quiz and hifz recitation feedback for motivated learners.

## Features Users May Abandon

- Custom plan setup if they do not understand all fields.
- Voice quiz if microphone/speech recognition fails or gives surprising results.
- Guardian linking if QR/cross-device flow is unclear.
- Parent dashboard if PIN/reset/security feels unclear.
- Hifz session if skip/retry/checkpoint consequences are not explained.
- English mode if memorization flows remain Arabic-only.
- Notification settings if reminder times cannot be personalized.
- Progress page if users do not understand how reading pages are counted.

## Top 10 Emotional/Product Improvements

1. Add "أول نجاح سريع" after onboarding: read one page, complete one zikr, or listen to one ayah.
2. Use kinder failure language: "نراجعها معاً" instead of hard fail states.
3. Add personalized encouragement based on streak, child progress, and long absence.
4. Let parents send praise/rewards after a child session.
5. Make certificates feel shareable and anticipated: show progress toward next certificate.
6. Add "today's plan is lighter because you were away" for inactive users.
7. Make child journey more playful with stage names, badges, and visual milestones.
8. Add confidence-building explanations for smart review scheduling.
9. Add visible saved/backup states to reduce anxiety.
10. Add an end-of-session reflection: "كيف كان حفظك اليوم؟" with simple choices.

## Suggested Onboarding Improvements

- Screen 1: "ماذا تريد أن تفعل أولاً؟" with choices: القراءة، الحفظ، أذكار اليوم، متابعة طفل.
- Screen 2: "لمن الحفظ؟" only if memorization is chosen.
- Screen 3: choose daily reminder time or skip.
- Screen 4: explain guest vs cloud backup.
- Final step: route directly to the chosen first action, not generic home.
- For skipped onboarding: show a home checklist until first meaningful completion.

## Suggested Retention Improvements

- Add "next best action" on home.
- Add a comeback flow after 3+ inactive days.
- Add streak repair/soft landing: "ابدأ بخطوة صغيرة اليوم".
- Add reminder time customization.
- Add weekly parent summary.
- Add "next certificate progress" on home/progress.
- Add "tomorrow preview" after daily plan completion.

## Suggested Gamification Improvements

- Keep rewards spiritual/respectful and avoid over-competitive framing.
- Make kids levels named, not just numbered.
- Add streak freeze or mercy mode for missed days, especially children.
- Show progress toward next star and next reward.
- Let guardians define real-world rewards and mark them claimed.
- Celebrate effort, not only correctness: listening, retrying, and returning after absence should earn gentle recognition.

## Suggestions Inspired By Top Modern Apps

- Duolingo-style single clear daily task, but calmer and spiritually appropriate.
- Khan Academy Kids-style child guidance: large friendly actions, minimal admin, supportive retry language.
- Headspace-style onboarding: select intent, set reminder, start immediately.
- Apple Fitness-style progress rings for daily reading, review, and azkar.
- Todoist-style "today" view: one central list of due spiritual tasks.
- Notion/Linear-style clear empty states with one primary action.
- Google Photos-style backup status: local/cloud state is always visible and calming.

## Product Priority Roadmap

### Phase 1: Zero/Low Risk UX Copy And Guidance

- Localize hardcoded Arabic strings.
- Replace mixed English in guardian linking.
- Add first-use hints for Quran long-press, daily plan ratings, hifz skip, and quiz microphone.
- Add inline banners for critical errors.

### Phase 2: Flow Simplification

- Add goal-based onboarding and home next-action card.
- Convert custom plan builder into presets plus advanced settings.
- Move child-journey guardian admin tools into parent/guardian surfaces.
- Add resume sheet instead of splash deep-restore.

### Phase 3: Retention And Emotional Polish

- Add comeback flow after inactivity.
- Add next review/tomorrow preview after completion.
- Add parent weekly insights and praise suggestions.
- Add child stage names and next-reward progress.

### Phase 4: Higher-Risk Product Logic UX

- Add validated plan setup constraints by surah/ayah metadata.
- Add self-grade fallback for voice quiz.
- Add cached/offline audio state to kids mode.
- Add stronger reset/delete safety model and tests around persistence.

## Safe Executable UX Improvements

These improvements are safe to plan and implement incrementally because they do not require changing Quran text, ayah numbering, memorization scoring, streak calculations, storage migrations, Supabase schema, or existing business rules. They are primarily copy, layout, guidance, visibility, and workflow-polish changes.

### Child First-Time Memorization Flow

- Priority: P0
- User affected: 9-year-old child, first-time child user, parent supervising setup
- Why safe: Does not change memorization logic; only changes where guidance appears and how existing actions are presented.
- Suggested change: Add a child-friendly first mission before the full journey map: "هيا نحفظ آية واحدة الآن".
- Implementation approach: Add a lightweight intro panel at the top of `KidsJourneyPage` when child progress is zero. Primary CTA opens the first unlocked stage. Keep existing stage logic unchanged.
- Acceptance criteria: A child can understand the next action without reading guardian setup text; first CTA is visually dominant; parent tools are not the first visible action.

- Priority: P0
- User affected: Child using kids mode
- Why safe: Uses existing `currentLoop`, `maxLoops`, and `mustListenFirst` state.
- Suggested change: Make the three listening repetitions feel like a game.
- Implementation approach: Replace neutral loop text with step labels: "اسمع", "ردد معي", "آخر مرة". Disable or visually lock "أنهيت المراجعة" until `currentLoop >= maxLoops`.
- Acceptance criteria: Child sees exactly how many listens remain; tapping complete early no longer feels like a failure; no scoring logic changes.

- Priority: P1
- User affected: Child, weak internet user
- Why safe: Adds visible feedback only.
- Suggested change: Add friendly audio failure copy in kids mode.
- Implementation approach: Add an inline banner when audio play fails: "لم يعمل الصوت الآن. جرّب مرة أخرى أو اطلب من ولي الأمر الاتصال بالإنترنت." A later code task can expose this through state without changing audio source logic.
- Acceptance criteria: Child is not left with a silent play button failure; retry remains available.

### Busy Parent Two-Minute Daily Flow

- Priority: P0
- User affected: Busy parent/guardian
- Why safe: Summarizes existing dashboard data; does not change child progress or rewards logic.
- Suggested change: Add a top "ملخص اليوم" card in `ParentDashboardPage`.
- Implementation approach: Use existing values from `ParentDashboard`: weekly sessions, points, stars, logs, rewards. Show one status sentence and one suggested action.
- Example copy: "اليوم: أكمل الطفل جلسة واحدة. يحتاج تشجيعاً للمراجعة القادمة."
- Acceptance criteria: Parent can answer "هل طفلي بخير اليوم؟" within 10 seconds.

- Priority: P1
- User affected: Parent/guardian
- Why safe: Adds presentation layer only.
- Suggested change: Add quick actions at the top: "إرسال تشجيع", "إضافة مكافأة", "تذكير الطفل", "عرض آخر جلسة".
- Implementation approach: Reuse existing add reward and reminder controls. "إرسال تشجيع" can start as local suggested praise copy without remote messaging.
- Acceptance criteria: Parent's most common actions appear before QR tools and long logs.

- Priority: P1
- User affected: Parent/guardian
- Why safe: Derived insight from existing logs.
- Suggested change: Add parent insight copy.
- Implementation approach: Compute simple UI-only messages: no sessions today, goal almost complete, reward close, long inactivity.
- Example copy: "باقي جلستان لفتح مكافأة: وقت لعب إضافي."
- Acceptance criteria: Parent sees meaning, not only numbers.

### Onboarding And First-Week Guidance

- Priority: P0
- User affected: First-time user, skipped-onboarding user, parent, beginner learner
- Why safe: Adds preference/guidance UI; can be implemented without changing core flows.
- Suggested change: Add intent-based onboarding choices.
- Implementation approach: Add final onboarding step with choices: "قراءة القرآن", "الحفظ لنفسي", "متابعة طفل", "الأذكار". Persist choice in SharedPreferences and use it to highlight the first home CTA.
- Acceptance criteria: New user gets one clear recommended action after onboarding.

- Priority: P1
- User affected: User who taps "تخطي"
- Why safe: Adds home guidance only.
- Suggested change: Show a dismissible "ابدأ من هنا" checklist on home after skipped onboarding.
- Implementation approach: Store `onboardingSkipped=true`; render checklist until one meaningful action is completed.
- Acceptance criteria: Skipping onboarding does not leave the user unguided.

### Memorization Plan Setup

- Priority: P0
- User affected: Adult memorizer, beginner Quran learner
- Why safe: Presets can pre-fill current fields without changing plan generation rules.
- Suggested change: Add plan presets before advanced custom controls.
- Implementation approach: Show cards: "خفيف", "متوازن", "مكثف", "جزء عم". Each card sets existing form values, then user can edit.
- Acceptance criteria: A beginner can create a plan in under 60 seconds.

- Priority: P1
- User affected: Mistake-prone user
- Why safe: Adds validation/description around existing inputs.
- Suggested change: Explain review settings in plain language.
- Implementation approach: Add helper text under "المراجعة القريبة" and "المراجعة البعيدة"; collapse advanced sliders by default.
- Acceptance criteria: User understands what the settings do before saving.

### Quran Reader Discoverability

- Priority: P1
- User affected: Beginner Quran reader, non-technical user
- Why safe: Adds a one-time hint only.
- Suggested change: Show a subtle first-use hint for long-press ayah actions.
- Implementation approach: Add dismissible hint: "اضغط مطولاً على الآية للاستماع أو إضافة علامة." Persist seen state in SharedPreferences.
- Acceptance criteria: Users discover listen/copy/bookmark without searching.

- Priority: P2
- User affected: Returning daily reader
- Why safe: Presentation-only confirmation.
- Suggested change: Show "تم احتساب الصفحة" when read progress is confirmed.
- Implementation approach: Use existing `isReadConfirmed` state and render a small footer checkmark or toast-style inline message.
- Acceptance criteria: Reading progress feels transparent.

### Voice Quiz And Hifz Feedback

- Priority: P0
- User affected: Beginner learner, weak internet/device user
- Why safe: Adds fallback UI without changing existing voice scoring.
- Suggested change: Add a manual fallback when speech recognition is unavailable.
- Implementation approach: Show "التقييم اليدوي" with weak/average/excellent buttons when microphone permission is denied or recognized text is empty repeatedly.
- Acceptance criteria: User can complete practice even when speech recognition fails.

- Priority: P1
- User affected: Beginner learner, child
- Why safe: Copy and action framing only.
- Suggested change: Replace harsh failure framing with coaching language.
- Implementation approach: Use "نراجعها معاً" and "استمع ثم أعد المحاولة" on failed quiz/hifz states. Keep scores unchanged.
- Acceptance criteria: Failure feels recoverable rather than punitive.

### Localization And Arabic UX

- Priority: P0
- User affected: English user, bilingual parent, Arabic-first user
- Why safe: Localization copy replacement only when done carefully.
- Suggested change: Move hardcoded user-visible strings to ARB files.
- Implementation approach: Prioritize guardian linking, kids journey, daily plan, custom plan, and quiz. Keep Arabic wording respectful and exact for non-Quran UI copy.
- Acceptance criteria: English mode no longer shows Arabic-only memorization controls, and Arabic mode no longer shows "Valid until" or "Regenerate code".

### Feedback And Error Visibility

- Priority: P1
- User affected: Non-technical user, weak internet user, child
- Why safe: Adds persistent UI states; does not change backend calls.
- Suggested change: Use inline banners for important errors instead of snackbars only.
- Implementation approach: Add reusable error/info banner component and display it for guardian linking, audio failure, auth/network problems, and plan save failures.
- Acceptance criteria: Critical messages remain visible until dismissed or resolved.

## Safe Implementation Checklist

- Do not change Quran text, ayah numbering, page mapping, or tajweed rendering.
- Do not change SM-2, rating calculations, streak logic, XP values, or certificate rules.
- Do not change Hive/Isar/Supabase schema without a separate approved data plan.
- Start with copy, hints, visual hierarchy, and derived summaries.
- Add widget tests for new visible states where practical.
- Verify Arabic RTL layout on small screens before release.

## Final Product Assessment

Talia already contains many features users would value, but the current experience feels like a feature-rich app that still needs product choreography. The strongest next step is not adding more features; it is making the first week feel safe, guided, and emotionally rewarding for each persona: reader, memorizer, child, and guardian.
