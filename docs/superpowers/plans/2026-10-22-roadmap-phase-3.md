# خارطة التميّز، المرحلة 3: خطة التنفيذ

> **للوكلاء المنفذين:** مهارة فرعية مطلوبة: superpowers:subagent-driven-development (مُوصى بها) أو superpowers:executing-plans. الخطوات بصيغة `- [ ]`.

**الهدف:** أربعة بنود من المرحلة 3 في خارطة التميّز، كلها خلف أعلام مطفأة:

| البند | الاسم | العلم في `ExperienceFeature`، مطفأ افتراضيًا |
|---|---|---|
| 7 | ودجت الشاشة الرئيسية (Android) | `homeWidget` |
| 8 | المراجعة الصوتية دون شاشة «سمّع لي» | `handsFreeReview` |
| 17 | عرض صفحتين على الأجهزة اللوحية | `tabletSpread` |
| 10 | الختمة العائلية الجماعية | `groupKhatmah` |

**البنية:** كل بند وحدة منفصلة بملفاتها، ويلمس الكود المشترك في نقاط ربط صغيرة محددة (الموجّه، `injection.dart`، `AccountDataReset`). المنطق في دوال Dart خالصة مختبرة أولاً، ثم التكامل، ثم الواجهة.

**التقنيات:** Flutter/Dart، `flutter_bloc`، `get_it`، `go_router`، `audio_service` و`just_audio` (موجودتان)، `speech_to_text` (موجودة)، `qcf_quran_plus` 0.0.8، Supabase (RLS وCAS)، `home_widget` (**جديدة، تحتاج موافقة R1**)، Kotlin مع JUnit 4.13.2.

**المواصفة:** `docs/superpowers/specs/2026-10-13-talia-differentiation-roadmap.md`: البنود 7 و8 و10 في الجزء الأول، والبند 17 في الجزء الثاني، والترتيب في §هـ «المرحلة 3». ومعها مواصفة مراجعة السماع `docs/superpowers/specs/2026-09-28-listening-review-design.md` للبند 8.

**الفرع:** `feat/roadmap-phase-3` من رأس `feat/kids-quran-journey` (PR #10 لم يُدمج بعد). يُعاد توجيهه إلى `main` بعد دمج PR #10.

## 0. قبل البدء: بوابات المرحلة 2 المفتوحة

هذه لا تمنع كتابة كود المرحلة 3، لكنها تمنع **تفعيل أي علم** من المرحلتين 2 و3:

- [ ] E0: مراجعة بشرية لأزواج المتشابهات الثلاثين، والمعايرة، ثم اعتماد الفهرس بالحقول `reviewedBy` و`reviewedAt` و`reviewSetId`.
- [ ] G: تشغيل هجرات المرحلة 2 على Supabase حقيقي (أو PGlite) واختبارات الأدوار، ثم النشر **بموافقة المالك لحظة التنفيذ**. (نُشرت في 2026-10-24 بطلب المالك، وتحققت صلاحياتها في الكتالوج. تبقى اختبارات الأدوار الحية لولي الأمر والطفل.)
- [ ] تجربة جهاز Android حقيقي وفق `docs/release/flag-device-test-matrix.md`، وتشمل تصدير النسخة الاحتياطية واستعادتها. تعذّرت على الإيميوليتر لأن نظامه يتعطّل عند فتح منتقي الملفات.

## 1. قرارات تحتاج موافقتك

**وافق المالك على R1–R6 في 2026-10-23.** وحسم R3 من المصحف المطبوع: الفاتحة (صفحة 1) في اليمين، أي الفردية يميناً والزوجية يساراً. هذا يخالف نص المواصفة §17، والمعتمد هو قرار المالك: `kOddPageOnRight = true`.

| # | القرار | البند | الاقتراح |
|---|---|---|---|
| R1 | إضافة تبعية `home_widget` | 7 | موافق. تغيّر `pubspec.lock`، فتُحدَّث بوابة `verify_v1_release.ps1` (تعمل `pub get --enforce-lockfile`) |
| R2 | نغمتا «صح» و«راجع» ملفان صوتيان قصيران (أقل من ثانية) مولَّدان برمجياً، ولا كلام فيهما | 8 | موافق. ليس فيهما نص ولا صوت قارئ. يُنشئهما `tool/generate_feedback_tones.dart` في `assets/audio/tones/` |
| R3 | **ترتيب الصفحتين في العرض المزدوج.** المواصفة تقول: الزوجية يميناً والفردية يساراً. أما في المصحف الورقي فأعرف أن الصفحة 1 (الفاتحة) في اليمين تقابلها 2 (أول البقرة) في اليسار، أي الفردية يميناً | 17 | **يُتحقق منه بمصحف المدينة المطبوع قبل H1**، ولا يُنفَّذ من الذاكرة. الخطة مكتوبة لتقبل أيّاً منهما بثابت واحد |
| R4 | جداول ودوال الختمة الجماعية، ونشرها على `Talia_Quran` | 10 | الموافقة على التصميم في K0. **النشر يُعرض عليك لحظة التنفيذ** (K5) |
| R5 | حدود الختمة الجماعية | 10 | رمز دعوة من 6 أحرف من أبجدية بلا أحرف ملتبسة (`ABCDEFGHJKLMNPQRSTUVWXYZ23456789`)، و30 عضواً كحد أقصى، و30 جزءاً، واسم عرض من 2 إلى 24 حرفاً، والبالغون فقط |
| R6 | الودجت للمسار البالغ فقط في v1 | 7 | موافق، تطبيقاً لقرار الخارطة «البنود للبالغ فقط في نسختها الأولى». ملف الطفل يعطي لقطة فارغة |

## Global Constraints

- لا يُعدَّل أي ملف قائم في `assets/data/`، ولا يُكتب أو يُولَّد نص ديني.
- **لا نص قرآني في الودجت** (§7.1). أسماء السور فقط من `surahs.json` عبر `SurahNames`.
- النص القرآني في التطبيق يُعرض من `Ayah.text` حرفياً. ودعاء الختم الجماعي **من المحتوى المعتمد فقط** عبر `KhatmDuaDatasource`.
- المراجعة الصوتية **لا تكتب في SRS ولا تخزّن أي صوت** (§8.3، وقرار مراجعة السماع).
- الختمة الجماعية **منفصلة تماماً** عن الختمة الشخصية ولا تُحسب فيها (§10.2). والأطفال خارجها.
- كل علم مطفأ افتراضياً، وإطفاؤه يعيد الواجهة السابقة ولا يحذف بيانات.
- المفاتيح والسجلات الخاصة بالحساب محصورة بالمالك، ويُلتقط المالك مرة واحدة لكل كتابة. وكل بادئة جديدة تُضاف إلى `AccountDataReset`.
- قبل `flutter test` في نفس الأمر: `$env:TEMP='D:\Flutter\talia_quran\.superpowers\tmp'; $env:TMP=$env:TEMP;`. ولا يعمل أمرا `flutter test` معاً.
- `dart format` للملفات الجديدة فقط. و`flutter analyze` على المشروع كله يطبع "No issues found!".
- ARB في `app_ar.arb` و`app_en.arb` معاً، والأعداد بـ ICU plural، ثم `flutter gen-l10n`.
- لا أيقونات Material (تُستخدم `TaliaIcons`)، ولا أرقام مباشرة في `BorderRadius.circular`.
- كل اختبار جديد يُرى فاشلاً مرة (RED).
- اختبارات Kotlin: `cd android; ./gradlew :app:testDebugUnitTest`.
- لا نشر على Supabase دون موافقة صريحة لحظة التنفيذ.

## Review Focus

1. **تبديل الحساب أو تسجيل الخروج والودجت ظاهر:** يجب أن يفرغ فوراً، فلا تبقى صلاة الحساب السابق ولا مراجعاته ولا ورده. الاختبار في J2.
2. **انقطاع الصوت أثناء «سمّع لي»:** مكالمة، أو فصل سماعة البلوتوث، أو فقد تركيز الصوت. يجب أن تتوقف الجولة ولا تُحسب الآية التي لم تُقيَّم، ولا يُسجَّل شيء. الاختبار في I1 وI2.
3. **عضوان يحجزان الجزء نفسه في اللحظة نفسها:** واحد فقط ينجح، والآخر يرى رسالة «حجزه غيرك» مع تحديث القائمة دون إعادة محاولة صامتة. الاختبار في K1 (SQL) وK2.
4. **تدوير الجهاز أو فتح رابط إلى صفحة فردية أو زوجية والعرض المزدوج مفعّل:** تبقى الصفحة الحالية نفسها ظاهرة، ويُحسب التقدّم مرة واحدة. الاختبار في H3.
5. **إكمال جزء دون إنترنت ثم مغادرة المجموعة أو إزالة العضو:** الإكمال المعلّق يُرفض بهدوء ويُحذف من الطابور، دون حلقة إعادة ولا تعطّل. الاختبار في K2.

---

## الترتيب

| الدفعة | البند | المخاطرة | لماذا هذا الترتيب |
|---|---|---|---|
| **H** | 17 | منخفضة–متوسطة | فيه قرار «متابعة أو توقف» بعد نموذج أولي، فيبدأ مبكراً. لا يمس البيانات |
| **I** | 8 | متوسطة | يمس `audio_service` المشترك مع القارئ |
| **J** | 7 | متوسطة | تبعية جديدة (R1)، وكود أصلي، وعزل الحسابات |
| **K** | 10 | **عالية** | Supabase وRLS وCAS ومزامنة. مراجعة Opus **إلزامية** |

يمكن تنفيذ H وI بالتوازي (لا ملف مشترك بينهما). وJ بعد I لأن كليهما يعدّل `injection.dart`. وK آخراً.

---

# الدفعة H: عرض صفحتين (البند 17)

### Task H1: سياسة العرض المزدوج

**Files:**
- Create: `lib/features/quran/domain/services/quran_spread_policy.dart`
- Test: `test/features/quran/domain/quran_spread_policy_test.dart`

**Interfaces:**
- Produces:
  - `const kSpreadMinWidthDp = 840.0;`
  - `bool shouldShowSpread({required double widthDp, required Orientation orientation, required bool enabled})`
  - `QuranSpread spreadForPage(int canonicalPage)`
  - `int spreadIndexForPage(int canonicalPage)` و`QuranSpread spreadAt(int index)` و`int spreadCount()`
  - `final class QuranSpread { final int? rightPage; final int? leftPage; }`
  - الثابت `const kOddPageOnRight = true;` (قرار R3). ولا يُغيَّر أي شيء آخر عند تبديله.

- [x] **Step 1: الاختبارات الفاشلة**
  - `shouldShowSpread`:
    - `(839, landscape, true)` ← false.
    - `(840, landscape, true)` ← true.
    - `(1200, portrait, true)` ← false.
    - `(1200, landscape, false)` ← false.
  - مع `kOddPageOnRight = true`:
    - `spreadForPage(1)` و`spreadForPage(2)` ← `(right: 1, left: 2)`.
    - `spreadForPage(603)` ← `(right: 603, left: 604)`.
  - كل صفحة من 1 إلى 604 تظهر في spread واحد فقط.
  - `spreadAt(spreadIndexForPage(p))` يحتوي `p` لكل `p`.
  - نسخة ثانية من الاختبار بالقيمة الأخرى للثابت (مجموعة `group` بمعامل)، حتى يبقى قرار R3 آمناً.
- [x] **Step 2:** `flutter test test/features/quran/domain/quran_spread_policy_test.dart`. المتوقع: FAIL، الملف غير موجود.
- [x] **Step 3:** التنفيذ. دوال خالصة، بلا Flutter إلا `Orientation`.
- [x] **Step 4:** الاختبار نفسه. المتوقع: PASS.
- [x] **Step 5:** Commit `feat(quran): two-page spread policy`.

### Task H2: نموذج أولي وقياس الأداء، ثم قرار المتابعة أو التوقف

**Files:**
- Create: `lib/features/quran/presentation/widgets/quran_spread_view.dart`. يحوي `QuranSpreadView(spread, pageBuilder)`، وهو `Row` اتجاهها LTR صريحاً، فيه صفحتان كلٌّ منهما `Expanded`، والصفحة اليمنى بصرياً هي `rightPage`.
- Create: `docs/superpowers/reviews/YYYY-MM-DD-tablet-spread-perf.md`
- Test: `test/features/quran/presentation/widgets/quran_spread_view_test.dart`

- [x] **Step 1: اختبار widget فاشل:**
  - على `Size(1280, 800)` تظهر الصفحتان، و`rightPage` على يمين `leftPage` (تُقارن `tester.getCenter(...).dx`)، حتى تحت `Directionality.rtl`.
  - `leftPage == null` ← صفحة واحدة في نصف الشاشة الأيمن.
- [x] **Step 2:** تشغيله. المتوقع: FAIL.
- [x] **Step 3:** التنفيذ. `pageBuilder` يستقبل رقم الصفحة ويعيد نفس الـwidget الذي يستخدمه `AppQuranPageView` لصفحة واحدة، دون تعديل حزمة qcf.
- [x] **Step 4:** تشغيله. المتوقع: PASS.
- [ ] **Step 5: قياس الأداء على جهاز لوحي أو إيميوليتر بعرض 1280×800 أفقي:** (محاولة 2026-10-24 على الإيميوليتر المتاح: أقصى عرض فيه 960×600، والعرض المفرد نفسه يتجاوز العتبات، فلا تحسم القرار. الأرقام في تقرير القياس.)
  - بناء profile، ثم `flutter run --profile`.
  - تقليب 30 صفحة، وقراءة DevTools.
  - **العتبة:** متوسط زمن الإطار أقل من 16ms، ولا إطار فوق 50ms بعد التحميل الأول، والذاكرة لا تتجاوز ضعف القارئ المفرد.
  - تُسجَّل الأرقام في ملف المراجعة.
- [ ] **Step 6: القرار:**
  - إن تجاوزت العتبة: **توقف**. يُسجَّل السبب، ويبقى العلم بلا ربط، ويُتخطّى H3.
  - إن نجحت: H3.
  - Commit `feat(quran): spread view prototype and perf notes`.

### Task H3: الربط في القارئ (فقط إن نجح H2)

**Files:**
- Modify: `lib/features/quran/presentation/pages/quran_reader_page.dart`. في موضع `AppQuranPageView` (~845) يُختار `PageView` على مستوى الـspread حين يكون `shouldShowSpread(...)` صحيحاً.
- Modify: `lib/features/quran/presentation/widgets/app_quran_page_view.dart` إن احتاج معامل `pageBuilder` عاماً.
- Test: `test/features/quran/presentation/pages/quran_reader_spread_test.dart`

**Interfaces:**
- Consumes: H1 و`QuranSpreadView` من H2.
- العلم: `ExperienceFeature.tabletSpread` من `ExperienceFlags`.

- [ ] **Step 1: الاختبارات الفاشلة:**
  1. العلم مفعّل والعرض 1280×800: فتح القارئ على الصفحة 50 يُظهر spread الصفحة 50، ويبقى `_currentPageNumber == 50`.
  2. تدوير الشاشة إلى عمودي يعيد الصفحة 50 مفردة. **(Review Focus 4)**
  3. الانتقال إلى الـspread التالي يحفظ آخر صفحة مقروءة، وهي الصفحة اليسرى بصرياً حسب R3. وإيصال القراءة يُحسب لكل صفحة مرة واحدة فقط (تُعدّ استدعاءات `confirmRead`).
  4. العلم مطفأ: لا تغيير، والعرض مفرد على أي مقاس.
- [ ] **Step 2:** تشغيلها. المتوقع: FAIL.
- [ ] **Step 3:** التنفيذ. تمييز التلاوة وطبقة قوة الحفظ يطبَّقان على الصفحتين من نفس `readerHighlights(...)`.
- [ ] **Step 4:** تشغيلها، ثم `test/features/quran` كاملاً. المتوقع: PASS.
- [ ] **Step 5:** Commit `feat(quran): two-page spread in the reader behind tabletSpread`.

---

# الدفعة I: «سمّع لي» دون شاشة (البند 8)

**قبل البدء:** تُقرأ `docs/superpowers/specs/2026-09-28-listening-review-design.md`، ويُحترم قرارها: الجولات **لا تكتب في SRS**.

### Task I1: محرك الجولة

**Files:**
- Create: `lib/core/memorization/hands_free/hands_free_round_engine.dart`
- Create: `lib/core/memorization/hands_free/hands_free_round_state.dart`
- Test: `test/core/memorization/hands_free/hands_free_round_engine_test.dart`

**Interfaces:**
- Consumes:
  - `ListeningCorpus`: نفس مصدر الآيات المؤهلة في `lib/core/memorization/listening/`.
  - السجلات المستحقة من `review_due_evaluator.dart`.
- Produces: محرك خالص متزامن، بلا Flutter ولا صوت.
  - `HandsFreeRoundState start({required List<AyahReviewRecord> due, required int maxItems, required DateTime now})`: يأخذ أكثر الآيات تأخراً أولاً، و`maxItems` الافتراضي 10. **لا يعبر حدود السورة.**
  - المراحل: `enum HandsFreePhase { prompt, userTurn, feedback, finished, paused }`.
  - `HandsFreeRoundState onPromptFinished(HandsFreeRoundState s)` ← `userTurn`.
  - `HandsFreeRoundState grade(HandsFreeRoundState s, HandsFreeGrade g)` ← `feedback`. القيم: `enum HandsFreeGrade { correct, review }`.
  - `HandsFreeRoundState next(HandsFreeRoundState s)` ← `prompt` التالي، أو `finished`.
  - `HandsFreeRoundState interrupt(HandsFreeRoundState s)` ← `paused`. **الآية الحالية تبقى بلا تقييم.**
  - `Duration promptClipLength(Duration ayahDuration)`: الأصغر بين 3 ثوانٍ ونصف مدة الآية، ولا يقل عن ثانية.
  - `HandsFreeRoundSummary summarize(...)`: عدد «صح» و«راجع»، وقائمة آيات «راجع» للعرض فقط.

- [x] **Step 1: الاختبارات الفاشلة:**
  - ترتيب الأكثر تأخراً أولاً، والحد 10.
  - لا سجلات مستحقة ← `finished` فوراً، وملخص فارغ.
  - `grade` خارج `userTurn` ← نفس الحالة دون تغيير.
  - `interrupt` أثناء `userTurn` ← `paused`، والملخص لا يحتوي تلك الآية. **(Review Focus 2)**
  - `promptClipLength(Duration(seconds: 2))` ← ثانية واحدة. و`(10s)` ← 3 ثوانٍ. و`(1500ms)` ← ثانية واحدة.
  - المحرك لا يستورد أي ملف من `review_outcome_committer` أو SRS. يُفحص بقراءة مصدر الملف داخل الاختبار، أي اختبار حدود.
- [x] **Step 2:** `flutter test test/core/memorization/hands_free`. المتوقع: FAIL.
- [x] **Step 3:** التنفيذ.
- [x] **Step 4:** نفس الأمر. المتوقع: PASS.
- [x] **Step 5:** Commit `feat(hifz): hands-free review round engine (no SRS writes)`.

### Task I2: التحكم بالصوت وأزرار الوسائط

**Files:**
- Create: `lib/features/memorization_plus/presentation/cubits/hands_free_review_cubit.dart`
- Create: `tool/generate_feedback_tones.dart`، ومنه `assets/audio/tones/correct.wav` و`assets/audio/tones/review.wav` (R2). تُضاف إلى `pubspec.yaml`.
- Modify: `lib/core/services/quran_background_audio_handler.dart`: مندوب وسائط اختياري.
- Modify: `lib/core/di/injection.dart`: تسجيل الكيوبت.
- Test: `test/features/memorization_plus/presentation/cubits/hands_free_review_cubit_test.dart`، و`test/core/services/quran_background_audio_handler_delegate_test.dart`

**Interfaces:**
- Consumes: محرك I1، و`AudioCacheService` لملف الآية، و`ListeningRecitationCapture` (`prepare` و`start` و`stop` و`cancel`)، و`V2RecitationEvaluator` لمقارنة النص الملتقط مع `Ayah.text`.
- Produces:
  - في `QuranBackgroundAudioHandler`:
    - `void setMediaDelegate(HandsFreeMediaDelegate? d)`.
    - حين يكون المندوب موجوداً، يُوجَّه `play` (زر السماعة) إلى `onPrimary()`، أي «صح»، ويُوجَّه `skipToNext` إلى `onSecondary()`، أي «راجع». أما `pause` (إجراء الإشعار أو شاشة القفل) فيُوجَّه إلى `onInterrupted()` فينهي الجولة دون تقييم. **مفاتيح الوسائط الفعلية** (PLAY وPAUSE وPLAY_PAUSE وHEADSETHOOK) تصل كلها من `audio_service` بصفة `click(media)`، ويصل NEXT بصفة `click(next)`. لذلك تُوجَّه إلى `onHardwareButton`، وتُمهَل 0.7 ثانية يلغيها خلالها أي انقطاع (تعديل بعد المراجعة وتجربة الإيميوليتر، 2026-10-24).
    - حين يكون `null`، يبقى سلوك القارئ كما هو حرفياً.
  - `abstract interface class HandsFreeMediaDelegate { void onPrimary(); void onSecondary(); void onInterrupted(); }`
  - `HandsFreeReviewCubit`، وطرقه: `start()` و`stopRound()`. وحالته `HandsFreeReviewState`، وفيها: الحالة من I1، و`micAvailable`، و`firstUseWarningPending`.

- [x] **Step 1: الاختبارات الفاشلة:**
  1. بلا مندوب، `play()` يشغّل القارئ كما قبل، ويُتحقق من ذلك بمشغّل وهمي.
  2. مع المندوب: `play()` يستدعي `onPrimary` ولا يشغّل القارئ.
  3. الكيوبت مع ميكروفون وهمي يعيد نص الآية الصحيح ← نغمة `correct` تعمل، ثم `next`.
  4. ميكروفون غير متاح ← `micAvailable == false`، وتقييم عبر زر السماعة.
  5. فقد تركيز الصوت أو حدث `becomingNoisy` ← `interrupt`، ولا نغمة، ولا تقييم. **(Review Focus 2)**
  6. لا استدعاء لأي `commit*` أو SRS طوال الجولة، يُتحقق منه بـmock صارم للمستودع.
  7. `stopRound()` يزيل المندوب، فيعود القارئ لسلوكه.
- [x] **Step 2:** تشغيلها. المتوقع: FAIL.
- [x] **Step 3:** التنفيذ. تشغيل المقطع يقتصر على أول `promptClipLength` من ملف الآية، ثم إيقاف المشغّل. ولا يُخزَّن الصوت الملتقط (`SpeechToText` يعطي نصاً فقط).
- [x] **Step 4:** تشغيلها، ثم `test/core/services`. المتوقع: PASS.
- [x] **Step 5:** Commit `feat(hifz): hands-free review audio and media-button control`.

### Task I3: الصفحة والدخول والتنبيه الأول

**Files:**
- Create: `lib/features/memorization_plus/presentation/pages/hands_free_review_page.dart`
- Modify: `lib/core/router/app_router.dart`: مسار `AppRoutes.handsFreeReview = '/memorization-plus/hands-free'`، وحارس العلم والبالغ فقط على نمط `similarAyahTrainerRedirect`.
- Modify: `lib/features/memorization_plus/presentation/pages/memorization_hub_page.dart`: بطاقة في قسم «المراجعة» حين يكون العلم مفعّلاً.
- ARB: `handsFreeTitle`، و`handsFreeDrivingWarning` (النص: «لا تستخدم الشاشة أثناء القيادة»، من المواصفة)، و`handsFreeStart`، و`handsFreeCorrect`، و`handsFreeReview`، و`handsFreeSummary` بـICU plural، و`handsFreeNoDue`، و`handsFreeMicFallback`.
- Test: `test/features/memorization_plus/presentation/pages/hands_free_review_page_test.dart`، و`test/core/router/hands_free_route_policy_test.dart`

- [x] **Step 1: الاختبارات الفاشلة:**
  - أول فتح يُظهر تحذير القيادة، ولا يظهر بعد قبوله (`hands_free_warning_seen|<owner>`).
  - العلم مطفأ ← لا بطاقة في المركز، والمسار يعيد إلى المركز.
  - ملف طفل ← إعادة توجيه.
  - لا مستحقات ← `handsFreeNoDue`.
  - الملخص يعرض أسماء السور وأرقام الآيات (`similarAyahLabel` من المرحلة 2)، **لا نص الآيات**.
- [x] **Step 2:** تشغيلها. المتوقع: FAIL.
- [x] **Step 3:** التنفيذ. ويُضاف المفتاح `hands_free_warning_seen|` إلى `AccountDataReset`.
- [x] **Step 4:** تشغيلها، ثم `flutter analyze`. المتوقع: PASS ولا ملاحظات.
- [x] **Step 5:** Commit `feat(hifz): hands-free review page behind handsFreeReview`.

توثيق I2/I3: `07cb4268` و`a54ac6e`، و2302 اختبار ناجح والتحليل الشامل بلا
ملاحظات. [تقرير التنفيذ وحدود التحقق](../reviews/2026-10-23-hands-free-review.md).
هذه نتائج آلية؛ I4 ما زال مطلوبًا قبل تفعيل العلم.

### Task I4: تجربة المالك (T8.3)

- [ ] جهاز حقيقي، والشاشة مطفأة، وسماعة بلوتوث. تُدوَّن نتيجة صف جديد «`handsFreeReview`» في `docs/release/flag-device-test-matrix.md`، ويشمل: مكالمة واردة أثناء الجولة، وفصل السماعة، وأزرار شاشة القفل.

---

# الدفعة J: ودجت الشاشة الرئيسية (البند 7). تبدأ بعد موافقة R1

### Task J1: اللقطة الخالصة

**Files:**
- Create: `lib/core/home_widget/widget_snapshot.dart`
- Create: `lib/core/home_widget/widget_snapshot_builder.dart`
- Test: `test/core/home_widget/widget_snapshot_builder_test.dart`

**Interfaces:**
- Produces:
  - `final class WidgetSnapshot`، وحقوله:
    - `schemaVersion = 1`
    - `String? nextPrayerKey` (`fajr`…`isha`) و`DateTime? nextPrayerAt`
    - `int dueReviewCount`
    - `int? wirdFromPage` و`int? wirdToPage` و`int? wirdDonePages`
    - `String? wirdSurahName` (من `SurahNames` فقط)
    - `bool isEmpty`
    - `Map<String, Object?> toJson()`
  - `const WidgetSnapshot.empty()`
  - `WidgetSnapshot buildWidgetSnapshot({required bool enabled, required bool isAdult, required bool signedOutOrSwitching, PrayerTimesDay? today, PrayerTimesDay? tomorrow, required int dueReviewCount, KhatmahPlan? activePlan, required DateTime now})`. يُوجَّه المنفّذ إلى الأنواع الفعلية في `prayer_times_service.dart` و`khatmah_plan.dart`.

- [x] **Step 1: الاختبارات الفاشلة:**
  - علم مطفأ، أو ملف طفل (R6)، أو `signedOutOrSwitching` ← `WidgetSnapshot.empty()`.
  - بعد العشاء ← الصلاة القادمة فجر الغد.
  - `dueReviewCount < 0` ← 0.
  - لا خطة ختمة نشطة ← حقول الورد `null`.
  - `toJson()` لا يحتوي أي مفتاح نصي فيه نص آية. يُفحص بأن القيم النصية الوحيدة هي `nextPrayerKey` و`wirdSurahName`، وأن `wirdSurahName` من `SurahNames`.
- [x] **Step 2:** `flutter test test/core/home_widget`. المتوقع: FAIL.
- [x] **Step 3:** التنفيذ.
- [x] **Step 4:** نفس الأمر. المتوقع: PASS.
- [x] **Step 5:** Commit `feat(widget): pure home-widget snapshot`.

### Task J2: النشر والتحديث وعزل الحسابات

**Files:**
- Modify: `pubspec.yaml` بإضافة `home_widget` بإصدار ثابت محدد (R1)، ثم `flutter pub get`.
- Create: `lib/core/home_widget/home_widget_publisher.dart`
- Modify: `lib/core/di/injection.dart`: تسجيل الناشر وربط المحفّزات.
- Modify: `lib/core/identity/account_data_reset.dart`: `clear()` يُستدعى ضمن المسح.
- Modify: `lib/core/sync/background_sync_scheduler.dart`: التحديث من المهمة الدورية الموجودة.
- Test: `test/core/home_widget/home_widget_publisher_test.dart`، و`test/integration/account_switch_isolation_test.dart` (إضافة حالة).

**Interfaces:**
- Consumes: J1.
- Produces:
  - `abstract interface class HomeWidgetBridge { Future<void> save(String key, String? json); Future<void> requestUpdate(); }`، وتنفيذه الافتراضي فوق `home_widget`.
  - `final class HomeWidgetPublisher`، وطرقه:
    - `Future<void> refresh()`: تقرأ المصادر، وتبني اللقطة، ثم تحفظها تحت المفتاح `talia_widget_snapshot_v1` وتطلب التحديث.
    - `Future<void> clear()`: تحفظ `null` وتطلب التحديث.
  - المحفّزات:
    - استئناف التطبيق.
    - `ProgressEventsBus` لسبب `reviewRecord`.
    - بعد جدولة الصلوات في `notification_scheduler`.
    - المهمة الدورية.

- [x] **Step 1: الاختبارات الفاشلة (بجسر وهمي):**
  1. `refresh()` بعلم مفعّل وبالغ ← حفظ JSON غير فارغ، ثم `requestUpdate`.
  2. تبديل الحساب عبر `AccountDataBarrier.prepareOwner` ← `clear()` يُستدعى **قبل** أي `refresh` للحساب الجديد. **(Review Focus 1)**
  3. تسجيل الخروج ← لقطة فارغة.
  4. خطأ من الجسر ← يُسجَّل ولا يُرمى، فلا يُكسر الاستئناف.
  5. حالة العزل في `account_switch_isolation_test.dart`: لقطة الحساب A لا تبقى بعد الدخول بالحساب B.
- [x] **Step 2:** تشغيلها. المتوقع: FAIL.
- [x] **Step 3:** التنفيذ.
- [x] **Step 4:** تشغيلها، ثم `test/core` و`test/integration`: ناجحان ضمن الفحص الشامل، 5170 اختبارًا.
- [x] **Step 5:** `scripts/verify_v1_release.ps1` دون `-BuildAndroidRelease`: نجحت استعادة التبعيات مع ثبات القفل؛ التحقق محلي فقط.
- [x] **Step 6:** Commit `feat(widget): publisher, refresh triggers, cleared on account change`.

### Task J3: الكود الأصلي

**Files:**
- Create: `android/app/src/main/kotlin/com/talia/quran/widget/WidgetSnapshotFormatter.kt`، وهو منطق خالص قابل للاختبار.
- Create: `android/app/src/main/kotlin/com/talia/quran/widget/TaliaHomeWidgetProvider.kt`، وهو `AppWidgetProvider` يقرأ JSON من `HomeWidgetPlugin.getData`.
- Create: `android/app/src/main/res/layout/talia_home_widget.xml`، و`res/xml/talia_home_widget_info.xml`، ونصوص في `res/values/` و`res/values-ar/`.
- Modify: `android/app/src/main/AndroidManifest.xml` بإضافة `receiver`.
- Modify: `lib/core/router/app_router.dart`: روابط `talia://widget/prayer` و`talia://widget/review` و`talia://widget/khatmah` تُعاد توجيهها إلى المسارات القائمة (مواقيت الصلاة، ومراجعة اليوم، ولوحة الختمة).
- Test: `android/app/src/test/kotlin/com/talia/quran/widget/WidgetSnapshotFormatterTest.kt`، و`test/core/router/widget_deep_link_test.dart`

**Interfaces:**
- Consumes: JSON من J1، مخطط `schemaVersion = 1`.
- Produces في Kotlin:
  - `data class WidgetRows(val prayerLine: String?, val reviewLine: String?, val wirdLine: String?, val empty: Boolean)`
  - `fun format(json: String?, arabic: Boolean, nowMillis: Long): WidgetRows`

- [x] **Step 1: اختبارات JVM فاشلة:**
  - `json == null` أو مخطط غير معروف ← `empty = true`.
  - العربية ← أرقام عربية-هندية واسم الصلاة بالعربية.
  - `dueReviewCount = 0` ← `reviewLine == null`.
  - JSON تالف ← `empty = true` دون استثناء.
- [ ] **Step 2:** `cd android; ./gradlew :app:testDebugUnitTest --tests '*WidgetSnapshotFormatterTest*'`. المتوقع: FAIL.
- [x] **Step 3:** التنفيذ. التخطيط بـ`layoutDirection="locale"`. والنقر على كل سطر `PendingIntent` لرابطه.
- [x] **Step 4:** نجح `:app:testDebugUnitTest` كاملًا، 41 اختبارًا منها 9 للودجت، بإعداد مجلد اتصال Java مؤقت للعملية. اختبار الرابط غير المعروف ناجح ضمن فحص Flutter الشامل؛ تفاصيل الأمر في تقرير الودجت.
- [ ] **Step 5:** على الإيميوليتر: إضافة الودجت، وتسجيل الخروج يفرّغه، وكل سطر يفتح مساره. تُدوَّن النتيجة في مصفوفة الأعلام. (2026-10-24: تفعيل المستقبِل وتعطيله مع العلم متحقق، لكن مشغّل الإيميوليتر المتاح لا يدعم الودجت، فالخطوة تنتظر جهازاً آخر.)
- [x] **Step 6:** Commit `feat(widget): Android home-screen widget with RTL rows and deep links`.
- [x] **Step 7:** مراجعة Opus (`opus-architecture-reviewer`) لعزل الحسابات والكود الأصلي.

---

# الدفعة K: الختمة الجماعية (البند 10). عالية المخاطرة

**تحديث 2026-10-24:** اعتمد المالك التصميم والتنفيذ المحلي. K1 محفوظة في
`143a0add`، ونُفّذت K2/K3 خلف العلم مع مراجعة Sol مستقلة وإصلاح ملاحظاتها.
نجح فحص النطاق المتأثر بـ174 اختبارًا، ثم نجحت اختبارات السباقات الستة بعد
إصلاح سباق زوال العضوية. اكتمل الفحص الشامل بـ5163 اختبارًا ناجحًا، والتحليل
بلا ملاحظات، وفحص الإصدار `LOCAL PASS — RELEASE NO-GO`.
تفاصيل التنفيذ والحدود في [تقرير الختمة الجماعية](../reviews/2026-10-23-group-khatmah.md).
فحوص K1 المحلية استخدمت PGlite المثبت، وشغلت الهجرات مرتين وثلاثة ملفات SQL
و34 فحص كتالوج بنجاح؛ هذا بديل محلي محدود، ولا يغلق بوابة مخطط Supabase
الكامل أو التزامن متعدد الاتصالات. لا نشر أو تفعيل للأعلام.

### Task K0: تصميم Opus (لا كود)

**Files:**
- Create: `docs/superpowers/specs/YYYY-MM-DD-group-khatmah-design.md`

يجب أن يحسم:
- **الجداول، وكلها بـRLS:**
  - `group_khatmah (id, code UNIQUE, title, owner_id, max_members ≤ 30, status, version, created_at, completed_at)`
  - `group_khatmah_member (group_id, user_id, display_name 2–24, joined_at, left_at)`
  - `group_khatmah_part (group_id, juz 1..30, status {open, claimed, completed}, claimed_by, version, updated_at)`
- **الدوال**، وكلها `SECURITY DEFINER` و`search_path=''`، ومن دون `PUBLIC` و`anon`، وممنوحة لـ`authenticated` فقط:
  - `create_group_khatmah(title, display_name)` ← المجموعة مع الرمز. يُولَّد بالأبجدية R5، ويُعاد التوليد عند تصادمه.
  - `join_group_khatmah(code, display_name)`
  - `claim_group_part(group_id, juz, expected_version)`
  - `complete_group_part(group_id, juz, expected_version)`
  - `release_group_part(group_id, juz, expected_version)`
  - `leave_group_khatmah(group_id)`
- **التعارضات:**
  - حجز متزامن: يُرجع `applied:false` مع الصف الحالي.
  - إكمال جزء محجوز لغيرك: مرفوض.
  - إكمال بعد المغادرة: مرفوض بحالة `not_member`.
  - مغادرة صاحب المجموعة.
  - المجموعة المكتملة تصبح للقراءة فقط.
- **القراءة:** `select` مقيَّد بالعضوية النشطة. والبريد لا يُكشف أبداً، فلا join مع `auth.users`.
- **المؤشرات والطابور:** نوعا طابور جديدان `group_khatmah_pull` و`group_khatmah_push`.

- [x] مراجعة `opus-architecture-reviewer` للتصميم، ثم **موافقة المالك على التصميم (R4)**. تصميم Astra ومراجعة Sol المستقلة وإصلاح الملاحظات، ثم اعتماد المالك الصريح للتصميم والتنفيذ المحلي في 2026-10-23: `../specs/2026-10-23-group-khatmah-design.md`.

### Task K1: الهجرة وفحوص العقد

**Files:**
- Create: `supabase/migrations/<timestamp>_group_khatmah.sql`، قابلة لإعادة التشغيل بنمط هجرات المرحلة 2: `IF NOT EXISTS` و`CREATE OR REPLACE` و`DROP POLICY IF EXISTS`.
- Create: `supabase/tests/<timestamp>_group_khatmah_test.sql`
- Create: `scripts/verify_group_khatmah_contract.ps1`، و`test/supabase/group_khatmah_contract_test.dart`
- Modify: `scripts/verify_supabase_contract.ps1` لإضافة الدوال الجديدة.

- [ ] **Step 1: اختبارات SQL فاشلة:**
  - غير العضو لا يرى المجموعة.
  - حجزان بنفس `expected_version`: واحد فقط ينجح. **(Review Focus 3)**
  - عضو رقم 31 مرفوض.
  - رمز غير صالح مرفوض.
  - إكمال بعد المغادرة يعطي `not_member`.
  - إعادة تشغيل الهجرة مرتين دون خطأ.
  - الدوال بلا منح لـ`anon`.
- [ ] **Step 2:** `scripts/verify_supabase_migrations.ps1` على قاعدة محلية مُرحَّلة. المتوقع: FAIL.
- [x] **Step 3:** كتابة الهجرة.
- [ ] **Step 4:** نفس الأمر، ثم `flutter test test/supabase/group_khatmah_contract_test.dart`. المتوقع: PASS.
- [x] **Step 5:** مراجعة `opus-architecture-reviewer` **إلزامية**.
- [x] **Step 6:** Commit `feat(supabase): group khatmah schema, RLS and CAS RPCs (not deployed)`.

### Task K2: المستودع والتخزين المحلي والدمج والطابور

**Files:**
- Create: `lib/features/group_khatmah/domain/entities/group_khatmah.dart`، وفيه `GroupKhatmah` و`GroupMember` و`GroupPart` و`GroupPartStatus`.
- Create: `lib/features/group_khatmah/domain/repositories/group_khatmah_repository.dart`
- Create: `lib/features/group_khatmah/data/group_khatmah_repository_impl.dart`
- Create: `lib/features/group_khatmah/data/group_khatmah_cloud_merge.dart`
- Modify: `lib/core/sync/cloud_sync_queue.dart` بإضافة `groupKhatmahPull = 'group_khatmah_pull'` و`groupKhatmahPush = 'group_khatmah_push'`.
- Modify: `lib/core/identity/account_data_reset.dart` بالبادئة `group_khatmah_cache_v1|`.
- Create: `lib/core/di/group_khatmah_injection.dart`
- Test: `test/features/group_khatmah/data/group_khatmah_repository_test.dart`، و`group_khatmah_cloud_merge_test.dart`، و`test/integration/account_switch_isolation_test.dart` (حالة).

**Interfaces:**
- Produces:
  - `Future<Either<Failure, GroupKhatmah>> create(String title, String displayName)`
  - `Future<Either<Failure, GroupKhatmah>> join(String code, String displayName)`
  - `Future<Either<Failure, GroupPart>> claim(String groupId, int juz)`. يتطلب اتصالاً، ويُرجع `GroupPartConflictFailure` عند التعارض.
  - `Future<Either<Failure, void>> completeLocally(String groupId, int juz)`. يحفظ في الكاش المحلي ويُدرج `groupKhatmahPush`.
  - `Future<Either<Failure, void>> leave(String groupId)`
  - `Stream<List<GroupKhatmah>> watchMine()`
  - الكاش: SharedPreferences تحت `group_khatmah_cache_v1|<owner>` بمؤشرات ومفاتيح متسخة على نمط `*_cloud_merge.dart`. **لا مخطط Isar جديد.**

- [x] **Step 1: الاختبارات الفاشلة (بعميل Supabase وهمي):**
  - الحجز دون اتصال ← `NetworkFailure`، ولا تغيير محلي.
  - تعارض الحجز ← `GroupPartConflictFailure`، ثم سحب للتحديث. **(Review Focus 3)**
  - الإكمال دون اتصال ← محفوظ محلياً، ومُدرَج في الطابور، ويُرسَل عند الاتصال بـ`expected_version` الصحيح.
  - الإكمال المعلّق بعد المغادرة يعيد `not_member`، فيُحذف من الطابور دون إعادة محاولة. **(Review Focus 5)**
  - الدمج: صف أحدث من الخادم يفوز إلا على مفتاح متسخ لم يُؤكَّد.
  - تبديل الحساب: لا يرى B كاش A.
  - **الختمة الشخصية لا تتغير بأي عملية جماعية**: لا استدعاء لمستودع الختمة الشخصية.
- [x] **Step 2:** تشغيلها. المتوقع: FAIL.
- [x] **Step 3:** التنفيذ.
- [x] **Step 4:** تشغيلها، ثم `test/core/sync` و`test/integration`. المتوقع: PASS.
- [x] **Step 5:** Commit `476b1563` — المستودع والسجل الدائم والطابور وعزل الحساب.

### Task K3: الواجهات

**Files:**
- Create: `lib/features/group_khatmah/presentation/cubits/group_khatmah_cubit.dart`
- Create: `lib/features/group_khatmah/presentation/pages/group_khatmah_list_page.dart`، و`group_khatmah_detail_page.dart`، و`group_khatmah_join_sheet.dart`
- Modify: `lib/core/router/app_router.dart` بمسار `/khatmah/group`، وحارس العلم والبالغ فقط.
- Modify: `lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart` بمدخل «ختمة جماعية» حين يكون العلم مفعّلاً.
- ARB: مفاتيح `groupKhatmah*`. والأعداد، مثل «N من 30 جزءاً» و«N أعضاء»، بـICU plural.
- Test: `test/features/group_khatmah/presentation/group_khatmah_detail_page_test.dart`

- [x] **Step 1: الاختبارات الفاشلة:**
  - شبكة الأجزاء الثلاثين بحالاتها، واسم العرض فقط دون أي بريد.
  - مشاركة الرمز.
  - رسالة التعارض.
  - بطاقة الإكمال تعرض دعاء الختم من `KhatmDuaDatasource`. وإن كان المحتوى غير معتمد فلا دعاء، على نمط اختبار `an unapproved khatm dua record opens nothing`.
  - شاشة 320dp دون تجاوز.
  - العلم مطفأ ← لا مدخل.
- [x] **Step 2:** تشغيلها. المتوقع: FAIL.
- [x] **Step 3:** التنفيذ.
- [x] **Step 4:** تشغيلها، ثم `flutter analyze`. المتوقع: PASS ولا ملاحظات.
- [x] **Step 5:** Commit `168c6b84` — الواجهات والحراسة والاستعادة، خلف العلم المطفأ.

### Task K4: مراجعة الدفعة

- [x] مراجعة معمارية: Astra على تصميم K1 ثم K4 وحواجز الردود المتأخرة، مع خطة إصلاح نفذها الجذر وفحص Sol مستقل. اختبارات فشل ثم نجاح لتبديل العضوية والردود القديمة؛ لا ملاحظات قابلة للإجراء في المتابعة المركزة.
- [x] `flutter test` كاملاً: 5170 اختبارًا ناجحًا على إصلاح `b817c83c`، بالتوازي 4 ومضاعف المهلة المحدود `2x`. الأمر الافتراضي لم يتغير؛ المحاولات السابقة المتعثرة موثقة في التقرير.

### Task K5: التشغيل التجريبي ثم النشر (Opus، بموافقة المالك)

- [ ] تشغيل الهجرة داخل `DO` ثم `ROLLBACK` على مشروع Supabase، وتسجيل النتيجة. (لم يُنفَّذ منفصلاً. كل `apply_migration` يعمل في معاملة مستقلة، وسبقه فحص الاعتماديات والمخطط `private` وتعريف `delete_current_user` الحالي.)
- [x] **عرض النشر على المالك وانتظار موافقته الصريحة لحظة التنفيذ.** طلب المالك نشر هجرات المرحلتين 2 و3 في 2026-10-24.
- [x] بعد الموافقة: النشر على `Talia_Quran` (`vxsqwozctxkvhgxkciua`)، ثماني هجرات نجحت كلها: ثلاث للمرحلة 2 وخمس للمرحلة 3. ثم فحوص العقد عبر `execute_sql`، وهي مكافئة لفحوص `verify_group_khatmah_contract.ps1` وصلاحيات دوال المرحلة 2: **32/32 ناجحة**. مستشارو الأمان لم يُظهروا جديداً خارج النمط القائم. لم يُشغَّل السكربت نفسه، لأنه يحتاج اتصال psql مباشراً.
- [ ] تزويد الأهلية: `private.group_khatmah_provision` لا يُستدعى من العميل، فكل حساب يتلقى `not_eligible` حتى يُزوَّد من مدير القاعدة. العلم ما زال مطفأً.

---

## 2. التحقق النهائي للمرحلة

- [x] `flutter analyze` بلا ملاحظات، و`flutter test` كاملاً ناجح (5170، بمهلة `2x` وتوازي 4)، و`./gradlew :app:testDebugUnitTest` ناجح (41، بإعداد Java مؤقت موثق).
- [x] `scripts/verify_v1_release.ps1` ناجح محليًا بخياري `-TestConcurrency 4 -TestTimeout 2x`: `LOCAL PASS — RELEASE NO-GO`؛ لا بناء إصدار أو فحص قاعدة بعيدة.
- [x] تقرير [حالة المرحلة](../reviews/2026-10-24-roadmap-phase-3-status.md) بالمُصلَح والمفتوح والتقارير التفصيلية.
- [x] صفوف جديدة في `docs/release/flag-device-test-matrix.md` للأعلام الأربعة، مع توضيح أن تجربة الجهاز لم تنفذ.
- [x] القيم الافتراضية لكل الأعلام مطفأة، ولم يفعّلها هذا التنفيذ. وتفعيل أي علم مشروط بالقسم 0 وبتجربة جهاز حقيقي.

تجاوز فحص Gradle عائق Java بإعداد مؤقت خاص بالعملية، ثم نجح بعد جلب أدوات
التبعية المحددة. لا يثبت ذلك تجربة المشغّل أو بناء إصدار موقع. تبقى H2/H3
وI4 وبوابات الجهاز والخادم وK5 مفتوحة وفق شروطها أعلاه. لم يثبت فشل اختبارات
الودجت عبر Gradle قبل التنفيذ في J3 Step 2؛ إثبات الفشل/النجاح المعزول
للمنسّق موثق، وعائق Java السابق ليس فشلًا سلوكيًا للاختبارات.
