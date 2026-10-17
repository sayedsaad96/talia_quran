import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/guardian_milestone_seen_store.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/guardian_news_section.dart';

class _Repo implements MemorizationPlusRepository {
  FamilyDashboard dashboard = const FamilyDashboard(
    children: [],
    settings: ParentSettings(weeklyGoalSessions: 99),
  );

  @override
  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard() async =>
      Right(dashboard);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

KidsSessionLog _log(int ayah) => KidsSessionLog(
  id: 'l$ayah',
  surahId: 114,
  ayahNumber: ayah,
  repeatsCompleted: 3,
  pointsEarned: 5,
  completedAt: DateTime.utc(2026, 10, 14),
);

FamilyDashboard _dashboard(List<KidsSessionLog> logs) => FamilyDashboard(
  settings: const ParentSettings(weeklyGoalSessions: 99),
  children: [
    FamilyChildEntry(
      childUserId: 'local-id',
      displayName: 'Noor',
      isLocal: true,
      localData: ParentDashboard(
        progress: const KidsProgress.initial(),
        stages: const [],
        logs: logs,
        rewards: const [],
        settings: const ParentSettings(),
      ),
    ),
  ],
);

void main() {
  testWidgets('shows a line and «Done» dismisses through the cubit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = GuardianMilestoneSeenStore(
      prefs,
      const FixedRecordOwnerProvider('owner'),
    );
    final repo = _Repo();
    final cubit = FamilyDashboardCubit(
      ParentAccessUsecase(repo),
      ParentRemoteLinkUsecase(repo),
      GetFamilyDashboardUsecase(repo),
      guardianSessionActive: () => true,
      milestoneStore: store,
      milestonesEnabled: () => true,
      ayahCounts: () async => {114: 2},
    );
    addTearDown(cubit.close);
    repo.dashboard = _dashboard([_log(1)]);
    await cubit.refresh();
    repo.dashboard = _dashboard([_log(1), _log(2)]);
    await cubit.refresh();
    final loaded = cubit.state as FamilyDashboardLoaded;
    expect(loaded.news, hasLength(1));

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: GuardianNewsSection(news: loaded.news)),
        ),
      ),
    );

    expect(find.text("What's new"), findsOneWidget);
    expect(find.textContaining('Noor completed Surah'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guardian-news-dismiss')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );

    expect((cubit.state as FamilyDashboardLoaded).news, isEmpty);
    expect(await store.seen('local'), {'surah:114'});
  });
}
