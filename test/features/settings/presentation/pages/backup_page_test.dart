import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/backup/backup_file_format.dart';
import 'package:talia_quran/core/backup/backup_restorer.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:talia_quran/features/settings/presentation/cubits/settings_state.dart';
import 'package:talia_quran/features/settings/presentation/pages/backup_page.dart';
import 'package:talia_quran/features/settings/presentation/pages/subpages/about_settings_page.dart';

class _MockSettingsCubit extends Mock implements SettingsCubit {}

final _payload = BackupPayload(
  schemaVersion: kBackupSchemaVersion,
  createdAt: DateTime.utc(2026, 10, 17),
  sections: const {'streak': <String, Object?>{}},
);

Widget _app(Widget home) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const Scaffold(body: Text('splash-page')),
      ),
      GoRoute(
        path: AppRoutes.backup,
        builder: (_, _) => const Scaffold(body: Text('backup-route')),
      ),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

bool _off(String key) => false;
bool _on(String key) => key == ExperienceFeature.localBackup.storageKey;

void main() {
  late int restoreCalls;
  late int exportCalls;
  late BackupRestoreResult restoreResult;

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    restoreCalls = 0;
    exportCalls = 0;
    restoreResult = BackupRestoreResult.restored;
  });
  tearDown(() => getIt.reset());

  Future<void> pumpPage(
    WidgetTester tester, {
    bool signedIn = false,
    List<int>? picked,
    bool pickNothing = false,
  }) async {
    final bytes = picked ?? encodeBackup(_payload);
    await tester.pumpWidget(
      _app(
        BackupPage(
          isSignedIn: () => signedIn,
          collect: (now) async => _payload,
          restore: (p) async {
            restoreCalls++;
            return restoreResult;
          },
          pickFile: () async => pickNothing ? null : bytes,
          exportFile: (name, data) async {
            exportCalls++;
            expect(name, startsWith('talia-backup'));
            expect(decodeBackup(data).payload, isNotNull);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows what the file includes and excludes', (tester) async {
    await pumpPage(tester);
    expect(find.textContaining('Includes:'), findsOneWidget);
    expect(find.textContaining('Excludes: bookmarks'), findsOneWidget);
  });

  testWidgets('signed-in user sees restore disabled with the explanation', (
    tester,
  ) async {
    await pumpPage(tester, signedIn: true);
    expect(
      find.text(
        'Restore is only available without an account. '
        'Your data is saved in your account.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Restore from a file'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Replace current data?'), findsNothing);
    expect(restoreCalls, 0);
  });

  testWidgets('export collects, encodes and hands the file to the sharer', (
    tester,
  ) async {
    await pumpPage(tester, signedIn: true);
    await tester.tap(find.text('Export a backup'));
    await tester.pumpAndSettle();
    expect(exportCalls, 1);
  });

  for (final c in <(List<int>, String)>[
    ([1, 2, 3], 'This file is not a valid Talia backup.'),
  ]) {
    testWidgets('decode error maps to its message; nothing restored', (
      tester,
    ) async {
      await pumpPage(tester, picked: c.$1);
      await tester.tap(find.text('Restore from a file'));
      await tester.pumpAndSettle();
      expect(find.text(c.$2), findsOneWidget);
      expect(find.text('Replace current data?'), findsNothing);
      expect(restoreCalls, 0);
    });
  }

  test('every decode error has a message key', () {
    for (final e in BackupDecodeError.values) {
      expect(backupDecodeErrorKind(e), isNotNull);
    }
    expect(
      backupDecodeErrorKind(BackupDecodeError.checksumMismatch),
      BackupErrorKind.corrupt,
    );
    expect(
      backupDecodeErrorKind(BackupDecodeError.newerVersion),
      BackupErrorKind.newer,
    );
    expect(
      backupDecodeErrorKind(BackupDecodeError.notGzip),
      BackupErrorKind.invalid,
    );
  });

  testWidgets('cancelled picker does nothing', (tester) async {
    await pumpPage(tester, pickNothing: true);
    await tester.tap(find.text('Restore from a file'));
    await tester.pumpAndSettle();
    expect(find.text('Replace current data?'), findsNothing);
    expect(restoreCalls, 0);
  });

  testWidgets('declining the confirmation restores nothing', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Restore from a file'));
    await tester.pumpAndSettle();
    expect(find.text('Replace current data?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(restoreCalls, 0);
    expect(find.text('splash-page'), findsNothing);
  });

  testWidgets('confirm → restore called → navigates to splash', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Restore from a file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(restoreCalls, 1);
    expect(find.text('splash-page'), findsOneWidget);
  });

  testWidgets('invalid sections after confirm show the invalid message', (
    tester,
  ) async {
    restoreResult = BackupRestoreResult.invalidSections;
    await pumpPage(tester);
    await tester.tap(find.text('Restore from a file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(find.text('This file is not a valid Talia backup.'), findsOneWidget);
    expect(find.text('splash-page'), findsNothing);
  });

  testWidgets('write failure shows an error and stays on the page', (
    tester,
  ) async {
    restoreResult = BackupRestoreResult.writeFailed;
    await pumpPage(tester);
    await tester.tap(find.text('Restore from a file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(find.text('splash-page'), findsNothing);
    expect(
      find.text('Something unexpected happened. Please try again.'),
      findsOneWidget,
    );
  });

  group('settings tile and route', () {
    Future<void> pumpAbout(WidgetTester tester) async {
      final cubit = _MockSettingsCubit();
      when(() => cubit.state).thenReturn(const SettingsState());
      when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => cubit.close()).thenAnswer((_) async {});
      await tester.pumpWidget(
        _app(
          BlocProvider<SettingsCubit>.value(
            value: cubit,
            child: const AboutSettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tile hidden when flag off or not registered', (tester) async {
      await pumpAbout(tester);
      expect(find.text('Backup'), findsNothing);
      getIt.registerSingleton<ExperienceFlags>(const ExperienceFlags(_off));
      await pumpAbout(tester);
      expect(find.text('Backup'), findsNothing);
    });

    testWidgets('tile shown when flag on and opens the route', (tester) async {
      getIt.registerSingleton<ExperienceFlags>(const ExperienceFlags(_on));
      await pumpAbout(tester);
      await tester.tap(find.text('Backup'));
      await tester.pumpAndSettle();
      expect(find.text('backup-route'), findsOneWidget);
    });

    test('backupRedirect', () {
      expect(backupRedirect(const ExperienceFlags(_off)), AppRoutes.settings);
      expect(backupRedirect(null), AppRoutes.settings);
      expect(backupRedirect(const ExperienceFlags(_on)), isNull);
    });
  });
}
