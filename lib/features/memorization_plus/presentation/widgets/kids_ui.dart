import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/kids_child_policy.dart';
import '../../domain/services/kids_world_phase.dart';
import '../theme/kids_theme.dart';
import '../world/kids_policy_controller.dart';
import '../world/kids_world_palette.dart';
import '../world/kids_world_phase_controller.dart';
import '../world/kids_world_scene.dart';

/// Shared visual shell for every screen in the kids memorization path: the
/// live day/night world scene. Night when no phase controller is registered.
class KidsBackground extends StatefulWidget {
  const KidsBackground({super.key, required this.child, this.animate = false});

  final Widget child;
  final bool animate;

  @override
  State<KidsBackground> createState() => _KidsBackgroundState();
}

class _KidsBackgroundState extends State<KidsBackground> {
  KidsWorldPhaseController? _controller;
  KidsPolicyController? _policy;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<KidsWorldPhaseController>()) {
      _controller = getIt<KidsWorldPhaseController>()..ensureStarted();
    }
    // App-lifetime singleton: listened to here, never disposed here.
    if (getIt.isRegistered<KidsPolicyController>()) {
      _policy = getIt<KidsPolicyController>();
    }
  }

  Widget _scene(KidsWorldPhase phase) {
    return KidsWorldPhaseScope(
      phase: phase,
      child: KidsWorldScene(
        phase: phase,
        animate: widget.animate,
        child: widget.child,
      ),
    );
  }

  Widget _world() {
    final controller = _controller;
    if (controller == null) return _scene(KidsWorldPhase.night);
    return ValueListenableBuilder<KidsWorldPhase>(
      valueListenable: controller,
      builder: (context, phase, _) => _scene(phase),
    );
  }

  @override
  Widget build(BuildContext context) {
    final policy = _policy;
    if (policy == null) return _world();
    // The guardian's reduce-motion policy stills every kids loop the same
    // way the OS setting does (scene, Talia, rings, recording wave).
    return ValueListenableBuilder<KidsChildPolicy>(
      valueListenable: policy,
      // Always wrapped so a live toggle keeps the subtree's state.
      builder: (context, value, child) {
        final data = MediaQuery.maybeOf(context) ?? const MediaQueryData();
        return MediaQuery(
          data: value.reduceMotion
              ? data.copyWith(disableAnimations: true)
              : data,
          child: child!,
        );
      },
      child: _world(),
    );
  }
}

/// Shared top bar so internal kids screens keep the same navigation language.
class KidsTopBar extends StatelessWidget {
  const KidsTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
    this.backLabel,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        0,
      ),
      decoration: const BoxDecoration(
        gradient: KidsTheme.heroCardGradient,
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusXl)),
        boxShadow: KidsTheme.card25DShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (backLabel == null)
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
                icon: const BackButtonIcon(),
                color: KidsTheme.shellTextPrimary,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  minimumSize: const Size(48, 48),
                ),
              )
            else
              Tooltip(
                message: backLabel!,
                child: TextButton.icon(
                  onPressed: onBack,
                  icon: const BackButtonIcon(),
                  label: Text(backLabel!),
                  style: TextButton.styleFrom(
                    foregroundColor: KidsTheme.shellTextPrimary,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLarge.copyWith(
                      color: KidsTheme.shellTextPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: KidsTheme.shellTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
