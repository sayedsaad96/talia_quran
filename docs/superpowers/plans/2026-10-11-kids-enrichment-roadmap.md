# خطة تنفيذ إثراء مسار الأطفال — Talia Quran

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. اتبع سياسة المشروع: Luna للاستكشاف، Terra للتنفيذ المعتاد، Sol للمراجعة والتكامل، وAstra للتحقيق المحدد في المخاطر الحرجة فقط.

**Goal:** تنفيذ المقترحات الاثني عشر تدريجيًا لتطوير الحفظ والفهم والمشاركة الأسرية والمتعة، مع حماية القرآن والتقدم والخصوصية والصوت.

**Architecture:** تمديد مسار الأطفال الحالي ومالكيه بدل بناء محرك حفظ أو مكافآت أو مزامنة بديل. المحتوى التعليمي والأنشطة الاختيارية لهما حالة منفصلة عن إثبات الحفظ، وتظل العمليات الحساسة داخل repositories/use cases القائمة. يطلق كل جزء خلف مفتاح مستقل بعد اجتياز اختبارات الحدود التي يلمسها.

**Tech Stack:** Flutter/Dart، Cubit، GetIt، repositories/use cases، Isar وSharedPreferences، مشغلات الصوت القائمة، ARB، وتكامل الأسرة الحالي. لا تعتمد هذه الخطة ترقية حزم أو إضافة مزود ذكاء اصطناعي.

**Spec:** عقد النطاق والمقترحات في القسم التالي، نقلًا عن مراجعة مسار الأطفال وطلب المستخدم بتاريخ 2026-10-11. هذه خطة فقط، وليست إذنًا بالتنفيذ أو النشر.

**Baseline:** HEAD عند إعداد الخطة: `81cf125a89b952baebcafe818ef82eda43e46f95`. فُحصت شجرة عمل تحتوي تعديلات سابقة، منها ملفات الترجمة؛ المرجع ليس snapshot نظيفًا. أعد فحص فرق الملفات المستهدفة قبل التنفيذ. لم تُشغّل اختبارات أو تحقق أجهزة أثناء كتابة الخطة.

## 0. مراجعة 2026-10-12 — مقارنة بالكود وقرارات المالك (تُقدَّم على ما يخالفها أدناه)

**خط الأساس المعاد فحصه:** HEAD `6843a67a` — commit وثائق للبالغين فقط بعد baseline الخطة؛ لا تغيير في كود الأطفال. الملفات الـ44 المذكورة في القسم 2 موجودة، والفجوات المعلنة في القسم 2 مؤكدة. فحص قراءة فقط؛ لم تُشغّل اختبارات.

**قرارات المالك (2026-10-12):**
- **T6 وT11 وT12 مؤجلة** خارج هذه المبادرة (تتسق مع تأجيل الإرشاد الصوتي وحزم المحتوى في نطاق Talia Adventure v1). لا يُنفذ T0-A لأنه لا يُحتاج إلا لها.
- **T1: قوالب تربوية فقط** — بلا نسبة دينية أو آية أو حديث أو دعاء داخل القالب؛ لذلك لا يحتاج T1 مراجعة مصادر شرعية.

**نتائج لم تذكرها الخطة أو قللت منها:**
1. `KidsAchievementStore.sync` (`data/datasources/kids_achievement_store.dart`) يعيد كتابة الخريطة من `KidsAchievementCatalog.evaluate` فقط، فيُسقط أي ID غير معروف للكتالوج الحالي (downgrade أو إنجاز مستقبلي). **إصلاحه شرط قبل T2:** دمج المفاتيح المخزنة غير المعروفة عند الكتابة. إضافة قيم لـ `KidsAchievementId` تكسر `switch` الشامل في `kids_achievement_labels.dart` (تحتاج ARB عربي/إنجليزي)، وتحقق أن عرض إنجازات الطفل البعيد (`RemoteChildActivity.achievements`) يتجاهل IDs المجهولة دون crash.
2. `create_kids_home_mission(p_child_user_id, p_title)` بلا مفتاح idempotency؛ النقر المزدوج ينشئ مهمتين. في T1 يكفي قفل الإرسال في الواجهة/الـ Cubit؛ لا migration. العنوان نص حر 1–120 حرفًا، فالقالب يملأ النموذج فقط بلغة ولي الأمر.
3. جهاز ولي الأمر لا يملك `KidsSessionLog` للطفل البعيد؛ يملك ملخص `RemoteChildActivity` فقط (أحداث محدودة، إنجازات، `weekReadPagesCount`). **T3 في الإصدار الأول للطفل المحلي فقط**؛ الطفل البعيد لاحقًا عبر مفاتيح اختيارية في snapshot النشاط (نفس نمط الإنجازات، بلا migration) مع عرض «غير متاح» عند غيابها.
4. قرار «طفل واحد لكل جهاز» قائم، و`AccountDataReset` يمسح بيانات الحساب المغادر. لذلك **T0 مخفف:** لا كيان `KidsFeatureScope` ولا childKey أو ترحيل هوية جديد. النطاق = `ownerId` على جهاز الطفل، و`childUserId` من الربط على جهاز ولي الأمر. يسقط اختبار `sameOwnerDifferentChildIsIsolated`؛ يبقى `lateResultAfterOwnerChangeIsDiscarded` لأي تخزين جديد.
5. مفاتيح الإطلاق تتبع نمط `lib/core/memorization/kids_hifz_feature_flags.dart` القائم (SharedPreferences، الغائب = false)؛ لا remote config.
6. `kids_mode_cubit.dart` (1378 سطرًا) و`kids_gamified_listen_page.dart` (1190 سطرًا) تلمسهما T4/T7/T8؛ تُنفذ هذه المهام متتابعة لا متوازية.

**التصنيف المعتمد:**

| المهمة | الحالة | الشرط |
|---|---|---|
| T0 | جاهز | النسخة المخففة (البند 4–5) |
| T1 | جاهز | تربوية فقط + قفل الإرسال المزدوج |
| T2 | جاهز بعد إصلاح المخزن | البند 1 أولًا؛ الحقول `attemptCount`/`hintCount`/`missionType` موجودة في `KidsSessionLog` |
| T3 | جاهز للطفل المحلي | البند 3 |
| T10 | جاهز بعد T2 | إسقاط بصري من إنجازات محفوظة فقط |
| T9 | جزئي | `listenAndChooseSurah` فقط (تلاوة وأسماء سور قائمة)؛ `chooseMeaning` ينتظر T5 |
| T8 | مشروط | يمس جلسة الحفظ: مراجعة Opus واختبارات committer إلزامية |
| T4 | مشروط | إرشاد بلا حفظ receipt أولًا؛ receipt + PIN في خطوة ثانية |
| T7 | مشروط | محلي فقط، مثبت في snapshot الجلسة؛ مخاطرة متوسطة–عالية |
| T5 | محجوب | لا مصدر معاني مرخص (الغريب ينتظر إذن مجمع الملك فهد) |
| T6، T11، T12، T0-A | مؤجل | قرار المالك 2026-10-12 |

**ترتيب التنفيذ المعدل:** T0 (مخفف) → إصلاح مخزن الإنجازات → T1 → T2 → T3 (محلي) → T10 → T9 (لعبة السورة) → T8 → T4 → T7، كلٌّ في PR مستقل. هذا المسار لا يمس `assets/data/quran.json` ولا Isar schema ولا migrations السحابة.

## 1. عقد النطاق والأولوية

الأولوية هنا ترتيب تنفيذ، وليست تصنيف شدة عيوب. أهمية المحتوى التعليمي مرتفعة، لكن إطلاقه ينتظر اعتماد المحتوى. يمكن إعداده بالتوازي مع المراحل المبكرة دون نشر مواد غير معتمدة.

| الترتيب | المهمة | المقترح الأصلي | القرار وحدود النسخة الأولى |
|---|---|---|---|
| 0 | T0 خط الأساس والعزل ومفاتيح الإطلاق | شرط مشترك | واجب قبل أي ميزة |
| 1 | T1 قوالب المهام الواقعية | 5 أعيش ما أتعلم | تمديد مهام المنزل، لا دورة حالات بديلة |
| 2 | T2 تقدير الجهد والمراجعة | 8 إنجازاتي الحقيقية | تمديد الإنجازات دون تغيير النقاط أو إثبات الحفظ |
| 3 | T3 ملخص أسبوعي عملي للأهل | 9 الرسالة الأسبوعية | داخل التطبيق أولًا، من بيانات موثوقة ومكتملة |
| 4 | T4 جلسة مشتركة للأسرة | 2 نتعلم سوا | إرشاد محلي داخل الرحلة الحالية، لا اتصال حي عن بعد |
| 5 | T5 المحتوى المعتمد لفهم المعاني | 1 أفهم ما أحفظ | مجموعة تجريبية من 3 دروس معتمدة، ثم توسع |
| 6 | T6 التعليمات المسموعة | 11 تجربة غير القارئ | مقاطع واجهة مسجلة معتمدة، لا أوامر صوتية أو TTS للقرآن |
| 7 | T7 تخصيص المساندة حسب القدرة | 3 تخصيص حسب القدرة | مساندة اختيارية، دون زيادة حدود العمر أو تغيير ترتيب الرحلة |
| 8 | T8 مساعدة محددة بعد التعثر | 4 ساعدني | استخدام تلميحات المحرك الحالية أولًا |
| 9 | T9 ألعاب تعليمية قصيرة | 7 ألعاب تخدم مهارة | التعرف على السورة والمعنى؛ لا إعادة ترتيب نص القرآن |
| 10 | T10 عالم يتطور | 6 العالم المتطور | إسقاط بصري من إنجازات محفوظة، لا تقدم إضافي |
| 11 | T11 الحقيبة الأسبوعية | 10 دون اتصال | إدارة تنزيل موثوقة فوق مصادر الصوت الحالية |
| 12 | T12 سجل التلاوة الشخصي | 12 أنا أتقدم | محلي اختياري فقط بعد بوابة هوية وموافقة وحذف |

**مراحل الإطلاق:** A = T0–T4؛ B = T5–T8؛ C = T9–T10؛ D = T11؛ E = T12. كل مرحلة قابلة للإطلاق وحدها، وكل مهمة في PR مستقل أو مجموعة صغيرة قابلة للمراجعة. لا تجمع ترحيل بيانات وتغيير محرك حفظ وإعادة تصميم شامل في دفعة واحدة.

## 2. الموجود حاليًا ونقاط التمديد

المسارات التالية موجودة بالفعل؛ وجود الملف أو الاختبار لا يثبت نجاحه على جهاز أو في البيئة المنشورة.

| المكوّن الحالي | الملفات / الرموز القائمة | ما يجب الحفاظ عليه |
|---|---|---|
| إعداد الطفل والهوية | `lib/features/memorization_plus/presentation/pages/path_selection_page.dart`، `domain/entities/memorization_profile.dart`، `presentation/cubits/memorization_identity_cubit.dart` | العمر والاسم والاختيار الحالي؛ عدم افتراض وجود عدة ملفات أطفال محليًا |
| سياسة العمر | `domain/entities/kids_session_policy.dart` → `KidsSessionPolicy`، `KidsJourneyPath` | 5–7: آية جديدة واحدة/مراجعة واحدة/6 دقائق/3 استماعات؛ 8–12: آيتان جديدتان/3 مراجعات/10 دقائق/استماعان؛ الجلسة الحالية آية واحدة |
| الرئيسية والرحلة | `presentation/pages/kids_gamified_home_page.dart`، `kids_gamified_journey_page.dart`، `kids_gamified_stage_page.dart`؛ `presentation/cubits/kids_journey_cubit.dart` | المهمة الحالية، الاستكمال، الأقفال، أولوية المراجعة |
| جلسة الطفل | `presentation/cubits/kids_mode_cubit.dart` → `tryFromMemory`، `remindMe`، `revealFirstWord`، `submitManualCompletion`؛ `presentation/pages/kids_gamified_listen_page.dart` | استماع ثم استرجاع ثم تقييم؛ موافقة ولي الأمر في المسار اليدوي |
| محرك التقييم | `lib/core/memorization/v2/session_engine.dart`، `session_phase.dart`، `recitation_evaluator.dart` | التلميحات في memorizing فقط، إخفاء النص في التسميع؛ STT ليس تقييم تجويد |
| حفظ النتائج والمكافآت | `lib/core/memorization/v2/kids_review_outcome_committer.dart`؛ `data/repositories/collaborators/memorization_kids_local_service.dart` | هويات ثابتة عند retry؛ فصل نتيجة المراجعة عن منح النقاط وعدم تكرارهما |
| مهام المنزل | `domain/entities/kids_home_mission.dart`، `domain/usecases/kids_home_missions_usecase.dart`، `presentation/widgets/home_missions_panel.dart` | assigned → reported → acknowledged؛ إقرار ولي الأمر بالاطلاع ليس تحققًا آليًا |
| السياسة الأسرية | `domain/entities/kids_child_policy.dart`، `presentation/widgets/kids_policy_controls.dart`، `data/repositories/collaborators/kids_child_policy_sync.dart` | CAS وإصدارات السياسة واحترام صلاحية الربط |
| الإنجازات والتقدم | `domain/services/kids_achievements.dart`، `kids_progress_snapshot.dart`، `data/datasources/kids_achievement_store.dart` | لا إعادة تسمية IDs المخزنة؛ أرقام الطفل منفصلة عن البالغ |
| لوحة الأسرة | `presentation/pages/child_detail_page.dart`، `family_dashboard_page.dart`، `presentation/widgets/parent_support_tip.dart` | بيانات الطفل المحلي تختلف عن ملخص الطفل البعيد؛ حالات عدم التوفر ليست صفرًا |
| العالم | `domain/services/kids_adventure_regions.dart`، `presentation/world/kids_world_scene.dart`، `kids_policy_controller.dart` | ترتيب السور، تقليل الحركة، وعدم معاقبة الانقطاع |
| المصحف والصوت | `lib/features/quran/presentation/pages/kids_quran_reader_page.dart`، `lib/core/services/audio_cache_service.dart`، `audio_lifecycle_manager.dart` | مالك تشغيل واضح؛ لا تداخل بين التلاوة والتسجيل والإرشاد |

المسارات المختصرة أعلاه تبدأ بـ `lib/features/memorization_plus/` ما لم يذكر خلافه.

**فجوات مؤكدة في الأساس وليست ميزات مكتملة:**

- قيمة `guidanceAudioEnabled` محفوظة، لكن مفتاحها مخفي عمدًا في الإعداد لأن جلسة الأطفال لا تستهلكها بعد. لا تعرض خيارًا لا يعمل.
- `AudioCacheService.prefetchSession` يتجاهل فشل الملف الفردي، والكاش العام يخضع للإخلاء. لا تستخدم اكتمال الاستدعاء كدليل أن الحقيبة متاحة دون اتصال.
- خطة voice pilot سابقة موجودة بالوثائق، لكن `lib/features/talia_companion/` غير موجود في الفحص الحالي. لا تعتمد على بنية مخططة بوصفها منفذة.
- مخزن الإنجازات الحالي مربوط بمالك الحساب؛ أي بيانات جديدة متعددة الأطفال أو حساسة تحتاج إثبات نطاق الطفل المستقر، ولا يكفي نسخ المفتاح الحالي.

## 3. Global Constraints — قواعد ملزمة لكل مهمة

- لا تغيير لنص القرآن، معرّفات السور والآيات والصفحات، ترتيب رحلة الحفظ أو معرّفات تقدم المستخدم ضمن هذه المبادرة.
- لا إعادة ضبط للتقدم أو النجوم أو الشهادات؛ لا إعادة تسمية/ترتيب قيم enums المخزنة بالفهرس. أضف القيم الجديدة دون تغيير القديمة.
- الحفظ والمراجعة والتلميحات تُنفذ عبر المحرك الحالي، والإثبات عبر committer والمكافأة عبر مالكها الحالي. نجاح نشاط تعليمي لا يعني إتمام آية أو شهادة حفظ.
- clean architecture + Cubit + repositories/use cases + DI. لا وصول للتخزين من الواجهة، ولا منطق أعمال داخل widgets.
- الملفات الجديدة ≤500 سطر، widgets ≤300، methods ≤50. افصل فقط الجزء اللازم من الملفات المتضخمة؛ لا refactor عام.
- العربي والإنجليزي عبر ARB؛ `flutter gen-l10n` لتوليد الترجمات. لا تعديل يدوي للمخرجات المولدة، ولا مسح تعديلات الترجمة السابقة.
- أي محتوى شرعي يخضع لـ `docs/TALIA_ISLAMIC_CONTENT_SOURCES_POLICY.md`: المصدر المحدد، الحقوق، الإصدار، المراجعة، والتحقق من العرض. لا توليد نص قرآن أو تفسير منشور وقت التشغيل.
- كل ميزة قابلة للتعطيل مستقلًا. تعطيلها يمنع التشغيل الجديد ويعود للتجربة الحالية، ولا يحذف بياناتها أو يدعي التراجع عن ترحيل قاعدة البيانات.
- الحساب + audience + هوية الطفل حدود مستقلة. التقط نطاق العملية عند بدايتها، وألغِ/تجاهل نتائجها عند تغيره؛ لا تكتب نتيجة قديمة باسم المالك الجديد.
- استخدم `lib/core/identity/account_data_barrier.dart` وleases/generations القائمة عند الكتابة، وسجّل كل مفتاح/ملف جديد ضمن سياسة `lib/core/identity/account_data_reset.dart` واختبار `test/core/identity/account_data_reset_test.dart`؛ ownerId وحده لا يثبت صلاحية اختيار طفل بعيد.
- تجميد حجم البيت بعد أول مكافأة canonical جزء من التاريخ القائم؛ لا تعيد تقسيم بيوت مكتملة عند تغير العمر أو القدرة. إثبات المراجعة والمكافأة لهما حدان منفصلان للحفظ، ولا تصف العملية كلها بأنها معاملة ذرية واحدة.
- أول إصدار محلي عندما يمكن ذلك؛ إضافة حقول سحابية تحتاج عقدًا بإصدار، توافق عميل قديم، واختبارات صلاحيات في بيئة اختبار معروفة. لا تعديل production ضمن تنفيذ محلي.
- لا ضمان مطلق بمنع كل الأخطاء؛ معيار الإطلاق هو اجتياز بوابات معلنة وتوثيق ما لم يُتحقق منه.

## 4. Review Focus — أكثر حالات الفشل أهمية

1. تبديل الحساب/الطفل أو فك الربط أثناء عملية async: لا تسرب ولا كتابة/تشغيل لنتيجة قديمة. يملك اختبارات الأساس T0 وتكرر عند كل تخزين/صوت جديد.
2. إنهاء الجلسة مرتين أو إغلاق التطبيق بين الحفظ والمكافأة: لا فقد أو تكرار تقدم. T2/T4/T8 يثبتون عدم إنشاء مسار إنهاء جديد.
3. تشغيل إرشاد أثناء التلاوة أو بدء الميكروفون: صوت واحد، وإلغاء callbacks المتأخرة. T6/T8/T11/T12.
4. غياب المحتوى/انقطاع الإنترنت/امتلاء التخزين: تظل الرحلة الحالية متاحة ولا نجاح وهمي للتنزيل. T5/T9/T11/T12.
5. ترقية مستخدم قديم ثم تعطيل ميزة أو العودة لعميل أقدم: قراءة متوافقة دون إسقاط الحقول/الإنجازات الجديدة. T0/T2/T7/T12.

## 5. دورة تنفيذ واختبار موحدة

هذه الخطوات جزء من **كل مهمة** أدناه، ويستبدل المنفذ `<test-file>` و`<affected-paths>` بالمسارات المحددة في المهمة.

- [ ] أعد قراءة الملفات المستهدفة وفرق العمل؛ تحقق أن الميزة لم تُنفذ منذ كتابة الخطة.
- [ ] أضف الاختبارات المسماة في المهمة، ثم شغّل `flutter test <test-file>` وتأكد أن الفشل متعلق بالسلوك الجديد، لا خلل البيئة.
- [ ] نفّذ أقل تغيير خلف مفتاح المهمة، وسجّل التسجيلات الجديدة في `lib/core/di/injection.dart`؛ عدّل router فقط إن احتاجت الميزة مسارًا جديدًا، مع اختبارات الحراسة.
- [ ] شغّل الاختبارات الجديدة واختبارات الجوار المحددة، و`flutter analyze <affected-paths>`، و`dart format --output=none --set-exit-if-changed <changed-dart-files>`.
- [ ] نفّذ سيناريوهات الجهاز التي تمسها المهمة وسجّل الجهاز/البناء/النتيجة؛ اختبار host لا يعوض اختبار الصوت/الصلاحيات على Android.
- [ ] راجع التغيير وحدوده ومحتواه، ثم أنشئ commit خاصًا بالمهمة. لا تنتقل إلى إطلاق المرحلة مع فشل غير مفسر.

## 6. المهام التنفيذية

جميع أسماء الملفات والواجهات التالية الموسومة «جديد» اقتراحات تنفيذ، وليست رموزًا موجودة. المسارات النسبية في هذا القسم تبدأ بـ `lib/features/memorization_plus/` أو `test/features/memorization_plus/` بحسب العمود.

### T0 — إثبات الأساس وحدود الإطلاق

> **مراجعة 2026-10-12:** نسخة مخففة — مفاتيح بنمط `KidsHifzFeatureFlags` وbaseline فقط؛ لا `KidsFeatureScope` ولا ترحيل هوية (انظر القسم 0، البندين 4–5).
>
> **حالة التنفيذ (2026-10-12، غير مثبت في git):** نُفذ `lib/core/memorization/kids_enrichment_feature_flags.dart` + اختباره (6/6) + تسجيل DI. baseline G0 على شجرة العمل الحالية: analyze بلا مشاكل، وكل حزم G0 ناجحة (memorization_plus 1235، core/memorization 392، router 51، kids_quran_reader 25، house_review_gate 14، account_switch 2، progress_snapshot 2، account_data_reset 15). لا تُشغّل بوابات الجهاز لأن T0 لا يغيّر سلوكًا ظاهرًا.

**الناتج:** تقرير baseline ومفاتيح مستقلة تعمل افتراضيًا بوضع الإيقاف، وعقد موثق لهوية البيانات الجديدة.

**ملفات:** قراءة `lib/core/identity/record_owner_provider.dart`، `domain/entities/child_identity_policy.dart`، `memorization_profile.dart`، stores الطفل و`lib/core/memorization/kids_hifz_feature_flags.dart`. جديد: `domain/entities/kids_enrichment_flags.dart`، `domain/entities/kids_feature_scope.dart` واختبارا `domain/kids_enrichment_flags_test.dart` و`domain/kids_feature_scope_test.dart` عند التنفيذ. لا تضف كيان نطاق مكررًا إذا كشف الفحص نوعًا قائمًا مناسبًا.

**العقد المقترح:** `KidsEnrichmentFeature` بقيم منفصلة للـ12 ميزة، و`bool isEnabled(KidsEnrichmentFeature feature)` في مزود flags؛ الغائب/الفاسد = false. `KidsFeatureScope` يحمل ownerId + audience + childKey ثابتًا مثبت المصدر. لا اسم الطفل ولا عمره مفتاح هوية.

- [ ] شغّل baseline المحدد بالقسم 7 وسجل failures السابقة منفصلة، دون إصلاحات خارج النطاق.
- [ ] اختبر `missingFlagIsOff`، `disablingOneFeatureDoesNotDisableKidsPath`، `lateResultAfterOwnerChangeIsDiscarded`، `sameOwnerDifferentChildIsIsolated`.
- [ ] تتبع إعادة اختيار الطفل/reset وربط الحساب ودمج local→signed-in. إن لم توجد هوية طفل مستقرة مناسبة، اكتب ترحيلًا منفصلًا مُراجعًا قبل أي تخزين جديد شخصي؛ لا تستنتجها من الاسم ولا تعممها على سجلات الحفظ القائمة.
- [ ] حدد ownership/cleanup لكل مفتاح وملف جديد. افتح Isar عبر `openAppIsar/appIsarSchemas` كاملًا فقط إذا احتاجت المهمة قاعدة البيانات.
- [ ] اختبر المفاتيح مغلقة: الرئيسية والخريطة والحفظ والمصحف والأسرة تعمل بالسلوك السابق.

**بوابة:** لا تبدأ تخزين بيانات شخصية جديدة قبل اجتياز اختبارات العزل. يمكن إعداد محتوى عام ومكونات عرض مستقلة أثناء ذلك.

### T0-A — تنسيق الصوت والميكروفون قبل إضافات الصوت

> **مؤجل (2026-10-12):** لا يُنفذ طالما T6/T11/T12 مؤجلة.

**التوقيت:** تنفذ بعد A وقبل تفعيل أي صوت جديد في T5/T6، ويعيد استخدامها T8/T9/T11/T12. يمكن عرض درس T5 نصيًا قبلها إذا استوفى الاعتماد.

**سبب الفصل:** `AudioLifecycleManager` يدير AudioPlayer ولا يملك الميكروفون/STT. مجرد تسجيل player جديد لا يمنع الإرشاد من دخول التسميع أو إنتاج نتيجة كاذبة.

**ملفات:** جديد `domain/services/kids_audio_activity_coordinator.dart` و`domain/entities/kids_audio_activity_lease.dart`؛ تمديد نقاط بدء/إيقاف الصوت والتسجيل في `KidsModeCubit`، وعقود قارئ الأطفال عند الانتقال. اختبارات جديدة `domain/kids_audio_activity_coordinator_test.dart` وجوار `test/core/services/audio_lifecycle_manager_test.dart` و`presentation/cubits/kids_speech_recitation_recorder_test.dart`.

**واجهة مقترحة:** `Future<KidsAudioActivityLease?> acquire({required KidsAudioActivity activity, required KidsFeatureScope scope, required Future<void> Function() stop})`، و`Future<void> release(KidsAudioActivityLease lease)`، و`Future<void> cancelAll()`؛ lease يحتوي operation token ويتيح `bool get isCurrent` للتحقق قبل تنفيذ callback. الأنشطة: quranPlayback/lessonAudio/guidance/recognition/portfolioCapture.

- [ ] اختبر start-recognition أثناء guidance: انتظار إيقاف الإرشاد ثم فتح الميكروفون، وصفر تداخل. طلب guidance أثناء recognition يرفض ولا يقاطع الطفل.
- [ ] اختبر طلبين متزامنين وrelease قديم وstop فاشل: لا تمنح lease جديدًا قبل تأكيد توقف السابق؛ أظهر حالة قابلة لإعادة المحاولة دون نجاح وهمي.
- [ ] قبل بدء أي تسجيل أوقف playback النشط على سطح الأطفال، وقبل أي playback امنع التقاطًا قائمًا أو ألغِه بفعل صريح. لا تسمح بالعودة التلقائية لتشغيل كلام قديم بعد انتهاء التسميع.
- [ ] اختبر navigation/background/مكالمة/فصل سماعة/revoke permission/account switch؛ callback ذو token قديم لا يشغل صوتًا ولا يقيم محاولة. اختبر أثر التنسيق على صوت البالغ في الخلفية ولا تغير سياسته العالمية.
- [ ] اربط coordinator بالمكونات الحالية عبر adapters محدودة، دون نقل تقييم الجلسة أو حفظها إليه. لا تضف listener عالميًا ثانيًا يؤدي إلى استدعاءات إيقاف متضاربة.

**قبول:** نشاط صوتي واحد في كل لحظة على سطح الأطفال، مع إلغاء آمن؛ نجاح mocks يتبعه اختبار جهاز للتداخل والمقاطعات.

### T1 — قوالب «أعيش ما أتعلم»

> **قرار المالك 2026-10-12:** قوالب تربوية فقط، بلا نسبة دينية؛ حقل المصدر غير مطلوب. أضف قفل إرسال ضد النقر المزدوج (القسم 0، البند 2).
>
> **حالة التنفيذ (2026-10-13، غير مثبت في git):** نُفذ خلف مفتاح `homeMissionTemplates` (مغلق افتراضيًا). الحوار الحالي كان يحمل أصلًا 4 اقتراحات غير دينية، فصار يستقبل قائمة قوالب: عند إغلاق المفتاح تبقى الأربعة كما هي، وعند فتحه تُعرض قوالب حسب فئة عمر الطفل (6 قوالب: ثلاثة مشتركة + «شارك لعبتك» لـ5–7 + «جهّز حقيبتك» لـ8–12 + «احكِ ما تعلمته» للفئتين). لا تغيير في الـ RPC أو التخزين. أُضيف قفل ضد الإرسال المكرر في `FamilyDashboardCubit.addHomeMission` ومنع `Navigator.pop` المزدوج في الحوار. الملفات: `domain/services/kids_home_mission_templates.dart` وتعديل `home_missions_panel.dart` و`child_detail_page.dart`. اختبارات: 4 للكتالوج، و5 للّوحة، و1 للـ cubit، وشغّلت اختبارات صفحة الطفل (12) والـ cubit كاملة. لم تُجرَّب على جهاز.

**يعتمد على:** T0؛ اعتماد أي إسناد شرعي قبل عرضه.

**ملفات:** جديد `domain/services/kids_home_mission_templates.dart`، `presentation/widgets/home_mission_template_picker.dart`؛ تمديد `presentation/widgets/home_missions_panel.dart`. اختبار جديد `domain/kids_home_mission_templates_test.dart`، وتمديد `data/kids_home_missions_local_test.dart` و`data/kids_home_mission_child_sync_test.dart`.

**واجهة:** `List<KidsHomeMissionTemplate> templatesFor(KidsAgeBand ageBand)`؛ قالب يحتوي ID وعناوين localization ومصدرًا عند وجود نسبة دينية. الاختيار يملأ نموذج المهمة الحالي، ثم يمر بإنشاء المهمة الحالي؛ لا reward تلقائيًا.

- [ ] اختبر اختيار القالب ثم تعديل العنوان، وتكرار النقر/إعادة المحاولة دون إنشاء مهمتين، وتعطيل homeMissionsEnabled، وفك الربط أثناء الإرسال.
- [ ] أضف 6 قوالب تربوية أولية موزعة على العمرين؛ لا تُحمّل الطفل مهامًا لم يخترها ولي الأمر.
- [ ] احفظ الحالات الحالية assigned/reported/acknowledged، واختبر بقاء المهمة بعد إعادة التشغيل وظهورها بعد المزامنة، وعدم تكرار المكافأة.

**قبول:** يستطيع ولي الأمر إرسال قالب وتعديله، ويستخدم الطفل نفس مسار الإبلاغ الحالي.

### T2 — إنجازات الجهد والمراجعة

> **شرط مسبق (2026-10-12):** أصلح `KidsAchievementStore.sync` ليحفظ IDs المخزنة غير المعروفة قبل إضافة أي إنجاز (القسم 0، البند 1). **أُنجز (2026-10-13).**
>
> **حالة التنفيذ (2026-10-13، غير مثبت في git):** نُفذ خلف مفتاح `effortAchievements` (مغلق افتراضيًا). ثلاثة إنجازات جديدة تُلحَق بنهاية `KidsAchievementId`: `firstReview` (مراجعة مكتملة) و`triedAgain` (نجاح بعد أكثر من محاولة) و`comeback` (عودة بعد ٣ أيام محلية فأكثر عبر `kidsIsReturningAfterBreak`). تُحسب بدالة pure `buildKidsEffortInputs(logs)` في `domain/services/kids_effort_achievement_inputs.dart` من `KidsSessionLog` فقط، بلا تكرار عند تكرار الـ id. `KidsAchievementCatalog.specs` لم يتغير، والجديدة في `effortSpecs` ولا تُقيَّم ولا تُعرض إلا إذا كان `KidsAchievementInputs.effort` غير null. لا تغيير في النقاط أو النجوم أو الشهادات أو التخزين. عرض ولي الأمر: يعرض فقط ما أبلغ به جهاز الطفل، بشرط تفعيل المفتاح على جهاز الأب. «إنجاز الأسرة» ما زال ينتظر T4. ملاحظة: كل السجلات المحفوظة اليوم تأتي من `awardKidsPoints` (نجاح مثبت)؛ `SaveKidsSessionLogUsecase` مسجَّل ولا يُستدعى، فلا يوجد «حدث تقني» يُستبعد. تمت مراجعة اختبارات memorization_plus كاملة (1277 ناجحًا) وanalyze نظيف؛ لم تُجرَّب على جهاز.

**ملفات:** تمديد `domain/services/kids_achievements.dart`، `data/datasources/kids_achievement_store.dart`، `domain/services/kids_progress_snapshot.dart`، `presentation/widgets/kids_achievement_labels.dart`. جديد `domain/services/kids_effort_achievement_inputs.dart`. اختبارات `domain/kids_achievements_test.dart` و`data/kids_achievement_store_test.dart` و`domain/kids_effort_achievement_inputs_test.dart` الجديد.

**واجهة:** دالة pure `KidsEffortAchievementInputs buildKidsEffortInputs(List<KidsSessionLog> logs)` من سجلات الطفل المحفوظة فقط. الإصدار الأول: أول مراجعة مكتملة، ونجاح بعد أكثر من محاولة. إنجاز العودة بعد انقطاع يستند لتواريخ محفوظة ومنطق `kids_return_policy.dart`. إنجاز الأسرة ينتظر إثبات T4.

- [ ] اختبر أن المحاولة الفاشلة وحدها لا تفتح إنجاز إتمام، وأن إعادة قراءة السجل/retry/cloud merge لا تعيد الاحتفال أو المنح.
- [ ] لا تستخدم pointsEarned>0 وحده لعد المراجعات؛ طابق دلالة السجل الناجح الحالي. اختبر مراجعة ناجحة بنقاط صفر، واستبعد الحدث التقني.
- [ ] اختبر قراءة مخزن قديم، والحفاظ على IDs غير المعروفة أثناء sync وعدم إسقاطها عند إضافة إنجاز جديد. إن منع الكاتب الحالي حفظ مفاتيح المستقبل، أصلح التوافق قبل إطلاق الإنجازات الجديدة.
- [ ] لا تغير رصيد النجوم أو شروط الشهادة. غياب بيانات remote اللازمة يظهر «غير متاح» ولا إنجازًا مستنتجًا.

**قبول:** يرى الطفل تقديرًا مثبتًا لجهده دون أي تغيير في أعداد الحفظ أو رصيد المكافآت القديم.

### T3 — ملخص أسبوعي للأهل

> **نطاق الإصدار الأول (2026-10-12):** الطفل المحلي فقط؛ الطفل البعيد يعرض «غير متاح» حتى تُضاف مفاتيح snapshot اختيارية (القسم 0، البند 3).
>
> **حالة التنفيذ (2026-10-13، غير مثبت في git):** نُفذ خلف مفتاح `weeklyCoaching` (مغلق افتراضيًا). `buildKidsWeeklyCoaching({logs, now, historyComplete})` في `domain/services/kids_weekly_coaching.dart`: نافذة ٧ أيام تقويمية محلية تشمل اليوم، تكرار الـ id يُحسب مرة، وثلاث حالات (`incompleteHistory` / `noHistory` / `ready`)، ونصيحة واحدة من كتالوج ثابت من ٥ (استماع مشترك إذا ظهر تلميح في نصف الجلسات فأكثر مع جلستين على الأقل، ثم مدح المحاولة، ثم الحفاظ على الإيقاع، ثم إضافة مراجعة، وإلا بداية صغيرة بلا لغة فقدان). `historyComplete` تكون true فقط للطفل المحلي (`child.isLocal && localData != null`)؛ الطفل المرتبط يعرض «غير متاح» ولا يُحكم عليه من سجلات قد تكون ناقصة. لا إشعارات ولا رسائل تلقائية. الواجهة: `KidsWeeklyCoachingCard` داخل `_Panel` في `child_detail_page.dart`. اختبارات: ١٥ للخدمة (حدود النافذة عند منتصف الليل، التكرار، الحالات، أولوية النصائح)، و٤ للبطاقة (منها العربية على ٣٢٠px)، و٣ على مستوى الصفحة (مغلق/محلي بلا جلسات/مرتبط). analyze نظيف واختبارات memorization_plus كاملة (١٣٠٣) ناجحة؛ لم تُجرَّب على جهاز.

**ملفات:** جديد `domain/services/kids_weekly_coaching.dart`، `presentation/widgets/kids_weekly_coaching_card.dart`؛ تمديد `presentation/pages/child_detail_page.dart`. جديد `domain/kids_weekly_coaching_test.dart` و`presentation/widgets/kids_weekly_coaching_card_test.dart`.

**واجهة:** `KidsWeeklyCoaching buildKidsWeeklyCoaching({required List<KidsSessionLog> logs, required DateTime now, required bool historyComplete})`. النتيجة تتضمن الفترة، ملخص أدلة وتوصية من كتالوج ثابت؛ لا LLM ولا تشخيص نفسي.

- [ ] احسب 7 أيام تقويمية محلية تشمل اليوم؛ اختبر منتصف الليل وتغير timezone وحدود الفترة والبيانات المكررة.
- [ ] اختبر بيانات فارغة مقابل ناقصة، وتأكد أن قائمة recentActivity المحدودة إلى 5 عناصر في snapshot ليست تاريخ أسبوع كامل.
- [ ] اقرأ التاريخ عبر repository مخصص للقراءة. للطفل البعيد لا تفترض اكتمال logs؛ أضف عقد اكتمال من المصدر إن لزم، وإلا اعرض ملخصًا محدودًا بوضوح دون حكم أسبوعي.
- [ ] اختر توصية قابلة للتنفيذ من evidence صريح: كثرة استخدام تلميح → اقتراح استماع مشترك. لا ترسل notification أو بريدًا تلقائيًا في الإصدار الأول.

**قبول:** تظهر معلومة موثوقة وخطوة عملية واحدة، مع حالة واضحة إذا لم تكفِ البيانات.

### T4 — «نتعلم سوا»

**ملفات:** جديد `presentation/cubits/kids_family_practice_cubit.dart`، `presentation/widgets/kids_family_practice_panel.dart`، `domain/entities/kids_family_practice_receipt.dart` وrepository/use case له إذا لزم حفظ إثبات المشاركة. تمديد صفحة الجلسة ولوحة ولي الأمر دون زر إنهاء جديد للحفظ. اختبارات جديدة `presentation/cubits/kids_family_practice_cubit_test.dart` و`presentation/widgets/kids_family_practice_panel_test.dart`، وجوار `presentation/cubits/kids_mode_cubit_test.dart`.

**واجهة:** الإرشاد يستقبل سياق المهمة الحالي؛ `begin()` و`advance()` و`cancel()` يديرون خطوات المشاركة فقط. إثبات المشاركة `recordFamilyPractice(receipt)` منفصل ومكرر التنفيذ بأمان، لا يستدعي awardKidsPoints أو committer.

- [ ] اختبر استكمال الخطوات وإلغاءها وإغلاق التطبيق، وعدم إتمام آية أو منح شهادة لمجرد إنهاء الإرشاد.
- [ ] استعمل verifier/PIN الحالي لإثبات فعل ولي الأمر عند تسجيل المشاركة؛ لا تدّعِ أن طفلًا بعيدًا شارك بناء على اختيار محلي في جهاز الأب.
- [ ] اختبر المسار اليدوي الحالي: double tap، PIN غير صحيح، PIN غير متاح، وتبديل الحساب أثناء التحقق.
- [ ] أضف إنجاز المشاركة في T2 فقط عند توفر receipt موثوق؛ لا تجعل المشاركة شرطًا لتقدم طفل يتعلم وحده.

**قبول:** يمكن إنهاء الإرشاد الأسري والخروج منه دون تعطيل أو تجاوز جلسة الحفظ الحالية.

### T5 — «أفهم ما أحفظ»

> **محجوب (2026-10-12):** لا مصدر معاني مرخص بعد؛ لا تستورد بيانات قبل دليل الترخيص.

**ملفات:** جديد `domain/entities/kids_learning_lesson.dart`، `domain/repositories/kids_learning_content_repository.dart`، `domain/usecases/get_kids_learning_lesson.dart`، `data/datasources/kids_learning_content_local_source.dart`، `presentation/cubits/kids_learning_lesson_cubit.dart`، `presentation/widgets/kids_learning_lesson_panel.dart`. محتوى جديد تحت `assets/data/kids_learning/` بعد الاعتماد، وتحديث assets في `pubspec.yaml` عند الحاجة. اختبارات جديدة `domain/kids_learning_content_contract_test.dart` و`presentation/widgets/kids_learning_lesson_panel_test.dart` و`test/assets/kids_learning_content_integrity_test.dart`.

**واجهة:** `Future<KidsLearningLesson?> getApprovedLesson({required int surahId, required int ayahNumber, required KidsAgeBand ageBand, required String locale})`. الدرس يحمل ID/version/source/review/license واللغة والعمر ومراجع الآيات دون نسخة بديلة لنصها. null = إخفاء الإضافة وترك الرحلة متاحة.

- [ ] جهز 3 دروس قصيرة مع نسختين عمريتين ومراجعة النص والصوت والسؤال والجواب؛ لا تنشر عناصر draft/blocked أو ترجمة غير مراجعة.
- [ ] اختبر invalid ayah/source/version، لغة غير متاحة، ملف تالف، وصوت مفقود؛ fallback نصي معتمد أو إخفاء الدرس، دون crash.
- [ ] اعرض الدرس بعد تثبيت نتيجة الجلسة أو باختيار مستقل؛ لا تضف phase لمحرك الحفظ ولا تشترط إجابة صحيحة لاحتساب الحفظ.
- [ ] افصل تتبع إكمال الدرس في repository تعليمي جديد بهوية owner/child/content/version إن احتاج T10؛ لا تكتب في سجلات الحفظ.
- [ ] اختبر النص القرآني من مصدره الحالي حرفيًا، وتمييز عنوان «شرح المعنى» عن الآية، وRTL/تكبير النص.

**قبول:** المحتوى معتمد وله مصدر وحقوق، والطفل يستطيع تخطيه، وفشل التحميل لا يمس نتيجة الحفظ المحفوظة.

### T6 — التعليمات المسموعة لغير القارئ

> **مؤجل بقرار المالك (2026-10-12).** يبقى مفتاح `guidanceAudioEnabled` مخفيًا.

**ملفات:** جديد `domain/services/kids_guidance_catalog.dart`، `presentation/cubits/kids_guidance_audio_cubit.dart`، `presentation/widgets/kids_spoken_instruction_button.dart`؛ تمديد صفحة الجلسة والإعداد و`presentation/world/kids_policy_controller.dart` فقط حسب المسؤولية. ملفات صوت جديدة تحت `assets/audio/kids_guidance/` بعد اعتمادها. اختبارات جديدة `presentation/cubits/kids_guidance_audio_cubit_test.dart` و`presentation/widgets/kids_spoken_instruction_button_test.dart`.

**واجهة:** `Future<void> play(KidsGuidanceCue cue)` و`Future<void> stop()`؛ cue من كتالوج ثابت للواجهة. لا تسجيل ميكروفون أو نطق آيات اصطناعي. استهلاك guidanceAudioEnabled فعليًا قبل إظهار مفتاحه.

- [ ] اختبر أن التلاوة والتسجيل يوقفان الإرشاد، وأن الرجوع/background/dispose/تبديل الطفل يمنع أي تشغيل متأخر.
- [ ] لا توقف تلاوة البالغ في الخلفية عالميًا؛ تحقق من سياسة AudioLifecycleManager الحالية وأضف تنسيقًا محدودًا لسطح الأطفال إذا لم تكفِ APIs القائمة.
- [ ] اختبر missing clip والإيقاف المتكرر وعدم إعادة الإرشاد عند كل rebuild، واحترام اختيار ولي الأمر بدل الكتابة فوقه بتغير العمر.
- [ ] أضف labels/semantics وتعليمات مرئية مكافئة؛ اجمع اختبار TalkBack ونص كبير وشاشة ضيقة على الجهاز.

**قبول:** الإعداد يعمل فعلًا، ولا يتداخل صوت الإرشاد مع القرآن أو التسميع، وتظل الأزرار المرئية كافية.

### T7 — تخصيص القدرة والمساندة

**ملفات:** جديد `domain/entities/kids_learning_support_profile.dart`، `domain/services/kids_support_policy.dart` وrepository/use case للإعداد ذي نطاق الطفل؛ تمديد إعداد الطفل ولوحة الأهل، وحقن policy في `KidsModeCubit` عند حدود جلسة جديدة فقط. اختبارات جديدة `domain/kids_support_policy_test.dart` وجوار `domain/kids_session_policy_test.dart` و`data/kids_policy_snapshot_test.dart` و`data/kids_child_policy_sync_test.dart`.

**واجهة:** `KidsSupportPolicy resolveKidsSupportPolicy({required KidsSessionPolicy agePolicy, required KidsLearningSupportProfile profile, required List<KidsSessionLog> history})`. مجهول القدرة = السلوك الحالي. الإعداد الأولي ثلاث إجابات لولي الأمر: القراءة مستقلة/بمساعدة/لا يقرأ؛ تفضيل المساندة؛ سور يعرفها للتوجيه فقط.

- [ ] اختبر أن أي profile لا يزيد maxNewAyahs/maxDueReviews/maxSessionMinutes ولا يفتح مراحل أو يغير معرّفاتها. السور المعروفة لا تتحول لحفظ مثبت دون مسار تقييم معتمد منفصل.
- [ ] عدّل عرض المساعدة تدريجيًا؛ لا تخفض عدد الاستماعات المطلوب في النسخة الأولى ولا عتبة STT ولا تصنيف mastery.
- [ ] ثبّت policy داخل session snapshot؛ تغيير ولي الأمر لا يقلب جلسة قائمة في منتصف التسميع. اختبر استكمال جلسة قديمة بلا حقول جديدة.
- [ ] احفظ إعدادات جديدة versioned وبقيم افتراضية. إن أضيفت للسحابة: migration إضافي + CAS + old-client compatibility قبل تشغيلها على الطفل المرتبط.

**قبول:** المساندة تتغير بوضوح، وحدود العمر والمحرك والتقدم تظل متوافقة.

### T8 — المساعدة المحددة بعد التعثر

**ملفات:** جديد `domain/services/kids_support_action_resolver.dart`؛ تمديد `KidsModeCubit` وصفحة الجلسة بأصغر patch. اختبارات جديدة `domain/kids_support_action_resolver_test.dart` وجوار `presentation/cubits/kids_mode_cubit_test.dart` و`presentation/pages/kids_gamified_listen_page_test.dart` و`domain/kids_recalled_words_test.dart`.

**واجهة:** `KidsSupportAction resolveKidsSupportAction(KidsSupportContext context)`؛ النسخة الأولى تعيد listenAgain/firstWord/guardianHelp بحسب phase ونتيجة المحاولة. تستدعي `remindMe/revealFirstWord` القائمة بعد الانتقال الصحيح، ولا تكشف تلميحًا أثناء التسجيل.

- [ ] اختبر التعثر مقابل technicalUnavailable/الصمت/رفض الإذن، فلا تتحول المشكلة التقنية لعقوبة أو دليل ضعف.
- [ ] اختبر اكتمال التلميح في سجل الاستخدام وتصنيف المراجعة، وعدم احتساب محاولة أو نقطة إضافية بسبب ضغط الدعم.
- [ ] اختبر النقر السريع والتنقل ونتيجة STT المتأخرة بعد إلغاء الجلسة، والمسار اليدوي وrestart بعد حفظ النتيجة.
- [ ] اختبر قتل العملية بعد commit المراجعة وقبل اكتمال reward projection ثم الاستئناف، مع المحافظة على sessionId/taskId وأعداد الآيات والنقاط. المرجع `test/core/memorization/v2/kids_review_outcome_committer_isar_test.dart` و`test/core/memorization/kids_progress_cloud_merge_test.dart`.
- [ ] أجّل تشغيل جزء كلمة/مقطع داخل الآية حتى توفر حدود صوتية موثقة ومتحقق منها؛ لا تقطع التسجيل عند زمن تقديري.

**قبول:** الطفل يعرف الخطوة التالية، ولا تنكسر قواعد hintsAllowed/textHidden أو ترتفع درجة الإتقان بسبب المساعدة.

### T9 — ألعاب تعليمية قصيرة

> **نطاق 2026-10-12:** `listenAndChooseSurah` فقط؛ `chooseMeaning` ينتظر T5.

**ملفات:** جديد `domain/entities/kids_learning_game.dart`، `domain/services/kids_learning_game_evaluator.dart`، `presentation/cubits/kids_learning_game_cubit.dart`، `presentation/pages/kids_learning_game_page.dart`؛ تمديد مستودع المحتوى T5 ومسارات محروسة. اختبارات جديدة `domain/kids_learning_game_evaluator_test.dart` و`presentation/pages/kids_learning_game_page_test.dart` واختبارات route في `test/core/router/`.

**واجهة:** `KidsGameResult evaluateKidsGameAnswer({required KidsLearningGame game, required String optionId})`. أنواع البداية listenAndChooseSurah/chooseMeaning، وجولة لا تتجاوز 3 أسئلة؛ answers من محتوى معتمد محدد الإصدار.

- [ ] اختبر خيارًا غير معروف، وغياب التلاوة، وإجابة متكررة، وإلغاء الجولة، ومدخل route لسورة غير متاحة أو مستخدم بالغ.
- [ ] لا ترتب الكلمات القرآنية ولا تعرض distractor كنص آية؛ لا تنشر سؤالًا بمعنى غير معتمد.
- [ ] سجّل إكمال الجولة كتعلم مستقل؛ لا تمنح حفظًا أو شهادة أو نقاط المحرك. يمكن عرض تشجيع مرئي منفصل.

**قبول:** النشاط اختياري، يمكن تخطيه، ولا يعدل تقدم الرحلة أو ميزانية الحفظ.

### T10 — تطور العالم

**ملفات:** جديد `domain/services/kids_world_growth_snapshot.dart`؛ تمديد `presentation/world/kids_world_scene.dart` ومكونات الخريطة والاحتفال فقط. اختبارات جديدة `domain/kids_world_growth_snapshot_test.dart` وجوار `presentation/world/kids_world_scene_test.dart` و`domain/kids_map_celebration_test.dart`.

**واجهة:** `KidsWorldGrowthSnapshot buildKidsWorldGrowthSnapshot(KidsWorldGrowthEvidence evidence)`؛ يستهلك إنجازات T2 وإكمال دروس T5/أنشطة T9 وإثبات T4. كل مصدر اختياري؛ لا يعتمد تشغيل العالم على تفعيل جميع الميزات.

- [ ] اختبر أن الغياب/تغير الساعة/غياب بيانات cloud لا يمحو المناطق القديمة، وأن إعادة قراءة نفس evidence لا تكرر الاحتفال.
- [ ] حافظ على ترتيب `KidsJourneyPath` وخمس مناطق `kids_adventure_regions.dart`؛ الزينة لا تفتح سورة مقفلة.
- [ ] اختبر تقليل الحركة وRTL والتكبير وGolden عند الحالات الجديدة. قس scrolling/frame performance على جهاز متوسط وقارن baseline، لا تدّعِ تحسنًا دون قياس.

**قبول:** العالم يعكس دليلًا محفوظًا دون تغييره؛ تعطيله يعيد الرسوم الحالية فقط.

### T11 — الحقيبة الأسبوعية دون اتصال

> **مؤجل بقرار المالك (2026-10-12).**

**ملفات:** جديد `domain/entities/kids_weekly_pack.dart`، `domain/repositories/kids_weekly_pack_repository.dart`، `domain/usecases/download_kids_weekly_pack.dart`، `data/repositories/kids_weekly_pack_repository_impl.dart`، `data/datasources/kids_weekly_pack_store.dart`، `presentation/cubits/kids_weekly_pack_cubit.dart` وwidget إدارة التنزيل. إعادة استخدام `AudioCacheService` ومصادر التلاوة بعد التحقق من فصل الاحتفاظ الدائم عن الكاش العام. اختبارات جديدة `data/kids_weekly_pack_repository_test.dart` و`presentation/cubits/kids_weekly_pack_cubit_test.dart`.

**واجهة:** `Future<KidsWeeklyPackStatus> download(KidsWeeklyPackManifest manifest)`، `Future<KidsWeeklyPackStatus> inspect(String packId)`، `Future<void> remove(String packId)`. Manifest يحدد content/version/locale/reciter/riwayah/ayah references والملفات وأحجامها وبصماتها المعتمدة.

- [ ] قرر storage ownership: manifest والتخصيص بنطاق الطفل، ويمكن مشاركة ملف تلاوة عام فقط عبر catalog immutable وreference counting؛ لا ملفات صوت أطفال في الكاش العام.
- [ ] تنزيل إلى ملفات مؤقتة، تحقق لكل ملف، ثم نشر manifest مكتمل ذريًا؛ pending/partial/failed لا تُعرض ready. استئناف متكرر آمن مع حصر التوازي ومهلة وإلغاء.
- [ ] اختبر انقطاع الشبكة/kill التطبيق/قلة المساحة/ملف تالف/تغير القارئ/تحديث المحتوى/تبديل الحساب أثناء التنزيل، ومنع path traversal في أسماء الملفات.
- [ ] اختبر حذف حقيبة دون حذف ملف تحتاجه حقيبة أخرى، وعدم مسح الحقيبة بواسطة سياسة إخلاء الكاش العادي؛ إن لم يتوفر pinning مضمون استخدم store خاصًا بالحقائب.
- [ ] airplane mode على جهاز: كل مورد موسوم جاهز يعمل. فشل STT ينتقل للمسار اليدوي الحالي مع حماية ولي الأمر؛ لا وعد أن التعرف على الكلام يعمل offline على كل جهاز.

**قبول:** ready تعني أن كل الموارد المطلوبة موجودة وصالحة ويمكن تشغيلها دون شبكة؛ حذف التنزيل لا يحذف حفظ الطفل.

### T12 — سجل التلاوة الشخصي

> **مؤجل بقرار المالك (2026-10-12).** المفتاح يبقى مغلقًا ولا يُبدأ أي التقاط صوت.

**بوابة مستقلة قبل التنفيذ:** T0 أثبت stable child scope؛ مراجعة خصوصية وموافقة ولي الأمر وحذف/احتفاظ؛ التحقيق في التقاط bytes لأن recorder الحالي مخصص للتعرف على الكلام وليس مستودع تسجيلات. لا تستنتج أن transcript أو نجاح STT يعني وجود ملف صوت.

**ملفات مقترحة بعد قرار الالتقاط:** جديد `domain/entities/kids_recitation_sample.dart`، `domain/repositories/kids_recitation_portfolio_repository.dart`، use cases capture/list/delete، `data/datasources/kids_recitation_portfolio_store.dart`، `presentation/cubits/kids_recitation_portfolio_cubit.dart` وواجهة خلف ولي الأمر. اختبارات جديدة `data/kids_recitation_portfolio_store_test.dart` و`presentation/cubits/kids_recitation_portfolio_cubit_test.dart`، واختبار جهاز للتسجيل/الحذف.

**واجهة:** `capture(scope, ayahReference, consentVersion)` و`list(scope)` و`delete(scope, sampleId)` و`deleteAll(scope)`؛ scope لا يؤخذ من query parameter وحده. محلي فقط، بلا رفع/مشاركة/تحليلات صوتية أو مزامنة تلقائية.

- [ ] نسخة أولى: حد 5 عينات × 60 ثانية لكل طفل، مع حد حجم محسوب قبل الكتابة. بلوغ الحد يطلب حذفًا صريحًا، ولا يحذف عينة قديمة تلقائيًا.
- [ ] موافقة مخصصة لحفظ الصوت قابلة للسحب خلف PIN؛ موافقة STT الحالية ليست موافقة تخزين. سحبها يوقف الالتقاط ويتيح الحذف ويشرح ما يُحذف؛ اختبار عدم استمرار التسجيل بالخلفية.
- [ ] اختبر رفض/سحب الإذن، مقاطعة مكالمة، امتلاء التخزين، فشل الحفظ بعد التسجيل، account switch، app restart أثناء ملف مؤقت، وحذف طفل/reset/logout حسب سياسة retention المعتمدة.
- [ ] الملفات خاصة بالتطبيق خارج logs والكاش العام؛ لا أسماء أطفال في المسار. راجع Android backup وقواعد النقل/النسخ الاحتياطي حتى لا تُرفع التسجيلات ضمن نسخ تلقائي غير مقصود.
- [ ] لا تكتب أو تعدل نتيجة الحفظ بناء على حفظ العينة أو سماعها؛ العينات للذاكرة الشخصية وليست شهادة تجويد.

**قبول:** ولي الأمر وحده يدير السجل والموافقة، والعزل والحذف مثبتان على جهاز. يبقى المفتاح مغلقًا إذا لم تُحسم هوية الطفل أو سياسة الخصوصية أو الالتقاط.

## 7. بوابات عدم التراجع

### G0 — baseline قبل التنفيذ

شغّل وسجل كل أمر وexit code منفصلًا، مع revision وdirty diff، ولا تستخدم failures تاريخية كمبرر تلقائي لتجاهل failure جديد:

```text
flutter analyze
flutter test test/features/memorization_plus
flutter test test/core/memorization
flutter test test/core/router
flutter test test/features/quran/kids_quran_reader_page_test.dart
flutter test test/integration/kids_house_review_gate_test.dart
flutter test test/integration/account_switch_isolation_test.dart
flutter test test/integration/progress_snapshot_consistency_test.dart
```

### G1 — كل مهمة

اختبارات unit/widget الجديدة + جوارها + تنسيق/تحليل الملفات المعدلة. أي تغيير في data/audio/session يحتاج اختبارات integration عند الحد المتأثر. لا تنفذ full suite بعد كل تعديل صغير بلا سبب؛ نفذها قبل إطلاق المرحلة.

### G2 — كل مرحلة

`flutter analyze` و`flutter test` كاملان. اختبار build Android ملائم؛ قبل مرشح إصدار نهائي `flutter build appbundle --release` مع تسجيل النتيجة. نجاح build لا يثبت تدفقًا أو صلاحية صوت.

مصفوفة الجهاز الضرورية: حساب محلي/مسجل، طفل محلي/مرتبط، 5–7/8–12، عربي RTL/إنجليزي LTR، light/dark، شاشة ضيقة/نص كبير/TalkBack، شبكة/انقطاع/airplane، صلاحية ميكروفون مرفوضة، background/عودة، restart، feature off/on. اختبر التوليفات التي تمسها المهمة وكل تدفق حرج أدناه، ولا تدّعِ اختبار كل الضرب الديكارتي دون سجل.

التدفقات الحرجة: حفظ جديد؛ due review؛ linked review/قفل البيت؛ استكمال جلسة؛ إتمام يدوي مع PIN؛ عدم تكرار reward؛ شهادة قديمة؛ مصحف→جلسة والرجوع؛ بقاء سياسة صوت البالغ؛ مهمة منزلية وربط/فك ربط؛ account switch مع async قيد التشغيل؛ تحديث تثبيت قديم ببيانات محفوظة.

### G3 — المحتوى والسحابة

قبل مادة دينية: source item/version + license evidence + review decision + canonical validation + عرض فعلي. قبل عقد سحابي: SQL/RLS/RPC على بيئة disposable/staging معلومة، account/child authorization وCAS وعميل قديم وoffline retry. الاختبارات المحلية لا تثبت حالة production، ولا تتطلب الخطة تشغيل أي شيء على production.

## 8. استراتيجية الترحيل والتراجع

- استخدم schemas/keys ذات إصدار وحقول اختيارية defaults تحفظ السلوك القديم. migrate عند الحاجة مرة واحدة مع checkpoint وفشل لا يمس الأصل. لا تعمل clear/reset لتجاوز خطأ parsing.
- اختبر old→new مع بيانات فعلية مجهولة الهوية/fixtures تغطي جلسة معلقة ونقاط وشهادات ومهام. اختبر client قديم أمام payload جديد؛ حافظ على unknown fields/IDs أو صرّح بعدم دعم downgrade وحدد بديلًا قبل الإطلاق.
- feature off ليست rollback لقاعدة البيانات؛ أوقف إنشاء البيانات الجديدة واتركها محفوظة قابلة للقراءة. إصلاح البيانات بخطة مخصصة فقط، لا حذف شامل.
- ترحيلات السحابة إضافية وقابلة للتوافق خلال نافذة الإصدار؛ لا drop/rename لعقد يستخدمه العميل القديم. عند فشل الإصدار عطّل الميزة الجديدة دون تعطيل الحفظ الحالي.
- أسرار أو raw transcripts أو أصوات أو أسماء أطفال لا تدخل السجلات. evidence الاختبارات يستخدم IDs اصطناعية.

## 9. الاعتماد والتنفيذ والمتابعة

ابدأ بإعداد محتوى T5 واعتماده، وبالتنفيذ البرمجي T0 ثم T1/T2/T3 ثم T4. بعد اكتمال A، نفذ T5 ثم T6 ثم T7 ثم T8. T9 يعتمد على T5، وT10 على مصادر evidence المفعلة فقط. T11 يعتمد على عقود المحتوى/الصوت، وT12 إطلاق مستقل اختياري لا يحجب باقي المشروع.

لا التزام زمني قبل قياس baseline وتوفر المحتوى المعتمد وقرار هوية الطفل. هذه العوامل قد تكون أطول من كتابة الواجهة. يتولى Terra مهام التنفيذ المحدودة؛ Sol يراجع تكامل كل مرحلة؛ يُطلب تحقيق Astra محدد عند المساس بمعاملة التقدم أو هوية البيانات أو lifecycle الصوت، دون إعادة مراجعة التطبيق كله.

**تعريف اكتمال المهمة:** الاختبارات ونتائج الجهاز المطلوبة مسجلة، والمحتوى معتمد عند الحاجة، وfeature off يعمل، وبيانات قديمة محفوظة، ولا failure جديد غير مفسر، والحدود غير المختبرة مكتوبة. لا يكفي وجود شاشة أو نجاح compile.

**قياس فائدة المنتج بعد الإطلاق التجريبي:** ثبات المراجعة وتقليل الحاجة للتلميحات، إكمال أنشطة الفهم، المشاركة الأسرية، والعودة الطوعية. استخدم تجميعات بلا صوت/نص تسميع أو بيانات تعريفية زائدة، وميّز عدم توفر البيانات عن الصفر. لا تجعل زيادة زمن الشاشة معيار النجاح.

**مراجعة تغطية الخطة:** المقترحات 1–12 ممثلة بالكامل في T5/T4/T7/T8/T1/T10/T9/T2/T3/T11/T6/T12 على الترتيب. لم يُنفذ أي منها ضمن إعداد هذا المستند؛ جميع مربعات التنفيذ والاختبار معلقة.

**دليل تحقق إعداد الخطة:** قراءة الكود الحالي ونقاط التمديد واختبارات الجوار، مراجعة مستقلة محددة لحدود الهوية/معاملات التقدم/lifecycle الصوت، ومراجعة ذاتية لتغطية كل مقترح والتبعيات. هذه أدلة لصلاحية التخطيط، وليست شهادة أن التطبيق الحالي خالٍ من الأخطاء أو أن التنفيذ المستقبلي اجتاز بوابات الإطلاق.
