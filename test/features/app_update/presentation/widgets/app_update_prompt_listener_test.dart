import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/app_version_service.dart';
import 'package:talia_quran/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:talia_quran/features/app_update/domain/usecases/google_play_update_usecase.dart';
import 'package:talia_quran/features/app_update/presentation/cubits/app_update_cubit.dart';
import 'package:talia_quran/features/app_update/presentation/widgets/app_update_prompt_listener.dart';

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets(
      '${locale.languageCode}: install action requires an explicit tap with enlarged text',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final repository = _DownloadedUpdateRepository();
        final cubit = AppUpdateCubit(
          GooglePlayUpdateUseCase(repository),
          await SharedPreferences.getInstance(),
          const _VersionInfoProvider(),
        );
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        );
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(() async {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          router.dispose();
          await cubit.close();
          await repository.close();
        });

        await tester.pumpWidget(
          BlocProvider.value(
            value: cubit,
            child: MaterialApp.router(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
              builder: (_, child) => AppUpdatePromptListener(child: child!),
            ),
          ),
        );

        expect(repository.completeCalls, 0);
        repository.downloadedController.add(null);
        await tester.pumpAndSettle();

        final l10n = lookupAppLocalizations(locale);
        expect(find.text(l10n.appUpdateReady), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(l10n.appUpdateInstallAction));
        await tester.pump();

        expect(repository.completeCalls, 1);
      },
    );
  }
}

class _VersionInfoProvider implements AppVersionInfoProvider {
  const _VersionInfoProvider();

  @override
  Future<AppVersionInfo> getVersionInfo() async =>
      const AppVersionInfo(version: '1.0.1', buildNumber: '2');
}

class _DownloadedUpdateRepository implements AppUpdateRepository {
  final downloadedController = StreamController<void>.broadcast();
  int completeCalls = 0;

  @override
  bool get isSupported => true;

  @override
  Stream<void> get downloadedUpdates => downloadedController.stream;

  @override
  Future<AppUpdateCheckResult> checkForUpdate() async =>
      const AppUpdateCheckResult.noUpdate();

  @override
  Future<AppUpdateStartResult> startFlexibleUpdate() async =>
      AppUpdateStartResult.started;

  @override
  Future<void> completeFlexibleUpdate() async {
    completeCalls++;
  }

  Future<void> close() => downloadedController.close();
}
