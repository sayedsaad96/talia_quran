import 'package:flutter/material.dart';

// ─── Premium Gate (Free Tier — Always Shows Content) ─────────────────────────
//
// In free tier mode, PremiumGate simply renders its child directly.
// When premium features are added, restore the subscription check logic.
//
// Note: Re-implement premium check when monetization is ready.

class PremiumGate extends StatelessWidget {
  const PremiumGate({
    super.key,
    required this.child,
    required this.featureName,
  });

  final Widget child;
  final String featureName;

  @override
  Widget build(BuildContext context) {
    // Free tier: always grant access
    return child;
  }
}
