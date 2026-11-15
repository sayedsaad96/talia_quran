part of 'invite_mode_sheet.dart';

class _SignInPanel extends StatelessWidget {
  const _SignInPanel(this.cubit);
  final InviteCreateCubit cubit;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(context.l10n.inviteSignInToCreate),
      FilledButton(
        onPressed: () async {
          await context.push('/login?from=share_good');
          if (context.mounted) await cubit.begin();
        },
        child: Text(context.l10n.inviteSignInToCreate),
      ),
    ],
  );
}

class _FailurePanel extends StatelessWidget {
  const _FailurePanel(this.cubit);
  final InviteCreateCubit cubit;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(context.l10n.inviteCreateError),
      TextButton(onPressed: cubit.begin, child: Text(context.l10n.retryLabel)),
    ],
  );
}

class _ExpiredPanel extends StatelessWidget {
  const _ExpiredPanel(this.cubit);
  final InviteCreateCubit cubit;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(context.l10n.inviteChainExpired),
      FilledButton(
        onPressed: cubit.startStandalone,
        child: Text(context.l10n.inviteChainFresh),
      ),
    ],
  );
}

class _CreatedPanel extends StatelessWidget {
  const _CreatedPanel(this.state, this.clock);
  final InviteCreateCreated state;
  final DateTime Function() clock;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final minutes = state.invite.expiresAt
        .difference(clock())
        .inMinutes
        .clamp(0, 1 << 30);
    final duration = minutes >= 1440
        ? l10n.inviteDurationDays(minutes ~/ 1440)
        : minutes >= 60
        ? l10n.inviteDurationHours(minutes ~/ 60)
        : l10n.inviteDurationMinutes(minutes);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          minutes < 60
              ? l10n.inviteExpirySoon(minutes)
              : l10n.inviteExpiresIn(duration),
        ),
        FilledButton(
          onPressed: () => SocialShareSheet.show(context, state.data),
          child: Text(l10n.inviteCreateAction),
        ),
      ],
    );
  }
}

class _ChoicePanel extends StatelessWidget {
  const _ChoicePanel(this.cubit, this.choice);
  final InviteCreateCubit cubit;
  final InviteCreateChoosingMode choice;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.inviteModeTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.inviteModePersonal),
              selected: choice.mode == InviteMode.personal,
              onSelected: (_) => cubit.chooseMode(InviteMode.personal),
            ),
            ChoiceChip(
              label: Text(l10n.inviteModePublic),
              selected: choice.mode == InviteMode.public,
              onSelected: (_) => cubit.chooseMode(InviteMode.public),
            ),
          ],
        ),
        if (choice.mode != null) _IdentityChoices(cubit, choice),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: choice.mode == null ? null : cubit.create,
          child: Text(l10n.inviteCreateAction),
        ),
      ],
    );
  }
}

class _IdentityChoices extends StatelessWidget {
  const _IdentityChoices(this.cubit, this.choice);
  final InviteCreateCubit cubit;
  final InviteCreateChoosingMode choice;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String label(InviteIdentityMode mode) => switch (mode) {
      InviteIdentityMode.fullName => l10n.inviteIdentityFullName,
      InviteIdentityMode.firstName => l10n.inviteIdentityFirstName,
      InviteIdentityMode.displayName => l10n.inviteIdentityDisplayName,
      InviteIdentityMode.anonymous => l10n.inviteIdentityAnonymous,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(l10n.inviteIdentityTitle),
        Wrap(
          spacing: 8,
          children: [
            for (final mode in InviteIdentityMode.values)
              ChoiceChip(
                label: Text(label(mode)),
                selected: choice.identity == mode,
                onSelected: (_) => cubit.chooseIdentity(mode),
              ),
          ],
        ),
      ],
    );
  }
}
