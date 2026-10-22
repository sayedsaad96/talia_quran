import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/v2/self_grade.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/locale_number_formatter.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../cubits/prayer_review_cubit.dart';

final class PrayerReviewPage extends StatelessWidget {
  const PrayerReviewPage({super.key, this.onRetry});
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.prayerReviewTitle)),
    body: SafeArea(
      child: BlocBuilder<PrayerReviewCubit, PrayerReviewState>(
        builder: (context, state) => _body(context, state),
      ),
    ),
  );

  Widget _body(BuildContext context, PrayerReviewState state) {
    final l10n = context.l10n;
    return switch (state.status) {
      PrayerReviewStatus.initial || PrayerReviewStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      PrayerReviewStatus.saved => _Message(l10n.prayerReviewSaved),
      PrayerReviewStatus.unavailable => _Message(l10n.prayerReviewUnavailable),
      PrayerReviewStatus.loadFailed => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.prayerReviewLoadFailed, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: onRetry,
                child: Text(l10n.similarAyahTrainerTryAgain),
              ),
            ],
          ),
        ),
      ),
      _ => _PassageReview(state: state),
    };
  }
}

final class _PassageReview extends StatelessWidget {
  const _PassageReview({required this.state});
  final PrayerReviewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = state.offer?.selection;
    if (selected == null) return _Message(l10n.prayerReviewUnavailable);
    final locale = l10n.localeName;
    final surah = locale.startsWith('ar')
        ? SurahNames.nameAr(selected.surahId)
        : SurahNames.nameEn(selected.surahId);
    final busy = state.status == PrayerReviewStatus.saving;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text(
          l10n.prayerReviewPassage(
            surah,
            LocaleNumberFormatter.number(selected.startAyah, locale),
            LocaleNumberFormatter.number(selected.endAyah, locale),
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final ayah in state.ayahs) _OriginalAyah(ayah: ayah),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.prayerReviewQuestion,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.status == PrayerReviewStatus.saveFailed) ...[
          Text(l10n.prayerReviewSaveFailed),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final grade in V2SelfGrade.values) ...[
          _GradeAction(grade: grade, enabled: !busy),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (busy) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

final class _OriginalAyah extends StatelessWidget {
  const _OriginalAyah({required this.ayah});
  final Ayah ayah;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleNumberFormatter.number(
                ayah.numberInSurah,
                context.l10n.localeName,
              ),
            ),
            Text(
              ayah.text,
              textDirection: TextDirection.rtl,
              style: AppTypography.quranVerse,
            ),
          ],
        ),
      ),
    ),
  );
}

final class _GradeAction extends StatelessWidget {
  const _GradeAction({required this.grade, required this.enabled});
  final V2SelfGrade grade;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (grade) {
      V2SelfGrade.mastered => l10n.prayerReviewGradeMastered,
      V2SelfGrade.hesitated => l10n.prayerReviewGradeHesitated,
      V2SelfGrade.forgot => l10n.prayerReviewGradeForgot,
    };
    return OutlinedButton(
      key: ValueKey('prayer_review_grade_${grade.name}'),
      onPressed: enabled
          ? () => context.read<PrayerReviewCubit>().grade(grade)
          : null,
      child: Text(label),
    );
  }
}

final class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
