import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/kids_journey_path_definition.dart';
import '../../domain/entities/kids_session_policy.dart';

/// How a child chose to memorize one surah: all at once, or in stages of
/// [stageSize] ayahs.
final class KidsSurahSplitChoice {
  const KidsSurahSplitChoice({required this.whole, this.stageSize});

  final bool whole;
  final int? stageSize;

  @override
  bool operator ==(Object other) =>
      other is KidsSurahSplitChoice &&
      other.whole == whole &&
      other.stageSize == stageSize;

  @override
  int get hashCode => Object.hash(whole, stageSize);
}

/// «كيف تحب أن تحفظها؟». Null when closed without a choice. "All at once" is
/// offered only for a surah of at most [kKidsWholeSurahMaxAyahsLimit] ayahs.
Future<KidsSurahSplitChoice?> showKidsSurahSplitSheet(
  BuildContext context, {
  required int ayahCount,
  required int defaultStageSize,
}) => showModalBottomSheet<KidsSurahSplitChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _KidsSurahSplitSheet(
    ayahCount: ayahCount,
    defaultStageSize: defaultStageSize,
  ),
);

class _KidsSurahSplitSheet extends StatefulWidget {
  const _KidsSurahSplitSheet({
    required this.ayahCount,
    required this.defaultStageSize,
  });

  final int ayahCount;
  final int defaultStageSize;

  @override
  State<_KidsSurahSplitSheet> createState() => _KidsSurahSplitSheetState();
}

class _KidsSurahSplitSheetState extends State<_KidsSurahSplitSheet> {
  late bool _whole = false;
  late int _size = sanitizeKidsAyahsPerHouse(widget.defaultStageSize) ?? 3;

  bool get _canBeWhole => widget.ayahCount <= kKidsWholeSurahMaxAyahsLimit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stageCount = (widget.ayahCount / _size).ceil();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.kidsSplitTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_canBeWhole) ...[
              _ModeButton(
                key: const ValueKey('kids-split-whole'),
                label: l10n.kidsSplitWhole,
                selected: _whole,
                onTap: () => setState(() => _whole = true),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ModeButton(
                key: const ValueKey('kids-split-staged'),
                label: l10n.kidsSplitStaged,
                selected: !_whole,
                onTap: () => setState(() => _whole = false),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!_whole) ...[
              Text(
                l10n.kidsSplitAyahsPerStage,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var size = 1; size <= 10; size++)
                    ChoiceChip(
                      key: ValueKey('kids-split-size-$size'),
                      label: SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(child: Text(context.numText(size))),
                      ),
                      selected: _size == size,
                      onSelected: (_) => setState(() => _size = size),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.kidsSplitStageCount(stageCount),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              key: const ValueKey('kids-split-confirm'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () => Navigator.of(context).pop(
                KidsSurahSplitChoice(
                  whole: _whole,
                  stageSize: _whole ? null : _size,
                ),
              ),
              child: Text(l10n.kidsSplitConfirm),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
