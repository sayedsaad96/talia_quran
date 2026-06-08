import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/qcf_hifz_verse_view.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../certificate/presentation/widgets/certificate_celebration_dialog.dart';
import '../../domain/entities/hifz_entities.dart';
import '../cubits/hifz_session_cubit.dart';

class HifzSessionPage extends StatelessWidget {
  const HifzSessionPage({
    super.key,
    required this.surahId,
    required this.startAyah,
  });

  final int surahId;
  final int startAyah;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<HifzSessionCubit>()..startSession(surahId, startAyah),
      child: const _HifzSessionView(),
    );
  }
}

class _HifzSessionView extends StatelessWidget {
  const _HifzSessionView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.endSessionTitle),
            content: Text(context.l10n.hifzLeaveSessionMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.l10n.continueAction),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  context.l10n.exitAction,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.parchmentDark
            : AppColors.parchmentLight,
        body: BlocConsumer<HifzSessionCubit, HifzSessionState>(
          listener: (context, state) {
            if (state is HifzSessionLoaded) {
              _saveSessionLocation(state);
            }
            if (state is CertificatesEarned) {
              _saveSessionLocation(state.previousState);
              unawaited(
                showCertificateCelebrationDialog(context, state.awards),
              );
            }
            // T-06: Redirect kids who accidentally reach the basic session
            // back to their dedicated kids-home screen.
            if (state is HifzSessionError && state.redirectToKidsHome) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go(AppRoutes.memorizationPlusKidsHome);
                }
              });
            }
          },
          buildWhen: (previous, current) => current is! CertificatesEarned,
          builder: (context, state) {
            if (state is HifzSessionLoading) {
              return const Center(child: LoadingWidget());
            }
            if (state is HifzSessionError) {
              return ErrorStateWidget(message: state.message);
            }
            if (state is HifzSessionLoaded) {
              return _FullSurahSession(state: state, isDark: isDark);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _saveSessionLocation(HifzSessionLoaded state) {
    final ayah = state.ayahs[state.currentIndex];
    unawaited(
      getIt<AppSessionService>().saveLocation(
        '/hifz/session?surahId=${state.surah.id}&startAyah=${ayah.numberInSurah}',
      ),
    );
  }
}

class _FullSurahSession extends StatelessWidget {
  const _FullSurahSession({required this.state, required this.isDark});
  final HifzSessionLoaded state;
  final bool isDark;
  static const _skipHintKey = 'hifz_skip_hint_seen';

  Future<void> _showSkipHintIfNeeded(BuildContext context) async {
    final prefs = getIt<SharedPreferences>();
    final seen = prefs.getBool(_skipHintKey) ?? false;
    if (seen) return;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.skip_next_rounded,
                color: AppColors.primary,
                size: 36,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                sheetContext.l10n.hifzSkipHintTitle,
                style: AppTypography.titleLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                sheetContext.l10n.hifzSkipHintBody,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontFamily: 'Amiri',
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(sheetContext.l10n.understood),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await prefs.setBool(_skipHintKey, true);
  }

  Future<void> _handleSkip(BuildContext context) async {
    await _showSkipHintIfNeeded(context);
    if (!context.mounted) return;
    await context.read<HifzSessionCubit>().skipAyah();
  }

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final ayah = state.ayahs[state.currentIndex];
    final hasCheckpoint =
        state.requiredCheckpoint != null || state.completedCheckpoint != null;

    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          title: Text(
            context.isArabic ? state.surah.nameAr : state.surah.nameEn,
            style: context.isArabic
                ? AppTypography.surahTitle.copyWith(
                    color: primary,
                    fontSize: 24,
                  )
                : AppTypography.titleLarge.copyWith(color: primary),
          ),
          centerTitle: true,
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ayah Index label
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 100),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Text(
                    context.l10n.hifzAyahNumberLabel(ayah.numberInSurah),
                    style: AppTypography.titleMedium.copyWith(color: primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Ayah Text Area
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: primary.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: hasCheckpoint
                            ? _CheckpointReviewCard(
                                state: state,
                                isDark: isDark,
                              )
                            : state.isEvaluating
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    context.l10n.hifzEvaluatingAyah,
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              )
                            : state.similarityScore != null
                            ? _EvaluationResult(
                                state: state,
                                ayahText: ayah.text,
                                isDark: isDark,
                              )
                            // T013/T014: Show recording prompt while recording
                            // (correct text must not be revealed during recall).
                            // Show QcfHifzVerseView when verse is displayed normally.
                            : state.isRecording
                            ? Text(
                                context.l10n.hifzRecordingAyahHint,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: textColor,
                                  fontSize: 20,
                                ),
                                textAlign: TextAlign.center,
                              ).animate(target: 1).fade(end: 0.5)
                            : QcfHifzVerseView(
                                surahNumber: state.surah.id,
                                verseNumber: ayah.numberInSurah,
                                fallbackText: ayah.text,
                                isUnlocked: true,
                                isMemorized:
                                    state
                                        .progressMap[ayah.numberInSurah]
                                        ?.status ==
                                    AyahStatus.memorized,
                                displayMode: HifzVerseDisplayMode.single,
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Audio error banner
                if (state.audioError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.audioError!,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Controls Area
                if (!hasCheckpoint &&
                    state.similarityScore == null &&
                    !state.isEvaluating) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Listen Button
                      _ControlButton(
                        icon: state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.headphones_rounded,
                        label: context.l10n.listen,
                        color: Colors.blue,
                        isDark: isDark,
                        isActive: state.isPlaying,
                        onTap: () {
                          if (state.isPlaying) {
                            context.read<HifzSessionCubit>().pauseAudio();
                          } else {
                            context.read<HifzSessionCubit>().playAudio();
                          }
                        },
                      ),

                      // Record / Stop Button
                      GestureDetector(
                        onTap: () {
                          if (state.isRecording) {
                            context.read<HifzSessionCubit>().stopRecording();
                          } else {
                            context.read<HifzSessionCubit>().startRecording();
                          }
                        },
                        child: AnimatedContainer(
                          duration: 300.ms,
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: state.isRecording ? Colors.red : primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (state.isRecording)
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                            ],
                          ),
                          child: Icon(
                            state.isRecording
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),

                      // BUG-1 FIX: Skip now calls skipAyah() which applies
                      // a soft penalty so skipped ayahs are rescheduled
                      _ControlButton(
                        icon: state.currentIndex == state.ayahs.length - 1
                            ? Icons.done_all_rounded
                            : Icons.skip_next_rounded,
                        label: state.currentIndex == state.ayahs.length - 1
                            ? (context.l10n.finish)
                            : (context.l10n.skip),
                        color: Colors.grey,
                        isDark: isDark,
                        isActive: false,
                        onTap: () {
                          if (state.currentIndex == state.ayahs.length - 1) {
                            Navigator.of(context).pop();
                          } else {
                            unawaited(_handleSkip(context));
                          }
                        },
                      ),
                    ],
                  ),
                ],

                // Result Controls
                if (!hasCheckpoint &&
                    state.similarityScore != null &&
                    !state.isEvaluating) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // BUG-2 FIX: use state.passThreshold instead of hardcoded 0.85
                      if ((state.similarityScore ?? 0) < state.passThreshold)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                context.read<HifzSessionCubit>().retryAyah(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(context.l10n.tryAgainAction),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      if ((state.similarityScore ?? 0) < state.passThreshold)
                        const SizedBox(width: AppSpacing.md),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (state.currentIndex == state.ayahs.length - 1) {
                              Navigator.of(context).pop();
                            } else {
                              context.read<HifzSessionCubit>().nextAyah();
                            }
                          },
                          icon: Icon(
                            state.currentIndex == state.ayahs.length - 1
                                ? Icons.done_all_rounded
                                : context.isArabic
                                ? Icons.arrow_back_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                          label: Text(
                            state.currentIndex == state.ayahs.length - 1
                                ? context.l10n.hifzFinishSession
                                : context.l10n.hifzNextAyah,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                // BUG-2 FIX: use state.passThreshold
                                ((state.similarityScore ?? 0) >=
                                    state.passThreshold)
                                ? Colors.green
                                : primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EvaluationResult extends StatelessWidget {
  const _EvaluationResult({
    required this.state,
    required this.ayahText,
    required this.isDark,
  });
  final HifzSessionLoaded state;
  final String ayahText;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final score = (state.similarityScore ?? 0) * 100;
    // BUG-2 FIX: use state.passThreshold instead of hardcoded 85
    final pass = (state.similarityScore ?? 0) >= state.passThreshold;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          pass ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: pass ? Colors.green : Colors.redAccent,
          size: 64,
        ).animate().scale(delay: 100.ms),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${score.toStringAsFixed(1)}%',
          style: AppTypography.displaySmall.copyWith(
            color: pass ? Colors.green : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(),
        const SizedBox(height: AppSpacing.md),
        Text(
          pass
              ? context.l10n.hifzExcellentMemorization
              : context.l10n.hifzNeedsAyahReview,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const Divider(height: 40),
        Text(
          context.l10n.youRecited,
          style: AppTypography.labelSmall.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          state.recognizedText.isEmpty
              ? context.l10n.hifzNoVoiceRecognized
              : state.recognizedText,
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          textAlign: TextAlign.center,
          textDirection: context.textDirection,
        ),
      ],
    );
  }
}

class _CheckpointReviewCard extends StatelessWidget {
  const _CheckpointReviewCard({required this.state, required this.isDark});

  final HifzSessionLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final checkpoint = state.completedCheckpoint ?? state.requiredCheckpoint!;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final passed = state.completedCheckpoint != null;
    final failed =
        state.similarityScore != null &&
        (state.similarityScore ?? 0) < state.passThreshold;
    final isSmallFullSurah =
        state.surah.ayahCount <= 20 && checkpoint.isFullSurah;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          passed ? Icons.verified_rounded : Icons.assignment_turned_in_rounded,
          color: passed ? Colors.green : AppColors.gold,
          size: 64,
        ).animate().scale(duration: 200.ms),
        const SizedBox(height: AppSpacing.md),
        Text(
          passed
              ? context.l10n.hifzReviewPassedTitle
              : context.l10n.hifzReviewTimeTitle,
          style: AppTypography.titleLarge.copyWith(
            color: passed ? Colors.green : primary,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isSmallFullSurah
              ? context.l10n.hifzReviewFullSurahHint
              : context.l10n.hifzReviewRangeHint(
                  checkpoint.startAyah,
                  checkpoint.endAyah,
                ),
          style: AppTypography.bodyLarge.copyWith(color: textColor),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        if (state.isEvaluating) ...[
          const SizedBox(height: AppSpacing.lg),
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.hifzEvaluatingReview,
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
        ] else if (state.isRecording) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.hifzRecordingReviewHint,
            style: AppTypography.bodyMedium.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => context.read<HifzSessionCubit>().stopRecording(),
            icon: const Icon(Icons.stop_rounded),
            label: Text(context.l10n.hifzFinishRecitation),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ] else if (passed) ...[
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              if (state.currentIndex == state.ayahs.length - 1) {
                Navigator.of(context).pop();
              } else {
                context.read<HifzSessionCubit>().nextAyah();
              }
            },
            icon: Icon(
              state.currentIndex == state.ayahs.length - 1
                  ? Icons.done_all_rounded
                  : context.isArabic
                  ? Icons.arrow_back_rounded
                  : Icons.arrow_forward_rounded,
            ),
            label: Text(
              state.currentIndex == state.ayahs.length - 1
                  ? context.l10n.hifzFinishSession
                  : context.l10n.hifzNextAyah,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ] else ...[
          if (failed) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.hifzReviewNotPassed,
              style: AppTypography.bodyMedium.copyWith(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => context.read<HifzSessionCubit>().startRecording(),
            icon: const Icon(Icons.mic_rounded),
            label: Text(context.l10n.hifzStartRecitation),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? color
                  : (isDark ? AppColors.darkCard : AppColors.lightCard),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? color : color.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Icon(icon, color: isActive ? Colors.white : color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
