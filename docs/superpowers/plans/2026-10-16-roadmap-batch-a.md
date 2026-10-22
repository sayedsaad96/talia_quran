# خارطة التميّز، الدفعة A: خطة التنفيذ

> **للوكلاء المنفذين:** مهارة فرعية مطلوبة: superpowers:subagent-driven-development (موصى بها) أو superpowers:executing-plans. الخطوات بصيغة `- [ ]`.

**الهدف:** تنفيذ أول أربعة بنود من المرحلة 1 في خارطة التميّز المعتمدة:
- **W0:** أدوات اختبار الأعلام على الجهاز.
- **البند 1:** خريطة قوة الحفظ على المصحف.
- **البند 12:** تكرار الآيات ومؤقت النوم في القارئ.
- **البند 2:** مركز الثقة.

**البنية:** أعلام `ExperienceFlags` جديدة على نمط `AdultJourneyFlags`. كل ميزة مطفأة افتراضياً. المنطق في دوال Dart خالصة قابلة للاختبار، والواجهة تتكيّف دون أي مساس ببيانات القرآن.

**التقنيات:** Flutter، `flutter_bloc`، `go_router`، `get_it`، `just_audio` (`QuranContinuousPlayerService`)، `qcf_quran_plus 0.0.8`، SharedPreferences.

**المواصفة:** `docs/superpowers/specs/2026-10-13-talia-differentiation-roadmap.md` (البنية المشتركة، وW0، والبنود 1 و2 و12). الحقائق المستقاة من الكود في `.superpowers/batch-a-facts.md`.

## Global Constraints

**المحتوى والبيانات:**
- لا يُعدَّل أي ملف في `assets/data/`، ولا يُعرض أي نص ديني جديد. التلوين طبقة عرض فقط فوق `qcf_quran_plus`.
- لا تغيير في Supabase، ولا في مخطط Isar، ولا في `V2SessionEngine`، ولا في المزامنة.

**الأعلام:**
- `lib/core/experience/experience_feature_flags.dart` يحتوي `enum ExperienceFeature` و`class ExperienceFlags`.
- بادئة المفتاح: `experience_flag_`. القيمة المفقودة أو غير المقروءة تعني مطفأ. إطفاء العلم يعيد الواجهة السابقة ولا يحذف أي بيانات.
- **قيم هذه الدفعة:** `strengthOverlay` و`readerRepeat` و`trustCenter`.
- **قيم تُضاف الآن للحفاظ على الجرد، ولا يقرؤها أحد بعد:**
  - `seasonalRamadan`
  - `forgettingForecast`
  - `similarAyahTrainer`
  - `prayerReview`
  - `homeWidget`
  - `handsFreeReview`
  - `clarityMode`
  - `groupKhatmah`
  - `localBackup`
  - `audioDownloads`
  - `afterPrayerAzkar`
  - `ayahNotes`
  - `tabletSpread`
  - `hijriYearRecap`
- **ممنوع إعادة تسمية أي قيمة.**

**البند 1 (خريطة القوة):**
- للبالغ فقط. قارئ الأطفال (`kids_quran_reader_page.dart`) لا يتغير.
- السجلات عبر `getAllReviewRecords(scope: ReviewRecordReadScope.adult)`.

**البند 2 (مركز الثقة): قرار T2.0 = الخيار (b).**
- **السبب:** `hasOnDeviceSupport` غير مكشوفة في واجهة `SpeechToText` العامة في الإصدار 7.5.0، وتشترط Android API 31 أو أعلى. تفعيل `onDevice: true` يُفشل التلاوة على أجهزة كثيرة.
- **النتيجة:** لا يُغيَّر أي استدعاء لـ`SpeechListenOptions`. نص الصوت هو حرفياً: «تالية لا تسجّل صوتك ولا تحفظه ولا ترفعه. التعرّف على الكلام تقوم به خدمة النظام في جهازك.»

**قواعد التنفيذ:**
- قبل `flutter test`، في نفس أمر PowerShell:

```powershell
$env:TEMP='D:\Flutter\talia_quran\.superpowers\tmp'; $env:TMP=$env:TEMP;
```

- لا يعمل أمرا `flutter test` في الوقت نفسه.
- `dart format` للملفات الجديدة فقط. الملفات الموجودة تُعدَّل يدوياً، ثم يُفحص `git diff --stat`.
- الاستيرادات نسبية داخل `lib/`.
- ARB في `app_ar.arb` و`app_en.arb` معاً، ثم `flutter gen-l10n`، ثم `test/core/l10n` (حارس المفاتيح المكررة).
- لا تُستخدم أيقونات Material في `lib/`. الأيقونات من `TaliaIcon` و`TaliaIcons`/`TaliaKidsIcons`، ونصف القطر من `AppSpacing.radius*` (حارسا `test/core/icons/talia_icon_test.dart` و`test/design_system/design_token_guard_test.dart`).
- Commit بمسارات صريحة: `git commit -m "..." -- <files>`. الرسالة تنتهي بسطر فارغ ثم `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **تشغيل صوت آية مع تلوين القوة:** إضاءة الصوت والتحديد والإشارة المرجعية تغلب تلوين القوة لنفس الآية. *(Task 4)*
2. **تبديل الحساب والقارئ مفتوح:** تلوين الحساب السابق يختفي ولا يبقى في الذاكرة المؤقتة. *(Task 4)*
3. **«التالي» أثناء تكرار آية خمس مرات:** ينتقل إلى الآية التالية المختلفة، لا إلى التكرار التالي لنفس الآية. *(Task 6)*
4. **مؤقت النوم والتطبيق في الخلفية:** التشغيل يتوقف فعلاً، وإلغاء المؤقت يعيد مستوى الصوت كاملاً. *(Task 6)*
5. **ملف المانيفست تالف أو مفقود:** مركز الثقة يعرض البطاقات دون أرقام، ولا يتعطل. *(Task 7)*

---

### Task 1: أعلام التجربة وشاشة «المختبر» للتطوير

**Files:**
- Create: `lib/core/experience/experience_feature_flags.dart`
- Create: `lib/features/settings/presentation/pages/labs_flags_page.dart`
- Modify: `lib/core/router/app_router.dart` (ثابت `labsFlags = '/settings/labs'` ومسار `GoRoute`)
- Modify: `lib/features/settings/presentation/pages/subpages/about_settings_page.dart` (بلاطة تظهر فقط إذا كان `kDebugMode`)
- Modify: `lib/core/di/injection.dart` (تسجيل `ExperienceFlags`)
- Test: `test/core/experience/experience_feature_flags_test.dart`
- Test: `test/features/settings/presentation/pages/labs_flags_page_test.dart`

**Interfaces:**

```dart
enum ExperienceFeature { strengthOverlay, readerRepeat, trustCenter, /* + inventory list */ ;
  String get storageKey => '${ExperienceFlags.keyPrefix}$name'; }
class ExperienceFlags {
  const ExperienceFlags(this._readBool);
  ExperienceFlags.fromPreferences(SharedPreferences prefs);
  static const keyPrefix = 'experience_flag_';
  bool isEnabled(ExperienceFeature feature); // missing/throwing → false
}

/// One switch per flag of every rollout family. Writes go straight to
/// SharedPreferences with the family's exact key.
class LabsFlagsPage extends StatefulWidget { const LabsFlagsPage({super.key, required this.prefs}); }
```

**الشاشة:** أربع مجموعات من المفاتيح، كل مفتاح يكتب نفس المفتاح الذي يقرؤه العلم.

| المجموعة | المفاتيح |
|---|---|
| `KidsEnrichmentFeature` | قيمه كلها |
| `AdultJourneyFeature` | قيمه كلها |
| `KidsHifzFeatureFlags` | `enabledKey` و`quranJourneyKey` |
| `ExperienceFeature` | قيمه كلها |

- العناوين نص تقني إنجليزي ثابت، فهذه شاشة للمطوّر وليست للمستخدم، **ولا تحتاج ARB**.
- الصفحة والمسار والبلاطة تعمل فقط إذا كان `kDebugMode`. في غيره يحوّل المسار إلى الإعدادات.

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('missing / non-bool / throwing read → false', ...);
test('storage keys are experience_flag_<name> and unique', ...);
testWidgets('labs page lists every family and toggling writes the exact key', ...);
  // toggle kids_enrichment_homeMissionTemplates → prefs.getBool(...) == true
```

- [ ] **Step 2: RED**

Run: `flutter test test/core/experience test/features/settings/presentation/pages/labs_flags_page_test.dart`

- [ ] **Step 3: التنفيذ.**

- [ ] **Step 4: GREEN**، ثم `flutter analyze`.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(experience): rollout flags and debug-only labs page"
```

---

### Task 2: مصفوفة اختبار الأعلام على الجهاز (W0)

**Files:**
- Create: `docs/release/flag-device-test-matrix.md`

مستند عربي. لكل علم صف واحد في جدول بالأعمدة التالية:

| العلم والمفتاح | مكان الظهور (من الحقائق A5) | خطوات التفعيل (شاشة المختبر) | السيناريو | المتوقع | حالات حدّية | النتيجة |
|---|---|---|---|---|---|---|

- **الحالات الحدّية لكل علم:** تبديل الحساب، والعمل دون إنترنت، وإطفاء العلم بعد الاستعمال، وإعادة تشغيل التطبيق.
- **الأعلام المؤجَّلة** (T5 وT6 وT11 وT12) تُذكر في قسم «لا يُختبر».
- **في الأعلى:** قسم «كيف أبدأ»: `flutter run` (بناء debug)، ثم الإعدادات، ثم «حول»، ثم «Labs».
- **في الأسفل:** «ترتيب التفعيل المقترح» بثلاث دفعات كما في §W0 من الخارطة. أضف إليها رحلة القرآن للأطفال مع إثراء الأطفال.

- [ ] **Step 1: الكتابة** من `.superpowers/batch-a-facts.md` (القسم A) ومن الكود عند الحاجة.
- [ ] **Step 2: Commit**

```bash
git commit -m "docs(release): flag device test matrix"
```

---

### Task 3: حالة قوة الحفظ ومصدر نطاقات الصفحة (خالص)

**Files:**
- Create: `lib/core/memorization/strength_band.dart`
- Create: `lib/features/quran/presentation/services/strength_overlay_source.dart`
- Test: `test/core/memorization/strength_band_test.dart`
- Test: `test/features/quran/presentation/services/strength_overlay_source_test.dart`

**Interfaces:**

```dart
enum StrengthBand { none, due, weak, building, solid }
StrengthBand strengthBandFor(AyahReviewRecord? record, DateTime now);
// null or totalReviews == 0 → none; classifyAt(now).isDue → due;
// strengthLevel 1-2 → weak; 3-5 → building; >= 6 → solid; 0 with reviews → weak

typedef PageAyahRanges = List<({int surah, int start, int end})> Function(int page);
// production: wraps qcf getPageData(page) (keys surah/start/end)

class StrengthOverlaySource {
  StrengthOverlaySource({required PageAyahRanges pageRanges});
  void setRecords(Iterable<AyahReviewRecord> adultRecords); // clears per-page cache
  void clear();
  Map<({int surah, int ayah}), StrengthBand> bandsForPage(int page, DateTime now); // cached per page, none omitted
}
```

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('band boundaries: null, 0 reviews, due wins over solid, 2→weak, 3→building, 5→building, 6→solid', ...);
test('bandsForPage covers only ayahs in the page ranges and omits none', ...);
test('setRecords clears the page cache; clear() empties results', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ. Step 4: GREEN.**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(reader): memorization strength bands and page ranges"
```

---

### Task 4: تلوين القوة في قارئ البالغ

**Files:**
- Create: `lib/features/quran/presentation/cubits/strength_overlay_cubit.dart`
- Create: `lib/features/quran/presentation/widgets/strength_overlay_legend.dart`
- Modify: `lib/features/quran/presentation/pages/quran_reader_page.dart`
  - `readerHighlights` (حول الأسطر 50–86)، مع معامل جديد اختياري `Map<({int surah,int ayah}),StrengthBand> strengthBands = const {}`.
  - الحساب حول السطر 714.
- Modify: `lib/features/quran/presentation/widgets/reader_overflow_sheet.dart`
  - معاملان جديدان اختياريان: `bool? strengthOverlayEnabled` و`ValueChanged<bool>? onStrengthOverlayChanged`.
  - يُعرض المفتاح فقط إذا لم يكونا `null`.
- Modify: `lib/features/quran/presentation/widgets/ayah_options_sheet.dart`
  - زر «راجع هذه الآية الآن» يستخدم `LearningIntent.review` و`LearningOrigin.quranReader`، على نمط `_startLearning`.
  - يظهر فقط مع العلم ووجود سجل مراجعة للآية.
- Modify: `lib/core/di/injection.dart`، وARB
- Test: `test/features/quran/presentation/cubits/strength_overlay_cubit_test.dart`
- Test: `test/features/quran/presentation/pages/reader_highlights_test.dart`

**Interfaces:**

```dart
class StrengthOverlayState extends Equatable { final bool enabled; final int revision; }
class StrengthOverlayCubit extends Cubit<StrengthOverlayState> {
  StrengthOverlayCubit({required MemorizationPlusRepository repository, required ProgressEventsBus events,
    required StrengthOverlaySource source, required SharedPreferences prefs, DateTime Function()? clock});
  Future<void> init();               // reads persisted toggle 'reader_strength_overlay_on' (per device), loads adult records if on
  Future<void> setEnabled(bool on);  // persists; loads or clears
  Map<({int surah,int ayah}),StrengthBand> bandsForPage(int page); // empty when off
  // listens to ProgressEventsBus (reviewRecord and account/owner changes) → reload records, bump revision; cancel on close
}
```

**الدمج في `readerHighlights`:**
- تلوين القوة يوضع **أولاً** في القائمة. في `qcf` آخر عنصر لنفس الآية هو الذي يُرسم، فتغلب الإشارات المرجعية والصوت والتحديد.
- **ألوان القوة** (alpha قبل ضرب `qcf` في 0.4):

| الحالة | اللون | alpha |
|---|---|---|
| `due` | `tokens.warning` | 0.45 |
| `weak` | `tokens.error` | 0.40 |
| `building` | `tokens.info` | 0.40 |
| `solid` | `tokens.success` | 0.40 |

- **لا ميزة دون العلم:** عند إطفاء `ExperienceFeature.strengthOverlay` لا يُنشأ الكيوبت ولا يظهر المفتاح.

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `strengthOverlayToggle` | «إظهار قوة الحفظ» | "Show memorization strength" |
| `strengthLegendDue` | «مستحقة» | "Due" |
| `strengthLegendWeak` | «ضعيفة» | "Weak" |
| `strengthLegendBuilding` | «تتقوّى» | "Building" |
| `strengthLegendSolid` | «ثابتة» | "Solid" |
| `reviewThisAyahNow` | «راجع هذه الآية الآن» | "Review this ayah now" |

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('readerHighlights puts strength first so audio/selected/bookmark win for the same ayah', ...);
test('readerHighlights with empty strengthBands equals the previous output', ...);
test('cubit off → bandsForPage empty; on → bands from adult records only (kids records ignored)', ...);
test('reviewRecord change event reloads and bumps revision; owner switch event clears', ...);
test('toggle persists across cubit instances', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ.**

- [ ] **Step 4: GREEN.** ثم `flutter analyze`، ثم `test/features/quran`، ثم حارسا الأيقونات والرموز.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(reader): memorization strength overlay behind experience flag"
```

---

### Task 5: خطة التكرار ومؤقت النوم (خالص)

**Files:**
- Create: `lib/core/services/reader_repeat_plan.dart`
- Create: `lib/core/services/sleep_timer.dart`
- Test: `test/core/services/reader_repeat_plan_test.dart`
- Test: `test/core/services/sleep_timer_test.dart`

**Interfaces:**

```dart
final class ReaderRepeatSettings extends Equatable {
  const ReaderRepeatSettings({this.perAyah = 1, this.rangeTimes = 1, this.speed = 1.0});
  final int perAyah;     // 1..10
  final int rangeTimes;  // 1..10, or 0 = infinite (loop)
  final double speed;    // 0.75, 1.0, 1.25, 1.5
  bool get isDefault;
}
/// Expands [ayahs] (in order) into the playback queue. rangeTimes 0 → one pass
/// (the caller sets loop mode). Values outside the ranges are clamped.
List<T> expandRepeatQueue<T>(List<T> ayahs, ReaderRepeatSettings s);
/// Index of the first queue item of the next / previous DISTINCT ayah.
int? nextDistinctIndex<T>(List<T> queue, int current);
int? previousDistinctIndex<T>(List<T> queue, int current);

enum SleepTimerChoice { off, min15, min30, min60, endOfSurah }
class SleepTimer {
  SleepTimer({required void Function(double volume) setVolume, required Future<void> Function() stop,
    DateTime Function()? clock});
  void start(Duration d); void cancel(); bool get isActive; Duration? get remaining;
  // last 10 s: volume ramps 1.0 → 0.0 in steps; on expiry stop() then setVolume(1.0); cancel() restores 1.0
}
```

**قرار:** لا فاصل صامت بين التكرارات في v1، لأن `_queue[index]` في الخدمة يربط الفهرس بالآية، والصمت يكسر هذا الربط. يُسجَّل في التقرير.

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('perAyah 3, rangeTimes 2 over [a,b] → a,a,a,b,b,b,a,a,a,b,b,b', ...);
test('defaults return the input unchanged', ...);
test('clamping: perAyah 0→1, 11→10', ...);
test('nextDistinctIndex skips repeats of the same ayah; null at the end', ...);
test('sleep timer fades in the last 10 s, stops, restores volume; cancel restores volume', ...); // fake_async
```

- [ ] **Step 2: RED. Step 3: التنفيذ. Step 4: GREEN.**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(reader-audio): repeat queue expansion and sleep timer"
```

---

### Task 6: التكرار ومؤقت النوم في المشغّل وشريط الصوت

**Files:**
- Modify: `lib/core/services/quran_continuous_player_service.dart`
  - إعدادات تكرار تُطبَّق عند بناء `_queue`.
  - `LoopMode.all` عند `rangeTimes == 0`.
  - `setSpeed`.
  - `nextAyah` و`previousAyah` يستخدمان `next/previousDistinctIndex` عند وجود تكرار.
  - `SleepTimer`.
- Modify: `lib/features/quran/presentation/cubits/quran_audio_player_cubit.dart` (الحالة تحمل `ReaderRepeatSettings` و`SleepTimerChoice`، والدوال `setRepeat` و`setSleepTimer`)
- Create: `lib/features/quran/presentation/widgets/reader_repeat_sheet.dart`
- Modify: `lib/features/quran/presentation/widgets/reader_docked_audio_bar.dart` (زر يفتح الورقة، فقط مع العلم)
- Modify: ARB
- Test: `test/core/services/quran_continuous_player_repeat_test.dart` (بنمط الاختبار الموجود للخدمة إن وُجد، وإلا بمشغّل وهمي يُمرَّر)
- Test: `test/features/quran/presentation/widgets/reader_repeat_sheet_test.dart`

**القواعد:**
- **مدى التكرار:** من الآية الحالية إلى نهاية النطاق الذي بدأ التشغيل به (صفحة أو سورة).
- **v1:** لا يوجد اختيار «من آية إلى آية» يدوياً، ويُسجَّل ذلك.
- **عند تغيير الإعدادات أثناء التشغيل:** يُعاد بناء القائمة من الآية الحالية.
- **«حتى نهاية السورة»:** يتوقف التشغيل عند آخر آية في السورة الحالية (الإيقاف في مستمع `currentIndex`).
- **التخزين:** لا يُحفظ أي إعداد بين الجلسات.

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `readerRepeatTitle` | «التكرار ومؤقت النوم» | "Repeat and sleep timer" |
| `readerRepeatPerAyah` | «تكرار كل آية» | "Repeat each ayah" |
| `readerRepeatRange` | «تكرار المقطع» | "Repeat the passage" |
| `readerRepeatInfinite` | «بلا توقف» | "Non-stop" |
| `readerRepeatSpeed` | «سرعة التلاوة» | "Recitation speed" |
| `readerSleepTimer` | «مؤقت النوم» | "Sleep timer" |
| `readerSleepOff` | «إيقاف» | "Off" |
| `readerSleepMinutes` | «{count} دقيقة» (`countText` String) | "{countText} min" |
| `readerSleepEndOfSurah` | «حتى نهاية السورة» | "End of surah" |

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('setRepeat(perAyah 3) rebuilds the queue from the current ayah', ...);
test('nextAyah with repeats jumps to the next distinct ayah', ...);
test('rangeTimes 0 sets LoopMode.all; back to 1 sets LoopMode.off', ...);
test('endOfSurah stops after the last ayah of the current surah', ...);
testWidgets('sheet hidden button when flag off; sheet changes call cubit', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ.**

- [ ] **Step 4: GREEN.** ثم `flutter analyze`، ثم `test/features/quran` و`test/core/services`، ثم الحارسان.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(reader-audio): repeat and sleep timer in the reader"
```

---

### Task 7: مركز الثقة

**Files:**
- Create: `lib/features/settings/presentation/pages/trust_center_page.dart`
- Create: `lib/core/content/content_manifest_summary.dart` (قراءة `assets/data/content_manifest.json`)
- Modify: `lib/core/router/app_router.dart` (`trustCenter = '/settings/trust-center'`)
- Modify: `about_settings_page.dart` (بلاطة في مجموعة «الخصوصية والأمان» قبل `PrivacyPolicyTile`، فقط مع العلم)
- Modify: ARB
- Test: `test/core/content/content_manifest_summary_test.dart`
- Test: `test/features/settings/presentation/pages/trust_center_page_test.dart`

**Interfaces:**

```dart
final class ContentManifestSummary extends Equatable {
  final String? datasetVersion; final int sourceCount; // items.length
  static ContentManifestSummary? parse(String json); // malformed → null
}
Future<ContentManifestSummary?> loadContentManifestSummary(AssetBundle bundle); // errors → null
```

**الصفحة:** ثلاث بطاقات.

| البطاقة | المحتوى |
|---|---|
| مصادر موثقة | `trustSourcesBody`، ثم سطر إصدار وعدد إذا كان الملخص غير `null`، ثم زر إلى `AppRoutes.sourcesLicenses` |
| صوتك | `trustVoiceBody` |
| بياناتك | `trustDataBody`، ثم زر إلى `AppRoutes.privacyPolicy` |

**ARB** (نصوص نهائية، تُراجَع بمهارة ux-copy عند المراجعة):

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `trustCenterTitle` | «كيف نحفظ المحتوى وخصوصيتك» | "How we protect content and your privacy" |
| `trustSourcesTitle` | «مصادر موثّقة» | "Verified sources" |
| `trustSourcesBody` | «لا يوجد في تالية أي نص ديني مولَّد. كل نص له مصدر ومرجع.» | "Talia contains no generated religious text. Every text has a source and a reference." |
| `trustSourcesMeta` | «إصدار البيانات {version} • {countText} مصادر» | "Data version {version} • {countText} sources" |
| `trustVoiceTitle` | «صوتك» | "Your voice" |
| `trustVoiceBody` | «تالية لا تسجّل صوتك ولا تحفظه ولا ترفعه. التعرّف على الكلام تقوم به خدمة النظام في جهازك.» | "Talia does not record, store or upload your voice. Speech recognition is done by your device's system service." |
| `trustDataTitle` | «بياناتك» | "Your data" |
| `trustDataBody` | «يمكنك استخدام تالية دون حساب. المزامنة اختيارية، وبيانات كل حساب معزولة عن غيره.» | "You can use Talia without an account. Sync is optional, and each account's data is kept separate." |
| `trustViewSources` | «عرض المصادر والتراخيص» | "View sources and licenses" |
| `trustViewPrivacy` | «سياسة الخصوصية» | "Privacy policy" |

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('parse real manifest shape → version + 4 sources', ...); // fixture copied from the real file's keys
test('malformed / missing items → null', ...);
testWidgets('page shows three cards; meta line hidden when summary null; buttons push routes', ...);
testWidgets('settings tile hidden when flag off', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ.**

- [ ] **Step 4: GREEN.** ثم `flutter analyze`، ثم `test/features/settings` و`test/core/l10n`.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(settings): trust center behind experience flag"
```

---

### Task 8: التحقق الكامل للدفعة

- [ ] تشغيل `flutter analyze` ثم `flutter test` كاملاً مرة واحدة. **المطلوب: 0 فشل.**
- [ ] تحديث `docs/release/flag-device-test-matrix.md` بإضافة صفوف `strengthOverlay` و`readerRepeat` و`trustCenter`.
- [ ] Commit.
