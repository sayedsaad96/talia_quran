import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/repositories/kids_support_profile_repository.dart';
import '../../domain/entities/kids_learning_support_profile.dart';

/// Guardian question «كيف يقرأ طفلك؟» for the child on this device. The
/// answer only changes how early help is suggested, from the next session.
class KidsSupportProfileEditor extends StatefulWidget {
  const KidsSupportProfileEditor({super.key, required this.store});

  final KidsSupportProfileRepository store;

  @override
  State<KidsSupportProfileEditor> createState() =>
      _KidsSupportProfileEditorState();
}

class _KidsSupportProfileEditorState extends State<KidsSupportProfileEditor> {
  late KidsReadingAbility _reading = widget.store.read().reading;
  bool _saving = false;
  bool _failed = false;

  Future<void> _select(KidsReadingAbility reading) async {
    if (_saving || reading == _reading) return;
    final previous = _reading;
    setState(() {
      _saving = true;
      _failed = false;
      _reading = reading;
    });
    var saved = false;
    try {
      saved = await widget.store.save(
        KidsLearningSupportProfile(reading: reading),
      );
    } catch (_) {
      // Any other repository failure: shown as "not saved", never stuck.
      saved = false;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!saved) {
        _reading = previous;
        _failed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = {
      KidsReadingAbility.independent: l10n.kidsSupportReadingIndependent,
      KidsReadingAbility.withHelp: l10n.kidsSupportReadingWithHelp,
      KidsReadingAbility.notYetReading: l10n.kidsSupportReadingNotYet,
    };
    return Column(
      key: const ValueKey('kids-support-profile-editor'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.kidsSupportReadingQuestion, style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final entry in options.entries)
              ChoiceChip(
                key: ValueKey('kids-support-reading-${entry.key.name}'),
                label: Text(entry.value),
                selected: _reading == entry.key,
                onSelected: _saving ? null : (_) => _select(entry.key),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _failed ? l10n.kidsSupportSaveFailed : l10n.kidsSupportReadingNote,
          key: ValueKey(
            _failed ? 'kids-support-save-failed' : 'kids-support-note',
          ),
          style: AppTypography.bodySmall.copyWith(
            color: context.tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}
