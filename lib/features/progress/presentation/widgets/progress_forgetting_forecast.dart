part of '../pages/progress_page.dart';

class _ForgettingForecastCard extends StatelessWidget {
  const _ForgettingForecastCard({
    required this.passages,
    required this.onReview,
  });

  final List<ForecastPassage> passages;
  final ValueChanged<ForecastPassage> onReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.tokens.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.forgettingForecastTitle,
              style: AppTypography.titleMedium,
            ),
            for (final passage in passages) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.forgettingForecastPassage(
                        context.localizedSurahName(passage.surahId),
                        context.numText(passage.startAyah),
                        context.numText(passage.endAyah),
                      ),
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onReview(passage),
                    child: Text(context.l10n.forgettingForecastReviewNow),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
