import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/journey/journey_presentation_data.dart';
import '../../../../core/journey/unified_journey_action.dart';
import '../../../../core/journey/unified_journey_action_mapper.dart';
import '../../../../core/journey/unified_journey_engine.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/unified_hero_action_card.dart';

void showHomeAlternativesSheet(
  BuildContext context, {
  required List<UnifiedJourneyAction> actions,
  required bool isDark,
}) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      const mapper = UnifiedJourneyActionMapper();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ctx.l10n.homeSomethingElse,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final action in actions)
              ListTile(
                leading: Icon(mapper.map(ctx, action).icon),
                title: Text(mapper.map(ctx, action).title),
                subtitle: Text(
                  '${mapper.map(ctx, action).subtitle} · ${ctx.l10n.homeMinutes(journeyActionMinutes(action))}',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(action.route);
                },
              ),
          ],
        ),
      );
    },
  );
}

class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({
    super.key,
    required this.data,
    required this.isDark,
    required this.onTap,
    required this.minutes,
    this.onMore,
  });

  final JourneyPresentationData data;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onLongPress: onMore,
          child: UnifiedHeroActionCard(
            data: JourneyPresentationData(
              title: data.title,
              subtitle: minutes > 0
                  ? '${data.subtitle} · ${context.l10n.homeMinutes(minutes)}'
                  : data.subtitle,
              icon: data.icon,
              route: data.route,
            ),
            isDark: isDark,
            onTap: onTap,
          ),
        ),
        if (onMore != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onMore,
              child: Text(context.l10n.homeSomethingElse),
            ),
          ),
      ],
    );
  }
}
