import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../../core/widgets/ayah_listen_button.dart';
import '../../../../core/widgets/qcf_hifz_verse_view.dart';
import '../../../certificate/presentation/widgets/certificate_celebration_dialog.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/quiz_cubit.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key, required this.surahId, this.ayahNumbers});

  final int surahId;
  final List<int>? ayahNumbers;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<QuizCubit>()
            ..loadQuiz(surahId: surahId, ayahNumbers: ayahNumbers),
      child: const _QuizView(),
    );
  }
}

class _QuizView extends StatelessWidget {
  const _QuizView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    // BUG-10 FIX: wrap with PopScope to prevent losing quiz results on back press
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final cubit = context.read<QuizCubit>();
        // Allow pop freely if quiz is done or not yet started
        if (cubit.state is QuizCompleted ||
            cubit.state is QuizInitial ||
            cubit.state is QuizLoading ||
            cubit.state is QuizError) {
          if (context.mounted) context.pop();
          return;
        }
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(context.l10n.quizExitTitle),
            content: Text(context.l10n.quizExitMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.quizStayAction),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  context.l10n.quizExitAction,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if ((shouldPop ?? false) && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          title: Text(
            context.l10n.reviewQuizTitle,
            style: AppTypography.titleLarge.copyWith(
              fontFamily: 'Amiri',
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        body: BlocConsumer<QuizCubit, QuizState>(
          listener: (context, state) {
            if (state is QuizAnswerResult && state.newAwards.isNotEmpty) {
              unawaited(
                showCertificateCelebrationDialog(context, state.newAwards),
              );
            }
          },
          builder: (context, state) {
            if (state is QuizLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is QuizError) {
              return _ErrorView(message: state.message, isDark: isDark);
            }
            if (state is QuizQuestion) {
              return _QuestionView(state: state, isDark: isDark);
            }
            if (state is QuizAnswerResult) {
              return _AnswerResultView(state: state, isDark: isDark);
            }
            if (state is QuizCompleted) {
              return _CompletedView(state: state, isDark: isDark);
            }
            return const SizedBox.shrink();
          },
        ),
      ), // Scaffold
    ); // PopScope
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Question View
// ═══════════════════════════════════════════════════════════════════════════════

class _QuestionView extends StatefulWidget {
  const _QuestionView({required this.state, required this.isDark});
  final QuizQuestion state;
  final bool isDark;

  @override
  State<_QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<_QuestionView> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _speechInitialized = false;
  int _speechFailureCount = 0;
  String _recognizedWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech({bool resetFailures = false}) async {
    if (resetFailures) {
      setState(() {
        _speechInitialized = false;
        _speechFailureCount = 0;
      });
    }

    // Check mic permission first
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechEnabled = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _speechFailureCount++;
            });
          }
          TaliaLogger.w('Speech recognition error', val);
        },
      );
    }
    if (!mounted) return;
    setState(() => _speechInitialized = true);
  }

  void _listen() async {
    if (!_speechEnabled) {
      setState(() => _speechInitialized = true);
      return;
    }

    if (!_isListening) {
      setState(() {
        _isListening = true;
        _recognizedWords = '';
      });
      await _speech.listen(
        onResult: (val) => setState(() {
          _recognizedWords = val.recognizedWords;
        }),
        localeId: 'ar_SA', // Set to Arabic
      );
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _QuestionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.ayahNumber != widget.state.ayahNumber) {
      _recognizedWords = '';
      _isListening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final isDark = widget.isDark;
    final primary = Theme.of(context).primaryColor;
    final progress = (s.questionIndex + 1) / s.totalQuestions;
    final showManualPanel =
        _speechInitialized && (!_speechEnabled || _speechFailureCount >= 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          Row(
            children: [
              Text(
                '${s.questionIndex + 1}/${s.totalQuestions}',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '✅ ${s.passedSoFar}',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Question card
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: isDark ? 0.2 : 0.08),
                  Colors.deepPurple.withValues(alpha: isDark ? 0.1 : 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.mic_none_rounded,
                  size: 48,
                  color: primary.withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'الآية رقم ${s.ayahNumber}',
                  style: AppTypography.headlineSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'اضغط على المايكروفون وقم بتسميع الآية',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Hint
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lightbulb_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'تلميح: ${s.hint}',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.amber.shade700,
                            fontFamily: 'Amiri',
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Listen Section ──────────────────────────────────────────────
          // Allows the user to hear the ayah before reciting it from memory.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: isDark ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                AyahListenButton(
                  surahId: s.surahId,
                  ayahNumber: s.ayahNumber,
                  size: AyahListenButtonSize.normal,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'استمع للآية',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.blue,
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'استمع قبل التسميع لتتذكر النطق الصحيح',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Voice Control Area
          Center(
            child: GestureDetector(
              onTap: _listen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? Colors.redAccent
                      : primary.withValues(alpha: 0.15),
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  size: 48,
                  color: _isListening ? Colors.white : primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              _isListening
                  ? 'جاري الاستماع...'
                  : (_recognizedWords.isEmpty
                        ? 'انقر للتحدث'
                        : 'انقر لإعادة التسجيل'),
              style: AppTypography.labelMedium.copyWith(
                color: _isListening
                    ? Colors.redAccent
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          if (showManualPanel) ...[
            const SizedBox(height: AppSpacing.lg),
            _ManualEvaluationPanel(
              isDark: isDark,
              onRetryMic: () => _initSpeech(resetFailures: true),
              onSkip: () => context.read<QuizCubit>().nextQuestion(),
              onRate: (rating) =>
                  context.read<QuizCubit>().submitManualRating(rating),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Speech Output
          if (_recognizedWords.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Text(
                _recognizedWords,
                textDirection: TextDirection.rtl,
                style: AppTypography.bodyLarge.copyWith(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  height: 2.0,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],

          // Submit button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isListening
                  ? null
                  : () {
                      if (_recognizedWords.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'يرجى تسجيل الصوت أولاً قبل التحقق',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        return;
                      }
                      context.read<QuizCubit>().submitAnswer(_recognizedWords);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                disabledBackgroundColor: primary.withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded),
                  const SizedBox(width: 12),
                  Text(
                    'تحقق من الإجابة',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualEvaluationPanel extends StatelessWidget {
  const _ManualEvaluationPanel({
    required this.isDark,
    required this.onRetryMic,
    required this.onSkip,
    required this.onRate,
  });

  final bool isDark;
  final VoidCallback onRetryMic;
  final VoidCallback onSkip;
  final ValueChanged<PerformanceRating> onRate;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: Colors.orange),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'التقييم اليدوي',
                  style: AppTypography.titleMedium.copyWith(
                    color: textColor,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'إذا لم يعمل الميكروفون، قيّم التسميع بنفس المقياس المستخدم في التطبيق.',
            style: AppTypography.bodySmall.copyWith(color: subTextColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ManualRatingButton(
                label: 'ضعيف',
                icon: Icons.replay_rounded,
                color: Colors.orange,
                onTap: () => onRate(PerformanceRating.weak),
              ),
              _ManualRatingButton(
                label: 'متوسط',
                icon: Icons.check_circle_outline_rounded,
                color: Theme.of(context).primaryColor,
                onTap: () => onRate(PerformanceRating.average),
              ),
              _ManualRatingButton(
                label: 'ممتاز',
                icon: Icons.verified_rounded,
                color: Colors.green,
                onTap: () => onRate(PerformanceRating.excellent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetryMic,
                  icon: const Icon(Icons.mic_rounded, size: 18),
                  label: const Text('إعادة محاولة الميكروفون'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                onPressed: onSkip,
                icon: const Icon(Icons.skip_next_rounded, size: 18),
                label: const Text('تخطي الآية'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualRatingButton extends StatelessWidget {
  const _ManualRatingButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.55)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Answer Result View
// ═══════════════════════════════════════════════════════════════════════════════

class _AnswerResultView extends StatelessWidget {
  const _AnswerResultView({required this.state, required this.isDark});
  final QuizAnswerResult state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final passed = state.passed;
    final color = passed ? Colors.green : Colors.orange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Result badge
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
              child: Icon(
                passed
                    ? Icons.check_circle_rounded
                    : Icons.psychology_alt_rounded,
                size: 72,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              passed ? 'أحسنت! ✨' : 'نراجعها معاً 💪',
              style: AppTypography.headlineSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'نسبة التطابق: ${state.scorePercent}%',
                style: AppTypography.titleMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // T017: correct Quran text rendered through QcfHifzVerseView.
          // userText stays as normal recognized speech text (unchanged).
          _ComparisonCard(
            title: 'النص الصحيح',
            text: state.correctText,
            icon: Icons.auto_stories_rounded,
            color: Colors.green,
            isDark: isDark,
            child: QcfHifzVerseView(
              surahNumber: state.surahId,
              verseNumber: state.ayahNumber,
              fallbackText: state.correctText,
              isUnlocked: true,
              isMemorized: false,
              displayMode: HifzVerseDisplayMode.comparison,
              textAlign: TextAlign.right,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // User text
          _ComparisonCard(
            title: context.l10n.quizYourAnswer,
            text: state.userText,
            icon: Icons.edit_note_rounded,
            color: passed ? Colors.green : Colors.orange,
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.xl),

          if (!passed) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  AyahListenButton(
                    surahId: state.surahId,
                    ayahNumber: state.ayahNumber,
                    size: AyahListenButtonSize.normal,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.quizListenRetryTitle,
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.orange.shade700,
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          context.l10n.quizListenRetrySubtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Next button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.read<QuizCubit>().nextQuestion(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Text(
                state.questionIndex < state.totalQuestions - 1
                    ? context.l10n.quizNextAyah
                    : context.l10n.quizShowResults,
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.title,
    required this.text,
    required this.icon,
    required this.color,
    required this.isDark,
    this.child,
  });
  final String title;
  final String text;
  final IconData icon;
  final Color color;
  final bool isDark;

  /// Optional content override. When provided, renders instead of Text(text).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // T017: render child (QcfHifzVerseView) when provided, else fallback Text.
          child ??
              Text(
                text,
                style: AppTypography.bodyLarge.copyWith(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  height: 2.0,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                textDirection: TextDirection.rtl,
              ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Completed View
// ═══════════════════════════════════════════════════════════════════════════════

class _CompletedView extends StatelessWidget {
  const _CompletedView({required this.state, required this.isDark});
  final QuizCompleted state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final passed = state.overallScore >= 0.8;
    final color = passed ? Colors.green : Colors.amber;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Medal
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Text(
              passed ? '🏆' : '📊',
              style: const TextStyle(fontSize: 72),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            passed
                ? context.l10n.quizExcellentResult
                : context.l10n.quizGoodEffortResult,
            style: AppTypography.displaySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            passed
                ? context.l10n.quizPassedMessage
                : context.l10n.quizRetryMessage,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Score circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 4),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${state.scorePercent}%',
                    style: AppTypography.displaySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    context.l10n.quizScoreLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                label: context.l10n.quizTotalLabel,
                value: '${state.totalQuestions}',
                icon: Icons.list_rounded,
                color: primary,
                isDark: isDark,
              ),
              _StatChip(
                label: context.l10n.quizPassedLabel,
                value: '${state.passedCount}',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
                isDark: isDark,
              ),
              _StatChip(
                label: context.l10n.quizNeedsPracticeLabel,
                value: '${state.failedCount}',
                icon: Icons.replay_rounded,
                color: Colors.orange,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl * 2),

          // Actions
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(
                context.l10n.backAction,
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Error View
// ═══════════════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.isDark});
  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 64,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }
}
