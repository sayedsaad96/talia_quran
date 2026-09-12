import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../domain/entities/home_contextual_slot.dart';
import '../cubits/home_cubit.dart';
import '../theme/home_skin.dart';
import 'glass_panel.dart';

class HomeContextualSlot extends StatelessWidget {
  const HomeContextualSlot({
    super.key,
    required this.state,
    required this.skin,
  });

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final slot = state.activeSlot;
    if (slot == null) return const SizedBox.shrink();
    if (slot.kind == HomeSlotKind.signIn) {
      final auth = context.watch<AuthCubit>().state;
      if (auth is AuthAuthenticated) return const SizedBox.shrink();
    }
    if (slot.kind == HomeSlotKind.parentTools && state.familyChildren.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final title = switch (slot.kind) {
      HomeSlotKind.fridayKahf => context.l10n.homeSlotFridayTitle,
      HomeSlotKind.ramadan => context.l10n.homeSlotRamadanTitle,
      HomeSlotKind.lastTenNights => context.l10n.homeSlotLastTenTitle,
      HomeSlotKind.streakRisk => context.l10n.homeStreakAtRisk,
      HomeSlotKind.khatmahNearComplete => context.l10n.homeSlotKhatmahTitle,
      HomeSlotKind.parentTools => context.l10n.homeParentToolsTitle,
      HomeSlotKind.signIn => context.l10n.guestUpgradeTitle,
      HomeSlotKind.tutorial => context.l10n.homeTourTitle,
    };
    final body = switch (slot.kind) {
      HomeSlotKind.fridayKahf => context.l10n.homeSlotFridayBody,
      HomeSlotKind.ramadan => context.l10n.homeSlotRamadanBody,
      HomeSlotKind.lastTenNights => context.l10n.homeSlotLastTenBody,
      HomeSlotKind.streakRisk => context.l10n.homeSlotStreakBody,
      HomeSlotKind.khatmahNearComplete => context.l10n.homeSlotKhatmahBody,
      HomeSlotKind.parentTools => context.l10n.homeParentToolsSubtitle,
      HomeSlotKind.signIn => context.l10n.guestUpgradeMessage,
      HomeSlotKind.tutorial => context.l10n.homeTourDesc,
    };

    return Semantics(
      container: true,
      label: title,
      child: GlassPanel(
        skin: skin,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            skin.gold.withValues(alpha: skin.isDark ? 0.16 : 0.12),
            skin.glassFill,
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      color: skin.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: skin.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(slot.route),
                    style: TextButton.styleFrom(
                      foregroundColor: skin.accent,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.l10n.homeSlotOpen,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.l10n.later,
              visualDensity: VisualDensity.compact,
              color: skin.textSecondary,
              onPressed: () => context.read<HomeCubit>().snoozeSlot(slot.kind),
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
