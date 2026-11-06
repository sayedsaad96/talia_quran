import '../../core/config/supabase_config.dart';
import '../../core/experience/experience_feature_flags.dart';

final class ShareGoodAvailability {
  ShareGoodAvailability(this._flags, this._supabase, {String? linkHost})
    : links = ShareGoodLinks(
        linkHost ?? const String.fromEnvironment('SHARE_GOOD_LINK_HOST'),
      );

  final ExperienceFlags _flags;
  final SupabaseConfig _supabase;
  final ShareGoodLinks links;

  bool get isAvailable =>
      _flags.isEnabled(ExperienceFeature.shareGood) &&
      _supabase.isConfigured &&
      links.hasValidHost;
}

final class ShareGoodLinks {
  const ShareGoodLinks(this.host);
  final String host;
  static final _hostPattern = RegExp(
    r'^(?=.{1,253}$)(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}$',
  );
  static final _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{43}$');
  static final _pathPattern = RegExp(r'^/i/([A-Za-z0-9_-]{43})$');

  bool get hasValidHost => _hostPattern.hasMatch(host);

  Uri build(String token) {
    if (!hasValidHost || !_tokenPattern.hasMatch(token)) {
      throw const FormatException(
        'Invalid invitation link configuration or token',
      );
    }
    return Uri.https(host, '/i/$token');
  }

  String? parse(Uri uri) {
    if (!hasValidHost ||
        uri.scheme != 'https' ||
        uri.host != host.toLowerCase() ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return _pathPattern.firstMatch(uri.path)?.group(1);
  }

  /// Validate raw ingress before Uri normalizes ports and escaped characters.
  String? parseRaw(String value) {
    final prefix = 'https://${host.toLowerCase()}/i/';
    if (!hasValidHost || !value.startsWith(prefix)) return null;
    final token = value.substring(prefix.length);
    if (!_tokenPattern.hasMatch(token)) return null;
    return parse(Uri.parse(value));
  }

  String? parseReferrer(String referrer) {
    if (!referrer.startsWith('inv=')) return null;
    final token = referrer.substring(4);
    return _tokenPattern.hasMatch(token) ? token : null;
  }
}
