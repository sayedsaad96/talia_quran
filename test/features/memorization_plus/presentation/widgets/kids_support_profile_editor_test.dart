import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_learning_support_profile.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/kids_support_profile_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_support_profile_editor.dart';

class _FakeRepo implements KidsSupportProfileRepository {
  _FakeRepo([this.profile = KidsLearningSupportProfile.unknown]);

  KidsLearningSupportProfile profile;
  bool accept = true;
  final saves = <KidsReadingAbility>[];

  @override
  KidsLearningSupportProfile read() => profile;

  @override
  Future<bool> save(KidsLearningSupportProfile next) async {
    saves.add(next.reading);
    if (accept) profile = next;
    return accept;
  }
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    KidsSupportProfileRepository repo, {
    Locale locale = const Locale('en'),
  }) => tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: KidsSupportProfileEditor(store: repo)),
    ),
  );

  ChoiceChip chip(WidgetTester tester, KidsReadingAbility r) =>
      tester.widget<ChoiceChip>(
        find.byKey(ValueKey('kids-support-reading-${r.name}')),
      );

  testWidgets('starts from the saved answer', (tester) async {
    await pump(
      tester,
      _FakeRepo(
        const KidsLearningSupportProfile(reading: KidsReadingAbility.withHelp),
      ),
    );

    expect(chip(tester, KidsReadingAbility.withHelp).selected, isTrue);
    expect(chip(tester, KidsReadingAbility.independent).selected, isFalse);
  });

  testWidgets('choosing an answer saves it once', (tester) async {
    final repo = _FakeRepo();
    await pump(tester, repo);

    await tester.tap(
      find.byKey(const ValueKey('kids-support-reading-notYetReading')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('kids-support-reading-notYetReading')),
    );
    await tester.pumpAndSettle();

    expect(repo.saves, [KidsReadingAbility.notYetReading]);
    expect(chip(tester, KidsReadingAbility.notYetReading).selected, isTrue);
  });

  testWidgets('a failed save restores the previous answer and says so', (
    tester,
  ) async {
    final repo = _FakeRepo()..accept = false;
    await pump(tester, repo);

    await tester.tap(
      find.byKey(const ValueKey('kids-support-reading-withHelp')),
    );
    await tester.pumpAndSettle();

    expect(chip(tester, KidsReadingAbility.withHelp).selected, isFalse);
    expect(
      find.byKey(const ValueKey('kids-support-save-failed')),
      findsOneWidget,
    );
  });

  testWidgets('an unexpected save error never leaves the chips stuck', (
    tester,
  ) async {
    await pump(tester, _ThrowingRepo());

    await tester.tap(
      find.byKey(const ValueKey('kids-support-reading-withHelp')),
    );
    await tester.pumpAndSettle();

    expect(chip(tester, KidsReadingAbility.withHelp).selected, isFalse);
    expect(chip(tester, KidsReadingAbility.independent).onSelected, isNotNull);
    expect(
      find.byKey(const ValueKey('kids-support-save-failed')),
      findsOneWidget,
    );
  });

  testWidgets('renders in Arabic at 320px without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pump(tester, _FakeRepo(), locale: const Locale('ar'));

    expect(find.text('كيف يقرأ طفلك؟'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ThrowingRepo implements KidsSupportProfileRepository {
  @override
  KidsLearningSupportProfile read() => KidsLearningSupportProfile.unknown;

  @override
  Future<bool> save(KidsLearningSupportProfile profile) async =>
      throw StateError('platform write failed');
}
