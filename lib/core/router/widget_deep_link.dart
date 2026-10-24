import 'app_router.dart';

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
    _ => AppRoutes.home,
  };
}
