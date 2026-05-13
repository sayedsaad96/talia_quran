import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/azkar_entities.dart';
import '../cubits/azkar_cubit.dart';

class AzkarCategoryPage extends StatelessWidget {
  const AzkarCategoryPage({super.key, required this.category});
  final String category;

  AzkarCategory get _category => switch (category) {
    'morning' => AzkarCategory.morning,
    'evening' => AzkarCategory.evening,
    'duas' => AzkarCategory.duas,
    _ => AzkarCategory.general,
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AzkarCubit>()..load(_category),
      child: _AzkarCategoryView(category: _category),
    );
  }
}

class _AzkarCategoryView extends StatelessWidget {
  const _AzkarCategoryView({required this.category});
  final AzkarCategory category;

  String _title(BuildContext ctx) => switch (category) {
    AzkarCategory.morning => ctx.l10n.morningAzkar,
    AzkarCategory.evening => ctx.l10n.eveningAzkar,
    AzkarCategory.general => ctx.l10n.generalAzkar,
    AzkarCategory.duas => ctx.l10n.duas,
  };

  List<Color> _gradientColors() => switch (category) {
    AzkarCategory.morning => [const Color(0xFFFF8C42), const Color(0xFFFF6B00)],
    AzkarCategory.evening => [const Color(0xFF2D5A8E), const Color(0xFF1A3A5C)],
    AzkarCategory.general => [AppColors.primary, AppColors.primaryDark],
    AzkarCategory.duas => [const Color(0xFFE11D48), const Color(0xFF881337)],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final gradColors = _gradientColors();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: BlocBuilder<AzkarCubit, AzkarState>(
        builder: (context, state) {
          if (state is AzkarLoading) {
            return const Center(child: LoadingWidget());
          }
          if (state is AzkarError) {
            return ErrorStateWidget(message: state.message);
          }
          if (state is AzkarLoaded) {
            if (state.allDone) {
              return _CompletionScreen(
                isDark: isDark,
                gradColors: gradColors,
                onReset: () => context.read<AzkarCubit>().reset(),
              );
            }
            return _ActiveAzkarScreen(
              state: state,
              title: _title(context),
              isDark: isDark,
              gradColors: gradColors,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ActiveAzkarScreen extends StatefulWidget {
  const _ActiveAzkarScreen({
    required this.state,
    required this.title,
    required this.isDark,
    required this.gradColors,
  });

  final AzkarLoaded state;
  final String title;
  final bool isDark;
  final List<Color> gradColors;

  @override
  State<_ActiveAzkarScreen> createState() => _ActiveAzkarScreenState();
}

class _ActiveAzkarScreenState extends State<_ActiveAzkarScreen> {
  static const _fontSizes = [22.0, 26.0, 30.0];
  int _fontSizeIndex = 1;

  void _cycleFontSize() {
    setState(() => _fontSizeIndex = (_fontSizeIndex + 1) % _fontSizes.length);
    HapticFeedback.selectionClick();
  }

  Future<void> _copyZikr(BuildContext context, ZikrSession session) async {
    await HapticFeedback.lightImpact();
    final text = _shareableText(session);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ الذكر')));
  }

  void _shareZikr(ZikrSession session) {
    unawaited(HapticFeedback.lightImpact());
    unawaited(
      SharePlus.instance.share(ShareParams(text: _shareableText(session))),
    );
  }

  String _shareableText(ZikrSession session) {
    final reference = session.zikr.reference.trim();
    return [
      session.zikr.text.trim(),
      if (reference.isNotEmpty) reference,
      'تمت المشاركة من تطبيق تالية للقرآن',
    ].join('\n\n');
  }

  void _openIndexSheet(BuildContext context, _AzkarSessionPalette palette) {
    HapticFeedback.selectionClick();
    final cubit = context.read<AzkarCubit>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 460),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.mutedText.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(
                    'فهرس الأذكار',
                    style: AppTypography.headlineSmall.copyWith(
                      color: palette.text,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: widget.state.sessions.length,
                    separatorBuilder: (_, _) => Divider(
                      color: palette.border.withValues(alpha: 0.55),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final session = widget.state.sessions[index];
                      final selected = index == widget.state.currentIndex;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? palette.gold
                              : palette.border.withValues(alpha: 0.7),
                          foregroundColor: selected
                              ? palette.onGold
                              : palette.text,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          session.zikr.reference.isNotEmpty
                              ? session.zikr.reference
                              : 'ذكر رقم ${index + 1}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: palette.text,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${session.currentCount} من ${session.zikr.totalCount}',
                          style: AppTypography.labelSmall.copyWith(
                            color: palette.mutedText,
                          ),
                        ),
                        trailing: session.isDone
                            ? Icon(Icons.check_circle, color: palette.gold)
                            : null,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          cubit.goTo(index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.state.current;
    final palette = _AzkarSessionPalette.resolve(widget.isDark);
    final total = widget.state.sessions.length;
    final completedPercent = total == 0
        ? 0.0
        : widget.state.completedCount / total;
    final percentLabel = '${(completedPercent * 100).round()}%';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: palette.background,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _AzkarBackdropPainter(palette: palette),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _SessionHeader(
                    title: widget.title,
                    state: widget.state,
                    palette: palette,
                    completedPercent: completedPercent,
                    percentLabel: percentLabel,
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    onReset: () => context.read<AzkarCubit>().reset(),
                    onFontSize: _cycleFontSize,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      child: Column(
                        children: [
                          Expanded(
                            child: Transform.translate(
                              offset: const Offset(0, -6),
                              child:
                                  _ZikrGlassCard(
                                        session: session,
                                        palette: palette,
                                        fontSize: _fontSizes[_fontSizeIndex],
                                        onShare: () => _shareZikr(session),
                                        onCopy: () => _copyZikr(context, session),
                                      )
                                      .animate()
                                      .fadeIn(duration: 260.ms)
                                      .slideY(begin: 0.04, end: 0),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CounterWidget(
                            session: session,
                            palette: palette,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.read<AzkarCubit>().increment();
                            },
                          ),
                          const SizedBox(height: 12),
                          _SessionNavigation(
                            palette: palette,
                            canGoPrevious: widget.state.currentIndex > 0,
                            canGoNext:
                                widget.state.currentIndex <
                                widget.state.sessions.length - 1,
                            onPrevious: () => context.read<AzkarCubit>().goTo(
                              widget.state.currentIndex - 1,
                            ),
                            onNext: () => context.read<AzkarCubit>().goNext(),
                            onIndex: () => _openIndexSheet(context, palette),
                          ),
                        ],
                      ),
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

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.title,
    required this.state,
    required this.palette,
    required this.completedPercent,
    required this.percentLabel,
    required this.onBack,
    required this.onReset,
    required this.onFontSize,
  });

  final String title;
  final AzkarLoaded state;
  final _AzkarSessionPalette palette;
  final double completedPercent;
  final String percentLabel;
  final VoidCallback onBack;
  final VoidCallback onReset;
  final VoidCallback onFontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                _RoundIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  palette: palette,
                  size: 48,
                  iconSize: 20,
                  onPressed: onBack,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeaderFlourish(palette: palette),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.displaySmall.copyWith(
                            color: palette.text,
                            fontFamily: 'Amiri',
                            fontSize: 26,
                            shadows: palette.textShadow,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _HeaderFlourish(palette: palette),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.refresh_rounded,
                      palette: palette,
                      size: 48,
                      iconSize: 20,
                      onPressed: onReset,
                    ),
                    const SizedBox(width: 8),
                    _RoundTextButton(
                      label: 'Aa',
                      palette: palette,
                      size: 48,
                      fontSize: 16,
                      onPressed: onFontSize,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${state.completedCount} من ${state.sessions.length} مكتمل',
            style: AppTypography.bodyLarge.copyWith(
              color: palette.mutedText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 10,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: palette.gold.withValues(alpha: 0.65),
                    ),
                    color: palette.recessed.withValues(alpha: 0.68),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: completedPercent,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(palette.gold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                percentLabel,
                style: AppTypography.headlineMedium.copyWith(
                  color: palette.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [palette.card, palette.recessed],
              ),
              border: Border.all(color: palette.border),
              boxShadow: [
                BoxShadow(
                  color: palette.gold.withValues(alpha: 0.16),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _EightPointStarPainter(color: palette.gold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZikrGlassCard extends StatelessWidget {
  const _ZikrGlassCard({
    required this.session,
    required this.palette,
    required this.fontSize,
    required this.onShare,
    required this.onCopy,
  });

  final ZikrSession session;
  final _AzkarSessionPalette palette;
  final double fontSize;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.shadowOpacity),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Text(
                        session.zikr.text,
                        style: AppTypography.azkarText.copyWith(
                          color: palette.text,
                          fontSize: fontSize,
                          height: 2.05,
                          shadows: palette.textShadow,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (session.zikr.reference.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Divider(color: palette.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    session.zikr.reference,
                    style: AppTypography.titleMedium.copyWith(
                      color: palette.gold,
                      fontFamily: 'Amiri',
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(child: Divider(color: palette.border)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CardActionButton(
                  icon: Icons.share_rounded,
                  label: 'مشاركة',
                  palette: palette,
                  onPressed: onShare,
                ),
              ),
              Container(width: 1, height: 36, color: palette.border),
              Expanded(
                child: _CardActionButton(
                  icon: Icons.copy_rounded,
                  label: 'نسخ',
                  palette: palette,
                  onPressed: onCopy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterWidget extends StatefulWidget {
  const _CounterWidget({
    required this.session,
    required this.palette,
    required this.onTap,
  });

  final ZikrSession session;
  final _AzkarSessionPalette palette;
  final VoidCallback onTap;

  @override
  State<_CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<_CounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.session.isDone) return;
    _pulseCtrl.forward().then((_) => _pulseCtrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final palette = widget.palette;
    final isDone = session.isDone;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final double counterSize = screenHeight < 700 ? 160 : 200;
    final double innerSize = counterSize - 24;
    final double progressSize = counterSize - 10;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 16,
          child: CustomPaint(
            size: const Size(54, 76),
            painter: _SideFlourishPainter(color: palette.gold),
          ),
        ),
        Positioned(
          right: 16,
          child: Transform.scale(
            scaleX: -1,
            child: CustomPaint(
              size: const Size(54, 76),
              painter: _SideFlourishPainter(color: palette.gold),
            ),
          ),
        ),
        GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) =>
                Transform.scale(scale: _pulseAnim.value, child: child),
            child: SizedBox(
              width: counterSize,
              height: counterSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: innerSize,
                    height: innerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.recessed,
                      border: Border.all(
                        color: palette.border.withValues(alpha: 0.85),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.gold.withValues(alpha: 0.18),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: progressSize,
                    height: progressSize,
                    child: CircularProgressIndicator(
                      value: session.progress,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: palette.border.withValues(alpha: 0.52),
                      valueColor: AlwaysStoppedAnimation<Color>(palette.gold),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDone)
                        Icon(Icons.check_rounded, color: palette.text, size: counterSize * 0.26)
                      else
                        Text(
                          '${session.currentCount}',
                          style: AppTypography.displayLarge.copyWith(
                            color: palette.text,
                            fontSize: counterSize * 0.26,
                            height: 1,
                            shadows: palette.textShadow,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'من ${session.zikr.totalCount}',
                        style: AppTypography.bodyLarge.copyWith(
                          color: palette.text,
                          fontSize: counterSize * 0.08,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDone ? 'اكتمل الذكر' : 'اضغط للتسبيح',
                        style: AppTypography.bodyMedium.copyWith(
                          color: palette.text,
                          fontFamily: 'Amiri',
                          fontSize: counterSize * 0.08,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionNavigation extends StatelessWidget {
  const _SessionNavigation({
    required this.palette,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onIndex,
  });

  final _AzkarSessionPalette palette;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onIndex;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          Expanded(
            child: _NavPillButton(
              label: 'السابق',
              icon: Icons.chevron_left_rounded,
              enabled: canGoPrevious,
              palette: palette,
              onPressed: onPrevious,
            ),
          ),
          const SizedBox(width: 14),
          _RoundIconButton(
            icon: Icons.format_list_bulleted_rounded,
            palette: palette,
            size: 56,
            iconSize: 24,
            onPressed: onIndex,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _NavPillButton(
              label: 'التالي',
              icon: Icons.chevron_right_rounded,
              iconAfterLabel: true,
              enabled: canGoNext,
              palette: palette,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavPillButton extends StatelessWidget {
  const _NavPillButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.palette,
    required this.onPressed,
    this.iconAfterLabel = false,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final _AzkarSessionPalette palette;
  final VoidCallback onPressed;
  final bool iconAfterLabel;

  @override
  Widget build(BuildContext context) {
    final content = [
      Icon(icon, color: palette.gold, size: 28),
      const SizedBox(width: 8),
      Text(
        label,
        style: AppTypography.titleLarge.copyWith(
          color: palette.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: iconAfterLabel ? content.reversed.toList() : content,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final _AzkarSessionPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: palette.text,
        padding: const EdgeInsets.symmetric(vertical: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.recessed.withValues(alpha: 0.65),
              border: Border.all(color: palette.border.withValues(alpha: 0.65)),
            ),
            child: Icon(icon, size: 20, color: palette.text),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: palette.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.palette,
    required this.onPressed,
    this.size = 56,
    this.iconSize = 24,
  });

  final IconData icon;
  final _AzkarSessionPalette palette;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.button,
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: palette.text, size: iconSize),
        ),
      ),
    );
  }
}

class _RoundTextButton extends StatelessWidget {
  const _RoundTextButton({
    required this.label,
    required this.palette,
    required this.onPressed,
    this.size = 56,
    this.fontSize = 20,
  });

  final String label;
  final _AzkarSessionPalette palette;
  final VoidCallback onPressed;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.button,
            border: Border.all(color: palette.border),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.titleLarge.copyWith(
                color: palette.text,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderFlourish extends StatelessWidget {
  const _HeaderFlourish({required this.palette});

  final _AzkarSessionPalette palette;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 34),
      painter: _HeaderFlourishPainter(color: palette.gold),
    );
  }
}

class _AzkarSessionPalette {
  const _AzkarSessionPalette({
    required this.background,
    required this.card,
    required this.recessed,
    required this.button,
    required this.border,
    required this.text,
    required this.mutedText,
    required this.gold,
    required this.onGold,
    required this.shadowOpacity,
    required this.textShadow,
  });

  final List<Color> background;
  final Color card;
  final Color recessed;
  final Color button;
  final Color border;
  final Color text;
  final Color mutedText;
  final Color gold;
  final Color onGold;
  final double shadowOpacity;
  final List<Shadow> textShadow;

  static _AzkarSessionPalette resolve(bool isDark) {
    if (isDark) {
      return const _AzkarSessionPalette(
        background: [Color(0xFF061728), Color(0xFF0A2438), Color(0xFF06131F)],
        card: Color(0xCC102B42),
        recessed: Color(0xFF092035),
        button: Color(0x66162D40),
        border: Color(0x554A6E89),
        text: Color(0xFFF8F1E5),
        mutedText: Color(0xCCF8F1E5),
        gold: Color(0xFFF2BE64),
        onGold: Color(0xFF102235),
        shadowOpacity: 0.32,
        textShadow: [
          Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      );
    }
    return const _AzkarSessionPalette(
      background: [Color(0xFFFFFBF2), Color(0xFFF4E8D3), Color(0xFFEAD8B8)],
      card: Color(0xEFFFFFFF),
      recessed: Color(0xFFFFF6E7),
      button: Color(0xDDFFF8EA),
      border: Color(0x66B99043),
      text: Color(0xFF1F2D2A),
      mutedText: Color(0xB21F2D2A),
      gold: Color(0xFFC7953F),
      onGold: Color(0xFFFFFFFF),
      shadowOpacity: 0.09,
      textShadow: [],
    );
  }
}

class _AzkarBackdropPainter extends CustomPainter {
  const _AzkarBackdropPainter({required this.palette});

  final _AzkarSessionPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final horizonPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          palette.gold.withValues(alpha: 0.0),
          palette.gold.withValues(alpha: 0.34),
          palette.gold.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45));
    final y = size.height * 0.18;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, y + 28),
        width: size.width * 0.9,
        height: 80,
      ),
      horizonPaint,
    );

    final silhouette = Paint()
      ..color = palette.recessed.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, y + 52)
      ..quadraticBezierTo(size.width * 0.25, y + 35, size.width * 0.5, y + 50)
      ..quadraticBezierTo(size.width * 0.72, y + 65, size.width, y + 44)
      ..lineTo(size.width, y + 96)
      ..lineTo(0, y + 96)
      ..close();
    canvas.drawPath(path, silhouette);

    for (final x in [size.width * 0.08, size.width * 0.18, size.width * 0.84]) {
      canvas.drawCircle(Offset(x, y + 44), 22, silhouette);
      canvas.drawRect(Rect.fromLTWH(x - 18, y + 44, 36, 40), silhouette);
    }
    for (final x in [size.width * 0.28, size.width * 0.78, size.width * 0.92]) {
      canvas.drawRect(Rect.fromLTWH(x, y + 10, 5, 74), silhouette);
      canvas.drawCircle(Offset(x + 2.5, y + 8), 5, silhouette);
    }
  }

  @override
  bool shouldRepaint(_AzkarBackdropPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}

class _EightPointStarPainter extends CustomPainter {
  const _EightPointStarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    for (final rotation in [0.0, math.pi / 4]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.42,
          height: size.height * 0.42,
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(center, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_EightPointStarPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _HeaderFlourishPainter extends CustomPainter {
  const _HeaderFlourishPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final mid = size.height / 2;
    canvas.drawLine(
      Offset(size.width / 2, 4),
      Offset(size.width / 2, size.height - 4),
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, mid),
        width: 18,
        height: 18,
      ),
      -math.pi / 2,
      math.pi,
      false,
      paint,
    );
    canvas.drawCircle(Offset(size.width / 2, mid), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HeaderFlourishPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SideFlourishPainter extends CustomPainter {
  const _SideFlourishPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final path = Path()
      ..moveTo(size.width * 0.8, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.5,
        size.width * 0.8,
        size.height * 0.88,
      );
    canvas.drawPath(path, paint);
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.28 + i * 0.18);
      canvas.drawPath(
        Path()
          ..moveTo(size.width * 0.5, y)
          ..lineTo(size.width * 0.25, y + 8)
          ..lineTo(size.width * 0.5, y + 16),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SideFlourishPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({
    required this.isDark,
    required this.gradColors,
    required this.onReset,
  });

  final bool isDark;
  final List<Color> gradColors;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradColors,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradColors[0].withValues(alpha: 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 56,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'تم بحمد الله',
              style: AppTypography.displaySmall.copyWith(
                fontFamily: 'Amiri',
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'اكتملت جميع الأذكار',
              style: AppTypography.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('إعادة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: gradColors[0],
                      side: BorderSide(
                        color: gradColors[0].withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: Text(context.l10n.home),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gradColors[0],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
