import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/datasources/share_good_local_store.dart';
import '../../domain/entities/invite_activity_target.dart';
import '../../domain/entities/invite_types.dart';
import '../../domain/repositories/share_good_repository.dart';
import '../../domain/services/invite_target_labeler.dart';
import '../../share_good_config.dart';
import '../cubits/invite_create_cubit.dart';

part 'invite_mode_panels.dart';

class InviteModeSheet extends StatelessWidget {
  const InviteModeSheet({super.key, required this.cubit, this.clock});
  final InviteCreateCubit cubit;
  final DateTime Function()? clock;

  static Future<void> show(
    BuildContext context,
    InviteActivityTarget target,
    InviteMoment moment, {
    String? parentToken,
  }) async {
    final cubit = _makeCubit(context, target, moment);
    if (parentToken == null) {
      await cubit.begin();
    } else {
      await cubit.startChain(parentToken);
    }
    if (!context.mounted) {
      await cubit.close();
      return;
    }
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => InviteModeSheet(cubit: cubit),
      );
    } finally {
      await cubit.close();
    }
  }

  static InviteCreateCubit _makeCubit(
    BuildContext context,
    InviteActivityTarget target,
    InviteMoment moment,
  ) {
    final l10n = context.l10n;
    return InviteCreateCubit(
      target: target,
      moment: moment,
      repository: getIt<ShareGoodRepository>(),
      store: getIt<ShareGoodLocalStore>(),
      labeler: getIt<InviteTargetLabeler>(),
      auth: getIt<AuthCubit>(),
      barrier: AccountDataBarrier.forPreferences(getIt<SharedPreferences>()),
      isChild: () async =>
          (await getIt<MemorizationPathResolver>().currentProfile())?.isAdult !=
          true,
      isAvailable: () => getIt<ShareGoodAvailability>().isAvailable,
      arabic: context.isArabic,
      makeShareData: (invite, label) => _shareData(l10n, moment, invite, label),
    );
  }

  static SocialShareData _shareData(
    AppLocalizations l10n,
    InviteMoment moment,
    CreatedInvite invite,
    InviteTargetLabel label,
  ) {
    final name = invite.context.identity.visibleName;
    final message = moment == InviteMoment.beforeActivity
        ? (name == null
              ? l10n.inviteBeforeAnonymous(label.title)
              : l10n.inviteBeforeNamed(name, label.title))
        : (name == null
              ? l10n.inviteAfterAnonymous(label.title)
              : l10n.inviteAfterNamed(name, label.title));
    return SocialShareData.invitation(
      title: label.title,
      message: message,
      linkUrl: invite.shareUrl,
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: BlocBuilder<InviteCreateCubit, InviteCreateState>(
        bloc: cubit,
        builder: (context, state) => switch (state) {
          InviteCreateCreating() => const PopScope(
            canPop: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          InviteCreateIdle() => const Center(
            child: CircularProgressIndicator(),
          ),
          InviteCreateNeedsSignIn() => _SignInPanel(cubit),
          InviteCreateFailed() => _FailurePanel(cubit),
          InviteCreateParentExpired() => _ExpiredPanel(cubit),
          InviteCreateCreated() => _CreatedPanel(state, clock ?? DateTime.now),
          InviteCreateChoosingMode() => _ChoicePanel(cubit, state),
        },
      ),
    ),
  );
}
