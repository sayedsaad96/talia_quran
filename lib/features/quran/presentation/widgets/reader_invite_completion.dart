import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../share_good/application/active_invite_sessions.dart';
import '../../../share_good/domain/repositories/share_good_repository.dart';
import '../../../share_good/domain/services/invite_target_labeler.dart';
import '../../../share_good/presentation/widgets/quran_invite_completion_banner.dart';
import '../../../share_good/presentation/widgets/invite_completion_sheet.dart';
import '../../../share_good/share_good_config.dart';

class ReaderInviteCompletion extends StatefulWidget {
  const ReaderInviteCompletion({
    super.key,
    required this.localSessionId,
    required this.pageNumber,
    required this.confirmed,
  });

  final String localSessionId;
  final int pageNumber;
  final bool confirmed;

  @override
  State<ReaderInviteCompletion> createState() => _ReaderInviteCompletionState();
}

class _ReaderInviteCompletionState extends State<ReaderInviteCompletion> {
  StreamSubscription<void>? _audienceChanges;
  Future<bool>? _isAllowed;

  @override
  void initState() {
    super.initState();
    if (!getIt.isRegistered<ShareGoodAvailability>() ||
        !getIt.isRegistered<MemorizationPathResolver>()) {
      return;
    }
    final path = getIt<MemorizationPathResolver>();
    _isAllowed = _canParticipate(path);
    _audienceChanges = path.changes.listen((_) {
      if (mounted) setState(() => _isAllowed = _canParticipate(path));
    });
  }

  Future<bool> _canParticipate(MemorizationPathResolver path) async {
    if (!getIt<ShareGoodAvailability>().isAvailable) return false;
    return !path.isKids(await path.currentProfile());
  }

  @override
  void dispose() {
    unawaited(_audienceChanges?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAllowed == null) return const SizedBox.shrink();
    return FutureBuilder<bool>(
      future: _isAllowed,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.data != true ||
            !getIt<ShareGoodAvailability>().isAvailable) {
          return const SizedBox.shrink();
        }
        return QuranInviteCompletionBanner(
          localSessionId: widget.localSessionId,
          pageNumber: widget.pageNumber,
          confirmed: widget.confirmed,
          enabled: true,
          sessions: getIt<ActiveInviteSessions>(),
          labeler: getIt<InviteTargetLabeler>(),
          repository: getIt<ShareGoodRepository>(),
          onCompleted: (session) =>
              unawaited(InviteCompletionSheet.show(context, session)),
        );
      },
    );
  }
}
