import '../l10n/app_localizations.dart';

class ResumeSessionPresentationInput {
  const ResumeSessionPresentationInput({
    required this.route,
    required this.isArabic,
    required this.l10n,
    this.metadata = const {},
  });

  final String route;
  final bool isArabic;
  final AppLocalizations l10n;
  final Map<String, String> metadata;
}
