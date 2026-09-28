import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/xp_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../xp/domain/entities/xp_gain_result.dart';
import '../../data/datasources/smart_wird_progress_store.dart';
import '../../domain/entities/azkar_entities.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../../domain/usecases/compose_smart_wird_usecase.dart';
import '../services/zikr_audio_service.dart';
import '../../../../core/widgets/talia_app_bar.dart';
import '../../../../core/router/app_router.dart';

/// A resumable recitation screen for the composed smart wird. Progress is
/// persisted continuously so the user can leave and come back mid-session;
/// completion awards XP once per day-part and can be shared as a card.
class SmartWirdPage extends StatefulWidget {
  const SmartWirdPage({super.key, this.currentTime});

  final DateTime? currentTime;

  @override
  State<SmartWirdPage> createState() => _SmartWirdPageState();
}

class _SmartWirdPageState extends State<SmartWirdPage> {
  final ComposeSmartWirdUsecase _compose = getIt<ComposeSmartWirdUsecase>();
  final AzkarRepository _repository = getIt<AzkarRepository>();
  final SmartWirdProgressStore _progressStore =
      getIt<SmartWirdProgressStore>();
  final ZikrAudioService _audioService = getIt<ZikrAudioService>();

  /// XP is a bonus, not a requirement: tests and minimal DI setups run
  /// without it, and completion never blocks on rewards.
  XpService? get _xpService =>
      getIt.isRegistered<XpService>() ? getIt<XpService>() : null;

  SmartWird? _wird;
  String? _error;
  bool _loading = true;
  final Map<String, int> _counts = {};
  int _currentCard = 0;
  XpGainResult? _xpResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final time = widget.currentTime ?? DateTime.now();
    final result = await _compose(now: time);
    if (!mounted) return;
    var failureMessage = '';
    SmartWird? wird;
    result.fold(
      (failure) => failureMessage = failure.message,
      (composed) => wird = composed,
    );
    if (failureMessage.isNotEmpty) {
      setState(() {
        _error = failureMessage;
        _loading = false;
      });
      return;
    }
    if (wird == null || wird!.isEmpty) {
      setState(() {
        _wird = wird;
        _loading = false;
      });
      return;
    }

    // Resume: restore today's persisted counts for this day-part.
    final saved = _progressStore.activeSession(time);
    if (saved != null && saved.dayPart == wird!.dayPart) {
      for (final item in wird!.items) {
        _counts[item.zikr.id] =
            (saved.counts[item.zikr.id] ?? 0).clamp(0, item.zikr.totalCount);
      }
      // Jump to the first unfinished card so the user continues seamlessly.
      final resumeIndex = wird!.items
          .indexWhere((item) => (_counts[item.zikr.id] ?? 0) < item.zikr.totalCount);
      _currentCard = resumeIndex == -1 ? 0 : resumeIndex;
    }

    // Pre-resolve the full corpus for pure re-composition on later events.
    final corpusResult = await _repository.getAllAzkar();
    if (!mounted) return;
    Map<AzkarCategory, List<Zikr>>? corpus;
    corpusResult.fold((_) => corpus = null, (data) => corpus = data);

    setState(() {
      _wird = wird;
      _corpus = corpus;
      _loading = false;
    });
    unawaited(_persistProgress());
  }

  Map<AzkarCategory, List<Zikr>>? _corpus;

  SmartWird get _recomposed {
    final wird = _wird!;
    if (_corpus == null) return wird;
    // Re-run the pure composer so day-part ordering stays consistent with the
    // persisted counts even if the corpus changed between sessions.
    return _compose.composeFromCorpus(_corpus!, wird.dayPart, wird.composedAt);
  }

  Future<void> _persistProgress() async {
    final wird = _wird;
    if (wird == null) return;
    final counts = {
      for (final entry in _counts.entries)
        if (entry.value > 0) entry.key: entry.value,
    };
    if (counts.isEmpty) return;
    await _progressStore.saveActiveSession(
      SmartWirdSession(
        dayPart: wird.dayPart,
        counts: counts,
        updatedAt: widget.currentTime ?? DateTime.now(),
      ),
      widget.currentTime,
    );
  }

  PageController? _pageController;

  void _bump(SmartWirdItem item) {
    final id = item.zikr.id;
    final next = (_counts[id] ?? 0) + 1;
    if (next > item.zikr.totalCount) return;
    if (next == item.zikr.totalCount) {
      unawaited(HapticFeedback.heavyImpact());
    } else {
      unawaited(HapticFeedback.lightImpact());
    }
    setState(() => _counts[id] = next);
    unawaited(_persistProgress());

    if (_allDone) {
      unawaited(_onSessionComplete());
      return;
    }

    // Completed card: advance to the next unfinished one (or the last card
    // when everything ahead is done) so the recitation keeps flowing.
    if (next >= item.zikr.totalCount) {
      final wird = _wird!;
      var target = wird.items
          .indexWhere((i) => (_counts[i.zikr.id] ?? 0) < i.zikr.totalCount);
      if (target == -1) {
        target = wird.items.length - 1;
      }
      if (target != _currentCard) {
        _pageController ??= PageController(initialPage: _currentCard);
        _pageController!.animateToPage(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _undo(SmartWirdItem item) {
    final id = item.zikr.id;
    final current = _counts[id] ?? 0;
    if (current == 0) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _counts[id] = current - 1);
    unawaited(_persistProgress());
  }

  void _reset() {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _counts.clear();
      _currentCard = 0;
    });
    unawaited(_progressStore.clearActiveSession(widget.currentTime));
  }

  bool get _allDone {
    final wird = _wird;
    if (wird == null || wird.isEmpty) return false;
    return wird.items.every(
      (item) => (_counts[item.zikr.id] ?? 0) >= item.zikr.totalCount,
    );
  }

  int get _completedCount => _wird!.items
      .where((item) => (_counts[item.zikr.id] ?? 0) >= item.zikr.totalCount)
      .length;

  Future<void> _onSessionComplete() async {
    final wird = _recomposed;
    try {
      await _progressStore.recordCompletion(
        dayPart: wird.dayPart,
        itemIds: wird.items.map((item) => item.zikr.id).toList(),
        date: widget.currentTime,
      );
      await _progressStore.clearActiveSession(widget.currentTime);

      // XP once per day-part per calendar day.
      final prefs = getIt<SharedPreferences>();
      final now = widget.currentTime ?? DateTime.now();
      final xpKey =
          'azkar_smart_wird_xp:${now.year}-${now.month}-${now.day}-${wird.dayPart.name}';
      if (prefs.getString(xpKey) == null) {
        await prefs.setString(xpKey, '1');
        final xpService = _xpService;
        if (xpService != null) {
          final result = await xpService.addXp('smart_wird_completed');
          if (mounted && result.xpAdded > 0) {
            setState(() => _xpResult = result);
          }
        }
      }
    } catch (_) {
      // Rewards never block the completion moment.
    }
  }

  void _shareSession() {
    unawaited(HapticFeedback.lightImpact());
    final wird = _wird!;
    final data = SocialShareData.azkarWird(
      categoryTitle: context.l10n.azkarSmartWird,
      completedCount: _completedCount,
      totalCount: wird.items.length,
    );
    SocialShareSheet.show(context, data);
  }

  void _openIndexSheet() {
    unawaited(HapticFeedback.selectionClick());
    final wird = _wird!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Directionality(
        textDirection: Directionality.of(context),
        child: Material(
          color: context.tokens.surface,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.tokens.textHint
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.l10n.azkarIndex,
                    style: AppTypography.headlineSmall.copyWith(
                      color: context.tokens.textPrimary,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: wird.items.length,
                    itemBuilder: (context, index) {
                      final item = wird.items[index];
                      final count = _counts[item.zikr.id] ?? 0;
                      final done = count >= item.zikr.totalCount;
                      return ListTile(
                        leading: Icon(
                          done
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: done ? AppColors.success : AppColors.primary,
                        ),
                        title: Text(
                          item.zikr.reference.isNotEmpty
                              ? item.zikr.reference
                              : context.l10n.zikrNumber(index + 1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.tokens.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '$count / ${item.zikr.totalCount}',
                          style: AppTypography.labelSmall.copyWith(
                            color: context.tokens.textSecondary,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          setState(() => _currentCard = index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final background =
        context.tokens.background;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: _loading
            ? const Center(child: LoadingWidget())
            : _error != null
                ? ErrorStateWidget(message: _error!, onRetry: _load)
                : _wird == null || _wird!.isEmpty
                    ? EmptyStateWidget(
                        key: const ValueKey('azkar-content-under-review'),
                        message: context.l10n.azkarContentUnderReview,
                        icon: Icons.pending_actions_rounded,
                      )
                    : _allDone
                        ? _SmartWirdDoneView(
                            completed: _completedCount,
                            total: _wird!.items.length,
                            xpResult: _xpResult,
                            onReset: _reset,
                            onShare: _shareSession,
                          )
                        : _buildSession(context, isDark),
      ),
    );
  }

  Widget _buildSession(BuildContext context, bool isDark) {
    final wird = _wird!;
    final totalItems = wird.items.length;
    final completed = _completedCount;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const BackButtonIcon(),
                color: context.tokens.textPrimary,
                onPressed: () {
                  TaliaBackButton.navigateBack(
                    context,
                    fallbackLocation: AppRoutes.azkar,
                  );
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.azkarSmartWird,
                      style: AppTypography.headlineSmall.copyWith(
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.w700,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                    Text(
                      context.l10n.completedCount(completed, totalItems),
                      style: AppTypography.labelMedium.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.azkarIndex,
                icon: Icon(
                  Icons.format_list_bulleted_rounded,
                  color: context.tokens.textPrimary,
                ),
                onPressed: _openIndexSheet,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: LinearProgressIndicator(
              value: totalItems == 0 ? 0 : completed / totalItems,
              backgroundColor:
                  context.tokens.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              minHeight: 4,
            ),
          ),
        ),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: _pageController ??= PageController(
                initialPage: _currentCard,
              ),
              itemCount: totalItems,
              onPageChanged: (index) => setState(() => _currentCard = index),
              itemBuilder: (context, index) {
                final item = wird.items[index];
                final count = _counts[item.zikr.id] ?? 0;
                final done = count >= item.zikr.totalCount;
                return _SmartWirdCard(
                  item: item,
                  count: count,
                  done: done,
                  isDark: isDark,
                  onTap: () => _bump(item),
                  onLongPress: () => _undo(item),
                  onToggleAudio: () => _audioService.toggle(item.zikr),
                  hasAudio: _audioService.hasAudio(item.zikr),
                  isAudioPlaying: _audioService.state.isPlaying &&
                      _audioService.state.zikrId == item.zikr.id,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SmartWirdCard extends StatelessWidget {
  const _SmartWirdCard({
    required this.item,
    required this.count,
    required this.done,
    required this.isDark,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleAudio,
    required this.hasAudio,
    required this.isAudioPlaying,
  });

  final SmartWirdItem item;
  final int count;
  final bool done;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleAudio;
  final bool hasAudio;
  final bool isAudioPlaying;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        context.tokens.textPrimary;
    final textSecondary =
        context.tokens.textSecondary;
    final card = context.tokens.card;
    final border = context.tokens.divider;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              onLongPress: onLongPress,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (hasAudio)
                            IconButton(
                              tooltip: isAudioPlaying
                                  ? context.l10n.azkarPauseRecitation
                                  : context.l10n.azkarPlayRecitation,
                              icon: Icon(
                                isAudioPlaying
                                    ? Icons.pause_circle_rounded
                                    : Icons.play_circle_rounded,
                                size: 22,
                                color: AppColors.primary,
                              ),
                              onPressed: onToggleAudio,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Column(
                          children: [
                            Text(
                              item.zikr.text,
                              style: AppTypography.azkarText.copyWith(
                                color: textPrimary,
                                fontSize: 25,
                                height: 1.9,
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                            ),
                            if (item.zikr.reference.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Text(
                                item.zikr.reference,
                                style: AppTypography.titleMedium.copyWith(
                                  color: textSecondary,
                                  fontFamily: 'Amiri',
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                                textDirection: TextDirection.rtl,
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
            ),
          ),
          const SizedBox(height: 20),
          _CounterDial(
            count: count,
            total: item.zikr.totalCount,
            done: done,
            isDark: isDark,
            onTap: onTap,
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.longPressToUndo,
            style: AppTypography.labelSmall.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CounterDial extends StatelessWidget {
  const _CounterDial({
    required this.count,
    required this.total,
    required this.done,
    required this.isDark,
    required this.onTap,
  });

  final int count;
  final int total;
  final bool done;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: context.l10n.tapToTasbeeh(total),
      value: '$count / $total',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: total == 0 ? 1.0 : count / total,
                ),
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  backgroundColor:
                      context.tokens.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    done ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            ),
            Container(
              width: 122,
              height: 122,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done
                    ? const LinearGradient(
                        colors: [AppColors.success, Color(0xFF1E5D46)],
                      )
                    : LinearGradient(
                        colors: isDark
                            ? [AppColors.primary, AppColors.primaryDark]
                            : [AppColors.primaryLight, AppColors.primary],
                      ),
              ),
              alignment: Alignment.center,
              child: done
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 38,
                    )
                  : Text(
                      '$count',
                      style: AppTypography.displayMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartWirdDoneView extends StatelessWidget {
  const _SmartWirdDoneView({
    required this.completed,
    required this.total,
    required this.xpResult,
    required this.onReset,
    required this.onShare,
  });

  final int completed;
  final int total;
  final XpGainResult? xpResult;
  final VoidCallback onReset;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        context.tokens.textPrimary;
    final textSecondary =
        context.tokens.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.primaryDark],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.azkarSmartWirdCompleted,
              style: AppTypography.displaySmall.copyWith(
                fontFamily: 'Amiri',
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.completedCount(completed, total),
              style: AppTypography.bodyLarge.copyWith(
                color: textSecondary,
              ),
            ),
            if (xpResult != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '+${xpResult!.xpAdded} XP',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
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
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(context.l10n.azkarShareWird),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              icon: const Icon(Icons.home_rounded, size: 18),
              label: Text(context.l10n.home),
            ),
          ],
        ),
      ),
    );
  }
}
