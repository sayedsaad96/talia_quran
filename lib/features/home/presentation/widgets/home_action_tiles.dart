import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/quran_continuous_player_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/today_checklist.dart';
import '../cubits/home_cubit.dart';
import '../theme/home_skin.dart';
import 'glass_panel.dart';

class HomeActionTiles extends StatelessWidget {
  const HomeActionTiles({super.key, required this.state, required this.skin});

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final tasks = state.todayChecklist?.tasks ?? const <TodayTask>[];
    TodayTask? of(TodayTaskKind kind) {
      for (final task in tasks) {
        if (task.kind == kind) return task;
      }
      return null;
    }

    final listenRoute = state.audioResume == null
        ? (of(TodayTaskKind.review)?.route ?? AppRoutes.memorizationHub)
        : null;
    final tiles = [
      (
        Icons.headphones_rounded,
        context.l10n.homeTileListen,
        context.l10n.homeTileListenHint,
        listenRoute,
      ),
      (
        Icons.replay_rounded,
        context.l10n.homeTileReview,
        context.l10n.homeTileReviewHint,
        of(TodayTaskKind.review)?.route ?? AppRoutes.memorizationHub,
      ),
      (
        Icons.bookmark_outline_rounded,
        context.l10n.homeTileMemorize,
        context.l10n.homeTileMemorizeHint,
        of(TodayTaskKind.memorize)?.route ?? AppRoutes.memorizationHub,
      ),
      (
        Icons.menu_book_outlined,
        context.l10n.homeTileRead,
        context.l10n.homeTileReadHint,
        of(TodayTaskKind.reading)?.route ?? AppRoutes.quran,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final singleColumn = constraints.maxWidth < 300 || textScale > 1.3;
        Widget tileAt(int i) => _ActionTile(
          skin: skin,
          icon: tiles[i].$1,
          title: tiles[i].$2,
          hint: tiles[i].$3,
          onTap: () {
            final route = tiles[i].$4;
            if (route == null) {
              final audio = state.audioResume!;
              getIt<QuranContinuousPlayerService>().playAyah(
                audio.surahId,
                audio.ayahNumber,
                reciter: audio.reciter,
                scope: audio.scope,
              );
              return;
            }
            context.push(route);
          },
        );

        if (singleColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                tileAt(i),
              ],
            ],
          );
        }

        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tileAt(0)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: tileAt(1)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tileAt(2)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: tileAt(3)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.skin,
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final HomeSkin skin;
  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $hint',
      child: GlassPanel(
        skin: skin,
        padding: const EdgeInsets.all(AppSpacing.itemGap),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: skin.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: skin.accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: skin.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: skin.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
