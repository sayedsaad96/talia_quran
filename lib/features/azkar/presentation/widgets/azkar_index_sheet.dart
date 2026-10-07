import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/azkar_entities.dart';

/// Row title for the index: the opening of the zikr text, so rows are
/// distinguishable even when many share the same source. The cut is made on a
/// letter boundary; the stored text is never altered.
String azkarIndexTitle(Zikr zikr, {int maxChars = 40}) {
  final flat = zikr.text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final letters = flat.characters;
  if (letters.length <= maxChars) return flat;
  return '${letters.take(maxChars)}…';
}

class AzkarIndexEntry {
  const AzkarIndexEntry({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool selected;
}

/// Bottom sheet listing every zikr with its progress. Shared by the category
/// reader and the smart wird so both index sheets behave the same.
Future<void> showAzkarIndexSheet(
  BuildContext context, {
  required List<AzkarIndexEntry> entries,
  required ValueChanged<int> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Directionality(
      textDirection: Directionality.of(context),
      child: _AzkarIndexSheet(
        entries: entries,
        onSelected: (index) {
          Navigator.pop(sheetContext);
          onSelected(index);
        },
      ),
    ),
  );
}

class _AzkarIndexSheet extends StatefulWidget {
  const _AzkarIndexSheet({required this.entries, required this.onSelected});

  final List<AzkarIndexEntry> entries;
  final ValueChanged<int> onSelected;

  @override
  State<_AzkarIndexSheet> createState() => _AzkarIndexSheetState();
}

class _AzkarIndexSheetState extends State<_AzkarIndexSheet> {
  static const double _rowExtent = 72;
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    final selected = widget.entries.indexWhere((entry) => entry.selected);
    // Open with the current row a little below the top, not at the very edge.
    final offset = selected <= 1 ? 0.0 : (selected - 1) * _rowExtent;
    _controller = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Material(
      color: context.tokens.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: math.min(460, height * 0.7)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: context.tokens.textHint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  context.l10n.azkarIndex,
                  style: AppTypography.headlineSmall.copyWith(
                    color: context.tokens.textPrimary,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  controller: _controller,
                  itemExtent: _rowExtent,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: widget.entries.length,
                  itemBuilder: (context, index) {
                    final entry = widget.entries[index];
                    return ListTile(
                      selected: entry.selected,
                      selectedTileColor: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      leading: entry.done
                          ? const Icon(
                              TaliaIcons.checkCircleFilled,
                              color: AppColors.success,
                            )
                          : CircleAvatar(
                              radius: 14,
                              backgroundColor: entry.selected
                                  ? AppColors.primary
                                  : context.tokens.surfaceVariant,
                              foregroundColor: entry.selected
                                  ? Colors.white
                                  : context.tokens.textPrimary,
                              child: Text(
                                context.numText(index + 1),
                                style: AppTypography.labelSmall,
                              ),
                            ),
                      title: Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.tokens.textPrimary,
                          fontFamily: 'Amiri',
                          fontWeight: entry.selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        entry.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: context.tokens.textSecondary,
                        ),
                      ),
                      onTap: () => widget.onSelected(index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
