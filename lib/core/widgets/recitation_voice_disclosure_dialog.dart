import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_typography.dart';

/// Shows the recitation speech disclosure. Returns true only when the user
/// explicitly agrees; dismissing it counts as declining.
Future<bool> showRecitationVoiceDisclosure(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (_) => const RecitationVoiceDisclosureDialog(),
  );
  return accepted ?? false;
}

class RecitationVoiceDisclosureDialog extends StatelessWidget {
  const RecitationVoiceDisclosureDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        l10n.recitationVoiceDisclosureTitle,
        style: AppTypography.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.recitationVoiceDisclosureBody),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.recitationVoiceDisclosureGuardian,
              style: AppTypography.bodySmall.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('recitation-voice-decline'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.recitationVoiceDisclosureDecline),
        ),
        FilledButton(
          key: const ValueKey('recitation-voice-accept'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.recitationVoiceDisclosureAccept),
        ),
      ],
    );
  }
}
