import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/kids_encouragement/domain/entities/kids_encouragement.dart';
import 'package:talia_quran/features/kids_encouragement/presentation/cubits/parent_encouragement_composer_cubit.dart';
import 'package:talia_quran/features/kids_encouragement/presentation/widgets/child_encouragement_card.dart';
import 'package:talia_quran/features/kids_encouragement/presentation/widgets/encouragement_composer_content.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

Widget _narrowArabicApp(Widget child) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData.fromView(
      WidgetsBinding.instance.platformDispatcher.views.first,
    ).copyWith(textScaler: const TextScaler.linear(2)),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SizedBox(width: 320, child: SingleChildScrollView(child: child)),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'parent chooses only fixed messages and stickers before sending',
    (tester) async {
      KidsEncouragementMessage? message;
      KidsEncouragementSticker? sticker;
      var sends = 0;
      await tester.pumpWidget(
        _app(
          EncouragementComposerContent(
            state: const ParentEncouragementComposerState(),
            onMessageSelected: (value) => message = value,
            onStickerSelected: (value) => sticker = value,
            onSend: () => sends++,
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('encouragement-message-well_done')),
      );
      await tester.tap(
        find.byKey(const ValueKey('encouragement-sticker-talia_encourage')),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('encouragement-send')),
      );
      await tester.tap(find.byKey(const ValueKey('encouragement-send')));
      expect(message, KidsEncouragementMessage.wellDone);
      expect(sticker, KidsEncouragementSticker.taliaEncourage);
      expect(sends, 1);
      expect(find.textContaining('١٠'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sending and quota states disable sending', (tester) async {
    for (final state in const [
      ParentEncouragementComposerState(isSending: true),
      ParentEncouragementComposerState(failed: true, quotaReached: true),
    ]) {
      await tester.pumpWidget(
        _app(
          EncouragementComposerContent(
            state: state,
            onMessageSelected: (_) {},
            onStickerSelected: (_) {},
            onSend: () => fail('disabled send'),
          ),
        ),
      );
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('encouragement-send')),
      );
      expect(button.onPressed, isNull);
    }
  });

  testWidgets('child reads a message and acknowledges only with Done', (
    tester,
  ) async {
    var acknowledgements = 0;
    await tester.pumpWidget(
      _app(
        ChildEncouragementCard(
          encouragement: KidsEncouragement(
            id: 1,
            parentUserId: 'parent',
            childUserId: 'child',
            message: KidsEncouragementMessage.proud,
            sticker: KidsEncouragementSticker.starReward,
            createdAt: DateTime.utc(2026, 10, 21),
            seenAt: null,
            clientRequestId: '00000000-0000-4000-8000-000000000001',
          ),
          onDone: () => acknowledgements++,
        ),
        reduceMotion: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(acknowledgements, 0);
    expect(find.text('أنا فخور بك!'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('encouragement-done')));
    expect(acknowledgements, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'composer and child card stay usable at narrow Arabic 200% text',
    (tester) async {
      await tester.pumpWidget(
        _narrowArabicApp(
          Column(
            children: [
              EncouragementComposerContent(
                state: const ParentEncouragementComposerState(),
                onMessageSelected: (_) {},
                onStickerSelected: (_) {},
                onSend: () {},
              ),
              ChildEncouragementCard(
                encouragement: KidsEncouragement(
                  id: 1,
                  parentUserId: 'parent',
                  childUserId: 'child',
                  message: KidsEncouragementMessage.seeYouTomorrow,
                  sticker: KidsEncouragementSticker.taliaEncourage,
                  createdAt: DateTime.utc(2026, 10, 21),
                  seenAt: null,
                  clientRequestId: '00000000-0000-4000-8000-000000000001',
                ),
                onDone: () {},
              ),
            ],
          ),
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('encouragement-done')),
      );
      expect(find.byKey(const ValueKey('encouragement-send')), findsOneWidget);
      expect(find.byKey(const ValueKey('encouragement-done')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
