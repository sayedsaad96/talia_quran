import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/presentation/pages/quran_reader_page.dart';

/// B3 — listening to the page on screen counts toward the khatmah only.
void main() {
  const playingPage44 = QuranAudioPlayerState(
    status: PlaybackStatus.playing,
    currentPageNumber: 44,
  );

  test('khatmah: playing the page on screen counts as engagement', () {
    expect(
      QuranReaderPage.countsAsListening(
        mode: QuranReaderMode.khatmah,
        audio: playingPage44,
        currentPage: 44,
      ),
      isTrue,
    );
  });

  test('free reading still requires a touch', () {
    expect(
      QuranReaderPage.countsAsListening(
        mode: QuranReaderMode.free,
        audio: playingPage44,
        currentPage: 44,
      ),
      isFalse,
    );
  });

  test('paused audio or another page does not count', () {
    expect(
      QuranReaderPage.countsAsListening(
        mode: QuranReaderMode.khatmah,
        audio: const QuranAudioPlayerState(
          status: PlaybackStatus.paused,
          currentPageNumber: 44,
        ),
        currentPage: 44,
      ),
      isFalse,
    );
    expect(
      QuranReaderPage.countsAsListening(
        mode: QuranReaderMode.khatmah,
        audio: playingPage44,
        currentPage: 45,
      ),
      isFalse,
    );
  });
}
