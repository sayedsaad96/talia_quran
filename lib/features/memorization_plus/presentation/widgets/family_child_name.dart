import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/family_dashboard.dart';

extension FamilyChildName on FamilyChildEntry {
  /// The child's name, or the localized default when none was set.
  String shownName(AppLocalizations l10n) {
    final name = displayName.trim();
    return name.isEmpty ? l10n.familyChildUnnamed : name;
  }
}
