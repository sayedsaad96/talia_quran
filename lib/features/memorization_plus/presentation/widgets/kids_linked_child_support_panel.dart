import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/kids_learning_support_profile.dart';
import '../../domain/repositories/kids_remote_reading_support_repository.dart';
import '../../domain/repositories/kids_support_profile_repository.dart';
import 'kids_support_profile_editor.dart';

/// The reading question for a linked child, answered on the guardian's
/// device and synced to the child's device (roadmap T7). Until the server
/// has the table, or offline, it says the setting is unavailable.
class KidsLinkedChildSupportPanel extends StatefulWidget {
  const KidsLinkedChildSupportPanel({
    super.key,
    required this.childUserId,
    required this.remote,
  });

  final String childUserId;
  final KidsRemoteReadingSupportRepository remote;

  @override
  State<KidsLinkedChildSupportPanel> createState() =>
      _KidsLinkedChildSupportPanelState();
}

class _KidsLinkedChildSupportPanelState
    extends State<KidsLinkedChildSupportPanel> {
  late final Future<_LinkedChildSupportProfile?> _load = _loadRemote();

  Future<_LinkedChildSupportProfile?> _loadRemote() async {
    final result = await widget.remote.load(widget.childUserId);
    return result.fold(
      (_) => null,
      (support) => _LinkedChildSupportProfile(
        widget.remote,
        widget.childUserId,
        support,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<_LinkedChildSupportProfile?>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final store = snapshot.data;
        if (store == null) {
          return Text(
            l10n.kidsSupportLinkedUnavailable,
            key: const ValueKey('kids-support-linked-unavailable'),
            style: AppTypography.bodyMedium,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KidsSupportProfileEditor(store: store),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.kidsSupportLinkedNote,
              style: AppTypography.bodySmall.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Adapts the remote CAS to the editor. A conflict (the child's device
/// changed the answer meanwhile) is reported as "not saved" after the fresh
/// version is read, so the guardian's retry succeeds.
class _LinkedChildSupportProfile implements KidsSupportProfileRepository {
  _LinkedChildSupportProfile(this._remote, this._childUserId, this._current);

  final KidsRemoteReadingSupportRepository _remote;
  final String _childUserId;
  KidsRemoteReadingSupport _current;

  @override
  KidsLearningSupportProfile read() => _current.profile;

  @override
  Future<bool> save(KidsLearningSupportProfile profile) async {
    final result = await _remote.save(
      _childUserId,
      profile,
      expectedVersion: _current.version,
    );
    return result.fold(
      (failure) async {
        if (failure is PolicyConflictFailure) {
          final fresh = await _remote.load(_childUserId);
          fresh.fold((_) {}, (support) => _current = support);
        }
        return false;
      },
      (saved) async {
        _current = saved;
        return true;
      },
    );
  }
}
