# Daily Review Task Implementation Plan — مهمة مراجعة تناسب وقت المستخدم

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** إظهار مهمة مراجعة واحدة مفهومة من الأنظمة الحالية، مع سبب ومدة تقريبية وبداية سهلة.

**Architecture:** read model صغير فوق AdultJourneySuggestionPolicy والمحرك الموحد؛ launch resolver الحالي يحسم الوجهة عند الضغط. لا scheduler جديد ولا journal إنجاز أو نقاط مستقل.

**Tech Stack:** Flutter/Dart، Cubit، GetIt، GoRouter وProgressEventsBus الحاليون؛ تخزين وقت اليوم الحالي دون schema جديدة.

**Spec:** `docs/superpowers/specs/2026-10-31-three-initiatives-design.md`، القسم C.

**حالة 2026-11-01:** C1/C2 منفذان ومختبران آليًا مع ربط الواجهة والتحقق الحديث عند الضغط؛ أضيفت لـC3 ثلاثة اختبارات ناجحة لتكامل القرار والمحرك والتخزين الحقيقي ومنع الإنجاز عند الخروج أو فشل الحفظ. يبقى قبول الرحلة الرسومية على Android وقارئ الشاشة وإعادة التشغيل؛ اختبار المجال ليس بديلًا عنها. العلم مطفأ افتراضيًا. [سجل التنفيذ](../../release/2026-10-31-three-initiatives-validation.md).

## Global Constraints

- Dart `^3.12.0` وFlutter `>=3.44.0`؛ لا ترقية حزم ولا تعديل جدولة FSRS أو تقييم التسميع.
- للبالغ المؤكد فقط؛ اختيارات الوقت 5/10/20، بلا اختيار تلقائي إن لم يختر المستخدم.
- أولوية الاستئناف/التنبيه الحرج/المراجعة المستحقة تبقى كما في الأنظمة الحالية. لا استبدال لبطاقة الختمة الرئيسية.
- لا تغيير blockSize/intent/origin أو اختصار جلسة لتناسب وقتًا تقديريًا؛ لا تسجيل إنجاز عند الضغط أو مجرد العودة.
- كل واجهة عربية وإنجليزية وTalkBack وتكبير 200%؛ الأسباب من بيانات فعلية دون نسب ثقة أو توقعات مختلقة.

## Review Focus

1. لا مراجعات أو كلها منجزة: لا وعد بمهمة غير موجودة — C1.
2. مهمة أطول من الوقت المختار: توضيح وخيار صريح لا قطع صامت — C1/C2.
3. حدث حفظ متأخر بعد تبديل حساب أو تحول لطفل: لا اقتراح أو تنقل قديم — C2.
4. ضغط مزدوج/العودة دون إكمال: لا جلستان أو إنجاز وهمي — C2/C3.
5. منتصف الليل وتغير timezone: اختيار وقت أمس لا يسري على اليوم الجديد — C1/C3.

## Task C1: إسقاط مهمة واحدة من التوصيات الحالية

**Files:**
- Create: `lib/features/adult_journey/domain/entities/daily_review_task.dart`, `domain/services/daily_review_task_policy.dart`.
- Read/reuse: `domain/services/adult_journey_suggestion_policy.dart`, `domain/entities/adult_journey_context.dart`, `lib/core/journey/unified_journey_action.dart`.
- Test: `test/features/adult_journey/domain/daily_review_task_policy_test.dart`; preserve `adult_journey_suggestion_policy_test.dart`.

**Interfaces:**
- `DailyReviewTaskDecision` مع status (ready/noReviews/noDueReview/blockedByPriority/unavailable)، suggestion عند ready، estimatedMinutes، exceedsBudget، reason، ownerId وlocalDate وdecisionKey لمراجعة صلاحية العرض، دون حالة persisted للإنجاز.
- `DailyReviewTaskDecision DailyReviewTaskPolicy.select({required AdultJourneyContext context, required AdultJourneyPreferences preferences})`؛ تقرأ `context.actions` كاملة، وليس suggestions المختصرة.
- خوارزمية القرار: طفل/هوية غير مؤكدة→unavailable؛ أول p1 resume إن وجد؛ ثم أول إجراء p2 حرج: إن كان review يعرض، وإلا blockedByPriority؛ ثم أول action ذي intent=review بترتيب المحرك الحالي. إن غاب: hasAdultReviewRecords=false→noReviews؛ hasDueAdultReview=true→unavailable مع إعادة تحميل/فتح المركز؛ وإلا noDueReview. لا توليد نطاق أو حالة إنجاز من flags وحدها.
- حول action إلى AdultJourneySuggestion باستخدام `AdultJourneySuggestionPolicy.launchKindOf` و`resumeDestinationOf` و`journeyActionMinutes` الموجود في unified_journey_engine.dart؛ reason=resume للاستئناف، urgent لـp2/p3، timeFit لمراجعة تلائم وقتًا اختاره المستخدم، ordinary لغير ذلك. عدم اختيار وقت لا يخفي المراجعة ولا يفترض budget. decisionKey تركيب مستقر لـowner/localDate/actionType/route/priority، ويتحقق eligibility من snapshot جديد لا من المفتاح وحده.

- [ ] اكتب حالات: طفل→غير ظاهر؛ resume→يحافظ على الأولوية؛ critical غير مراجعة→blockedByPriority؛ مراجعة مستحقة→المهمة الحالية؛ لا سجلات→noReviews؛ لا مستحق→noDueReview؛ مهمة 10 دقائق مع budget 5→exceedsBudget=true.
- [ ] اختبر ثبات النتيجة لنفس snapshot وعدم ترتيب جديد للسجلات أو تعديل preferences/actions؛ زمن أمس لا يطبق بعد تغير localDate.
- [ ] اختبر review بعد أكثر من ثلاث actions، وغياب goal/budget، وhasDueAdultReview=true دون action صالح؛ لا تسقط المهمة أو تختلق route.
- [ ] شغل `flutter test test/features/adult_journey/domain/daily_review_task_policy_test.dart` للتأكد من الفشل ثم نفذ policy pure بلا DI أو تخزين أو clock مخفي.
- [ ] أعد الاختبار واختبارات policy القائمة؛ راجع ثم commit.

## Task C2: بطاقة واحدة والتحقق من الوجهة عند الضغط

**Files:**
- Create: `lib/features/adult_journey/presentation/widgets/daily_review_task_card.dart`.
- Modify: `lib/features/adult_journey/presentation/cubits/adult_journey_state.dart`, `adult_journey_cubit.dart`, `presentation/widgets/adult_today_budget_card.dart`, `adult_journey_home_slot.dart`, `lib/core/l10n/app_ar.arb`, `lib/core/l10n/app_en.arb`.
- Modify: `lib/features/adult_journey/adult_journey_feature_flags.dart`, `lib/core/experience/rollout_manifest.dart`؛ DI إذا احتاج policy injection.
- Test: new `test/features/adult_journey/presentation/daily_review_task_card_test.dart`؛ reuse cubit/home_slot/launch_resolver tests.

**Interfaces:**
- `DailyReviewTaskCard({required DailyReviewTaskDecision decision, required VoidCallback onStart, required VoidCallback onOtherOptions})`؛ العرض بلا business logic.
- state يضيف decision مشتقًا من نفس owner/context؛ استخدم `AdultJourneyCubit.resolveLaunch(suggestion)` وAdultJourneyLaunchResolver الموجودين؛ أعد refresh عند العودة وأحداث تقدم موثوقة.
- أضف `Future<String?> resolveDailyReviewLaunch({required String expectedDecisionKey})` إلى Cubit، مع `Future<AdultJourneyContext> Function() loadFreshContext` محقون يبني من Home load جديد والساعة الحالية. أثناء الضغط: امنع التكرار، التقط owner/lease، حمّل context/preferences جديدين، أعد select، وقارن decisionKey/day/adult/eligibility؛ اختلافها يحدث البطاقة ويعيد null. بعد ذلك فقط resolveLaunch، ثم تحقق من owner/lease/day مرة ثانية. الواجهة تتحقق من current state/mounted مباشرة قبل التنقل بلا await بين الفحص وpush. لا تعيد استعمال context المخبأ كبديل عند فشل التحديث.
- feature `dailyReviewTask` يبدأ off؛ عند on تستبدل قائمة الاقتراحات داخل بطاقة وقت اليوم بمهمة واحدة، وتبقى «خيارات أخرى» تفتح القائمة الأصلية داخل sheet. لا تضف بطاقة رئيسية مكررة.

- [ ] اختبر noReviews برسالة وبداية مناسبة، وnoDueReview برسالة بلا إنجاز، والمدة بوصف تقريبي، وexceedsBudget بخياري تغيير الوقت/متابعة المهمة الحالية. blockedByPriority لا يخفي الإجراء المحمي.
- [ ] اختبر ضغطين متتابعين→at most one navigation، والحساب يتغير أثناء resolve→لا تنقل؛ العودة من route بلا evidence→لا completed أو XP. feature off يعيد UI الحالي دون مسح تفضيل الوقت.
- [ ] اختبر انتهاء مراجعة من مكان آخر قبل الضغط، وعبور منتصف الليل أو التحول لطفل أثناء fresh load أو route resolution: abort ثم refresh، حتى إذا بقي route نفسه.
- [ ] شغل `flutter test test/features/adult_journey/presentation` مع الفشل المقصود؛ نفذ UI مشتقًا من state وواجهة «خيارات أخرى» والتوطين، ثم `flutter gen-l10n`.
- [ ] أعد `flutter test test/features/adult_journey` واختبارات home primary action القائمة؛ لا تغير ترتيب الختمة أو urgent review. راجع ثم commit.

## Task C3: قبول رحلة المراجعة دون ازدواج الإنجاز

**Files:**
- Create: `test/integration/daily_review_task_flow_test.dart` حسب نمط اختبارات التكامل القائم.
- Reference: `lib/core/memorization/v2/review_outcome_committer.dart`, `lib/features/adult_journey/application/adult_journey_launch_resolver.dart`.
- Record runtime evidence in سجل G؛ لا تعديل committer من أجل تجميل البطاقة.

**Interfaces:** اختبار يقرأ task decision ووجهة حية ونتيجة commit القائمة؛ لا يحقن «إنجاز» وهميًا في واجهة البطاقة.

- [ ] اكتب سيناريو تفضيل 5 دقائق→مراجعة→إنهاء ناجح عبر مسار الحفظ الحالي→refresh يختار الحالة التالية الصحيحة؛ افحص أن progress effect واحد فقط، وأن إعادة فتح home لا تعيد منحه.
- [ ] اختبر خروجًا مبكرًا، فشل commit، انقطاع الشبكة مع حفظ محلي ناجح، restart، وتبديل الحساب/الوقت قبل بدء المهمة. اختبر منتصف الليل بحقن clock دون انتظار حقيقي.
- [ ] شغل `flutter test test/integration/daily_review_task_flow_test.dart`؛ إذا كان harness الحالي يتطلب جهازًا استخدم نمطه المسجل بدل تحويل integration إلى mock-only؛ سجل ما لم يختبر فعليًا.
- [ ] اختبر Android فعليًا بالعربية وTalkBack و200%، ومستخدم بالغ بلا خطة ثم مع خطة وختمة نشطة. لا تكتب task complete إلى مخزن جديد.
- [ ] راجع وcommit اختبارات المهمة فقط. فعّل بعد G؛ الرجوع للمظهر السابق بالمفتاح لا يغير خطة أو سجل مراجعة.
