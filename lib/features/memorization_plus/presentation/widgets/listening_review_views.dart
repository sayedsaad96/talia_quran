import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/memorization/listening/listening_round_result.dart';
import '../../../../core/widgets/memorization_ayah_display.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../data/listening/listening_review_stats_store.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../cubits/listening_review_cubit.dart';
import '../cubits/listening_review_state.dart';
import '../pages/v2/v2_session_widgets.dart';

String _surahName(BuildContext context, int surahId) {
  final Surah? surah = context
      .read<ListeningReviewCubit>()
      .material
      ?.surahs[surahId];
  if (surah == null) return '$surahId';
  return context.l10n.localeName == 'ar' ? surah.nameAr : surah.nameEn;
}

class _Centered extends StatelessWidget {
  const _Centered({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

class ListeningErrorView extends StatelessWidget {
  const ListeningErrorView({super.key});

  @override
  Widget build(BuildContext context) => _Centered(
    children: [
      Text(context.l10n.listeningReviewErrorBody, textAlign: TextAlign.center),
      const SizedBox(height: AppSpacing.md),
      FilledButton(
        onPressed: () => context.read<ListeningReviewCubit>().load(),
        child: Text(context.l10n.listeningReviewRetry),
      ),
    ],
  );
}

class ListeningNotEnoughView extends StatelessWidget {
  const ListeningNotEnoughView({super.key});

  @override
  Widget build(BuildContext context) => _Centered(
    children: [
      const Icon(Icons.hearing_rounded, size: 48),
      const SizedBox(height: AppSpacing.md),
      Text(
        context.l10n.listeningReviewNotEnoughTitle,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        context.l10n.listeningReviewNotEnoughBody,
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class ListeningStartView extends StatelessWidget {
  const ListeningStartView({super.key, required this.stats});

  final ListeningReviewStats stats;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListeningReviewCubit>();
    final l10n = context.l10n;
    Widget mode(IconData icon, String label, ListeningQuizMode value) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => cubit.startRound(value),
            icon: Icon(icon),
            label: Text(label),
          ),
        );
    return _Centered(
      children: [
        const Icon(Icons.hearing_rounded, size: 48),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.listeningReviewStartPrompt,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (stats.hasPlayed) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.listeningReviewLastScore(
              stats.lastCorrect!,
              stats.lastScored!,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        mode(
          Icons.menu_book_rounded,
          l10n.listeningReviewModeWhichSurah,
          ListeningQuizMode.whichSurah,
        ),
        mode(
          Icons.link_rounded,
          l10n.listeningReviewModeNextAyah,
          ListeningQuizMode.nextAyah,
        ),
        mode(
          Icons.shuffle_rounded,
          l10n.listeningReviewModeMixed,
          ListeningQuizMode.mixed,
        ),
      ],
    );
  }
}

class ListeningQuestionView extends StatelessWidget {
  const ListeningQuestionView({super.key, required this.round});

  final ListeningReviewInRound round;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListeningReviewCubit>();
    final l10n = context.l10n;
    final question = round.question;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          l10n.listeningReviewQuestionProgress(
            round.index + 1,
            round.questions.length,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          switch (question) {
            WhichSurahQuestion() => l10n.listeningReviewWhichSurahPrompt,
            NextAyahQuestion(:final prompt) =>
              l10n.listeningReviewNextAyahPrompt(
                _surahName(context, prompt.surahId),
              ),
          },
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: round.isPlaying || round.playsLeft <= 0 || round.isAnswered
              ? null
              : cubit.replay,
          icon: Icon(
            round.isPlaying ? Icons.graphic_eq_rounded : Icons.replay_rounded,
          ),
          label: Text(l10n.listeningReviewReplay(round.playsLeft)),
        ),
        // Announced to screen readers when playback starts and ends.
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              round.isPlaying ? l10n.listeningReviewAudioPlaying : '',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (round.isAnswered)
          _Reveal(round: round)
        else
          switch (question) {
            final WhichSurahQuestion q => _SurahOptions(question: q),
            NextAyahQuestion() => _NextAyahControls(round: round),
          },
      ],
    );
  }
}

class _SurahOptions extends StatelessWidget {
  const _SurahOptions({required this.question});

  final WhichSurahQuestion question;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListeningReviewCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final surahId in question.optionSurahIds)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () => cubit.answerSurah(surahId),
              child: Text(_surahName(context, surahId)),
            ),
          ),
      ],
    );
  }
}

class _NextAyahControls extends StatelessWidget {
  const _NextAyahControls({required this.round});

  final ListeningReviewInRound round;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListeningReviewCubit>();
    final l10n = context.l10n;
    if (round.selfGradeMode) {
      if (!round.selfGradeRevealed) {
        return FilledButton(
          onPressed: cubit.revealForSelfGrade,
          child: Text(l10n.listeningReviewReveal),
        );
      }
      final question = round.question as NextAyahQuestion;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AyahCard(ref: question.answer, text: question.nextAyahText),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final (label, outcome) in [
                (l10n.listeningReviewGradeMastered, ListeningOutcome.correct),
                (l10n.listeningReviewGradeHesitant, ListeningOutcome.hesitant),
                (l10n.listeningReviewGradeForgot, ListeningOutcome.wrong),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: OutlinedButton(
                      onPressed: () => cubit.selfGrade(outcome),
                      child: Text(label),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (round.recognizedText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(round.recognizedText, textAlign: TextAlign.center),
          ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: round.isRecording
              ? cubit.stopRecording
              : cubit.startRecording,
          icon: Icon(
            round.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          ),
          label: Text(
            round.isRecording
                ? l10n.listeningReviewStopRecord
                : l10n.listeningReviewRecord,
          ),
        ),
        TextButton(
          onPressed: round.isRecording ? null : cubit.useSelfGrade,
          child: Text(l10n.listeningReviewCantRecord),
        ),
      ],
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({required this.ref, required this.text});

  final ListeningAyahRef ref;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return V2PhaseCard(
      child: MemorizationAyahDisplay(
        text: text,
        surahId: ref.surahId,
        ayahNumber: ref.ayahNumber,
        textColor: tokens.textPrimary,
        decorationColor: tokens.accent.withValues(alpha: 0.5),
        referenceColor: tokens.accent,
        isCompleted: false,
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.round});

  final ListeningReviewInRound round;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListeningReviewCubit>();
    final l10n = context.l10n;
    final answer = round.current!;
    final ok = answer.outcome == ListeningOutcome.correct;
    final ref = answer.reviewTarget;
    final text = cubit.material?.corpus.textOf(ref) ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ok ? l10n.listeningReviewCorrect : l10n.listeningReviewWrong,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: ok ? context.tokens.success : context.tokens.error,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _AyahCard(ref: ref, text: text),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.listeningReviewAyahRef(
            _surahName(context, ref.surahId),
            ref.ayahNumber,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: cubit.next,
          child: Text(l10n.listeningReviewNext),
        ),
      ],
    );
  }
}

class ListeningResultView extends StatelessWidget {
  const ListeningResultView({super.key, required this.result});

  final ListeningRoundResult result;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListeningReviewCubit>();
    final l10n = context.l10n;
    final reviewable = cubit.material?.prompts.toSet() ?? const {};
    final weak = result.weakLinksWithin(reviewable);
    final surahTally = result.whichSurahTally;
    final nextTally = result.nextAyahTally;
    final showBreakdown = surahTally.scored > 0 && nextTally.scored > 0;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          l10n.listeningReviewResultTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.listeningReviewResultScore(result.correct, result.scored),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (showBreakdown) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.listeningReviewBreakdownWhichSurah(
              surahTally.correct,
              surahTally.scored,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            l10n.listeningReviewBreakdownNextAyah(
              nextTally.correct,
              nextTally.scored,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.listeningReviewWeakLinksTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (weak.isEmpty)
          Text(l10n.listeningReviewNoWeakLinks)
        else
          for (final ref in weak)
            ListTile(
              leading: const Icon(Icons.link_off_rounded),
              title: Text(
                l10n.listeningReviewAyahRef(
                  _surahName(context, ref.surahId),
                  ref.ayahNumber,
                ),
              ),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => context.push(
                MemorizationNavigationResolver.reviewAyahLocation(
                  ref.surahId,
                  ref.ayahNumber,
                ),
              ),
            ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: cubit.backToStart,
          child: Text(l10n.listeningReviewNewRound),
        ),
      ],
    );
  }
}
