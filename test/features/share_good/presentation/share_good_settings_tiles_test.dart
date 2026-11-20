import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/talia_localization_delegates.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/presentation/widgets/share_good_settings_tiles.dart';

class FakeAuth extends Cubit<AuthState> implements AuthCubit {
  FakeAuth(super.initialState);
  void change(AuthState next) => emit(next);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MutableOwner implements RecordOwnerProvider {
  String id = 'a';
  @override
  String get currentOwnerId => id;
  @override
  bool get isSignedIn => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late ShareGoodLocalStore store;
  late AccountDataBarrier barrier;
  late MutableOwner owner;
  late FakeAuth auth;
  late StreamController<void> audience;
  var adult = true;
  var enabled = true;
  Completer<bool>? adultCheck;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = MutableOwner();
    auth = FakeAuth(
      const AuthAuthenticated(
        user: AppUser(id: 'a', email: '', displayName: 'A'),
      ),
    );
    audience = StreamController<void>.broadcast(sync: true);
    adult = true;
    enabled = true;
    adultCheck = null;
  });
  tearDown(() async {
    await audience.close();
    await auth.close();
  });
  Future<void> pumpTile(WidgetTester tester) async {
    // The barrier's serialized queue must be created in the widget test's
    // fake-async zone so its completion is advanced by tester pumps.
    store = ShareGoodLocalStore(const FlutterSecureStorage(), prefs);
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: taliaLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShareGoodIdentitySettingsTile(
            auth: auth,
            store: store,
            barrier: barrier,
            isAvailable: () => enabled,
            isAdult: () => adultCheck?.future ?? Future.value(adult),
            audienceChanges: audience.stream,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'personal preference defaults to first name and writes for current owner',
    (tester) async {
      await pumpTile(tester);
      var dropdown = tester.widget<DropdownButton<InviteIdentityMode>>(
        find.byType(DropdownButton<InviteIdentityMode>),
      );
      expect(dropdown.value, InviteIdentityMode.firstName);
      await tester.tap(find.byType(DropdownButton<InviteIdentityMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Without a name').last);
      await tester.pumpAndSettle();
      expect(
        prefs.getString('${ShareGoodLocalStore.identityPrefix}a'),
        'anonymous',
      );
      dropdown = tester.widget<DropdownButton<InviteIdentityMode>>(
        find.byType(DropdownButton<InviteIdentityMode>),
      );
      expect(dropdown.value, InviteIdentityMode.anonymous);
      expect(prefs.getString('${ShareGoodLocalStore.identityPrefix}b'), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('hides during account change and never writes the old owner', (
    tester,
  ) async {
    await pumpTile(tester);
    owner.id = 'b';
    auth.change(
      const AuthAuthenticated(
        user: AppUser(id: 'b', email: '', displayName: 'B'),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(DropdownButton<InviteIdentityMode>), findsNothing);
    expect(prefs.getString('${ShareGoodLocalStore.identityPrefix}a'), isNull);
    expect(prefs.getString('${ShareGoodLocalStore.identityPrefix}b'), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('child and unavailable feature hide identity control', (
    tester,
  ) async {
    adult = false;
    await pumpTile(tester);
    expect(find.byType(DropdownButton<InviteIdentityMode>), findsNothing);
    adult = true;
    audience.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButton<InviteIdentityMode>), findsOneWidget);
    enabled = false;
    audience.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButton<InviteIdentityMode>), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('account change during selection prevents the pending write', (
    tester,
  ) async {
    await pumpTile(tester);
    adultCheck = Completer<bool>();
    await tester.tap(find.byType(DropdownButton<InviteIdentityMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Without a name').last);
    await tester.pump();
    auth.change(const AuthUnauthenticated());
    adultCheck!.complete(true);
    await tester.pumpAndSettle();
    expect(prefs.getString('${ShareGoodLocalStore.identityPrefix}a'), isNull);
    expect(find.byType(DropdownButton<InviteIdentityMode>), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
