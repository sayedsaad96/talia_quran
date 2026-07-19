import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/azkar_entities.dart';
import '../../domain/repositories/azkar_repository.dart';

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> {
  late Future<Map<AzkarCategory, int>> _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadCounts();
  }

  Future<Map<AzkarCategory, int>> _loadCounts() async {
    final repo = getIt<AzkarRepository>();
    final counts = <AzkarCategory, int>{};
    for (final category in AzkarCategory.values) {
      final result = await repo.getAzkar(category);
      counts[category] = result.fold((_) => 0, (list) => list.length);
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: FutureBuilder<Map<AzkarCategory, int>>(
        future: _countsFuture,
        builder: (context, snapshot) {
          final counts = snapshot.data;
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, isDark),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.lg,
                  AppSpacing.pagePadding,
                  120, // Prevent cutoff by bottom nav
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _AzkarCategoryCard(
                      title: context.l10n.morningAzkar,
                      subtitle: counts == null ? '...' : context.l10n.zikrCount(counts[AzkarCategory.morning] ?? 0),
                      icon: Icons.wb_sunny_rounded,
                      gradientColors: const [Color(0xFFFF8C42), Color(0xFFFF6B00)],
                      route: 'morning',
                      delay: 0,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AzkarCategoryCard(
                      title: context.l10n.eveningAzkar,
                      subtitle: counts == null ? '...' : context.l10n.zikrCount(counts[AzkarCategory.evening] ?? 0),
                      icon: Icons.nightlight_round,
                      gradientColors: const [Color(0xFF2D5A8E), Color(0xFF1A3A5C)],
                      route: 'evening',
                      delay: 80,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AzkarCategoryCard(
                      title: context.l10n.generalAzkar,
                      subtitle: counts == null ? '...' : context.l10n.azkarCount(counts[AzkarCategory.general] ?? 0),
                      icon: Icons.spa_rounded,
                      gradientColors: const [Color(0xFF1A6B5A), Color(0xFF0F4A3E)],
                      route: 'general',
                      delay: 160,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AzkarCategoryCard(
                      title: context.l10n.duas,
                      subtitle: counts == null ? '...' : context.l10n.duaCount(counts[AzkarCategory.duas] ?? 0),
                      icon: Icons.volunteer_activism_rounded,
                      gradientColors: const [Color(0xFFE11D48), Color(0xFF881337)],
                      route: 'duas',
                      delay: 240,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _DailyTip(isDark: isDark),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                  ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -20,
                child: Icon(
                  Icons.mosque_rounded,
                  size: 200,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.lg,
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.azkar,
                        style: AppTypography.headlineLarge.copyWith(
                          color: Colors.white,
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          context.l10n.azkarSubtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

class _AzkarCategoryCard extends StatefulWidget {
  const _AzkarCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.route,
    required this.delay,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String route;
  final int delay;
  final bool isDark;

  @override
  State<_AzkarCategoryCard> createState() => _AzkarCategoryCardState();
}

class _AzkarCategoryCardState extends State<_AzkarCategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        context.push('/azkar/${widget.route}');
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOutCubic,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors[0].withValues(alpha: 0.4),
                blurRadius: _isPressed ? 10 : 20,
                offset: Offset(0, _isPressed ? 4 : 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern/icon
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  widget.icon,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    // Icon Container with Glassmorphism feel
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: AppTypography.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: context.isArabic ? 'Amiri' : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Text(
                              widget.subtitle,
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back_ios_new_rounded
                            : Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms, delay: widget.delay.ms).slideY(
            begin: 0.05,
            end: 0,
            curve: Curves.easeOutCubic,
            duration: 400.ms,
          ),
    );
  }
}

class _DailyTip extends StatefulWidget {
  const _DailyTip({required this.isDark});
  final bool isDark;

  @override
  State<_DailyTip> createState() => _DailyTipState();
}

class _DailyTipState extends State<_DailyTip> {
  static const List<String> _tips = [
    // أذكار وفضائل
    'قُلْ هُوَ اللَّهُ أَحَدٌ — قراءة المعوذتين ثلاثًا تكفيك من كل شيء',
    'من قرأ آية الكرسي دبر كل صلاة مكتوبة لم يمنعه من دخول الجنة إلا أن يموت',
    'أحب الكلام إلى الله أربع: سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر',
    'كلمتان خفيفتان على اللسان ثقيلتان في الميزان: سبحان الله وبحمده، سبحان الله العظيم',
    'من قال: سبحان الله وبحمده في يوم مائة مرة حطت خطاياه وإن كانت مثل زبد البحر',
    'من لزم الاستغفار جعل الله له من كل هم فرجا ومن كل ضيق مخرجا',
    'من صلى علي صلاة واحدة صلى الله عليه بها عشراً',
    'أقرب ما يكون العبد من ربه وهو ساجد فأكثروا الدعاء',
    'يا مقلب القلوب ثبت قلبي على دينك',

    // آيات قرآنية
    '﴿وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ﴾',
    '﴿فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ﴾',
    '﴿وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا ۝ وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ﴾',
    '﴿لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا﴾',
    '﴿إِنَّ مَعَ الْعُسْرِ يُسْرًا﴾',
    '﴿وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ وَإِنَّهَا لَكَبِيرَةٌ إِلَّا عَلَى الْخَاشِعِينَ﴾',
    '﴿رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً﴾',
    '﴿وَالذَّاكِرِينَ اللَّهَ كَثِيرًا وَالذَّاكِرَاتِ أَعَدَّ اللَّهُ لَهُم مَّغْفِرَةً وَأَجْرًا عَظِيمًا﴾',
    '﴿وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَى﴾',

    // أدعية
    'اللهم إني أسألك الهدى والتقى والعفاف والغنى',
    'اللهم إنك عفو تحب العفو فاعف عني',
    'اللهم أعني على ذكرك وشكرك وحسن عبادتك',
    'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار',
    'اللهم إني أعوذ بك من الهم والحزن، والعجز والكسل، والبخل والجبن',
    'اللهم أصلح لي ديني الذي هو عصمة أمري، وأصلح لي دنياي التي فيها معاشي',
    'اللهم إني أسألك الجنة وما قرب إليها من قول أو عمل',
    'رب اشرح لي صدري ويسر لي أمري',

    // حكم ونصائح
    'الصدقة تطفئ الخطيئة كما يطفئ الماء النار',
    'الدعاء هو العبادة',
    'تبسمك في وجه أخيك لك صدقة',
    'لا تحقرن من المعروف شيئاً، ولو أن تلقى أخاك بوجه طلق',
    'اقرأوا القرآن فإنه يأتي يوم القيامة شفيعاً لأصحابه',
    'خيركم من تعلم القرآن وعلمه',
    'الطهور شطر الإيمان، والحمد لله تملأ الميزان',
    'اتق الله حيثما كنت، وأتبع السيئة الحسنة تمحها',
    'احفظ الله يحفظك، احفظ الله تجده تجاهك',
    'ما نقصت صدقة من مال، وما زاد الله عبداً بعفوٍ إلا عزاً',
    'من حسن إسلام المرء تركه ما لا يعنيه',
    'الكلمة الطيبة صدقة',
  ];

  late String _currentTip;

  @override
  void initState() {
    super.initState();
    // Use the current day of the year as a seed so it changes daily
    final now = DateTime.now();
    final seed = now.year * 1000 + now.month * 100 + now.day;
    // We cannot import dart:math easily without adding it to the top.
    // Instead, we can do a simple hash or just use the seed directly since we just need an index.
    final index = seed % _tips.length;
    _currentTip = _tips[index];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppColors.gold, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _currentTip,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontFamily: 'Amiri',
                height: 1.7,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}
