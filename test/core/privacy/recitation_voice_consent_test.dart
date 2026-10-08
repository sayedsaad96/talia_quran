import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/privacy/recitation_voice_consent.dart';
import 'package:talia_quran/core/widgets/recitation_voice_disclosure_dialog.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_recitation_capture.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('RecitationVoiceConsent', () {
    test(
      'acceptance is remembered and the dialog is not shown again',
      () async {
        var asks = 0;
        final consent = RecitationVoiceConsent(
          prefs,
          ask: () async {
            asks++;
            return true;
          },
        );

        expect(await consent.ensure(), isTrue);
        expect(await consent.ensure(), isTrue);
        expect(asks, 1);
        expect(consent.isAccepted, isTrue);
      },
    );

    test(
      'declining is not remembered, so the next attempt asks again',
      () async {
        var asks = 0;
        final consent = RecitationVoiceConsent(
          prefs,
          ask: () async {
            asks++;
            return false;
          },
        );

        expect(await consent.ensure(), isFalse);
        expect(await consent.ensure(), isFalse);
        expect(asks, 2);
        expect(consent.isAccepted, isFalse);
      },
    );

    test('concurrent callers share one dialog', () async {
      var asks = 0;
      final answer = Completer<bool>();
      final consent = RecitationVoiceConsent(
        prefs,
        ask: () {
          asks++;
          return answer.future;
        },
      );

      final first = consent.ensure();
      final second = consent.ensure();
      answer.complete(true);

      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(asks, 1);
    });
  });

  group('speech paths fail closed when the disclosure is declined', () {
    test('kids recorder reports a denied permission before the mic', () async {
      var micRequested = false;
      final recorder = KidsSpeechRecitationRecorder(
        voiceConsent: () async => false,
        microphonePermission: () async {
          micRequested = true;
          return true;
        },
      );

      final result = await recorder.capture(
        externalCompleter: Completer<KidsRecitationCaptureResult>(),
      );

      expect(result.isError, isTrue);
      expect(micRequested, isFalse);
    });

    test('listening review falls back before the mic', () async {
      final capture = SpeechToTextListeningCapture(
        voiceConsent: () async => false,
      );

      expect(
        await capture.prepare(),
        ListeningCaptureReadiness.permissionDenied,
      );
    });
  });

  group('RecitationVoiceDisclosureDialog', () {
    Future<Future<bool>> open(WidgetTester tester) async {
      late Future<bool> result;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('open'),
                onPressed: () =>
                    result = showRecitationVoiceDisclosure(context),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('accepting returns true', (tester) async {
      final result = await open(tester);
      expect(find.text('قبل بدء التسميع'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('recitation-voice-accept')));
      await tester.pumpAndSettle();

      expect(await result, isTrue);
    });

    testWidgets('declining or dismissing returns false', (tester) async {
      var result = await open(tester);
      await tester.tap(find.byKey(const ValueKey('recitation-voice-decline')));
      await tester.pumpAndSettle();
      expect(await result, isFalse);

      result = await open(tester);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });
  });
}
