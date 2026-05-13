import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/achievement_service.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../../../features/quran/domain/repositories/quran_repository.dart';
import '../../../../core/utils/arabic_normalizer.dart';

part 'quiz_state.dart';

class QuizCubit extends Cubit<QuizState> {
  QuizCubit(this._repository, this._quranRepository, this._achievementService)
    : super(const QuizInitial());

  final MemorizationPlusRepository _repository;
  final QuranRepository _quranRepository;
  final AchievementService _achievementService;

  List<_QuizItem> _items = [];
  int _currentIndex = 0;
  int _passedCount = 0;
  int _failedCount = 0;

  /// Load ayahs for quiz from a surah range.
  /// [surahId] - the surah to test
  /// [ayahNumbers] - specific ayahs to test (if null, tests all reviewed ayahs)
  Future<void> loadQuiz({required int surahId, List<int>? ayahNumbers}) async {
    emit(const QuizLoading());

    try {
      // Get surah detail for actual text
      final surahResult = await _quranRepository.getSurahDetail(surahId);
      final ayahs = surahResult.fold(
        (_) => <dynamic>[],
        (detail) => detail.ayahs,
      );

      if (ayahs.isEmpty) {
        emit(const QuizError('لم يتم العثور على بيانات السورة'));
        return;
      }

      // Get review records to find which ayahs the user has studied
      final recordsResult = await _repository.getAllReviewRecords();
      final records = recordsResult.fold((_) => <AyahReviewRecord>[], (r) => r);

      final surahRecords = records
          .where((r) => r.surahId == surahId && r.totalReviews > 0)
          .toList();
      final reviewedAyahNumbers = surahRecords.map((r) => r.ayahNumber).toSet();

      final cachedPlanResult = await _repository.getCachedDailyPlan();
      final cachedPlan = cachedPlanResult.getOrElse(() => null);
      final plannedAyahNumbers =
          cachedPlan != null && cachedPlan.surahId == surahId
          ? {
              ...cachedPlan.newAyahs.map((a) => a.ayahNumber),
              ...cachedPlan.nearRevision.map((a) => a.ayahNumber),
              ...cachedPlan.farRevision.map((a) => a.ayahNumber),
            }
          : <int>{};

      // Build quiz items
      _items = [];

      if (ayahNumbers != null && ayahNumbers.isNotEmpty) {
        final allowedAyahNumbers = ayahNumbers
            .where(
              (ayahNumber) =>
                  reviewedAyahNumbers.contains(ayahNumber) ||
                  plannedAyahNumbers.contains(ayahNumber),
            )
            .toSet();

        if (allowedAyahNumbers.isEmpty) {
          emit(const QuizError('لا يمكن اختبار آيات خارج خطتك أو سجلاتك'));
          return;
        }

        for (final num in allowedAyahNumbers) {
          try {
            final ayah = ayahs.firstWhere((a) => a.numberInSurah == num);
            _items.add(
              _QuizItem(
                surahId: surahId,
                ayahNumber: num,
                correctText: ayah.text,
              ),
            );
          } catch (_) {}
        }
      } else {
        // Test all reviewed ayahs in this surah
        for (final record in surahRecords) {
          try {
            final ayah = ayahs.firstWhere(
              (a) => a.numberInSurah == record.ayahNumber,
            );
            _items.add(
              _QuizItem(
                surahId: surahId,
                ayahNumber: record.ayahNumber,
                correctText: ayah.text,
              ),
            );
          } catch (_) {}
        }
      }

      if (_items.isEmpty) {
        emit(const QuizError('لا توجد آيات محفوظة لاختبارها في هذه السورة'));
        return;
      }

      _currentIndex = 0;
      _passedCount = 0;
      _failedCount = 0;

      _emitCurrentQuestion();
    } catch (e) {
      emit(QuizError('حدث خطأ: $e'));
    }
  }

  /// Submit the user's answer for the current ayah.
  Future<void> submitAnswer(String userInput) async {
    if (state is! QuizQuestion) return;
    final current = _items[_currentIndex];

    final similarity = _calculateSimilarity(
      ArabicNormalizer.normalize(userInput.trim()),
      ArabicNormalizer.normalize(current.correctText.trim()),
    );

    // BUG-8 FIX: three-tier grading instead of binary pass/fail
    // This prevents a 1% difference from swinging between best and worst outcome
    final PerformanceRating rating;
    final bool passed;
    if (similarity >= 0.80) {
      rating = PerformanceRating.excellent;
      passed = true;
      _passedCount++;
    } else if (similarity >= 0.60) {
      rating = PerformanceRating.average;
      passed = true; // counted as "passed" in quiz summary
      _passedCount++;
    } else {
      rating = PerformanceRating.weak;
      passed = false;
      _failedCount++;
    }

    var newAwards = <CertificateAward>[];
    final result = await _repository.evaluateAyah(
      surahId: current.surahId,
      ayahNumber: current.ayahNumber,
      rating: rating,
    );
    final failure = result.fold((f) => f, (_) => null);
    if (failure == null) {
      newAwards = await _achievementService.checkAndUnlockCertificates();
    }

    emit(
      QuizAnswerResult(
        surahId: current.surahId,
        ayahNumber: current.ayahNumber,
        correctText: current.correctText,
        userText: userInput.trim(),
        similarity: similarity,
        passed: passed,
        questionIndex: _currentIndex,
        totalQuestions: _items.length,
        newAwards: newAwards,
      ),
    );
  }

  /// Move to the next question or show final results.
  void nextQuestion() {
    _currentIndex++;
    if (_currentIndex >= _items.length) {
      emit(
        QuizCompleted(
          totalQuestions: _items.length,
          passedCount: _passedCount,
          failedCount: _failedCount,
          overallScore: _items.isEmpty ? 0 : _passedCount / _items.length,
        ),
      );
    } else {
      _emitCurrentQuestion();
    }
  }

  void _emitCurrentQuestion() {
    final item = _items[_currentIndex];
    // Show a hint: first few words
    final words = item.correctText.split(' ');
    final hint = words.length > 2
        ? '${words[0]} ${words[1]} ...'
        : '${words[0]} ...';

    emit(
      QuizQuestion(
        surahId: item.surahId,
        ayahNumber: item.ayahNumber,
        hint: hint,
        questionIndex: _currentIndex,
        totalQuestions: _items.length,
        passedSoFar: _passedCount,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Arabic text comparison utilities (using centralized ArabicNormalizer)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate similarity between two strings using longest common subsequence.
  double _calculateSimilarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final wordsA = a.split(' ');
    final wordsB = b.split(' ');

    // Word-level LCS
    final lcsLen = _lcsLength(wordsA, wordsB);
    final maxLen = wordsA.length > wordsB.length
        ? wordsA.length
        : wordsB.length;

    return lcsLen / maxLen;
  }

  int _lcsLength(List<String> a, List<String> b) {
    final m = a.length;
    final n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }
    return dp[m][n];
  }
}

/// Internal quiz item (not exposed outside cubit).
class _QuizItem {
  const _QuizItem({
    required this.surahId,
    required this.ayahNumber,
    required this.correctText,
  });
  final int surahId;
  final int ayahNumber;
  final String correctText;
}
