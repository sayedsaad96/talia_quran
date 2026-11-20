import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../domain/entities/invite_activity_target.dart';
import '../../domain/entities/invite_types.dart';
import '../../share_good_config.dart';
import 'invite_mode_sheet.dart';

enum ShareGoodActionStyle { button, text, icon }

class ShareGoodAction extends StatefulWidget {
  const ShareGoodAction({
    super.key,
    required this.target,
    required this.moment,
    this.style = ShareGoodActionStyle.button,
  });
  final InviteActivityTarget target;
  final InviteMoment moment;
  final ShareGoodActionStyle style;
  @override
  State<ShareGoodAction> createState() => _ShareGoodActionState();
}

class _ShareGoodActionState extends State<ShareGoodAction> {
  late Future<bool> _eligible;
  StreamSubscription<void>? _profileChanges;
  @override
  void initState() {
    super.initState();
    _eligible = _check();
    if (getIt.isRegistered<MemorizationPathResolver>()) {
      _profileChanges = getIt<MemorizationPathResolver>().changes.listen((_) {
        if (mounted) setState(() => _eligible = _check());
      });
    }
  }

  @override
  void dispose() {
    _profileChanges?.cancel();
    super.dispose();
  }

  Future<bool> _check() async {
    try {
      if (!getIt<ShareGoodAvailability>().isAvailable) return false;
      // Round-trip through validation, including when assertions are disabled.
      InviteActivityTarget.fromJson(widget.target.toJson());
      return (await getIt<MemorizationPathResolver>().currentProfile())
              ?.isAdult ==
          true;
    } catch (_) {
      return false;
    }
  }

  @override
  void didUpdateWidget(covariant ShareGoodAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) _eligible = _check();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    key: ObjectKey(_eligible),
    future: _eligible,
    builder: (context, snapshot) {
      if (snapshot.data != true ||
          !getIt<ShareGoodAvailability>().isAvailable) {
        return const SizedBox.shrink();
      }
      final label = context.l10n.inviteCreateAction;
      void open() =>
          InviteModeSheet.show(context, widget.target, widget.moment);
      return switch (widget.style) {
        ShareGoodActionStyle.button => FilledButton.tonalIcon(
          onPressed: open,
          icon: const Icon(TaliaIcons.share),
          label: Text(label),
        ),
        ShareGoodActionStyle.text => TextButton.icon(
          onPressed: open,
          icon: const Icon(TaliaIcons.share),
          label: Text(label),
        ),
        ShareGoodActionStyle.icon => IconButton(
          onPressed: open,
          tooltip: label,
          icon: const Icon(TaliaIcons.share),
        ),
      };
    },
  );
}
