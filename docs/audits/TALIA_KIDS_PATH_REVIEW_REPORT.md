# تقرير مراجعة مسار الأطفال — Talia Kids Path Review

- **التاريخ:** 2026-09-24
- **النطاق:** مسار الحفظ للأطفال فقط (`memorization_plus` — واجهة الطفل والكيوبتات وسياسات الجلسة). لا يمس مسار الكبار.
- **المنهجية:** مراجعة ثابتة (static review) لكل صفحات وودجات ومحددات المسار مع تشغيل الاختبارات القائمة، ثم تقسيم المعالجة إلى خمس مراحل تنفيذية مع اختبارات لكل إصلاح.
- **ملاحظة على أرقام الأسطر:** مأخوذة من لحظة المراجعة (2026-09-24) وقبل تنفيذ الإصلاحات؛ الإصلاحات نفسها غيّرت أسطر بعض الملفات، والأرقام هنا مرجع تاريخي لا مرجع حي.

---

## 1) خريطة ملفات المسار

| الطبقة | الملف |
| --- | --- |
| صفحات | `lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart` |
| | `kids_gamified_journey_page.dart`، `kids_gamified_stage_page.dart` |
| | `kids_gamified_listen_page.dart`، `kids_gamified_completion_page.dart` |
| ودجات | `presentation/widgets/kids_mission_card.dart`، `kids_house_card.dart`، `kids_journey_signpost.dart` |
| | `kids_progress_header.dart`، `kids_reward_dialog.dart`، `kids_stage_details.dart`، `kids_ayah_card.dart`، `kids_ui.dart` |
| حالة | `presentation/cubits/kids_journey_cubit.dart` (+ `_state.dart`)، `kids_mode_cubit.dart` |
| دومين | `domain/entities/kids_journey_stage.dart`، `kids_session_policy.dart`، `kids_progress.dart` |
| | `domain/navigation/kids_next_mission_resolver.dart` |
| عقد الربط | `domain/entities/kids_qr_link_contract.dart` (أُنشئ في المرحلة 1) |

---

## 2) المشاكل المكتشفة (مع أرقام الأسطر والحالة)

الخطورة: 🔴 عالية (تؤثر على سلوك المنتج) · 🟡 متوسطة (تجربة استخدام) · 🟢 منخفضة (تحسين).

### المجموعة أ — مسار المهمة (resolver/تنقّل)

| # | الخطورة | المشكلة | الموقع | الحالة |
| --- | --- | --- | --- | --- |
| K1 | 🔴 | بادئة QR لربط جهاز الطفل بولي الأمر غير موحّدة: المولّد يصدر بادئة والماسح يقرأ بادئة قديمة حرفية (`talia_link:`) فيفشل الربط صامتاً | `memorization_parent_access_service.dart` + `family_dashboard_page.dart` (الماسح) | ✅ أُغلقت — المرحلة 1: عقد مشترك `kids_qr_link_contract.dart` (qrPrefix=`talia-kids-link:` مع قبول legacy) + اختبار 6/6 |
| K2 | 🔴 | محدد المهمة التالية مختلف بين شاشة الإكمال والرئيسية: صفحة الإكمال كانت تحلّ المهمة بخطة خاصة بها بدل `KidsNextMissionResolver` فيتناقض «التالي» مع مهمة الرئيسية | `kids_gamified_completion_page.dart:48` (`_loadNextMission`) | ✅ أُغلقت — المرحلة 1: استُبدلت بـ`KidsNextMissionResolver` مع سجلات مراجعة `ReviewRecordReadScope.kids`؛ بقيت خطة بديلة فقط لتجاوز الآية المكتملة للتو (`:76` `_resolveNextSkippingJustCompleted`) |
| K3 | 🔴 | صفحة المرحلة تفتح المهمة بدون `missionType` فتُعاد الجلسات المتوقفة من الصفر بدل الاستئناف | `kids_gamified_stage_page.dart` — `_startMission` (كانت تبني الرابط يدوياً) | ✅ أُغلقت — المرحلة 2: `kidsNextMissionLocation()` يمرر `resume` لمرحلة جارية و`newMemorization` لجديدة + اختبار تتبّع |
| K4 | 🔴 | ازدواجية قاعدة «الآية التالية»: المحلّل يحسبها بـ`_firstIncompleteAyah` بينما الكيان يعرّف `nextAyahToStart` (ترتيب مختلف عند فجوات الإكمال) | `kids_next_mission_resolver.dart:71,86` مقابل `kids_journey_stage.dart:29` | ✅ أُغلقت — المرحلة 3: أصبح `nextAyahToStart` واعياً بالفجوات (يتخطى المكتملة بدل العودة إليها) والمحلّل يفوض إليه كمصدر وحيد للحقيقة + 2 اختبار |
| K5 | 🟡 | خطة الإكمال البديلة تتجاوز أولوية المحلّل (SRS أولاً) بعد تجاوز الآية المكتملة للتو | `kids_gamified_completion_page.dart:76` `_resolveNextSkippingJustCompleted` | ✅ أُغلقت — المرحلة 3: حُذفت الخطة الموازية واستُبدلت بـ`KidsNextMissionResolver.resolveSkippingAyah` (يعيد تشغيل خط SRS الأولوية مع افتراض اكتمال الآية) + 3 اختبارات |
| K6 | 🟡 | بطاقة المهمة تعرض كل المهام بعنوان «آخر مهمة» حتى عندما تكون مراجعة مستحقة (SRS) أو مراجعة مرتبطة — مضللة للطفل | `kids_mission_card.dart` (`kidsGamifiedLastMission` ثابتة) | ✅ أُغلقت — المرحلة 2: `isReviewMission` يعرض «جاهز للمراجعة» (`kidsGamifiedNeedsReview`) بلون مراجعة + اختبار |

### المجموعة ب — واجهة الطفل

| # | الخطورة | المشكلة | الموقع | الحالة |
| --- | --- | --- | --- | --- |
| K7 | 🟡 | عرض ثابت على الشاشات الضيقة: `cardWidth = 176` و`sideMargin = 16` يعطيان المساحة الفعلية للمنزل ~144px فقط عند 320px، وتُبنى المنازل اليمينية فوق سطر متصل | `kids_gamified_journey_page.dart:357-358` (`_JourneyMapSegment`) | ✅ أُغلقت — المرحلة 4: عرض متجاوب (44% من العرض، حد أدنى 136px وحد أقصى 156px عند ≤360px) وهامش جانبي 10px + اختبار يقيس عرض البطاقات فعلياً |
| K8 | 🟡 | زر الميكروفون يُعطَّل صامتةً حتى اكتمال الاستماع الإلزامي، والفيدباك الوحيد SnackBar يظهر مرة واحدة من الكيوبت | `kids_gamified_listen_page.dart:394-395` (`micDisabled`) و`:444` (`onPressed: null`) والـSnackBar عند `:128` تقريباً | ✅ أُغلقت — المرحلة 3: `_ListenFirstMicHint` يعرض «استمع {المتبقي} مرات» مكان الزر مع نقرة تشغّل الصوت (لا تسجل أبداً) + اختبار widget |
| K9 | 🟢 | الرحلة الفارغة تُظهر الاحتفال فقط عندما `stages.isEmpty`؛ الرئيسية الآن تحمي «الطفل الذي لم يبدأ» بشرط التقدم | `kids_gamified_journey_page.dart:206` (EmptyStateWidget) + `kids_gamified_home_page.dart` (شرط `ayahsCompleted > 0` من المرحلة 2) | ✅ أُغلقت — المرحلة 2 (احتفال الرئيسية شرطه التقدم الحقيقي + أجنحة RTL للرحلة الفارغة) |
| K10 | 🟡 | مفتاح «صوت المرشد» ظاهر في واجهتي ولي الأمر والطفل دون أي مستهلك فعلي (حقل ميت) | `family_dashboard_page.dart` (SwitchListTile) + `path_selection_page.dart` | ✅ أُغلقت — المرحلة 1: أزيلت المفاتيح مع تعليقات NOTE؛ الحقل `guidanceAudioEnabled` بقى في النموذج + اختبار widget للوحة الأسرة |

### المجموعة ج — المكافآت والتحفيز

| # | الخطورة | المشكلة | الموقع | الحالة |
| --- | --- | --- | --- | --- |
| K11 | 🟡 | شاشة الإكمال تعرض النجوم فقط؛ النقاط المكتسبة وترقية المستوى لا تظهر رغم توفرها في نتيجة الإكمال | `kids_reward_dialog.dart:64` (حبة `_RewardPill` واحدة للنجوم) | ✅ أُغلقت — المرحلة 3: `sessionPointsEarned`/`leveledUpTo` في حالة الكيوبت تنتقل عبر مسار الإكمال وتُعرض كحبتي «نقاط» و«مستوى» اختياريتين + 3 اختبارات |
| K12 | 🟡 | سلسلة الأيام (`currentStreak`) موجودة في `KidsProgress` ولا تظهر في واجهة الطفل إطلاقاً — محرك التحفيز اليومي مفقود | `kids_progress_header.dart` (لا استخدام لـ`currentStreak`) مقابل `kids_progress.dart:37` | ✅ أُغلقت — المرحلة 3: `_StreakBadge` (🔥 «{count} يوم مواظبة» عبر `homeStreakDays`) تحت قسم المستوى/XP، مخفية عند الصفر + 3 اختبارات (بما فيها 320px) |
| K13 | 🟢 | `KidsProgressHeader` يمرر كائن `progress` كاملاً للودجات الداخلية بدل القيم، ما يصعّب إعادة الاستخدام | `kids_progress_header.dart` (`_LevelProgressSection`/`_StarCounter`) | ✅ أُغلقت — المرحلة 5: `_ProgressHeaderBody` يستقبل قيماً صريحة فقط (level/percentage/progressValue/stars/streak)؛ 92/92 تمر دون تعديل أي اختبار |

### المجموعة د — سياسة العمر وحدود الجلسة

| # | الخطورة | المشكلة | الموقع | الحالة |
| --- | --- | --- | --- | --- |
| K14 | 🔴 | عدد تكرارات الاستماع ثابت `1` يدوياً بغض النظر عن العمر | `kids_mode_cubit.dart` — `_maxLoops` ثابت قديم | ✅ أُغلقت — المرحلة 1: `maxListenRepetitions` في `KidsSessionPolicy` (5–7 → 1، 8–12 → 2) ويضبط الكيوبت `maxLoops` في `load()` + 19/19 اختبار |
| K15 | 🟡 | `maxNewAyahs` و`maxDueReviews` لا يستهلكهما أحد عند بدء الجلسات (حدود حصة العمر غير مفروضة)؛ `maxSessionMinutes` يُستهلك فقط كهدف عرضي | بحث المستهلكين: فقط `memorization_identity_cubit.dart:101` (`sessionGoalMinutes`) | ✅ أُغلقت — المرحلة 4: بوابة يومية في `load()` تمنع جلسة `newMemorization` جديدة بعد بلوغ `maxNewAyahs` (من سجل الجلسات المحلي، وفشل القراءة يفتح البوابة)؛ الاستئناف والمراجعات لا تُحجب أبداً. أما `maxDueReviews` فهي حجم جدولة يملكه المحلّل (مراجعة واحدة مستحقة في كل مرة) لا حجب تحميل — لتعذُّر حجب SRS جوهرياً |
| K16 | 🟡 | `blockReviewRequired` مفروض عبر `V2SessionState.initial` لكن لا يوجد اختبار واجهة يثبت حجب التقدم قبل المراجعة المرتبطة للأعمار 8–12 | `kids_mode_cubit.dart` (`load`) + اختبارات الكيوبت | ✅ أُغلقت — المرحلة 4: كشف الاختبار فجوة أعمق — `markCompleted` كان يُصدر `isCompleted: true` رغم أن المحرك في `blockReviewPending`. أصبح الإكمال مقيّداً بالطور النهائي للمحرك (`_sessionReachedCompletion`) + اختبار كيوبت يثبت البقاء محجوزاً |

---

## 3) المراحل الخمس

> المراحل 1 و2 **منفّذتان ومغلقتان**؛ 3–5 قيد الانتظار. كل مرحلة تُنفّذ بنفس الأسلوب: فجوات واقعية + اختبار لكل إصلاح + `flutter analyze` نظيف + عدم لمس مسار الكبار.

### المرحلة 1 — ثقة الربط واتساق المهمة (✅ منجزة)
- **البند:** K1، K2، K10، K14.
- **النواتج:** عقد QR المشترك؛ توحيد المحلّل في شاشة الإكمال (+`missionType` في التوجيه)؛ إخفاء مفتاح صوت المرشد من اللوحتين؛ `maxListenRepetitions` بسياسة العمر.
- **الأدلة:** `kids_qr_link_contract_test` 6/6 · `family_dashboard_page_test` 2/2 · `kids_mode_cubit_test` 19/19 · `guardian_linking` + `memorization_plus_repository_impl` 72/72 · analyze نظيف.

### المرحلة 2 — اتساق الواجهة والتسمية (✅ منجزة)
- **البند:** K3، K6، K9 (+ أجنحة RTL إضافية).
- **النواتج:** `kidsNextMissionLocation` يحمل نوع المهمة من صفحة المرحلة؛ «جاهز للمراجعة» بدل «آخر مهمة»؛ احتفال الرئيسية عند اكتمال الرحلة (شرط التقدم الحقيقي)؛ أجنحة RTL 320px لبطاقة المراجعة وصفحة المرحلة المكتملة والرحلة الفارغة.
- **الأدلة:** جناح الأطفال (6 صفحات + الكيوبت) 62/62 · analyze نظيف على 7 ملفات متغيرة.

### المرحلة 3 — تفاعل الطفل ومكافآته (✅ منجزة)
- **البند:** K4، K5، K8، K11، K12.
- **النواتج:**
  1. `nextAyahToStart` في الكيان أصبح متخطياً للفجوات والمحلّل يفوض إليه (حُذف `_firstIncompleteAyah`).
  2. `KidsNextMissionResolver.resolveSkippingAyah` استُبدل به خطة الإكمال الموازية — أولوية SRS محفوظة بعد كل إكمال.
  3. تلميح استماع دائم مكان زر الميكروفون (`_ListenFirstMicHint`) والنقرة تشغّل الصوت.
  4. `KidsRewardDialog` يقبل `pointsEarned`/`leveledUpTo` ويُظهر حبتي نقاط ومستوى؛ السلسلة كاملة عبر حالة الكيوبت ومسار الإكمال.
  5. `_StreakBadge` في `KidsProgressHeader` عند `currentStreak > 0`.
- **الأدلة:** جناح الأطفال الكامل (11 ملف اختبار) **88/88** · `flutter analyze` على 13 ملفاً متغيراً: **لا ملاحظات**.

### المرحلة 4 — تجاوب الحدود والسياسة (✅ منجزة)
- **البند:** K7، K15، K16.
- **النواتج:**
  1. `_JourneyMapSegment` يستخدم عرضاً متجاوباً للمنازل (44% بحدود 136–156px) وهامشاً 10px عند ≤360px.
  2. بوابة الحد اليومي في `KidsModeCubit.load()` عبر `KidsSessionLogsLoader` + رمز رسالة `@kids/daily_limit|<n>` موطَّن بالعربية والإنجليزية، تُطبَّق على `newMemorization` فقط.
  3. إصلاح دلالة الإكمال: `isCompleted` لن يصير true إلا حين يبلغ محرك V2 طواره النهائي — جلسة `blockReviewPending` تبقى قابلة للاستئناف ولا تفتح شاشة الاحتفال.
- **الأدلة:** جناح الأطفال الكامل **92/92** · `flutter analyze` نظيف على 10 ملفات متغيرة · 4 اختبارات جديدة (K7 قياس، K15 حجب + تجاوز، K16 حجز بالطور).

### المرحلة 5 — هيكلة وتلميع (✅ منجزة)
- **البند:** K13 (+ تنظيف تعليقات المرحلتين السابقتين).
- **النواتج:**
  1. `KidsProgressHeader`: الودجات الداخلية تستقبل قيماً صريحة فقط عبر `_ProgressHeaderBody` — لا تماسّ مع كيان التقدم داخل البنية.
  2. تقسيم `kids_gamified_journey_page.dart` من 567 إلى 338 سطراً: الرسّامان في `widgets/kids_journey_painters.dart` (مع دالة `resolveJourneySegmentMetrics` لقياسات K7) وقطاع الخريطة في `widgets/kids_journey_segment.dart` كودجة عامة.
  3. تعليقتا NOTE المؤقتتان (إخفاء مفتاح صوت المرشد) حُوّلتا لإحالة دائمة على بند K10 في هذا التقرير.
- **معيار القبول محقق:** **92/92** اختباراً تمر دون تعديل أي ملف اختبار · `flutter analyze` نظيف على 6 ملفات متغيرة.

---

## 4) خطة الاختبارات

### 4.1 لكل إصلاح (الحد الأدنى)
- اختبار وحدة/ودجت جديد يثبت السلوك الجديد ويسمى بعد المتطلب (نمط التسمية القائم بالإنجليزية).
- تحديث الاختبارات القائمة المتأثرة **بوعي** (مثل رفع `debugSetLoopCount(1)` إلى `(2)` بعد اعتماد سياسة العمر) — لا حذف صامت للتوقعات.
- `flutter analyze` على الملفات المتغيرة فقط (أسرع وأدق من المشروع كاملاً).

### 4.2 الجناح الرجل (regression suite) بعد كل مرحلة
```bash
flutter test test/features/memorization_plus/domain/kids_next_mission_resolver_test.dart \
  test/features/memorization_plus/domain/kids_session_policy_test.dart \
  test/features/memorization_plus/domain/kids_qr_link_contract_test.dart \
  test/features/memorization_plus/presentation/cubits/kids_mode_cubit_test.dart \
  test/features/memorization_plus/presentation/pages/kids_gamified_stage_page_test.dart \
  test/features/memorization_plus/presentation/pages/kids_gamified_home_page_test.dart \
  test/features/memorization_plus/presentation/pages/kids_gamified_journey_page_test.dart \
  test/features/memorization_plus/presentation/pages/kids_gamified_listen_page_test.dart \
  test/features/memorization_plus/presentation/pages/kids_gamified_rtl_narrow_test.dart \
  test/features/memorization_plus/presentation/pages/kids_gamified_completion_page_test.dart \
  test/features/memorization_plus/presentation/widgets/kids_progress_header_test.dart \
  --reporter compact
```
- الحالة المرجعية بعد المرحلة 4: **92/92** (بعد المرحلة 3 كانت 88/88 وبعد المرحلة 2 كانت 62/62 على نطاق أضيق).
- عند لمس عقد الربط أضف: `guardian_linking_page_test.dart` و`memorization_plus_repository_impl_test.dart` و`kids_qr_link_contract_test.dart` (مرجع المرحلة 1: 72/72 + 6/6).

### 4.3 مصفوفة الاختبار اليدوي (قبل الإطلاق)
| السيناريو | الخطوات | المتوقع |
| --- | --- | --- |
| ربط QR عبر جهازين | ولٍ يولّد QR → طفل يمسح | الرابط يعمل بالبادئة الجديدة، والكود الورقي القديم يقبل |
| استئناف جلسة متوقفة | أوقف جلسة منتصف مرحلة → افتح من صفحة المرحلة | تستأنف من موضعها (`missionType=resume`) |
| مراجعة مستحقة | خلّد مراجعة متأخرة → افتح الرئيسية | البطاقة «جاهز للمراجعة» و«التالي» في الإكمال يوافقها |
| بوابة الاستماع | عمر 6 مقابل عمر 9 | الأول يسمع مرة والثاني مرتين قبل تفعيل الميكروفون |
| شاشة 320px عربية | افتح الرئيسية/الرحلة/المرحلة/الاستماع/الإكمال | بلا Overflow أو استثناءات |
| رحلة مكتملة | أتمّ كل المراحل | احتفال في الرئيسية والخريطة بلا CTA قديم |
| مسار الكبار | دورة حفظ كاملة للكبار | لا أي تغيير سلوكي أو بصري |

### 4.4 ضوابط عامة
- لا تعديل على نماذج البيانات أو منطق تقدم الحفظ (قاعدة `docs/kids_gamified_ui.md`).
- أي تعديل l10n يتم في `app_en.arb`/`app_ar.arb` فقط إن لزم، مع الانتباه أن الملفات المولّدة فيها تعديلات مسبقة على القرص.
- لا `commit`/`push` إلا بطلب صريح من المستخدم.

---

## 5) سجل الصيانة

| التاريخ | الحدث |
| --- | --- |
| 2026-09-24 | إنشاء التقرير؛ إغلاق المرحلة 1 (4 بنود) والمرحلة 2 (3 بنود + أجنحة RTL) بأدلة الاختبارات أعلاه |
| 2026-09-25 | إغلاق المرحلة 3 (بنود K4، K5، K8، K11، K12)؛ الجناح الكامل 88/88 وanalyze نظيف؛ مرجع جناح الانحدار الجديد في §4.2 |
| 2026-09-25 | إغلاق المرحلة 4 (بنود K7، K15، K16) مع إصلاح دلالة الإكمال في `markCompleted`؛ الجناح الكامل 92/92 |
| 2026-09-25 | إغلاق المرحلة 5 (K13 + تقسيم خريطة الرحلة + تنظيف التعليقات)؛ 92/92 بلا تعديل أي اختبار — اكتملت المراحل الخمس جميعها |
