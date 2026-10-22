import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injection.dart';
import '../../../core/experience/experience_feature_flags.dart';
import '../../../core/prayer_review/prayer_review_prompt_coordinator.dart';
import '../../../core/router/app_router.dart';
import '../../prayer_companion/domain/entities/prayer_companion.dart';
import '../../prayer_companion/presentation/cubits/prayer_companion_cubit.dart';
import '../domain/entities/prayer_review_authority.dart';

Future<void> submitPrayerCompanionWithReview(
  BuildContext context,
  PrayerCompanionCubit cubit,
  PrayerOccurrence occurrence,
  PrayerCompanionCommand command,
) async {
  if (cubit.state is PrayerCompanionSubmitting) return;
  final origin = _captureOrigin(context, cubit.state, occurrence, command);
  await cubit.submit(command);
  if (origin != null) await origin.present(cubit.state);
}

_ReviewOrigin? _captureOrigin(
  BuildContext context,
  PrayerCompanionState state,
  PrayerOccurrence occurrence,
  PrayerCompanionCommand command,
) {
  if (command != PrayerCompanionCommand.confirm ||
      !getIt.isRegistered<ExperienceFlags>() ||
      !getIt<ExperienceFlags>().isEnabled(ExperienceFeature.prayerReview) ||
      !getIt.isRegistered<PrayerReviewPromptCoordinator>()) {
    return null;
  }
  try {
    final coordinator = getIt<PrayerReviewPromptCoordinator>();
    final authority = coordinator.captureAuthority();
    if (authority.ownerId != occurrence.ownerId) return null;
    final route = ModalRoute.of(context);
    if (route == null) return null;
    return _ReviewOrigin(
      coordinator,
      authority,
      GoRouter.of(context),
      route,
      state is PrayerCompanionSuccess &&
          state.record.status == PrayerCompanionStatus.confirmed,
    );
  } catch (_) {
    return null;
  }
}

final class _ReviewOrigin {
  const _ReviewOrigin(
    this.coordinator,
    this.authority,
    this.router,
    this.route,
    this.alreadyConfirmed,
  );
  final PrayerReviewPromptCoordinator coordinator;
  final PrayerReviewAuthority authority;
  final GoRouter router;
  final ModalRoute<dynamic> route;
  final bool alreadyConfirmed;
  bool get _active =>
      route.isActive &&
      route.isCurrent &&
      route.navigator?.mounted == true &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  Future<void> present(PrayerCompanionState state) async {
    if (!_active || state is! PrayerCompanionSuccess) return;
    try {
      authority.check();
      final offer = await coordinator.forConfirmation(
        state.record,
        authority: authority,
        newlyConfirmed: !alreadyConfirmed,
        foreground: true,
      );
      if (offer == null || !_active) return;
      authority.check();
      offer.authority.check();
      await router.push<void>(
        AppRoutes.prayerReview,
        extra: state.record.occurrence,
      );
    } catch (_) {
      // The optional review never changes or rolls back the prayer confirmation.
    }
  }
}
