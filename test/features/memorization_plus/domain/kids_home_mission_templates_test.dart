import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_home_mission_templates.dart';

void main() {
  test('every band gets a non-empty set without duplicates', () {
    for (final band in KidsAgeBand.values) {
      final ids = KidsHomeMissionTemplates.idsFor(band);
      expect(ids, isNotEmpty, reason: band.name);
      expect(ids.toSet().length, ids.length, reason: band.name);
    }
  });

  test('templates differ by age band', () {
    final young = KidsHomeMissionTemplates.idsFor(KidsAgeBand.fiveToSeven);
    final older = KidsHomeMissionTemplates.idsFor(KidsAgeBand.eightToTwelve);

    expect(young, contains(KidsHomeMissionTemplateId.shareToy));
    expect(young, isNot(contains(KidsHomeMissionTemplateId.prepareBag)));
    expect(older, contains(KidsHomeMissionTemplateId.prepareBag));
    expect(older, isNot(contains(KidsHomeMissionTemplateId.shareToy)));
  });

  test('every template is offered to at least one band', () {
    for (final id in KidsHomeMissionTemplateId.values) {
      expect(
        KidsHomeMissionTemplates.all.any((t) => t.id == id),
        isTrue,
        reason: id.name,
      );
    }
  });

  test('the legacy set is the four suggestions guardians already had', () {
    expect(KidsHomeMissionTemplates.legacy, [
      KidsHomeMissionTemplateId.tidyRoom,
      KidsHomeMissionTemplateId.helpTable,
      KidsHomeMissionTemplateId.kindWord,
      KidsHomeMissionTemplateId.shareToy,
    ]);
  });
}
