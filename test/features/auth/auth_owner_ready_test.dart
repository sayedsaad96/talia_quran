import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/auth/presentation/pages/login_page.dart';
import 'package:talia_quran/features/settings/presentation/cubits/profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';

class _Auth extends Mock implements AuthRepository {}

class _Reset extends Mock implements AccountDataReset {}

class _MarkerStore extends InMemorySharedPreferencesStore {
  _MarkerStore(super.data) : super.withData();
  bool reject = true;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (reject && key.endsWith(AuthCubit.lastSignedInUserIdKey)) return false;
    return super.setValue(valueType, key, value);
  }
}

class _Owner implements RecordOwnerProvider {
  _Owner(this.currentOwnerId);
  @override
  String currentOwnerId;
  @override
  bool get isSignedIn => currentOwnerId != 'local';
}

void main() {
  testWidgets(
    'actual login cleanup failure stays on login and retry routes only after ready',
    (tester) async {
      await getIt.reset();
      SharedPreferences.setMockInitialValues({
        AuthCubit.lastSignedInUserIdKey: 'a',
        'khatmah_active_plan': 'private-a',
      });
      final prefs = await SharedPreferences.getInstance();
      getIt.registerSingleton<SharedPreferences>(prefs);
      final auth = _Auth();
      final reset = _Reset();
      final owner = _Owner('local');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      const b = AppUser(id: 'b', email: 'b@test.invalid', displayName: 'B');
      AppUser? current;
      var fail = true;
      when(() => auth.currentUser).thenAnswer((_) => current);
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.pullProgressFromCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => auth.syncProgressToCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => auth.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        current = b;
        owner.currentOwnerId = 'b';
        return const Right(b);
      });
      when(() => reset.clearAccountOwnedData(departingOwnerId: 'a')).thenAnswer(
        (_) => barrier.clear(() async {
          if (fail) throw const AccountDataResetException('denied');
          await prefs.remove('khatmah_active_plan');
        }),
      );
      final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
      final profile = ProfileCubit(prefs)..loadProfile();
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('ready home')),
          ),
        ],
      );
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: cubit),
            BlocProvider<ProfileCubit>.value(value: profile),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'b@test.invalid',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      final submit = find.byType(FilledButton).last;
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ready home'), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(barrier.isReady, isFalse);
      final l10n = AppLocalizations.of(tester.element(find.byType(LoginPage)));
      expect(find.text(l10n.authGenericError), findsOneWidget);
      fail = false;
      await tester.tap(find.text(l10n.retrySyncAfterError));
      await tester.pumpAndSettle();
      expect(find.text('ready home'), findsOneWidget);
      expect(prefs.getString('khatmah_active_plan'), isNull);
      expect(barrier.isReady, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await cubit.close();
      await profile.close();
      await getIt.reset();
    },
  );
  test(
    'marker rejection after successful clear stays gated and retry opens owner',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = _MarkerStore({
        'flutter.auth_last_signed_in_user_id': 'a',
        'flutter.khatmah_active_plan': 'private-a',
        'flutter.khatmah_owner': 'a',
      });
      SharedPreferencesStorePlatform.instance = store;
      final prefs = await SharedPreferences.getInstance();
      final owner = _Owner('b');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final auth = _Auth();
      final reset = _Reset();
      const user = AppUser(id: 'b', email: 'b@test.invalid', displayName: 'B');
      when(() => auth.currentUser).thenReturn(user);
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.pullProgressFromCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => auth.syncProgressToCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(() => reset.clearAccountOwnedData(departingOwnerId: 'a')).thenAnswer(
        (_) => barrier.clear(() async {
          await prefs.remove('khatmah_active_plan');
          await prefs.remove('khatmah_owner');
        }),
      );
      final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
      await expectLater(
        cubit.ensureCloudSyncComplete(),
        throwsA(isA<AccountDataResetException>()),
      );
      expect(prefs.getString('khatmah_active_plan'), isNull);
      expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'a');
      expect(cubit.state, isA<AuthOwnerDataFailure>());
      expect(barrier.isReady, isFalse);
      store.reject = false;
      await cubit.ensureCloudSyncComplete();
      expect(cubit.state, isA<AuthAuthenticated>());
      expect(barrier.isReady, isTrue);
      expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'b');
      await cubit.close();
    },
  );
  test(
    'same-owner cached startup preserves existing local authority offline',
    () async {
      SharedPreferences.setMockInitialValues({
        AuthCubit.lastSignedInUserIdKey: 'a',
        'khatmah_active_plan': 'private-a',
        'khatmah_owner': 'a',
      });
      final prefs = await SharedPreferences.getInstance();
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = _Owner('a');
      final lease = barrier.capture();
      final auth = _Auth();
      final reset = _Reset();
      const user = AppUser(id: 'a', email: 'a@test.invalid', displayName: 'A');
      when(() => auth.currentUser).thenReturn(user);
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.pullProgressFromCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => auth.syncProgressToCloud(),
      ).thenAnswer((_) async => const Right(unit));
      final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
      await cubit.ensureCloudSyncComplete();
      expect(lease.check, returnsNormally);
      expect(prefs.getString('khatmah_active_plan'), 'private-a');
      expect(cubit.state, isA<AuthAuthenticated>());
      await cubit.close();
    },
  );
  for (final rejectC in [false, true]) {
    test(
      'rapid A B C preserves current failure=$rejectC and retry remains usable',
      () async {
        SharedPreferences.setMockInitialValues({
          AuthCubit.lastSignedInUserIdKey: 'a',
          'khatmah_active_plan': 'private-a',
          'khatmah_owner': 'a',
        });
        final prefs = await SharedPreferences.getInstance();
        final owner = _Owner('a');
        final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
        final auth = _Auth();
        final reset = _Reset();
        const a = AppUser(id: 'a', email: 'a@test.invalid', displayName: 'A');
        const b = AppUser(id: 'b', email: 'b@test.invalid', displayName: 'B');
        const c = AppUser(id: 'c', email: 'c@test.invalid', displayName: 'C');
        AppUser current = a;
        final events = StreamController<AppUser?>.broadcast();
        final started = Completer<void>();
        final release = Completer<void>();
        var clearCalls = 0;
        var failCurrent = rejectC;
        when(() => auth.currentUser).thenAnswer((_) => current);
        when(() => auth.authStateChanges).thenAnswer((_) => events.stream);
        when(
          () => auth.passwordRecoveryChanges,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => auth.pullProgressFromCloud(),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => auth.syncProgressToCloud(),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => reset.clearAccountOwnedData(
            departingOwnerId: any(named: 'departingOwnerId'),
          ),
        ).thenAnswer((_) async {
          clearCalls++;
          if (!started.isCompleted) started.complete();
          await release.future;
          await barrier.clear(() async {
            if (clearCalls > 1 && failCurrent) {
              throw const AccountDataResetException('current C denied');
            }
            await prefs.remove('khatmah_active_plan');
          });
        });
        final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
        await cubit.ensureCloudSyncComplete();
        final states = <AuthState>[];
        final sub = cubit.stream.listen(states.add);
        current = b;
        owner.currentOwnerId = 'b';
        events.add(b);
        await started.future;
        current = c;
        owner.currentOwnerId = 'c';
        events.add(c);
        await Future<void>.delayed(Duration.zero);
        release.complete();
        if (rejectC) {
          await expectLater(
            cubit.ensureCloudSyncComplete(),
            throwsA(isA<AccountDataResetException>()),
          );
          expect(cubit.state, isA<AuthOwnerDataFailure>());
          expect(barrier.isReady, isFalse);
          expect(
            states.whereType<AuthAuthenticated>().any((s) => s.user.id == 'c'),
            isFalse,
          );
          failCurrent = false;
        }
        await cubit.ensureCloudSyncComplete();
        expect(
          states.whereType<AuthAuthenticated>().any((s) => s.user.id == 'b'),
          isFalse,
        );
        expect((cubit.state as AuthAuthenticated).user.id, 'c');
        expect(barrier.isReady, isTrue);
        expect(prefs.getString('khatmah_active_plan'), isNull);
        await sub.cancel();
        await cubit.close();
        await events.close();
      },
    );
  }
  for (final marker in [null, 'a']) {
    test(
      'guest to owner with previous marker=$marker opens local data after readiness',
      () async {
        SharedPreferences.setMockInitialValues({
          AuthCubit.lastSignedInUserIdKey: ?marker,
        });
        final prefs = await SharedPreferences.getInstance();
        final owner = _Owner('local');
        final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
        // A normal logout has already cleared all Khatmah data.
        await barrier.clear(() async {});
        final auth = _Auth();
        final reset = _Reset();
        const user = AppUser(
          id: 'a',
          email: 'a@test.invalid',
          displayName: 'A',
        );
        when(() => auth.currentUser).thenReturn(user);
        when(
          () => auth.authStateChanges,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => auth.passwordRecoveryChanges,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => auth.pullProgressFromCloud(),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => auth.syncProgressToCloud(),
        ).thenAnswer((_) async => const Right(unit));
        owner.currentOwnerId = 'a';
        final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
        addTearDown(cubit.close);
        await cubit.ensureCloudSyncComplete();
        expect(cubit.state, isA<AuthAuthenticated>());
        await expectLater(barrier.run((_) async => true), completion(isTrue));
      },
    );
  }
  for (final cached in [true, false]) {
    test(
      'owner readiness cached=$cached waits for cleanup and propagates failure',
      () async {
        SharedPreferences.setMockInitialValues({
          AuthCubit.lastSignedInUserIdKey: 'a',
          'khatmah_active_plan': 'private-a',
        });
        final prefs = await SharedPreferences.getInstance();
        final auth = _Auth();
        final reset = _Reset();
        const user = AppUser(
          id: 'b',
          email: 'b@test.invalid',
          displayName: 'B',
        );
        AppUser? current = cached ? user : null;
        final events = StreamController<AppUser?>.broadcast();
        final cleanup = Completer<void>();
        unawaited(
          cleanup.future.then<void>(
            (_) {},
            onError: (Object _, StackTrace _) {},
          ),
        );
        when(() => auth.currentUser).thenAnswer((_) => current);
        when(() => auth.authStateChanges).thenAnswer((_) => events.stream);
        when(
          () => auth.passwordRecoveryChanges,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => auth.pullProgressFromCloud(),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => auth.syncProgressToCloud(),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => reset.clearAccountOwnedData(departingOwnerId: 'a'),
        ).thenAnswer((_) => cleanup.future);
        final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
        addTearDown(() async {
          await cubit.close();
          await events.close();
        });
        if (!cached) {
          current = user;
          events.add(user);
          await Future<void>.delayed(Duration.zero);
        }
        final prematurelyReady = cubit.state is AuthAuthenticated;
        final completion = cubit.ensureCloudSyncComplete().then<Object?>(
          (_) => null,
          onError: (Object e) => e,
        );
        cleanup.completeError(const AccountDataResetException('denied'));
        final error = await completion;
        expect(prematurelyReady, isFalse);
        expect(error, isA<AccountDataResetException>());
        expect(cubit.state, isNot(isA<AuthAuthenticated>()));
        expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'a');
      },
    );
  }
}
