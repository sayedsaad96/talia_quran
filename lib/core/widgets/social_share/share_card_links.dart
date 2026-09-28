import 'social_share_model.dart';

/// The QR destination printed on every card. Only campaign parameters are
/// added; no user data ever enters the URL.
abstract final class ShareCardLinks {
  static String forCategory(SocialShareCategory category) {
    return Uri.parse(SocialShareData.landingPageUrl)
        .replace(
          path: '/',
          queryParameters: {
            'utm_source': 'talia_app',
            'utm_medium': 'share_card',
            'utm_campaign': category.name,
          },
        )
        .toString();
  }
}
