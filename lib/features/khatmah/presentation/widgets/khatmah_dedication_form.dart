import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../khatmah_localizations.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/khatmah_dedication.dart';

class KhatmahDedicationForm extends StatefulWidget {
  const KhatmahDedicationForm({
    super.key,
    this.initialDedication,
    required this.onChanged,
  });

  final KhatmahDedication? initialDedication;
  final ValueChanged<KhatmahDedication> onChanged;

  @override
  State<KhatmahDedicationForm> createState() => _KhatmahDedicationFormState();
}

class _KhatmahDedicationFormState extends State<KhatmahDedicationForm> {
  late bool _isDedicated;
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  String? _relationship;
  DedicationCondition? _condition;

  static const List<String> _relationshipOptionsArabic = [
    'والد / والدة',
    'صديق',
    'قريب',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialDedication;
    _isDedicated = init?.isDedicated ?? false;
    _nameController = TextEditingController(text: init?.recipientName ?? '');
    _noteController = TextEditingController(text: init?.customNote ?? '');
    _relationship = init?.relationship;
    _condition = init?.condition;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(
      KhatmahDedication(
        isDedicated: _isDedicated,
        recipientName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        relationship: _relationship,
        condition: _condition,
        customNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism_rounded, color: primary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.khatmahDedicateKhatmahToSomeone,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Semantics(
                label: context.l10n.khatmahDedicateKhatmahToSomeone,
                child: Switch(
                  key: const Key('khatmah_dedication_toggle'),
                  value: _isDedicated,
                  activeTrackColor: primary.withValues(alpha: 0.5),
                  activeThumbColor: primary,
                  onChanged: (val) {
                    setState(() {
                      _isDedicated = val;
                    });
                    _notifyChange();
                  },
                ),
              ),
            ],
          ),
          if (_isDedicated) ...[
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.khatmahDedicationPreference),
            const SizedBox(height: AppSpacing.md),
            // Recipient name text field
            TextFormField(
              key: const Key('khatmah_dedication_recipient_name'),
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.l10n.khatmahRecipientName,
                hintText: context.l10n.khatmahEGMyBelovedMother,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onChanged: (_) => _notifyChange(),
            ),
            const SizedBox(height: AppSpacing.md),
            // Relationship dropdown
            DropdownButtonFormField<String>(
              key: const Key('khatmah_dedication_relationship'),
              isExpanded: true,
              initialValue: _relationship,
              decoration: InputDecoration(
                labelText: context.l10n.khatmahRelationship,
                prefixIcon: const Icon(Icons.group_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              items: {..._relationshipOptionsArabic, ?_relationship}
                  .map(
                    (rel) => DropdownMenuItem(
                      value: rel,
                      child: Text(localizedKhatmahRelationship(context, rel)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _relationship = val;
                });
                _notifyChange();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            // Condition choice chips
            Text(
              context.l10n.khatmahCondition,
              style: AppTypography.labelMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  key: const Key('khatmah_dedication_condition_alive'),
                  label: Text(context.l10n.khatmahLiving),
                  selected: _condition == DedicationCondition.alive,
                  selectedColor: primary.withValues(alpha: 0.2),
                  onSelected: (selected) {
                    setState(() {
                      _condition = selected ? DedicationCondition.alive : null;
                    });
                    _notifyChange();
                  },
                ),
                ChoiceChip(
                  key: const Key('khatmah_dedication_condition_deceased'),
                  label: Text(context.l10n.khatmahDeceased),
                  selected: _condition == DedicationCondition.deceased,
                  selectedColor: primary.withValues(alpha: 0.2),
                  onSelected: (selected) {
                    setState(() {
                      _condition = selected
                          ? DedicationCondition.deceased
                          : null;
                    });
                    _notifyChange();
                  },
                ),
                ChoiceChip(
                  key: const Key('khatmah_dedication_condition_sick'),
                  label: Text(context.l10n.khatmahSickRecovery),
                  selected: _condition == DedicationCondition.sick,
                  selectedColor: primary.withValues(alpha: 0.2),
                  onSelected: (selected) {
                    setState(() {
                      _condition = selected ? DedicationCondition.sick : null;
                    });
                    _notifyChange();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Custom note optional text field
            TextFormField(
              key: const Key('khatmah_dedication_custom_note'),
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.l10n.khatmahSpecialNoteDuAOptional,
                hintText: context.l10n.khatmahWriteYourOwnNote,
                prefixIcon: const Icon(Icons.note_alt_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onChanged: (_) => _notifyChange(),
            ),
          ],
        ],
      ),
    );
  }
}
