import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../cubits/kids_mode_cubit.dart';
import '../navigation/memorization_navigation_resolver.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_ayah_card.dart';

class KidsGamifiedListenPage extends StatelessWidget {
  const KidsGamifiedListenPage({
    super.key,
    required this.surahId,
    required this.ayahNumber,
    required this.ayahText,
  });

  final int surahId;
  final int ayahNumber;
  final String ayahText;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<KidsModeCubit>()..load(surahId, ayahNumber, ayahText),
      child: _KidsGamifiedListenView(
        surahId: surahId,
        ayahNumber: ayahNumber,
        ayahText: ayahText,
      ),
    );
  }
}

class _KidsGamifiedListenView extends StatelessWidget {
  const _KidsGamifiedListenView({
    required this.surahId,
    required this.ayahNumber,
    required this.ayahText,
  });

  final int surahId;
  final int ayahNumber;
  final String ayahText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KidsTheme.nightSkyDark,
      body: BlocConsumer<KidsModeCubit, KidsModeState>(
        listenWhen: (previous, current) {
          if (current is! KidsModeLoaded) return false;
          final prev = previous is KidsModeLoaded ? previous : null;
          if (current.mustListenFirst && prev?.mustListenFirst != true) {
            return true;
          }
          if (current.audioError != null &&
              prev?.audioError != current.audioError) {
            return true;
          }
          if (current.recordingError != null &&
              prev?.recordingError != current.recordingError) {
            return true;
          }
          final wasCompleted = prev?.isCompleted ?? false;
          return current.isCompleted && !wasCompleted;
        },
        listener: (context, state) {
          if (state is! KidsModeLoaded) return;
          if (state.mustListenFirst) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.kidsGamifiedListenFirst(state.maxLoops),
                ),
              ),
            );
            return;
          }
          if (state.audioError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.localizedCubitMessage(state.audioError!)),
              ),
            );
            return;
          }
          if (state.recordingError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.localizedCubitMessage(state.recordingError!),
                ),
              ),
            );
            return;
          }
          if (state.isCompleted) {
            context.pushReplacement(
              '${AppRoutes.memorizationPlusKidsCompletion}'
              '?surahId=${state.surahId}'
              '&completedAyahNumber=${state.ayahNumber}'
              '&starsEarned=${state.sessionStarsEarned}',
            );
          }
        },
        builder: (context, state) {
          if (state is KidsModeInitial || state is KidsModeLoading) {
            return const Center(child: LoadingWidget());
          }

          if (state is KidsModeError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<KidsModeCubit>().load(
                surahId,
                ayahNumber,
                ayahText,
              ),
            );
          }

          if (state is! KidsModeLoaded) return const SizedBox.shrink();

          return KidsGamifiedListenContent(
            state: state,
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(
                    MemorizationNavigationResolver.kidsHomeFallbackLocation(
                      surahId,
                    ),
                  ),
            onPlayPause: () {
              final cubit = context.read<KidsModeCubit>();
              if (state.isPlaying) {
                cubit.stopAudio();
              } else {
                cubit.playAudio();
              }
            },
            onRecordRecitation: () =>
                context.read<KidsModeCubit>().startRecording(),
          );
        },
      ),
    );
  }
}

@visibleForTesting
class KidsGamifiedListenContent extends StatelessWidget {
  const KidsGamifiedListenContent({
    super.key,
    required this.state,
    required this.onBack,
    required this.onPlayPause,
    required this.onRecordRecitation,
  });

  final KidsModeLoaded state;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final VoidCallback onRecordRecitation;

  @override
  Widget build(BuildContext context) {
    final audioUnavailable = state.audioError != null;

    return Container(
      decoration: const BoxDecoration(gradient: KidsTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _KidsGamifiedListenAppBar(onBack: onBack),
              Expanded(
                child: CustomScrollView(
                  key: const PageStorageKey<String>('kids-gamified-listen'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      sliver: SliverList.list(
                        children: [
                          KidsAyahCard(
                            surahId: state.surahId,
                            ayahNumber: state.ayahNumber,
                            ayahText: state.ayahText,
                            isCompleted: state.isCompleted,
                            // isBuffering is true only during URL loading/buffering,
                            // not during actual playback — more accurate than isPlaying
                            isAudioLoading: state.isBuffering,
                            audioUnavailable: audioUnavailable,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _KidsGamifiedLoopIndicator(state: state),
                          const SizedBox(height: AppSpacing.xl),
                          _KidsGamifiedAudioControls(
                            state: state,
                            onPlayPause: onPlayPause,
                            onRecordRecitation: onRecordRecitation,
                          ),
                          const SizedBox(height: 96),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KidsGamifiedListenAppBar extends StatelessWidget {
  const _KidsGamifiedListenAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.kidsGamifiedListenAndRepeat,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontFamily: 'Amiri',
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KidsGamifiedLoopIndicator extends StatelessWidget {
  const _KidsGamifiedLoopIndicator({required this.state});

  final KidsModeLoaded state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: KidsTheme.cardRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            context.l10n.kidsGamifiedRepeatStep,
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontFamily: 'Amiri',
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < state.maxLoops; index++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: index < state.currentLoop ? 30 : 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: index < state.currentLoop
                        ? KidsTheme.goldStar
                        : Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${state.currentLoop}/${state.maxLoops}',
                style: AppTypography.titleSmall.copyWith(
                  color: KidsTheme.goldStar,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KidsGamifiedAudioControls extends StatelessWidget {
  const _KidsGamifiedAudioControls({
    required this.state,
    required this.onPlayPause,
    required this.onRecordRecitation,
  });

  final KidsModeLoaded state;
  final VoidCallback onPlayPause;
  final VoidCallback onRecordRecitation;

  @override
  Widget build(BuildContext context) {
    final isRecording = state.isRecording;
    final loopsComplete = state.currentLoop >= state.maxLoops;
    final micDisabled = state.isCompleted || isRecording || !loopsComplete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: FilledButton.tonalIcon(
            key: const ValueKey('kids-gamified-play-audio'),
            onPressed: state.isRecording ? null : onPlayPause,
            icon: Icon(
              state.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(context.l10n.kidsGamifiedListenAndRepeat),
            style: FilledButton.styleFrom(
              backgroundColor: KidsTheme.goldStar,
              foregroundColor: KidsTheme.nightSkyDark,
              minimumSize: const Size(220, 56),
              shape: const RoundedRectangleBorder(
                borderRadius: KidsTheme.buttonRadius,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Mic button: shows a pulsing recording indicator while isRecording
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: FilledButton.icon(
            key: ValueKey(
              isRecording
                  ? 'kids-gamified-record-recitation-recording'
                  : 'kids-gamified-record-recitation-idle',
            ),
            onPressed: micDisabled ? null : onRecordRecitation,
            icon: isRecording
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.mic_rounded),
            label: Text(
              isRecording
                  ? context.l10n.kidsGamifiedRecordingInProgress
                  : context.l10n.kidsGamifiedRecordYourVoice,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: isRecording
                  ? KidsTheme.forestGreen.withValues(alpha: 0.6)
                  : KidsTheme.forestGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: const RoundedRectangleBorder(
                borderRadius: KidsTheme.buttonRadius,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
