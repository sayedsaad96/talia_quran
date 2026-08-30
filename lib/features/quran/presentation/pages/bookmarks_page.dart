import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../data/datasources/bookmark_service.dart';
import '../../domain/entities/bookmark_entry.dart';
import '../../domain/bookmark_reader_location.dart';

/// Dedicated bookmarks browser showing all saved ayahs grouped by Surah.
class BookmarksTab extends StatefulWidget {
  const BookmarksTab({super.key});

  @override
  State<BookmarksTab> createState() => _BookmarksTabState();
}

class _BookmarksTabState extends State<BookmarksTab> {
  Future<void> _removeBookmark(BookmarkEntry entry) async {
    await getIt<BookmarkService>().toggle(entry);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return ListenableBuilder(
      listenable: getIt<BookmarkService>(),
      builder: (context, _) {
        final bookmarks = getIt<BookmarkService>().getAll();

        if (bookmarks.isEmpty) {
          return _EmptyBookmarks(isDark: isDark);
        }

        // Group bookmarks by surah
        final grouped = <int, List<BookmarkEntry>>{};
        for (final b in bookmarks) {
          grouped.putIfAbsent(b.surahId, () => []).add(b);
        }

        final surahIds = grouped.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          itemCount: surahIds.length,
          itemBuilder: (context, index) {
            final surahId = surahIds[index];
            final entries = grouped[surahId]!;
            return _SurahBookmarkGroup(
              surahName: entries.first.surahName,
              entries: entries,
              isDark: isDark,
              onTap: (entry) {
                context.push(bookmarkReaderLocation(entry));
              },
              onDismissed: _removeBookmark,
            );
          },
        );
      },
    );
  }
}

class _EmptyBookmarks extends StatelessWidget {
  const _EmptyBookmarks({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_outline_rounded,
                size: 56,
                color: primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.isArabic
                  ? 'لا توجد علامات مرجعية بعد'
                  : 'No bookmarks yet',
              style: AppTypography.titleMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.isArabic
                  ? 'اضغط مطوّلاً على أي آية أثناء القراءة لحفظها كعلامة مرجعية وتصل إليها بسهولة هنا'
                  : 'Long-press any ayah while reading to save it as a bookmark',
              style: AppTypography.bodySmall.copyWith(
                color: textColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahBookmarkGroup extends StatelessWidget {
  const _SurahBookmarkGroup({
    required this.surahName,
    required this.entries,
    required this.isDark,
    required this.onTap,
    required this.onDismissed,
  });

  final String surahName;
  final List<BookmarkEntry> entries;
  final bool isDark;
  final void Function(BookmarkEntry) onTap;
  final Future<void> Function(BookmarkEntry) onDismissed;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Surah header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 18, color: primary),
                const SizedBox(width: 8),
                Text(
                  surahName,
                  style: AppTypography.titleMedium.copyWith(color: primary),
                ),
                const Spacer(),
                Text(
                  context.l10n.bookmarksCountItem(entries.length),
                  style: AppTypography.labelSmall.copyWith(color: subtextColor),
                ),
              ],
            ),
          ),
          // Bookmarked ayahs
          ...entries.map(
            (entry) => Dismissible(
              key: ValueKey(entry.key),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: AlignmentDirectional.centerEnd,
                padding: const EdgeInsetsDirectional.only(end: 24),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(context.l10n.removeBookmarkTitle),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(context.l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          context.l10n.delete,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) => onDismissed(entry),
              child: Card(
                color: cardColor,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: BorderSide(color: primary.withValues(alpha: 0.1)),
                ),
                child: InkWell(
                  onTap: () => onTap(entry),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${entry.ayahNumber}',
                              style: AppTypography.labelMedium.copyWith(
                                color: primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            entry.ayahText,
                            style: AppTypography.quranSmall.copyWith(
                              color: textColor,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          tooltip: context.l10n.share,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.share_rounded,
                            size: 18,
                            color: primary.withValues(alpha: 0.7),
                          ),
                          onPressed: () {
                            final data = SocialShareData.quranVerse(
                              surahName: entry.surahName,
                              ayahNumber: entry.ayahNumber,
                              ayahText: entry.ayahText,
                            );
                            SocialShareSheet.show(context, data);
                          },
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: subtextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
