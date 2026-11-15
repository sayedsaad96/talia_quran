import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/domain/repositories/share_good_repository.dart';
import 'package:talia_quran/features/share_good/presentation/widgets/invite_completion_sheet.dart';

class MockAuth extends Mock implements AuthCubit {}

class FakeRepository implements ShareGoodRepository {
  FakeRepository(this.session);
  final InviteSession session;
  final names = <String>[];
  @override
  Future<Either<ShareGoodFailure, InviteSession>> disclose(
    String token,
    String name,
  ) async {
    names.add(name);
    return Right(session);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const token = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  final session = InviteSession(
    token: token,
    snapshot: ResolvedInvite(
      token: token,
      target: const QuranPageInviteTarget(1),
      moment: InviteMoment.beforeActivity,
      mode: InviteMode.public,
      inviter: const InviterIdentity(mode: InviteIdentityMode.anonymous),
      status: InviteLifecycleStatus.active,
      expiresAt: DateTime.utc(2099),
    ),
    serverStatus: InviteParticipationStatus.completedPrivate,
  );
  late ShareGoodLocalStore store;
  late AccountDataBarrier barrier;
  late FakeRepository repo;
  late MockAuth auth;
  late StreamController<AuthState> changes;
  AuthState state = const AuthUnauthenticated();
  var signIns = 0;
  final chainSessions = <InviteSession>[];
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    barrier = AccountDataBarrier.forPreferences(prefs)
      ..owner = const FixedRecordOwnerProvider('b');
    store = ShareGoodLocalStore(const FlutterSecureStorage(), prefs);

    repo = FakeRepository(session);
    auth = MockAuth();
    changes = StreamController<AuthState>.broadcast();
    state = const AuthUnauthenticated();
    signIns = 0;
    chainSessions.clear();
    when(() => auth.state).thenAnswer((_) => state);
    when(() => auth.stream).thenAnswer((_) => changes.stream);
  });
  tearDown(() async => changes.close());
  Future<void> open(
    WidgetTester tester, {
    Future<bool> Function()? isChild,
  }) async {
    store = ShareGoodLocalStore(
      const FlutterSecureStorage(),
      await SharedPreferences.getInstance(),
    );
    await store.saveSession(session);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => InviteCompletionSheet.show(
                context,
                session,
                auth: auth,
                repository: repo,
                store: store,
                barrier: barrier,
                isChild: isChild ?? () async => false,
                signIn: (_) async {
                  signIns++;
                },
                openChain: (_, session) async => chainSessions.add(session),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('private clears consent without disclosure', (tester) async {
    await open(tester);
    expect((await store.session(token))!.awaitingConsent, isTrue);
    await tester.tap(find.text('Keep my completion private'));
    await tester.pumpAndSettle();
    expect(repo.names, isEmpty);
    expect((await store.session(token))!.awaitingConsent, isFalse);
  });
  testWidgets('chain sign in returns to consent without disclosing', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Continue the chain'));
    await tester.pumpAndSettle();
    expect(signIns, 1);
    expect(chainSessions, isEmpty);
    expect(find.text('Keep my completion private'), findsOneWidget);
    state = const AuthAuthenticated(
      user: AppUser(id: 'b', email: '', displayName: 'Current Name'),
    );
    changes.add(state);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue the chain'));
    await tester.pumpAndSettle();
    expect(chainSessions, [session]);
    expect(repo.names, isEmpty);
    expect(find.text('Keep my completion private'), findsOneWidget);
  });
  testWidgets(
    'sign in returns to sheet and current account requires explicit disclosure',
    (tester) async {
      await open(tester);
      await tester.tap(find.text('Tell them I completed it'));
      await tester.pumpAndSettle();
      expect(signIns, 1);
      expect(repo.names, isEmpty);
      state = const AuthAuthenticated(
        user: AppUser(id: 'b', email: '', displayName: 'Current Name'),
      );
      changes.add(state);
      await tester.pumpAndSettle();
      expect(repo.names, isEmpty);
      expect(find.textContaining('Current Name'), findsOneWidget);
      await tester.tap(find.text('Tell them I completed it'));
      await tester.pumpAndSettle();
      expect(repo.names, ['Current Name']);
      expect((await store.session(token))!.awaitingConsent, isFalse);
    },
  );
  testWidgets('dismissal keeps completion private; child cannot open', (
    tester,
  ) async {
    await open(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect((await store.session(token))!.awaitingConsent, isFalse);
    expect(repo.names, isEmpty);
    await open(tester, isChild: () async => true);
    expect(find.text('Keep my completion private'), findsNothing);
  });
}
