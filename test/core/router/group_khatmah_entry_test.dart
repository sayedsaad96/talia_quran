import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/group_khatmah_entry.dart';
import '../../features/group_khatmah/data/group_khatmah_test_support.dart';

void main() {
  tearDown(() => getIt.reset());
  testWidgets('entry is absent without feature registrations', (tester) async {
    await tester.pumpWidget(_app(const GroupKhatmahEntry()));
    expect(find.byType(IconButton), findsNothing);
  });
  testWidgets('entry requires enabled flag, adult and signed-in owner', (
    tester,
  ) async {
    final environment = MutableEnvironment();
    addTearDown(environment.dispose);
    var opened = 0;
    final owner = MutableOwner(ownerA);
    await tester.pumpWidget(
      _app(
        GroupKhatmahEntry(
          environment: environment,
          owner: owner,
          onOpen: () => opened++,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('group-khatmah-entry')));
    expect(opened, 1);
    environment.setFeatureEnabled(false);
    await tester.pump();
    expect(find.byKey(const Key('group-khatmah-entry')), findsNothing);
    environment.setFeatureEnabled(true);
    environment.setAdult(false);
    await tester.pump();
    expect(find.byKey(const Key('group-khatmah-entry')), findsNothing);
    environment.setAdult(true);
    owner.currentOwnerId = '';
    environment.setAdult(true);
    await tester.pump();
    expect(find.byKey(const Key('group-khatmah-entry')), findsNothing);
  });
}

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(appBar: AppBar(actions: [child])),
);
