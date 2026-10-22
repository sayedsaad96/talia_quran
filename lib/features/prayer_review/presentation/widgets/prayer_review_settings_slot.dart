import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/experience/experience_feature_flags.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/locale_number_formatter.dart';
import '../../../prayer_companion/domain/entities/prayer_companion.dart';
import '../../presentation/cubits/prayer_review_settings_cubit.dart';
import '../../../settings/presentation/widgets/settings_group.dart';

/// Feature-gated insertion point for the Prayer Settings page.
final class PrayerReviewSettingsSlot extends StatelessWidget {
  const PrayerReviewSettingsSlot({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_available()) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => getIt<PrayerReviewSettingsCubit>()..load(),
      child: const PrayerReviewSettingsPanel(),
    );
  }

  bool _available() =>
      getIt.isRegistered<ExperienceFlags>() &&
      getIt<ExperienceFlags>().isEnabled(ExperienceFeature.prayerReview) &&
      getIt.isRegistered<PrayerReviewSettingsCubit>();
}

/// Presentational panel, separated so it can be tested without global DI.
final class PrayerReviewSettingsPanel extends StatelessWidget {
  const PrayerReviewSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerReviewSettingsCubit, PrayerReviewSettingsState>(
      builder: (context, state) {
        if (!state.isReady) return const SizedBox.shrink();
        return SettingsGroup(
          title: context.l10n.prayerReviewSettingsTitle,
          children: [
            for (final prayer in PrayerKey.values)
              _PrayerLengthTile(
                prayer: prayer,
                value: state.lengths[prayer]!,
              ),
            if (state.saveFailed)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.l10n.errorOccurred,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        );
      },
    );
  }
}

final class _PrayerLengthTile extends StatelessWidget {
  const _PrayerLengthTile({required this.prayer, required this.value});

  final PrayerKey prayer;
  final int value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      title: Text(_label(l10n)),
      subtitle: DropdownButton<int>(
        key: Key('prayer_review_length_${prayer.name}'),
        isExpanded: true,
        value: value,
        items: [
          for (final length in const [3, 7, 15])
            DropdownMenuItem(
              value: length,
              child: Text(
                l10n.prayerReviewLengthOption(length).replaceFirst(
                  length.toString(),
                  LocaleNumberFormatter.number(length, l10n.localeName),
                ),
              ),
            ),
        ],
        onChanged: stateSaving(context) ? null : (next) {
          if (next != null) {
            context.read<PrayerReviewSettingsCubit>().changeLength(
              prayer,
              next,
            );
          }
        },
      ),
    );
  }

  bool stateSaving(BuildContext context) =>
      context.read<PrayerReviewSettingsCubit>().state.isSaving;

  String _label(AppLocalizations l10n) => switch (prayer) {
    PrayerKey.fajr => l10n.prayerFajr,
    PrayerKey.dhuhr => l10n.prayerDhuhr,
    PrayerKey.asr => l10n.prayerAsr,
    PrayerKey.maghrib => l10n.prayerMaghrib,
    PrayerKey.isha => l10n.prayerIsha,
  };
}
