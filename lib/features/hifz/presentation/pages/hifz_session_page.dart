import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
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
            title: Text(context.isArabic ? 'إنهاء الجلسة؟' : 'End Session?'),
            content: Text(context.isArabic
                ? 'هل تريد الخروج من جلسة الحفظ؟ سيتم حفظ تقدمك الحالي.'
                : 'Do you want to leave the memorization session? Your current progress will be saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.isArabic ? 'متابعة' : 'Continue'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  context.isArabic ? 'خروج' : 'Exit',
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
        body: BlocBuilder<HifzSessionCubit, HifzSessionState>(
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
}

class _FullSurahSession extends StatelessWidget {
  const _FullSurahSession({required this.state, required this.isDark});
  final HifzSessionLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final ayah = state.ayahs[state.currentIndex];
    final fontSize = getIt<SharedPreferences>()
        .getDouble(AppConstants.kFontSize) ?? AppConstants.fontSizeLarge;
    
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          title: Text(
            context.isArabic ? state.surah.nameAr : state.surah.nameEn,
            style: context.isArabic 
                ? AppTypography.surahTitle.copyWith(color: primary, fontSize: 24)
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 100),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Text(
                    '${context.isArabic ? "آية" : "Ayah"} ${ayah.numberInSurah}',
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
                        child: state.isEvaluating 
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  context.isArabic ? "جارِ التقييم..." : "Evaluating...",
                                  style: AppTypography.bodyLarge.copyWith(color: textColor),
                                )
                              ],
                            )
                          : state.similarityScore != null
                            ? _EvaluationResult(state: state, ayahText: ayah.text, isDark: isDark)
                            : Text(
                                state.isRecording 
                                  ? (context.isArabic ? "يتم التسجيل، اقرأ الآية من حفظك..." : "Recording, recite from memory...")
                                  : ayah.text,
                                style: AppTypography.quranVerse.copyWith(
                                  color: textColor,
                                  fontSize: state.isRecording ? 20 : fontSize,
                                ),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                              ).animate(target: state.isRecording ? 1 : 0).fade(end: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Audio error banner
                if (state.audioError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.audioError!,
                            style: AppTypography.bodySmall.copyWith(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Controls Area
                if (state.similarityScore == null && !state.isEvaluating) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Listen Button
                      _ControlButton(
                        icon: state.isPlaying ? Icons.pause_rounded : Icons.headphones_rounded,
                        label: context.isArabic ? 'استماع' : 'Listen',
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
                                )
                            ],
                          ),
                          child: Icon(
                            state.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      
                      // Next Button (Manual overrides if needed)
                      _ControlButton(
                        icon: Icons.skip_next_rounded,
                        label: context.isArabic ? 'تخطي' : 'Skip',
                        color: Colors.grey,
                        isDark: isDark,
                        isActive: false,
                        onTap: () {
                           context.read<HifzSessionCubit>().nextAyah();
                        },
                      ),
                    ],
                  ),
                ],
                
                // Result Controls
                if (state.similarityScore != null && !state.isEvaluating) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if ((state.similarityScore ?? 0) < 0.85)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.read<HifzSessionCubit>().retryAyah(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(context.isArabic ? 'حاول مجدداً' : 'Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      if ((state.similarityScore ?? 0) < 0.85)
                        const SizedBox(width: AppSpacing.md),
                        
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.read<HifzSessionCubit>().nextAyah(),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(context.isArabic ? 'الآية التالية' : 'Next Ayah'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ((state.similarityScore ?? 0) >= 0.85) ? Colors.green : primary,
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
  const _EvaluationResult({required this.state, required this.ayahText, required this.isDark});
  final HifzSessionLoaded state;
  final String ayahText;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final score = (state.similarityScore ?? 0) * 100;
    final pass = score >= 85;
    
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
            ? (context.isArabic ? 'ممتاز! حفظ متقن.' : 'Excellent! Perfect memorization.')
            : (context.isArabic ? 'تحتاج إلى مراجعة هذه الآية.' : 'You need to review this Ayah.'),
          style: AppTypography.titleMedium.copyWith(color: isDark ? Colors.white70 : Colors.black87),
        ),
        const Divider(height: 40),
        Text(
          context.isArabic ? "ما قرأته:" : "You recited:",
          style: AppTypography.labelSmall.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          state.recognizedText.isEmpty ? (context.isArabic ? "(لم يتم التعرف على صوت)" : "(No voice recognized)") : state.recognizedText,
          style: AppTypography.bodyLarge.copyWith(color: isDark ? Colors.white54 : Colors.black54),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
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
              color: isActive ? color : (isDark ? AppColors.darkCard : AppColors.lightCard),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? color : color.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          )
        ],
      ),
    );
  }
}
