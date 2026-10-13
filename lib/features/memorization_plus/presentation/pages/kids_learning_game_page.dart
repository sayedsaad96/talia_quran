import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/kids_learning_game.dart';
import '../cubits/kids_learning_game_cubit.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_ui.dart';
import '../world/kids_world_palette.dart';

/// «أي سورة هذه؟» — an optional listening game over ayahs the child has
/// already memorized. It can be left at any time and never changes the
/// journey, the memorization budget or rewards.
class KidsLearningGamePage extends StatelessWidget {
  const KidsLearningGamePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<KidsLearningGameCubit>()..start(),
    child: const KidsLearningGameView(),
  );
}

@visibleForTesting
class KidsLearningGameView extends StatelessWidget {
  const KidsLearningGameView({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.memorizationPlusKidsHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KidsBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              KidsTopBar(
                title: l10n.kidsGameTitle,
                onBack: () => _back(context),
                backLabel: l10n.goBack,
              ),
              Expanded(
                child:
                    BlocBuilder<KidsLearningGameCubit, KidsLearningGameState>(
                      builder: (context, state) => ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          switch (state.status) {
                            KidsLearningGameStatus.loading => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            KidsLearningGameStatus.unavailable => _Message(
                              key: const ValueKey('kids-game-unavailable'),
                              text: l10n.kidsGameUnavailable,
                            ),
                            KidsLearningGameStatus.playing => _RoundCard(
                              state: state,
                            ),
                            KidsLearningGameStatus.finished => _Finished(
                              state: state,
                              onDone: () => _back(context),
                            ),
                          },
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.kidsGameNote,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: KidsWorldPalette.of(context).onSceneMuted,
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

String _surahName(BuildContext context, int surahId) =>
    context.l10n.localeName == 'ar'
    ? SurahNames.nameAr(surahId)
    : SurahNames.nameEn(surahId);

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      gradient: KidsTheme.parchmentGradient,
      borderRadius: KidsTheme.cardRadius,
      border: Border.all(color: KidsTheme.parchmentEdge, width: 1.5),
    ),
    child: child,
  );
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => _Card(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.bodyLarge.copyWith(color: KidsTheme.inkOnParchment),
    ),
  );
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({required this.state});

  final KidsLearningGameState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final round = state.round!;
    final cubit = context.read<KidsLearningGameCubit>();
    return _Card(
      child: Column(
        key: ValueKey('kids-game-round-${state.roundIndex}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.kidsGameRoundCounter(
              context.numText(state.roundIndex + 1),
              context.numText(state.roundCount),
            ),
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: KidsTheme.lockedGrey,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.kidsGamePrompt,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: KidsTheme.inkOnParchment,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const ValueKey('kids-game-listen'),
            onPressed: state.isAudioPlaying
                ? cubit.stopAudio
                : cubit.playRecitation,
            icon: Icon(
              state.isAudioPlaying ? TaliaIcons.pause : TaliaIcons.play,
            ),
            label: Text(l10n.kidsGameListen),
          ),
          if (state.audioFailed) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.kidsGameAudioFailed,
              key: const ValueKey('kids-game-audio-failed'),
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: KidsTheme.lockedGrey,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          for (final option in round.options) ...[
            _OptionButton(
              surahId: option,
              state: state,
              onTap: () => cubit.answer(option),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (state.answered) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              state.result == KidsGameResult.correct
                  ? l10n.kidsGameCorrect
                  : l10n.kidsGameAnswerWas(_surahName(context, round.surahId)),
              key: const ValueKey('kids-game-feedback'),
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: KidsTheme.inkOnParchment,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              key: const ValueKey('kids-game-next'),
              onPressed: cubit.next,
              child: Text(state.isLastRound ? l10n.done : l10n.next),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.surahId,
    required this.state,
    required this.onTap,
  });

  final int surahId;
  final KidsLearningGameState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final round = state.round!;
    final answered = state.answered;
    final isAnswer = surahId == round.surahId;
    final isPicked = surahId == state.selected;
    final Color? background = !answered
        ? null
        : isAnswer
        ? const Color(0xFFD1FAE5)
        : isPicked
        ? const Color(0xFFE5E7EB)
        : null;
    return OutlinedButton(
      key: ValueKey('kids-game-option-$surahId'),
      onPressed: answered ? null : onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: background,
        foregroundColor: KidsTheme.inkOnParchment,
        disabledForegroundColor: KidsTheme.inkOnParchment,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (answered && isAnswer) ...[
            const Icon(TaliaIcons.check, size: 20),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              _surahName(context, surahId),
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Finished extends StatelessWidget {
  const _Finished({required this.state, required this.onDone});

  final KidsLearningGameState state;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Card(
      child: Column(
        key: const ValueKey('kids-game-finished'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.kidsGameFinished(
              context.numText(state.correctCount),
              context.numText(state.roundCount),
            ),
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: KidsTheme.inkOnParchment,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: onDone, child: Text(l10n.done)),
        ],
      ),
    );
  }
}
