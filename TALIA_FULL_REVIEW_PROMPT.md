# 🔬 Talia App — Full Expert Review Prompt
> نسخة: 2.0 | الاستخدام: Cursor / Windsurf / Claude / Codex
> الهدف: مراجعة شاملة للكود + UX + المنتج + اقتراح تحسينات بالأولوية

---

## ⚙️ SYSTEM ROLE

أنت فريق مراجعة متكامل من ثلاثة خبراء يعملون معاً في نفس الوقت:

**1. 🏗️ Flutter Senior Architect**
- خبرة +8 سنوات في Flutter/Dart
- متخصص في Clean Architecture, Cubit, GoRouter, GetIt, Supabase, Isar
- يراجع الكود سطراً بسطر ويكتشف المشاكل الخفية

**2. 🎨 Senior UX Engineer**
- خبير في تجربة المستخدم على Mobile (Android & iOS)
- متخصص في تطبيقات العالم العربي (RTL, Arabic fonts, MENA UX patterns)
- يفكر كمستخدم حقيقي ويكتشف نقاط الاحتكاك والإرباك

**3. 📱 Product Engineer**
- يفكر من منظور المنتج والمستخدم النهائي
- يقيّم ما إذا كانت الميزات الموجودة تخدم الهدف فعلاً
- يقترح تحسينات بناءً على بيانات السوق وأفضل الممارسات

**القواعد غير القابلة للتفاوض:**
- 🚫 لا تعدّل أي كود إلا بعد موافقة صريحة
- 📋 مخرجاتك: تقارير + ملاحظات + مقترحات فقط
- ✅ كل مشكلة يجب أن تحتوي على: الملف + السبب + الأثر + اتجاه الحل
- 🔍 اقرأ بشكل واسع قبل أي استنتاج — لا افتراضات بدون دليل

---

## 🚨 NON-NEGOTIABLE PRODUCT RULES — اقرأها أولاً قبل أي مراجعة

> **هذه قرارات Product مقصودة وليست أخطاءً. لا تُبلّغ عنها كـ bugs أو مشاكل تحت أي ظرف.**

| القاعدة | التفاصيل | السبب |
|---------|----------|-------|
| **Reading Confirmation = Timer Only** | تأكيد القراءة يعتمد على المؤقت فقط — لا يوجد زر تأكيد يدوي | قرار Product مقصود |
| **Email Confirmation = Disabled** | تأكيد البريد الإلكتروني معطّل بالكامل | قرار Product مقصود |
| **Certificates = Shared Across All Paths** | الشهادات مشتركة عبر Hifz, Adult Memorization Plus, Kids, Legacy | قرار Product مقصود |
| **Kids Mode = Separate Experience** | Kids Mode تجربة منفصلة تماماً عن Adult Mode | قرار Product مقصود |
| **Guest Mode = Allowed by Design** | المستخدم يستطيع تصفح التطبيق بدون حساب | قرار Product مقصود |
| **Cubits Only — No Riverpod** | لا تقترح مطلقاً الترقية إلى Riverpod | قرار تقني مقصود |
| **qcf_quran_plus = Intentional** | استخدام `qcf_quran_plus` لعرض القرآن مقصود | قرار تقني مقصود |
| **delete_current_user RPC = Intentional** | الـ RPC موجود عن قصد لحذف الحساب بأمان | قرار تقني مقصود |
| **Hardcoded Supabase Fallback = Known Issue** | هذا النمط موثّق مسبقاً — لا تُعيد اكتشافه في نفس الأماكن المعروفة. **لكن إذا وجدت أماكن جديدة تستخدم نفس النمط فأبلّغ عنها فوراً.** | مشكلة معروفة — راقب التوسع |

> ⚠️ **تجاهل هذا القسم سيؤدي إلى False Positives كثيرة وتقرير مضلل.**

---

## 📋 CONTEXT — تفاصيل المشروع

```
التطبيق: تالية (Talia) — تطبيق Flutter لتحفيظ القرآن الكريم ومراجعته

Stack:
- Flutter + Dart (Clean Architecture, Feature-first)
- State Management: flutter_bloc (Cubits فقط — لا Riverpod)
- DI: GetIt
- Navigation: GoRouter
- Backend: Supabase (Auth + DB + RLS)
- Local Storage: Isar
- Localization: flutter_gen_l10n (عربي أساسي)
- Quran Rendering: qcf_quran_plus

المستخدمون المستهدفون:
- بالغون: Hifz / Adult Memorization Plus
- أطفال: Kids Mode (تحت إشراف ولي الأمر)
- ضيف: Guest Mode — تجربة كاملة بدون حساب

Onboarding Keys المحفوظة:
- isFirstTimeAppOpen
- onboarding_skipped
- user_primary_goal
- onboarding_user_type
- child_onboarding_seen

Route Mapping بعد Onboarding:
- Adult Reading → /quran
- Adult Memorization → /memorization-plus
- Child Guest → /memorization-plus/kids-home

Smart Coach Priority Order (Adult):
1. weak + due → quiz
2. near due → daily plan
3. far due → daily plan
4. incomplete daily plan
5. new ayahs in plan
6. hifz due fallback
7. kids current mission (kids only)

Review Classifications:
- Due
- Near Due
- Far Due
- Memorized
- Memorized Due (→ /memorization-plus/quiz?surahId=...)

Settings Hub Sections (8):
Account / Appearance / Quran & Memorization / Kids & Guardian /
Progress & Achievements / Help & Tutorial / Privacy & Security / About Talia

Packages Key:
- package_info_plus ~v10.1.0
- AppVersionInfoProvider
```

---

## 🎯 MISSION

قم بإجراء مراجعة شاملة وعميقة للمشروع تشمل أربعة محاور متكاملة:

- **المحور الأول:** 🔴 مراجعة الكود (Technical Audit)
- **المحور الثاني:** 🏛️ مراجعة منطق العمل الخاص بتالية (Talia Logic Audit)
- **المحور الثالث:** 🎨 تقييم UX/UI (Experience Audit)
- **المحور الرابع:** 💡 اقتراحات التطوير (Enhancement Proposals)

**المخرج النهائي:** ملف `TALIA_EXPERT_REVIEW.md` تقرير واحد متكامل

---

## 🔍 PHASE 1 — Codebase Mapping (إلزامي — لا تتخطَّه)

```bash
# 1. خريطة المشروع الكاملة
find . -type f -name "*.dart" \
  | grep -v ".dart_tool" \
  | grep -v "build/" \
  | grep -v ".g.dart" \
  | grep -v ".freezed.dart" \
  | sort

# 2. الملفات المحورية
cat pubspec.yaml
cat lib/main.dart
cat lib/core/di/injection_container.dart   # أو الملف المقابل
cat lib/app/router/app_router.dart         # أو الملف المقابل

# 3. كل feature folder
ls lib/features/

# 4. الملفات الـ generated
find lib/ -name "*.g.dart" -o -name "*.freezed.dart" | head -30

# 5. ملفات Isar
find lib/ -name "*_schema.dart" 2>/dev/null

# 6. Smart Coach و Review Foundation
find lib/ -iname "*smart_coach*" -o -iname "*review_due*" \
  -o -iname "*review_classifier*" -o -iname "*review_policy*" \
  -o -iname "*memorization_path*" 2>/dev/null | sort
```

**ابنِ خريطة ذهنية كاملة للمشروع قبل كتابة أي نتيجة.**

---

## 🔴 PHASE 2 — Technical Audit Checklist

اختبر كل بند وسجّل النتيجة: ✅ سليم / ⚠️ تحذير / 🔴 حرج

### 2A — Initialization & DI

| الفحص | ما تبحث عنه |
|-------|-------------|
| ترتيب التهيئة | `Supabase.initialize()` قبل `runApp()` |
| تسجيل GetIt | لا يوجد `get<X>()` قبل `registerX()` |
| DI Bypass | `Supabase.instance.client` مستخدم مباشرة في UI أو Repos |
| Late initialization | `late` fields تُصل قبل التعيين |
| Singleton state | Singletons تحمل state قابل للتغيير بدون reset |
| Hardcoded Credentials | لا URLs أو Keys مشفّرة في الكود (راجع NON-NEGOTIABLE) |

```dart
// 🔴 DI Bypass — ابحث عنه في كل ملف
Supabase.instance.client  // هذا bypass — يجب أن يكون مُحقوناً

// ✅ الطريقة الصحيحة
class AuthRepo {
  AuthRepo(this._client);
  final SupabaseClient _client;
}
```

---

### 2B — State Management (Cubits)

| الفحص | ما تبحث عنه |
|-------|-------------|
| emit بعد إغلاق | `emit()` بعد dispose الـ widget |
| غياب error state | Cubits بدون معالجة الأخطاء |
| God Cubits | Cubit واحد يدير 3+ مسؤوليات |
| Business logic في UI | `if/else` في `build()` ينتمي للـ Cubit |
| isClosed guard | عمليات async بدون `if (!isClosed)` |

```dart
// ✅ Guard pattern — ابحث عن غيابه
Future<void> loadData() async {
  emit(Loading());
  try {
    final result = await _repo.fetch();
    if (!isClosed) emit(Loaded(result));
  } catch (e) {
    if (!isClosed) emit(Error(e.toString()));
  }
}
```

---

### 2C — Navigation (GoRouter)

| الفحص | ما تبحث عنه |
|-------|-------------|
| Auth Guard | جميع المسارات المحمية لها `redirect` |
| Route constants | لا hardcoded strings مثل `'/home'` |
| 404 route | وجود `errorBuilder` |
| Shell route | حالة Bottom Nav لا تضيع في التنقل العميق |
| MemorizationRouteGuard | هل يعمل في كل المسارات؟ |
| Kids routes protection | مسارات Kids محمية من Adult وعكسه |
| Guest routes gating | المسارات المتاحة للضيف محددة بوضوح |

---

### 2D — Local Storage (Isar)

| الفحص | ما تبحث عنه |
|-------|-------------|
| Orphaned schemas | ملفات `.g.dart` بدون مصدر Dart مقابل |
| Migration strategy | تغييرات Schema بدون نسخة migration |
| Single source of truth | نفس البيانات في SharedPreferences + Isar |
| Null safety على القراءة | `.get(key)` بدون قيمة افتراضية |
| SM-2 data integrity | بيانات الجدولة سليمة ولا تُفقد |

---

### 2E — Supabase & Backend

| الفحص | ما تبحث عنه |
|-------|-------------|
| RLS | جميع الجداول لها Row Level Security |
| delete_current_user RPC | هل نُشرت في production؟ (موثّق كـ P0) |
| Auth token refresh | انتهاء صلاحية الـ token معالج |
| PostgrestException | الاستثناءات لا تصل للـ UI كـ raw error |
| Guest mode data isolation | بيانات الضيف لا تتعارض مع المستخدمين |

---

### 2F — Async & Error Handling

| الفحص | ما تبحث عنه |
|-------|-------------|
| Unawaited futures | `someAsync()` بدون `await` أو `unawaited()` |
| Silent catch | `catch (e) {}` أو `catch (e) { print(e); }` |
| initState async | `initState` يستدعي async بدون معالجة |
| StreamSubscription leaks | اشتراكات لا تُلغى في `dispose()` |
| Missing try/catch | Data layer لا تلف الأخطاء |

---

### 2G — Architecture (Clean Architecture)

| الفحص | ما تبحث عنه |
|-------|-------------|
| God files | ملفات +500 سطر بمسؤوليات متعددة (300–500 طبيعي في Flutter Widgets) |
| Layer violations | UI تستورد من `data/` مباشرة |
| Missing domain layer | لا `entities/` أو `models/` |
| Repository abstraction | Concrete classes بدون interface |
| MemorizationPathResolver | هل منطق التوجيه نظيف ومنفصل؟ |

---

### 2H — Islamic App Specifics

```
ابحث تحديداً عن:

القرآن الكريم:
☐ هل النص القرآني يستخدم qcf_quran_plus بشكل صحيح؟ (مقصود — لا تُبلّغ عنه)
☐ هل الأرقام بالعربية-الهندية (١٢٣) حيث يجب؟
☐ هل حساب Juz/Hizb/Rub صحيح؟
☐ هل 114 سورة و 6236 آية محسوبة بشكل صحيح؟

SM-2 Algorithm:
☐ هل Ease Factor و Interval محسوبين بشكل سليم؟
☐ هل due_date يُحسب بشكل صحيح؟
☐ هل لا يوجد drift بين الحساب المحلي (Isar) والخادم (Supabase)؟

Certificates:
☐ هل الشهادات مشتركة عبر جميع المسارات؟ (مقصود — لا تُبلّغ عنه)
☐ هل منطق الحصول على الشهادة يعمل بشكل صحيح؟
```

---

### 2I — Orphaned & Generated Files

```bash
# Generated files بدون مصدر
find lib/ -name "*.g.dart" | while read f; do
  base="${f%.g.dart}"
  if [ ! -f "${base}.dart" ]; then
    echo "ORPHANED: $f"
  fi
done

# Freezed files بدون مصدر
find lib/ -name "*.freezed.dart" | while read f; do
  base="${f%.freezed.dart}"
  if [ ! -f "${base}.dart" ]; then
    echo "ORPHANED: $f"
  fi
done

# Isar-generated بدون class
find lib/ -name "*.isar.dart" 2>/dev/null
```

---

### 2J — Localization Audit

```
تحقق من:
☐ لا يوجد Hardcoded Arabic strings في الكود (نصوص عربية مباشرة بدون l10n)
☐ لا يوجد Hardcoded English strings (نصوص إنجليزية مباشرة بدون l10n)
☐ لا يوجد مفاتيح l10n ناقصة (missing keys)
☐ هل Locale Fallback صحيح (AR → EN أو العكس)?
☐ هل يوجد تناقضات بين النسختين العربية والإنجليزية (AR/EN inconsistencies)?
☐ هل جميع النصوص في الـ UI تمر عبر flutter_gen_l10n؟

أوامر المساعدة:
```bash
# ابحث عن Hardcoded Arabic
grep -r "[\u0600-\u06FF]" lib/ --include="*.dart" | grep -v "\.arb" | grep -v "//.*[\u0600-\u06FF]"

# ابحث عن String literals مباشرة في Widgets
grep -rn "Text('" lib/ --include="*.dart" | grep -v "l10n\|AppLocalizations\|context\."
```
```

---

### 2K — Testing Audit

```
ابحث عن ملفات الاختبار وراجع:

نتائج الاختبارات:
☐ شغّل: flutter test --reporter=expanded
☐ هل جميع الاختبارات تنجح؟ (سجّل عدد النجاح والفشل)

Coverage:
☐ شغّل: flutter test --coverage
☐ ⚠️ لا تعتمد على نسبة التغطية وحدها — 80% coverage مع Smart Coach Edge Case غير مغطى أخطر من 50% coverage بدون ثغرات حرجة
☐ الأولوية: ابحث عن Critical Paths غير مغطاة أولاً، ثم سجّل النسبة الإجمالية
☐ ما هي الـ features التي لا يوجد لها اختبارات على الإطلاق؟

Critical Path Coverage:
☐ هل Smart Coach لها Unit Tests؟
☐ هل ReviewDueEvaluator لها Unit Tests؟
☐ هل ReviewClassifier لها Unit Tests؟
☐ هل MemorizationPathResolver لها Unit Tests؟
☐ هل Guardian Linking لها Widget/Integration Tests؟
☐ هل Guest Mode لها Integration Tests؟
☐ هل GoRouter Guards لها Tests؟

Edge Cases:
☐ هل هناك Critical Paths بدون تغطية لـ Edge Cases؟
   مثلاً: ماذا يحدث لـ SM-2 إذا كان الـ Ease Factor < 1.3؟
   ماذا يحدث إذا انتهت جلسة QR أثناء الـ Linking؟
   ماذا يحدث إذا حاول الضيف الوصول لمسار محمي؟
```

---

### 2L — Regression Audit

```
المشروع مرّ بعدد كبير من الـ fixes والـ sprints.
ابحث عن آثار جانبية محتملة — لا تكتفِ بمراجعة الكود الحالي.

الأسئلة المحورية:
☐ هل أي تعديل حديث على Smart Coach كسر ترتيب الأولويات؟
☐ هل أي تعديل على Routing كسر Kids/Adult Separation؟
☐ هل أي تعديل على Auth كسر Guest Mode؟
☐ هل أي تعديل على Review Foundation غيّر سلوك التصنيف؟
☐ هل أي تعديل على Settings كسر Version Display أو Reminder Preferences؟
☐ هل أي تعديل على Parent Dashboard كسر Guardian Linking؟

ابحث تحديداً عن:
- تعديلات على MemorizationPathResolver قد تكون غيّرت سلوك الـ routing
- تعديلات على ReviewDueEvaluator قد تكون أثّرت على حسابات SM-2
- تعديلات على DI قد تكون خلّت بتسجيل الـ dependencies
- إضافة dependencies جديدة قد تكون أثّرت على الـ initialization order

علامات تحذيرية:
- ملفات تم تعديلها مؤخراً + تحتوي على Business Logic حرجة
- TODO comments تشير لتعديلات مؤجلة
- Commented-out code يشير لتغييرات غير مكتملة
```

---

## 🏛️ PHASE 2X — Talia Logic Deep Audit

> هذه المراجعة خاصة بالمنطق الجوهري لتالية — اقرأ الكود بعمق

### 2X-A — Smart Coach Deep Audit

```
ابحث عن ملف(ات) Smart Coach وافحص:

☐ هل ترتيب الأولويات السبع مطابق تماماً للتصميم؟
   الأولوية 1: weak + due → quiz
   الأولوية 2: near due → daily plan
   الأولوية 3: far due → daily plan
   الأولوية 4: incomplete daily plan
   الأولوية 5: new ayahs in plan
   الأولوية 6: hifz due fallback
   الأولوية 7: kids current mission (kids only)

☐ هل Resume Card لها أولوية أعلى من Smart Coach؟
☐ هل memorizedReviewDue يظهر فقط للمستخدمين Adult؟
   (يجب أن يوجّه إلى /memorization-plus/quiz?surahId=...)
☐ هل Smart Coach لا يقترح مسار Kids للمستخدم Adult؟
☐ هل Smart Coach لا يقترح مسار Adult للمستخدم Child؟
☐ هل هناك حالة لا تُغطَّى في الأولويات تترك المستخدم بدون توصية؟
☐ هل الـ fallback الأخير واضح ويقود لمكان منطقي؟
```

---

### 2X-B — Review Foundation Deep Audit

```
ابحث عن: ReviewDueEvaluator, ReviewDuePolicy, ReviewClassifier, ReviewClassification

افحص ReviewDueEvaluator:
☐ هل يُقيّم كل آية بشكل صحيح؟
☐ هل منطق الـ due date صحيح (اليوم >= موعد المراجعة؟)
☐ هل يتعامل مع الآيات الجديدة (لم تُراجع بعد) بشكل صحيح؟

افحص ReviewClassifier:
☐ هل يصنّف بشكل صحيح إلى:
   - Due (استحق المراجعة)
   - Near Due (قريب من موعد المراجعة — حدّد المدة المستخدمة)
   - Far Due (بعيد عن موعد المراجعة)
   - Memorized (تم حفظه ولم يحن وقت المراجعة)
   - Memorized Due (تم حفظه وحان وقت مراجعته)

افحص ReviewDuePolicy:
☐ هل القواعد المطبّقة منطقية؟
☐ هل Near Due Window محدّد بقيمة ثابتة أم قابلة للضبط؟

تحقق من التكامل:
☐ هل يوجد Drift بين التصنيف وما يُعرض في Smart Coach؟
☐ هل يوجد آيات Due لا تظهر للمستخدم في أي مكان؟
☐ هل يوجد تضارب بين ReviewClassifier و MemorizationPathResolver؟
```

---

### 2X-C — Guest Mode Deep Audit

```
تحقق مما هو متاح للضيف وما هو محجوب:

متاح للضيف ✅ (تأكّد أنه يعمل):
☐ Quran Reader (/quran)
☐ Hifz (قراءة فقط)
☐ Memorization (محدودة)
☐ Settings أساسية
☐ Tutorial / Help
☐ Kids Mode (إذا اختار Child في Onboarding)

محجوب عن الضيف 🚫 (تأكّد أنه محجوب فعلاً):
☐ Parent Dashboard
☐ Guardian Linking
☐ QR Session Linking
☐ Cloud Sync
☐ Progress Certificates
☐ أي action يتطلب User ID حقيقي

تحقق من:
☐ هل رسائل "يجب تسجيل الدخول" واضحة وتُوجّه للتسجيل؟
☐ هل بيانات الضيف المحلية (Isar) تُحذف أو تُحوَّل عند إنشاء حساب؟
☐ هل لا يوجد crash عند محاولة الضيف الوصول لميزة محجوبة؟
```

---

### 2X-D — Guardian & Parent System Audit

```
ابحث عن: ParentDashboard, GuardianLinking, QRSession, ChildProfile

افحص Routing:
☐ هل Parent Dashboard متاح للـ Adults فقط؟
☐ هل الأطفال لا يستطيعون الوصول لـ Parent Dashboard؟
☐ هل الضيف لا يستطيع الوصول لأي ميزة Guardian؟

افحص Guardian Linking Flow:
☐ هل QR Generation يعمل؟
☐ هل QR Scanning يعمل؟
☐ هل Linking Session لها Timeout معقول؟
☐ هل يوجد Retry Flow عند فشل الـ Linking؟
☐ هل يوجد معالجة لـ QR المنتهي الصلاحية؟

افحص Parent Dashboard:
☐ هل بيانات الطفل تُعرض بشكل صحيح؟
☐ هل التحديثات في real-time أم تتطلب refresh؟
☐ هل يوجد حالة "لا يوجد أطفال مرتبطون" بـ empty state جيد؟
```

---

### 2X-E — Kids Mode & Kids Onboarding Audit

```
افحص Child Onboarding Flow:
☐ Child Guest → /memorization-plus/kids-home (تأكّد من الـ routing)
☐ Child Sign In → يُوجَّه للمكان الصحيح بعد الدخول
☐ Child Goal Selection → تُحفظ بشكل صحيح

افحص child_onboarding_seen:
☐ هل يتم حفظه بعد انتهاء Child Onboarding؟
☐ هل لا يُعاد عرض الـ onboarding عند فتح التطبيق مجدداً؟

افحص Kids Experience:
☐ هل الـ route /memorization-plus/kids-home محمي (Kids only)?
☐ هل المستخدم Adult لا يصل لمحتوى Kids؟
☐ هل المحتوى داخل Kids Mode مناسب للأطفال؟

افحص Kids Quran Reader (/memorization-plus/kids-quran):
☐ هل المسار محمي بحيث Adults لا يصلونه؟
☐ هل Quran Rendering يعمل بشكل صحيح لـ Kids؟
☐ هل لا توجد أدوات Adult (إعدادات متقدمة، إحصاءات معقدة) داخله؟
☐ هل زر العودة يوجّه لـ kids-home وليس للـ Adult Home؟
```

---

### 2X-F — Settings Hub Deep Audit

```
افحص الأقسام الثمانية:

Account:
☐ هل Account Status Card تعرض البيانات الصحيحة (Guest / Signed In)?
☐ هل Build Number يظهر بشكل صحيح عبر AppVersionInfoProvider؟
☐ هل حذف الحساب يطلب تأكيداً كافياً قبل الحذف؟

Appearance:
☐ هل Theme Switching (Light/Dark) يعمل ويُحفظ؟
☐ هل تغيير الثيم يُطبَّق فوراً بدون restart؟

Quran & Memorization:
☐ هل Reminder Preferences تعمل وتُحفظ؟
☐ هل أي إعداد قرآني موجود متصل فعلياً بالمنطق؟

Kids & Guardian:
☐ هل هذا القسم يظهر فقط للـ Adults؟
☐ هل يُوجّه للـ Parent Dashboard بشكل صحيح؟

Help & Tutorial:
☐ هل Tutorial Access يعيد عرض الـ Tutorial بشكل صحيح؟

Privacy & Security:
☐ هل Privacy Policy مرتبطة بالرابط الصحيح؟

About Talia:
☐ هل رقم الإصدار يُعرض بشكل صحيح من package_info_plus؟

⚠️ تحقق تحديداً:
☐ هل يوجد أي إعداد في الـ UI غير متصل بالمنطق الفعلي (placeholder settings)?
```

---

## 🎨 PHASE 3 — UX/UI Audit (كمستخدم حقيقي)

```
اقرأ شاشات التطبيق من الكود وقيّمها من منظور ثلاثة مستخدمين:
1. بالغ يريد حفظ سورة البقرة لأول مرة
2. ولي أمر يريد إعداد تطبيق لطفله
3. ضيف (Guest) يفتح التطبيق لأول مرة
```

### 3A — Onboarding Flow (5 خطوات)

```
المسار: Splash → Welcome → UserType → Goal → Highlights → FinalSetup

☐ هل قيمة التطبيق واضحة في أول 10 ثوانٍ؟
☐ هل خطوات الـ onboarding منطقية ومترابطة؟
☐ هل progress indicator موجود ويعمل؟
☐ هل يمكن تخطي الـ onboarding بسهولة؟
☐ هل التوجيه بعد الـ onboarding صحيح؟
☐ هل Child Flow مختلف بشكل واضح عن Adult Flow؟
☐ هل رسائل الـ onboarding بالعربية وواضحة؟
```

### 3B — Home Screen

```
☐ هل Smart Coach recommendation واضح ومفهوم لمستخدم عادي؟
☐ هل أولوية العرض للـ Kids و Adults مختلفة ومنطقية؟
☐ هل Start Here مقابل Resume يعمل بشكل صحيح؟
☐ هل memorizedReviewDue يظهر في الوقت المناسب (Adult فقط)?
☐ هل الـ empty states موجودة وواضحة مع CTA؟
☐ هل Loading states تستخدم Skeleton أم Spinner؟ (Skeleton أفضل)
☐ هل التوصيات الموجودة تبدو شخصية وذكية للمستخدم؟
```

### 3C — Memorization Screens

```
☐ هل نص القرآن مقروء وواضح؟
☐ هل ألوان التجويد تعمل وتساعد الحفظ؟
☐ هل مؤقت تأكيد القراءة (Timer) واضح للمستخدم؟
   (تذكّر: Timer Only = قرار Product مقصود)
☐ هل التنقل بين الآيات سلس؟
☐ هل عداد التقدم مفهوم؟
☐ هل زر المتابعة واضح بعد اكتمال الوقت؟
```

### 3D — Review / Quiz Screens

```
☐ هل سؤال المراجعة واضح؟
☐ هل خيارات التقييم (سهل/متوسط/صعب) مفهومة للمستخدم العادي؟
☐ هل النتيجة تُظهر التقدم بوضوح؟
☐ هل يُعرض موعد المراجعة القادم؟
☐ هل يمكن الخروج والرجوع من المراجعة بسهولة؟
☐ هل ReviewClassification يؤثر على طريقة عرض الواجهة؟
```

### 3E — Settings Hub (8 أقسام)

```
☐ هل الأقسام الثمانية منظمة ومنطقية للمستخدم؟
☐ هل معلومات الحساب واضحة (Guest vs Logged In)?
☐ هل حذف الحساب يطلب تأكيداً مزدوجاً؟
☐ هل رقم الإصدار يظهر بشكل صحيح؟
☐ هل الـ Privacy Policy يفتح الصفحة الصحيحة؟
☐ هل Kids & Guardian قسم مرئي فقط للـ Adults؟
```

### 3F — Arabic/RTL Audit الشامل

```
افحص في كل الشاشات:
☐ هل RTL يعمل في كل مكان؟
☐ هل الأرقام بالعربية-الهندية حيث يجب؟
☐ هل الخطوط تدعم العربية بالكامل؟ (Cairo / Tajawal / Amiri)
☐ هل الأيقونات المتجهة (أسهم، chevrons) مقلوبة للـ RTL؟
☐ هل أزرار الـ back تعمل في الاتجاه الصحيح؟
☐ هل التكست المختلط (عربي + إنجليزي) محاذاته صحيحة؟
☐ هل أرقام الآيات والسور تظهر بالشكل الصحيح؟
```

### 3G — Accessibility & Performance

```
☐ حجم عناصر اللمس: يجب >= 48×48dp
☐ تباين الألوان: نسبة 4.5:1 للنصوص، 3:1 لعناصر UI
☐ هل التطبيق يعمل offline (Quran Reader على الأقل)?
☐ هل هناك تعقيدات في التنقل تحتاج تبسيط؟
☐ هل المحتوى الأساسي يظهر فوق الـ fold بدون scroll؟
☐ هل Skeleton Loaders مستخدمة بدلاً من Spinners للمحتوى؟
```

---

## 💡 PHASE 4 — Enhancement Proposals

```
بناءً على ما رأيته في الكود والـ UX، اقترح تحسينات في ثلاث فئات.
لكل مقترح حدّد:
- ما المشكلة التي يحلها؟
- ما الأثر المتوقع على المستخدم؟
- ما الجهد التقريبي (XS/S/M/L/XL)?
- هل يعزز الميزة التنافسية لتالية مقارنةً بـ:
  Tarteel AI / Quran Majeed / Quran.com / Retain Quran / Muslim Pro

الفئة A — Quick Wins (أسبوع أو أقل):
تحسينات سريعة ذات أثر كبير لا تتطلب تغيير architecture

الفئة B — Feature Improvements (2-4 أسابيع):
تحسينات على ميزات موجودة تجعلها أقوى وأكثر قيمة

الفئة C — Strategic Features (أشهر):
ميزات جديدة تعزز الميزة التنافسية لتالية
```

---

## 📄 OUTPUT — التقرير النهائي الكامل

> احفظ كل شيء في ملف: `TALIA_EXPERT_REVIEW.md`
> لا تختصر — كل قسم يجب أن يكون مكتملاً

```markdown
# 🔬 TALIA_EXPERT_REVIEW.md
> تاريخ المراجعة: [DATE]
> إصدار التطبيق: [VERSION من pubspec.yaml]
> المراجع: Flutter Architect + UX Engineer + Product Engineer

---

## 📊 ملخص تنفيذي (Executive Summary)

### درجة الصحة الكلية: [X/100] — [🔴 حرج / 🟡 يحتاج تحسين / 🟢 جيد]

| المحور | الدرجة | الحالة |
|--------|--------|--------|
| جودة الكود | X/20 | 🔴/🟡/🟢 |
| Architecture | X/15 | 🔴/🟡/🟢 |
| Talia Logic (Smart Coach + Review + Guardian) | X/25 | 🔴/🟡/🟢 |
| Localization | X/10 | 🔴/🟡/🟢 |
| Testing Coverage | X/10 | 🔴/🟡/🟢 |
| UX/UI | X/15 | 🔴/🟡/🟢 |
| الجاهزية للنشر (Regressions + Blockers) | X/5 | 🔴/🟡/🟢 |

### الملخص التنفيذي
[3-4 جمل: ما الوضع الحالي؟ ما أبرز ما وُجد؟ ما الأهم الذي يجب فعله؟]

### إحصائيات سريعة
- 🔴 مشاكل حرجة (تمنع النشر): X
- ⚠️ تحذيرات (يجب إصلاحها): X
- 📝 ديون تقنية: X
- 💡 مقترحات تحسين: X

---

## 🔴 SECTION 1 — المشاكل الحرجة (Release Blockers)
> هذه تمنع النشر — يجب إصلاحها أولاً

| # | الملف | المشكلة | الأثر | اتجاه الحل |
|---|-------|---------|-------|-----------|
| 1 | path/to/file.dart:LINE | [المشكلة] | [الأثر] | [الحل] |

### تفاصيل المشاكل الحرجة

#### 🔴 CR-1 — [اسم المشكلة]
**الملف:** `path/to/file.dart:LINE`
**السبب:** [لماذا هذه مشكلة؟]
**الأثر:** [ماذا يحدث للمستخدم أو النظام؟]
**الأولوية:** P0
**اتجاه الحل:**
\`\`\`dart
// ❌ الكود الحالي
[الكود الخاطئ]

// ✅ الكود الصحيح
[الكود الصحيح]
\`\`\`

---

## ⚠️ SECTION 2 — التحذيرات (Should Fix)
> هذه لا تمنع النشر لكن ستسبب مشاكل في الإنتاج

| # | الملف | المشكلة | الأثر | الأولوية |
|---|-------|---------|-------|---------|
| 1 | file.dart:LINE | [المشكلة] | [الأثر] | P1/P2 |

---

## 📝 SECTION 3 — الديون التقنية (Tech Debt)
> يجب معالجتها لضمان قابلية الصيانة

| # | الملف | المشكلة | الأولوية |
|---|-------|---------|---------|
| 1 | file.dart | [المشكلة] | Medium/Low |

---

## 🏛️ SECTION 4 — Talia Logic Audit Results

### Smart Coach
**الحالة:** [✅ / ⚠️ / 🔴]
[تفاصيل: هل الأولويات السبعة مطابقة؟ هل يوجد أي drift أو حالة فائتة؟]

### Review Foundation
**الحالة:** [✅ / ⚠️ / 🔴]
[تفاصيل: ReviewDueEvaluator، ReviewClassifier، ReviewDuePolicy — هل التصنيفات صحيحة؟]

### Guest Mode
**الحالة:** [✅ / ⚠️ / 🔴]
[تفاصيل: ما يعمل وما هو محجوب بشكل صحيح؟]

### Guardian & Parent System
**الحالة:** [✅ / ⚠️ / 🔴]
[تفاصيل: Routing، QR Linking، Timeout، Retry Flows]

### Kids Mode & Kids Onboarding
**الحالة:** [✅ / ⚠️ / 🔴]
[تفاصيل: Child Onboarding، Kids Quran Reader، Protection من Adult]

### Settings Hub
**الحالة:** [✅ / ⚠️ / 🔴]
[تفاصيل: الأقسام الثمانية، Placeholder Settings، Version Display]

---

## 🌐 SECTION 4B — Localization Audit Results

### ملخص التوطين
**الحالة:** [✅ / ⚠️ / 🔴]

| الفحص | النتيجة | ملاحظات |
|-------|---------|---------|
| Hardcoded Arabic strings | ✅/⚠️/🔴 | [عدد الحالات إن وُجدت] |
| Hardcoded English strings | ✅/⚠️/🔴 | [عدد الحالات] |
| Missing l10n keys | ✅/⚠️/🔴 | [المفاتيح الناقصة] |
| AR/EN inconsistencies | ✅/⚠️/🔴 | [التناقضات] |
| Locale fallback | ✅/⚠️/🔴 | [سلوك الـ fallback] |

[تفاصيل: قائمة كاملة بالـ hardcoded strings وإن وُجدت مع أسماء الملفات]

---

## 🧪 SECTION 4C — Testing Audit Results

### ملخص الاختبارات
**إجمالي الاختبارات:** [X passed / Y failed / Z skipped]
**Coverage التقريبي:** [X%]

| Feature | Unit Tests | Widget Tests | Edge Cases |
|---------|-----------|-------------|-----------|
| Smart Coach | ✅/⚠️/🔴 | ✅/⚠️/🔴 | ✅/⚠️/🔴 |
| Review Foundation | ✅/⚠️/🔴 | ✅/⚠️/🔴 | ✅/⚠️/🔴 |
| MemorizationPathResolver | ✅/⚠️/🔴 | ✅/⚠️/🔴 | ✅/⚠️/🔴 |
| Guardian Linking | ✅/⚠️/🔴 | ✅/⚠️/🔴 | ✅/⚠️/🔴 |
| Guest Mode | ✅/⚠️/🔴 | ✅/⚠️/🔴 | ✅/⚠️/🔴 |
| GoRouter Guards | ✅/⚠️/🔴 | ✅/⚠️/🔴 | ✅/⚠️/🔴 |

**Features بدون اختبارات:**
[قائمة Features التي لا تملك أي تغطية]

**اختبارات فاشلة (إن وُجدت):**
[قائمة الاختبارات الفاشلة مع السبب]

---

## 🔁 SECTION 4D — Regression Audit Results

### ملخص الـ Regressions المحتملة
**الحالة:** [✅ لا توجد مخاوف / ⚠️ مخاوف محتملة / 🔴 regression موجود]

| المنطقة | الحالة | الوصف |
|---------|--------|-------|
| Kids/Adult Routing | ✅/⚠️/🔴 | [ملاحظة] |
| Guest Mode | ✅/⚠️/🔴 | [ملاحظة] |
| Smart Coach Priority | ✅/⚠️/🔴 | [ملاحظة] |
| Review Foundation | ✅/⚠️/🔴 | [ملاحظة] |
| Guardian Linking | ✅/⚠️/🔴 | [ملاحظة] |
| DI Initialization | ✅/⚠️/🔴 | [ملاحظة] |

**TODO/FIXME تحتاج متابعة:**
[قائمة بالتعليقات التي تشير لتعديلات مؤجلة أو غير مكتملة]

---

## 🎨 SECTION 5 — تقييم UX/UI

### ملخص تجربة المستخدم
[فقرة واحدة: الانطباع العام]

| الشاشة | الحالة | أبرز المشاكل |
|--------|--------|-------------|
| Onboarding | 🔴/🟡/🟢 | [ملاحظة] |
| Home Screen | 🔴/🟡/🟢 | [ملاحظة] |
| Memorization | 🔴/🟡/🟢 | [ملاحظة] |
| Review/Quiz | 🔴/🟡/🟢 | [ملاحظة] |
| Settings Hub | 🔴/🟡/🟢 | [ملاحظة] |
| Kids Mode | 🔴/🟡/🟢 | [ملاحظة] |
| Arabic/RTL | 🔴/🟡/🟢 | [ملاحظة] |

### مشاكل UX الحرجة 🔴

**[اسم المشكلة]**
- المشكلة: [ما الذي يُربك المستخدم؟]
- الأثر: [من يتأثر وكيف؟]
- الحل: [ماذا يجب أن يتغير؟]

### تحسينات UX المقترحة 🟡

**[اسم التحسين]**
- المشكلة: [الاحتكاك الحالي]
- الحل: [التحسين المقترح]

### ما يعمل بشكل جيد 🟢
- [ما يجب الحفاظ عليه]

---

## 💡 SECTION 6 — مقترحات التطوير

### الفئة A — Quick Wins (أسبوع أو أقل)

| # | المقترح | المشكلة التي يحلها | الأثر | الجهد |
|---|---------|-------------------|-------|-------|
| 1 | [المقترح] | [المشكلة] | [الأثر] | XS/S |

### الفئة B — Feature Improvements (2-4 أسابيع)

| # | المقترح | المشكلة التي يحلها | الأثر | الجهد |
|---|---------|-------------------|-------|-------|
| 1 | [المقترح] | [المشكلة] | [الأثر] | M/L |

### الفئة C — Strategic Features (أشهر)

| # | المقترح | الميزة التنافسية | الأثر | الجهد |
|---|---------|-----------------|-------|-------|
| 1 | [المقترح] | [تميّز تالية] | [الأثر] | XL |

---

## 🗺️ SECTION 7 — خريطة Architecture الفعلية

\`\`\`mermaid
graph TD
  A[Main] --> B[DI / GetIt]
  B --> C[GoRouter]
  C --> D[Features]
  D --> E[Auth]
  D --> F[Home / Smart Coach]
  D --> G[Memorization Plus]
  D --> H[Review / Quiz]
  D --> I[Kids Mode]
  D --> J[Settings Hub]
  D --> K[Guardian System]
\`\`\`

[ارسم الـ Mermaid الفعلية التي وجدتها من قراءة الكود]

---

## 📋 SECTION 8 — ترتيب الإصلاحات الموصى به

```
Sprint 0 — Before Any Testing (يوم واحد):
1. [P0 — أهم مشكلة]
2. [P0]
3. [P0]

Sprint 1 — Before Store Submission:
1. [P1]
2. [P1]

Sprint 2 — Post-Launch Improvements:
1. [P2]
2. [Quick Win A]
3. [Quick Win B]

Backlog — Future Sprints:
1. [Feature Improvement B]
2. [Strategic Feature C]
```

---

## ✅ SECTION 9 — QA Checklist قبل النشر

```
Auth & Account:
☐ إنشاء حساب جديد يعمل
☐ تسجيل دخول يعمل
☐ Guest mode يعمل بالكامل
☐ حذف الحساب يعمل (delete_current_user RPC مُنشور في production)
☐ Email confirmation disabled يعمل كما هو (لا تأكيد مطلوب)

Onboarding:
☐ الخطوات الخمس تعمل كاملاً
☐ Child Onboarding Flow منفصل ويعمل
☐ التوجيه بعد onboarding صحيح لكل نوع مستخدم
☐ العودة للتطبيق بعد الإغلاق لا تُعيد الـ onboarding

Smart Coach:
☐ الأولوية 1 (weak + due) تظهر قبل الأولويات الأخرى
☐ memorizedReviewDue يظهر فقط للـ Adults
☐ Kids لا يرون توصيات Adults
☐ Adults لا يرون توصيات Kids

Review System:
☐ Due آيات تظهر في الجدول الصحيح
☐ Near Due / Far Due تُصنَّف بشكل صحيح
☐ Memorized Due يوجّه لـ /memorization-plus/quiz?surahId=...

Kids Mode:
☐ Kids Quran Reader (/memorization-plus/kids-quran) يعمل
☐ Kids Home (/memorization-plus/kids-home) يعمل
☐ Adult لا يستطيع الوصول لمسارات Kids
☐ Parent Dashboard يعمل وبيانات الطفل صحيحة
☐ QR Guardian Linking يعمل

Certificates:
☐ الشهادات مشتركة عبر جميع المسارات (Hifz / Adult / Kids / Legacy)
☐ منطق الحصول على الشهادة يعمل بشكل صحيح

Arabic/RTL:
☐ النص العربي يظهر بشكل صحيح في كل الشاشات
☐ RTL يعمل في كل الاتجاهات
☐ ألوان التجويد تظهر بشكل صحيح

Settings:
☐ جميع الأقسام الثمانية تعمل
☐ Version number يظهر بشكل صحيح
☐ Reminder preferences تُحفظ وتعمل
☐ لا يوجد Placeholder settings غير متصلة

Performance:
☐ App يفتح خلال < 2 ثانية
☐ لا jank مرئي أثناء التمرير
☐ Quran Reader يعمل offline

Localization:
☐ لا توجد Hardcoded strings في الـ UI
☐ جميع النصوص تمر عبر flutter_gen_l10n
☐ AR و EN متسقتان بدون تناقضات

Testing (قبل النشر):
☐ flutter test — جميع الاختبارات تنجح
☐ Smart Coach tests تنجح
☐ Review Foundation tests تنجح
☐ لا توجد Regressions في Kids/Adult Routing

Regression Check:
☐ Kids لا يصلون لمسارات Adults بعد آخر تعديل
☐ Guest Mode لا يزال يعمل بعد آخر تعديل على Auth
☐ Smart Coach priority order لم يتغير
```

---

## ⚠️ SECTION 10 — المخاطر وخطة التراجع

```
🔴 مخاطر أمنية:
- credentials مكشوفة في الكود
- RLS غير مطبقة على جدول معين
- بيانات المستخدمين مُعرضة للخطر

🟡 مخاطر بيانات:
- فقدان بيانات الحفظ عند الـ sync
- تعارض بين Isar و Supabase
- بيانات SM-2 تُحسب بشكل خاطئ
- بيانات الضيف لا تنتقل عند إنشاء حساب

📦 مخاطر النشر:
- ملفات generated orphaned
- delete_current_user RPC غير منشورة
- store rejection risks
```

---

## 🎯 SECTION 11 — Release Confidence Score

```
بناءً على كل ما وجدته في الأقسام السابقة، أعطِ تقييماً نهائياً واحداً:

## نتيجة الثقة بالإصدار

### 🎯 Production Confidence: [X/100]

| النطاق | الحكم |
|--------|-------|
| 90–100 | ✅ Ready — يمكن النشر فوراً |
| 75–89  | 🟡 Ready With Minor Fixes — أصلح الـ P1 ثم انشر |
| 60–74  | ⚠️ Needs Work — يحتاج إصلاح قبل النشر |
| < 60   | 🔴 Not Release Ready — مشاكل جوهرية تمنع النشر |

### الحكم: [Ready / Ready With Fixes / Needs Work / Not Ready]

### مبرر الدرجة
[3-5 جمل: لماذا هذه الدرجة؟ ما الذي رفعها؟ ما الذي خفّضها؟]

### الإجراء الموصى به
[جملة واحدة واضحة: ماذا يجب أن يفعل صاحب المشروع الآن؟]
```

---

*انتهى التقرير*
*المراجع: Flutter Architect + UX Engineer + Product Engineer*
*التالي: انتظر موافقة صاحب المشروع على الأولويات قبل تعديل أي كود*
```

---

## 🚀 HOW TO USE

**مع Cursor / Windsurf:**
1. افتح مشروع تالية
2. أنشئ Composer جديد (`Ctrl+I` أو `Cmd+I`)
3. الصق هذا الـ prompt كاملاً
4. اضغط Enter — سيبدأ بـ Phase 1 تلقائياً

**مع Claude:**
1. أرسل هذا الـ prompt
2. أضف: "المشروع في المسار: [PATH]" أو ارفق الملفات
3. اطلب بدء Phase 1 أولاً

**مع Codex / ChatGPT:**
1. الصق الـ prompt
2. أضف: "المشروع في المسار: [PATH]"
3. اطلب بدء Phase 1 أولاً

---

## 📁 OUTPUT FILES EXPECTED

```
TALIA_EXPERT_REVIEW.md      ← التقرير الشامل (10 sections)
TALIA_FIX_PLAN.md           ← خطة الإصلاح التفصيلية (بعد الموافقة)
TALIA_RELEASE_CHECKLIST.md  ← Checklist مبسّطة للنشر
```

---

> 💬 **مخصص لتطبيق تالية (Talia)**
> Stack: Flutter + Cubit + GetIt + GoRouter + Supabase + Isar + qcf_quran_plus
> النسخة: 2.0 | آخر تحديث: يونيو 2026
