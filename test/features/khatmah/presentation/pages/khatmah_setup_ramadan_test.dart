import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan_template.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/create_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_setup_page.dart';

class MockCreateKhatmahUsecase extends Mock implements CreateKhatmahUsecase {}

class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  final first = DateTime(2027, 2, 8);
  RamadanInfo info(RamadanPhase phase) => RamadanInfo(
    phase: phase,
    monthLength: 30,
    firstDay: first,
    lastDay: DateTime(2027, 3, 9),
  );

  late MockCreateKhatmahUsecase create;

  setUpAll(() => registerFallbackValue(FakeKhatmahPlan()));
  setUp(() => create = MockCreateKhatmahUsecase());
  tearDown(() async {
    if (getIt.isRegistered<ExperienceFlags>()) {
      await getIt.unregister<ExperienceFlags>();
    }
  });

  void setFlag(bool on) =>
      getIt.registerSingleton<ExperienceFlags>(ExperienceFlags((_) => on));

  Future<void> pump(WidgetTester tester, RamadanPhase phase) async {
    final cubit = KhatmahSetupCubit(create);
    final router = GoRouter(
      initialLocation: '/s',
      routes: [
        GoRoute(
          path: '/s',
          builder: (_, _) => KhatmahSetupPage(
            cubit: cubit,
            ramadanInfo: info(phase),
            now: first,
          ),
        ),
        GoRoute(
          path: '/khatmah/dashboard',
          builder: (_, _) => const Scaffold(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
  }

  const box = Key('khatmah_setup_ramadan_templates');

  testWidgets('flag off: no templates', (tester) async {
    setFlag(false);
    await pump(tester, RamadanPhase.ramadan);
    expect(find.byKey(box), findsNothing);
  });

  testWidgets('afterEid: no templates', (tester) async {
    setFlag(true);
    await pump(tester, RamadanPhase.afterEid);
    expect(find.byKey(box), findsNothing);
  });

  testWidgets('ramadan with flag: three templates', (tester) async {
    setFlag(true);
    await pump(tester, RamadanPhase.ramadan);
    expect(find.byKey(box), findsOneWidget);
    for (final t in RamadanKhatmahTemplate.values) {
      expect(
        find.byKey(Key('khatmah_setup_ramadan_${t.name}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('oneInMonth submits pages unit, ceil(604/days)', (tester) async {
    setFlag(true);
    when(() => create(any())).thenAnswer((_) async {});
    await pump(tester, RamadanPhase.ramadan);
    final chip = find.byKey(const Key('khatmah_setup_ramadan_oneInMonth'));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    final submit = find.byKey(const Key('khatmah_setup_submit_button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    final plan =
        verify(() => create(captureAny())).captured.single as KhatmahPlan;
    expect(plan.targetPagesPerDay, (604 / 30).ceil());
    expect(plan.targetDays, 30);
    expect(plan.wirdUnit, KhatmahWirdUnit.pages);
  });

  testWidgets('splitByPrayers shows 5 contiguous portions', (tester) async {
    setFlag(true);
    await pump(tester, RamadanPhase.ramadan);
    final chip = find.byKey(const Key('khatmah_setup_ramadan_splitByPrayers'));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    final ranges = <(int, int)>[];
    for (var i = 0; i < 5; i++) {
      final text = tester
          .widget<Text>(find.byKey(Key('khatmah_setup_ramadan_portion_$i')))
          .data!;
      final m = RegExp(r'pages (\d+)–(\d+)').firstMatch(text)!;
      ranges.add((int.parse(m[1]!), int.parse(m[2]!)));
    }
    expect(
      find.byKey(const Key('khatmah_setup_ramadan_portion_5')),
      findsNothing,
    );
    expect(ranges.first.$1, 1);
    expect(ranges.last.$2, 21);
    for (var i = 1; i < 5; i++) {
      expect(ranges[i].$1, ranges[i - 1].$2 + 1);
    }
  });
}
