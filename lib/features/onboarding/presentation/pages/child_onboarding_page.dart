import 'package:flutter/material.dart';
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
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
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
      ),
      _ChildOnboardingStep(
        icon: Icons.flag_rounded,
        title: isArabic ? 'المهام' : 'Missions',
        description: isArabic
            ? 'كل مهمة تقود الطفل إلى آيات قليلة وواضحة.'
            : 'Each mission focuses the child on a small set of ayahs.',
      ),
      _ChildOnboardingStep(
        icon: Icons.stars_rounded,
        title: isArabic ? 'المكافآت' : 'Rewards',
        description: isArabic
            ? 'النجوم والنقاط تشجع الاستمرار بدون ضغط.'
            : 'Stars and points encourage steady progress without pressure.',
      ),
      _ChildOnboardingStep(
        icon: Icons.family_restroom_rounded,
        title: isArabic ? 'متابعة ولي الأمر' : 'Parent Follow-up',
        description: isArabic
            ? 'يمكن لولي الأمر متابعة التقدم وربط الحساب لاحقاً.'
            : 'A parent can follow progress and link accounts later.',
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
            AppSpacing.lg,
            AppSpacing.pagePadding,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: AppSpacing.sm),
              Icon(Icons.auto_awesome_rounded, color: primary, size: 44),
              const SizedBox(height: AppSpacing.md),
              Text(
                isArabic ? 'قبل أن يبدأ الطفل' : 'Before Your Child Starts',
                style: AppTypography.headlineMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isArabic
                    ? 'هذه لمحة سريعة عن تجربة الأطفال حتى يعرف الطفل أين يبدأ، ويعرف ولي الأمر كيف يتابع.'
                    : 'A quick orientation so the child knows where to begin, and the parent knows what to expect.',
                style: AppTypography.bodyMedium.copyWith(
                  color: subTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: steps.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => _ChildOnboardingTile(
                    step: steps[index],
                    isDark: isDark,
                    surface: surface,
                    primary: primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => _startKidsPath(context),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(isArabic ? 'ابدأ وضع الأطفال' : 'Start Kids Mode'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.tutorialGuide),
                child: Text(isArabic ? 'عرض الدليل أولاً' : 'View guide first'),
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
    required this.primary,
  });

  final _ChildOnboardingStep step;
  final bool isDark;
  final Color surface;
  final Color primary;

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
        border: Border.all(color: primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(step.icon, color: primary, size: 22),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: subTextColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildOnboardingStep {
  const _ChildOnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
