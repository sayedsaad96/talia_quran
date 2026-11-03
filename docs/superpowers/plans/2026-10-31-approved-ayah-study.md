# Approved Ayah Study Implementation Plan — الفهم المعتمد بجوار الآية

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** إتاحة تفسير عربي وترجمة معاني إنجليزية معتمدين محليًا من الآية، مع المصدر والحواشي.

**Architecture:** feature مستقلة `quran_study` تقرأ حزمًا محلية ذات إصدار واعتماد وبصمة. تستقبل canonical ayah reference من القارئ القائم؛ لا تغير QuranRepository أو corpus أو نظام الحفظ.

**Tech Stack:** Flutter/Dart، Cubit، Repository/UseCases، asset bundles، crypto الموجود؛ لا API أثناء القراءة ولا dependency جديدة.

**Spec:** `docs/superpowers/specs/2026-10-31-three-initiatives-design.md`، القسم B.

**حالة 2026-11-01:** B2/B3 منفذان هندسيًا ومربوطان بالقارئ خلف علم مطفأ؛ B1 ينتظر المصدر والإصدار والحقوق والاعتماد البشري. لا توجد حزمة تفسير أو ترجمة فعلية مضافة. [سجل التنفيذ](../../release/2026-10-31-three-initiatives-validation.md).

## Global Constraints

- Dart `^3.12.0` وFlutter `>=3.44.0`؛ العربية والإنجليزية وRTL/LTR وTalkBack وتكبير 200%.
- لا نشر محتوى قبل ثبوت المصدر/الإصدار/الحقوق/المراجعة؛ لا تعديل قرآن أو توليد تفسير أو ترجمة.
- لغة المحتوى منفصلة عن لغة الواجهة؛ الحواشي والنطاقات والعزو محفوظة، ولا تقطع فقرة المصدر لإجبارها على آية واحدة.
- وثيقة المصدر الأول من المجمع تعذر الوصول لرابطها في التخطيط؛ لا يعد ذلك سماحًا باستبداله تلقائيًا.

## Review Focus

1. block يغطي عدة آيات: يظهر نطاقه الصحيح دون تكرار مصطنع — B2/B3.
2. حواشٍ أو HTML وروابط غير آمنة: حفظ المعنى والبنية دون تنفيذ markup — B2.
3. حزمة تالفة/غير معتمدة/ذات إصدار مجهول: توقف طبقة الفهم وحدها — B2/B3.
4. تبديل الآية بينما الطلب جارٍ: لا عرض تفسير آية سابقة — B3.
5. لغة واجهة إنجليزية مع تفسير عربي وتكبير 200%: اتجاه وحركة وترتيب قراءة صحيح — B3.

## Task B1: اعتماد حزمة المصدر قبل نشرها

**Files:**
- Create: `docs/content/2026-10-31-quran-study-source-register.md` عند التنفيذ.
- Reference: `docs/TALIA_ISLAMIC_CONTENT_SOURCES_POLICY.md`, `assets/data/content_manifest.json`.
- لا تعديل أصول المحتوى في هذه المهمة قبل توافر الحقوق.

**Interfaces:** سجل اعتماد لكل dataset: `sourceId`, `kind`, `language`, `workTitle`, `publisher`, `edition`, `sourceUrl`, `retrievedAt`, `licenseEvidence`, `reviewedBy`, `reviewedAt`, `reviewDecision`, `sha256`, `footnoteFormat`, `coverage`.

- [ ] تحقق من صفحة التفسير الميسر الحالية ونسخة بعينها؛ ابدأ بالمصدر الذي تحدده السياسة. تحقق من QuranEnc translations/list واختر عملًا إنجليزيًا مسمى وإصدارًا ثابتًا؛ `english_saheeh` مثال API وليس اختيارًا معتمدًا مسبقًا.
- [ ] وثق حقوق التخزين المحلي والتوزيع والتحديث والنسبة؛ وجود API لا يثبتها. سجل المعرفات والإصدار والقرار البشري. لا مراسلات خارجية تلقائية باسم المستخدم.
- [ ] بوابة نجاح: مصدران بإثبات حقوق وقرار مراجعة يسمحان بالاستخدام المقترح. إن نقص أي شرط، سجل `blocked` للـdataset؛ يمكن متابعة تطوير B2/B3 ببيانات اختبار تقنية غير منشورة، ولا يفتح التفعيل للمستخدم.
- [ ] راجع السجل ثم commit للوثيقة وحدها. أي اختيار مصدر بديل يمر بسياسة التعارض لا بسهولة API.

## Task B2: حزم بإصدار وتحقق deterministic

**Files:**
- Create: `lib/features/quran_study/domain/entities/study_entry.dart`, `domain/repositories/quran_study_repository.dart`, `domain/usecases/get_ayah_study.dart`, `data/datasources/approved_study_bundle_source.dart`, `data/repositories/quran_study_repository_impl.dart`.
- Create: `tool/content/validate_quran_study_bundle.dart`, `test/features/quran_study/study_bundle_validation_test.dart`, `test/features/quran_study/quran_study_repository_test.dart`.
- After B1 only: `assets/data/quran_study/study_manifest.json`, `tafsir_ar.json`, `translation_en.json`; register in `pubspec.yaml` and governance manifest using approved metadata.

**Interfaces:**
- `StudyBlock`: sourceId, blockId, surahId, fromAyah, toAyah, kind (tafsir/meaningTranslation), language, text, footnotes. العربية القرآنية تعرض من corpus الحالي فقط.
- `Future<StudyLoadResult> GetAyahStudy.call({required int surahId, required int ayahNumber, required StudyKind kind})`؛ نتائج ready/unavailable/invalidReference/invalidBundle مع entries+source metadata عند ready.
- `StudyBundleValidation validateStudyBundle({required List<int> bytes, required Map<String, Object?> manifestEntry, required Map<int, int> canonicalAyahCounts})`: يثبت approval/rights evidence/hash، uniqueness، bounds من corpus الموجود، النطاقات والتغطية المصرح بها. التغطية الكاملة تعني كل آية لها entry أو block يغطيها؛ لا تفترض block لكل آية.

- [ ] اكتب اختبارات لحزمة كاملة وصحيحة؛ نقص آية؛ تداخل مشروع عبر blocks مميزة؛ duplicate blockId؛ surah/ayah غير صالح؛ mismatch hash؛ missing approval؛ حاشية ونطاق محفوظين دون تغيير.
- [ ] استخدم corpus المرجعي الحالي عند الحاجة لنص قرآني؛ fixtures للفهم تعليمات تقنية مصطنعة معلنة، لا تفسيرًا منشورًا مخترعًا.
- [ ] شغل `flutter test test/features/quran_study` وتحقق من فشل الحالات الجديدة؛ نفذ parser/validator/repository. اعرض النص كنص منظم آمن؛ لا WebView أو HTML فعّال ولا تحميل روابط ضمن العرض.
- [ ] أعد الاختبارات؛ بعد B1 استورد الحزمة verbatim وشغل `dart run tool/content/validate_quran_study_bundle.dart`؛ نجاحه يحتاج صفر أخطاء مع تقرير coverage/bounds/hashes. لا تقبل اختبار schema وحده كاعتماد شرعي.
- [ ] تحقق deterministic من عدم تغير `assets/data/quran.json`. راجع ثم commit ملفات المهمة فقط.

## Task B3: لوحة فهم يمكن الوصول إليها من الآية

**Files:**
- Create: `lib/features/quran_study/presentation/cubits/ayah_study_cubit.dart`, `ayah_study_state.dart`, `presentation/widgets/ayah_study_sheet.dart`, `study_source_footer.dart`.
- Modify: `lib/features/quran/presentation/widgets/ayah_options_sheet.dart`, `reader_overflow_sheet.dart`, `lib/core/di/injection.dart`, `lib/core/l10n/app_ar.arb`, `lib/core/l10n/app_en.arb`, `lib/core/experience/experience_feature_flags.dart`, `rollout_manifest.dart`.
- Test: `test/features/quran_study/ayah_study_cubit_test.dart`, `ayah_study_sheet_test.dart`, existing `test/features/quran/presentation/widgets/ayah_options_sheet_test.dart`.

**Interfaces:**
- `Future<void> AyahStudyCubit.load({required int surahId, required int ayahNumber, required StudyKind kind})` يستعمل GetAyahStudy، ويرفض نتائج request سابقة بعد الاختيار/الإغلاق.
- `AyahStudySheet.show(context, {required int surahId, required int ayahNumber})`؛ تبويبا التفسير وترجمة المعاني، وloading/empty/blocked/error مستقلان.
- مدخل بديل للضغط المطول: overflow «فهم آية» ثم اختيار مرجع واضح من الصفحة الحالية، دون افتراض أن أول آية مرئية هي المحددة.
- مفتاح `approvedAyahStudy` افتراضيًا off؛ تفعيله يتطلب B1+B2+B3 وسجل قبول G.

- [ ] اختبر طلب آية A بطيء ثم B سريع: تعرض B فقط؛ missing bundle يترك القارئ صالحًا؛ تعديل اللغة لا يستبدل dataset؛ لا تقدم/XP عند فتح أو قراءة الفهم.
- [ ] اختبر العنوان والمصدر والإصدار والحواشي والنطاق، ونسخ مرجع بلاغ يحتوي source/version/ayah دون إرسال شبكة تلقائي. المشاركة المباشرة للنص خارج v1.
- [ ] شغل `flutter test test/features/quran_study test/features/quran/presentation/widgets/ayah_options_sheet_test.dart` للفشل قبل التنفيذ ثم نفذ الواجهة والـDI والتوطين و`flutter gen-l10n`.
- [ ] أعد الاختبارات؛ اختبر Android بلا شبكة وTalkBack وتكبير 200% وRTL/LTR وإغلاق/فتح أثناء تشغيل الصوت. وقت فتح اللوحة لا يعيد تهيئة المشغل أو المصحف.
- [ ] قارن عينة عرض بشرية بالمصدر، ثم راجع وcommit. لا تفعل الميزة إذا بقي dataset blocked حتى لو نجحت اختبارات UI.

## الإطلاق والتراجع

حزمتان معتمدتان كاملتان أو تجربة داخلية مغلقة واضحة؛ لا ادعاء تغطية القرآن كاملًا مع نقص المحتوى. التراجع يعطل الفهم فقط ويحافظ على المصحف والتقدم. تحديث dataset إصدار مستقل يمر B1/B2 مجددًا، ولا تجلب تحديثات صامتة أثناء القراءة.
