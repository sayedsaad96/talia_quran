import 'package:dartz/dartz.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/talia_localization_delegates.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/share_good/application/active_invite_sessions.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/domain/repositories/share_good_repository.dart';
import 'package:talia_quran/features/share_good/presentation/widgets/azkar_invite_completion.dart';

class ShareFake extends Mock implements ShareGoodRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ActiveInviteSessions sessions;
  late ShareFake repo;
  late InviteSession session;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    sessions = ActiveInviteSessions(
      ShareGoodLocalStore(
        const FlutterSecureStorage(),
        await SharedPreferences.getInstance(),
      ),
    );
    repo = ShareFake();
    session = InviteSession(
      token: 'token',
      localSessionId: 'local',
      serverStatus: InviteParticipationStatus.started,
      snapshot: ResolvedInvite(
        token: 'token',
        target: const AzkarCollectionInviteTarget(AzkarCategory.morning),
        moment: InviteMoment.beforeActivity,
        mode: InviteMode.personal,
        inviter: const InviterIdentity(mode: InviteIdentityMode.anonymous),
        status: InviteLifecycleStatus.active,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    sessions.activate(session);
    when(
      () => repo.advance('token', InviteParticipationStatus.completedPrivate),
    ).thenAnswer(
      (_) async => Right(
        InviteSession(
          token: 'token',
          snapshot: session.snapshot,
          pendingStatus: InviteParticipationStatus.completedPrivate,
        ),
      ),
    );
  });
  tearDown(() async => sessions.dispose());
  Future<void> show(
    WidgetTester tester,
    bool? done, {
    AzkarCategory category = AzkarCategory.morning,
    String id = 'local',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: taliaLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: AzkarInviteCompletion(
            localSessionId: id,
            category: category,
            allDone: done,
            enabled: true,
            sessions: sessions,
            repository: repo,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('fresh transition reports once', (tester) async {
    await show(tester, false);
    await show(tester, true);
    await tester.pump();
    await show(tester, true);
    verify(
      () => repo.advance('token', InviteParticipationStatus.completedPrivate),
    ).called(1);
  });
  testWidgets('already completed requires confirmation', (tester) async {
    await show(tester, true);
    verifyNever(
      () => repo.advance('token', InviteParticipationStatus.completedPrivate),
    );
    expect(find.text('I completed these today'), findsOneWidget);
    await tester.tap(find.text('Confirm completion'));
    await tester.pump();
    verify(
      () => repo.advance('token', InviteParticipationStatus.completedPrivate),
    ).called(1);
  });
  testWidgets('general, duas and mismatched sessions cannot report', (
    tester,
  ) async {
    for (final category in [
      AzkarCategory.general,
      AzkarCategory.duas,
      AzkarCategory.evening,
    ]) {
      await show(tester, false, category: category);
      await show(tester, true, category: category);
      expect(find.text('Confirm completion'), findsNothing);
    }
    verifyNever(
      () => repo.advance('token', InviteParticipationStatus.completedPrivate),
    );
  });
}
