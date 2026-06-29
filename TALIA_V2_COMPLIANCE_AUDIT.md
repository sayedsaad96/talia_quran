# TALIA V2 — COMPLIANCE AUDIT PROMPT
# تحقق من تنفيذ الـ Specs في الكود الفعلي

---

## دورك

أنت Senior Flutter Architect مسؤول عن تدقيق مطابقة الكود للـ Specifications.

لديك 3 وثائق تصميم:
- **ProductSpec.md** — ماذا يفعل التطبيق (من منظور المنتج)
- **ArchitectureSpec.md** — كيف يُبنى داخلياً (من منظور الهندسة)
- **V2_MASTER_PROMPT.md** — خطة التنفيذ المفصلة (Phase A → H)

مهمتك: **افتح الكود، اقرأه، وأجب: هل نُفِّذ ما في الـ specs أم لا؟**

---

## قواعد صارمة

- **لا تثق بأي documentation موجودة في المشروع** — اقرأ الكود فقط
- كل نتيجة تحتاج **file:line** كدليل
- إذا لم تجد دليلاً → اكتب `NOT VERIFIED` وليس PASS
- لا تعدّل أي كود في هذا الـ prompt — **READ ONLY**
- إذا وجدت شيئاً غير متوقع → سجّله كـ `DISCREPANCY`

---

## DO NOT TOUCH

```
لا تعدّل أي ملف في هذا الـ prompt.
هذا audit قراءة فقط.
```

---

## المرجع المختصر للـ Specs

### من ProductSpec — Core Requirements:

```
PROD-01: رحلة الحفظ = Learning → Memorizing → Reciting → Block Review → Completed
PROD-02: لا يوجد نص آية أثناء Recitation phase
PROD-03: لا يوجد نص آية أثناء Block Review
PROD-04: Hint System: 3 مستويات فقط (Level 0/1/2)
PROD-05: Hints تظهر فقط في Memorizing phase
PROD-06: Hints لا تظهر في Recitation أو Block Review
PROD-07: الآية تُعتبر محفوظة فقط بعد Recitation Pass
PROD-08: Block Review: بعد N آيات — اختبار المقطع كاملاً
PROD-09: Block Review Failure → إعادة الآيات الضعيفة فقط
PROD-10: Kids: نفس الـ engine، تغيير في الـ UI فقط
PROD-11: Remediation = إعادة تعليم آية فشلت ثم إعادة Recitation
```

### من ArchitectureSpec — Core Requirements:

```
ARCH-01: State Machine: created→learning→memorizing→reciting→remediation→blockReviewPending→blockReview→completed
ARCH-02: Learning phase: لا تقييم، لا تسجيل نجاح/فشل
ARCH-03: Memorizing phase: يسمح Hint System، يُسجَّل مستوى المساعدة
ARCH-04: Reciting phase: تقييم Pass/Fail، لا نص ظاهر
ARCH-05: Feature flag: enable_memorization_v2 يجب أن يكون default=false
ARCH-06: Backward compatibility: flag OFF → legacy flow يعمل عادي
ARCH-07: ممنوع تعديل Review Engine
ARCH-08: كل تغيير backward compatible
```

### من V2_MASTER_PROMPT — Building Blocks المطلوبة:

```
V2-01: ReviewRecordCreatedByMode enum يحتوي على v2Session value
V2-02: ReviewRecordFilters.isAdultCompatible() يشمل v2Session
V2-03: MemorizationProfile يحتوي على childAge (int?)
V2-04: V2SessionPhase enum موجود مع كل الـ states
V2-05: V2HintLevel enum موجود (none/firstWord/fullText)
V2-06: V2SessionEngine موجود كـ pure stateless class
V2-07: V2SessionState موجود مع tracking fields
V2-08: V2SessionReviewAdapter موجود ومسجّل في GetIt
V2-09: V2SessionProgressAdapter موجود
V2-10: V2SessionGamificationAdapter موجود
V2-11: MemorizationSessionCubit موجود مع الـ states المطلوبة
V2-12: 6 V2 pages موجودة (learning/memorizing/reciting/remediation/block_review/completion)
V2-13: GoRouter route: /memorization-v2/session موجود
V2-14: MemorizationSessionCubit مسجّل في GetIt
V2-15: ScheduleNextReviewUsecase مسجّل في GetIt
V2-16: ArabicNormalizer موجود بالـ 7 normalization rules
V2-17: V2FeatureFlag موجود بـ isAdultEnabled() و isKidsEnabled()
V2-18: Block Review skip logic للأطفال أقل من 8 سنوات
V2-19: AyahReviewRecord يُكتب بـ mode=v2Session بعد كل آية
V2-20: Smart Coach يقرأ V2 records (Priority 1-4)
```

---

## PHASE 1 — BUILDING BLOCKS VERIFICATION

تحقق من وجود المكونات الأساسية.

### الخطوة 1: اقرأ هيكل المشروع أولاً

```bash
# خريطة الـ V2 files
find lib/ -path "*/v2*" -o -path "*/memorization_v2*" | grep -v ".g.dart" | sort

# خريطة الـ core/memorization
find lib/core/memorization/ -name "*.dart" | grep -v ".g.dart" | sort

# خريطة الـ memorization session cubit
find lib/features/ -name "*session*cubit*" -o -name "*session_cubit*" | grep -v ".g.dart"
```

### الخطوة 2: تحقق من كل building block

للتحقق من كل V2-XX item أدناه، استخدم هذا الأسلوب:

```bash
# مثال للتحقق من V2-01:
grep -n "v2Session\|V2Session" \
  lib/features/memorization_plus/domain/entities/memorization_entities.dart

# مثال للتحقق من V2-04:
grep -n "enum V2SessionPhase\|created,\|learning,\|memorizing,\|reciting,\|remediation" \
  lib/core/memorization/v2/session_phase.dart 2>/dev/null || echo "FILE NOT FOUND"
```

**للتحقق من كل item، افتح الملف المتوقع مباشرةً — لا تبحث عشوائياً.**

### جدول التحقق — Building Blocks

لكل item، اكتب:
- `✅ PASS` + file:line إذا وُجد
- `❌ MISSING` إذا غير موجود
- `⚠️ PARTIAL` + التفصيل إذا موجود جزئياً
- `🔄 DISCREPANCY` + التفصيل إذا موجود لكن مختلف عن الـ spec

```
[V2-01] ReviewRecordCreatedByMode includes v2Session
  Expected: lib/features/memorization_plus/domain/entities/memorization_entities.dart
  Check: grep -n "v2Session" lib/features/memorization_plus/domain/entities/memorization_entities.dart
  Result: [ ]

[V2-02] ReviewRecordFilters.isAdultCompatible() includes v2Session
  Expected: lib/core/memorization/review_record_filters.dart
  Check: cat lib/core/memorization/review_record_filters.dart
  Result: [ ]

[V2-03] MemorizationProfile has childAge field
  Expected: lib/features/memorization_plus/domain/entities/memorization_profile.dart
  Check: grep -n "childAge" lib/features/memorization_plus/domain/entities/memorization_profile.dart
  Result: [ ]

[V2-04] V2SessionPhase enum with all 8 states
  Expected: lib/core/memorization/v2/session_phase.dart
  Check: cat lib/core/memorization/v2/session_phase.dart
  Verify: created, learning, memorizing, reciting, remediation, blockReviewPending, blockReview, completed
  Result: [ ]

[V2-05] V2HintLevel enum
  Expected: lib/core/memorization/v2/ (find the file)
  Check: grep -rn "enum V2HintLevel\|V2HintLevel" lib/core/memorization/v2/
  Result: [ ]

[V2-06] V2SessionEngine (pure stateless class)
  Expected: lib/core/memorization/v2/session_engine.dart
  Check: grep -n "class V2SessionEngine" lib/core/memorization/v2/session_engine.dart 2>/dev/null
  Verify: stateless (no mutable state fields), pure logic
  Result: [ ]

[V2-07] V2SessionState with tracking fields
  Expected: lib/core/memorization/v2/ (find the file)
  Check: grep -rn "class V2SessionState\|currentPhase\|currentAyah\|failureTracker\|hintTracker" lib/core/memorization/v2/
  Result: [ ]

[V2-08] V2SessionReviewAdapter registered in GetIt
  Check 1: grep -n "V2SessionReviewAdapter" lib/core/di/injection.dart
  Check 2: grep -n "class V2SessionReviewAdapter" lib/ -r --include="*.dart" | grep -v ".g.dart"
  Result: [ ]

[V2-09] V2SessionProgressAdapter
  Check: grep -rn "class V2SessionProgressAdapter" lib/ --include="*.dart" | grep -v ".g.dart"
  Result: [ ]

[V2-10] V2SessionGamificationAdapter
  Check: grep -rn "class V2SessionGamificationAdapter" lib/ --include="*.dart" | grep -v ".g.dart"
  Result: [ ]

[V2-11] MemorizationSessionCubit with required states
  Expected: lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart
  Check: grep -n "class.*Cubit\|MSInitial\|MSLoading\|MSActive\|MSComplete\|MSError\|MemorizationSession" \
    lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart
  Result: [ ]

[V2-12] 6 V2 pages exist
  Check: find lib/features/memorization_plus/presentation/pages/ -name "v2_*" -o -name "*v2*" | grep -v ".g.dart"
  Verify: learning / memorizing / reciting / remediation / block_review / completion
  Result: [ ]

[V2-13] GoRouter route /memorization-v2/session
  Check: grep -n "memorization-v2\|memorizationV2" lib/core/router/app_router.dart
  Result: [ ]

[V2-14] MemorizationSessionCubit registered in GetIt
  Check: grep -n "MemorizationSessionCubit" lib/core/di/injection.dart
  Result: [ ]

[V2-15] ScheduleNextReviewUsecase registered in GetIt
  Check: grep -n "registerLazySingleton<ScheduleNextReviewUsecase\|registerFactory<ScheduleNextReviewUsecase" \
    lib/core/di/injection.dart
  Result: [ ]

[V2-16] ArabicNormalizer with 7 normalization rules
  Expected: lib/core/utils/arabic_normalizer.dart
  Check: cat lib/core/utils/arabic_normalizer.dart
  Verify presence of: harakat removal, hamza normalization, alif variants, stop symbols,
    punctuation, spaces, tatweel
  Result: [ ]

[V2-17] V2FeatureFlag with isAdultEnabled() and isKidsEnabled()
  Expected: lib/core/memorization/v2/v2_feature_flag.dart
  Check: cat lib/core/memorization/v2/v2_feature_flag.dart
  Verify: default value = false for both methods
  Result: [ ]

[V2-18] Block Review skip for children under 8
  Check: grep -n "childAge\|blockReviewRequired\|blockReview.*skip\|age.*8\|8.*age" \
    lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart
  Result: [ ]

[V2-19] AyahReviewRecord written with mode=v2Session after each ayah
  Check: grep -n "v2Session\|createdByMode.*v2\|V2Session" \
    lib/core/memorization/v2/session_adapters.dart 2>/dev/null || \
    grep -rn "v2Session\|createdByMode" lib/core/memorization/v2/ --include="*.dart"
  Result: [ ]

[V2-20] Smart Coach reads V2 records (Priority 1-4)
  Check 1: grep -n "v2Session\|V2Session\|isAdultCompatible" lib/core/memorization/smart_coach_engine.dart
  Check 2: grep -n "isAdultCompatible" lib/core/memorization/review_record_filters.dart
  Verify: v2Session is included in isAdultCompatible filter
  Result: [ ]
```

---

## PHASE 2 — PRODUCT RULES VERIFICATION

تحقق من تطبيق قواعد المنتج في الكود الفعلي.

### PROD-01: State Machine المطلوبة مطبقة

```bash
# تحقق أن كل phase موجودة في V2SessionPhase enum
cat lib/core/memorization/v2/session_phase.dart

# تحقق أن الـ cubit يستخدم الـ phases
grep -n "V2SessionPhase\." \
  lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart \
  | head -20
```

**ما يجب التحقق منه:**
- هل الـ 8 phases كلها موجودة في enum؟
- هل الـ cubit يمر بها بالترتيب الصحيح؟
- هل يمكن الانتقال من `reciting` مباشرة لـ `blockReviewPending` (بدون تخطي `remediation` إذا كان هناك فشل)؟

---

### PROD-02 + PROD-03: لا نص آية في Recitation و Block Review

هذه من أهم القواعد في المنتج.

```bash
# في recitation page:
grep -n "ayahText\|qcf_quran\|QuranText\|RawAyah\|AyahDisplay\|text.*ayah\|ayah.*text" \
  lib/features/memorization_plus/presentation/pages/v2_recitation_page.dart 2>/dev/null || \
  find lib/ -name "*recit*" -o -name "*v2_rec*" | xargs grep -l "ayahText\|QuranText" 2>/dev/null

# في block review page:
grep -n "ayahText\|qcf_quran\|QuranText\|RawAyah\|AyahDisplay" \
  lib/features/memorization_plus/presentation/pages/v2_block_review_page.dart 2>/dev/null || \
  find lib/ -name "*block_review*" | xargs grep -l "ayahText\|QuranText" 2>/dev/null
```

**شرط PASS:** لا يوجد أي widget يعرض نص الآية في هاتين الشاشتين.
**شرط FAIL:** وجود أي `ayahText`, `QuranText`, `qcf_quran`, أو `RawAyah` widget في هذه الصفحات.

---

### PROD-04 + PROD-05 + PROD-06: Hint System

```bash
# تحقق من وجود 3 مستويات فقط
grep -rn "enum V2HintLevel\|HintLevel\|hintLevel" lib/core/memorization/v2/ --include="*.dart"

# تحقق أن hints تظهر فقط في memorizing page
grep -rn "HintButton\|useHint\|V2HintLevel" \
  lib/features/memorization_plus/presentation/pages/ --include="*.dart" \
  | grep -v ".g.dart"

# تحقق أن hints غير موجودة في recitation page
grep -n "useHint\|HintButton\|V2HintLevel" \
  lib/features/memorization_plus/presentation/pages/v2_recitation_page.dart 2>/dev/null
grep -n "useHint\|HintButton\|V2HintLevel" \
  lib/features/memorization_plus/presentation/pages/v2_block_review_page.dart 2>/dev/null
```

**شرط PASS للـ hints:**
- V2HintLevel enum: 3 قيم فقط (none/firstWord/fullText أو ما يعادلها)
- Hint UI موجود فقط في memorizing page
- لا Hint UI في recitation أو block_review pages

---

### PROD-07: الآية تُعتبر محفوظة بعد Recitation Pass فقط

```bash
# تحقق: أين تُكتب AyahReviewRecord بـ v2Session mode؟
grep -rn "onAyahPassed\|saveReviewRecord\|v2Session\|createdByMode" \
  lib/core/memorization/v2/ --include="*.dart" | grep -v ".g.dart"

# تحقق: هل يتم الكتابة في Learning phase؟ (يجب أن لا يكون)
grep -n "learning\|Learning" \
  lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart \
  | grep -i "record\|save\|write\|isar\|onAyah" | head -10
```

**شرط PASS:** `onAyahPassed()` / `saveReviewRecord()` يُستدعى فقط بعد Recitation Pass — ليس في Learning أو Memorizing.

---

### PROD-08 + PROD-09: Block Review Logic

```bash
# تحقق من وجود Block Review logic في engine
grep -n "evaluateBlockReview\|blockReview\|BlockReview\|blockSize\|blockAyahs" \
  lib/core/memorization/v2/session_engine.dart 2>/dev/null | head -20

# تحقق من Targeted Remediation (إعادة الضعيفة فقط)
grep -n "weakAyah\|failureTracker\|weak_ayah\|failedAyahs\|targetedRemediation" \
  lib/core/memorization/v2/ -r --include="*.dart" | grep -v ".g.dart"
```

**شرط PASS:**
- Block Review يُطلَق بعد N آيات
- عند الفشل: تُعاد الآيات الضعيفة فقط، ليس المقطع كله

---

### PROD-10: Kids = نفس الـ engine

```bash
# تحقق: هل Kids Mode يستخدم نفس V2SessionEngine؟
grep -n "V2SessionEngine\|sessionEngine" \
  lib/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart

# أو هل يوجد KidsMemorizationSessionCubit؟
find lib/ -name "*kids*session*" -o -name "*kids*memorization*" | grep -v ".g.dart"
```

**شرط PASS:** Kids إما يستخدم نفس `MemorizationSessionCubit` مع kids-specific adapters، أو يوجد `KidsMemorizationSessionCubit` يستخدم نفس `V2SessionEngine`.

---

### ARCH-05: Feature Flag Default = false

```bash
cat lib/core/memorization/v2/v2_feature_flag.dart
```

**شرط PASS:** `isAdultEnabled()` و `isKidsEnabled()` كلاهما يُرجعان `false` كـ default عند غياب SharedPrefs key.

---

### ARCH-06: Backward Compatibility — Legacy Flow يعمل عند Flag OFF

```bash
# تحقق: هل يوجد conditional navigation بناءً على الـ flag؟
grep -n "V2FeatureFlag\|isAdultEnabled\|enable_memorization_v2" \
  lib/features/memorization_plus/presentation/pages/daily_plan_page.dart

# تحقق: هل القديم (DailyPlanCubit / QuizCubit) لا يزال مسجلاً في GetIt؟
grep -n "DailyPlanCubit\|QuizCubit" lib/core/di/injection.dart

# تحقق: هل routes القديمة لا تزال موجودة؟
grep -n "daily-plan\|/quiz\|memorization-plus/quiz" lib/core/router/app_router.dart
```

**شرط PASS:** عند Flag = false، المستخدم يذهب للـ Quiz/DailyPlan القديم — وليس إلى V2.

---

## PHASE 3 — EXECUTION PATH VERIFICATION

تتبع flow الجلسة الكاملة من بداية لنهاية.

### Trace: Adult V2 Session من الـ Home حتى Completed

```bash
# خطوة 1: من أين يبدأ الـ navigation لـ V2?
grep -n "memorization-v2\|memorizationV2Session\|context.go.*v2\|context.push.*v2" \
  lib/features/memorization_plus/presentation/pages/daily_plan_page.dart \
  lib/core/memorization/smart_coach_engine.dart \
  lib/features/home/presentation/ -r

# خطوة 2: ما الـ arguments المرسلة لـ V2 session?
grep -n "extra\|surahId\|startAyah\|blockSize" lib/core/router/app_router.dart | grep "v2"

# خطوة 3: كيف يبدأ الـ Cubit الجلسة؟
grep -n "startSession\|initialize\|Future.*start" \
  lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart | head -10

# خطوة 4: كيف تنتهي الجلسة وتُكتب البيانات؟
grep -n "completed\|Completed\|onBlockCompleted\|onAyahPassed\|awards\|gamification" \
  lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart | head -20
```

**اكتب الـ execution path الكامل الذي وجدته:**

```
Navigation:
  [Source] → /memorization-v2/session?surahId=X&startAyah=Y&blockSize=Z
  → GoRouter → V2LearningPage

Cubit initialization:
  MemorizationSessionCubit.[method]()
  → V2SessionEngine.[method]()

Phase transitions:
  Learning → [user action] → Memorizing
  Memorizing → [user action] → Reciting
  Reciting → [Pass/Fail] → [next state]
  Block Review → [Pass/Fail] → Completed

Data writes on completion:
  → V2SessionReviewAdapter.onAyahPassed() → IsarAyahReviewRecord (mode=v2Session)
  → V2SessionGamificationAdapter.onBlockCompleted() → StreakService + XpService + AchievementService

Status: COMPLETE / BROKEN at [step] / PARTIAL
```

---

## PHASE 4 — SMART COACH INTEGRATION VERIFICATION

### تحقق: هل Smart Coach يقرأ V2 records؟

```bash
# الخطوة 1: اقرأ SmartCoachEngine كاملاً
cat lib/core/memorization/smart_coach_engine.dart

# الخطوة 2: تحقق من ReviewRecordFilters
cat lib/core/memorization/review_record_filters.dart

# الخطوة 3: تحقق أن V2 records تصل للـ snapshot
grep -n "getAllReviewRecords\|getReviewRecords\|isAdultCompatible" \
  lib/core/memorization/memorization_progress_reader.dart 2>/dev/null || \
  find lib/core/memorization/ -name "*.dart" | xargs grep -l "getAllReviewRecords" 2>/dev/null
```

**شرط PASS للـ Smart Coach integration:**
- `ReviewRecordFilters.isAdultCompatible()` يشمل `v2Session` mode
- `MemorizationProgressReader` يجلب records بدون تصفية الـ v2Session out
- Smart Coach Priority 1 (Weak ayah) يمكن أن يأتي من V2 records

---

## PHASE 5 — ACCEPTANCE CRITERIA CHECK

هذه الـ 12 criteria المطلوبة في الـ V2_MASTER_PROMPT.
تحقق من كل واحدة:

```bash
# AC-01: flutter analyze — zero errors
flutter analyze lib/ 2>&1 | tail -5

# AC-02: Feature flag OFF → legacy flow
# (تحقق conceptually من Phase 2 findings)

# AC-03: Feature flag ON → V2 flow كامل
# (تحقق من Phase 3 execution path)

# AC-04: AyahReviewRecord بـ mode=v2Session
grep -rn "v2Session\|ReviewRecordCreatedByMode.v2" lib/core/memorization/v2/ --include="*.dart"

# AC-05: Smart Coach يقرأ V2 records
# (من Phase 4 findings)

# AC-06: AchievementService يحتسب V2 records
grep -n "v2Session\|createdByMode\|isAdultCompatible\|getAllRecords\|allRecords" \
  lib/core/services/achievement_service.dart | head -10

# AC-07: Kids flag منفصل
grep -n "isKidsEnabled\|_keyKids\|enable.*kids" lib/core/memorization/v2/v2_feature_flag.dart

# AC-08: Block Review skip لأطفال < 8
grep -rn "childAge.*8\|8.*childAge\|blockReviewRequired" lib/ --include="*.dart" | grep -v ".g.dart"

# AC-09: Weak Ayah signal يصل Smart Coach بعد 3 فشل
grep -rn "weakAyah\|failureCount.*3\|3.*failure\|onAyahWeak\|weak.*signal" \
  lib/core/memorization/v2/ --include="*.dart"

# AC-10: لا نص في Recitation + Block Review
# (من Phase 2: PROD-02 + PROD-03 findings)

# AC-11: Hints فقط في Memorizing
# (من Phase 2: PROD-05 findings)

# AC-12: No regression في existing tests
flutter test --no-pub 2>&1 | tail -10
```

---

## PHASE 6 — STATE MANAGEMENT AUDIT *(جديد)*

تحقق من صحة Cubit Lifecycle وإدارة الـ resources.

```bash
# تحقق من dispose في MemorizationSessionCubit
grep -n "close\|dispose\|StreamSubscription\|cancel()" \
  lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart

# تحقق من SpeechToText disposal
grep -rn "SpeechToText\|speechToText\|_speech\|speech\.stop\|speech\.cancel" \
  lib/features/memorization_plus/ --include="*.dart" | grep -v ".g.dart" | head -20

# تحقق من Audio player disposal
grep -rn "AudioPlayer\|audioPlayer\|_player\|player\.dispose\|player\.stop" \
  lib/features/memorization_plus/ --include="*.dart" | grep -v ".g.dart" | head -20

# تحقق من تكرار الـ listeners
grep -n "BlocListener\|BlocConsumer\|listen(" \
  lib/features/memorization_plus/presentation/ -r --include="*.dart" | grep -v ".g.dart"

# تحقق من Stream subscriptions غير مُلغاة
grep -rn "StreamSubscription\|\.listen(" \
  lib/features/memorization_plus/presentation/cubits/ --include="*.dart" | grep -v "cancel\|dispose"
```

**ما يجب التحقق منه:**
- هل `MemorizationSessionCubit.close()` يُلغي كل الـ subscriptions؟
- هل `SpeechToText` يُوقَف عند الخروج من Reciting phase؟
- هل `AudioPlayer` يُتخلص منه عند إغلاق الـ Cubit؟
- هل يوجد تكرار في الـ listeners يسبب double-execution؟

**Output:**
```
[SM-01] Cubit dispose completeness
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: file:line

[SM-02] SpeechToText lifecycle
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: file:line

[SM-03] Audio player cleanup
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: file:line

[SM-04] No duplicate listeners
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: file:line

[SM-05] Stream subscriptions cancelled on dispose
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: file:line
```

---

## PHASE 7 — CLEAN ARCHITECTURE COMPLIANCE *(جديد)*

تحقق من عدم اختراق الطبقات.

```bash
# تحقق: هل Presentation تصل للـ Repository مباشرة؟
grep -rn "MemorizationPlusRepositoryImpl\|MemorizationRepository" \
  lib/features/memorization_plus/presentation/ --include="*.dart" | grep -v ".g.dart"

# تحقق: هل Cubits تعتمد على Usecases/Adapters فقط؟
grep -n "import.*repository\|import.*data_source" \
  lib/features/memorization_plus/presentation/cubits/ -r --include="*.dart"

# تحقق: هل Domain layer خالية من Flutter imports؟
grep -rn "import 'package:flutter" \
  lib/features/memorization_plus/domain/ --include="*.dart" | grep -v ".g.dart"

# تحقق: هل Domain layer خالية من BuildContext؟
grep -rn "BuildContext\|context\.read\|context\.watch" \
  lib/features/memorization_plus/domain/ --include="*.dart" | grep -v ".g.dart"

# تحقق: هل V2SessionEngine خالي من UI dependencies؟
grep -n "import 'package:flutter\|BuildContext\|Widget\|State" \
  lib/core/memorization/v2/session_engine.dart 2>/dev/null

# تحقق: هل Core/Memorization خالي من Feature-specific imports؟
grep -rn "import.*features/memorization_plus/presentation" \
  lib/core/memorization/ --include="*.dart" | grep -v ".g.dart"
```

**شرط PASS لكل بند:**

```
[CA-01] Presentation → Repository: No direct access
  Status: ✅ PASS / ❌ FAIL
  Evidence: file:line

[CA-02] Cubits depend on Usecases/Adapters only
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: file:line

[CA-03] Domain layer: no Flutter imports
  Status: ✅ PASS / ❌ FAIL
  Evidence: file:line

[CA-04] Domain layer: no BuildContext
  Status: ✅ PASS / ❌ FAIL
  Evidence: file:line

[CA-05] V2SessionEngine: no UI dependencies
  Status: ✅ PASS / ❌ FAIL
  Evidence: file:line

[CA-06] Core layer: no Presentation imports
  Status: ✅ PASS / ❌ FAIL
  Evidence: file:line
```

---

## PHASE 8 — GUEST MODE AUDIT *(جديد)*

تحقق من سلوك المستخدم الضيف (Guest User).

```bash
# تحقق: هل Quran Reading متاح للـ Guest؟
grep -rn "isGuest\|GuestUser\|guestMode\|isLoggedIn\|AuthStatus" \
  lib/features/quran/ --include="*.dart" | grep -v ".g.dart" | head -20

# تحقق: هل Memorization Exploration متاح للـ Guest؟
grep -n "isGuest\|authRequired\|requireAuth\|GuestGuard" \
  lib/core/router/app_router.dart | head -20

# تحقق: هل Protected routes محمية فعلاً؟
grep -n "redirect\|authGuard\|requiresAuth\|isAuthenticated" \
  lib/core/router/app_router.dart | head -20

# تحقق: هل V2 session تنكسر مع Guest؟
grep -rn "userId\|currentUser\|getUser()\|AuthRepository" \
  lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart | head -10

# تحقق: هل يوجد null-safety للـ user في V2 engine؟
grep -n "user!\|userId!\|\.userId\b" \
  lib/core/memorization/v2/ -r --include="*.dart" | grep -v ".g.dart"
```

**ما يجب التحقق منه:**
- Guest يستطيع تصفح القرآن؟
- Guest يستطيع استكشاف الحفظ دون حادثة Crash؟
- Routes المحمية ترفض Guest وتوجهه للـ Login؟
- V2 session لا تنكسر عند `userId == null`؟

**Output:**
```
[GM-01] Guest can access Quran reading
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: file:line

[GM-02] Guest can explore memorization
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: file:line

[GM-03] Protected routes guard is enforced
  Status: ✅ PASS / ❌ FAIL
  Evidence: file:line

[GM-04] V2 flow does not crash for guest (null user)
  Status: ✅ PASS / ❌ FAIL / NOT VERIFIED
  Evidence: file:line
```

---

## PHASE 9 — CERTIFICATE POLICY AUDIT *(جديد)*

تحقق من أن جميع المسارات تُسهم في الشهادات.

```bash
# تحقق: هل Hifz records تُحسب في الشهادات؟
grep -n "hifz\|HifzRecord\|certificate\|Certificate" \
  lib/core/services/certificate_service.dart 2>/dev/null || \
  find lib/ -name "*certificate*" | grep -v ".g.dart"

# تحقق: هل Memorization Plus records تُحسب؟
grep -rn "MemorizationPlus\|memorization_plus\|createdByMode" \
  lib/core/services/certificate_service.dart 2>/dev/null

# تحقق: هل Kids Mode يُسهم في الشهادات؟
grep -rn "kidsMode\|kids_mode\|KidsMode\|childCertificate" \
  lib/core/services/certificate_service.dart 2>/dev/null

# تحقق: هل V2 records تُحسب؟
grep -n "v2Session\|V2Session\|v2Record" \
  lib/core/services/certificate_service.dart 2>/dev/null

# تحقق: هل Legacy migrated records تُحسب؟
grep -n "migrated\|legacy\|migration\|legacyRecord" \
  lib/core/services/certificate_service.dart 2>/dev/null

# fallback: ابحث في كل ملفات الـ certificate
find lib/ -name "*certificate*" -o -name "*Certificate*" | grep -v ".g.dart" | \
  xargs grep -n "isAdultCompatible\|v2Session\|kidsMode\|hifz" 2>/dev/null
```

**Output:**
```
[CP-01] Hifz records → Certificate
  Status: ✅ PASS / ❌ FAIL / NOT VERIFIED
  Evidence: file:line

[CP-02] Memorization Plus records → Certificate
  Status: ✅ PASS / ❌ FAIL / NOT VERIFIED
  Evidence: file:line

[CP-03] Kids Mode records → Certificate
  Status: ✅ PASS / ❌ FAIL / NOT VERIFIED
  Evidence: file:line

[CP-04] V2 records → Certificate
  Status: ✅ PASS / ❌ FAIL / NOT VERIFIED
  Evidence: file:line

[CP-05] Legacy migrated records → Certificate
  Status: ✅ PASS / ❌ FAIL / NOT VERIFIED
  Evidence: file:line
```

---

## PHASE 10 — SMART COACH HOME INTEGRATION *(جديد)*

تحقق من أن Home يعرض توصيات Smart Coach بشكل صحيح.

```bash
# تحقق: هل Home يستهلك Smart Coach output؟
grep -rn "SmartCoachEngine\|SmartCoachRecommendation\|smartCoach" \
  lib/features/home/ --include="*.dart" | grep -v ".g.dart" | head -20

# تحقق: هل Weak Ayahs تظهر في الـ Home؟
grep -rn "weakAyah\|WeakAyah\|priority.*1\|Priority1" \
  lib/features/home/ --include="*.dart" | grep -v ".g.dart"

# تحقق: هل Due Reviews تظهر في الـ Home؟
grep -rn "dueReview\|DueReview\|due.*review\|reviewDue" \
  lib/features/home/ --include="*.dart" | grep -v ".g.dart"

# تحقق: هل Continue Session recommendation موجودة؟
grep -rn "continueSession\|ContinueSession\|resumeSession\|lastSession" \
  lib/features/home/ --include="*.dart" | grep -v ".g.dart"

# تحقق: هل يوجد deduplication لمنع التكرار؟
grep -rn "deduplicate\|distinct\|toSet\|unique\|removeDuplicates" \
  lib/core/memorization/smart_coach_engine.dart 2>/dev/null
```

**ما يجب التحقق منه:**
- Home يستدعي Smart Coach وعرض النتائج؟
- الآيات الضعيفة (Priority 1) تظهر للمستخدم؟
- المراجعات المستحقة تظهر للمستخدم؟
- "Continue Session" تظهر عند وجود جلسة غير مكتملة؟
- لا يتكرر نفس الـ recommendation مرتين؟

**Output:**
```
[SCH-01] Home consumes Smart Coach output
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: file:line

[SCH-02] Weak ayahs visible in Home
  Status: ✅ PASS / ❌ FAIL / NOT VERIFIED
  Evidence: file:line

[SCH-03] Due reviews visible in Home
  Status: ✅ PASS / ❌ FAIL / NOT VERIFIED
  Evidence: file:line

[SCH-04] Continue session recommendation exists
  Status: ✅ PASS / ❌ FAIL / NOT VERIFIED
  Evidence: file:line

[SCH-05] No duplicated recommendations
  Status: ✅ PASS / ❌ FAIL / NOT VERIFIED
  Evidence: file:line
```

---

## OUTPUT المطلوب

اكتب ملف `TALIA_V2_COMPLIANCE_REPORT.md` بهذا الهيكل:

```markdown
# TALIA V2 COMPLIANCE REPORT
Generated: [date]
Auditor: Code-First Read-Only Audit

---

## SUMMARY

| Category | Total | PASS | FAIL | PARTIAL | NOT VERIFIED |
|----------|-------|------|------|---------|--------------|
| Building Blocks (V2-01 to V2-20) | 20 | | | | |
| Product Rules (PROD-01 to PROD-11) | 11 | | | | |
| Architecture Rules (ARCH-01 to ARCH-08) | 8 | | | | |
| Acceptance Criteria (AC-01 to AC-12) | 12 | | | | |
| State Management (SM-01 to SM-05) | 5 | | | | |
| Clean Architecture (CA-01 to CA-06) | 6 | | | | |
| Guest Mode (GM-01 to GM-04) | 4 | | | | |
| Certificate Policy (CP-01 to CP-05) | 5 | | | | |
| Smart Coach Home (SCH-01 to SCH-05) | 5 | | | | |
| **TOTAL** | **76** | | | | |

**Overall Compliance: [N]% ([Pass count]/76)**

---

## PHASE 1 — BUILDING BLOCKS

[V2-01] ReviewRecordCreatedByMode includes v2Session
  Status: ✅ PASS / ❌ MISSING / ⚠️ PARTIAL / 🔄 DISCREPANCY
  Evidence: [file:line]
  Note: [أي ملاحظة]

[V2-02] ...
...continue for all 20 items...

---

## PHASE 2 — PRODUCT RULES

[PROD-01] State Machine flow correct
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: [file:line]

[PROD-02] No ayah text in Recitation page
  Status: ✅ PASS / ❌ FAIL
  Evidence: [file:line — or "No text widget found"]

...continue for all 11 rules...

---

## PHASE 3 — EXECUTION PATH

Adult V2 Session execution chain:
  [write the full chain found in code]
  Status: COMPLETE / BROKEN at [step] / PARTIAL

---

## PHASE 4 — SMART COACH INTEGRATION

V2 records visible to Smart Coach: YES / NO / PARTIAL
Evidence: [file:line]
Gap: [what's missing if any]

---

## PHASE 5 — ACCEPTANCE CRITERIA

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-01 | flutter analyze clean | | |
| AC-02 | Flag OFF → legacy works | | |
| AC-03 | Flag ON → V2 full flow | | |
| AC-04 | AyahReviewRecord mode=v2Session | | |
| AC-05 | Smart Coach reads V2 records | | |
| AC-06 | AchievementService counts V2 | | |
| AC-07 | Kids flag separate | | |
| AC-08 | Block Review skip <8 years | | |
| AC-09 | Weak Ayah signal after 3 fails | | |
| AC-10 | No text in Recitation + BlockReview | | |
| AC-11 | Hints only in Memorizing | | |
| AC-12 | No regression in existing tests | | |

---

## PHASE 6 — STATE MANAGEMENT

[SM-01] Cubit dispose completeness
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: [file:line]

...continue for SM-02 to SM-05...

---

## PHASE 7 — CLEAN ARCHITECTURE

[CA-01] Presentation → Repository: No direct access
  Status: ✅ PASS / ❌ FAIL
  Evidence: [file:line]

...continue for CA-02 to CA-06...

---

## PHASE 8 — GUEST MODE

[GM-01] Guest can access Quran reading
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: [file:line]

...continue for GM-02 to GM-04...

---

## PHASE 9 — CERTIFICATE POLICY

[CP-01] Hifz records → Certificate
  Status: ✅ PASS / ❌ FAIL / NOT VERIFIED
  Evidence: [file:line]

...continue for CP-02 to CP-05...

---

## PHASE 10 — SMART COACH HOME INTEGRATION

[SCH-01] Home consumes Smart Coach output
  Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
  Evidence: [file:line]

...continue for SCH-02 to SCH-05...

---

## CRITICAL FINDINGS

### 🔴 Blockers (specs violated — prevents V2 release):
1. [finding] — [file:line]

### 🟠 High Priority (specs not implemented):
1. [finding] — [file:line]

### 🟡 Medium Priority (partial implementation):
1. [finding] — [file:line]

### ✅ Confirmed Working:
1. [finding] — [file:line]

---

## DISCREPANCIES (موجود لكن مختلف عن الـ spec)
[List anything where implementation differs from what specs say]

---

## RECOMMENDATION

Overall: COMPLIANT / PARTIALLY COMPLIANT / NON-COMPLIANT

Ready for release: YES / NO / CONDITIONALLY

Blocking issues count: [N]
Estimated fix effort: [S/M/L/XL]

Next required action:
1. [...]
2. [...]
```

---

## STOP RULES

توقف وسجّل كـ "NEEDS HUMAN DECISION" إذا:
- وجدت implementation مختلفة تماماً عن الـ spec لكن تبدو deliberate
- وجدت ملفاً محذوفاً مقصوداً وفيه refactoring حصل
- `MemorizationPlusRepositoryImpl` يحتاج قراءة عميقة (51KB)
  → اقرأ فقط الـ methods المتعلقة بالـ V2، ولا تقرأه كاملاً

لا توقف إذا كانت المشكلة واضحة — سجّلها وكمّل.
