import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/services/audio_resume_store.dart';

void main() {
  test('rejects an audio resume write after account authority is invalidated', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AudioResumeStore(prefs);
    AccountDataBarrier.forPreferences(prefs).invalidate();

    await expectLater(
      store.save(const AudioResumePosition(surahId: 67, ayahNumber: 1)),
      throwsA(isA<AccountDataUnavailableException>()),
    );
    expect(store.position, isNull);
  });

  test('hides an existing audio resume position while account data is blocked',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AudioResumeStore(prefs);
    await store.save(const AudioResumePosition(surahId: 67, ayahNumber: 1));

    AccountDataBarrier.forPreferences(prefs).invalidate();

    expect(store.position, isNull);
  });
}
