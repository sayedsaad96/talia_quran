import '../../constants/app_constants.dart';
import 'social_share_model.dart';

/// The QR destination printed on every card: the app's Play listing. The
/// campaign rides in Play's `referrer` parameter (reported in Play Console)
/// and carries only two short values; no user data ever enters the URL.
abstract final class ShareCardLinks {
  static String forCategory(SocialShareCategory category) {
    final referrer = Uri(
      queryParameters: {
        'utm_source': 'tc', // talia card; short keeps the QR sparse
        'utm_campaign': category.name,
      },
    ).query;
    return Uri.parse(SocialShareData.landingPageUrl)
        .replace(
          queryParameters: {
            'id': AppConstants.androidApplicationId,
            'referrer': referrer,
          },
        )
        .toString();
  }
}
