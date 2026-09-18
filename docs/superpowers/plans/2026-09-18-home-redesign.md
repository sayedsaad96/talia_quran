# Home Page UI/UX Overhaul — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Talia Quran home page into a Modern Islamic Luxury interface — context-driven, spiritually minimalist, with premium animations and zero redundant navigation.

**Architecture:** Presentation-layer only overhaul. No `HomeCubit`/`HomeState` changes. Update `HomeSkin` with new tokens, create reusable animation utilities, then modify each widget section top-to-bottom. Remove `HomeActionTiles` and `HomeQuickAccess` from the layout. Merge `HomeDailyChallengeCard` + `HomeJourneyRingCard` + `HomeMomentumStrip` into a unified panel.

**Tech Stack:** Flutter/Dart, BLoC (`flutter_bloc`), `go_router`, existing `HomeSkin` theming system, `GlassPanel` glass-morphism component.

**Spec:** [`docs/superpowers/specs/2026-09-18-home-redesign-design.md`](file:///d:/Flutter/talia_quran/docs/superpowers/specs/2026-09-18-home-redesign-design.md)

## Global Constraints

- Flutter SDK (current project version)
- No new pub dependencies — use only `dart:ui`, `package:flutter/...`, and existing project packages
- All animations must check `MediaQuery.disableAnimationsOf(context)` before running
- All layouts must work in both RTL (Arabic) and LTR (English)
- All text over the mosque banner must meet WCAG AA contrast ratio ≥ 4.5:1
- Existing `HomeCubit` / `HomeState` logic must NOT be modified
- Follow existing `HomeSkin` / `GlassPanel` / `AppTypography` / `AppSpacing` patterns
- Hot-reload after every Dart file edit via `dtd` + `hot_reload` MCP tools
- No existing Islamic geometric pattern assets exist — patterns must be painted via `CustomPainter`

---

### Task 1: Expand `HomeSkin` with New Design Tokens

**Files:**
- Modify: `lib/features/home/presentation/theme/home_skin.dart`

**Interfaces:**
- Consumes: `AppColors` color constants
- Produces: 6 new `HomeSkin` fields available to all downstream widgets: `meshGradient`, `editorialBackground`, `consolidatedBadgeFill`, `consolidatedBadgeBorder`, `heroCardTexture`, `springCurve`

- [ ] **Step 1: Add 6 new fields to `HomeSkin` class**

Add after the existing `shadow` field (line 60):

```dart
  /// Mesh-like gradient for the Hero Card background.
  final LinearGradient meshGradient;

  /// Subtle background for the editorial Ayah of the Day section.
  final Color editorialBackground;

  /// Glass fill for the consolidated status badge in the header.
  final Color consolidatedBadgeFill;

  /// Border for the consolidated status badge.
  final Color consolidatedBadgeBorder;

  /// Opacity for the faint Islamic geometric pattern overlay on Hero Card.
  final double heroCardTextureOpacity;

  /// Unified spring animation curve for tactile interactions.
  static const Curve springCurve = Curves.easeOutBack;

  /// Spring animation duration for tactile press feedback.
  static const Duration springDuration = Duration(milliseconds: 200);
```

Update the constructor to include these fields as `required`.

- [ ] **Step 2: Add values to the dark factory**

Inside the `if (isDark)` branch of `forBrightness`:

```dart
meshGradient: const LinearGradient(
  begin: AlignmentDirectional.topStart,
  end: AlignmentDirectional.bottomEnd,
  colors: [Color(0xFF12655A), Color(0xFF0A3D36), Color(0xFF06312B)],
  stops: [0.0, 0.5, 1.0],
),
editorialBackground: Colors.white.withValues(alpha: 0.03),
consolidatedBadgeFill: Colors.white.withValues(alpha: 0.12),
consolidatedBadgeBorder: Colors.white.withValues(alpha: 0.18),
heroCardTextureOpacity: 0.06,
```

- [ ] **Step 3: Add values to the light factory**

Inside the light-mode return:

```dart
meshGradient: const LinearGradient(
  begin: AlignmentDirectional.topStart,
  end: AlignmentDirectional.bottomEnd,
  colors: [Color(0xFF0D5C53), Color(0xFF094A43), Color(0xFF06332E)],
  stops: [0.0, 0.5, 1.0],
),
editorialBackground: AppColors.primary.withValues(alpha: 0.03),
consolidatedBadgeFill: AppColors.primary.withValues(alpha: 0.08),
consolidatedBadgeBorder: AppColors.primary.withValues(alpha: 0.14),
heroCardTextureOpacity: 0.04,
```

- [ ] **Step 4: Verify compilation**

Run: `dart analyze lib/features/home/presentation/theme/home_skin.dart`
Expected: No errors (warnings about unused fields are acceptable at this stage).

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/theme/home_skin.dart
git commit -m "feat(home): expand HomeSkin with 6 new design tokens for redesign"
```

---

### Task 2: Create Reusable Animation Utilities

**Files:**
- Create: `lib/features/home/presentation/widgets/spring_tap.dart`
- Create: `lib/features/home/presentation/widgets/staggered_fade_slide.dart`

**Interfaces:**
- Consumes: `HomeSkin.springCurve`, `HomeSkin.springDuration`
- Produces: `SpringTap` widget (wraps any child with spring scale-on-press), `StaggeredFadeSlide` widget (wraps any child with delayed fade+slide entry)

- [ ] **Step 1: Create `SpringTap` widget**

```dart
// lib/features/home/presentation/widgets/spring_tap.dart
import 'package:flutter/material.dart';

import '../theme/home_skin.dart';

/// Wraps [child] in a tactile spring-scale animation on press.
/// Scale drops to [pressedScale] on tap-down, returns on tap-up/cancel.
class SpringTap extends StatefulWidget {
  const SpringTap({
    super.key,
    required this.onTap,
    required this.child,
    this.pressedScale = 0.98,
  });

  final VoidCallback onTap;
  final Widget child;
  final double pressedScale;

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: HomeSkin.springDuration,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _controller, curve: HomeSkin.springCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return GestureDetector(onTap: widget.onTap, child: widget.child);
    }
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
```

- [ ] **Step 2: Create `StaggeredFadeSlide` widget**

```dart
// lib/features/home/presentation/widgets/staggered_fade_slide.dart
import 'package:flutter/material.dart';

/// Wraps [child] in a one-shot fade + slide-up animation with a
/// configurable [delay] for staggered cascade effects.
class StaggeredFadeSlide extends StatefulWidget {
  const StaggeredFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.offsetY = 20.0,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _offset = Tween<Offset>(
      begin: Offset(0, widget.offsetY),
      end: Offset.zero,
    ).animate(curved);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(offset: _offset.value, child: child),
      ),
      child: widget.child,
    );
  }
}
```

- [ ] **Step 3: Verify compilation**

Run: `dart analyze lib/features/home/presentation/widgets/spring_tap.dart lib/features/home/presentation/widgets/staggered_fade_slide.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/presentation/widgets/spring_tap.dart lib/features/home/presentation/widgets/staggered_fade_slide.dart
git commit -m "feat(home): add SpringTap and StaggeredFadeSlide animation utilities"
```

---

### Task 3: Create Islamic Geometric Pattern Painter

**Files:**
- Create: `lib/features/home/presentation/widgets/islamic_pattern_painter.dart`

**Interfaces:**
- Consumes: A `Color` and `opacity` value
- Produces: `IslamicPatternOverlay` widget that renders a subtle repeating geometric pattern via `CustomPainter`

- [ ] **Step 1: Create the CustomPainter and overlay widget**

```dart
// lib/features/home/presentation/widgets/islamic_pattern_painter.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints a subtle repeating Islamic 8-point star pattern.
/// Used as a faint texture overlay on the Hero Card.
class IslamicPatternPainter extends CustomPainter {
  IslamicPatternPainter({required this.color, required this.opacity});

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const tileSize = 48.0;
    final cols = (size.width / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cx = col * tileSize + tileSize / 2;
        final cy = row * tileSize + tileSize / 2;
        _drawStar(canvas, Offset(cx, cy), tileSize * 0.38, paint);
      }
    }
  }

  /// Draws an 8-point star at [center] with the given [radius].
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 8;
    final innerRadius = radius * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final angle = (math.pi * i / points) - math.pi / 2;
      final r = i.isEven ? radius : innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(IslamicPatternPainter oldDelegate) =>
      color != oldDelegate.color || opacity != oldDelegate.opacity;
}

/// Positioned overlay that paints the Islamic pattern on the right edge.
class IslamicPatternOverlay extends StatelessWidget {
  const IslamicPatternOverlay({
    super.key,
    required this.color,
    required this.opacity,
  });

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRect(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SizedBox(
              width: 160,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: AlignmentDirectional.centerEnd,
                  end: AlignmentDirectional.centerStart,
                  colors: [Colors.white, Colors.transparent],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: CustomPaint(
                  painter: IslamicPatternPainter(
                    color: color,
                    opacity: opacity,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `dart analyze lib/features/home/presentation/widgets/islamic_pattern_painter.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/presentation/widgets/islamic_pattern_painter.dart
git commit -m "feat(home): add Islamic geometric pattern CustomPainter overlay"
```

---

### Task 4: Redesign Header — Consolidated Badge & Top Bar

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_night_header.dart`

**Interfaces:**
- Consumes: `HomeSkin` (including new `consolidatedBadgeFill`, `consolidatedBadgeBorder`), `HomeLoaded` state, `StaggeredFadeSlide`
- Produces: Restructured `HomeNightHeader` with centered logo, symmetrical icon row, and single consolidated badge replacing scattered chips

- [ ] **Step 1: Restructure `HomeNightHeader.build()` — replace chips with consolidated badge**

Replace the current `Wrap` of chips (lines 62-67) with a single consolidated glass pill:

```dart
// Replace the Wrap(children: chips) section with:
_ConsolidatedBadge(state: state, skin: skin),
```

- [ ] **Step 2: Restructure `_TopRow` — symmetrical layout**

Modify `_TopRow` to place the logo center with icons on both sides. Remove the profile avatar + name from the top row (it moves into the consolidated badge or is removed). Keep Search and Settings icons:

```dart
@override
Widget build(BuildContext context) {
  return Row(
    children: [
      _HeaderIcon(
        skin: skin,
        tooltip: context.l10n.searchSurah,
        icon: Icons.search_rounded,
        onTap: () => context.push(AppRoutes.quranSearch),
      ),
      const Spacer(),
      Image.asset(
        HomeSkin.logoAsset,
        width: 72,
        height: 72,
        cacheWidth: 150,
        cacheHeight: 150,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) =>
            Icon(Icons.menu_book_rounded, color: skin.gold, size: 36),
      ),
      const Spacer(),
      _HeaderIcon(
        skin: skin,
        tooltip: context.l10n.settings,
        icon: Icons.settings_suggest_rounded,
        onTap: () => context.push(AppRoutes.settings),
      ),
    ],
  );
}
```

- [ ] **Step 3: Remove `_BrandLockup` — logo now lives in `_TopRow`**

Delete the `_BrandLockup` widget class entirely. Remove `_BrandLockup(skin: skin)` and its `SizedBox(height: AppSpacing.sm)` from `HomeNightHeader.build()`.

- [ ] **Step 4: Create `_ConsolidatedBadge` widget**

```dart
class _ConsolidatedBadge extends StatelessWidget {
  const _ConsolidatedBadge({required this.state, required this.skin});

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];

    // Occasion
    if (state.occasion != HomeOccasion.none) {
      parts.add(switch (state.occasion) {
        HomeOccasion.friday => context.l10n.homeOccasionFriday,
        HomeOccasion.ramadan => context.l10n.homeOccasionRamadan,
        HomeOccasion.lastTenNights => context.l10n.homeOccasionLastTenNights,
        HomeOccasion.none => '',
      });
    }

    // Hijri date
    if (state.hijriLabel.isNotEmpty) {
      parts.add(state.hijriLabel);
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: skin.consolidatedBadgeFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: skin.consolidatedBadgeBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nights_stay_rounded, size: 14, color: skin.gold),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                parts.join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: skin.textOnHero,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Move `HomeAchievementChip` into consolidated badge or remove from header**

Remove `HomeAchievementChip` from the header chips area. It will be shown inside the Unified Progress Panel (Task 7) instead.

- [ ] **Step 6: Verify compilation and hot-reload**

Run: `dart analyze lib/features/home/presentation/widgets/home_night_header.dart`
Expected: No errors. Hot-reload to verify visual result.

- [ ] **Step 7: Commit**

```bash
git add lib/features/home/presentation/widgets/home_night_header.dart
git commit -m "feat(home): redesign header with centered logo, consolidated badge"
```

---

### Task 5: Redesign Hero Card with Spring Physics & Texture

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_continue_card.dart`
- Modify: `lib/features/home/presentation/widgets/home_start_khatmah_card.dart`

**Interfaces:**
- Consumes: `HomeSkin` (including `meshGradient`, `heroCardTextureOpacity`), `SpringTap`, `IslamicPatternOverlay`, `StaggeredFadeSlide`
- Produces: Visually upgraded Hero Cards with mesh gradient, geometric texture, spring tap feedback, and staggered entry

- [ ] **Step 1: Update `HomeContinueCard` — replace gradient with mesh gradient**

In `HomeContinueCard.build()`, replace the `gradient: skin.heroGradient` on the `Ink` with `gradient: skin.meshGradient`.

- [ ] **Step 2: Add Islamic pattern overlay to `HomeContinueCard`**

Inside the `Stack` children of `HomeContinueCard`, add after the glow orb:

```dart
IslamicPatternOverlay(
  color: skin.textOnHero,
  opacity: skin.heroCardTextureOpacity,
),
```

- [ ] **Step 3: Upgrade Surah title typography in `HomeContinueCard`**

Change the Surah name text style from `AppTypography.displaySmall.copyWith(fontSize: 26, fontWeight: FontWeight.w800)` to:

```dart
AppTypography.displaySmall.copyWith(
  fontSize: 30,
  fontWeight: FontWeight.w700,
  color: skin.textOnHero,
  height: 1.3,
),
```

Change the Ayah/page number subtitle color to `skin.gold`.

- [ ] **Step 4: Wrap `HomeContinueCard` with `SpringTap`**

Replace the outer `InkWell` with `SpringTap`:

```dart
return SpringTap(
  onTap: () => context.push(recitation.route),
  child: /* existing card decoration */,
);
```

Remove the old `InkWell` and its `borderRadius`.

- [ ] **Step 5: Apply same changes to `HomeStartKhatmahCard`**

Apply the same upgrades:
- Replace `gradient: skin.heroGradient` with `gradient: skin.meshGradient`
- Add `IslamicPatternOverlay`
- Wrap with `SpringTap` instead of `InkWell`

- [ ] **Step 6: Verify compilation and hot-reload**

Run: `dart analyze lib/features/home/presentation/widgets/home_continue_card.dart lib/features/home/presentation/widgets/home_start_khatmah_card.dart`
Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/home/presentation/widgets/home_continue_card.dart lib/features/home/presentation/widgets/home_start_khatmah_card.dart
git commit -m "feat(home): upgrade hero cards with mesh gradient, texture, spring tap"
```

---

### Task 6: Contextual Slot with AnimatedSwitcher

**Files:**
- Modify: `lib/features/home/presentation/pages/home_page.dart` (the sliver wrapping `HomeContextualSlot`)

**Interfaces:**
- Consumes: `HomeLoaded.activeSlot`, `HomeContextualSlot`
- Produces: Smooth animated appearance/disappearance of the contextual slot

- [ ] **Step 1: Wrap `HomeContextualSlot` sliver with `AnimatedSwitcher`**

In `HomeLoadedView.build()`, replace the conditional sliver for `state.activeSlot != null` (lines 258-269):

```dart
SliverToBoxAdapter(
  child: AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );
    },
    child: state.activeSlot != null
        ? Padding(
            key: ValueKey(state.activeSlot!.kind),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              0,
            ),
            child: HomeContextualSlot(state: state, skin: skin),
          )
        : const SizedBox.shrink(key: ValueKey('empty_slot')),
  ),
),
```

- [ ] **Step 2: Verify compilation and hot-reload**

Run: `dart analyze lib/features/home/presentation/pages/home_page.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/presentation/pages/home_page.dart
git commit -m "feat(home): add AnimatedSwitcher to contextual slot for smooth transitions"
```

---

### Task 7: Unified Progress Panel (Merge 3 Widgets)

**Files:**
- Create: `lib/features/home/presentation/widgets/home_unified_progress.dart`

**Interfaces:**
- Consumes: `HomeLoaded` (for khatmah, progress, checklist, streak data), `HomeSkin`, `StreakCubit`/`StreakState`, `GlassPanel`, `SpringTap`
- Produces: `HomeUnifiedProgress` widget combining streak + journey ring + XP + achievement into a single Bento panel

- [ ] **Step 1: Create `HomeUnifiedProgress` widget**

```dart
// lib/features/home/presentation/widgets/home_unified_progress.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../streak/presentation/cubits/streak_cubit.dart';
import '../cubits/home_cubit.dart';
import '../theme/home_skin.dart';
import 'glass_panel.dart';
import 'spring_tap.dart';

/// Unified Bento-grid progress panel merging:
/// - Streak flame + weekly dots (from HomeMomentumStrip)
/// - Journey ring: memorization/khatmah circular progress (from HomeJourneyRingCard)
/// - XP + achievement level
class HomeUnifiedProgress extends StatelessWidget {
  const HomeUnifiedProgress({
    super.key,
    required this.state,
    required this.skin,
  });

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      skin: skin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top section: Streak + XP side-by-side
          Row(
            children: [
              // Streak flame
              _StreakSection(skin: skin),
              const SizedBox(width: AppSpacing.md),
              // XP counter
              _XpSection(totalXp: state.totalXp, skin: skin),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Divider
          Container(height: 1, color: skin.glassBorder),
          const SizedBox(height: AppSpacing.md),
          // Bottom section: Journey ring + weekly dots
          Row(
            children: [
              // Journey ring
              _JourneyRingCompact(state: state, skin: skin),
              const SizedBox(width: AppSpacing.md),
              // Weekly activity dots
              Expanded(child: _WeeklyDots(state: state, skin: skin)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakSection extends StatelessWidget {
  const _StreakSection({required this.skin});
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StreakCubit, StreakState>(
      builder: (context, streakState) {
        final days = streakState is StreakLoaded ? streakState.currentStreak : 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded,
                size: 22, color: AppColors.streakOrange),
            const SizedBox(width: 6),
            Text(
              '$days',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.streakOrange,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              context.l10n.streakDays,
              style: AppTypography.labelSmall.copyWith(
                color: skin.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _XpSection extends StatelessWidget {
  const _XpSection({required this.totalXp, required this.skin});
  final int totalXp;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 18, color: skin.gold),
        const SizedBox(width: 4),
        Text(
          '$totalXp XP',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: skin.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _JourneyRingCompact extends StatelessWidget {
  const _JourneyRingCompact({required this.state, required this.skin});
  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final progress = state.progress;
    final memPct = progress.totalAyahs > 0
        ? progress.memorizedAyahs / progress.totalAyahs
        : 0.0;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: memPct,
            strokeWidth: 5,
            color: skin.accent,
            backgroundColor: skin.progressTrack,
          ),
          Text(
            '${(memPct * 100).round()}%',
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: skin.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyDots extends StatelessWidget {
  const _WeeklyDots({required this.state, required this.skin});
  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final days = state.activityCountsByDay;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final active = i < days.length && days[i] > 0;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? skin.accent : skin.progressTrack,
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `dart analyze lib/features/home/presentation/widgets/home_unified_progress.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/presentation/widgets/home_unified_progress.dart
git commit -m "feat(home): create unified progress panel merging streak, journey ring, XP"
```

---

### Task 8: Editorial Ayah of the Day

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_ayah_of_day.dart`

**Interfaces:**
- Consumes: `AyahOfDay`, `HomeSkin` (including `editorialBackground`), `AppTypography.quranMedium`
- Produces: Upgraded `HomeAyahOfDayCard` with no card background, floating editorial typography, ghost-style action icons

- [ ] **Step 1: Replace `GlassPanel` container with transparent editorial layout**

Remove the `GlassPanel` wrapper. Replace with a simple `Padding` container with generous whitespace:

```dart
@override
Widget build(BuildContext context) {
  return SpringTap(
    onTap: () => context.push('/quran/page/${ayah.pageNumber}'),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          // Decorative quotation mark
          Text(
            '﴿',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 32,
              color: skin.gold.withValues(alpha: 0.5),
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Ayah text — editorial floating
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              ayah.text,
              textAlign: TextAlign.center,
              style: AppTypography.quranMedium.copyWith(
                fontSize: 24,
                height: 2.0,
                color: skin.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Closing quotation mark
          Text(
            '﴾',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 32,
              color: skin.gold.withValues(alpha: 0.5),
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Surah reference
          Text(
            surahRef,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: skin.gold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Ghost action icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GhostIcon(
                icon: Icons.play_circle_outline_rounded,
                skin: skin,
                onTap: () { /* listen */ },
              ),
              const SizedBox(width: AppSpacing.lg),
              _GhostIcon(
                icon: Icons.share_outlined,
                skin: skin,
                onTap: () { /* share */ },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 2: Create `_GhostIcon` helper**

```dart
class _GhostIcon extends StatelessWidget {
  const _GhostIcon({
    required this.icon,
    required this.skin,
    required this.onTap,
  });

  final IconData icon;
  final HomeSkin skin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      color: skin.textSecondary.withValues(alpha: 0.6),
      splashRadius: 20,
    );
  }
}
```

- [ ] **Step 3: Verify compilation and hot-reload**

Run: `dart analyze lib/features/home/presentation/widgets/home_ayah_of_day.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/presentation/widgets/home_ayah_of_day.dart
git commit -m "feat(home): redesign Ayah of Day as editorial floating typography"
```

---

### Task 9: First Run, Parent Children & Fallback Cards Upgrade

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_first_run.dart`
- Modify: `lib/features/home/presentation/widgets/resume_session_card.dart`
- Modify: `lib/features/home/presentation/widgets/next_best_action_card.dart`

**Interfaces:**
- Consumes: `HomeSkin`, `SpringTap`, `IslamicPatternOverlay`
- Produces: Visual consistency across all primary action variants

- [ ] **Step 1: Redesign `HomeFirstRun` as a luxury welcome card**

Replace the stacked buttons layout with a single Hero-style emerald card:

```dart
@override
Widget build(BuildContext context) {
  return SpringTap(
    onTap: () => context.push(AppRoutes.quran),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: skin.meshGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: skin.shadow,
      ),
      child: Stack(
        children: [
          IslamicPatternOverlay(
            color: skin.textOnHero,
            opacity: skin.heroCardTextureOpacity,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.homeWelcomeTitle,
                style: AppTypography.displaySmall.copyWith(
                  color: skin.textOnHero,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.homeWelcomeSubtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: skin.textOnHeroMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusFull,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    context.l10n.homeStartJourney,
                    style: AppTypography.labelMedium.copyWith(
                      color: skin.textOnHero,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

Note: `HomeFirstRun` will need `HomeSkin skin` as a parameter. Update its constructor accordingly.

- [ ] **Step 2: Upgrade `ResumeSessionCard` and `NextBestActionCard` visuals**

Apply the Hero Card visual treatment to both fallback cards:
- Replace the existing `Container` decoration with `gradient: skin.meshGradient` and `borderRadius: AppSpacing.radiusXl`
- Add `IslamicPatternOverlay`
- Wrap with `SpringTap`
- Update text colors to `skin.textOnHero` / `skin.textOnHeroMuted` / `skin.gold`

Both cards need `HomeSkin skin` as a constructor parameter.

- [ ] **Step 3: Verify compilation**

Run: `dart analyze lib/features/home/presentation/widgets/home_first_run.dart lib/features/home/presentation/widgets/resume_session_card.dart lib/features/home/presentation/widgets/next_best_action_card.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/presentation/widgets/home_first_run.dart lib/features/home/presentation/widgets/resume_session_card.dart lib/features/home/presentation/widgets/next_best_action_card.dart
git commit -m "feat(home): upgrade first-run and fallback cards to luxury hero style"
```

---

### Task 10: Restructure `HomeLoadedView` Layout — Remove Deprecated, Add Animations

**Files:**
- Modify: `lib/features/home/presentation/pages/home_page.dart`

**Interfaces:**
- Consumes: All upgraded widgets from Tasks 1-9, `StaggeredFadeSlide`, `HomeUnifiedProgress`
- Produces: Final restructured home page layout with correct widget ordering, deprecated widgets removed, staggered animations, and BouncingScrollPhysics

- [ ] **Step 1: Remove `HomeActionTiles` and `HomeQuickAccess` imports and slivers**

Remove these imports from `home_page.dart`:
```dart
// REMOVE:
import '../widgets/home_action_tiles.dart';
import '../widgets/home_quick_access.dart';
```

Remove the corresponding `SliverToBoxAdapter` entries for `HomeActionTiles` (lines 270-280) and `HomeQuickAccess` (lines 364-374) from the `slivers` list.

- [ ] **Step 2: Remove `HomeDailyChallengeCard` + `HomeJourneyRingCard` slivers and replace with `HomeUnifiedProgress`**

Remove the `LayoutBuilder` section (lines 281-322) that renders the side-by-side challenge/journey cards. Replace with:

```dart
SliverToBoxAdapter(
  child: StaggeredFadeSlide(
    delay: const Duration(milliseconds: 240),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        0,
      ),
      child: HomeUnifiedProgress(state: state, skin: skin),
    ),
  ),
),
```

- [ ] **Step 3: Add `HomeParentChildren` after the primary action area**

Insert after the `_PrimaryAction` sliver and before the Unified Progress panel:

```dart
if (state.familyChildren.isNotEmpty)
  SliverToBoxAdapter(
    child: StaggeredFadeSlide(
      delay: const Duration(milliseconds: 160),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.md,
          AppSpacing.pagePadding,
          0,
        ),
        child: HomeParentChildren(
          children: state.familyChildren,
          skin: skin,
        ),
      ),
    ),
  ),
```

Remove the old `HomeParentChildren` sliver from its previous position (lines 349-363).

- [ ] **Step 4: Wrap remaining slivers with `StaggeredFadeSlide`**

Wrap each remaining `SliverToBoxAdapter` content with `StaggeredFadeSlide`, incrementing delays by ~80ms:
- Primary Action: delay 0ms
- Parent Children: delay 160ms  
- Unified Progress: delay 240ms
- Ayah of Day: delay 320ms
- Activity Feed: delay 400ms

- [ ] **Step 5: Replace scroll physics**

In `HomeLoadedView.build()`, change:
```dart
physics: const AlwaysScrollableScrollPhysics(),
```
to:
```dart
physics: const BouncingScrollPhysics(
  parent: AlwaysScrollableScrollPhysics(),
),
```

- [ ] **Step 6: Update `HomeFirstRun` usage to pass `skin`**

In the `isFirstRun` sliver, update:
```dart
child: HomeFirstRun(skin: skin),
```

- [ ] **Step 7: Update `_PrimaryAction` fallback cards to pass `skin`**

In `_PrimaryAction.build()`, update `ResumeSessionCard` and `NextBestActionCard` calls to pass `skin: skin`.

- [ ] **Step 8: Add new imports**

```dart
import '../widgets/home_unified_progress.dart';
import '../widgets/staggered_fade_slide.dart';
```

Remove unused imports:
```dart
// REMOVE:
import '../widgets/home_action_tiles.dart';
import '../widgets/home_quick_access.dart';
```

- [ ] **Step 9: Verify full compilation**

Run: `dart analyze lib/features/home/`
Expected: No errors.

- [ ] **Step 10: Commit**

```bash
git add lib/features/home/
git commit -m "feat(home): restructure layout - remove deprecated widgets, add staggered animations"
```

---

### Task 11: Parallax Header Effect

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_background.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`

**Interfaces:**
- Consumes: Scroll offset from `CustomScrollView`
- Produces: Mosque background image scrolls at 0.3× speed relative to content

- [ ] **Step 1: Add `ScrollController` to `HomeLoadedView`**

Convert `HomeLoadedView` to a `StatefulWidget` with a `ScrollController`:

```dart
class HomeLoadedView extends StatefulWidget {
  const HomeLoadedView({super.key, required this.state, required this.skin});
  final HomeLoaded state;
  final HomeSkin skin;
  @override
  State<HomeLoadedView> createState() => _HomeLoadedViewState();
}

class _HomeLoadedViewState extends State<HomeLoadedView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pass _scrollController to CustomScrollView
    // Pass _scrollController to HomeNightHeader for parallax
  }
}
```

- [ ] **Step 2: Update `HomeHeroBanner` to accept a parallax offset**

Add an optional `parallaxOffset` parameter:

```dart
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({
    super.key,
    required this.skin,
    required this.child,
    this.parallaxOffset = 0.0,
  });

  final HomeSkin skin;
  final Widget child;
  final double parallaxOffset;

  @override
  Widget build(BuildContext context) {
    // Apply parallax to the Image alignment:
    final alignment = Alignment(0.0, -1.0 + parallaxOffset * 0.3);
    // Use this alignment in Image.asset
  }
}
```

- [ ] **Step 3: Wire scroll listener to update parallax**

In `_HomeLoadedViewState`, use `AnimatedBuilder` with the scroll controller to compute the parallax offset and pass it to `HomeNightHeader`/`HomeHeroBanner`.

- [ ] **Step 4: Verify compilation and hot-reload**

Run: `dart analyze lib/features/home/presentation/widgets/home_background.dart lib/features/home/presentation/pages/home_page.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/home_background.dart lib/features/home/presentation/pages/home_page.dart
git commit -m "feat(home): add parallax scroll effect to mosque header background"
```

---

### Task 12: Final Static Analysis & Cleanup

**Files:**
- All files modified in Tasks 1-11

**Interfaces:**
- Consumes: Full project
- Produces: Clean compilation, no unused imports, no dead code

- [ ] **Step 1: Run full static analysis**

Run: `dart analyze lib/features/home/`
Fix any warnings or errors.

- [ ] **Step 2: Remove unused widget files if now fully deprecated**

The following widgets are no longer used in the home page layout but may be used elsewhere. Verify before removing:
- `home_action_tiles.dart` — check for other imports
- `home_quick_access.dart` — check for other imports  
- `home_momentum_strip.dart` — check for other imports

If not imported anywhere else, delete the files.

- [ ] **Step 3: Run `dart fix --apply`**

Run: `dart fix --apply --code=unused_import lib/features/home/`

- [ ] **Step 4: Final compilation check**

Run: `dart analyze lib/`
Expected: No errors in the home feature.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore(home): final cleanup — remove deprecated widgets, fix imports"
```
