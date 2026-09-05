# Islamic UX Reverence Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Islamic UX reverence principles from `13_islamic_ux.md` across Talia: build a centralized `QuranTextDisplay` component, enforce strict typography separation, add independent Quran font scaling, establish an audio reverence policy to suppress UI noises during Quran recitation, refine celebration overlays to distinguish adult devotional dignity from kids gamification, respect silence during recitation recall, and enforce respectful Quran copying/sharing attribution.

**Architecture:** 
- Shared Presentation Layer: A unified `QuranTextDisplay` enforcing authentic Uthmani styling, non-truncation, Quranic brackets (`﴿ ﴾`), and contrast protection.
- Theme & Settings: Decouple sacred typography (`Amiri`/`QCF`) from system chrome (`Noto_Naskh_Arabic`), and introduce independent Quran font scaling with local persistence.
- Audio & Devotional State: An `AudioReverencePolicy` coordinating active recitation with app UI sound effects and celebration transitions.
- Assessment & Guidance: Respectful "watching quietly" companion state during active recall silence without anxiety-inducing timers.

**Tech Stack:** Flutter, Dart, BLoC/Cubit, SharedPreferences, QCF/Amiri fonts, Material 3, just_audio

## Global Constraints

- Reverence for the Mushaf: Quran text must NEVER be clipped mid-word with generic ellipsis (`...`) or distorted with playful bouncy animations.
- Font Separation: `Amiri` and `QCF` are strictly reserved for Quran text, Azkar, and sacred Hadith. System UI chrome must strictly use `Noto_Naskh_Arabic`.
- Dark Mode Reverence: Pure pitch black (`#000000`) must NEVER be used behind Uthmani script. Safe parchment tones (`#0A201D` / `#021210`) must be preserved to prevent diacritic halation.
- Silence as a Valid State: Moments of quiet in memorization and recitation are sacred focus states, not empty states to fill with noise or high-stress countdowns.
- Audio Reverence: Quran audio playback must completely suppress UI notification sounds, XP chimes, and button sound effects.
- Offline-First: All typography, settings, and components must work completely offline without network calls.
- Static Analysis: Zero warnings or errors on `flutter analyze` after every task.

---

### Task 1: Centralized `QuranTextDisplay` Component & Anti-Truncation Rules

**Files:**
- Create: `lib/core/widgets/quran_text_display.dart`
- Test: `test/core/widgets/quran_text_display_test.dart`

**Interfaces:**
- Consumes:
  - `lib/core/theme/app_colors.dart` (`AppColors.lightTextPrimary`, `AppColors.darkTextPrimary`, `AppColors.parchmentDark`)
  - `lib/core/theme/app_typography.dart` (`AppTypography.quranVerse`, `AppTypography.quranMedium`)
- Produces:
  - `class QuranTextDisplay extends StatelessWidget`:
    - `final String text;`
    - `final int? ayahNumber;`
    - `final String? surahName;`
    - `final double? fontSize;`
    - `final Color? color;`
    - `final TextAlign textAlign;`
    - `final bool showBrackets;`
    - `final bool isDark;`
    - Static helper: `static String formatWithBrackets(String text, {int? ayahNumber})`
    - Static helper: `static Color resolveSafeTextColor(Color background, bool isDark)`

- [ ] **Step 1: Write failing tests for `QuranTextDisplay`**

```dart
// test/core/widgets/quran_text_display_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/quran_text_display.dart';

void main() {
  group('QuranTextDisplay', () {
    test('formatWithBrackets wraps text in authentic Quranic brackets', () {
      final formatted = QuranTextDisplay.formatWithBrackets(
        'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
        ayahNumber: 2,
      );
      expect(formatted, contains('﴿'));
      expect(formatted, contains('﴾'));
      expect(formatted, contains('٢'));
    });

    testWidgets('renders verse with Amiri font and no mid-word truncation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuranTextDisplay(
              text: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
              ayahNumber: 5,
              showBrackets: true,
            ),
          ),
        ),
      );

      final textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontFamily, 'Amiri');
      expect(textWidget.overflow, isNot(TextOverflow.ellipsis));
    });

    test('resolveSafeTextColor prevents invisible text on pure black', () {
      final safeColor = QuranTextDisplay.resolveSafeTextColor(
        const Color(0xFF000000),
        true,
      );
      expect(safeColor.computeLuminance() > 0.5, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/widgets/quran_text_display_test.dart`  
Expected: FAIL with compilation error (QuranTextDisplay does not exist yet).

- [ ] **Step 3: Implement `QuranTextDisplay`**

```dart
// lib/core/widgets/quran_text_display.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/quran_ayah_display_text.dart';

/// Central presentation widget for Quranic text outside the full Mushaf page view.
/// Enforces Islamic UX Reverence:
/// 1. Authentic Mushaf font (Amiri) with balanced line height for diacritics.
/// 2. Quranic brackets `﴿ ﴾` and Arabic verse numbering.
/// 3. Strict ban on `TextOverflow.ellipsis` to prevent clipping sacred words.
/// 4. Contrast protection against pure black halation.
class QuranTextDisplay extends StatelessWidget {
  const QuranTextDisplay({
    super.key,
    required this.text,
    this.ayahNumber,
    this.surahName,
    this.fontSize,
    this.color,
    this.textAlign = TextAlign.center,
    this.showBrackets = true,
    this.isDark = false,
  });

  final String text;
  final int? ayahNumber;
  final String? surahName;
  final double? fontSize;
  final Color? color;
  final TextAlign textAlign;
  final bool showBrackets;
  final bool isDark;

  static String toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((char) {
      final digit = int.tryParse(char);
      return digit != null ? arabicDigits[digit] : char;
    }).join();
  }

  static String formatWithBrackets(String rawText, {int? ayahNumber}) {
    final cleaned = rawText.trim();
    if (ayahNumber != null && ayahNumber > 0) {
      return '﴿ $cleaned ۝${toArabicDigits(ayahNumber)} ﴾';
    }
    return '﴿ $cleaned ﴾';
  }

  static Color resolveSafeTextColor(Color background, bool isDark) {
    if (isDark && background.value == 0xFF000000) {
      return AppColors.darkTextPrimary;
    }
    return isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark || Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = color ?? (effectiveIsDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    final displayText = showBrackets
        ? formatWithBrackets(text, ayahNumber: ayahNumber)
        : (ayahNumber != null && ayahNumber! > 0
            ? '$text ۝${toArabicDigits(ayahNumber!)}'
            : text);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        displayText,
        textAlign: textAlign,
        textWidthBasis: TextWidthBasis.parent,
        softWrap: true,
        style: AppTypography.quranVerse.copyWith(
          fontFamily: 'Amiri',
          fontSize: fontSize ?? 24.0,
          color: resolvedColor,
          height: 2.2,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/widgets/quran_text_display_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/widgets/quran_text_display.dart test/core/widgets/quran_text_display_test.dart
git commit -m "feat(ux): implement centralized QuranTextDisplay with reverence safeguards"
```

---

### Task 2: Strict Typography Separation across System Chrome

**Files:**
- Modify: `lib/core/widgets/error_info_banner.dart:54-60`
- Modify: `lib/features/settings/presentation/pages/settings_page.dart:313-321`
- Test: `test/core/widgets/error_info_banner_test.dart`

**Interfaces:**
- Consumes:
  - `lib/core/theme/app_typography.dart` (`AppTypography.titleSmall`, `AppTypography.titleLarge`)
- Produces:
  - Cleaned UI headers strictly using `Noto_Naskh_Arabic` instead of `Amiri`.

- [ ] **Step 1: Write test verifying system chrome does not use `Amiri`**

```dart
// test/core/widgets/error_info_banner_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/error_info_banner.dart';

void main() {
  testWidgets('ErrorInfoBanner uses Noto Naskh font for system titles, never Amiri', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ErrorInfoBanner(
            title: 'خطأ في الاتصال',
            message: 'تعذر الوصول إلى الخادم',
            type: ErrorInfoBannerType.error,
          ),
        ),
      ),
    );

    final titleFinder = find.text('خطأ في الاتصال');
    expect(titleFinder, findsOneWidget);

    final titleText = tester.widget<Text>(titleFinder);
    expect(titleText.style?.fontFamily, isNot('Amiri'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/widgets/error_info_banner_test.dart`  
Expected: FAIL because `ErrorInfoBanner` line 57 currently has `fontFamily: 'Amiri'`.

- [ ] **Step 3: Modify `ErrorInfoBanner` and `SettingsPage` to use system typography**

In `lib/core/widgets/error_info_banner.dart:54-60`:
```dart
Text(
  title!,
  style: AppTypography.titleSmall.copyWith(
    color: colors.foreground,
    fontWeight: FontWeight.w700,
    fontFamily: 'Noto_Naskh_Arabic',
  ),
),
```

In `lib/features/settings/presentation/pages/settings_page.dart:313-321`:
```dart
Text(
  context.l10n.settings,
  style: AppTypography.titleLarge.copyWith(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 20,
  ),
),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/widgets/error_info_banner_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/widgets/error_info_banner.dart lib/features/settings/presentation/pages/settings_page.dart test/core/widgets/error_info_banner_test.dart
git commit -m "refactor(typography): reserve Amiri exclusively for sacred texts and use Noto Naskh for system UI"
```

---

### Task 3: Independent Quran Font Sizing State & Settings Control

**Files:**
- Create: `lib/core/theme/quran_font_size_cubit.dart`
- Modify: `lib/core/di/injection.dart`
- Modify: `lib/features/settings/presentation/widgets/settings_appearance_tiles.dart`
- Test: `test/core/theme/quran_font_size_cubit_test.dart`
- Test: `test/features/settings/presentation/widgets/quran_font_size_tile_test.dart`

**Interfaces:**
- Consumes:
  - `SharedPreferences` via `getIt<SharedPreferences>()`
  - `QuranTextDisplay` from Task 1
- Produces:
  - `class QuranFontSizeCubit extends Cubit<double>`:
    - Default size scale: `1.0` (range `0.8` to `1.5`)
    - `Future<void> setScale(double newScale)`
  - `class QuranFontSizeTile extends StatelessWidget` with a slider and live sample verse preview with tashkeel.

- [ ] **Step 1: Write failing test for `QuranFontSizeCubit`**

```dart
// test/core/theme/quran_font_size_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/theme/quran_font_size_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late QuranFontSizeCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'quran_font_scale': 1.2});
    prefs = await SharedPreferences.getInstance();
    cubit = QuranFontSizeCubit(prefs);
  });

  tearDown(() => cubit.close());

  test('loads saved font scale from preferences', () {
    expect(cubit.state, 1.2);
  });

  test('setScale updates state and persists value clamped between 0.8 and 1.5', () async {
    await cubit.setScale(1.4);
    expect(cubit.state, 1.4);
    expect(prefs.getDouble('quran_font_scale'), 1.4);

    await cubit.setScale(2.0); // should clamp to 1.5
    expect(cubit.state, 1.5);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/theme/quran_font_size_cubit_test.dart`  
Expected: FAIL with compilation error (Cubit does not exist).

- [ ] **Step 3: Implement `QuranFontSizeCubit` and `QuranFontSizeTile`**

```dart
// lib/core/theme/quran_font_size_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranFontSizeCubit extends Cubit<double> {
  QuranFontSizeCubit(this._prefs)
      : super(_prefs.getDouble(_prefKey) ?? 1.0);

  final SharedPreferences _prefs;
  static const String _prefKey = 'quran_font_scale';

  static const double minScale = 0.8;
  static const double maxScale = 1.5;

  Future<void> setScale(double scale) async {
    final clamped = scale.clamp(minScale, maxScale);
    await _prefs.setDouble(_prefKey, clamped);
    emit(clamped);
  }
}
```

In `lib/features/settings/presentation/widgets/settings_appearance_tiles.dart`:
```dart
class QuranFontSizeTile extends StatelessWidget {
  const QuranFontSizeTile({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranFontSizeCubit, double>(
      builder: (context, scale) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'حجم خط الآيات والأذكار',
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    '${(scale * 100).toInt()}%',
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: scale,
                min: QuranFontSizeCubit.minScale,
                max: QuranFontSizeCubit.maxScale,
                divisions: 7,
                activeColor: isDark ? AppColors.primaryLight : AppColors.primary,
                onChanged: (val) => context.read<QuranFontSizeCubit>().setScale(val),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: QuranTextDisplay(
                  text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  fontSize: 22.0 * scale,
                  isDark: isDark,
                  showBrackets: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Register in `lib/core/di/injection.dart` and run tests**

Register `getIt.registerLazySingleton<QuranFontSizeCubit>(() => QuranFontSizeCubit(getIt<SharedPreferences>()));`  
Run: `flutter test test/core/theme/quran_font_size_cubit_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/theme/quran_font_size_cubit.dart lib/core/di/injection.dart lib/features/settings/presentation/widgets/settings_appearance_tiles.dart test/core/theme/quran_font_size_cubit_test.dart
git commit -m "feat(accessibility): provide independent Quran font scaling with live Mushaf preview"
```

---

### Task 4: Audio Reverence Policy (Suppress UI Sounds during Quran Recitation)

**Files:**
- Create: `lib/core/services/audio_reverence_policy.dart`
- Test: `test/core/services/audio_reverence_policy_test.dart`

**Interfaces:**
- Consumes:
  - `ContinuousPlaybackState` / `AudioLifecycleManager`
- Produces:
  - `class AudioReverencePolicy`:
    - `static final AudioReverencePolicy instance`
    - `bool get isQuranAudioActive`
    - `void setQuranAudioPlaying(bool isPlaying)`
    - `bool shouldPlayUiSoundEffect()`

- [ ] **Step 1: Write failing test for `AudioReverencePolicy`**

```dart
// test/core/services/audio_reverence_policy_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/audio_reverence_policy.dart';

void main() {
  late AudioReverencePolicy policy;

  setUp(() {
    policy = AudioReverencePolicy();
  });

  test('shouldPlayUiSoundEffect returns true when Quran audio is not active', () {
    expect(policy.isQuranAudioActive, isFalse);
    expect(policy.shouldPlayUiSoundEffect(), isTrue);
  });

  test('shouldPlayUiSoundEffect returns false when Quran recitation is active', () {
    policy.setQuranAudioPlaying(true);
    expect(policy.isQuranAudioActive, isTrue);
    expect(policy.shouldPlayUiSoundEffect(), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/audio_reverence_policy_test.dart`  
Expected: FAIL with compilation error (Policy does not exist).

- [ ] **Step 3: Implement `AudioReverencePolicy`**

```dart
// lib/core/services/audio_reverence_policy.dart
import 'package:flutter/foundation.dart';

/// Enforces the Islamic UX rule:
/// "Never auto-play unrelated sound (notification chimes, character sound effects)
/// over active Quran audio playback."
class AudioReverencePolicy {
  static final AudioReverencePolicy instance = AudioReverencePolicy._();

  AudioReverencePolicy() : _isQuranAudioActive = false;
  AudioReverencePolicy._() : _isQuranAudioActive = false;

  bool _isQuranAudioActive;
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);

  bool get isQuranAudioActive => _isQuranAudioActive;

  void setQuranAudioPlaying(bool isPlaying) {
    _isQuranAudioActive = isPlaying;
    isPlayingNotifier.value = isPlaying;
  }

  /// Returns true only if it is reverent to play UI sounds (XP chimes, button clicks).
  bool shouldPlayUiSoundEffect() {
    return !_isQuranAudioActive;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/audio_reverence_policy_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/services/audio_reverence_policy.dart test/core/services/audio_reverence_policy_test.dart
git commit -m "feat(audio): establish AudioReverencePolicy to suppress UI SFX during recitation"
```

---

### Task 5: Reverent Celebrations (`CelebrationOverlay` refinement for Adult vs Kids)

**Files:**
- Modify: `lib/core/widgets/celebration_overlay.dart`
- Test: `test/core/widgets/celebration_overlay_test.dart`

**Interfaces:**
- Consumes:
  - `AudioReverencePolicy.instance.shouldPlayUiSoundEffect()`
  - `AppColors.ambientGold`
- Produces:
  - Updated `CelebrationOverlay` accepting `bool isKids = false`.
  - Adult track: Subtle ambient gold glow, reverent prayer/dua (`بارك الله في حفظك`), no confetti fireworks.
  - Kids track: Confetti, stars, and celebratory animation.

- [ ] **Step 1: Write failing test for `CelebrationOverlay` adult mode**

```dart
// test/core/widgets/celebration_overlay_test.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/celebration_overlay.dart';

void main() {
  testWidgets('CelebrationOverlay in adult mode does not render confetti widget', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CelebrationOverlay(
            type: CelebrationType.ayah,
            xpGained: 10,
            isKids: false,
            onComplete: () {},
          ),
        ),
      ),
    );

    expect(find.byType(ConfettiWidget), findsNothing);
    expect(find.text('بارك الله في حفظك'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/widgets/celebration_overlay_test.dart`  
Expected: FAIL because `isKids` does not exist on `CelebrationOverlay` and ConfettiWidget is always rendered.

- [ ] **Step 3: Modify `CelebrationOverlay`**

In `lib/core/widgets/celebration_overlay.dart`:
Add `final bool isKids;` with default `false`.
Conditionally initialize and render `ConfettiWidget` only when `widget.isKids == true`.
In adult mode, display a calming card with:
```dart
Text(
  'بارك الله في حفظك',
  style: AppTypography.headlineSmall.copyWith(
    color: AppColors.goldDark,
    fontFamily: 'Noto_Naskh_Arabic',
    fontWeight: FontWeight.bold,
  ),
)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/widgets/celebration_overlay_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/widgets/celebration_overlay.dart test/core/widgets/celebration_overlay_test.dart
git commit -m "feat(ux): adapt CelebrationOverlay for adult reverent dua vs kids gamification"
```

---

### Task 6: Silence as a Valid State & "Watching Quietly" in V2 Recitation

**Files:**
- Modify: `lib/features/memorization_plus/presentation/pages/v2/v2_recitation_page.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/v2/v2_session_widgets.dart`
- Test: `test/features/memorization_plus/presentation/pages/v2_recitation_silence_test.dart`

**Interfaces:**
- Consumes:
  - `13_islamic_ux.md` ("Companion character's watching quietly state exists for exactly this reason")
- Produces:
  - `V2HiddenTextCard` displays a quiet listening indicator ("تالية في حالة إنصات هادئ...") during recall.
  - Absence of high-stress timers or flashing warnings.

- [ ] **Step 1: Write test verifying quiet companion state during recitation**

```dart
// test/features/memorization_plus/presentation/pages/v2_recitation_silence_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/v2/v2_session_widgets.dart';

void main() {
  testWidgets('V2HiddenTextCard displays calm listening status when recording', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: V2HiddenTextCard(
            isRecording: true,
            isEvaluating: false,
            speechIssue: null,
          ),
        ),
      ),
    );

    expect(find.text('في حالة إنصات هادئ... اقرأ على مهل'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/memorization_plus/presentation/pages/v2_recitation_silence_test.dart`  
Expected: FAIL (Text not found in widget).

- [ ] **Step 3: Update `V2HiddenTextCard` in `v2_session_widgets.dart`**

Enhance the recording state of `V2HiddenTextCard` to render:
```dart
if (isRecording) ...[
  const Icon(Icons.graphic_eq_rounded, color: AppColors.primary, size: 32),
  const SizedBox(height: AppSpacing.sm),
  Text(
    'في حالة إنصات هادئ... اقرأ على مهل',
    textAlign: TextAlign.center,
    style: AppTypography.bodyMedium.copyWith(
      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      fontWeight: FontWeight.w600,
    ),
  ),
]
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/memorization_plus/presentation/pages/v2_recitation_silence_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/features/memorization_plus/presentation/pages/v2/v2_session_widgets.dart test/features/memorization_plus/presentation/pages/v2_recitation_silence_test.dart
git commit -m "feat(ux): implement quiet listening companion state during active recall recitation"
```

---

### Task 7: Respectful Quran Copying & Attribution Helper

**Files:**
- Create: `lib/core/utils/quran_clipboard_helper.dart`
- Modify: `lib/features/quran/presentation/pages/quran_reader_page.dart`
- Test: `test/core/utils/quran_clipboard_helper_test.dart`

**Interfaces:**
- Consumes:
  - `Ayah` entity from `lib/features/quran/domain/entities/quran_entities.dart`
- Produces:
  - `class QuranClipboardHelper`:
    - `static String formatForCopy({required String ayahText, required String surahName, required int ayahNumber})`

- [ ] **Step 1: Write failing test for `QuranClipboardHelper`**

```dart
// test/core/utils/quran_clipboard_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/utils/quran_clipboard_helper.dart';

void main() {
  test('formatForCopy outputs authentic brackets and full attribution', () {
    final formatted = QuranClipboardHelper.formatForCopy(
      ayahText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
      surahName: 'البقرة',
      ayahNumber: 255,
    );

    expect(formatted, '﴿ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ﴾ [سورة البقرة: الآية ٢٥٥] — عبر تطبيق تالية');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/quran_clipboard_helper_test.dart`  
Expected: FAIL with compilation error (Helper does not exist).

- [ ] **Step 3: Implement `QuranClipboardHelper` and wire in `QuranReaderPage`**

```dart
// lib/core/utils/quran_clipboard_helper.dart
import '../widgets/quran_text_display.dart';

class QuranClipboardHelper {
  static String formatForCopy({
    required String ayahText,
    required String surahName,
    required int ayahNumber,
  }) {
    final arabicNumber = QuranTextDisplay.toArabicDigits(ayahNumber);
    return '﴿ ${ayahText.trim()} ﴾ [سورة $surahName: الآية $arabicNumber] — عبر تطبيق تالية';
  }
}
```

In `lib/features/quran/presentation/pages/quran_reader_page.dart` (inside `_AyahOptionsSheet` on Copy):
Use `QuranClipboardHelper.formatForCopy` before sending text to `Clipboard.setData`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/quran_clipboard_helper_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/utils/quran_clipboard_helper.dart lib/features/quran/presentation/pages/quran_reader_page.dart test/core/utils/quran_clipboard_helper_test.dart
git commit -m "feat(ux): format copied Quran verses with sacred brackets and attribution"
```

---

## Verification Plan

### Automated Tests
Execute the entire test suite and verify analyzer clean state:
```bash
flutter analyze
flutter test test/core/widgets/quran_text_display_test.dart
flutter test test/core/widgets/error_info_banner_test.dart
flutter test test/core/theme/quran_font_size_cubit_test.dart
flutter test test/core/services/audio_reverence_policy_test.dart
flutter test test/core/widgets/celebration_overlay_test.dart
flutter test test/features/memorization_plus/presentation/pages/v2_recitation_silence_test.dart
flutter test test/core/utils/quran_clipboard_helper_test.dart
```

### Manual Verification
1. **Font Sizing in Settings:** Open Settings > Appearance > Quran Font Size. Move slider and verify live preview renders Uthmani text cleanly.
2. **Night Mode Mushaf:** Inspect Quran reader in dark mode, verify background is soft parchment dark (`#0A201D`) and diacritics are distinct without halation.
3. **Recitation Session Silence:** Enter a V2 memorization recitation step. Observe that during recording, the companion shows "في حالة إنصات هادئ" with no stressful countdown timer.
4. **Copy Ayah:** Long press an ayah in the reader, tap copy, paste into another app, and verify it includes `﴿ ... ﴾ [سورة ... : الآية ...] — عبر تطبيق تالية`.
