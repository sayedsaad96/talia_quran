import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
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

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => currentOwnerId != 'local';
}

Map<String, Object?> _historyRow({
  required String id,
  required String title,
  String? certificateId,
  int khatmahNumber = 1,
  int totalDays = 31,
}) => {
  'id': id,
  'khatmahNumber': khatmahNumber,
  'title': title,
  'startDate': '2026-01-01T00:00:00.000',
  'completedDate': '2026-01-31T00:00:00.000',
  'totalDays': totalDays,
  'dedication': null,
  'certificateId': certificateId,
};

Future<void> _pumpHistoryPage(
  WidgetTester tester,
  KhatmahHistoryCubit cubit, {
  Locale locale = const Locale('en'),
  Size? size,
  double textScale = 1,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
  }
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: textScale == 1
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
      home: KhatmahHistoryPage(cubit: cubit),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'mismatched-only history is corrupt instead of a false empty state',
    (tester) async {
      final rawHistory = jsonEncode([
        {
          'id': 'mismatched-plan',
          'khatmahNumber': 1,
          'title': 'Private mismatched completion',
          'startDate': '2026-01-01T00:00:00.000',
          'completedDate': '2026-01-31T00:00:00.000',
          'totalDays': 31,
          'dedication': null,
          'certificateId': 'khatmah-someone-else',
        },
      ]);
      SharedPreferences.setMockInitialValues({'khatmah_history': rawHistory});
      final prefs = await SharedPreferences.getInstance();
      final repository = KhatmahRepositoryImpl(KhatmahLocalDatasource(prefs));
      final cubit = KhatmahHistoryCubit(GetKhatmahHistoryUsecase(repository));
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: KhatmahHistoryPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('khatmah_history_corrupt')), findsOneWidget);
      expect(find.byKey(const Key('khatmah_history_empty')), findsNothing);
      expect(find.text('Private mismatched completion'), findsNothing);
      expect(find.byKey(const Key('khatmah_history_retry')), findsOneWidget);
      expect(prefs.getString('khatmah_history'), rawHistory);
    },
  );

  testWidgets(
    'malformed storage is a retryable failure distinct from semantic corruption',
    (tester) async {
      SharedPreferences.setMockInitialValues({'khatmah_history': '{broken'});
      final prefs = await SharedPreferences.getInstance();
      final repository = KhatmahRepositoryImpl(KhatmahLocalDatasource(prefs));
      final cubit = KhatmahHistoryCubit(GetKhatmahHistoryUsecase(repository));
      addTearDown(cubit.close);

      await _pumpHistoryPage(tester, cubit);

      expect(find.byKey(const Key('khatmah_history_failure')), findsOneWidget);
      expect(find.byKey(const Key('khatmah_history_corrupt')), findsNothing);
      expect(find.byKey(const Key('khatmah_history_empty')), findsNothing);

      await prefs.setString(
        'khatmah_history',
        jsonEncode([
          _historyRow(
            id: 'recovered-plan',
            title: 'Recovered completion',
            certificateId: 'khatmah-recovered-plan',
          ),
        ]),
      );
      await tester.tap(find.byKey(const Key('khatmah_history_retry')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('khatmah_history_reopen_recovered-plan')),
        findsOneWidget,
      );
      expect(find.text('Recovered completion'), findsOneWidget);
    },
  );

  testWidgets(
    'mixed history shows valid certificate with warning and withholds invalid metadata',
    (tester) async {
      final history = [
        _historyRow(
          id: 'valid-plan',
          title: 'Valid completion',
          certificateId: 'khatmah-valid-plan',
        ),
        _historyRow(
          id: 'mismatched-plan',
          title: 'Private mismatched completion',
          certificateId: 'khatmah-another-plan',
        ),
        _historyRow(id: '', title: 'Partial private completion'),
      ];
      SharedPreferences.setMockInitialValues({
        'khatmah_history': jsonEncode(history),
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = KhatmahRepositoryImpl(KhatmahLocalDatasource(prefs));
      final cubit = KhatmahHistoryCubit(GetKhatmahHistoryUsecase(repository));
      addTearDown(cubit.close);

      await _pumpHistoryPage(tester, cubit);

      expect(find.byKey(const Key('khatmah_history_corrupt')), findsOneWidget);
      expect(
        find.byKey(const Key('khatmah_history_reopen_valid-plan')),
        findsOneWidget,
      );
      expect(find.text('Valid completion'), findsOneWidget);
      expect(find.text('Private mismatched completion'), findsNothing);
      expect(find.text('Partial private completion'), findsNothing);
      expect(find.byKey(const Key('khatmah_history_retry')), findsOneWidget);
      final persisted = prefs.getString('khatmah_history')!;
      expect(persisted, contains('khatmah-another-plan'));
      expect(persisted, contains('"certificateId":null'));
    },
  );

  testWidgets('old-owner history exposes no award or private metadata', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'auth_last_signed_in_user_id': 'a',
      'khatmah_owner': 'a',
      'khatmah_history': jsonEncode([
        _historyRow(
          id: 'owner-a-plan',
          title: 'Owner A private completion',
          certificateId: 'khatmah-owner-a-plan',
        ),
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final owner = _MutableOwner('b');
    AccountDataBarrier.forPreferences(prefs).owner = owner;
    final repository = KhatmahRepositoryImpl(KhatmahLocalDatasource(prefs));
    final cubit = KhatmahHistoryCubit(GetKhatmahHistoryUsecase(repository));
    addTearDown(cubit.close);

    await _pumpHistoryPage(tester, cubit);

    expect(find.byKey(const Key('khatmah_history_failure')), findsOneWidget);
    expect(find.text('Owner A private completion'), findsNothing);
    expect(
      find.byKey(const Key('khatmah_history_reopen_owner-a-plan')),
      findsNothing,
    );
  });

  testWidgets('long Arabic certificate action fits at 320px and 2x text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'khatmah_history': jsonEncode([
        _historyRow(
          id: 'arabic-plan',
          title: 'ختمة طويلة العنوان لاختبار العرض العربي الضيق',
          certificateId: 'khatmah-arabic-plan',
        ),
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final repository = KhatmahRepositoryImpl(KhatmahLocalDatasource(prefs));
    final cubit = KhatmahHistoryCubit(GetKhatmahHistoryUsecase(repository));
    addTearDown(cubit.close);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHistoryPage(
      tester,
      cubit,
      locale: const Locale('ar'),
      size: const Size(320, 640),
      textScale: 2,
    );

    expect(
      find.byKey(const Key('khatmah_history_reopen_arabic-plan')),
      findsOneWidget,
    );
    expect(find.text('فتح الشهادة مجدداً'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.byType(KhatmahHistoryPage))),
      TextDirection.rtl,
    );
  });

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
