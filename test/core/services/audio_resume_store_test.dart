import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/services/audio_resume_store.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';

void main() {
  test('new reciter resume survives restart and can be updated', () async {
    final raw = jsonEncode(
      const AudioResumePosition(
        surahId: 1,
        ayahNumber: 2,
        reciterId: 'maher',
      ).toJson(),
    );
    SharedPreferences.setMockInitialValues({'audio_resume_position': raw});
    final prefs = await SharedPreferences.getInstance();
    final store = AudioResumeStore(prefs);
    expect(
      const AudioResumePosition(
        surahId: 1,
        ayahNumber: 2,
        reciterId: 'maher',
      ).reciter,
      QuranReciter.maher,
    );
    expect(store.position?.reciter, QuranReciter.maher);
    expect(store.position?.ayahNumber, 2);
    expect(prefs.getString('audio_resume_position'), raw);
    await store.save(
      const AudioResumePosition(surahId: 1, ayahNumber: 3, reciterId: 'maher'),
    );
    expect(AudioResumeStore(prefs).position?.reciter, QuranReciter.maher);
    expect(AudioResumeStore(prefs).position?.ayahNumber, 3);
  });

  test(
    'rejects an audio resume write after account authority is invalidated',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AudioResumeStore(prefs);
      AccountDataBarrier.forPreferences(prefs).invalidate();

      await expectLater(
        store.save(const AudioResumePosition(surahId: 67, ayahNumber: 1)),
        throwsA(isA<AccountDataUnavailableException>()),
      );
      expect(store.position, isNull);
    },
  );

  test(
    'hides an existing audio resume position while account data is blocked',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AudioResumeStore(prefs);
      await store.save(const AudioResumePosition(surahId: 67, ayahNumber: 1));

      AccountDataBarrier.forPreferences(prefs).invalidate();

      expect(store.position, isNull);
    },
  );
}
