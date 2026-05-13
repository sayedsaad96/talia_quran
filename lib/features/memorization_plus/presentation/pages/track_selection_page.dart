import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/track_selection_cubit.dart';

class TrackSelectionPage extends StatelessWidget {
  const TrackSelectionPage({super.key, this.editMode = false});

  final bool editMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TrackSelectionCubit>()..load(),
      child: _TrackSelectionView(editMode: editMode),
    );
  }
}

class _TrackSelectionView extends StatelessWidget {
  const _TrackSelectionView({required this.editMode});

  final bool editMode;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: BlocConsumer<TrackSelectionCubit, TrackSelectionState>(
        listener: (context, state) {
          if (state is TrackSelectionLoaded && state.hasTrack) {
            unawaited(_navigateToTrack(context, state.track!, replace: true));
          } else if (state is TrackSelectionError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (!editMode && state is TrackSelectionLoaded && state.hasTrack) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                unawaited(
                  _navigateToTrack(context, state.track!, replace: true),
                );
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppColors.heroGradientDark
                        : AppColors.heroGradientLight,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        AppSpacing.xl,
                        AppSpacing.pagePadding,
                        AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editMode ? 'تعديل خطة الحفظ' : 'نظام الحفظ الذكي',
                            style: AppTypography.displaySmall.copyWith(
                              color: Colors.white,
                              fontFamily: 'Amiri',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            editMode
                                ? 'يمكنك تغيير المسار أو الخطة الآن'
                                : 'Smart Memorization System',
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
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    editMode ? 'اختر خطة جديدة' : 'اختر مسارك',
                    style: AppTypography.headlineSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'يمكنك التغيير في أي وقت من الإعدادات',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _TrackCard(
                    track: MemorizationTrack.adults,
                    isDark: isDark,
                    titleAr: 'مسار الكبار',
                    titleEn: 'Adults Track',
                    description:
                        'خطة يومية مدروسة: حفظ جديد + مراجعة قريبة + مراجعة بعيدة مع تقييم ذاتي وجدولة تكيّفية',
                    icon: Icons.school_rounded,
                    gradient: [
                      AppColors.primary.withValues(alpha: 0.9),
                      const Color(0xFF1A3A5C),
                    ],
                    features: const [
                      '📚 3–5 آيات جديدة يومياً',
                      '🔄 مراجعة قريبة (آخر 5 أيام)',
                      '📅 مراجعة بعيدة (تكرار ذكي)',
                      '⭐ تقييم ذاتي: ممتاز / متوسط / ضعيف',
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _TrackCard(
                    track: MemorizationTrack.kids,
                    isDark: isDark,
                    titleAr: 'مسار الأطفال والمبتدئين',
                    titleEn: 'Kids & Beginners Track',
                    description:
                        'تعلم ممتع مع الاستماع والتكرار والمكافآت والنجوم لتشجيع الأطفال على الحفظ',
                    icon: Icons.child_care_rounded,
                    gradient: const [Color(0xFF2D8E4C), Color(0xFF1A6B5A)],
                    features: const [
                      '🎧 استمع وكرر تلقائياً',
                      '⭐ نجوم ومكافآت',
                      '🎮 مستويات ونقاط',
                      '🔊 تشغيل تلقائي للآية',
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Custom Plan Card ──
                  GestureDetector(
                    onTap: () => context.push('/memorization-plus/custom-plan'),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6C3483), Color(0xFF4A235A)],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXl,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6C3483,
                            ).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.dashboard_customize_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'خطة مخصصة',
                                        style: AppTypography.titleLarge
                                            .copyWith(
                                              color: Colors.white,
                                              fontFamily: 'Amiri',
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        'Custom Plan',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'صمّم خطة حفظ تناسب قدراتك وجدولك الزمني: حدد السور والآيات ومستوى الصعوبة وأيام الحفظ والمراجعة بكل حرية',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.6,
                                fontFamily: 'Amiri',
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ...[
                              '✏️ تحكم كامل بعدد الآيات والسور',
                              '📅 جدول مرن حسب أيامك المتاحة',
                              '⚡ مستوى صعوبة قابل للتعديل',
                              '🔁 إعدادات مراجعة متقدمة',
                            ].map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  f,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
          );
        },
      ),
    );
  }

  // BUG-9 FIX: load last active surahId so user resumes from where they left off
  Future<void> _navigateToTrack(
    BuildContext context,
    MemorizationTrack track,
    {required bool replace}
  ) async {
    final cubit = context.read<TrackSelectionCubit>();
    final lastSurahId = await cubit.getLastActiveSurahId();

    if (!context.mounted) return;
    final location = track == MemorizationTrack.adults
        ? '/memorization-plus/daily-plan?surahId=$lastSurahId'
        : '/memorization-plus/kids-journey?surahId=$lastSurahId';

    if (replace) {
      context.go(location);
      return;
    }

    if (track == MemorizationTrack.adults) {
      await context.push('/memorization-plus/daily-plan?surahId=$lastSurahId');
    } else {
      await context.push(
        '/memorization-plus/kids-journey?surahId=$lastSurahId',
      );
    }
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.track,
    required this.isDark,
    required this.titleAr,
    required this.titleEn,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.features,
  });

  final MemorizationTrack track;
  final bool isDark;
  final String titleAr;
  final String titleEn;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<TrackSelectionCubit>().selectTrack(track),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleAr,
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          titleEn,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Description
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.6,
                  fontFamily: 'Amiri',
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: AppSpacing.md),
              // Features
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    f,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
