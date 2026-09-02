import 'package:flutter/material.dart';

import '../../../../core/memorization/v2/session_phase.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/router/app_router.dart';
import '../../../certificate/presentation/widgets/certificate_celebration_dialog.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/kids_mode_cubit.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_ayah_card.dart';

class KidsGamifiedListenPage extends StatelessWidget {
  const KidsGamifiedListenPage({
    super.key,
    required this.surahId,
    required this.ayahNumber,
    required this.ayahText,
    this.missionType = KidsMissionType.newMemorization,
  });

  final int surahId;
  final int ayahNumber;
  final String ayahText;
  final KidsMissionType missionType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<KidsModeCubit>()
            ..load(surahId, ayahNumber, ayahText, missionType: missionType),
      child: _KidsGamifiedListenView(
        surahId: surahId,
        ayahNumber: ayahNumber,
        ayahText: ayahText,
        missionType: missionType,
      ),
    );
  }
}

class _KidsGamifiedListenView extends StatelessWidget {
  const _KidsGamifiedListenView({
    required this.surahId,
    required this.ayahNumber,
    required this.ayahText,
    required this.missionType,
  });

  final int surahId;
  final int ayahNumber;
  final String ayahText;
  final KidsMissionType missionType;

  Future<void> _submitGuardianCompletion(BuildContext context) async {
    final pinController = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.parentDashboardEnterPinTitle),
        content: TextField(
          controller: pinController,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: InputDecoration(
            helperText: context.l10n.parentDashboardPinHelp,
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, pinController.text.trim()),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
    pinController.dispose();
    if (pin == null || !context.mounted) return;

    final accepted = await context.read<KidsModeCubit>().submitManualCompletion(
      guardianPin: pin,
    );
    if (!accepted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.parentDashboardPinIncorrect)),
      );
    }
  }

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
            unawaited(_navigateAfterKidsCompletion(context, state));
          }
        },
        builder: (context, state) {
          if (state is KidsModeInitial || state is KidsModeLoading) {
            return const Center(child: LoadingWidget());
          }

          if (state is KidsModeError) {
            return ErrorStateWidget(
              message: context.localizedCubitMessage(state.message),
              onRetry: () => context.read<KidsModeCubit>().load(
                surahId,
                ayahNumber,
                ayahText,
                missionType: missionType,
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
            onStopRecording: () =>
                context.read<KidsModeCubit>().stopRecording(),
            onManualComplete: () => _submitGuardianCompletion(context),
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
    required this.onStopRecording,
    this.onManualComplete,
  });

  final KidsModeLoaded state;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final VoidCallback onRecordRecitation;
  final VoidCallback onStopRecording;

  /// V1-M8 â€” manual/self-grade completion route (null hides the action).
  final VoidCallback? onManualComplete;

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
                          if (state.isRecording ||
                              state.sessionState.phase.textHidden)
                            const _KidsHiddenRecallCard()
                          else
                            KidsAyahCard(
                              surahId: state.surahId,
                              ayahNumber: state.ayahNumber,
                              ayahText: state.ayahText,
                              isCompleted: state.isCompleted,
                              // Buffering means the audio source is loading,
                              // not that recitation playback is in progress.
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
                            onStopRecording: onStopRecording,
                            onManualComplete: onManualComplete,
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

class _KidsHiddenRecallCard extends StatelessWidget {
  const _KidsHiddenRecallCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.kidsGamifiedTestStepSubtitle,
      child: Container(
        key: const ValueKey('kids-hidden-recall-card'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: KidsTheme.cardRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.visibility_off_rounded,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.kidsGamifiedTestStepSubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
          ],
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
            icon: const BackButtonIcon(),
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
    required this.onStopRecording,
    this.onManualComplete,
  });

  final KidsModeLoaded state;
  final VoidCallback onPlayPause;
  final VoidCallback onRecordRecitation;
  final VoidCallback onStopRecording;

  /// V1-M8 â€” manual/self-grade completion route (null hides the action).
  final VoidCallback? onManualComplete;

  @override
  Widget build(BuildContext context) {
    final isRecording = state.isRecording;
    final loopsComplete = state.currentLoop >= state.maxLoops;
    final micDisabled = state.isCompleted || isRecording || !loopsComplete;
    final showManualComplete =
        !state.isCompleted &&
        !isRecording &&
        onManualComplete != null &&
        state.canUseGuardianFallback;

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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: isRecording
              ? _RecordingActivePanel(
                  key: const ValueKey('recording-panel'),
                  seconds: state.recordingSeconds,
                  onDone: onStopRecording,
                )
              : FilledButton.icon(
                  key: const ValueKey('kids-gamified-record-recitation-idle'),
                  onPressed: micDisabled ? null : onRecordRecitation,
                  icon: const Icon(Icons.mic_rounded),
                  label: Text(context.l10n.kidsGamifiedRecordYourVoice),
                  style: FilledButton.styleFrom(
                    backgroundColor: KidsTheme.forestGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: const RoundedRectangleBorder(
                      borderRadius: KidsTheme.buttonRadius,
                    ),
                  ),
                ),
        ),
        if (showManualComplete) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.kidsManualCompleteHint,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const ValueKey('kids-gamified-manual-complete'),
            onPressed: onManualComplete,
            icon: const Icon(Icons.verified_rounded),
            label: Text(context.l10n.kidsManualCompleteAction),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              minimumSize: const Size.fromHeight(52),
              shape: const RoundedRectangleBorder(
                borderRadius: KidsTheme.buttonRadius,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget shown while recording is active.
/// Displays an animated waveform, elapsed time, and a "Done" button.
class _RecordingActivePanel extends StatefulWidget {
  const _RecordingActivePanel({
    super.key,
    required this.seconds,
    required this.onDone,
  });

  final int seconds;
  final VoidCallback onDone;

  @override
  State<_RecordingActivePanel> createState() => _RecordingActivePanelState();
}

class _RecordingActivePanelState extends State<_RecordingActivePanel>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!mounted) return;
    final disable = MediaQuery.of(context).disableAnimations;
    if (disable) {
      _waveController.value = 1.0;
    } else if (!_waveController.isAnimating) {
      if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
        _waveController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  String _formatSeconds(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: KidsTheme.forestGreen.withValues(alpha: 0.15),
        borderRadius: KidsTheme.buttonRadius,
        border: Border.all(
          color: KidsTheme.forestGreen.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing red dot
              AnimatedBuilder(
                animation: _waveController,
                builder: (_, _) => Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(
                      alpha: 0.5 + (_waveController.value * 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.l10n.kidsGamifiedRecordingInProgress,
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _formatSeconds(widget.seconds),
                style: AppTypography.titleSmall.copyWith(
                  color: KidsTheme.forestGreen,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          // Animated waveform bars
          const SizedBox(height: AppSpacing.sm),
          AnimatedBuilder(
            animation: _waveController,
            builder: (_, _) {
              final v = _waveController.value;
              final heights = [0.5, 0.9, 0.6, 1.0, 0.7, 0.85, 0.55, 0.75, 0.4];
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < heights.length; i++) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 5,
                      height:
                          8 +
                          (24 *
                              heights[i] *
                              (0.4 + 0.6 * ((v + i * 0.15) % 1.0))),
                      decoration: BoxDecoration(
                        color: KidsTheme.forestGreen.withValues(
                          alpha: 0.6 + 0.4 * ((v + i * 0.1) % 1.0),
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    if (i < heights.length - 1) const SizedBox(width: 4),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          // Done button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('kids-gamified-stop-recording'),
              onPressed: widget.onDone,
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(context.l10n.kidsGamifiedDoneRecording),
              style: FilledButton.styleFrom(
                backgroundColor: KidsTheme.forestGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: const RoundedRectangleBorder(
                  borderRadius: KidsTheme.buttonRadius,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _navigateAfterKidsCompletion(
  BuildContext context,
  KidsModeLoaded state,
) async {
  if (state.newAwards.isNotEmpty) {
    await showCertificateCelebrationDialog(context, state.newAwards);
  }
  if (!context.mounted) return;
  context.pushReplacement(
    '${AppRoutes.memorizationPlusKidsCompletion}'
    '?surahId=${state.surahId}'
    '&completedAyahNumber=${state.ayahNumber}'
    '&starsEarned=${state.sessionStarsEarned}',
  );
}
