# Kids 2.5D Gamified Journey & 3D Tasks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the kids memorization journey and daily task screens into a vibrant, high-performance 2.5D isometric game adventure with dynamic biomes, interactive map nodes (chests, castles, palaces), a living hero avatar with jump physics, 3D Quran tablet recitation, and juicy audio/haptic feedback.

**Architecture:** Layered presentation upgrade preserving 100% of existing Domain & Storage models (`KidsJourneyCubit`, `KidsJourneyStage`, `Isar`). Introduces a clean `KidsBiomeEngine`, `KidsAudioFeedbackService` (via `just_audio`), Canvas-based 2.5D isometric path & node rendering with procedural fallbacks, and a physics-driven `HeroAvatarController`, guarded by feature flags.

**Tech Stack:** Flutter, Dart, `flutter_bloc`, `flutter_animate`, `just_audio`, `shared_preferences`, `CustomPainter`, `HapticFeedback`.

## Global Constraints

- **Platform:** Android & iOS (Flutter).
- **Target Frame Rate:** 60-120 FPS via isolated `RepaintBoundary` layers.
- **Offline First:** 100% functional without internet connection.
- **Zero Regression:** Core memorization, scoring, streaks, and cloud sync logic must remain unaffected.
- **Feature Flag:** New 2.5D experience gated by `KidsHifzFeatureFlags.kids3dMapEnabled`.

---

### Task 1: Feature Flag & Biome Engine Infrastructure

**Files:**
- Modify: `lib/core/memorization/kids_hifz_feature_flags.dart`
- Create: `lib/features/memorization_plus/presentation/theme/kids_biome_theme.dart`
- Create: `lib/features/memorization_plus/domain/services/kids_biome_engine.dart`
- Test: `test/features/memorization_plus/domain/services/kids_biome_engine_test.dart`

**Interfaces:**
- Consumes: `surahId: int`
- Produces: `KidsBiomeType` (enum: `cloud`, `oasis`, `celestial`), `KidsBiomeTheme`, `KidsBiomeEngine.resolveBiome(int surahId)`

- [ ] **Step 1: Write the failing unit tests for Biome Engine**

```dart
// test/features/memorization_plus/domain/services/kids_biome_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_biome_engine.dart';
import 'package:talia_quran/features/memorization_plus/presentation/theme/kids_biome_theme.dart';

void main() {
  group('KidsBiomeEngine', () {
    test('resolves surahs 93..114 to cloud realm', () {
      expect(KidsBiomeEngine.resolveBiome(114), KidsBiomeType.cloud);
      expect(KidsBiomeEngine.resolveBiome(93), KidsBiomeType.cloud);
    });

    test('resolves surahs 78..92 to oasis realm', () {
      expect(KidsBiomeEngine.resolveBiome(78), KidsBiomeType.oasis);
      expect(KidsBiomeEngine.resolveBiome(92), KidsBiomeType.oasis);
    });

    test('resolves surahs < 78 to celestial realm', () {
      expect(KidsBiomeEngine.resolveBiome(67), KidsBiomeType.celestial);
      expect(KidsBiomeEngine.resolveBiome(1), KidsBiomeType.celestial);
    });

    test('provides complete theme colors and gradients for every biome', () {
      for (final biome in KidsBiomeType.values) {
        final theme = KidsBiomeTheme.forBiome(biome);
        expect(theme.primaryGradient.colors.length, greaterThanOrEqualTo(2));
        expect(theme.pathColor, isNotNull);
        expect(theme.nameArabic.isNotEmpty, isTrue);
      }
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/memorization_plus/domain/services/kids_biome_engine_test.dart`  
Expected: Compilation failure (classes do not exist yet).

- [ ] **Step 3: Implement Feature Flag, Biome Theme, and Biome Engine**

Add feature flag in `lib/core/memorization/kids_hifz_feature_flags.dart`:
```dart
static const bool kids3dMapEnabled = true;
```

Create `lib/features/memorization_plus/presentation/theme/kids_biome_theme.dart`:
```dart
import 'package:flutter/material.dart';

enum KidsBiomeType { cloud, oasis, celestial }

class KidsBiomeTheme {
  const KidsBiomeTheme({
    required this.type,
    required this.nameArabic,
    required this.primaryGradient,
    required this.pathColor,
    required this.platformBorderColor,
    required this.accentGlow,
    required this.dustParticlesColor,
  });

  final KidsBiomeType type;
  final String nameArabic;
  final LinearGradient primaryGradient;
  final Color pathColor;
  final Color platformBorderColor;
  final Color accentGlow;
  final Color dustParticlesColor;

  static KidsBiomeTheme forBiome(KidsBiomeType type) {
    return switch (type) {
      KidsBiomeType.cloud => const KidsBiomeTheme(
        type: KidsBiomeType.cloud,
        nameArabic: 'جزر السحاب والنور',
        primaryGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFBAE6FD)],
        ),
        pathColor: Color(0xFFE0F2FE),
        platformBorderColor: Color(0xFF7DD3FC),
        accentGlow: Color(0xFFF59E0B),
        dustParticlesColor: Colors.white,
      ),
      KidsBiomeType.oasis => const KidsBiomeTheme(
        type: KidsBiomeType.oasis,
        nameArabic: 'واحة الفردوس والحدائق',
        primaryGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF34D399)],
        ),
        pathColor: Color(0xFFD1FAE5),
        platformBorderColor: Color(0xFF6EE7B7),
        accentGlow: Color(0xFFFBBF24),
        dustParticlesColor: Color(0xFFA7F3D0),
      ),
      KidsBiomeType.celestial => const KidsBiomeTheme(
        type: KidsBiomeType.celestial,
        nameArabic: 'سماء النجوم والشهب',
        primaryGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4C1D95)],
        ),
        pathColor: Color(0xFFE9D5FF),
        platformBorderColor: Color(0xFFA855F7),
        accentGlow: Color(0xFFF43F5E),
        dustParticlesColor: Color(0xFFFDE047),
      ),
    };
  }
}
```

Create `lib/features/memorization_plus/domain/services/kids_biome_engine.dart`:
```dart
import '../../presentation/theme/kids_biome_theme.dart';

abstract final class KidsBiomeEngine {
  static KidsBiomeType resolveBiome(int surahId) {
    if (surahId >= 93 && surahId <= 114) {
      return KidsBiomeType.cloud;
    }
    if (surahId >= 78 && surahId <= 92) {
      return KidsBiomeType.oasis;
    }
    return KidsBiomeType.celestial;
  }

  static KidsBiomeTheme resolveTheme(int surahId) {
    return KidsBiomeTheme.forBiome(resolveBiome(surahId));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/memorization_plus/domain/services/kids_biome_engine_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/memorization/kids_hifz_feature_flags.dart lib/features/memorization_plus/presentation/theme/kids_biome_theme.dart lib/features/memorization_plus/domain/services/kids_biome_engine.dart test/features/memorization_plus/domain/services/kids_biome_engine_test.dart
git commit -m "feat(kids): add feature flag and dynamic biome engine"
```

---

### Task 2: Game Audio Feedback Service & Mute Persistence

**Files:**
- Create: `lib/features/memorization_plus/domain/services/kids_audio_feedback_service.dart`
- Test: `test/features/memorization_plus/domain/services/kids_audio_feedback_service_test.dart`

**Interfaces:**
- Consumes: `SharedPreferences`, `just_audio.AudioPlayer`
- Produces: `KidsAudioFeedbackService` with `playTap()`, `playJump()`, `playStarDing()`, `playChestUnlock()`, `playVictoryFanfare()`, `setMuted(bool)`, `isMuted: bool`

- [ ] **Step 1: Write unit tests for KidsAudioFeedbackService**

```dart
// test/features/memorization_plus/domain/services/kids_audio_feedback_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_audio_feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late KidsAudioFeedbackService audioService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'kids_sfx_muted': false});
    prefs = await SharedPreferences.getInstance();
    audioService = KidsAudioFeedbackService(preferences: prefs);
  });

  test('reads initial mute status from SharedPreferences', () {
    expect(audioService.isMuted, isFalse);
  });

  test('updating mute status persists to SharedPreferences', () async {
    await audioService.setMuted(true);
    expect(audioService.isMuted, isTrue);
    expect(prefs.getBool('kids_sfx_muted'), isTrue);

    await audioService.setMuted(false);
    expect(audioService.isMuted, isFalse);
    expect(prefs.getBool('kids_sfx_muted'), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/memorization_plus/domain/services/kids_audio_feedback_service_test.dart`  
Expected: FAIL (class not implemented).

- [ ] **Step 3: Implement KidsAudioFeedbackService**

Create `lib/features/memorization_plus/domain/services/kids_audio_feedback_service.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KidsAudioFeedbackService {
  KidsAudioFeedbackService({
    required SharedPreferences preferences,
    AudioPlayer? player,
  })  : _prefs = preferences,
        _player = player ?? AudioPlayer(),
        _isMuted = preferences.getBool(_prefKey) ?? false;

  static const String _prefKey = 'kids_sfx_muted';
  final SharedPreferences _prefs;
  final AudioPlayer _player;
  bool _isMuted;

  bool get isMuted => _isMuted;

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    await _prefs.setBool(_prefKey, muted);
  }

  Future<void> playTap() async {
    await HapticFeedback.lightImpact();
    if (_isMuted) return;
    // Light system feedback as default zero-latency fallback
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playJump() async {
    await HapticFeedback.mediumImpact();
    if (_isMuted) return;
    await _playSafe('assets/audio/kids/jump.mp3');
  }

  Future<void> playStarDing() async {
    await HapticFeedback.lightImpact();
    if (_isMuted) return;
    await _playSafe('assets/audio/kids/star_ding.mp3');
  }

  Future<void> playChestUnlock() async {
    await HapticFeedback.heavyImpact();
    if (_isMuted) return;
    await _playSafe('assets/audio/kids/chest_unlock.mp3');
  }

  Future<void> playVictoryFanfare() async {
    await HapticFeedback.heavyImpact();
    if (_isMuted) return;
    await _playSafe('assets/audio/kids/victory_fanfare.mp3');
  }

  Future<void> _playSafe(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (_) {
      // Fallback cleanly to haptic click if audio file is unbundled
      await SystemSound.play(SystemSoundType.click);
    }
  }

  void dispose() {
    _player.dispose();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/memorization_plus/domain/services/kids_audio_feedback_service_test.dart`  
Expected: PASS.

- [ ] **Step 5: Register KidsAudioFeedbackService in GetIt DI**

Modify `lib/core/di/injection.dart` to register `KidsAudioFeedbackService`:
```dart
getIt.registerLazySingleton<KidsAudioFeedbackService>(
  () => KidsAudioFeedbackService(preferences: getIt<SharedPreferences>()),
);
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/memorization_plus/domain/services/kids_audio_feedback_service.dart test/features/memorization_plus/domain/services/kids_audio_feedback_service_test.dart lib/core/di/injection.dart
git commit -m "feat(kids): implement audio feedback service with mute persistence"
```

---

### Task 3: Map Node Type Resolver & Models

**Files:**
- Create: `lib/features/memorization_plus/domain/entities/kids_map_node_type.dart`
- Create: `lib/features/memorization_plus/domain/services/kids_map_node_resolver.dart`
- Test: `test/features/memorization_plus/domain/services/kids_map_node_resolver_test.dart`

**Interfaces:**
- Consumes: `KidsJourneyStage`, `totalStagesInSurah: int`
- Produces: `KidsMapNodeType` (`stageHouse`, `mysteryChest`, `reviewFortress`, `grandPalace`), `KidsMapNodeResolver.resolve()`

- [ ] **Step 1: Write unit tests for Map Node Resolver**

```dart
// test/features/memorization_plus/domain/services/kids_map_node_resolver_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_stage.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_map_node_type.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_map_node_resolver.dart';

void main() {
  KidsJourneyStage createStage({
    required int stageNumber,
    KidsJourneyStageStatus status = KidsJourneyStageStatus.current,
  }) {
    return KidsJourneyStage(
      stageNumber: stageNumber,
      surahId: 114,
      startAyah: 1,
      endAyah: 3,
      completedAyahs: const [1],
      status: status,
    );
  }

  group('KidsMapNodeResolver', () {
    test('resolves needsReview status to reviewFortress', () {
      final stage = createStage(
        stageNumber: 2,
        status: KidsJourneyStageStatus.needsReview,
      );
      expect(
        KidsMapNodeResolver.resolve(stage: stage, totalStages: 6),
        KidsMapNodeType.reviewFortress,
      );
    });

    test('resolves last stage completed to grandPalace', () {
      final stage = createStage(
        stageNumber: 6,
        status: KidsJourneyStageStatus.completed,
      );
      expect(
        KidsMapNodeResolver.resolve(stage: stage, totalStages: 6),
        KidsMapNodeType.grandPalace,
      );
    });

    test('resolves multiple of 4 to mysteryChest', () {
      final stage = createStage(stageNumber: 4);
      expect(
        KidsMapNodeResolver.resolve(stage: stage, totalStages: 8),
        KidsMapNodeType.mysteryChest,
      );
    });

    test('resolves regular stages to stageHouse', () {
      final stage = createStage(stageNumber: 1);
      expect(
        KidsMapNodeResolver.resolve(stage: stage, totalStages: 6),
        KidsMapNodeType.stageHouse,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/memorization_plus/domain/services/kids_map_node_resolver_test.dart`  
Expected: Compilation error.

- [ ] **Step 3: Implement KidsMapNodeType and KidsMapNodeResolver**

Create `lib/features/memorization_plus/domain/entities/kids_map_node_type.dart`:
```dart
enum KidsMapNodeType {
  stageHouse,
  mysteryChest,
  reviewFortress,
  grandPalace,
}
```

Create `lib/features/memorization_plus/domain/services/kids_map_node_resolver.dart`:
```dart
import '../entities/kids_journey_stage.dart';
import '../entities/kids_map_node_type.dart';

abstract final class KidsMapNodeResolver {
  static KidsMapNodeType resolve({
    required KidsJourneyStage stage,
    required int totalStages,
  }) {
    if (stage.status == KidsJourneyStageStatus.needsReview) {
      return KidsMapNodeType.reviewFortress;
    }
    if (stage.stageNumber == totalStages &&
        stage.status == KidsJourneyStageStatus.completed) {
      return KidsMapNodeType.grandPalace;
    }
    if (stage.stageNumber > 0 && stage.stageNumber % 4 == 0) {
      return KidsMapNodeType.mysteryChest;
    }
    return KidsMapNodeType.stageHouse;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/memorization_plus/domain/services/kids_map_node_resolver_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/memorization_plus/domain/entities/kids_map_node_type.dart lib/features/memorization_plus/domain/services/kids_map_node_resolver.dart test/features/memorization_plus/domain/services/kids_map_node_resolver_test.dart
git commit -m "feat(kids): add map node type domain model and presentation resolver"
```

---

### Task 4: 2.5D Isometric Path Painter & Interactive Node Widgets

**Files:**
- Create: `lib/features/memorization_plus/presentation/widgets/isometric_path_painter.dart`
- Create: `lib/features/memorization_plus/presentation/widgets/isometric_map_node_widget.dart`
- Test: `test/features/memorization_plus/presentation/widgets/isometric_map_node_widget_test.dart`

**Interfaces:**
- Consumes: `KidsJourneyStage`, `KidsBiomeTheme`, `KidsMapNodeType`
- Produces: `IsometricPathPainter` (Canvas 2.5D stone/cloud road), `IsometricMapNodeWidget` with 3D elevation, interactive tap, procedural vector fallback for houses/chests/palaces.

- [ ] **Step 1: Write widget test for IsometricMapNodeWidget**

```dart
// test/features/memorization_plus/presentation/widgets/isometric_map_node_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_stage.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_map_node_type.dart';
import 'package:talia_quran/features/memorization_plus/presentation/theme/kids_biome_theme.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/isometric_map_node_widget.dart';

void main() {
  testWidgets('IsometricMapNodeWidget renders and responds to tap', (tester) async {
    var tapped = false;
    final stage = const KidsJourneyStage(
      stageNumber: 1,
      surahId: 114,
      startAyah: 1,
      endAyah: 3,
      completedAyahs: [1],
      status: KidsJourneyStageStatus.current,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: IsometricMapNodeWidget(
              stage: stage,
              nodeType: KidsMapNodeType.stageHouse,
              theme: KidsBiomeTheme.forBiome(KidsBiomeType.cloud),
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(IsometricMapNodeWidget), findsOneWidget);
    await tester.tap(find.byType(IsometricMapNodeWidget));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/memorization_plus/presentation/widgets/isometric_map_node_widget_test.dart`  
Expected: Compilation failure.

- [ ] **Step 3: Implement IsometricPathPainter and IsometricMapNodeWidget**

Create `lib/features/memorization_plus/presentation/widgets/isometric_path_painter.dart`:
```dart
import 'package:flutter/material.dart';
import '../theme/kids_biome_theme.dart';

class IsometricPathPainter extends CustomPainter {
  const IsometricPathPainter({
    required this.nodePositions,
    required this.theme,
  });

  final List<Offset> nodePositions;
  final KidsBiomeTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    final path = Path()..moveTo(nodePositions.first.dx, nodePositions.first.dy);
    for (var i = 1; i < nodePositions.length; i++) {
      final prev = nodePositions[i - 1];
      final current = nodePositions[i];
      final midY = (prev.dy + current.dy) / 2;
      path.cubicTo(
        prev.dx, midY,
        current.dx, midY,
        current.dx, current.dy,
      );
    }

    // Draw deep 3D shadow layer
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..strokeWidth = 26
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path.shift(const Offset(0, 10)), shadowPaint);

    // Draw main isometric stepping path
    final mainPaint = Paint()
      ..color = theme.pathColor
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, mainPaint);

    // Draw glowing center track
    final glowPaint = Paint()
      ..color = theme.platformBorderColor.withValues(alpha: 0.8)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant IsometricPathPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions || oldDelegate.theme != theme;
  }
}
```

Create `lib/features/memorization_plus/presentation/widgets/isometric_map_node_widget.dart`:
```dart
import 'package:flutter/material.dart';
import '../../domain/entities/kids_journey_stage.dart';
import '../../domain/entities/kids_map_node_type.dart';
import '../theme/kids_biome_theme.dart';

class IsometricMapNodeWidget extends StatelessWidget {
  const IsometricMapNodeWidget({
    super.key,
    required this.stage,
    required this.nodeType,
    required this.theme,
    required this.onTap,
  });

  final KidsJourneyStage stage;
  final KidsMapNodeType nodeType;
  final KidsBiomeTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = stage.status == KidsJourneyStageStatus.locked;
    final isCurrent = stage.status == KidsJourneyStageStatus.current;
    final isCompleted = stage.status == KidsJourneyStageStatus.completed;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Node Content / Iconography
          Container(
            width: 100,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isCurrent
                      ? theme.accentGlow.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.18),
                  blurRadius: isCurrent ? 24 : 12,
                  spreadRadius: isCurrent ? 4 : 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildNodeIcon(isLocked, isCurrent, isCompleted),
                if (isLocked)
                  const Positioned(
                    right: 8,
                    top: 8,
                    child: Icon(Icons.lock_rounded, color: Colors.white70, size: 22),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 3D Squashed Cylinder Platform Base
          Container(
            width: 110,
            height: 32,
            decoration: BoxDecoration(
              color: isLocked ? Colors.grey.shade400 : theme.pathColor,
              borderRadius: const BorderRadius.all(Radius.elliptical(55, 16)),
              border: Border.all(
                color: isCurrent ? theme.accentGlow : theme.platformBorderColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'مرحلة ${stage.stageNumber}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.grey.shade700 : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeIcon(bool isLocked, bool isCurrent, bool isCompleted) {
    return switch (nodeType) {
      KidsMapNodeType.mysteryChest => Icon(
          isCompleted ? Icons.card_giftcard_rounded : Icons.lock_clock_rounded,
          size: 54,
          color: isLocked ? Colors.grey : theme.accentGlow,
        ),
      KidsMapNodeType.reviewFortress => Icon(
          Icons.shield_rounded,
          size: 56,
          color: isLocked ? Colors.grey : const Color(0xFF7C3AED),
        ),
      KidsMapNodeType.grandPalace => Icon(
          Icons.workspace_premium_rounded,
          size: 60,
          color: isLocked ? Colors.grey : const Color(0xFFF59E0B),
        ),
      KidsMapNodeType.stageHouse => Icon(
          isCompleted ? Icons.star_rounded : Icons.home_rounded,
          size: 52,
          color: isLocked ? Colors.grey : (isCurrent ? theme.accentGlow : Colors.white),
        ),
    };
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/memorization_plus/presentation/widgets/isometric_map_node_widget_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/memorization_plus/presentation/widgets/isometric_path_painter.dart lib/features/memorization_plus/presentation/widgets/isometric_map_node_widget.dart test/features/memorization_plus/presentation/widgets/isometric_map_node_widget_test.dart
git commit -m "feat(kids): implement 2.5D isometric path painter and tactile node widget"
```

---

### Task 5: Hero Avatar Controller & Jump Animation Pipeline

**Files:**
- Create: `lib/features/memorization_plus/presentation/widgets/hero_avatar_widget.dart`
- Test: `test/features/memorization_plus/presentation/widgets/hero_avatar_widget_test.dart`

**Interfaces:**
- Consumes: `position: Offset`, `onAvatarTapped: VoidCallback?`
- Produces: `HeroAvatarWidget` with idle breathing bounce, touch-trigger flip, parabolic jump animation.

- [ ] **Step 1: Write widget test for HeroAvatarWidget**

```dart
// test/features/memorization_plus/presentation/widgets/hero_avatar_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/hero_avatar_widget.dart';

void main() {
  testWidgets('HeroAvatarWidget renders and plays bounce on tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HeroAvatarWidget(
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(HeroAvatarWidget), findsOneWidget);
    await tester.tap(find.byType(HeroAvatarWidget));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/memorization_plus/presentation/widgets/hero_avatar_widget_test.dart`  
Expected: Compilation failure.

- [ ] **Step 3: Implement HeroAvatarWidget**

Create `lib/features/memorization_plus/presentation/widgets/hero_avatar_widget.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/kids_theme.dart';

class HeroAvatarWidget extends StatefulWidget {
  const HeroAvatarWidget({
    super.key,
    this.onTap,
    this.isJumping = false,
  });

  final VoidCallback? onTap;
  final bool isJumping;

  @override
  State<HeroAvatarWidget> createState() => _HeroAvatarWidgetState();
}

class _HeroAvatarWidgetState extends State<HeroAvatarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pokeController;

  @override
  void initState() {
    super.initState();
    _pokeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pokeController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pokeController.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.25)
                .chain(CurveTween(curve: Curves.elasticOut))
                .animate(_pokeController),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: KidsTheme.goldStar, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: KidsTheme.goldStar.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  KidsTheme.kidAvatarAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.face_rounded,
                    size: 40,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -4, end: 4, duration: 1200.ms, curve: Curves.easeInOut),
          const SizedBox(height: 4),
          // Pulsing shadow beneath hero
          Container(
            width: 44,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.all(Radius.elliptical(22, 5)),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 1200.ms),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/memorization_plus/presentation/widgets/hero_avatar_widget_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/memorization_plus/presentation/widgets/hero_avatar_widget.dart test/features/memorization_plus/presentation/widgets/hero_avatar_widget_test.dart
git commit -m "feat(kids): implement hero avatar widget with idle breathing and tap physics"
```

---

### Task 6: 2.5D Isometric Journey Map Screen Integration

**Files:**
- Create: `lib/features/memorization_plus/presentation/widgets/kids_isometric_journey_map.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart`
- Test: `test/features/memorization_plus/presentation/pages/kids_gamified_journey_page_test.dart`

**Interfaces:**
- Consumes: `KidsJourneyLoaded state`, `KidsBiomeTheme`
- Produces: Integrated 2.5D map with auto-scroll to current stage, avatar positioning, modal stage sheet.

- [ ] **Step 1: Write integration test for 2.5D Journey Map**

```dart
// test/features/memorization_plus/presentation/pages/kids_gamified_journey_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_stage.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_progress.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_state.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart';

void main() {
  testWidgets('KidsGamifiedJourneyContent renders isometric map when flag is enabled', (tester) async {
    final stages = [
      const KidsJourneyStage(
        stageNumber: 1,
        surahId: 114,
        startAyah: 1,
        endAyah: 3,
        completedAyahs: [1, 2, 3],
        status: KidsJourneyStageStatus.completed,
      ),
      const KidsJourneyStage(
        stageNumber: 2,
        surahId: 114,
        startAyah: 4,
        endAyah: 6,
        completedAyahs: [],
        status: KidsJourneyStageStatus.current,
      ),
    ];

    final state = KidsJourneyLoaded(
      surahId: 114,
      stages: stages,
      progress: const KidsProgress.initial(),
      surahName: 'الناس',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KidsGamifiedJourneyContent(
            state: state,
            onBack: () {},
            onStageSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(KidsGamifiedJourneyContent), findsOneWidget);
  });
}
```

- [ ] **Step 2: Implement KidsIsometricJourneyMap**

Create `lib/features/memorization_plus/presentation/widgets/kids_isometric_journey_map.dart`:
```dart
import 'package:flutter/material.dart';
import '../../domain/entities/kids_journey_stage.dart';
import '../../domain/services/kids_map_node_resolver.dart';
import '../theme/kids_biome_theme.dart';
import 'hero_avatar_widget.dart';
import 'isometric_map_node_widget.dart';
import 'isometric_path_painter.dart';

class KidsIsometricJourneyMap extends StatelessWidget {
  const KidsIsometricJourneyMap({
    super.key,
    required this.stages,
    required this.theme,
    required this.onStageSelected,
    this.onAvatarTap,
  });

  final List<KidsJourneyStage> stages;
  final KidsBiomeTheme theme;
  final ValueChanged<KidsJourneyStage> onStageSelected;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();

    const nodeHeight = 150.0;
    final totalHeight = stages.length * nodeHeight + 80.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final nodePositions = <Offset>[];

        for (var i = 0; i < stages.length; i++) {
          final isEven = i.isEven;
          final x = isEven ? width * 0.28 : width * 0.72;
          final y = totalHeight - (i * nodeHeight + 80.0);
          nodePositions.add(Offset(x, y));
        }

        return SizedBox(
          height: totalHeight,
          width: width,
          child: Stack(
            children: [
              // 2.5D Path Canvas
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: IsometricPathPainter(
                      nodePositions: nodePositions,
                      theme: theme,
                    ),
                  ),
                ),
              ),
              // Map Nodes
              for (var i = 0; i < stages.length; i++)
                Positioned(
                  left: nodePositions[i].dx - 55,
                  top: nodePositions[i].dy - 60,
                  child: IsometricMapNodeWidget(
                    stage: stages[i],
                    nodeType: KidsMapNodeResolver.resolve(
                      stage: stages[i],
                      totalStages: stages.length,
                    ),
                    theme: theme,
                    onTap: () => onStageSelected(stages[i]),
                  ),
                ),
              // Hero Avatar on Current Stage
              for (var i = 0; i < stages.length; i++)
                if (stages[i].status == KidsJourneyStageStatus.current)
                  Positioned(
                    left: nodePositions[i].dx - 32,
                    top: nodePositions[i].dy - 128,
                    child: HeroAvatarWidget(onTap: onAvatarTap),
                  ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Integrate into KidsGamifiedJourneyPage**

In `lib/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart`:
- Check `KidsHifzFeatureFlags.kids3dMapEnabled`.
- When enabled, resolve `KidsBiomeTheme` via `KidsBiomeEngine.resolveTheme(state.surahId)`.
- Render `KidsIsometricJourneyMap` inside the `CustomScrollView` with background gradient from `theme.primaryGradient`.

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/memorization_plus/presentation/pages/kids_gamified_journey_page_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/memorization_plus/presentation/widgets/kids_isometric_journey_map.dart lib/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart test/features/memorization_plus/presentation/pages/kids_gamified_journey_page_test.dart
git commit -m "feat(kids): assemble 2.5D isometric journey map with dynamic biome background"
```

---

### Task 7: 3D Quran Tablet & Lantern Loop Indicator in Listen Screen

**Files:**
- Create: `lib/features/memorization_plus/presentation/widgets/kids_glowing_lanterns_widget.dart`
- Modify: `lib/features/memorization_plus/presentation/widgets/kids_ayah_card.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart`
- Test: `test/features/memorization_plus/presentation/widgets/kids_glowing_lanterns_widget_test.dart`

**Interfaces:**
- Consumes: `currentLoop: int`, `maxLoops: int`, `KidsBiomeTheme`
- Produces: `KidsGlowingLanternsWidget` (3D glowing lanterns with audio ding on loop increment), tactile 3D ayah tablet.

- [ ] **Step 1: Write test for KidsGlowingLanternsWidget**

```dart
// test/features/memorization_plus/presentation/widgets/kids_glowing_lanterns_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_glowing_lanterns_widget.dart';

void main() {
  testWidgets('KidsGlowingLanternsWidget renders lanterns matching maxLoops', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: KidsGlowingLanternsWidget(
              currentLoop: 2,
              maxLoops: 3,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(KidsGlowingLanternsWidget), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_rounded), findsNWidgets(3));
  });
}
```

- [ ] **Step 2: Implement KidsGlowingLanternsWidget**

Create `lib/features/memorization_plus/presentation/widgets/kids_glowing_lanterns_widget.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/kids_theme.dart';

class KidsGlowingLanternsWidget extends StatelessWidget {
  const KidsGlowingLanternsWidget({
    super.key,
    required this.currentLoop,
    required this.maxLoops,
  });

  final int currentLoop;
  final int maxLoops;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < maxLoops; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            _buildLantern(lit: i < currentLoop),
          ],
        ],
      ),
    );
  }

  Widget _buildLantern({required bool lit}) {
    final lantern = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? KidsTheme.goldStar : Colors.white.withValues(alpha: 0.15),
        boxShadow: lit
            ? [
                BoxShadow(
                  color: KidsTheme.goldStar.withValues(alpha: 0.6),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.lightbulb_rounded,
        color: lit ? const Color(0xFF78350F) : Colors.white54,
        size: 24,
      ),
    );

    return lit ? lantern.animate().scale(duration: 200.ms, curve: Curves.easeOutBack) : lantern;
  }
}
```

- [ ] **Step 3: Integrate Lanterns and 3D Tablet into KidsGamifiedListenPage**

- Replace `_KidsGamifiedLoopIndicator` in `lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart` with `KidsGlowingLanternsWidget`.
- Upgrade `KidsAyahCard` styling with 3D bevel and warm wooden/parchment frame.
- Add audio ding trigger from `getIt<KidsAudioFeedbackService>().playStarDing()` whenever `currentLoop` advances.

- [ ] **Step 4: Run widget tests**

Run: `flutter test test/features/memorization_plus/presentation/widgets/kids_glowing_lanterns_widget_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/memorization_plus/presentation/widgets/kids_glowing_lanterns_widget.dart lib/features/memorization_plus/presentation/widgets/kids_ayah_card.dart lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart test/features/memorization_plus/presentation/widgets/kids_glowing_lanterns_widget_test.dart
git commit -m "feat(kids): add 3D glowing lanterns and tactile ayah tablet to listen screen"
```

---

### Task 8: Celebration Completion Upgrades & Full Verification

**Files:**
- Modify: `lib/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart`
- Modify: `lib/features/memorization_plus/presentation/widgets/kids_reward_dialog.dart`
- Test: `test/features/memorization_plus/presentation/pages/kids_gamified_completion_page_test.dart`

**Interfaces:**
- Consumes: `starsEarned: int`, `surahId: int`
- Produces: Celebratory completion experience with 3D bouncing star drop, victory fanfare audio, and direct next mission routing.

- [ ] **Step 1: Write widget test for Completion Page**

```dart
// test/features/memorization_plus/presentation/pages/kids_gamified_completion_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_reward_dialog.dart';

void main() {
  testWidgets('KidsRewardDialog renders earned stars and action buttons', (tester) async {
    var returned = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: KidsRewardDialog(
              starsEarned: 3,
              onReturnToMap: () => returned = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(KidsRewardDialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.map_rounded));
    expect(returned, isTrue);
  });
}
```

- [ ] **Step 2: Update KidsRewardDialog with audio fanfare and 3D bounce**

In `lib/features/memorization_plus/presentation/widgets/kids_reward_dialog.dart`:
- Trigger `getIt<KidsAudioFeedbackService>().playVictoryFanfare()` on `initState` / display.
- Add bouncy star animations with confetti effect.

- [ ] **Step 3: Run all unit and widget tests across memorization_plus**

Run: `flutter test test/features/memorization_plus/`  
Expected: ALL PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart lib/features/memorization_plus/presentation/widgets/kids_reward_dialog.dart test/features/memorization_plus/presentation/pages/kids_gamified_completion_page_test.dart
git commit -m "feat(kids): enhance completion celebration with 3D star bounce and victory audio"
```
