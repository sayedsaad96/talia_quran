import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/repositories/khatmah_repository.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_khatmah_history_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_history_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_history_page.dart';

class _LifecycleHistoryRepository implements KhatmahRepository {
  const _LifecycleHistoryRepository(this.changes);

  @override
  final Stream<void>? changes;

  @override
  Object? get authority => null;

  @override
  Future<List<KhatmahHistoryEntry>> getHistory() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'persisted completion reopens the same award after feature restart',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = KhatmahRepositoryImpl(KhatmahLocalDatasource(prefs));
      final completed = KhatmahPlan(
        id: 'restart-plan',
        title: 'Restart Khatmah',
        completedPages: {for (var page = 1; page <= 604; page++) page},
        targetPagesPerDay: 4,
        targetDays: 151,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 6, 1),
        status: KhatmahStatus.completed,
        lastReadDate: DateTime(2026, 5, 31),
      );
      await repository.createPlan(completed);
      final persisted = await repository.completePlan(completed);
      expect(persisted.certificate?.id, 'khatmah-restart-plan');

      Future<CertificateAward> openFromFreshState() async {
        final cubit = KhatmahHistoryCubit(GetKhatmahHistoryUsecase(repository));
        late CertificateAward opened;
        final router = GoRouter(
          initialLocation: AppRoutes.khatmahHistory,
          routes: [
            GoRoute(
              path: AppRoutes.khatmahHistory,
              builder: (_, _) => KhatmahHistoryPage(cubit: cubit),
            ),
            GoRoute(
              path: AppRoutes.certificate,
              builder: (_, state) {
                final extra = state.extra! as Map<String, dynamic>;
                opened = extra['award'] as CertificateAward;
                return const Scaffold(body: Text('reopened certificate'));
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
        final reopen = find.byKey(
          const Key('khatmah_history_reopen_restart-plan'),
        );
        expect(reopen, findsOneWidget);
        await tester.tap(reopen);
        await tester.pumpAndSettle();
        expect(find.text('reopened certificate'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        await cubit.close();
        return opened;
      }

      final first = await openFromFreshState();
      final restarted = await openFromFreshState();
      expect(first, restarted);
      expect(restarted.id, persisted.certificate!.id);
      expect(await repository.getHistory(), hasLength(1));
    },
  );

  testWidgets('owned history page cancels its authority subscription on pop', (
    tester,
  ) async {
    await getIt.reset();
    var listens = 0;
    var cancels = 0;
    final changes = StreamController<void>.broadcast(
      onListen: () => listens++,
      onCancel: () => cancels++,
    );
    final repository = _LifecycleHistoryRepository(changes.stream);
    getIt.registerFactory<KhatmahHistoryCubit>(
      () => KhatmahHistoryCubit(GetKhatmahHistoryUsecase(repository)),
    );
    addTearDown(() async {
      await changes.close();
      await getIt.reset();
    });

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: KhatmahHistoryPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(listens, 1);
    expect(cancels, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(cancels, 1);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'history is accessible and overflow-free for ${locale.languageCode}',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repository = KhatmahRepositoryImpl(KhatmahLocalDatasource(prefs));
        final cubit = KhatmahHistoryCubit(GetKhatmahHistoryUsecase(repository));
        addTearDown(cubit.close);
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: KhatmahHistoryPage(cubit: cubit),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('khatmah_history_empty')), findsOneWidget);
        expect(tester.takeException(), isNull);
        final direction = Directionality.of(
          tester.element(find.byType(KhatmahHistoryPage)),
        );
        expect(
          direction,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
      },
    );
  }
}
