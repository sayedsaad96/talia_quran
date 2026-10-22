import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/backup/backup_sections.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/progress/hijri_year_recap.dart';
import 'package:talia_quran/core/progress/hijri_year_recap_loader.dart';
import 'package:talia_quran/features/progress/presentation/cubits/hijri_year_recap_cubit.dart';
import 'package:talia_quran/features/progress/presentation/widgets/hijri_year_recap_slot.dart';
import 'package:talia_quran/features/progress/presentation/widgets/hijri_year_recap_card.dart';

class _Source implements HijriYearRecapSource {
  _Source({this.visible = true, this.dismissed = false, this.wait});
  final bool visible;
  final bool dismissed;
  final Future<bool>? wait;
  int loads = 0;
  final dismissedYears = <int>[];

  @override
  Future<HijriYearRecapLoadResult> load() async {
    loads++;
    if (wait != null) await wait;
    return HijriYearRecapLoadResult(
      _recap(visible: visible),
      dismissed: dismissed,
    );
  }

  @override
  Future<void> dismiss(int hijriYear) async => dismissedYears.add(hijriYear);
}

HijriYearRecap _recap({bool visible = true}) => HijriYearRecap(
  hijriYear: 1448,
  yearStartDate: DateTime(2026, 6, 1),
  yearEndExclusiveDate: DateTime(2027, 5, 1),
  visibilityStartDate: DateTime(2027, 4, 1),
  visibilityEndDate: DateTime(2027, 4, 20),
  isVisible: visible,
  completedKhatmahs: 2,
  approximateMemorizedAyahs: 12,
  lifetimeLongestStreak: 21,
  activityByDay: const {'2027-04-01': 1},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<
    ({HijriYearRecapCubit cubit, _Source source, AccountDataBarrier barrier})
  >
  make({
    bool adult = true,
    bool visible = true,
    bool dismissed = false,
    Future<bool>? profileWait,
    Future<bool>? loadWait,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final barrier = AccountDataBarrier.forPreferences(prefs);
    final source = _Source(
      visible: visible,
      dismissed: dismissed,
      wait: loadWait,
    );
    return (
      cubit: HijriYearRecapCubit(
        source,
        barrier,
        readAdultEligibility: () async =>
            profileWait == null ? adult : await profileWait,
      ),
      source: source,
      barrier: barrier,
    );
  }

  test('flag off performs no profile or recap read', () async {
    final env = await make();
    await env.cubit.load(enabled: false, isAdult: true);
    expect(env.source.loads, 0);
    expect(env.cubit.state, const HijriYearRecapState.hidden());
    await env.cubit.close();
  });

  test('adult hint cannot bypass false profile eligibility', () async {
    final env = await make(adult: false);
    await env.cubit.load(enabled: true, isAdult: true);
    expect(env.source.loads, 0);
    expect(env.cubit.state.isVisible, isFalse);
    await env.cubit.close();
  });

  test(
    'invalidation during eligibility drops the result and clears view',
    () async {
      final gate = Completer<bool>();
      final env = await make(profileWait: gate.future);
      final loading = env.cubit.load(enabled: true, isAdult: true);
      env.barrier.invalidate();
      gate.complete(true);
      await loading;
      expect(env.source.loads, 0);
      expect(env.cubit.state.isVisible, isFalse);
      await env.cubit.close();
    },
  );

  test('invalidation during loading drops a stale recap', () async {
    final gate = Completer<bool>();
    final env = await make(loadWait: gate.future);
    final loading = env.cubit.load(enabled: true, isAdult: true);
    await Future<void>.delayed(Duration.zero);
    expect(env.source.loads, 1);
    env.barrier.invalidate();
    gate.complete(true);
    await loading;
    expect(env.cubit.state.isVisible, isFalse);
    await env.cubit.close();
  });

  test('dismissed and out-of-window recaps remain hidden', () async {
    for (final env in [
      await make(dismissed: true),
      await make(visible: false),
    ]) {
      await env.cubit.load(enabled: true, isAdult: true);
      expect(env.cubit.state.isVisible, isFalse);
      await env.cubit.close();
    }
  });

  test('dismiss writes the selected Hijri year then hides', () async {
    final env = await make();
    await env.cubit.load(enabled: true, isAdult: true);
    await env.cubit.dismiss();
    expect(env.source.dismissedYears, [1448]);
    expect(env.cubit.state.isVisible, isFalse);
    await env.cubit.close();
  });

  test('owner/year dismissal keys are reset and backup scoped', () {
    const prefix = HijriYearRecapLoader.dismissalPrefix;
    const key = '${prefix}1448|owner-a';
    expect(AccountDataReset.clearedPreferencePrefixes, contains(prefix));
    expect(
      BackupPreferencePolicy.backupKeyFor(key, 'owner-a'),
      '${prefix}1448|{owner}',
    );
    expect(BackupPreferencePolicy.backupKeyFor(key, 'owner-b'), isNull);
    expect(() => BackupPreferencePolicy.validate(key, true), returnsNormally);
    expect(() => BackupPreferencePolicy.validate(key, 'true'),
        throwsA(isA<BackupSectionInvalid>()));
  });

  testWidgets('flag-off slot does not resolve DI or fetch data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const HijriYearRecapSlot(enabled: false, isAdult: true),
    );
    expect(find.byType(HijriYearRecapSlot), findsOneWidget);
  });

  testWidgets('a hidden recap leaves no spacing gap', (tester) async {
    final env = await make(visible: false);
    await getIt.reset();
    getIt.registerFactory<HijriYearRecapCubit>(() => env.cubit);
    addTearDown(getIt.reset);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: HijriYearRecapSlot(
            enabled: true,
            isAdult: true,
            padding: EdgeInsets.only(top: 40),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(tester.getSize(find.byType(HijriYearRecapSlot)).height, 0);
  });

  testWidgets('Arabic card renders the year, activity, and approximate label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: HijriYearRecapCard(recap: _recap())),
      ),
    );
    expect(find.textContaining('١٤٤٨'), findsOneWidget);
    expect(find.textContaining('أيام النشاط'), findsOneWidget);
    expect(find.textContaining('تقريب'), findsOneWidget);
  });
}
