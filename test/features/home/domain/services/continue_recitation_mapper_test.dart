import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/home/domain/entities/continue_recitation.dart';
import 'package:talia_quran/features/home/domain/services/continue_recitation_mapper.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';

void main() {
  const mapper = ContinueRecitationMapper();
  final now = DateTime(2026, 9, 9, 10);

  KhatmahPlan planWith({
    KhatmahStatus status = KhatmahStatus.active,
    int startPage = 10,
    int endPage = 13,
  }) {
    return KhatmahPlan(
      id: 'k1',
      title: KhatmahPlan.defaultTitle,
      status: status,
      targetPagesPerDay: 4,
      targetDays: 151,
      startDate: now,
      expectedEndDate: now.add(const Duration(days: 151)),
      dailyTargetDate: now,
      dailyTargetStartPage: startPage,
      dailyTargetEndPage: endPage,
      completedPages: {for (var page = 1; page <= 11; page++) page},
    );
  }

  test('active khatmah uses real daily page target as N of M', () {
    final recitation = mapper.map(
      isArabic: true,
      activeKhatmah: planWith(),
      now: now,
    );

    expect(recitation, isNotNull);
    expect(recitation!.unit, ContinueRecitationUnit.pages);
    expect(recitation.current, 2);
    expect(recitation.total, 4);
    expect(recitation.percent, 0.5);
    expect(recitation.route, '/quran/page/12?mode=khatmah');
  });

  test('random mushaf browsing without an active khatmah returns null', () {
    final recitation = mapper.map(
      isArabic: false,
      lastRestorableLocation: '/quran/page/42',
      confirmedReadPages: 37,
    );

    expect(recitation, isNull);
  });

  test('confirmed read pages without an active khatmah return null', () {
    final recitation = mapper.map(
      isArabic: false,
      confirmedReadPages: 80,
    );

    expect(recitation, isNull);
  });

  test('paused khatmah returns null', () {
    final recitation = mapper.map(
      isArabic: true,
      activeKhatmah: planWith(status: KhatmahStatus.paused),
      confirmedReadPages: 3,
    );

    expect(recitation, isNull);
  });

  test('completed khatmah returns null', () {
    final recitation = mapper.map(
      isArabic: true,
      activeKhatmah: planWith(status: KhatmahStatus.completed),
    );

    expect(recitation, isNull);
  });
}
