import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/kids_encouragement.dart';
import '../cubits/parent_encouragement_composer_cubit.dart';
import 'encouragement_labels.dart';

class EncouragementComposerContent extends StatelessWidget {
  const EncouragementComposerContent({
    super.key,
    required this.state,
    required this.onMessageSelected,
    required this.onStickerSelected,
    required this.onSend,
  });

  final ParentEncouragementComposerState state;
  final ValueChanged<KidsEncouragementMessage> onMessageSelected;
  final ValueChanged<KidsEncouragementSticker> onStickerSelected;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.encouragementTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.encouragementLimit),
          const SizedBox(height: AppSpacing.md),
          _messageChoices(context),
          const SizedBox(height: AppSpacing.md),
          _stickerChoices(context),
          const SizedBox(height: AppSpacing.md),
          if (state.sent || state.failed)
            Semantics(
              liveRegion: true,
              child: Text(
                state.sent
                    ? l10n.encouragementSent
                    : state.quotaReached
                    ? l10n.encouragementQuota
                    : l10n.encouragementFailed,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            key: const ValueKey('encouragement-send'),
            onPressed: state.isSending || state.quotaReached ? null : onSend,
            child: state.isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.encouragementSend),
          ),
        ],
      ),
    );
  }

  Widget _messageChoices(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final message in KidsEncouragementMessage.values)
        ChoiceChip(
          key: ValueKey('encouragement-message-${message.serverKey}'),
          label: Text(encouragementMessageLabel(context.l10n, message)),
          selected: state.message == message,
          onSelected: state.isSending
              ? null
              : (_) => onMessageSelected(message),
        ),
    ],
  );

  Widget _stickerChoices(BuildContext context) => Wrap(
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.sm,
    children: [
      for (final sticker in KidsEncouragementSticker.values)
        ChoiceChip(
          key: ValueKey('encouragement-sticker-${sticker.serverKey}'),
          avatar: Image.asset(
            sticker.assetPath,
            width: 32,
            height: 32,
            excludeFromSemantics: true,
          ),
          label: Text(encouragementStickerLabel(context.l10n, sticker)),
          selected: state.sticker == sticker,
          onSelected: state.isSending
              ? null
              : (_) => onStickerSelected(sticker),
        ),
    ],
  );
}
