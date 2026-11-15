import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/datasources/share_good_local_store.dart';
import '../../domain/entities/invite_types.dart';
import '../cubits/good_impact_cubit.dart';

class ShareGoodSettingsTile extends StatelessWidget {
  const ShareGoodSettingsTile({
    super.key,
    required this.cubit,
    required this.onTap,
  });
  final GoodImpactCubit cubit;
  final VoidCallback onTap;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<GoodImpactCubit, GoodImpactState>(
    bloc: cubit,
    builder: (context, state) {
      if (!cubit.isAvailable()) return const SizedBox.shrink();
      final hasNew =
          state is GoodImpactReady && cubit.isCurrent(state) && state.hasNew;
      return ListTile(
        leading: const Icon(TaliaIcons.heartFilled),
        title: Text(context.l10n.goodImpactTitle),
        trailing: hasNew
            ? Semantics(label: context.l10n.goodImpactNew, child: const Badge())
            : null,
        onTap: onTap,
      );
    },
  );
}

/// The default identity applies only to personal invitations, not public ones.
class ShareGoodIdentitySettingsTile extends StatefulWidget {
  const ShareGoodIdentitySettingsTile({
    super.key,
    required this.auth,
    required this.store,
    required this.barrier,
    required this.isAvailable,
    required this.isAdult,
    this.audienceChanges,
  });
  final AuthCubit auth;
  final ShareGoodLocalStore store;
  final AccountDataBarrier barrier;
  final bool Function() isAvailable;
  final Future<bool> Function() isAdult;
  final Stream<void>? audienceChanges;

  @override
  State<ShareGoodIdentitySettingsTile> createState() =>
      _ShareGoodIdentitySettingsTileState();
}

class _ShareGoodIdentitySettingsTileState
    extends State<ShareGoodIdentitySettingsTile> {
  late _IdentityController _controller;
  @override
  void initState() {
    super.initState();
    _controller = _IdentityController(widget);
  }

  @override
  void didUpdateWidget(covariant ShareGoodIdentitySettingsTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auth != widget.auth ||
        oldWidget.store != widget.store ||
        oldWidget.barrier != widget.barrier ||
        oldWidget.isAvailable != widget.isAvailable ||
        oldWidget.isAdult != widget.isAdult ||
        oldWidget.audienceChanges != widget.audienceChanges) {
      unawaited(_controller.close());
      _controller = _IdentityController(widget);
    }
  }

  @override
  void dispose() {
    unawaited(_controller.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<_IdentityController, _IdentityView>(
        bloc: _controller,
        builder: (context, state) {
          final current = widget.auth.state;
          if (!widget.isAvailable() ||
              state.owner == null ||
              current is! AuthAuthenticated ||
              current.user.id != state.owner ||
              !widget.barrier.isReady) {
            return const SizedBox.shrink();
          }
          final l10n = context.l10n;
          String label(InviteIdentityMode mode) => switch (mode) {
            InviteIdentityMode.fullName => l10n.inviteIdentityFullName,
            InviteIdentityMode.firstName => l10n.inviteIdentityFirstName,
            InviteIdentityMode.displayName => l10n.inviteIdentityDisplayName,
            InviteIdentityMode.anonymous => l10n.inviteIdentityAnonymous,
          };
          return ListTile(
            leading: const Icon(TaliaIcons.person),
            title: Text(l10n.inviteIdentityTitle),
            subtitle: Text(l10n.inviteModePersonal),
            trailing: DropdownButton<InviteIdentityMode>(
              value: state.mode,
              onChanged: state.busy
                  ? null
                  : (value) {
                      if (value != null) _controller.setIdentity(value);
                    },
              items: [
                for (final mode in InviteIdentityMode.values)
                  DropdownMenuItem(value: mode, child: Text(label(mode))),
              ],
            ),
          );
        },
      );
}

class _IdentityView {
  const _IdentityView({
    this.owner,
    this.mode = InviteIdentityMode.firstName,
    this.busy = false,
  });
  final String? owner;
  final InviteIdentityMode mode;
  final bool busy;
}

class _IdentityController extends Cubit<_IdentityView> {
  _IdentityController(this.config) : super(const _IdentityView()) {
    _authChanges = config.auth.stream.listen((_) => refresh());
    _barrierChanges = config.barrier.changes.listen((_) => refresh());
    _audienceChanges = config.audienceChanges?.listen((_) => refresh());
    refresh();
  }
  final ShareGoodIdentitySettingsTile config;
  late final StreamSubscription<AuthState> _authChanges;
  late final StreamSubscription<void> _barrierChanges;
  StreamSubscription<void>? _audienceChanges;
  int _generation = 0;

  bool _valid(String owner, int generation) {
    final auth = config.auth.state;
    return !isClosed &&
        generation == _generation &&
        config.isAvailable() &&
        auth is AuthAuthenticated &&
        auth.user.id == owner &&
        config.barrier.isReady;
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    if (!isClosed) emit(const _IdentityView());
    final auth = config.auth.state;
    if (!config.isAvailable() || auth is! AuthAuthenticated) return;
    try {
      final lease = config.barrier.capture()..checkOwner(auth.user.id);
      if (!await config.isAdult()) return;
      lease.checkOwner(auth.user.id);
      if (!_valid(auth.user.id, generation)) return;
      emit(
        _IdentityView(
          owner: auth.user.id,
          mode: config.store.personalIdentityPreference(auth.user.id),
        ),
      );
    } catch (_) {
      /* Keep the setting hidden until account data is ready. */
    }
  }

  Future<void> setIdentity(InviteIdentityMode mode) async {
    final previous = state;
    final owner = previous.owner;
    final generation = _generation;
    if (owner == null || previous.busy || !_valid(owner, generation)) return;
    emit(_IdentityView(owner: owner, mode: previous.mode, busy: true));
    try {
      final lease = config.barrier.capture()..checkOwner(owner);
      if (!await config.isAdult() || !_valid(owner, generation)) return;
      await config.barrier.run((lease) async {
        lease.checkOwner(owner);
        if (!_valid(owner, generation)) {
          throw const AccountDataUnavailableException();
        }
        if (!await config.store.setPersonalIdentityPreference(owner, mode)) {
          throw const AccountDataUnavailableException();
        }
        lease.checkOwner(owner);
      }, authority: lease);
      if (_valid(owner, generation)) {
        emit(_IdentityView(owner: owner, mode: mode));
      }
    } catch (_) {
      if (_valid(owner, generation)) {
        emit(_IdentityView(owner: owner, mode: previous.mode));
      }
    } finally {
      if (_valid(owner, generation) && state.busy) {
        emit(_IdentityView(owner: owner, mode: previous.mode));
      }
    }
  }

  @override
  Future<void> close() async {
    _generation++;
    await _authChanges.cancel();
    await _barrierChanges.cancel();
    await _audienceChanges?.cancel();
    return super.close();
  }
}
