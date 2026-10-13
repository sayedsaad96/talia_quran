import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/open_location.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/presentation/theme/home_skin.dart';
import '../../../home/presentation/widgets/glass_panel.dart';
import '../../domain/entities/adult_journey_preferences.dart';
import '../../domain/entities/adult_journey_suggestion.dart';
import '../adult_journey_safe_routes.dart';
import '../cubits/adult_journey_cubit.dart';
import '../cubits/adult_journey_state.dart';
import 'adult_journey_error_text.dart';
import 'adult_journey_suggestion_tile.dart';

/// «مناسب لوقتك اليوم»: 5/10/20 minute chips (none selected by default) and at
/// most three suggestions from the existing journey. Times are approximate
/// and nothing here starts a timer, stops audio or trims a session.
class AdultTodayBudgetCard extends StatefulWidget {
  const AdultTodayBudgetCard({
    super.key,
    required this.state,
    required this.skin,
    this.openRoute,
  });

  final AdultJourneyState state;
  final HomeSkin skin;

  /// Navigation hook; defaults to the shell-aware `openLocation`.
  final Future<void> Function(BuildContext context, String route)? openRoute;

  @override
  State<AdultTodayBudgetCard> createState() => _AdultTodayBudgetCardState();
}

class _AdultTodayBudgetCardState extends State<AdultTodayBudgetCard> {
  bool _changingTime = false;
  bool _navigating = false;

  /// One tap → one fresh resolution → at most one navigation. A null route
  /// (account changed, child profile, another launch running) opens nothing.
  Future<void> _open(AdultJourneySuggestion suggestion) async {
    if (_navigating) return;
    _navigating = true;
    try {
      final cubit = context.read<AdultJourneyCubit>();
      final route = await cubit.resolveLaunch(suggestion);
      if (route == null || !mounted) return;
      final open = widget.openRoute ?? (c, r) => c.openLocation(r);
      await open(context, route);
    } finally {
      _navigating = false;
    }
  }

  Future<void> _choose(int minutes) async {
    final ok = await context.read<AdultJourneyCubit>().setTodayMinutes(minutes);
    if (ok && mounted) setState(() => _changingTime = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final skin = widget.skin;
    final minutes = widget.state.todayMinutes;
    final showChips = minutes == null || _changingTime;
    return GlassPanel(
      skin: skin,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            minutes == null
                ? l10n.adultJourneyTodayTitle
                : l10n.adultJourneyFitTitle,
            style: AppTypography.titleMedium.copyWith(
              color: skin.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.adultJourneyTodayHint,
            style: AppTypography.bodySmall.copyWith(color: skin.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (showChips) _chips(minutes),
          // Only this card's own failures (time choice, back to usual).
          if (widget.state.errorFor(AdultJourneyErrorSource.today)
              case final code?)
            AdultJourneyErrorText(
              code,
              key: const ValueKey('adult_today_error'),
            ),
          if (minutes != null) ..._suggestions(),
        ],
      ),
    );
  }

  Widget _chips(int? selected) {
    final busy = widget.state.isSaving;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final m in adultJourneyMinuteChoices.toList()..sort())
          ChoiceChip(
            key: ValueKey('adult_minutes_$m'),
            label: Text(context.l10n.homeMinutes(context.numText(m))),
            selected: selected == m,
            onSelected: busy ? null : (_) => _choose(m),
          ),
      ],
    );
  }

  List<Widget> _suggestions() {
    final shown = widget.state.suggestions.isEmpty
        ? const [
            AdultJourneySuggestion(
              launchKind: AdultJourneyLaunchKind.explore,
              reason: AdultJourneySuggestionReason.estimateUnavailable,
            ),
          ]
        : widget.state.suggestions;
    return [
      for (final (i, s) in shown.indexed)
        AdultJourneySuggestionTile(
          key: ValueKey('adult_suggestion_$i'),
          suggestion: s,
          skin: widget.skin,
          onOpen: _openerFor(s),
          onChangeTime: () => setState(() => _changingTime = true),
        ),
      TextButton(
        key: const ValueKey('adult_back_to_usual'),
        onPressed: widget.state.isSaving
            ? null
            : () => context.read<AdultJourneyCubit>().clearToday(),
        child: Text(context.l10n.adultJourneyBackToUsual),
      ),
    ];
  }

  /// Tappable only when a safe destination exists; the actual route is
  /// resolved at tap time.
  VoidCallback? _openerFor(AdultJourneySuggestion suggestion) {
    if (adultJourneySafeRoute(suggestion) == null) return null;
    return () => _open(suggestion);
  }
}
