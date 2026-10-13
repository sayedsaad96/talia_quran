import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../settings/presentation/widgets/settings_nav_tile.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../adult_journey_feature_flags.dart';
import '../cubits/adult_journey_cubit.dart';
import 'adult_journey_setup_sheet.dart';

/// Adult-only Settings entry that opens the same setup sheet as Home. Builds
/// nothing when personalization is off. The caller decides adult-only.
class AdultJourneySettingsTile extends StatefulWidget {
  const AdultJourneySettingsTile({super.key, required this.isDark});

  final bool isDark;

  @override
  State<AdultJourneySettingsTile> createState() =>
      _AdultJourneySettingsTileState();
}

class _AdultJourneySettingsTileState extends State<AdultJourneySettingsTile> {
  AdultJourneyCubit? _cubit;

  @override
  void initState() {
    super.initState();
    final enabled =
        getIt.isRegistered<AdultJourneyFlags>() &&
        getIt.isRegistered<AdultJourneyCubit>() &&
        getIt<AdultJourneyFlags>().isEnabled(
          AdultJourneyFeature.personalization,
        );
    if (enabled) _cubit = getIt<AdultJourneyCubit>()..loadPreferences();
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  Future<void> _open() async {
    final cubit = _cubit!;
    if (!cubit.state.isVisible) await cubit.loadPreferences();
    if (!mounted) return;
    await showAdultJourneySetupSheet(context, cubit);
  }

  @override
  Widget build(BuildContext context) {
    if (_cubit == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Column(
      children: [
        SettingsDivider(isDark: widget.isDark),
        SettingsNavTile(
          icon: TaliaIcons.journey,
          title: l10n.adultJourneySettingsTileTitle,
          subtitle: l10n.adultJourneySettingsTileSubtitle,
          isDark: widget.isDark,
          onTap: _open,
        ),
      ],
    );
  }
}
