import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';

void main() {
  test('previews are write-free unless a session explicitly requests freeze', () {
    const preview = GetKidsJourneyParams(surahId: 114);
    const session = GetKidsJourneyParams(surahId: 114, freezeForSession: true);

    expect(preview.freezeForSession, isFalse);
    expect(session.freezeForSession, isTrue);
  });
}
