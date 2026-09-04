import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatm_dua_datasource.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_plan_model.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/create_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_khatm_dua_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatm_dua_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatm_dua_page.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_setup_page.dart';

class _HeldSave extends KhatmahLocalDatasource {
  _HeldSave(super.prefs);
  final release = Completer<void>();
  bool started = false;
  @override
  Future<void> savePlan(KhatmahPlanModel plan) async {
    started = true;
    await release.future;
    await super.savePlan(plan);
  }
}

class _Dua extends Mock implements GetKhatmDuaUsecase {}

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => getIt.reset());
  Future<GoRouter> open(WidgetTester tester, Widget page) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('previous page')),
        ),
        GoRoute(path: '/owned', builder: (_, _) => page),
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
    unawaited(router.push('/owned'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return router;
  }

  for (final fails in [false, true]) {
    testWidgets(
      'owned setup popped during save settles safely failure=$fails',
      (tester) async {
        final data = _HeldSave(await SharedPreferences.getInstance());
        final repository = KhatmahRepositoryImpl(data);
        late KhatmahSetupCubit cubit;
        getIt.registerFactory<KhatmahSetupCubit>(
          () => cubit = KhatmahSetupCubit(CreateKhatmahUsecase(repository)),
        );
        final router = await open(tester, const KhatmahSetupPage());
        final submit = find.byKey(const Key('khatmah_setup_submit_button'));
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pump();
        expect(data.started, isTrue);
        router.pop();
        await tester.pumpAndSettle();
        expect(cubit.isClosed, isTrue);
        if (fails) {
          data.release.completeError(Exception('save failed'));
        } else {
          data.release.complete();
        }
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('previous page'), findsOneWidget);
        expect(cubit.state, isA<KhatmahSetupSaving>());
        expect(await repository.getActivePlan(), fails ? isNull : isNotNull);
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      },
    );
    testWidgets('owned Dua popped during load settles safely failure=$fails', (
      tester,
    ) async {
      final getDua = _Dua();
      final release = Completer<KhatmDuaData>();
      when(() => getDua()).thenAnswer((_) => release.future);
      late KhatmDuaCubit cubit;
      getIt.registerFactory<KhatmDuaCubit>(() => cubit = KhatmDuaCubit(getDua));
      final router = await open(tester, const KhatmDuaPage());
      router.pop();
      await tester.pumpAndSettle();
      expect(cubit.isClosed, isTrue);
      if (fails) {
        release.completeError(Exception('asset failed'));
      } else {
        release.complete(
          const KhatmDuaData(
            arabicText: '',
            source: '',
            sourceNote: '',
            tier: 'guidance',
            dedicationInserts: {},
          ),
        );
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('previous page'), findsOneWidget);
      expect(cubit.state, isA<KhatmDuaLoading>());
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
  }
}
