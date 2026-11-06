import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/share_good/application/incoming_invite_link_service.dart';
import 'package:talia_quran/features/share_good/application/install_referrer_channel.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/share_good_config.dart';

class FakeLinks implements AppLinks {
  final controller = StreamController<String>.broadcast(sync: true);
  Future<String?> initial = Future.value(null);
  @override
  Future<String?> getInitialLinkString() => initial;
  @override
  Stream<String> get stringLinkStream => controller.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeReferrer extends InstallReferrerChannel {
  String? value;
  int calls = 0;
  @override
  Future<String?> readOnce() async {
    calls++;
    return value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const a = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const b = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  late FakeLinks appLinks;
  late FakeReferrer referrer;
  late ShareGoodLocalStore store;
  late SharedPreferences prefs;
  late IncomingInviteLinkService service;
  var enabled = true;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = ShareGoodLocalStore(const FlutterSecureStorage(), prefs);
    appLinks = FakeLinks();
    referrer = FakeReferrer();
    enabled = true;
    service = IncomingInviteLinkService(
      appLinks: appLinks,
      referrer: referrer,
      store: store,
      preferences: prefs,
      links: const ShareGoodLinks('example.com'),
      isEnabled: () => enabled,
      isAndroid: true,
    );
  });
  tearDown(() async {
    await service.dispose();
    await appLinks.controller.close();
  });

  test('initial link is persisted until preview acknowledges it', () async {
    appLinks.initial = Future.value('https://example.com/i/$a');
    expect(await service.initialToken(), a);
    expect(await store.pendingIncomingToken(), a);
    expect(await store.acknowledgePendingIncomingToken(b), isFalse);
    expect(await store.acknowledgePendingIncomingToken(a), isTrue);
  });
  test(
    'warm link beats a slower initial link and duplicate is delivered once',
    () async {
      final initial = Completer<String?>();
      appLinks.initial = initial.future;
      final found = <String>[];
      final sub = service.tokens.listen(found.add);
      final start = service.initialToken();
      appLinks.controller.add('https://example.com/i/$b');
      appLinks.controller.add('https://example.com/i/$b');
      initial.complete('https://example.com/i/$a');
      expect(await start, b);
      await Future<void>.delayed(Duration.zero);
      expect(found, [b]);
      expect(await store.pendingIncomingToken(), b);
      await sub.cancel();
    },
  );
  test('referrer is checked once and rejects marketing data', () async {
    referrer.value = 'utm_source=tc';
    expect(await service.initialToken(), isNull);
    expect(await service.initialToken(), isNull);
    expect(referrer.calls, 1);
    expect(prefs.getBool('share_good_referrer_checked'), isTrue);
  });
  test(
    'an unacknowledged invite survives a restart ahead of the referrer',
    () async {
      await store.setPendingIncomingToken(a);
      referrer.value = 'inv=$b';
      expect(await service.initialToken(), a);
      expect(await store.pendingIncomingToken(), a);
      expect(referrer.calls, 0);
    },
  );
  test(
    'disabled links do not persist and malformed raw links are rejected',
    () async {
      enabled = false;
      appLinks.controller.add('https://example.com/i/$a');
      enabled = true;
      appLinks.controller.add('https://example.com:443/i/$a');
      await Future<void>.delayed(Duration.zero);
      expect(await store.pendingIncomingToken(), isNull);
    },
  );
}
