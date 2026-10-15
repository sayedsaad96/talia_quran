# رحلة القرآن للأطفال: خطة التنفيذ

> **للوكلاء المنفذين:** مهارة فرعية مطلوبة: استخدم superpowers:subagent-driven-development (موصى بها) أو superpowers:executing-plans لتنفيذ هذه الخطة مهمةً مهمة. الخطوات مكتوبة بصيغة مربعات الاختيار (`- [ ]`) للمتابعة.

**الهدف:** مسار أطفال بديل اسمه «رحلة القرآن». يغطي 114 سورة، كل بيت فيه سورة، والطفل يختار لكل سورة «كاملة» (حتى 20 آية) أو «على مراحل» من 1 إلى 10 آيات.

**البنية:**
- تعميم `KidsJourneyPath` الثابت إلى `KidsJourneyPathDefinition` قابل للاختيار، يُقرأ من `ParentSettings` ومن علم تفعيل.
- المواضع الستة التي تفترض جزء عمّ تأخذ المسار كمعامل.
- البيوت والمراجعة الإلزامية والمهام والميزانية تبقى كما هي.
- خريطة جديدة لـ114 بيتاً تُبنى من منشئ خالص في مرور واحد.

**التقنيات:** Flutter، `flutter_bloc`، `go_router`، `get_it`، SharedPreferences (تخزين `ParentSettings` الحالي)، و`mocktail`/`mockito` حسب الملف المجاور.

**المواصفة:** `docs/superpowers/specs/2026-10-16-kids-quran-journey-design.md` (تُقرأ مع هذه الخطة).

## Global Constraints

**المحتوى والبيانات:**
- لا يُعدَّل أي ملف في `assets/data/`، ولا يُعرض أي نص ديني جديد.
- نصوص ARB الجديدة نصوص واجهة عامة فقط.
- لا تغيير في Supabase، ولا في مخطط Isar، ولا في `V2SessionEngine`، ولا في `kids_review_outcome_committer.dart`، ولا في المزامنة.

**القيم المرجعية:**
- معرّف المغامرة يبقى حرفياً `fatiha_then_juz_amma`.
- المعرّفان الجديدان: `quran_from_nas` و`quran_from_fatiha`.
- أي قيمة مجهولة أو مفقودة، أو العلم مطفأ، تعني `juzAmmaAdventure`.
- حد «كاملة»: `ayahCount <= 20`. حجم المرحلة: `sanitizeKidsAyahsPerHouse` (من 1 إلى 10).
- مفتاح العلم: `kids_quran_journey_enabled`، وقيمته الافتراضية `false`.

**قواعد التنفيذ:**
- كل كتابة إعدادات تمر عبر `_ensureKidsOwner`.
- في `lib/` تُستخدم الاستيرادات النسبية.
- `dart format` على **الملفات الجديدة فقط**. الملفات الموجودة تُعدَّل يدوياً، ثم يُفحص `git diff --stat` للتأكد من عدم وجود تغييرات جانبية.
- قبل `flutter test`:

```powershell
$env:TEMP='D:\Flutter\talia_quran\.superpowers\tmp'; $env:TMP=$env:TEMP
```

- لا يعمل أمرا `flutter test` في الوقت نفسه.
- Commit لملفات المهمة فقط بأسمائها. **ممنوع `git add -A` أو `git add .`**، لأن شجرة العمل فيها عمل المالك غير المحفوظ.
- مفاتيح ARB تُضاف إلى `app_ar.arb` و`app_en.arb` معاً، ثم `flutter gen-l10n`.

**تعديلات على المواصفة تبنّتها الخطة بعد قراءة الكود** (المواصفة تُحدَّث في Task 9):
1. **الرئيسية لا ترسم مشهد خريطة.** بطاقة «الرحلة» في `KidsHomeNavigationCards` هي التي تفتح الخريطة. في رحلة القرآن تفتح خريطة القرآن الجديدة بدل صفحة رحلة السورة.
2. **اختيار «كاملة» يُطبَّق في أي مسار** متى كانت السورة في `kidsWholeSurahIds` و20 آية أو أقل، حتى لا تتغير قسمة سورة عند تبديل المسار (E4).
3. **`kidsJourneyPathId` و`kidsWholeSurahIds` يُكتبان فقط عبر دوال مخصصة** فوق `updateKidsHouseSettings`، و`saveParentSettings` يحافظ على قيمهما الحالية، على نفس نمط `kidsHouseSizesBySurah`.
4. **المسار يُقرأ من المستودع:** `getKidsJourneyPath()` بدل مزوّد DI منفصل. السبب أن `MemorizationNavigationResolver` لا يستطيع أخذ معامل مسمّى جديد، لأن له معاملاً موضعياً اختيارياً.

## Review Focus

1. **طفل بدأ سوراً في رحلة القرآن ثم عاد إلى المغامرة:** مراجعاته المستحقة لسور خارج جزء عمّ تظهر في مهمة الرئيسية، ولا تختفي. *(Task 4: اختبار `dueReview` لسورة 67 بمسار المغامرة)*
2. **تغيير قسمة سورة بدأها الطفل:** لا تُفقد أي آية مكتملة، ولا تتولد مكافأة مكررة، ومرحلة صارت مكتملة بعد إعادة القسمة لا تعلق الطفل في حلقة. *(Task 3: اختبار إعادة القسمة)*
3. **حفظ إعدادات عامة بعد اختيار المسار:** تغيير التذكير مثلاً عبر `saveParentSettings` لا يمسح `kidsJourneyPathId` ولا `kidsWholeSurahIds`. *(Task 2)*
4. **القفز إلى سورة بعيدة ثم الإكمال:** «السورة التالية» تتبع الاتجاه من السورة التي أُكملت، وتتخطى المحفوظ. *(Task 4)*
5. **فتح الخريطة على سورة طويلة كالبقرة:** لا تجمّد الواجهة، والمنشئ لا يستدعي `getSurahDetail` لكل سورة. *(Task 6: المنشئ يأخذ `List<Surah>` فقط، وTask 7: `ListView.builder`)*

---

### Task 0: خط الأساس

**Files:** لا تعديل.

- [ ] **Step 1: تشغيل اختبارات مسار الأطفال الحالية وتسجيل النتيجة**

Run:

```powershell
flutter test test/features/memorization_plus/domain test/features/memorization_plus/presentation/navigation test/features/memorization_plus/memorization_plus_repository_impl_test.dart test/features/memorization_plus/presentation/cubits/kids_mode_cubit_test.dart test/integration/kids_house_review_gate_test.dart
```

Expected: تُسجَّل الحصيلة (عدد الناجح والفاشل) في `docs/superpowers/plans/2026-10-16-kids-quran-journey.baseline.txt`.

- إذا وُجد فشل قائم، يُسجَّل كما هو **ولا يُصلح** هنا.
- كل مهمة لاحقة يجب ألا تضيف فشلاً جديداً على هذه الحصيلة.

---

### Task 1: تعريف المسار وعلم التفعيل

**Files:**
- Create: `lib/features/memorization_plus/domain/entities/kids_journey_path_definition.dart`
- Modify: `lib/core/memorization/kids_hifz_feature_flags.dart`
- Test: `test/features/memorization_plus/domain/kids_journey_path_definition_test.dart`

**Interfaces:**
- Consumes: `KidsJourneyPath` من `kids_session_policy.dart` دون تغيير.
- Produces:

```dart
enum KidsJourneyPathId {
  juzAmmaAdventure('fatiha_then_juz_amma'),
  quranFromNas('quran_from_nas'),
  quranFromFatiha('quran_from_fatiha');
  const KidsJourneyPathId(this.storageValue);
  final String storageValue;
  static KidsJourneyPathId parse(String? raw); // unknown/null → juzAmmaAdventure
}

final class KidsJourneyPathDefinition {
  const KidsJourneyPathDefinition._(this.id);
  static const adventure = KidsJourneyPathDefinition._(KidsJourneyPathId.juzAmmaAdventure);
  static KidsJourneyPathDefinition of(KidsJourneyPathId id);
  final KidsJourneyPathId id;
  List<int> get surahIds;
  bool contains(int surahId);
  int? nextAfter(int surahId);
  bool get locksAhead;      // id == juzAmmaAdventure
  bool get isQuranJourney;  // !locksAhead
}

/// Flag off → adventure, whatever is stored.
KidsJourneyPathDefinition resolveKidsJourneyPath({
  required String? storedPathId,
  required bool quranJourneyEnabled,
});

// kids_hifz_feature_flags.dart
static const quranJourneyKey = 'kids_quran_journey_enabled';
static bool isQuranJourneyEnabled(SharedPreferences prefs); // ?? false
```

- [ ] **Step 1: كتابة الاختبارات الفاشلة**

```dart
test('adventure keeps the existing path verbatim', () {
  expect(KidsJourneyPathDefinition.adventure.surahIds, KidsJourneyPath.surahIds);
  expect(KidsJourneyPathId.juzAmmaAdventure.storageValue, 'fatiha_then_juz_amma');
  expect(KidsJourneyPathDefinition.adventure.nextAfter(78), isNull);
  expect(KidsJourneyPathDefinition.adventure.locksAhead, isTrue);
});
test('quranFromNas: Fatiha, then 114 down to 2', () {
  final p = KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas);
  expect(p.surahIds.length, 114);
  expect(p.surahIds.take(3), [1, 114, 113]);
  expect(p.surahIds.last, 2);
  expect(p.nextAfter(1), 114);
  expect(p.nextAfter(3), 2);
  expect(p.nextAfter(2), isNull);
  expect(p.locksAhead, isFalse);
});
test('quranFromFatiha: 1..114', () {
  final p = KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromFatiha);
  expect(p.surahIds, List.generate(114, (i) => i + 1));
  expect(p.nextAfter(113), 114);
  expect(p.nextAfter(114), isNull);
  expect(p.contains(2), isTrue);
});
test('parse falls back to the adventure', () {
  for (final raw in [null, '', 'x', 'QURAN_FROM_NAS']) {
    expect(KidsJourneyPathId.parse(raw), KidsJourneyPathId.juzAmmaAdventure);
  }
  expect(KidsJourneyPathId.parse('quran_from_nas'), KidsJourneyPathId.quranFromNas);
});
test('flag off forces the adventure', () {
  expect(resolveKidsJourneyPath(storedPathId: 'quran_from_nas', quranJourneyEnabled: false).id,
      KidsJourneyPathId.juzAmmaAdventure);
  expect(resolveKidsJourneyPath(storedPathId: 'quran_from_nas', quranJourneyEnabled: true).id,
      KidsJourneyPathId.quranFromNas);
});
test('nextAfter for a surah outside the path is null', () {
  expect(KidsJourneyPathDefinition.adventure.nextAfter(50), isNull);
});
```

إضافة اختبار للعلم في ملف الاختبار نفسه: `SharedPreferences.setMockInitialValues({})` تعني `false`، و`{'kids_quran_journey_enabled': true}` تعني `true`.

- [ ] **Step 2: التشغيل والتأكد من الفشل**

Run: `flutter test test/features/memorization_plus/domain/kids_journey_path_definition_test.dart`
Expected: FAIL (الملف غير موجود).

- [ ] **Step 3: التنفيذ**

- المغامرة تفوّض إلى `KidsJourneyPath.surahIds` و`KidsJourneyPath.contains` و`KidsJourneyPath.nextAfter`.
- قوائم القرآن `static final` محسوبة مرة واحدة.
- `nextAfter` العام يعتمد على `indexOf`.

- [ ] **Step 4: التشغيل والتأكد من النجاح**

Run: نفس الأمر. Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/memorization_plus/domain/entities/kids_journey_path_definition.dart lib/core/memorization/kids_hifz_feature_flags.dart test/features/memorization_plus/domain/kids_journey_path_definition_test.dart
git commit -m "feat(kids-quran-journey): selectable journey path definition and flag"
```

---

### Task 2: تخزين المسار واختيار القسمة

**Files:**
- Modify: `lib/features/memorization_plus/domain/entities/parent_dashboard.dart` (`ParentSettings`: حقلان، و`copyWith`، و`props`)
- Modify: `lib/features/memorization_plus/data/models/memorization_models.dart` (`ParentSettingsModel`: `fromJson`/`toJson`/`fromEntity`)
- Modify: `lib/features/memorization_plus/data/datasources/memorization_kids_storage.dart` (دمج `saveParentSettings`)
- Modify: `lib/features/memorization_plus/data/repositories/collaborators/memorization_kids_local_service.dart`
- Modify: `lib/features/memorization_plus/domain/repositories/memorization_plus_repository.dart`
- Modify: `lib/features/memorization_plus/data/repositories/memorization_plus_repository_family.dart`
- Modify: `lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart`
- Modify: `lib/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart`
- Modify: `lib/core/di/injection.dart` (تمرير قارئ العلم)
- Test: `test/features/memorization_plus/data/kids_journey_path_settings_test.dart`

**Interfaces:**
- Consumes: Task 1.
- Produces:

```dart
// ParentSettings
final String? kidsJourneyPathId;      // copyWith(kidsJourneyPathId:, clearKidsJourneyPathId:)
final Set<int> kidsWholeSurahIds;     // default const {}

// JSON keys: 'kidsJourneyPathId' (String?), 'kidsWholeSurahIds' (List<int>, 1..114 only, dupes dropped)

// MemorizationPlusRepository (+ family + impl + usecase wrappers of the same names)
Future<Either<Failure, KidsJourneyPathDefinition>> getKidsJourneyPath();
Future<Either<Failure, ParentSettings>> setKidsJourneyPath(KidsJourneyPathId id);
Future<Either<Failure, ParentSettings>> setKidsSurahSplit(
  int surahId, {required bool whole, int? stageSize});

// MemorizationKidsLocalService + MemorizationPlusRepositoryImpl constructors
bool Function() quranJourneyEnabled = _quranJourneyOff, // optional named; top-level `bool _quranJourneyOff() => false;`
```

**قواعد `setKidsSurahSplit`:**
- تعيد `Left(ValidationFailure())` في ثلاث حالات:
  1. `surahId` خارج المدى من 1 إلى 114.
  2. `whole` مع سورة أكثر من 20 آية (عدد الآيات من `_quranRepository.getSurahDetail`).
  3. `!whole` و`sanitizeKidsAyahsPerHouse(stageSize) == null`.
- **إذا كان `whole`:** يضيف السورة إلى المجموعة، ويزيل مفتاحها من `kidsHouseSizesBySurah`.
- **إذا لم يكن `whole`:** يزيلها من المجموعة، ويكتب الحجم في `kidsHouseSizesBySurah`.
- تُكتب عبر `updateKidsHouseSettings` مع `_ensureKidsOwner` قبل الكتابة وبعدها، على نمط `setKidsAyahsPerHouse`.

**`getKidsJourneyPath`:**
- تقرأ الإعدادات وتعيد `resolveKidsJourneyPath(storedPathId: settings.kidsJourneyPathId, quranJourneyEnabled: quranJourneyEnabled())`.

**التعديل في `saveParentSettings`:**
- يضيف إلى `merged` القيمتين الحاليتين: `kidsJourneyPathId: current.kidsJourneyPathId`، و`clearKidsJourneyPathId: current.kidsJourneyPathId == null`، و`kidsWholeSurahIds: current.kidsWholeSurahIds`.

**DI:**
- `MemorizationPlusRepositoryImpl(..., quranJourneyEnabled: () => KidsHifzFeatureFlags.isQuranJourneyEnabled(getIt<SharedPreferences>()))`.
- إن كان المنشئ لا يقبل معاملات مسمّاة إضافية، يُضاف كأول معامل مسمّى بعد الموجودة.

- [ ] **Step 1: كتابة الاختبارات الفاشلة**

```dart
test('model round-trips path id and whole surahs', ...);  // toJson→fromJson يحفظ 'quran_from_nas' و{103, 1}
test('model drops invalid whole surah ids', ...);          // [0, 115, 'x', 103, 103] → {103}
test('saveParentSettings keeps path id and whole surahs', ...);
  // setKidsJourneyPath(quranFromNas) و setKidsSurahSplit(103, whole: true)
  // ثم saveParentSettings(settings.copyWith(reminderHour: 7)) يُبقي الاثنين
test('setKidsSurahSplit whole rejects a surah over 20 ayahs', ...); // 67 (30 آية) → Left(ValidationFailure)
test('setKidsSurahSplit whole on 103 then staged 3 swaps storage', ...);
  // whole: kidsWholeSurahIds={103}, لا مفتاح 103 في الأحجام
  // staged 3: المجموعة فارغة، والأحجام[103]=3
test('setKidsSurahSplit rejects stageSize 0 and 11', ...);
test('getKidsJourneyPath is the adventure while the flag is off', ...);
test('getKidsJourneyPath returns the stored path when the flag is on', ...);
test('settings written for owner A are not visible to owner B', ...); // على نمط اختبارات العزل الموجودة في data/
```

يُتبع نمط إعداد الاختبار في `test/features/memorization_plus/data/kids_home_missions_local_test.dart`: SharedPreferences وهمية، ومالك وهمي، و`QuranRepository` وهمي يعيد `SurahDetail` لـ103 (3 آيات) و67 (30 آية).

- [ ] **Step 2: التشغيل والتأكد من الفشل**

Run: `flutter test test/features/memorization_plus/data/kids_journey_path_settings_test.dart`
Expected: FAIL.

- [ ] **Step 3: التنفيذ** حسب الواجهات والقواعد أعلاه.

- [ ] **Step 4: التشغيل**

Run: الاختبار الجديد، ثم `flutter analyze`.
Expected: PASS، و0 أخطاء.

- [ ] **Step 5: Commit**

يشمل ملفات المهمة فقط:

```bash
git commit -m "feat(kids-quran-journey): store journey path and per-surah split"
```

---

### Task 3: حجم البيت مع «كاملة» وإلغاء القفل في رحلة القرآن

**Files:**
- Modify: `lib/features/memorization_plus/data/repositories/collaborators/memorization_kids_local_service.dart` (`_houseSize`، و`getKidsJourney`، و`_earlierHouseUnfinished`)
- Test: `test/features/memorization_plus/data/kids_quran_journey_houses_test.dart`

**Interfaces:**
- Consumes: Task 2 (`kidsWholeSurahIds`، و`quranJourneyEnabled`).
- Produces: سلوك `getKidsJourney(surahId:)` الجديد. **التوقيع لا يتغير.**

**التغييرات:**

1. **`_houseSize`** يأخذ معاملاً جديداً `required int ayahCount`. السطر الأول فيه:
   - إذا كانت `settings.kidsWholeSurahIds.contains(surahId) && ayahCount <= 20` يعيد `ayahCount` **دون تثبيت أي حجم**.
   - غير ذلك السلوك الحالي كما هو.
   - المستدعيان (`getKidsJourney` و`_earlierHouseUnfinished`) يمرران `detail.surah.ayahCount`.
2. **`_earlierHouseUnfinished`:**
   - في بدايتها: `final path = resolveKidsJourneyPath(storedPathId: settings.kidsJourneyPathId, quranJourneyEnabled: _quranJourneyEnabled());` ثم `if (!path.locksAhead) return false;`.
   - بقية الدالة لا تتغير، وتبقى تستخدم `KidsJourneyPath.surahIds`.

- [ ] **Step 1: كتابة الاختبارات الفاشلة**

```dart
test('whole surah 103 is one stage of 3 ayahs', ...);
  // stages.length == 1، و startAyah 1، و endAyah 3
test('whole is ignored for a 30-ayah surah stored as whole', ...);
  // JSON مخزّن يدوياً بـ kidsWholeSurahIds:[67] → مراحل بالحجم الافتراضي (5 لعمر 9)
test('re-splitting a started surah keeps completed ayahs', ...);
  // سجلات مكافأة للآيات 1..5 من 67 بحجم 5 → setKidsSurahSplit(67, whole:false, stageSize:3)
  // → المراحل [1-3] و[4-6]، والآيات المكتملة {1,2,3,4,5}، ولا آية ضاعت
  // المرحلة الأولى needsReview (مراجعة البيت معلّقة) والثانية current
test('quran journey never locks a later surah', ...);
  // flag on، والمسار quranFromNas، والبداية 1، ولا سجلات للفاتحة → getKidsJourney(67) أول مرحلة current
test('adventure still locks a later surah (unchanged)', ...);
  // نفس الإعداد بمسار المغامرة → getKidsJourney(113) أول مرحلة locked
```

- [ ] **Step 2: التشغيل والتأكد من الفشل**

Run: `flutter test test/features/memorization_plus/data/kids_quran_journey_houses_test.dart`
Expected: FAIL.

- [ ] **Step 3: التنفيذ** كما في «التغييرات» أعلاه.

- [ ] **Step 4: التشغيل**

Run: الاختبار الجديد، ثم أوامر Task 0.
Expected: PASS، وحصيلة خط الأساس دون فشل جديد.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(kids-quran-journey): whole-surah houses and no lock on the Quran journey"
```

---

### Task 4: المحللات تأخذ المسار

**Files:**
- Modify: `lib/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart`
- Modify: `lib/features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart` (`_mandatoryKidsHouseSurah`، و`kidsMissionAfterCompletion`، وأي استدعاء لـ`KidsNextMissionResolver`)
- Modify: `lib/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart`
- Modify: `lib/core/di/injection.dart` (موضع `KidsJourneyCubit(` قرب السطر 1319)
- Test: `test/features/memorization_plus/domain/kids_next_mission_resolver_test.dart` (إضافة)
- Test: `test/features/memorization_plus/presentation/navigation/memorization_navigation_resolver_test.dart` (إضافة)

**Interfaces:**
- Consumes: Task 1 و`getKidsJourneyPath()` من Task 2.
- Produces:

```dart
// KidsNextMissionResolver — new optional named param on both methods
KidsNextMission? resolve({..., KidsJourneyPathDefinition path = KidsJourneyPathDefinition.adventure});
Future<KidsJourneyContinuation?> findContinuation({..., KidsJourneyPathDefinition path = KidsJourneyPathDefinition.adventure});
// _nextSurah(int surahId, KidsJourneyPathDefinition path):
//   path.locksAhead → KidsJourneyPath.nextAfter(surahId, lastSurahId: lastJuzAmmaSurahId)  (unchanged)
//   otherwise       → path.nextAfter(surahId)

// KidsJourneyCubit — new optional named constructor param
typedef KidsJourneyPathLoader = Future<KidsJourneyPathDefinition> Function();
KidsJourneyPathLoader? pathLoader; // null or throwing → adventure
```

**الاستدعاءات:**
- `MemorizationNavigationResolver` يقرأ `(await _repository.getKidsJourneyPath()).getOrElse(() => KidsJourneyPathDefinition.adventure)`، ويمرره إلى `resolve` و`findContinuation`.
- **`_mandatoryKidsHouseSurah`:**
  - إذا كان `path.locksAhead`: السلوك الحالي كما هو.
  - وإلا: يمر على كل `path.surahIds` المبدوءة، دون `skip`.
- **`KidsJourneyCubit`:** يحمّل المسار مرة واحدة في كل `load`، ويمرره إلى المحلل.
- **DI:** `pathLoader: () async => (await getIt<MemorizationPlusRepository>().getKidsJourneyPath()).getOrElse(() => KidsJourneyPathDefinition.adventure)`.

- [ ] **Step 1: كتابة الاختبارات الفاشلة**

```dart
// kids_next_mission_resolver_test.dart
test('quran journey continues from 67 to 66 skipping a memorized 66', ...);
  // path quranFromNas، و66 كل مراحلها completed، و65 فيها مرحلة مفتوحة
  // → findContinuation(activeSurahId: 67) يعطي 65 newMemorization
test('quran journey from Fatiha: 1 → 2', ...);
test('adventure default is unchanged: 79 → 78 then null', ...);
test('due review of surah 67 still leads on the adventure path', ...); // Review Focus 1
  // سجل kidsMode مستحق للآية 67:1، والمسار adventure → resolve يعطي dueReview لـ 67

// memorization_navigation_resolver_test.dart
test('mandatory house review is found in a surah outside Juz Amma on the Quran journey', ...);
  // مستودع وهمي: getKidsJourneyPath → quranFromNas، وسجلات مكافأة لـ 67، ومراحل 67 فيها requiresHouseReview
  // → كلٌّ من kidsHomeLocation و kidsJourneyLocation يشير إلى 67
```

- [ ] **Step 2: التشغيل والتأكد من الفشل**

Run: الملفان.
Expected: FAIL في الاختبارات الجديدة فقط.

- [ ] **Step 3: التنفيذ** حسب الواجهات أعلاه.

- [ ] **Step 4: التشغيل**

Run: الملفان، ثم أوامر Task 0.
Expected: PASS، ودون فشل جديد.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(kids-quran-journey): mission resolvers follow the selected path"
```

---

### Task 5: الألعاب، والإعداد، واختيار المسار لولي الأمر

**Files:**
- Modify: `lib/features/memorization_plus/domain/services/kids_learning_game_builder.dart`
- Modify: الكيوبت أو الصفحة التي تستدعي `buildListenAndChooseSurahGame` (يُحدَّد بـ`grep`)
- Modify: `lib/features/memorization_plus/presentation/cubits/memorization_identity_cubit.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/path_selection_page.dart` (قسم الطفل حول الأسطر 440–470)
- Modify: `lib/features/memorization_plus/presentation/pages/family_dashboard_page.dart` (بجوار `KidsHouseSizeSelector` قرب السطر 323)
- Modify: `lib/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart`
- Create: `lib/features/memorization_plus/presentation/widgets/kids_journey_path_selector.dart`
- Modify: `lib/core/l10n/app_ar.arb` و`lib/core/l10n/app_en.arb`
- Test: `test/features/memorization_plus/domain/kids_learning_game_builder_test.dart` (إضافة)
- Test: `test/features/memorization_plus/presentation/widgets/kids_journey_path_selector_test.dart`
- Test: اختبار الكيوبت المجاور لـ`memorization_identity_cubit` إن وُجد، وإلا يُنشأ `test/features/memorization_plus/presentation/cubits/memorization_identity_cubit_path_test.dart`

**Interfaces:**
- Consumes: Tasks 1 و2.
- Produces:

```dart
KidsLearningGame? buildListenAndChooseSurahGame(Iterable<KidsSessionLog> logs,
  {required Random random, KidsJourneyPathDefinition path = KidsJourneyPathDefinition.adventure});
// filter uses path.contains; _options neighbours come from path.surahIds

// MemorizationIdentityCubit.setupChild gains:
KidsJourneyPathId journeyPathId = KidsJourneyPathId.juzAmmaAdventure,
// validation: KidsJourneyPathDefinition.of(journeyPathId).contains(startingSurahId)
// after a successful setup: _repository.setKidsJourneyPath(journeyPathId)

class KidsJourneyPathSelector extends StatelessWidget {
  const KidsJourneyPathSelector({super.key, required this.value, required this.onChanged});
  final KidsJourneyPathId value;
  final ValueChanged<KidsJourneyPathId> onChanged;
} // three RadioListTile options, labels from ARB

// FamilyDashboardCubit
Future<bool> setKidsJourneyPath(KidsJourneyPathId id);
```

**ARB** (عربي ثم إنجليزي):

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `kidsJourneyPathTitle` | «مسار الحفظ» | "Memorization path" |
| `kidsJourneyPathAdventure` | «مغامرة جزء عمّ» | "Juz Amma adventure" |
| `kidsJourneyPathFromNas` | «رحلة القرآن: من الناس إلى البقرة» | "Quran journey: An-Nas to Al-Baqarah" |
| `kidsJourneyPathFromFatiha` | «رحلة القرآن: من الفاتحة إلى الناس» | "Quran journey: Al-Fatihah to An-Nas" |

**الإظهار:**
- `KidsJourneyPathSelector` يظهر في صفحة الإعداد ولوحة الأسرة **فقط** إذا كان `KidsHifzFeatureFlags.isQuranJourneyEnabled(prefs)`.
- قائمة سورة البداية في الإعداد تُبنى من `KidsJourneyPathDefinition.of(selected).surahIds`.
- عند تغيير المسار تُعاد سورة البداية إلى `surahIds.first`.

- [ ] **Step 1: كتابة الاختبارات الفاشلة**

```dart
test('game includes surah 67 on the Quran journey and excludes it on the adventure', ...);
testWidgets('path selector shows three options and reports the tapped one', ...);
test('setupChild rejects starting surah 2 on the adventure and accepts it on quranFromFatiha', ...);
test('setupChild stores the chosen path', ...); // verify setKidsJourneyPath(quranFromNas) called once
```

- [ ] **Step 2: التشغيل والتأكد من الفشل.**

- [ ] **Step 3: التنفيذ**

1. التعديلات في الكود.
2. ARB.
3. `flutter gen-l10n`.
4. `dart format` على الملفين الجديدين فقط.

- [ ] **Step 4: التشغيل**

Run: الاختبارات الجديدة، ثم `flutter analyze`.
Expected: PASS، و0 أخطاء.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(kids-quran-journey): path choice in setup and family dashboard; games follow path"
```

---

### Task 6: منشئ ملخص البيوت (خالص)

**Files:**
- Create: `lib/features/memorization_plus/domain/services/kids_surah_house_summary_builder.dart`
- Test: `test/features/memorization_plus/domain/kids_surah_house_summary_builder_test.dart`

**Interfaces:**
- Consumes:
  - Task 1.
  - `KidsHouseReviewPolicy.pendingAyahs`.
  - `KidsSessionLogsCloudMerge.isCanonicalRewardLog`.
  - `KidsDueReviewPolicy.isDue` (نفس قاعدة الاستحقاق في `getKidsJourney` و`_mostOverdueKidsAyah`).
- Produces:

```dart
enum KidsSurahHouseStatus { notStarted, inProgress, needsReview, completed }

final class KidsSurahHouse extends Equatable {
  final int surahId; final int ayahCount; final int juz;
  final KidsSurahHouseStatus status;
  final int completedCount;
  double get progress; // completedCount / ayahCount
}

List<KidsSurahHouse> buildKidsSurahHouses({
  required KidsJourneyPathDefinition path,
  required List<Surah> surahs,                 // from QuranRepository.getSurahs()
  required List<KidsSessionLog> logs,
  required List<AyahReviewRecord> kidsRecords,
  required Map<int, int> frozenSizes,          // ParentSettings.kidsHouseSizesBySurah
  required Set<int> wholeSurahIds,
  required int defaultStageSize,               // guardian kidsAyahsPerHouse ?? age default
  required DateTime now,
}); // ordered by path.surahIds

/// The house the map opens on: last surah with a canonical reward log if
/// not completed; otherwise the next non-completed house after it in path
/// order; with no logs, path.surahIds.first.
int currentKidsSurahHouse(List<KidsSurahHouse> houses, List<KidsSessionLog> logs);
```

**قاعدة الحالة لكل سورة:**
1. **حجم المرحلة:** إن كانت كاملة و20 آية أو أقل فالحجم `ayahCount`، وإلا `frozenSizes[id] ?? defaultStageSize`.
2. **`needsReview`:** إذا كانت أي مرحلة مكتملة فيها `pendingAyahs` غير فارغة، أو أي سجل مراجعة طفل مستحق في السورة.
3. **`completed`:** إذا اكتملت كل الآيات ولم تتحقق حالة المراجعة.
4. **`inProgress`:** إذا وُجدت آية مكتملة واحدة على الأقل.
5. **`notStarted`:** غير ذلك.

يُجمَّع كل شيء في مرور واحد: `Map<int surahId, Set<int>>` للآيات المكتملة، و`Map<int, List<KidsSessionLog>>` للسجلات.

- [ ] **Step 1: كتابة الاختبارات الفاشلة**

```dart
test('returns 114 houses in quranFromNas order with juz from surahs', ...);
test('notStarted / inProgress / completed from canonical reward logs', ...);
test('needsReview when a finished stage has a pending house review', ...);
test('needsReview when a kids record of the surah is due', ...);
test('whole 103 is completed after its 3 ayahs plus their house review', ...);
test('review-only logs do not count as completion', ...);
test('current house: last started; next non-completed after a completed one; first with no logs', ...);
test('adventure path returns its 38 houses only', ...);
```

- [ ] **Step 2: الفشل.** **Step 3: التنفيذ.** **Step 4: النجاح**، ثم `dart format` على الملفين الجديدين.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(kids-quran-journey): pure surah-house summary builder"
```

---

### Task 7: خريطة رحلة القرآن

**Files:**
- Create: `lib/features/memorization_plus/presentation/cubits/kids_quran_journey_cubit.dart`
- Create: `lib/features/memorization_plus/presentation/pages/kids_quran_journey_page.dart`
- Create: `lib/features/memorization_plus/presentation/widgets/kids_quran_journey_map.dart`
- Modify: `lib/core/router/app_router.dart`
  - الثابت: `memorizationPlusKidsQuranJourney = '/memorization-plus/kids-quran-journey'`
  - الحماية: `MemorizationRouteGuard.kidsOnlyRedirect()`
- Modify: `lib/core/di/injection.dart` (تسجيل الكيوبت كـfactory)
- Modify: `lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart` (`onJourneyTap` قرب السطر 267)
- Modify: ARB
- Test: `test/features/memorization_plus/presentation/cubits/kids_quran_journey_cubit_test.dart`
- Test: `test/features/memorization_plus/presentation/pages/kids_quran_journey_page_test.dart`

**Interfaces:**
- Consumes: Tasks 2 و6.
- Produces:

```dart
sealed class KidsQuranJourneyState extends Equatable {}
final class KidsQuranJourneyLoading extends KidsQuranJourneyState {}
final class KidsQuranJourneyError extends KidsQuranJourneyState {}
final class KidsQuranJourneyLoaded extends KidsQuranJourneyState {
  final List<KidsSurahHouse> houses;
  final int currentSurahId;
  final Map<int, String> surahNames; // nameAr/nameEn by locale, from Surah
}
class KidsQuranJourneyCubit extends Cubit<KidsQuranJourneyState> {
  KidsQuranJourneyCubit(MemorizationPlusRepository repository, QuranRepository quranRepository,
      {DateTime Function()? clock});
  Future<void> load();
}
// Home: onJourneyTap pushes memorizationPlusKidsQuranJourney when
// (await repo.getKidsJourneyPath()).isQuranJourney, else the existing route.
```

**الصفحة:**
- `ListView.builder` مع `itemExtent: 132` وتمرير أولي إلى فهرس البيت الحالي (`initialScrollOffset = index * 132`).
- **كل عنصر:** مقطع طريق مرسوم بـ`CustomPainter` بسيط (يمين ويسار متناوب)، وبطاقة بيت تعرض اسم السورة، و«N آية»، وأيقونة الحالة، وشريط التقدّم.
- **لافتة الجزء:** فوق البيت إذا كان أول بيت في الترتيب يحمل هذا `juz`.
- **Talia عند البيت الحالي:** أصل `assets/images/talia/` المستخدم في `KidsTaliaCompanion`.
- **الضغط على بيت:**
  - إذا كان `surahId != currentSurahId` وحالته `notStarted`: حوار تأكيد `kidsQuranJourneyJumpConfirm(surahName, currentName)`، ثم `context.push('${AppRoutes.memorizationPlusKidsJourney}?surahId=$id')`.
  - غير ذلك: يفتح الصفحة مباشرة دون حوار.

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `kidsQuranJourneyTitle` | «رحلة القرآن» | "Quran journey" |
| `kidsQuranJourneyJuz` | «الجزء {number}» | "Juz {number}" |
| `kidsQuranJourneyAyahCount` | «{count} آية» | "{count} ayahs" |
| `kidsQuranJourneyJumpConfirm` | «تريد أن تبدأ سورة {surah}؟ سورة {current} ستنتظرك» | "Start Surah {surah}? Surah {current} will wait for you." |
| `kidsQuranJourneyJumpYes` | «نبدأ» | "Let's start" |
| `kidsQuranJourneyJumpNo` | «ليس الآن» | "Not now" |
| `kidsQuranJourneyComplete` | «أتممت رحلة القرآن كلها! أخبر وليّ أمرك بهذا الإنجاز العظيم.» | "You finished the whole Quran journey! Tell your guardian about this great achievement." |

- [ ] **Step 1: كتابة الاختبارات الفاشلة**

```dart
// cubit
test('load emits Loaded with 114 houses and the current house', ...);
test('load emits Error when surahs cannot be read', ...);
// page (KidsQuranJourneyLoaded مُمرَّر مباشرة إلى widget محتوى @visibleForTesting)
testWidgets('builds lazily: fewer than 20 house cards in the tree for 114 houses', ...);
testWidgets('juz signpost appears before the first house of each juz', ...);
testWidgets('tapping a notStarted house that is not current asks for confirmation', ...);
testWidgets('tapping the current house opens it without a dialog', ...);
testWidgets('all houses completed shows the journey-complete message', ...);
```

- [ ] **Step 2: الفشل.**

- [ ] **Step 3: التنفيذ**، ثم ARB و`flutter gen-l10n`، ثم `dart format` على الملفات الجديدة فقط.

- [ ] **Step 4: النجاح**، ثم `flutter analyze`.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(kids-quran-journey): Quran journey map page"
```

---

### Task 8: ورقة «كيف تحب أن تحفظها؟» وكلمة «المرحلة»

**Files:**
- Create: `lib/features/memorization_plus/presentation/widgets/kids_surah_split_sheet.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart` (عرض الورقة، وقائمة «غيّر طريقة الحفظ»، وتمرير المسار إلى بطاقات البيوت)
- Modify: `lib/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart` و`kids_journey_state.dart`
- Modify: `lib/features/memorization_plus/presentation/widgets/kids_house_card.dart` (اختيار عنوان «المرحلة»)
- Modify: ARB
- Test: `test/features/memorization_plus/presentation/widgets/kids_surah_split_sheet_test.dart`
- Test: إضافة إلى اختبار صفحة الرحلة المجاور (يُحدَّد بـ`grep KidsGamifiedJourneyContent test/`)

**Interfaces:**
- Consumes: Tasks 2 و4.
- Produces:

```dart
// KidsJourneyLoaded gains:
final bool isQuranJourney;
final bool needsSplitChoice; // isQuranJourney && no reward log in surah && not whole && no frozen size
final int surahAyahCount;
final int defaultStageSize;

// computed in KidsJourneyCubit.load from the path loader (Task 4), the
// kids session logs it already reads, and ParentSettings via a new optional
// named loader `Future<ParentSettings?> Function()? settingsLoader` (null → needsSplitChoice false)

// KidsJourneyCubit
Future<bool> chooseSplit({required int surahId, required bool whole, int? stageSize});
// calls repository.setKidsSurahSplit then load(surahId: surahId, showLoading: false)

Future<KidsSurahSplitChoice?> showKidsSurahSplitSheet(BuildContext context,
  {required int ayahCount, required int defaultStageSize});
final class KidsSurahSplitChoice { final bool whole; final int? stageSize; }
// whole option rendered only when ayahCount <= 20;
// stage selector 1..10; live text kidsSplitStageCount(count: (ayahCount / size).ceil())

// KidsHouseCard gains: final bool useStageWording; // false keeps current text
```

**الصفحة:**
- عند `needsSplitChoice` تُعرض الورقة تلقائياً مرة واحدة بعد البناء.
- إغلاق الورقة دون اختيار يبقي الحالة كما هي، فتظهر مرة أخرى عند الفتح التالي.
- قائمة صفحة الرحلة في رحلة القرآن فيها عنصر «غيّر طريقة الحفظ» يفتح الورقة نفسها.

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `kidsSplitTitle` | «كيف تحب أن تحفظها؟» | "How would you like to memorize it?" |
| `kidsSplitWhole` | «كاملة مرة واحدة» | "All at once" |
| `kidsSplitStaged` | «على مراحل» | "In stages" |
| `kidsSplitAyahsPerStage` | «آيات كل مرحلة» | "Ayahs per stage" |
| `kidsSplitStageCount` | «ستكون {count} مراحل» | "{count} stages" |
| `kidsSplitConfirm` | «ابدأ» | "Start" |
| `kidsSplitChange` | «غيّر طريقة الحفظ» | "Change how to memorize" |
| `kidsStageTitle` | «المرحلة {number}» | "Stage {number}" |
| `kidsReviewStageTitle` | «مراجعة المرحلة {number}» | "Stage {number} review" |

- [ ] **Step 1: كتابة الاختبارات الفاشلة**

```dart
testWidgets('whole option hidden for 30 ayahs, shown for 3', ...);
testWidgets('stage count text updates: 30 ayahs, size 4 → 8 stages', ...);
testWidgets('confirm returns KidsSurahSplitChoice(whole: false, stageSize: 4)', ...);
testWidgets('journey page shows the sheet once when needsSplitChoice', ...);
testWidgets('Quran journey cards say المرحلة; adventure cards keep بيت الحفظ', ...);
test('chooseSplit reloads with one stage for whole 103', ...);
```

- [ ] **Step 2: الفشل.**

- [ ] **Step 3: التنفيذ**، ثم ARB و`flutter gen-l10n`، ثم `dart format` على الملف الجديد فقط.

- [ ] **Step 4: النجاح**، ثم `flutter analyze`.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(kids-quran-journey): whole-or-stages choice and stage wording"
```

---

### Task 9: التكامل والمراجعة وتحديث المواصفة

**Files:**
- Create: `test/integration/kids_quran_journey_flow_test.dart`
- Modify: `docs/superpowers/specs/2026-10-16-kids-quran-journey-design.md` (إضافة «تعديلات الخطة» الثلاثة من Global Constraints تحت القسم 5)

**الاختبار:** على نمط `test/integration/kids_house_review_gate_test.dart` (مستودع حقيقي فوق SharedPreferences وهمية).

- [ ] **Step 1: كتابة اختبار التكامل**

```dart
testWidgets / test('kids Quran journey end to end', () async {
  // 1. flag on; child age 9; adventure; one reward log on 114:1
  // 2. setKidsJourneyPath(quranFromNas) → getKidsJourneyPath().isQuranJourney
  // 3. getKidsJourney(67): no lock; setKidsSurahSplit(67, whole: true) → Left(ValidationFailure)
  // 4. setKidsSurahSplit(67, whole: false, stageSize: 5) → 6 stages
  // 5. record reward logs 67:1..5 + their house-review proofs → stage 1 completed
  // 6. setKidsSurahSplit(67, whole: false, stageSize: 3) → completed ayahs still {1..5}
  // 7. setKidsSurahSplit(103, whole: true) → one stage of 3
  // 8. setKidsJourneyPath(juzAmmaAdventure) → 114:1 still completed, 67 logs still present,
  //    a due kids record on 67:1 still yields a dueReview mission
  // 9. switch owner → getParentSettings has no path id and no whole surahs
});
```

- [ ] **Step 2: التشغيل**

Run: `flutter test test/integration/kids_quran_journey_flow_test.dart`
Expected: PASS.

- [ ] **Step 3: الحزمة الكاملة**

Run: `flutter analyze`، ثم `flutter test`.
Expected:
- 0 أخطاء تحليل.
- لا فشل جديد مقارنة بـ`2026-10-16-kids-quran-journey.baseline.txt`.
- **تُذكر الأرقام الفعلية في التقرير.**

- [ ] **Step 4: مراجعة `opus-architecture-reviewer`**

النطاق:
- Tasks 2–4: التخزين، والمالك، والدمج، والمحللات.
- Task 8: `chooseSplit`.

تُصلح كل ملاحظة بمستوى P0 إلى P2 قبل الإغلاق.

- [ ] **Step 5: Commit**

```bash
git commit -m "test(kids-quran-journey): end-to-end flow; spec notes"
```

---

### Task 10: تجربة على الجهاز (المالك)

**Files:** لا تعديل في الكود.

- [ ] تفعيل العلم يدوياً على جهاز Android حقيقي عبر شاشة التطوير أو `adb shell`، بكتابة `kids_quran_journey_enabled=true` في التفضيلات.
- [ ] تجربة السيناريو:
  1. اختيار رحلة القرآن من الناس.
  2. فتح الخريطة والتمرير إلى البقرة.
  3. اختيار العصر «كاملة».
  4. اختيار الملك «على مراحل».
  5. القفز بين السور.
  6. العودة إلى المغامرة.
- [ ] **ملاحظة خاصة لآيات طويلة** (البقرة 282): ميزانية الاستماع والتعرّف على الكلام.
- [ ] **القرار بعد التجربة:** تفعيل العلم افتراضياً في الإصدار، أو الإبقاء عليه مطفأً مع قائمة إصلاحات.
