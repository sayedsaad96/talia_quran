import 'dart:convert';
import 'dart:io';

const _sections = [
  ('privacyControllerTitle', ['privacyControllerBody']),
  (
    'privacyDataTitle',
    ['privacyAccountData', 'privacyProgressData', 'privacyTechnicalData'],
  ),
  ('privacyPurposeTitle', ['privacyPurposeBody']),
  (
    'privacyPermissionsTitle',
    [
      'privacyMicrophone',
      'privacyCamera',
      'privacyNotifications',
      'privacyPhotos',
      'privacyLocation',
    ],
  ),
  (
    'privacyChildrenTitle',
    ['privacyChildrenBody', 'privacyGuardianSharing', 'privacyChildrenSpeech'],
  ),
  (
    'privacyProvidersTitle',
    ['privacyProvidersBody', 'privacyProviderProtection'],
  ),
  ('privacySecurityTitle', ['privacySecurityBody']),
  ('privacyRetentionTitle', ['privacyRetentionBody']),
  (
    'privacyDeletionTitle',
    ['privacyDeletionBody', 'privacyDeletionLimits', 'privacyExternalDeletion'],
  ),
  ('privacyRightsTitle', ['privacyRightsBody']),
  ('privacyChangesTitle', ['privacyChangesBody']),
  ('privacyContactTitle', ['privacyContactBody']),
];

String _escape(String text) => const HtmlEscape().convert(text);

Map<String, dynamic> _copy(String locale) =>
    jsonDecode(File('lib/core/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

String _section(Map<String, dynamic> copy, String title, List<String> keys) =>
    '<section><h2>${_escape(copy[title] as String)}</h2>'
    '${keys.map((key) => '<p>${_escape(copy[key] as String)}</p>').join()}'
    '</section>';

String _languageContent(String locale, bool deletionOnly) {
  final copy = _copy(locale);
  final heading = deletionOnly ? 'privacyDeletionTitle' : 'privacyPolicy';
  final sections = deletionOnly
      ? _sections.where(
          (section) => [
            'privacyDeletionTitle',
            'privacyRetentionTitle',
            'privacyContactTitle',
          ].contains(section.$1),
        )
      : _sections;
  final actionLabel = locale == 'ar'
      ? 'إرسال طلب حذف الحساب'
      : 'Email a deletion request';
  final deletionRequest = Uri(
    scheme: 'mailto',
    path: 'elsayed.saad2014@feps.edu.eg',
    queryParameters: {
      'subject': 'Talia Quran account deletion request',
      'body':
          'Please delete my Talia Quran account and associated data. I am sending this request from my account email. Please confirm completion.',
    },
  );
  return '<article lang="$locale" dir="${locale == 'ar' ? 'rtl' : 'ltr'}" id="$locale">'
      '<h1>${_escape(copy[heading] as String)}</h1>'
      '<p class="date">${_escape(copy['privacyEffectiveDate'] as String)}</p>'
      '${deletionOnly ? '' : '<p>${_escape(copy['privacyIntro'] as String)}</p>'}'
      '${deletionOnly ? '<p><a class="action" href="${_escape(deletionRequest.toString())}">$actionLabel</a></p>' : ''}'
      '${sections.map((section) => _section(copy, section.$1, section.$2)).join()}'
      '</article>';
}

String _document(bool deletionOnly) =>
    '''<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Talia Quran — ${deletionOnly ? 'Account Deletion' : 'Privacy Policy'}</title>
<style>
:root {color-scheme:light dark} body {margin:0;font-family:system-ui,sans-serif;line-height:1.8;background:#f7faf8;color:#163328} main {max-width:850px;margin:auto;padding:24px} nav {display:flex;gap:20px;flex-wrap:wrap} a {color:#116744;text-underline-offset:4px} article {margin:32px 0;padding:28px;background:white;border:1px solid #d8e3dc;border-radius:12px} h1 {font-size:1.8rem} h2 {font-size:1.3rem} p {white-space:pre-line;overflow-wrap:anywhere} .date {color:#4c6658} .action {display:inline-block;padding:10px 18px;border:2px solid currentColor;border-radius:8px} a:focus-visible {outline:3px solid #d98d22;outline-offset:4px} @media(prefers-color-scheme:dark) {body {background:#101b16;color:#edf5f0} article {background:#16261d;border-color:#3b5645} a {color:#83d7af} .date {color:#b3c9bc}} @media(max-width:480px) {main {padding:12px} article {padding:18px}}
</style>
</head>
<body><main>
<nav aria-label="Language and policies"><a href="#ar">العربية</a><a href="#en" lang="en">English</a><a href="privacy-policy.html">سياسة الخصوصية / Privacy policy</a><a href="delete-account.html">حذف الحساب / Delete account</a></nav>
${_languageContent('ar', deletionOnly)}
${_languageContent('en', deletionOnly)}
</main></body></html>
''';

void main() {
  Directory('docs/legal').createSync(recursive: true);
  for (final deletionOnly in [false, true]) {
    final name = deletionOnly ? 'delete-account' : 'privacy-policy';
    File('docs/legal/$name.html').writeAsStringSync(_document(deletionOnly));
  }
}
