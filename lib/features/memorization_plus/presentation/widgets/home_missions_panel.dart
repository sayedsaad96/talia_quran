import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/kids_home_mission.dart';
import '../../domain/entities/kids_session_policy.dart';
import '../../domain/services/kids_home_mission_templates.dart';

import '../../../../core/utils/locale_number_formatter.dart';

/// Maximum mission length; mirrors the server and local-service limit.
const int kHomeMissionDialogMaxLength = 120;

/// Guardian-side «المهمات المنزلية» panel: add button, list with status chips,
/// and «اطّلعت» on reported rows only. It holds no state of its own; the
/// caller routes [onAdd] and [onAcknowledge] to the dashboard cubit.
class HomeMissionsPanel extends StatelessWidget {
  const HomeMissionsPanel({
    super.key,
    required this.missions,
    required this.onAdd,
    required this.onAcknowledge,
    this.templateAgeBand,
  });

  final List<KidsHomeMission> missions;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onAcknowledge;

  /// When set, the add dialog suggests the educational templates for this age
  /// band; null keeps the four suggestions every guardian already had.
  final KidsAgeBand? templateAgeBand;

  Future<void> _showAddDialog(BuildContext context) async {
    final band = templateAgeBand;
    final title = await showDialog<String>(
      context: context,
      builder: (_) => HomeMissionDialog(
        templates: band == null
            ? KidsHomeMissionTemplates.legacy
            : KidsHomeMissionTemplates.idsFor(band),
      ),
    );
    if (title != null && title.isNotEmpty) onAdd(title);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.childDetailHomeMissions,
                  style: AppTypography.titleSmall,
                ),
              ),
              TextButton.icon(
                key: const ValueKey('child-detail-add-home-mission'),
                onPressed: () => _showAddDialog(context),
                icon: const Icon(TaliaIcons.addTask),
                label: Text(l10n.childDetailAddHomeMission),
              ),
            ],
          ),
          if (missions.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          for (final mission in missions)
            _HomeMissionRow(
              mission: mission,
              onAcknowledge: () => onAcknowledge(mission.id),
            ),
        ],
      ),
    );
  }
}

class _HomeMissionRow extends StatelessWidget {
  const _HomeMissionRow({required this.mission, required this.onAcknowledge});

  final KidsHomeMission mission;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color) = switch (mission.status) {
      KidsHomeMissionStatus.assigned => (
        l10n.kidsHomeMissionAssigned,
        context.tokens.textSecondary,
      ),
      KidsHomeMissionStatus.reported => (
        l10n.kidsHomeMissionReported,
        AppColors.warning,
      ),
      KidsHomeMissionStatus.acknowledged => (
        l10n.kidsHomeMissionAcknowledged,
        AppColors.success,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mission.title, style: AppTypography.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
          if (mission.status == KidsHomeMissionStatus.reported)
            FilledButton(
              key: ValueKey('home-mission-ack-${mission.id}'),
              onPressed: onAcknowledge,
              child: Text(l10n.kidsHomeMissionAcknowledgeAction),
            ),
        ],
      ),
    );
  }
}

/// Add-mission dialog: built-in non-religious suggestion chips (tapping one
/// fills the field, which stays editable) plus free text of 1-120 characters.
class HomeMissionDialog extends StatefulWidget {
  const HomeMissionDialog({
    super.key,
    this.templates = KidsHomeMissionTemplates.legacy,
  });

  final List<KidsHomeMissionTemplateId> templates;

  @override
  State<HomeMissionDialog> createState() => _HomeMissionDialogState();
}

class _HomeMissionDialogState extends State<HomeMissionDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  /// A second tap on «حفظ» while the dialog is closing must not pop the page
  /// underneath it.
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _suggestion(AppLocalizations l10n, KidsHomeMissionTemplateId id) =>
      switch (id) {
        KidsHomeMissionTemplateId.tidyRoom => l10n.kidsHomeMissionSuggestTidy,
        KidsHomeMissionTemplateId.helpTable => l10n.kidsHomeMissionSuggestHelp,
        KidsHomeMissionTemplateId.kindWord => l10n.kidsHomeMissionSuggestKind,
        KidsHomeMissionTemplateId.shareToy => l10n.kidsHomeMissionSuggestShare,
        KidsHomeMissionTemplateId.tellLearning =>
          l10n.kidsHomeMissionSuggestLearning,
        KidsHomeMissionTemplateId.prepareBag => l10n.kidsHomeMissionSuggestBag,
      };

  void _submit() {
    if (_submitted) return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = context.l10n.fieldRequired);
      return;
    }
    if (text.length > kHomeMissionDialogMaxLength) {
      setState(
        () => _errorText = context.l10n.fieldTooLong(
          LocaleNumberFormatter.format(
            (kHomeMissionDialogMaxLength).toString(),
            context.l10n.localeName,
          ),
        ),
      );
      return;
    }
    _submitted = true;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.childDetailAddHomeMission),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final id in widget.templates)
                  ActionChip(
                    key: ValueKey('home-mission-template-${id.name}'),
                    label: Text(_suggestion(l10n, id)),
                    onPressed: () => setState(() {
                      _controller.text = _suggestion(l10n, id);
                      _errorText = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              maxLength: kHomeMissionDialogMaxLength,
              decoration: InputDecoration(
                errorText: _errorText,
                counterText: '',
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
