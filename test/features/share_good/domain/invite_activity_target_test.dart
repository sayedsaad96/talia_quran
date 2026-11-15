import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';

void main() {
  test('round-trips all four v1 shapes', () {
    const targets = <InviteActivityTarget>[
      QuranPageInviteTarget(42),
      QuranSurahInviteTarget(18),
      QuranWirdInviteTarget(120, 124),
      AzkarCollectionInviteTarget(AzkarCategory.morning),
    ];
    for (final target in targets) {
      expect(InviteActivityTarget.fromJson(target.toJson()), target);
    }
  });
  test('rejects malformed targets', () {
    final invalid = <Object?>[
      {'v': 2, 'type': 'quran_page', 'page': 1},
      {'v': 1, 'type': 'quran_page', 'page': 1, 'text': 'x'},
      {'v': 1, 'type': 'quran_page', 'page': 0},
      {'v': 1, 'type': 'quran_page', 'page': 605},
      {'v': 1, 'type': 'quran_page', 'page': 4.0},
      {'v': 1, 'type': 'quran_surah', 'surah_id': 115},
      {'v': 1, 'type': 'quran_wird', 'start_page': 3, 'end_page': 2},
      {'v': 1, 'type': 'quran_wird', 'start_page': 1, 'end_page': 21},
      {'v': 1, 'type': 'azkar_collection', 'category': 'general'},
      null,
    ];
    for (final value in invalid) {
      expect(
        () => InviteActivityTarget.fromJson(value),
        throwsFormatException,
        reason: '$value',
      );
    }
  });
}
