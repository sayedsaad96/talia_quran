# تقرير مراجعة مشروع تالية (Talia Quran) — خطة الإصلاح والتطوير الشامل

> **تاريخ المراجعة:** 2026-04-25  
> **المراجع:** Senior Flutter Engineer  
> **المشروع:** `github.com/sayedsaad96/talia_quran`  
> **الحالة:** ❌ غير جاهز للنشر — يحتاج إصلاحات حرجة أولاً

---

## فهرس التقرير

1. [ملخص تنفيذي](#-ملخص-تنفيذي)
2. [🔴 بلوكرز — مشاكل حرجة تمنع النشر](#-بلوكرز)
3. [🟡 مشاكل معمارية رئيسية](#-مشاكل-معمارية)
4. [🟠 مشاكل في طبقة البيانات](#-مشاكل-البيانات)
5. [🔵 مشاكل UX وواجهة المستخدم](#-مشاكل-ux)
6. [🟢 مشاكل جودة الكود](#-جودة-الكود)
7. [🚀 التحسينات المقترحة — Phase 1 (ضرورية)](#-تحسينات-phase-1)
8. [✨ التحسينات المقترحة — Phase 2 (تنافسية)](#-تحسينات-phase-2)
9. [💡 التحسينات المقترحة — Phase 3 (مستقبلية)](#-تحسينات-phase-3)
10. [📋 خطة التنفيذ بالأولوية](#-خطة-التنفيذ)
11. [🏗 البنية المعمارية المقترحة للنظام الموحد](#-البنية-المعمارية-المقترحة-للنظام-الموحد)

---

## ملخص تنفيذي

المشروع مبني على أساس معماري جيد (Clean Architecture + BLoC/Cubit + GetIt + GoRouter) ويظهر جهدًا حقيقيًا في التصميم والتفكير في تجربة المستخدم. إلا أن هناك **مشاكل حرجة** تجعله غير جاهز للنشر بصورته الحالية، أبرزها:

- **نظامان للحفظ لا يتكلمان مع بعضهما** → بيانات ضائعة وإحصائيات خاطئة
- **Hard Reset للتقدم عند فشل التسميع** → تجربة مدمرة للمستخدم
- **`print()` داخل `build()` method** → يُنفَّذ عند كل إعادة رسم
- **صوت القرآن من 3 CDNs مختلفة** → أحدها غير مستخدم أبدًا
- **منطق BusinessLogic داخل الـ Widget** (BookmarkService)

---

## 🔴 بلوكرز

### BUG-001 — Hard Reset كامل عند فشل التسميع ❌ CRITICAL

**الملف:** `lib/features/hifz/presentation/cubits/hifz_session_cubit.dart`

**المشكلة:** عندما يفشل المستخدم في تسميع آية (similarity < 0.85)، يتم مسح **كل تقدمه** بالكامل:

```dart
// ❌ الكود الحالي — يمسح 90 يومًا من التقدم عند فشل واحد
if (pass) {
  currentProgress = currentProgress.advanceWithSpacedRepetition();
} else {
  currentProgress = AyahProgressModel.initial(surahId, ayahNumber); // ← RESET TO ZERO
}
```

**التأثير:** مستخدم راجع آية 30 مرة على مدار 3 أشهر — يفشل مرة واحدة — يضيع كل شيء. هذا سيُحبط المستخدمين ويدفعهم لحذف التطبيق.

**الإصلاح المطلوب:**
```dart
// ✅ soft penalty — يُخفِّض التقدم بدلاً من محوه
if (pass) {
  currentProgress = currentProgress.advanceWithSpacedRepetition();
} else {
  // أعد الجدولة لغد بدلاً من الحذف الكامل
  currentProgress = AyahProgressModel(
    surahId: currentProgress.surahId,
    ayahNumber: currentProgress.ayahNumber,
    status: currentProgress.repetitions > 2 ? AyahStatus.review : AyahStatus.learning,
    repetitions: (currentProgress.repetitions - 1).clamp(0, 999), // خفض واحد فقط
    nextReviewDate: DateTime.now().add(const Duration(days: 1)),
    lastReviewDate: DateTime.now(),
  );
}
```

---

### BUG-002 — `print()` داخل `build()` ❌ CRITICAL

**الملفات:** `hifz_session_page.dart` + `hifz_session_cubit.dart`

```dart
// ❌ داخل _FullSurahSession.build() — يعمل عند كل rebuild
print('HIFZ SESSION LOADED: currentIndex=${state.currentIndex}, isRecording=${state.isRecording}');

// ❌ في cubit — يكشف أخطاء داخلية في production
onError: (val) => print('STT Error: $val'),
onStatus: (val) => print('STT Status: $val'),
```

**الإصلاح:** حذف الـ `print` بالكامل أو استبدالها بـ `debugPrint` wrapped بـ `kDebugMode`:
```dart
if (kDebugMode) {
  debugPrint('HIFZ SESSION: currentIndex=${state.currentIndex}');
}
```

---

### BUG-003 — نظامَان للحفظ منفصلان تمامًا ❌ CRITICAL

**الملفات:** `hifz/` feature vs `memorization_plus/` feature

هذه أكبر مشكلة معمارية في المشروع. النظامان يستخدمان:

| الجانب | Hifz Feature | MemorizationPlus Feature |
|---|---|---|
| مفاتيح التخزين | `hifz_progress_{s}_{a}` | `mem_plus_review_{s}_{a}` |
| نموذج البيانات | `AyahProgressModel` | `AyahReviewRecordModel` |
| خوارزمية SM-2 | فترات ثابتة `[1,3,7,14,30,90]` | مضاعفات `×2.5 / ×1.5 / reset` |
| طريقة التقييم | تلقائي (voice recognition) | يدوي (3 تقييمات) |
| معيار "محفوظ" | `repetitions >= 5` | `strengthLevel >= 6` |
| عند الفشل | **Hard Reset إلى صفر** ❌ | يُخفَّض بدرجة واحدة ✅ |

**النتيجة الكارثية:**
- المستخدم يحفظ من `HifzPage` → لا يظهر تقدمه في `DailyPlanPage`
- `ProgressRepository.getOverallProgress()` تقرأ من النظامَين وقد تحسب نفس الآية **مرتين**
- الإحصائيات في `ProgressPage` مضللة

**الإصلاح:** قرار معماري حاسم — راجع [البنية المقترحة](#بنية-مقترحة)

---

### BUG-004 — 3 روابط صوتية مختلفة، أحدها غير مستخدم ❌ CRITICAL

```dart
// AppConstants.audioBaseUrl — مُعرَّف ولم يُستخدم أبدًا ❌
'https://cdn.islamic.network/quran/audio/128/ar.alafasy/'

// HifzSessionCubit — URL مختلف (format: 001001.mp3)
'https://everyayah.com/data/Alafasy_128kbps/${surahStr}${ayahStr}.mp3'

// KidsModeCubit — نفس everyayah لكن مكرر ❌
'https://everyayah.com/data/Alafasy_128kbps/${surahStr}${ayahStr}.mp3'

// Ayah entity — URL ثالث (format: ayah_global_number.mp3) 
'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$number.mp3'
```

**الإصلاح:** خدمة صوتية مركزية (`AudioService`) تحتوي على URL واحد ومنطق بناء الرابط.

---

### BUG-005 — `BookmarkService` يُستدعى مباشرة من الـ Widget ❌

**الملف:** `lib/features/quran/presentation/pages/quran_reader_page.dart` (سطر 372)

```dart
// ❌ Business logic داخل Widget — انتهاك Clean Architecture
getIt<BookmarkService>().toggle(
  BookmarkEntry(
    surahName: "سورة", // ← اسم السورة hardcoded وخاطئ!
    ...
  ),
);
```

**مشكلتان في سطر واحد:**
1. استدعاء مباشر من Widget دون Cubit
2. اسم السورة الغلط `"سورة"` بدلاً من الاسم الحقيقي

---

### BUG-006 — زر تشغيل الصوت في القارئ غير مكتمل ❌

**الملف:** `quran_reader_page.dart` سطر 349

```dart
_OptionBtn(
  icon: Icons.play_circle_fill_rounded,
  label: context.l10n.play,
  onTap: () {
    // Play logic would go here  ← ❌ كود فارغ يُنشر كـ production
    Navigator.pop(context);
  },
),
```

---

### BUG-007 — `SplashPage` و`OnboardingPage` تصلان لـ SharedPreferences مباشرة ❌

**الملفات:** `splash_page.dart` + `onboarding_page.dart`

```dart
// ❌ تجاوز نظام DI — يُنشئ instance جديد من SharedPreferences
final prefs = await SharedPreferences.getInstance();
final bool isFirstTime = prefs.getBool('isFirstTimeAppOpen') ?? true;
```

يجب استخدام `getIt<SharedPreferences>()` أو تمرير قيمة عبر `ProfileCubit`.

---

## 🟡 مشاكل معمارية

### ARCH-001 — `ProfileCubit` في الطبقة الخاطئة

```
❌ الموضع الحالي:  features/settings/data/profile_cubit.dart
✅ الموضع الصحيح: features/settings/presentation/cubits/profile_cubit.dart
```

Cubit هو presentation layer concern — لا يجب أن يكون في `data/`.

---

### ARCH-002 — `HomeCubit` و`KidsModeCubit` يعتمدان على `QuranRepository` مباشرة

```dart
// ❌ Cubit يعتمد على Repository مباشرة بدلاً من UseCase
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getProgress, this._getHifzProgress, 
            this._quranRepository,  // ← يجب أن يكون GetDailyWirdUsecase
            this._memorizationPlusRepository) ...
}
```

انتهاك للقاعدة: Presentation layer تعتمد على Use Cases فقط، لا على Repositories.

---

### ARCH-003 — `ProgressRepository` تعتمد على datasource من feature أخرى

```dart
// ❌ ProgressRepository تستدعي datasource من MemorizationPlus مباشرة
class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._progressDs, this._hifzDs, this._memPlusDs);
  final MemorizationPlusLocalDatasource _memPlusDs; // ← يجب أن يكون Repository
}
```

يجب أن تعتمد على `MemorizationPlusRepository` (interface) لا على datasource مباشرة.

---

### ARCH-004 — `DailyPlanCubit` يستدعي Repository مباشرة

```dart
// ❌ في DailyPlanCubit
_repository.saveDailyPlan(updatedPlan); // ← بدون use case، والنتيجة مهملة
```

`saveDailyPlan` يُستدعى بدون `await` ونتيجته مهملة — إذا فشل الحفظ لا أحد يعلم.

---

### ARCH-005 — `_hifzDatasource` محقون لكن مهمل بالكامل

```dart
// memorization_plus_repository_impl.dart
// ignore: unused_field
final HifzLocalDatasource _hifzDatasource; // ← محقون ومدفوع ثمنه، لكن لا يُستخدم
```

---

### ARCH-006 — `SurahHifzProgress.totalAyahs` غلط

```dart
// hifz_repository_impl.dart — getAllSurahProgress()
return SurahHifzProgress(
  surahId: e.key,
  totalAyahs: ayahs.length, // ← ❌ هذا عدد الآيات المُتتبعة فقط، لا إجمالي السورة!
  memorizedCount: ...
);
```

نسبة التقدم ستظهر 100% إذا حفظ المستخدم 5 آيات فقط من سورة (لأن length=5 وmemorized=5).

---

### ARCH-007 — `QuranPageState` classes لا ترث من `Equatable`

```dart
// ❌ بدون Equatable = إعادة رسم غير ضرورية على كل emit
abstract class QuranPageState {} // ← لا Equatable!
class QuranPageLoaded extends QuranPageState {
  final QuranPageDetail detail;
  final bool isReadConfirmed;
  QuranPageLoaded(this.detail, {this.isReadConfirmed = false});
}
```

---

### ARCH-008 — `_startTimerForPage` يُستدعى من `build()`

```dart
// quran_reader_page.dart
Widget build(BuildContext context) {
  ...
  if (state is QuranPageLoaded) {
    _startTimerForPage(state.detail, context); // ← side effect في build!
    return _ContinuousPageText(detail: state.detail);
  }
}
```

Side effects لا تنتمي إلى `build()` — يجب نقلها لـ `didChangeDependencies` أو `BlocListener`.

---

## 🟠 مشاكل البيانات

### DATA-001 — `isNearRevision / isFarRevision` منطقها مضلل

```dart
// memorization_entities.dart
bool get isNearRevision {
  final diff = DateTime.now().difference(lastReviewedAt).inDays;
  return diff <= 5 && !isMemorized; // ← مبني على عمر المراجعة لا الاستحقاق
}
```

آية راجعها المستخدم أمس بفترة مراجعة 30 يومًا (غير مستحقة الآن) تُعامَل كـ "near revision" وتُضاف للخطة اليومية بالخطأ.

**الإصلاح:**
```dart
// بناءً على الاستحقاق والقوة
bool get isHighPriority => isDue && strengthLevel <= 3;
bool get isLowPriority  => isDue && strengthLevel > 3;
```

---

### DATA-002 — `MemorizationDifficulty` معرَّف ولا أثر له

```dart
// CustomMemorizationPlan له difficulty field
final MemorizationDifficulty difficulty; // ← easy / moderate / challenging

// لكن ScheduleNextReviewUsecase لا يستقبله ولا يستخدمه
AyahReviewRecord schedule(AyahReviewRecord record, PerformanceRating rating) {
  // لا يوجد أي مراعاة للـ difficulty هنا
}
```

المستخدم يختار مستوى الصعوبة لكنه لا يغير شيئًا — هذا خداع غير مقصود.

---

### DATA-003 — `generateDailyPlan` قد يُنفذ 114 طلب async

```dart
// memorization_plus_repository_impl.dart
while (currentSurahId <= 114) {
  // يقرأ JSON كاملاً لكل سورة حتى يجد خطة
  final surahResult = await _quranRepository.getSurahDetail(currentSurahId);
  ...
  currentSurahId++;
}
```

في أسوأ حالة (مستخدم جديد بدون بيانات) يُنفذ 114 قراءة من assets. بطيء على الأجهزة الضعيفة.

---

### DATA-004 — الـ Streak لا يتحدث عند إتمام الأذكار

الـ streak يُحسب فقط عند استدعاء `getOverallProgress()`. مستخدم يفتح التطبيق ويقرأ الأذكار فقط — لا يتحدث الـ streak.

---

### DATA-005 — `getAllProgress()` يفحص كل مفاتيح SharedPreferences — O(n) على الكل

```dart
// hifz_local_datasource.dart
Future<List<AyahProgressModel>> getAllProgress() async {
  final keys = _prefs.getKeys() // ← يجلب كل مفاتيح SharedPreferences ثم يفلترها
      .where((k) => k.startsWith(AppConstants.kHifzProgress))
      .toList();
}
```

**المشكلة:** `getKeys()` يُرجع **كل** المفاتيح الموجودة في SharedPreferences (بما فيها مفاتيح الإعدادات والـ profile والـ streak)، ثم يفلترها واحدًا واحدًا. مع نمو بيانات الحفظ، هذا O(n) على المجموع الكلي وليس على بيانات الحفظ فقط. SharedPreferences غير مناسب كـ database لبيانات تنمو مع الوقت — الحل الصحيح هو Isar (راجع FEAT-T01).

---

### DATA-006 — `read_pages` مفتاح hardcoded

```dart
// progress_local_datasource.dart
await _prefs.setString('read_pages', jsonEncode(pages)); // ← raw string!
```

يجب أن يكون في `AppConstants`:
```dart
static const String kReadPages = 'read_pages';
```

---

### DATA-007 — `estimatedDays` يستخدم 20 آية متوسط لكل سورة

```dart
for (int s = startSurahId; s <= endSurahId; s++) {
  totalAyahs += 20; // ← placeholder average — البقرة 286، الكوثر 3!
}
```

---

### DATA-008 — `AyahReviewRecordModel.initial` يضع `nextReviewDate = now`

```dart
factory AyahReviewRecordModel.initial(int surahId, int ayahNumber) {
  final now = DateTime.now();
  return AyahReviewRecordModel(
    nextReviewDate: now, // ← آية جديدة "مستحقة" فورًا بدون منطق
    totalReviews: 0,
  );
}
```

آية لم يرَها المستخدم بعد تُعامَل كأنها مستحقة الآن.

---

## 🔵 مشاكل UX

### UX-001 — لا توجد خطوط قرآنية حقيقية

التطبيق يستخدم `Amiri` و`NotoNaskhArabic` — هذه خطوط عربية عامة، **ليست خطوطًا قرآنية**. تطبيقات القرآن الاحترافية (Quran.com, Ayah) تستخدم:
- **KFGQPC Uthmanic Hafs** (النص الرسمي)
- **Scheherazade New**
- **Noor Madinah**

غياب الخط القرآني يُقلل من مصداقية التطبيق.

---

### UX-002 — لا يوجد تخزين مؤقت (Caching) للصوت

كل مرة يستمع المستخدم لآية تُحمَّل من الإنترنت من جديد. في وضع الحفظ المتكرر (Kids Mode = 3 loops)، يتم تحميل نفس الملف 3 مرات.

---

### UX-003 — لا يوجد مؤشر عند فشل تحميل الصوت

```dart
// hifz_session_cubit.dart
} catch (e) {
  emit(st.copyWith(isPlaying: false)); // ← يُخفق بصمت، المستخدم لا يعلم
}
```

---

### UX-004 — لا توجد صفحة للمفضلة (Bookmarks)

`BookmarkService` موجود ومكتمل لكن **لا توجد صفحة UI** لعرض المفضلة. المستخدم يضيف آيات للمفضلة ثم لا يجدها في أي مكان.

---

### UX-005 — إعداد حجم الخط موجود لكن لا يُطبَّق في الحفظ

```dart
// app_constants.dart
static const double fontSizeSmall  = 18.0;
static const double fontSizeMedium = 22.0;
static const double fontSizeLarge  = 26.0;
static const double fontSizeXLarge = 30.0;
```

هذه الثوابت موجودة، لكن `HifzSessionPage` لا تقرأها — حجم الخط ثابت.

---

### UX-006 — `Settings` تحتوي على "About" section بالإنجليزية

```dart
_SettingsSection(
  title: 'About', // ← مكتوبة بالإنجليزية في وسط واجهة عربية
  children: [_AboutTile(isDark: isDark)],
),
```

---

### UX-007 — لا يوجد تأكيد عند حذف الخطة المخصصة

```dart
// custom_plan_cubit.dart
Future<void> deletePlan() async {
  // لا يوجد dialog للتأكيد — حذف فوري ونهائي
  final result = await _repository.deleteCustomPlan();
}
```

---

### UX-008 — أسماء السور في `CustomPlanSetupPage` hardcoded

```dart
// custom_plan_setup_page.dart
const List<String> _surahNames = [
  '', 'الفاتحة', 'البقرة', 'آل عمران', ...
];
```

هذه مكررة مع بيانات `surahs.json` الموجودة أصلاً — مصدر حقيقة واحدة يجب أن يُستخدم.

---

### UX-009 — لا يوجد Haptic Feedback

تطبيقات القرآن وتطبيقات الحفظ تستخدم haptic feedback عند:
- الانتقال للآية التالية
- نجاح التسميع
- اكتمال الجلسة

---

## 🟢 جودة الكود

### CODE-001 — `pubspec.yaml` وصف افتراضي

```yaml
description: "A new Flutter project." # ← يجب تحديثه قبل النشر
version: 1.0.0+1
```

---

### CODE-002 — ازدواجية في `_normalizeArabic`

```dart
// ArabicNormalizer.normalize() في core/utils — مكتملة
// _normalizeArabic() في quiz_cubit.dart — نسخة ثانية مختلفة قليلاً!

// quiz_cubit.dart يُزيل tatweel لكن ArabicNormalizer لا يُزيله
normalized = normalized.replaceAll('\u0640', ''); // ← موجود في quiz فقط
```

يجب استخدام `ArabicNormalizer` في كل مكان وإضافة تطبيع الـ tatweel له.

---

### CODE-003 — `HifzSessionState.copyWith` يستخدم `-1` كـ sentinel

```dart
// hifz_session_state.dart
similarityScore: similarityScore != null 
    ? (similarityScore == -1 ? null : similarityScore) // ← hacky!
    : this.similarityScore,
```

استخدام `-1` للـ "reset to null" مضلل. يجب استخدام نمط `Optional` أو method منفصلة `clearScore()`.

---

### CODE-004 — Achievement strings غير مترجمة

```dart
// progress_repository_impl.dart
Achievement(
  id: 'first_page',
  titleKey: 'الصفحة الأولى',      // ← مكتوب مباشرة، لا يدعم الإنجليزية
  descriptionKey: 'اقرأ أول صفحة', // ← لا يدعم l10n
),
```

---

### CODE-005 — لا توجد Unit Tests

`test/widget_test.dart` يحتوي على الـ test الافتراضي فقط من Flutter template. لا توجد اختبارات للـ:
- SM-2 algorithm (`advanceWithSpacedRepetition`, `ScheduleNextReviewUsecase`)
- `ArabicNormalizer`
- `_calculateStreak`
- Use Cases

---

### CODE-006 — `home_page.dart` وصل 1086 سطرًا

صفحة الـ Home وحدها 1086 سطر. يجب تقسيمها لـ widgets منفصلة في ملفات مختلفة.

---

### CODE-007 — `// ignore: deprecated_member_use` في `progress_page.dart`

```dart
// progress_page.dart (سطر 98، 1075)
// ignore: deprecated_member_use
```

يجب إصلاح API المُهمَل بدلاً من تجاهله.

---

## 🚀 تحسينات Phase 1

> **الهدف:** جعل التطبيق جاهزًا للنشر وآمنًا من الأخطاء

### IMP-P1-001 — خدمة صوتية مركزية

**الخطوة 1:** تحديث `AppConstants.audioBaseUrl` ليصبح everyayah (الـ URL المستخدم فعليًا في الكود):

```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  // ✅ URL واحد موحّد — تنسيق 001001.mp3
  static const String audioBaseUrl =
      'https://everyayah.com/data/Alafasy_128kbps/';
}
```

**الخطوة 2:** إنشاء `QuranAudioService` يبني الرابط من AppConstants:

```dart
// lib/core/services/quran_audio_service.dart
class QuranAudioService {
  /// بناء رابط الصوت من surahId + ayahNumber
  /// مثال: surah=1, ayah=1 → "001001.mp3"
  static String buildUrl(int surahId, int ayahNumber) {
    final s = surahId.toString().padLeft(3, '0');
    final a = ayahNumber.toString().padLeft(3, '0');
    return '${AppConstants.audioBaseUrl}$s$a.mp3';
  }
}
```

**الخطوة 3:** حذف كل URL مكتوب مباشرة في:
- `hifz_session_cubit.dart` → `QuranAudioService.buildUrl(surahId, ayahNumber)`
- `kids_mode_cubit.dart` → `QuranAudioService.buildUrl(surahId, ayahNumber)`
- `quran_entities.dart` (audioUrl getter) → `QuranAudioService.buildUrl(surahId, numberInSurah)`

---

### IMP-P1-002 — توحيد نظامَي الحفظ

**القرار المعماري:** الاحتفاظ بواجهتَي المستخدم (Hifz العادي + MemorizationPlus الذكي) مع **كتابة البيانات على نظام واحد فقط** (`AyahReviewRecord` من MemorizationPlus).

```dart
// HifzSessionCubit — عند نجاح التسميع
// يكتب على MemorizationPlusRepository بدلاً من HifzRepository
await _evaluateMemorizationUsecase(EvaluateMemorizationParams(
  surahId: ayah.surahId,
  ayahNumber: ayah.numberInSurah,
  rating: score >= 0.90 ? PerformanceRating.excellent 
        : score >= 0.75 ? PerformanceRating.average 
        : PerformanceRating.weak,
));
```

---

### IMP-P1-003 — Soft Reset بدلاً من Hard Reset

هذا الإصلاح هو نفسه المذكور في BUG-001، ومدرج هنا في Phase 1 للتأكيد على أولويته. الكود المطلوب:

```dart
// lib/features/hifz/presentation/cubits/hifz_session_cubit.dart
// استبدال السطر الذي يستدعي AyahProgressModel.initial() بهذا:

if (pass) {
  currentProgress = currentProgress.advanceWithSpacedRepetition();
} else {
  // ✅ soft penalty: تخفيض الـ repetitions بمقدار 1 + إعادة الجدولة لغد
  final penalizedReps = (currentProgress.repetitions - 1).clamp(0, 999);
  const intervals = [1, 3, 7, 14, 30, 90];
  final intervalDays = penalizedReps < intervals.length ? intervals[penalizedReps] : 1;
  
  currentProgress = AyahProgressModel(
    surahId: currentProgress.surahId,
    ayahNumber: currentProgress.ayahNumber,
    status: penalizedReps > 2 ? AyahStatus.review : AyahStatus.learning,
    repetitions: penalizedReps,
    nextReviewDate: DateTime.now().add(Duration(days: intervalDays)),
    lastReviewDate: DateTime.now(),
  );
}
```

**ملاحظة:** `AyahStatus` enum يحتوي على: `notStarted`, `learning`, `review`, `memorized` — الكود يستخدم القيم الصحيحة.

---

### IMP-P1-004 — إصلاح `SurahHifzProgress.totalAyahs`

```dart
// hifz_repository_impl.dart
// يجب تمرير surahData لحساب التقدم الحقيقي
return SurahHifzProgress(
  surahId: e.key,
  totalAyahs: surahMap[e.key]?.ayahCount ?? ayahs.length, // ← الإجمالي الحقيقي
  memorizedCount: ...
);
```

---

### IMP-P1-005 — صفحة المفضلة

إضافة `BookmarksPage` مع:
- عرض قائمة المفضلة مرتبة بالتاريخ
- الانتقال مباشرة للآية عند الضغط
- حذف من المفضلة بـ swipe
- اسم السورة الحقيقي من data layer

---

### IMP-P1-006 — تطبيق حجم الخط في جلسة الحفظ

```dart
// hifz_session_page.dart
final fontSize = getIt<SharedPreferences>()
    .getDouble(AppConstants.kFontSize) ?? AppConstants.fontSizeMedium;

Text(
  ayah.text,
  style: AppTypography.quranLarge.copyWith(fontSize: fontSize),
)
```

---

### IMP-P1-007 — إصلاح `_startTimerForPage` من `build()`

```dart
// نقله لـ BlocListener
BlocListener<QuranPageCubit, QuranPageState>(
  listener: (context, state) {
    if (state is QuranPageLoaded && !_readConfirmed) {
      _startTimerForPage(state.detail);
    }
  },
)
```

---

### IMP-P1-008 — تطبيق `MemorizationDifficulty` في الخوارزمية

```dart
// ScheduleNextReviewUsecase — إضافة معامل difficulty
AyahReviewRecord schedule(
  AyahReviewRecord record, 
  PerformanceRating rating,
  {MemorizationDifficulty difficulty = MemorizationDifficulty.moderate}
) {
  final multiplier = switch (difficulty) {
    MemorizationDifficulty.easy       => 3.0,
    MemorizationDifficulty.moderate   => 2.5,
    MemorizationDifficulty.challenging => 1.5,
  };
  
  final newInterval = switch (rating) {
    PerformanceRating.excellent => (record.intervalDays * multiplier).round(),
    PerformanceRating.average   => (record.intervalDays * 1.5).round(),
    PerformanceRating.weak      => 1,
  }.clamp(1, 180);
}
```

---

## ✨ تحسينات Phase 2

> **الهدف:** جعل التطبيق تنافسيًا مع Quran.com وتطبيقات الحفظ الكبيرة

### IMP-P2-001 — الخط القرآني الرسمي

إضافة خط **KFGQPC Uthmanic Hafs** أو **Scheherazade New** للقراءة القرآنية:

```yaml
# pubspec.yaml
fonts:
  - family: KFGQPCHafs
    fonts:
      - asset: assets/fonts/UthmanicHafs/UthmanicHafs1Ver17.ttf
```

هذا وحده يرفع مصداقية التطبيق بشكل كبير.

---

### IMP-P2-002 — تخزين مؤقت للصوت (Audio Caching)

```yaml
# pubspec.yaml
flutter_cache_manager: ^3.4.1
```

```dart
// AudioService with caching
final cacheManager = DefaultCacheManager();
final file = await cacheManager.getSingleFile(audioUrl);
await _player.setFilePath(file.path);
```

يُحسِّن تجربة Kids Mode (3 loops بدون تحميل متكرر) وجلسات الحفظ المتكررة.

---

### IMP-P2-003 — إشعارات تذكير يومي

```yaml
flutter_local_notifications: ^18.0.0
```

- تذكير بمراجعة الخطة اليومية
- تذكير الـ streak ("لديك 7 أيام متتالية، لا تنسَ اليوم!")
- تحفيز بعد إكمال السورة

---

### IMP-P2-004 — بحث في القرآن

```dart
// quran_repository.dart — إضافة use case
Future<Either<Failure, List<Ayah>>> searchAyahs(String query);
```

البحث بـ:
- اسم السورة (عربي / إنجليزي)
- جزء من نص الآية
- رقم الصفحة أو الجزء

---

### IMP-P2-005 — قاعدة بيانات محلية (Isar)

**المشكلة:** SharedPreferences غير مناسب لبيانات تنمو مع المستخدم.

```yaml
isar: ^4.0.0
isar_flutter_libs: ^4.0.0
```

```dart
@collection
class AyahProgressSchema {
  Id get isarId => Isar.autoIncrement;
  
  late int surahId;
  late int ayahNumber;
  late int strengthLevel;
  late DateTime nextReviewDate;
  
  @Index(composite: [CompositeIndex('ayahNumber')])
  int get compositeIndex => surahId;
}
```

**الفوائد:**
- استعلام O(log n) بدلاً من O(n)
- Transaction safety
- Queries معقدة (آيات مستحقة هذا اليوم، إلخ)
- لا فقدان للبيانات عند Crash

---

### IMP-P2-006 — مشاركة آية كصورة

```yaml
screenshot: ^3.0.0
```

```dart
// في _AyahOptionsSheet
_OptionBtn(
  icon: Icons.image_rounded,
  label: 'مشاركة كصورة',
  onTap: () => _shareAsImage(ayah),
),
```

صورة جميلة تحتوي على:
- نص الآية بالخط القرآني
- اسم السورة ورقم الآية
- شعار تاليه

---

### IMP-P2-007 — رسم بياني للتقدم الأسبوعي/الشهري

```yaml
fl_chart: ^0.69.0
```

في `ProgressPage`:
- رسم بياني للآيات المحفوظة يوميًا (آخر 30 يوم)
- رسم دائري لتوزيع الحالات (محفوظة / مراجعة / تعلم)
- مقارنة الأسابيع

---

### IMP-P2-008 — وضع المراجعة السريعة (Flash Cards)

بطاقات flash card تُظهر أول كلمة في الآية وتطلب من المستخدم إكمالها — جديد وممتع.

---

### IMP-P2-009 — دعم Tajweed Coloring

تلوين أحكام التجويد في القارئ:
- أحمر: غنة
- أخضر: مد
- أزرق: إدغام
- إلخ

هذه ميزة تنافسية حقيقية يطلبها كثيرون.

---

### IMP-P2-010 — Onboarding محسَّن مع خطوات إضافية

Onboarding حالي: 3 شرائح عامة.

المقترح:
1. مرحبًا بك
2. **اختيار مستوى الحفظ** (مبتدئ / متوسط / متقدم)
3. **اختيار الهدف** (حفظ جزء عمّ / القرآن كاملاً / سور بعينها)
4. **تحديد وقت الجلسة اليومية** (10 دقائق / 20 / 30)
5. **تفعيل الإشعارات** مع اختيار الوقت

---

## 💡 تحسينات Phase 3

> **الهدف:** ميزات متقدمة للتميز الكامل

### IMP-P3-001 — Widget للشاشة الرئيسية (Home Screen Widget)

```yaml
home_widget: ^0.6.0
```

- يعرض آية اليوم
- يعرض الـ streak
- يعرض عدد الآيات للمراجعة اليوم

---

### IMP-P3-002 — وضع المسابقة مع الأصدقاء (Multiplayer Quiz)

- مسابقة تسميع مع صديق عبر الرابط
- لوحة صدارة

---

### IMP-P3-003 — تقرير أسبوعي بالبريد الإلكتروني / PDF

تقرير أسبوعي يُرسَل للمستخدم يحتوي على:
- الآيات المحفوظة هذا الأسبوع
- نسبة التقدم
- الـ streak

---

### IMP-P3-004 — دعم Apple Watch / Wear OS

عرض آية اليوم وإشعار المراجعة على الساعة الذكية.

---

### IMP-P3-005 — خريطة الحفظ التفاعلية

خريطة بصرية للقرآن الكريم تُظهر:
- السور المحفوظة باللون الأخضر
- قيد الحفظ باللون الأصفر
- غير مبدوء باللون الرمادي

---

## 📋 خطة التنفيذ

### Sprint 1 — Critical Fixes (أسبوع 1)

| # | المهمة | الملف | الأولوية |
|---|--------|-------|----------|
| S1-1 | حذف كل `print()` statements | `hifz_session_cubit.dart`, `hifz_session_page.dart` | 🔴 |
| S1-2 | إصلاح Hard Reset → Soft Penalty | `ayah_progress_model.dart`, `hifz_session_cubit.dart` | 🔴 |
| S1-3 | توحيد رابط الصوت في `AppConstants` | `app_constants.dart`, `hifz_session_cubit.dart`, `kids_mode_cubit.dart`, `quran_entities.dart` | 🔴 |
| S1-4 | إصلاح زر الصوت في القارئ | `quran_reader_page.dart` | 🔴 |
| S1-5 | إصلاح `BookmarkEntry.surahName` | `quran_reader_page.dart` | 🔴 |
| S1-6 | نقل BookmarkService logic لـ Cubit | `quran_reader_page.dart` + cubit جديد | 🔴 |
| S1-7 | إضافة `kReadPages` لـ `AppConstants` | `app_constants.dart`, `progress_local_datasource.dart` | 🟡 |
| S1-8 | إصلاح `pubspec.yaml` description + version | `pubspec.yaml` | 🟡 |

### Sprint 2 — Architecture Fixes (أسبوع 2)

| # | المهمة | الملف | الأولوية |
|---|--------|-------|----------|
| S2-1 | نقل `ProfileCubit` للطبقة الصحيحة | إنشاء `presentation/cubits/profile_cubit.dart` | 🟡 |
| S2-2 | إصلاح `Splash` و`Onboarding` DI | `splash_page.dart`, `onboarding_page.dart` | 🟡 |
| S2-3 | جعل `QuranPageState` يرث `Equatable` | `quran_page_cubit.dart` | 🟡 |
| S2-4 | نقل `_startTimerForPage` من `build()` | `quran_reader_page.dart` | 🟡 |
| S2-5 | إصلاح `SurahHifzProgress.totalAyahs` | `hifz_repository_impl.dart` | 🟡 |
| S2-6 | توحيد `_normalizeArabic` → `ArabicNormalizer` | `quiz_cubit.dart` + `arabic_normalizer.dart` | 🟢 |
| S2-7 | إصلاح `_hifzDatasource` unused field | `memorization_plus_repository_impl.dart` | 🟢 |
| S2-8 | إصلاح Achievement strings للـ l10n | `progress_repository_impl.dart` | 🟢 |

### Sprint 3 — Data Layer Unification (أسبوع 3-4)

| # | المهمة | الملف | الأولوية |
|---|--------|-------|----------|
| S3-1 | **قرار: توحيد نظامَي الحفظ** | `hifz_session_cubit.dart` | 🔴 |
| S3-2 | `HifzSessionCubit` يكتب على MemorizationPlus | `hifz_session_cubit.dart` | 🔴 |
| S3-3 | تطبيق `MemorizationDifficulty` في الخوارزمية | `memorization_plus_usecases.dart` | 🟡 |
| S3-4 | إصلاح `isNearRevision/isFarRevision` | `memorization_entities.dart` | 🟡 |
| S3-5 | `estimatedDays` يستخدم data layer | `memorization_entities.dart` | 🟢 |
| S3-6 | `generateDailyPlan` يُحسَّن الأداء | `memorization_plus_repository_impl.dart` | 🟢 |

### Sprint 4 — Phase 1 Improvements (أسبوع 5-6)

| # | المهمة |
|---|--------|
| S4-1 | صفحة المفضلة (`BookmarksPage`) |
| S4-2 | تطبيق حجم الخط في جلسة الحفظ |
| S4-3 | خدمة صوتية مركزية (`QuranAudioService`) |
| S4-4 | إضافة Haptic Feedback |
| S4-5 | تأكيد حذف الخطة المخصصة |
| S4-6 | أسماء السور من data layer بدلاً من hardcode |
| S4-7 | Unit Tests للخوارزميات الأساسية |

### Sprint 5 — Phase 2 Improvements (أسبوع 7-10)

| # | المهمة |
|---|--------|
| S5-1 | الخط القرآني الحقيقي |
| S5-2 | Audio Caching |
| S5-3 | إشعارات يومية |
| S5-4 | بحث في القرآن |
| S5-5 | مشاركة آية كصورة |
| S5-6 | رسوم بيانية للتقدم |
| S5-7 | Onboarding محسَّن |

### Sprint 6 — Database Migration (أسبوع 11-12)

| # | المهمة |
|---|--------|
| S6-1 | إضافة Isar كـ database |
| S6-2 | Migration من SharedPreferences لـ Isar |
| S6-3 | Queries محسَّنة للتقارير |

---

## 🏗 البنية المعمارية المقترحة للنظام الموحد

### الرؤية

```
كل تفاعل مع آية (قراءة، حفظ، مراجعة، أطفال)
              ↓
     يُسجَّل في AyahReviewRecord  (نظام واحد)
              ↓
     يُقرأ من MemorizationPlus   (مصدر حقيقة واحد)
              ↓
     يُعرض في Progress + Daily Plan + Home
```

### تدفق البيانات المقترح

```dart
// نمط موحد لكل أنواع التقييم
abstract class MemorizationEvaluationSource {
  PerformanceRating get rating;
  String get source; // 'voice', 'manual', 'kids'
}

// HifzSessionCubit — voice evaluation
class VoiceEvaluation implements MemorizationEvaluationSource {
  final double similarityScore;
  
  @override
  PerformanceRating get rating => similarityScore >= 0.90 
      ? PerformanceRating.excellent
      : similarityScore >= 0.75 
          ? PerformanceRating.average 
          : PerformanceRating.weak;
  
  @override
  String get source => 'voice';
}

// DailyPlanCubit — manual evaluation
class ManualEvaluation implements MemorizationEvaluationSource {
  final PerformanceRating _rating;
  
  @override
  PerformanceRating get rating => _rating;
  
  @override
  String get source => 'manual';
}
```

---

---
---

# 🔍 نتائج المراجعة الثانية — مشاكل إضافية وتحسينات

> **تاريخ هذه المراجعة:** 2026-04-25  
> هذا القسم يضيف ما اكتُشف في مراجعة عميقة ثانية للكود، بعد قراءة كل ملف لم يُقرأ في المرة الأولى، بما فيها `progress_repository_impl.dart` كاملاً، `surah_detail_page.dart`، `azkar_cubit.dart`، `injection.dart` ترتيب التسجيل، و`pubspec.yaml` التبعيات.

---

## 🔴 بلوكرز جديدة

### BUG-008 — Bookmark SnackBar يُظهر نفس النص عند الإضافة والحذف ❌ CRITICAL

**الملف:** `lib/features/quran/presentation/pages/surah_detail_page.dart` (سطر 79)

```dart
// ❌ نفس النص في الحالتين — المستخدم لا يعرف ماذا حدث
isNowBookmarked ? context.l10n.bookmark : context.l10n.bookmark,
//              ↑ هذا                     ↑ وهذا — متطابقان تماماً!
```

**الإصلاح:**
```dart
// ✅ رسالة مختلفة لكل حالة
context.showSnackBar(
  isNowBookmarked
    ? 'تمت إضافة الآية للمفضلة ✓'
    : 'تمت إزالة الآية من المفضلة',
);
```

---

### BUG-009 — `StreamSubscription` يتراكم في `SurahDetailPage` — Memory Leak ❌ CRITICAL

**الملف:** `lib/features/quran/presentation/pages/surah_detail_page.dart` (سطر 97)

```dart
// ❌ كل ضغطة على آية تُنشئ subscription جديدة بدون إلغاء السابقة
Future<void> _playAyah(Ayah ayah) async {
  await _player.setUrl(ayah.audioUrl);
  await _player.play();
  _player.playerStateStream.listen((state) { // ← NEW subscription كل مرة!
    if (state.processingState == ProcessingState.completed) {
      if (mounted) setState(() => _isPlaying = false);
    }
  });
}
```

**النتيجة:** بعد 10 آيات، 10 subscriptions نشطة تُنادي `setState` معًا — أداء سيء وسلوك غير متوقع.

**الإصلاح:**
```dart
// ✅ حفظ الـ subscription وإلغاؤها قبل الاستماع الجديد
StreamSubscription<PlayerState>? _playerSubscription;

Future<void> _playAyah(Ayah ayah) async {
  _playerSubscription?.cancel(); // ← إلغاء السابقة أولاً
  await _player.setUrl(ayah.audioUrl);
  await _player.play();
  _playerSubscription = _player.playerStateStream.listen((state) {
    if (state.processingState == ProcessingState.completed) {
      if (mounted) setState(() => _isPlaying = false);
    }
  });
}

@override
void dispose() {
  _playerSubscription?.cancel(); // ← إلغاء عند مغادرة الصفحة
  _player.dispose();
  super.dispose();
}
```

---

### BUG-010 — `_evaluateRecitation` تُحفظ فشلاً حتى لو STT لم يعمل أصلاً ❌ CRITICAL

**الملف:** `lib/features/hifz/presentation/cubits/hifz_session_cubit.dart`

```dart
// ❌ إذا فشل الميكروفون أو انقطعت الشبكة، recognizedText = "" → score = 0.0 → Hard Reset
double score = 0.0;
if (normalizedSpoken.isNotEmpty) {
  score = normalizedExpected.similarityTo(normalizedSpoken);
}
// normalizedSpoken فارغ ← score يبقى 0.0 ← pass = false ← Hard Reset للتقدم
// المستخدم لم يحاول أصلاً لكن تقدمه يُمسح!
final pass = score >= 0.85;
```

**الإصلاح:**
```dart
// ✅ إذا لم يُسجَّل أي صوت، لا تُقيِّم — أخبر المستخدم
if (normalizedSpoken.isEmpty) {
  emit(st.copyWith(
    isEvaluating: false,
    similarityScore: null,
    errorMessage: 'لم يتم التعرف على صوت — حاول مجدداً',
  ));
  return; // ← لا حفظ، لا تقييم، لا تأثير على التقدم
}
```

---

### BUG-011 — `readSurahs` تحسب سور الحفظ لا سور القراءة ❌

**الملف:** `lib/features/progress/data/repositories/progress_repository_impl.dart` (سطر 55-58)

```dart
// bySurah مبنية من allProgress (بيانات الحفظ)
final bySurah = <int, List<dynamic>>{};
for (final p in allProgress) {
  bySurah.putIfAbsent(p.surahId, () => []).add(p);
}
// ❌ هذا يعد السور التي بدأ فيها الحفظ — ليس السور المقروءة!
final readSurahs = bySurah.keys.length;
```

المستخدم الذي قرأ 10 سور بدون حفظ سيرى `readSurahs = 0` في صفحة التقدم.

**الإصلاح:** `readSurahs` يجب أن يُحسب من `readPages` بتحويل الصفحات لسور.

---

### BUG-012 — تبعية `injectable` ميتة في `pubspec.yaml` ❌

**الملف:** `pubspec.yaml`

```yaml
injectable: ^2.7.1+4  # ← موجود في الـ dependencies
```

المشروع يستخدم **manual GetIt** (`getIt.registerLazySingleton`). لا يوجد **أي** annotation مثل `@injectable` أو `@lazySingleton` في أي ملف في المشروع. هذه التبعية تُضاف للحجم النهائي بلا فائدة.

**الإصلاح:** حذفها من `pubspec.yaml`.

---

### BUG-013 — `google_fonts` يُنزِّل الخطوط من الشبكة ❌

**الملف:** `pubspec.yaml` + استخدام `GoogleFonts` في `AppTypography`

```yaml
google_fonts: ^8.0.2  # ← يطلب الخطوط من Google CDN في أول تشغيل
```

في حالات: شبكة بطيئة، أجهزة قديمة، أو مستخدمين يحجبون Google — التطبيق يظهر بخطوط افتراضية مختلفة تمامًا عن التصميم المقصود.

**الإصلاح:**
```dart
// بدلاً من:
GoogleFonts.amiri()

// استخدم الخط المُحمَّل كـ asset (موجود أصلاً في assets/fonts/):
AppTypography.quranLarge // ← يستخدم fontFamily: 'Amiri' من الـ assets مباشرة
```

إضافة `GoogleFonts.config(allowRuntimeFetching: false)` في `main()` لضمان عدم طلب الخطوط من الشبكة:
```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config(allowRuntimeFetching: false); // ← منع الطلبات الشبكية
  await configureDependencies();
  runApp(const App());
}
```

---

## 🟡 مشاكل معمارية جديدة

### ARCH-009 — `ProgressRepository` يرجع `getIt<MemorizationPlusLocalDatasource>()` قبل تسجيله

**الملف:** `lib/core/di/injection.dart`

```dart
// سطر 74: تسجيل ProgressRepository
getIt.registerLazySingleton<ProgressRepository>(
  () => ProgressRepositoryImpl(
    getIt<ProgressLocalDatasource>(),
    getIt<HifzLocalDatasource>(),
    getIt<MemorizationPlusLocalDatasource>(), // ← يُستدعى lazily
  ),
);

// سطر 181: تسجيل MemorizationPlusLocalDatasource — بعد ProgressRepository بـ 107 أسطر!
getIt.registerLazySingleton<MemorizationPlusLocalDatasource>(
  () => MemorizationPlusLocalDatasourceImpl(getIt<SharedPreferences>()),
);
```

يعمل الآن لأن `registerLazySingleton` ينتظر حتى أول استدعاء. لكنه **هش جداً** — أي إعادة ترتيب أو استدعاء مبكر لـ `getIt<ProgressRepository>()` قبل اكتمال `configureDependencies()` سيُسبب crash. الحل: نقل `MemorizationPlusLocalDatasource` فوق `ProgressRepository`.

---

### ARCH-010 — `HomeCubit` مسجَّل قبل `MemorizationPlusRepository`

**الملف:** `lib/core/di/injection.dart` (سطر 171 vs 184)

```dart
// سطر 171: HomeCubit يستدعي getIt<MemorizationPlusRepository>()
getIt.registerFactory<HomeCubit>(
  () => HomeCubit(
    getIt<GetProgressUsecase>(),
    getIt<GetHifzProgressUsecase>(),
    getIt<QuranRepository>(),
    getIt<MemorizationPlusRepository>(), // ← يُسجَّل في سطر 184!
  ),
);
// سطر 184: التسجيل الفعلي لـ MemorizationPlusRepository
```

نفس المشكلة — هش وغير واضح للمطور القادم.

**الإصلاح:** إعادة ترتيب الـ DI ليكون:
```
1. SharedPreferences
2. Core services (Theme, Locale, Profile)
3. Data Sources (كلها أولاً)
4. Repositories (بعد كل datasources)
5. Use Cases
6. Cubits
```

---

### ARCH-011 — `_saveProgress` في `HifzSessionCubit` بدون error handling

**الملف:** `lib/features/hifz/presentation/cubits/hifz_session_cubit.dart`

```dart
// ❌ إذا فشل الحفظ لأي سبب، التقييم يُعرض للمستخدم لكن لا يُحفظ فعلياً
await _saveProgress(currentProgress); // ← استثناء هنا = بيانات ضائعة بصمت
emit(st.copyWith(isEvaluating: false, similarityScore: score, ...));
```

**الإصلاح:**
```dart
try {
  await _saveProgress(currentProgress);
} catch (e) {
  // سجل الخطأ + أخبر المستخدم أن التقييم حُسب لكن لم يُحفظ
  emit(st.copyWith(isEvaluating: false, similarityScore: score, saveError: true));
  return;
}
```

---

## 🟠 مشاكل بيانات جديدة

### DATA-009 — عداد الأذكار لا يُحفظ بين جلسات التطبيق

**الملف:** `lib/features/azkar/presentation/cubits/azkar_cubit.dart`

```dart
// العداد في الـ state فقط — يختفي عند إغلاق التطبيق
final sessions = azkar
    .map((z) => ZikrSession(zikr: z, currentCount: 0, isDone: false))
    .toList();
```

المستخدم يكمل 5 أذكار من 10، يغلق التطبيق، يفتحه من جديد → يبدأ من الصفر. يجب حفظ العداد في SharedPreferences مع التحقق من تاريخ اليوم (إعادة الضبط في اليوم التالي):

```dart
// azkar_local_datasource.dart — إضافة methods للحفظ اليومي
Future<Map<String, int>> getAzkarCounters(AzkarCategory category, DateTime date);
Future<void> saveAzkarCounter(AzkarCategory cat, String zikrId, int count, DateTime date);

// في AzkarCubit.load():
final savedDate = await _datasource.getLastAzkarDate(category);
final isToday = savedDate?.day == DateTime.now().day;
final savedCounters = isToday
    ? await _datasource.getAzkarCounters(category, DateTime.now())
    : {}; // ← إعادة الضبط في يوم جديد
```

---

### DATA-010 — `similarity threshold` مكتوب مباشرة في الكود

**الملف:** `lib/features/hifz/presentation/cubits/hifz_session_cubit.dart` (سطر 186)

```dart
final pass = score >= 0.85; // ← hardcoded، غير قابل للتخصيص
```

يجب أن يكون في `AppConstants` وأن يظهر كإعداد في صفحة الإعدادات:
```dart
// app_constants.dart
static const double kSimilarityThreshold = 0.85;
static const String kSimilarityThresholdKey = 'similarity_threshold';

// في hifz_session_cubit.dart
final threshold = _prefs.getDouble(AppConstants.kSimilarityThresholdKey)
    ?? AppConstants.kSimilarityThreshold;
final pass = score >= threshold;
```

**قيم مقترحة في الإعدادات:**
- سهل: 0.70
- متوسط: 0.85 (الافتراضي)
- صعب: 0.92

---

### DATA-011 — الأذكار: تصنيف `general` موجود كـ enum لكن لا يوجد مسار له في الـ Router

**الملف:** `lib/core/router/app_router.dart`

```dart
// AzkarCategory.general موجود في الكود
// لكن المسار /azkar/:category يقبل فقط 'morning' و'evening' في الـ UI
// لا يوجد زر في الواجهة للوصول لـ AzkarCategory.general
```

الأذكار العامة موجودة في `azkar.json` لكن المستخدم لا يستطيع الوصول إليها.

---

## 🔵 مشاكل UX جديدة

### UX-010 — لا يوجد تأكيد عند الخروج من جلسة الحفظ

**الملف:** `lib/features/hifz/presentation/pages/hifz_session_page.dart`

```dart
// زر الرجوع في AppBar يُغلق الجلسة فوراً بدون تأكيد
AppBar(
  backgroundColor: Colors.transparent,
  // ← لا يوجد WillPopScope أو PopScope
  // ← لا يوجد confirmDismiss dialog
)
```

المستخدم يضغط عن طريق الخطأ على زر الرجوع في منتصف التسميع — يفقد الجلسة كلها.

**الإصلاح:**
```dart
// هيئة الـ Scaffold بـ PopScope
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) async {
    if (didPop) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('خروج من الجلسة؟'),
        content: const Text('لن يتم حفظ الجلسة الحالية.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('خروج')),
        ],
      ),
    );
    if (confirm == true && context.mounted) context.pop();
  },
)
```

---

### UX-011 — `DailyPlanPage` لا تُظهر شاشة "اكتملت المراجعة اليوم"

**الملف:** `lib/features/memorization_plus/presentation/pages/daily_plan_page.dart`

عندما يكمل المستخدم كل آيات الخطة اليومية، الصفحة تُظهر قائمة فارغة بدون أي رسالة. لا يوجد:
- تهنئة أو احتفال
- ملخص للجلسة (كم آية راجعت، كم نجحت)
- وقت المراجعة القادمة
- زر "شارك إنجازك"

---

### UX-012 — `Share.share()` deprecated — يجب تحديثه

**الملف:** `lib/features/progress/presentation/pages/progress_page.dart` (سطر 98، 1075)

```dart
// ignore: deprecated_member_use
Share.share(text); // ← deprecated في share_plus v13+
```

**الإصلاح لـ share_plus v13+:**
```dart
await SharePlus.instance.share(
  ShareParams(text: text, subject: 'تقدمي في حفظ القرآن'),
);
```

---

### UX-013 — لا يوجد دليل عند رفض إذن الميكروفون

**الملف:** `lib/features/hifz/presentation/pages/hifz_session_page.dart` + `quiz_page.dart`

```dart
// عند رفض الميكروفون — لا شيء يحدث، STT يصمت
if (!_speechEnabled) {
  // الكود يتجاهل الحالة تماماً
}
```

**الإصلاح:**
```dart
if (!_speechEnabled) {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('يحتاج التطبيق إذن الميكروفون'),
      content: const Text('للتسميع الصوتي، يرجى السماح بالوصول للميكروفون من إعدادات الجهاز.'),
      actions: [
        TextButton(
          onPressed: () => openAppSettings(), // ← permission_handler
          child: const Text('فتح الإعدادات'),
        ),
      ],
    ),
  );
  return;
}
```

---

### UX-014 — الأذكار العامة لا يمكن الوصول إليها من الواجهة

راجع DATA-011 أعلاه. يجب إضافة قسم ثالث في `AzkarPage` للأذكار العامة بجانب الصباح والمساء.

---

### UX-015 — `HifzPage` لا تُظهر نسبة التقدم الحقيقية

**المشكلة:** `SurahHifzProgress.totalAyahs = ayahs.length` (المتتبعة فقط لا الإجمالي) — تم ذكرها في ARCH-006 لكن الأثر هنا: شريط التقدم في HifzPage يُظهر 100% للمستخدم الذي حفظ 3 آيات فقط من سورة طويلة.

---

## 🟢 مشاكل جودة كود جديدة

### CODE-008 — `injectable` تبعية غير مستخدمة

راجع BUG-012 — `injectable: ^2.7.1+4` في `pubspec.yaml` بدون استخدام واحد له في المشروع.

---

### CODE-009 — `_surahNames` قائمة مكررة تحتوي على أخطاء إملائية محتملة

**الملف:** `lib/features/memorization_plus/presentation/pages/custom_plan_setup_page.dart`

```dart
const List<String> _surahNames = [
  '', 'الفاتحة', 'البقرة', ... // 114 اسم مكتوب يدوياً
];
```

هذه القائمة مكررة مع `surahs.json` الموجود في المشروع. أي خطأ إملائي في هذه القائمة لن يُكتشف لأنها لا تأتي من مصدر بيانات قابل للتحقق.

**الإصلاح:** استخدام `GetSurahsUsecase` في `CustomPlanSetupPage` وتحميل الأسماء من data layer مرة واحدة.

---

### CODE-010 — `debugLogDiagnostics: false` في GoRouter — يجب أن يعتمد على `kDebugMode`

**الملف:** `lib/core/router/app_router.dart`

```dart
static final GoRouter router = GoRouter(
  debugLogDiagnostics: false, // ← مفيد في debug، يضيع معلومات تشخيصية
  ...
);
```

**الإصلاح:**
```dart
debugLogDiagnostics: kDebugMode, // ← يُشغَّل فقط في debug mode
```

---

### CODE-011 — `withValues(alpha:...)` بدلاً من `withOpacity()` في بعض المواضع، وعكسه في أخرى

**الملف:** مواضع متعددة في `home_page.dart` و`azkar_category_page.dart`

```dart
// بعض المواضع تستخدم النمط الجديد:
color: widget.gradColors[0].withValues(alpha: 0.35)

// وأخرى تستخدم القديم:
color: primary.withOpacity(0.1)
```

يجب توحيد الاستخدام على `withValues(alpha:)` في كل المشروع (هو الـ API الحديث في Flutter 3.27+).

---

## 📋 Sprint جديد — Sprint 0 (فوري قبل Sprint 1)

> هذه المشاكل أبسط وأسرع من Sprint 1 لكنها يجب أن تُحل أولاً

| # | المهمة | الملف | الوقت المقدر |
|---|--------|-------|-------------|
| S0-1 | حذف `injectable` من `pubspec.yaml` | `pubspec.yaml` | 5 دقائق |
| S0-2 | إضافة `GoogleFonts.config(allowRuntimeFetching: false)` | `main.dart` | 5 دقائق |
| S0-3 | إصلاح Bookmark SnackBar (نصين مختلفين) | `surah_detail_page.dart` | 10 دقائق |
| S0-4 | إصلاح Stream leak في `_playAyah` | `surah_detail_page.dart` | 15 دقائق |
| S0-5 | تبديل `Share.share()` للـ API الجديد | `progress_page.dart` | 10 دقائق |
| S0-6 | إضافة `debugLogDiagnostics: kDebugMode` | `app_router.dart` | 2 دقيقة |
| S0-7 | توحيد `withValues(alpha:)` في المشروع | متعدد | 20 دقيقة |
| S0-8 | إضافة الأذكار العامة للواجهة | `azkar_page.dart` | 30 دقيقة |

---

## 📋 تحديث خطة Sprint 1

أضف هذه المهام لـ Sprint 1:

| # | المهمة الإضافية | الملف |
|---|----------------|-------|
| S1-9 | إصلاح `readSurahs` ليحسب من `readPages` | `progress_repository_impl.dart` |
| S1-10 | إصلاح `_evaluateRecitation` لا تُقيِّم عند empty STT | `hifz_session_cubit.dart` |
| S1-11 | إضافة `PopScope` confirmation في HifzSession | `hifz_session_page.dart` |
| S1-12 | إضافة دليل رفض إذن الميكروفون | `hifz_session_page.dart`, `quiz_page.dart` |
| S1-13 | نقل `similarity_threshold` لـ `AppConstants` | `app_constants.dart`, `hifz_session_cubit.dart` |

---

## 📋 تحديث خطة Sprint 2

أضف هذه المهام لـ Sprint 2:

| # | المهمة الإضافية | الملف |
|---|----------------|-------|
| S2-9 | إعادة ترتيب DI — كل datasources أولاً | `injection.dart` |
| S2-10 | إضافة error handling لـ `_saveProgress` | `hifz_session_cubit.dart` |
| S2-11 | إضافة شاشة "اكتملت المراجعة اليوم" | `daily_plan_page.dart` |

---

## 📋 تحديث خطة Sprint 4

أضف هذه المهام لـ Sprint 4:

| # | المهمة الإضافية | الملف |
|---|----------------|-------|
| S4-8 | حفظ عداد الأذكار يومياً | `azkar_cubit.dart`, `azkar_local_datasource.dart` |
| S4-9 | إعداد مستوى دقة التسميع في الإعدادات | `settings_page.dart` + `hifz_session_cubit.dart` |
| S4-10 | أسماء السور من UseCase بدلاً من hardcode | `custom_plan_setup_page.dart` |

---

## ملاحظات ختامية

المشروع يمتلك إمكانات حقيقية وأسسًا جيدة. الأولويات القصوى قبل أي نشر:

1. **إصلاح Hard Reset** — هذه الأولى والأهم من ناحية تجربة المستخدم
2. **حذف `print()` من `build()`** — أداء وأمان
3. **توحيد رابط الصوت** — موثوقية
4. **اتخاذ قرار توحيد نظامَي الحفظ** — هذا يحدد هوية التطبيق

بعد إصلاح البلوكرز، التطبيق يمكنه المنافسة بشكل حقيقي إذا أُضيف له **الخط القرآني الحقيقي** + **الإشعارات** + **تخزين مؤقت للصوت** — هذه الثلاث وحدها تُحدث فرقًا جوهريًا في التقييمات على المتجر.

---

*تم إعداد هذا التقرير بعد مراجعة 95 ملف من ملفات المشروع يدويًا وتتبع كل dependency chain.*

---
---

# 🌟 مقترحات التطوير والتحسين — ما بعد التعديلات

> هذا القسم يُقدِّم رؤية شاملة لكل الميزات والتحسينات التي يمكن إضافتها بعد إتمام الإصلاحات، مرتبة حسب الأثر على المستخدم والقيمة التنافسية.

---

## فهرس المقترحات

- [🎯 المحور الأول — تجربة القراءة والتلاوة](#محور-القراءة)
- [🧠 المحور الثاني — نظام الحفظ الذكي](#محور-الحفظ)
- [🎮 المحور الثالث — التحفيز والـ Gamification](#محور-التحفيز)
- [🔔 المحور الرابع — الإشعارات والتذكير](#محور-الإشعارات)
- [👨‍👩‍👧 المحور الخامس — وضع الأطفال المتطور](#محور-الأطفال)
- [📊 المحور السادس — التقارير والإحصائيات](#محور-التقارير)
- [🌐 المحور السابع — الميزات الاجتماعية](#محور-اجتماعي)
- [⚙️ المحور الثامن — الإعدادات والتخصيص](#محور-الإعدادات)
- [🏗 المحور التاسع — البنية التقنية](#محور-تقني)
- [💼 المحور العاشر — التسييل والنشر](#محور-تسييل)

---

## 🎯 المحور الأول — تجربة القراءة والتلاوة {#محور-القراءة}

### 📖 FEAT-R01 — الخط القرآني الرسمي (KFGQPC Uthmanic Hafs)

**الأثر:** 🔥 عالي جداً — يُميِّز التطبيق فور فتحه  
**الصعوبة:** 🟡 متوسطة  
**الحزمة المقترحة:** تحميل مباشر من `fonts/`

هذه الميزة وحدها تُغيِّر الانطباع الأول للمستخدم. الخط القرآني الرسمي المستخدم في المصحف الشريف يُضفي مصداقية وجمالاً لا يمكن تحقيقهما بأي خط آخر.

```yaml
# pubspec.yaml
fonts:
  - family: UthmanicHafs
    fonts:
      - asset: assets/fonts/hafs/UthmanicHafs1Ver17.ttf
```

```dart
// app_typography.dart
static const TextStyle quranText = TextStyle(
  fontFamily: 'UthmanicHafs',
  fontSize: 22,
  height: 2.0,
  letterSpacing: 0,
);
```

**الخطوط المرشحة للإضافة:**
- `KFGQPC HAFS Uthmanic` — الأكثر استخدامًا في تطبيقات القرآن
- `Scheherazade New` — جميل ومرخص مجانًا من SIL
- `Noor Madinah` — شائع في التطبيقات الإسلامية

---

### 🎨 FEAT-R02 — تلوين أحكام التجويد (Tajweed Coloring)

**الأثر:** 🔥 عالي جداً — ميزة تنافسية حقيقية  
**الصعوبة:** 🔴 عالية  

تلوين الآيات بحسب أحكام التجويد:

| اللون | الحكم |
|-------|-------|
| 🔴 أحمر | غنّة (إدغام بغنة، إخفاء) |
| 🟢 أخضر | مدود |
| 🔵 أزرق | قلقلة |
| 🟡 أصفر | تفخيم |
| 🟣 بنفسجي | إدغام بلا غنة |

```dart
// tajweed_parser.dart
class TajweedParser {
  static List<TajweedSpan> parse(String ayahText) {
    // قواعد التجويد كـ RegExp rules
    final rules = [
      TajweedRule(pattern: RegExp(r'[نم]\u0652'), color: Colors.red, label: 'إخفاء'),
      TajweedRule(pattern: RegExp(r'[آ]'), color: Colors.blue, label: 'مد'),
      // ...
    ];
    return _applyRules(ayahText, rules);
  }
}
```

**ملاحظة:** يمكن البدء بتحميل البيانات من `quran.com API` التي تدعم tajweed markup، أو استخدام ملف JSON منفصل للأحكام.

---

### 🖼 FEAT-R03 — وضع المصحف (صور الصفحات الحقيقية)

**الأثر:** 🔥 عالي — تجربة قراءة أصيلة  
**الصعوبة:** 🔴 عالية (حجم الأصول)  

عرض صور المصحف الحقيقية بدلاً من النص، مما يُتيح:
- تجربة قراءة مطابقة للمصحف المطبوع
- دعم علامات الوقف الحقيقية
- حفظ الصفحة كصورة ومشاركتها

```dart
// quran_mushaf_page.dart
Image.asset(
  'assets/mushaf/page_${pageNumber.toString().padLeft(3, '0')}.jpg',
  fit: BoxFit.contain,
  cacheHeight: 2000,
)
```

---

### 🔍 FEAT-R04 — البحث في القرآن الكريم

**الأثر:** 🔥 عالي — مطلوب جداً من المستخدمين  
**الصعوبة:** 🟡 متوسطة  

```dart
// search use case
class SearchAyahsUsecase implements UseCase<List<SearchResult>, String> {
  @override
  Future<Either<Failure, List<SearchResult>>> call(String query) async {
    final normalized = ArabicNormalizer.normalize(query);
    // بحث في الآيات المخزنة محلياً
    return _repository.searchAyahs(normalized);
  }
}

class SearchResult {
  final Surah surah;
  final Ayah ayah;
  final List<int> matchPositions; // لتمييز الكلمات المطابقة
}
```

**أنواع البحث:**
- بحث نصي في الآيات مع تطبيع عربي
- بحث باسم السورة (عربي/إنجليزي)
- بحث برقم الصفحة أو الجزء أو الحزب
- فلترة النتائج حسب نوع السورة (مكية/مدنية)

---

### 🔖 FEAT-R05 — صفحة المفضلة المتكاملة

**الأثر:** 🟡 متوسط  
**الصعوبة:** 🟢 منخفضة (البنية موجودة)  

`BookmarkService` مكتمل لكن لا توجد صفحة عرض. المطلوب:

```
BookmarksPage
├── قائمة مرتبة حسب التاريخ
├── تجميع حسب السورة
├── Swipe to delete
├── الانتقال الفوري للآية عند الضغط
└── مشاركة الآية المفضلة
```

---

### 🔊 FEAT-R06 — التحكم الكامل في مشغل الصوت

**الأثر:** 🔥 عالي  
**الصعوبة:** 🟡 متوسطة  

```dart
// audio_player_bar.dart — شريط تحكم ثابت أسفل الشاشة
class QuranAudioBar extends StatelessWidget {
  // تشغيل / إيقاف / السابق / التالي
  // اختيار القارئ (عفاسي، الحصري، السديس...)
  // سرعة التشغيل (0.75x، 1x، 1.25x)
  // تكرار آية / تكرار صفحة
  // نمط: آية آية / صفحة صفحة / تلاوة مستمرة
}
```

**قراء مقترحون للإضافة:**
- مشاري العفاسي (موجود)
- عبد الباسط عبد الصمد
- محمود الحصري
- ماهر المعيقلي
- سعد الغامدي

---

### 📋 FEAT-R07 — وضع التدبر (Reflection Mode)

**الأثر:** 🟡 متوسط — يُميِّز التطبيق  
**الصعوبة:** 🟡 متوسطة  

عند الضغط المطول على آية:
- عرض تفسير مختصر (من ملف JSON محلي)
- إمكانية إضافة ملاحظة شخصية على الآية
- عرض الآيات المرتبطة بنفس الموضوع

```dart
// reflection_model.dart
class AyahReflection {
  final int surahId;
  final int ayahNumber;
  final String note;
  final DateTime createdAt;
  final List<String> tags;
}
```

---

## 🧠 المحور الثاني — نظام الحفظ الذكي {#محور-الحفظ}

### 🔄 FEAT-H01 — خوارزمية SM-2 الكاملة بمعامل EF

**الأثر:** 🔥 عالي — دقة علمية للحفظ  
**الصعوبة:** 🟡 متوسطة  

الخوارزمية الحالية تُبسِّط SM-2. الخوارزمية الكاملة تستخدم معامل Ease Factor (EF) الذي يتكيف مع كل آية:

```dart
// lib/core/algorithms/sm2_algorithm.dart

class SM2Result {
  const SM2Result({
    required this.repetitions,
    required this.easeFactor,
    required this.intervalDays,
    required this.nextReviewDate,
  });
  final int repetitions;
  final double easeFactor;
  final int intervalDays;
  final DateTime nextReviewDate;
}

class SM2Algorithm {
  /// EF يبدأ من 2.5 ويتعدل بعد كل مراجعة
  static SM2Result calculate({
    required int repetitions,
    required double easeFactor,    // نطاق: 1.3 → 2.5+
    required int intervalDays,
    required int quality,          // 0-5 (0=فشل تام, 5=مثالي)
  }) {
    final double newEF = (easeFactor + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
        .clamp(1.3, double.infinity);

    final int newInterval;
    final int newReps;

    if (quality < 3) {
      // فشل — إعادة من البداية لكن بـ EF محفوظ
      newReps = 0;
      newInterval = 1;
    } else {
      newReps = repetitions + 1;
      newInterval = switch (newReps) {
        1     => 1,
        2     => 6,
        _     => (intervalDays * newEF).round(),
      };
    }

    return SM2Result(
      repetitions: newReps,
      easeFactor: newEF,
      intervalDays: newInterval,
      nextReviewDate: DateTime.now().add(Duration(days: newInterval)),
    );
  }
}
```

**الفائدة:** كل آية تحصل على جدولة مُخصَّصة بناءً على أداء المستخدم تحديداً فيها، وليس نمطاً موحداً للجميع.

---

### 📅 FEAT-H02 — خطة حفظ ذكية بناءً على جدول المستخدم

**الأثر:** 🔥 عالي — يُحل إشكالية "لا وقت للحفظ"  
**الصعوبة:** 🟡 متوسطة  

```dart
// smart_schedule_generator.dart
class SmartScheduleGenerator {
  /// يولد خطة واقعية بناءً على:
  /// - عدد دقائق المستخدم يومياً
  /// - الأيام المتاحة
  /// - الهدف (سورة / جزء / القرآن كاملاً)
  /// - مستوى الصعوبة الحالي
  SmartPlan generate({
    required int dailyMinutes,
    required List<int> availableDays, // أيام الأسبوع
    required int targetSurahId,
    required DateTime targetDate,     // تاريخ الانتهاء المطلوب
  }) {
    final ayahsPerSession = _estimateAyahsPerMinute() * dailyMinutes;
    final totalDays = targetDate.difference(DateTime.now()).inDays;
    final availableSessions = (totalDays / 7) * availableDays.length;
    
    return SmartPlan(
      newAyahsPerDay: (totalAyahs / availableSessions).ceil(),
      estimatedCompletionDate: _calculateRealCompletion(...),
      weeklySchedule: _buildWeeklySchedule(availableDays),
      warningIfUnrealistic: totalAyahs / dailyMinutes > 2,
    );
  }
}
```

---

### 🗺 FEAT-H03 — خريطة الحفظ التفاعلية

**الأثر:** 🔥 عالي — تصور بصري ممتاز  
**الصعوبة:** 🟡 متوسطة  

```dart
// memorization_map_widget.dart
class QuranMemorizationMap extends StatelessWidget {
  // شبكة 114 خلية (واحدة لكل سورة)
  // لون كل خلية يعكس حالة الحفظ:
  // - أخضر غامق: محفوظة بالكامل ✅
  // - أخضر فاتح: جزء منها محفوظ 🟩
  // - أصفر: قيد الحفظ 🟨
  // - رمادي: لم يُبدأ بعد ⬜
  
  // عند الضغط على خلية: تفاصيل السورة + زر البدء
}
```

---

### 🃏 FEAT-H04 — بطاقات الحفظ (Flash Cards Mode)

**الأثر:** 🟡 متوسط — طريقة مراجعة إضافية ممتعة  
**الصعوبة:** 🟢 منخفضة  

بطاقة تُظهر أول كلمة أو كلمتين، والمستخدم يُكمل الباقي من حفظه:

```
┌─────────────────────────────┐
│  سورة البقرة — الآية 255   │
│                             │
│   اللَّهُ لَا إِلَـٰهَ     │
│         ← أكمل من حفظك    │
│                             │
│  [أعرفها] [صعبة] [لا أعرف] │
└─────────────────────────────┘
```

---

### 🎤 FEAT-H05 — تحسين التعرف على الصوت

**الأثر:** 🔥 عالي — القلب النابض للتطبيق  
**الصعوبة:** 🔴 عالية  

النظام الحالي يستخدم `speech_to_text` مع `string_similarity` (Dice's coefficient) وله قيود:

**المشاكل الحالية:**
- الحد 0.85 قاسٍ جداً لبعض اللهجات
- لا يُفرِّق بين خطأ في كلمة واحدة وخطأ في نص كامل
- لا تغذية راجعة عن مكان الخطأ تحديداً

**التحسينات المقترحة:**

```dart
// enhanced_evaluation.dart
class EnhancedEvaluationResult {
  final double overallScore;
  final List<WordEvaluation> wordResults; // كل كلمة على حدة
  final String missedWord;               // أول كلمة أُخطئت
  final EvaluationGrade grade;           // ممتاز / جيد / يحتاج مراجعة
}

enum EvaluationGrade { excellent, good, needsWork, incorrect }

// معايير أكثر مرونة
EvaluationGrade get grade => switch (overallScore) {
  >= 0.92 => EvaluationGrade.excellent,
  >= 0.78 => EvaluationGrade.good,
  >= 0.60 => EvaluationGrade.needsWork,
  _       => EvaluationGrade.incorrect,
};
```

**إضافة Whisper API (اختياري للـ Premium):**
```dart
// للمستخدمين المتقدمين — دقة أعلى بكثير
class WhisperEvaluationService {
  Future<EvaluationResult> evaluate(File audioFile, String expectedText) async {
    // OpenAI Whisper API مع Arabic tuning
  }
}
```

---

### 📖 FEAT-H06 — جلسة المراجعة الجماعية (Batch Review)

**الأثر:** 🟡 متوسط  
**الصعوبة:** 🟢 منخفضة  

بدلاً من مراجعة آية واحدة، مراجعة مجموعة آيات في جلسة واحدة متدفقة:

```
┌─ جلسة المراجعة ─────────────────┐
│ 8 آيات للمراجعة اليوم           │
│ ██████░░ 6/8 مكتملة             │
│                                  │
│ → سورة الملك: آية 3-7           │
│   [استمع] [سجِّل] [التالية →]   │
└──────────────────────────────────┘
```

---

## 🎮 المحور الثالث — التحفيز والـ Gamification {#محور-التحفيز}

### 🏆 FEAT-G01 — نظام الإنجازات المتطور

**الأثر:** 🔥 عالي — الاحتفاظ بالمستخدم (Retention)  
**الصعوبة:** 🟡 متوسطة  

النظام الحالي لديه إنجازات أساسية. المقترح: إنجازات ديناميكية متعددة الطبقات:

```dart
enum AchievementTier { bronze, silver, gold, platinum }

class TieredAchievement {
  final String id;
  final Map<AchievementTier, int> thresholds; // bronze=1, silver=10, gold=50...
  final String Function(AchievementTier) titleBuilder;
  
  AchievementTier get currentTier {
    // يتدرج تلقائياً مع تقدم المستخدم
  }
}
```

**إنجازات مقترحة جديدة:**

| الإنجاز | الشرط |
|---------|-------|
| 🌅 صاحب الفجر | إتمام جلسة قبل الساعة 6 صباحًا |
| 🌙 ساهر الليل | إتمام جلسة بعد الساعة 11 مساءً |
| ⚡ البرق | مراجعة 10 آيات في أقل من 10 دقائق |
| 🎯 المتقن | تسميع 5 آيات متتالية بدرجة "ممتاز" |
| 📅 المداوم | 30 يوماً متتالية بلا انقطاع |
| 🌍 المسافر | فتح التطبيق من 3 مناطق زمنية مختلفة |
| 👑 حافظ جزء عمّ | إتمام حفظ الجزء الثلاثين |

---

### 🔥 FEAT-G02 — Streak System متطور

**الأثر:** 🔥 عالي  
**الصعوبة:** 🟢 منخفضة  

```dart
// streak_service.dart
class StreakService {
  // Streak يومي (الحالي)
  int get dailyStreak => ...;
  
  // أطول streak محقق (للفخر)
  int get longestStreak => ...;
  
  // Streak حماية — يُعطي المستخدم "حماية" واحدة شهرياً
  // يمكنه استخدامها لحماية الـ streak يوم واحد
  bool get hasStreakShield => ...;
  Future<void> useStreakShield() async => ...;
  
  // رسائل تحفيزية مخصصة — if/else لدعم Dart 2 و 3 معًا
  String get motivationalMessage {
    if (dailyStreak == 0)        return 'ابدأ رحلتك اليوم!';
    if (dailyStreak == 1)        return 'يوم واحد — الرحلة تبدأ بخطوة';
    if (dailyStreak == 7)        return 'أسبوع كامل! أنت تبني عادة رائعة';
    if (dailyStreak == 30)       return 'شهر مداومة! أنت من القلة المثابرة';
    if (dailyStreak >= 100)      return 'مئة يوم! أنت في طريق الحفاظين';
    return 'استمر، لا تقطع السلسلة! 🔥';
  }
}
```

---

### 🎊 FEAT-G03 — احتفالات الإنجاز (Celebration Animations)

**الأثر:** 🟡 متوسط — لحظات سعادة للمستخدم  
**الصعوبة:** 🟢 منخفضة  

```yaml
confetti: ^0.7.0
```

```dart
// celebration_widget.dart
class SurahCompletionCelebration extends StatelessWidget {
  // confetti + رسالة تهنئة + زر المشاركة
  // يظهر عند:
  // - إتمام حفظ سورة كاملة
  // - بلوغ milestone معين في الـ streak
  // - فتح إنجاز جديد
}
```

---

### 📊 FEAT-G04 — لوحة التقدم الأسبوعية

**الأثر:** 🟡 متوسط  
**الصعوبة:** 🟢 منخفضة  

```dart
// weekly_summary_widget.dart
// يعرض كل يوم أحد ملخصاً للأسبوع:
// - عدد الآيات الجديدة
// - عدد الآيات المراجعة
// - أفضل يوم في الأسبوع
// - مقارنة مع الأسبوع الماضي
```

---

## 🔔 المحور الرابع — الإشعارات والتذكير {#محور-الإشعارات}

### 🔔 FEAT-N01 — نظام إشعارات ذكي

**الأثر:** 🔥 عالي — يُحافظ على المستخدمين  
**الصعوبة:** 🟡 متوسطة  
**الحزمة:** `flutter_local_notifications: ^18.0.0`

```dart
// notification_service.dart
class TaliaNotificationService {
  
  // إشعار المراجعة اليومية
  Future<void> scheduleDailyReviewReminder({
    required TimeOfDay time,
    required int pendingReviewCount,
  }) async {
    await _plugin.zonedSchedule(
      NotificationIds.dailyReview,
      'وقت المراجعة اليومية 📖',
      'لديك $pendingReviewCount آية للمراجعة اليوم',
      _nextInstanceOf(time),
      ...
    );
  }
  
  // تحذير انقطاع الـ streak
  Future<void> scheduleStreakProtectionAlert(int currentStreak) async {
    // يُرسَل قبل منتصف الليل إذا لم يفتح المستخدم التطبيق
    await _plugin.zonedSchedule(
      NotificationIds.streakAlert,
      '⚠️ لا تُضيِّع $currentStreak يوماً!',
      'لم تراجع حفظك اليوم بعد — لا تزال قادرًا',
      _todayAt(TimeOfDay(hour: 22, minute: 0)),
      ...
    );
  }
  
  // تذكير بآية اليوم من الورد اليومي
  Future<void> scheduleDailyAyah() async {
    await _plugin.periodicallyShow(
      NotificationIds.dailyAyah,
      'آية اليوم ✨',
      _getDailyAyahText(),
      RepeatInterval.daily,
      ...
    );
  }
}
```

**أنواع الإشعارات:**
- تذكير المراجعة اليومية (وقت يختاره المستخدم)
- تحذير انقطاع الـ streak قبل منتصف الليل
- إشعار آية اليوم في الصباح
- تذكير إذا مر 3 أيام بلا دخول للتطبيق
- تهنئة عند فتح إنجاز جديد

---

### ⏰ FEAT-N02 — تذكير أوقات الصلاة (Salah Integration)

**الأثر:** 🟡 متوسط — يجعل التطبيق جزءًا من روتين المستخدم  
**الصعوبة:** 🟡 متوسطة  
**الحزمة:** `adhan: ^2.1.1`

```dart
// صغّر جلسة الحفظ بعد كل صلاة
// "لديك 10 دقائق قبل الإقامة — راجع آيتين"
class PrayerIntegrationService {
  Future<void> schedulePostPrayerReminder(Prayer prayer) async {
    final nextPrayer = await _prayerTimes.nextPrayer();
    // إشعار بعد 5 دقائق من وقت الصلاة
  }
}
```

---

## 👨‍👩‍👧 المحور الخامس — وضع الأطفال المتطور {#محور-الأطفال}

### 🎨 FEAT-K01 — واجهة أطفال مستقلة كاملة

**الأثر:** 🔥 عالي — شريحة سوق كاملة  
**الصعوبة:** 🔴 عالية  

```
وضع الأطفال الحالي: صفحة واحدة بسيطة
المقترح: تجربة أطفال متكاملة مستقلة
```

**ميزات وضع الأطفال المتطور:**
- خلفيات ملونة وشخصيات متحركة (بدون صور بشرية)
- خط أكبر وأكثر وضوحًا
- أصوات تشجيعية بالعربية عند النجاح
- نجوم ✨ وجوائز رمزية بدلاً من الـ Progress bars
- وضع "ولي الأمر" لمتابعة تقدم الطفل
- تحديد سور مناسبة للأطفال (قصار السور أولاً)
- جلسات أقصر (5 دقائق كحد أقصى)

```dart
// parent_dashboard_page.dart
class ParentDashboardPage extends StatelessWidget {
  // تقرير يومي عن الطفل
  // عدد الآيات المحفوظة هذا الأسبوع
  // الـ streak
  // آخر جلسة
  // إشعار "أكمل طفلك جلسة اليوم!"
}
```

---

### 🎵 FEAT-K02 — ترديد جماعي مع الصوت

**الأثر:** 🟡 متوسط  
**الصعوبة:** 🟡 متوسطة  

للأطفال: وضع "الترديد مع الشيخ" — يُشغِّل الصوت ويطلب من الطفل الترديد مباشرة خلفه (الطريقة الكلاسيكية في الكتّاب).

---

## 📊 المحور السادس — التقارير والإحصائيات {#محور-التقارير}

### 📈 FEAT-S01 — رسوم بيانية للتقدم

**الأثر:** 🟡 متوسط  
**الصعوبة:** 🟢 منخفضة  
**الحزمة:** `fl_chart: ^0.69.0`

```dart
// progress_charts_widget.dart

// 1. رسم خطي: الآيات المحفوظة على مدار 30 يوماً
LineChart(ayahsMemorizedPerDay)

// 2. رسم شريطي: مقارنة الأسابيع
BarChart(weeklyComparison)

// 3. رسم دائري: توزيع حالات الآيات
PieChart([
  PieChartSectionData(value: memorized, color: Colors.green),
  PieChartSectionData(value: reviewing, color: Colors.blue),
  PieChartSectionData(value: learning, color: Colors.orange),
])

// 4. Heatmap: خريطة النشاط (مثل GitHub)
ActivityHeatmap(dailyActivity: last365Days)
```

---

### 📄 FEAT-S02 — تقرير PDF قابل للمشاركة

**الأثر:** 🟡 متوسط  
**الصعوبة:** 🟡 متوسطة  

```yaml
pdf: ^3.11.0
```

تقرير شهري يحتوي:
- إجمالي الآيات المحفوظة
- السور المكتملة
- رسم بياني للتقدم
- شهادة إنجاز إذا أتمّ سورة كاملة

---

### 🏆 FEAT-S03 — شهادات الحفظ

**الأثر:** 🟡 متوسط — قيمة عاطفية كبيرة  
**الصعوبة:** 🟡 متوسطة  

شهادة رقمية جميلة عند إتمام:
- حفظ سورة كاملة
- إتمام جزء كامل
- الوصول لـ 100 يوم streak

قابلة للمشاركة على وسائل التواصل الاجتماعي.

---

## 🌐 المحور السابع — الميزات الاجتماعية {#محور-اجتماعي}

### 👥 FEAT-SO01 — مجموعات الحفظ (Study Groups)

**الأثر:** 🔥 عالي — الـ Retention الأعلى  
**الصعوبة:** 🔴 عالية (يحتاج Backend)  

```dart
// study_group_model.dart
class StudyGroup {
  final String id;
  final String name;           // "مجموعة الأسرة", "مجموعة الزملاء"
  final String joinCode;       // كود للانضمام
  final List<GroupMember> members;
  final int targetSurahId;     // رقم السورة المشتركة (int, 1→114)
  final GroupLeaderboard leaderboard;
}
```

**ميزات المجموعة:**
- مشاركة التقدم مع الأسرة أو الأصدقاء
- منافسة ودية: من يحفظ أكثر هذا الأسبوع؟
- تشجيع متبادل: "أحمد أتمّ سورة الملك اليوم! 🎉"
- إشعار إذا غاب عضو من المجموعة أكثر من يومين

---

### 🤝 FEAT-SO02 — مشاركة تقدمك

**الأثر:** 🟡 متوسط — marketing مجاني  
**الصعوبة:** 🟢 منخفضة  

```dart
// بطاقة مشاركة جميلة:
// "أتممت حفظ سورة الملك في تطبيق تالية!
//  سلسلة: 47 يوماً 🔥
//  حُفِظَ: 267 آية"
// + زر مشاركة على واتساب / تيليجرام / إنستجرام
```

---

## ⚙️ المحور الثامن — الإعدادات والتخصيص {#محور-الإعدادات}

### 🎨 FEAT-SET01 — ثيمات متعددة

**الأثر:** 🟡 متوسط  
**الصعوبة:** 🟢 منخفضة  

```dart
enum AppThemeVariant {
  forest,    // الحالي (أخضر داكن)
  night,     // أسود مع ذهبي
  parchment, // بيج دافئ (محاكاة الورق)
  royal,     // كحلي مع فضي
  minimal,   // أبيض نقي
}
```

---

### 📝 FEAT-SET02 — تخصيص جلسة الحفظ

**الأثر:** 🟡 متوسط  
**الصعوبة:** 🟢 منخفضة  

```
إعدادات الجلسة:
├── حجم الخط (صغير / متوسط / كبير / كبير جداً)
├── إظهار/إخفاء التشكيل
├── إظهار/إخفاء الترجمة
├── سرعة الصوت (بطيء / عادي / سريع)
├── عدد التكرار قبل التسميع (1 / 2 / 3 / 5)
├── وقت الصمت بين الآيات
└── الانتقال التلقائي بعد النجاح
```

---

### 🌍 FEAT-SET03 — ترجمات معاني القرآن

**الأثر:** 🟡 متوسط — يستهدف غير العرب أو المبتدئين  
**الصعوبة:** 🟡 متوسطة  

```dart
enum QuranTranslation {
  arabic,      // التفسير العربي الميسر
  englishSahi, // Saheeh International
  urdu,        // ترجمة أردية
  french,      // فرنسية
}
```

---

## 🏗 المحور التاسع — البنية التقنية {#محور-تقني}

### 💾 FEAT-T01 — قاعدة بيانات Isar

**الأثر:** 🔥 عالي — أساس كل تحسين آخر  
**الصعوبة:** 🟡 متوسطة  

```yaml
isar: ^4.0.0
isar_flutter_libs: ^4.0.0
path_provider: ^2.1.3
```

```dart
// schemas/ayah_review_schema.dart
@collection
class AyahReviewSchema {
  Id get isarId => Isar.autoIncrement;
  
  @Index(composite: [CompositeIndex('ayahNumber')])
  late int surahId;
  late int ayahNumber;
  late int strengthLevel;
  late int intervalDays;
  late DateTime nextReviewDate;
  late DateTime lastReviewedAt;
  late int totalReviews;
  
  // Query: كل الآيات المستحقة اليوم
  static Future<List<AyahReviewSchema>> getDueToday(Isar isar) {
    return isar.ayahReviewSchemas
        .filter()
        .nextReviewDateLessThan(DateTime.now())
        .findAll();
  }
}
```

**مكاسب الانتقال لـ Isar:**
- استعلام `getDueToday()` في O(log n) بدلاً من O(n)
- لا فقدان للبيانات عند الـ crash (atomic transactions)
- دعم full-text search للبحث في القرآن
- حجم تخزين أصغر (binary بدلاً من JSON strings)

---

### 🔄 FEAT-T02 — مزامنة السحابة (Cloud Sync)

**الأثر:** 🔥 عالي — مستخدمون بأجهزة متعددة  
**الصعوبة:** 🔴 عالية  
**الخيارات:** Supabase (مجاني حتى 500MB) أو Firebase

```dart
// sync_service.dart
class CloudSyncService {
  // يحتفظ ببيانات الحفظ في السحابة
  // يستعيدها عند تثبيت التطبيق على جهاز جديد
  // Conflict resolution: آخر تحديث يفوز
  
  Future<void> syncUp() async {
    final unsynced = await _db.getUnsyncedRecords();
    await _supabase.from('ayah_reviews').upsert(unsynced.toJson());
  }
  
  Future<void> syncDown() async {
    final remote = await _supabase.from('ayah_reviews')
        .select().eq('user_id', userId);
    await _db.mergeRecords(remote);
  }
}
```

---

### 📦 FEAT-T03 — تخزين مؤقت ذكي للصوت

**الأثر:** 🟡 متوسط  
**الصعوبة:** 🟢 منخفضة  
**الحزمة:** `flutter_cache_manager: ^3.4.1`

```dart
// audio_cache_service.dart
class AudioCacheService {
  static final _cacheManager = CacheManager(
    Config(
      'quran_audio',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500, // ~500 آية = ~50MB
    ),
  );
  
  Future<String> getAudioPath(int surahId, int ayahNumber) async {
    final url = QuranAudioService.buildUrl(surahId, ayahNumber);
    final file = await _cacheManager.getSingleFile(url);
    return file.path;
  }
  
  // تحميل مسبق لآيات الجلسة القادمة
  Future<void> prefetchSession(List<Ayah> ayahs) async {
    for (final ayah in ayahs) {
      unawaited(getAudioPath(ayah.surahId, ayah.numberInSurah));
    }
  }
}
```

---

### 🧪 FEAT-T04 — اختبارات شاملة (Test Suite)

**الأثر:** 🔥 عالي — ضمان الجودة على المدى البعيد  
**الصعوبة:** 🟡 متوسطة  

```dart
// test/core/sm2_algorithm_test.dart
void main() {
  group('SM-2 Algorithm', () {
    test('excellent rating increases interval', () {
      final result = SM2Algorithm.calculate(
        repetitions: 2, easeFactor: 2.5, intervalDays: 6, quality: 5,
      );
      expect(result.intervalDays, greaterThan(6));
      expect(result.easeFactor, greaterThanOrEqualTo(2.5));
    });
    
    test('failed review resets repetitions', () {
      final result = SM2Algorithm.calculate(
        repetitions: 5, easeFactor: 2.5, intervalDays: 30, quality: 1,
      );
      expect(result.repetitions, equals(0));
      expect(result.intervalDays, equals(1));
    });
  });

  group('ArabicNormalizer', () {
    test('removes tashkeel correctly', () {
      expect(
        ArabicNormalizer.normalize('بِسْمِ اللَّهِ'),
        equals('بسم الله'),
      );
    });
    
    test('normalizes alef variations', () {
      expect(ArabicNormalizer.normalize('إِنَّا أَعْطَيْنَاكَ'), 
             equals(ArabicNormalizer.normalize('انا اعطيناك')));
    });
  });

  group('StreakCalculation', () {
    test('consecutive days increase streak', () {
      // TODO: inject mock DateTime and assert streak increments
      expect(true, isTrue); // placeholder — يكتمل مع تطبيق StreakService
    });
    test('missed day resets streak to 1', () {
      expect(true, isTrue); // placeholder
    });
    test('same day doesnt change streak', () {
      expect(true, isTrue); // placeholder
    });
  });
}
```

---

### 🖥 FEAT-T05 — Widget للشاشة الرئيسية (Home Screen Widget)

**الأثر:** 🟡 متوسط — تذكير دائم بالتطبيق  
**الصعوبة:** 🟡 متوسطة  
**الحزمة:** `home_widget: ^0.6.0`

```dart
// widgets:
// 1. آية اليوم (نص + صوت بلمسة واحدة)
// 2. عداد الـ Streak مع تحذير إذا لم يُفتح التطبيق
// 3. عدد الآيات المعلقة للمراجعة
```

---

## 💼 المحور العاشر — التسييل والنشر {#محور-تسييل}

### 💎 FEAT-M01 — نموذج Freemium

**الأثر:** 🔥 عالي — استدامة المشروع  
**الصعوبة:** 🟡 متوسطة  

```
الطبقة المجانية (Free):
├── قراءة القرآن الكريم كاملاً
├── الأذكار
├── حفظ حتى 3 سور
└── الإشعارات الأساسية

الطبقة المدفوعة (Premium - شهري/سنوي):
├── حفظ بلا حدود
├── مزامنة السحابة
├── وضع المصحف (صور الصفحات)
├── التعرف الصوتي المتقدم (Whisper)
├── التقارير التفصيلية
├── Tajweed Coloring
├── جميع القراء الصوتيين
└── تحميل للاستخدام بدون إنترنت
```

---

### 🎁 FEAT-M02 — اشتراك عائلي

```dart
// family_plan.dart
// اشتراك واحد يشمل حتى 6 أفراد من العائلة
// وضع الأطفال مرتبط بحساب ولي الأمر
// تقرير موحد للعائلة كلها
```

---

### 📱 FEAT-M03 — تحسين الـ ASO (App Store Optimization)

**قبل النشر:**
- [ ] اسم التطبيق: "تالية — حفظ القرآن الكريم"
- [ ] وصف يتضمن كلمات مفتاحية: حفظ، تجويد، مراجعة، ذكاء اصطناعي
- [ ] لقطات شاشة احترافية (بالعربية والإنجليزية)
- [ ] فيديو تعريفي 30 ثانية
- [ ] الفئة: Reference أو Education
- [ ] تقييم المحتوى: 4+ (مناسب للجميع)

---

## 📊 جدول أولويات التطوير الشامل

| المرحلة | الميزة | الأثر | الصعوبة | الأسابيع المقدرة |
|---------|--------|-------|----------|-----------------|
| **أولاً** | إصلاح الـ Blockers (BUG-001 → BUG-007) | 🔴 حرجة | 🟡 | 2 |
| **أولاً** | إصلاح المعمارية (ARCH-001 → ARCH-008) | 🔴 حرجة | 🟡 | 2 |
| **ثانياً** | توحيد نظامَي الحفظ | 🔥 عالي | 🔴 | 2 |
| **ثانياً** | FEAT-R01 — الخط القرآني | 🔥 عالي | 🟢 | 1 |
| **ثانياً** | FEAT-N01 — الإشعارات | 🔥 عالي | 🟡 | 1 |
| **ثانياً** | FEAT-R04 — البحث | 🔥 عالي | 🟡 | 1 |
| **ثالثاً** | FEAT-T03 — Audio Caching | 🔥 عالي | 🟢 | 1 |
| **ثالثاً** | FEAT-R05 — صفحة المفضلة | 🟡 متوسط | 🟢 | 1 |
| **ثالثاً** | FEAT-G01 — الإنجازات المتطورة | 🟡 متوسط | 🟡 | 2 |
| **ثالثاً** | FEAT-H05 — تحسين التسميع | 🔥 عالي | 🔴 | 2 |
| **رابعاً** | FEAT-T01 — Isar Database | 🔥 عالي | 🟡 | 3 |
| **رابعاً** | FEAT-R02 — Tajweed Coloring | 🔥 عالي | 🔴 | 3 |
| **رابعاً** | FEAT-T04 — Test Suite | 🔥 عالي | 🟡 | 2 |
| **خامساً** | FEAT-T02 — Cloud Sync | 🔥 عالي | 🔴 | 4 |
| **خامساً** | FEAT-SO01 — مجموعات الحفظ | 🔥 عالي | 🔴 | 4 |
| **خامساً** | FEAT-M01 — Freemium | 🔥 عالي | 🟡 | 2 |

---

## 🎯 الرؤية النهائية للتطبيق

بعد تطبيق كل هذه التحسينات، سيكون تطبيق **تالية** قادرًا على المنافسة مع:

| التطبيق | الميزة التي نتفوق فيها |
|---------|----------------------|
| **Quran.com** | نظام الحفظ الذكي بالصوت |
| **Memorize Quran** | تجربة الأطفال المتكاملة |
| **Hisnul Muslim** | دمج الأذكار مع الحفظ في بيئة واحدة |
| **تطبيقات التحفيظ التقليدية** | الـ Gamification والـ Streak والإشعارات |

**الميزة الجوهرية لتالية التي لا يقدمها أحد بشكل متكامل:**  
> نظام حفظ ذكي يجمع التسميع الصوتي التلقائي + SM-2 علمياً دقيق + وضع أطفال متكامل + متابعة الأسرة — كل هذا في تطبيق واحد بتصميم إسلامي أصيل ومحلي بالكامل (offline-first).

---

*هذا التقرير الشامل يغطي 13 بلوكرز، 11 مشكلة معمارية، 11 مشكلة في البيانات، 15 مشكلة UX، 11 مشكلة جودة كود، و38 مقترح تطوير موزعة على 10 محاور، و Sprint 0 جديد — بناءً على مراجعتين كاملتين لـ 95 ملف من ملفات المشروع يدويًا.*
