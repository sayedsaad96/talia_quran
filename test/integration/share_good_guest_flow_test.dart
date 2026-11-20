import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/talia_localization_delegates.dart';
import 'package:talia_quran/core/router/launch_destination.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/share_good/application/active_invite_sessions.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_remote_datasource.dart';
import 'package:talia_quran/features/share_good/data/repositories/share_good_repository_impl.dart';
import 'package:talia_quran/features/share_good/domain/services/invite_target_labeler.dart';
import 'package:talia_quran/features/share_good/presentation/cubits/invite_preview_cubit.dart';
import 'package:talia_quran/features/share_good/presentation/widgets/invite_completion_sheet.dart';
import 'package:talia_quran/features/share_good/presentation/widgets/quran_invite_completion_banner.dart';
import 'package:talia_quran/features/share_good/share_good_config.dart';

class _Quran extends Mock implements QuranRepository {}

class _GuestAuth extends Cubit<AuthState> implements AuthCubit {
  _GuestAuth() : super(const AuthUnauthenticated());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Remote extends ShareGoodRemoteDatasource {
  _Remote() : super(null);
  final statuses = <String>[];
  final operations = <String>[];
  @override
  Future<Map<String, dynamic>> call(
    String function, [
    Map<String, dynamic>? params,
  ]) async {
    operations.add(function);
    if (function == 'advance_share_good_participation_v1') {
      statuses.add(params!['p_status'] as String);
      return {'status': params['p_status']};
    }
    return {
      'target': {'v': 1, 'type': 'quran_page', 'page': 42},
      'moment': 'before',
      'mode': 'public',
      'inviter': {'mode': 'anonymous'},
      'status': 'active',
      'expires_at': DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String(),
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest opens, starts, confirms and keeps completion private', (
    tester,
  ) async {
    const token = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'isFirstTimeAppOpen': true});
    final prefs = await SharedPreferences.getInstance();
    final local = ShareGoodLocalStore(const FlutterSecureStorage(), prefs);
    final remote = _Remote();
    final repository = ShareGoodRepositoryImpl(
      remote: remote,
      local: local,
      links: const ShareGoodLinks('example.test'),
      timezone: () async => 'UTC',
    );
    final sessions = ActiveInviteSessions(local);
    final labeler = InviteTargetLabeler(_Quran());
    final preview = InvitePreviewCubit(
      repository: repository,
      labeler: labeler,
      activeSessions: sessions,
      isChild: () async => false,
      cachedSession: local.session,
    );
    final auth = _GuestAuth();
    addTearDown(() async {
      await preview.close();
      await sessions.dispose();
      await auth.close();
    });
    expect(
      LaunchDestination.resolve(isFirstTime: true, pendingInvite: token),
      '/invite/$token',
    );
    await preview.load(token);
    expect(await preview.startActivity(), '/quran/page/42');
    final id = preview.activityLaunch!.localSessionId;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: taliaLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => QuranInviteCompletionBanner(
              localSessionId: id,
              pageNumber: 42,
              confirmed: true,
              enabled: true,
              sessions: sessions,
              labeler: labeler,
              repository: repository,
              onCompleted: (session) => InviteCompletionSheet.show(
                context,
                session,
                auth: auth,
                repository: repository,
                store: local,
                barrier: AccountDataBarrier.forPreferences(prefs),
                isChild: () async => false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('I finished reading'));
    await tester.pumpAndSettle();
    expect((await local.session(token))!.awaitingConsent, isTrue);
    await tester.tap(find.text('Keep my completion private'));
    await tester.pumpAndSettle();
    expect(remote.statuses, ['opened', 'started', 'completed_private']);
    expect(
      remote.operations,
      isNot(contains('disclose_share_good_completion_v1')),
    );
    expect((await local.session(token))!.awaitingConsent, isFalse);
    expect(prefs.getBool('isFirstTimeAppOpen'), isTrue);
    expect(auth.state, isA<AuthUnauthenticated>());
  });
}
