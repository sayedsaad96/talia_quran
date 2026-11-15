import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/share_good/application/share_good_notification_controller.dart';
import 'package:talia_quran/features/share_good/application/active_invite_sessions.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('opaque reminder resolves secure session only once', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = ShareGoodLocalStore(const FlutterSecureStorage(), prefs);
    final session = InviteSession(
      token: 'secret-token',
      serverStatus: InviteParticipationStatus.started,
      snapshot: ResolvedInvite(
        token: 'secret-token',
        target: const QuranPageInviteTarget(1),
        moment: InviteMoment.beforeActivity,
        mode: InviteMode.personal,
        inviter: const InviterIdentity(mode: InviteIdentityMode.anonymous),
        status: InviteLifecycleStatus.active,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    await store.saveSession(session);
    final saved = (await store.session(session.token))!;
    final controller = ShareGoodNotificationController(
      store: store,
      isAvailable: () => true,
      isAdult: () async => true,
      reminderEnabled: () => true,
    );
    expect(await controller.claim('sg1|${saved.localSessionId}'), saved);
    expect(await controller.claim('sg1|${saved.localSessionId}'), isNull);
    expect(await controller.claim('sg1|../secret-token'), isNull);
    expect(await controller.claim('pc1|${saved.localSessionId}'), isNull);
  });

  test('clearing the active session cancels its reminder', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = ShareGoodLocalStore(const FlutterSecureStorage(), prefs);
    final session = InviteSession(
      token: 'secret-token',
      serverStatus: InviteParticipationStatus.started,
      snapshot: ResolvedInvite(
        token: 'secret-token',
        target: const QuranPageInviteTarget(1),
        moment: InviteMoment.beforeActivity,
        mode: InviteMode.personal,
        inviter: const InviterIdentity(mode: InviteIdentityMode.anonymous),
        status: InviteLifecycleStatus.active,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    await store.saveSession(session);
    final saved = (await store.session(session.token))!;
    final sessions = ActiveInviteSessions(store);
    var scheduled = 0, cancelled = 0;
    final controller = ShareGoodNotificationController(
      store: store,
      isAvailable: () => true,
      isAdult: () async => true,
      reminderEnabled: () => true,
    );
    await controller.start(
      sessions: sessions,
      schedule: (_) async {
        scheduled++;
      },
      cancel: () async {
        cancelled++;
      },
    );
    cancelled = 0;
    sessions.activate(saved);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    sessions.clear(saved.token);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(scheduled, 1);
    expect(cancelled, 1);
    await controller.dispose();
    await sessions.dispose();
  });
}
