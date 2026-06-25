// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/v2/hint_usage.dart';
import '../../../../core/memorization/v2/session_phase.dart';
import '../../../../core/memorization/v2/session_state.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/qcf_hifz_verse_view.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../cubits/memorization_session_cubit.dart';

class V2SessionPage extends StatelessWidget {
  const V2SessionPage({
    super.key,
    required this.surahId,
    required this.startAyah,
    this.blockSize = 5,
  });

  final int surahId;
  final int startAyah;
  final int blockSize;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MemorizationSessionCubit>()
        ..startSession(
          surahId: surahId,
          startAyah: startAyah,
          blockSize: blockSize,
        ),
      child: const _V2SessionView(),
    );
  }
}

class _V2SessionView extends StatelessWidget {
  const _V2SessionView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.isArabic ? 'جلسة الحفظ' : 'Memorization Session'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<MemorizationSessionCubit, MemorizationSessionState>(
        listener: (context, state) {
          if (state is MSError) {
            context.showSnackBar(state.message, isError: true);
          }
        },
        builder: (context, state) {
          if (state is MSLoading || state is MSInitial) {
            return const Center(child: LoadingWidget());
          }
          if (state is MSError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.go(AppRoutes.memorizationPlus),
            );
          }
          if (state is MSCompleted) {
            return V2CompletionPage(finalState: state.finalState);
          }
          if (state is! MSActive) return const SizedBox.shrink();

          return switch (state.sessionState.phase) {
            V2SessionPhase.created ||
            V2SessionPhase.learning => V2LearningPage(state: state),
            V2SessionPhase.memorizing => V2MemorizingPage(state: state),
            V2SessionPhase.reciting => V2RecitationPage(state: state),
            V2SessionPhase.remediation => V2RemediationPage(state: state),
            V2SessionPhase.blockReviewPending => V2BlockReviewPendingPage(
              state: state,
            ),
            V2SessionPhase.blockReview => V2BlockReviewPage(state: state),
            V2SessionPhase.completed => V2CompletionPage(
              finalState: state.sessionState,
            ),
          };
        },
      ),
    );
  }
}

class V2LearningPage extends StatelessWidget {
  const V2LearningPage({super.key, required this.state});

  final MSActive state;

  @override
  Widget build(BuildContext context) {
    return _V2PhaseScaffold(
      session: state.sessionState,
      icon: Icons.menu_book_rounded,
      title: context.isArabic ? 'تعلّم الآية' : 'Learn the ayah',
      subtitle: context.isArabic
          ? 'استمع واقرأ الآية بهدوء قبل محاولة حفظها.'
          : 'Listen and read before trying to memorize.',
      primaryActionLabel: context.isArabic ? 'انتقل للحفظ' : 'Start memorizing',
      primaryActionIcon: Icons.psychology_rounded,
      onPrimaryAction: () =>
          context.read<MemorizationSessionCubit>().advanceToMemorizing(),
      children: [
        _AyahTextCard(session: state.sessionState),
        const SizedBox(height: AppSpacing.md),
        _AudioAction(
          isPlaying: state.isPlaying,
          onPressed: () =>
              context.read<MemorizationSessionCubit>().playCurrentAyah(),
        ),
      ],
    );
  }
}

class V2MemorizingPage extends StatelessWidget {
  const V2MemorizingPage({super.key, required this.state});

  final MSActive state;

  @override
  Widget build(BuildContext context) {
    final session = state.sessionState;
    final hintLevel = session.hintTracker.levelFor(
      session.surahId,
      session.currentAyah.numberInSurah,
    );

    return _V2PhaseScaffold(
      session: session,
      icon: Icons.psychology_rounded,
      title: context.isArabic ? 'احفظ الآية' : 'Memorize the ayah',
      subtitle: context.isArabic
          ? 'درّب ذاكرتك. التلميحات متاحة هنا فقط.'
          : 'Practice from memory. Hints are only available here.',
      primaryActionLabel: context.isArabic ? 'أنا جاهز للتسميع' : 'I am ready',
      primaryActionIcon: Icons.mic_rounded,
      onPrimaryAction: () =>
          context.read<MemorizationSessionCubit>().advanceToReciting(),
      children: [
        _HintCard(session: session, hintLevel: hintLevel),
        const SizedBox(height: AppSpacing.md),
        _AudioAction(
          isPlaying: state.isPlaying,
          onPressed: () =>
              context.read<MemorizationSessionCubit>().playCurrentAyah(),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _HintButton(
              label: context.isArabic ? 'أول كلمة' : 'First word',
              icon: Icons.short_text_rounded,
              onPressed: () => context.read<MemorizationSessionCubit>().useHint(
                V2HintLevel.firstWord,
              ),
            ),
            _HintButton(
              label: context.isArabic ? 'إظهار الآية' : 'Show ayah',
              icon: Icons.visibility_rounded,
              onPressed: () => context.read<MemorizationSessionCubit>().useHint(
                V2HintLevel.fullAyah,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class V2RecitationPage extends StatelessWidget {
  const V2RecitationPage({super.key, required this.state});

  final MSActive state;

  @override
  Widget build(BuildContext context) {
    final isRecording = state.isRecording;
    return _V2PhaseScaffold(
      session: state.sessionState,
      icon: Icons.mic_rounded,
      title: context.isArabic ? 'سمّع من حفظك' : 'Recite from memory',
      subtitle: context.isArabic
          ? 'النص مخفي الآن. سجّل تسميعك بدون تلميحات.'
          : 'The ayah text is hidden. Record without hints.',
      primaryActionLabel: isRecording
          ? (context.isArabic ? 'إيقاف التسجيل' : 'Stop recording')
          : (context.isArabic ? 'بدء التسجيل' : 'Start recording'),
      primaryActionIcon: isRecording ? Icons.stop_rounded : Icons.mic_rounded,
      onPrimaryAction: () {
        final cubit = context.read<MemorizationSessionCubit>();
        return isRecording ? cubit.stopRecording() : cubit.startRecording();
      },
      children: [
        _HiddenTextCard(
          isRecording: isRecording,
          isEvaluating: state.isEvaluating,
          speechIssue: state.speechIssue,
        ),
      ],
    );
  }
}

class V2RemediationPage extends StatelessWidget {
  const V2RemediationPage({super.key, required this.state});

  final MSActive state;

  @override
  Widget build(BuildContext context) {
    return _V2PhaseScaffold(
      session: state.sessionState,
      icon: Icons.healing_rounded,
      title: context.isArabic ? 'مراجعة قصيرة' : 'Short remediation',
      subtitle: context.isArabic
          ? 'استمع واقرأ الآية مرة أخرى، ثم ارجع لمحاولة التسميع.'
          : 'Listen and read again, then return to recitation.',
      primaryActionLabel: context.isArabic ? 'أحاول مرة أخرى' : 'Try again',
      primaryActionIcon: Icons.replay_rounded,
      onPrimaryAction: () =>
          context.read<MemorizationSessionCubit>().completeRemediation(),
      children: [
        _FailureSummary(session: state.sessionState),
        const SizedBox(height: AppSpacing.md),
        _AyahTextCard(session: state.sessionState),
        const SizedBox(height: AppSpacing.md),
        _AudioAction(
          isPlaying: state.isPlaying,
          onPressed: () =>
              context.read<MemorizationSessionCubit>().playCurrentAyah(),
        ),
      ],
    );
  }
}

class V2BlockReviewPendingPage extends StatelessWidget {
  const V2BlockReviewPendingPage({super.key, required this.state});

  final MSActive state;

  @override
  Widget build(BuildContext context) {
    final session = state.sessionState;
    final start = session.blockAyahs.first.numberInSurah;
    final end = session.blockAyahs.last.numberInSurah;
    return _V2PhaseScaffold(
      session: session,
      icon: Icons.fact_check_rounded,
      title: context.isArabic ? 'مراجعة المقطع' : 'Block review',
      subtitle: context.isArabic
          ? 'أنهيت الآيات منفردة. الخطوة التالية تسميع المقطع كاملاً من الذاكرة.'
          : 'All individual ayahs passed. Next, recite the full block from memory.',
      primaryActionLabel: context.isArabic
          ? 'ابدأ مراجعة المقطع'
          : 'Start Block Review',
      primaryActionIcon: Icons.play_arrow_rounded,
      onPrimaryAction: () =>
          context.read<MemorizationSessionCubit>().startBlockReview(),
      children: [
        _BlockReviewSummaryCard(session: session, start: start, end: end),
      ],
    );
  }
}

class V2BlockReviewPage extends StatelessWidget {
  const V2BlockReviewPage({super.key, required this.state});

  final MSActive state;

  @override
  Widget build(BuildContext context) {
    final session = state.sessionState;
    final start = session.blockAyahs.first.numberInSurah;
    final end = session.blockAyahs.last.numberInSurah;
    final isRecording = state.isRecording;
    return _V2PhaseScaffold(
      session: session,
      icon: Icons.mic_external_on_rounded,
      title: context.isArabic ? 'سمّع المقطع كاملاً' : 'Recite the full block',
      subtitle: context.isArabic
          ? 'النص مخفي الآن. سجّل الآيات $start-$end كاملة بدون تلميحات.'
          : 'Text is hidden. Record ayahs $start-$end together without hints.',
      primaryActionLabel: isRecording
          ? (context.isArabic ? 'إيقاف التسجيل' : 'Stop recording')
          : (context.isArabic ? 'بدء التسجيل' : 'Start recording'),
      primaryActionIcon: isRecording ? Icons.stop_rounded : Icons.mic_rounded,
      onPrimaryAction: () {
        final cubit = context.read<MemorizationSessionCubit>();
        return isRecording ? cubit.stopRecording() : cubit.startRecording();
      },
      children: [
        _BlockReviewHiddenCard(
          start: start,
          end: end,
          isRecording: isRecording,
          isEvaluating: state.isEvaluating,
          speechIssue: state.speechIssue,
        ),
      ],
    );
  }
}

class V2CompletionPage extends StatelessWidget {
  const V2CompletionPage({super.key, required this.finalState});

  final V2SessionState finalState;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final title = context.isArabic ? 'اكتملت الجلسة' : 'Session complete';
    final subtitle = context.isArabic
        ? 'تم حفظ آيات هذا المقطع بنجاح.'
        : 'This memorization block has been completed.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(Icons.verified_rounded, size: 72, color: primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SummaryRow(
              passed: finalState.passedAyahNumbers.length,
              total: finalState.totalAyahsInBlock,
              failures: finalState.failureTracker.totalFailures,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => context.go(
                Uri(
                  path: AppRoutes.memorizationPlusDailyPlan,
                  queryParameters: {'surahId': '${finalState.surahId}'},
                ).toString(),
              ),
              icon: const Icon(Icons.today_rounded),
              label: Text(context.isArabic ? 'العودة للخطة' : 'Back to plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _V2PhaseScaffold extends StatelessWidget {
  const _V2PhaseScaffold({
    required this.session,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.onPrimaryAction,
    required this.children,
  });

  final V2SessionState session;
  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final Future<void> Function() onPrimaryAction;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _ProgressHeader(session: session, primary: primary),
          const SizedBox(height: AppSpacing.lg),
          Icon(icon, color: primary, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onPrimaryAction,
            icon: Icon(primaryActionIcon),
            label: Text(primaryActionLabel),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.session, required this.primary});

  final V2SessionState session;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return LinearProgressIndicator(
      value: session.blockProgress,
      minHeight: 8,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      backgroundColor: isDark ? AppColors.darkDivider : AppColors.lightDivider,
      valueColor: AlwaysStoppedAnimation<Color>(primary),
    );
  }
}

class _AyahTextCard extends StatelessWidget {
  const _AyahTextCard({required this.session});

  final V2SessionState session;

  @override
  Widget build(BuildContext context) {
    final ayah = session.currentAyah;
    final isDark = context.isDark;
    return _PhaseCard(
      child: QcfHifzVerseView(
        surahNumber: session.surahId,
        verseNumber: ayah.numberInSurah,
        fallbackText: ayah.text,
        isUnlocked: true,
        isMemorized: session.passedAyahNumbers.contains(ayah.numberInSurah),
        displayMode: HifzVerseDisplayMode.single,
        textAlign: TextAlign.center,
      ),
      footer: Text(
        context.isArabic
            ? 'الآية ${ayah.numberInSurah}'
            : 'Ayah ${ayah.numberInSurah}',
        textAlign: TextAlign.center,
        style: AppTypography.labelMedium.copyWith(
          color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.session, required this.hintLevel});

  final V2SessionState session;
  final V2HintLevel hintLevel;

  @override
  Widget build(BuildContext context) {
    final firstWord = session.currentAyah.text
        .trim()
        .split(RegExp(r'\s+'))
        .first;
    return switch (hintLevel) {
      V2HintLevel.none => _PhaseCard(
        child: Icon(
          Icons.visibility_off_rounded,
          size: 42,
          color: context.isDark
              ? AppColors.darkTextHint
              : AppColors.lightTextHint,
        ),
        footer: Text(
          context.isArabic ? 'حاول من غير تلميح' : 'Try without a hint first',
          textAlign: TextAlign.center,
        ),
      ),
      V2HintLevel.firstWord => _PhaseCard(
        child: Text(
          firstWord,
          textAlign: TextAlign.center,
          style: AppTypography.quranLarge,
        ),
        footer: Text(
          context.isArabic ? 'تم كشف أول كلمة' : 'First word revealed',
          textAlign: TextAlign.center,
        ),
      ),
      V2HintLevel.fullAyah => _AyahTextCard(session: session),
    };
  }
}

class _BlockReviewSummaryCard extends StatelessWidget {
  const _BlockReviewSummaryCard({
    required this.session,
    required this.start,
    required this.end,
  });

  final V2SessionState session;
  final int start;
  final int end;

  @override
  Widget build(BuildContext context) {
    return _PhaseCard(
      child: Icon(
        Icons.checklist_rtl_rounded,
        size: 48,
        color: context.isDark ? AppColors.primaryLight : AppColors.primary,
      ),
      footer: Column(
        children: [
          Text(
            context.isArabic ? 'الآيات $start-$end' : 'Ayahs $start-$end',
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.isArabic
                ? 'تم اجتياز ${session.passedAyahNumbers.length}/${session.totalAyahsInBlock} آيات.'
                : '${session.passedAyahNumbers.length}/${session.totalAyahsInBlock} ayahs passed individually.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BlockReviewHiddenCard extends StatelessWidget {
  const _BlockReviewHiddenCard({
    required this.start,
    required this.end,
    required this.isRecording,
    required this.isEvaluating,
    required this.speechIssue,
  });

  final int start;
  final int end;
  final bool isRecording;
  final bool isEvaluating;
  final V2SpeechIssue? speechIssue;

  @override
  Widget build(BuildContext context) {
    final primary = context.isDark ? AppColors.primaryLight : AppColors.primary;
    final message = speechIssue == null
        ? isEvaluating
              ? (context.isArabic
                    ? 'جار تقييم المقطع...'
                    : 'Evaluating block...')
              : isRecording
              ? (context.isArabic
                    ? 'يتم تسجيل المقطع الآن'
                    : 'Recording block now')
              : (context.isArabic
                    ? 'اضغط التسجيل عندما تكون جاهزاً'
                    : 'Press record when you are ready')
        : (context.isArabic
              ? 'تعذر استخدام الميكروفون'
              : 'Microphone is not available');

    return _PhaseCard(
      child: Column(
        children: [
          Icon(
            isRecording
                ? Icons.graphic_eq_rounded
                : Icons.visibility_off_rounded,
            size: 64,
            color: primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.isArabic ? 'الآيات $start-$end' : 'Ayahs $start-$end',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium,
          ),
        ],
      ),
      footer: Text(message, textAlign: TextAlign.center),
    );
  }
}

class _HiddenTextCard extends StatelessWidget {
  const _HiddenTextCard({
    required this.isRecording,
    required this.isEvaluating,
    required this.speechIssue,
  });

  final bool isRecording;
  final bool isEvaluating;
  final V2SpeechIssue? speechIssue;

  @override
  Widget build(BuildContext context) {
    final primary = context.isDark ? AppColors.primaryLight : AppColors.primary;
    final message = speechIssue == null
        ? isEvaluating
              ? (context.isArabic ? 'جار التقييم...' : 'Evaluating...')
              : isRecording
              ? (context.isArabic ? 'يتم التسجيل الآن' : 'Recording now')
              : (context.isArabic
                    ? 'اضغط التسجيل عندما تكون جاهزاً'
                    : 'Press record when you are ready')
        : (context.isArabic
              ? 'تعذر استخدام الميكروفون'
              : 'Microphone is not available');

    return _PhaseCard(
      child: Icon(
        isRecording ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
        size: 64,
        color: primary,
      ),
      footer: Text(message, textAlign: TextAlign.center),
    );
  }
}

class _FailureSummary extends StatelessWidget {
  const _FailureSummary({required this.session});

  final V2SessionState session;

  @override
  Widget build(BuildContext context) {
    final failures = session.failureTracker.failureCountFor(
      session.surahId,
      session.currentAyah.numberInSurah,
    );
    return _PhaseCard(
      child: const Icon(
        Icons.refresh_rounded,
        size: 42,
        color: AppColors.warning,
      ),
      footer: Text(
        context.isArabic
            ? 'عدد المحاولات التي تحتاج مراجعة: $failures'
            : 'Attempts needing remediation: $failures',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AudioAction extends StatelessWidget {
  const _AudioAction({required this.isPlaying, required this.onPressed});

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
      ),
      label: Text(
        isPlaying
            ? (context.isArabic ? 'يتم التشغيل' : 'Playing')
            : (context.isArabic ? 'استمع للآية' : 'Listen to ayah'),
      ),
    );
  }
}

class _HintButton extends StatelessWidget {
  const _HintButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.child, required this.footer});

  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: child),
          const SizedBox(height: AppSpacing.md),
          DefaultTextStyle(
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            child: footer,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.passed,
    required this.total,
    required this.failures,
  });

  final int passed;
  final int total;
  final int failures;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: context.isArabic ? 'تم تسميعها' : 'Passed',
            value: '$passed/$total',
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            label: context.isArabic ? 'محاولات' : 'Retries',
            value: '$failures',
            icon: Icons.replay_rounded,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _PhaseCard(
      child: Icon(icon, color: color, size: 32),
      footer: Column(
        children: [
          Text(value, style: AppTypography.titleLarge.copyWith(color: color)),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
