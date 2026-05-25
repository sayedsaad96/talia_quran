import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  static const _pageCount = 4;
  static const _goalKey = 'user_primary_goal';
  static const _skippedKey = 'onboarding_skipped';
  int _currentPage = 0;
  String _selectedGoal = 'reading';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding({bool skipped = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTimeAppOpen', false);
    await prefs.setBool(_skippedKey, skipped);
    await prefs.setString(_goalKey, _selectedGoal);
    if (!mounted) return;
    context.go(skipped ? '/' : _routeForGoal(_selectedGoal));
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  String _routeForGoal(String goal) => switch (goal) {
    'reading' => '/quran',
    'memorization' => '/memorization-plus',
    'child' => '/memorization-plus',
    'azkar' => '/azkar',
    _ => '/',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // RTL-first: skip button positioned on the trailing side
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () => _completeOnboarding(skipped: true),
                  child: Text(
                    context.l10n.onboardingSkip,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _OnboardingSlide(
                    title: context.l10n.onboardingQuranTitle,
                    description: context.l10n.onboardingQuranDesc,
                    icon: Icons.menu_book_rounded,
                    isDark: isDark,
                    primaryColor: primaryColor,
                    glowColor: Colors.amber,
                  ),
                  _OnboardingSlide(
                    title: context.l10n.onboardingSmartTitle,
                    description: context.l10n.onboardingSmartDesc,
                    icon: Icons.psychology_alt_rounded,
                    isDark: isDark,
                    primaryColor: primaryColor,
                    glowColor: Colors.blueAccent,
                  ),
                  _OnboardingSlide(
                    title: context.l10n.onboardingKidsTitle,
                    description: context.l10n.onboardingKidsDesc,
                    icon: Icons.child_care_rounded,
                    isDark: isDark,
                    primaryColor: primaryColor,
                    glowColor: Colors.purpleAccent,
                  ),
                  _GoalSelectionSlide(
                    selectedGoal: _selectedGoal,
                    onChanged: (goal) => setState(() => _selectedGoal = goal),
                    isDark: isDark,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _pageCount,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? primaryColor
                              : isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Start Button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _pageCount - 1
                              ? context.l10n.onboardingStartNow
                              : context.l10n.next,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_currentPage != _pageCount - 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isDark;
  final Color primaryColor;
  final Color glowColor;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.isDark,
    required this.primaryColor,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graphic Illustration
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glowColor.withValues(alpha: isDark ? 0.05 : 0.03),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: isDark ? 0.1 : 0.05),
                      blurRadius: 40,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
              // Inner ring
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: glowColor.withValues(alpha: 0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
              ),
              // Core icon background
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      glowColor.withValues(alpha: 0.8),
                      glowColor.withValues(alpha: 0.4),
                    ],
                  ),
                ),
                child: Center(child: Icon(icon, size: 64, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 64),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GoalSelectionSlide extends StatelessWidget {
  const _GoalSelectionSlide({
    required this.selectedGoal,
    required this.onChanged,
    required this.isDark,
    required this.primaryColor,
  });

  final String selectedGoal;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final goals = [
      ('reading', 'القراءة', Icons.menu_book_rounded, AppColors.primary),
      (
        'memorization',
        'الحفظ لنفسي',
        Icons.psychology_alt_rounded,
        Colors.blue,
      ),
      ('child', 'متابعة طفل', Icons.child_care_rounded, Colors.green),
      ('azkar', 'الأذكار', Icons.volunteer_activism_rounded, Colors.orange),
    ];
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_rounded, color: primaryColor, size: 72),
          const SizedBox(height: 32),
          Text(
            'ماذا تريد أن تفعل أولاً؟',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'اختر بداية واضحة، ويمكنك استخدام باقي التطبيق لاحقاً.',
            style: TextStyle(fontSize: 16, height: 1.5, color: subTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ...goals.map((goal) {
            final selected = selectedGoal == goal.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onChanged(goal.$1),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? goal.$4.withValues(alpha: 0.14)
                        : isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? goal.$4
                          : goal.$4.withValues(alpha: 0.16),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(goal.$3, color: goal.$4),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          goal.$2,
                          style: TextStyle(
                            color: selected ? goal.$4 : textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle_rounded, color: goal.$4),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
