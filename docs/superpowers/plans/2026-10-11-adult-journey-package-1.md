# Adult Journey Package 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** إضافة تخصيص اختياري للكبار، ووقت إرشادي لليوم، وعودة هادئة، دون تغيير مصدر حقيقة الحفظ أو المراجعة أو الختمة.

**Architecture:** Feature-first `adult_journey` يملك التفضيلات والسياسات وCubit والعرض. يستهلك مخرجات الرحلة الحالية ويستخدم الملاحة الحالية، ويخزن سجلًا محليًا لكل مالك تحت AccountDataBarrier؛ لا ينشئ جدولة أو تقدمًا موازيين.

**Tech Stack:** Flutter/Dart وCubit وGetIt وSharedPreferences وEquatable الموجودة؛ لا تغيير إصدارات أو إضافة حزم.

**Spec:** [التصميم المقترح](../specs/2026-10-11-adult-journey-package-1-design.md).

**Status:** خطة مقترحة أعدت بطلب المستخدم؛ التنفيذ غير بدأ، والتصميم والخطة يحتاجان مراجعة قبل تعديل التطبيق. مرجع المصدر HEAD `81cf125a89b952baebcafe818ef82eda43e46f95` وشجرة العمل القائمة في 2026-10-11. كل الواجهات تحت `adult_journey` أدناه **مقترحة للإنشاء** وليست APIs موجودة.

**مراجعة 2026-10-12:** قورنت الخطة بالمصدر عند HEAD نفسه. التعديلات: لا تعديل لـ `HomeCubit`/`home_state` (Task 4)، شرط بالغ مثبت (Tasks 3–5)، آلية زيارة مبسطة بكتابة يومية (Task 5)، وتقسيم التسليم إلى ثلاث مراحل. التفاصيل والأسباب في spec §10.

## Global Constraints

- Adult only; no child writes or child UI changes.
- No Quran text, ayah identifiers, audio ownership, SRS, session engine, or stored-plan mutations.
- No new dependencies, Isar schemas, Supabase migrations, RPCs, or cloud synchronization.
- Existing onboarding remains four steps; skip/guest/login/deep links retain their current contracts.
- New strings use app_ar.arb and app_en.arb; generated localizations use flutter gen-l10n.
- New widgets <=300 lines; methods <=50 lines; files <=500 lines.
- Missing/corrupt optional data falls back to the current experience; saving errors never report success.
- Default feature switches are off until acceptance gates pass; disabling them restores current behavior without deleting progress.

## Review Focus

- حساب A يتحول إلى B أو يعود إلى A أثناء await: إبطال النتيجة القديمة حتى لو تطابق المعرف مجددًا؛ مهام 1 و4 و6.
- تغيير التاريخ المحلي/المنطقة الزمنية والتواريخ المستقبلية: انتهاء وقت اليوم دون دعوة غياب خاطئة؛ مهام 2 و5.
- الاستئناف والمراجعة الملحة أطول من خمس دقائق: لا إخفاء أو قطع أو تبديل إلى حفظ جديد؛ مهام 2 و4.
- أول مستخدم أو ترقية بلا سجل أو JSON مجهول: الرئيسية قابلة للاستخدام ولا اختلاق عودة أو محفوظ؛ مهام 1 و3 و5.
- نقرة مزدوجة أو رابط استئناف قديم أو تبويب مخفي/هوية لم تجهز: وجهة آمنة وملاحة واحدة محدثة وزيارة عند اجتماع شروط الأهلية فقط؛ مهام 4 و5 و6.

## Existing integration points

| الملف الموجود | الوظيفة التي تستعمل |
|---|---|
| `lib/core/identity/record_owner_provider.dart` | `RecordOwnerProvider.currentOwnerId` |
| `lib/core/identity/account_data_barrier.dart` | `forPreferences`, `run`, `capture`, `changes`, `AccountDataLease.check` |
| `lib/core/identity/account_data_reset.dart` | `clearedPreferencePrefixes` والتنظيف الحالي للخروج والحذف |
| `lib/core/journey/unified_journey_action.dart` | `UnifiedJourneyAction`, `JourneyIntent`, `UnifiedJourneyPriority` |
| `lib/core/journey/unified_journey_engine.dart` | `evaluateAll` ومقادير `journeyActionMinutes` القائمة |
| `lib/features/home/presentation/cubits/home_cubit.dart` و`home_state.dart` | قراءة فقط: `HomeLoaded.alternativeActions` (كل مخرجات `evaluateAll` بترتيبها)، `customPlan`، `microReview`، `selectedTrack`، `isKids`، `isFirstRun`؛ لا تعديل |
| `lib/core/widgets/app_shell.dart` و`app_router.dart` | `StatefulShellRoute.indexedStack`: فرع الرئيسية index 0 لفحص الظهور في Task 5 |
| `lib/features/home/presentation/pages/home_page.dart` | يتجاوز 500 سطر حاليًا؛ تركيب sliver واحد فقط، ويحتوي `didChangeAppLifecycleState` القائم |
| `lib/features/home/domain/services/home_primary_action_resolver.dart` | أولوية الختمة/الإجراء الرئيسي؛ لا تعديل منطقها |
| `lib/features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart` | `resolve()`, `MemorizationNavigationTargets.todayPlanLocation/reviewQuizLocation` |
| `lib/features/settings/presentation/widgets/settings_hub_body.dart` | مدخل النموذج المشترك للكبار فقط |

## Proposed file ownership and interfaces

الجذر المختصر في بقية الخطة `AJ = lib/features/adult_journey`، وجذر الاختبارات `AJT = test/features/adult_journey`. هذه اختصارات توثيقية وليست مسارات CLI.

| المسار الجديد تحت AJ | المسؤولية |
|---|---|
| `domain/entities/adult_journey_preferences.dart` | `AdultJourneyGoal {reading,memorization,review,azkar}`, `AdultJourneyExperience {beginner,continuing,returning}`؛ snapshot لا يحمل قرآنًا أو تقدمًا |
| `domain/repositories/adult_journey_repository.dart` | قراءة وتعديل السجل عبر أوامر typed؛ لا UI/SharedPreferences في Domain |
| `data/adult_journey_preferences_codec.dart` | JSON v1، تحقق الأنواع والتواريخ والإصدار |
| `data/adult_journey_repository_impl.dart` | ملكية وتخزين محمي ودمج التحديثات |
| `domain/entities/adult_journey_context.dart` | input: ownerId، isAdult، now، actions، hasActiveAdultPlan، hasAdultReviewRecords، hasDueAdultReview |
| `domain/entities/adult_journey_suggestion.dart` | action اختياري، launchKind، estimatedMinutes اختياري، exceedsBudget، reason code |
| `domain/services/adult_journey_suggestion_policy.dart` | اختيار عرضي فوق المخرجات الموجودة؛ لا إنشاء جلسة أو تعديل خطة |
| `domain/services/adult_return_policy.dart` | calendar-day/offer/dismissal rules خالصة |
| `application/adult_journey_usecases.dart` | قراءة/حفظ profile وtoday وvisit/dismiss عبر Repository |
| `application/adult_journey_launch_resolver.dart` | إعادة حل المسارات عند النقر، اعتمادًا على المنافذ الحالية |
| `presentation/cubits/adult_journey_cubit.dart` و`adult_journey_state.dart` | حالة منفصلة، request revision وlease وإغلاق اشتراكات |
| `presentation/widgets/adult_journey_section.dart` | بطاقة اختيارية مشتركة بمدخل Context؛ لا تحميل تقدم مستقل |
| `presentation/widgets/adult_journey_setup_sheet.dart` | النموذج المشترك من الرئيسية والإعدادات |
| `presentation/widgets/adult_today_budget_card.dart` | 5/10/20 ومقترحات اليوم والتوضيح الزمني |
| `presentation/widgets/adult_return_card.dart` | عرض العودة وأفعالها |
| `adult_journey_feature_flags.dart` | أعلام البناء الجديدة افتراضيًا false |

**البيانات الجديدة:** `AdultJourneyPreferences` يحتوي جميع حقول التخزين في spec §5، دون ownerId داخل JSON؛ المالك جزء من المفتاح والمعاملة. goal وexperience اختياريان؛ profileCompleted وlightReturnToday افتراضيهما false. بقية الحقول اختيارية عدا schemaVersion=1. `AdultJourneyLoadResult` حالات ready(snapshot)/missing/unsupported/corrupt، حتى لا يتحول الإصدار المجهول إلى reset صامت. تعريف هذه الأنواع في ملف preferences المذكور، وتقسيم codec عند الحاجة للحدود الحجمية.

**Commands مقترحة:** sealed `AdultJourneyUpdate` بفروع `SaveProfile(goal,experience?)`, `SnoozeSetup(localDate)`, `SetToday(localDate,minutes,lightReturn)`, `ClearToday`, `RecordHomeVisit(nowUtc)`, `DismissReturn(localDate)`. تعرف في `domain/entities/adult_journey_update.dart`. لا يستقبل المستودع blob كاملًا من UI حتى لا تمحو عملية قديمة تحديثًا أحدث، ولا يتلقى يوم عرض العودة من المستدعي.

**Repository مقترح:**

```dart
Future<AdultJourneyLoadResult> load({required String expectedOwnerId});
Future<AdultJourneyPreferences> update({
  required String expectedOwnerId,
  required AdultJourneyUpdate command,
});
```

كل update يقرأ أحدث snapshot ويدمج أمره داخل `barrier.run`؛ الإصدار المجهول يرفض الكتابة دون مسحه. `RecordHomeVisit` يحسب قرار العرض من آخر snapshot داخل المعاملة مع سياسة العودة، لا من نسخة UI قديمة. استخدم `DateTime Function()` injectable للاختبارات.

## Task 0: تثبيت خط الأساس قبل التنفيذ

**Files:** لا تعديل للتطبيق. Create: `docs/superpowers/evidence/2026-10-11-adult-journey-package-1.md` عند بدء التنفيذ الفعلي.

**Interfaces:** Consumes التصميم والخطة وشجرة العمل؛ Produces سجل الأوامر والمخرج والنسخة والاختبارات السابقة الفاشلة إن وجدت.

- [ ] راجع الوثيقتين مع المستخدم قبل التطبيق؛ هذه الخطة وحدها لا تبدأ التنفيذ. اختر طريقة التنفيذ في ذلك الوقت.
- [ ] افحص `git -c core.fsmonitor=false status --short` و`git rev-parse HEAD`؛ لا تخلط تغييرات المستخدم بمهام الحزمة. استخدم فرعًا/checkout مناسبًا عبر مهارة worktrees عند التنفيذ، مع تحديد كيف تصل التغييرات المحلية المطلوبة إليه؛ لا تفترض أن worktree ينسخها.
- [ ] شغّل `flutter analyze`، ثم `flutter test test/features/onboarding test/features/home test/core/journey test/core/router test/core/identity test/features/memorization_plus/presentation/navigation test/features/memorization_plus/domain/services/plan_schedule_policy_test.dart test/integration/account_switch_isolation_test.dart`.
- [ ] سجل النتائج كخط أساس. أي فشل متعلق بالهوية أو تقدم الحفظ أو الملاحة يعالج/يحسم قبل التفعيل؛ لا تنسب فشلًا سابقًا للحزمة ولا تتجاهله.
- [ ] راجع file map مع المصدر الحالي. إذا اختلف عقد موجود عما في الخطة حدّث الوثيقتين قبل تعديل المستهلكين.
- [ ] سجل الملفات المعدلة محليًا وغير المحفوظة قبل البدء. في 2026-10-12 تشمل `lib/core/l10n/app_ar.arb` و`app_localizations.dart` و`app_localizations_ar.dart` واختبار `prayer_companion_settings_section_test.dart`. لا `dart format` على مجلدات كاملة؛ نسّق الملفات المعدلة في الحزمة فقط.

## Task 1: سجل التفضيلات وملكية الحساب والتنظيف

**Files:** Create AJ files preferences/update/repository/codec/repository_impl/usecases/flags من الخريطة، و`domain/services/adult_return_policy.dart` كمتطلب سابق للتخزين. Modify `lib/core/identity/account_data_reset.dart` (إضافة prefix فقط)، `lib/core/di/injection.dart` (registrations محددة). Create AJT `data/adult_journey_repository_test.dart`, `data/adult_journey_codec_test.dart`, `domain/adult_return_policy_test.dart`. Extend `test/core/identity/account_data_reset_test.dart`.

**Interfaces:** Consumes `RecordOwnerProvider`, `SharedPreferences`, `AccountDataBarrier`; Produces Repository المذكور وusecases `LoadAdultJourney.call(expectedOwnerId)`, `UpdateAdultJourney.call(expectedOwnerId,command)` والأعلام الثلاثة.

`AdultJourneyFeatureFlags` كائن immutable بـ const constructor ذي named bools الثلاثة default=false، يحقن من DI. الإنتاج يستخدم قيم بناء ثابتة محلية، والاختبارات تحقن كائنًا بقيمها؛ لا mutable globals أو remote config. الفعالية: personalization شرط كل العرض، وtodayBudget شرط الأفعال الزمنية في العودة.

- [ ] اكتب اختبارات `AdultReturnPolicy` كاملة وفق عقد Task2 الموضح أدناه، وشغّل `flutter test test/features/adult_journey/domain/adult_return_policy_test.dart` لتثبت فشل السلوك الناقص؛ ثم نفذ السياسة الخالصة وأعدها حتى PASS قبل إنشاء RecordHomeVisit في المستودع.
- [ ] اكتب اختبارات codec/repository الفاشلة: missing لا يكتب، JSON خاطئ/إصدار2 لا يمسح، minutes=7 ترفض، فشل setString لا يصدر نجاحًا، حقول today لا تمحو profile أو visit. اختبر goal roundtrip بالقيم الأربع وتجربة null.
- [ ] اختبر فشل حفظ profile ثم load ثم نجاح SetToday: يجب بقاء profile المخزن السابق، دون تسريب القيمة المرفوضة من cache. اختبر false وexception، وفشل reload ثم منع load/update حتى reload ناجح، مع تبديل المالك أثناء المصالحة.
- [ ] اكتب اختبارات سباق A→B وA→B→A أثناء حفظ/قراءة، واختبارات ترتيب تحديث profile ثم today ثم visit. Assert: لا نتائج قديمة في B، ولا اختيار من A يكتب بمفتاح B، وتنظيف الحساب لا تعقبه إعادة إنشاء سجل بعملية قديمة.
- [ ] اكتب اختبار cleanup للخروج والحذف يغطي `adult_journey_v1_`، مع بقاء theme/locale وفق الاختبارات الحالية.
- [ ] Run: `flutter test test/features/adult_journey/data test/core/identity/account_data_reset_test.dart`؛ قبل الإنتاج الجديد يجب أن تفشل الاختبارات الجديدة للسلوك الناقص، لا بسبب إعداد اختبار معطوب.
- [ ] نفذ الواجهات وJSON وفق spec §5؛ تحقق lease والمالك قبل/بعد await، ونتيجة setString. عند false/exception أعد تحميل SharedPreferences داخل نفس الحاجز مع lease؛ المصالحة الفاشلة تمنع استخدام cache لهذا الملحق حتى reload ناجح. لا تعدل مخططات Isar أو auth flow. أضف prefix في قائمة التنظيف الحالية لتشمل logout/deletion تلقائيًا.
- [ ] أضف التسجيلات المحددة في DI مع default flags=false. لا تفتح database جديدة ولا تضف SharedPreferences singleton ثانيًا.
- [ ] أعد الأمر نفسه؛ Expected جميع الاختبارات المحددة PASS. راجع الفرق ثم احفظ commit لهذه المهمة وحدها عند تنفيذ الخطة.

## Task 2: سياسات الاقتراح وعودة التقويم

**Files:** Create AJ context/suggestion/suggestion_policy. Create AJT `domain/adult_journey_suggestion_policy_test.dart`. Reuse return_policy و`domain/adult_return_policy_test.dart` المنشأين في Task1؛ عقدهما الكامل مذكور هنا لقراءة مترابطة للسياسات، وليس إنشاءً ثانيًا.

**Interfaces:**

```dart
List<AdultJourneySuggestion> select({
  required AdultJourneyContext context,
  required AdultJourneyPreferences preferences,
});
AdultReturnDecision evaluate({
  required DateTime now,
  required DateTime? lastHomeSeenAtUtc,
  required String? returnOfferLocalDate,
  required String? returnDismissedLocalDate,
  required bool explicitlyReturning,
});
```

`AdultReturnDecision {bool showOffer, String? eligibleLocalDate}`؛ `AdultJourneyLaunchKind {resume,reading,khatmah,memorize,review,azkar,explore,setupPlan}`. context actions يحافظ على ترتيب evaluateAll، ولا يستنتج mastery من خبرة المستخدم. reason enum: goalMatch/timeFit/urgent/resume/needsPlan/noReview/estimateUnavailable. كل هذه أنواع جديدة تعرف في ملفات المجال المذكورة. constructor السياسة `AdultReturnPolicy({DateTime Function(DateTime)? toLocal})` يستعمل تحويلًا إلى المنطقة المحلية الحالية افتراضيًا؛ now وlastHomeSeenAtUtc لحظتان مطلقتان تحولان عبر هذا المنفذ. isAdult لا يساوي نفي isKids عند هوية غير جاهزة؛ يجب أن يكون الجمهور البالغ مثبتًا.

- [ ] اكتب اختبارات الاختيار: طفل→قائمة فارغة؛ دون تخصيص→لا overlay؛ max3 اقتراحات بلا مسارات مكررة؛ review6 مع budget5 يبقى أولًا وexceedsBudget=true؛ p1 ثم p2 ثم p3 لا يعاد ترتيبها لأجل الهدف؛ العودة الخفيفة لا تنشئ جديدًا بدل مراجعة متاحة.
- [ ] ثبت مدد الإصدار الأول في assertions: reading4/memorize8/review6/azkar5/resume3/explore2؛ ليست وعدًا بزمن فعلي. setupPlan لا زمن له. تحقق أن مصدر تقديرها هو الدالة الحالية، لا جدول موازٍ.
- [ ] تأكد أن اختبارات العودة المنفذة كمتطلب في Task1 تغطي: previous=null لا عرض آلي، dayGap6 لا عرض، dayGap7 عرض، مستقبل لا عرض، dismissal اليوم يخفي، offer اليوم يبقى بعد إعادة فتح، تغيير timezone لا يستعمل `difference.inDays` كتقويم. fixture محلي: lastSeen 2026-10-04 23:59 وnow 2026-10-11 00:01 ⇒ gap7. حساب التقويم باستخدام مكونات year/month/day في UTC بعد تحويل اللحظات إلى المنطقة المحلية الحالية. انتهاء today يختبر في سياسة الاقتراح والتخزين، لا سياسة العودة وحدها.

  مثال اختبار عقد السياسة الجديدة (يوضع داخل ملف اختبارها مع استيراد النوع الجديد عند إنشائه):

  ```dart
  test('seven calendar days qualifies despite less than 168 hours', () {
    final policy = AdultReturnPolicy(toLocal: (value) => value.toUtc());
    final result = policy.evaluate(
      now: DateTime.utc(2026, 10, 11, 0, 1),
      lastHomeSeenAtUtc: DateTime.utc(2026, 10, 4, 23, 59),
      returnOfferLocalDate: null,
      returnDismissedLocalDate: null,
      explicitlyReturning: false,
    );
    expect(result.showOffer, isTrue);
    expect(result.eligibleLocalDate, '2026-10-11');
  });
  ```

- [ ] Run: `flutter test test/features/adult_journey/domain`؛ Expected اختبارات السلوك الجديد FAIL قبل التنفيذ.
- [ ] نفذ السياسات الخالصة فقط. حماية أولويات p1..p3 ثم ترتيب اختياري: مطابقة الهدف، ملاءمة الوقت، index الأصلي. إعداد الخطة/المراجعة الفارغة وجهات مفسرة، لا روابط آيات مفبركة.
- [ ] أعد الاختبارات حتى PASS؛ راجع عدم وجود أي استدعاء لتعديل تقدم أو خطة. Commit نطاق المهمة فقط.

## Task 3: Cubit ونموذج التخصيص الاختياري

**Files:** Create AJ presentation cubit/state/setup_sheet وsection. Modify `lib/features/settings/presentation/widgets/settings_hub_body.dart` (tile للكبار)، `lib/features/home/presentation/pages/home_page.dart` (تركيب section)، `lib/core/l10n/app_ar.arb`, `app_en.arb`, DI. Create AJT `presentation/adult_journey_cubit_test.dart`, `presentation/adult_journey_setup_sheet_test.dart`.

**Interfaces:** Cubit `load(AdultJourneyContext context)`, `saveProfile(AdultJourneyGoal goal, AdultJourneyExperience? experience)`, `snoozeSetup()`, `refreshContext(AdultJourneyContext context)`. State: immutable preferences/status/error-code/suggestions/returnDecision، مع request revision. Widget `AdultJourneySection(context: AdultJourneyContext)`؛ النموذج يستعمل نفس Cubit scope ولا يقرأ DB.

- [ ] اكتب اختبارات نموذج الهدف الأربع، experience اختيارية، التخطي/الرجوع بلا حفظ، retry بعد فشل، تغيير الخبرة لا يغيّر SRS/الصعوبة، إخفاء النموذج للطفل، no post-close emission، وإلغاء نتائج A→B→A.
- [ ] اكتب widget tests عربية وإنجليزية، فاتح/داكن، width320 وtextScale2.0، وأسماء semantics وخيارات radio/زر الحفظ. افصل نص الواجهة الجديد عن أي اقتباس ديني؛ لا محتوى تعبدي جديد.
- [ ] Run: `flutter test test/features/adult_journey/presentation/adult_journey_cubit_test.dart test/features/adult_journey/presentation/adult_journey_setup_sheet_test.dart`؛ تحقق الفشل للسلوك المفقود.
- [ ] نفذ النموذج وCubit، مع إشعارات خطأ localized لا raw exception. تحقق profileCompleted مستقل عن HomeLoaded.isFirstRun. لا تعدل `OnboardingState.stepCount` أو أكواد skip/login/guest.
- [ ] اختبر شرط البالغ المثبت: `selectedTrack == adults` و`!isKids` يظهر الملحق؛ `selectedTrack == null` أو طفل أو `HomeLoaded` بملف شخصي فاشل التحميل ⇒ لا ملحق والرئيسية كما هي. واختبر أن دعوة التخصيص لا تظهر في الرئيسية مع `HomeFirstRun`، وتبقى من الإعدادات.
- [ ] اختبر أن حفظ الهدف لا يكتب `user_primary_goal`، وأن النموذج لا يملأ مسبقًا منه.
- [ ] أضف مدخل الرئيسية والإعدادات وARB، ثم `flutter gen-l10n`؛ لا تعدل generated localizations يدويًا، ولا تستبدل تغييرات ARB السابقة. في `home_page.dart` أضف sliver واحدًا فقط يستدعي `AdultJourneySection`. ARB: أضف المفاتيح الجديدة دون إعادة ترتيب أو تنسيق، وراجع `git diff` للملفات الثلاثة للتأكد أن فرق المالك السابق باقٍ كما هو.
- [ ] أعد الاختبارات مع `flutter test test/features/onboarding test/features/settings test/features/adult_journey/presentation`؛ Expected PASS. استعرض فروق الترجمة/اللقطات قبل قبول أي baseline بصري. Commit المهمة.

## Task 4: وقت اليوم وربط الملاحة الحالية

**Files:** Create AJ today_budget_card وapplication launch_resolver و`presentation/adult_journey_context_adapter.dart` (تحويل `HomeLoaded` إلى `AdultJourneyContext`). Extend cubit بـ `setTodayMinutes(int minutes)`, `clearToday()`, `Future<String?> resolveLaunch(AdultJourneySuggestion suggestion)`. **لا تعديل** لـ HomeCubit/home_state؛ HomePage مركب من Task 3. Create AJT `application/adult_journey_launch_resolver_test.dart`, `presentation/adult_today_budget_card_test.dart`, `presentation/adult_journey_context_adapter_test.dart`.

**تقسيم المراحل:** بطاقة وقت اليوم والمحول ضمن المرحلة أ، وتعرض الاقتراحات دون تنقل (أو بالمسار الموجود في `UnifiedJourneyAction.route` لغير الاستئناف فقط إن قررت المراجعة ذلك). محلل التنقل وخطوات الاختبار المتعلقة به هي المرحلة ب.

**Interfaces:** `AdultJourneyLaunchResolver.resolve({required AdultJourneyLaunchKind kind, required String expectedOwnerId, AdultResumeDestination? resumeDestination}) -> Future<String?>`. نوع مقترح `AdultResumeDestination {memorization,quran,azkar,unknown}` يعرف بملف suggestion ويحمل في الاقتراح. المنافذ injectable closures تعيد أحدث route من مصادرها؛ memorize/review من `MemorizationNavigationResolver.resolve()`؛ reading/khatmah من بيانات Home المحدثة. resume يفتح وجهة القسم الثابتة فقط وفق spec §6، دون session URL أو معرفات من SharedPreferences. لا تنشأ دورة DI (Home لا يعتمد على Cubit الميزة).

- [ ] اختبارات today: 5/10/20 فقط، تخزين اليوم، إعادة تشغيل اليوم نفسه، انتهاء يوم جديد، clearToday لا يمس profile/return، فشل التخزين يبقي الاختيار السابق، flag off يزيل البطاقة ويترك Home كما كان.
- [ ] اختبارات launch: due-review يتغير بين العرض والنقر ⇒ استعمال أحدث reviewQuizLocation؛ انتهت الخطة ⇒ وجهة آمنة لا جلسة قديمة؛ current profile طفل ⇒ null؛ حساب تغير أو lease بطل ⇒ null؛ ضغطتان ⇒ حل وملاحة واحدة؛ URI لا يضيف blockSize ولا يعيد كتابة intent/origin.
- [ ] اختبر جلسة استئناف مكتملة/محذوفة، ورابط طفل قديم، وكتابة delayed last_restorable_location من الحساب السابق: البطاقة الجديدة لا تفتح تلك الجلسة، بل وجهة القسم الآمنة بلا معرفات أو null لمسار الطفل. لا تعتبر فحص شكل AppSessionService إثبات ملكية. دعم direct resume غير داخل الحزمة.
- [ ] اختبر بقاء بطاقة الختمة ومراجعتها الملحة مع budget5 واختيار حفظ؛ لا تعيد كتابة اختبارات الأولوية لتوافق overlay جديدًا.
- [ ] Run: `flutter test test/features/adult_journey/application test/features/adult_journey/presentation/adult_today_budget_card_test.dart test/features/home/domain/services/home_primary_action_resolver_test.dart`؛ تحقق الفشل الجديد قبل التنفيذ.
- [ ] نفذ الاختيار والعرض؛ ضع «تقريبًا» في كل تقدير، وتوضيح exceedsBudget، مع زر تغيير الوقت. لا مؤقت أو إيقاف صوت أو قص نطاق الجلسة.
- [ ] ابن Context عبر `adult_journey_context_adapter.dart` من `HomeLoaded` القائم (`alternativeActions` بترتيبها، `customPlan`، `microReview`، `selectedTrack`، `isKids`)؛ لا يستورد `HomeLoaded` في Domain. اختبر المحول: الترتيب محفوظ، والطفل أو غير المثبت ⇒ `isAdult=false`. إن احتجت حقلًا غير موجود فحدّث spec §6 أولًا ثم أضف getter مشتقًا فقط.
- [ ] نفذ resolver بنقرة واحدة وlease عبر await؛ أعط null عند فشل الهوية، وfallback إلى hub/لوحة الختمة إذا غاب الهدف. لا تفتح جلسة جديدة فوق جلسة مستأنفة تلقائيًا.
- [ ] Run: `flutter test test/features/adult_journey test/features/home test/core/journey test/features/memorization_plus/presentation/navigation test/features/memorization_plus/domain/navigation/review_ayah_location_test.dart`؛ Expected PASS مع تسجيل أي فشل سابق. Commit المهمة.

## Task 5: العودة الهادئة وزيارات الرئيسية الفعلية

**Files:** Create AJ return_card و`presentation/widgets/adult_journey_visibility_binding.dart`. Extend usecases/cubit بواجهات `recordVisibleHomeVisit()`, `startLightReturnToday()`, `dismissReturn()`, `continueNormally()`. Modify HomePage لتركيب binding. Create AJT `presentation/adult_return_card_test.dart`, `presentation/adult_journey_visibility_binding_test.dart`.

**Interfaces (مبسطة، مراجعة 2026-10-12):** binding خفيف يقيم الأهلية عند نقطتين فقط: وصول `HomeLoaded` جديد، و`AppLifecycleState.resumed`. الفحص لحظي عبر منفذ قابل للحقن `bool Function() isHomeForeground` يجمع: الفرع الحالي للـ shell = 0 (`StatefulNavigationShell.maybeOf(context)?.currentIndex`)، و`ModalRoute.of(context)?.isCurrent == true`، وحالة lifecycle resumed. ثم `AccountDataBarrier.isReady` وبالغ مثبت. لا عداد generation جديد ولا مستمع عام لكل حدث `changes`؛ تغير المالك يؤدي لتحميل Home جديد فيعاد التقييم، والـ lease الملتقط قبل الكتابة يبطل أي callback قديم. Cubit يكتب `RecordHomeVisit` باستخدام now injectable؛ المستودع يتجاهل الأمر إن كانت `lastHomeSeenAtUtc` في اليوم المحلي نفسه للمالك (كتابة واحدة يوميًا)، ويحسب offer والزيارة في نفس update المحمي.

- [ ] اختبارات: Home في تبويب آخر/تحت صفحة مدفوعة/خلفية/طفل/غير مثبت/حاجز مغلق ⇒ صفر زيارات؛ عدة تحميلات في اليوم نفسه ⇒ كتابة واحدة؛ يوم جديد ⇒ كتابة جديدة؛ disposal يلغي المستمع؛ baseline ترقية لا عرض؛ dayGap7 يظهر مرة، ويبقى متاحًا اليوم بعد restart حتى dismissal.
- [ ] اختبر cold start: الحاجز مغلق ثم يصبح جاهزًا ويصل `HomeLoaded` ⇒ زيارة واحدة؛ A→B ⇒ لا كتابة لمفتاح B بـ lease A، وزيارة B بعد تحميلها فقط؛ logout ثم login بعد غياب ⇒ خط أساس بلا دعوة عودة.
- [ ] اختبارات أفعال العودة: light⇒today5 وlightReturn=true فقط؛ continueNormally⇒مسح today ودعوة اليوم دون حذف profile؛ اختيار وقت دون تأكيد لا يحفظ؛ no reviews⇒قراءة/وجهة محايدة دون آيات جديدة؛ المقارنة قبل/بعد لسجلات الحفظ والخطة متطابقة.
- [ ] Run: `flutter test test/features/adult_journey/presentation/adult_return_card_test.dart test/features/adult_journey/presentation/adult_journey_visibility_binding_test.dart`؛ Expected فشل السلوك الناقص قبل التنفيذ.
- [ ] نفذ العرض دون popup أو navigation تلقائي؛ صياغة العودة لا تدّعي أن المستخدم ترك القرآن. خزّن returnOfferLocalDate قبل استبدال lastHomeSeenAtUtc، بعملية واحدة. لا تعتمد على recentActivity أو آخر مراجعة لتاريخ الغياب.
- [ ] تأكد من فصل `setupSnoozedLocalDate` عن `returnDismissedLocalDate`، وأن اختيار «عائد» يدويًا يعرض الخيارات دون اختلاق تاريخ. أعد الاختبارات حتى PASS. Commit المهمة.

## Task 6: تكامل الحماية والتفعيل التدريجي

**Files:** Create `test/integration/adult_journey_non_mutation_test.dart`, `test/integration/adult_journey_account_isolation_test.dart`, `test/integration/adult_journey_navigation_test.dart`. Extend `test/integration/account_switch_isolation_test.dart` فقط إن احتاج fixture التسجيل الجديد. Update evidence document وflags بعد مراجعة النتائج فقط.

**Interfaces:** المستودعات وcubit والواجهات من المهام السابقة؛ اختبارات المضيف تحت test/integration لا تمثل Android E2E.

- [ ] اكتب ثم شغّل اختبارات non-mutation على قاعدة اختبار كاملة المخططات: تغيير goal/experience/today/light/visit/dismiss لا يغير review evidence/checkpoints/SRS/plan/daily completion/khatmah/reading/bookmarks/XP. قارن snapshot القيم، لا عدد السجلات فقط.
- [ ] أثبت أن تنفيذ جلسة عادية بعد الدخول من البطاقة يسجل التقدم عبر المسار الحالي مرة واحدة، وأن refresh/restart لا يكرر الأثر أو يحتسب اختيار الوقت إنجازًا.
- [ ] اكتب وشغّل تكامل guest→accountA→B→logout، A→B→A مع delayed read/write، وحذف الحساب مع عملية حفظ منتظرة؛ Expected لا توريث أو resurrection، وبقاء الإعدادات العامة وفق العقد الحالي.
- [ ] اكتب وشغّل تكامل اختيار هدف دون خطة، review بلا سجلات، انتهاء/إيقاف ختمة قبل النقر، تسجيل الدخول من onboarding، deep link إلى قارئ/جلسة؛ اختيار التخصيص لا يعترض الوجهة الأصلية.
- [ ] Run: `flutter gen-l10n` ثم `dart format --output=none --set-exit-if-changed lib/features/adult_journey test/features/adult_journey test/integration/adult_journey_non_mutation_test.dart test/integration/adult_journey_account_isolation_test.dart test/integration/adult_journey_navigation_test.dart`، وأضف مسارات Dart المعدلة الأخرى صراحة. Expected formatter exit0.
- [ ] Run: `flutter analyze` ثم `flutter test`؛ سجل أمر/exit/output لكل منهما. فشل مرتبط بالحزمة أو ثوابت الحفظ/الهوية يمنع التفعيل. لا تحديث تلقائي للـgoldens لمجرد إنجاح الاختبار.
- [ ] تجربة Android موثقة على النسخة الحالية: مستخدم جديد/قديم/ضيف/حساب، عربي/إنجليزي، offline، تكبير نص، خلفية مع صوت شغال، منتصف الليل، process restart، تبديل الحساب، خطأ حفظ محاكى. تحقق أن 5 دقائق لا توقف التلاوة وأن زر الرجوع يعود للوجهة الصحيحة.
- [ ] راجع التنفيذ ومصفوفة القبول؛ فعّل personalization فقط ثم اختبر، ثم todayBudget ثم اختبر، ثم gentleReturn. قواعد الاعتماد: personalization=false يعطل الكل؛ todayBudget=false يعطل أفعال العودة الزمنية. لا ادعاء بتفعيل تدريجي عن بعد؛ هذه أعلام بناء محلية.
- [ ] جرّب rollback بإطفاء الأعلام الثلاثة: الواجهة السابقة تعمل، وكل تقدم حقيقي محفوظ. لا rollback بترحيل عكسي أو مسح قاعدة البيانات.
- [ ] سجل الملفات الجديدة ونتائج الاختبارات وما لم يختبر، ثم احفظ commit التفعيل فقط بعد مراجعة الأدلة. لا نشر أو دمج تلقائي ضمن هذه الخطة.

## Acceptance coverage

| شرط التصميم | المهمة/الدليل المطلوب |
|---|---|
| البداية اختيارية والتهيئة الحالية محفوظة | 3 + onboarding_flow_test |
| المالك والتنظيف والأخطاء لا تخلط البيانات | 1 + 6 |
| الوقت إرشادي ولا يقطع جلسة أو ينقص نطاقًا | 2 + 4 + تجربة Android |
| الأولويات والختمة تظل متاحة | 2 + 4 + home_primary_action_resolver_test |
| العودة من زيارة مالك مؤهلة، لا استنتاج إنجاز | 2 + 5 |
| يوم جديد/منطقة زمنية/restart | 2 + 4 + 5 + Android |
| لا تغيير ديني/تقدم بسبب التفضيلات | 6 snapshot + مراجعة diff |
| إيقاف الميزة يستعيد السلوك السابق | 4 + 6 flag matrix |

## Delivery phases (مراجعة 2026-10-12)

| المرحلة | المهام | الخطر | شرط الإغلاق |
|---|---|---|---|
| أ ✅ (`4438e529`) | 0، 1، 2، 3، وبطاقة وقت اليوم والمحول من 4 | منخفض: ملفات جديدة، وسطر بادئة في reset، وتسجيلات DI، وsliver واحد، ومفاتيح ARB | اختبارات المهام PASS، `flutter analyze` نظيف، الأعلام false |
| ب ✅ (2026-10-13) | محلل التنقل من 4 | متوسط: يعتمد على `MemorizationNavigationResolver` | اختبارات launch والمسارات القائمة PASS |
| ج ✅ آليًا (2026-10-13؛ تجربة الجهاز معلقة) | 5 ثم 6 | متوسط إلى عال: lifecycle وظهور وتبديل حساب | اختبارات Task 5 وتكامل Task 6 PASS، ثم تجربة Android يدوية يجريها المالك |

لا تبدأ مرحلة قبل إغلاق سابقتها. أي حاجة لتعديل `HomeCubit` أو المحرك أو `HomePrimaryActionResolver` توقف التنفيذ وتعود للتصميم.

### قرارات تنفيذ المرحلة أ (2026-10-13)

| القرار | السبب |
|---|---|
| الأعلام `AdultJourneyFlags` مفاتيح جهاز في SharedPreferences (`adult_journey_flag_<name>`) على نمط `KidsEnrichmentFlags`، لا ثوابت بناء | النمط الأحدث في المشروع؛ القيمة المفقودة أو التالفة = مطفأ؛ البادئة خارج `adult_journey_v1_` فلا يقلبها تبديل الحساب |
| سجل تالف (`corrupt`) يستبدل فقط بأمر صريح من المستخدم؛ الأمر الآلي (زيارة) يرفض. سجل إصدار أحدث (`unsupported`) لا يكتب فوقه أبدًا ويخفي الملحق | لا إعادة كتابة صامتة؛ لا حماية من خفض النسخة دون ذلك؛ والمستخدم لا يعلق بسجل تالف للأبد |
| `RecordAdultHomeVisit` يعيد «بلا تغيير» في اليوم المحلي نفسه، فلا كتابة | تنفيذ قاعدة الكتابة اليومية في المصغّر (reducer) الخالص، لا في الواجهة |
| حدث الحاجز لنفس المالك (مثل كتابة الختمة) يسقط النتائج الجارية ويعيد القراءة؛ تغير المالك وحده يخفي فورًا | `KhatmahRepositoryImpl` يطلق `notifyChanged` في كل كتابة؛ الإخفاء عندها يُسقط البطاقة حتى تحميل Home التالي |
| تنقل المرحلة أ: الاستئناف إلى ثابت القسم فقط، إعداد الخطة إلى `memorizationPlusCustomPlan`، المقترحات المبنية على إجراء إلى `action.route` كبطاقة Home الحالية | مسموح في الخطة للمرحلة أ؛ إعادة الحل بـ `MemorizationNavigationResolver` في المرحلة ب |
| مدخل الإعدادات مشروط بـ `memorizationProfile?.isAdult` لا `isAdultPath` | `isAdultPath` يقبل تلميح `mem_plus_track` القديم؛ نفس قاعدة البالغ المثبت في Home |
| `hasAdultReviewRecords` = `microReview != null || memorizedAyahs > 0`؛ `hasActiveAdultPlan` بقاعدة `MemorizationNavigationResolver` | مشتقة من حقول `HomeLoaded` القائمة دون تعديلها |

## Review and execution handoff

الوثيقتان مقترحتان وقابلتان للتعديل، ولم تنفذ المهام أو تثبت اختبارات التطبيق بعد. التوصية عند اعتماد التنفيذ: مهام صغيرة متتابعة، Terra للتنفيذ الروتيني، وSol لمراجعة الدمج؛ مراجعة مركزة أقوى فقط إذا ظهرت مشكلة في الهوية/البيانات تتجاوز الخطة. لا حاجة لسبعة مراجعين أو تدقيق إصدار شامل لهذه الحزمة.

تراجع الخطة والتصميم قبل بدء أي تعديل. يختار المستخدم وقتها التنفيذ المباشر أو التنفيذ مع مراجعة مستقلة لكل مهمة. أي حاجة لتغيير محرك الحفظ أو جداول SRS أو مخططات البيانات تعني توسيع نطاق يتطلب تصميمًا جديدًا، لا إضافة صامتة أثناء التنفيذ.

### قرارات تنفيذ المرحلة ج (2026-10-13)

| القرار | السبب |
|---|---|
| فحص «الرئيسية في المقدمة» يمر على كل مسار محيط عبر الملاحات (`route.navigator.context`)، لا `ModalRoute.isCurrent` وحده | صفحات القارئ والجلسات والأوراق تُدفع على الملاح الجذري فوق الـ shell، فيبقى مسار فرع الرئيسية «حاليًا» تحتها (P2 من المراجعة). مُثبت باختبار `GoRouter` حقيقي فشل مع الفحص القديم |
| الزيارات لا تسجل إلا مع تفعيل `gentleReturn` | أقل كتابة ممكنة؛ أول تفعيل يسجل خط أساس فقط، فلا دعوة قبل 7 أيام |
| «بداية خفيفة» و«أكمل كالمعتاد» أمران ذريان (`StartAdultLightReturn`، `ContinueAdultAsUsual`) | سجل واحد لكل اختيار؛ لا حالة وسيطة بين مسح اليوم وإخفاء الدعوة |
| وصف «عائد» يعرض الخيارات حتى أول إخفاء؛ التحول إليه من وصف آخر يمسح إخفاءً سابقًا | §4.3 «يظهر الخيارات فورًا» دون تكرار يومي مزعج ودون ادعاء تاريخ غياب |
| `recordHomeVisit` صامت ولا ينشر أثناء حفظ يجريه المستخدم | لا يُعطّل الأزرار ولا يمسح `isSaving`؛ المستودع يسلسل الكتابات |
| انحراف عن Task 6: مقارنة «عدم التعديل» على SharedPreferences بالقيم + فحص ثابت يمنع في مصدر الميزة أي Isar/Supabase/`user_primary_goal`/كتابة خارج المستودع؛ لا لقطة Isar | الميزة لا تملك مسارًا لـ Isar أصلًا، والفحص الثابت يكسر الاختبار إن أضيف |
| انحراف: لا `adult_journey_navigation_test.dart`؛ التنقل مغطى باختبارات المحلل (14) والـ slot مع `GoRouter` حقيقي | الحالات المطلوبة (جلسة قديمة، طفل، تبديل حساب، نقرتان) مختبرة في الوحدات بلا تكرار |

### إصلاحات مراجعة الفرع كاملًا (2026-10-13)

| الملاحظة | الإصلاح |
|---|---|
| خطأ يظهر في بطاقة أخرى | `AdultJourneyErrorSource` على الحالة؛ كل بطاقة تعرض خطأها فقط عبر `AdultJourneyErrorText` المشترك؛ النموذج يعرض خطأ الحفظ بعد محاولته هو فقط |
| حفظ ناجح يُبلَّغ كفاشل عند حدث حاجز لنفس المالك | `_write` يعيد نجاح الحفظ لنفس المالك؛ إعادة القراءة الناتجة عن الحدث تنشر السجل |
| الزيارة لا تُحسب عند الرجوع للرئيسية | الـ slot يستمع لـ `GoRouter.routerDelegate` ويفحص المقدمة بعد كل تنقل؛ الكتابة تبقى مرة يوميًا |
| الرئيسية قديمة بعد تعديل الإعدادات | `AdultJourneyRepository.changes` (معرّف المالك بعد كل حفظ فعلي)؛ الـ cubit يعيد القراءة إلا لحفظه الجاري |
| تجاوز منتصف الليل | `refreshDay()` عند العودة للتطبيق، ولا ينشر أثناء حفظ جارٍ |
| مدخل الإعدادات مع سجل أحدث/حساب غير جاهز | يعيد القراءة عند كل نقرة، يمنع النقر المزدوج، ويعرض رسالة مناسبة (نسخة أحدث ≠ حساب غير جاهز) بدل فتح نموذج لا يحفظ |
| صحة الكود | تقسيم `select` و`build` للبلاطة دون 50 سطرًا؛ تسمية `withinTime`/`fitsChosenTime`؛ تصحيح تعليق قديم |
| مقبول دون تغيير | ختم المالك وقت التغذية (يحرسه `HomeCubit` نفسه)؛ حفظ متزامن في الرئيسية والإعدادات بفارق أجزاء ثانية قد يترك الرئيسية قديمة حتى القراءة التالية |
