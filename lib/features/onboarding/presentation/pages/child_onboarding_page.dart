import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../memorization_plus/domain/navigation/memorization_navigation_resolver.dart';

class ChildOnboardingPage extends StatefulWidget {
  const ChildOnboardingPage({super.key});

  static const _seenKey = 'child_onboarding_seen';

  @override
  State<ChildOnboardingPage> createState() => _ChildOnboardingPageState();
}

class _ChildOnboardingPageState extends State<ChildOnboardingPage> {
  bool _checkingSeen = true;

  @override
  void initState() {
    super.initState();
    _redirectIfAlreadySeen();
  }

  Future<void> _redirectIfAlreadySeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(ChildOnboardingPage._seenKey) ?? false;
    if (!mounted) return;
    if (!seen) {
      setState(() => _checkingSeen = false);
      return;
    }

    final location = await MemorizationNavigationResolver(
      getIt<MemorizationPlusRepository>(),
    ).childOnboardingLocation();
    if (mounted) context.go(location);
  }

  Future<void> _startKidsPath(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ChildOnboardingPage._seenKey, true);
    final location = await MemorizationNavigationResolver(
      getIt<MemorizationPlusRepository>(),
    ).childOnboardingLocation();
    if (context.mounted) context.go(location);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSeen) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = context.isDark;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final isArabic = context.isArabic;

    final steps = [
      _ChildOnboardingStep(
        icon: Icons.child_care_rounded,
        title: isArabic ? 'وضع الأطفال' : 'Kids Mode',
        description: isArabic
            ? 'مسار أبسط وممتع يناسب الطفل داخل منطقة الحفظ.'
            : 'A simpler, playful path inside the memorization area.',
        color: AppColors.gold,
      ),
      _ChildOnboardingStep(
        icon: Icons.flag_rounded,
        title: isArabic ? 'المهام' : 'Missions',
        description: isArabic
            ? 'كل مهمة تقود الطفل إلى آيات قليلة وواضحة.'
            : 'Each mission focuses the child on a small set of ayahs.',
        color: AppColors.kidsGreen,
      ),
      _ChildOnboardingStep(
        icon: Icons.stars_rounded,
        title: isArabic ? 'المكافآت' : 'Rewards',
        description: isArabic
            ? 'النجوم والنقاط تشجع الاستمرار بدون ضغط.'
            : 'Stars and points encourage steady progress without pressure.',
        color: AppColors.amber,
      ),
      _ChildOnboardingStep(
        icon: Icons.family_restroom_rounded,
        title: isArabic ? 'متابعة ولي الأمر' : 'Parent Follow-up',
        description: isArabic
            ? 'يمكن لولي الأمر متابعة التقدم وربط الحساب لاحقاً.'
            : 'A parent can follow progress and link accounts later.',
        color: AppColors.info,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.md,
            AppSpacing.pagePadding,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.onboarding),
                    icon: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                    ),
                    color: subTextColor,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: AppColors.gold, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          isArabic ? 'رحلة البراعم' : 'Kids Journey',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 36),
                ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.85, 0.85)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isArabic ? 'قبل أن يبدأ الطفل' : 'Before Your Child Starts',
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05),
              const SizedBox(height: 4),
              Text(
                isArabic
                    ? 'هذه لمحة سريعة عن تجربة الأطفال حتى يعرف الطفل أين يبدأ، ويعرف ولي الأمر كيف يتابع.'
                    : 'A quick orientation so the child knows where to begin, and the parent knows what to expect.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: subTextColor,
                  height: 1.45,
                  fontSize: 13,
                ),
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: steps.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => _ChildOnboardingTile(
                    step: steps[index],
                    isDark: isDark,
                    surface: surface,
                    index: index,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Gold CTA
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  gradient: const LinearGradient(
                    colors: [AppColors.goldLight, AppColors.goldDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _startKidsPath(context),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            isArabic ? 'ابدأ وضع الأطفال' : 'Start Kids Mode',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.tutorialGuide),
                  child: Text(
                    isArabic ? 'عرض الدليل أولاً' : 'View guide first',
                    style: AppTypography.labelMedium.copyWith(
                      color: subTextColor,
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

class _ChildOnboardingTile extends StatelessWidget {
  const _ChildOnboardingTile({
    required this.step,
    required this.isDark,
    required this.surface,
    required this.index,
  });

  final _ChildOnboardingStep step;
  final bool isDark;
  final Color surface;
  final int index;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: step.color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: step.color.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(step.icon, color: step.color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: subTextColor,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms, delay: (100 + index * 50).ms).slideY(begin: 0.05);
  }
}

class _ChildOnboardingStep {
  const _ChildOnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}
