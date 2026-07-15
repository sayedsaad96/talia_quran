import 'dart:async';

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

  @override
  Widget build(BuildContext context) {
    final isDark = switch (category) {
      AzkarCategory.evening => true,
      AzkarCategory.morning => false,
      _ => context.isDark,
    };

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
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<AzkarCubit>().load(category),
            );
          }
          if (state is AzkarLoaded) {
            if (state.allDone) {
              return _CompletionScreen(
                isDark: isDark,
                onReset: () => context.read<AzkarCubit>().reset(),
              );
            }
            return _ActiveAzkarScreen(
              state: state,
              title: _title(context),
              isDark: isDark,
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
  });

  final AzkarLoaded state;
  final String title;
  final bool isDark;

  @override
  State<_ActiveAzkarScreen> createState() => _ActiveAzkarScreenState();
}

class _ActiveAzkarScreenState extends State<_ActiveAzkarScreen> {
  static const _fontSizes = [22.0, 26.0, 30.0];
  int _fontSizeIndex = 1;
  late PageController _pageController;
  Timer? _undoTimer;
  bool _showUndo = false;
  int? _undoIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.state.currentIndex);
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _cycleFontSize() {
    setState(() => _fontSizeIndex = (_fontSizeIndex + 1) % _fontSizes.length);
    HapticFeedback.selectionClick();
  }

  Future<void> _copyZikr(BuildContext context, ZikrSession session) async {
    final text = _shareableText(context, session);
    await HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.zikrCopied)));
  }

  void _shareZikr(BuildContext context, ZikrSession session) {
    unawaited(HapticFeedback.lightImpact());
    unawaited(
      SharePlus.instance.share(
        ShareParams(text: _shareableText(context, session)),
      ),
    );
  }

  void _handleCounterTap(BuildContext context, int index, ZikrSession session) {
    if (session.isDone) {
      HapticFeedback.selectionClick();
      context.read<AzkarCubit>().goNextUnfinished();
      return;
    }

    final willComplete = session.currentCount + 1 >= session.zikr.totalCount;
    if (willComplete) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    context.read<AzkarCubit>().increment();

    _undoTimer?.cancel();
    setState(() {
      _showUndo = true;
      _undoIndex = index;
    });
    _undoTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showUndo = false);
    });
  }

  Future<void> _undoLastCount(BuildContext context) async {
    final index = _undoIndex;
    if (index == null) return;

    final cubit = context.read<AzkarCubit>();
    cubit.goTo(index);
    await cubit.decrementCurrent();
    await HapticFeedback.selectionClick();
    _undoTimer?.cancel();
    if (mounted) {
      setState(() => _showUndo = false);
    }
  }

  String _shareableText(BuildContext context, ZikrSession session) {
    final reference = session.zikr.reference.trim();
    return [
      session.zikr.text.trim(),
      if (reference.isNotEmpty) reference,
      context.l10n.sharedFromTalia,
    ].join('\n\n');
  }

  void _openIndexSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    final cubit = context.read<AzkarCubit>();
    final isDark = widget.isDark;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: Directionality.of(context),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 460),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint)
                            .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(
                    context.l10n.azkarIndex,
                    style: AppTypography.headlineSmall.copyWith(
                      color: textColor,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: widget.state.sessions.length,
                    separatorBuilder: (_, _) => Divider(
                      color: (isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider),
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
                              ? AppColors.gold
                              : (isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.lightSurfaceVariant),
                          foregroundColor: selected ? Colors.white : textColor,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          session.zikr.reference.isNotEmpty
                              ? session.zikr.reference
                              : context.l10n.zikrNumber(index + 1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textColor,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          context.l10n.miniProgressOf(
                            session.zikr.totalCount,
                            session.currentCount,
                          ),
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        trailing: session.isDone
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                              )
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
    final total = widget.state.sessions.length;
    final completedPercent = total == 0
        ? 0.0
        : widget.state.completedCount / total;

    return BlocListener<AzkarCubit, AzkarState>(
      listenWhen: (previous, current) {
        if (previous is AzkarLoaded && current is AzkarLoaded) {
          return previous.currentIndex != current.currentIndex;
        }
        return false;
      },
      listener: (context, state) {
        if (state is AzkarLoaded && _pageController.hasClients) {
          _pageController.animateToPage(
            state.currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: SafeArea(
        child: Column(
          children: [
            // ─── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: AppTypography.headlineSmall.copyWith(
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.w700,
                            color: widget.isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.completedCount(
                            widget.state.completedCount,
                            widget.state.sessions.length,
                          ),
                          style: AppTypography.labelMedium.copyWith(
                            color: widget.isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_size_rounded),
                    color: widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    onPressed: _cycleFontSize,
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted_rounded),
                    color: widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    onPressed: () => _openIndexSheet(context),
                  ),
                ],
              ),
            ),

            // ─── Progress Bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: completedPercent,
                  backgroundColor: widget.isDark
                      ? AppColors.darkDivider
                      : AppColors.lightDivider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.gold,
                  ),
                  minHeight: 4,
                ),
              ),
            ),

            // ─── PageView (Zikr Content) ─────────────────────────────
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    context.read<AzkarCubit>().goTo(index);
                  },
                  itemCount: widget.state.sessions.length,
                  itemBuilder: (context, index) {
                    final session = widget.state.sessions[index];
                    return _ZikrReaderPage(
                      session: session,
                      fontSize: _fontSizes[_fontSizeIndex],
                      isDark: widget.isDark,
                      showUndo: _showUndo && _undoIndex == index,
                      onTap: () => _handleCounterTap(context, index, session),
                      onLongPress: () => _undoLastCount(context),
                      onUndo: () => _undoLastCount(context),
                      onShare: () => _shareZikr(context, session),
                      onCopy: () => _copyZikr(context, session),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZikrReaderPage extends StatelessWidget {
  const _ZikrReaderPage({
    required this.session,
    required this.fontSize,
    required this.isDark,
    required this.showUndo,
    required this.onTap,
    required this.onLongPress,
    required this.onUndo,
    required this.onShare,
    required this.onCopy,
  });

  final ZikrSession session;
  final double fontSize;
  final bool isDark;
  final bool showUndo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onUndo;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // ─── Reading Area ────────────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Actions Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 20,
                            color: secondaryColor,
                          ),
                          onPressed: onCopy,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.share_rounded,
                            size: 20,
                            color: secondaryColor,
                          ),
                          onPressed: onShare,
                        ),
                      ],
                    ),
                  ),

                  // Text Area
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        children: [
                          Text(
                            session.zikr.text,
                            style: AppTypography.azkarText.copyWith(
                              color: textColor,
                              fontSize: fontSize,
                              height: 1.9,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                          ),
                          if (session.zikr.reference.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Divider(color: borderColor),
                            const SizedBox(height: 12),
                            Text(
                              session.zikr.reference,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.gold,
                                fontFamily: 'Amiri',
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // ─── Tap Target (Circular Counter) ──────────────────────
          GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circular Progress
                SizedBox(
                  width: 160,
                  height: 160,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: session.zikr.totalCount == 0 ? 1.0 : session.currentCount / session.zikr.totalCount,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 8,
                        backgroundColor: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          session.isDone ? AppColors.success : AppColors.gold,
                        ),
                      );
                    },
                  ),
                ),
                
                // The Button itself
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: session.isDone
                        ? const LinearGradient(
                            colors: [AppColors.success, Color(0xFF1E5D46)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: isDark
                                ? [AppColors.primary, AppColors.primaryDark]
                                : [AppColors.primaryLight, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: session.isDone
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (session.isDone)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 40,
                        ).animate().scale(
                          duration: 300.ms,
                          curve: Curves.easeOutBack,
                        )
                      else
                        Text(
                          '${session.currentCount}',
                          style: AppTypography.displayMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      
                      Text(
                        'من ${session.zikr.totalCount}',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Undo Hint
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: showUndo
                  ? TextButton.icon(
                      key: const ValueKey('undo'),
                      onPressed: onUndo,
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : AppColors.primary,
                        backgroundColor: (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.undo_rounded, size: 20),
                      label: Text(context.l10n.undo),
                    )
                  : Text(
                      key: const ValueKey('hint'),
                      context.l10n.longPressToUndo,
                      style: AppTypography.labelSmall.copyWith(
                        color: secondaryColor,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({required this.isDark, required this.onReset});

  final bool isDark;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryLight, AppColors.primaryDark],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
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
              context.l10n.azkarCompletedTitle,
              style: AppTypography.displaySmall.copyWith(
                fontFamily: 'Amiri',
                color: textColor,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.azkarCompletedDesc,
              style: AppTypography.bodyLarge.copyWith(color: secondaryColor),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(context.l10n.reset),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
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
                      backgroundColor: AppColors.primary,
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
