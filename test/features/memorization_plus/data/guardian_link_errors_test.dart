import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/l10n/localization_helpers.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_parent_access_service.dart';

void main() {
  group('normalizeLinkToken', () {
    String? normalize(String raw) =>
        MemorizationParentAccessService.normalizeLinkToken(raw);

    test('accepts a typed code in any case and with spacing', () {
      expect(normalize('a1b2c3d4e5f6'), 'A1B2C3D4E5F6');
      expect(normalize('  A1B2 C3D4-E5F6 '), 'A1B2C3D4E5F6');
    });

    test('accepts scanned QR payloads, including the legacy prefix', () {
      expect(normalize('talia-kids-link:A1B2C3D4E5F6'), 'A1B2C3D4E5F6');
      expect(normalize('talia_link:a1b2c3d4e5f6'), 'A1B2C3D4E5F6');
    });

    test('rejects codes this app could never have issued', () {
      expect(normalize(''), isNull);
      expect(normalize('A1B2C3'), isNull);
      expect(normalize('A1B2C3D4E5F6A'), isNull);
      expect(normalize('ZZZZZZZZZZZZ'), isNull);
      expect(normalize('https://example.com'), isNull);
    });
  });

  group('linkAcceptFailure', () {
    String codeFor(String serverMessage) =>
        MemorizationParentAccessService.linkAcceptFailure(
          PostgrestException(message: serverMessage, code: 'P0001'),
        ).message;

    test('maps each accept_child_link_token_with_hash exception', () {
      expect(
        codeFor('Invalid or expired link token'),
        CubitMessageCodes.guardianLinkCodeInvalid,
      );
      expect(
        codeFor('Child already has an active guardian'),
        CubitMessageCodes.guardianChildHasGuardian,
      );
      expect(
        codeFor('Parent and child accounts must be different'),
        CubitMessageCodes.guardianSameAccount,
      );
      expect(
        codeFor('Not authenticated'),
        CubitMessageCodes.guardianSignInRequired,
      );
    });

    test('keeps unknown server errors generic', () {
      expect(
        codeFor('permission denied for table parent_child_links'),
        CubitMessageCodes.errorServer,
      );
    });
  });

  testWidgets('every guardian message code is translated in both locales', (
    tester,
  ) async {
    const codes = [
      CubitMessageCodes.guardianSignInRequired,
      CubitMessageCodes.guardianCloudUnavailable,
      CubitMessageCodes.guardianOnlyForChildren,
      CubitMessageCodes.guardianAlreadyLinked,
      CubitMessageCodes.guardianParentModeAdultsOnly,
      CubitMessageCodes.guardianLinkCodeInvalid,
      CubitMessageCodes.guardianChildHasGuardian,
      CubitMessageCodes.guardianSameAccount,
      CubitMessageCodes.parentRewardTitleRequired,
      CubitMessageCodes.parentRewardLimitReached,
      CubitMessageCodes.childNicknameInvalid,
      CubitMessageCodes.childAgeInvalid,
      CubitMessageCodes.guardianChildNotLinked,
      CubitMessageCodes.childIdentityUpdateUnavailable,
    ];
    for (final locale in const [Locale('ar'), Locale('en')]) {
      late BuildContext captured;
      await tester.pumpWidget(
        Localizations(
          locale: locale,
          delegates: AppLocalizations.localizationsDelegates,
          child: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final texts = <String>{};
      for (final code in codes) {
        final text = captured.localizedCubitMessage(code);
        expect(text, isNot(startsWith('@')), reason: '$code in $locale');
        texts.add(text);
      }
      expect(texts, hasLength(codes.length), reason: 'distinct in $locale');
    }
  });
}
