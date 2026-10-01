import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations_ar.dart';
import 'package:talia_quran/core/l10n/app_localizations_en.dart';
import 'package:talia_quran/features/settings/presentation/pages/privacy_policy_content.dart';

void main() {
  for (final l10n in [AppLocalizationsAr(), AppLocalizationsEn()]) {
    test(
      'published policy matches in-app disclosures in ${l10n.localeName}',
      () {
        final html = File('docs/legal/privacy-policy.html').readAsStringSync();
        const escape = HtmlEscape();
        for (final section in PrivacyPolicyContent.sections(l10n)) {
          expect(html, contains(escape.convert(section.title)));
          for (final paragraph in [...section.paragraphs, ...section.bullets]) {
            expect(html, contains(escape.convert(paragraph)));
          }
        }
      },
    );

    test(
      'external deletion discloses scope and contact in ${l10n.localeName}',
      () {
        final html = File('docs/legal/delete-account.html').readAsStringSync();
        const escape = HtmlEscape();
        for (final paragraph in [
          l10n.privacyDeletionBody,
          l10n.privacyDeletionLimits,
          l10n.privacyExternalDeletion,
          l10n.privacyRetentionBody,
        ]) {
          expect(html, contains(escape.convert(paragraph)));
        }
        expect(html, contains('mailto:elsayed.saad2014@feps.edu.eg'));
        expect(html, contains('subject=Talia+Quran+account+deletion+request'));
      },
    );
  }
}
