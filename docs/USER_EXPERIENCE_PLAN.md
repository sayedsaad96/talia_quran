# خطة تنفيذ تحسينات تجربة المستخدم — تقرير UX

بناءً على [REAL_USER_EXPERIENCE_TESTING_REPORT.md](file:///d:/Sayed/Flutter/talia_quran/docs/REAL_USER_EXPERIENCE_TESTING_REPORT.md)

> [!IMPORTANT]
> هذه الخطة تغطي **فقط** التغييرات الآمنة التي لا تمس: نص القرآن، خوارزمية SM-2، حساب السلسلة (Streak)، هيكل قاعدة البيانات، أو أي منطق أعمال حساس.

---

## ملخص المراحل

| المرحلة | الوصف | المخاطرة | عدد المهام | يحتاج موافقة؟ |
|---------|-------|----------|-----------|--------------|
| **Phase 1** | نصوص + توطين + إرشادات أولية | 🟢 صفر/منخفضة | 8 | لا |
| **Phase 2** | تبسيط التدفقات + إرشاد المستخدم | 🟡 منخفضة/متوسطة | 10 | نعم (بعض المهام) |
| **Phase 3** | الاحتفاظ والتحفيز العاطفي | 🟡 متوسطة | 6 | نعم |
| **Phase 4** | منطق المنتج عالي المخاطر | 🔴 عالية | 4 | نعم + اختبارات |

---

## Phase 1: إصلاحات النصوص والتوطين (صفر مخاطرة)

> [!NOTE]
> هذه المرحلة تغيّر نصوص فقط — لا تمس أي منطق أعمال أو تنقل أو حالة.

---

### المهمة 1.1: إصلاح النصوص الإنجليزية المختلطة في صفحة ربط ولي الأمر
- **UX Issue**: UX-13
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [guardian_linking_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/guardian_linking_page.dart#L203-L214)
  - [app_ar.arb](file:///d:/Sayed/Flutter/talia_quran/lib/core/l10n/app_ar.arb)
  - [app_en.arb](file:///d:/Sayed/Flutter/talia_quran/lib/core/l10n/app_en.arb)
- **التغيير المطلوب**:
  1. استبدال `'Valid until ${...}'` (سطر 204) بمفتاح توطين عربي: `صالح حتى الساعة {time}`
  2. استبدال `'Regenerate code'` (سطر 213) بمفتاح توطين: `تجديد الرمز`
  3. إضافة المفاتيح الجديدة في كلا ملفي ARB
- **لماذا آمن**: تغيير نص عرض فقط، لا يمس منطق الربط أو QR.

---

### المهمة 1.2: إضافة دليل خطوات مرقّمة في صفحة ربط ولي الأمر
- **UX Issue**: UX-13
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [guardian_linking_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/guardian_linking_page.dart)
- **التغيير المطلوب**:
  1. إضافة نص إرشادي مرقّم في `_PairingCard`:
     - `١. افتح تالية على جهاز ولي الأمر`
     - `٢. اذهب إلى الإعدادات > لوحة ولي الأمر`
     - `٣. امسح رمز QR أو أدخل الرمز يدوياً`
  2. إضافة عداد تنازلي مرئي بدل النص الثابت
- **لماذا آمن**: إضافة عناصر عرض فقط.

---

### المهمة 1.3: نقل النصوص المكتوبة مباشرة (hardcoded) إلى ملفات ARB
- **UX Issue**: UX-27
- **الأولوية**: P0
- **الملفات المتأثرة** (الأعلى أولوية):

| الملف | أمثلة على النصوص المكتوبة مباشرة |
|-------|-----------------------------------|
| [path_selection_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/path_selection_page.dart) | `'مسار الحفظ'`, `'من سيستخدم هذه الميزة؟'`, `'مسار البالغين'`, `'مسار الأطفال'` |
| [kids_journey_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/kids_journey_page.dart) | `'رحلة الحفظ'`, `'خريطة الحفظ'`, `'ربط ولي الأمر عن بعد'`, `'إنشاء QR'` |
| [onboarding_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/onboarding/presentation/pages/onboarding_page.dart) | `'تخطي'`, `'ابدأ الآن'`, `'التالي'` + عناوين/أوصاف الشرائح |
| [splash_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/splash/presentation/pages/splash_page.dart) | `'تالية'`, `'تطبيق تحفيظ القرآن الكريم'` |

- **التغيير المطلوب**:
  1. إضافة كل مفتاح جديد في `app_ar.arb` و`app_en.arb`
  2. استبدال النصوص المباشرة بـ `context.l10n.keyName`
  3. إعادة توليد ملفات التوطين بـ `flutter gen-l10n`
- **لماذا آمن**: تغيير مصدر النص فقط، النص النهائي المعروض يبقى نفسه.

---

### المهمة 1.4: إضافة تلميح أول استخدام للضغط المطوّل في قارئ القرآن
- **UX Issue**: UX-22
- **الأولوية**: P1
- **الملفات المتأثرة**:
  - [quran_reader_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/quran/presentation/pages/quran_reader_page.dart)
  - SharedPreferences (مفتاح `quran_long_press_hint_seen`)
- **التغيير المطلوب**:
  1. عند أول فتح للقارئ، عرض `Banner` خفيف: `اضغط مطولاً على الآية للاستماع أو إضافة علامة`
  2. حفظ حالة الإخفاء في SharedPreferences
  3. التلميح قابل للإخفاء بزر ×
- **لماذا آمن**: عنصر UI تعليمي فقط، لا يمس عرض القرآن.

---

### المهمة 1.5: إضافة توضيح لأزرار التقييم الذاتي في الخطة اليومية
- **UX Issue**: UX-10
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [daily_plan_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/daily_plan_page.dart)
  - SharedPreferences (مفتاح `daily_plan_rating_hint_seen`)
- **التغيير المطلوب**:
  1. إضافة labels توضيحية تحت كل زر تقييم:
     - **ضعيف**: `احتجت للمصحف`
     - **متوسط**: `أخطاء بسيطة`
     - **ممتاز**: `بدون خطأ`
  2. عند أول استخدام: عرض bottom sheet تعليمي يشرح تأثير التقييم على الجدولة
  3. حفظ حالة العرض في SharedPreferences
- **لماذا آمن**: إضافة نص توضيحي فقط، لا تغيير في منطق التقييم أو SM-2.

---

### المهمة 1.6: إضافة توضيح لتأثير زر التخطي في جلسة الحفظ
- **UX Issue**: UX-21
- **الأولوية**: P1
- **الملفات المتأثرة**:
  - [hifz_session_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/hifz/presentation/pages/hifz_session_page.dart)
  - SharedPreferences (مفتاح `hifz_skip_hint_seen`)
- **التغيير المطلوب**:
  1. عند أول ضغط على "تخطي"، عرض bottom sheet:
     - `سنضيف هذه الآية للمراجعة لاحقاً، لا تقلق.`
     - زر "فهمت" لإخفاء التلميح
  2. حفظ حالة العرض
- **لماذا آمن**: إضافة توضيح لسلوك موجود، لا تغيير في منطق التخطي.

---

### المهمة 1.7: تحسين توضيح إعدادات دقة التسميع
- **UX Issue**: UX-26
- **الأولوية**: P2
- **الملفات المتأثرة**:
  - [settings_page_tiles.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/settings/presentation/pages/settings_page_tiles.dart)
  - [app_ar.arb](file:///d:/Sayed/Flutter/talia_quran/lib/core/l10n/app_ar.arb)
  - [app_en.arb](file:///d:/Sayed/Flutter/talia_quran/lib/core/l10n/app_en.arb)
- **التغيير المطلوب**:
  1. استبدال dropdown بثلاث بطاقات segmented:
     - `متسامح — مناسب للأطفال والمبتدئين`
     - `متوازن — للممارسة اليومية`
     - `دقيق — للمتقدمين`
  2. كل بطاقة تعرض النسبة المطلوبة
- **لماذا آمن**: تغيير عرض الاختيار فقط، القيم المحفوظة تبقى نفسها.

---

### المهمة 1.8: إضافة تأكيد مرئي لاحتساب صفحة القراءة
- **UX Issue**: UX-23
- **الأولوية**: P2
- **الملفات المتأثرة**:
  - [quran_reader_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/quran/presentation/pages/quran_reader_page.dart)
- **التغيير المطلوب**:
  1. عند تغيّر `isReadConfirmed` إلى `true`، عرض أيقونة ✓ صغيرة في footer
  2. الأيقونة تختفي بعد 2 ثانية بـ `AnimatedOpacity`
- **لماذا آمن**: ردود فعل بصرية فقط، لا تغيير في منطق الاحتساب.

---

## Phase 2: تبسيط التدفقات وتحسين الإرشاد (منخفضة المخاطرة)

> [!IMPORTANT]
> هذه المرحلة تغيّر تدفق الشاشات والـ routing. تحتاج مراجعة لبعض المهام.

---

### المهمة 2.1: إضافة شاشة اختيار الهدف في نهاية الـ Onboarding
- **UX Issue**: UX-01
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [onboarding_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/onboarding/presentation/pages/onboarding_page.dart)
  - SharedPreferences (مفتاح `user_primary_goal`)
- **التغيير المطلوب**:
  1. إضافة slide رابعة بعد الشرائح الثلاث الحالية:
     - `ماذا تريد أن تفعل أولاً؟`
     - 4 خيارات: `القراءة` / `الحفظ لنفسي` / `متابعة طفل` / `الأذكار`
  2. حفظ الاختيار في SharedPreferences
  3. `_completeOnboarding()` يوجّه إلى الصفحة المناسبة بناءً على الاختيار:
     - القراءة → `/quran`
     - الحفظ → `/memorization-plus`
     - متابعة طفل → `/memorization-plus/guardian-linking`
     - الأذكار → `/azkar`
  4. تحديث عدد الصفحات من 3 إلى 4
- **لماذا آمن**: إضافة شاشة اختيار فقط، لا تغيير في التدفقات الحالية.

---

### المهمة 2.2: إضافة قائمة "ابدأ من هنا" بعد تخطي الـ Onboarding
- **UX Issue**: UX-02
- **الأولوية**: P1
- **الملفات المتأثرة**:
  - [home_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/home/presentation/pages/home_page.dart)
  - [home_page_widgets.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/home/presentation/pages/home_page_widgets.dart)
  - SharedPreferences (مفتاح `onboarding_skipped`, `first_action_completed`)
- **التغيير المطلوب**:
  1. في `_completeOnboarding` عند "تخطي": حفظ `onboardingSkipped=true`
  2. في `HomePage`: عرض strip قابل للإخفاء بثلاث مهام:
     - `اقرأ صفحة` → يوجّه لـ `/quran`
     - `ابدأ الحفظ` → يوجّه لـ `/memorization-plus`
     - `دليل سريع` → يفتح tutorial guide
  3. إخفاء الـ strip بعد إتمام أول مهمة
- **لماذا آمن**: إضافة widget تعليمي فقط.

---

### المهمة 2.3: تغيير استعادة الـ Splash من deep-restore إلى Home مع بطاقة استكمال
- **UX Issue**: UX-03
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [splash_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/splash/presentation/pages/splash_page.dart#L49-L66)
  - [home_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/home/presentation/pages/home_page.dart)
  - [home_page_widgets.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/home/presentation/pages/home_page_widgets.dart)
  - [app_session_service.dart](file:///d:/Sayed/Flutter/talia_quran/lib/core/services/app_session_service.dart)

> [!WARNING]
> هذا التغيير يعدّل سلوك بدء التشغيل. يجب اختبار سيناريوهات: أول فتح، رجوع بعد جلسة عادية، رجوع بعد جلسة حفظ، رجوع بعد غياب طويل.

- **التغيير المطلوب**:
  1. في `SplashPage._navigateAfterDelay()`: دائماً `context.go(AppRoutes.home)` بدل `context.go(lastLocation)`
  2. الاحتفاظ بقيمة `lastLocation` في الذاكرة/الخدمة
  3. في `HomePage`: إذا كان `lastLocation != null && lastLocation != '/'`:
     - عرض بطاقة `استكمال من حيث توقفت` مع وصف الشاشة (حفظ/مراجعة/اختبار...)
     - زر "استكمال" يوجّه إلى `lastLocation`
     - زر "ليس الآن" يخفي البطاقة ويمسح `lastLocation`
- **لماذا آمن**: لا يمسح بيانات، فقط يغيّر نقطة الهبوط.

---

### المهمة 2.4: إضافة بطاقة "الإجراء الأفضل التالي" في الرئيسية
- **UX Issue**: UX-04
- **الأولوية**: P1
- **الملفات المتأثرة**:
  - [home_cubit.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/home/presentation/cubits/home_cubit.dart)
  - [home_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/home/presentation/pages/home_page.dart)
  - [home_page_widgets.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/home/presentation/pages/home_page_widgets.dart)
- **التغيير المطلوب**:
  1. في `HomeCubit`: حساب `nextAction` بناءً على:
     - هل هناك مراجعات مستحقة؟ → "لديك مراجعة مستحقة"
     - هل الورد اليومي مكتمل؟ → "أكمل ورد اليوم"
     - هل وقت أذكار الصباح/المساء؟ → "حان وقت الأذكار"
     - الهدف المختار من الـ onboarding
  2. عرض بطاقة CTA كبيرة فوق باقي البطاقات
- **لماذا آمن**: عرض مشتق من بيانات موجودة، لا تغيير في البيانات نفسها.

---

### المهمة 2.5: إضافة Presets لإعداد خطة الحفظ المخصصة
- **UX Issue**: UX-07
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [custom_plan_setup_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/custom_plan_setup_page.dart)
- **التغيير المطلوب**:
  1. إضافة 4 بطاقات preset قبل النموذج التفصيلي:
     - **خفيف**: 3 آيات/يوم، 5 أيام/أسبوع، 10 دقائق، سهل
     - **متوازن**: 5 آيات/يوم، 6 أيام/أسبوع، 15 دقيقة، متوسط
     - **مكثف**: 10 آيات/يوم، 7 أيام/أسبوع، 30 دقيقة، صعب
     - **جزء عم**: سورة الناس إلى الفيل، 3 آيات/يوم
  2. عند اختيار preset: ملء الحقول الموجودة تلقائياً
  3. نقل الإعدادات المتقدمة (مراجعة قريبة/بعيدة) خلف `ExpansionTile` بعنوان "تخصيص متقدم"
  4. إضافة بطاقة ملخص نهائية قبل زر الحفظ
- **لماذا آمن**: يستخدم نفس حقول النموذج الموجودة، لا تغيير في `CustomMemorizationPlan`.

---

### المهمة 2.6: إضافة تأكيد قبل اختيار مسار الحفظ
- **UX Issue**: UX-06
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [path_selection_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/path_selection_page.dart#L87-L105)
- **التغيير المطلوب**:
  1. عند الضغط على بطاقة المسار: عرض bottom sheet تأكيد بدل الحفظ المباشر
  2. المحتوى:
     - `ماذا سيحدث بعد ذلك؟` + وصف المسار
     - `يمكن تغييره من الإعدادات لاحقاً`
     - زر "تأكيد" + زر "رجوع"
  3. الحفظ يتم فقط بعد التأكيد
- **لماذا آمن**: إضافة خطوة تأكيد فقط، نفس البيانات تُحفظ.

---

### المهمة 2.7: نقل أدوات ربط ولي الأمر من رحلة الطفل إلى لوحة ولي الأمر
- **UX Issue**: UX-12
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [kids_journey_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/kids_journey_page.dart#L73)

> [!WARNING]
> يجب التأكد أن وظيفة الربط عن بعد تبقى متاحة من لوحة ولي الأمر.

- **التغيير المطلوب**:
  1. إخفاء `_RemoteLinkCard` من `KidsJourneyPage` بشكل افتراضي
  2. إبقاء الوصول عبر أيقونة إعدادات ولي الأمر في AppBar (موجودة بالفعل في سطر 116-125)
  3. إضافة بطاقة تحفيزية بديلة للطفل: مهمة أولى واضحة
- **لماذا آمن**: نقل widget من موقع لآخر، لا تغيير في منطق الربط.

---

### المهمة 2.8: تحسين تحذيرات الحذف وإعادة الضبط
- **UX Issue**: UX-09
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [custom_plan_setup_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/custom_plan_setup_page.dart)
  - [settings_page_tiles.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/settings/presentation/pages/settings_page_tiles.dart)
- **التغيير المطلوب**:
  1. استبدال dialog الحذف البسيط بقائمة checklist واضحة:
     - ✅ `سيبقى: الإنجازات، السجل، الشهادات`
     - ⚠️ `سيتغير: اختيار المسار والخطة الحالية`
  2. زر التأكيد يصبح أحمر مع نص واضح: `تأكيد إعادة الضبط`
- **لماذا آمن**: تغيير عرض التأكيد فقط.

---

### المهمة 2.9: إضافة بطاقة "ملخص اليوم" في لوحة ولي الأمر
- **UX Issue**: UX-15
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [parent_dashboard_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/parent_dashboard_page.dart)
- **التغيير المطلوب**:
  1. إضافة بطاقة `_TodaySummaryCard` في أعلى لوحة ولي الأمر
  2. تعرض ملخص مشتق من بيانات الـ dashboard الموجودة:
     - عدد الجلسات اليوم
     - النقاط المكتسبة
     - جملة إرشادية مثل: `اليوم: أكمل الطفل جلسة واحدة. شجعه على المراجعة القادمة.`
  3. إضافة أزرار إجراء سريع: `إضافة مكافأة` / `عرض آخر جلسة`
- **لماذا آمن**: عرض مشتق من بيانات موجودة.

---

### المهمة 2.10: تحسين تأكيد PIN ولي الأمر
- **UX Issue**: UX-14
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [parent_dashboard_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/parent_dashboard_page.dart)
- **التغيير المطلوب**:
  1. عند إنشاء PIN جديد: إضافة حقل تأكيد (إدخال PIN مرتين)
  2. شرح واضح: `هذا الرمز يحمي لوحة ولي الأمر على هذا الجهاز`
  3. تغيير نص إعادة الضبط من "نسيت الرمز؟ إعادة ضبط محلية" إلى "إعادة ضبط على هذا الجهاز — سيطلب إنشاء رمز جديد"
- **لماذا آمن**: تغيير UI فقط، نفس آلية الحفظ.

---

## Phase 3: الاحتفاظ والتحفيز العاطفي (متوسطة المخاطرة)

> [!IMPORTANT]
> هذه المرحلة تضيف عناصر تحفيزية وعاطفية. تحتاج موافقة لأنها تؤثر على تجربة المستخدم الأساسية.

---

### المهمة 3.1: إضافة "الغد" وتأثير السلسلة في احتفال إتمام الخطة اليومية
- **UX Issue**: UX-11
- **الأولوية**: P1
- **الملفات المتأثرة**:
  - [daily_plan_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/daily_plan_page.dart)
- **التغيير المطلوب**:
  1. في bottom sheet الاحتفال: إضافة:
     - `حافظت على سلسلة X أيام`
     - `موعدك القادم: المراجعة غداً`
     - زر `ذكرني غداً` (يفعّل إشعار)
- **لماذا آمن**: عرض بيانات مشتقة + ربط بإشعار موجود.

---

### المهمة 3.2: تغيير لغة الفشل إلى لغة تدريبية
- **UX Issue**: UX-19
- **الأولوية**: P1
- **الملفات المتأثرة**:
  - [quiz_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/quiz_page.dart)
  - [hifz_session_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/hifz/presentation/pages/hifz_session_page.dart)
- **التغيير المطلوب**:
  1. استبدال أيقونة الفشل الحمراء بأيقونة تدريبية (مراجعة مقترحة)
  2. تغيير `حاول مرة أخرى` إلى `نراجعها معاً`
  3. إضافة زر "استمع ثم أعد المحاولة" في نتيجة الاختبار
  4. لغة ألطف للأطفال: `تحتاج تدريباً أكثر` بدل أي إشارة فشل
- **لماذا آمن**: تغيير نصوص وأيقونات فقط، الدرجات تبقى كما هي.

---

### المهمة 3.3: إضافة شريط تقدم الجلسة في صفحة الحفظ
- **UX Issue**: UX-20
- **الأولوية**: P1
- **الملفات المتأثرة**:
  - [hifz_session_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/hifz/presentation/pages/hifz_session_page.dart)
- **التغيير المطلوب**:
  1. إضافة عنصر `آية 3 من 7` في أعلى الجلسة
  2. شريط تقدم خطي تحت العنوان
- **لماذا آمن**: عرض فقط.

---

### المهمة 3.4: تعطيل زر إتمام المراجعة في وضع الأطفال حتى اكتمال الاستماع
- **UX Issue**: UX-16
- **الأولوية**: P1
- **الملفات المتأثرة**:
  - [kids_mode_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/kids_mode_page.dart)
- **التغيير المطلوب**:
  1. تعطيل بصري لزر "أنهيت المراجعة" حتى `currentLoop >= maxLoops`
  2. عرض تقدم: `استمع {current} من {max} مرات لفتح الزر`
  3. تسمية حلقات الاستماع: `اسمع` → `ردد معي` → `آخر مرة`
- **لماذا آمن**: يستخدم `currentLoop` و `maxLoops` الموجودين، لا تغيير في المنطق.

---

### المهمة 3.5: إضافة مؤشر Undo في عداد الأذكار
- **UX Issue**: UX-24
- **الأولوية**: P1
- **الملفات المتأثرة**:
  - [azkar_category_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/azkar/presentation/pages/azkar_category_page.dart)
- **التغيير المطلوب**:
  1. إضافة زر تراجع (undo) صغير يظهر لمدة 3 ثوانٍ بعد كل increment
  2. دعم long-press للتراجع عن آخر عداد
  3. haptic feedback مميز عند اكتمال الذكر
- **لماذا آمن**: لا يؤثر على حفظ البيانات (العداد local state).

---

### المهمة 3.6: إنشاء مكوّن Banner خطأ قابل لإعادة الاستخدام
- **UX Issue**: UX-28
- **الأولوية**: P1
- **الملفات المتأثرة**:
  - **[جديد]** `lib/core/widgets/error_info_banner.dart`
  - ملفات الاستخدام الأولى:
    - [guardian_linking_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/guardian_linking_page.dart)
    - [path_selection_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/path_selection_page.dart)
    - [login_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/auth/presentation/pages/login_page.dart)
- **التغيير المطلوب**:
  1. إنشاء `ErrorInfoBanner` widget:
     - يدعم `error` / `warning` / `info` أنواع
     - يبقى مرئياً حتى الإخفاء يدوياً أو حل المشكلة
     - يدعم RTL
  2. استبدال Snackbars بالـ banner في المواقع الحرجة (auth, guardian, path selection)
- **لماذا آمن**: إضافة widget جديد + استبدال طريقة العرض فقط.

---

## Phase 4: منطق المنتج عالي المخاطر (تحتاج موافقة + اختبارات)

> [!CAUTION]
> هذه المرحلة تمس تدفقات تفاعلية تعتمد على أجهزة خارجية (ميكروفون، شبكة) أو بيانات حساسة. كل مهمة تحتاج اختبار وموافقة قبل التنفيذ.

---

### المهمة 4.1: إضافة بديل يدوي عند فشل التعرف الصوتي في الاختبار
- **UX Issue**: UX-18
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [quiz_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/quiz_page.dart)
- **التغيير المطلوب**:
  1. عند `_speechEnabled == false` أو فشل التعرف المتكرر:
     - عرض panel بديل: `التقييم اليدوي`
     - أزرار: ضعيف / متوسط / ممتاز (نفس مقياس التقييم)
  2. خيار إعادة المحاولة للميكروفون
  3. خيار تخطي الآية الحالية
- **لماذا آمن نسبياً**: يضيف مسار بديل بدون تغيير منطق التسجيل الصوتي.
- **يحتاج اختبار**: التأكد أن الدرجة اليدوية تُحفظ بنفس آلية الدرجة الصوتية.

---

### المهمة 4.2: إضافة خطأ صوت صديق للطفل في وضع الأطفال
- **UX Issue**: UX-17
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [kids_mode_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/kids_mode_page.dart)
  - Kids mode cubit (إضافة حالة `audioError` في state)
- **التغيير المطلوب**:
  1. عند فشل تشغيل الصوت: عرض banner ودود:
     - `لم يعمل الصوت الآن. جرّب مرة أخرى أو اطلب من ولي الأمر الاتصال بالإنترنت.`
  2. إضافة `audioError` property في `KidsModeLoaded` state
  3. زر إعادة المحاولة
- **يحتاج اختبار**: التأكد من عدم تعطل flow الاستماع.

---

### المهمة 4.3: إضافة التحقق من صحة رقم الآية في إعداد الخطة المخصصة
- **UX Issue**: UX-08
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [custom_plan_setup_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/custom_plan_setup_page.dart)
  - بيانات metadata السور (عدد آيات كل سورة)
- **التغيير المطلوب**:
  1. تحميل metadata السور (عدد الآيات لكل سورة)
  2. إضافة validator في TextFormField: `هذه السورة فيها X آيات`
  3. عند تغيير `_startSurahId`: clamp/reset الآية إذا تجاوزت الحد
- **يحتاج اختبار**: التحقق من صحة البيانات لكل سورة.

---

### المهمة 4.4: تحسين نموذج أمان الحذف وإعادة الضبط
- **UX Issue**: UX-09
- **الأولوية**: P0
- **الملفات المتأثرة**:
  - [custom_plan_setup_page.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/memorization_plus/presentation/pages/custom_plan_setup_page.dart)
  - [settings_page_tiles.dart](file:///d:/Sayed/Flutter/talia_quran/lib/features/settings/presentation/pages/settings_page_tiles.dart)
- **التغيير المطلوب**:
  1. للعمليات عالية المخاطر: مطالبة المستخدم بكتابة كلمة تأكيد
  2. التمييز الواضح بين حذف الخطة والاحتفاظ بالبيانات التاريخية
- **يحتاج اختبار**: التأكد أن البيانات المحذوفة هي فقط المقصودة.

---

## خطة التحقق

### اختبارات آلية
```bash
# بعد كل مرحلة
flutter analyze
flutter test
```

### اختبارات يدوية لكل مرحلة

| المرحلة | ما يجب اختباره |
|---------|---------------|
| Phase 1 | تأكيد ظهور النصوص بالعربية والإنجليزية بشكل صحيح، RTL سليم |
| Phase 2 | تدفق Onboarding كامل، استعادة الجلسة، path selection، presets |
| Phase 3 | احتفال الإتمام، عداد الأذكار + undo، banners الأخطاء |
| Phase 4 | الاختبار الصوتي مع ميكروفون / بدونه، أخطاء الصوت في وضع الأطفال |

### التحقق من عدم حدوث regression
- [ ] تنقل بين كل الشاشات بدون crash
- [ ] عرض القرآن لم يتغير
- [ ] بيانات الحفظ والتقدم والسلسلة سليمة
- [ ] RTL يعمل على شاشات صغيرة
- [ ] الوضع المظلم يعمل بشكل صحيح

---

## ترتيب التنفيذ المقترح

```
Phase 1 (1.1 → 1.8) → مراجعة → Phase 2 (2.1 → 2.10) → مراجعة
→ Phase 3 (3.1 → 3.6) → مراجعة → Phase 4 (4.1 → 4.4) → مراجعة نهائية
```

> [!TIP]
> يمكن البدء بـ Phase 1 فوراً دون موافقة إضافية لأنها تغييرات نصية فقط.

## أسئلة مفتوحة

1. **هل تريد البدء بمرحلة معينة أم بالترتيب المقترح؟**
2. **هل هناك مهام تريد إضافتها أو إزالتها من الخطة؟**
3. **بالنسبة للمهمة 1.3 (التوطين): هل تريد نقل كل النصوص دفعة واحدة أم ملف بملف؟**
4. **بالنسبة للمهمة 2.3 (تغيير سلوك Splash): هل أنت مرتاح لتغيير سلوك بدء التشغيل أم تفضل إبقاء deep-restore كخيار في الإعدادات؟**
