# خارطة التميّز، المرحلة 4: الإطلاق والتفعيل

> **للوكلاء المنفذين:** مهارة فرعية مطلوبة: superpowers:subagent-driven-development (مُوصى بها) أو superpowers:executing-plans. الخطوات بصيغة `- [ ]`.

**الهدف:** تشغيل ما بُني في المراحل 1–3 لكل المستخدمين على دفعات آمنة قبل تجميد رمضان (**2027-01-15**). كل علم ينتهي إلى حالة من اثنتين:
- مفعَّل افتراضياً، ومعه دليل اختبار على جهاز حقيقي.
- مؤجَّل صراحةً، ومعه سبب مكتوب. هذا معيار W0 في الخارطة.

لا ميزات جديدة في هذه المرحلة.

**البنية:**
- اليوم كل علم يُقرأ من التخزين المحلي، وقيمته `false` إذا لم يُضبط، وصفحة Labs موجودة في بناء debug فقط. لذلك لا يوجد في بناء release أي طريق لتفعيل ميزة.
- تضيف هذه المرحلة **بيان تفعيل** مركزياً في الكود، يحدد القيمة الافتراضية لكل علم مع دليلها واعتمادياتها. وتمر كل دفعة تفعيل بالخطوات نفسها: تُغلق بواباتها، ثم يُغيَّر سطرها في البيان، ثم يُبنى إصدار.
- إيقاف ميزة بعد إطلاقها يكون بإصدار جديد يعيد سطرها إلى `off`. الإيقاف يُخفي الواجهة ولا يحذف بيانات (ح3).

**التقنيات:** Flutter/Dart و`shared_preferences` والأعلام الأربعة القائمة، وSupabase عبر فرع اختبار، و`scripts/verify_v1_release.ps1`.

**المواصفة:** `docs/superpowers/specs/2026-10-13-talia-differentiation-roadmap.md`، في §W0 و§«بوابة القبول لكل بند» و§هـ. ومصفوفة الأعلام في `docs/release/flag-device-test-matrix.md`. وحالة المرحلة 3 في `docs/superpowers/reviews/2026-10-24-roadmap-phase-3-status.md`.

## 0. ما يملكه المالك ولا يملكه الوكيل

هذه الخطوات لا ينفذها وكيل. الخطة تجهّز لها أدواتها وتنتظر نتيجتها:

| # | المهمة | تحجب |
|---|---|---|
| O1 | تجارب الجهاز الحقيقي وفق المصفوفة. بعضها يحتاج هاتفاً حقيقياً وسماعة بلوتوث (I4)، ومشغّلاً يدعم الودجت (J3)، وجهازاً لوحياً بقياس 1280×800 (H2) | كل دفعة |
| O2 | مراجعة بشرية لأزواج المتشابهات واعتماد الفهرس (E0)، وتحتاج مراجعاً يعيّنه المالك | `similarAyahTrainer` |
| O3 | رفع الإصدار إلى Google Play وتحديد نسبة الطرح | كل دفعة |
| O4 | الموافقة على أي هجرة أو تزويد على Supabase لحظة التنفيذ | L2 وL5 |

## 1. قرارات تحتاج موافقتك

| # | القرار | الاقتراح |
|---|---|---|
| P4-R1 | آلية التفعيل | **قيم افتراضية مدمجة في الكود (L0)**، بلا إعداد عن بُعد. هذا يحافظ على العمل دون إنترنت، والثمن أن الإيقاف يحتاج إصداراً جديداً. البديل جدول إعدادات في Supabase، وهو أسرع إيقافاً لكنه يضيف اعتماداً على الشبكة ومساحة هجوم جديدة |
| P4-R2 | قاعدة الاختبار الحية للأدوار والتزامن | **فرع Supabase مؤقت من `Talia_Quran`** يُحذف بعد الفحص، ويُعرض عليك قبل إنشائه لأنه مدفوع. الإنتاج لا يُستخدم للاختبار |
| P4-R3 | أهلية الختمة الجماعية | **دالة `request_group_khatmah_eligibility()`** تمنح الأهلية تلقائياً لحساب مسجَّل مسارُه بالغ في `profiles.selected_path` وليس طفلاً مرتبطاً. البديل قائمة يدوية للتجربة المغلقة |
| P4-R4 | ما يجب أن يصل قبل التجميد | `seasonalRamadan` و`afterPrayerAzkar` في الموجة 1، لأن رمضان 1448 يبدأ بعد التجميد ولن يتغير شيء بعده |
| P4-R5 | البنود التي لا يُتوقع إغلاق بواباتها قبل التجميد | تُؤجَّل صراحةً: `similarAyahTrainer` (E0)، و`tabletSpread` إن لم يتوفر جهاز لوحي، وT5 وT6 وT11 وT12 كما قرّرتَ سابقاً |

## Global Constraints

- لا يُعدَّل أي ملف في `assets/data/`، ولا يُكتب نص ديني.
- القيمة الافتراضية لكل علم تبقى `off` حتى يحمل سطره في البيان دليلاً موثَّقاً في `docs/release/rollout-evidence.md`.
- إيقاف أي علم يُخفي الواجهة ولا يحذف بيانات، ويُختبر بـ«ح3» في كل دفعة.
- أي تغيير مقصود يضبطه المستخدم في Labs (debug) يتقدّم على القيمة الافتراضية، ويمكن إعادته إلى الافتراضي.
- قبل كل دفعة: `./scripts/verify_v1_release.ps1 -BuildAndroidRelease`، ويجب أن يُطبع **PASS** دون خياري التوازي والمهلة.
- بعد **2027-01-15** لا يتغير البيان ولا الكود إلا لإصلاح خلل حرج.
- قبل `flutter test`: `$env:TEMP='D:\Flutter\talia_quran\.superpowers\tmp'; $env:TMP=$env:TEMP;`. ولا يعمل أمرا `flutter test` معاً.
- لا نشر على Supabase ولا إنشاء فرع مدفوع دون موافقة لحظية.

## Review Focus

1. **جهاز مطوّر عليه تغيير قديم من Labs:** هذا التغيير يغلب الافتراضي الجديد. يجب أن تُظهر Labs ذلك بوضوح، وأن تتيح «إعادة إلى الافتراضي». الاختبار في L0.
2. **علم مفعَّل واعتماديته مطفأة:** مثل `todayBudget` دون `personalization`، أو `gentleReturn` دون `personalization`. يجب أن يُقرأ العلم مطفأً، وأن يرفض اختبار البيان هذا التكوين. الاختبار في L0.
3. **إصدار لاحق يعيد علماً إلى `off`:** تختفي الميزة، وتبقى بياناتها، وتعود إذا أعيد العلم. الاختبار في L0 (سلوك القراءة)، وفي كل موجة (ح3 على الجهاز).
4. **ملف طفل مع موجة أعلام البالغ:** لا تتسرب إليه أي ميزة بالغ ولا بيانات بالغ. الاختبار في L1 (فحص دخاني لكل علم بالغ مع ملف طفل).
5. **الودجت بعد منتصف الليل قبل فتح التطبيق:** يبقى سطر الصلاة صحيحاً، ويختفي العدّ والورد القديمان. الاختبار في L1.

---

## الترتيب

| الدفعة | المحتوى | يعتمد على |
|---|---|---|
| **L0** | بيان التفعيل وLabs | — |
| **L1** | إصلاحات ما قبل الإطلاق المعروفة | — |
| **L2** | التحقق الحي على فرع Supabase | P4-R2، O4 |
| **L3** | حزمة تجارب الجهاز (أدلة لكل موجة) | L0، O1 |
| **L4** | الموجات 1–4 | L0، L3، والبوابات المذكورة لكل موجة |
| **L5** | أهلية الختمة الجماعية | P4-R3، L2، O4 |
| **L6** | H3 إن نجح H2 | O1 (جهاز لوحي) |
| **L7** | نقطة التجميد 2027-01-15 | الكل |

يمكن تنفيذ L0 وL1 وL2 بالتوازي، لأن ملفاتها منفصلة.

---

# L0: بيان التفعيل

### Task L0.1: البيان والقراءة الموحّدة

**Files:**
- Create: `lib/core/experience/rollout_manifest.dart`
- Modify:
  - `lib/core/experience/experience_feature_flags.dart`
  - `lib/core/memorization/kids_enrichment_feature_flags.dart`
  - `lib/features/adult_journey/adult_journey_feature_flags.dart`
  - `lib/core/memorization/kids_hifz_feature_flags.dart`
  - في كلها تصبح القراءة `_readBool(key) ?? RolloutManifest.defaultFor(key)`، وتبقى معالجة الخطأ «مطفأ».
- Create: `docs/release/rollout-evidence.md`. أول قسم فيه `## owner-2026-10-18-quran-journey`، ويوثّق القرار القائم.
- Test: `test/core/experience/rollout_manifest_test.dart`

**Interfaces:**
- Produces:
  - `enum RolloutStage { off, on }`
  - `final class RolloutEntry { const RolloutEntry(this.key, this.stage, {this.evidence, this.requires = const []}); final String key; final RolloutStage stage; final String? evidence; final List<String> requires; }`
  - `abstract final class RolloutManifest { static const List<RolloutEntry> entries; static bool defaultFor(String key); static RolloutEntry? entryFor(String key); }`
  - `defaultFor` تعيد `true` فقط إن كانت `stage == on` وكل ما في `requires` يعيد `true` بدوره. والمفتاح المجهول يعيد `false`.
  - القيم الأولية تطابق السلوك الحالي حرفياً: كل شيء `off` عدا `kids_quran_journey_enabled`، فهو `on` مع `evidence: 'owner-2026-10-18-quran-journey'`.
  - `requires`:
    - `todayBudget` ← `personalization`.
    - `gentleReturn` ← `personalization`.
    - `quranJourney` لا يعتمد على شيء.

- [ ] **Step 1: الاختبارات الفاشلة**
  - كل قيمة في `ExperienceFeature` و`KidsEnrichmentFeature` و`AdultJourneyFeature`، ومعها مفتاحا `KidsHifzFeatureFlags`، لها سطر واحد فقط في البيان، ولا يوجد في البيان مفتاح لا يقابله علم.
  - كل سطر `on` له `evidence` يظهر عنواناً `## <evidence>` في `docs/release/rollout-evidence.md`. يقرأ الاختبار الملف من القرص.
  - كل مفتاح في `requires` موجود في البيان، ولا توجد حلقة.
  - **(Review Focus 2)**: لا يوجد سطر `on` تكون إحدى اعتمادياته `off`.
  - سلوك القراءة:
    - بلا قيمة مخزَّنة ← تُعاد القيمة الافتراضية.
    - `false` مخزَّنة مع افتراضي `on` ← `false`.
    - `true` مخزَّنة مع اعتمادية افتراضية مطفأة ← تُحترم القيمة المخزَّنة، فالـoverride صريح.
    - استثناء أثناء القراءة ← `false`.
  - انحدار: `KidsHifzFeatureFlags.isQuranJourneyEnabled` بلا قيمة مخزَّنة ← `true`، وبقية الأعلام ← `false`.
- [ ] **Step 2:** `flutter test test/core/experience/rollout_manifest_test.dart`. المتوقع: FAIL.
- [ ] **Step 3:** التنفيذ.
- [ ] **Step 4:** الاختبار نفسه، ثم `test/core` و`test/features/settings`. المتوقع: PASS.
- [ ] **Step 5:** Commit `feat(rollout): central default manifest for every flag`.

### Task L0.2: Labs تُظهر الافتراضي والتغيير

**Files:**
- Modify: `lib/features/settings/presentation/pages/labs_flags_page.dart`
- Test: `test/features/settings/labs_flags_page_test.dart`

- [ ] **Step 1: الاختبارات الفاشلة**
  - كل سطر يعرض «افتراضي: on/off».
  - عند وجود قيمة مخزَّنة تظهر شارة «مُغيَّر محلياً» وزر «إعادة إلى الافتراضي»، والزر يستدعي `prefs.remove(key)`. **(Review Focus 1)**
  - المفتاح يعكس القيمة الفعلية بعد الاعتماديات.
- [ ] **Step 2:** تشغيلها. المتوقع: FAIL.
- [ ] **Step 3:** التنفيذ. نصوص Labs بالإنجليزية كما هي اليوم، فالصفحة debug فقط.
- [ ] **Step 4:** تشغيلها. المتوقع: PASS.
- [ ] **Step 5:** Commit `feat(labs): show rollout defaults and local overrides`.

---

# L1: إصلاحات ما قبل الإطلاق

### Task L1.1: الودجت بعد منتصف الليل

**Files:**
- Modify: `lib/core/home_widget/widget_snapshot.dart` و`widget_snapshot_builder.dart` و`widget_snapshot_source.dart`
- Modify: `android/app/src/main/kotlin/com/talia/quran/widget/WidgetSnapshotFormatter.kt`
- Test: `test/core/home_widget/widget_snapshot_builder_test.dart`، و`WidgetSnapshotFormatterTest.kt`

**Interfaces:**
- يضاف إلى `upcomingPrayers` فروض الغد الخمسة كاملة، عبر `PrayerTimesService` لتاريخ الغد. `schemaVersion` يبقى 1، والإضافة لا تكسر اللقطات القديمة.
- يضاف حقل `dayEndsAt` (millis)، وهو نهاية اليوم المحلي للقطة.
- المنسّق: بعد `dayEndsAt` يُخفى سطرا المراجعة والورد، ويبقى سطر الصلاة من القائمة حتى آخر وقت فيها.

- [ ] **Step 1: الاختبارات الفاشلة.** **(Review Focus 5)**
  - JVM: لقطة يوم الاثنين، والوقت الثلاثاء 00:30 ← `prayerLine` هو فجر الثلاثاء، و`reviewLine == null`، و`wirdLine == null`.
  - Dart: اللقطة تحوي 5 + المتبقي من اليوم، بلا تكرار، ومرتبة.
- [ ] **Step 2:** تشغيلها. المتوقع: FAIL.
- [ ] **Step 3:** التنفيذ. جدولة إعادة الرسم تشمل الأوقات الجديدة و`dayEndsAt`.
- [ ] **Step 4:** `flutter test test/core/home_widget`، ثم `./gradlew :app:testDebugUnitTest --tests '*WidgetSnapshotFormatterTest*'`. المتوقع: PASS.
- [ ] **Step 5:** Commit `fix(widget): keep prayer row correct after midnight`.

### Task L1.2: نص موافقة الصوت في «سمّع لي»

الحوار المشترك يقول «تُحفظ نتيجة التقييم فقط ضمن تقدّمك»، وهذا غير صحيح في «سمّع لي» لأن الجولة لا تحفظ شيئاً.

**Files:**
- Modify: موضع استدعاء حوار الموافقة في `hands_free_review_page.dart`، مع معامل نص اختياري للحوار المشترك.
- ARB: `handsFreeVoiceConsentBody`. يُكتب بمعنى جملة الحوار نفسها، مع تبديل جملة الحفظ بـ«ولا تحفظ هذه الجولة أي نتيجة».
- Test: `test/features/memorization_plus/presentation/pages/hands_free_review_page_test.dart`

- [ ] **Step 1:** اختبار فاشل: الحوار من «سمّع لي» لا يحتوي «تُحفظ نتيجة التقييم»، ويحتوي «لا تحفظ هذه الجولة». والحوار في الجلسة العادية لم يتغير.
- [ ] **Step 2:** تشغيله. المتوقع: FAIL.
- [ ] **Step 3:** التنفيذ، ثم `flutter gen-l10n`.
- [ ] **Step 4:** تشغيله، ثم `test/core/privacy`. المتوقع: PASS.
- [ ] **Step 5:** Commit `fix(hifz): accurate voice consent for hands-free review`.

### Task L1.3: فحص دخاني لعزل الطفل عن أعلام البالغ

**Files:**
- Test: `test/integration/adult_flags_child_profile_smoke_test.dart`

- [ ] **Step 1:** اختبار لكل علم بالغ في الموجة 1 (قائمتها في L4.1)، مع ملف طفل نشط: الشاشة الرئيسية للطفل وقارئه ومساره لا تُظهر بطاقة الميزة ولا مدخلها. **(Review Focus 4)**
- [ ] **Step 2:** تشغيله. المتوقع: PASS إن كانت الحراسات القائمة سليمة. إن فشل، يُعالَج كخلل بـ`superpowers:systematic-debugging` قبل أي موجة.
- [ ] **Step 3:** Commit `test(rollout): adult flags never surface on a child profile`.

---

# L2: التحقق الحي على Supabase (يحتاج P4-R2 وموافقة لحظية)

### Task L2.1: فرع الاختبار والعقود

- [ ] عرض تكلفة الفرع على المالك (`get_cost` ثم `confirm_cost`)، وانتظار موافقته.
- [ ] إنشاء الفرع، ثم التأكد من تطابق `list_migrations` مع الإنتاج.
- [ ] تشغيل `scripts/verify_supabase_migrations.ps1` و`scripts/verify_supabase_contract.ps1` على رابط الفرع. المتوقع: PASS.

### Task L2.2: اختبارات الأدوار والتزامن الحية

**Files:**
- Create: `tool/live_contract/live_role_checks.dart`. سكربت Dart يستخدم `supabase` بحسابات اختبار تُنشأ عبر SQL **على الفرع فقط**. يقرأ رابط الفرع ومفتاحه من متغيرات البيئة، ولا يُحفظ أي سر في المستودع.
- Create: `docs/superpowers/reviews/YYYY-MM-DD-live-contract.md`

- [ ] حالات المرحلة 2 من `docs/superpowers/reviews/2026-10-21-remote-family-open-gates.md`:
  - ولي أمر، وطفل، وحساب غير مرتبط.
  - طلبا CAS متعارضان: ينجح واحد فقط.
  - 11 تشجيعاً متزامناً: الحد اليومي 10.
  - إعادة إرسال الطلب نفسه: رسالة واحدة.
  - سحب الرابط أثناء الانتظار: الطلب مرفوض.
- [ ] حالات الختمة الجماعية:
  - عضوان يحجزان الجزء نفسه بجلستين مستقلتين: ينجح واحد، والآخر يتلقى `conflict`.
  - العضو رقم 31 يُرفض.
  - إكمال بعد المغادرة: `not_member`.
  - حذف الحساب يمر بالتنظيف.
- [ ] تسجيل النتائج، ثم **حذف الفرع**.
- [ ] Commit `test(supabase): live role and concurrency checks on a branch`.

---

# L3: حزمة تجارب الجهاز

### Task L3.1: دليل موجّه لكل موجة

**Files:**
- Modify: `docs/release/flag-device-test-matrix.md`. يضاف قسم «ترتيب المرحلة 4» يربط كل موجة بصفوفها الحالية، ومعه أمر البناء الموحّد.
- Modify: `docs/release/rollout-evidence.md`. قالب قسم لكل علم: الجهاز، وإصدار Android، والتاريخ، والصفوف المنفذة، والنتيجة، ورابط اللقطات.

- [ ] كتابة القسمين. لا يُشغَّل أي اختبار هنا.
- [ ] الوكيل ينفذ على الإيميوليتر الصفوف التي لا تحتاج عتاداً خاصاً، ويسجّلها بعلامة «إيميوليتر». الصفوف التي تحتاج هاتفاً حقيقياً تبقى للمالك (O1).
- [ ] Commit `docs(rollout): phase 4 device-test guide and evidence template`.

---

# L4: موجات التفعيل

لكل موجة الخطوات نفسها:
1. التحقق من أن صفوفها في المصفوفة «نجح» على جهاز حقيقي، وأن قسمها مكتوب في `rollout-evidence.md`.
2. تغيير أسطرها في البيان إلى `on` مع `evidence`.
3. `./scripts/verify_v1_release.ps1 -BuildAndroidRelease`. المتوقع: PASS.
4. Commit، ثم PR، ثم الدمج.
5. يرفع المالك الإصدار (O3).

العلم الذي لم تكتمل أدلته عند موعد الموجة يُنقل إلى الموجة التالية، ويُكتب سبب النقل.

### Task L4.1: الموجة 1، البالغ محلي التأثير (قبل 2026-12-15)

`personalization`، `todayBudget`، `gentleReturn`، `strengthOverlay`، `readerRepeat`، `trustCenter`، `clarityMode`، `afterPrayerAzkar`، `seasonalRamadan`، `localBackup`، `forgettingForecast`، `audioDownloads`، `ayahNotes`، `hijriYearRecap`.

- شرط خاص: `localBackup` يحتاج تصديراً واستعادة على هاتف حقيقي، لأنهما تعذّرا على الإيميوليتر.
- شرط خاص: `gentleReturn` يحتاج تثبيت عتبة العودة في المصفوفة.
- Commit `feat(rollout): wave 1 adult local features on by default`.

### Task L4.2: الموجة 2، الأطفال المحليون (قبل 2026-12-31)

T1–T4، وT7–T10، و`bedtimeListening`، و`guardianPromise`، و`guardianRecitation`، و`guardianMilestones`، و`monthlyReport`، و`kids_hifz_v2_enabled`، و`prayerReview`.

- شرط خاص: جدول §1 في المصفوفة كاملاً.
- شرط خاص: تأكيد أن T4 لا يُكمل الآية.
- شرط خاص: `prayerReview` يحتاج صفوف قسمه كلها، لأنه يمس الإشعارات.
- يُكتب صراحةً أن `guardianCertificates` بلا أثر.
- Commit `feat(rollout): wave 2 kids local features on by default`.

### Task L4.3: الموجة 3، الأسرة عن بُعد (قبل 2027-01-10)

`remotePlan`، `remotePromise`، `encouragements`.

- شرط خاص: L2.2 ناجحة.
- شرط خاص: تجربة جهازين، ولي أمر وطفل، مع قطع الاتصال وسحب الرابط.
- Commit `feat(rollout): wave 3 remote family on by default`.

### Task L4.4: الموجة 4، المرحلة 3 (حسب الجاهزية، ولا موعد يتجاوز التجميد)

- `homeWidget`: J3 Step 5 على مشغّل يدعم الودجت، و«ح1» مع الودجت ظاهراً.
- `handsFreeReview`: I4 كاملاً. الحد المعروف لمفتاح PAUSE يُوثَّق في وصف الإصدار.
- `groupKhatmah`: L5 وL2.2 ناجحتان، وتجربة عضوين على جهازين.
- `tabletSpread`: يُفعَّل فقط إن اكتمل L6.
- Commit `feat(rollout): wave 4 phase 3 features on by default`.

---

# L5: أهلية الختمة الجماعية (P4-R3، وموافقة نشر لحظية)

### Task L5.1: طلب الأهلية من الخادم

**Files:**
- Create: `supabase/migrations/<timestamp>_group_khatmah_self_eligibility.sql`
- Modify: `lib/features/group_khatmah/data/supabase_group_khatmah_remote.dart` ومستودعها. عند تلقي `not_eligible` لأول مرة يُستدعى الطلب مرة واحدة، ثم تُعاد العملية.
- Modify: `scripts/verify_group_khatmah_contract.ps1`
- Test: `supabase/tests/<timestamp>_group_khatmah_self_eligibility_test.sql`، و`test/features/group_khatmah/data/group_khatmah_eligibility_test.dart`

**Interfaces:**
- `public.request_group_khatmah_eligibility() RETURNS jsonb`، بصيغة `SECURITY INVOKER` تغلّف `private.group_khatmah_self_eligibility()` التي هي `SECURITY DEFINER` مع `search_path=''`.
- الدالة تأخذ قفل الفاعل نفسه.
- تمنح الأهلية فقط إن كانت الجلسة صالحة، و`public.profiles.selected_path = 'adult'` (يكتبه `upsert_memorization_identity`)، وليس للحساب رابط نشط بصفة طفل في `parent_child_links`. القيمة `policy_version = 1`.
- تعيد `{eligible: bool}`، ولا تُلغي أهلية سبق منحها يدوياً.

- [ ] **Step 1: اختبارات SQL فاشلة:**
  - بالغ ← `eligible:true`.
  - طفل مرتبط ← `false`.
  - مجهول الهوية ← `group_session_required`.
  - تكرار الطلب لا يغيّر شيئاً.
  - `anon` بلا صلاحية تنفيذ.
- [ ] **Step 2:** تشغيلها على PGlite. المتوقع: FAIL.
- [ ] **Step 3:** كتابة الهجرة والعميل.
- [ ] **Step 4:** SQL على PGlite، ثم `flutter test test/features/group_khatmah`. المتوقع: PASS.
- [ ] **Step 5:** مراجعة `opus-architecture-reviewer` إلزامية.
- [ ] **Step 6:** Commit. ثم **عرض النشر على المالك** وتنفيذه بعد موافقته، ثم فحوص العقد على الإنتاج.

---

# L6: ربط العرض المزدوج (مشروط)

- [ ] O1: قياس H2 على جهاز لوحي حقيقي بأوامر `docs/superpowers/reviews/2026-10-23-tablet-spread-perf.md`. الحاضنة تطبع `QURAN_PROFILE_SUMMARY`.
- [ ] إن نجحت العتبات: تنفيذ **Task H3** من `docs/superpowers/plans/2026-10-22-roadmap-phase-3.md` كما هي، وتبقى اختبارات Review Focus 4 فيها.
- [ ] إن فشلت، أو لم يتوفر جهاز قبل 2027-01-05: تأجيل صريح في `rollout-evidence.md` مع السبب.

---

# L7: نقطة التجميد (2027-01-15)

- [ ] جدول نهائي في `docs/release/rollout-evidence.md` يضع كل علم من الأعلام الأربعة في إحدى حالتين: `on` مع دليله، أو `off` مع سبب مكتوب. وهذا هو معيار W0.
- [ ] `./scripts/verify_v1_release.ps1 -BuildAndroidRelease`: PASS على رأس `main`.
- [ ] تحديث ذاكرة المشروع وحالة الخارطة: ما أُطلق، وما أُجِّل إلى ما بعد رمضان.
- [ ] Commit `docs(rollout): freeze checkpoint`.
