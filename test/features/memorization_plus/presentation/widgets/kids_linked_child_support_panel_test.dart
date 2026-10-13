import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_learning_support_profile.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/kids_remote_reading_support_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_linked_child_support_panel.dart';

class _FakeRemote implements KidsRemoteReadingSupportRepository {
  _FakeRemote(this.server);

  KidsRemoteReadingSupport server;
  bool unavailable = false;
  final saves = <(KidsReadingAbility, int)>[];

  @override
  Future<Either<Failure, KidsRemoteReadingSupport>> load(String child) async =>
      unavailable ? const Left(NetworkFailure()) : Right(server);

  @override
  Future<Either<Failure, KidsRemoteReadingSupport>> save(
    String child,
    KidsLearningSupportProfile profile, {
    required int expectedVersion,
  }) async {
    saves.add((profile.reading, expectedVersion));
    if (expectedVersion != server.version) {
      return const Left(PolicyConflictFailure());
    }
    server = KidsRemoteReadingSupport(profile, server.version + 1);
    return Right(server);
  }
}

void main() {
  Future<void> pump(WidgetTester tester, _FakeRemote remote) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: KidsLinkedChildSupportPanel(childUserId: 'c1', remote: remote),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder chip(KidsReadingAbility r) =>
      find.byKey(ValueKey('kids-support-reading-${r.name}'));

  testWidgets('shows the child answer read from the server', (tester) async {
    await pump(
      tester,
      _FakeRemote(
        const KidsRemoteReadingSupport(
          KidsLearningSupportProfile(reading: KidsReadingAbility.withHelp),
          3,
        ),
      ),
    );

    expect(
      tester.widget<ChoiceChip>(chip(KidsReadingAbility.withHelp)).selected,
      isTrue,
    );
  });

  testWidgets('saves against the version it read', (tester) async {
    final remote = _FakeRemote(
      const KidsRemoteReadingSupport(KidsLearningSupportProfile.unknown, 0),
    );
    await pump(tester, remote);

    await tester.tap(chip(KidsReadingAbility.notYetReading));
    await tester.pumpAndSettle();

    expect(remote.saves, [(KidsReadingAbility.notYetReading, 0)]);
    expect(remote.server.version, 1);
  });

  testWidgets('a conflict says not saved, then a retry succeeds', (
    tester,
  ) async {
    final remote = _FakeRemote(
      const KidsRemoteReadingSupport(KidsLearningSupportProfile.unknown, 0),
    );
    await pump(tester, remote);
    // The child's device changed the answer meanwhile.
    remote.server = const KidsRemoteReadingSupport(
      KidsLearningSupportProfile(reading: KidsReadingAbility.independent),
      1,
    );

    await tester.tap(chip(KidsReadingAbility.withHelp));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('kids-support-save-failed')),
      findsOneWidget,
    );

    await tester.tap(chip(KidsReadingAbility.withHelp));
    await tester.pumpAndSettle();

    expect(remote.saves.map((s) => s.$2), [0, 1]);
    expect(remote.server.profile.reading, KidsReadingAbility.withHelp);
  });

  testWidgets('an unreachable server shows the setting as unavailable', (
    tester,
  ) async {
    await pump(
      tester,
      _FakeRemote(
        const KidsRemoteReadingSupport(KidsLearningSupportProfile.unknown, 0),
      )..unavailable = true,
    );

    expect(
      find.byKey(const ValueKey('kids-support-linked-unavailable')),
      findsOneWidget,
    );
    expect(chip(KidsReadingAbility.withHelp), findsNothing);
  });
}
