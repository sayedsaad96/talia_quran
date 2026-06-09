import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
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
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.authState, required this.child});

  final AuthState authState;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => _FakeAuthCubit(authState),
      child: MaterialApp(
        locale: const Locale('en'),
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

  @override
  Future<Either<Failure, MemorizationProfile>>
  refreshChildGuardianLink() async => Right(_childProfile());

  @override
  Future<Either<Failure, PairingSession?>> refreshPairingSession() async =>
      const Right(null);

  @override
  Future<Either<Failure, PairingSession>> createGuardianPairingSession() async {
    createPairingCalls++;
    return Right(_pairingSession());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
