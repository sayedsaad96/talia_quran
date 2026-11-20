import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/datasources/share_good_local_store.dart';
import '../../domain/entities/invite_types.dart';
import '../../domain/repositories/share_good_repository.dart';
import '../../domain/services/inviter_identity_resolver.dart';
import 'invite_mode_sheet.dart';

class InviteCompletionSheet extends StatefulWidget {
  const InviteCompletionSheet._({
    required this.session,
    required this.auth,
    required this.repository,
    required this.store,
    required this.barrier,
    required this.isChild,
    required this.signIn,
    required this.openChain,
  });

  final InviteSession session;
  final AuthCubit auth;
  final ShareGoodRepository repository;
  final ShareGoodLocalStore store;
  final AccountDataBarrier barrier;
  final Future<bool> Function() isChild;
  final Future<void> Function(BuildContext) signIn;
  final Future<void> Function(BuildContext, InviteSession) openChain;

  static Future<void> show(
    BuildContext context,
    InviteSession session, {
    AuthCubit? auth,
    ShareGoodRepository? repository,
    ShareGoodLocalStore? store,
    AccountDataBarrier? barrier,
    Future<bool> Function()? isChild,
    Future<void> Function(BuildContext)? signIn,
    Future<void> Function(BuildContext, InviteSession)? openChain,
  }) async {
    final local = store ?? getIt<ShareGoodLocalStore>();
    final child =
        isChild ??
        () async =>
            (await getIt<MemorizationPathResolver>().currentProfile())
                ?.isChild ==
            true;
    try {
      if (await child()) return;
      await local.setAwaitingConsent(session.token, true);
    } catch (_) {
      // No consent is requested if its durable state cannot be saved.
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => InviteCompletionSheet._(
        session: session,
        auth: auth ?? getIt<AuthCubit>(),
        repository: repository ?? getIt<ShareGoodRepository>(),
        store: local,
        barrier:
            barrier ??
            AccountDataBarrier.forPreferences(getIt<SharedPreferences>()),
        isChild: child,
        signIn:
            signIn ??
            (context) async {
              await context.push('/login?from=share_good');
            },
        openChain:
            openChain ??
            (context, session) => InviteModeSheet.show(
              context,
              session.snapshot.target,
              InviteMoment.afterActivity,
              parentToken: session.token,
            ),
      ),
    );
    try {
      await local.setAwaitingConsent(session.token, false);
    } catch (_) {
      // Leave the pending choice retryable if storage is unavailable.
    }
  }

  @override
  State<InviteCompletionSheet> createState() => _InviteCompletionSheetState();
}

class _InviteCompletionSheetState extends State<InviteCompletionSheet> {
  bool _busy = false;
  bool _failed = false;
  bool _disclosed = false;

  String? _name(AuthState state) => state is AuthAuthenticated
      ? const InviterIdentityResolver()
            .resolve(
              InviteIdentityMode.displayName,
              authDisplayName: state.user.displayName,
            )
            .visibleName
      : null;

  Future<void> _private() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.store.setAwaitingConsent(widget.session.token, false);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _continueChain() async {
    if (_busy) return;
    if (widget.auth.state is! AuthAuthenticated) {
      await widget.signIn(context);
      if (mounted) setState(() {});
      return;
    }
    setState(() => _busy = true);
    try {
      if (await widget.isChild()) return;
      if (mounted) await widget.openChain(context, widget.session);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _tell() async {
    if (_busy) return;
    final state = widget.auth.state;
    if (state is! AuthAuthenticated) {
      await widget.signIn(context);
      if (mounted) setState(() {});
      return;
    }
    final name = _name(state);
    if (name == null) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final lease = widget.barrier.capture();
      lease.checkOwner(state.user.id);
      if (await widget.isChild()) throw const AccountDataUnavailableException();
      lease.checkOwner(state.user.id);
      final current = widget.auth.state;
      if (current is! AuthAuthenticated ||
          current.user.id != state.user.id ||
          _name(current) != name) {
        throw const AccountDataUnavailableException();
      }
      final result = await widget.repository.disclose(
        widget.session.token,
        name,
      );
      lease.checkOwner(state.user.id);
      if (result.isLeft()) throw const AccountDataUnavailableException();
      await widget.store.setAwaitingConsent(widget.session.token, false);
      if (mounted) {
        setState(() {
          _busy = false;
          _disclosed = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: BlocBuilder<AuthCubit, AuthState>(
          bloc: widget.auth,
          builder: (context, state) {
            final name = _name(state);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.inviteCompletionTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (state is! AuthAuthenticated)
                  Text(l10n.inviteGuestSignIn)
                else if (name != null)
                  Text(l10n.inviteTellName(name))
                else
                  Text(l10n.inviteNameUnavailable),
                if (_failed) Text(l10n.inviteDisclosureError),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _private,
                  child: Text(
                    _disclosed ? l10n.closingDone : l10n.inviteKeepPrivate,
                  ),
                ),
                if (!_disclosed)
                  TextButton(
                    onPressed:
                        _busy || (state is AuthAuthenticated && name == null)
                        ? null
                        : _tell,
                    child: Text(l10n.inviteTellInviter),
                  ),
                OutlinedButton(
                  onPressed: _busy ? null : _continueChain,
                  child: Text(l10n.inviteContinueChain),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
