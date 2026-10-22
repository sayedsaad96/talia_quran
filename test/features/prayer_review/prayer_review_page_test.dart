import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/v2/self_grade.dart';
import 'package:talia_quran/core/prayer_review/manual_prayer_review_committer.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_offer_service.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_authority.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_selection.dart';
import 'package:talia_quran/features/prayer_review/presentation/cubits/prayer_review_cubit.dart';
import 'package:talia_quran/features/prayer_review/presentation/pages/prayer_review_page.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

final _bodies = [
  for (var n = 1; n <= 3; n++)
    Ayah(
      number: n,
      surahId: 1,
      numberInSurah: n,
      page: 1,
      text: 'body $n   exact',
    ),
];
final _occurrence = PrayerOccurrence(
  ownerId: 'owner',
  localDate: DateTime(2026, 10, 20),
  prayerKey: PrayerKey.dhuhr,
  scheduledAt: DateTime.utc(2026, 10, 20, 12),
);

Future<PrayerReviewCubit> _cubit(
  Future<void> Function(V2SelfGrade) save,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final barrier = AccountDataBarrier.forPreferences(prefs)
    ..owner = const FixedRecordOwnerProvider('owner');
  PrayerReviewAuthority capture() =>
      PrayerReviewAuthority(ownerId: 'owner', lease: barrier.capture());
  final offer = PrayerReviewOffer(
    authority: capture(),
    selection: PrayerReviewSelection(
      ownerId: 'owner',
      localDayKey: '2026-10-20',
      prayerKey: PrayerKey.dhuhr,
      scheduledAt: DateTime.utc(2026, 10, 20, 12),
      selectedAt: DateTime.utc(2026, 10, 20, 11),
      surahId: 1,
      startAyah: 1,
      endAyah: 3,
    ),
  );
  return PrayerReviewCubit(
    captureAuthority: capture,
    accountChanges: barrier.changes,
    loadOffer: (_, {bool allowSelection = true}) async => offer,
    readPassage: (_) async => _bodies,
    saveGrade: (_, grade) async {
      await save(grade);
      return ManualPrayerReviewResult(
        alreadyCommitted: false,
        receipt: PrayerReviewReceipt(
          ownerId: 'owner',
          localDayKey: '2026-10-20',
          surahId: 1,
          startAyah: 1,
          endAyah: 3,
          gradeIndex: grade.index,
          committedAt: DateTime.utc(2026, 10, 20, 12),
          eventIds: ['e1', 'e2', 'e3'],
        ),
      );
    },
  );
}

Widget _app(
  PrayerReviewCubit cubit, {
  Locale locale = const Locale('en'),
  double scale = 1,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: BlocProvider.value(value: cubit, child: const PrayerReviewPage()),
);

void main() {
  testWidgets(
    'shows original passage and saves only the selected manual grade',
    (tester) async {
      final grades = <V2SelfGrade>[];
      final cubit = (await tester.runAsync(
        () => _cubit((grade) async => grades.add(grade)),
      ))!;
      await tester.runAsync(() => cubit.load(_occurrence));
      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();
      for (final ayah in _bodies) {
        expect(find.text(ayah.text), findsOneWidget);
      }
    await tester.scrollUntilVisible(find.text('With hesitation'), 200);
      await tester.tap(find.text('With hesitation'));
      await tester.pumpAndSettle();
      expect(grades, [V2SelfGrade.hesitated]);
      expect(find.text('Your self-assessment was saved.'), findsOneWidget);
      expect(find.text(_bodies.first.text), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(cubit.close);
    },
  );

  testWidgets(
    'Arabic narrow large-text save failure retains the same passage',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = (await tester.runAsync(
        () => _cubit((_) async => throw StateError('failed')),
      ))!;
      await tester.runAsync(() => cubit.load(_occurrence));
      await tester.pumpWidget(
        _app(cubit, locale: const Locale('ar'), scale: 1.7),
      );
      await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('لم أستطع'), 200);
      await tester.tap(find.text('لم أستطع'));
      await tester.pumpAndSettle();
      expect(cubit.state.status, PrayerReviewStatus.saveFailed);
      expect(cubit.state.ayahs.map((a) => a.text), _bodies.map((a) => a.text));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(cubit.close);
    },
  );
}
