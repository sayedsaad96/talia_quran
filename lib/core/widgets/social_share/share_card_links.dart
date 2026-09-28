import 'social_share_model.dart';

/// The QR destination printed on every card. Only two campaign parameters
/// are added (kept short so the QR stays sparse and scannable); no user data
/// ever enters the URL.
abstract final class ShareCardLinks {
  static String forCategory(SocialShareCategory category) {
    return Uri.parse(SocialShareData.landingPageUrl)
        .replace(
          path: '/',
          queryParameters: {
            'utm_source': 'tc', // talia card; short keeps the QR at version 4
            'utm_campaign': category.name,
          },
        )
        .toString();
  }
}
