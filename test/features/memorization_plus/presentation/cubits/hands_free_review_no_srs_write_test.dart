import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/hands_free/hands_free_round_state.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/services/hands_free_media_delegate.dart';
import 'package:talia_quran/features/memorization_plus/data/hands_free/hands_free_audio_session.dart';
import 'package:talia_quran/features/memorization_plus/data/hands_free/hands_free_practice_audio.dart';
import 'package:talia_quran/features/memorization_plus/data/hands_free/hands_free_review_source.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_recitation_capture.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/hands_free_review_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

/// Strict: only the two read methods are stubbed. Any other call (every write
/// included) returns null from mocktail, fails the typed await, and is also
/// caught by verifyNoMoreInteractions below.
class _StrictRecords extends Mock implements MemorizationPlusRepository {}

class _Quran extends Mock implements QuranRepository {}

class _Audio implements HandsFreePracticeAudio {
  @override
  Future<bool> playPrompt(ListeningAyahRef ref) async => true;
  @override
  Future<void> playFeedback(HandsFreeGrade grade) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

class _Capture implements ListeningRecitationCapture, ListeningCaptureHealth {
  @override
  bool hadError = false;
  String words = '';
  void Function()? ended;
  @override
  Future<ListeningCaptureReadiness> prepare() async =>
      ListeningCaptureReadiness.ready;
  @override
  Future<void> start(
    void Function(String) onWords, {
    required void Function() onStopped,
  }) async => ended = onStopped;
  @override
  Future<String> stop() async => words;
  @override
  Future<void> cancel() async {}
}

class _Session implements HandsFreeAudioSession {
  @override
  Stream<void> get interruptions => const Stream.empty();
  @override
  void setCaptureActive(bool active) {}
  @override
  Future<void> activate() async {}
  @override
  Future<void> release() async {}
  @override
  Future<void> dispose() async {}
}

class _Lease implements HandsFreeMediaLease {
  @override
  bool get isCurrent => true;
  @override
  void publish({required MediaItem item, required bool playing}) {}
  @override
  Future<void> release() async {}
}

void main() {
  final now = DateTime.utc(2026, 10, 23);
  test('a full round never calls any review-records write method', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('owner-a');
    final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    final records = _StrictRecords();
    final quran = _Quran();
    final due = [
      for (var a = 1; a <= 2; a++)
        AyahReviewRecord(
          surahId: 1,
          ayahNumber: a,
          strengthLevel: 6,
          intervalDays: 1,
          lastReviewedAt: now.subtract(const Duration(days: 2)),
          nextReviewDate: now.subtract(const Duration(days: 1)),
          totalReviews: 1,
          lastRating: null,
          createdByMode: ReviewRecordCreatedByMode.v2Session,
        ),
    ];
    const texts = ['first test target', 'second test target'];
    when(() => records.getMemorizationProfile()).thenAnswer(
      (_) async => Right(
        MemorizationProfile.empty().copyWith(
          selectedPath: MemorizationPath.adult,
        ),
      ),
    );
    when(
      () => records.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    ).thenAnswer((_) async => Right(due));
    when(() => quran.getSurahDetail(1)).thenAnswer(
      (_) async => Right(
        SurahDetail(
          surah: const Surah(
            id: 1,
            nameAr: 'test',
            nameEn: 'test',
            ayahCount: 2,
            juz: 1,
            type: 'test',
            page: 1,
          ),
          ayahs: [
            for (var i = 0; i < 2; i++)
              Ayah(
                number: i + 1,
                surahId: 1,
                numberInSurah: i + 1,
                text: texts[i],
              ),
          ],
        ),
      ),
    );
    final source = HandsFreeReviewSource(
      records,
      quran,
      owner,
      barrier,
      MemorizationPathResolver(records),
    );
    final capture = _Capture();
    final cubit = HandsFreeReviewCubit(
      load: source.load,
      audio: _Audio(),
      capture: capture,
      session: _Session(),
      acquireMedia: (_) async => _Lease(),
      mediaTitle: (_) => 'test practice',
      now: () => now,
      firstUseWarningPending: false,
    );
    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    await cubit.start();
    capture.words = texts[0];
    capture.ended!();
    await settle();
    capture.ended = null;
    cubit.onSecondary(); // Self-grade the second ayah.
    await settle();
    expect(cubit.state.round!.phase, HandsFreePhase.finished);
    expect(cubit.state.round!.grades.whereType<HandsFreeGrade>(), hasLength(2));
    await cubit.close();

    verify(() => records.getMemorizationProfile()).called(1);
    verify(
      () => records.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    ).called(1);
    verifyNoMoreInteractions(records);
  });
}
