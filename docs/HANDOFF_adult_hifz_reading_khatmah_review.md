# Handoff: مراجعة الحفظ + القراءة + الختمة (مسار الكبار)

> ملف تسليم من جلسة Cowork لاستكمال المراجعة في Claude Code.
> الحالة: تمت قراءة الكود الأساسي للثلاث ميزات وتوثيق النتائج أدناه (مؤكدة من الكود). المتبقي موضّح في آخر الملف.

## المطلوب الأصلي من المستخدم
مراجعة ميزة الحفظ والقراءة والختمة بالكامل في مسار الكبار والتأكد أن كل منها يعمل بكفاءة دون مشاكل أو تداخل، ثم:
1. تقرير مفصل بالمشاكل وكيفية إصلاحها
2. تحسينات وتطوير لتجربة أفضل
3. خطة تنفيذ

(اتبع `AGENTS.md`: مستويات الخطورة P0–P4، ولكل مشكلة: المكان، المسار المتأثر، الفشل، الدليل، الأثر، الإصلاح المقترح. لا تعدّل الكود إلا إذا طلب المستخدم ذلك.)

---

## النتائج المؤكدة حتى الآن

### A. الحفظ (Memorization V2)

**A1 — P1: التقييم اليدوي (بدون STT) لا يُحدِّث التكرار المتباعد؛ الآية تبقى "جديدة" للأبد**
- `lib/core/memorization/v2/review_outcome_commit_support.dart` → `manualSchedule()` يغيّر `lastReviewedAt` و`nextReviewDate (+1 يوم)` فقط، ولا يزيد `totalReviews`.
- `lib/core/memorization/review_classification.dart`: `isNew = totalReviews == 0`.
- النتيجة: `memorization_daily_plan_service.dart` (السطر ~121) يعيد عرض نفس الآيات كـ "جديدة" كل يوم، فالمتعلم لا يتجاوز أول مقطع. وهي أيضاً تُحسب في `dueBacklogCount` (مسار "overdue-but-unclassified" في `daily_plan_review_queue.dart`) لكنها لا تظهر في أي قسم (weak/near/far)؛ وعند تجاوز السعة (10+5) يُغلق الحفظ الجديد دون عمل ظاهر.
- الإصلاح: تسجيل المراجعة اليدوية كمراجعة حقيقية (زيادة `totalReviews`، وجدولة متحفظة مثل تقييم "average" بفترة محدودة القيمة القصوى)، مع إبقاء الاستثناء من الإتقان/الشهادات. إضافة اختبار: 3 أيام تقييم يدوي ← لا تعود الآية في newAyahs.

**A2 — P1: "أكمل خطة اليوم" يفتح عناصر المراجعة كجلسة حفظ من 5 آيات**
- `memorization_navigation_resolver.dart` → `_v2SessionLocation` مع `continueDailyPlan` يستخدم دائماً `LearningIntent.memorize`، بينما `PendingAyahResolver.firstPendingPlanTarget` يعيد أولاً عناصر weak/near/far/retention.
- النتيجة: آية مراجعة تمر بالاستماع والتلميحات + 4 آيات بعدها (قد تكون خارج الخطة/جديدة)، وتُسجَّل "ممتاز" في SRS لمادة أُعيد تعلمها قبل ثوانٍ (عكس التعليق في `session_engine.startReview`).
- الإصلاح: استخدام `ayah.isNew ? memorize : review` كما في `dailyPlanAyahLocation` نفسها.

**A3 — P1: نقطة الاستئناف واحدة لكل سورة → المراجعة تمسح مقطع الحفظ الجاري + إعادة استخدام sessionId**
- المفتاح `IsarV2Session.keyFor(owner|audience|surahId)`؛ و`V2SessionLocalDatasource.saveSession` يحتفظ بـ `sessionId` القديم عند حفظ جلسة جديدة بنفس المفتاح.
- السيناريو: حفظ آيات 21–25 من البقرة جارٍ، ثم فتح مراجعة لآية من نفس السورة ← `startSession` لا يستأنف (intent مختلف) ← `_saveProgress` يستبدل نقطة الحفظ ← عند انتهاء المراجعة `_onBlockCompleted` يمسح الصف. تقدم المقطع يضيع. وإذا كانت آية المراجعة ضمن المقطع الجاري ونجحت فيه سابقاً، فمفتاح `'$sessionId|ayah:S:A|final'` موجود ← `alreadyCommitted` ← لا تُجدول المراجعة.
- كذلك بدء مقطع جديد في نفس السورة لا يحتوي startAyah يستبدل المقطع غير المكتمل بصمت.
- الإصلاح: إضافة intent (و/أو نطاق المقطع) لمفتاح الجلسة، وتوليد sessionId جديد عند بدء جلسة جديدة (عدم وراثته)، أو تحذير المستخدم قبل الاستبدال.

**A4 — P2: فشل مراجعة المقطع لا يخفض تقييم الآية الضعيفة، وإعادة النجاح بعد العلاج تُبتلع**
- `commitFailedAutomaticAttempt` يكتب حدث attempt فقط دون تحديث projection. وإعادة النجاح لنفس الآية في نفس الجلسة تُعاد كـ `alreadyCommitted` قبل كتابة checkpoint (فلا تتقدم نقطة الاستئناف أيضاً).
- الإصلاح: عند فشل مراجعة المقطع، خفّض تقييم الآية المستهدفة (weak/lapse) أو أعد جدولتها؛ واجعل taskId لما بعد العلاج مميزاً (مثلاً `ayah:S:A:remediation:n`).

**A5 — P2: نطاق "أعد المحاولة" (0.70–0.88) يُعامل كفشل**
- `recitation_evaluator.dart` يحسب `RecitationVerdict.retry` لكن `session_engine.evaluateRecitation` يعتمد على `passed` فقط ← علاج + تسجيل فشل + أثر على SRS لأخطاء قد تكون من التعرف على الصوت. الواجهة فقط تعرض "retry".
- الإصلاح: retry يبقى في `reciting` دون تسجيل فشل (مع حد أقصى للمحاولات قبل العلاج).

**A6 — P2: حجم المقطع ثابت 5 آيات** بغض النظر عن `newAyahsPerDay` أو طول الآيات (البقرة مقابل جزء عم)، ولا يُمرَّر `blockSize` في المسارات. مراجعة المقطع الطويلة في تسجيل STT واحد (`pauseFor: 5s`، بدون `listenFor`) معرّضة للقطع.
- الإصلاح: حجم المقطع = min(newAyahsPerDay، حد بعدد الكلمات/الأسطر)، وتقسيم مراجعة المقطع الطويل.

**A7 — P3: XP المراجعة** — `review_effect_outbox_processor._processXp` يضيف دائماً `v2_block_completed` حتى لمراجعة آية واحدة (المحوّل القديم كان يفرق).

**A8 — P3: صفوف `sync` في الـ outbox** تبقى pending للمستخدم غير المسجل، وتُقرأ كلها في كل `processPending` (نمو غير محدود).

### B. القراءة

**B1 — P1: "الورد اليومي" يتحرك مع أي قراءة حرة**
- `quran_reader_page._confirmThenRecordKhatmah` في الوضع الحر يستدعي `saveDailyWirdLastCompletedPage(pageNumber)` لأي صفحة تُؤكَّد، حتى الرجوع للخلف أو فتح الكهف يوم الجمعة ← ورد الغد يقفز (`GetDailyWirdUsecase`: lastCompleted + 1).
- الإصلاح: التحديث فقط إذا كانت الصفحة = هدف اليوم أو امتداده المتصل (max مع القيمة السابقة وبشرط التسلسل)، أو فصل "مكان القراءة الحرة" عن "تقدم الورد".

**B2 — P2: الورد اليومي صفحة واحدة بلا حالة إنجاز**؛ `DailyWirdCard` لا يعرض "تم اليوم". مفاتيح `daily_wird_target_YYYY-MM-DD` لا تُحذف أبداً من SharedPreferences.

**B3 — P2: تأكيد القراءة يحتاج لمسة + مؤقت**؛ الاستماع للتلاوة (تقليب الصفحات تلقائياً عبر الصوت) لا يُحتسب أبداً. خيار مقترح: "الاستماع يُحتسب" للختمة.

**B4 — P3:** `confirmRead` يترك الصفحة pending للأبد إذا لم تكن الحالة `QuranPageLoaded` (لا يُستدعى `clearPending`).

### C. الختمة

**C1 — P1: القراءة في وضع الختمة لا تُسجل السلسلة (streak) ولا سجل القراءة**
- `recordOrdinaryReading: false` في وضع الختمة ← `QuranPageCubit.confirmRead` يتخطى `StreakService.recordActivity` و`DailyReadingLogService`. المستخدم الذي يقرأ ورد الختمة فقط يخسر سلسلته.
- الإصلاح: تسجيل النشاط/السلسلة لقراءة الختمة مع إبقاء فصل تقدم الورد العادي.

**C2 — P1 (تداخل): بطاقة "أكمل التلاوة" في الرئيسية تعرض سورة/آيات صفحة الورد العادي بينما تفتح صفحة الختمة**
- `ContinueRecitationMapper._fromKhatmah` يستخدم `dailyWirdPageDetail` (صفحة `GetDailyWirdUsecase`) للاسم والمعاينة، والمسار `plan.nextUnreadPage`.
- الإصلاح: تحميل تفاصيل صفحة `nextUnreadPage` للختمة.
- مرتبط (يحتاج تحقق): `HomeCubit._refreshKhatmah` يحدّث `activeKhatmah` فقط ولا يعيد حساب `continueRecitation` ← تقدم قديم على البطاقة بعد القراءة.

**C3 — P2: فتح القارئ من لوحة الختمة ينشئ KhatmahCubit جديداً**
- المسار `/quran/page/X?mode=khatmah` لا يمرر cubit ← `getIt<KhatmahCubit>()` (factory) جديد + `load()`. إذا كان ورد اليوم مكتملاً، يُصدَر `KhatmahWirdCompleted` فوراً ← يظهر حوار الختام (غير قابل للإغلاق باللمس) عند كل فتح للقارئ. (تحقق عملياً.)

**C4 — P2: السلسلة بتوقيت UTC** — `StreakService.recordActivity` و`_processStreak` في الـ outbox يستخدمان يوم UTC؛ في القاهرة (UTC+3) القراءة 00:00–03:00 تُحسب لليوم السابق. والختمة/الخطة اليومية تستخدم اليوم المحلي. كما يوجد تطبيقان مختلفان للسلسلة (الـ outbox بدون "يوم الرحمة" ولا milestones).

**C5 — P2: تحديثات الختمة تسبب إعادة تحميل وومضة**: `_changesSub` في `KhatmahCubit` يستدعي `load()` (يُصدر `KhatmahLoading`) بعد كل تغيير قد يصل بعد انتهاء الطلب المعلق.

**C6 — P3:** التسجيل "الفعلي" (physical) يحسب `confirmedStart` من الخطة الممرَّرة (قد تكون قديمة) وليس `current` داخل `mutatePlan`.

**C7 — تحسينات:** بدء الختمة من صفحة محددة (الحقل `startPage` موجود لكنه غير مستخدم، `nextUnreadPage` يبدأ دائماً من 1)؛ إعداد بتاريخ انتهاء/عدد أيام (رمضان 30 يوم) وليس صفحات/يوم فقط؛ إعادة توزيع تلقائية عند التأخر؛ الختمة المتوقفة لا تُسجل القراءة دون إشعار واضح في القارئ.

---

## ما لم يُراجَع بعد (للاستكمال)
- `memorization_hub_page.dart`, `daily_plan_page.dart`, `custom_plan_setup_page.dart`, `practice_surah_page.dart`, صفحات `v2/*` (UX، حالات فارغة، رسائل).
- `review_evidence_sync_service.dart`, `memorization_production_sync_service.dart` (مزامنة وتعارضات).
- `khatmah_dashboard_page.dart` (بقية الملف)، `khatmah_completion_page.dart`، `khatmah_reader_session_bar.dart`.
- `home_cubit.copyWith` للتحقق من C2 الجزء الثاني، وتسجيل `KhatmahCubit` كـ factory (C3).
- تشغيل: `flutter analyze` و`flutter test` (test/ فيه اختبارات موجودة) وكتابة اختبارات تثبت A1, A2, A3, B1, C1, C2.

## خطة التنفيذ المقترحة (مسودة)
1. **الموجة 1 (أعطال تمنع التقدم):** A1، A2، A3، B1، C1، C2 — مع اختبار وحدة لكل واحدة قبل الإصلاح (TDD).
2. **الموجة 2 (سلامة البيانات والاتساق):** A4، A5، C3، C4 (توحيد السلسلة على اليوم المحلي وخدمة واحدة)، C5.
3. **الموجة 3 (تجربة المستخدم):** A6 (مقطع ذكي)، B2 (حالة إنجاز الورد)، B3 (الاستماع يُحتسب)، C7 (بدء من صفحة / ختمة بمدة / إعادة توزيع).
4. **الموجة 4 (أداء وصيانة):** A7، A8، B4، C6، تنظيف مفاتيح SharedPreferences القديمة.

## أمر مقترح لبدء Claude Code
```
اقرأ docs/HANDOFF_adult_hifz_reading_khatmah_review.md واستكمل المراجعة: تحقق من البنود المعلَّمة "يحتاج تحقق"، راجع الملفات في قسم "ما لم يُراجَع بعد"، شغّل flutter analyze و flutter test، ثم أخرج التقرير النهائي المفصل وخطة التنفيذ. لا تعدّل كود التطبيق قبل موافقتي.
```
