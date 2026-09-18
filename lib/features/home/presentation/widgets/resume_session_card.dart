import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/journey/resume_session_presentation_input.dart';
import '../../../../core/journey/resume_session_presentation_mapper.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/home_cubit.dart';
import '../theme/home_skin.dart';
import 'islamic_pattern_painter.dart';
import 'spring_tap.dart';

class ResumeSessionCard extends StatelessWidget {
  const ResumeSessionCard({
    super.key,
    required this.location,
    required this.skin,
  });

  final String location;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final presentationData = const ResumeSessionPresentationMapper().map(
      ResumeSessionPresentationInput(
        route: location,
        isArabic: context.isArabic,
        l10n: context.l10n,
      ),
    );

    return Semantics(
      button: true,
      label: presentationData.title,
      child: SpringTap(
        onTap: () => unawaited(context.push(location)),
        child: Container(
          decoration: BoxDecoration(
            gradient: skin.meshGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: skin.shadow,
          ),
          child: Stack(
            children: [
              IslamicPatternOverlay(
                color: skin.textOnHero,
                opacity: skin.heroCardTextureOpacity,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(presentationData.icon, color: skin.gold, size: 34),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                presentationData.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium.copyWith(
                                  color: skin.textOnHero,
                                  fontFamily: 'Amiri',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                presentationData.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: skin.textOnHeroMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: TextButton(
                            onPressed: () => unawaited(context.push(location)),
                            style: TextButton.styleFrom(
                              foregroundColor: skin.gold,
                            ),
                            child: Text(
                              context.l10n.resumeAction,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await getIt<AppSessionService>()
                                .clearLastRestorableLocation();
                            if (context.mounted) {
                              unawaited(context.read<HomeCubit>().load());
                            }
                          },
                          icon: Icon(Icons.close_rounded, color: skin.textOnHeroMuted),
                          tooltip: context.l10n.notNow,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
