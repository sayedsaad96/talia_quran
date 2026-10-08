import 'package:flutter/material.dart';

import '../../../../core/icons/talia_icons.dart';
import '../../../../core/memorization/v2/session_phase.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../certificate/presentation/widgets/certificate_celebration_dialog.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/memorization_ayah_display.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/kids_mode_cubit.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_ayah_card.dart';
import '../widgets/guardian_pin_dialog.dart';
import '../widgets/kids_chunky_button.dart';
import '../widgets/kids_loading_widget.dart';
import '../widgets/kids_loop_progress_indicator.dart';
import '../widgets/kids_recording_waveform.dart';
import '../widgets/kids_talia_companion.dart';
import '../widgets/kids_ui.dart';

import '../../../../core/utils/locale_number_formatter.dart';

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

/// Guards the guardian completion flow against a double tap.
bool _guardianCompletionInFlight = false;

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
    // A double tap would stack two PIN dialogs.
    if (_guardianCompletionInFlight) return;
    _guardianCompletionInFlight = true;
    try {
      await _runGuardianCompletion(context);
    } finally {
      _guardianCompletionInFlight = false;
    }
  }

  Future<void> _runGuardianCompletion(BuildContext context) async {
    final cubit = context.read<KidsModeCubit>();
    // Confirming completion is a guardian action. The PIN is optional at
    // child setup, so on an unlinked device a guardian without one creates it
    // here first. A linked child's guardian is remote, and an unreadable
    // setting asks for the existing PIN.
    final repository = getIt<MemorizationPlusRepository>();
    final settings = (await repository.getParentSettings()).fold(
      (_) => null,
      (settings) => settings,
    );
    final isLinked = (await repository.getMemorizationProfile()).fold(
      (_) => true,
      (profile) => profile.isGuardianLinked,
    );
    if (!context.mounted) return;
    final String? pin;
    if (settings != null && !settings.hasPin && !isLinked) {
      pin = await createGuardianPin(context);
    } else {
      if (settings != null && !settings.hasPin) {
        // A linked child without a PIN: the remote guardian sets one through
        // recovery first, then it is entered below.
        final recovered = await verifyGuardianPin(
          context,
          confirmLabel: context.l10n.confirm,
          allowRecovery: true,
        );
        if (!recovered || !context.mounted) return;
      }
      pin = await showDialog<String>(
        context: context,
        builder: (_) => const _GuardianPinConfirmationDialog(),
      );
    }
    if (pin == null || !context.mounted) return;

    final accepted = await cubit.submitManualCompletion(guardianPin: pin);
    final alreadyDone =
        cubit.state is KidsModeLoaded &&
        (cubit.state as KidsModeLoaded).isCompleted;
    if (!accepted && !alreadyDone && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.parentDashboardPinIncorrect)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    void onBack() => context.canPop()
        ? context.pop()
        : context.go(
            MemorizationNavigationResolver.kidsHomeFallbackLocation(surahId),
          );

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
                  context.l10n.kidsGamifiedListenFirst(
                    state.maxLoops,
                    context.numText(state.maxLoops),
                  ),
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
            // W2: a near-miss recitation shows the friendly word-progress
            // banner instead of the generic snackbar — a single clear
            // message instead of double feedback.
            final mismatchWithWordFeedback =
                state.recordingError ==
                    CubitMessageCodes.kidsRecitationMismatch &&
                state.hasWordFeedback;
            if (!mismatchWithWordFeedback) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.localizedCubitMessage(state.recordingError!),
                  ),
                ),
              );
            }
            return;
          }
          if (state.isCompleted) {
            unawaited(_navigateAfterKidsCompletion(context, state));
          }
        },
        builder: (context, state) {
          if (state is KidsModeInitial || state is KidsModeLoading) {
            return KidsGamifiedListenStatusShell(
              onBack: onBack,
              child: const KidsLoadingWidget(),
            );
          }

          if (state is KidsModeError) {
            // Retrying cannot lift today's quota: lead the child back home,
            // where the day-complete card is waiting (N3).
            final isDailyLimit = state.message.startsWith(
              CubitMessageCodes.kidsDailySessionLimitPrefix,
            );
            return KidsGamifiedListenStatusShell(
              onBack: onBack,
              child: KidsErrorWidget(
                message: context.localizedCubitMessage(state.message),
                actionLabel: isDailyLimit ? context.l10n.goBack : null,
                onRetry: isDailyLimit
                    ? onBack
                    : () => context.read<KidsModeCubit>().load(
                        surahId,
                        ayahNumber,
                        ayahText,
                        missionType: missionType,
                      ),
              ),
            );
          }

          if (state is! KidsModeLoaded) return const SizedBox.shrink();

          return KidsGamifiedListenContent(
            state: state,
            onBack: onBack,
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
            onTryFromMemory: () =>
                context.read<KidsModeCubit>().tryFromMemory(),
            onRevealFirstWord: () =>
                context.read<KidsModeCubit>().revealFirstWord(),
            onRemindMe: () => context.read<KidsModeCubit>().remindMe(),
            onManualComplete: () => _submitGuardianCompletion(context),
          );
        },
      ),
    );
  }
}

@visibleForTesting
class KidsGamifiedListenStatusShell extends StatelessWidget {
  const KidsGamifiedListenStatusShell({
    super.key,
    required this.onBack,
    required this.child,
  });

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KidsBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              KidsTopBar(
                title: context.l10n.kidsGamifiedListenAndRepeat,
                onBack: onBack,
                backLabel: context.l10n.goBack,
              ),
              Expanded(child: child),
            ],
          ),
        ),
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
    this.onTryFromMemory,
    this.onRevealFirstWord,
    this.onRemindMe,
    this.onManualComplete,
  });

  final KidsModeLoaded state;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final VoidCallback onRecordRecitation;
  final VoidCallback onStopRecording;

  /// K25 — hides the ayah for recall once the listens are done (null
  /// disables the step).
  final VoidCallback? onTryFromMemory;

  /// K25 — "give me the start" while recalling (null hides the action).
  final VoidCallback? onRevealFirstWord;

  /// K28 — "remind me" at a hidden recitation (null hides the action).
  final VoidCallback? onRemindMe;

  /// V1-M8 — manual/self-grade completion route (null hides the action).
  final VoidCallback? onManualComplete;

  @override
  Widget build(BuildContext context) {
    final audioUnavailable = state.audioError != null;
    // Nothing moves around the recitation itself: the scene and Talia stay
    // still while the ayah plays or the child recites (Adventure §7).
    final calm =
        state.isPlaying ||
        state.isRecording ||
        state.isRecallingFromMemory ||
        state.isAwaitingRecitation ||
        state.sessionState.phase.textHidden;
    final pose = kidsTaliaPoseFor(state);

    return KidsBackground(
      animate: !calm,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              KidsTopBar(
                title: context.l10n.kidsGamifiedListenAndRepeat,
                onBack: onBack,
                backLabel: context.l10n.goBack,
              ),
              Expanded(
                child: CustomScrollView(
                  key: const PageStorageKey<String>('kids-gamified-listen'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      sliver: SliverList.list(
                        children: [
                          KidsTaliaCompanion(
                            key: const ValueKey('kids-talia-companion'),
                            pose: pose,
                            message: kidsTaliaBubbleFor(context, pose),
                            animate: !calm,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (state.isReview && state.isAwaitingRecitation)
                            const _KidsReviewChallengeCard()
                          else if (state.isRecording ||
                              state.sessionState.phase.textHidden)
                            const _KidsHiddenRecallCard()
                          else if (state.isRecallingFromMemory)
                            _KidsRecallFromMemoryCard(
                              firstWord: state.firstWordRevealed
                                  ? state.firstWord
                                  : null,
                            )
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
                              // K32: after a miss, the words that were right.
                              recalledWords: state.recalledWords,
                            ),
                          // W2: friendly word-level progress after a near
                          // miss — "you got X of Y words" instead of a bare
                          // failure.
                          if (state.hasWordFeedback) ...[
                            const SizedBox(height: AppSpacing.md),
                            _CloseMatchFeedbackBanner(
                              key: const ValueKey('kids-close-match-feedback'),
                              matched: state.lastMatchedWords,
                              total: state.lastTargetWords,
                            ),
                          ],
                          // A review has no listen gate to count (K28).
                          if (state.maxLoops > 0) ...[
                            const SizedBox(height: AppSpacing.md),
                            KidsLoopProgressIndicator(
                              completedLoops: state.currentLoop,
                              maxLoops: state.maxLoops,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          _KidsGamifiedAudioControls(
                            state: state,
                            onPlayPause: onPlayPause,
                            onRecordRecitation: onRecordRecitation,
                            onStopRecording: onStopRecording,
                            onTryFromMemory: onTryFromMemory,
                            onRevealFirstWord: onRevealFirstWord,
                            onRemindMe: onRemindMe,
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

/// A round, glossy icon badge that heads the kids session cards.
class _KidsMedallion extends StatelessWidget {
  const _KidsMedallion({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Color.lerp(color, Colors.white, 0.35)!, color],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: KidsTheme.card25DShadow,
      ),
      child: TaliaIcon(icon, color: Colors.white, size: 32),
    );
  }
}

const _kidsSoftCardDecoration = BoxDecoration(
  color: KidsTheme.creamParchment,
  borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusXl)),
  border: Border.fromBorderSide(
    BorderSide(color: KidsTheme.parchmentEdge, width: 2),
  ),
  boxShadow: KidsTheme.card25DShadow,
);

/// W2 — child-friendly near-miss feedback: celebrates how close the child
/// was and guides the next attempt, instead of a bare "did not match".
class _CloseMatchFeedbackBanner extends StatelessWidget {
  const _CloseMatchFeedbackBanner({
    super.key,
    required this.matched,
    required this.total,
  });

  final int matched;
  final int total;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final bannerContent = Semantics(
      label: context.l10n.kidsRecitationCloseMatch(
        LocaleNumberFormatter.format(
          (matched).toString(),
          context.l10n.localeName,
        ),
        LocaleNumberFormatter.format(
          (total).toString(),
          context.l10n.localeName,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: _kidsSoftCardDecoration.copyWith(
          border: Border.all(color: KidsTheme.goldStar, width: 2),
        ),
        child: Row(
          children: [
            const _KidsMedallion(
              icon: TaliaKidsIcons.trophy,
              color: KidsTheme.goldStar,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.kidsRecitationCloseMatch(
                      LocaleNumberFormatter.format(
                        (matched).toString(),
                        context.l10n.localeName,
                      ),
                      LocaleNumberFormatter.format(
                        (total).toString(),
                        context.l10n.localeName,
                      ),
                    ),
                    style: AppTypography.titleSmall.copyWith(
                      color: KidsTheme.inkOnParchment,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: matched / total),
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        color: KidsTheme.goldStar,
                        backgroundColor: KidsTheme.parchmentEdge.withValues(
                          alpha: 0.6,
                        ),
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

    return bannerContent;
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
          vertical: AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          gradient: KidsTheme.heroCardGradient,
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusXl)),
          boxShadow: KidsTheme.card25DShadow,
        ),
        child: Column(
          children: [
            const _KidsMedallion(
              icon: TaliaKidsIcons.hide,
              color: KidsTheme.mintGlow,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.kidsGamifiedTestStepSubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// K28 — "⭐ review challenge": a review opens with the ayah hidden, so the
/// attempt measures what stayed from before.
class _KidsReviewChallengeCard extends StatelessWidget {
  const _KidsReviewChallengeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('kids-review-challenge-card'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KidsTheme.sessionPurpleLight, KidsTheme.sessionPurpleDark],
        ),
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusXl)),
        boxShadow: KidsTheme.card25DShadow,
      ),
      child: Column(
        children: [
          const _KidsMedallion(
            icon: TaliaKidsIcons.starFilled,
            color: KidsTheme.goldStar,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.kidsGamifiedReviewChallenge,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.kidsGamifiedReviewChallengeSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// K25 — "try to remember": the ayah is hidden while the child recalls it.
/// After "give me the start" only the first word shows, verbatim from the
/// ayah text; it disappears again once recording starts (no hints during
/// recitation, Product Rules §5).
class _KidsRecallFromMemoryCard extends StatelessWidget {
  const _KidsRecallFromMemoryCard({this.firstWord});

  final String? firstWord;

  @override
  Widget build(BuildContext context) {
    final word = firstWord;
    return Container(
      key: const ValueKey('kids-recall-from-memory-card'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: _kidsSoftCardDecoration.copyWith(
        border: Border.all(
          color: KidsTheme.reviewPurple.withValues(alpha: 0.45),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const _KidsMedallion(
            icon: TaliaKidsIcons.hifz,
            color: KidsTheme.reviewPurple,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.kidsGamifiedTryToRemember,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: KidsTheme.inkOnParchment,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: word == null ? 0 : AppSpacing.lg),
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            ),
            child: word == null
                ? const SizedBox(key: ValueKey('kids-first-word-empty'))
                : Text(
                    word,
                    key: const ValueKey('kids-first-word'),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: MemorizationAyahDisplay.textStyle(
                      color: KidsTheme.forestGreen,
                    ),
                  ),
          ),
          if (word != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.kidsGamifiedFirstWordShown,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: KidsTheme.inkOnParchment.withValues(alpha: 0.75),
                letterSpacing: 0,
              ),
            ),
          ],
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
    this.onTryFromMemory,
    this.onRevealFirstWord,
    this.onRemindMe,
    this.onManualComplete,
  });

  final KidsModeLoaded state;
  final VoidCallback onPlayPause;
  final VoidCallback onRecordRecitation;
  final VoidCallback onStopRecording;
  final VoidCallback? onTryFromMemory;
  final VoidCallback? onRevealFirstWord;
  final VoidCallback? onRemindMe;

  /// V1-M8 — manual/self-grade completion route (null hides the action).
  final VoidCallback? onManualComplete;

  @override
  Widget build(BuildContext context) {
    final isRecording = state.isRecording;
    final loopsComplete = state.currentLoop >= state.maxLoops;
    final micDisabled = state.isCompleted || isRecording || !loopsComplete;
    // K25: the mic belongs to recall. Before it, the step is "try from
    // memory"; while recalling, "give me the start" sits under the mic.
    // K28: a hidden recitation (a review, or a near miss) keeps the mic too.
    final recalling = state.isRecallingFromMemory || state.isAwaitingRecitation;
    final showFirstWordHint =
        state.isRecallingFromMemory &&
        !isRecording &&
        !state.firstWordRevealed &&
        onRevealFirstWord != null;
    final showRemindMe = state.isAwaitingRecitation && onRemindMe != null;
    // K8: a listen-gated mic is never silent — the button area itself carries
    // a persistent hint, instead of relying on a one-shot SnackBar.
    final showListenFirstHint =
        !state.isCompleted && !isRecording && !loopsComplete;
    final showManualComplete =
        !state.isCompleted &&
        !isRecording &&
        onManualComplete != null &&
        state.canUseGuardianFallback;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: KidsRoundActionButton(
            key: const ValueKey('kids-gamified-play-audio'),
            icon: state.isPlaying ? TaliaKidsIcons.stop : TaliaKidsIcons.play,
            label: context.l10n.kidsGamifiedListenAndRepeat,
            // No audio during a hidden recitation: it would be the answer.
            onPressed: state.isRecording || state.sessionState.phase.textHidden
                ? null
                : onPlayPause,
            active: state.isPlaying,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          ),
          child: isRecording
              ? _RecordingActivePanel(
                  key: const ValueKey('recording-panel'),
                  seconds: state.recordingSeconds,
                  onDone: onStopRecording,
                )
              : showListenFirstHint
              ? _ListenFirstMicHint(
                  key: const ValueKey('kids-gamified-record-recitation-idle'),
                  remainingListens: state.maxLoops - state.currentLoop,
                  // Tapping the hint plays the audio (never records).
                  onPlayPressed: onPlayPause,
                )
              : recalling
              ? Center(
                  key: const ValueKey('kids-gamified-record-recitation-idle'),
                  child: KidsRoundActionButton(
                    icon: TaliaKidsIcons.mic,
                    label: context.l10n.kidsGamifiedRecordYourVoice,
                    tone: KidsButtonTone.green,
                    diameter: 100,
                    onPressed: micDisabled ? null : onRecordRecitation,
                  ),
                )
              // A finished ayah has nothing left to try: no greyed-out button.
              : state.isCompleted
              ? const SizedBox.shrink(
                  key: ValueKey('kids-gamified-completed-idle'),
                )
              : KidsChunkyButton(
                  key: const ValueKey('kids-gamified-try-from-memory'),
                  onPressed: onTryFromMemory,
                  icon: TaliaKidsIcons.hifz,
                  label: context.l10n.kidsGamifiedTryFromMemory,
                  tone: KidsButtonTone.purple,
                ),
        ),
        if (showFirstWordHint) ...[
          const SizedBox(height: AppSpacing.md),
          KidsChunkyButton(
            key: const ValueKey('kids-gamified-first-word-hint'),
            onPressed: onRevealFirstWord,
            icon: TaliaKidsIcons.idea,
            label: context.l10n.kidsGamifiedGiveMeTheStart,
            tone: KidsButtonTone.soft,
            height: 56,
          ),
        ],
        if (showRemindMe) ...[
          const SizedBox(height: AppSpacing.md),
          KidsChunkyButton(
            key: const ValueKey('kids-gamified-remind-me'),
            onPressed: onRemindMe,
            icon: TaliaKidsIcons.show,
            label: context.l10n.kidsGamifiedRemindMe,
            tone: KidsButtonTone.soft,
            height: 56,
          ),
        ],
        if (showManualComplete) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: _kidsSoftCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.kidsManualCompleteHint,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: KidsTheme.inkOnParchment.withValues(alpha: 0.8),
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                KidsChunkyButton(
                  key: const ValueKey('kids-gamified-manual-complete'),
                  onPressed: onManualComplete,
                  icon: TaliaKidsIcons.verified,
                  label: context.l10n.kidsManualCompleteAction,
                  tone: KidsButtonTone.green,
                  height: 56,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// K8 — persistent listen-gate hint shown in place of the mic button while
/// required listens are still pending. Tapping it plays the audio.
class _ListenFirstMicHint extends StatelessWidget {
  const _ListenFirstMicHint({
    super.key,
    required this.remainingListens,
    required this.onPlayPressed,
  });

  final int remainingListens;
  final VoidCallback onPlayPressed;

  @override
  Widget build(BuildContext context) {
    return KidsChunkyButton(
      key: const ValueKey('kids-gamified-listen-first-hint'),
      onPressed: onPlayPressed,
      icon: TaliaKidsIcons.listen,
      label: context.l10n.kidsGamifiedListenFirst(
        remainingListens,
        context.numText(remainingListens),
      ),
      tone: KidsButtonTone.soft,
      maxLines: 3,
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
    // Reduced motion freezes the wave; tests control motion the same way
    // instead of sniffing the binding type (K24).
    if (MediaQuery.disableAnimationsOf(context)) {
      _waveController.stop();
      _waveController.value = 1.0;
    } else if (!_waveController.isAnimating) {
      _waveController.repeat(reverse: true);
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
    return context.digitText(
      '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _kidsSoftCardDecoration.copyWith(
        border: Border.all(color: KidsTheme.buttonGreenFace, width: 2),
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
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(
                      alpha: 0.5 + (_waveController.value * 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  context.l10n.kidsGamifiedRecordingInProgress,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: KidsTheme.inkOnParchment,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _formatSeconds(widget.seconds),
                style: AppTypography.titleSmall.copyWith(
                  color: KidsTheme.buttonGreenFace,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          // The waveform paints inside fixed slots, so recording updates do
          // not trigger a panel relayout on every tick.
          const SizedBox(height: AppSpacing.sm),
          KidsRecordingWaveform(animation: _waveController),
          const SizedBox(height: AppSpacing.md),
          // Done button
          KidsChunkyButton(
            key: const ValueKey('kids-gamified-stop-recording'),
            onPressed: widget.onDone,
            icon: TaliaKidsIcons.checkCircleFilled,
            label: context.l10n.kidsGamifiedDoneRecording,
            tone: KidsButtonTone.green,
            height: 56,
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
  // K11: carry session points (and any level-up) to the completion screen.
  final levelUpSegment = state.leveledUpTo == null
      ? ''
      : '&leveledUpTo=${state.leveledUpTo}';
  context.pushReplacement(
    '${AppRoutes.memorizationPlusKidsCompletion}'
    '?surahId=${state.surahId}'
    '&completedAyahNumber=${state.ayahNumber}'
    '&starsEarned=${state.sessionStarsEarned}'
    '&pointsEarned=${state.sessionPointsEarned}'
    '$levelUpSegment',
  );
}

class _GuardianPinConfirmationDialog extends StatefulWidget {
  const _GuardianPinConfirmationDialog();

  @override
  State<_GuardianPinConfirmationDialog> createState() =>
      _GuardianPinConfirmationDialogState();
}

class _GuardianPinConfirmationDialogState
    extends State<_GuardianPinConfirmationDialog> {
  late final TextEditingController _pinController;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.parentDashboardEnterPinTitle),
      content: SingleChildScrollView(
        child: TextField(
          controller: _pinController,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: InputDecoration(
            helperText: context.l10n.parentDashboardPinHelp,
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _pinController.text.trim()),
          child: Text(context.l10n.confirm),
        ),
      ],
    );
  }
}
