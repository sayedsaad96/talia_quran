import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/talia_localization_delegates.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/share_good/application/active_invite_sessions.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/domain/repositories/share_good_repository.dart';
import 'package:talia_quran/features/share_good/domain/services/invite_target_labeler.dart';
import 'package:talia_quran/features/share_good/presentation/widgets/quran_invite_completion_banner.dart';

class QuranFake extends Mock implements QuranRepository {}

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
        target: const QuranWirdInviteTarget(10, 12),
        moment: InviteMoment.beforeActivity,
        mode: InviteMode.personal,
        inviter: const InviterIdentity(mode: InviteIdentityMode.anonymous),
        status: InviteLifecycleStatus.active,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    sessions.activate(session);
  });
  tearDown(() async => sessions.dispose());
  Future<void> show(
    WidgetTester tester, {
    int page = 12,
    bool confirmed = true,
    bool enabled = true,
    String id = 'local',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: taliaLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: QuranInviteCompletionBanner(
            localSessionId: id,
            pageNumber: page,
            confirmed: confirmed,
            enabled: enabled,
            sessions: sessions,
            labeler: InviteTargetLabeler(QuranFake()),
            repository: repo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows only the matching range and requires successful end confirmation',
    (tester) async {
      await show(tester, id: 'missing');
      expect(find.text('I finished reading'), findsNothing);
      await show(tester, page: 10);
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );
      await show(tester, confirmed: false);
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );
      await show(tester, enabled: false);
      expect(find.text('I finished reading'), findsNothing);
    },
  );
  testWidgets('submits once and hides after confirmed completion', (
    tester,
  ) async {
    final pending = Completer<Either<ShareGoodFailure, InviteSession>>();
    when(
      () => repo.advance('token', InviteParticipationStatus.completedPrivate),
    ).thenAnswer((_) => pending.future);
    await show(tester);
    await tester.tap(find.text('I finished reading'));
    await tester.pump();
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    pending.complete(
      Right(
        InviteSession(
          token: 'token',
          snapshot: session.snapshot,
          pendingStatus: InviteParticipationStatus.completedPrivate,
        ),
      ),
    );
    await tester.pumpAndSettle();
    verify(
      () => repo.advance('token', InviteParticipationStatus.completedPrivate),
    ).called(1);
    expect(find.text('I finished reading'), findsNothing);
  });
  testWidgets('expired and failed submissions show recoverable feedback', (
    tester,
  ) async {
    when(
      () => repo.advance('token', InviteParticipationStatus.completedPrivate),
    ).thenAnswer((_) async => const Left(ShareGoodFailure.network));
    await show(tester);
    await tester.tap(find.text('I finished reading'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not record completion. Please try again.'),
      findsOneWidget,
    );
    when(
      () => repo.advance('token', InviteParticipationStatus.completedPrivate),
    ).thenAnswer((_) async => const Left(ShareGoodFailure.expired));
    await tester.tap(find.text('I finished reading'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'You can start reading for yourself; it will not count towards this invitation.',
      ),
      findsOneWidget,
    );
    expect(find.text('I finished reading'), findsNothing);
  });
}
