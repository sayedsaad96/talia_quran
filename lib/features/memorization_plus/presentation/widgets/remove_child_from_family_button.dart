import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubits/family_dashboard_cubit.dart';

/// Guardian-side end of a linked child's link (a lost or reset child device
/// would otherwise stay on the dashboard for good). Asks first; on success
/// the detail page closes and the dashboard confirms the removal.
class RemoveChildFromFamilyButton extends StatefulWidget {
  const RemoveChildFromFamilyButton({
    super.key,
    required this.childUserId,
    required this.childName,
  });

  final String childUserId;
  final String childName;

  @override
  State<RemoveChildFromFamilyButton> createState() =>
      _RemoveChildFromFamilyButtonState();
}

class _RemoveChildFromFamilyButtonState
    extends State<RemoveChildFromFamilyButton> {
  bool _busy = false;

  Future<void> _remove() async {
    final cubit = context.read<FamilyDashboardCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.parentDashboardRemoveChildConfirmTitle),
        content: Text(
          dialogContext.l10n.parentDashboardRemoveChildConfirmBody(
            widget.childName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('family-remove-child-confirm'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.parentDashboardRemoveChild),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final removed = await cubit.removeChild(widget.childUserId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (removed) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const ValueKey('family-remove-child'),
      style: TextButton.styleFrom(foregroundColor: AppColors.error),
      onPressed: _busy ? null : _remove,
      icon: _busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(TaliaIcons.linkOff),
      label: Text(context.l10n.parentDashboardRemoveChild),
    );
  }
}
