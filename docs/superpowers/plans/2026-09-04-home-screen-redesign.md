# Home Screen Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Talia Quran home screen from a cluttered stats dashboard into a serene daily companion with prayer times, unified action card, daily ayah & tadabbur, and time-aware shortcuts.

**Architecture:** Clean Architecture layers (domain → data → presentation) for each new service. New services (`PrayerTimesService`, `HijriCalendarService`, `DailyAyahRepository`) are injected via `get_it` into `HomeCubit`. Existing `UnifiedJourneyEngine` is preserved as-is — the new `UnifiedHeroFocusCard` consumes its output. Heatmap and heavy stats migrate to `ProgressPage`.

**Tech Stack:** Flutter/Dart, `adhan_dart` (prayer times), `geolocator` (GPS), `hijri` (Hijri calendar), existing `just_audio` + `AyahListenButton` (audio), existing `SocialShareSheet` (sharing).

**Spec:** `docs/superpowers/specs/2026-09-04-home-screen-redesign-design.md` (v2)

## Global Constraints

- SDK: `^3.11.4` (from pubspec.yaml)
- Offline-first: All new features must work without internet
- Dark/Light theme: Every new widget must support both via `isDark` parameter
- Localization: Arabic primary (`app_ar.arb`), English secondary (`app_en.arb`), camelCase keys
- DI pattern: `getIt.registerLazySingleton<Interface>(() => Impl(...))`
- Spacing: 8pt grid via `AppSpacing.*`, radii via `AppSpacing.radius*`
- Decorations: Use `AppDecorations.*` for card styles
- Colors: Use `AppColors.*` — never hardcode hex inline
- After editing Dart files: connect via `dtd` tool and `hot_reload`

---

### Task 1: Prayer Times Service (Domain + Data Layer)

**Files:**
- Create: `lib/features/home/domain/models/prayer_times_data.dart`
- Create: `lib/features/home/domain/services/prayer_times_service.dart`
- Create: `lib/features/home/domain/services/hijri_calendar_service.dart`
- Create: `lib/features/home/domain/services/location_service.dart`
- Create: `lib/features/home/data/services/prayer_times_service_impl.dart`
- Create: `lib/features/home/data/services/hijri_calendar_service_impl.dart`
- Create: `lib/features/home/data/services/location_service_impl.dart`
- Create: `lib/features/home/data/constants/preset_cities.dart`
- Modify: `pubspec.yaml` (add `adhan_dart`, `geolocator`, `hijri`)
- Modify: `android/app/src/main/AndroidManifest.xml` (add location permissions)
- Modify: `ios/Runner/Info.plist` (add location usage description)
- Modify: `lib/core/di/injection.dart` (register new services)

**Interfaces:**
- Produces: `PrayerTimesData` model, `PrayerTimesService.getTodayPrayerTimes(double lat, double lng, {CalculationMethod? method, Madhab? madhab})`, `HijriCalendarService.getHijriDate({int offset})`, `LocationService.getCurrentCoordinates()`, `LocationService.getSavedCoordinates()`, `LocationService.saveCoordinates(double lat, double lng, String cityName)`

- [ ] **Step 1: Add dependencies to `pubspec.yaml`**

Add under `dependencies:`:
```yaml
  adhan_dart: ^1.0.5
  geolocator: ^13.0.2
  hijri: ^3.0.0
```

Run: `flutter pub get`

- [ ] **Step 2: Add platform permissions**

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

In `ios/Runner/Info.plist`, add:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>يُستخدم لتحديد مواقيت الصلاة بدقة بناءً على موقعك</string>
```

- [ ] **Step 3: Create `PrayerTimesData` model**

```dart
// lib/features/home/domain/models/prayer_times_data.dart
import 'package:equatable/equatable.dart';

enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

class PrayerTimesData extends Equatable {
  const PrayerTimesData({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.hijriDate,
    required this.cityName,
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final String hijriDate;
  final String cityName;

  PrayerName get nextPrayer {
    final now = DateTime.now();
    if (now.isBefore(fajr)) return PrayerName.fajr;
    if (now.isBefore(sunrise)) return PrayerName.sunrise;
    if (now.isBefore(dhuhr)) return PrayerName.dhuhr;
    if (now.isBefore(asr)) return PrayerName.asr;
    if (now.isBefore(maghrib)) return PrayerName.maghrib;
    if (now.isBefore(isha)) return PrayerName.isha;
    return PrayerName.fajr; // after isha → tomorrow's fajr
  }

  DateTime get nextPrayerTime {
    final now = DateTime.now();
    if (now.isBefore(fajr)) return fajr;
    if (now.isBefore(sunrise)) return sunrise;
    if (now.isBefore(dhuhr)) return dhuhr;
    if (now.isBefore(asr)) return asr;
    if (now.isBefore(maghrib)) return maghrib;
    if (now.isBefore(isha)) return isha;
    return fajr.add(const Duration(days: 1)); // tomorrow's fajr
  }

  Duration get timeToNextPrayer => nextPrayerTime.difference(DateTime.now());

  DateTime timeForPrayer(PrayerName prayer) => switch (prayer) {
    PrayerName.fajr => fajr,
    PrayerName.sunrise => sunrise,
    PrayerName.dhuhr => dhuhr,
    PrayerName.asr => asr,
    PrayerName.maghrib => maghrib,
    PrayerName.isha => isha,
  };

  @override
  List<Object?> get props => [fajr, sunrise, dhuhr, asr, maghrib, isha, hijriDate, cityName];
}
```

- [ ] **Step 4: Create `LocationService` interface and implementation**

```dart
// lib/features/home/domain/services/location_service.dart
abstract class LocationService {
  Future<({double lat, double lng, String cityName})?> getCurrentCoordinates();
  ({double lat, double lng, String cityName})? getSavedCoordinates();
  Future<void> saveCoordinates(double lat, double lng, String cityName);
}
```

Implementation in `lib/features/home/data/services/location_service_impl.dart` using `geolocator` for GPS, `SharedPreferences` for persistence, and `preset_cities.dart` for manual fallback (preset list of ~30 major Arab/Islamic cities with lat/lng).

- [ ] **Step 5: Create `PrayerTimesService` interface and implementation**

```dart
// lib/features/home/domain/services/prayer_times_service.dart
import '../models/prayer_times_data.dart';

abstract class PrayerTimesService {
  PrayerTimesData? getTodayPrayerTimes({
    required double latitude,
    required double longitude,
    String? calculationMethod,
    String? madhab,
  });
}
```

Implementation in `lib/features/home/data/services/prayer_times_service_impl.dart` using `adhan_dart` with auto-detected calculation method based on coordinates and `SharedPreferences` for user overrides.

- [ ] **Step 6: Create `HijriCalendarService` interface and implementation**

```dart
// lib/features/home/domain/services/hijri_calendar_service.dart
abstract class HijriCalendarService {
  String getFormattedHijriDate({int dayOffset = 0});
}
```

Implementation using `hijri` package. Reads `'hijri_day_offset'` from `SharedPreferences`.

- [ ] **Step 7: Create `preset_cities.dart`**

```dart
// lib/features/home/data/constants/preset_cities.dart
class PresetCity {
  const PresetCity({required this.nameAr, required this.nameEn, required this.lat, required this.lng, required this.calculationMethod});
  final String nameAr, nameEn;
  final double lat, lng;
  final String calculationMethod;
}

const presetCities = <PresetCity>[
  PresetCity(nameAr: 'مكة المكرمة', nameEn: 'Makkah', lat: 21.4225, lng: 39.8262, calculationMethod: 'umm_al_qura'),
  PresetCity(nameAr: 'المدينة المنورة', nameEn: 'Madinah', lat: 24.4672, lng: 39.6024, calculationMethod: 'umm_al_qura'),
  PresetCity(nameAr: 'القاهرة', nameEn: 'Cairo', lat: 30.0444, lng: 31.2357, calculationMethod: 'egyptian'),
  // ... ~27 more cities
];
```

- [ ] **Step 8: Register services in `injection.dart`**

Add lazy singleton registrations for `LocationService`, `PrayerTimesService`, and `HijriCalendarService` in `configureDependencies()` after the SharedPreferences registration.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat(prayer-times): add PrayerTimesService, HijriCalendarService, LocationService with adhan_dart"
```

---

### Task 2: Daily Ayah Repository (Data Layer)

**Files:**
- Create: `lib/features/home/domain/models/daily_ayah_entry.dart`
- Create: `lib/features/home/domain/repositories/daily_ayah_repository.dart`
- Create: `lib/features/home/data/repositories/daily_ayah_repository_impl.dart`
- Create: `assets/data/daily_ayahs.json`
- Modify: `pubspec.yaml` (add asset)
- Modify: `lib/core/di/injection.dart` (register repository)

**Interfaces:**
- Produces: `DailyAyahEntry` model, `DailyAyahRepository.getTodayAyah()`

- [ ] **Step 1: Create `DailyAyahEntry` model**

```dart
// lib/features/home/domain/models/daily_ayah_entry.dart
import 'package:equatable/equatable.dart';

class DailyAyahEntry extends Equatable {
  const DailyAyahEntry({
    required this.surahId,
    required this.ayahNumber,
    required this.pageNumber,
    required this.ayahTextAr,
    required this.tadabburAr,
    required this.tadabburEn,
    required this.surahNameAr,
    required this.surahNameEn,
  });

  final int surahId;
  final int ayahNumber;
  final int pageNumber;
  final String ayahTextAr;
  final String tadabburAr;
  final String tadabburEn;
  final String surahNameAr;
  final String surahNameEn;

  factory DailyAyahEntry.fromJson(Map<String, dynamic> json) => DailyAyahEntry(
    surahId: json['surahId'] as int,
    ayahNumber: json['ayahNumber'] as int,
    pageNumber: json['pageNumber'] as int,
    ayahTextAr: json['ayahTextAr'] as String,
    tadabburAr: json['tadabburAr'] as String,
    tadabburEn: json['tadabburEn'] as String,
    surahNameAr: json['surahNameAr'] as String,
    surahNameEn: json['surahNameEn'] as String,
  );

  @override
  List<Object?> get props => [surahId, ayahNumber, pageNumber];
}
```

- [ ] **Step 2: Create `assets/data/daily_ayahs.json`**

Create a JSON array of 366 curated ayah entries. Start with an initial set of ~50 well-known ayahs with tadabbur, then expand. Structure:
```json
[
  {
    "surahId": 13,
    "ayahNumber": 28,
    "pageNumber": 252,
    "ayahTextAr": "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
    "tadabburAr": "راحة النفس وسكونها الحقيقي في ذكر الله وحده، لا في زخارف الدنيا ولا متاعها",
    "tadabburEn": "True peace and tranquility of the heart is found only in the remembrance of Allah",
    "surahNameAr": "الرعد",
    "surahNameEn": "Ar-Ra'd"
  }
]
```

Add to `pubspec.yaml` under `flutter > assets`:
```yaml
    - assets/data/daily_ayahs.json
```

- [ ] **Step 3: Create repository interface and implementation**

```dart
// lib/features/home/domain/repositories/daily_ayah_repository.dart
import '../models/daily_ayah_entry.dart';
abstract class DailyAyahRepository {
  Future<DailyAyahEntry> getTodayAyah();
}
```

Implementation loads JSON from assets, parses it, and returns `entries[dayOfYear % entries.length]`.

- [ ] **Step 4: Register in DI and commit**

```bash
git add -A
git commit -m "feat(daily-ayah): add DailyAyahRepository with curated ayahs and tadabbur"
```

---

### Task 3: Update `HomeCubit` and `HomeState`

**Files:**
- Modify: `lib/features/home/presentation/cubits/home_state.dart`
- Modify: `lib/features/home/presentation/cubits/home_cubit.dart`
- Modify: `lib/core/di/injection.dart` (update HomeCubit factory)

**Interfaces:**
- Consumes: `PrayerTimesService`, `HijriCalendarService`, `LocationService`, `DailyAyahRepository` from Tasks 1-2
- Produces: Updated `HomeLoaded` with `prayerTimesData` and `dailyAyah` fields

- [ ] **Step 1: Add new fields to `HomeLoaded`**

Add to `HomeLoaded`:
```dart
final PrayerTimesData? prayerTimesData;
final DailyAyahEntry? dailyAyah;
```

Update `copyWith` and `props` accordingly.

- [ ] **Step 2: Inject new services into `HomeCubit` constructor**

Add `PrayerTimesService`, `HijriCalendarService`, `LocationService`, `DailyAyahRepository` as constructor parameters.

- [ ] **Step 3: Load new data in `HomeCubit.load()`**

Add to the `load()` method (alongside existing parallel loads):
```dart
// Load prayer times
final coords = _locationService.getSavedCoordinates();
PrayerTimesData? prayerTimesData;
if (coords != null) {
  final hijri = _hijriService.getFormattedHijriDate();
  prayerTimesData = _prayerTimesService.getTodayPrayerTimes(
    latitude: coords.lat,
    longitude: coords.lng,
  );
  // Attach hijri date
  if (prayerTimesData != null) {
    prayerTimesData = PrayerTimesData(/* ...copy with hijriDate: hijri */);
  }
}

// Load daily ayah
final dailyAyah = await _dailyAyahRepository.getTodayAyah();
```

- [ ] **Step 4: Update `HomeCubit` DI registration in `injection.dart`**

Update the factory registration to pass the new service dependencies.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(home-cubit): integrate prayer times and daily ayah into HomeLoaded state"
```

---

### Task 4: Localization Keys

**Files:**
- Modify: `lib/core/l10n/app_ar.arb`
- Modify: `lib/core/l10n/app_en.arb`

**Interfaces:**
- Produces: ~45 new localization keys for prayer names, hijri months, card titles, time-aware messages

- [ ] **Step 1: Add Arabic localization keys to `app_ar.arb`**

Add keys for:
- Prayer names: `prayerFajr`, `prayerSunrise`, `prayerDhuhr`, `prayerAsr`, `prayerMaghrib`, `prayerIsha`
- Hijri month names: `hijriMonth1` through `hijriMonth12`
- Prayer pill: `prayerTimeRemaining`, `prayerTimesTitle`
- Daily ayah: `dailyAyahTitle`, `dailyAyahOpenInMushaf`, `dailyAyahListen`, `dailyAyahShare`, `dailyAyahTadabbur`
- Time-aware shortcuts: `morningAzkarTitle`, `morningAzkarSubtitle`, `eveningAzkarTitle`, `eveningAzkarSubtitle`, `fridayKahfTitle`, `fridayKahfSubtitle`, `nightAzkarTitle`, `nightAzkarSubtitle`
- Motivation strip: `compactStreakLabel`, `compactLevelLabel`, `viewFullStats`
- Hero focus card: `continueReading`, `continueMemoization`, `startYourJourney`, `onePageMakesADifference`
- Location: `locationPermissionReason`, `chooseCityManually`, `changeCity`

- [ ] **Step 2: Add corresponding English keys to `app_en.arb`**

- [ ] **Step 3: Run code generation and commit**

```bash
flutter gen-l10n
git add -A
git commit -m "feat(l10n): add localization keys for prayer times, daily ayah, time-aware shortcuts"
```

---

### Task 5: New Home Page Widgets — `ModernHeroHeader` + `PrayerTimesPill`

**Files:**
- Modify: `lib/features/home/presentation/pages/home_page_widgets.dart`
- Create: `lib/features/home/presentation/widgets/prayer_times_pill.dart`
- Create: `lib/features/home/presentation/widgets/prayer_times_bottom_sheet.dart`

**Interfaces:**
- Consumes: `PrayerTimesData` from `HomeLoaded.prayerTimesData`, `LocationService`, existing `ProfileCubit`
- Produces: `ModernHeroHeader` widget (replaces `_HeroHeader`), `PrayerTimesPill` widget, `PrayerTimesBottomSheet`

- [ ] **Step 1: Create `PrayerTimesPill` StatefulWidget**

A capsule showing: prayer icon + next prayer name + time + remaining + hijri date. Uses `Timer.periodic(Duration(minutes: 1))` for countdown. On tap → opens `PrayerTimesBottomSheet`.

- [ ] **Step 2: Create `PrayerTimesBottomSheet`**

Shows all 6 prayer times in a clean list with the next prayer highlighted. Includes "change city" button that triggers location re-detection or manual city picker.

- [ ] **Step 3: Rewrite `_HeroHeader` → `ModernHeroHeader`**

Replace the existing `_HeroHeader` in `home_page_widgets.dart`:
- Keep: greeting + name + settings icon
- Remove: `_AchievementRow`, large "تاليــة" text with logo
- Add: small inline logo (22px) merged with greeting line
- Add: `PrayerTimesPill` at the bottom of the header

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(home-header): replace HeroHeader with ModernHeroHeader + PrayerTimesPill"
```

---

### Task 6: New Home Page Widgets — `UnifiedHeroFocusCard` + `TimeAwareDailyShortcutCard` + `DailyAyahTadabburCard` + `CompactMotivationStrip`

**Files:**
- Create: `lib/features/home/presentation/widgets/unified_hero_focus_card_v2.dart`
- Create: `lib/features/home/presentation/widgets/time_aware_daily_shortcut_card.dart`
- Create: `lib/features/home/presentation/widgets/daily_ayah_tadabbur_card.dart`
- Create: `lib/features/home/presentation/widgets/compact_motivation_strip.dart`

**Interfaces:**
- Consumes: `HomeLoaded` (heroAction, activeKhatmah, dailyWirdPageDetail, customPlan, coachRecommendation, dailyAyah, prayerTimesData, totalXp, progress), `StreakCubit`, `AyahListenButton`, `SocialShareSheet`
- Produces: 4 new widgets ready for composition in `_HomeContent`

- [ ] **Step 1: Create `UnifiedHeroFocusCardV2`**

Implements the 4 scenarios from spec section 3.2.2:
- Both khatmah + memorization → SegmentedButton toggle with 2 tabs
- Single source → direct card, no toggle
- Daily wird only → "one page makes a difference" CTA
- Nothing → "start your Quran journey" CTA

Uses `UnifiedJourneyEngine` result (`heroAction`) to determine initial active tab.

- [ ] **Step 2: Create `TimeAwareDailyShortcutCard`**

Checks priority: Friday (Surah Al-Kahf) > Morning (azkar) > Evening (azkar) > Night (sleep azkar).
Uses `prayerTimesData` for dynamic time boundaries (fajr → morning, dhuhr → afternoon, asr → evening).
Routes: `'/azkar/morning'`, `'/azkar/evening'`, `'/quran/surah/18'`, `'/azkar/general'`.

- [ ] **Step 3: Create `DailyAyahTadabburCard`**

Renders:
- Ayah text in Amiri font, large and centered
- Surah name + ayah number reference
- Tadabbur text in body font
- 3 action buttons row: Open in Mushaf (`context.push`), Listen (`AyahListenButton`), Share (`SocialShareSheet.show`)

- [ ] **Step 4: Create `CompactMotivationStrip`**

Horizontal card with: 🔥 streak count + level badge + XP + "view stats →" tap to `AppRoutes.progress`.
Uses `BlocBuilder<StreakCubit, StreakState>` for live streak data.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(home-widgets): add UnifiedHeroFocusCard, TimeAwareShortcut, DailyAyah, MotivationStrip"
```

---

### Task 7: Rewrite `_HomeContent` Layout and Remove Old Widgets

**Files:**
- Modify: `lib/features/home/presentation/pages/home_page.dart` (`_HomeContent`)
- Modify: `lib/features/home/presentation/pages/home_page_widgets.dart` (remove old widgets)

**Interfaces:**
- Consumes: All widgets from Tasks 5-6, existing conditional banners
- Produces: New `_HomeContent` `CustomScrollView` layout matching the spec IA

- [ ] **Step 1: Rewrite `_HomeContent.build()` slivers**

Replace the entire slivers list with the new layout:
```dart
slivers: [
  // 1. ModernHeroHeader
  SliverToBoxAdapter(child: ModernHeroHeader(state: state, isDark: isDark)),

  // 2. UnifiedHeroFocusCard
  SliverToBoxAdapter(child: Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.md, AppSpacing.pagePadding, 0),
    child: UnifiedHeroFocusCardV2(state: state, isDark: isDark),
  )),

  // 3. Conditional banners (same logic, same design)
  SliverToBoxAdapter(child: _SignInNudgeBanner(isDark: isDark)),
  if (state.lastRestorableLocation == null)
    SliverToBoxAdapter(child: _TutorialPromptBanner(isDark: isDark)),
  if (!state.isKids && state.selectedTrack == MemorizationTrack.adults)
    SliverToBoxAdapter(child: /* ParentGuardianToolsCard — same as before */),

  // 4. TimeAwareDailyShortcutCard
  SliverToBoxAdapter(child: Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.md, AppSpacing.pagePadding, 0),
    child: TimeAwareDailyShortcutCard(prayerTimes: state.prayerTimesData, isDark: isDark),
  )),

  // 5. DailyAyahTadabburCard
  if (state.dailyAyah != null)
    SliverToBoxAdapter(child: Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.md, AppSpacing.pagePadding, 0),
      child: DailyAyahTadabburCard(ayah: state.dailyAyah!, isDark: isDark),
    )),

  // 6. CompactMotivationStrip
  SliverToBoxAdapter(child: Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.lg, AppSpacing.pagePadding, 0),
    child: CompactMotivationStrip(state: state, isDark: isDark),
  )),

  // 7. Bottom padding
  SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl + AppSpacing.lg)),
],
```

- [ ] **Step 2: Remove old widgets from `home_page_widgets.dart`**

Delete the following widget classes:
- `_QuickActionsGrid` and `_QuickActionButton`
- `_HomeEngagementSection` and `_HomeEngagementTile`
- `_HomeActivityHeatmapSection`
- `_ProgressSection` and `_ProgressMetricPill`
- `_AchievementRow` and `_AchievementBadge`
- `_DailyWirdCard`
- `_ResumeSessionCard`
- `_NextBestActionCard`

Keep: `_SignInNudgeBanner`, `_TutorialPromptBanner`, `_ParentGuardianToolsCard`, `_HeroIconButton`.

- [ ] **Step 3: Remove old imports**

Clean up unused imports from `home_page.dart` (e.g., `khatmah_hero_card.dart` import, `unified_hero_action_card.dart` import if replaced).

- [ ] **Step 4: Run `dart analyze` and fix any issues**

```bash
dart analyze lib/features/home/
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(home-page): rewrite HomeContent layout, remove old redundant widgets"
```

---

### Task 8: Migrate Heatmap + Engagement Stats to `ProgressPage`

**Files:**
- Modify: `lib/features/progress/presentation/cubits/progress_cubit.dart`
- Modify: `lib/features/progress/presentation/cubits/progress_state.dart`
- Modify: `lib/features/progress/presentation/pages/progress_page.dart`
- Modify: `lib/core/di/injection.dart` (update ProgressCubit dependencies)

**Interfaces:**
- Consumes: `GetActivityHeatmapUsecase`, `ActivityHeatmap` widget from `lib/core/widgets/activity_heatmap.dart`
- Produces: Updated `ProgressPage` with heatmap section + engagement stats

- [ ] **Step 1: Add heatmap fields to `ProgressLoaded` state**

```dart
final Map<String, int> activityCountsByDay;
final DateTime activityStartDate;
```

- [ ] **Step 2: Inject `GetActivityHeatmapUsecase` into `ProgressCubit`**

Add it as a constructor dependency and load heatmap data in `loadProgress()`.

- [ ] **Step 3: Update DI registration for `ProgressCubit`**

Pass `GetActivityHeatmapUsecase` to the factory.

- [ ] **Step 4: Add `ActivityHeatmap` section to `ProgressPage`**

Insert after "Memorization Progress" section and before "Certificates" section:
```dart
// Activity Heatmap
if (state.activityCountsByDay.isNotEmpty)
  _ActivityHeatmapSection(state: state, isDark: isDark),
```

Implement `_ActivityHeatmapSection` (similar to the old `_HomeActivityHeatmapSection` but inside `ProgressPage` context).

- [ ] **Step 5: Add weekly engagement stats to `ProgressPage`**

Add a section similar to the old `_HomeEngagementSection` (streak, XP level, due today, weekly activity) at the top of `ProgressPage`, right after the hero stats cards.

- [ ] **Step 6: Run `dart analyze` on progress feature**

```bash
dart analyze lib/features/progress/ lib/features/home/
```

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(progress-page): migrate activity heatmap and engagement stats from home page"
```

---

## Execution Dependencies

```
Task 1 (Prayer Times Service) ─┐
Task 2 (Daily Ayah Data)  ─────┤
Task 4 (Localization Keys) ────┤
                                ├─→ Task 3 (Update HomeCubit) ─→ Task 5 (Header + PrayerPill)
                                │                                       │
                                │                                       ├─→ Task 6 (New Widgets) ─→ Task 7 (Rewrite Layout)
                                │                                       │
                                └───────────────────────────────────────→ Task 8 (Migrate Heatmap)
```

Tasks 1, 2, and 4 can run in parallel. Task 3 depends on 1+2. Tasks 5-6 depend on 3+4. Task 7 depends on 5+6. Task 8 can run in parallel with 5-7.
