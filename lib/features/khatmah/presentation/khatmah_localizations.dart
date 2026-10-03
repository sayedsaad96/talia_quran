import 'package:flutter/widgets.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/locale_number_formatter.dart';
import '../domain/entities/khatmah_dedication.dart';
import '../domain/entities/khatmah_plan.dart';

/// Localize only the stable system title. Recipient names and user-authored
/// titles remain exactly as entered by the user.
String localizedKhatmahPlanTitle(BuildContext context, String title) =>
    title.trim() == KhatmahPlan.defaultTitle
    ? context.l10n.khatmahQuranKhatmah
    : title;

/// Physical-page entry accepts both the Arabic and Western numeric keyboards.
int? parseKhatmahPageInput(String input) =>
    int.tryParse(LocaleNumberFormatter.western(input.trim()));

/// Translate known legacy relationship values without changing stored data.
String localizedKhatmahRelationship(
  BuildContext context,
  String? relationship,
) {
  final l10n = context.l10n;
  return switch (relationship) {
    'والد / والدة' || 'Parent' => l10n.khatmahRelationshipParent,
    'الأم' || 'والدة' || 'Mother' => l10n.khatmahRelationshipMother,
    'الأب' || 'والد' || 'Father' => l10n.khatmahRelationshipFather,
    'صديق' || 'Friend' => l10n.khatmahRelationshipFriend,
    'قريب' || 'Relative' => l10n.khatmahRelationshipRelative,
    'أخرى' || 'Other' => l10n.khatmahRelationshipOther,
    _ => relationship ?? '',
  };
}

String localizedKhatmahCondition(
  BuildContext context,
  DedicationCondition? condition,
) => switch (condition) {
  DedicationCondition.alive => context.l10n.khatmahLiving,
  DedicationCondition.deceased => context.l10n.khatmahDeceased,
  DedicationCondition.sick => context.l10n.khatmahSickRecovery,
  null => '',
};
