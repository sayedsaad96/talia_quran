import 'package:meta/meta.dart';

/// The single shared contract for the kids→parent guardian-link QR payload.
///
/// The child device encodes [qrPrefix] + token into `PairingSession.qrData`,
/// and the parent device's QR scanner accepts exactly this prefix. Both sides
/// must import this contract so the prefixes can never drift apart again
/// (the old `talia_link:` scanner prefix silently broke QR pairing).
@immutable
final class KidsQrLinkContract {
  const KidsQrLinkContract._();

  /// Prefix encoded by the child device into the guardian-link QR payload.
  static const String qrPrefix = 'talia-kids-link:';

  /// Builds the full QR payload the child device encodes.
  static String qrData(String token) => '$qrPrefix$token';

  /// True when [rawValue] is a payload this app's scanner must accept.
  static bool isLinkPayload(String rawValue) {
    final normalized = rawValue.trim();
    return normalized.toLowerCase().startsWith(qrPrefix) ||
        normalized.toLowerCase().startsWith(legacyQrPrefix);
  }

  /// Extracts the raw token from a scanned payload, accepting the legacy
  /// `talia_link:` prefix for tokens already printed on paper or saved in
  /// old screenshots, and a bare token pasted without any prefix.
  static String extractToken(String rawValue) {
    final normalized = rawValue.trim();
    for (final prefix in const [qrPrefix, legacyQrPrefix]) {
      if (normalized.toLowerCase().startsWith(prefix)) {
        return normalized.substring(prefix.length).trim();
      }
    }
    return normalized;
  }

  /// Pre-contract prefix kept for backwards compatibility only.
  static const String legacyQrPrefix = 'talia_link:';
}
