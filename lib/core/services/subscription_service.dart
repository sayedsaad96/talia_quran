// ─── Subscription Service (Free Tier — All Features Unlocked) ───────────────
//
// This is a stub implementation. All features are FREE.
// When premium features are ready to be developed, replace this
// with the actual RevenueCat / purchases_flutter implementation.
//
// Note: Re-implement with purchases_flutter when monetization is ready.

class SubscriptionService {
  /// Always returns true — app is completely free
  Future<bool> isPremium() async => true;

  /// No-op — no purchases in free tier
  Future<bool> purchaseMonthly() async => true;

  /// No-op — no purchases in free tier
  Future<bool> purchaseYearly() async => true;

  /// No-op — no purchases in free tier
  Future<bool> restorePurchases() async => true;
}
