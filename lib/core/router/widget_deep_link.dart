import 'app_router.dart';

/// Placeholder swapped for the live wird page once the account lease is held.
const widgetWirdMarker = '__widget_wird__';

/// Widget intents carry no account IDs or arbitrary route/query payloads.
String widgetDeepLinkDestination(Uri? uri) {
  if (uri == null ||
      uri.scheme != 'talia' ||
      uri.host != 'widget' ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort ||
      uri.hasQuery ||
      uri.hasFragment) {
    return AppRoutes.home;
  }
  return switch (uri.path) {
    '/prayer' => '${AppRoutes.home}?widgetPrayer=1',
    '/review' => AppRoutes.memorizationPlusDailyPlan,
    '/khatmah' => AppRoutes.khatmahDashboard,
    '/khatmah-setup' => AppRoutes.khatmahSetup,
    // Resolved to the live wird page after the account lease is checked.
    '/wird' => widgetWirdMarker,
    _ => AppRoutes.home,
  };
}
