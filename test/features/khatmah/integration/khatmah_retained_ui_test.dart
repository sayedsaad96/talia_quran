import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_plan_model.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_schedule_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_dashboard_page.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_completion_page.dart';
import 'package:talia_quran/features/certificate/presentation/pages/certificate_page.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';

class _RejectSave extends KhatmahLocalDatasource {
  _RejectSave(super.prefs);
  bool reject = false;
  @override
  Future<void> savePlan(KhatmahPlanModel plan) async {
    if (reject) throw const KhatmahStorageException('rejected');
    await super.savePlan(plan);
  }
}

void main() {
  late _RejectSave data;
  late KhatmahRepositoryImpl repository;
  late KhatmahCubit cubit;
  DateTime now = DateTime(2026, 9, 4, 23, 59);
  final plan = KhatmahPlan(
    id: 'p',
    title: 'P',
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 9, 1),
    expectedEndDate: DateTime(2027, 1, 29),
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    data = _RejectSave(await SharedPreferences.getInstance());
    repository = KhatmahRepositoryImpl(data);
    now = DateTime(2026, 9, 4, 23, 59);
  });
  Future<void> pump(
    WidgetTester tester, {
    ValueChanged<KhatmahReadingResult>? onComplete,
  }) async {
    cubit = KhatmahCubit(
      GetActiveKhatmahUsecase(repository),
      RecordKhatmahReadingUsecase(repository),
      PauseResumeKhatmahUsecase(repository),
      DeleteKhatmahUsecase(repository),
      updateSchedule: UpdateKhatmahScheduleUsecase(repository),
      now: () => now,
    );
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => KhatmahDashboardPage(cubit: cubit),
        ),
        GoRoute(
          path: AppRoutes.khatmahCompletion,
          builder: (_, state) {
            onComplete?.call(state.extra! as KhatmahReadingResult);
            return const Scaffold(body: Text('persisted completion route'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('physical page604 delivers persisted completion exactly once', (
    tester,
  ) async {
    await repository.createPlan(
      plan.copyWith(completedPages: {for (var p = 1; p < 604; p++) p}),
    );
    final completions = <KhatmahReadingResult>[];
    await pump(tester, onComplete: completions.add);
    final open = find.byKey(const Key('khatmah_dashboard_log_mushaf_button'));
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('khatmah_dashboard_mushaf_page_input')),
      '604',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('khatmah_dashboard_mushaf_save_button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('persisted completion route'), findsOneWidget);
    expect(completions, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
    expect(completions.single.historyEntry!.certificate?.id, 'khatmah-p');
    expect(await repository.getActivePlan(), isNull);
    expect(await repository.getHistory(), hasLength(1));
    await tester.pump();
    expect(completions, hasLength(1));
  }, timeout: const Timeout(Duration(seconds: 30)));
  testWidgets('persisted completion action opens the issued certificate', (
    tester,
  ) async {
    await repository.createPlan(plan);
    final result = await RecordKhatmahReadingUsecase(repository)(
      (await repository.getActivePlan())!,
      604,
      source: KhatmahReadingSource.physical,
      readAt: now,
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              KhatmahCompletionPage(completion: result, enableConfetti: false),
        ),
        GoRoute(
          path: AppRoutes.certificate,
          builder: (_, state) {
            final extra = state.extra! as Map<String, dynamic>;
            return CertificatePage(
              award: extra['award'] as CertificateAward,
              userName: 'Reader',
            );
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(
      const Key('khatmah_completion_certificate_button'),
    );
    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(
      tester.widget<CertificatePage>(find.byType(CertificatePage)).award.id,
      'khatmah-p',
    );
    expect(await repository.getCompletedCount(), 1);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });
  testWidgets('retained abandon confirmation cannot delete replacement', (
    tester,
  ) async {
    await repository.createPlan(plan);
    await pump(tester);
    await tester.tap(find.byKey(const Key('khatmah_dashboard_abandon_button')));
    await tester.pumpAndSettle();
    await repository.deletePlan(expectedPlanId: 'p');
    await repository.createPlan(plan.copyWith(id: 'q'));
    await tester.tap(
      find.byKey(const Key('khatmah_dashboard_abandon_confirm_button')),
    );
    await tester.pumpAndSettle();
    expect((await repository.getActivePlan())?.id, 'q');
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });
  testWidgets('failed adaptive schedule never announces success', (
    tester,
  ) async {
    await repository.createPlan(plan);
    await pump(tester);
    data.reject = true;
    final button = find.byKey(
      const Key('khatmah_dashboard_calm_adjustment_button'),
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('End date recalibrated smoothly'), findsNothing);
    expect(cubit.state, isA<KhatmahProgressFailure>());
    data.reject = false;
    final retry = find.byKey(
      const Key('khatmah_dashboard_failure_retry_button'),
    );
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(
      (await repository.getActivePlan())!.expectedEndDate,
      DateTime(2027, 2, 1),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });
  testWidgets('retained daily target rolls at midnight without manual reload', (
    tester,
  ) async {
    await repository.createPlan(
      plan.copyWith(
        completedPages: {1, 2, 3, 4},
        dailyTargetDate: DateTime(2026, 9, 4),
        dailyTargetStartPage: 1,
        dailyTargetEndPage: 4,
      ),
    );
    await pump(tester);
    expect(cubit.state, isA<KhatmahWirdCompleted>());
    now = DateTime(2026, 9, 5);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(cubit.state, isA<KhatmahActive>());
    expect(find.text('Pages 5 to 8'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });
  testWidgets(
    'paused adaptive controls are disabled and cannot announce success',
    (tester) async {
      await repository.createPlan(plan.copyWith(status: KhatmahStatus.paused));
      await pump(tester);
      for (final key in [
        'khatmah_dashboard_calm_adjustment_button',
        'khatmah_dashboard_mild_compensation_button',
      ]) {
        expect(
          tester.widget<OutlinedButton>(find.byKey(Key(key))).onPressed,
          isNull,
        );
      }
      expect(find.byType(SnackBar), findsNothing);
      expect(
        (await repository.getActivePlan())!.expectedEndDate,
        DateTime(2027, 1, 29),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    },
  );
}
