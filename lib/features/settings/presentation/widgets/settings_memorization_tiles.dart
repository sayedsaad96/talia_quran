import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import 'settings_section.dart';

class MemorizationPathSummaryTile extends StatelessWidget {
  const MemorizationPathSummaryTile({
    super.key,
    required this.isDark,
    required this.profile,
  });

  final bool isDark;
  final MemorizationProfile? profile;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final selectedPath = profile?.selectedPath;
    final hasPath = selectedPath != null;
    final title = switch (selectedPath) {
      MemorizationPath.adult => context.l10n.memorizationPathAdultsTitle,
      MemorizationPath.child => context.l10n.memorizationPathKidsTitle,
      _ => context.l10n.settingsMemorizationPathNotSelected,
    };
    final subtitle = switch (selectedPath) {
      MemorizationPath.adult => context.l10n.memorizationPathAdultsDesc,
      MemorizationPath.child => context.l10n.memorizationPathKidsDesc,
      _ => context.l10n.settingsMemorizationPathNotSelectedDesc,
    };

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasPath
                  ? primary.withValues(alpha: 0.12)
                  : AppColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.route_rounded,
              color: hasPath ? primary : AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.memorizationPath,
                  style: AppTypography.labelSmall.copyWith(
                    color: subtextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: hasPath ? textColor : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.labelSmall.copyWith(color: subtextColor),
                ),
              ],
            ),
          ),
          if (!hasPath) const SettingsTrailingChevron(color: AppColors.error),
        ],
      ),
    );

    if (!hasPath) {
      return InkWell(
        onTap: () => context.push(AppRoutes.memorizationPlus),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: content,
      );
    }

    return content;
  }
}

class ResetMemorizationPathTile extends StatelessWidget {
  const ResetMemorizationPathTile({
    super.key,
    required this.isDark,
    required this.onReset,
  });

  final bool isDark;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => const ResetMemorizationPathDialog(),
        );
        if (confirmed == true) await onReset();
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restart_alt_rounded,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.resetMemorizationPathTileTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    context.l10n.resetMemorizationPathTileSubtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SettingsTrailingChevron(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class ResetMemorizationPathDialog extends StatefulWidget {
  const ResetMemorizationPathDialog({super.key});

  @override
  State<ResetMemorizationPathDialog> createState() =>
      _ResetMemorizationPathDialogState();
}

class _ResetMemorizationPathDialogState
    extends State<ResetMemorizationPathDialog> {
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final confirmText = context.l10n.settingsResetPathConfirmPhrase;
    final canConfirm = _confirmController.text.trim() == confirmText;

    return AlertDialog(
      title: Text(
        context.l10n.resetMemorizationPathQuestion,
        style: const TextStyle(fontFamily: 'Amiri'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.resetMemorizationIdentityWarning),
            const SizedBox(height: AppSpacing.md),
            SettingsChecklistLine(
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF2D8E4C),
              text: context.l10n.settingsResetPathKeeps,
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsChecklistLine(
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
              text: context.l10n.settingsResetPathChanges,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.settingsResetPathInstruction),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _confirmController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: confirmText),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: canConfirm ? () => Navigator.pop(context, true) : null,
          child: Text(context.l10n.confirmResetMemorizationPath),
        ),
      ],
    );
  }
}

class SettingsChecklistLine extends StatelessWidget {
  const SettingsChecklistLine({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class AccuracySettingTile extends StatefulWidget {
  const AccuracySettingTile({super.key, required this.isDark});
  final bool isDark;

  @override
  State<AccuracySettingTile> createState() => _AccuracySettingTileState();
}

class _AccuracySettingTileState extends State<AccuracySettingTile> {
  static const _key = 'similarity_threshold';
  static const _levels = [0.70, 0.85, 0.92];
  int _selected = 1; // default = medium (0.85)

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPreferences>();
    final saved = prefs.getDouble(_key) ?? 0.85;
    if (saved <= 0.70) {
      _selected = 0;
    } else if (saved >= 0.92) {
      _selected = 2;
    } else {
      _selected = 1;
    }
  }

  Future<void> _select(BuildContext context, int value) async {
    if (value == _selected) return;

    final previous = _selected;
    final errorMessage = context.l10n.accuracySaveError;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _selected = value);

    final saved = await getIt<SharedPreferences>().setDouble(
      _key,
      _levels[_selected],
    );
    if (!mounted) return;
    if (!saved) {
      setState(() => _selected = previous);
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;

    final titles = [
      context.l10n.accuracyEasyTitle,
      context.l10n.accuracyMediumTitle,
      context.l10n.accuracyHardTitle,
    ];
    final descriptions = [
      context.l10n.accuracyEasyDesc,
      context.l10n.accuracyMediumDesc,
      context.l10n.accuracyHardDesc,
    ];
    final percents = [70, 85, 92];
    final colors = [Colors.green, primary, Colors.deepOrange];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_rounded, color: primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.l10n.accuracyLevel,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < 3; i++) ...[
            AccuracyOptionCard(
              title: titles[i],
              description: descriptions[i],
              percentLabel: context.l10n.accuracyRequiredPercent(percents[i]),
              color: colors[i],
              isDark: widget.isDark,
              isSelected: _selected == i,
              onTap: () => _select(context, i),
            ),
            if (i != 2) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class AccuracyOptionCard extends StatelessWidget {
  const AccuracyOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.percentLabel,
    required this.color,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final String percentLabel;
  final Color color;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.14 : 0.06),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: color.withValues(alpha: isSelected ? 0.72 : 0.18),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTypography.labelSmall.copyWith(
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                percentLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
