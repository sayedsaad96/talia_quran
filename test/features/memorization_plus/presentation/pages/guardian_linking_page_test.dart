import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/guardian_linking_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/guardian_linking_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('guest child sees sign-in-required message and no QR action', (
    tester,
  ) async {
    final repository = _GuardianLinkingRepository();
    getIt.registerFactory<GuardianLinkingCubit>(
      () => GuardianLinkingCubit(repository),
    );

    await tester.pumpWidget(
      const _TestApp(
        authState: AuthUnauthenticated(),
        child: GuardianLinkingPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Sign in to access guardian tools. Your local progress remains on this device.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sign in or create account'), findsOneWidget);
    expect(find.text('Continue Kids memorization'), findsOneWidget);
    expect(find.textContaining('cloud', findRichText: true), findsNothing);
    expect(find.textContaining('sync', findRichText: true), findsNothing);
    expect(find.textContaining('backup', findRichText: true), findsNothing);
    expect(find.text('Link guardian now'), findsNothing);
    expect(repository.createPairingCalls, 0);
  });

  testWidgets('signed-in child can still create guardian pairing code', (
    tester,
  ) async {
    final repository = _GuardianLinkingRepository();
    getIt.registerFactory<GuardianLinkingCubit>(
      () => GuardianLinkingCubit(repository),
    );

    await tester.pumpWidget(
      const _TestApp(
        authState: AuthAuthenticated(
          user: AppUser(
            id: 'child-user',
            email: 'child@example.com',
            displayName: 'Child',
          ),
        ),
        child: GuardianLinkingPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Link guardian now'), findsOneWidget);

    await tester.tap(find.text('Link guardian now'));
    await tester.pumpAndSettle();

    expect(repository.createPairingCalls, 1);
    expect(find.text('ABCDEF'), findsOneWidget);
  });

  testWidgets('a blocked pairing explains the reason in the UI language', (
    tester,
  ) async {
    final repository = _GuardianLinkingRepository()
      ..createPairingResult = const Left(
        NetworkFailure(CubitMessageCodes.guardianCloudUnavailable),
      );
    getIt.registerFactory<GuardianLinkingCubit>(
      () => GuardianLinkingCubit(repository),
    );

    await tester.pumpWidget(
      const _TestApp(
        authState: AuthAuthenticated(
          user: AppUser(
            id: 'child-user',
            email: 'child@example.com',
            displayName: 'Child',
          ),
        ),
        child: GuardianLinkingPage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Link guardian now'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Linking children isn't available in this version because cloud "
        'sync is not enabled.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('@guardian'), findsNothing);
  });

  testWidgets('"continue" points forward in Arabic (K22)', (tester) async {
    getIt.registerFactory<GuardianLinkingCubit>(
      () => GuardianLinkingCubit(_GuardianLinkingRepository()),
    );

    await tester.pumpWidget(
      const _TestApp(
        authState: AuthUnauthenticated(),
        locale: Locale('ar'),
        child: GuardianLinkingPage(),
      ),
    );
    await tester.pumpAndSettle();

    // arrow_forward mirrors itself under RTL (points left); a hand-picked
    // arrow_back pointed the child backwards.
    expect(find.byIcon(Icons.arrow_forward_rounded), findsWidgets);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.authState,
    required this.child,
    this.locale = const Locale('en'),
  });

  final AuthState authState;
  final Widget child;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => _FakeAuthCubit(authState),
      child: MaterialApp(
        locale: locale,
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }
}

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GuardianLinkingRepository implements MemorizationPlusRepository {
  int createPairingCalls = 0;
  Either<Failure, PairingSession>? createPairingResult;

  @override
  Future<Either<Failure, MemorizationProfile>>
  refreshChildGuardianLink() async => Right(_childProfile());

  @override
  Future<Either<Failure, PairingSession?>> refreshPairingSession() async =>
      const Right(null);

  @override
  Future<Either<Failure, PairingSession>> createGuardianPairingSession() async {
    createPairingCalls++;
    return createPairingResult ?? Right(_pairingSession());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> hasPendingCloudWork() async => false;
}

MemorizationProfile _childProfile() {
  final now = DateTime.utc(2026, 1, 1);
  return MemorizationProfile(
    schemaVersion: 1,
    selectedPath: MemorizationPath.child,
    guardianLinkStatus: GuardianLinkStatus.none,
    guardianOnboardingStatus: GuardianOnboardingStatus.required,
    isParentGuardian: false,
    createdAt: now,
    updatedAt: now,
  );
}

PairingSession _pairingSession() {
  final now = DateTime.utc(2026, 1, 1, 12);
  return PairingSession(
    id: 'session-1',
    pairingCode: 'ABCDEF',
    qrData: 'talia-kids-link:ABCDEF',
    createdAt: now,
    expiresAt: now.add(const Duration(minutes: 10)),
    status: PairingSessionStatus.pending,
    isUsed: false,
  );
}
