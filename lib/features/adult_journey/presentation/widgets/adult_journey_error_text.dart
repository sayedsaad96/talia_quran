import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/adult_journey_state.dart';

/// The localized message for a failed adult-journey save. A failure is never
/// silent and never shows a raw exception; the previous choice stays as is.
class AdultJourneyErrorText extends StatelessWidget {
  const AdultJourneyErrorText(this.code, {super.key});

  final AdultJourneyErrorCode code;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        switch (code) {
          AdultJourneyErrorCode.saveFailed => l10n.adultJourneyErrorSaveFailed,
          AdultJourneyErrorCode.unavailable =>
            l10n.adultJourneyErrorUnavailable,
          AdultJourneyErrorCode.unsupportedRecord =>
            l10n.adultJourneyErrorUnsupported,
        },
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
