import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/accessibility/clarity_mode.dart';
import '../../../../core/extensions/context_extensions.dart';

/// On/off switch for clarity mode. Renders nothing while the rollout flag is
/// off or no controller is registered.
class ClaritySettingTile extends StatelessWidget {
  const ClaritySettingTile({super.key, this.controller});

  /// Injected in tests; defaults to the registered controller.
  final ClarityModeController? controller;

  @override
  Widget build(BuildContext context) {
    final clarity = controller ?? ClarityModeController.maybeInstance();
    if (clarity == null || !clarity.isAvailable) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: clarity,
      builder: (context, _) => SwitchListTile(
        title: Text(context.l10n.clarityModeTitle),
        subtitle: Text(context.l10n.clarityModeSubtitle),
        value: clarity.preference,
        onChanged: (on) => unawaited(clarity.setOn(on)),
      ),
    );
  }
}
