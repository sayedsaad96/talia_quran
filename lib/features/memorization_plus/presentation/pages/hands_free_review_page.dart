import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/memorization/hands_free/hands_free_round_state.dart';
import '../../../../core/memorization/listening/listening_question.dart';
import '../cubits/hands_free_review_cubit.dart';
import '../widgets/similar_ayah_label.dart';

class HandsFreeReviewPage extends StatelessWidget {
  const HandsFreeReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HandsFreeReviewCubit>()..initializeWarning(),
      child: const HandsFreeReviewView(),
    );
  }
}

class HandsFreeReviewView extends StatelessWidget {
  const HandsFreeReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.handsFreeTitle)),
      body: SafeArea(
        child: BlocBuilder<HandsFreeReviewCubit, HandsFreeReviewState>(
          builder: (context, state) => _HandsFreeBody(state: state),
        ),
      ),
    );
  }
}

class _HandsFreeBody extends StatelessWidget {
  const _HandsFreeBody({required this.state});

  final HandsFreeReviewState state;

  @override
  Widget build(BuildContext context) {
    if (state.firstUseWarningPending) {
      return _WarningView(loading: state.loading, hasError: state.hasError);
    }
    final round = state.round;
    if (round?.phase == HandsFreePhase.finished) {
      return round!.items.isEmpty ? const _NoDueView() : const _SummaryView();
    }
    return _RoundView(state: state);
  }
}

class _WarningView extends StatelessWidget {
  const _WarningView({required this.loading, required this.hasError});

  final bool loading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return _ScrollableCenter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(TaliaIcons.warning, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.handsFreeDrivingWarning,
            textAlign: TextAlign.center,
          ),
          if (hasError) const _HandsFreeError(),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () =>
                context.read<HandsFreeReviewCubit>().acceptWarning(),
            child: Text(context.l10n.handsFreeAcceptWarning),
          ),
          const SizedBox(height: AppSpacing.itemGap),
          FilledButton(
            onPressed: null,
            child: Text(context.l10n.handsFreeStart),
          ),
        ],
      ),
    );
  }
}

class _NoDueView extends StatelessWidget {
  const _NoDueView();

  @override
  Widget build(BuildContext context) => _ScrollableCenter(
    child: Text(context.l10n.handsFreeNoDue, textAlign: TextAlign.center),
  );
}

class _RoundView extends StatelessWidget {
  const _RoundView({required this.state});

  final HandsFreeReviewState state;

  @override
  Widget build(BuildContext context) {
    final round = state.round;
    final phase = round?.phase;
    final current = round?.currentAyah;
    final active = phase != null && phase != HandsFreePhase.paused;
    return _ScrollableCenter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoundStatus(
            current: current,
            phase: phase,
            micAvailable: state.micAvailable,
          ),
          if (state.hasError) const _HandsFreeError(),
          const SizedBox(height: AppSpacing.lg),
          _RoundActions(
            isUserTurn: phase == HandsFreePhase.userTurn,
            active: active,
            loading: state.loading,
          ),
        ],
      ),
    );
  }
}

class _RoundStatus extends StatelessWidget {
  const _RoundStatus({
    required this.current,
    required this.phase,
    required this.micAvailable,
  });

  final ListeningAyahRef? current;
  final HandsFreePhase? phase;
  final bool micAvailable;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(context.l10n.handsFreeDescription, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        if (current case final ref?)
          Text(
            similarAyahLabel(context, ref.surahId, ref.ayahNumber),
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge,
          ),
        const SizedBox(height: AppSpacing.itemGap),
        Text(_phaseLabel(context, phase), textAlign: TextAlign.center),
        if (!micAvailable && phase == HandsFreePhase.userTurn) ...[
          const SizedBox(height: AppSpacing.md),
          Text(context.l10n.handsFreeMicFallback, textAlign: TextAlign.center),
        ],
      ],
    );
  }

  String _phaseLabel(BuildContext context, HandsFreePhase? phase) =>
      switch (phase) {
        HandsFreePhase.prompt => context.l10n.handsFreePrompt,
        HandsFreePhase.userTurn => context.l10n.handsFreeYourTurn,
        HandsFreePhase.feedback => context.l10n.handsFreeFeedback,
        HandsFreePhase.paused => context.l10n.handsFreePaused,
        _ => '',
      };
}

class _RoundActions extends StatelessWidget {
  const _RoundActions({
    required this.isUserTurn,
    required this.active,
    required this.loading,
  });

  final bool isUserTurn;
  final bool active;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (isUserTurn) {
      return const Column(children: [_GradeButtons(), _StopButton()]);
    }
    if (active) return const _StopButton();
    return FilledButton(
      onPressed: loading
          ? null
          : () => context.read<HandsFreeReviewCubit>().start(),
      child: loading
          ? const SizedBox.square(
              dimension: AppSpacing.md,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(context.l10n.handsFreeStart),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton();

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => context.read<HandsFreeReviewCubit>().stopRound(),
    icon: const Icon(TaliaIcons.stop),
    label: Text(context.l10n.stop),
  );
}

class _GradeButtons extends StatelessWidget {
  const _GradeButtons();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HandsFreeReviewCubit>();
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: cubit.onPrimary,
            child: Text(context.l10n.handsFreeCorrect),
          ),
        ),
        const SizedBox(width: AppSpacing.itemGap),
        Expanded(
          child: OutlinedButton(
            onPressed: cubit.onSecondary,
            child: Text(context.l10n.handsFreeReview),
          ),
        ),
      ],
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView();

  @override
  Widget build(BuildContext context) {
    final summary = context.read<HandsFreeReviewCubit>().state.summary;
    final reviewed = summary.reviewAyahs;
    return _ScrollableCenter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.handsFreeSummary(
              summary.correctCount + summary.reviewCount,
            ),
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.itemGap),
          Text(
            '${context.numText(summary.correctCount)} ${context.l10n.handsFreeCorrect} '
            '· ${context.numText(summary.reviewCount)} ${context.l10n.handsFreeReview}',
            textAlign: TextAlign.center,
          ),
          for (final ref in reviewed)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.itemGap),
              child: Text(
                similarAyahLabel(context, ref.surahId, ref.ayahNumber),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _ScrollableCenter extends StatelessWidget {
  const _ScrollableCenter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _HandsFreeError extends StatelessWidget {
  const _HandsFreeError();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: Text(
      context.l10n.handsFreeError,
      textAlign: TextAlign.center,
      style: TextStyle(color: context.colorScheme.error),
    ),
  );
}
