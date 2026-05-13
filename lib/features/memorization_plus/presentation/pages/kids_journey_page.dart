import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/kids_journey_cubit.dart';

class KidsJourneyPage extends StatelessWidget {
  const KidsJourneyPage({super.key, required this.surahId});
  final int surahId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<KidsJourneyCubit>()..load(surahId: surahId),
      child: _KidsJourneyView(surahId: surahId),
    );
  }
}

class _KidsJourneyView extends StatelessWidget {
  const _KidsJourneyView({required this.surahId});
  final int surahId;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF0F7F4),
      body: BlocConsumer<KidsJourneyCubit, KidsJourneyState>(
        listener: (context, state) {
          if (state is KidsJourneyLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is KidsJourneyLoading || state is KidsJourneyInitial) {
            return const Center(child: LoadingWidget());
          }
          if (state is KidsJourneyError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () =>
                  context.read<KidsJourneyCubit>().load(surahId: surahId),
            );
          }
          if (state is! KidsJourneyLoaded) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () =>
                context.read<KidsJourneyCubit>().load(surahId: surahId),
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context, isDark, state),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _HeroProgressCard(state: state, isDark: isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _RemoteLinkCard(state: state, isDark: isDark),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'خريطة الحفظ',
                        style: AppTypography.headlineSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontFamily: 'Amiri',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...state.stages.map(
                        (stage) => _StageTile(stage: stage, isDark: isDark),
                      ),
                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    bool isDark,
    KidsJourneyLoaded state,
  ) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 150,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF0F7F4),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.admin_panel_settings_rounded,
            color: Colors.white,
          ),
          tooltip: 'لوحة ولي الأمر',
          onPressed: () => context.push(
            '${AppRoutes.parentDashboard}?surahId=${state.surahId}',
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D8E4C), Color(0xFF1A6B5A)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رحلة الحفظ',
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  Text(
                    'استمع، كرر، واجمع النجوم خطوة بخطوة',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroProgressCard extends StatelessWidget {
  const _HeroProgressCard({required this.state, required this.isDark});
  final KidsJourneyLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final stage = state.currentStage;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatPill(
                icon: Icons.stars_rounded,
                label: '${state.progress.totalPoints} نقطة',
                color: const Color(0xFFFFB300),
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.military_tech_rounded,
                label: 'مستوى ${state.progress.currentLevel}',
                color: const Color(0xFF2D8E4C),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            stage == null
                ? 'ابدأ أول مرحلة اليوم'
                : 'المرحلة ${stage.stageNumber}: الآيات ${stage.startAyah}-${stage.endAyah}',
            style: AppTypography.titleLarge.copyWith(
              fontFamily: 'Amiri',
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: stage?.progress ?? 0,
              backgroundColor: const Color(0xFF2D8E4C).withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2D8E4C)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoteLinkCard extends StatelessWidget {
  const _RemoteLinkCard({required this.state, required this.isDark});
  final KidsJourneyLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF2D5A8E).withValues(alpha: isDark ? 0.22 : 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: const Color(0xFF2D5A8E).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2D5A8E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ربط ولي الأمر عن بعد',
                  style: AppTypography.titleMedium.copyWith(
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
              TextButton(
                onPressed: state.isCreatingLink
                    ? null
                    : () =>
                          context.read<KidsJourneyCubit>().createRemoteLinkQr(),
                child: Text(state.qrPayload == null ? 'إنشاء QR' : 'تجديد'),
              ),
            ],
          ),
          if (state.qrPayload != null) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: QrImageView(
                  data: state.qrPayload!,
                  version: QrVersions.auto,
                  size: 180,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'افتح لوحة ولي الأمر على الجهاز الآخر وامسح الرمز.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({required this.stage, required this.isDark});
  final KidsJourneyStage stage;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final locked = stage.status == KidsJourneyStageStatus.locked;
    final completed = stage.status == KidsJourneyStageStatus.completed;
    final color = completed
        ? const Color(0xFFFFB300)
        : locked
        ? Colors.grey
        : const Color(0xFF2D8E4C);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: locked
            ? null
            : () async {
                final startAyah =
                    stage.completedAyahs.length >= stage.totalAyahs
                    ? stage.startAyah
                    : stage.startAyah + stage.completedAyahs.length;
                await context.push(
                  '${AppRoutes.memorizationPlusKids}?surahId=${stage.surahId}&ayahNumber=$startAyah',
                );
                if (context.mounted) {
                  await context.read<KidsJourneyCubit>().load(
                    surahId: stage.surahId,
                  );
                }
              },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.16),
                child: Icon(
                  locked
                      ? Icons.lock_rounded
                      : completed
                      ? Icons.emoji_events_rounded
                      : Icons.play_arrow_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحلة ${stage.stageNumber}',
                      style: AppTypography.titleMedium.copyWith(
                        fontFamily: 'Amiri',
                      ),
                    ),
                    Text(
                      'الآيات ${stage.startAyah}-${stage.endAyah} • ${stage.completedCount}/${stage.totalAyahs}',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
