import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/talia_localization_delegates.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/domain/repositories/share_good_repository.dart';
import 'package:talia_quran/features/share_good/domain/services/invite_target_labeler.dart';
import 'package:talia_quran/features/share_good/presentation/cubits/invite_create_cubit.dart';
import 'package:talia_quran/features/share_good/presentation/widgets/invite_mode_sheet.dart';

class MockAuth extends Mock implements AuthCubit {}

class FakeCreatedCubit extends Cubit<InviteCreateState>
    implements InviteCreateCubit {
  FakeCreatedCubit(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuran implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRepository implements ShareGoodRepository {
  final contexts = <InviteContext>[];
  final parents = <String>[];
  bool expiredParent = false;
  int disclosures = 0;
  @override
  Future<Either<ShareGoodFailure, CreatedInvite>> continueChain(
    String parentToken,
    InviteContext ctx,
  ) async {
    parents.add(parentToken);
    if (expiredParent) return const Left(ShareGoodFailure.expired);
    return create(ctx);
  }

  @override
  Future<Either<ShareGoodFailure, InviteSession>> disclose(
    String token,
    String name,
  ) async {
    disclosures++;
    return const Left(ShareGoodFailure.invalidInvite);
  }

  @override
  Future<Either<ShareGoodFailure, CreatedInvite>> create(
    InviteContext ctx,
  ) async {
    contexts.add(ctx);
    return Right(
      CreatedInvite(
        token: 'token',
        shareUrl: Uri.https('example.com', '/i/token'),
        context: ctx,
        createdAt: DateTime.utc(2026),
        expiresAt: DateTime.utc(2027),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ShareGoodLocalStore store;
  late FakeRepository repo;
  late MockAuth auth;
  late AccountDataBarrier barrier;
  late InviteCreateCubit cubit;
  bool child = false;
  AuthState authState = const AuthUnauthenticated();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = ShareGoodLocalStore(const FlutterSecureStorage(), prefs);
    barrier = AccountDataBarrier.forPreferences(prefs)
      ..owner = const FixedRecordOwnerProvider('owner');
    repo = FakeRepository();
    auth = MockAuth();
    authState = const AuthAuthenticated(
      user: AppUser(id: 'owner', email: '', displayName: 'Example Person'),
    );
    child = false;
    when(() => auth.state).thenAnswer((_) => authState);
    cubit = InviteCreateCubit(
      target: const QuranPageInviteTarget(1),
      moment: InviteMoment.beforeActivity,
      repository: repo,
      store: store,
      labeler: InviteTargetLabeler(FakeQuran()),
      auth: auth,
      barrier: barrier,
      isChild: () async => child,
      isAvailable: () => true,
      arabic: false,
      makeShareData: (_, _) => const SocialShareData(
        content: '',
        category: SocialShareCategory.achievement,
      ),
    );
  });
  tearDown(() => cubit.close());
  test(
    'mode is required; personal uses saved preference and public defaults anonymous',
    () async {
      await store.setPersonalIdentityPreference(
        'owner',
        InviteIdentityMode.fullName,
      );
      await cubit.begin();
      await cubit.create();
      expect(repo.contexts, isEmpty);
      cubit.chooseMode(InviteMode.personal);
      expect(
        (cubit.state as InviteCreateChoosingMode).identity,
        InviteIdentityMode.fullName,
      );
      cubit.chooseMode(InviteMode.public);
      expect(
        (cubit.state as InviteCreateChoosingMode).identity,
        InviteIdentityMode.anonymous,
      );
      await cubit.create();
      expect(repo.contexts.single.identity.mode, InviteIdentityMode.anonymous);
      expect(cubit.state, isA<InviteCreateCreated>());
    },
  );
  test('guest and child cannot create', () async {
    authState = const AuthUnauthenticated();
    await cubit.begin();
    expect(cubit.state, isA<InviteCreateNeedsSignIn>());
    child = true;
    await cubit.begin();
    expect(cubit.state, isA<InviteCreateFailed>());
    expect(repo.contexts, isEmpty);
  });
  test('chain asks for sign in and retains parent on return', () async {
    authState = const AuthUnauthenticated();
    await cubit.startChain('parent');
    expect(cubit.state, isA<InviteCreateNeedsSignIn>());
    authState = const AuthAuthenticated(
      user: AppUser(id: 'owner', email: '', displayName: 'Example Person'),
    );
    await cubit.begin();
    cubit.chooseMode(InviteMode.public);
    await cubit.create();
    expect(repo.parents, ['parent']);
    expect(repo.contexts.single.target, const QuranPageInviteTarget(1));
    expect(repo.contexts.single.moment, InviteMoment.afterActivity);
    expect(repo.disclosures, 0);
  });
  test('expired chain allows explicit standalone creation', () async {
    repo.expiredParent = true;
    await cubit.startChain('parent');
    cubit.chooseMode(InviteMode.public);
    await cubit.create();
    expect(cubit.state, isA<InviteCreateParentExpired>());
    expect(repo.contexts, isEmpty);
    await cubit.startStandalone();
    cubit.chooseMode(InviteMode.public);
    await cubit.create();
    expect(repo.parents, ['parent']);
    expect(repo.contexts.single.moment, InviteMoment.afterActivity);
    expect(cubit.state, isA<InviteCreateCreated>());
  });
  testWidgets('expired parent offers a new standalone invitation', (
    tester,
  ) async {
    repo.expiredParent = true;
    await cubit.startChain('parent');
    cubit.chooseMode(InviteMode.public);
    await cubit.create();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: taliaLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: InviteModeSheet(cubit: cubit)),
      ),
    );
    expect(
      find.textContaining('original invitation has expired'),
      findsOneWidget,
    );
    await tester.tap(find.text('Create a new invitation'));
    await tester.pump();
    expect(cubit.state, isA<InviteCreateChoosingMode>());
  });
  test('account change between selection and creation does not send', () async {
    await cubit.begin();
    cubit.chooseMode(InviteMode.personal);
    authState = const AuthAuthenticated(
      user: AppUser(id: 'other', email: '', displayName: 'Other'),
    );
    await cubit.create();
    expect(repo.contexts, isEmpty);
  });
  testWidgets('create button remains disabled until a mode is selected', (
    tester,
  ) async {
    await cubit.begin();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: taliaLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: InviteModeSheet(cubit: cubit)),
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(repo.contexts, isEmpty);
  });
  testWidgets('warns when an invitation expires in 50 minutes', (tester) async {
    final now = DateTime(2026, 1, 1, 14, 40);
    const target = QuranPageInviteTarget(1);
    final invite = CreatedInvite(
      token: 'token',
      shareUrl: Uri.https('example.com', '/i/token'),
      context: const InviteContext(
        target: target,
        moment: InviteMoment.beforeActivity,
        mode: InviteMode.public,
        identity: InviterIdentity(mode: InviteIdentityMode.anonymous),
      ),
      createdAt: now,
      expiresAt: DateTime(2026, 1, 1, 15, 30),
    );
    final created = FakeCreatedCubit(
      InviteCreateCreated(
        invite,
        const SocialShareData(
          content: '',
          category: SocialShareCategory.achievement,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: taliaLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InviteModeSheet(cubit: created, clock: () => now),
        ),
      ),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(InviteModeSheet)),
    );
    expect(find.text(l10n.inviteExpirySoon(50)), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await created.close();
  });
}
